USE flightdb;
SET hive.cli.print.header=true;

SELECT origin, hour_bucket, n, delayed, ROUND(p, 4) AS p
FROM model_l3
ORDER BY origin, hour_bucket;
