USE sales_intelligence_bi;

-- ============================================================
-- SALES INTELLIGENCE ANALYSIS
-- Analyze pipeline, weighted pipeline, quota attainment,
-- coverage, bookings, win/loss performance, and forecast risk.
-- ============================================================

-- Establish the reported open-pipeline baseline by forecast category.
SELECT
    Forecast_Category,
    COUNT(*) AS open_opportunities,
    SUM(Opportunity_Amount) AS total_pipeline,
    SUM(Weighted_Pipeline) AS weighted_pipeline
FROM vw_opportunities_trusted
WHERE Status = 'Open'
GROUP BY Forecast_Category
ORDER BY total_pipeline DESC;

-- Compare clean and quality-flagged open pipeline by forecast category.
SELECT
    Forecast_Category,
    quality_status,
    COUNT(*) AS open_opportunities,
    SUM(Opportunity_Amount) AS total_pipeline,
    SUM(Weighted_Pipeline) AS weighted_pipeline
FROM vw_opportunities_trusted
WHERE Status = 'Open'
GROUP BY
    Forecast_Category,
    quality_status
ORDER BY
    Forecast_Category,
    quality_status;
    
-- Summarize clean versus review-required open pipeline.
SELECT
    quality_status,
    COUNT(*) AS open_opportunities,
    SUM(Opportunity_Amount) AS total_pipeline,
    SUM(Weighted_Pipeline) AS weighted_pipeline
FROM vw_opportunities_trusted
WHERE Status = 'Open'
GROUP BY quality_status
ORDER BY total_pipeline DESC;

-- Analyze validated open pipeline by region.
SELECT
    Region,
    COUNT(*) AS open_opportunities,
    SUM(Opportunity_Amount) AS total_pipeline,
    SUM(Weighted_Pipeline) AS weighted_pipeline
FROM vw_opportunities_trusted
WHERE Status = 'Open'
  AND quality_status = 'Pass'
GROUP BY Region
ORDER BY total_pipeline DESC;

-- Analyze validated open pipeline by customer segment.
SELECT
    Segment,
    COUNT(*) AS open_opportunities,
    SUM(Opportunity_Amount) AS total_pipeline,
    SUM(Weighted_Pipeline) AS weighted_pipeline
FROM vw_opportunities_trusted
WHERE Status = 'Open'
  AND quality_status = 'Pass'
GROUP BY Segment
ORDER BY total_pipeline DESC;

-- Analyze validated open pipeline by product family.
SELECT
    p.Product_Family,
    COUNT(*) AS open_opportunities,
    SUM(o.Opportunity_Amount) AS total_pipeline,
    SUM(o.Weighted_Pipeline) AS weighted_pipeline
FROM vw_opportunities_trusted AS o
INNER JOIN products AS p
    ON o.Product_ID = p.Product_ID
WHERE o.Status = 'Open'
  AND o.quality_status = 'Pass'
GROUP BY p.Product_Family
ORDER BY total_pipeline DESC;

-- Analyze validated open pipeline by sales representative.
SELECT
    s.Sales_Rep_ID,
    s.Sales_Rep_Name,
    s.Region,
    COUNT(*) AS open_opportunities,
    SUM(o.Opportunity_Amount) AS total_pipeline,
    SUM(o.Weighted_Pipeline) AS weighted_pipeline
FROM vw_opportunities_trusted AS o
INNER JOIN sales_reps AS s
    ON o.Sales_Rep_ID = s.Sales_Rep_ID
WHERE o.Status = 'Open'
  AND o.quality_status = 'Pass'
GROUP BY
    s.Sales_Rep_ID,
    s.Sales_Rep_Name,
    s.Region
ORDER BY total_pipeline DESC;

-- Summarize quota by sales representative.
SELECT
    s.Sales_Rep_ID,
    s.Sales_Rep_Name,
    s.Region,
    COUNT(q.Quota_ID) AS quota_periods,
    SUM(CAST(q.Monthly_Quota AS DECIMAL(18,2))) AS total_quota
FROM sales_reps AS s
INNER JOIN quotas AS q
    ON s.Sales_Rep_ID = q.Sales_Rep_ID
GROUP BY
    s.Sales_Rep_ID,
    s.Sales_Rep_Name,
    s.Region
ORDER BY total_quota DESC;

-- Validate quota date coverage before calculating pipeline coverage.
SELECT
    MIN(STR_TO_DATE(Quota_Month, '%Y-%m-%d')) AS first_quota_month,
    MAX(STR_TO_DATE(Quota_Month, '%Y-%m-%d')) AS last_quota_month,
    COUNT(DISTINCT Quota_Month) AS distinct_quota_months
FROM quotas;

