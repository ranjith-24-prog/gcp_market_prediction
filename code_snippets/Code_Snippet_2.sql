CREATE OR REPLACE MODEL `vlba-2024-mpd-group-6.mpd_g6_data.mpd_customer_clusters`
OPTIONS(
  MODEL_TYPE = 'KMEANS',
  NUM_CLUSTERS = 5,
  STANDARDIZE_FEATURES = FALSE
) AS
SELECT
Country_Num
FROM
`vlba-2024-mpd-group-6.mpd_g6_data.MPD_CustomerData_ML`