# Analytical Methodology & Technical Approach

**Project:** Sales Intelligence & Forecasting  
**Project Type:** Independent Business Intelligence Case Study  
**Technologies:** MySQL, Excel, Power BI, DAX, Salesforce CRM, PowerPoint  
**Original Data Snapshot:** August 17, 2026  
**Data:** Synthetic and fictional

## 1. Business Context

Sales leadership needs reliable visibility into pipeline health, forecast credibility, quota performance, and opportunities requiring attention.

The central challenge in this simulation was determining whether reported opportunity values provided a trustworthy basis for revenue planning.

I approached the project as a business intelligence engagement rather than an isolated dashboard exercise. The work began with evaluating source-data reliability, continued through analytical modeling and forecast-risk assessment, and concluded with executive reporting and recommended management actions.

The analytical approach was organized around three questions:

- Can the underlying opportunity data support reliable reporting?
- What do pipeline, quota, and opportunity-history measures reveal about forecast confidence?
- Which findings should leadership investigate or act on?

## 2. Data Architecture and Preparation

The project uses separate analytical components for data validation, financial reporting, CRM simulation, and executive communication.

### SQL Analytical Layer

MySQL was used to profile the original synthetic datasets and create a trusted reporting layer.

The workflow uses:

**Raw source tables → Deduplicated opportunity view → Typed reporting view → Quality-flagged view → Trusted analytical view**

The original source records were preserved rather than modified directly.

This separation enables analysis of source-data issues while maintaining a traceable reporting population.

### Excel Analysis

Excel was used for supporting analysis, reconciliation, quota and pipeline review, forecast-risk investigation, and management follow-up tracking.

The workbook provides an additional checkpoint for evaluating results before presenting them through Power BI.

### Power BI Reporting

Power BI provides the primary analytical reporting solution, with a dimensional model, DAX measures, executive reporting, forecast analysis, quality assurance, and opportunity-level investigation.

### Salesforce CRM Simulation

Salesforce was used as a separate CRM reporting and import-validation simulation.

The Salesforce and Power BI deliverables represent complementary analytical workflows. They are not presented as a continuously synchronized production integration.

## 3. Analytical Decision: Investigating Duplicate Records

One of the initial priorities was identifying whether repeated opportunity records could distort pipeline and sales reporting.

I compared raw record counts with distinct opportunity identifiers and investigated repeated records before determining how to handle them.

The distinction between an exact duplicate and a potentially different record sharing the same business identifier was important.

Removing records solely because they share an opportunity ID could discard information that requires investigation.

The trusted-layer approach therefore used a `ROW_NUMBER()` window function to remove exact duplicate source records based on the defined comparison fields.

### Business Impact

The final reconciliation identified:

| Measure | Result |
| --- | ---: |
| Original opportunity rows | 1,500 |
| Deduplicated opportunity rows | 1,490 |
| Exact duplicates removed | 10 |
| Difference in aggregated opportunity amounts | $6,321,000 |

This demonstrated that duplicate source records could materially inflate reported opportunity amounts.

The $6.321M represents potential overstatement across the full synthetic dataset, not a confirmed reduction in realized revenue or an isolated FY2026 Q3 impact.

**Supporting SQL:** [Data profiling](../02_SQL/02_data_profile_recovered.sql), [Trusted layer](../02_SQL/03_trusted_layer.sql), and [Duplicate impact QA](../02_SQL/06_duplicate_impact_qa.sql)

## 4. Analytical Decision: Establishing Reporting Quality Rules

Deduplication alone was insufficient to establish reporting reliability.

Opportunities could still contain incomplete ownership information, invalid references, inconsistent forecast classifications, or other attributes affecting downstream analysis.

I used a quality-flagging approach to distinguish records meeting the defined reporting rules from those requiring further review.

The controls included:

- Missing sales ownership and invalid reference-table relationships.
- Missing expected close dates and invalid financial or probability values.
- Missing actual close dates or win/loss reasons for closed opportunities.
- Inconsistencies among stage, status, and forecast category.

The resulting reporting population contained 1,406 quality-passing opportunities out of 1,490 deduplicated records, a 94.4% pass rate.

The quality classification supports repeatable filtering and transparent exclusions. It does not establish that every passing record is independently accurate.

## 5. Analytical Decision: Separating Pipeline Value from Forecast Confidence

Open pipeline represents potential deal value, but it should not automatically be treated as expected revenue.

I separated nominal pipeline value from probability-weighted pipeline and evaluated both against sales quota.

For FY2026 Q3, the validated reporting figures were:

| Measure | Value |
| --- | ---: |
| Open Pipeline | $91.35M |
| Weighted Pipeline | $47.94M |
| Total Quota | $24.65M |
| Weighted Pipeline Coverage | 1.95x |

