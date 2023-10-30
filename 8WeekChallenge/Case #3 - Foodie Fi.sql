----------------------------------------------------------------------------------------------------
-- Case Study Questions
-- This case study is split into an initial data understanding question before diving straight into 
-- data analysis questions before finishing with 1 single extension challenge.
----------------------------------------------------------------------------------------------------



-------------------------------------------------------------------------------
-----------------    SECTION A. Customer Journey    ---------------------------
-------------------------------------------------------------------------------

-- Based off the 8 sample customers provided in the sample from the subscriptions table, 
-- write a brief description about each customer’s onboarding journey.
	--1. customer_id - 1 started with the free trial plan on 2020-08-01 and then a week later 
	--   after the free trial expired, they subscribed to the "basic monthly" plan.
	--2. customer_id - 2 started with the free trial plan on 2020-09-20 but seemed to enjoy the 
	--   service and subscribed to the "pro annual" plan after the free trial expired.
	--3. customer_id - 11 started with the free trial plan on 2020-11-19 but probably didnt like the 
	--   services and canceled the service after the free trial expired.
	--4. customer_id - 13 started with the free trial plan on 2020-12-15, subscribed for the 
	--   "basic monthly" plan a week later and after about 3 months, they upgraded to the 
	--   "pro monthly" subcription.
	--5. customer_id - 15 started with the free trial plan on 2020-03-17, subscribed to the 
	--   "pro monthly" plan a week later and then cancelled the service about a month later
	--6. customer_id - 16 started with the free trial plan on 2020-05-31, subscribed for the 
	--   "basic monthly" plan a week later and after about 4 and half months, they upgraded 
	--	 to the "pro annual" subcription.
	--7. customer_id - 18 started with the free trial plan on 2020-07-06 and went to subscribe for the 
	--   "pro monthly" plan a week later
	--8. customer_id - 19 started with the free trial plan on 2020-06-22, subscribed for the "pro monthly" 
	--   plan a week later and after 2 months, they upgraded to the "pro annual" subcription.

--Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!

SELECT customer_id, plan_name, price, start_date
FROM dbo.subscriptions as sub
	JOIN dbo.plans as pla
		ON sub.plan_id = pla.plan_id
WHERE	customer_id = 1 OR
		customer_id = 2 OR
		customer_id = 11 OR
		customer_id = 13 OR
		customer_id = 15 OR
		customer_id = 16 OR
		customer_id = 18 OR
		customer_id = 19
;


