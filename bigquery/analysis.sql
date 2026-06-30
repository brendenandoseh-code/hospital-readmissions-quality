-- ============================================================
-- Hospital Readmissions Quality — BigQuery Standard SQL
-- Adapted from ../sql/. Dataset assumed: `readmissions`.
-- load.sh loads the CMS file with an explicit schema (clean column names), so this
-- view mirrors the SQLite one. SAFE_CAST turns "N/A"/"Too Few to Report" into NULL.
--
-- Note: the cleaning view is named `measures` (not `readmissions`) on purpose — BigQuery
-- resolves a bare identifier to the table's row STRUCT when it matches the range-variable
-- name, which would collide with the `readmissions` (count) column. `measures` avoids that.
-- ============================================================

CREATE OR REPLACE VIEW readmissions.measures AS
SELECT
    facility_id,
    facility_name,
    state,
    CASE measure_name
        WHEN 'READM-30-AMI-HRRP'      THEN 'Heart Attack (AMI)'
        WHEN 'READM-30-CABG-HRRP'     THEN 'Bypass Surgery (CABG)'
        WHEN 'READM-30-COPD-HRRP'     THEN 'COPD'
        WHEN 'READM-30-HF-HRRP'       THEN 'Heart Failure (HF)'
        WHEN 'READM-30-HIP-KNEE-HRRP' THEN 'Hip/Knee Replacement'
        WHEN 'READM-30-PN-HRRP'       THEN 'Pneumonia (PN)'
        ELSE measure_name
    END                                         AS condition,
    measure_name,
    SAFE_CAST(num_discharges   AS INT64)        AS discharges,
    SAFE_CAST(err              AS FLOAT64)      AS err,
    SAFE_CAST(predicted_rate   AS FLOAT64)      AS predicted_rate,
    SAFE_CAST(expected_rate    AS FLOAT64)      AS expected_rate,
    SAFE_CAST(num_readmissions AS INT64)        AS readmissions,
    CASE WHEN SAFE_CAST(err AS FLOAT64) > 1.0 THEN 1 ELSE 0 END AS worse_than_expected
FROM readmissions.readmissions_raw;

-- Q1. National picture by condition.
SELECT condition,
       COUNT(err)                                            AS hospitals_reported,
       ROUND(AVG(err), 4)                                    AS avg_err,
       SUM(worse_than_expected)                              AS hospitals_worse,
       ROUND(100.0 * SUM(worse_than_expected) / COUNT(err), 1) AS pct_worse,
       SUM(readmissions)                                     AS total_readmissions
FROM readmissions.measures GROUP BY condition ORDER BY pct_worse DESC;

-- Q2. State-level performance (>= 30 measures for a stable average).
SELECT state,
       COUNT(DISTINCT facility_id)                           AS hospitals,
       COUNT(err)                                            AS measures_reported,
       ROUND(AVG(err), 4)                                    AS avg_err,
       ROUND(100.0 * SUM(worse_than_expected) / COUNT(err), 1) AS pct_worse
FROM readmissions.measures GROUP BY state HAVING COUNT(err) >= 30 ORDER BY avg_err DESC;

-- Q3. Worst Heart-Failure outliers (>= 300 discharges).
SELECT facility_name, state, discharges, err, readmissions
FROM readmissions.measures
WHERE condition = 'Heart Failure (HF)' AND discharges >= 300
ORDER BY err DESC LIMIT 25;

-- Q4. Facility-level extract (dashboard main source).
SELECT facility_id, facility_name, state, condition,
       discharges, err, predicted_rate, expected_rate, readmissions, worse_than_expected
FROM readmissions.measures WHERE err IS NOT NULL;

-- Q5. Suppression / coverage by condition.
SELECT condition,
       COUNT(*)                                              AS rows_total,
       SUM(CASE WHEN err IS NULL THEN 1 ELSE 0 END)          AS rows_suppressed,
       ROUND(100.0 * SUM(CASE WHEN err IS NULL THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_suppressed
FROM readmissions.measures GROUP BY condition ORDER BY pct_suppressed DESC;
