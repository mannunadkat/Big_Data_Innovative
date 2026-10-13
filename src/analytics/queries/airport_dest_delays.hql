USE flightdb;
SET hive.cli.print.header=true;

SELECT dest AS airport,
       COUNT(*) AS total_arrivals,
       ROUND(100.0 * SUM(is_delayed) / SUM(CASE WHEN cancelled = 0 THEN 1 ELSE 0 END), 2) AS arr_delay_pct,
       ROUND(AVG(CASE WHEN cancelled = 0 THEN arr_delay END), 2) AS avg_arr_delay_min
FROM flights_cleaned
GROUP BY dest
HAVING COUNT(*) >= 10000
ORDER BY arr_delay_pct DESC
LIMIT 25;
