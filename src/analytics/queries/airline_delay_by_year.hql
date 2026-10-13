USE flightdb;
SET hive.cli.print.header=true;

SELECT f.carrier AS carrier,
       f.`year` AS data_year,
       COUNT(*) AS total_flights,
       ROUND(100.0 * SUM(f.is_delayed) / SUM(CASE WHEN f.cancelled = 0 THEN 1 ELSE 0 END), 2) AS delay_pct,
       ROUND(AVG(CASE WHEN f.cancelled = 0 THEN f.arr_delay END), 2) AS avg_arr_delay_min
FROM flights_cleaned f
GROUP BY f.carrier, f.`year`
ORDER BY carrier, data_year;
