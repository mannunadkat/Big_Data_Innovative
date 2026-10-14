USE flightdb;
SET hive.cli.print.header=true;

SELECT flight_month AS month_num,
       COUNT(*) AS total_flights,
       SUM(CASE WHEN weather_delay > 0 THEN 1 ELSE 0 END) AS flights_with_weather_delay,
       SUM(weather_delay) AS weather_delay_min,
       ROUND(100.0 * SUM(weather_delay) / SUM(carrier_delay + weather_delay + nas_delay + security_delay + late_aircraft_delay), 2) AS weather_share_pct,
       ROUND(SUM(weather_delay) / SUM(CASE WHEN weather_delay > 0 THEN 1 ELSE 0 END), 1) AS avg_weather_delay_per_affected_flight_min,
       SUM(CASE WHEN cancellation_code = 'B' THEN 1 ELSE 0 END) AS weather_cancellations
FROM flights_cleaned
GROUP BY flight_month
ORDER BY month_num;
