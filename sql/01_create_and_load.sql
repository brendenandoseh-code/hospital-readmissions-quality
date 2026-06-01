-- ============================================================
-- Hospital Readmissions Quality Analysis
-- 01 — Schema & cleaning
-- Source: CMS Hospital Readmissions Reduction Program (HRRP), FY2026
-- Engine: SQLite (also runs with minor syntax tweaks on Postgres/BigQuery)
-- ============================================================

-- Raw load target. (build.py bulk-loads the CSV into this table.)
-- One row = one hospital x one of six 30-day readmission measures.
CREATE TABLE IF NOT EXISTS readmissions_raw (
    facility_name   TEXT,
    facility_id     TEXT,
    state           TEXT,
    measure_name    TEXT,    -- READM-30-{AMI,CABG,COPD,HF,HIP-KNEE,PN}-HRRP
    num_discharges  TEXT,    -- text on load: holds "N/A"/"Too Few to Report"
    footnote        TEXT,
    err             TEXT,    -- Excess Readmission Ratio (>1 = worse than expected)
    predicted_rate  TEXT,
    expected_rate   TEXT,
    num_readmissions TEXT,
    start_date      TEXT,
    end_date        TEXT
);

-- Cleaned, analysis-ready view.
--  * ERR > 1.0  -> hospital readmits MORE than CMS predicts for its case-mix (worse)
--  * ERR < 1.0  -> better than expected
--  * Non-numeric placeholders ("N/A", "Too Few to Report") become NULL and drop out of math.
DROP VIEW IF EXISTS readmissions;
CREATE VIEW readmissions AS
SELECT
    facility_id,
    facility_name,
    state,
    -- friendly condition label
    CASE measure_name
        WHEN 'READM-30-AMI-HRRP'      THEN 'Heart Attack (AMI)'
        WHEN 'READM-30-CABG-HRRP'     THEN 'Bypass Surgery (CABG)'
        WHEN 'READM-30-COPD-HRRP'     THEN 'COPD'
        WHEN 'READM-30-HF-HRRP'       THEN 'Heart Failure (HF)'
        WHEN 'READM-30-HIP-KNEE-HRRP' THEN 'Hip/Knee Replacement'
        WHEN 'READM-30-PN-HRRP'       THEN 'Pneumonia (PN)'
        ELSE measure_name
    END                                              AS condition,
    measure_name,
    CAST(NULLIF(NULLIF(num_discharges,'N/A'),'Too Few to Report') AS INTEGER)    AS discharges,
    CAST(NULLIF(err,'N/A')                          AS REAL)                      AS err,
    CAST(NULLIF(predicted_rate,'N/A')               AS REAL)                      AS predicted_rate,
    CAST(NULLIF(expected_rate,'N/A')                AS REAL)                      AS expected_rate,
    CAST(NULLIF(NULLIF(num_readmissions,'N/A'),'Too Few to Report') AS INTEGER)  AS readmissions,
    CASE WHEN CAST(NULLIF(err,'N/A') AS REAL) > 1.0 THEN 1 ELSE 0 END            AS worse_than_expected
FROM readmissions_raw;
