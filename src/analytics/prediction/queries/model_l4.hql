USE flightdb;
SET hive.cli.print.header=true;

SELECT carrier, hour_bucket, n, delayed, ROUND(p, 4) AS p
FROM model_l4
ORDER BY carrier, hour_bucket;
