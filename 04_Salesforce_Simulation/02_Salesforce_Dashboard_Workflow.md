# Salesforce Sales Leadership Dashboard Design

**Portfolio Simulation | Synthetic CRM Data**

This dashboard design brings together pipeline, forecast risk, quota performance, and CRM data quality into a single sales leadership view. The goal is to support recurring forecast reviews, pipeline discussions, and QBR preparation with consistent, decision-ready reporting.

## Dashboard Audience

- Sales Leadership
- Sales Operations
- Revenue Operations
- Sales Managers

## Primary Business Questions

- Are we on track against quota?
- Is there enough pipeline to support the remaining target?
- Which opportunities create the greatest forecast risk?
- Which reps or regions require additional attention?
- Are CRM data-quality issues affecting forecast confidence?


## Dashboard Components

### Executive KPI Summary
Provides an at-a-glance view of overall sales performance and forecast position.

- Total Quota
- Total Bookings
- Quota Attainment (%)
- Open Pipeline
- Weighted Pipeline
- Gross Pipeline Coverage
- Weighted Pipeline Coverage

### Pipeline by Opportunity Owner
Shows open pipeline and weighted pipeline by Opportunity Owner to identify coverage gaps and concentration.

### Pipeline by Region
Compares pipeline position across regions and supports regional performance reviews.

### Forecast Risk
Highlights High Risk and Medium Risk opportunities based on stage alignment, stale activity, close-date movement, and forecast changes.

### Quota and Coverage Performance
Compares quota attainment and remaining pipeline coverage by Opportunity Owner.

### CRM Data Quality
Surfaces records requiring review because of missing, inconsistent, stale, or potentially unreliable CRM information.


## Dashboard Filters

- Fiscal Quarter
- Opportunity Owner
- Sales Manager
- Region
- Segment
- Product Family
- Stage
- Forecast Category
- Risk Level

## Drill-Down Workflow

Leadership can begin with the executive KPI summary, then drill into the area requiring attention.

- Quota concern → Opportunity Owner performance → individual open opportunities
- Pipeline concern → Region or Segment → Opportunity Owner → opportunity detail
- Forecast concern → Risk Level → flagged opportunities → risk drivers
- Data-quality concern → issue type → Opportunity Owner → affected records

## Review Workflow

1. Review overall quota attainment and pipeline coverage.
2. Identify reps, regions, or segments requiring attention.
3. Review forecast-risk opportunities and underlying risk drivers.
4. Validate CRM data-quality issues that could affect reporting confidence.
5. Assign follow-up actions to the appropriate sales rep or manager.
6. Revisit outstanding actions during the next forecast review or QBR cycle.


## Forecast Follow-Up and Governance

The reporting workflow is designed to move identified issues into clear ownership and follow-up rather than stopping at dashboard visibility.

### Follow-Up Actions

- Validate stage and forecast category alignment with the Opportunity Owner.
- Confirm current activity and next steps for stale opportunities.
- Reassess Close Date credibility for repeatedly pushed opportunities.
- Review forecast confidence where downgrade history indicates increased risk.
- Correct CRM data-quality issues before they affect recurring leadership reporting.

### Ownership

- Opportunity Owner: deal-level updates and next steps
- Sales Manager: escalation, forecast review, and high-risk opportunity follow-up
- Sales Operations / Revenue Operations: reporting validation, CRM hygiene, and recurring review
- Sales Leadership: prioritization and decision-making

### Reporting Control

Issues identified during forecast or pipeline reviews are documented, assigned, and revisited during the next review cycle until resolved or formally accepted.

This creates a repeatable process:

**Identify → Validate → Assign → Follow Up → Reassess**