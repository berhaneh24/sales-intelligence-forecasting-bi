USE sales_intelligence_bi;

SELECT
    r.Status,
    r.raw_rows,
    d.deduped_rows,
    r.raw_rows - d.deduped_rows AS duplicates_removed,
    r.raw_amount,
    d.deduped_amount,
    ROUND(
        r.raw_amount - d.deduped_amount,
        2
    ) AS potential_overstatement
FROM (
    SELECT
        Status,
        COUNT(*) AS raw_rows,
        SUM(CAST(Opportunity_Amount AS DECIMAL(18,2)))
            AS raw_amount
    FROM opportunities
    GROUP BY Status
) AS r
JOIN (
    SELECT
        Status,
        COUNT(*) AS deduped_rows,
        SUM(CAST(Opportunity_Amount AS DECIMAL(18,2)))
            AS deduped_amount
    FROM vw_opportunities_deduped
    GROUP BY Status
) AS d
    ON r.Status = d.Status
ORDER BY r.Status;