-- ALTER DATABASE with MODIFY NAME changes the database name
ALTER DATABASE hotels
      MODIFY Name = project;

SELECT stays_in_weekend_nights FROM dbo.['2018'];

-- Display meal without duplicates use distinct after select 

SELECT DISTINCT meal
FROM dbo.['2018'];

-- Count the number of rows or values
SELECT COUNT(arrival_date_week_number)
FROM dbo.['2020'];

SELECT * FROM dbo.['2019'];

-- Define a VIEW named 'hotels' that combines data from three tables (2018, 2019, 2020):
CREATE VIEW dbo.Hotels AS
SELECT * FROM dbo.['2018']
UNION
SELECT * FROM dbo.['2019']
UNION
SELECT * FROM dbo.['2020'];

-- Now, we can query the 'Hotels' view as if it's a table.
SELECT * FROM HOTELS ;

-- Q1: What is the total number of nights stayed by guests?
SELECT count(stays_in_weekend_nights + stays_in_week_nights)
FROM Hotels;

-- Renames the result as 'TotalStays' using the 'AS' keyword for better clarity.
SELECT count(stays_in_weekend_nights + stays_in_week_nights) AS TotalStays
FROM Hotels


--Q2: How much revenue did each stay generate?
SELECT (stays_in_weekend_nights + stays_in_week_nights )*adr AS Revenue
FROM Hotels

--Q3: What is the total revenue generated for all stays in the data(years--> 2018, 2019, and 2020)?

SELECT sum((stays_in_weekend_nights + stays_in_week_nights )*adr) AS Revenue
FROM Hotels

--Q4: What was the yearly total revenue from both weekend and weekday stays?
SELECT arrival_date_year,arrival_date_month,
(stays_in_weekend_nights + stays_in_week_nights)*adr AS Revenue
FROM Hotels


--Q5: Round the total revenue to the nearest integer for easier reporting
SELECT ROUND(SUM((stays_in_weekend_nights + stays_in_week_nights)*adr),0) AS Revenue
FROM Hotels


--Q6: What was the total revenue per year?
SELECT arrival_date_year,
ROUND(SUM((stays_in_weekend_nights + stays_in_week_nights)*adr),0) AS Revenue -- rounded to the nearest integer
FROM Hotels
GROUP BY arrival_date_year


--Q7: Total Revenue per year, broken down by hotel type
SELECT arrival_date_year,hotel,
ROUND(SUM((stays_in_weekend_nights + stays_in_week_nights)*adr),0) AS Revenue
FROM Hotels
GROUP BY arrival_date_year,hotel

--Q8: Adding meal cost and market segment information using JOIN
SELECT *
FROM Hotels 
LEFT JOIN dbo.[meal_cost$]
ON Hotels.meal = dbo.[meal_cost$].meal
LEFT JOIN dbo.[market_segment$]
ON Hotels.market_segment = dbo.[market_segment$].market_segment






--Q9: What is the profit percentage for each month across all years?
SELECT 
    arrival_date_year,
    arrival_date_month,
    ROUND(
        SUM((stays_in_weekend_nights + stays_in_week_nights) * adr), 0) - ROUND(SUM(dbo.[meal_cost$].cost), 0) AS Profit , 
    ROUND(
        (
            (SUM((stays_in_weekend_nights + stays_in_week_nights) * adr) - SUM([meal_cost$].cost))
            / SUM((stays_in_weekend_nights + stays_in_week_nights) * adr) )     * 100, 2) AS Profit_Percentage
FROM 
    Hotels
LEFT JOIN 
    dbo.[meal_cost$]
ON 
    Hotels.meal = dbo.[meal_cost$].meal
GROUP BY 
    arrival_date_year, arrival_date_month
ORDER BY 
    arrival_date_year, arrival_date_month;



-- Q10: Which meals and market segments (e.g., families, corporate clients, etc.) contribute the most to the total revenue for each hotel annually?
SELECT 
    Hotels.hotel, 
    Hotels.arrival_date_year, 
    Hotels.meal, 
    Hotels.market_segment, 
    ROUND(SUM((stays_in_weekend_nights + stays_in_week_nights) * adr), 0) AS Total_Revenue
FROM 
    Hotels
LEFT JOIN 
    dbo.[meal_cost$] 
ON 
    Hotels.meal = dbo.[meal_cost$].meal
LEFT JOIN 
    dbo.[market_segment$] 
ON 
    Hotels.market_segment = dbo.[market_segment$].market_segment
GROUP BY 
    Hotels.hotel, 
    Hotels.arrival_date_year, 
    Hotels.meal, 
    Hotels.market_segment
ORDER BY 
    Hotels.hotel, 
    Hotels.arrival_date_year, 
    Total_Revenue DESC;


-- Q11: How does revenue compare between public holidays and regular days each year?

SELECT 
    arrival_date_year, 
    'Holiday' AS Day_Type, 
    ROUND(SUM(stays_in_weekend_nights * adr), 2) AS Total_Revenue
FROM 
    Hotels
GROUP BY 
    arrival_date_year

UNION 

SELECT 
    arrival_date_year, 
    'regular days' AS Day_Type, 
    ROUND(SUM(stays_in_week_nights * adr), 2) AS Total_Revenue
FROM 
    Hotels
GROUP BY 
    arrival_date_year
ORDER BY 
    arrival_date_year, 
    Day_Type DESC;

-- Q12: What are the key factors (e.g., hotel type, market type, meals offered, number of nights booked) significantly impact hotel revenue annually?
SELECT 
    arrival_date_year,
    hotel,
    Hotels.market_segment,
    Hotels.meal,
    ROUND(SUM((stays_in_weekend_nights + stays_in_week_nights) * adr), 2) AS Total_Revenue,
    COUNT(*) AS Total_Bookings,
    SUM(stays_in_weekend_nights + stays_in_week_nights) AS Total_Nights
