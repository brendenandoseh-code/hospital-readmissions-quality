# Run this analysis on BigQuery

The SQLite pipeline (`../sql/`) ported to **BigQuery Standard SQL**. Runs on the **free BigQuery sandbox** (no billing).

> Adapted from the tested SQLite version; BigQuery-dialect changes are `SAFE_CAST` (which turns the CMS `"N/A"`/`"Too Few to Report"` placeholders into NULL), `CREATE OR REPLACE VIEW`, and dataset-qualified names. Confirm on first run.

## Option A — Web console (no install)
1. Open the **BigQuery console** (`console.cloud.google.com/bigquery`) — first visit enables a free **sandbox** project.
2. **Create dataset** → ID `readmissions` (location US).
3. **Create table** → Source: *Upload* → `data/HRRP_FY2026.csv` → Table name `readmissions_raw`. **Don't auto-detect** — click **Edit as text** under Schema and paste:
   ```
   facility_name:STRING,facility_id:STRING,state:STRING,measure_name:STRING,num_discharges:STRING,footnote:STRING,err:STRING,predicted_rate:STRING,expected_rate:STRING,num_readmissions:STRING,start_date:STRING,end_date:STRING
   ```
   (Loading these as STRING lets `SAFE_CAST` clean the suppressed values.) Set "Header rows to skip" = 1 → Create.
4. New query tab → paste **`analysis.sql`** → Run (creates the `readmissions.measures` view and runs the five analyses).

## Option B — Command line (`bq`)
```bash
bash bigquery/load.sh
```

## Notes
- `dataset.table` references resolve to your default/sandbox project — no project ID hard-coded.
- The explicit schema (vs. auto-detect) is deliberate: it keeps the clean column names the view expects and preserves the suppressed-value strings for `SAFE_CAST`.
