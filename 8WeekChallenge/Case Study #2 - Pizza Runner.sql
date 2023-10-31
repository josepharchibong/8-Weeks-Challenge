-------------------------------------------------------------------------------
--CLEANING UP customer_orders
SELECT * FROM dbo.customer_orders

--Handling Missing Data/nulls
UPDATE dbo.customer_orders
SET exclusions = NULL
WHERE exclusions IN ('null', ' ')
;
UPDATE dbo.customer_orders
SET extras = NULL
WHERE extras IN ('null', ' ')
;

--Eliminating duplicate rows
WITH RowNumCTE AS
(
	SELECT *, 
		ROW_NUMBER() OVER (
			PARTITION BY order_id, customer_id, pizza_id, exclusions, extras
			ORDER BY order_id
			) as row_num
	FROM dbo.customer_orders
)
DELETE
FROM RowNumCTE
WHERE row_num > 1
;

--Data Transformation: splitting order_time into order_date & order_time

SELECT order_time, SUBSTRING(CONVERT(varchar, order_time, 120), 1, 10), 
	SUBSTRING(CONVERT(varchar, order_time, 120), 12, LEN(order_time))
FROM dbo.customer_orders
;

ALTER TABLE customer_orders
ADD order_date date, order_time1 time(0)
;
UPDATE customer_orders
SET order_date = SUBSTRING(CONVERT(varchar, order_time, 120), 1, 10),
	order_time1 = SUBSTRING(CONVERT(varchar, order_time, 120), 12, LEN(order_time))
;

--Dropping the old columns & remaning the new ones
ALTER TABLE dbo.customer_orders
DROP COLUMN order_time
; 
EXEC sp_rename 'dbo.customer_orders.order_time1' , 'order_time' , 'COLUMN'
;

----------------------------------------------------------------------------------------
--CLEANING UP runner_orders
SELECT * FROM dbo.runner_orders

--Handling Missing Data/nulls
UPDATE dbo.runner_orders
SET pickup_time = NULL
WHERE pickup_time IN ('null')
;
UPDATE dbo.runner_orders
SET distance = NULL
WHERE distance IN ('null')
;
UPDATE dbo.runner_orders
SET duration = NULL
WHERE duration IN ('null')
;
UPDATE dbo.runner_orders
SET cancellation = NULL
WHERE cancellation IN ('null', ' ')
;
--Data Tranformation for some columns with inconsistent data
--Spliting the integer from strings in distance
SELECT distance, SUBSTRING(distance, 1, 
		CASE 
			WHEN CHARINDEX('km', distance) = 0
				THEN LEN(distance)
			ELSE CHARINDEX('km', distance) -1
		END )
FROM dbo.runner_orders
;
--Spliting the integer from strings in duration
SELECT duration, SUBSTRING(duration, 1, 
		CASE 
			WHEN CHARINDEX('min', duration) = 0
				THEN LEN(duration)
			ELSE CHARINDEX('min', duration) -1
		END )
FROM dbo.runner_orders
;
--Creating new columns for distance & duration
ALTER TABLE dbo.runner_orders
ADD distance_split float, duration_split float
;
--Updating the new columns for distance & duration
UPDATE dbo.runner_orders
SET distance_split = SUBSTRING(distance, 1, 
		CASE 
			WHEN CHARINDEX('k', distance) = 0
				THEN LEN(distance)
			ELSE CHARINDEX('km', distance) -1
		END ) ,
duration_split = SUBSTRING(duration, 1, 
		CASE 
			WHEN CHARINDEX('min', duration) = 0
				THEN LEN(duration)
			ELSE CHARINDEX('min', duration) -1
		END )
;
--Dropping the old columns & remaning the new ones
ALTER TABLE dbo.runner_orders
DROP COLUMN distance, duration
; 
EXEC sp_rename 'dbo.runner_orders.distance_split' , 'distance_km' , 'COLUMN'
;
EXEC sp_rename 'dbo.runner_orders.duration_split' , 'duration_mins' , 'COLUMN'
;

--Data Formatting: changing the data type for pickup_time
ALTER TABLE dbo.runner_orders
ALTER COLUMN pickup_time datetime
;


-------------------------------------------------------------------------------
-------------------     SECTION A: Pizza Metrics   ----------------------------
-------------------------------------------------------------------------------

--1. How many pizzas were ordered?
SELECT COUNT(pizza_id) AS pizzas_ordered
FROM dbo.customer_orders
;


--2. How many unique customer orders were made?
SELECT COUNT(pizza_id) AS Unique_Orders
FROM
(
	SELECT *
	FROM dbo.customer_orders
	WHERE exclusions IS NOT NULL OR extras IS NOT NULL
) Unique_Orders_Sub
;


--3. How many successful orders were delivered by each runner?
SELECT runner_id, COUNT(runner_id) AS successful_orders
FROM dbo.runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id
;


--4. How many of each type of pizza was delivered?
--Changing the data type of pizza_name to nvarchar
ALTER TABLE pizza_names
ALTER COLUMN pizza_name nvarchar(20)
;
SELECT pizza_name, COUNT(cus.pizza_id) as pizza_count_delivered
FROM dbo.customer_orders as cus
	JOIN dbo.pizza_names as piz
		ON cus.pizza_id = piz.pizza_id
	JOIN dbo.runner_orders as run
		ON cus.order_id = run.order_id
WHERE run.cancellation IS NULL
GROUP BY pizza_name
;


--5. How many Vegetarian and Meatlovers were ordered by each customer?
WITH rowrankCTE AS 
(
	SELECT	customer_id, 
			pizza_name, 
			cus.pizza_id, 
			RANK() OVER (PARTITION BY customer_id, cus.pizza_id ORDER BY customer_id) as rowrank
	FROM dbo.customer_orders as cus
		JOIN dbo.pizza_names as piz
			ON cus.pizza_id = piz.pizza_id
) 
SELECT customer_id, pizza_name, COUNT(rowrank) AS order_count
FROM rowrankCTE 
GROUP BY customer_id, pizza_name
ORDER BY customer_id
;


--6. What was the maximum number of pizzas delivered in a single order?
WITH pizza_delivered_CTE AS
(
	SELECT run.order_id, COUNT(run.order_id) AS order_count
	FROM dbo.runner_orders as run
		JOIN dbo.customer_orders as cus
			ON run.order_id = cus.order_id
	WHERE run.cancellation IS NULL
	GROUP BY run.order_id
)
SELECT MAX(order_count) AS max_order_count
FROM pizza_delivered_CTE
;


--7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
--Delivered pizzas with atleast 1 change
	WITH Atleast_1_Change AS
	(
		SELECT customer_id, cus.order_id, exclusions, extras
		FROM customer_orders as cus
			JOIN dbo.runner_orders as run
				ON cus.order_id = run.order_id
		WHERE (exclusions IS NOT NULL OR extras IS NOT NULL) AND run.cancellation IS NULL
	)	
	SELECT customer_id,  COUNT(*) AS order_count
	FROM Atleast_1_Change
	GROUP BY customer_id
;
--Delivered pizzas with no change
	WITH No_Change AS
	(
		SELECT customer_id, cus.order_id, exclusions, extras
		FROM customer_orders as cus
			JOIN dbo.runner_orders as run
				ON cus.order_id = run.order_id
		WHERE (exclusions IS NULL AND extras IS NULL) AND run.cancellation IS NULL
	)	
	SELECT customer_id,  COUNT(*) AS order_count
	FROM No_Change
	GROUP BY customer_id
;

