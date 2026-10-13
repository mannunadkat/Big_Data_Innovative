USE flightdb;
SET hive.cli.print.header=true;

SELECT f.carrier AS carrier,
       COALESCE(c.carrier_name, f.carrier) AS carrier_name,
       COUNT(*) AS total_flights,
       SUM(f.cancelled) AS cancelled_flights,
       SUM(CASE WHEN f.cancelled = 0 THEN 1 ELSE 0 END) AS operated_flights,
       SUM(f.is_delayed) AS delayed_flights,
       ROUND(100.0 * SUM(f.is_delayed) / SUM(CASE WHEN f.cancelled = 0 THEN 1 ELSE 0 END), 2) AS delay_pct,
       ROUND(AVG(CASE WHEN f.cancelled = 0 THEN f.dep_delay END), 2) AS avg_dep_delay_min,
       ROUND(AVG(CASE WHEN f.cancelled = 0 THEN f.arr_delay END), 2) AS avg_arr_delay_min
FROM flights_cleaned f
LEFT JOIN carriers_ref c ON f.carrier = c.carrier
GROUP BY f.carrier, c.carrier_name
ORDER BY delay_pct DESC;
