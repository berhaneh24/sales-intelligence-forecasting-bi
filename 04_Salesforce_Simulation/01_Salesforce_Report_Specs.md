# Salesforce Opportunity Reporting Design

**Portfolio Simulation | Synthetic CRM Data**

This reporting design shows how Salesforce opportunity data can support pipeline visibility, forecast reviews, quota planning, and sales leadership reporting.

## Q3 Open Pipeline by Opportunity Owner

**Business Purpose**  
Give sales leadership a clear view of FY2026 Q3 open pipeline by Opportunity Owner for pipeline reviews, forecast discussions, and QBR preparation.

**Report Type**  
Opportunities

**Fields**
- Opportunity ID
- Opportunity Name
- Opportunity Owner
- Sales Manager
- Region
- Segment
- Product Family
- Stage
- Forecast Category
- Amount
- Probability (%)
- Weighted Pipeline
- Close Date
- Fiscal Quarter
- Data Quality Status

**Filters**
- Open Opportunities
- Fiscal Quarter: FY2026-Q3
- Data Quality Status: Pass

**Groupings**
- Opportunity Owner
- Region

**Measures**
- Open Pipeline
- Weighted Pipeline
- Opportunity Count
- Average Deal Size
- Pipeline Coverage

**How It Will Be Used**  
Helps leadership identify pipeline coverage gaps, concentration risk, and reps that may need additional pipeline development or forecast review.


---

## Forecast Risk / Commit Review

**Business Purpose**  
Give sales leadership a focused view of open opportunities where deal activity, stage progression, close-date movement, or forecast history may not support the current forecast position.

**Salesforce-Style Source**  
Opportunities + Opportunity History

**Fields**
- Opportunity ID
- Opportunity Name
- Opportunity Owner
- Sales Manager
- Region
- Segment
- Stage
- Forecast Category
- Amount
- Weighted Pipeline
- Close Date
- Last Activity Date
- Close-Date Pushes
- Forecast Downgrades
- Forecast Risk Score
- Risk Level
- Risk Driver

**Filters**
- Open Opportunities
- Data Quality Status: Pass
- Forecast Risk Score: 2 or higher

**Groupings**
- Risk Level
- Opportunity Owner

**Measures**
- At-Risk Opportunity Count
- At-Risk Pipeline
- At-Risk Weighted Pipeline
- Share of Weighted Pipeline at Risk

**How It Will Be Used**  
Helps leadership prioritize forecast review discussions, challenge questionable Commit or Best Case positions, validate close-date credibility, and identify deals requiring follow-up before forecast calls or QBR reviews.


---

## Salesforce Data Quality / Hygiene Review

**Business Purpose**  
Surface opportunity records that could reduce confidence in pipeline and forecast reporting so data issues can be reviewed before leadership reporting and QBR discussions.

**Salesforce-Style Source**  
Opportunities

**Fields**
- Opportunity ID
- Opportunity Name
- Opportunity Owner
- Sales Manager
- Stage
- Forecast Category
- Amount
- Close Date
- Last Activity Date
- Next Step
- Data Quality Status

**Data Quality Checks**
- Missing Opportunity Owner
- Missing or invalid Close Date
- Missing Next Step
- Stale opportunity activity
- Stage / forecast category inconsistency
- Duplicate opportunity records

**Filters**
- Data Quality Status: Review Required

**Groupings**
- Data Quality Issue
- Opportunity Owner

**Measures**
- Records Requiring Review
- Pipeline Value Affected
- Percentage of Opportunity Records Requiring Review

**How It Will Be Used**  
Helps Sales Operations and sales leadership identify CRM hygiene issues that could affect pipeline visibility, forecast confidence, and downstream reporting.


---

## Quota Attainment / Pipeline Coverage Review

**Business Purpose**  
Give sales leadership a consolidated view of quota performance and forward pipeline coverage by sales representative to identify attainment risk and areas requiring additional pipeline development.

**Salesforce-Style Source**  
Opportunities + Forecasting Quotas

**Fields**
- Opportunity Owner
- Sales Manager
- Region
- Quota
- Bookings
- Quota Attainment (%)
- Open Pipeline
- Weighted Pipeline
- Gross Pipeline Coverage
- Weighted Pipeline Coverage
- Performance Status

**Filters**
- Fiscal Quarter: FY2026-Q3
- Data Quality Status: Pass

**Groupings**
- Opportunity Owner
- Region

**Measures**
- Total Quota
- Total Bookings
- Quota Attainment (%)
- Open Pipeline
- Weighted Pipeline
- Gross Pipeline Coverage
- Weighted Pipeline Coverage

**How It Will Be Used**  
Helps leadership identify reps that are below quota, evaluate whether remaining pipeline is sufficient to close performance gaps, and focus pipeline-generation or deal-review discussions where additional attention is needed.