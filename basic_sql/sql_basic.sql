---
SELECT *
FROM company
WHERE status = 'closed';

---
SELECT funding_total
FROM company
WHERE category_code = 'news' AND country_code = 'USA'
ORDER BY funding_total DESC;

---
SELECT SUM(price_amount) AS total_cash_deals
FROM acquisition
WHERE term_code = 'cash' AND acquired_at BETWEEN '2011-01-01' AND '2013-12-31';

---
SELECT first_name, last_name, network_username
FROM people
WHERE network_username LIKE 'Silver%';

---
SELECT *
FROM people
WHERE network_username LIKE '%money%' AND last_name LIKE 'K%';

---
SELECT country_code, SUM(funding_total) AS total_investments
FROM company
GROUP BY country_code
ORDER BY total_investments DESC;

---
WITH RoundSummary AS (
    SELECT
        funded_at,
        MIN(raised_amount) AS min_raised_amount,
        MAX(raised_amount) AS max_raised_amount
    FROM funding_round
    GROUP BY funded_at
)

SELECT *
FROM RoundSummary
WHERE min_raised_amount <> 0 AND min_raised_amount <> max_raised_amount;

---
SELECT
    *,
    CASE
        WHEN invested_companies >= 100 THEN 'high_activity'
        WHEN invested_companies >= 20 AND invested_companies < 100 THEN 'middle_activity'
        ELSE 'low_activity'
    END AS activity_category
FROM fund;

---
SELECT
    activity_category,
    ROUND(AVG(investment_rounds)) AS avg_investment_rounds
FROM (
    SELECT
        activity_category,
        investment_rounds
    FROM fund
    LEFT JOIN (
        SELECT
            id AS fund_id,
            CASE
                WHEN invested_companies >= 100 THEN 'high_activity'
                WHEN invested_companies >= 20 AND invested_companies < 100 THEN 'middle_activity'
                ELSE 'low_activity'
            END AS activity_category
        FROM fund
    ) AS categories ON fund.id = categories.fund_id
) AS categorized_funds
GROUP BY activity_category
ORDER BY avg_investment_rounds ASC;

---
SELECT
    country_code,
    MIN(invested_companies) AS min_invested_companies,
    MAX(invested_companies) AS max_invested_companies,
    AVG(invested_companies) AS avg_invested_companies
FROM fund
WHERE founded_at BETWEEN '2010-01-01' AND '2012-12-31'
GROUP BY country_code
HAVING MIN(invested_companies) > 0
ORDER BY avg_invested_companies DESC, country_code
LIMIT 10;

---
SELECT p.first_name, 
       p.last_name, 
       e.instituition
FROM people p
LEFT JOIN education e on p.id =e.person_id

---
SELECT
    c.name AS company_name,
    COUNT(DISTINCT e.instituition) AS unique_education_count
FROM
    company c
JOIN
    people p ON c.id = p.company_id
JOIN
    education e ON p.id = e.person_id
GROUP BY
    c.name
ORDER BY
    unique_education_count DESC
LIMIT 5;

---
SELECT DISTINCT c.name
FROM company c
JOIN funding_round f ON c.id = f.company_id
WHERE c.status = 'closed'
AND is_first_round = 1
AND is_last_round = 1;

---
SELECT DISTINCT p.id AS employee_id
FROM people p
JOIN company c ON p.company_id = c.id
JOIN funding_round f ON c.id = f.company_id
WHERE c.status = 'closed'
  AND is_first_round = 1
  AND is_last_round = 1;

---
SELECT DISTINCT p.id AS employee_id, e.instituition AS education_institution
FROM people p
JOIN education e ON p.id = e.person_id
JOIN company c ON p.company_id = c.id
JOIN funding_round f ON c.id = f.company_id
WHERE c.status = 'closed'
  AND f.is_first_round = 1
  AND f.is_last_round = 1;

---
SELECT
    p.id AS employee_id,
    COUNT(e.instituition) AS education_count
FROM
    people p
JOIN
    education e ON p.id = e.person_id
WHERE 
    p.company_id IN (
        SELECT c.id
        FROM company c
        JOIN funding_round f ON c.id = f.company_id
        WHERE c.status = 'closed'
            AND f.is_first_round = 1
            AND f.is_last_round = 1
    )
GROUP BY
    p.id;

---
SELECT
    AVG(education_count) AS average_education_count
FROM (
    SELECT
        p.id AS employee_id,
        COUNT(e.instituition) AS education_count
    FROM
        people p
    JOIN
        education e ON p.id = e.person_id
    WHERE
        p.company_id IN (
            SELECT c.id
            FROM company c
            JOIN funding_round f ON c.id = f.company_id
            WHERE c.status = 'closed'
                AND f.is_first_round = 1
                AND f.is_last_round = 1
        )
    GROUP BY
        p.id
) AS subquery;

---

