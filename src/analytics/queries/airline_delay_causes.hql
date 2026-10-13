USE flightdb;
SET hive.cli.print.header=true;

SELECT f.carrier AS carrier,
       COALESCE(c.carrier_name, f.carrier) AS carrier_name,
       SUM(f.carrier_delay) AS carrier_delay_min,
       SUM(f.weather_delay) AS weather_delay_min,
       SUM(f.nas_delay) AS nas_delay_min,
       SUM(f.security_delay) AS security_delay_min,
       SUM(f.late_aircraft_delay) AS late_aircraft_delay_min,
       SUM(f.carrier_delay + f.weather_delay + f.nas_delay + f.security_delay + f.late_aircraft_delay) AS total_cause_delay_min
FROM flights_cleaned f
LEFT JOIN carriers_ref c ON f.carrier = c.carrier
GROUP BY f.carrier, c.carrier_name
ORDER BY total_cause_delay_min DESC;
