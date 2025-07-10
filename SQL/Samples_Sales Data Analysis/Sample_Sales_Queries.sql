SELECT *
FROM sample_sales_data;

SELECT COUNT(*) AS TotalRows
FROM sample_sales_data;

/* Creating a copy of the original database*/
SELECT * 
	INTO sample_sales_copy
	FROM sample_sales_data;

SELECT *
FROM sample_sales_copy;

-- Creating a temporary dataset and selecting relevant columns from the database copy for the analysis
SELECT CONCAT(ORDERNUMBER, CAST(ORDERDATE as date)) AS Sales_ID,
	ORDERNUMBER AS OrderNumber,
	QUANTITYORDERED AS QuantityNumber,
	ROUND(PRICEEACH, 2) AS PriceEach,
	ORDERLINENUMBER AS OrderLineNumber,
	ROUND(SALES, 2) AS Sales,
	CAST(ORDERDATE AS Date) AS OrderDate,
	STATUS AS Status,
	QTR_ID AS Qtr_ID,
	MONTH_ID AS Month_ID,
	YEAR_ID AS Year_ID,
	PRODUCTLINE AS ProductLine,
	MSRP,
	PRODUCTCODE AS ProductCode,
	CUSTOMERNAME AS CustomerName,
	CITY AS City,
	COUNTRY AS Country,
	CONCAT(CONTACTLASTNAME, CONTACTFIRSTNAME) AS ContactFullName,
	DEALSIZE AS DealSize

INTO sample_sales_df
FROM sample_sales_copy;

SELECT *
FROM	sample_sales_df;

--<--------------------------------------- DATA CLEANING PROCESS ------------------------------------>
-- 1.		Checking for Null values and Empty values in the df_sample_sales dataset
SELECT *
FROM sample_sales_df
WHERE
	OrderNumber IS NULL OR
	QuantityNumber IS NULL OR
	PriceEach IS NULL OR
	OrderLineNumber IS NULL OR
	Sales IS NULL OR
	OrderDate IS NULL OR
	Status IS NULL OR
	Qtr_ID IS NULL OR
	Month_ID IS NULL OR
	Year_ID IS NULL OR
	ProductLine IS NULL OR
	MSRP IS NULL OR
	ProductCode IS NULL OR
	CustomerName IS NULL OR
	City IS NULL OR
	Country IS NULL OR
	ContactFullName IS NULL OR
	DealSize IS NULL;

-- No Null Values found

-- Checking for empty values
SELECT *
FROM sample_sales_df
WHERE
	Sales_ID = ' ' OR
	OrderNumber = ' '  OR
	QuantityNumber  = ' '  OR
	PriceEach = ' '  OR
	OrderLineNumber = ' '  OR
	Sales = ' '  OR
	OrderDate = ' '  OR
	Status = ' '  OR
	Qtr_ID = ' '  OR
	Month_ID=  ' '  OR
	Year_ID	 = ' '  OR
	ProductLine= ' ' OR
	MSRP = ' ' OR
	ProductCode = ' ' OR
	CustomerName = ' ' OR
	City = ' ' OR
	Country = ' ' OR
	ContactFullName = ' ' OR
	DealSize = ' ' ;

-- No empty values

-- 2.	Checking for Duplicates
SELECT *
FROM sample_sales_df
GROUP BY
	Sales_ID,
	OrderNumber, 
	QuantityNumber,
	PriceEach,
	OrderLineNumber,
	Sales,
	OrderDate,
	Status,
	Qtr_ID,
	Month_ID,
	Year_ID,
	ProductLine,
	MSRP,
	ProductCode,
	CustomerName,
	City,
	Country,
	ContactFullName,
	DealSize

HAVING COUNT(*) > 1;

-- No duplicates found

