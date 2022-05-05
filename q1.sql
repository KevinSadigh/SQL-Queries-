-- Q1. Airlines

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel;
DROP TABLE IF EXISTS q1 CASCADE;

CREATE TABLE q1 (
    pass_id INT,
    name VARCHAR(100),
    airlines INT
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;
DROP VIEW IF EXISTS numberOfFlights CASCADE;
DROP VIEW IF EXISTS passengerName CASCADE;
DROP VIEW IF EXISTS answer CASCADE; 
DROP VIEW IF EXISTS departedFlights CASCADE;
-- Define views for your intermediate steps here:
--Finds flights that acc departed 
CREATE VIEW departedFlights AS 
SELECT *  
FROM departure JOIN flight ON departure.flight_id = flight.id; 
--finds total number of flights that the passenger took
CREATE VIEW numberOfFlights AS 
SELECT pass_id, COUNT(DISTINCT departedFlights.airline) AS num_flights
FROM booking JOIN departedFlights ON booking.flight_id = departedFlights.id
GROUP BY pass_id;
--find the passenger name and concatinate it 
CREATE VIEW passengerName AS
SELECT id as pass_id, CONCAT(firstname, ' ', surname) AS pass_name
FROM passenger;
--FROM booking JOIN passenger ON pass_id = passenger.id;

CREATE VIEW answer AS 
SELECT DISTINCT p1.pass_id,pass_name, num_flights
FROM passengerName p1 LEFT JOIN numberOfFlights p2 ON p1.pass_id = p2.pass_id;  

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q1(pass_id, name, airlines)
SELECT pass_id, pass_name, num_flights
FROM answer; 