SELECT
    AVG(education_count) AS average_education_count
FROM (
    SELECT
        p.id AS employee_id,
        COUNT(e.instituition) AS education_count
    FROM
        people p
    JOIN
        education e ON p.id = e.person_id
    JOIN
        company c ON p.company_id = c.id
    WHERE
        c.name = 'Socialnet'
    GROUP BY
        p.id
) AS subquery;

---
SELECT
    f.name,
    c.name,
    fr.raised_amount
FROM
    investment i
JOIN
    funding_round fr ON i.funding_round_id = fr.id
JOIN
    company c ON fr.company_id = c.id
JOIN
    fund f ON i.fund_id = f.id
WHERE
    c.milestones > 6
    AND fr.funded_at BETWEEN '2012-01-01' AND '2013-12-31';

---

SELECT
    acquirer.name AS acquirer_name,
    acquisition.price_amount AS acquisition_amount,
    acquired.name AS acquired_name,
    COALESCE(SUM(acquired_funding.funding_total), 0) AS investment_amount,
    CASE WHEN COALESCE(SUM(acquired_funding.funding_total), 0) <> 0
         THEN ROUND(acquisition.price_amount / NULLIF(SUM(acquired_funding.funding_total), 0), 0)
         ELSE 0
    END AS ratio
FROM
    acquisition
JOIN
    company acquirer ON acquisition.acquiring_company_id = acquirer.id
JOIN
    company acquired ON acquisition.acquired_company_id = acquired.id
LEFT JOIN
    company acquired_funding ON acquired.id = acquired_funding.id
WHERE
    acquisition.price_amount <> 0 AND acquired_funding.funding_total <> 0
GROUP BY
    acquirer.name, acquisition.price_amount, acquired.name
ORDER BY
    acquisition_amount DESC,
    acquired_name
LIMIT 10;

---

SELECT
    c.name AS company_name,
    EXTRACT(MONTH FROM f.funded_at) AS funding_month
FROM
    company c
JOIN
    funding_round f ON c.id = f.company_id
WHERE
    c.category_code = 'social'
    AND EXTRACT(YEAR FROM f.funded_at) BETWEEN 2010 AND 2013
    AND f.raised_amount <> 0
ORDER BY
    c.name, f.funded_at;

---

WITH acq AS (
  SELECT 
    EXTRACT(Month FROM acquired_at::date) AS month,
    COUNT(acquired_company_id) AS acquired_company,
    SUM(price_amount) AS price_amount
  FROM 
    acquisition a
  WHERE 
    acquired_at::date IS NOT NULL
    AND EXTRACT(YEAR FROM acquired_at::date) BETWEEN 2010 AND 2013  
  GROUP BY 
    month
),
fr AS (
  SELECT 
    EXTRACT(Month FROM fr.funded_at::date) AS month,
    COUNT(DISTINCT f.name) AS fund_name_count
  FROM 
    fund f
    LEFT JOIN investment i ON f.id = i.fund_id
    LEFT JOIN funding_round fr ON i.funding_round_id = fr.id
  WHERE 
    f.country_code = 'USA'
    AND EXTRACT(YEAR FROM fr.funded_at::date) BETWEEN 2010 AND 2013  
  GROUP BY 
    month
)
SELECT 
  COALESCE(acq.month, fr.month) AS month,
  COALESCE(fund_name_count, 0) AS fund_name,
  COALESCE(acq.acquired_company, 0) AS acquired_company,
  COALESCE(acq.price_amount, 0) AS price_amount
FROM 
  acq
  FULL JOIN fr ON acq.month = fr.month
ORDER BY
  month;

---

WITH
  inv_2011 AS (SELECT
      c.country_code,
      AVG(c.funding_total) AS avg_investment_2011
    FROM
      company c
    WHERE
      EXTRACT(YEAR FROM c.founded_at) = 2011 
    GROUP BY
      c.country_code
),
   inv_2012 AS (
 SELECT
      c.country_code,
      AVG(c.funding_total) AS avg_investment_2012
    FROM
      company c
    WHERE
      EXTRACT(YEAR FROM c.founded_at) = 2012 
    GROUP BY
      c.country_code
),
inv_2013 AS (      
SELECT
      c.country_code,
      AVG(c.funding_total) AS avg_investment_2013
    FROM
      company c
    WHERE
      EXTRACT(YEAR FROM c.founded_at) = 2013 
    GROUP BY
      c.country_code
)

  SELECT
  inv_2011.country_code,
  inv_2011.avg_investment_2011,
  inv_2012.avg_investment_2012,
  inv_2013.avg_investment_2013
FROM
  inv_2011
  INNER JOIN inv_2012 ON inv_2011.country_code = inv_2012.country_code
  INNER JOIN inv_2013 ON inv_2011.country_code = inv_2013.country_code
ORDER BY
  inv_2011.avg_investment_2011 DESC;
