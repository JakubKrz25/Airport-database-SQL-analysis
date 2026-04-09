USE airportdb;

-- Preliminary analysis

SELECT 
	ag.airport_id,
    ag.name,
    ag.city,
    ag.country,
    ag.latitude,
    ag.longitude,
    a.iata,
    a.icao
FROM airport_geo ag
LEFT JOIN airport a
	ON a.airport_id=ag.airport_id
WHERE city='';

/* There are 3 airports with corrupted data. We've managed, based on fragments of names,
coordinates (which can be found in "country" column), icao and information available online
 to reconstruct this data.
*/

UPDATE airport_geo
SET name = 'LITTLE GOOSE LOCK AND DAM AIRPORT',
city = 'STARBUCK',
country='UNITED STATES',
latitude='46.5839444',
longitude='118.0035833'
WHERE airport_id = 6993;
-- Source of data: http://airnav.com/airport/16W

UPDATE airport_geo
SET name = UPPER('Sky Ranch Airport'),
city = UPPER('Knoxville'),
country='UNITED STATES',
latitude='35.8856381',
longitude='83.9576836'
WHERE airport_id = 10037;
-- Source of data: https://www.airnav.com/airport/TN98


UPDATE airport_geo
SET name = UPPER('UPMC Jameson Heliport'),
city = UPPER('New Castle'),
country='UNITED STATES',
latitude='41.0126861',
longitude='80.3517111'
WHERE airport_id = 11580;
-- Source of data: https://airnav.com/airport/3PN4


SELECT 
	airport_id,
    name,
    city,
    country,
    latitude,
    longitude
FROM airport_geo
WHERE airport_id IN (6993,10037,11580);

-- Top 3 routes (we count airports in one city as one)
WITH routes AS
			(
			SELECT
				f.flight_id,
				f.from,
				ag1.city AS city1,
				ag1.country AS country1,
				f.to,
				ag2.city AS city2,
				ag2.country AS country2
			FROM flight f
			LEFT JOIN airport_geo ag1
				ON ag1.airport_id=f.from
			LEFT JOIN airport_geo ag2
				ON ag2.airport_id=f.to
			)
		
SELECT
    concat(city1,'(',country1,')','->',city2,'(',country2,')') AS route,
    count(flight_id) AS number_of_flights
FROM routes
GROUP BY route
ORDER BY number_of_flights DESC
LIMIT 3;


-- The most popular destination for each airport

WITH city_and_country AS
			(
			SELECT
				airport_id,
				concat(city,' (',country,')') AS city_country
			FROM airport_geo
			),
            
dest as
			(
			SELECT
				f.from AS departure,
				c.city_country AS destination,
				count(*) AS number
			FROM flight f
			JOIN city_and_country c
				ON c.airport_id=f.to
			GROUP BY f.from, c.city_country
			),


ranked AS
			(
			SELECT 
				departure,
				destination,
				number,
				DENSE_RANK() OVER (PARTITION BY departure ORDER BY number DESC) as rnk
			FROM dest
			)
            
SELECT
	a.name,
    r.destination,
    r.number as number_of_flights
FROM ranked r
JOIN airport_geo a
	ON a.airport_id=r.departure
WHERE rnk=1
ORDER BY number_of_flights DESC, name
LIMIT 10
;

-- Airports with flights to the highest number of countries

SELECT
	ag1.name AS name,
    ag1.city,
    ag1.country,
    COUNT(DISTINCT ag2.country) AS number_of_countries
FROM flight f
JOIN airport_geo ag1
	ON ag1.airport_id=f.from
JOIN airport_geo ag2
	ON ag2.airport_id=f.to
GROUP BY ag1.airport_id, name, city, country
ORDER BY number_of_countries DESC, name
LIMIT 10;

-- Airports with the most arrivals

SELECT
	ag.name,
    ag.city,
    ag.country,
    count(f.from) as arrivals
FROM flight f
JOIN airport_geo ag
	ON ag.airport_id=f.to
GROUP BY airport_id, name, city, country
ORDER BY arrivals DESC
LIMIT 10;


-- Airports with the most departures

SELECT
	ag.name,
    ag.city,
    ag.country,
    count(f.to) as departures
FROM flight f
JOIN airport_geo ag
	ON ag.airport_id=f.from
GROUP BY airport_id, name, city, country
ORDER BY departures DESC
LIMIT 10;


-- Next we find 3 flights with the lowest occupancy rate.

WITH seats AS
			(
			SELECT
				flight_id,
				count(*) AS sold_seats
			FROM booking
			GROUP BY flight_id
			),
            
city_and_country AS
			(
			SELECT
				airport_id,
				concat(city,' (',country,')') AS city_country
			FROM airport_geo
			),
            
            
flight_info AS
			(
			SELECT
				f.flight_id,
                a.capacity,
				DATE(f.departure) AS departure_date,
				c1.city_country AS departure,
				c2.city_country AS arrival
			FROM flight f
			JOIN  city_and_country c1
				ON c1.airport_id=f.from
			JOIN  city_and_country c2
				ON c2.airport_id=f.to
			JOIN airplane a
				ON a.airplane_id=f.airplane_id
			 )

SELECT
	s.flight_id,
	f.capacity,
    COALESCE(s.sold_seats, 0) as sold_seats,
    ROUND((COALESCE(s.sold_seats, 0)/ f.capacity)*100,2) as occupancy_rate,
    f.departure_date,
    f.departure,
    f.arrival
FROM flight_info f
LEFT JOIN seats as s
	on f.flight_id=s.flight_id
ORDER BY occupancy_rate
LIMIT 3
;



/* Considering higest occupancy race we can find flights that were overbooked
(i.e. there were more sold seats than capacity). */
            

WITH seats AS
			(
			SELECT
				flight_id,
				count(*) AS sold_seats
			FROM booking
			GROUP BY flight_id
			),
            
city_and_country AS
			(
			SELECT
				airport_id,
				concat(city,' (',country,')') AS city_country
			FROM airport_geo
			),
            
            
flight_info AS
			(
			SELECT
				f.flight_id,
                a.capacity,
				DATE(f.departure) AS departure_date,
				c1.city_country AS departure,
				c2.city_country AS arrival
			FROM flight f
			JOIN  city_and_country c1
				ON c1.airport_id=f.from
			JOIN  city_and_country c2
				ON c2.airport_id=f.to
			JOIN airplane a
				ON a.airplane_id=f.airplane_id
			 )

SELECT
	s.flight_id,
	f.capacity,
    COALESCE(s.sold_seats, 0) as sold_seats,
    ROUND((COALESCE(s.sold_seats, 0)/ f.capacity)*100,2) as occupancy_rate,
    f.departure_date,
    f.departure,
    f.arrival
FROM flight_info f
LEFT JOIN seats as s
	on f.flight_id=s.flight_id
WHERE COALESCE(s.sold_seats, 0) > capacity
ORDER BY occupancy_rate desc
;


