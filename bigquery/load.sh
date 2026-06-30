#!/usr/bin/env bash
# Load the CMS HRRP data into BigQuery, create the cleaning view, and run the analyses.
# Works on the free BigQuery sandbox. Prereqs: Google Cloud SDK (gcloud + bq),
# `gcloud auth login`, `gcloud config set project YOUR_PROJECT_ID`.
# Run from the repo root:  bash bigquery/load.sh
set -euo pipefail
DATASET=readmissions

bq --location=US mk -f --dataset "$DATASET"

# The CMS file is 12 columns in a fixed order. Load with an explicit schema so the
# columns get clean names and stay STRING — so SAFE_CAST can clean the
# "N/A" / "Too Few to Report" placeholders in the view.
SCHEMA="facility_name:STRING,facility_id:STRING,state:STRING,measure_name:STRING,num_discharges:STRING,footnote:STRING,err:STRING,predicted_rate:STRING,expected_rate:STRING,num_readmissions:STRING,start_date:STRING,end_date:STRING"
bq load --replace --source_format=CSV --skip_leading_rows=1 \
    "${DATASET}.readmissions_raw" "data/HRRP_FY2026.csv" "$SCHEMA"

bq query --use_legacy_sql=false < "bigquery/analysis.sql"

echo "Done — explore dataset '${DATASET}' in the BigQuery console."
