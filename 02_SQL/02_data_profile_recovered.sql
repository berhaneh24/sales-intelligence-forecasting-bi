USE sales_intelligence_bi;

-- ============================================================
-- DATA PROFILING
-- Review record counts, business-key uniqueness, and source
-- quality before pipeline and forecast analysis.
-- ============================================================

-- Compare total rows with unique business IDs.
SELECT
    'accounts' AS table_name,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT Account_ID) AS distinct_business_ids
FROM accounts

UNION ALL

SELECT
    'sales_reps',
    COUNT(*),
    COUNT(DISTINCT Sales_Rep_ID)
FROM sales_reps

UNION ALL

SELECT
    'products',
    COUNT(*),
    COUNT(DISTINCT Product_ID)
FROM products

UNION ALL

SELECT
    'quotas',
    COUNT(*),
    COUNT(DISTINCT Quota_ID)
FROM quotas

UNION ALL

SELECT
    'opportunities',
    COUNT(*),
    COUNT(DISTINCT Opportunity_ID)
FROM opportunities

UNION ALL

SELECT
    'opportunity_history',
    COUNT(*),
    COUNT(DISTINCT History_ID)
FROM opportunity_history;


-- Identify repeated opportunity IDs for further review.
SELECT
    Opportunity_ID,
    COUNT(*) AS record_count
FROM opportunities
GROUP BY Opportunity_ID
HAVING COUNT(*) > 1
ORDER BY record_count DESC, Opportunity_ID;


-- Review repeated opportunity records before deciding how to handle them.
SELECT *
FROM opportunities
WHERE Opportunity_ID IN (
    SELECT Opportunity_ID
    FROM opportunities
    GROUP BY Opportunity_ID
    HAVING COUNT(*) > 1
)
ORDER BY Opportunity_ID, Row_ID;


-- Check whether repeated IDs are exact duplicate records.
SELECT
    Opportunity_ID,
    Opportunity_Name,
    Account_ID,
    Sales_Rep_ID,
    Product_ID,
    Segment,
    Region,
    Stage,
    Forecast_Category,
    Created_Date,
    Expected_Close_Date,
    Actual_Close_Date,
    Opportunity_Amount,
    Probability,
    Weighted_Pipeline,
    Fiscal_Quarter,
    Status,
    Win_Loss_Reason,
    Last_Activity_Date,
    Next_Step,
    COUNT(*) AS duplicate_count
FROM opportunities
GROUP BY
    Opportunity_ID,
    Opportunity_Name,
    Account_ID,
    Sales_Rep_ID,
    Product_ID,
    Segment,
    Region,
    Stage,
    Forecast_Category,
    Created_Date,
    Expected_Close_Date,
    Actual_Close_Date,
    Opportunity_Amount,
    Probability,
    Weighted_Pipeline,
    Fiscal_Quarter,
    Status,
    Win_Loss_Reason,
    Last_Activity_Date,
    Next_Step
HAVING COUNT(*) > 1
ORDER BY Opportunity_ID;


-- Quantify the potential reporting impact of exact duplicates.
SELECT
    Status,
    COUNT(*) AS affected_opportunities,
    SUM(CAST(Opportunity_Amount AS DECIMAL(18,2))) AS potential_overstatement
FROM (
    SELECT
        Opportunity_ID,
        Status,
        Opportunity_Amount
    FROM opportunities
    GROUP BY
        Opportunity_ID,
        Opportunity_Name,
        Account_ID,
        Sales_Rep_ID,
        Product_ID,
        Segment,
        Region,
        Stage,
        Forecast_Category,
        Created_Date,
        Expected_Close_Date,
        Actual_Close_Date,
        Opportunity_Amount,
        Probability,
        Weighted_Pipeline,
        Fiscal_Quarter,
        Status,
        Win_Loss_Reason,
        Last_Activity_Date,
        Next_Step
    HAVING COUNT(*) > 1
) AS duplicate_records
GROUP BY Status
ORDER BY potential_overstatement DESC;

-- Check completeness of critical opportunity fields.
SELECT
    SUM(CASE WHEN Account_ID IS NULL OR TRIM(Account_ID) = '' THEN 1 ELSE 0 END) AS missing_account_id,
    SUM(CASE WHEN Sales_Rep_ID IS NULL OR TRIM(Sales_Rep_ID) = '' THEN 1 ELSE 0 END) AS missing_sales_rep_id,
    SUM(CASE WHEN Expected_Close_Date IS NULL OR TRIM(Expected_Close_Date) = '' THEN 1 ELSE 0 END) AS missing_expected_close_date,
    SUM(CASE WHEN Opportunity_Amount IS NULL OR TRIM(Opportunity_Amount) = '' THEN 1 ELSE 0 END) AS missing_opportunity_amount,
    SUM(CASE WHEN Last_Activity_Date IS NULL OR TRIM(Last_Activity_Date) = '' THEN 1 ELSE 0 END) AS missing_last_activity_date
