USE flightdb;
SET hive.cli.print.header=true;

SELECT t.cancellation_code AS cancellation_code,
       CASE t.cancellation_code WHEN 'A' THEN 'Carrier'
                                WHEN 'B' THEN 'Weather'
                                WHEN 'C' THEN 'National Air System'
                                WHEN 'D' THEN 'Security'
                                ELSE 'Unknown' END AS reason,
       t.cancelled_flights AS cancelled_flights,
       ROUND(100.0 * t.cancelled_flights / SUM(t.cancelled_flights) OVER (), 2) AS pct_of_cancellations
FROM (
  SELECT cancellation_code, COUNT(*) AS cancelled_flights
  FROM flights_cleaned
  WHERE cancelled = 1
  GROUP BY cancellation_code
) t
ORDER BY cancelled_flights DESC;