-- 3.	Standardizing data entry
-- a.	Checking for Inconsistent data entries
--  Identify the Inconsistent Data
SELECT DISTINCT Status	FROM sample_sales_df;
SELECT DISTINCT ProductLine	FROM sample_sales_df;
SELECT DISTINCT City	FROM sample_sales_df;
SELECT DISTINCT Country	FROM sample_sales_df;
SELECT DISTINCT DealSize	FROM sample_sales_df;

-- All data entries in text columns are consistent

---- 4.	Correcting Column data types
---- Step 1: Checking for incorrect column data type
--SELECT COLUMN_NAME, DATA_TYPE
--FROM INFORMATION_SCHEMA.COLUMNS
--WHERE TABLE_NAME = 'df_sample_sales';

---- OrderNumber, OrderLineNumber, Qtr_ID, Month_ID, Year_ID are hsving wrong column data type

---- Step 2:	Correcting wrong column data types

--ALTER TABLE df_sample_sales
--ALTER COLUMN OrderNumber INT;

--ALTER TABLE df_sample_sales
--ALTER COLUMN OrderLineNumber VARCHAR;

--ALTER TABLE df_sample_sales
--ALTER COLUMN Qtr_ID VARCHAR;

--ALTER TABLE df_sample_sales
--ALTER COLUMN Month_ID VARCHAR;

--ALTER TABLE df_sample_sales
--ALTER COLUMN Year_ID VARCHAR;

------------------------------- FINAL DATA QUALITY CHECKS --------------------------------
--- Row Count Check:
SELECT COUNT(*) AS [Total rows]
FROM sample_sales_df;

-- There are 2,823 rows in the df_sample_sales table

-- Column Count Check:
SELECT COUNT(*) AS [Total columns]
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'sample_sales_df';

-- There are 19 columns in the df_sample_sales table

-- Data Type Check:
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'sample_sales_df';

-- All column data types are correct

-- Duplicate Check:
SELECT Sales_ID, COUNT(*) 
FROM sample_sales_df
GROUP BY Sales_ID
HAVING COUNT(*) > 1;

-- No duplicates found

SELECT *
FROM sample_sales_df;

-------------------------------------- DATA ANALYSIS ---------------------------------------
-- 1.		Sales Performance Overview
-- a.		Total Sales
SELECT SUM(Sales) AS [Total Sales]
FROM sample_sales_df;

-- b.	Total Quantity of Products Sold
SELECT SUM(QuantityNumber) AS [Total Products Sold]
FROM sample_sales_df;

-- c.	Average Revenue Per order
SELECT ROUND(SUM(Sales)/COUNT(OrderNumber), 4) AS [Avg Revenue per order]
FROM sample_sales_df;

--d.		Sales Trend Over Time
-- i.		Monthly Sales Trend
SELECT CASE MONTH_ID
    WHEN 1 THEN 'January'
    WHEN 2 THEN 'February'
    WHEN 3 THEN 'March'
    WHEN 4 THEN 'April'
    WHEN 5 THEN 'May'
    WHEN 6 THEN 'June'
    WHEN 7 THEN 'July'
    WHEN 8 THEN 'August'
    WHEN 9 THEN 'September'
    WHEN 10 THEN 'October'
    WHEN 11 THEN 'November'
    WHEN 12 THEN 'December'
END AS Month_Name,
Month_ID, ROUND(SUM(Sales), 2) AS [Total Sales]
FROM sample_sales_df
GROUP BY Month_ID
ORDER BY SUM(Sales) DESC;

-- ii.		Yearly Sales Trend
SELECT Year_ID, ROUND(SUM(Sales), 2) AS [Total Sales]
FROM sample_sales_df
GROUP BY Year_ID
ORDER BY SUM(Sales) DESC;

-- e.	Top 5 Countries by Total Sales
SELECT TOP 5 Country, ROUND(SUM(Sales), 2) AS [Total Sales]
FROM sample_sales_df
GROUP BY Country
ORDER BY SUM(Sales) DESC;

