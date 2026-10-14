USE flightdb;
DROP TABLE IF EXISTS flights_split;
CREATE TABLE flights_split
STORED AS TEXTFILE
AS
SELECT carrier,
       origin,
       dest,
       flight_month,
       dep_hour DIV 4 AS hour_bucket,
       is_delayed,
       `year` AS data_year,
       CASE WHEN `year` = ${hivevar:test_year} THEN 'test'
            WHEN pmod(hash(fl_date, carrier, flight_num, origin, dest, crs_dep_time), 10) = 9 THEN 'validation'
            ELSE 'train' END AS split_set
FROM flights_cleaned
WHERE cancelled = 0;
