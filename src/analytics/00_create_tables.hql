CREATE DATABASE IF NOT EXISTS flightdb;
USE flightdb;

DROP TABLE IF EXISTS flights_cleaned;
CREATE EXTERNAL TABLE flights_cleaned (
  fl_date STRING,
  flight_year INT,
  flight_month INT,
  day_of_month INT,
  day_of_week INT,
  carrier STRING,
  flight_num INT,
  origin STRING,
  dest STRING,
  crs_dep_time INT,
  dep_hour INT,
  dep_delay INT,
  arr_delay INT,
  cancelled INT,
  cancellation_code STRING,
  diverted INT,
  distance INT,
  carrier_delay INT,
  weather_delay INT,
  nas_delay INT,
  security_delay INT,
  late_aircraft_delay INT,
  is_delayed INT
)
PARTITIONED BY (`year` INT)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/flights/cleaned';

MSCK REPAIR TABLE flights_cleaned;

DROP TABLE IF EXISTS carriers_ref;
CREATE EXTERNAL TABLE carriers_ref (
  carrier STRING,
  carrier_name STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/flights/reference/carriers'
TBLPROPERTIES ('skip.header.line.count'='1');
