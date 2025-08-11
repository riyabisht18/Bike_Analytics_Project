use DataWarehouseAnalytics
-- Extract a distinct list of customer countries
SELECT  DISTINCT  country 
FROM GOLD.dim_customers;

--All unique product categories, subcategories, and product names
SELECT  category , subcategory , product_name
FROM GOLD.dim_products
ORDER BY 1,2,3 ;

--First and last order dates in the dataset
SELECT 
	MIN(order_date) as First_orderdate ,
	max(order_date) as Last_orderdate ,
	DATEDIFF(year , MIN(order_date) ,MAX (order_date)) as Timespan 
FROM GOLD.fact_sales;

-- Identify the oldest and youngest customers in the dataset
SELECT 
	MIN(birthdate)  AS Oldest_birthday,
	DATEDIFF(YEAR , MIN(birthdate)  , GETDATE()) as Oldest_age , 
	MAX(birthdate) AS Youngest_birthday , 
	DATEDIFF(YEAR , MAX(birthdate)  , GETDATE()) as Youngest_age  
FROM GOLD.dim_customers ;

/* 
===========================
 Customer & Sales Summary
===========================
This query provides a high-level summary of key metrics from the customer and sales data. 
Each row in the result shows a different KPI (Key Performance Indicator), including:

- Total Sales Revenue (SUM of all sales amounts)
- Total Quantity Sold
- Average Product Price
- Total Number of Unique Orders
- Total Number of Products in the catalog
- Total Number of Customers
- Total Number of Customers Who Placed an Order


*/

SELECT 
	'Total Sales' as Meaure_name , SUM(sales_amount) as Measure_value FROM GOLD.fact_sales
UNION ALL
SELECT 'Total Quanity'  Meaure_name , SUM(quantity) as Measure_value FROM GOLD.fact_sales
UNION ALL
SELECT 'Avg price'  Meaure_name , AVG(price) as Measure_value FROM GOLD.fact_sales
UNION ALL
SELECT 'Total Orders'  Meaure_name , COUNT(DISTINCT order_number) as Measure_value FROM GOLD.fact_sales
UNION ALL
SELECT 'Total Products'  Meaure_name , COUNT(product_key) as Measure_value FROM GOLD.dim_products
UNION ALL
SELECT 'Total Customers '  Meaure_name , COUNT(customer_id) as Measure_value FROM GOLD.dim_customers
UNION ALL
SELECT 'Total Order placed '  Meaure_name , COUNT( DISTINCT customer_key) as Measure_value FROM GOLD.fact_sales ; 


 -- Customer Demographics EDA

SELECT 
	country , 
	COUNT(customer_key) as Total_customers
FROM GOLD.dim_customers
GROUP BY country
ORDER BY Total_customers DESC  ; 

--Gender-wise Distribution
SELECT 
	gender , 
	COUNT(customer_id) as Total_Gender 
FROM GOLD.dim_customers
GROUP BY gender
ORDER BY Total_Gender  DESC  ; 
 
-- Marital Status Distribution
SELECT 
	marital_status , 
	COUNT(customer_key) AS Total_status
FROM GOLD.dim_customers
GROUP BY marital_status
ORDER BY Total_status  DESC; 

--Total Products per Category
SELECT	
	category, 
	COUNT(product_key) as Total_products
FROM GOLD.dim_products
GROUP BY category
ORDER BY  Total_products DESC ; 

--Average Cost per Category
SELECT	
	category, 
	AVG(cost) as AVG_cost
FROM GOLD.dim_products
GROUP BY category
ORDER BY  AVG_cost DESC ; 

--Revenue by Product Category
SELECT 
	p.category ,
	sum(f.sales_amount) AS Total_revenue
FROM GOLD.fact_sales AS f
LEFT JOIN gold.dim_products as p 
	ON p.product_key = f.product_key
GROUP BY P.category
ORDER BY Total_revenue DESC  ; 

--Top 5 Customers by Total Revenue Contribution
SELECT TOP 5 
	C.customer_key , 
	C.first_name ,
	C.last_name , 
	C.country ,
	SUM(f.sales_amount) AS total_revenue
FROM GOLD.fact_sales AS f 
LEFT JOIN gold.dim_customers AS C 
	ON C.customer_key = F.customer_key
GROUP BY 
	C.customer_key , 
	C.first_name ,
	C.last_name ,
	c.country
ORDER BY total_revenue DESC	;

-- Total Sold Items by Country
SELECT 
	C.country ,
	SUM(F.quantity) AS Total_sold_items 
FROM GOLD.dim_customers AS C
LEFT JOIN gold.fact_sales AS F
	ON C.customer_key = F.customer_key
GROUP BY c.country
ORDER BY Total_sold_items DESC  ; 

-- Total Revenue by Customer Marital Status
SELECT 
	C.marital_status ,
	SUM(F.sales_amount) AS Total_revenueby_status
FROM GOLD.dim_customers AS C
LEFT JOIN gold.fact_sales AS F
	ON C.customer_key = F.customer_key
GROUP BY c.marital_status
ORDER BY Total_revenueby_status DESC  ; 

--Total Revenue by each Country
SELECT 
	C.country ,
	SUM(F.sales_amount) AS Total_revenueby_country
FROM GOLD.dim_customers AS C
LEFT JOIN gold.fact_sales AS F
	ON C.customer_key = F.customer_key
GROUP BY c.country
ORDER BY Total_revenueby_country DESC  ;


--Top 5 Products by Total Revenue
SELECT TOP 5 
	p.product_name ,
	sum(f.sales_amount) AS Total_revenue
FROM GOLD.fact_sales AS f
LEFT JOIN gold.dim_products as p 
	ON p.product_key = f.product_key
GROUP BY P.product_name
ORDER BY Total_revenue DESC  ; 


-- Bottom 5 Products by Total Revenue
SELECT TOP 5 
	p.product_name ,
	sum(f.sales_amount) AS Total_revenue
FROM GOLD.fact_sales AS f
LEFT JOIN gold.dim_products as p 
	ON p.product_key = f.product_key
GROUP BY P.product_name
ORDER BY Total_revenue   ; 


--  Bottom 3 Customers by Number of Orders
SELECT TOP 3
	C.customer_key , 
	C.first_name ,
	C.last_name , 
	COUNT(F.order_number) AS total_Orders
FROM GOLD.fact_sales AS f 
LEFT JOIN gold.dim_customers AS C 
	ON C.customer_key = F.customer_key
GROUP BY 
	C.customer_key , 
	C.first_name ,
	C.last_name 
ORDER BY total_Orders 	;

