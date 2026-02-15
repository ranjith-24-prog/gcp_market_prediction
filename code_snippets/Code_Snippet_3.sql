Create table `mpd_g6_data.MPD_Clustering_Output`
AS
SELECT
Centroid_id as Cluster,
CustomerId,
CustDescr as Customer_name,
City,
Country
FROM
ML.PREDICT(MODEL `vlba-2024-mpd-group-6.mpd_g6_data.mpd_customer_clusters`, TABLE `vlba-2024-mpd-group-6.mpd_g6_data.MPD_CustomerData_ML` )