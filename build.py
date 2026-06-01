"""
Hospital Readmissions Quality Analysis — pipeline
-------------------------------------------------
Loads the CMS HRRP CSV into SQLite, applies the cleaning view from
sql/01_create_and_load.sql, runs the queries in sql/02_analysis.sql,
and writes Tableau-ready CSVs to outputs/.

Run:  py build.py
Requires only the Python standard library (sqlite3, csv).
"""
import csv, sqlite3, os, re

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.join(HERE, "data", "HRRP_FY2026.csv")
DB   = os.path.join(HERE, "readmissions.db")
OUT  = os.path.join(HERE, "outputs")
os.makedirs(OUT, exist_ok=True)

RAW_COLS = ["facility_name","facility_id","state","measure_name","num_discharges",
            "footnote","err","predicted_rate","expected_rate","num_readmissions",
            "start_date","end_date"]

def load():
    if os.path.exists(DB):
        os.remove(DB)
    con = sqlite3.connect(DB)
    cur = con.cursor()
    # schema + cleaning view
    with open(os.path.join(HERE,"sql","01_create_and_load.sql"), encoding="utf-8") as f:
        cur.executescript(f.read())
    # bulk load CSV -> readmissions_raw
    with open(DATA, encoding="utf-8-sig", newline="") as f:
        rdr = csv.reader(f)
        next(rdr)  # header
        cur.executemany(
            f"INSERT INTO readmissions_raw ({','.join(RAW_COLS)}) "
            f"VALUES ({','.join('?'*len(RAW_COLS))})",
            (row for row in rdr if len(row) == len(RAW_COLS))
        )
    con.commit()
    n = cur.execute("SELECT COUNT(*) FROM readmissions_raw").fetchone()[0]
    print(f"Loaded {n:,} raw rows.")
    return con

def split_queries(path):
    """Return list of (label, sql) using the '-> outputs/NAME.csv' hint in each query comment."""
    text = open(path, encoding="utf-8").read()
    out = []
    for stmt in [s.strip() for s in text.split(";") if s.strip() and not s.strip().startswith("--") is False]:
        pass
    # simpler: split on ';' then keep statements that contain SELECT
    for chunk in text.split(";"):
        if "SELECT" in chunk.upper():
            m = re.search(r"outputs/([\w]+)\.csv", chunk)
            label = m.group(1) if m else "query_%d" % len(out)
            # strip pure-comment lines for execution clarity (SQLite tolerates them anyway)
            out.append((label, chunk.strip()))
    return out

def export(con, label, sql):
    cur = con.execute(sql)
    cols = [d[0] for d in cur.description]
    rows = cur.fetchall()
    with open(os.path.join(OUT, f"{label}.csv"), "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f); w.writerow(cols); w.writerows(rows)
    return cols, rows

def main():
    con = load()
    queries = split_queries(os.path.join(HERE,"sql","02_analysis.sql"))
    summaries = {}
    for label, sql in queries:
        cols, rows = export(con, label, sql)
        summaries[label] = (cols, rows)
        print(f"  outputs/{label}.csv  ({len(rows)} rows)")

    # ---- print headline findings for the README ----
    print("\n================ KEY FINDINGS ================")
    if "by_condition" in summaries:
        cols, rows = summaries["by_condition"]
        ci = {c:i for i,c in enumerate(cols)}
        print("\nReadmissions worse-than-expected, by condition:")
        for r in rows:
            print(f"  {r[ci['condition']]:<24} avg ERR {r[ci['avg_err']]:.4f} | "
                  f"{r[ci['pct_worse']]:>5}% of hospitals worse | "
                  f"{r[ci['total_readmissions']] or 0:,} readmissions")
    if "by_state" in summaries:
        cols, rows = summaries["by_state"]
        ci = {c:i for i,c in enumerate(cols)}
        print("\nWorst 5 states by average ERR (>=30 measures):")
        for r in rows[:5]:
            print(f"  {r[ci['state']]}  avg ERR {r[ci['avg_err']]:.4f} | {r[ci['pct_worse']]}% worse")
        print("Best 5 states:")
        for r in rows[-5:]:
            print(f"  {r[ci['state']]}  avg ERR {r[ci['avg_err']]:.4f} | {r[ci['pct_worse']]}% worse")
    con.close()
    print("\nDone. Connect Tableau to the files in outputs/.")

if __name__ == "__main__":
    main()
