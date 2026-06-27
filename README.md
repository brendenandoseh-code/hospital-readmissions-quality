# Hospital Readmissions: A Healthcare Quality Analysis

**Author:** Brenden Andoseh · [LinkedIn](https://www.linkedin.com/in/brenden-andoseh-189484177/)
**Stack:** SQL (SQLite) · Python (stdlib) · Tableau
**Data:** [CMS Hospital Readmissions Reduction Program (HRRP), FY2026](https://data.cms.gov/provider-data/dataset/9n3s-kdb3) — real, public, 3,055 hospitals
**Live dashboard:** [Tableau Public](https://public.tableau.com/app/profile/brenden.andoseh/viz/HospitalReadmissionsQualityCMSHRRPFY2026/HRQdashboard)

> 30-day readmissions are a core hospital **quality and cost** measure. Under Medicare's HRRP, hospitals that readmit more patients than expected for their case-mix are financially penalized. This project takes the official CMS file and answers: **which conditions and which states have the biggest readmission problem, and where should a quality team focus first?**

---

## Business problem
A hospital network's quality leadership wants to know where excess 30-day readmissions are concentrated — by clinical condition and by geography — so they can target improvement programs (discharge planning, follow-up calls, medication reconciliation) where they'll reduce the most harm and avoid the most penalty dollars.

## The data
One row per hospital × condition, across six CMS measures: Heart Attack (AMI), Bypass Surgery (CABG), COPD, Heart Failure (HF), Hip/Knee Replacement, and Pneumonia. The key metric is the **Excess Readmission Ratio (ERR)**:

- **ERR > 1.0** → the hospital readmits **more** patients than CMS predicts for its case-mix (worse, penalized).
- **ERR < 1.0** → **fewer** than expected (better).

CMS suppresses measures with too few cases ("Too Few to Report" / "N/A"); the pipeline converts these to NULL so they never distort an average.

## Method
1. **Load** the CSV into SQLite (`build.py`).
2. **Clean** with a SQL view (`sql/01_create_and_load.sql`) — type-cast numerics, NULL out suppressed values, label conditions, and flag `worse_than_expected`.
3. **Analyze** with five queries (`sql/02_analysis.sql`) → five Tableau-ready CSVs in `outputs/`.
4. **Visualize** in Tableau (`tableau/DASHBOARD_GUIDE.md`).

## Key findings *(real FY2026 figures)*

**1. Heart Failure and Pneumonia drive the readmission burden.** They aren't the highest *rate* of penalized hospitals, but they dominate **absolute** readmissions — **169,065** (HF) and **131,428** (PN), dwarfing surgical measures like Hip/Knee (4,998). A quality team chasing volume of harm should start with **HF and pneumonia discharge programs.**

| Condition | Avg ERR | % hospitals worse than expected | Total readmissions |
|---|---|---|---|
| Bypass Surgery (CABG) | 1.0018 | 49.9% | 7,153 |
| Heart Attack (AMI) | 1.0018 | 49.7% | 36,231 |
| **Heart Failure (HF)** | 1.0014 | 48.9% | **169,065** |
| Hip/Knee Replacement | 1.0040 | 47.9% | 4,998 |
| COPD | 1.0011 | 47.2% | 42,934 |
| **Pneumonia (PN)** | 1.0015 | 46.8% | **131,428** |

**2. Geography matters more than condition.** Average ERR ranges from **1.034 (Massachusetts)** down to **0.943 (Idaho)** — a far wider spread than across conditions. In MA and NJ, **>62%** of measured hospitals are worse than expected; in ID, MT, ND, and ME, fewer than **21%** are. Penalties cluster in dense Northeast/urban states, which points to **system-level factors** (patient acuity, post-acute access, socioeconomics) beyond any single hospital's control.

**3. A short list of high-volume hospitals are clear outliers.** Filtering Heart Failure to facilities with ≥300 discharges surfaces specific, high-confidence targets (e.g., ST LUCIE MEDICAL CENTER, FL at ERR 1.28 with 115 readmissions) — exactly the kind of ranked worklist a quality director can act on.

## Recommendations
- **Prioritize HF + pneumonia** transitional-care interventions — they carry the largest absolute readmission load.
- **Investigate the worst-ERR states** (MA, NJ, FL, IL) for systemic post-acute-care gaps, and **study the best (ID, ND, MT)** for transferable practices.
- **Build a ranked, volume-weighted worklist** (not a raw ERR sort) so improvement effort lands where it prevents the most readmissions.

## Honest notes (data caveats)
- **Suppression is uneven.** CABG is suppressed for **71%** of hospitals (low surgical volume), so its national numbers rest on a small subset; HF/PN are reported for ~85–89% (`outputs/data_quality.csv`). Conclusions are weighted toward the well-reported chronic measures on purpose.
- ERR is **case-mix adjusted by CMS**, but residual confounding (e.g., area deprivation) is well-documented — hence the "investigate," not "blame," framing on geography.
- FY2026 ERRs cover discharges **07/01/2021–06/30/2024**.

## Reproduce it
```bash
# data/HRRP_FY2026.csv is the real CMS download (re-fetch anytime):
#   https://data.cms.gov/provider-data/dataset/9n3s-kdb3  ->  "Download CSV"
py build.py                 # loads, cleans, runs SQL, writes outputs/
# then open Tableau and follow tableau/DASHBOARD_GUIDE.md
```

## Files
```
hospital-readmissions-quality/
├─ README.md                ← this file
├─ build.py                 ← end-to-end pipeline (stdlib only)
├─ data/HRRP_FY2026.csv     ← real CMS source data
├─ sql/01_create_and_load.sql   ← schema + cleaning view
├─ sql/02_analysis.sql          ← 5 analysis queries
├─ outputs/                 ← Tableau-ready CSVs (generated)
└─ tableau/DASHBOARD_GUIDE.md   ← step-by-step dashboard build
```
