-- ============================================================
-- Hospital Readmissions Quality Analysis
-- 02 — Analysis queries  (run after 01_create_and_load.sql)
-- Each query below maps to one exported CSV / one Tableau sheet.
-- ============================================================

-- Q1. National picture by condition: how many hospitals are penalized
--     (ERR > 1), average ERR, and total excess readmissions.
--     -> outputs/by_condition.csv  (Tableau: bar chart of % worse-than-expected)
SELECT
    condition,
    COUNT(err)                                            AS hospitals_reported,
    ROUND(AVG(err), 4)                                    AS avg_err,
    SUM(worse_than_expected)                              AS hospitals_worse,
    ROUND(100.0 * SUM(worse_than_expected) / COUNT(err), 1) AS pct_worse,
    SUM(readmissions)                                     AS total_readmissions
FROM readmissions
GROUP BY condition
ORDER BY pct_worse DESC;

-- Q2. State-level performance: average ERR across all conditions, ranked.
--     -> outputs/by_state.csv  (Tableau: filled map + ranked bar)
SELECT
    state,
    COUNT(DISTINCT facility_id)                           AS hospitals,
    COUNT(err)                                            AS measures_reported,
    ROUND(AVG(err), 4)                                    AS avg_err,
    ROUND(100.0 * SUM(worse_than_expected) / COUNT(err), 1) AS pct_worse
FROM readmissions
GROUP BY state
HAVING COUNT(err) >= 30          -- suppress thin states for a stable average
ORDER BY avg_err DESC;

-- Q3. Worst-performing hospitals on Heart Failure (highest-volume chronic measure),
--     limited to facilities with a meaningful denominator.
--     -> outputs/worst_heart_failure.csv  (Tableau: ranked table / dot plot)
SELECT
    facility_name, state, discharges, err, readmissions
FROM readmissions
WHERE condition = 'Heart Failure (HF)'
  AND discharges >= 300            -- focus where the signal is reliable
ORDER BY err DESC
LIMIT 25;

-- Q4. Facility-level extract powering the dashboard (one row per hospital x condition,
--     numeric measures only). -> outputs/facility_measures.csv  (Tableau main extract)
SELECT
    facility_id, facility_name, state, condition,
    discharges, err, predicted_rate, expected_rate, readmissions, worse_than_expected
FROM readmissions
WHERE err IS NOT NULL;

-- Q5. Data-quality / coverage check: share of measures suppressed ("Too Few to Report"
--     or N/A) by condition — an honest note for the dashboard footer.
--     -> outputs/data_quality.csv
SELECT
    condition,
    COUNT(*)                                              AS rows_total,
    SUM(CASE WHEN err IS NULL THEN 1 ELSE 0 END)          AS rows_suppressed,
    ROUND(100.0 * SUM(CASE WHEN err IS NULL THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_suppressed
FROM readmissions
GROUP BY condition
ORDER BY pct_suppressed DESC;
