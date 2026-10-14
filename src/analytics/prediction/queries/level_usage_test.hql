USE flightdb;
SET hive.cli.print.header=true;
SELECT level_used,
       COUNT(*) AS flights,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_test,
       ROUND(100.0 * SUM(is_delayed) / COUNT(*), 2) AS actual_delay_pct,
       ROUND(AVG(p), 4) AS avg_pred_p,
       ROUND(SUM(CASE WHEN (p >= ${hivevar:threshold} AND is_delayed = 1) OR (p < ${hivevar:threshold} AND is_delayed = 0) THEN 1 ELSE 0 END) / COUNT(*), 4) AS accuracy
FROM flights_scored
WHERE split_set = 'test'
GROUP BY level_used
ORDER BY level_used;
