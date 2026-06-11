
-- Data Cleaning process :

-- 1. Remove Duplicates
-- 2. Standardize the Data
-- 3. NULL values or blank values
-- 4. Remove Any Columns

# -------------- CREATING THE STAGING TABLE -------------- #

/* 
DROP TABLE IF EXISTS layoffs;
DROP TABLE IF EXISTS layoffs_staging;
DROP TABLE IF EXISTS layoffs_staging2;
*/

SELECT *
FROM world_layoffs.layoffs;

-- Create a staging table to preserve the raw dataset
CREATE TABLE layoffs_staging
LIKE world_layoffs.layoffs;

-- Copy data into the staging table for cleaning
INSERT world_layoffs.layoffs_staging
SELECT *
FROM world_layoffs.layoffs;

SELECT *
FROM world_layoffs.layoffs_staging;

# -------------- REMOVING DUPLICATES -------------- #

-- Identify duplicate records using ROW_NUMBER()
WITH duplicates AS (
	SELECT 
		*,
		ROW_NUMBER() OVER (
			PARTITION BY company, 
						 location,
						 industry, 
						 total_laid_off, 
						 percentage_laid_off, 
						 `date`,
                         stage,
                         country,
                         funds_raised_millions
		) AS row_num
	FROM world_layoffs.layoffs_staging
)

SELECT *
FROM duplicates
WHERE row_num > 1;

-- MySQL CTEs are not directly updatable, so create a new table
-- with a helper column to facilitate duplicate removal

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Populate the new staging table and assign row numbers
INSERT INTO world_layoffs.layoffs_staging2
SELECT 
	*,
	ROW_NUMBER() OVER (
		PARTITION BY company, 
					 location,
					 industry, 
					 total_laid_off, 
					 percentage_laid_off, 
					 `date`,
					 stage,
					 country,
					 funds_raised_millions
	) AS row_num
FROM world_layoffs.layoffs_staging;

SELECT * FROM world_layoffs.layoffs_staging2;

-- Disable safe update mode to allow deletion
SET SQL_SAFE_UPDATES = 0;

-- Remove duplicate records, keeping only the first occurrence
DELETE
FROM world_layoffs.layoffs_staging2
WHERE row_num > 1;

# -------------- STANDARDIZING DATA -------------- #

SELECT *
FROM world_layoffs.layoffs_staging2;

# -- Standardizing company names by removing leading and trailing spaces

SELECT company, TRIM(company)
FROM world_layoffs.layoffs_staging2;

UPDATE world_layoffs.layoffs_staging2
SET company = TRIM(company);

SELECT company
FROM world_layoffs.layoffs_staging2;

# -- Standardizing industry names 

SELECT DISTINCT industry
FROM world_layoffs.layoffs_staging2;

-- We notice that there are different name variations of the same Crypto industry

-- Identify variations of the Crypto industry label
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE industry LIKE '%Crypto%';

-- Consolidate all Crypto-related labels into a single value
UPDATE world_layoffs.layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE '%Crypto%';

SELECT DISTINCT industry
FROM world_layoffs.layoffs_staging2;

# -- Standardizing country names

SELECT DISTINCT country
FROM world_layoffs.layoffs_staging2
ORDER BY country;

-- We notice a trailing '.' after some occurrences of 'United States'

UPDATE world_layoffs.layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States';

SELECT DISTINCT country
FROM world_layoffs.layoffs_staging2
ORDER BY country;


# -- Standardizing date values by converting them from TEXT to DATE format

SELECT `date`, STR_TO_DATE(`date`, '%m/%d/%Y')
FROM world_layoffs.layoffs_staging2;

-- Convert date strings to MySQL DATE values
UPDATE world_layoffs.layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Change the column data type from TEXT to DATE
ALTER TABLE world_layoffs.layoffs_staging2
MODIFY COLUMN `date` DATE;


# -------------- HANDLING NULL OR BLANK VALUES -------------- #

# -- Handling NULL industry values

-- We work on populating missing industry values by matching records 
-- from the same company and location that already have an industry

-- Identify missing industry values
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE industry IS NULL OR industry = '';

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE company = 'Airbnb';

-- We standardize blank industries to NULL
UPDATE world_layoffs.layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- Find matching records that can be used to fill missing industries
SELECT *
FROM world_layoffs.layoffs_staging2 st1
JOIN world_layoffs.layoffs_staging2 st2
	ON st1.company = st2.company
	AND st1.location = st2.location
WHERE (st1.industry IS NULL OR st1.industry = '') 
	AND st2.industry IS NOT NULL;

-- Populate missing industry values using matching company records
UPDATE world_layoffs.layoffs_staging2 st1
JOIN world_layoffs.layoffs_staging2 st2
	ON st1.company = st2.company
 SET st1.industry = st2.industry
 WHERE st1.industry IS NULL 
	AND st2.industry IS NOT NULL;
    
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE industry IS NULL OR industry = '';

-- The only NULL case that hasn't been treated is one we cannot populate 
-- since there's no matching record of this company 

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE company = 'Bally''s Interactive';

# -- Handling NULL total_laid_off and percentage_laid_off

-- We remove records where both total_laid_off AND percentage_laid_off are missing
-- as they provide no layoff information and are not useful for analysis

-- Check rows with missing total layoffs
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL;

-- Check rows with missing layoff percentages
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE percentage_laid_off IS NULL;

-- Identify rows missing both key layoff metrics
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL 
	AND percentage_laid_off IS NULL;

-- Remove rows that contain no layoff information
DELETE
FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL 
	AND percentage_laid_off IS NULL;
    
-- Verify deletion
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL 
	AND percentage_laid_off IS NULL;
 
SELECT *
FROM world_layoffs.layoffs_staging2;

# -------------- DROPPING COLUMNS -------------- #

-- Remove the temporary row number column used for duplicate identification and removal
ALTER TABLE world_layoffs.layoffs_staging2
DROP COLUMN row_num;

# -------------- FINAL DATASET -------------- #

SELECT *
FROM world_layoffs.layoffs_staging2;

