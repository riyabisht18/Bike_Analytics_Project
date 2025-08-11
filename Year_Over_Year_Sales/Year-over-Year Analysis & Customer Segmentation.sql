USE  DataWarehouseAnalytics ; 

--  Year-wise summary of total sales, unique customers, and quantity sold
SELECT 
	YEAR(order_date)  AS order_year  ,
	SUM(sales_amount) AS Total_sales ,
	COUNT(DISTINCT customer_key) AS Total_customers ,
	SUM(quantity) AS Total_quantity 
FROM gold.fact_sales
WHERE order_date IS NOT NULL 
GROUP BY YEAR(order_date) 
ORDER BY YEAR(order_date)   ; 


-- Year-wise sales with running total and moving average of price
SELECT 
Order_date,
Total_sales,
SUM(Total_sales) OVER(ORDER BY Order_date) AS  running_total ,
AVG(AVG_Price) OVER(ORDER BY Order_date) AS Moving_avg
FROM 
(
	SELECT 
		YEAR(order_date ) AS Order_date,
		SUM(sales_amount) AS Total_sales ,
		AVG(price) AS AVG_Price
	FROM gold.fact_sales
	WHERE order_date IS NOT NULL
	GROUP BY YEAR (order_date )
)t ; 


-- Year-wise product sales analysis: average comparison and year-over-year change
WITH yearly_products_sales AS
(
	SELECT 
		YEAR(f.order_date) AS order_year , 
		 P.product_name , 
		SUM(f.sales_amount) AS Current_sales  
	FROM gold.fact_sales AS f
	LEFT JOIN gold.dim_products AS p
		ON P.product_key = f.product_key
	WHERE order_date IS NOT NULL
	GROUP BY 
		YEAR(f.order_date),
		 P.product_name  	
)
SELECT 
	order_year ,
	product_name ,
	Current_sales   ,
	AVG(Current_sales) OVER(PARTITION BY product_name) AS AVG_sales ,
	Current_sales - AVG(Current_sales) OVER(PARTITION BY product_name) AS Diff_avg ,
	CASE 
		WHEN Current_sales - AVG(Current_sales) OVER(PARTITION BY product_name) > 0 THEN 'Above Avg'
		WHEN Current_sales - AVG(Current_sales) OVER(PARTITION BY product_name) < 0 THEN 'Below Avg'
		ELSE 'AVG'
	END AS Avg_change ,
	LAG(Current_sales) OVER(PARTITION BY product_name ORDER BY order_year  ) AS Previous_year_sales ,
	Current_sales  - LAG(Current_sales) OVER(PARTITION BY product_name ORDER BY order_year  ) AS diff_previous ,
	CASE 
		WHEN Current_sales  - LAG(Current_sales) OVER(PARTITION BY product_name ORDER BY order_year  )  > 0 THEN 'Increase'
		WHEN Current_sales  - LAG(Current_sales) OVER(PARTITION BY product_name ORDER BY order_year  )  < 0 THEN 'Decrease'
		ELSE 'No change'
		END  py_change
		FROM yearly_products_sales
ORDER BY product_name , order_year    ; 


-- category contributes to overall sales 
WITH Category_sales AS
(
	SELECT
		category ,
		SUM(F.sales_amount) AS Total_sales
	FROM gold.fact_sales AS f
	LEFT JOIN gold.dim_products AS p
		ON P.product_key = F.product_key
	GROUP BY P.category 
)
SELECT 
	category , 
	Total_Sales , 
	SUM(Total_sales) OVER() AS  overall_sales , 
	CONCAT(ROUND((CAST(Total_Sales AS FLOAT)/ SUM(Total_sales) OVER())*100 ,2) ,'%' )AS Percentage_contribution 
FROM Category_sales 
ORDER BY Total_sales DESC ; 


-- Categorizes products by cost and shows how many products fall into each price range.
WITH Product_segments AS 
(
	SELECT 
		product_key ,
		product_name , 
		cost ,
	CASE
		WHEN COST < 100 THEN 'Below 100'
		WHEN COST BETWEEN  100 AND 500 THEN '100 - 500'
		WHEN COST BETWEEN  500 AND 1000 THEN '500 - 1000'
		ELSE 'Above 1000'
	END Cost_range
	FROM gold.dim_products
)
SELECT 
	Cost_range ,
	COUNT(product_key) AS Total_products
FROM Product_segments
GROUP BY Cost_range 
ORDER BY Total_products  DESC ;


-- Segments customers into VIP, Regular, and New based
WITH Customer_spending   AS 
(
	SELECT 
		C.customer_key ,
		MIN(F.order_date) AS First_orderdate ,
		MAX(f.order_date) AS Last_orderdate , 
		DATEDIFF(MONTH , MIN(F.order_date), MAX(f.order_date)) AS Lifespan_month, 
		SUM(f.sales_amount) AS Total_spending 
	FROM gold.fact_sales AS f
	LEFT JOIN gold.dim_customers AS c
		ON C.customer_key = F.customer_key
	GROUP BY C.customer_key
)
SELECT 
	Customer_segment , 
	COUNT(customer_key) AS Total_customers
FROM 
	(
	SELECT 
		customer_key ,
		Lifespan_month ,
		Total_spending ,
	CASE 
		WHEN Lifespan_month >= 12 AND  Total_spending > 5000 THEN 'VIP ' 
		WHEN Lifespan_month >= 12 AND   Total_spending <=  5000 THEN 'Regular' 
		ELSE 'New'
	END Customer_segment
	FROM Customer_spending 
	)t
GROUP BY Customer_segment 
ORDER  BY Total_customers DESC  ; 






