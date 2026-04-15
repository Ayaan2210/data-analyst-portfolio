-- =========================================================
-- HR ANALYTICS — EMPLOYEE ATTRITION ANALYSIS (POSTGRESQL)
-- Dataset: IBM HR Analytics | 1,470 Records
-- Focus: Attrition Patterns, Department, Salary, Overtime
-- =========================================================


-- =========================================================
-- 1. Overall Attrition Rate
-- =========================================================
SELECT
    COUNT(*) AS total_employees,
    SUM(CASE WHEN "Attrition" = 'Yes' THEN 1 ELSE 0 END) AS employees_left,
    ROUND(
        SUM(CASE WHEN "Attrition" = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS attrition_rate_pct
FROM employee_data;

-- 💡 Insight: Baseline attrition — compare against industry benchmark of 10-15%


-- =========================================================
-- 2. Department-wise Attrition Rate (CTE)
-- =========================================================
WITH dept_stats AS (
    SELECT
        "Department",
        COUNT(*) AS total,
        SUM(CASE WHEN "Attrition" = 'Yes' THEN 1 ELSE 0 END) AS left_count
    FROM employee_data
    GROUP BY "Department"
)
SELECT
    "Department",
    total,
    left_count,
    ROUND(left_count * 100.0 / total, 2) AS attrition_rate_pct
FROM dept_stats
ORDER BY attrition_rate_pct DESC;

-- 💡 Insight: Sales typically leads attrition — high-pressure target-driven environment


-- =========================================================
-- 3. Age Group Attrition Analysis (CTE)
-- =========================================================
WITH age_groups AS (
    SELECT *,
        CASE
            WHEN "Age" < 26 THEN '18-25'
            WHEN "Age" BETWEEN 26 AND 35 THEN '26-35'
            WHEN "Age" BETWEEN 36 AND 45 THEN '36-45'
            WHEN "Age" BETWEEN 46 AND 55 THEN '46-55'
            ELSE '55+'
        END AS age_group
    FROM employee_data
)
SELECT
    age_group,
    COUNT(*) AS total,
    SUM(CASE WHEN "Attrition" = 'Yes' THEN 1 ELSE 0 END) AS left_count,
    ROUND(
        SUM(CASE WHEN "Attrition" = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS attrition_rate_pct
FROM age_groups
GROUP BY age_group
ORDER BY age_group;

-- 💡 Insight: Younger employees explore more options — higher early-career attrition


-- =========================================================
-- 4. Salary Quartile Analysis (Window Function)
-- =========================================================
WITH salary_bands AS (
    SELECT *,
        NTILE(4) OVER (ORDER BY "MonthlyIncome") AS salary_quartile
    FROM employee_data
),
quartile_stats AS (
    SELECT
        salary_quartile,
        MIN("MonthlyIncome") AS min_salary,
        MAX("MonthlyIncome") AS max_salary,
        COUNT(*) AS total,
        SUM(CASE WHEN "Attrition" = 'Yes' THEN 1 ELSE 0 END) AS left_count
    FROM salary_bands
    GROUP BY salary_quartile
)
SELECT
    CONCAT('Q', salary_quartile) AS quartile,
    min_salary,
    max_salary,
    total,
    left_count,
    ROUND(left_count * 100.0 / total, 2) AS attrition_rate_pct
FROM quartile_stats
ORDER BY salary_quartile;

-- 💡 Insight: Q1 (lowest salary) almost always has the highest attrition rate


-- =========================================================
-- 5. Job Role Attrition with Ranking (Window Function)
-- =========================================================
WITH role_stats AS (
    SELECT
        "JobRole",
        COUNT(*) AS total,
        SUM(CASE WHEN "Attrition" = 'Yes' THEN 1 ELSE 0 END) AS left_count,
        ROUND(
            SUM(CASE WHEN "Attrition" = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
            2
        ) AS attrition_rate_pct
    FROM employee_data
    GROUP BY "JobRole"
)
SELECT
    "JobRole",
    total,
    left_count,
    attrition_rate_pct,
    RANK() OVER (ORDER BY attrition_rate_pct DESC) AS attrition_rank
FROM role_stats;

-- 💡 Insight: Sales Rep and Lab Technician consistently rank highest


-- =========================================================
-- 6. Overtime Impact on Attrition
-- =========================================================
SELECT
    "OverTime",
    COUNT(*) AS total_employees,
    SUM(CASE WHEN "Attrition" = 'Yes' THEN 1 ELSE 0 END) AS left_count,
    ROUND(
        SUM(CASE WHEN "Attrition" = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS attrition_rate_pct,
    ROUND(AVG("MonthlyIncome"), 0) AS avg_monthly_income
FROM employee_data
GROUP BY "OverTime";

-- 💡 Insight: Overtime employees leave at 2-3x rate — workload is a major push factor


-- =========================================================
-- 7. Repeat Attrition Risk — High Risk Employee Profile
-- =========================================================
SELECT
    "EmployeeNumber",
    "Age",
    "Department",
    "JobRole",
    "MonthlyIncome",
    "YearsAtCompany",
    "JobSatisfaction",
    "OverTime",
    "Attrition"
FROM employee_data
WHERE
    "OverTime" = 'Yes'
    AND "JobSatisfaction" <= 2
    AND "YearsAtCompany" <= 3
    AND "MonthlyIncome" < (SELECT AVG("MonthlyIncome") FROM employee_data)
ORDER BY "MonthlyIncome" ASC;

-- 💡 Insight: These employees match the highest-risk attrition profile


-- =========================================================
-- 8. Cumulative Attrition by Years at Company (Window Function)
-- =========================================================
WITH year_stats AS (
    SELECT
        "YearsAtCompany",
        COUNT(*) AS total,
        SUM(CASE WHEN "Attrition" = 'Yes' THEN 1 ELSE 0 END) AS left_count
    FROM employee_data
    GROUP BY "YearsAtCompany"
)
SELECT
    "YearsAtCompany",
    total,
    left_count,
    ROUND(left_count * 100.0 / total, 2) AS attrition_rate_pct,
    SUM(left_count) OVER (ORDER BY "YearsAtCompany") AS cumulative_attrition
FROM year_stats
ORDER BY "YearsAtCompany";

-- 💡 Insight: First 2-3 years are the most critical — highest attrition window


-- =========================================================
-- END OF PROJECT
-- =========================================================