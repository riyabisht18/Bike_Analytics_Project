/*
===============================================================================
Product Report
===============================================================================
Purpose:
    - This report consolidates key product metrics and behaviors.

Highlights:
    1. Gathers essential fields such as product name, category, subcategory, and cost.
    2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
    3. Aggregates product-level metrics:
       - total orders
       - total sales
       - total quantity sold
       - total customers (unique)
       - lifespan (in months)
    4. Calculates valuable KPIs:
       - recency (months since last sale)
       - average order revenue (AOR)
       - average monthly revenue */


CREATE VIEW gold.products_report AS 
WITH base_query AS (
    SELECT
	    f.order_number,
        f.order_date,
		f.customer_key,
        f.sales_amount,
        f.quantity,
        p.product_key,
        p.product_name,
        p.category,
        p.subcategory,
        p.cost
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON f.product_key = p.product_key
    WHERE order_date IS NOT NULL  
),

product_aggregations AS (
SELECT
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan,
    MAX(order_date) AS last_sale_date,
    COUNT(DISTINCT order_number) AS total_orders,
	COUNT(DISTINCT customer_key) AS total_customers,
    SUM(sales_amount) AS total_sales,
    SUM(quantity) AS total_quantity,
	ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity, 0)),1) AS avg_selling_price
FROM base_query

GROUP BY
    product_key,
    product_name,
    category,
    subcategory,
    cost
)


SELECT 
	product_key,
	product_name,
	category,
	subcategory,
	cost,
	last_sale_date,
	DATEDIFF(MONTH, last_sale_date, GETDATE()) AS recency_in_months,
	CASE
		WHEN total_sales > 50000 THEN 'High-Performer'
		WHEN total_sales >= 10000 THEN 'Mid-Range'
		ELSE 'Low-Performer'
	END AS product_segment,
	lifespan,
	total_orders,
	total_sales,
	total_quantity,
	total_customers,
	avg_selling_price,
	-- Average Order Revenue (AOR)
	CASE 
		WHEN total_orders = 0 THEN 0
		ELSE total_sales / total_orders
	END AS avg_order_revenue,

	-- Average Monthly Revenue
	CASE
		WHEN lifespan = 0 THEN total_sales
		ELSE total_sales / lifespan
	END AS avg_monthly_revenue

FROM product_aggregations 

SELECT * FROM gold.products_report ;

-- Top 10 products by total sales, showing sales, orders, and unique customers
SELECT TOP 10
    product_name,
    total_sales,
    total_orders,
    total_customers
FROM gold.products_report
ORDER BY total_sales DESC;

-- Summary of product segments showing count of products, total sales, orders, and customers per segment
SELECT 
    product_segment,
    COUNT(product_key) AS num_products,
    SUM(total_sales) AS segment_total_sales,
    SUM(total_orders) AS segment_total_orders,
    SUM(total_customers) AS segment_total_customers
FROM gold.products_report
GROUP BY product_segment
ORDER BY segment_total_sales DESC;

-- Products not sold in the last 6 months , ordered by recency
SELECT 
    product_name,
    category,
    recency_in_months,
    total_sales,
    total_orders
FROM gold.products_report
WHERE recency_in_months > 6
ORDER BY recency_in_months DESC;

-- Average total sales by product lifespan , ordered by highest average sales
SELECT 
    lifespan,
    AVG(total_sales) AS avg_sales_per_lifespan
FROM gold.products_report
GROUP BY lifespan
ORDER BY avg_sales_per_lifespan DESC;




/*
Customer Report
===============================================================================
Purpose:
    - This report consolidates key customer metrics and behaviors

Highlights:
    1. Gathers essential fields such as names, ages, and transaction details.
	2. Segments customers into categories (VIP, Regular, New) and age groups.
    3. Aggregates customer-level metrics:
	   - total orders
	   - total sales
	   - total quantity purchased
	   - total products
	   - lifespan (in months)
    4. Calculates valuable KPIs:
	    - recency (months since last order)
		- average order value
		- average monthly spend */


