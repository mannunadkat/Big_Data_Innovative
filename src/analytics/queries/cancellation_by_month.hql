USE flightdb;
SET hive.cli.print.header=true;

SELECT flight_month AS month_num,
       COUNT(*) AS total_flights,
       SUM(cancelled) AS cancelled_flights,
       ROUND(100.0 * SUM(cancelled) / COUNT(*), 2) AS cancel_pct,
       SUM(CASE WHEN cancellation_code = 'A' THEN 1 ELSE 0 END) AS carrier_cancels,
       SUM(CASE WHEN cancellation_code = 'B' THEN 1 ELSE 0 END) AS weather_cancels,
       SUM(CASE WHEN cancellation_code = 'C' THEN 1 ELSE 0 END) AS nas_cancels,
       SUM(CASE WHEN cancellation_code = 'D' THEN 1 ELSE 0 END) AS security_cancels
FROM flights_cleaned
GROUP BY flight_month
ORDER BY month_num;
