---- Data Cleaning
ALTER TABLE hr_attrition
ADD COLUMN Tenure int;

UPDATE hr_attrition
SET Tenure = timestampdiff(day, Dynamic_Date, Attrition_Date);

-- rename ID column
ALTER TABLE hr_attrition
RENAME COLUMN Employee_No to emp_id;

-- rename job title column
ALTER TABLE hr_attrition
RENAME COLUMN Job_Role to Job_Title;

-- rename attrition_retention column
ALTER TABLE hr_attrition
RENAME COLUMN Switch_Attrition_Retention_1 to Attrition_Retention_1;

ALTER TABLE hr_attrition
RENAME COLUMN Switch_Attrition_Retention_2 to Attrition_Retention_2;


-- Term Date
UPDATE hr_attrition
SET Attrition_Date = REPLACE(Attrition_Date,'-','/');

ALTER TABLE hr_attrition
MODIFY COLUMN Attrition_Date varchar(20);

UPDATE hr_attrition
SET Attrition_Date = NULL
WHERE Attrition_Date = '';

UPDATE hr_attrition
SET Attrition_Date = date_format(str_to_date(Attrition_Date,'%d/%m/%Y'),'%Y-%m-%d');

ALTER TABLE hr_attrition
MODIFY COLUMN Attrition_Date date;


-- Dynamic Date
UPDATE hr_attrition
SET Dynamic_Date = REPLACE(Dynamic_Date,'-','/');

ALTER TABLE hr_attrition
MODIFY COLUMN Dynamic_Date varchar(20);

UPDATE hr_attrition
SET Dynamic_Date = NULL
WHERE Dynamic_Date = '';

UPDATE hr_attrition
SET Dynamic_Date = date_format(str_to_date(Dynamic_Date,'%d/%m/%Y'),'%Y-%m-%d');

ALTER TABLE hr_attrition
MODIFY COLUMN Dynamic_Date date;


-- Checking the gender column
SELECT DISTINCT(Gender)
FROM hr_attrition;

-- checking for empty values
SELECT * FROM hr_attrition
WHERE Gender IS NULL;




---- Data Exploration
-- Total Employees (Check Duplicates)
SELECT emp_id, COUNT(*) as employee_cnt
FROM hr_attrition
GROUP BY emp_id
HAVING employee_cnt > 1;


-- Employees by age group
SELECT
 CASE
  WHEN Age < 30 THEN '20-29'
  WHEN Age < 40 THEN '30-39'
  WHEN Age < 50 THEN '40-49'
  ELSE '50-59'
  END Age_Distribution, COUNT(*) as Age_cnt
FROM hr_attrition
GROUP BY Age_Distribution
ORDER BY Age_cnt DESC;


-- Gender breakdown
What is the gender breakdown of employees in the company?
SELECT Gender, COUNT(*) AS count
FROM hr_attrition
GROUP BY Gender;


-- Salary by Gender
-- Attrition rates and salary by Gender  
SELECT Gender,  AVG(Monthly_Income) AS Avg_Income,
COUNT(*)* 100 / (SELECT COUNT(*) FROM hr_attrition) AS Gender_Percent,
SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) /CAST(COUNT(*) AS DECIMAL(10,2))* 100  AS Attrition_Percent
FROM hr_attrition
GROUP BY Gender
ORDER BY Attrition_Percent DESC


-- Age distribution
SELECT
MIN(Age) AS Youngest,
    MAX(Age) AS Oldest
FROM hr_attrition

	
-- Top 3 Education
SELECT * FROM
(
    SELECT Education_Switch_Calc, COUNT(*) AS count,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM hr_attrition) * 100, 2) AS percentage,
	RANK() OVER(ORDER BY COUNT(*) DESC) AS rnk
	FROM hr_attrition
    GROUP BY Education_Switch_Calc
) cte
WHERE rnk <= 3;


-- Top 3 Departments
SELECT * FROM
(
	SELECT Department, COUNT(*) AS count,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM hr_attrition) * 100, 2) AS percentage,
	RANK() OVER(ORDER BY COUNT(*) DESC) as rnk
	FROM hr_attrition
    GROUP BY Department
) cte
WHERE rnk <= 3;


-- Gender | Job title distribution across departments
SELECT Department, Gender, COUNT(*) AS Employees
FROM hr_attrition
GROUP BY Department, Gender
ORDER BY Department, Employees DESC;


-- Gender distribution across job titles
SELECT Gender, Job_Title, COUNT(*) AS count
FROM hr_attrition
GROUP BY Job_Title, Gender
ORDER BY Job_Title, COUNT DESC;


-- Analyze average age and tenure within each department
SELECT Department, ROUND(AVG(Age)) AS Avg_Age, Tenure
FROM hr_attrition
GROUP BY Department, Tenure
ORDER BY Avg_Age DESC, Tenure;


-- Turnover rate in each departments & job title
WITH cte AS (
 SELECT Department, COUNT(*) total_count,
  COUNT(CASE WHEN Attrition_Date IS NOT NULL THEN 1 END) as attrition_count
 FROM hr_attrition
 GROUP BY Department)

SELECT Department,
  ROUND((attrition_count/
          total_count)*100, 1) AS turnover_rate
FROM cte
ORDER BY turnover_rate DESC;


WITH job_title_count AS (
 SELECT Job_Title, COUNT(*) total_count,
  SUM(CASE WHEN Attrition_Date IS NOT NULL THEN 1 END) termination_count
 FROM hr_attrition
 GROUP BY job_title)

SELECT job_title, ROUND((termination_count
                          /total_count)*100, 1) AS turnover_rate
FROM job_title_count
ORDER BY turnover_rate DESC;



-- Percentage of employees that left the organization
SELECT Job_title,
       COUNT(*) AS Total_Employees,
       SUM(CASE WHEN Attrition = "Yes" THEN 1 ELSE 0 END) AS Attrition_Count,
       ROUND((SUM(CASE WHEN Attrition = "Yes" THEN 1 ELSE 0 END) * 100.0) / NULLIF(COUNT(*), 0), 0) AS Attrition_Percentage_Rounded
FROM hr_attrition
GROUP BY Job_title
ORDER BY Job_title;  



-- Location with highest number of employees
SELECT Department, ROUND(AVG(Age)) AS avg_age,
	COUNT(CASE WHEN Attrition_Retention_2 = "Attrition" THEN 1 END) as Attrition_cnt,
    COUNT(CASE WHEN Attrition_Retention_2 = "Retention" THEN 1 END) as Retention_cnt
FROM hr_attrition
GROUP BY Department
ORDER BY avg_age DESC;



-- Employees who have been with the company the longest and shortest 
SELECT
    Employee_Number,
    MAX(Tenure) AS longest_tenure
FROM hr_attrition
WHERE Tenure IS NOT NULL
GROUP BY Employee_Number
ORDER BY MAX(Tenure) DESC
LIMIT 1;      


-- Shortest tenure
SELECT
    Employee_Number,
    MIN(Tenure) AS shortest_tenure
FROM hr_attrition
WHERE Tenure IS NOT NULL AND Tenure > 0
GROUP BY Employee_Number
ORDER BY MIN(Tenure)
LIMIT 1;    


