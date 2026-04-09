use airportdb;

-- We start by finding the total revenue from flight tickets.

SELECT
	CONCAT(ROUND(SUM(price)/1000000,2),' mln') as total_revenue
FROM booking
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


