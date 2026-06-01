# Tableau Dashboard Build Guide

Goal: a single **"Hospital Readmissions Quality"** dashboard you can publish to **Tableau Public** and link from your resume. ~30–45 minutes. Tableau Public is free.

## Connect the data
1. Run `py build.py` first — it writes the CSVs to `outputs/`.
2. Open Tableau Public → **Connect → Text file** → select `outputs/facility_measures.csv` (the main extract).
3. Add the other CSVs as separate data sources (no joins needed): `by_condition.csv`, `by_state.csv`, `worst_heart_failure.csv`.

> Tip: rename the data source fields to friendly names if Tableau imports them with underscores.

## Sheet 1 — "Where's the burden?" (bar, from `by_condition.csv`)
- Columns: `total_readmissions`  ·  Rows: `condition` (sort descending).
- Color by `pct_worse`. Title: **"Heart Failure & Pneumonia drive the most readmissions."**
- This is your lead visual — absolute harm, not just rates.

## Sheet 2 — "Geography" (filled map, from `by_state.csv`)
- Double-click `state` → Tableau makes a map. Color by `avg_err` (diverging red/blue centered on **1.0** — edit the color legend so 1.0 is the neutral midpoint).
- Tooltip: `hospitals`, `avg_err`, `pct_worse`.
- Title: **"Readmission penalties cluster in the Northeast."**

## Sheet 3 — "State ranking" (bar, from `by_state.csv`)
- Columns: `avg_err`  ·  Rows: `state` (sorted).
- Add a reference line at **1.0** (Analytics → Constant Line). Color bars red above 1.0, blue below.

## Sheet 4 — "Action list" (table/dot plot, from `worst_heart_failure.csv`)
- Rows: `facility_name`, `state`. Columns: `err`. Size by `readmissions`.
- Title: **"Highest-volume Heart Failure outliers — start here."**

## Assemble the dashboard
1. New **Dashboard**, size **1200×900**.
2. Layout: Sheet 1 top-left, Sheet 2 top-right, Sheet 3 bottom-left, Sheet 4 bottom-right.
3. Add a **filter** on `condition` (and `state`) — right-click → Use as Filter so the map drives the table.
4. Add a title: **"Hospital Readmissions Quality — CMS HRRP FY2026."**
5. Footer text box (build credibility with honesty):
   *"Source: CMS Hospital Readmissions Reduction Program, FY2026 (3,055 hospitals). ERR > 1.0 = more readmissions than expected for case-mix. CABG measure suppressed for 71% of hospitals; chronic measures (HF/PN) reported for ~85–89%."*

## Publish
- **File → Save to Tableau Public.** Make the viz title descriptive.
- Copy the public URL into:
  - your resume header (next to the GitHub/portfolio link),
  - your LinkedIn **Featured** section,
  - the top of this README.

## Talking point (for interviews)
> "I took the real CMS readmissions file, cleaned it in SQL — handling CMS's suppressed values so they didn't skew averages — and found that while penalty *rates* are similar across conditions, Heart Failure and Pneumonia carry the overwhelming majority of actual readmissions. So I'd point a quality team at transitional care for those two first, and I flagged the wide state-level variation as a systemic issue to investigate rather than a hospital-by-hospital blame exercise."