FROM opportunities;

-- Summarize missing ownership and close-date issues by opportunity.
SELECT
    COUNT(DISTINCT CASE
        WHEN Sales_Rep_ID IS NULL OR TRIM(Sales_Rep_ID) = ''
        THEN Opportunity_ID
    END) AS opportunities_missing_owner,

    COUNT(DISTINCT CASE
        WHEN Expected_Close_Date IS NULL OR TRIM(Expected_Close_Date) = ''
        THEN Opportunity_ID
    END) AS opportunities_missing_close_date,

    COUNT(DISTINCT CASE
        WHEN (Sales_Rep_ID IS NULL OR TRIM(Sales_Rep_ID) = '')
         AND (Expected_Close_Date IS NULL OR TRIM(Expected_Close_Date) = '')
        THEN Opportunity_ID
    END) AS opportunities_missing_both
FROM opportunities;

-- Review opportunities with missing sales ownership.
SELECT DISTINCT
    Opportunity_ID,
    Opportunity_Name,
    Sales_Rep_ID,
    Region,
    Stage,
    Forecast_Category,
    Status,
    Opportunity_Amount,
    Expected_Close_Date,
    Last_Activity_Date,
    Next_Step
FROM opportunities
WHERE Sales_Rep_ID IS NULL
   OR TRIM(Sales_Rep_ID) = ''
ORDER BY
    Status,
    CAST(Opportunity_Amount AS DECIMAL(18,2)) DESC,
    Opportunity_ID;

-- Summarize the business impact of missing sales ownership.
SELECT
    Status,
    COUNT(DISTINCT Opportunity_ID) AS affected_opportunities,
    SUM(CAST(Opportunity_Amount AS DECIMAL(18,2))) AS affected_amount
FROM (
    SELECT DISTINCT
        Opportunity_ID,
        Status,
        Opportunity_Amount
    FROM opportunities
    WHERE Sales_Rep_ID IS NULL
       OR TRIM(Sales_Rep_ID) = ''
) AS missing_owner_records
GROUP BY Status
ORDER BY affected_amount DESC;


-- Review opportunities with missing expected close dates.
SELECT DISTINCT
    Opportunity_ID,
    Opportunity_Name,
    Sales_Rep_ID,
    Region,
    Stage,
    Forecast_Category,
    Status,
    Opportunity_Amount,
    Expected_Close_Date,
    Last_Activity_Date,
    Next_Step
FROM opportunities
WHERE Expected_Close_Date IS NULL
   OR TRIM(Expected_Close_Date) = ''
ORDER BY
    Status,
    CAST(Opportunity_Amount AS DECIMAL(18,2)) DESC,
    Opportunity_ID;


-- Quantify open pipeline with missing expected close dates.
SELECT
    COUNT(DISTINCT Opportunity_ID) AS affected_opportunities,
    SUM(CAST(Opportunity_Amount AS DECIMAL(18,2))) AS affected_pipeline
FROM (
    SELECT DISTINCT
        Opportunity_ID,
        Opportunity_Amount
    FROM opportunities
    WHERE Expected_Close_Date IS NULL
       OR TRIM(Expected_Close_Date) = ''
) AS missing_close_date_records;


-- Break down missing close-date pipeline by forecast category.
SELECT
    Forecast_Category,
    COUNT(DISTINCT Opportunity_ID) AS affected_opportunities,
    SUM(CAST(Opportunity_Amount AS DECIMAL(18,2))) AS affected_pipeline
FROM (
    SELECT DISTINCT
        Opportunity_ID,
        Forecast_Category,
        Opportunity_Amount
    FROM opportunities
    WHERE Expected_Close_Date IS NULL
       OR TRIM(Expected_Close_Date) = ''
) AS missing_close_date_records
GROUP BY Forecast_Category
ORDER BY affected_pipeline DESC;


-- Prioritize higher-confidence opportunities with missing close dates.
SELECT DISTINCT
    Opportunity_ID,
    Opportunity_Name,
    Sales_Rep_ID,
    Region,
    Stage,
    Forecast_Category,
    Opportunity_Amount,
    Last_Activity_Date,
    Next_Step
FROM opportunities
WHERE (Expected_Close_Date IS NULL OR TRIM(Expected_Close_Date) = '')
  AND Forecast_Category IN ('Commit', 'Best Case')
ORDER BY
    CASE
        WHEN Forecast_Category = 'Commit' THEN 1
        WHEN Forecast_Category = 'Best Case' THEN 2
    END,
    CAST(Opportunity_Amount AS DECIMAL(18,2)) DESC,
    Opportunity_ID;
    
