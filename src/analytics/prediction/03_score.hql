USE flightdb;
SET hive.auto.convert.join=false;
DROP TABLE IF EXISTS flights_scored;
CREATE TABLE flights_scored STORED AS TEXTFILE AS
SELECT s.split_set AS split_set,
       s.data_year AS data_year,
       s.carrier AS carrier,
       s.hour_bucket AS hour_bucket,
       s.is_delayed AS is_delayed,
       COALESCE(m1.p, m2.p, m3.p, m4.p, CAST('${hivevar:global_p}' AS DOUBLE)) AS p,
       CASE WHEN m1.p IS NOT NULL THEN 'L1'
            WHEN m2.p IS NOT NULL THEN 'L2'
            WHEN m3.p IS NOT NULL THEN 'L3'
            WHEN m4.p IS NOT NULL THEN 'L4'
            ELSE 'GLOBAL' END AS level_used
FROM (
  SELECT carrier, origin, dest, flight_month, hour_bucket, is_delayed, data_year, split_set
  FROM flights_split
  WHERE split_set IN ('validation', 'test')
) s
LEFT JOIN model_l1 m1 ON s.carrier = m1.carrier AND s.origin = m1.origin AND s.dest = m1.dest
                      AND s.flight_month = m1.flight_month AND s.hour_bucket = m1.hour_bucket
LEFT JOIN model_l2 m2 ON s.carrier = m2.carrier AND s.origin = m2.origin
                      AND s.flight_month = m2.flight_month AND s.hour_bucket = m2.hour_bucket
LEFT JOIN model_l3 m3 ON s.origin = m3.origin AND s.hour_bucket = m3.hour_bucket
LEFT JOIN model_l4 m4 ON s.carrier = m4.carrier AND s.hour_bucket = m4.hour_bucket;
