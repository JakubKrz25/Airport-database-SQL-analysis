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

