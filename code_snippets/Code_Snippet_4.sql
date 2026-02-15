CREATE OR REPLACE TABLE mpd_g6_data.ZZMPD_Sales_Info AS
SELECT OI.OrderNumber,OI.ProductId,OI.SalesQuantity, Round((OI.RevenueUSD-OI.DiscountUSD),2) Actual_Revenue,O.Date, O.CustomerId
FROM `vlba-2024-mpd-group-6.mpd_g6_data.MPD_OrderItems` OI
JOIN `vlba-2024-mpd-group-6.mpd_g6_data.MPD_Orders` O
ON OI.OrderNumber = O.OrderNumber
ORDER BY O.Date;