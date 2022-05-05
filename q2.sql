-- Q2. Refunds!

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel;
DROP TABLE IF EXISTS q2 CASCADE;

CREATE TABLE q2 (
    airline CHAR(2),
    name VARCHAR(50),
    year CHAR(4),
    seat_class seat_class,
    refund REAL
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;
DROP VIEW IF EXISTS outboundFlight CASCADE;
DROP VIEW IF EXISTS inboundFlight CASCADE;
DROP VIEW IF EXISTS domesticFlights CASCADE;
DROP VIEW IF EXISTS internationalFlights CASCADE;
DROP VIEW IF EXISTS domesticDelayedFive CASCADE;
DROP VIEW IF EXISTS internationalDelayedEight CASCADE;
DROP VIEW IF EXISTS domesticDelayedTen CASCADE;
DROP VIEW IF EXISTS internationalDelayedTwelve CASCADE;
DROP VIEW IF EXISTS madeUpTimeDomesticFive CASCADE;
DROP VIEW IF EXISTS madeUpTimeDomesticTen CASCADE;
DROP VIEW IF EXISTS madeUpTimeIntEight CASCADE;
DROP VIEW IF EXISTS madeUpTimeIntTwelve CASCADE;
DROP VIEW IF EXISTS offerRefundDom35Percent CASCADE;
DROP VIEW IF EXISTS offerRefundDom50Percent CASCADE;
DROP VIEW IF EXISTS offerRefundInt35Percent CASCADE;
DROP VIEW IF EXISTS offerRefundInt50Percent CASCADE;
DROP VIEW IF EXISTS refundDomestic35 CASCADE;
DROP VIEW IF EXISTS refundDomestic50 CASCADE;
DROP VIEW IF EXISTS refundInt35 CASCADE;
DROP VIEW IF EXISTS refundInt50 CASCADE;
DROP VIEW IF EXISTS everything CASCADE;
DROP VIEW IF EXISTS totalRefund CASCADE;
DROP VIEW IF EXISTS answer CASCADE; 
-- Define views for your intermediate steps here:

--first find all outbound flights airports and countires then do the same for inbound dont try and do it all in one query 
CREATE VIEW outboundFlight AS 
SELECT flight.id, flight.outbound, flight.s_dep, flight.s_arv, airport.code, airport.country
FROM flight JOIN airport ON flight.outbound = airport.code;

CREATE VIEW inboundFlight AS    
SELECT flight.id, flight.inbound, flight.s_dep, flight.s_arv, airport.code, airport.country
FROM flight JOIN airport ON flight.inbound = airport.code;

--find the domestic flights then do the same for international flights 
CREATE VIEW domesticFlights AS 
SELECT DISTINCT inboundFlight.id as domesticID, inboundFlight.s_dep, inboundFlight.s_arv 
FROM inboundFlight JOIN outboundFlight ON (inboundFlight.country = outboundFlight.country and inboundFlight.id = outboundFlight.id);

CREATE VIEW internationalFlights AS 
SELECT DISTINCT inboundFlight.id as internationalID, inboundFlight.s_dep, inboundFlight.s_arv
FROM inboundFlight JOIN outboundFlight ON (inboundFlight.country <> outboundFlight.country and inboundFlight.id = outboundFlight.id);
--find the domestic flights delayed by more than 5 hours but less than 10 hours 
CREATE VIEW domesticDelayedFive AS 
SELECT domesticFlights.domesticID as delayedID, departure.datetime - domesticFlights.s_dep AS domDepDelay, domesticFlights.s_arv 
FROM domesticFlights JOIN departure ON domesticFlights.domesticID = departure.flight_id
WHERE (departure.datetime - domesticFlights.s_dep >= '05:00:00' and departure.datetime - domesticFlights.s_dep < '10:00:00'); --do less than 10 later too when adding another view
--find the international flights delayed by more than 8 hours but less than 12 hours 
CREATE VIEW internationalDelayedEight AS 
SELECT internationalFlights.internationalID as iDelayedID, departure.datetime - internationalFlights.s_dep AS intDepDelay, internationalFlights.s_arv
FROM internationalFlights JOIN departure ON internationalFlights.internationalID = departure.flight_id
WHERE (departure.datetime - internationalFlights.s_dep >= '08:00:00' and departure.datetime - internationalFlights.s_dep < '12:00:00');
--find the domestic flights delayed by more than 10 hours 
CREATE VIEW domesticDelayedTen AS 
SELECT domesticFlights.domesticID as delayedIDTen, departure.datetime - domesticFlights.s_dep AS domDepDelay, domesticFlights.s_arv  
FROM domesticFlights JOIN departure ON domesticFlights.domesticID = departure.flight_id
WHERE departure.datetime - domesticFlights.s_dep >= '10:00:00';
--find the international flights delayed by more than 12 hoursand find out the exact delay to use in the next views to see if pilot made up flight  
CREATE VIEW internationalDelayedTwelve AS 
SELECT internationalFlights.internationalID as iDelayedIDTwelve, departure.datetime - internationalFlights.s_dep AS intDepDelay, internationalFlights.s_arv
FROM internationalFlights JOIN departure ON internationalFlights.internationalID = departure.flight_id
WHERE departure.datetime - internationalFlights.s_dep >= '12:00:00';
--check if the pilots made up time during the flight using the arrival relation and scheduled arrival and comparing it with the depDelays 
--check if any of the 4 flight classes made up time 
CREATE VIEW madeUpTimeDomesticFive AS 
SELECT domesticDelayedFive.delayedID 
FROM domesticDelayedFive JOIN arrival ON domesticDelayedFive.delayedID = arrival.flight_id
WHERE arrival.datetime - domesticDelayedFive.s_arv < (domesticDelayedFive.domDepDelay * 0.5);

CREATE VIEW madeUpTimeDomesticTen AS 
SELECT domesticDelayedTen.delayedIDTen, arrival.datetime - domesticDelayedTen.s_arv as delay1
FROM domesticDelayedTen JOIN arrival ON domesticDelayedTen.delayedIDTen = arrival.flight_id
WHERE arrival.datetime - domesticDelayedTen.s_arv < (domesticDelayedTen.domDepDelay * 0.5);

CREATE VIEW madeUpTimeIntEight AS 
SELECT internationalDelayedEight.iDelayedID 
FROM internationalDelayedEight JOIN arrival ON internationalDelayedEight.iDelayedID = arrival.flight_id
WHERE arrival.datetime - internationalDelayedEight.s_arv < (internationalDelayedEight.intDepDelay * 0.5);

CREATE VIEW madeUpTimeIntTwelve AS 
SELECT internationalDelayedTwelve.iDelayedIDTwelve, arrival.datetime - internationalDelayedTwelve.s_arv as delay1
FROM internationalDelayedTwelve JOIN arrival ON internationalDelayedTwelve.iDelayedIDTwelve = arrival.flight_id
WHERE arrival.datetime - internationalDelayedTwelve.s_arv < (internationalDelayedTwelve.intDepDelay * 0.5);
--find the flights that dont need refunds 
CREATE VIEW offerRefundDom35Percent AS 
(SELECT domesticDelayedFive.delayedID FROM domesticDelayedFive)
except 
(SELECT madeUpTimeDomesticFive.delayedID FROM madeUpTimeDomesticFive); 

CREATE VIEW offerRefundDom50Percent AS 
(SELECT domesticDelayedTen.delayedIDTen FROM domesticDelayedTen)
except 
(SELECT madeUpTimeDomesticTen.delayedIDTen FROM madeUpTimeDomesticTen); 

CREATE VIEW offerRefundInt35Percent AS 
(SELECT internationalDelayedEight.iDelayedID FROM internationalDelayedEight)
except 
(SELECT madeUpTimeIntEight.iDelayedID FROM madeUpTimeIntEight);

CREATE VIEW offerRefundInt50Percent AS 
(SELECT internationalDelayedTwelve.iDelayedIDTwelve FROM internationalDelayedTwelve)
except 
(SELECT madeUpTimeIntTwelve.iDelayedIDTwelve FROM madeUpTimeIntTwelve);
--find total refunds for each class
CREATE VIEW refundDomestic35 AS 
SELECT sum(booking.price * 0.35) AS refund, offerRefundDom35Percent.delayedID as refundID, booking.seat_class, flight.airline, EXTRACT(YEAR FROM flight.s_arv) as yearFlight
FROM booking JOIN offerRefundDom35Percent ON booking.flight_id = offerRefundDom35Percent.delayedID JOIN flight ON booking.flight_id = flight.id
GROUP BY booking.seat_class, offerRefundDom35Percent.delayedID, flight.airline, yearFlight;

CREATE VIEW refundDomestic50 AS 
SELECT sum(booking.price * 0.50) AS refund, offerRefundDom50Percent.delayedIDTen as refundID, booking.seat_class, flight.airline, EXTRACT(YEAR FROM flight.s_arv) as yearFlight
FROM booking JOIN offerRefundDom50Percent ON booking.flight_id = offerRefundDom50Percent.delayedIDTen JOIN flight ON booking.flight_id = flight.id
GROUP BY booking.seat_class, offerRefundDom50Percent.delayedIDTen, flight.airline, yearFlight;

CREATE VIEW refundInt35 AS 
SELECT sum(booking.price * 0.35) AS refund, offerRefundInt35Percent.iDelayedID as refundID, booking.seat_class, flight.airline, EXTRACT(YEAR FROM flight.s_arv) as yearFlight
FROM booking JOIN offerRefundInt35Percent ON booking.flight_id = offerRefundInt35Percent.iDelayedID JOIN flight ON booking.flight_id = flight.id
GROUP BY booking.seat_class, offerRefundInt35Percent.iDelayedID, flight.airline, yearFlight;

CREATE VIEW refundInt50 AS 
SELECT sum(booking.price * 0.50) AS refund, offerRefundInt50Percent.iDelayedIDTwelve as refundID, booking.seat_class, flight.airline, EXTRACT(YEAR FROM flight.s_arv) as yearFlight
FROM booking JOIN offerRefundInt50Percent ON booking.flight_id = offerRefundInt50Percent.iDelayedIDTwelve JOIN flight ON booking.flight_id = flight.id
GROUP BY booking.seat_class, offerRefundInt50Percent.iDelayedIDTwelve, flight.airline, yearFlight;

CREATE VIEW everything AS 
SELECT * FROM refundDomestic50 
UNION 
SELECT * FROM refundInt50
UNION 
SELECT * FROM refundDomestic35
UNION 
SELECT * FROM refundInt35;
--count then group by airline and done 
CREATE VIEW answer AS 
SELECT everything.airline, airline.name, everything.yearFLight, everything.seat_class, sum(everything.refund) as refund
FROM everything JOIN airline ON everything.airline = airline.code
GROUP BY everything.airline, everything.seat_class, everything.yearFLight, airline.name;
-- Your query that answers the question goes below the "insert into" line:

INSERT INTO q2(airline, name, year, seat_class, refund)
SELECT answer.airline, answer.name, answer.yearFlight, answer.seat_class, answer.refund
FROM answer; 

-- for this we need the flight relation to get the scheduled departure and arrival and then the 
-- departure and arrival relations to see when the actual time is and the airline relation to get 
-- the code and name of the airline, as well as the price class to caluclate the refund and the 
-- cost per class