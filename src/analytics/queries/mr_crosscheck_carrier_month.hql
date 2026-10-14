USE flightdb;
SET hive.cli.print.header=false;
SELECT carrier,
       `year`,
       flight_month,
       COUNT(*),
       SUM(cancelled),
       SUM(CASE WHEN cancelled = 0 THEN 1 ELSE 0 END),
       SUM(is_delayed),
       SUM(CASE WHEN cancelled = 0 THEN arr_delay ELSE 0 END)
FROM flights_cleaned
GROUP BY carrier, `year`, flight_month;
