USE flightdb;
SET hive.cli.print.header=true;

SELECT origin,
       dest,
       CONCAT(origin, '-', dest) AS route,
       COUNT(*) AS total_flights,
       ROUND(100.0 * SUM(is_delayed) / SUM(CASE WHEN cancelled = 0 THEN 1 ELSE 0 END), 2) AS delay_pct,
       ROUND(AVG(CASE WHEN cancelled = 0 THEN arr_delay END), 2) AS avg_arr_delay_min,
       ROUND(AVG(distance), 0) AS avg_distance_mi
FROM flights_cleaned
GROUP BY origin, dest
HAVING COUNT(*) >= 2000
ORDER BY delay_pct DESC
LIMIT 25;
