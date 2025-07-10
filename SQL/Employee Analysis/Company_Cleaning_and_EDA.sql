-- Checking all the tables

SELECT  *
FROM companies;

SELECT *
FROM employees;

SELECT *
FROM functions;

SELECT *
FROM salaries;

/* Creating a copy of the original tables into Temporary Dataset. We do not need to work on the Original datasets
*/

-- USING JOIN clause
SELECT * 
	INTO employee_dataset
	FROM salaries
	LEFT JOIN companies
	ON salaries.comp_name = companies.company_name
	LEFT JOIN employees
	ON salaries.employee_id = employees.employee_code_emp
	LEFT JOIN functions
	ON salaries.func_code = functions.function_code;

SELECT *
FROM employee_dataset;

-- Creating another temporary dataset with only the Relevant Columns from employee_dataset for EDA
SELECT CONCAT(employee_id, CAST(date AS date)) AS id,
	CAST(date as date) AS month_year_df,
	employee_id, 
	employee_name,
	[GEN_M_F], 
	age,
	salary,
	function_group,
	company_name,
	company_city,
	company_type,
	const_site_category

INTO df_employee
FROM employee_dataset

-- Table for the rest of the EDA is df_employee Table
SELECT *
FROM df_employee;

-------------------------------------------------- STARTING THE DATA CLEANING PROCESS ---------------------
-- 1.		Renaming the GRN_M_F column to 'Gender'
EXEC sp_rename 'df_employee.[GEN_M_F]', 'Gender', 'COLUMN';

-- 2.	Checking for Null Values and empty values in all the columns In the df_employee Table
-- For NULL Values
SELECT *
FROM df_employee
WHERE
	const_site_category IS NULL;

	/* 
	id 
	employee_id  
	employee_name 
	Gender 
	age
	salary 
	function_group
	company_name 
	company_city 
	company_type 
	*/
-- For empty values
SELECT *
FROM df_employee
WHERE
	id = ''  OR
	employee_id  = ''  OR
	employee_name = ''  OR
	Gender = ''  OR
	age = ''  OR
	salary = ''  OR
	function_group = ''  OR
	company_name = ''  OR
	company_city = ''  OR
	company_type = ''  OR
	const_site_category= '' ;

	-- There is no empty values

-- Dealing with the Null values
-- First we identify the columns with the null values
--SELECT COUNT(id) AS count_of_missing_id
--FROM df_employee
--WHERE id IS NULL;

--SELECT COUNT(employee_id) AS count_of_missing_employee_id
--FROM df_employee
--WHERE employee_id IS NULL;

--SELECT COUNT(employee_name) AS count_of_missing_employee_name
--FROM df_employee
--WHERE employee_name IS NULL;

--SELECT COUNT(Gender) AS count_of_missing_Gender
--FROM df_employee
--WHERE Gender IS NULL;

--SELECT COUNT(age) AS count_of_missing_age
--FROM df_employee
--WHERE age IS NULL;

--SELECT COUNT(function_group) AS count_of_missing_function_group
--FROM df_employee
--WHERE function_group IS NULL;

--SELECT COUNT(salary) AS count_of_missing_salary
--FROM df_employee
--WHERE salary IS NULL;

--SELECT COUNT(company_name) AS count_of_missing_company_name
--FROM df_employee
--WHERE company_name IS NULL;

--SELECT COUNT(company_city) AS count_of_missing_company_city
--FROM df_employee
--WHERE company_city IS NULL;

--SELECT COUNT(company_type) AS count_of_missing_company_type
--FROM df_employee
--WHERE company_type IS NULL;

SELECT COUNT(const_site_category) AS count_of_missing_const_site_category
FROM df_employee
WHERE const_site_category IS NULL;

-- Deleting the rows where missing values were detected
DELETE FROM df_employee
WHERE const_site_category IS NULL;

DELETE FROM df_employee
WHERE salary IS NULL;

-- NULL values have been removed

----------------- 3. Removing Duplicates
SELECT *
FROM df_employee
GROUP BY 
	id, 
	employee_id,
	employee_name, 
	month_year_df,
	Gender, 
	age,
	salary, 
	function_group,
	company_name, 
	company_city, 
	company_type, 
	const_site_category

HAVING COUNT(*) > 1;

-- Deleting duplicated rows from the table
WITH Duplicated_CTE AS ( 
	SELECT *,
	ROW_NUMBER() OVER(PARTITION BY 	id, employee_id, employee_name, month_year_df, Gender, age, salary, function_group,
	company_name, 
	company_city, 
	company_type, 
	const_site_category
	ORDER BY (SELECT NULL)) AS row_num
	FROM df_employee
)