CREATE VIEW gold.Customer_reports AS 
WITH Base_query AS
(
	SELECT 
		f.order_number ,
		f.product_key  ,
		f.order_date ,
		f.sales_amount ,
		f.quantity ,
		c.customer_key , 
		c.customer_number ,
		CONCAT(c.first_name , ' '  , c.last_name  ) AS	Customer_name ,
		DATEDIFF(YEAR , birthdate , GETDATE()) AS Age
	FROM gold.fact_sales AS f
	LEFT JOIN gold.dim_customers AS c
		ON C.customer_key = f.customer_key
	WHERE order_date IS NOT NULL
) ,
Customers_Aggregation  AS
(
	SELECT 
		customer_key ,
		customer_number ,
		Customer_name ,
		Age ,
		COUNT(DISTINCT order_number) AS Total_orders ,
		SUM(sales_amount) AS Total_sales ,
		SUM(quantity) AS Total_quantity  , 
		COUNT( DISTINCT  product_key) AS Total_products ,
		MAX(order_date) AS	Last_orderdate ,
		DATEDIFF(MONTH , MIN(order_date), MAX(order_date)) AS Lifespan_month 
	FROM Base_query
	GROUP BY 
		customer_key ,
		customer_number ,
		Customer_name ,
		Age 
)
SELECT 
	    customer_key ,
		customer_number ,
		Customer_name ,
		Age  ,
		CASE 
			WHEN Age < 20 THEN 'Under 20'
			WHEN Age BETWEEN 20 AND 29 THEN '20 - 29'
			WHEN Age BETWEEN 30 AND 39 THEN '30 -39'
			WHEN Age BETWEEN 40 AND 49 THEN '40 -49'
			ELSE '50 and Above'
		END Age_group ,
	CASE 
		WHEN Lifespan_month >= 12 AND  Total_sales > 5000 THEN 'VIP ' 
		WHEN Lifespan_month >= 12 AND   Total_sales <=  5000 THEN 'Regular' 
		ELSE 'New'
	END Customer_segment , 
		Last_orderdate ,
		DATEDIFF(MONTH , Last_orderdate  , GETDATE()) AS Receny , 
		Total_orders ,
		Total_products ,
		Total_quantity ,
		Total_sales ,
		Lifespan_month ,
		-- AOV 
	CASE 
		WHEN total_sales = 0 THEN 0
		ELSE total_sales / total_orders
	END AS avg_order_value,
-- Compuate average monthly spend
	CASE 
		WHEN Lifespan_month = 0 THEN total_sales
		ELSE total_sales / Lifespan_month
	END AS avg_monthly_spend
FROM Customers_Aggregation ; 


-- Revenue and Orders by Customer Segment
SELECT 
	Customer_segment ,
	COUNT(customer_key) AS Num_customers ,
	SUM(Total_sales) Total_revenue,
	COUNT(Total_orders) Total_orders
FROM gold.Customer_reports
GROUP BY Customer_segment
ORDER BY Total_revenue DESC 

-- Average Order Value (AOV) by Age Group 
SELECT 
	Age_group ,
	AVG(avg_order_value) AS  AOV 
FROM gold.Customer_reports
GROUP BY Age_group 
ORDER BY AOV DESC

-- Customers inactive over 6 months
SELECT 
	customer_key ,
	Customer_name ,
	Customer_segment ,
	Receny
FROM gold.Customer_reports
WHERE Receny > 6
ORDER BY Receny DESC ; 

-- Avg sales by customer lifespan
SELECT 
    Lifespan_month,
    AVG(Total_sales) AS Avg_sales
FROM gold.Customer_reports
GROUP BY Lifespan_month
ORDER BY Lifespan_month DESC ;

-- Top 10 customers by avg monthly spend 
SELECT TOP 10
    customer_key, 
    Customer_name, 
    Customer_segment, 
    avg_monthly_spend
FROM gold.Customer_reports
ORDER BY avg_monthly_spend DESC
;

--  Avg unique products bought per customer segment
SELECT 
    Customer_segment,
    AVG(Total_products) AS Avg_unique_products
FROM gold.Customer_reports
GROUP BY Customer_segment;