USE flightdb;
SET hive.cli.print.header=true;

SELECT f.carrier AS carrier,
       COALESCE(c.carrier_name, f.carrier) AS carrier_name,
       COUNT(*) AS total_flights,
       SUM(f.cancelled) AS cancelled_flights,
       ROUND(100.0 * SUM(f.cancelled) / COUNT(*), 2) AS cancel_pct
FROM flights_cleaned f
LEFT JOIN carriers_ref c ON f.carrier = c.carrier
GROUP BY f.carrier, c.carrier_name
ORDER BY cancel_pct DESC;
