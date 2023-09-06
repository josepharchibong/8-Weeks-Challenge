/* --------------------
   Case Study Questions
   --------------------*/


-- 1. What is the total amount each customer spent at the restaurant?

SELECT sal.customer_id, SUM(men.price) AS TotalAmountSpent
FROM dbo.Sales as sal
	JOIN dbo.Menu as men
		ON sal.product_id = men.product_id
GROUP BY sal.customer_id
;


-- 2. How many days has each customer visited the restaurant?

SELECT customer_id, COUNT(order_date) AS Days_Visited
FROM dbo.Sales
GROUP BY customer_id
;




-- 3. What was the first item from the menu purchased by each customer?

WITH ItemOrderbyCustomer AS
(
	SELECT product_id, customer_id, order_date, ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY customer_id, order_date) AS item_numbering
	FROM dbo.Sales
)
SELECT customer_id, iobc.product_id, menu.product_name
FROM ItemOrderbyCustomer as iobc
	JOIN dbo.Menu as menu
		ON iobc.product_id = menu.product_id
WHERE item_numbering = '1'
;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT TOP 1 sale.product_id, menu.product_name, COUNT(sale.product_id) AS purchase_count_per_item
FROM dbo.Sales as sale
	JOIN dbo.Menu as menu
		ON sale.product_id = menu.product_id
GROUP BY sale.product_id, menu.product_name
ORDER BY purchase_count_per_item DESC
;


-- 5. Which item was the most popular for each customer?

WITH product_rank AS
(
	SELECT customer_id, product_id, RANK() OVER (PARTITION BY customer_id ORDER BY COUNT(product_id) DESC, product_id) AS rank
	FROM dbo.Sales
	GROUP BY customer_id, product_id
)
SELECT customer_id, pror.product_id, menu.product_name
FROM product_rank as pror
	JOIN dbo.Menu as menu
		ON pror.product_id = menu.product_id
WHERE rank = 1
;


-- 6. Which item was purchased first by the customer after they became a member?

WITH date_rank AS
(
	SELECT sal.customer_id, order_date, join_date, product_id, RANK() OVER (PARTITION BY sal.customer_id ORDER BY order_date) AS rank
	FROM dbo.Sales as sal
		JOIN dbo.Members as mem
			ON sal.customer_id = mem.customer_id
	WHERE order_date >= join_date
)
SELECT dara.customer_id, menu.product_name
FROM date_rank as dara
	JOIN dbo.Menu as menu
		ON dara.product_id = menu.product_id
WHERE rank = 1
;


-- 7. Which item was purchased just before the customer became a member?

WITH date_rank AS
(
	SELECT sal.customer_id, order_date, join_date, product_id, RANK() OVER (PARTITION BY sal.customer_id ORDER BY order_date DESC, product_id) AS rank
		FROM dbo.Sales as sal
			JOIN dbo.Members as mem
				ON sal.customer_id = mem.customer_id
	WHERE order_date < join_date
)
SELECT dara.customer_id, dara.product_id, menu.product_name
FROM date_rank as dara
	JOIN dbo.Menu as menu
		ON dara.product_id = menu.product_id
WHERE rank = 1
;


-- 8. What is the total items and amount spent for each member before they became a member?

SELECT sal.customer_id, COUNT(sal.product_id) AS total_items, SUM(menu.price) AS total_amount_spent
FROM dbo.Sales as sal
	JOIN dbo.Members as mem
		ON sal.customer_id = mem.customer_id
	JOIN dbo.Menu as menu
		ON sal.product_id = menu.product_id
WHERE order_date < join_date
GROUP BY sal.customer_id
;


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?


WITH CustomerPointsCTE1 AS
(
	SELECT sal.customer_id, sal.product_id, menu.product_name, menu.price, 
		CASE
			WHEN sal.product_id = '1' 
				THEN (menu.price*20)
			ELSE (menu.price*10)
		END AS customer_points
	FROM dbo.Sales as sal
		JOIN dbo.Menu as menu
			ON sal.product_id = menu.product_id
)
SELECT customer_id, SUM(customer_points) AS customer_points
FROM CustomerPointsCTE1
GROUP BY customer_id
;


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
--     not just sushi - how many points do customer A and B have at the end of January?

WITH CustomerPointsCTE2 AS
(
	SELECT sal.customer_id, sal.product_id, menu.product_name, menu.price, (menu.price*20) AS customer_points
	FROM dbo.Sales as sal
			JOIN dbo.Menu as menu
				ON sal.product_id = menu.product_id
			JOIN dbo.Members as mem
				ON sal.customer_id = mem.customer_id
		WHERE order_date >= join_date AND order_date <= DATEADD(week, 1, join_date) AND order_date < '20210201'
)
SELECT customer_id, SUM(customer_points) AS customer_points
FROM CustomerPointsCTE2
GROUP BY customer_id
;

-- Bonus Question 1: Join All Tables; create a column that specifies if a customer was a member at the time of the purchase

SELECT sal.customer_id, sal.order_date, menu.product_name, menu.price,
	CASE
		WHEN join_date > order_date
			THEN 'N'
		WHEN join_date <= order_date
			THEN 'Y'
		ELSE 'N'
	END AS member
	FROM dbo.Sales as sal
			FULL OUTER JOIN dbo.Menu as menu
				ON sal.product_id = menu.product_id
			FULL OUTER JOIN dbo.Members as mem
				ON sal.customer_id = mem.customer_id
;


-- Bonus Question 2: Rank all things

WITH All_Join AS
(
	SELECT sal.customer_id, sal.order_date, menu.product_name, menu.price,
		CASE
			WHEN join_date > order_date
				THEN 'N'
			WHEN join_date <= order_date
				THEN 'Y'
			ELSE 'N'
		END AS member
		FROM dbo.Sales as sal
				FULL OUTER JOIN dbo.Menu as menu
					ON sal.product_id = menu.product_id
				FULL OUTER JOIN dbo.Members as mem
					ON sal.customer_id = mem.customer_id
)
SELECT *, 
	CASE 
		WHEN member = 'N'
			THEN NULL
		WHEN member = 'Y'
			THEN RANK() OVER (PARTITION BY customer_id, member ORDER BY order_date) 
	END as ranking
FROM All_Join

;
