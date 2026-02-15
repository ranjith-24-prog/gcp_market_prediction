Create or Replace Table mpd_g6_data.CCMPD_future_ReqMat_forecast as
SELECT 
    co.Country, 
    co.Year, 
    co.Month, 
    pm.MatId, 
    ma.Mat_group, 
    SUM(co.Forecasted_Sales_Quantity * pm.Amount_Required) AS Forecasted_Material_Qty
FROM 
    `vlba-2024-mpd-group-6.mpd_g6_data.CCMPD_Sal_Prof_Seasonal_Model_Output` co
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