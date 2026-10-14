USE flightdb;
SET hive.cli.print.header=true;

SELECT * FROM (
  SELECT 'L1 carrier+origin+dest+month+hour_bucket' AS model_level, COUNT(*) AS model_keys, SUM(n) AS flights_covered, ROUND(MIN(p), 4) AS min_p, ROUND(AVG(p), 4) AS avg_p_over_keys, ROUND(MAX(p), 4) AS max_p FROM model_l1
  UNION ALL
  SELECT 'L2 carrier+origin+month+hour_bucket', COUNT(*), SUM(n), ROUND(MIN(p), 4), ROUND(AVG(p), 4), ROUND(MAX(p), 4) FROM model_l2
  UNION ALL
  SELECT 'L3 origin+hour_bucket', COUNT(*), SUM(n), ROUND(MIN(p), 4), ROUND(AVG(p), 4), ROUND(MAX(p), 4) FROM model_l3
  UNION ALL
  SELECT 'L4 carrier+hour_bucket', COUNT(*), SUM(n), ROUND(MIN(p), 4), ROUND(AVG(p), 4), ROUND(MAX(p), 4) FROM model_l4
  UNION ALL
  SELECT 'GLOBAL', COUNT(*), SUM(n), ROUND(MIN(p), 4), ROUND(AVG(p), 4), ROUND(MAX(p), 4) FROM model_global
) t
ORDER BY model_level;
