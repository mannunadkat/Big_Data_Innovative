USE flightdb;
SET hive.cli.print.header=true;

SELECT carrier, origin, dest, flight_month, hour_bucket, n, delayed, ROUND(p, 4) AS p
FROM model_l1
ORDER BY n DESC
LIMIT 10;
