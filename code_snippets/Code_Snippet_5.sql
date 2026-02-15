CREATE OR REPLACE TABLE mpd_g6_data.ZZMPD_Material_monthly_unit_cost_info AS
WITH UniqueOrders AS (
    SELECT 
        mo.MATNR AS MatId,
        ma.Mat_group,
        ma.Lot_size,
        mo.Date,
        mo.Quantity AS OrderQuantity,
        mo.invoice_value_USD
    FROM 
        `vlba-2024-mpd-group-6.mpd_g6_data.MPD_ProductMat` pm
    JOIN 
        `vlba-2024-mpd-group-6.mpd_g6_data.MPD_MaterialAttr` ma
    ON 
        pm.MatId = ma.MatId
    JOIN 
        `vlba-2024-mpd-group-6.mpd_g6_data.MPD_MaterialOrders` mo
    ON 
        ma.MatId = mo.MATNR
    GROUP BY 
        mo.MATNR, ma.Mat_group, ma.Lot_size, mo.Date, mo.Quantity, mo.invoice_value_USD
)
SELECT 
    uo.MatId,
    uo.Mat_group,
    uo.Lot_size,
    uo.Date,
    uo.OrderQuantity,
    uo.invoice_value_USD,
    CASE 
        WHEN uo.OrderQuantity = 0 OR uo.Lot_size = 0 THEN 0 
        ELSE ROUND((uo.invoice_value_USD / (uo.OrderQuantity * uo.Lot_size)), 2)
    END AS UnitCost
FROM 
    UniqueOrders uo
ORDER BY 
    uo.MatId, uo.Date;
