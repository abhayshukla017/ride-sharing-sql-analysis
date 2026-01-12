CREATE DATABASE quickcab
USE quickcab;
CREATE TABLE ride_sharing_data (
    ride_id INT PRIMARY KEY,
    driver_id INT,
    customer_id INT,
    ride_date DATE,
    city VARCHAR(20),
    ride_type VARCHAR(10),
    distance_km DECIMAL(4,1),
    fare_amount INT,
    payment_method VARCHAR(10),
    ride_status VARCHAR(10)
);
CREATE TABLE drivers (
    driver_id INT PRIMARY KEY
);
INSERT INTO drivers
SELECT DISTINCT driver_id
FROM ride_sharing_data;
CREATE TABLE customers (
    customer_id INT PRIMARY KEY
);
INSERT INTO customers
SELECT DISTINCT customer_id
FROM ride_sharing_data;
CREATE TABLE rides (
    ride_id INT PRIMARY KEY,
    driver_id INT,
    customer_id INT,
    ride_date DATE,
    city VARCHAR(20),
    ride_type VARCHAR(10),
    distance_km DECIMAL(4,1),
    fare_amount INT,
    payment_method VARCHAR(10),
    ride_status VARCHAR(10),
    FOREIGN KEY (driver_id) REFERENCES drivers(driver_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);
INSERT INTO rides
SELECT *
FROM ride_sharing_data;

-- #1 Total completed ride revenue.
SELECT SUM(fare_amount) AS total_revenue
FROM rides
WHERE ride_status = 'Completed';

-- #2 City-wise revenue ranking
SELECT city,
       SUM(fare_amount) AS revenue,
       RANK() OVER (ORDER BY SUM(fare_amount) DESC) AS city_rank
FROM rides
WHERE ride_status = 'Completed'
GROUP BY city;

--#3 Month-over-month revenue trend
SELECT 
    YEAR(ride_date) AS yr,
    MONTH(ride_date) AS mn,
    SUM(fare_amount) AS revenue
FROM rides
WHERE ride_status = 'Completed'
GROUP BY YEAR(ride_date), MONTH(ride_date)
ORDER BY yr, mn;

--#4Revenue growth compared to previous month
WITH monthly_rev AS (
    SELECT MONTH(ride_date) AS mn,
           SUM(fare_amount) AS revenue
    FROM rides
    WHERE ride_status = 'Completed'
    GROUP BY MONTH(ride_date)
)
SELECT mn,
       revenue,
       revenue - LAG(revenue) OVER (ORDER BY mn) AS mom_growth
FROM monthly_rev;


--#5 Average fare per km by ride type
SELECT ride_type,
       SUM(fare_amount) * 100.0 /
       SUM(SUM(fare_amount)) OVER () AS revenue_pct
FROM rides
WHERE ride_status = 'Completed'
GROUP BY ride_type;


--#6 Peak revenue day of week
SELECT DAYNAME(ride_date) AS day_name,
       SUM(fare_amount) AS revenue
FROM rides
WHERE ride_status = 'Completed'
GROUP BY DAYNAME(ride_date)
ORDER BY revenue DESC;

--#7 Revenue loss due to cancellations
SELECT SUM(fare_amount) AS cancelled_revenue_loss
FROM rides
WHERE ride_status = 'Cancelled';


--#8 Completed vs cancelled rides per driver
SELECT driver_id,
       SUM(CASE WHEN ride_status='Completed' THEN 1 ELSE 0 END) AS completed,
       SUM(CASE WHEN ride_status='Cancelled' THEN 1 ELSE 0 END) AS cancelled
FROM rides
GROUP BY driver_id;


--#9 Driver revenue rank
SELECT driver_id,
       SUM(fare_amount) AS revenue,
       RANK() OVER (ORDER BY SUM(fare_amount) DESC) AS rnk
FROM rides
WHERE ride_status='Completed'
GROUP BY driver_id;


--#10 Most efficient drivers (high fare per km)
SELECT driver_id,
       AVG(fare_amount / distance_km) AS fare_per_km
FROM rides
WHERE ride_status='Completed'
GROUP BY driver_id
ORDER BY fare_per_km DESC;


--#11 Drivers with zero cancellations
SELECT driver_id
FROM rides
GROUP BY driver_id
HAVING SUM(CASE WHEN ride_status='Cancelled' THEN 1 ELSE 0 END) = 0;


--#12 Repeat customers (more than 3 rides)
SELECT customer_id
FROM rides
GROUP BY customer_id
HAVING COUNT(*) > 3;


--#13 Top 10 customers by spend
SELECT customer_id,
       SUM(fare_amount) AS total_spent
FROM rides
WHERE ride_status='Completed'
GROUP BY customer_id
ORDER BY total_spent DESC
LIMIT 10;


--#14 Preferred ride type per city
SELECT *
FROM (
    SELECT city,
           ride_type,
           COUNT(*) AS rides,
           RANK() OVER (PARTITION BY city ORDER BY COUNT(*) DESC) AS rnk
    FROM rides
    GROUP BY city, ride_type
) t
WHERE rnk = 1;


--#15 Business insight: best city to expand
SELECT city,
       COUNT(*) AS total_rides,
       AVG(fare_amount) AS avg_fare
FROM rides
WHERE ride_status='Completed'
GROUP BY city
ORDER BY total_rides DESC, avg_fare DESC;

















