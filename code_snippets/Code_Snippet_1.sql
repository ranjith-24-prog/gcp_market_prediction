Create table `mpd_g6_data.MPD_CustomerData_ML` AS
SELECT MPD_CustomerAttr.CustomerId, CustDescr, City, Country,
CASE Country
  WHEN 'BR' THEN 1
  WHEN 'CH' THEN 2
  WHEN 'DE' THEN 3
  WHEN 'FR' THEN 4
  WHEN 'US' THEN 5
  ELSE NULL
END AS Country_Num
FROM `mpd_g6_data.MPD_CustomerAttr`
JOIN `mpd_g6_data.MPD_CustomerText`
ON MPD_CustomerAttr.CustomerId = MPD_CustomerText.CustomerId
order by Country;