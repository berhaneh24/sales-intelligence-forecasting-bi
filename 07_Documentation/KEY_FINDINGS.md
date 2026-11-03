# Key Findings & Business Recommendations

**Project:** Sales Intelligence & Forecasting  
**Project Type:** Independent BI Case Study  
**Reporting Focus:** FY2026 Q3  
**Original Data Snapshot:** August 17, 2026  
**Data:** Synthetic and fictional

## Executive Summary

The analysis examined whether reported pipeline and sales performance provided a reliable basis for revenue forecasting and leadership decisions.

The findings highlight three areas: the financial impact of source-data quality, the difference between reported pipeline and probability-weighted revenue, and the importance of investigating opportunity-level risks before relying on forecast commitments.

Although the simulated organization exceeded its reported quarterly quota, strong aggregate performance did not eliminate the need for deal-level validation and forecast review.

## 1. Duplicate Records Created Measurable Reporting Exposure

**Finding**

SQL profiling identified 10 exact duplicate opportunity records across the source dataset.

| Measure | Result |
| --- | ---: |
| Original Opportunity Records | 1,500 |
| Deduplicated Records | 1,490 |
| Exact Duplicates Removed | 10 |
| Potential Amount Overstatement | $6,321,000 |

Of the $6.321M difference, $3.501M related to open opportunities, $2.613M to Won opportunities, and $207K to Lost opportunities.

**Why It Matters**

Duplicate records can materially distort financial reporting, even when the number of duplicate rows appears small.

Without appropriate reconciliation, leadership could make decisions using overstated opportunity amounts.

**Recommended Action**

Maintain source-to-trusted-layer reconciliation, establish duplicate-monitoring controls, and investigate conflicting records before allowing them into financial reporting.

The amount identified represents potential overstatement across the full synthetic dataset, not a confirmed FY2026 Q3 revenue impact.

## 2. Reported Pipeline Exceeded Probability-Weighted Pipeline

**Finding**

The validated FY2026 Q3 pipeline totaled $91.35M, compared with $47.94M in probability-weighted pipeline.

| Metric | FY2026 Q3 |
| --- | ---: |
| Open Pipeline | $91,350,000 |
| Weighted Pipeline | $47,935,050 |
| Difference | $43,414,950 |
| Weighted Pipeline Coverage | 1.95x |

Probability weighting reduced the nominal pipeline value by approximately 47.5%.

**Why It Matters**

Open pipeline reflects potential sales value, but does not account fully for the likelihood of individual opportunities closing.

Weighted pipeline provides an additional forecasting perspective. However, its usefulness depends on the quality and calibration of the underlying probability assumptions.

**Recommended Action**

Review pipeline using both nominal and weighted values. Investigate opportunity stage alignment, forecast classifications, and historical deal movement before relying on weighted values for revenue planning.

The difference is not a realized financial loss or a measured forecasting error.

## 3. Strong Quota Attainment Did Not Eliminate Forecast Risk

**Finding**

FY2026 Q3 reporting showed:

| Metric | Result |
| --- | ---: |
| Bookings | $40,128,000 |
| Total Quarterly Quota | $24,645,000 |
| Quota Attainment | 162.82% |
| Gross Pipeline Coverage | 3.71x |
| Weighted Pipeline Coverage | 1.95x |

**Why It Matters**

Quota attainment and pipeline coverage answer different business questions.

Quota attainment describes booked performance against the selected target, while coverage evaluates the size of the open pipeline relative to quota.

A representative or region may perform strongly against quota while still requiring attention to forward pipeline development.

**Recommended Action**

Evaluate attainment alongside weighted pipeline coverage and opportunity-level risk. Use combined performance indicators to prioritize pipeline reviews rather than ranking sales representatives on bookings alone.

Because the original reporting snapshot is August 17, 2026, the comparison represents bookings available at that snapshot against the selected FY2026 Q3 quota.

## 4. Forecast Risk Required More Than a Single Indicator

**Finding**

The forecast-risk analysis evaluated four indicators: stale activity, stage/forecast alignment, repeated close-date postponements, and forecast-category downgrades.

### FY2026 Q3 Risk Indicators

| Risk Indicator | Flagged Opportunities |
| --- | ---: |
| Stale Activity | 24 |
| Stage/Forecast Mismatch | 12 |
| Repeated Close-Date Pushes | 10 |
| Repeated Forecast Downgrades | 2 |

The quarter-filtered risk classification identified four Medium Risk opportunities and zero High Risk opportunities.

Across the broader validated open-opportunity population, the management tracker identified 29 priority opportunities: two High Risk and 27 Medium Risk.

These risk indicators can overlap and should not be summed to determine unique opportunity counts.

**Why It Matters**

A forecast category alone may not capture all the evidence relevant to deal credibility.

An opportunity may have a confident forecast position while showing limited recent activity, inconsistent stage information, or repeated closing delays.

**Recommended Action**

Prioritize opportunities with multiple risk indicators. Require deal owners to review current stage, forecast category, next steps, and expected close dates during recurring forecast meetings.

The risk scores are business-rule-based review priorities, not statistically validated default or loss probabilities.

## 5. Data Quality Needed to Be Measured Separately from Import Success

**Finding**

After deduplication, 1,406 of 1,490 opportunities passed the defined analytical quality checks, resulting in a 94.4% pass rate.

The Salesforce CRM simulation separately processed 1,406 opportunity records through an external-ID-based upsert, resulting in:

| Salesforce Import Result | Count |
| --- | ---: |
| Created | 1,401 |
| Updated | 5 |
| Data Loader Errors | 0 |

**Why It Matters**

A successful import does not independently prove that business data is accurate or suitable for reporting.

Technical processing controls and business data-quality controls answer different questions.

**Recommended Action**

Maintain separate checks for import success, source-record identity, business-rule compliance, and reporting reconciliation.

This helps prevent technically successful data loads from being interpreted as proof of complete analytical accuracy.

## 6. Translating Findings into Management Follow-Up

The analysis was designed to move beyond identifying problems and support practical management decisions.

The resulting approach emphasizes:

- **Data Reliability:** Monitor duplicates, incomplete records, and inconsistent classifications before financial reporting.
- **Forecast Credibility:** Investigate opportunities with multiple risk indicators and validate stage and closing assumptions.
- **Sales Execution:** Review quota attainment alongside pipeline coverage, with attention to regional and representative-level variation.
- **Accountability:** Connect priority opportunities to recommended actions, responsible owners, and follow-up dates.

The Power BI Leadership Actions page and supporting Excel management tracker demonstrate how these findings can be organized for recurring leadership review.

These follow-up activities are proposed within the simulation; the project does not claim they were implemented by an actual sales organization.

## Conclusion

The most important finding was that reliable forecasting requires more than a large pipeline or strong quota attainment.

It requires confidence in the underlying data, an understanding of the assumptions behind weighted revenue, and a structured way to identify opportunities needing further investigation.

The project demonstrates how data validation, sales analysis, forecast-risk assessment, and executive reporting can work together to support more informed management decisions.

**Supporting evidence:** SQL profiling and reconciliation scripts, Excel analysis workbook, Power BI Command Center, Salesforce import validation, and Executive QBR.

*Independent portfolio case study using fully synthetic and fictional data. No production business results or realized financial improvements are claimed.*
