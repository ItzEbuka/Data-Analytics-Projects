USE HealthCare_Project;

-- CHECKING FOR NULL VALUES 
SELECT COUNT(*)
FROM healthcare_Table;

-- PERFORMING DATA QUALITY CHECKS
SELECT Name,  COUNT(*) AS [Duplicate Count]
FROM healthcare_Table
GROUP BY Name
HAVING COUNT(*) > 1;

-- REMOVING DUPLICATES FROM THE TABLE USING CTE
WITH Duplicated_Rows AS (
	SELECT *, ROW_NUMBER() OVER(PARTITION BY [Hospital] ORDER BY (SELECT NULL)) AS Row_Num
	FROM healthcare_Table
)

DELETE FROM Duplicated_Rows
WHERE Row_Num > 1;

-- CHECKING FOR DUPLICATES AGAIN
SELECT COUNT(*) AS UNIQUE_ROWS
FROM healthcare_Table;

SELECT *  
FROM healthcare_Table;

----------------------------------- Overall Patient & Hospital Statistics --------------------------------------------------------------
-- Patients
SELECT 
	COUNT(*) AS [Total Patients], 
	ROUND(AVG(Age), 0) AS [Average Patient Age], 
	COUNT(DISTINCT [Blood Type]) AS [Category of Blood Type],
	ROUND(AVG([Billing Amount]), 2) AS [Average Billing Amount] 
FROM healthcare_Table;

-- Hospitals
SELECT 
	COUNT(DISTINCT hospital) AS [Total Hospitals],
	COUNT(DISTINCT [Admission Type]) AS [Category of Admission Type],
	COUNT(DISTINCT Medication) AS [Types of Medication],
	COUNT(DISTINCT [Test Results]) AS [Distinct Test Results],
	COUNT(DISTINCT Doctor) AS [Total Doctors],
	COUNT(DISTINCT [Medical Condition]) AS [Category of Medical Condition]
FROM healthcare_Table;



-------------------------------------- Segment 1: Patient Demographics ------------------------------------------------
-- Analyzing the distribution of patients by age groups

-- Step 1: Getting the Age Range from the Age Column
SELECT MIN(Age) AS Minimum_Age, MAX(Age) AS Max_Age
FROM healthcare_Table;

-- Step 2: using the age range to create the age groups ad getting the patient age distribution
SELECT COUNT(*) Patient_Age_Distribution,
(CASE	
	WHEN Age BETWEEN 18 AND 24 THEN 'Young Adults'
	WHEN Age BETWEEN 25 AND 44 THEN 'Adults'
	WHEN Age BETWEEN 45 AND 64 THEN 'Middle-Aged Adults'
	ELSE 'Seniors'

END) AS AgeGroup
FROM healthcare_Table
GROUP BY (CASE	
	WHEN Age BETWEEN 18 AND 24 THEN 'Young Adults'
	WHEN Age BETWEEN 25 AND 44 THEN 'Adults'
	WHEN Age BETWEEN 45 AND 64 THEN 'Middle-Aged Adults'
	ELSE 'Seniors'

END);

-- Determining the percentage of male and female patients (Gender Distribution)
SELECT 
    COUNT(*) AS Total_Patients,
    ROUND((COUNT(CASE WHEN Gender = 'Male' THEN 1 END) * 100.0 / COUNT(*)), 2) AS Male_Patient_Percentage,
    ROUND((COUNT(CASE WHEN Gender = 'Female' THEN 1 END) * 100.0 / COUNT(*)), 2) AS Female_Patient_Percentage
FROM healthcare_Table;


-- Identifying the most common blood types among patients
SELECT [Blood Type], COUNT(*) AS Count_of_BloodTypes
FROM healthcare_Table
GROUP BY [Blood Type]
ORDER BY Count_of_BloodTypes DESC;


-------------------------------------- Segment 2: Medical Conditions ----------------------------------------------------

-- Most Common Medical Conditions
SELECT [Medical Condition], COUNT(*) AS Count_of_MedicalConditions
FROM healthcare_Table
GROUP BY [Medical Condition]
ORDER BY Count_of_MedicalConditions DESC;
 
-- Analyzing which medical conditions are more prevalent in specfic age groups
-- Using CTEs
WITH Age_groups AS (
	SELECT [Medical Condition],
(CASE	
	WHEN Age BETWEEN 18 AND 24 THEN 'Young Adults'
	WHEN Age BETWEEN 25 AND 44 THEN 'Adults'
	WHEN Age BETWEEN 45 AND 64 THEN 'Middle-Aged Adults'
	ELSE 'Seniors'

END) AS AgeGroup
FROM healthcare_Table
),