-- Check for opportunity account IDs missing from the account reference table.
SELECT
    COUNT(DISTINCT o.Opportunity_ID) AS opportunities_with_invalid_account
FROM opportunities AS o
LEFT JOIN accounts AS a
    ON o.Account_ID = a.Account_ID
WHERE a.Account_ID IS NULL
  AND o.Account_ID IS NOT NULL
  AND TRIM(o.Account_ID) <> '';
  
-- Check for populated sales rep IDs missing from the sales rep reference table.
SELECT
    COUNT(DISTINCT o.Opportunity_ID) AS opportunities_with_invalid_sales_rep
FROM opportunities AS o
LEFT JOIN sales_reps AS s
    ON o.Sales_Rep_ID = s.Sales_Rep_ID
WHERE s.Sales_Rep_ID IS NULL
  AND o.Sales_Rep_ID IS NOT NULL
  AND TRIM(o.Sales_Rep_ID) <> '';

-- Review opportunities with invalid sales rep references.
SELECT DISTINCT
    o.Opportunity_ID,
    o.Opportunity_Name,
    o.Sales_Rep_ID,
    o.Region,
    o.Stage,
    o.Forecast_Category,
    o.Status,
    o.Opportunity_Amount,
    o.Expected_Close_Date,
    o.Next_Step
FROM opportunities AS o
LEFT JOIN sales_reps AS s
    ON o.Sales_Rep_ID = s.Sales_Rep_ID
WHERE s.Sales_Rep_ID IS NULL
  AND o.Sales_Rep_ID IS NOT NULL
  AND TRIM(o.Sales_Rep_ID) <> ''
ORDER BY
    o.Status,
    CAST(o.Opportunity_Amount AS DECIMAL(18,2)) DESC,
    o.Opportunity_ID;
    
-- Summarize the business impact of invalid sales rep references. 
SELECT
	o.Status,
    COUNT(DISTINCT o.Opportunity_ID) AS affected_opportunities,
    SUM(CAST(o.Opportunity_Amount AS DECIMAL(18,2))) AS affected_amount
FROM opportunities AS o
LEFT JOIN sales_reps AS s
    ON o.Sales_Rep_ID = s.Sales_Rep_ID
WHERE s.Sales_Rep_ID IS NULL
  AND o.Sales_Rep_ID IS NOT NULL
  AND TRIM(o.Sales_Rep_ID) <> ''
GROUP BY o.Status
ORDER BY affected_amount DESC;

-- Check for opportunity product IDs missing from the product reference table.
SELECT
    COUNT(DISTINCT o.Opportunity_ID) AS opportunities_with_invalid_product
FROM opportunities AS o
LEFT JOIN products AS p
    ON o.Product_ID = p.Product_ID
WHERE p.Product_ID IS NULL
  AND o.Product_ID IS NOT NULL
  AND TRIM(o.Product_ID) <> '';
  
-- Check opportunity amounts for invalid formats and non-positive values.
SELECT
    SUM(
        CASE
            WHEN NOT REGEXP_LIKE(
                TRIM(Opportunity_Amount),
                '^-?[0-9]+(\\.[0-9]+)?$'
            )
            THEN 1 ELSE 0
        END
    ) AS non_numeric_amounts,

    SUM(
        CASE
            WHEN REGEXP_LIKE(
                TRIM(Opportunity_Amount),
                '^-?[0-9]+(\\.[0-9]+)?$'
            )
             AND CAST(Opportunity_Amount AS DECIMAL(18,2)) <= 0
            THEN 1 ELSE 0
        END
    ) AS non_positive_amounts
FROM opportunities;

-- Review opportunities with zero or negative amounts.
SELECT DISTINCT
    Opportunity_ID,
    Opportunity_Name,
    Sales_Rep_ID,
    Region,
    Stage,
    Forecast_Category,
    Status,
    Opportunity_Amount,
    Probability,
    Weighted_Pipeline,
    Expected_Close_Date,
    Next_Step
FROM opportunities
WHERE REGEXP_LIKE(
        TRIM(Opportunity_Amount),
        '^-?[0-9]+(\\.[0-9]+)?$'
      )
  AND CAST(Opportunity_Amount AS DECIMAL(18,2)) <= 0
ORDER BY
    CAST(Opportunity_Amount AS DECIMAL(18,2)),
    Opportunity_ID;
    
-- Summarize zero and negative opportunity amounts.
SELECT
    CASE
        WHEN CAST(Opportunity_Amount AS DECIMAL(18,2)) < 0 THEN 'Negative'
        WHEN CAST(Opportunity_Amount AS DECIMAL(18,2)) = 0 THEN 'Zero'
    END AS amount_issue,
    COUNT(DISTINCT Opportunity_ID) AS affected_opportunities,
    SUM(CAST(Opportunity_Amount AS DECIMAL(18,2))) AS total_amount,
    SUM(CAST(Weighted_Pipeline AS DECIMAL(18,2))) AS weighted_pipeline_impact
