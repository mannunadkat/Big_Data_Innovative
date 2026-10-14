USE flightdb;
SET hive.cli.print.header=true;
SHOW TABLES;
SELECT split_set, COUNT(*) AS operated_flights FROM flights_split GROUP BY split_set ORDER BY split_set;
