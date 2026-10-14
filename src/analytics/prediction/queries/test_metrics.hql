USE flightdb;
SET hive.cli.print.header=true;
SELECT c.tp AS tp, c.fp AS fp, c.fn AS fn, c.tn AS tn,
       c.tp + c.fp + c.fn + c.tn AS test_rows,
       ROUND((c.tp + c.tn) / (c.tp + c.fp + c.fn + c.tn), 4) AS accuracy,
       ROUND(c.tp / (c.tp + c.fp), 4) AS prec,
       ROUND(c.tp / (c.tp + c.fn), 4) AS recall,
       ROUND(2.0 * c.tp / (2.0 * c.tp + c.fp + c.fn), 4) AS f1,
       ROUND(100.0 * (c.tp + c.fn) / (c.tp + c.fp + c.fn + c.tn), 2) AS test_delay_pct,
       ROUND(GREATEST(c.tp + c.fn, c.fp + c.tn) / (c.tp + c.fp + c.fn + c.tn), 4) AS baseline_accuracy,
       ROUND(2.0 * (c.tp + c.fn) / ((c.tp + c.fn) + (c.tp + c.fp + c.fn + c.tn)), 4) AS baseline_f1_always_delayed,
       ROUND((c.tp / (c.tp + c.fp)) / ((c.tp + c.fn) / (c.tp + c.fp + c.fn + c.tn)), 3) AS lift
FROM (
  SELECT SUM(CASE WHEN p >= ${hivevar:threshold} AND is_delayed = 1 THEN 1 ELSE 0 END) AS tp,
         SUM(CASE WHEN p >= ${hivevar:threshold} AND is_delayed = 0 THEN 1 ELSE 0 END) AS fp,
         SUM(CASE WHEN p <  ${hivevar:threshold} AND is_delayed = 1 THEN 1 ELSE 0 END) AS fn,
         SUM(CASE WHEN p <  ${hivevar:threshold} AND is_delayed = 0 THEN 1 ELSE 0 END) AS tn
  FROM flights_scored
  WHERE split_set = 'test'
) c;
