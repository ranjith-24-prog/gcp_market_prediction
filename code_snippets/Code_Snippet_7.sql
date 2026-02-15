Create or Replace Table mpd_g6_data.CCMPD_past_ReqMat_offroad_Touring as
SELECT 
    co.Country, 
    co.Year, 
    co.Month, 
    pm.MatId, 
    ma.Mat_group, 
    SUM(co.total_sales_qty * pm.Amount_Required) AS Forecasted_Material_Qty
FROM 
    `vlba-2024-mpd-group-6.mpd_g6_data.CCMPD_Past_TotSales_Rev_Exp_Prof_CYMP_Model` co
JOIN 
    `vlba-2024-mpd-group-6.mpd_g6_data.MPD_ProductMat` pm
ON 
    pm.ProductId = co.ProductId
JOIN 
    `vlba-2024-mpd-group-6.mpd_g6_data.MPD_MaterialAttr` ma
ON 
    pm.MatId = ma.MatID
GROUP BY 
    co.Year, 
    co.Month, 
    pm.MatId, 
    ma.Mat_group,
    co.Country
ORDER BY
    co.Year, 
    co.Month, 
    pm.MatId