FROM 
    Hotels
LEFT JOIN 
    dbo.[meal_cost$] 
ON 
    Hotels.meal = dbo.[meal_cost$].meal
LEFT JOIN 
    dbo.[market_segment$] 
ON 
    Hotels.market_segment = dbo.[market_segment$].market_segment
GROUP BY 
    arrival_date_year, Hotels.hotel, Hotels.market_segment, Hotels.meal
ORDER BY 
    arrival_date_year, Total_Revenue DESC;

-- Q13: Based on stay data, what are the yearly trends in customer preferences for room types (e.g., family rooms vs. single rooms), and how do these preferences influence revenue?

SELECT 
    arrival_date_year,
    reserved_room_type,
    assigned_room_type,
    COUNT(*) AS Total_Bookings,
    SUM(stays_in_weekend_nights + stays_in_week_nights) AS Total_Nights,
    ROUND(SUM((stays_in_weekend_nights + stays_in_week_nights) * adr), 2) AS Total_Revenue,
    COUNT(CASE WHEN reserved_room_type != assigned_room_type THEN 1 END) AS Changed_Rooms
FROM 
    Hotels
GROUP BY 
    arrival_date_year, reserved_room_type, assigned_room_type
ORDER BY 
    arrival_date_year, Total_Revenue DESC;


--Q14: Knowing the cancellation of the reservation depends on several factors such as the meal and the name of the hotels

SELECT 
    hotel, 
    meal,  
    COUNT(*) AS Total_Bookings,  
    AVG(previous_cancellations) AS Avg_Previous_Cancellations,  
    AVG(previous_bookings_not_canceled) AS Avg_Previous_Bookings_Not_Canceled
FROM 
    Hotels
GROUP BY 
    hotel, meal
ORDER BY 
    hotel, meal, Avg_Previous_Cancellations DESC;

--Q15: Number of visitors each year

SELECT 
    arrival_date_year,   
    SUM(adults) AS Total_Adults, 
    SUM(children) AS Total_Children,  
    SUM(babies) AS Total_Babies,  
    SUM(adults + CHILDREN + BABIES) AS Total_Visitors  
FROM 
    Hotels
GROUP BY 
    arrival_date_year 
ORDER BY 
    arrival_date_year;  


--Q16: What are the most booked room types each year?
SELECT 
    arrival_date_year, 
    reserved_room_type,  
    COUNT(*) AS Number_of_Bookings  
FROM 
    Hotels
GROUP BY 
    arrival_date_year, reserved_room_type
ORDER BY 
    arrival_date_year, Number_of_Bookings DESC;  

--Q17: What are the most chosen meals each year?
SELECT 
    arrival_date_year, 
    meal,  
    COUNT(*) AS Number_of_Bookings  
FROM 
    Hotels
GROUP BY 
    arrival_date_year, meal
ORDER BY 
    arrival_date_year, Number_of_Bookings DESC;  
     
--Q18: What are the most popular meals served in each hotel?

SELECT 
    hotel,
    meal,
    COUNT(*) AS Number_of_Bookings
FROM 
    Hotels
GROUP BY 
    hotel, meal
ORDER BY 
    hotel, Number_of_Bookings DESC;

--Q19: What is the total revenue for each hotel based on the type of room booked?
SELECT 
    hotel,
    reserved_room_type,
    ROUND(SUM((stays_in_weekend_nights + stays_in_week_nights) * adr), 0) AS Total_Revenue
FROM 
    Hotels
GROUP BY 
    hotel, reserved_room_type
ORDER BY 
    hotel, Total_Revenue DESC;

--Q20: Which market segment contributed the most revenue to each hotel?

SELECT 
    hotel, 
    market_segment, 
    ROUND(SUM((stays_in_weekend_nights + stays_in_week_nights) * adr), 0) AS Total_Revenue
FROM 
    Hotels
GROUP BY 
    hotel, market_segment
ORDER BY 
    hotel, Total_Revenue DESC;


-------------------------------------------------------------

SELECT agent , company FROM dbo.['2018']
WHERE agent is null;


SELECT ISNULL(company , 'UNKOWN') as company
FROM dbo.['2018'];


SELECT ISNULL(agent , 0) as agent
FROM dbo.['2018'];

update dbo.['2018']
SET agent = REPLACE(agent , 'NULL' , 0)
where agent is NULL;


update dbo.['2018']
SET company = REPLACE(company , 'NULL' , 'UNKOWN')
where company is NULL;


SELECT * FROM dbo.['2019']

update dbo.['2019']
SET agent = REPLACE(agent , 'NULL' , 0)
where agent is NULL;

update dbo.['2019']
SET company = REPLACE(company , 'NULL' , 'UNKOWN')
where company is NULL;


SELECT * FROM dbo.market_segment$

update dbo.market_segment$
SET Discount = REPLACE(Discount , 'NULL' , 0)
where Discount is NULL;

update dbo.market_segment$
SET market_segment = REPLACE(market_segment , 'NULL' , 'undefined')
where market_segment is NULL;




SELECT * FROM dbo.meal_cost$;

update dbo.meal_cost$
SET Cost = REPLACE(Cost , 'NULL' , 0)
where Cost is NULL;

update dbo.meal_cost$
SET meal = REPLACE(meal , 'NULL' , 'undefined')
where meal is NULL;

SELECT * FROM dbo.meal_cost$;

SELECT * FROM dbo.['2018'];

--------------------------------------------








   