FROM opportunities
WHERE REGEXP_LIKE(
        TRIM(Opportunity_Amount),
        '^-?[0-9]+(\\.[0-9]+)?$'
      )
  AND CAST(Opportunity_Amount AS DECIMAL(18,2)) <= 0
GROUP BY
    CASE
        WHEN CAST(Opportunity_Amount AS DECIMAL(18,2)) < 0 THEN 'Negative'
        WHEN CAST(Opportunity_Amount AS DECIMAL(18,2)) = 0 THEN 'Zero'
    END
ORDER BY total_amount;

-- Check probability values for invalid formats and out-of-range values.
SELECT
    SUM(
        CASE
            WHEN NOT REGEXP_LIKE(
                TRIM(Probability),
                '^-?[0-9]+(\\.[0-9]+)?$'
            )
            THEN 1 ELSE 0
        END
    ) AS non_numeric_probabilities,

    SUM(
        CASE
            WHEN REGEXP_LIKE(
                TRIM(Probability),
                '^-?[0-9]+(\\.[0-9]+)?$'
            )
             AND (
                    CAST(Probability AS DECIMAL(6,2)) < 0
                 OR CAST(Probability AS DECIMAL(6,2)) > 100
             )
            THEN 1 ELSE 0
        END
    ) AS out_of_range_probabilities
FROM opportunities;

-- Review opportunities with out-of-range probability values.
SELECT DISTINCT
    Opportunity_ID,
    Opportunity_Name,
    Sales_Rep_ID,
    Region,
    Stage,
    Forecast_Category,
    Status,
    Opportunity_Amount,
    Probability,
    Weighted_Pipeline,
    Expected_Close_Date,
    Next_Step
FROM opportunities
WHERE REGEXP_LIKE(
        TRIM(Probability),
        '^-?[0-9]+(\\.[0-9]+)?$'
      )
  AND (
        CAST(Probability AS DECIMAL(6,2)) < 0
        OR CAST(Probability AS DECIMAL(6,2)) > 100
      )
ORDER BY
    CAST(Probability AS DECIMAL(6,2)),
    Opportunity_ID;
    
-- Summarize out-of-range probability values and weighted pipeline impact.
SELECT
    CASE
        WHEN CAST(Probability AS DECIMAL(6,2)) < 0
            THEN 'Below 0%'
        WHEN CAST(Probability AS DECIMAL(6,2)) > 100
            THEN 'Above 100%'
    END AS probability_issue,
    COUNT(DISTINCT Opportunity_ID) AS affected_opportunities,
    SUM(CAST(Opportunity_Amount AS DECIMAL(18,2))) AS affected_amount,
    SUM(CAST(Weighted_Pipeline AS DECIMAL(18,2))) AS weighted_pipeline_impact
FROM opportunities
WHERE REGEXP_LIKE(
        TRIM(Probability),
        '^-?[0-9]+(\\.[0-9]+)?$'
      )
  AND (
        CAST(Probability AS DECIMAL(6,2)) < 0
        OR CAST(Probability AS DECIMAL(6,2)) > 100
      )
GROUP BY
    CASE
        WHEN CAST(Probability AS DECIMAL(6,2)) < 0
            THEN 'Below 0%'
        WHEN CAST(Probability AS DECIMAL(6,2)) > 100
            THEN 'Above 100%'
    END
ORDER BY weighted_pipeline_impact;

-- Validate weighted pipeline against opportunity amount and probability.
SELECT
    SUM(
        CASE
            WHEN NOT REGEXP_LIKE(
                TRIM(Weighted_Pipeline),
                '^-?[0-9]+(\\.[0-9]+)?$'
            )
            THEN 1 ELSE 0
        END
    ) AS non_numeric_weighted_pipeline,

    SUM(
        CASE
            WHEN REGEXP_LIKE(
                    TRIM(Weighted_Pipeline),
                    '^-?[0-9]+(\\.[0-9]+)?$'
                 )
             AND ABS(
                    CAST(Weighted_Pipeline AS DECIMAL(18,2))
                    -
                    (
                        CAST(Opportunity_Amount AS DECIMAL(18,2))
                        * CAST(Probability AS DECIMAL(6,2))
                        / 100
                    )
                 ) > 0.01
            THEN 1 ELSE 0
        END
    ) AS mismatched_weighted_pipeline
FROM opportunities;

-- Profile stage, status, and forecast category combinations.
SELECT
    Stage,
    Status,
    Forecast_Category,
    COUNT(*) AS opportunity_count
FROM (
    SELECT DISTINCT
        Opportunity_ID,
        Stage,
        Status,
        Forecast_Category
    FROM opportunities
) AS unique_opportunities
GROUP BY
    Stage,
    Status,
    Forecast_Category