-- Profile quota periods by fiscal quarter before calculating coverage.
SELECT
    Fiscal_Quarter,
    MIN(STR_TO_DATE(Quota_Month, '%Y-%m-%d')) AS first_month,
    MAX(STR_TO_DATE(Quota_Month, '%Y-%m-%d')) AS last_month,
    COUNT(DISTINCT Quota_Month) AS months_in_quarter,
    COUNT(DISTINCT Sales_Rep_ID) AS sales_reps,
    SUM(CAST(Monthly_Quota AS DECIMAL(18,2))) AS total_quota
FROM quotas
GROUP BY Fiscal_Quarter
ORDER BY first_month;

-- Calculate validated FY2026-Q3 pipeline coverage.
WITH q3_pipeline AS (
    SELECT
        SUM(Opportunity_Amount) AS total_pipeline,
        SUM(Weighted_Pipeline) AS weighted_pipeline
    FROM vw_opportunities_trusted
    WHERE Status = 'Open'
      AND quality_status = 'Pass'
      AND Expected_Close_Date BETWEEN '2026-07-01' AND '2026-09-30'
),

q3_quota AS (
    SELECT
        SUM(CAST(Monthly_Quota AS DECIMAL(18,2))) AS total_quota
    FROM quotas
    WHERE Fiscal_Quarter = 'FY2026-Q3'
)

SELECT
    p.total_pipeline,
    p.weighted_pipeline,
    q.total_quota,

    ROUND(
        p.total_pipeline / NULLIF(q.total_quota, 0),
        2
    ) AS gross_pipeline_coverage,

    ROUND(
        p.weighted_pipeline / NULLIF(q.total_quota, 0),
        2
    ) AS weighted_pipeline_coverage

FROM q3_pipeline AS p
CROSS JOIN q3_quota AS q;

-- Calculate FY2026-Q3 pipeline coverage by sales representative.
WITH rep_pipeline AS (
    SELECT
        Sales_Rep_ID,
        SUM(Opportunity_Amount) AS total_pipeline,
        SUM(Weighted_Pipeline) AS weighted_pipeline
    FROM vw_opportunities_trusted
    WHERE Status = 'Open'
      AND quality_status = 'Pass'
      AND Expected_Close_Date BETWEEN '2026-07-01' AND '2026-09-30'
    GROUP BY Sales_Rep_ID
),

rep_quota AS (
    SELECT
        Sales_Rep_ID,
        SUM(CAST(Monthly_Quota AS DECIMAL(18,2))) AS total_quota
    FROM quotas
    WHERE Fiscal_Quarter = 'FY2026-Q3'
    GROUP BY Sales_Rep_ID
)

SELECT
    s.Sales_Rep_ID,
    s.Sales_Rep_Name,
    s.Region,

    COALESCE(p.total_pipeline, 0) AS total_pipeline,
    COALESCE(p.weighted_pipeline, 0) AS weighted_pipeline,
    q.total_quota,

    ROUND(
        COALESCE(p.total_pipeline, 0) / NULLIF(q.total_quota, 0),
        2
    ) AS gross_pipeline_coverage,

    ROUND(
        COALESCE(p.weighted_pipeline, 0) / NULLIF(q.total_quota, 0),
        2
    ) AS weighted_pipeline_coverage

FROM sales_reps AS s
INNER JOIN rep_quota AS q
    ON s.Sales_Rep_ID = q.Sales_Rep_ID
LEFT JOIN rep_pipeline AS p
    ON s.Sales_Rep_ID = p.Sales_Rep_ID

ORDER BY weighted_pipeline_coverage ASC;

-- Validate FY2026-Q3 closed-won bookings before calculating quota attainment.
SELECT
    COUNT(*) AS won_opportunities,
    SUM(Opportunity_Amount) AS total_bookings
FROM vw_opportunities_trusted
WHERE Status = 'Won'
  AND quality_status = 'Pass'
  AND Actual_Close_Date BETWEEN '2026-07-01' AND '2026-09-30';
  
-- Check for Q3 wins dated after the reporting snapshot.
SELECT
    COUNT(*) AS future_won_opportunities,
    SUM(Opportunity_Amount) AS future_bookings
FROM vw_opportunities_trusted
WHERE Status = 'Won'
  AND quality_status = 'Pass'
  AND Actual_Close_Date > '2026-08-17'
  AND Actual_Close_Date <= '2026-09-30';
  
-- Calculate FY2026-Q3 quota attainment as of the reporting snapshot.
WITH q3_bookings AS (
    SELECT
        SUM(Opportunity_Amount) AS total_bookings
    FROM vw_opportunities_trusted
    WHERE Status = 'Won'
      AND quality_status = 'Pass'
      AND Actual_Close_Date BETWEEN '2026-07-01' AND '2026-08-17'
),

q3_quota AS (
    SELECT
        SUM(CAST(Monthly_Quota AS DECIMAL(18,2))) AS total_quota
    FROM quotas
    WHERE Fiscal_Quarter = 'FY2026-Q3'
)

