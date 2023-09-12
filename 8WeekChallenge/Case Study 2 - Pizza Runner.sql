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


