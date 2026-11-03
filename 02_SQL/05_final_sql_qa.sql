USE sales_intelligence_bi;

-- 1. Confirm raw versus trusted opportunity grain.
SELECT
    (SELECT COUNT(*) FROM opportunities) AS raw_rows,
    (SELECT COUNT(*) FROM vw_opportunities_deduped) AS deduped_rows,
    (SELECT COUNT(*) FROM vw_opportunities_trusted) AS trusted_rows;


-- 2. Confirm trusted-layer quality classification.
SELECT
    quality_status,
    COUNT(*) AS opportunity_count
FROM vw_opportunities_trusted
GROUP BY quality_status
ORDER BY opportunity_count DESC;


-- 3. Reconcile validated open pipeline.
SELECT
    COUNT(*) AS open_opportunities,
    SUM(Opportunity_Amount) AS total_pipeline,
    SUM(Weighted_Pipeline) AS weighted_pipeline
FROM vw_opportunities_trusted
WHERE Status = 'Open'
  AND quality_status = 'Pass';


-- 4. Reconcile validated closed opportunities.
SELECT
    Status,
    COUNT(*) AS closed_opportunities,
    SUM(Opportunity_Amount) AS closed_amount
FROM vw_opportunities_trusted
WHERE Status IN ('Won', 'Lost')
  AND quality_status = 'Pass'
GROUP BY Status
ORDER BY Status;


-- 5. Confirm total validated business population.
SELECT
    COUNT(*) AS validated_business_opportunities
FROM vw_opportunities_trusted
WHERE quality_status = 'Pass';