SELECT
    b.total_bookings,
    q.total_quota,

    ROUND(
        b.total_bookings / NULLIF(q.total_quota, 0),
        4
    ) AS quota_attainment_ratio,

    ROUND(
        (b.total_bookings / NULLIF(q.total_quota, 0)) * 100,
        2
    ) AS quota_attainment_pct

FROM q3_bookings AS b
CROSS JOIN q3_quota AS q;

-- Calculate FY2026-Q3 quota attainment by sales representative.
WITH rep_bookings AS (
    SELECT
        Sales_Rep_ID,
        SUM(Opportunity_Amount) AS total_bookings
    FROM vw_opportunities_trusted
    WHERE Status = 'Won'
      AND quality_status = 'Pass'
      AND Actual_Close_Date BETWEEN '2026-07-01' AND '2026-08-17'
    GROUP BY Sales_Rep_ID
),

rep_quota AS (
    SELECT
        Sales_Rep_ID,
        SUM(CAST(Monthly_Quota AS DECIMAL(18,2))) AS total_quota
    FROM quotas
    WHERE Fiscal_Quarter = 'FY2026-Q3'
    GROUP BY Sales_Rep_ID
)

SELECT
    s.Sales_Rep_ID,
    s.Sales_Rep_Name,
    s.Region,
    COALESCE(b.total_bookings, 0) AS total_bookings,
    q.total_quota,

    ROUND(
        COALESCE(b.total_bookings, 0) / NULLIF(q.total_quota, 0),
        4
    ) AS quota_attainment_ratio,

    ROUND(
        (COALESCE(b.total_bookings, 0) / NULLIF(q.total_quota, 0)) * 100,
        2
    ) AS quota_attainment_pct

FROM sales_reps AS s
INNER JOIN rep_quota AS q
    ON s.Sales_Rep_ID = q.Sales_Rep_ID
LEFT JOIN rep_bookings AS b
    ON s.Sales_Rep_ID = b.Sales_Rep_ID

ORDER BY quota_attainment_pct ASC;

-- Combine Q3 quota attainment and weighted pipeline coverage by rep.
WITH rep_bookings AS (
    SELECT
        Sales_Rep_ID,
        SUM(Opportunity_Amount) AS total_bookings
    FROM vw_opportunities_trusted
    WHERE Status = 'Won'
      AND quality_status = 'Pass'
      AND Actual_Close_Date BETWEEN '2026-07-01' AND '2026-08-17'
    GROUP BY Sales_Rep_ID
),

rep_pipeline AS (
    SELECT
        Sales_Rep_ID,
        SUM(Opportunity_Amount) AS total_pipeline,
        SUM(Weighted_Pipeline) AS weighted_pipeline
    FROM vw_opportunities_trusted
    WHERE Status = 'Open'
      AND quality_status = 'Pass'
      AND Expected_Close_Date BETWEEN '2026-07-01' AND '2026-09-30'
    GROUP BY Sales_Rep_ID
),

rep_quota AS (
    SELECT
        Sales_Rep_ID,
        SUM(CAST(Monthly_Quota AS DECIMAL(18,2))) AS total_quota
    FROM quotas
    WHERE Fiscal_Quarter = 'FY2026-Q3'
    GROUP BY Sales_Rep_ID
)

SELECT
    s.Sales_Rep_ID,
    s.Sales_Rep_Name,
    s.Region,

    COALESCE(b.total_bookings, 0) AS total_bookings,
    q.total_quota,
    COALESCE(p.weighted_pipeline, 0) AS weighted_pipeline,

    ROUND(
        COALESCE(b.total_bookings, 0)
        / NULLIF(q.total_quota, 0) * 100,
        2
    ) AS quota_attainment_pct,

    ROUND(
        COALESCE(p.weighted_pipeline, 0)
        / NULLIF(q.total_quota, 0),
        2
    ) AS weighted_pipeline_coverage,

   CASE
    WHEN COALESCE(b.total_bookings, 0) / NULLIF(q.total_quota, 0) < 1
     AND COALESCE(p.weighted_pipeline, 0) / NULLIF(q.total_quota, 0) < 1
        THEN 'High Risk'

    WHEN COALESCE(b.total_bookings, 0) / NULLIF(q.total_quota, 0) < 1
        THEN 'Attainment Risk'

    WHEN COALESCE(b.total_bookings, 0) / NULLIF(q.total_quota, 0) >= 1
     AND COALESCE(p.weighted_pipeline, 0) / NULLIF(q.total_quota, 0) < 1
        THEN 'Above Quota / Thin Forward Pipeline'

    ELSE 'On / Above Quota'
END AS performance_status

FROM sales_reps AS s

INNER JOIN rep_quota AS q
    ON s.Sales_Rep_ID = q.Sales_Rep_ID

LEFT JOIN rep_bookings AS b
    ON s.Sales_Rep_ID = b.Sales_Rep_ID

LEFT JOIN rep_pipeline AS p
    ON s.Sales_Rep_ID = p.Sales_Rep_ID

