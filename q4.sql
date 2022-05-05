-- Q4. Plane Capacity Histogram

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel;
DROP TABLE IF EXISTS q4 CASCADE;

CREATE TABLE q4 (
	airline CHAR(2),
	tail_number CHAR(5),
	very_low INT,
	low INT,
	fair INT,
	normal INT,
	high INT
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;
DROP VIEW IF EXISTS flightsDeparted CASCADE; 
DROP VIEW IF EXISTS planeInfo CASCADE;
DROP VIEW IF EXISTS bookedNumPerPlane CASCADE; 
DROP VIEW IF EXISTS flightPercentage CASCADE;
DROP VIEW IF EXISTS veryLow CASCADE;
DROP VIEW IF EXISTS low CASCADE;
DROP VIEW IF EXISTS fair CASCADE; 
DROP VIEW IF EXISTS normal CASCADE;
DROP VIEW IF EXISTS high CASCADE;
DROP VIEW IF EXISTS answer CASCADE; 
-- Define views for your intermediate steps here:

--flights that have actually departed
CREATE VIEW flightsDeparted AS 
SELECT *  
FROM departure JOIN flight ON departure.flight_id = flight.id; 

--airline and tail number of all planes 
CREATE VIEW planeInfo AS 
SELECT DISTINCT ON(Plane.tail_number) Plane.airline, Plane.tail_number, (plane.capacity_economy+plane.capacity_business+plane.capacity_first) AS totalCap, flight.id AS flightID
FROM flight JOIN Plane ON flight.plane = Plane.tail_number;
--GROUP BY Plane.airline, Plane.tail_number, flightID;
-- this finds out percenntage of how full flight has been only on flights that have actually departed bc of the third join
CREATE VIEW bookedNumPerPlane AS 
SELECT COUNT(booking.id) AS amountBooked, flight.id AS bID, flight.plane
FROM booking JOIN flight ON booking.flight_id = flight.id JOIN flightsDeparted on booking.flight_id = flightsDeparted.id
GROUP BY flight.id;

CREATE VIEW flightPercentage AS 
SELECT bookedNumPerPlane.amountBooked * 100.0 / planeInfo.totalCap AS percentageBooked, planeInfo.flightID as pID, planeInfo.tail_number
FROM bookedNumPerPlane JOIN planeInfo ON planeInfo.flightID = bookedNumPerPlane.bID;

CREATE VIEW veryLow AS 
SELECT planeInfo.airline, planeInfo.tail_number, COUNT(flightPercentage.percentageBooked) as countVL
FROM planeInfo JOIN flightPercentage ON planeInfo.flightID = flightPercentage.pID
WHERE flightPercentage.percentageBooked < 20
GROUP BY planeInfo.tail_number, planeInfo.airline; 

CREATE VIEW low AS 
SELECT planeInfo.airline, planeInfo.tail_number, COUNT(flightPercentage.percentageBooked) as countL
FROM planeInfo JOIN flightPercentage ON planeInfo.flightID = flightPercentage.pID
WHERE (flightPercentage.percentageBooked >= 20 and flightPercentage.percentageBooked < 40)
GROUP BY planeInfo.tail_number, planeInfo.airline; 

CREATE VIEW fair AS 
SELECT planeInfo.airline, planeInfo.tail_number, COUNT(flightPercentage.percentageBooked) as countF
FROM planeInfo JOIN flightPercentage ON planeInfo.flightID = flightPercentage.pID
WHERE (flightPercentage.percentageBooked >= 40 and flightPercentage.percentageBooked < 60)
GROUP BY planeInfo.tail_number, planeInfo.airline; 

CREATE VIEW normal AS 
SELECT planeInfo.airline, planeInfo.tail_number, COUNT(flightPercentage.percentageBooked) as countN
FROM planeInfo JOIN flightPercentage ON planeInfo.flightID = flightPercentage.pID
WHERE (flightPercentage.percentageBooked >= 60 and flightPercentage.percentageBooked < 80)
GROUP BY planeInfo.tail_number, planeInfo.airline; 

CREATE VIEW high AS 
SELECT planeInfo.airline, planeInfo.tail_number, COUNT(flightPercentage.percentageBooked) as countH
FROM planeInfo JOIN flightPercentage ON planeInfo.flightID = flightPercentage.pID
WHERE (flightPercentage.percentageBooked >= 80)
GROUP BY planeInfo.tail_number, planeInfo.airline; 

CREATE VIEW answer AS 
SELECT planeInfo.airline, planeInfo.tail_number, coalesce(high.countH,0) AS high, coalesce(normal.countN,0) AS normal, coalesce(fair.countF,0) AS fair, coalesce(low.countL,0) AS low, coalesce(veryLow.countVL,0) AS very_low
FROM planeInfo LEFT JOIN high ON planeInfo.tail_number = high.tail_number LEFT JOIN normal ON planeInfo.tail_number = normal.tail_number
LEFT JOIN fair ON planeInfo.tail_number = fair.tail_number LEFT JOIN low ON planeInfo.tail_number = low.tail_number
LEFT JOIN veryLow ON planeInfo.tail_number = veryLow.tail_number;

--select airline, tail_number, very_low, low, fair, normal, high from answer;
-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q4(airline, tail_number, very_low, low, fair, normal, high)
SELECT airline, tail_number, very_low, low, fair, normal, high
FROM answer; 
