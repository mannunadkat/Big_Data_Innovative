USE flightdb;
SET hive.cli.print.header=true;
SELECT ROUND(FLOOR(p * 20) / 20, 2) AS p_bin_low,
       COUNT(*) AS flights,
       ROUND(AVG(p), 4) AS avg_pred_p,
       ROUND(AVG(is_delayed), 4) AS actual_rate
FROM flights_scored
WHERE split_set = 'test'
GROUP BY FLOOR(p * 20)
ORDER BY p_bin_low;
