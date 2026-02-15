CREATE OR REPLACE TABLE mpd_g6_data.CCMPD_Past_TotSales_Rev_Exp_Prof_CYMP_VIS AS
WITH SalesSummary AS (
    SELECT 
        EXTRACT(YEAR FROM si.Date) AS year,
        EXTRACT(MONTH FROM si.Date) AS month,
        si.ProductId,
        ca.Country,
        SUM(si.SalesQuantity) AS total_sales_qty,
        ROUND(SUM(si.Actual_Revenue), 2) AS total_revenue
    FROM 
        `vlba-2024-mpd-group-6.mpd_g6_data.ZZMPD_Sales_Info` si
    JOIN 
        `vlba-2024-mpd-group-6.mpd_g6_data.MPD_CustomerAttr` ca ON si.CustomerId = ca.CustomerId
    GROUP BY 
        year, month, si.ProductId, ca.Country
),
MaterialCostSummary AS (
    SELECT
        EXTRACT(YEAR FROM si.Date) AS year,
        EXTRACT(MONTH FROM si.Date) AS month,
        si.ProductId,
        ca.Country,
        pm.MatId,
        SUM(CAST(si.SalesQuantity AS NUMERIC) * (pm.Amount_Required / CAST(pm.Lot_size AS NUMERIC)) * mu.UnitCost) AS total_expense
    FROM 
        `vlba-2024-mpd-group-6.mpd_g6_data.ZZMPD_Sales_Info` si
    JOIN 
        `vlba-2024-mpd-group-6.mpd_g6_data.MPD_CustomerAttr` ca ON si.CustomerId = ca.CustomerId
    JOIN 
        `vlba-2024-mpd-group-6.mpd_g6_data.MPD_ProductMat` pm ON si.ProductId = pm.ProductId
    JOIN (
        SELECT 
            MatId,
            EXTRACT(YEAR FROM Date) AS year,
            EXTRACT(MONTH FROM Date) AS month,
            AVG(UnitCost) AS UnitCost
        FROM 
            `vlba-2024-mpd-group-6.mpd_g6_data.ZZMPD_Material_monthly_unit_cost_info`
        GROUP BY 
            MatId, year, month
    ) mu 
        ON pm.MatId = mu.MatId AND EXTRACT(YEAR FROM si.Date) = year AND EXTRACT(MONTH FROM si.Date) = month
    GROUP BY 
        year, month, si.ProductId, ca.Country, pm.MatId
),
ExpenseSummary AS (
    SELECT
        year,
        month,
        ProductId,
        Country,
        ROUND(SUM(total_expense), 2) AS total_expense
    FROM
        MaterialCostSummary
    GROUP BY
        year, month, ProductId, Country
)
SELECT 
    ss.year,
    ss.month,
    ss.ProductId,
    pa.catDescr AS ProdCat,
    ss.Country,
    ss.total_sales_qty,
    ss.total_revenue,
    es.total_expense,
    ROUND((ss.total_revenue - es.total_expense), 2) AS monthly_profit
FROM 
    SalesSummary ss
JOIN 
    ExpenseSummary es ON ss.year = es.year AND ss.month = es.month AND ss.ProductId = es.ProductId AND ss.Country = es.Country
JOIN 
    `vlba-2024-mpd-group-6.mpd_g6_data.MPD_ProductAttr` pa ON ss.ProductId = pa.ProductId
ORDER BY 
    ss.Country, ss.year, ss.month, ss.ProductId;
