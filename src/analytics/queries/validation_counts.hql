USE flightdb;
SET hive.cli.print.header=true;
SELECT `year` AS data_year, COUNT(*) AS rows_in_hive, SUM(cancelled) AS cancelled_rows,
       SUM(is_delayed) AS delayed_rows
FROM flights_cleaned
GROUP BY `year`
ORDER BY data_year;
