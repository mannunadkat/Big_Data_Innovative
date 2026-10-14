USE flightdb;
SET hive.cli.print.header=true;
SELECT ROUND(c.thr_pct / 100.0, 2) AS threshold,
       c.tp AS tp, c.fp AS fp, c.fn AS fn, c.tn AS tn,
       ROUND(c.tp / (c.tp + c.fp), 4) AS prec,
       ROUND(c.tp / (c.tp + c.fn), 4) AS recall,
       ROUND(2.0 * c.tp / (2.0 * c.tp + c.fp + c.fn), 4) AS f1,
       ROUND((c.tp + c.tn) / (c.tp + c.fp + c.fn + c.tn), 4) AS accuracy
FROM (
  SELECT x.thr_pct AS thr_pct,
         SUM(CASE WHEN f.p >= x.thr_pct / 100.0 AND f.is_delayed = 1 THEN 1 ELSE 0 END) AS tp,
         SUM(CASE WHEN f.p >= x.thr_pct / 100.0 AND f.is_delayed = 0 THEN 1 ELSE 0 END) AS fp,
         SUM(CASE WHEN f.p <  x.thr_pct / 100.0 AND f.is_delayed = 1 THEN 1 ELSE 0 END) AS fn,
         SUM(CASE WHEN f.p <  x.thr_pct / 100.0 AND f.is_delayed = 0 THEN 1 ELSE 0 END) AS tn
  FROM flights_scored f
  LATERAL VIEW explode(array(6,8,10,12,14,16,18,20,22,24,26,28,30,32,34,36,38,40,42,44,46,48,50)) x AS thr_pct
  WHERE f.split_set = '${hivevar:split_name}'
  GROUP BY x.thr_pct
) c
ORDER BY threshold;
