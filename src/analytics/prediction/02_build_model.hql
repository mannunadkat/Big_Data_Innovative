USE flightdb;

DROP TABLE IF EXISTS model_global;
CREATE TABLE model_global STORED AS TEXTFILE AS
SELECT COUNT(*) AS n,
       SUM(is_delayed) AS delayed,
       SUM(is_delayed) / COUNT(*) AS p
FROM flights_split
WHERE split_set = 'train';

DROP TABLE IF EXISTS model_l1;
CREATE TABLE model_l1 STORED AS TEXTFILE AS
SELECT carrier, origin, dest, flight_month, hour_bucket,
       COUNT(*) AS n,
       SUM(is_delayed) AS delayed,
       SUM(is_delayed) / COUNT(*) AS p
FROM flights_split
WHERE split_set = 'train'
GROUP BY carrier, origin, dest, flight_month, hour_bucket
HAVING COUNT(*) >= ${hivevar:min_support};

DROP TABLE IF EXISTS model_l2;
CREATE TABLE model_l2 STORED AS TEXTFILE AS
SELECT carrier, origin, flight_month, hour_bucket,
       COUNT(*) AS n,
       SUM(is_delayed) AS delayed,
       SUM(is_delayed) / COUNT(*) AS p
FROM flights_split
WHERE split_set = 'train'
GROUP BY carrier, origin, flight_month, hour_bucket
HAVING COUNT(*) >= ${hivevar:min_support};

DROP TABLE IF EXISTS model_l3;
CREATE TABLE model_l3 STORED AS TEXTFILE AS
SELECT origin, hour_bucket,
       COUNT(*) AS n,
       SUM(is_delayed) AS delayed,
       SUM(is_delayed) / COUNT(*) AS p
FROM flights_split
WHERE split_set = 'train'
GROUP BY origin, hour_bucket
HAVING COUNT(*) >= ${hivevar:min_support};

DROP TABLE IF EXISTS model_l4;
CREATE TABLE model_l4 STORED AS TEXTFILE AS
SELECT carrier, hour_bucket,
       COUNT(*) AS n,
       SUM(is_delayed) AS delayed,
       SUM(is_delayed) / COUNT(*) AS p
FROM flights_split
WHERE split_set = 'train'
GROUP BY carrier, hour_bucket
HAVING COUNT(*) >= ${hivevar:min_support};
