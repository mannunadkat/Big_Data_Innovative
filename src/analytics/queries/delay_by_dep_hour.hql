USE flightdb;
SET hive.cli.print.header=true;

SELECT t.dep_hour AS dep_hour,
       CASE WHEN t.dep_hour < 6 THEN 'Night (00-05)'
            WHEN t.dep_hour < 12 THEN 'Morning (06-11)'
            WHEN t.dep_hour < 18 THEN 'Afternoon (12-17)'
            ELSE 'Evening (18-23)' END AS time_bucket,
       t.total_flights AS total_flights,
       t.delayed_flights AS delayed_flights,
       t.delay_pct AS delay_pct,
       t.avg_dep_delay_min AS avg_dep_delay_min,
       t.avg_arr_delay_min AS avg_arr_delay_min
FROM (
  SELECT dep_hour,
         COUNT(*) AS total_flights,
         SUM(is_delayed) AS delayed_flights,
         ROUND(100.0 * SUM(is_delayed) / SUM(CASE WHEN cancelled = 0 THEN 1 ELSE 0 END), 2) AS delay_pct,
         ROUND(AVG(CASE WHEN cancelled = 0 THEN dep_delay END), 2) AS avg_dep_delay_min,
         ROUND(AVG(CASE WHEN cancelled = 0 THEN arr_delay END), 2) AS avg_arr_delay_min
  FROM flights_cleaned
  GROUP BY dep_hour
) t
ORDER BY dep_hour;