ORDER BY
    CASE
        WHEN COALESCE(b.total_bookings, 0) / NULLIF(q.total_quota, 0) < 1
         AND COALESCE(p.weighted_pipeline, 0) / NULLIF(q.total_quota, 0) < 1
            THEN 1

        WHEN COALESCE(b.total_bookings, 0) / NULLIF(q.total_quota, 0) < 1
            THEN 2

        WHEN COALESCE(b.total_bookings, 0) / NULLIF(q.total_quota, 0) >= 1
         AND COALESCE(p.weighted_pipeline, 0) / NULLIF(q.total_quota, 0) < 1
            THEN 3

        ELSE 4
    END,
    quota_attainment_pct;
    
-- Analyze validated closed opportunities and overall win rate.
SELECT
    Status,
    COUNT(*) AS closed_opportunities,
    SUM(Opportunity_Amount) AS closed_amount
FROM vw_opportunities_trusted
WHERE Status IN ('Won', 'Lost')
  AND quality_status = 'Pass'
GROUP BY Status
ORDER BY closed_amount DESC;

-- Calculate overall validated win rate by opportunity count and dollar value.
SELECT
    COUNT(*) AS total_closed_opportunities,

    SUM(CASE WHEN Status = 'Won' THEN 1 ELSE 0 END) AS won_opportunities,

    SUM(CASE WHEN Status = 'Lost' THEN 1 ELSE 0 END) AS lost_opportunities,

    ROUND(
        SUM(CASE WHEN Status = 'Won' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0) * 100,
        2
    ) AS win_rate_pct,

    SUM(Opportunity_Amount) AS total_closed_amount,

    SUM(
        CASE
            WHEN Status = 'Won' THEN Opportunity_Amount
            ELSE 0
        END
    ) AS won_amount,

    ROUND(
        SUM(
            CASE
                WHEN Status = 'Won' THEN Opportunity_Amount
                ELSE 0
            END
        )
        / NULLIF(SUM(Opportunity_Amount), 0) * 100,
        2
    ) AS dollar_win_rate_pct

FROM vw_opportunities_trusted
WHERE Status IN ('Won', 'Lost')
  AND quality_status = 'Pass';
  
-- Analyze validated closed opportunities by win/loss reason.
SELECT
    Status,
    Win_Loss_Reason,
    COUNT(*) AS closed_opportunities,
    SUM(Opportunity_Amount) AS closed_amount
FROM vw_opportunities_trusted
WHERE Status IN ('Won', 'Lost')
  AND quality_status = 'Pass'
  AND Win_Loss_Reason IS NOT NULL
  AND TRIM(Win_Loss_Reason) <> ''
GROUP BY
    Status,
    Win_Loss_Reason
ORDER BY
    Status,
    closed_amount DESC;
    
-- Analyze validated win rate by customer segment.
SELECT
    Segment,

    COUNT(*) AS total_closed_opportunities,

    SUM(
        CASE
            WHEN Status = 'Won' THEN 1
            ELSE 0
        END
    ) AS won_opportunities,

    SUM(
        CASE
            WHEN Status = 'Lost' THEN 1
            ELSE 0
        END
    ) AS lost_opportunities,

    ROUND(
        SUM(CASE WHEN Status = 'Won' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0) * 100,
        2
    ) AS win_rate_pct,

    SUM(Opportunity_Amount) AS total_closed_amount,

    SUM(
        CASE
            WHEN Status = 'Won' THEN Opportunity_Amount
            ELSE 0
        END
    ) AS won_amount

FROM vw_opportunities_trusted
WHERE Status IN ('Won', 'Lost')
  AND quality_status = 'Pass'
GROUP BY Segment
ORDER BY win_rate_pct DESC;

-- Analyze validated win rate by product family.
SELECT
    p.Product_Family,

    COUNT(*) AS total_closed_opportunities,

    SUM(
        CASE
            WHEN o.Status = 'Won' THEN 1
            ELSE 0
        END
    ) AS won_opportunities,

    SUM(
        CASE
            WHEN o.Status = 'Lost' THEN 1
            ELSE 0
        END
    ) AS lost_opportunities,

    ROUND(
        SUM(CASE WHEN o.Status = 'Won' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0) * 100,
        2
    ) AS win_rate_pct,

    SUM(o.Opportunity_Amount) AS total_closed_amount,

    SUM(
        CASE
            WHEN o.Status = 'Won' THEN o.Opportunity_Amount
            ELSE 0
        END
    ) AS won_amount

FROM vw_opportunities_trusted AS o

INNER JOIN products AS p
    ON o.Product_ID = p.Product_ID

WHERE o.Status IN ('Won', 'Lost')
  AND o.quality_status = 'Pass'

GROUP BY p.Product_Family

ORDER BY win_rate_pct DESC;

