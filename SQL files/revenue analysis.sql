use airportdb;

-- We start by finding the total revenue from flight tickets.

SELECT
	CONCAT(ROUND(SUM(price)/1000000,2),' mln') as total_revenue
FROM booking
;

-- Now we are intrested in monthly revenue distribution.

WITH monthly_revenue AS
			(
			SELECT
				DATE_FORMAT(f.departure, "%Y-%m-01") AS month,
				SUM(b.price) AS revenue
			FROM flight f
			JOIN booking b
				ON b.flight_id=f.flight_id
			GROUP BY month
			ORDER BY month
			)

SELECT 
	month,
    revenue,
	SUM(revenue) OVER (ORDER BY month) AS running_revenue
FROM monthly_revenue
;
-- Now we are interested in average, minimal and maximal ticket price.

SELECT
	ROUND(AVG(price),2) AS average_price,
    MIN(price) AS minimal_price,
    MAX(price) AS maximal_price
FROM booking
;

-- After preliminary analysis we are interested in distribution of ticket prices.

SELECT
    CONCAT(ROUND(price/50)*50,'-',ROUND(price/50)*50+50) AS price_interval,
    CONCAT(ROUND(COUNT(booking_id)/1000000,4),' mln') as frequency
FROM booking
GROUP BY price_interval
ORDER BY price_interval
;

-- Next we find most profitable flights.

SELECT
	b.flight_id,
	a1.city as departure_city,
    a1.country as departure_country,
    a2.city as destination_city,
    a2.country as destination_country,
    SUM(b.price) as revenue
FROM booking b
LEFT JOIN flight f
	ON f.flight_id=b.flight_id
LEFT JOIN  airport_geo a1
	on a1.airport_id=f.from
LEFT JOIN  airport_geo a2
	on a2.airport_id=f.to
GROUP BY b.flight_id, a1.city, a1.country, a2.city, a2.country
ORDER BY revenue DESC
LIMIT 10;

-- This query took 1421 seconds- because we are joining huge "booking" table.
-- We should first compute te most profitable flights and then join.


WITH revenue AS
			(
			SELECT
				flight_id,
				SUM(price) as revenue
			FROM booking
			GROUP BY flight_id
			ORDER BY revenue DESC
			LIMIT 10
			)
            
SELECT
	r.flight_id,
    a1.city as departure_city,
    a1.country as departure_country,
    a2.city as destination_city,
    a2.country as destination_country,
    r.revenue
FROM revenue r
LEFT JOIN flight f
	ON f.flight_id=r.flight_id
LEFT JOIN  airport_geo a1
	on a1.airport_id=f.from
LEFT JOIN  airport_geo a2
	on a2.airport_id=f.to;
    
-- After opitmization query took only 507 second, so we reduced the execution time aprox. by 64%.


-- Now we look for the airlines that made the highest revenue.


WITH revenue AS
			(
			SELECT
				flight_id,
				SUM(price) as revenue
			FROM booking
			GROUP BY flight_id
			ORDER BY revenue DESC
			LIMIT 10
			),

total_revenue AS
			(	
			SELECT 
				f.airline_id,
				SUM(r.revenue) AS total_revenue
			FROM revenue r
			LEFT JOIN flight f
				ON f.flight_id=r.flight_id
			GROUP BY f.airline_id
			)
            
SELECT
	a.airlinename,
    tr.total_revenue
FROM total_revenue tr
LEFT JOIN airline a
	ON a.airline_id=tr.airline_id