Medical_Conditions AS (
	SELECT AgeGroup, [Medical Condition], COUNT(*) AS Total_Patient_Count
	FROM Age_groups
	GROUP BY AgeGroup, [Medical Condition]
),

Rank_Medical_Conditions AS (
	SELECT AgeGroup, [Medical Condition], Total_Patient_Count,
	RANK()OVER(PARTITION BY AgeGroup ORDER BY Total_Patient_Count DESC) AS Condition_Rank
	FROM Medical_Conditions
)

SELECT AgeGroup, [Medical Condition], Total_Patient_Count
FROM Rank_Medical_Conditions
WHERE Condition_Rank < 10
ORDER BY Condition_Rank;

-- Comorbidity Analysis (Checking if patients with certain conditions have other conditions


----------------------------------- Segment 3: Admission and Discharge Trends-----------------------------------------------------
-- Admmission Trends Over Time:

WITH Trends_Over_Time AS(
	SELECT  Name AS Patient_name,
	CONVERT(date, [Date of Admission], 103) AS Date_of_Admission
	FROM 
	healthcare_Table
)

SELECT COUNT(*) AS Patient_Count, MONTH(Date_of_Admission) AS Admissions_by_Month
FROM Trends_Over_Time
GROUP BY MONTH(Date_of_Admission)
ORDER BY Patient_Count DESC;


-- Length of Stay (Calculating the average length of stay for patients and comparing across different types)

WITH Length_of_Stay AS (
	SELECT Name AS Patient_Name, 
	DATEDIFF(DAY, [Date of Admission], [Discharge Date]) AS Duration_of_Stay,
	[Admission Type]
	FROM healthcare_Table
)

SELECT COUNT(Patient_Name) AS Count_of_Patients, [Admission Type], AVG(Duration_of_Stay) AS Avg_Length_of_Stay
FROM Length_of_Stay
GROUP BY [Admission Type]
ORDER BY AVG(Duration_of_Stay) DESC;

-- Discharge Patterns (identifying trends in discharge dates)
SELECT COUNT(Name) AS Count_of_Patient_Discharged,  DATENAME(WEEKDAY, [Discharge Date]) AS Day_of_The_Week
FROM healthcare_Table
GROUP BY DATENAME(WEEKDAY, [Discharge Date])
ORDER BY Count_of_Patient_Discharged;



-------------------------------- Segment 4: Hospital and Doctor Performance --------------------------------------------
-- Busiest Hospitals (Determining which hospitals have the highest number of admissions)
SELECT COUNT(*) AS [number of admissions], Hospital
FROM healthcare_Table
GROUP BY Hospital
ORDER BY [number of admissions] DESC;


-- Doctor Workload (Analyzing the number of patients treated by each doctor)
SELECT COUNT(*) AS [Number of Patients Treated], Doctor
FROM healthcare_Table
GROUP BY Doctor
ORDER BY [Number of Patients Treated] DESC;


-- Hospital Performance by Condition (Comparing hospitals based on the number of patients treated for specific condiions)
SELECT COUNT(*) AS [Number of Patients Treated], Hospital, [Medical Condition]
FROM healthcare_Table
GROUP BY Hospital, [Medical Condition]
ORDER BY [Number of Patients Treated] DESC;



------------------------------------ Segment 5: Insurance and Billing Analysis ---------------------------------------
-- Insurance Provider (Identifying the most common insurance providers among patients)
SELECT Count(*) AS [Count of Patients], [Insurance Provider]
FROM healthcare_Table
GROUP BY [Insurance Provider]
ORDER BY [Count of Patients] DESC;


-- Billing Analysis (Calculating the average billing amount and compare it across medical consitions, and insurance providers)
WITH Billing_Analysis AS (
	SELECT [Insurance Provider], [Billing Amount], [Medical Condition]
	FROM healthcare_Table
)

SELECT [Insurance Provider], ROUND(AVG([Billing Amount]), 2) AS [Average Billing Amount], [Medical Condition]
FROM healthcare_Table
GROUP BY [Insurance Provider], [Medical Condition]
ORDER BY [Average Billing Amount] DESC;


-- Cost of Admission (Determining various billing amounts based on certain admission types)
SELECT [Admission Type], ROUND(AVG([Billing Amount]), 2) AS [Average Billing Amount], 
ROUND(SUM([Billing Amount]), 2) AS [Total_billed_Amount]
FROM healthcare_Table
GROUP BY [Admission Type]
ORDER BY [Average Billing Amount] DESC;



-------------------------------------Segment 6: Room Utilization -----------------------------------------------
-- Room Occupancy (Analyzing how specific rooms are used)
SELECT COUNT(*) AS [Room Count], [Room Number]
FROM healthcare_Table
GROUP BY [Room Number]
ORDER BY [Room Count] DESC;


-- Room Usage by Condition (Checking if certain medical conditions are more likely to use specific rooms)
-- Using CTEs
WITH Group_Data AS (
	SELECT [Medical Condition],[Room Number]
	FROM healthcare_Table
	GROUP BY [Medical Condition], [Room Number]
),

Patient_Count AS (
	SELECT COUNT(*) AS Patient_Count, [Medical Condition], [Room Number]
	FROM Group_Data
	GROUP BY [Medical Condition], [Room Number]
),


Rank_Room AS (
	SELECT [Medical Condition],[Room Number], Patient_Count,
	RANK()OVER(PARTITION BY [Room Number] ORDER BY Patient_Count DESC) AS Condition_Rank
	FROM Patient_Count
)

SELECT [Room Number], [Medical Condition], Patient_Count
FROM Rank_Room
WHERE Condition_Rank < 10
ORDER BY Condition_Rank;



----------------------------------- Segment 7: Admission Type Analysis -------------------------------------
-- Admission Type Distribution (Determining the frequency of each admission type)
SELECT COUNT(*) AS [Patient Count], [Admission Type]
FROM healthcare_Table
GROUP BY [Admission Type]
ORDER BY [Patient Count];


-- Admission type by Condition (Analyzing which medical conditions are more likely to result in emergency admissions)
WITH Emergency_Admission AS (
	SELECT [Medical Condition], COUNT(*) AS [Emergency Count]
	FROM healthcare_Table
	WHERE [Admission Type] = 'Emergency'
	GROUP BY [Medical Condition]
),

TotalAdmission AS (
	SELECT [Medical Condition], COUNT(*) AS [Total Admission Count]
	FROM healthcare_Table
	GROUP BY [Medical Condition]
),

Admission_Proportion AS (
	SELECT e.[Medical Condition], e.[Emergency Count], t.[Total Admission Count],
	ROUND((CAST(e.[Emergency Count] AS  float)/t.[Total Admission Count]) * 100, 2) AS Emergency_Proportion
	FROM Emergency_Admission e
	INNER JOIN TotalAdmission t
	ON e.[Medical Condition] = t.[Medical Condition]
),

Ranked_Conditions AS (
	SELECT [Medical Condition], [Emergency Count], [Total Admission Count], Emergency_Proportion,
	RANK() OVER(ORDER BY Emergency_Proportion DESC) AS ConditionRank
	FROM Admission_Proportion
)

SELECT *
FROM Ranked_Conditions
WHERE ConditionRank <= 5
ORDER BY ConditionRank;
	


--------------------------------------- Segment 8: Test Result Analysis ---------------------------------------
-- Test Results Distributions (Analyzing the distribution of test results)
SELECT COUNT(*)	 AS [Patient Count], [Test Results]
FROM healthcare_Table
GROUP BY [Test Results]
ORDER BY [Patient Count] DESC;

-- Test Results by Condition (Checking if certain medical conditions have a higher rate of abnormal test results)
WITH Abnormal_Test AS (
	SELECT  [Medical Condition], COUNT(*) AS [Abnormal Test Count]
	FROM healthcare_Table
	WHERE [Test Results] = 'Abnormal'
	GROUP BY [Medical Condition]
),

Total_Test_Results AS (
	SELECT [Medical Condition], COUNT(*) AS Total_Test_Count
	FROM	healthcare_Table
	GROUP BY [Medical Condition]
),

Abnormal_Rate AS (
	SELECT a.[Medical Condition], a.[Abnormal Test Count], t.Total_Test_Count,
	ROUND((CAST(a.[Abnormal Test Count] AS  float)/t.Total_Test_Count), 4) AS Abnormal_Proportion
	FROM Abnormal_Test	a
	INNER JOIN Total_Test_Results	t
	ON a.[Medical Condition] = t.[Medical Condition]
),

Rank_Conditions AS (
	SELECT [Medical Condition], [Abnormal Test Count], Total_Test_Count, Abnormal_Proportion ,
	RANK() OVER(ORDER BY Abnormal_Proportion	DESC) AS Condition_Rank
	FROM Abnormal_Rate
)

SELECT *
FROM Rank_Conditions
WHERE Condition_Rank <= 5
ORDER BY Condition_Rank;