-- 2.	Product Analysis
-- a.	Top 10 Best-Selling & Worst Selling Products (by Quantity Ordered)
SELECT TOP 10 ProductCode, SUM(QuantityNumber) AS [Total Quantity Sold]
FROM sample_sales_df
GROUP BY ProductCode
ORDER BY  SUM(QuantityNumber) DESC;

SELECT TOP 10 ProductCode, SUM(QuantityNumber) AS [Total Quantity Sold]
FROM sample_sales_df
GROUP BY ProductCode
ORDER BY  SUM(QuantityNumber) ASC;

-- b.	Top 10 Revenue-Generating Products (by Total Sales)
SELECT TOP 10 ProductCode, SUM(Sales) AS [Total Revenue]
FROM sample_sales_df
GROUP BY ProductCode
ORDER BY  SUM(Sales) DESC;

-- c.	Revenue by Product Line
SELECT ProductLine, SUM(Sales) AS [Total Revenue]
FROM sample_sales_df
GROUP BY ProductLine
ORDER BY  SUM(Sales) DESC;

-- d.	Sales vs MSRP (Are we selling below or above the suggested price?)
SELECT Sales_ID, ProductLine, PriceEach, MSRP,
CASE
	WHEN PriceEach > MSRP THEN 'Above MSRP'
	WHEN PriceEach = MSRP THEN 'At MSRP'
	ELSE 'Below MSRP'
END AS [Pricing Status],
ROUND((MSRP - PriceEach), 2) AS [Discount Amount]
FROM sample_sales_df;

-- e.	Average Price per Product Line
SELECT ProductLine, ROUND(AVG(PriceEach), 2) AS [Avg Price]
FROM sample_sales_df
GROUP BY ProductLine
ORDER BY	AVG(PriceEach);

-- 3.	Customer Analysis
-- a.	Top 10 Customers by Total Revenue
SELECT TOP 10 CustomerName, SUM(Sales) AS [Total Revenue]
FROM sample_sales_df
GROUP BY CustomerName
ORDER BY [Total Revenue] DESC;

-- b.	Average Order Value per Customer
SELECT CustomerName, (ROUND(SUM(Sales)/COUNT(Sales_ID), 2)) AS AOV
FROM sample_sales_df
GROUP BY CustomerName
ORDER BY AOV;

-- c.	Customer Distribution by Country
SELECT Country, COUNT(*) AS [Total Customers]
FROM sample_sales_df
GROUP BY Country
ORDER BY [Total Customers] DESC;

-- d.	Customer Loyalty: How many orders per customer?
SELECT CustomerName, COUNT(*) AS [Total Orders]
FROM sample_sales_df
GROUP BY CustomerName
ORDER BY [Total Orders] DESC;

-- e.	Top Deal Sizes (Small, Medium, Large) by Customer
SELECT CustomerName, DealSize, SUM(Sales) AS [Total Revenue]
FROM sample_sales_df
GROUP BY CustomerName, DealSize
ORDER BY [Total Revenue] DESC;


-- 4.	Order Status and Operational Efficiency
-- a.	Order Status Breakdown:
SELECT Status, COUNT(*) AS [Total Orders],
ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS [% Breakdown]
FROM sample_sales_df
GROUP BY Status
ORDER BY [Total Orders] DESC;

-- b.	Sales Loss from Cancelled Orders
SELECT SUM(Sales) AS [Potential Revenue Lost]
FROM sample_sales_df
WHERE Status = 'Cancelled';

-- 5.	Regional Sales Analysis
-- a. Top Performing Countries, & City
SELECT TOP 10  Country, City, SUM(Sales) AS [Total Sales]
FROM sample_sales_df
GROUP BY Country, City
ORDER BY [Total Sales] DESC;

-- b.	Regional Deal Size Distribution
SELECT Country, DealSize, COUNT(*) AS [Deal Size Distribution]
FROM sample_sales_df
GROUP BY Country, DealSize
ORDER BY  Country, DealSize DESC;

