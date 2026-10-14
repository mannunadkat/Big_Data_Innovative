USE flightdb;
SET hive.cli.print.header=true;
SELECT split_set,
       data_year,
       COUNT(*) AS scored_rows,
       SUM(is_delayed) AS delayed_flights
FROM flights_scored
GROUP BY split_set, data_year
ORDER BY split_set, data_year;