ORDER BY
    Stage,
    Status,
    Forecast_Category;
    
-- Identify stage, status, and forecast category inconsistencies.
SELECT DISTINCT
    Opportunity_ID,
    Opportunity_Name,
    Stage,
    Status,
    Forecast_Category,
    Opportunity_Amount,
    Probability,
    Expected_Close_Date,
    Actual_Close_Date,
    CASE
        WHEN Stage = 'Closed Won'
             AND (Status <> 'Won' OR Forecast_Category <> 'Closed')
            THEN 'Closed Won mismatch'

        WHEN Stage = 'Closed Lost'
             AND (Status <> 'Lost' OR Forecast_Category <> 'Omitted')
            THEN 'Closed Lost mismatch'

        WHEN Stage NOT IN ('Closed Won', 'Closed Lost')
             AND Status <> 'Open'
            THEN 'Open stage has closed status'

        WHEN Status = 'Open'
             AND Forecast_Category IN ('Closed', 'Omitted')
            THEN 'Open opportunity has closed forecast category'
    END AS consistency_issue
FROM opportunities
WHERE
       (Stage = 'Closed Won'
        AND (Status <> 'Won' OR Forecast_Category <> 'Closed'))

    OR (Stage = 'Closed Lost'
        AND (Status <> 'Lost' OR Forecast_Category <> 'Omitted'))

    OR (Stage NOT IN ('Closed Won', 'Closed Lost')
        AND Status <> 'Open')

    OR (Status = 'Open'
        AND Forecast_Category IN ('Closed', 'Omitted'))
ORDER BY
    consistency_issue,
    Opportunity_ID;
    
-- Summarize stage, status, and forecast consistency issues.
SELECT
    consistency_issue,
    COUNT(DISTINCT Opportunity_ID) AS affected_opportunities,
    SUM(CAST(Opportunity_Amount AS DECIMAL(18,2))) AS affected_amount
FROM (
    SELECT DISTINCT
        Opportunity_ID,
        Opportunity_Amount,
        CASE
            WHEN Stage = 'Closed Won'
                 AND (Status <> 'Won' OR Forecast_Category <> 'Closed')
                THEN 'Closed Won mismatch'

            WHEN Stage = 'Closed Lost'
                 AND (Status <> 'Lost' OR Forecast_Category <> 'Omitted')
                THEN 'Closed Lost mismatch'

            WHEN Stage NOT IN ('Closed Won', 'Closed Lost')
                 AND Status <> 'Open'
                THEN 'Open stage has closed status'

            WHEN Status = 'Open'
                 AND Forecast_Category IN ('Closed', 'Omitted')
                THEN 'Open opportunity has closed forecast category'
        END AS consistency_issue
    FROM opportunities
    WHERE
           (Stage = 'Closed Won'
            AND (Status <> 'Won' OR Forecast_Category <> 'Closed'))

        OR (Stage = 'Closed Lost'
            AND (Status <> 'Lost' OR Forecast_Category <> 'Omitted'))

        OR (Stage NOT IN ('Closed Won', 'Closed Lost')
            AND Status <> 'Open')

        OR (Status = 'Open'
            AND Forecast_Category IN ('Closed', 'Omitted'))
) AS consistency_exceptions
GROUP BY consistency_issue
ORDER BY affected_amount DESC;

-- Check actual close-date consistency with opportunity status.
SELECT
    SUM(
        CASE
            WHEN Status IN ('Won', 'Lost')
             AND (Actual_Close_Date IS NULL OR TRIM(Actual_Close_Date) = '')
            THEN 1 ELSE 0
        END
    ) AS closed_without_actual_close_date,

    SUM(
        CASE
            WHEN Status = 'Open'
             AND Actual_Close_Date IS NOT NULL
             AND TRIM(Actual_Close_Date) <> ''
            THEN 1 ELSE 0
        END
    ) AS open_with_actual_close_date
FROM opportunities;

-- Review closed opportunities missing actual close dates.
SELECT DISTINCT
    Opportunity_ID,
    Opportunity_Name,
    Sales_Rep_ID,
    Region,
    Stage,
    Forecast_Category,
    Status,
    Opportunity_Amount,
    Expected_Close_Date,
    Actual_Close_Date,
    Win_Loss_Reason
FROM opportunities
WHERE Status IN ('Won', 'Lost')
  AND (
        Actual_Close_Date IS NULL
        OR TRIM(Actual_Close_Date) = ''
      )
ORDER BY
    Status,
    CAST(Opportunity_Amount AS DECIMAL(18,2)) DESC,
    Opportunity_ID;
    
-- Summarize closed opportunities missing actual close dates.
SELECT
    Status,
    COUNT(DISTINCT Opportunity_ID) AS affected_opportunities,
    SUM(CAST(Opportunity_Amount AS DECIMAL(18,2))) AS affected_amount
