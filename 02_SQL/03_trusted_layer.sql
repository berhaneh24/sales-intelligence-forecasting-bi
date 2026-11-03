USE sales_intelligence_bi;

-- ============================================================
-- TRUSTED ANALYTICAL LAYER
-- Preserve raw source data while creating validated,
-- deduplicated structures for downstream reporting.
-- ============================================================

-- Create a deduplicated opportunity view.
-- Exact duplicate source records are removed while preserving
-- potentially different records that share an Opportunity_ID.
CREATE OR REPLACE VIEW vw_opportunities_deduped AS

WITH ranked_opportunities AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
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
            ORDER BY Row_ID
        ) AS duplicate_rank
    FROM opportunities
)

SELECT
    Row_ID,
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
FROM ranked_opportunities
WHERE duplicate_rank = 1;

SELECT
    COUNT(*) AS deduped_rows,
    COUNT(DISTINCT Opportunity_ID) AS unique_opportunities
FROM vw_opportunities_deduped;

-- Reconcile raw and deduplicated opportunity counts.
SELECT
    (SELECT COUNT(*) FROM opportunities) AS raw_rows,
    (SELECT COUNT(*) FROM vw_opportunities_deduped) AS deduped_rows,
    (SELECT COUNT(*) FROM opportunities)
      - (SELECT COUNT(*) FROM vw_opportunities_deduped) AS duplicate_rows_removed;
      
-- Create a typed reporting view from the deduplicated opportunity layer.
CREATE OR REPLACE VIEW vw_opportunities_typed AS
SELECT
    Row_ID,
    Opportunity_ID,
    Opportunity_Name,
    Account_ID,
    Sales_Rep_ID,
    Product_ID,
    Segment,
    Region,
    Stage,
    Forecast_Category,

    STR_TO_DATE(NULLIF(TRIM(Created_Date), ''), '%Y-%m-%d')
        AS Created_Date,

    STR_TO_DATE(NULLIF(TRIM(Expected_Close_Date), ''), '%Y-%m-%d')
        AS Expected_Close_Date,

    STR_TO_DATE(NULLIF(TRIM(Actual_Close_Date), ''), '%Y-%m-%d')
        AS Actual_Close_Date,

    CAST(Opportunity_Amount AS DECIMAL(18,2))
        AS Opportunity_Amount,

    CAST(Probability AS DECIMAL(6,2))
        AS Probability,

    CAST(Weighted_Pipeline AS DECIMAL(18,2))
        AS Weighted_Pipeline,

    Fiscal_Quarter,
    Status,
    Win_Loss_Reason,

    STR_TO_DATE(NULLIF(TRIM(Last_Activity_Date), ''), '%Y-%m-%d')
        AS Last_Activity_Date,

    Next_Step

FROM vw_opportunities_deduped;

-- Validate row grain after type conversion.
SELECT
    COUNT(*) AS typed_rows,
    COUNT(DISTINCT Opportunity_ID) AS unique_opportunities
FROM vw_opportunities_typed;

-- Verify data types in the typed reporting view.
DESCRIBE vw_opportunities_typed;

-- Create a quality-flagged reporting view.
CREATE OR REPLACE VIEW vw_opportunities_quality_flagged AS
SELECT
    t.*,

    CASE
        WHEN t.Sales_Rep_ID IS NULL
             OR TRIM(t.Sales_Rep_ID) = ''
        THEN 1 ELSE 0
    END AS flag_missing_owner,

    CASE
        WHEN t.Expected_Close_Date IS NULL
        THEN 1 ELSE 0
    END AS flag_missing_expected_close_date,

    CASE
        WHEN t.Opportunity_Amount <= 0
        THEN 1 ELSE 0
    END AS flag_invalid_amount,

    CASE
        WHEN t.Probability < 0
             OR t.Probability > 100
        THEN 1 ELSE 0
    END AS flag_invalid_probability,

    CASE
        WHEN t.Status IN ('Won', 'Lost')
             AND t.Actual_Close_Date IS NULL
        THEN 1 ELSE 0
    END AS flag_closed_missing_actual_close_date,

    CASE
        WHEN t.Status IN ('Won', 'Lost')
             AND (
                 t.Win_Loss_Reason IS NULL
                 OR TRIM(t.Win_Loss_Reason) = ''
             )
        THEN 1 ELSE 0
    END AS flag_missing_win_loss_reason,

    CASE
        WHEN t.Stage = 'Closed Won'
             AND (
                 t.Status <> 'Won'
                 OR t.Forecast_Category <> 'Closed'
             )
        THEN 1

        WHEN t.Stage = 'Closed Lost'
             AND (
                 t.Status <> 'Lost'
                 OR t.Forecast_Category <> 'Omitted'
             )
        THEN 1

        WHEN t.Stage NOT IN ('Closed Won', 'Closed Lost')
             AND t.Status <> 'Open'
        THEN 1

        WHEN t.Status = 'Open'
             AND t.Forecast_Category IN ('Closed', 'Omitted')
        THEN 1

        ELSE 0
    END AS flag_stage_status_forecast_mismatch