-- Analyze validated win rate by sales representative.
SELECT
    s.Sales_Rep_ID,
    s.Sales_Rep_Name,
    s.Region,

    COUNT(*) AS total_closed_opportunities,

    SUM(
        CASE
            WHEN o.Status = 'Won' THEN 1
            ELSE 0
        END
    ) AS won_opportunities,

    SUM(
        CASE
            WHEN o.Status = 'Lost' THEN 1
            ELSE 0
        END
    ) AS lost_opportunities,

    ROUND(
        SUM(CASE WHEN o.Status = 'Won' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0) * 100,
        2
    ) AS win_rate_pct,

    SUM(o.Opportunity_Amount) AS total_closed_amount,

    SUM(
        CASE
            WHEN o.Status = 'Won' THEN o.Opportunity_Amount
            ELSE 0
        END
    ) AS won_amount

FROM vw_opportunities_trusted AS o

INNER JOIN sales_reps AS s
    ON o.Sales_Rep_ID = s.Sales_Rep_ID

WHERE o.Status IN ('Won', 'Lost')
  AND o.quality_status = 'Pass'

GROUP BY
    s.Sales_Rep_ID,
    s.Sales_Rep_Name,
    s.Region

ORDER BY win_rate_pct DESC;

-- Profile current validated open pipeline by forecast category and stage.
SELECT
    Forecast_Category,
    Stage,
    COUNT(*) AS open_opportunities,
    SUM(Opportunity_Amount) AS total_pipeline,
    SUM(Weighted_Pipeline) AS weighted_pipeline
FROM vw_opportunities_trusted
WHERE Status = 'Open'
  AND quality_status = 'Pass'
GROUP BY
    Forecast_Category,
    Stage
ORDER BY
    Forecast_Category,
    total_pipeline DESC;
    
-- Stress-test forecast confidence against current sales-stage maturity.
SELECT
    CASE
        WHEN Forecast_Category = 'Commit'
             AND Stage IN ('Proposal', 'Negotiation')
            THEN 'Stage Aligned'

        WHEN Forecast_Category = 'Commit'
            THEN 'Review - Commit Stage Risk'

        WHEN Forecast_Category = 'Best Case'
             AND Stage IN ('Solution Validation', 'Proposal', 'Negotiation')
            THEN 'Stage Aligned'

        WHEN Forecast_Category = 'Best Case'
            THEN 'Review - Best Case Early Stage'

        WHEN Forecast_Category = 'Pipeline'
            THEN 'Stage Aligned'

        ELSE 'Review - Other'
    END AS forecast_stage_status,

    COUNT(*) AS open_opportunities,
    SUM(Opportunity_Amount) AS total_pipeline,
    SUM(Weighted_Pipeline) AS weighted_pipeline

FROM vw_opportunities_trusted

WHERE Status = 'Open'
  AND quality_status = 'Pass'

GROUP BY forecast_stage_status

ORDER BY total_pipeline DESC;

-- Assess stale validated open pipeline using the reporting snapshot date.
SELECT
    CASE
        WHEN Last_Activity_Date IS NULL
            THEN 'Review - Missing Activity Date'

        WHEN DATEDIFF(
            '2026-08-17',
            Last_Activity_Date
        ) > 90
            THEN 'Review - 90+ Days Stale'

        ELSE 'Recent Activity'
    END AS activity_status,

    COUNT(*) AS open_opportunities,
    SUM(Opportunity_Amount) AS total_pipeline,
    SUM(Weighted_Pipeline) AS weighted_pipeline

FROM vw_opportunities_trusted

WHERE Status = 'Open'
  AND quality_status = 'Pass'

GROUP BY activity_status

ORDER BY total_pipeline DESC;

-- Assess forecast risk from repeated expected-close-date pushes.
WITH ordered_history AS (
    SELECT
        Row_ID,
        Opportunity_ID,
        Change_Date,
        Expected_Close_Date,

        LAG(Expected_Close_Date) OVER (
            PARTITION BY Opportunity_ID
            ORDER BY
                STR_TO_DATE(Change_Date, '%Y-%m-%d'),
                Row_ID
        ) AS previous_expected_close_date

    FROM opportunity_history
),

push_counts AS (
    SELECT
        Opportunity_ID,
        COUNT(*) AS close_date_pushes

    FROM ordered_history

    WHERE Expected_Close_Date IS NOT NULL
      AND TRIM(Expected_Close_Date) <> ''
      AND previous_expected_close_date IS NOT NULL
      AND TRIM(previous_expected_close_date) <> ''

      AND STR_TO_DATE(Expected_Close_Date, '%Y-%m-%d')
          >
          STR_TO_DATE(previous_expected_close_date, '%Y-%m-%d')

    GROUP BY Opportunity_ID
)