FROM (
    SELECT DISTINCT
        Opportunity_ID,
        Status,
        Opportunity_Amount
    FROM opportunities
    WHERE Status IN ('Won', 'Lost')
      AND (
            Actual_Close_Date IS NULL
            OR TRIM(Actual_Close_Date) = ''
          )
) AS missing_close_date_records
GROUP BY Status
ORDER BY affected_amount DESC;

-- Check win/loss reason completeness for closed opportunities.
SELECT
    SUM(
        CASE
            WHEN Status = 'Won'
             AND (Win_Loss_Reason IS NULL OR TRIM(Win_Loss_Reason) = '')
            THEN 1 ELSE 0
        END
    ) AS won_missing_reason,

    SUM(
        CASE
            WHEN Status = 'Lost'
             AND (Win_Loss_Reason IS NULL OR TRIM(Win_Loss_Reason) = '')
            THEN 1 ELSE 0
        END
    ) AS lost_missing_reason
FROM opportunities;

-- Review closed opportunities missing win/loss reasons.
SELECT DISTINCT
    Opportunity_ID,
    Opportunity_Name,
    Sales_Rep_ID,
    Region,
    Stage,
    Forecast_Category,
    Status,
    Opportunity_Amount,
    Expected_Close_Date,
    Actual_Close_Date,
    Win_Loss_Reason
FROM opportunities
WHERE Status IN ('Won', 'Lost')
  AND (
        Win_Loss_Reason IS NULL
        OR TRIM(Win_Loss_Reason) = ''
      )
ORDER BY
    Status,
    CAST(Opportunity_Amount AS DECIMAL(18,2)) DESC,
    Opportunity_ID;
    
-- Summarize closed opportunities missing win/loss reasons.
SELECT
    Status,
    COUNT(DISTINCT Opportunity_ID) AS affected_opportunities,
    SUM(CAST(Opportunity_Amount AS DECIMAL(18,2))) AS affected_amount
FROM (
    SELECT DISTINCT
        Opportunity_ID,
        Status,
        Opportunity_Amount
    FROM opportunities
    WHERE Status IN ('Won', 'Lost')
      AND (
            Win_Loss_Reason IS NULL
            OR TRIM(Win_Loss_Reason) = ''
          )
) AS missing_reason_records
GROUP BY Status
ORDER BY affected_amount DESC;

-- Profile open opportunities by days since last activity.
SELECT
    activity_age_bucket,
    COUNT(DISTINCT Opportunity_ID) AS affected_opportunities,
    SUM(CAST(Opportunity_Amount AS DECIMAL(18,2))) AS affected_pipeline
FROM (
    SELECT DISTINCT
        Opportunity_ID,
        Opportunity_Amount,
        Last_Activity_Date,
        CASE
            WHEN DATEDIFF(
                    '2026-08-17',
                    STR_TO_DATE(Last_Activity_Date, '%Y-%m-%d')
                 ) <= 30
                THEN '0-30 Days'

            WHEN DATEDIFF(
                    '2026-08-17',
                    STR_TO_DATE(Last_Activity_Date, '%Y-%m-%d')
                 ) <= 60
                THEN '31-60 Days'

            WHEN DATEDIFF(
                    '2026-08-17',
                    STR_TO_DATE(Last_Activity_Date, '%Y-%m-%d')
                 ) <= 90
                THEN '61-90 Days'

            ELSE '90+ Days'
        END AS activity_age_bucket
    FROM opportunities
    WHERE Status = 'Open'
) AS open_activity
GROUP BY activity_age_bucket
ORDER BY
    CASE activity_age_bucket
        WHEN '0-30 Days' THEN 1
        WHEN '31-60 Days' THEN 2
        WHEN '61-90 Days' THEN 3
        WHEN '90+ Days' THEN 4
    END;
    
-- Assess stale open pipeline by forecast category.
SELECT
    Forecast_Category,
    COUNT(DISTINCT Opportunity_ID) AS stale_opportunities,
    SUM(CAST(Opportunity_Amount AS DECIMAL(18,2))) AS stale_pipeline
FROM (
    SELECT DISTINCT
        Opportunity_ID,
        Forecast_Category,
        Opportunity_Amount,
        Last_Activity_Date
    FROM opportunities
    WHERE Status = 'Open'
      AND DATEDIFF(
            '2026-08-17',
            STR_TO_DATE(Last_Activity_Date, '%Y-%m-%d')
          ) > 90
) AS stale_pipeline_records
GROUP BY Forecast_Category
ORDER BY stale_pipeline DESC;

