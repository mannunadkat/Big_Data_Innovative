USE flightdb;
SET hive.cli.print.header=true;

SELECT origin AS airport,
       COUNT(*) AS total_departures,
       SUM(cancelled) AS cancelled_departures,
       ROUND(100.0 * SUM(CASE WHEN cancelled = 0 AND dep_delay >= 15 THEN 1 ELSE 0 END) / SUM(CASE WHEN cancelled = 0 THEN 1 ELSE 0 END), 2) AS dep_delay_pct,
       ROUND(AVG(CASE WHEN cancelled = 0 THEN dep_delay END), 2) AS avg_dep_delay_min
FROM flights_cleaned
GROUP BY origin
HAVING COUNT(*) >= 10000
ORDER BY dep_delay_pct DESC
LIMIT 25;