SELECT
    CASE
        WHEN COALESCE(p.close_date_pushes, 0) >= 3
            THEN 'Review - 3+ Close-Date Pushes'

        ELSE '0-2 Close-Date Pushes'
    END AS close_date_push_status,

    COUNT(*) AS open_opportunities,
    SUM(o.Opportunity_Amount) AS total_pipeline,
    SUM(o.Weighted_Pipeline) AS weighted_pipeline

FROM vw_opportunities_trusted AS o

LEFT JOIN push_counts AS p
    ON o.Opportunity_ID = p.Opportunity_ID

WHERE o.Status = 'Open'
  AND o.quality_status = 'Pass'

GROUP BY close_date_push_status

ORDER BY total_pipeline DESC;

-- Assess forecast risk from repeated forecast-category downgrades.
WITH ordered_history AS (
    SELECT
        Row_ID,
        Opportunity_ID,
        Change_Date,
        Forecast_Category,

        LAG(Forecast_Category) OVER (
            PARTITION BY Opportunity_ID
            ORDER BY
                STR_TO_DATE(Change_Date, '%Y-%m-%d'),
                Row_ID
        ) AS previous_forecast_category

    FROM opportunity_history
),

downgrades AS (
    SELECT
        Opportunity_ID

    FROM ordered_history

    WHERE
        (
            previous_forecast_category = 'Commit'
            AND Forecast_Category IN ('Best Case', 'Pipeline')
        )

        OR
        (
            previous_forecast_category = 'Best Case'
            AND Forecast_Category = 'Pipeline'
        )
),

downgrade_counts AS (
    SELECT
        Opportunity_ID,
        COUNT(*) AS downgrade_count

    FROM downgrades

    GROUP BY Opportunity_ID
)

SELECT
    CASE
        WHEN COALESCE(d.downgrade_count, 0) >= 2
            THEN 'Review - 2+ Forecast Downgrades'

        ELSE '0-1 Forecast Downgrades'
    END AS downgrade_status,

    COUNT(*) AS open_opportunities,
    SUM(o.Opportunity_Amount) AS total_pipeline,
    SUM(o.Weighted_Pipeline) AS weighted_pipeline

FROM vw_opportunities_trusted AS o

LEFT JOIN downgrade_counts AS d
    ON o.Opportunity_ID = d.Opportunity_ID

WHERE o.Status = 'Open'
  AND o.quality_status = 'Pass'

GROUP BY downgrade_status

ORDER BY total_pipeline DESC;

-- Build a combined forecast-risk model for validated open opportunities.
WITH ordered_history AS (
    SELECT
        Row_ID,
        Opportunity_ID,
        Change_Date,
        Expected_Close_Date,
        Forecast_Category,

        LAG(Expected_Close_Date) OVER (
            PARTITION BY Opportunity_ID
            ORDER BY STR_TO_DATE(Change_Date, '%Y-%m-%d'), Row_ID
        ) AS previous_expected_close_date,

        LAG(Forecast_Category) OVER (
            PARTITION BY Opportunity_ID
            ORDER BY STR_TO_DATE(Change_Date, '%Y-%m-%d'), Row_ID
        ) AS previous_forecast_category

    FROM opportunity_history
),

history_signals AS (
    SELECT
        Opportunity_ID,

        SUM(
            CASE
                WHEN Expected_Close_Date IS NOT NULL
                 AND previous_expected_close_date IS NOT NULL
                 AND STR_TO_DATE(Expected_Close_Date, '%Y-%m-%d')
                     > STR_TO_DATE(previous_expected_close_date, '%Y-%m-%d')
                    THEN 1
                ELSE 0
            END
        ) AS close_date_pushes,

        SUM(
            CASE
                WHEN previous_forecast_category = 'Commit'
                 AND Forecast_Category IN ('Best Case', 'Pipeline')
                    THEN 1

                WHEN previous_forecast_category = 'Best Case'
                 AND Forecast_Category = 'Pipeline'
                    THEN 1

                ELSE 0
            END
        ) AS forecast_downgrades

    FROM ordered_history
    GROUP BY Opportunity_ID
),

risk_flags AS (
    SELECT
        o.Opportunity_ID,
        o.Opportunity_Name,
        o.Sales_Rep_ID,
        o.Region,
        o.Segment,
        o.Product_ID,
        o.Stage,
        o.Forecast_Category,
        o.Opportunity_Amount,
        o.Weighted_Pipeline,
        o.Expected_Close_Date,
        o.Last_Activity_Date,
        o.Next_Step,

        COALESCE(h.close_date_pushes, 0) AS close_date_pushes,
        COALESCE(h.forecast_downgrades, 0) AS forecast_downgrades,

        CASE
            WHEN o.Forecast_Category = 'Commit'
             AND o.Stage NOT IN ('Proposal', 'Negotiation')
                THEN 1

            WHEN o.Forecast_Category = 'Best Case'
             AND o.Stage NOT IN (
                 'Solution Validation',
                 'Proposal',
                 'Negotiation'
             )
                THEN 1

            ELSE 0
        END AS flag_stage_risk,

        CASE
            WHEN o.Last_Activity_Date IS NULL
              OR DATEDIFF('2026-08-17', o.Last_Activity_Date) > 90
                THEN 1
            ELSE 0
        END AS flag_stale_activity,

        CASE
            WHEN COALESCE(h.close_date_pushes, 0) >= 3
                THEN 1
            ELSE 0
        END AS flag_close_date_push_risk,

        CASE
            WHEN COALESCE(h.forecast_downgrades, 0) >= 2
                THEN 1
            ELSE 0
        END AS flag_downgrade_risk

    FROM vw_opportunities_trusted AS o

    LEFT JOIN history_signals AS h
        ON o.Opportunity_ID = h.Opportunity_ID

    WHERE o.Status = 'Open'
      AND o.quality_status = 'Pass'
),