-- Prioritize stale Commit and Best Case opportunities for review.
SELECT DISTINCT
    Opportunity_ID,
    Opportunity_Name,
    Sales_Rep_ID,
    Region,
    Stage,
    Forecast_Category,
    Opportunity_Amount,
    Probability,
    Weighted_Pipeline,
    Expected_Close_Date,
    Last_Activity_Date,
    DATEDIFF(
        '2026-08-17',
        STR_TO_DATE(Last_Activity_Date, '%Y-%m-%d')
    ) AS days_since_last_activity,
    Next_Step
FROM opportunities
WHERE Status = 'Open'
  AND Forecast_Category IN ('Commit', 'Best Case')
  AND DATEDIFF(
        '2026-08-17',
        STR_TO_DATE(Last_Activity_Date, '%Y-%m-%d')
      ) > 90
ORDER BY
    CASE
        WHEN Forecast_Category = 'Commit' THEN 1
        WHEN Forecast_Category = 'Best Case' THEN 2
    END,
    CAST(Opportunity_Amount AS DECIMAL(18,2)) DESC,
    days_since_last_activity DESC;
    
-- Identify expected close-date changes across opportunity history.
WITH ordered_history AS (
    SELECT
        Row_ID,
        History_ID,
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
)

SELECT
    Opportunity_ID,
    COUNT(*) AS close_date_pushes
FROM ordered_history
WHERE previous_expected_close_date IS NOT NULL
  AND Expected_Close_Date IS NOT NULL
  AND TRIM(Expected_Close_Date) <> ''
  AND STR_TO_DATE(Expected_Close_Date, '%Y-%m-%d')
      >
      STR_TO_DATE(previous_expected_close_date, '%Y-%m-%d')
GROUP BY Opportunity_ID
HAVING COUNT(*) > 0
ORDER BY
    close_date_pushes DESC,
    Opportunity_ID;

-- Assess current open opportunities with repeated close-date pushes.
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
    WHERE previous_expected_close_date IS NOT NULL
      AND Expected_Close_Date IS NOT NULL
      AND TRIM(Expected_Close_Date) <> ''
      AND STR_TO_DATE(Expected_Close_Date, '%Y-%m-%d')
          >
          STR_TO_DATE(previous_expected_close_date, '%Y-%m-%d')
    GROUP BY Opportunity_ID
)

SELECT
    o.Forecast_Category,
    COUNT(DISTINCT o.Opportunity_ID) AS affected_opportunities,
    SUM(CAST(o.Opportunity_Amount AS DECIMAL(18,2))) AS affected_pipeline
FROM opportunities AS o
INNER JOIN push_counts AS p
    ON o.Opportunity_ID = p.Opportunity_ID
WHERE o.Status = 'Open'
  AND p.close_date_pushes >= 3
GROUP BY o.Forecast_Category
ORDER BY affected_pipeline DESC;

-- Recalculate repeated close-date push impact after deduplicating opportunities
-- so pipeline totals are not inflated by duplicate raw records.
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
    WHERE previous_expected_close_date IS NOT NULL
      AND Expected_Close_Date IS NOT NULL
      AND TRIM(Expected_Close_Date) <> ''
      AND STR_TO_DATE(Expected_Close_Date, '%Y-%m-%d')
          >
          STR_TO_DATE(previous_expected_close_date, '%Y-%m-%d')
    GROUP BY Opportunity_ID
),

unique_opportunities AS (
    SELECT DISTINCT
        Opportunity_ID,
        Forecast_Category,
        Status,
        Opportunity_Amount
    FROM opportunities
)

SELECT
    o.Forecast_Category,
    COUNT(*) AS affected_opportunities,
    SUM(CAST(o.Opportunity_Amount AS DECIMAL(18,2))) AS affected_pipeline
FROM unique_opportunities AS o
INNER JOIN push_counts AS p
    ON o.Opportunity_ID = p.Opportunity_ID
WHERE o.Status = 'Open'
  AND p.close_date_pushes >= 3
GROUP BY o.Forecast_Category
ORDER BY affected_pipeline DESC;

-- Prioritize higher-confidence open opportunities with repeated close-date pushes.
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
    WHERE previous_expected_close_date IS NOT NULL
      AND Expected_Close_Date IS NOT NULL
      AND TRIM(Expected_Close_Date) <> ''
      AND STR_TO_DATE(Expected_Close_Date, '%Y-%m-%d')
          >
          STR_TO_DATE(previous_expected_close_date, '%Y-%m-%d')
    GROUP BY Opportunity_ID
),

unique_opportunities AS (
    SELECT DISTINCT
        Opportunity_ID,
        Opportunity_Name,
        Sales_Rep_ID,
        Region,
        Stage,
        Forecast_Category,
        Status,
        Opportunity_Amount,
        Probability,
        Weighted_Pipeline,
        Expected_Close_Date,
        Last_Activity_Date,
        Next_Step
    FROM opportunities
)

