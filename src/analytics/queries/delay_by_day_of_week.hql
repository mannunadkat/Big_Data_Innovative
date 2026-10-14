USE flightdb;
SET hive.cli.print.header=true;

SELECT t.day_of_week AS day_num,
       ELT(t.day_of_week, 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun') AS day_name,
       t.total_flights AS total_flights,
       t.delayed_flights AS delayed_flights,
       t.delay_pct AS delay_pct,
       t.avg_arr_delay_min AS avg_arr_delay_min
FROM (
  SELECT day_of_week,
         COUNT(*) AS total_flights,
         SUM(is_delayed) AS delayed_flights,
         ROUND(100.0 * SUM(is_delayed) / SUM(CASE WHEN cancelled = 0 THEN 1 ELSE 0 END), 2) AS delay_pct,
         ROUND(AVG(CASE WHEN cancelled = 0 THEN arr_delay END), 2) AS avg_arr_delay_min
  FROM flights_cleaned
  GROUP BY day_of_week
) t
ORDER BY day_num;