risk_scored AS (
    SELECT
        *,

        (
            flag_stage_risk
            + flag_stale_activity
            + flag_close_date_push_risk
            + flag_downgrade_risk
        ) AS forecast_risk_score

    FROM risk_flags
)

SELECT
    CASE
        WHEN forecast_risk_score >= 3 THEN 'High Risk'
        WHEN forecast_risk_score = 2 THEN 'Medium Risk'
        WHEN forecast_risk_score = 1 THEN 'Watch'
        ELSE 'Low Risk'
    END AS forecast_risk_level,

    COUNT(*) AS open_opportunities,
    SUM(Opportunity_Amount) AS total_pipeline,
    SUM(Weighted_Pipeline) AS weighted_pipeline

FROM risk_scored

GROUP BY forecast_risk_level

ORDER BY
    CASE forecast_risk_level
        WHEN 'High Risk' THEN 1
        WHEN 'Medium Risk' THEN 2
        WHEN 'Watch' THEN 3
        ELSE 4
    END;
    
-- Reconcile trusted open-pipeline totals before finalizing forecast risk.
SELECT
    COUNT(*) AS open_opportunities,
    SUM(Opportunity_Amount) AS total_pipeline,
    SUM(Weighted_Pipeline) AS weighted_pipeline
FROM vw_opportunities_trusted
WHERE Status = 'Open'
  AND quality_status = 'Pass';
  
-- QA the combined forecast-risk population before risk-level grouping.
WITH ordered_history AS (
    SELECT
        Row_ID,
        Opportunity_ID,
        Change_Date,
        Expected_Close_Date,
        Forecast_Category,

        LAG(Expected_Close_Date) OVER (
            PARTITION BY Opportunity_ID
            ORDER BY STR_TO_DATE(Change_Date, '%Y-%m-%d'), Row_ID
        ) AS previous_expected_close_date,

        LAG(Forecast_Category) OVER (
            PARTITION BY Opportunity_ID
            ORDER BY STR_TO_DATE(Change_Date, '%Y-%m-%d'), Row_ID
        ) AS previous_forecast_category

    FROM opportunity_history
),

history_signals AS (
    SELECT
        Opportunity_ID,

        SUM(
            CASE
                WHEN Expected_Close_Date IS NOT NULL
                 AND previous_expected_close_date IS NOT NULL
                 AND STR_TO_DATE(Expected_Close_Date, '%Y-%m-%d')
                     > STR_TO_DATE(previous_expected_close_date, '%Y-%m-%d')
                    THEN 1
                ELSE 0
            END
        ) AS close_date_pushes,

        SUM(
            CASE
                WHEN previous_forecast_category = 'Commit'
                 AND Forecast_Category IN ('Best Case', 'Pipeline')
                    THEN 1

                WHEN previous_forecast_category = 'Best Case'
                 AND Forecast_Category = 'Pipeline'
                    THEN 1

                ELSE 0
            END
        ) AS forecast_downgrades

    FROM ordered_history
    GROUP BY Opportunity_ID
),

risk_flags AS (
    SELECT
        o.Opportunity_ID,
        o.Opportunity_Amount,
        o.Weighted_Pipeline,

        COALESCE(h.close_date_pushes, 0) AS close_date_pushes,
        COALESCE(h.forecast_downgrades, 0) AS forecast_downgrades

    FROM vw_opportunities_trusted AS o

    LEFT JOIN history_signals AS h
        ON o.Opportunity_ID = h.Opportunity_ID

    WHERE o.Status = 'Open'
      AND o.quality_status = 'Pass'
)

SELECT
    COUNT(*) AS risk_rows,
    COUNT(DISTINCT Opportunity_ID) AS unique_opportunities,
    SUM(Opportunity_Amount) AS total_pipeline,
    SUM(Weighted_Pipeline) AS weighted_pipeline
FROM risk_flags;

