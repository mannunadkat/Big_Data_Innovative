USE flightdb;
SET hive.cli.print.header=true;

SELECT o.airport AS airport,
       o.departures AS departures,
       o.dep_delay_pct AS dep_delay_pct,
       o.avg_dep_delay_min AS avg_dep_delay_min,
       d.arrivals AS arrivals,
       d.arr_delay_pct AS arr_delay_pct,
       d.avg_arr_delay_min AS avg_arr_delay_min
FROM (
  SELECT origin AS airport, COUNT(*) AS departures,
         ROUND(100.0 * SUM(CASE WHEN cancelled = 0 AND dep_delay >= 15 THEN 1 ELSE 0 END) / SUM(CASE WHEN cancelled = 0 THEN 1 ELSE 0 END), 2) AS dep_delay_pct,
         ROUND(AVG(CASE WHEN cancelled = 0 THEN dep_delay END), 2) AS avg_dep_delay_min
  FROM flights_cleaned GROUP BY origin HAVING COUNT(*) >= 10000
) o
JOIN (
  SELECT dest AS airport, COUNT(*) AS arrivals,
         ROUND(100.0 * SUM(is_delayed) / SUM(CASE WHEN cancelled = 0 THEN 1 ELSE 0 END), 2) AS arr_delay_pct,
         ROUND(AVG(CASE WHEN cancelled = 0 THEN arr_delay END), 2) AS avg_arr_delay_min
  FROM flights_cleaned GROUP BY dest HAVING COUNT(*) >= 10000
) d ON o.airport = d.airport
ORDER BY dep_delay_pct DESC
LIMIT 25;
