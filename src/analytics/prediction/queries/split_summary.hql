USE flightdb;
SET hive.cli.print.header=true;

SELECT split_set,
       data_year,
       COUNT(*) AS operated_flights,
       SUM(is_delayed) AS delayed_flights,
       ROUND(100.0 * SUM(is_delayed) / COUNT(*), 2) AS delay_pct
FROM flights_split
GROUP BY split_set, data_year
ORDER BY split_set, data_year;