FROM vw_opportunities_typed AS t;

-- Validate data-quality flag counts.
SELECT
    SUM(flag_missing_owner) AS missing_owner,
    SUM(flag_missing_expected_close_date) AS missing_expected_close_date,
    SUM(flag_invalid_amount) AS invalid_amount,
    SUM(flag_invalid_probability) AS invalid_probability,
    SUM(flag_closed_missing_actual_close_date) AS closed_missing_actual_close_date,
    SUM(flag_missing_win_loss_reason) AS missing_win_loss_reason,
    SUM(flag_stage_status_forecast_mismatch) AS stage_status_forecast_mismatch
FROM vw_opportunities_quality_flagged;

-- Validate reference-table relationships from the typed opportunity layer.
SELECT
    SUM(
        CASE
            WHEN t.Sales_Rep_ID IS NOT NULL
             AND TRIM(t.Sales_Rep_ID) <> ''
             AND s.Sales_Rep_ID IS NULL
            THEN 1 ELSE 0
        END
    ) AS invalid_sales_rep_reference,

    SUM(
        CASE
            WHEN t.Account_ID IS NOT NULL
             AND TRIM(t.Account_ID) <> ''
             AND a.Account_ID IS NULL
            THEN 1 ELSE 0
        END
    ) AS invalid_account_reference,

    SUM(
        CASE
            WHEN t.Product_ID IS NOT NULL
             AND TRIM(t.Product_ID) <> ''
             AND p.Product_ID IS NULL
            THEN 1 ELSE 0
        END
    ) AS invalid_product_reference

FROM vw_opportunities_typed AS t

LEFT JOIN sales_reps AS s
    ON t.Sales_Rep_ID = s.Sales_Rep_ID

LEFT JOIN accounts AS a
    ON t.Account_ID = a.Account_ID

LEFT JOIN products AS p
    ON t.Product_ID = p.Product_ID;

-- Update the quality-flagged reporting view with reference-integrity controls.
CREATE OR REPLACE VIEW vw_opportunities_quality_flagged AS
SELECT
    t.*,

    CASE
        WHEN t.Sales_Rep_ID IS NULL
             OR TRIM(t.Sales_Rep_ID) = ''
        THEN 1 ELSE 0
    END AS flag_missing_owner,

    CASE
        WHEN t.Sales_Rep_ID IS NOT NULL
             AND TRIM(t.Sales_Rep_ID) <> ''
             AND s.Sales_Rep_ID IS NULL
        THEN 1 ELSE 0
    END AS flag_invalid_sales_rep_reference,

    CASE
        WHEN t.Account_ID IS NOT NULL
             AND TRIM(t.Account_ID) <> ''
             AND a.Account_ID IS NULL
        THEN 1 ELSE 0
    END AS flag_invalid_account_reference,

    CASE
        WHEN t.Product_ID IS NOT NULL
             AND TRIM(t.Product_ID) <> ''
             AND p.Product_ID IS NULL
        THEN 1 ELSE 0
    END AS flag_invalid_product_reference,

    CASE
        WHEN t.Expected_Close_Date IS NULL
        THEN 1 ELSE 0
    END AS flag_missing_expected_close_date,

    CASE
        WHEN t.Opportunity_Amount <= 0
        THEN 1 ELSE 0
    END AS flag_invalid_amount,

    CASE
        WHEN t.Probability < 0
             OR t.Probability > 100
        THEN 1 ELSE 0
    END AS flag_invalid_probability,

    CASE
        WHEN t.Status IN ('Won', 'Lost')
             AND t.Actual_Close_Date IS NULL
        THEN 1 ELSE 0
    END AS flag_closed_missing_actual_close_date,

    CASE
        WHEN t.Status IN ('Won', 'Lost')
             AND (
                 t.Win_Loss_Reason IS NULL
                 OR TRIM(t.Win_Loss_Reason) = ''
             )
        THEN 1 ELSE 0
    END AS flag_missing_win_loss_reason,

    CASE
        WHEN t.Stage = 'Closed Won'
             AND (
                 t.Status <> 'Won'
                 OR t.Forecast_Category <> 'Closed'
             )
        THEN 1

        WHEN t.Stage = 'Closed Lost'
             AND (
                 t.Status <> 'Lost'
                 OR t.Forecast_Category <> 'Omitted'
             )
        THEN 1

        WHEN t.Stage NOT IN ('Closed Won', 'Closed Lost')
             AND t.Status <> 'Open'
        THEN 1

        WHEN t.Status = 'Open'
             AND t.Forecast_Category IN ('Closed', 'Omitted')
        THEN 1

        ELSE 0
    END AS flag_stage_status_forecast_mismatch

