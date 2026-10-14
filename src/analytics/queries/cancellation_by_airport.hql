USE flightdb;
SET hive.cli.print.header=true;

SELECT origin AS airport,
       COUNT(*) AS total_departures,
       SUM(cancelled) AS cancelled_flights,
       ROUND(100.0 * SUM(cancelled) / COUNT(*), 2) AS cancel_pct,
       SUM(CASE WHEN cancellation_code = 'B' THEN 1 ELSE 0 END) AS weather_cancellations
FROM flights_cleaned
GROUP BY origin
HAVING COUNT(*) >= 10000
ORDER BY cancel_pct DESC
LIMIT 25;