The difference between open and weighted pipeline highlights the importance of probability assumptions.

However, probability weighting alone does not establish forecast accuracy.

That led to additional analysis of opportunity stage alignment, activity recency, historical close-date changes, and forecast-category movement.

## 6. Analytical Decision: Using Multiple Forecast-Risk Signals

Rather than classifying forecast risk using only a single status field, the analysis combined four defined indicators:

- **Stage/Forecast Alignment:** Identifies opportunities whose current sales stage may not support the stated forecast category.
- **Stale Activity:** Flags opportunities with missing activity dates or activity more than 90 days old relative to the reporting snapshot.
- **Repeated Close-Date Pushes:** Uses opportunity history to identify deals whose expected close dates have been postponed three or more times.
- **Forecast Downgrades:** Examines repeated movement from higher-confidence forecast categories to lower-confidence categories.

SQL window functions, including `LAG()`, were used to compare sequential opportunity-history records.

The four indicators contribute to an interpretable risk score, which supports High Risk, Medium Risk, Watch, and Low Risk classifications.

These are defined analytical prioritization rules, not a statistically trained prediction model.

The indicators may overlap, and their counts should not be added together to determine unique opportunity totals.

## 7. Analytical Decision: Connecting Performance with Forward Pipeline

Quota attainment provides information about historical sales performance, while pipeline coverage provides a separate view of potential future performance.

Using either measure alone can lead to incomplete conclusions.

The analysis therefore considered both measures when evaluating sales representative performance.

For example, a representative could exceed quota but still have limited forward pipeline coverage.

This creates a different management question from a representative who is below quota and also lacks sufficient weighted pipeline.

The approach supports more targeted review and coaching discussions rather than relying exclusively on a sales leaderboard.

## 8. Power BI Modeling and Reporting Decisions

The Power BI solution uses fact tables for opportunity, quota, and forecast-risk data, supported by shared reporting dimensions.

Date relationships were configured to support different business interpretations of time.

For example, expected close dates provide the active opportunity reporting context, while the Bookings DAX measure uses `USERELATIONSHIP()` to apply the actual close date.

The report contains five pages:

- **QA Validation:** Reporting controls and reconciliation.
- **Executive Overview:** Business performance and forecast exposure.
- **Leadership Actions:** Prioritized follow-up and management accountability.
- **Pipeline & Forecast:** Pipeline composition, coverage, and forecasting analysis.
- **Opportunity Detail:** Individual opportunity investigation and recommended actions.

The design separates leadership monitoring from deeper analytical investigation.

## 9. CRM Import and Reconciliation Approach

The Salesforce simulation included opportunity field mapping, test imports, a full external-ID-based upsert, and reconciliation of Data Loader results.

The full upsert successfully processed 1,406 records:

- 1,401 created.
- 5 updated.
- 0 reported Data Loader errors.

External-ID mapping supported matching existing CRM records during the upsert process.

The Salesforce executive dashboard provides visibility into the simulated CRM opportunity population, including pipeline by stage, forecast category, region, and sales representative.

Successful import processing and business data-quality validation are distinct controls.

## 10. Turning Findings into Management Actions

An important objective was ensuring that analysis led to practical recommendations rather than ending with descriptive reporting.

The workflow connects risk indicators with opportunity-level investigation, suggested actions, responsible owners, and follow-up dates.

The management approach is:

**Identify → Validate → Prioritize → Assign → Follow Up → Reassess**

Examples include reviewing stale opportunities, confirming deal-stage credibility, investigating forecast downgrades, and evaluating pipeline coverage concerns.

These are proposed actions within the fictional business scenario, not evidence of actual organizational remediation or realized financial improvement.

## 11. Validation and Reporting Boundaries

The project includes reconciliation checks across SQL, Excel, Power BI, and Salesforce.

Key controls include duplicate-impact reconciliation, trusted-record classification, financial KPI comparisons, snapshot-date checks, and CRM import validation.

The original data snapshot is August 17, 2026. The Salesforce dashboard's later display timestamp reflects the reporting environment and should not be interpreted as a refreshed underlying business-data snapshot.

The analytical model remains subject to documented assumptions, quality-rule limitations, and reproducibility checks.

## 12. Conclusion

The project demonstrates an analytical workflow that moves from understanding business requirements and examining source-data reliability to developing reporting models, testing forecast assumptions, and communicating recommendations.

The central focus was not simply producing dashboards, but building a traceable analytical approach that supports more defensible reporting and clearer business decisions.

*The case study reflects an independent portfolio simulation. All business records and financial figures are synthetic, and no production deployment or realized financial outcomes are claimed.*