FROM vw_opportunities_typed AS t

LEFT JOIN sales_reps AS s
    ON t.Sales_Rep_ID = s.Sales_Rep_ID

LEFT JOIN accounts AS a
    ON t.Account_ID = a.Account_ID

LEFT JOIN products AS p
    ON t.Product_ID = p.Product_ID;
    
-- Final reconciliation of all trusted-layer data-quality flags.
SELECT
    SUM(flag_missing_owner) AS missing_owner,
    SUM(flag_invalid_sales_rep_reference) AS invalid_sales_rep_reference,
    SUM(flag_invalid_account_reference) AS invalid_account_reference,
    SUM(flag_invalid_product_reference) AS invalid_product_reference,
    SUM(flag_missing_expected_close_date) AS missing_expected_close_date,
    SUM(flag_invalid_amount) AS invalid_amount,
    SUM(flag_invalid_probability) AS invalid_probability,
    SUM(flag_closed_missing_actual_close_date) AS closed_missing_actual_close_date,
    SUM(flag_missing_win_loss_reason) AS missing_win_loss_reason,
    SUM(flag_stage_status_forecast_mismatch) AS stage_status_forecast_mismatch
FROM vw_opportunities_quality_flagged;

-- Create the final trusted opportunity view with an overall quality indicator.
CREATE OR REPLACE VIEW vw_opportunities_trusted AS
SELECT
    q.*,

    (
        flag_missing_owner
        + flag_invalid_sales_rep_reference
        + flag_invalid_account_reference
        + flag_invalid_product_reference
        + flag_missing_expected_close_date
        + flag_invalid_amount
        + flag_invalid_probability
        + flag_closed_missing_actual_close_date
        + flag_missing_win_loss_reason
        + flag_stage_status_forecast_mismatch
    ) AS quality_issue_count,

    CASE
        WHEN (
            flag_missing_owner
            + flag_invalid_sales_rep_reference
            + flag_invalid_account_reference
            + flag_invalid_product_reference
            + flag_missing_expected_close_date
            + flag_invalid_amount
            + flag_invalid_probability
            + flag_closed_missing_actual_close_date
            + flag_missing_win_loss_reason
            + flag_stage_status_forecast_mismatch
        ) = 0
        THEN 'Pass'

        ELSE 'Review Required'
    END AS quality_status

FROM vw_opportunities_quality_flagged AS q;

-- Summarize overall trusted-layer quality status.
SELECT
    quality_status,
    COUNT(*) AS opportunity_count
FROM vw_opportunities_trusted
GROUP BY quality_status
ORDER BY opportunity_count DESC;

-- Profile the number of quality issues per opportunity.
SELECT
    quality_issue_count,
    COUNT(*) AS opportunity_count
FROM vw_opportunities_trusted
GROUP BY quality_issue_count
ORDER BY quality_issue_count;