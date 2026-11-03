# Data Validation & Reconciliation

**Project:** Sales Intelligence & Forecasting  
**Scope:** Independent BI Portfolio Simulation  
**Original Data Snapshot:** August 17, 2026  
**Data:** Synthetic and fictional

## 1. Validation Objective

The objective was to establish reliable reporting inputs before evaluating pipeline health, quota attainment, and forecast risk.

Rather than assuming the source CRM records were accurate, I examined duplicate opportunities, missing and inconsistent attributes, reference integrity, financial calculations, and CRM import outcomes.

The validation process preserved the original source records while using a trusted analytical layer for downstream reporting.

## 2. Source Data and Duplicate Reconciliation

Initial SQL profiling identified repeated opportunity records that could inflate financial reporting.

A deduplicated analytical view was created using `ROW_NUMBER()` to remove exact duplicate records while retaining the raw source data for traceability.

### Reconciliation Results

| Opportunity Status | Raw Records | Deduplicated Records | Records Removed | Potential Amount Overstatement |
| --- | ---: | ---: | ---: | ---: |
| Open | 731 | 727 | 4 | $3,501,000 |
| Won | 503 | 498 | 5 | $2,613,000 |
| Lost | 266 | 265 | 1 | $207,000 |
| *Total* | 1,500 | 1,490 | 10 | $6,321,000 |

**Finding:** Exact duplicate records accounted for $6.321M in potential financial overstatement across the full source dataset.

This amount represents the difference between raw and deduplicated opportunity amounts, not a confirmed FY2026 Q3 revenue or pipeline overstatement.

**Validation evidence:** [Duplicate impact reconciliation](../02_SQL/06_duplicate_impact_qa.sql)

## 3. Trusted Analytical Layer

After duplicate reconciliation, the opportunity dataset was evaluated against defined data-quality rules.

Checks included missing sales ownership, invalid account or product references, missing expected close dates, nonpositive amounts, out-of-range probabilities, missing closed-deal information, and inconsistent stage/status/forecast combinations.

### Quality Classification

| Metric | Result |
| --- | ---: |
| Deduplicated opportunity records | 1,490 |
| Records passing quality rules | 1,406 |
| Records requiring review | 84 |
| Quality pass rate | 94.4% |

The quality status differentiates opportunities that satisfy the defined reporting controls from records requiring additional investigation.

A passing classification indicates compliance with the implemented checks; it does not establish that every business attribute is independently accurate.

**Validation evidence:** [Trusted analytical layer](../02_SQL/03_trusted_layer.sql) and [Final SQL QA](../02_SQL/05_final_sql_qa.sql)

## 4. FY2026 Q3 Financial Reconciliation

Core financial KPIs were checked across the analytical reporting outputs and Power BI.

| Financial KPI | Verified Result |
| --- | ---: |
| Bookings | $40,128,000 |
| Total Quota | $24,645,000 |
| Quota Attainment | 162.82% |
| Open Pipeline | $91,350,000 |
| Weighted Pipeline | $47,935,050 |
| Gross Pipeline Coverage | 3.71x |
| Weighted Pipeline Coverage | 1.95x |
| Open Opportunities | 142 |

Bookings reflect quality-passing Won opportunities using their actual close dates. Open pipeline uses quality-passing Open opportunities in the relevant expected-close-date reporting context.

Weighted pipeline coverage is calculated as weighted open pipeline divided by quota. It is a coverage indicator, not a guarantee of future revenue.

**Validation evidence:** [Excel analysis](../03_Excel_Analysis/Sales_Intelligence_Forecasting_Analysis.xlsx) and [Power BI Command Center](../05_PowerBI/Sales_Intelligence_Forecast_Confidence_Command_Center.pbix)

## 5. Forecast Risk Validation

The forecast-risk analysis combines multiple signals instead of relying exclusively on an opportunity's stated forecast category.

These signals include stage/forecast misalignment, stale activity, repeated close-date pushes, and forecast-category downgrades.

### FY2026 Q3 Risk Checks

| Risk Indicator | Flagged Opportunities |
| --- | ---: |
| Stale activity | 24 |
| Stage/forecast mismatch | 12 |
| Repeated close-date pushes | 10 |
| Repeated forecast downgrades | 2 |
| Medium-risk opportunities | 4 |
| High-risk opportunities | 0 |

Risk indicators are not mutually exclusive, and their counts should not be added to determine the unique number of at-risk opportunities.

The risk-scoring thresholds are defined analytical business rules for prioritizing reviews, not a statistically validated prediction of deal failure.

The broader all-period risk review identifies 29 priority opportunities, comprising 2 High Risk and 27 Medium Risk opportunities. Those totals use a different reporting scope from FY2026 Q3.

## 6. Snapshot-Date Validation

The original reporting snapshot is August 17, 2026.

Two additional SQL checks were executed to investigate whether later-dated events could affect historical reporting.

| Validation Test | Result |
| --- | ---: |
| Opportunity-history records dated after August 17, 2026 | 0 |
| Opportunities with later-dated history | 0 |
| Quality-passing Won opportunities dated August 18–September 30, 2026 | 0 |
| Associated future-dated bookings amount | $0 |

These checks found no post-snapshot opportunity-history records or future-dated Q3 bookings within the tested populations.

Production reporting against continuously changing datasets would require explicit as-of-date handling and appropriate historical snapshots.

## 7. Salesforce CRM Import Reconciliation

The Salesforce simulation used opportunity external-ID mapping to support record matching and upsert processing.

A test load preceded the full opportunity upsert, followed by reconciliation using Salesforce Data Loader success and error outputs.

### Full Upsert Results

| Import Metric | Verified Result |
| --- | ---: |
| Successfully processed records | 1,406 |
| New records created | 1,401 |
| Existing records updated | 5 |
| Data Loader errors | 0 |
| Duplicate source opportunity IDs in success results | 0 |
| Missing source opportunity IDs in success results | 0 |

The created and updated records total 1,406 successfully processed rows.

Import success is distinct from the trusted-layer quality pass rate. These measurements represent different validation questions and should not be interpreted as interchangeable.

The Salesforce executive dashboard summarizes a broader pipeline population than the FY2026 Q3 Power BI financial review.

## 8. Validation Boundaries and Outstanding Checks

The completed reconciliation establishes confidence in the reported results under the current dataset and implemented quality rules.

Before treating the project as fully reproducible, the following technical details should be reviewed:

- Explicit handling of null or malformed numeric values in the trusted-layer quality rules.
- Consistent open-opportunity filtering for analyses labeled as open pipeline.
- Alignment of snapshot dates, reporting periods, and data populations across published outputs.
- Refresh behavior and file dependencies for independently reopening the Power BI and Excel deliverables.

These are documented validation limitations and publication checks, not evidence that the reconciled results are incorrect.

## 9. Conclusion

The validation process identified 10 exact duplicate opportunity records representing $6.321M in potential reporting overstatement, classified the deduplicated dataset using defined quality controls, reconciled FY2026 Q3 reporting metrics, and verified 1,406 successful Salesforce opportunity upsert operations with zero reported Data Loader errors.

Together, these controls demonstrate an approach centered on data reliability, traceability, and defensible business reporting.

*Independent portfolio simulation. All business entities, records, and financial figures are fictional.*