-- QA totals after calculating the forecast risk score.
WITH ordered_history AS (
    SELECT
        Row_ID,
        Opportunity_ID,
        Change_Date,
        Expected_Close_Date,
        Forecast_Category,

        LAG(Expected_Close_Date) OVER (
            PARTITION BY Opportunity_ID
            ORDER BY STR_TO_DATE(Change_Date, '%Y-%m-%d'), Row_ID
        ) AS previous_expected_close_date,

        LAG(Forecast_Category) OVER (
            PARTITION BY Opportunity_ID
            ORDER BY STR_TO_DATE(Change_Date, '%Y-%m-%d'), Row_ID
        ) AS previous_forecast_category

    FROM opportunity_history
),

history_signals AS (
    SELECT
        Opportunity_ID,

        SUM(
            CASE
                WHEN Expected_Close_Date IS NOT NULL
                 AND previous_expected_close_date IS NOT NULL
                 AND STR_TO_DATE(Expected_Close_Date, '%Y-%m-%d')
                     > STR_TO_DATE(previous_expected_close_date, '%Y-%m-%d')
                    THEN 1
                ELSE 0
            END
        ) AS close_date_pushes,

        SUM(
            CASE
                WHEN previous_forecast_category = 'Commit'
                 AND Forecast_Category IN ('Best Case', 'Pipeline')
                    THEN 1

                WHEN previous_forecast_category = 'Best Case'
                 AND Forecast_Category = 'Pipeline'
                    THEN 1

                ELSE 0
            END
        ) AS forecast_downgrades

    FROM ordered_history
    GROUP BY Opportunity_ID
),

risk_flags AS (
    SELECT
        o.*,
        
        COALESCE(h.close_date_pushes, 0) AS close_date_pushes,
		COALESCE(h.forecast_downgrades, 0) AS forecast_downgrades,

        CASE
            WHEN o.Forecast_Category = 'Commit'
             AND o.Stage NOT IN ('Proposal', 'Negotiation')
                THEN 1

            WHEN o.Forecast_Category = 'Best Case'
             AND o.Stage NOT IN (
                 'Solution Validation',
                 'Proposal',
                 'Negotiation'
             )
                THEN 1

            ELSE 0
        END AS flag_stage_risk,

        CASE
            WHEN o.Last_Activity_Date IS NULL
              OR DATEDIFF('2026-08-17', o.Last_Activity_Date) > 90
                THEN 1
            ELSE 0
        END AS flag_stale_activity,

        CASE
            WHEN COALESCE(h.close_date_pushes, 0) >= 3
                THEN 1
            ELSE 0
        END AS flag_close_date_push_risk,

        CASE
            WHEN COALESCE(h.forecast_downgrades, 0) >= 2
                THEN 1
            ELSE 0
        END AS flag_downgrade_risk

    FROM vw_opportunities_trusted AS o

    LEFT JOIN history_signals AS h
        ON o.Opportunity_ID = h.Opportunity_ID

    WHERE o.Status = 'Open'
      AND o.quality_status = 'Pass'
),

risk_scored AS (
    SELECT
        *,
        (
            flag_stage_risk
            + flag_stale_activity
            + flag_close_date_push_risk
            + flag_downgrade_risk
        ) AS forecast_risk_score

    FROM risk_flags
)

-- Identify the highest-priority opportunities for forecast review.
SELECT
    Opportunity_ID,
    Opportunity_Name,
    Sales_Rep_ID,
    Region,
    Segment,
    Stage,
    Forecast_Category,
    Opportunity_Amount,
    Weighted_Pipeline,
    Expected_Close_Date,
    Last_Activity_Date,
    close_date_pushes,
    forecast_downgrades,
    flag_stage_risk,
    flag_stale_activity,
    flag_close_date_push_risk,
    flag_downgrade_risk,
    forecast_risk_score
FROM risk_scored
WHERE forecast_risk_score >= 2
ORDER BY
    forecast_risk_score DESC,
    Opportunity_Amount DESC;

-- Check whether duplicate opportunity IDs contain different weighted-pipeline values.
SELECT
    Opportunity_ID,
    COUNT(*) AS duplicate_rows,

    MIN(CAST(Opportunity_Amount AS DECIMAL(18,2))) AS min_amount,
    MAX(CAST(Opportunity_Amount AS DECIMAL(18,2))) AS max_amount,

    MIN(CAST(Probability AS DECIMAL(6,2))) AS min_probability,
    MAX(CAST(Probability AS DECIMAL(6,2))) AS max_probability,

    MIN(CAST(Weighted_Pipeline AS DECIMAL(18,2))) AS min_weighted_pipeline,
    MAX(CAST(Weighted_Pipeline AS DECIMAL(18,2))) AS max_weighted_pipeline,

    MAX(CAST(Weighted_Pipeline AS DECIMAL(18,2)))
      - MIN(CAST(Weighted_Pipeline AS DECIMAL(18,2)))
        AS weighted_pipeline_difference

FROM opportunities

GROUP BY Opportunity_ID

HAVING COUNT(*) > 1

ORDER BY weighted_pipeline_difference DESC;