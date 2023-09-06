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
