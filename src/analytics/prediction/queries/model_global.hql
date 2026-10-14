USE flightdb;
SET hive.cli.print.header=true;

SELECT n, delayed, ROUND(p, 4) AS p FROM model_global;
