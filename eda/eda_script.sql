# -------------- EXPLORATORY DATA ANALYSIS (EDA) -------------- #

-- View the cleaned dataset
SELECT *
FROM world_layoffs.layoffs_staging2;

# --------------- 1. Overall Layoff Trends --------------- #

-- Analyze total layoffs by year
SELECT 
	YEAR(`date`), 
    SUM(total_laid_off) AS total_layoffs
FROM world_layoffs.layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;

-- Analyze year-over-year growth

WITH yearly AS (
	SELECT 
		YEAR(`date`) AS `year`, 
		SUM(total_laid_off) AS total_layoffs
	FROM world_layoffs.layoffs_staging2
	GROUP BY YEAR(`date`)
)

SELECT 
	year,
    total_layoffs AS curr_year_layoffs,
    LAG(total_layoffs) OVER ( ORDER BY year) AS prev_year_layoffs,
    total_layoffs - LAG(total_layoffs) OVER ( ORDER BY year) AS yearly_change_amount
FROM yearly;

-- Analyze total layoffs by month

SELECT 
	DATE_FORMAT(`date`, '%Y-%m') AS `month`,
    SUM(total_laid_off) AS total_layoffs
FROM world_layoffs.layoffs_staging2
WHERE DATE_FORMAT(`date`, '%Y-%m') IS NOT NULL
GROUP BY `month`
ORDER BY 1 ASC;

-- Worst month for layoffs

SELECT 
	DATE_FORMAT(`date`, '%Y-%m') AS `month`,
    SUM(total_laid_off) AS total_layoffs
FROM world_layoffs.layoffs_staging2
GROUP BY `month`
ORDER BY 2 DESC;
 
 -- Calculate the cumulative number of layoffs over time (monthly)
WITH rolling_total AS (
	SELECT 
		DATE_FORMAT(`date`, '%Y-%m') AS `month`,
		SUM(total_laid_off) AS mth_total
	FROM world_layoffs.layoffs_staging2
	WHERE DATE_FORMAT(`date`, '%Y-%m') IS NOT NULL
	GROUP BY `month`
	ORDER BY 1 ASC
)

SELECT
	`month`,
    mth_total,
    SUM(mth_total) OVER (
		ORDER BY `month`
    ) AS rolling_sum
FROM rolling_total;

-- Analyze the month-over-month layoff growth
WITH monthly AS (
	SELECT 
		DATE_FORMAT(`date`, '%Y-%m') AS `month`, 
		SUM(total_laid_off) AS layoffs
	FROM world_layoffs.layoffs_staging2
    WHERE DATE_FORMAT(`date`, '%Y-%m') IS NOT NULL
	GROUP BY `month`
    ORDER BY 1
)
 
SELECT 
	month,
    layoffs AS curr_month_layoffs,
    LAG(layoffs) OVER ( ORDER BY month ) AS prev_month_layoffs,
    layoffs - LAG(layoffs) OVER ( ORDER BY month ) AS monthly_change_amount
FROM monthly;


# --------------- 2. Company Analysis --------------- #


-- Find the companies with the highest total number of layoffs
SELECT company, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

-- Identify companies that experienced layoffs in multiple years
SELECT 
	company,
	COUNT(DISTINCT YEAR(`date`)) AS years_with_layoffs
FROM world_layoffs.layoffs_staging2
GROUP BY company
HAVING years_with_layoffs > 1
ORDER BY years_with_layoffs DESC;

# --------------- 3. Country Analysis --------------- #

-- Calculate total layoffs by country
SELECT country, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

-- Count the number of companies represented in each country
SELECT 
	country, 
    COUNT(company) AS country_companies_count
FROM world_layoffs.layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

# --------------- 4. Industry Analysis --------------- #

-- Calculate total layoffs by industry
SELECT industry, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;

-- Analyze layoffs by industry over time (monthly)
SELECT industry, SUBSTRING(`date`, 1, 7), SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY industry, SUBSTRING(`date`, 1, 7)
ORDER BY 3 DESC;

-- Count the number of companies affected represented in each industry
SELECT 
	industry, 
    COUNT(DISTINCT company) AS industry_companies_affected_count
FROM world_layoffs.layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;

-- Analyze industry layoffs by year
SELECT 
	YEAR(`date`) AS `year`,
    industry,
    SUM(total_laid_off) AS total_layoffs
FROM world_layoffs.layoffs_staging2
WHERE YEAR(`date`) IS NOT NULL
GROUP BY `year`, industry
ORDER BY 1, 3 DESC;

# --------------- 5. Complete Shutdown Analysis --------------- #

-- Identify companies that laid off 100% of their workforce
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE percentage_laid_off = 1;

-- Identify industries with the most complete shutdowns
SELECT
	industry,
    COUNT(*) AS shutdowns
FROM world_layoffs.layoffs_staging2
WHERE percentage_laid_off = 1
GROUP BY industry
ORDER BY 2 DESC;

-- Analyze largest layoffs among well-funded companies
SELECT
	company,
    funds_raised_millions,
    SUM(total_laid_off) AS total_layoffs
FROM world_layoffs.layoffs_staging2
GROUP BY company, funds_raised_millions
ORDER BY funds_raised_millions DESC;

# --------------- 6. Ranking queries --------------- #

-- Rank the top 5 companies with the most layoffs each year
WITH company_year (company, years, total_laid_off) AS (
	SELECT 
		company,
		YEAR(`date`),
		SUM(total_laid_off)
	FROM world_layoffs.layoffs_staging2
	GROUP BY company, YEAR(`date`)
	ORDER BY 3 DESC
),

company_years_ranked AS (
	SELECT 
		*, 
		DENSE_RANK() OVER (
			PARTITION BY years
			ORDER BY total_laid_off DESC
		) ranking
	FROM company_year
	WHERE years IS NOT NULL
)

SELECT *
FROM company_years_ranked
WHERE ranking <= 5;

-- Rank the top 3 industries with the highest layoffs total each year

WITH industry_year AS (
	SELECT
		YEAR(`date`) AS year,
        industry,
        SUM(total_laid_off) AS total_layoffs
    FROM world_layoffs.layoffs_staging2
    GROUP BY industry, year
),

industries_ranked AS (
	SELECT
		*,
		DENSE_RANK() OVER (
			PARTITION BY year
			ORDER BY total_layoffs DESC
		) AS ranking
	FROM industry_year
)

SELECT
	*
FROM industries_ranked
WHERE ranking <= 3;
