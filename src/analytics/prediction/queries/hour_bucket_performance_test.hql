USE flightdb;
SET hive.cli.print.header=true;
SELECT hour_bucket,
       ELT(hour_bucket + 1, '00-03', '04-07', '08-11', '12-15', '16-19', '20-23') AS dep_hours,
       COUNT(*) AS flights,
       ROUND(100.0 * SUM(is_delayed) / COUNT(*), 2) AS actual_delay_pct,
       ROUND(100.0 * SUM(CASE WHEN p >= ${hivevar:threshold} THEN 1 ELSE 0 END) / COUNT(*), 2) AS predicted_delayed_pct,
       ROUND(SUM(CASE WHEN (p >= ${hivevar:threshold} AND is_delayed = 1) OR (p < ${hivevar:threshold} AND is_delayed = 0) THEN 1 ELSE 0 END) / COUNT(*), 4) AS accuracy,
       ROUND(SUM(CASE WHEN p >= ${hivevar:threshold} AND is_delayed = 1 THEN 1 ELSE 0 END) / SUM(CASE WHEN p >= ${hivevar:threshold} THEN 1 ELSE 0 END), 4) AS prec,
       ROUND(SUM(CASE WHEN p >= ${hivevar:threshold} AND is_delayed = 1 THEN 1 ELSE 0 END) / SUM(is_delayed), 4) AS recall
FROM flights_scored
WHERE split_set = 'test'
GROUP BY hour_bucket
ORDER BY hour_bucket;