SELECT
    o.Opportunity_ID,
    o.Opportunity_Name,
    o.Sales_Rep_ID,
    o.Region,
    o.Stage,
    o.Forecast_Category,
    o.Opportunity_Amount,
    o.Probability,
    o.Weighted_Pipeline,
    o.Expected_Close_Date,
    o.Last_Activity_Date,
    p.close_date_pushes,
    o.Next_Step
FROM unique_opportunities AS o
INNER JOIN push_counts AS p
    ON o.Opportunity_ID = p.Opportunity_ID
WHERE o.Status = 'Open'
  AND o.Forecast_Category IN ('Commit', 'Best Case')
  AND p.close_date_pushes >= 3
ORDER BY
    CASE
        WHEN o.Forecast_Category = 'Commit' THEN 1
        WHEN o.Forecast_Category = 'Best Case' THEN 2
    END,
    p.close_date_pushes DESC,
    CAST(o.Opportunity_Amount AS DECIMAL(18,2)) DESC;

-- Profile forecast-category changes across opportunity history.
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
)

SELECT
    previous_forecast_category,
    Forecast_Category AS new_forecast_category,
    COUNT(*) AS transition_count
FROM ordered_history
WHERE previous_forecast_category IS NOT NULL
  AND Forecast_Category IS NOT NULL
  AND TRIM(Forecast_Category) <> ''
  AND Forecast_Category <> previous_forecast_category
GROUP BY
    previous_forecast_category,
    Forecast_Category
ORDER BY transition_count DESC;

-- Classify forecast-category transitions as upgrades, downgrades, or outcomes.
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

transitions AS (
    SELECT
        Opportunity_ID,
        previous_forecast_category,
        Forecast_Category AS new_forecast_category,

        CASE
            WHEN previous_forecast_category = 'Pipeline'
                 AND Forecast_Category IN ('Best Case', 'Commit')
                THEN 'Upgrade'

            WHEN previous_forecast_category = 'Best Case'
                 AND Forecast_Category = 'Commit'
                THEN 'Upgrade'

            WHEN previous_forecast_category = 'Best Case'
                 AND Forecast_Category = 'Pipeline'
                THEN 'Downgrade'

            WHEN previous_forecast_category = 'Commit'
                 AND Forecast_Category IN ('Best Case', 'Pipeline')
                THEN 'Downgrade'

            WHEN Forecast_Category IN ('Closed', 'Omitted')
                THEN 'Outcome / Exit'

            ELSE 'Other'
        END AS transition_type

    FROM ordered_history
    WHERE previous_forecast_category IS NOT NULL
      AND Forecast_Category IS NOT NULL
      AND TRIM(Forecast_Category) <> ''
      AND Forecast_Category <> previous_forecast_category
)

SELECT
    transition_type,
    COUNT(*) AS transition_count,
    COUNT(DISTINCT Opportunity_ID) AS affected_opportunities
FROM transitions
GROUP BY transition_type
ORDER BY transition_count DESC;

-- Identify opportunities with repeated forecast downgrades.
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
               previous_forecast_category = 'Best Case'
               AND Forecast_Category = 'Pipeline'
           )

        OR (
               previous_forecast_category = 'Commit'
               AND Forecast_Category IN ('Best Case', 'Pipeline')
           )
),

downgrade_counts AS (
    SELECT
        Opportunity_ID,
        COUNT(*) AS downgrade_count
    FROM downgrades
    GROUP BY Opportunity_ID
    HAVING COUNT(*) >= 2
)

SELECT
    downgrade_count,
    COUNT(*) AS affected_opportunities
FROM downgrade_counts
GROUP BY downgrade_count
ORDER BY downgrade_count DESC;

-- Assess current open opportunities with repeated forecast downgrades.
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
               previous_forecast_category = 'Best Case'
               AND Forecast_Category = 'Pipeline'
           )

        OR (
               previous_forecast_category = 'Commit'
               AND Forecast_Category IN ('Best Case', 'Pipeline')
           )
),

downgrade_counts AS (
    SELECT
        Opportunity_ID,
        COUNT(*) AS downgrade_count
    FROM downgrades
    GROUP BY Opportunity_ID
    HAVING COUNT(*) >= 2
),

unique_opportunities AS (
    SELECT DISTINCT
        Opportunity_ID,
        Forecast_Category,
        Status,
        Opportunity_Amount
    FROM opportunities
)

SELECT
    o.Forecast_Category,
    COUNT(*) AS affected_opportunities,
    SUM(CAST(o.Opportunity_Amount AS DECIMAL(18,2))) AS affected_pipeline
FROM unique_opportunities AS o
INNER JOIN downgrade_counts AS d
    ON o.Opportunity_ID = d.Opportunity_ID
WHERE o.Status = 'Open'
GROUP BY o.Forecast_Category
ORDER BY affected_pipeline DESC;

    