DELETE FROM Duplicated_CTE
WHERE row_num > 1;

-- Duplicated rows have been removed

----------- 4.		Standardizing Data Entry
-- a. Standardizing the Gender Column:
UPDATE df_employee
SET Gender = CASE
	WHEN Gender = 'M' THEN 'Male'
	WHEN Gender = 'F' THEN 'Female'
	ELSE Gender
END;

SELECT *
FROM df_employee;

----- b.		Standardizing the Text columns to be in the proper case
UPDATE df_employee
SET 
    employee_name = UPPER(LEFT(employee_name, 1)) + LOWER(SUBSTRING(employee_name, 2, LEN(employee_name))),
    function_group = UPPER(LEFT(function_group, 1)) + LOWER(SUBSTRING(function_group, 2, LEN(function_group))),
    company_name = UPPER(LEFT(company_name, 1)) + LOWER(SUBSTRING(company_name, 2, LEN(company_name))),
    company_city = UPPER(LEFT(company_city, 1)) + LOWER(SUBSTRING(company_city, 2, LEN(company_city))),
    company_type = UPPER(LEFT(company_type, 1)) + LOWER(SUBSTRING(company_type, 2, LEN(company_type))),
    const_site_category = UPPER(LEFT(const_site_category, 1)) + LOWER(SUBSTRING(const_site_category, 2, LEN(const_site_category)));

------ c.	Dealing with Inconsistent data entries
-- Step 1: Identify the Inconsistent Data
SELECT DISTINCT company_type FROM df_employee;
SELECT DISTINCT company_city FROM df_employee;
SELECT DISTINCT function_group FROM df_employee;
SELECT DISTINCT  company_name FROM df_employee;
SELECT DISTINCT const_site_category FROM df_employee;

-- Step 2: Correct the Inconsistent Entries
UPDATE df_employee
SET company_type = 'Construction site'
WHERE company_type = 'Construction sites';

UPDATE df_employee
SET company_city = 'Goiania'
WHERE company_city = 'Goianiaa';

UPDATE df_employee
SET const_site_category = 'Commercial'
WHERE const_site_category = 'Commerciall';

-- All Inconsistent data entries have been corrected
SELECT *
FROM df_employee;

-- Adding a company_state column in the df_employee Table
ALTER TABLE df_employee
ADD company_state VARCHAR(50);

UPDATE df_employee
SET company_state = 
    CASE 
        WHEN company_city = 'Brasilia' THEN 'Distrito Federal'
        WHEN company_city = 'Palmas' THEN 'Tocantins'
        WHEN company_city = 'Goiania' THEN 'Goiás'
        ELSE 'Unknown'
    END;


---------------------FINAL DATA QUALITY CHECKS--------------------------------
--- Row Count Check:
SELECT COUNT(*) AS [Total rows]
FROM df_employee;

-- There are 6,813 rows in the Table

-- Column Count Check:
SELECT COUNT(*) AS [Total columns]
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'df_employee';

-- There are 13 columns in the Table

-- Data Type Check:
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'df_employee';

-- Duplicate Check:
SELECT id, COUNT(*) 
FROM df_employee 
GROUP BY id 
HAVING COUNT(*) > 1;

-- No duplicate values found


----------------------------------------- DATA ANALYSIS ---------------------------------------------
-- 1)	Has the average salary decreased or increased since January 2022?
SELECT month_year_df AS salary_month, ROUND(AVG(salary),2) AS [Average Salary]
FROM df_employee
GROUP BY month_year_df
ORDER BY [Average Salary];

-- 2)	How effective is our HR program in reducing the gender gap?
-- a)	Count of male vs female employees over time
SELECT 
    month_year_df, 
    Gender, 
    COUNT(employee_id) AS total_employees, 
    ROUND(100.0 * COUNT(employee_id) / SUM(COUNT(employee_id)) OVER (PARTITION BY month_year_df), 2) AS [Percentage]
FROM df_employee
GROUP BY month_year_df, Gender
ORDER BY month_year_df, Gender;

-- b)	Looking at the Gender pay gap over time (Male vs Female Salary Difference)
-- Using Subqyueries and Joins
SELECT 
    a.month_year_df, 
    a.avg_salary AS male_avg_salary, 
    b.avg_salary AS female_avg_salary, 
    (a.avg_salary - b.avg_salary) AS salary_gap, 
    ROUND((a.avg_salary - b.avg_salary) / a.avg_salary * 100, 2) AS salary_gap_percentage
