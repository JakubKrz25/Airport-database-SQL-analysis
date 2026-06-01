USE airportdb;

-- We find how long on average are flights chosen by man and women.


WITH duration AS
			(
			SELECT
				p.passenger_id,
				p.sex,
				timestampdiff(minute, f.departure, f.arrival) AS minutes
			FROM booking b
			JOIN flight f
				ON f.flight_id=b.flight_id
			JOIN passengerdetails p
				ON p.passenger_id=b.passenger_id
			),
            
avg_duration AS
			(
			SELECT
				sex,
				avg(minutes) as average_duration
			FROM duration
			GROUP BY sex
			)
            
            
SELECT
	sex,
    CONCAT(FLOOR(average_duration/60),'h',FLOOR(MOD(average_duration,60)),'m') as average_time
FROM avg_duration
;

-- As this query took long time to fetch (213sec) I decided to optimise it.
/* First observation is that in the previous aproach we computed timestampdiff for each booking
 but in fact we can compute it for each flight instead.*/
 
 WITH duration AS
			 (
			 SELECT
				flight_id,
				timestampdiff(minute, departure, arrival) AS minutes
			 from flight
			),
            
            
sex_flight  AS
			(
			SELECT
				b.flight_id,
				p.sex
			FROM booking b
			JOIN passengerdetails p
				ON p.passenger_id=b.passenger_id
			),
            
avg_duration AS 
		(
		SELECT
			s.sex,
			avg(minutes) as average_time
		FROM sex_flight s
		JOIN duration d
			ON d.flight_id=s.flight_id
		GROUP BY sex
		)
        
SELECT 
	sex,
    CONCAT(FLOOR(average_time/60),'h',FLOOR(MOD(average_time,60)),'m') as average_time
FROM 
	avg_duration
;
-- We've managed to reduce the fetching time to 194sec (so aprox. by 9%).


-- Next we find passengers that took the most flights.
SELECT 
	p.firstname as first_name,
    p.lastname as last_name,
    COUNT(*) AS number_of_flights
FROM booking b
LEFT JOIN passenger p
	ON p.passenger_id=b.passenger_id
GROUP BY b.passenger_id
ORDER BY number_of_flights DESC
LIMIT 10;

-- Avg, min and max number of flights:

WITH passengers_flights as 
			(
			SELECT 
				passenger_id,
				COUNT(*) AS number_of_flights
			FROM booking 
			GROUP BY passenger_id
			)
            
 
SELECT 
	FLOOR(AVG(number_of_flights)) as average_number_of_flights,
    MIN(number_of_flights) as minimal_number_of_flights,
    MAX(number_of_flights) as maximal_number_of_flights
FROM passengers_flights;

-- Most frequent travelers

WITH ranking AS
			(
			SELECT
				passenger_id,
				count(*) AS number_of_flights
			FROM booking
			GROUP BY passenger_id
			ORDER BY number_of_flights DESC 
			LIMIT 10
			)
            
SELECT
	p.firstname,
    p.lastname,
    r.number_of_flights
FROM ranking r
JOIN passenger p
	ON r.passenger_id=p.passenger_id
;

-- Now we find passengers travelling to the largest number of countries

WITH ranking AS
			(
			SELECT
				b.passenger_id,
				COUNT(ag.country) AS number_of_countries
			FROM booking b
			JOIN flight f
				ON b.flight_id=f.flight_id
			JOIN airport_geo ag
				ON ag.airport_id=f.to
			GROUP BY b.passenger_id
            ORDER BY number_of_countries DESC
            LIMIT 10
			)
            
SELECT
	p.firstname,
    p.lastname,
	r.number_of_countries
FROM ranking r
JOIN passenger p
	ON r.passenger_id=p.passenger_id
    
