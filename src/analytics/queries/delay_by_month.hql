USE flightdb;
SET hive.cli.print.header=true;

SELECT flight_month AS month_num,
       COUNT(*) AS total_flights,
       SUM(cancelled) AS cancelled_flights,
       SUM(is_delayed) AS delayed_flights,
       ROUND(100.0 * SUM(is_delayed) / SUM(CASE WHEN cancelled = 0 THEN 1 ELSE 0 END), 2) AS delay_pct,
       ROUND(AVG(CASE WHEN cancelled = 0 THEN arr_delay END), 2) AS avg_arr_delay_min
FROM flights_cleaned
GROUP BY flight_month
ORDER BY month_num;
