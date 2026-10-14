USE flightdb;
SET hive.cli.print.header=true;

SELECT origin AS airport,
       COUNT(*) AS total_departures,
       SUM(CASE WHEN weather_delay > 0 THEN 1 ELSE 0 END) AS flights_with_weather_delay,
       SUM(weather_delay) AS weather_delay_min,
       SUM(carrier_delay + weather_delay + nas_delay + security_delay + late_aircraft_delay) AS total_cause_delay_min,
       ROUND(100.0 * SUM(weather_delay) / SUM(carrier_delay + weather_delay + nas_delay + security_delay + late_aircraft_delay), 2) AS weather_share_pct,
       ROUND(1000.0 * SUM(weather_delay) / COUNT(*), 1) AS weather_min_per_1000_flights
FROM flights_cleaned
GROUP BY origin
HAVING COUNT(*) >= 10000
ORDER BY weather_min_per_1000_flights DESC
LIMIT 25;