FROM 
    (SELECT month_year_df, AVG(salary) AS avg_salary FROM df_employee WHERE Gender = 'Male' GROUP BY month_year_df) a
JOIN 
    (SELECT month_year_df, AVG(salary) AS avg_salary FROM df_employee WHERE Gender = 'Female' GROUP BY month_year_df) b
ON a.month_year_df = b.month_year_df
ORDER BY a.month_year_df;

-- 3)	Salary distribution across the states in Brazil
SELECT ROUND(AVG(salary), 2) AS [Average Salary], company_state AS [State]
FROM df_employee
GROUP BY company_state
ORDER BY [Average Salary] DESC;

-- 4)	 How Standardized is the Pay Policy across the states?
SELECT company_state AS [State], function_group AS [Function], ROUND(AVG(salary), 2) AS [Averge Salary], 
ROUND(STDEVP(salary), 2) AS [Salary standard deviation]
FROM df_employee
GROUP BY company_state, function_group;

-- 5)	How experience is the engineering team
/*
 By analyzing age distribution as a proxy for experience, I will adopt that older employees tend to have more work experience. 
Though this is not  absolute.
*/

SELECT *
FROM df_employee;

SELECT 
	company_state AS [State],
	MIN(age) AS [Youngest Engineer],
	MAX(age) AS [Oldest Engineer],
	AVG(age) AS [Avg. Age],
	COUNT(*) AS [Total Employees]
FROM df_employee
WHERE function_group = 'Engineering'
GROUP BY company_state;

-- 6)	In what function groups (Job Role) does the company spend the most?
SELECT
	function_group AS [Job Role],
	SUM(salary) AS [Total Salary Spending Per Job Role],
	ROUND(AVG(salary), 2) AS [Avg. Salary Per Job Role]
FROM df_employee
GROUP BY function_group
ORDER BY [Total Salary Spending Per Job Role] DESC;

-- 7)	What construction sites spent the most in salaries for the period?
SELECT 
	const_site_category AS [Type of Construction SIte],
	SUM(salary) AS [Total Salaries Spent]
FROM df_employee
GROUP BY const_site_category
ORDER BY [Total Salaries Spent] DESC;


---------------------------------------- Insights--------------------------------------------------------------
/*
1)	The average salary has increased from $15,182.3 in Jan 2022 to $66,465.14 in Jan 2023, showing a steady growth in employee compensation 
over time.

2) Effectiveness of HR Program in Reducing the Gender Gap

	a)	Based on Employee Count: Female representation has increased from 5.48% in Jan 2022 to 36.4% in Jan 2023, showing a positive shift 
	in gender diversity.
	b)	Gender Pay Gap: Initially, men earned significantly more, but by mid-2022, women began earning higher on average than men, 
	indicating corrective measures in pay equity.

3)		Salary Distribution Across States in Brazil
	Highest Paying State: Tocantins (72,079.17)
	Mid-Range: Goiás (48,989.04)
	Lowest: Distrito Federal (33,484.88)

4)	Standardization of Pay Policy Across States

	i.	High salary deviations in Goiás and Tocantins indicate inconsistent pay policies across locations.
	ii.	Engineering roles show major pay inconsistencies, with Goiás (195,340.94 avg, 126,151.1 std dev) compared to 
	Distrito Federal (4,200 avg, 1,249 std dev).

5)	Experience of the Engineering Team

	i.	Distrito Federal has the most experienced team (Avg. age: 28, oldest: 38).
	ii.	Goiás has younger engineers (Avg. age: 22), suggesting less experience.

6)	Highest Spending Function Groups

	i.	Professionals have the highest total salary spending (155.7M) and a moderate avg salary (48,967.62).
	ii.	Engineering roles receive high salaries (136,162.44 avg) but lower total spending.
	iii.	 Production supervisors have high individual salaries (108,638.78 avg) but lower total spending.

7)		Construction Sites with the Highest Salary Expenses

	i.	Residential construction sites had the highest salary spending (210.7M), indicating heavy workforce allocation.
	ii.	Commercial (48.7M) and hospital sites (40.1M) spent significantly less in comparison.

*/

---------------------------------------Recommendations---------------------------------------------------
/*
1.	Balance pay equity to avoid disparities in favor of either gender.
2.	Assess cost of living vs salary fairness in different states.
3.	Implement a more standardized salary structure to ensure consistency and fairness across locations.
4.	Consider mentorship programs in the 3 states to develop young engineers.
5.	Assess ROI on each of the job roles and optimize workforce spending.
6.	Evaluate labor cost efficiency in residential projects to identify potential cost-saving strategies.
*/