CREATE DATABASE vehicle_sales_db;
USE vehicle_sales_db;
CREATE TABLE vehicle_sales (
    tempregistrationnumber VARCHAR(50) PRIMARY KEY,
    modeldesc       VARCHAR(100),
    fuel            VARCHAR(30),
    colour          VARCHAR(30),
    vehicleclass    VARCHAR(50),
    makeyear        INT,
    seatcapacity    INT,
    secondvehicle   VARCHAR(5),     -- 'Y' / 'N' flag
    category        VARCHAR(50),
    makername       VARCHAR(50),
    officecd        VARCHAR(20),    -- RTO office code (proxy for city)
    sale_date       DATE
);

LOAD DATA LOCAL INFILE 'C:\Users\a\Downloads\vehicle_sales_q4_2025.csv'
INTO TABLE vehicle_sales
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


-- 1. How many vehicles were sold per month?
SELECT
    DATE_FORMAT(sale_date, '%Y-%m') AS sales_month,
    COUNT(*) AS total_vehicles_sold
FROM vehicle_sales
GROUP BY sales_month
ORDER BY sales_month;



-- 2. Category-wise distribution of sold vehicles
SELECT
    category,
    COUNT(*) AS vehicles_sold,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM vehicle_sales), 2) AS pct_of_total
FROM vehicle_sales
GROUP BY category
ORDER BY vehicles_sold DESC;


-- 3. Top 5 cities (RTO office codes) accounting for maximum sales
SELECT
    officecd AS city_office,
    COUNT(*) AS vehicles_sold
FROM vehicle_sales
GROUP BY officecd
ORDER BY vehicles_sold DESC
LIMIT 5;



-- 4. Top 10 models sold, broken down by city, category, maker,
--    fuel type, and seating capacity (using window functions)

SELECT category, modeldesc, vehicles_sold
FROM (
    SELECT
        category,
        modeldesc,
        COUNT(*) AS vehicles_sold,
        ROW_NUMBER() OVER (PARTITION BY category ORDER BY COUNT(*) DESC) AS rnk
    FROM vehicle_sales
    GROUP BY category, modeldesc
) ranked
WHERE rnk <= 10
ORDER BY category, vehicles_sold DESC;


-- 5. Colour preference of customers (by city, category, maker,
--    model, seating capacity)
SELECT category, colour, vehicles_sold
FROM (
    SELECT
        category,
        colour,
        COUNT(*) AS vehicles_sold,
        ROW_NUMBER() OVER (PARTITION BY category ORDER BY COUNT(*) DESC) AS rnk
    FROM vehicle_sales
    GROUP BY category, colour
) ranked
WHERE rnk = 1
ORDER BY category;


-- 6. Market share of each vehicle maker
SELECT
    makername,
    COUNT(*) AS vehicles_sold,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM vehicle_sales), 2) AS market_share_pct
FROM vehicle_sales
GROUP BY makername
ORDER BY market_share_pct DESC;


-- 7. Fuel type sales breakdown
SELECT
    fuel,
    COUNT(*) AS vehicles_sold,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM vehicle_sales), 2) AS pct_of_total
FROM vehicle_sales
GROUP BY fuel
ORDER BY vehicles_sold DESC;


-- 8. First-time buyers
SELECT
    COUNT(*) AS first_time_buyers
FROM vehicle_sales
WHERE secondvehicle = 'N';



-- 9. Seating capacity distribution
SELECT
    seatcapacity,
    COUNT(*) AS vehicles_sold
FROM vehicle_sales
GROUP BY seatcapacity
ORDER BY seatcapacity;


-- Checks for duplicate registration numbers and null values
SELECT tempregistrationnumber, COUNT(*) AS dup_count
FROM vehicle_sales
GROUP BY tempregistrationnumber
HAVING COUNT(*) > 1;

SELECT COUNT(*) AS rows_with_missing_data
FROM vehicle_sales
WHERE modeldesc IS NULL OR fuel IS NULL OR makername IS NULL OR sale_date IS NULL;
