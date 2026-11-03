-- ============================================================
-- SALES BUSINESS INTELLIGENCE PORTFOLIO PROJECT
-- Synthetic CRM data for pipeline, forecast, quota,
-- and data-quality analysis.
-- All data is fictional and created for portfolio use.
-- ============================================================

CREATE DATABASE IF NOT EXISTS sales_intelligence_bi;

USE sales_intelligence_bi;

-- Accounts: customer and account reference data
CREATE TABLE IF NOT EXISTS accounts (
    Row_ID INT AUTO_INCREMENT PRIMARY KEY,
    Account_ID VARCHAR(50),
    Account_Name VARCHAR(255),
    Segment VARCHAR(100),
    Region VARCHAR(100),
    Account_Tier VARCHAR(50),
    Industry VARCHAR(100),
    Customer_Status VARCHAR(50)
);             

-- Sales reps: ownership, region, manager, and active status
CREATE TABLE IF NOT EXISTS sales_reps (
	Row_ID INT AUTO_INCREMENT PRIMARY KEY,
	Sales_Rep_ID VARCHAR(50),
	Sales_Rep_Name VARCHAR(150),
	Region VARCHAR(100),
	Manager VARCHAR(150),
	Hire_Date VARCHAR(30),
	Active_Flag VARCHAR(10)
);

-- Products: solution and product reference data
CREATE TABLE IF NOT EXISTS products (
	Row_ID INT AUTO_INCREMENT PRIMARY KEY,
    Product_ID VARCHAR(50),
    Product_Family VARCHAR(150),
    Description VARCHAR(500),
    Typical_Deal_Size_Multiplier VARCHAR(50)
);
    
-- Quotas: monthly sales targets by rep and region
CREATE TABLE IF NOT EXISTS quotas (
	Row_ID INT AUTO_INCREMENT PRIMARY KEY,
    Quota_ID VARCHAR(50),
    Sales_Rep_ID VARCHAR(50),
    Quota_Month VARCHAR(30),
    Monthly_Quota VARCHAR(50),
    Fiscal_Quarter VARCHAR(30),
    Region VARCHAR(100)
);

-- Opportunities: current CRM pipeline and forecast snapshot
CREATE TABLE IF NOT EXISTS opportunities (
	Row_ID INT AUTO_INCREMENT PRIMARY KEY,
    Opportunity_ID VARCHAR (50),
    Opportunity_Name VARCHAR(250),
    Account_ID VARCHAR(50),
    Sales_Rep_ID VARCHAR(50),
    Product_ID VARCHAR(50),
    Segment VARCHAR(100),
    Region VARCHAR(100),
    Stage VARCHAR(100),
    Forecast_Category VARCHAR(100),
	Created_Date VARCHAR(30),
    Expected_Close_Date VARCHAR(30),
    Actual_Close_Date VARCHAR(30),
    Opportunity_Amount VARCHAR(50),
    Probability VARCHAR(50),
    Weighted_Pipeline VARCHAR(50),
    Fiscal_Quarter VARCHAR(30),
    Status VARCHAR(50),
    Win_Loss_Reason VARCHAR(150),
    Last_Activity_Date VARCHAR(30),
    Next_Step VARCHAR(255)
);
    
-- Opportunity history: stage, forecast, and close-date changes
CREATE TABLE IF NOT EXISTS opportunity_history (
	Row_ID INT AUTO_INCREMENT PRIMARY KEY,
    History_ID VARCHAR(50),
    Opportunity_ID VARCHAR(50),
    Change_Date VARCHAR(30),
    Stage VARCHAR(100),
    Forecast_Category VARCHAR(100),
    Expected_Close_Date VARCHAR(30),
    Opportunity_Amount VARCHAR(50),
    Changed_By VARCHAR(50)
);

-- ============================================================
-- RAW DATA LOAD
-- Synthetic CSV files were imported using MySQL Workbench.
-- Raw fields are preserved for data-quality profiling.
-- ============================================================

-- ============================================================
-- POST-IMPORT VALIDATION
-- Validate row counts and sample records before analysis.
-- ============================================================

-- Row counts
SELECT COUNT(*) AS accounts_rows
FROM accounts;

SELECT COUNT(*) AS sales_reps_rows
FROM sales_reps;

SELECT COUNT(*) AS products_rows
FROM products;

SELECT COUNT(*) AS quotas_rows
FROM quotas;

SELECT COUNT(*) AS opportunities_rows
FROM opportunities;

SELECT COUNT(*) AS opportunity_history_rows
FROM opportunity_history;


-- Sample records
SELECT * FROM accounts LIMIT 10;
SELECT * FROM sales_reps LIMIT 10;
SELECT * FROM products LIMIT 10;
SELECT * FROM quotas LIMIT 10;
SELECT * FROM opportunities LIMIT 10;
SELECT * FROM opportunity_history LIMIT 10;
    
    




                                                                                                                                                                                                                                                                                                                           