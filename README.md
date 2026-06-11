# World Layoffs Data Cleaning & Exploratory Data Analysis (MySQL)

## Project Overview

This project analyzes a global layoffs dataset using MySQL. It consists of two main phases:

1. **Data Cleaning** : Preparing the raw dataset by removing duplicates, standardizing values, handling missing data, and ensuring data consistency.
2. **Exploratory Data Analysis (EDA)** : Investigating layoff trends across companies, industries, countries, and time periods to uncover meaningful insights.

The final result is a clean, analysis-ready dataset along with SQL queries that answer key business questions about global layoffs.

## Dataset

The dataset contains information about company layoffs, including:

- Company name
- Location
- Industry
- Total employees laid off
- Percentage of workforce laid off
- Date of layoff
- Company stage
- Country
- Funds raised (in millions)

Dataset source: [Kaggle - Layoffs Dataset](https://www.kaggle.com/datasets/swaptr/layoffs-2022)

---

# Data Cleaning

## 1. Creating a Staging Table

To preserve the integrity of the raw dataset, staging tables were created and populated with the original data. All cleaning operations were performed on the staging tables rather than the source table.

## 2. Removing Duplicates

Duplicate records were identified using the `ROW_NUMBER()` window function.

Since Common Table Expressions (CTEs) are not directly updatable in MySQL, a second staging table was created with an additional helper column (`row_num`) to identify duplicate rows.

Duplicate records were removed while retaining the first occurrence of each record.

## 3. Standardizing Data

Several columns contained inconsistent formatting and naming conventions.

### Company Names

- Removed leading and trailing whitespace using `TRIM()`.

### Industry Names

Consolidated industry variations such as:

- Crypto Currency
- CryptoCurrency
- Cryptocurrency

into a single standardized value:

- Crypto

### Country Names

- Removed trailing punctuation from country names.
- Standardized entries such as:
  - United States.
  - United States

into:

- United States

### Date Column

- Converted date values from text format to MySQL `DATE` format using `STR_TO_DATE()`.
- Modified the column data type accordingly.

## 4. Handling Missing Values

### Missing Industry Values

- Converted blank industry values to `NULL`.
- Populated missing industries by matching records with the same company and location where industry information was available.

### Missing Layoff Metrics

Rows where both:

- `total_laid_off`
- `percentage_laid_off`

were missing were removed because they contained no useful layoff information for analysis.

## 5. Removing Unnecessary Columns

After duplicate removal was completed, the temporary helper column `row_num` was dropped from the final dataset.

---

# Exploratory Data Analysis (EDA)

The cleaned dataset was analyzed to answer several business questions related to global layoffs.

## Key Areas Explored


### Overall Layoff Trends Analysis

- How have total layoffs changed from year to year?
- Which years experienced the highest number of layoffs?
- How did layoffs evolve on a monthly basis?
- Which months recorded the highest number of layoffs?
- What does the cumulative growth of layoffs look like over time?
- How did layoffs change from one month to the next?
  
### Company Analysis

- Which companies laid off the most employees overall?
- Which companies experienced layoffs across multiple years?
- 

### Industry Analysis

- Which industries were most affected by layoffs?
- How many companies were impacted within each industry?
- How did industry layoffs evolve over time?

### Country Analysis

- Which countries experienced the highest number of layoffs?
- Which countries had the largest number of affected companies?

### Complete Shutdown Analysis
- Which companies laid off 100% of their workforce?
- Which industries experienced the highest number of complete shutdowns?
- Did highly funded companies still undergo significant layoffs?

### Ranking Analysis

- Which companies had the highest layoffs each year?
- Which industries experienced the highest layoffs each year?

---

# Key SQL Concepts Demonstrated

- Window Functions (`ROW_NUMBER()`, `DENSE_RANK()`, `SUM() OVER`)
- Common Table Expressions (CTEs)
- Self Joins
- Aggregate Functions
- Date Functions
- String Manipulation (`TRIM()`)
- Data Standardization
- Data Validation
- Ranking Functions
- Time-Series Analysis
- Data Cleaning Best Practices

---

# Final Result

The final dataset is:

- Free of duplicate records
- Consistent in formatting and naming conventions
- Properly typed for date analysis
- Populated with available missing industry values
- Stripped of records lacking meaningful layoff information
- Ready for exploratory data analysis and visualization

This project demonstrates an end-to-end SQL workflow, from raw data cleaning to business-oriented exploratory analysis.
