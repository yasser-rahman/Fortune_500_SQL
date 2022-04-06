-- Database: Fortune500

DROP DATABASE IF EXISTS "Fortune500";

CREATE DATABASE "Fortune500"
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'English_United States.1252'
    LC_CTYPE = 'English_United States.1252'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;


-- Creating Table "fortune500"

DROP TABLE IF EXISTS "fortune500";
CREATE TABLE "fortune500"(
	"id" SERIAL,
	"rank" INTEGER,
	"title" VARCHAR PRIMARY KEY,
	"name" VARCHAR,
	"ticker" CHAR(5),
	"url" VARCHAR,
	"hq" VARCHAR,
	"sector" VARCHAR,
	"industry" VARCHAR,
	"employees" INTEGER,
	"revenues" INTEGER,
	"revenues_change" REAL,
	"profits" NUMERIC,
	"profits_change" REAL,
	"assets" NUMERIC,
	"equity" NUMERIC
);


-- Migrating data from csv file into fortune500.

COPY "fortune500"("rank", "title", "name", "ticker", "url", "hq",
     "sector", "industry", "employees", "revenues", "revenues_change",
     "profits", "profits_change", "assets", "equity")
FROM 'C:\Users\Yasser A.RahmAN\Desktop\SQL for Business Analytics\fortune.csv'
DELIMITER ','
CSV HEADER;

-- Compute the average revenue per employee for Fortune 500 companies by sector.

SELECT sector, ROUND(AVG(revenues/employees:: NUMERIC), 2) avg_rev_empl
FROM fortune500
GROUP BY sector
ORDER BY avg_rev_empl DESC;

-- Summarize numeric columns
-- Summarize profits column in fortune500 by sector
SELECT sector,
	   AVG(profits),
	   MIN(profits),
	   MAX(profits),
	   VARIANCE(profits),
	   STDDEV(profits)
FROM fortune500
GROUP BY sector
ORDER BY AVG;

-- Exploring a Variable Distribtion in a dataset
SELECT trunc(profits,-3), COUNT(*)
FROM fortune500
GROUP BY 1
ORDER BY 1;
-- Exploring the mutual relationships among revenue, equity, asset
SELECT ROUND(corr(revenues, profits):: NUMERIC, 2) AS revenue_profit_corrlation,
	   ROUND(corr(revenues, assets):: NUMERIC, 2) AS revenue_asset_corrlation,
	   ROUND(corr(revenues, equity):: NUMERIC, 2) AS revenue_equity_corrlation

FROM fortune500;


-- Compute the mean (avg()) and median assets of Fortune 500
-- companies by sector.
SELECT sector,
	   AVG(assets) AS MEAN, -- Assets Mean
	   PERCENTILE_disc(0.5) WITHIN GROUP (ORDER BY assets) AS MEDIAN -- Median
FROM fortune500
GROUP BY sector;

-- Top 10 compnaies in Fortune500

CREATE TEMP TABLE "top_10" AS
SELECT "rank", "title"
FROM fortune500
WHERE "rank" <= 10

-- Find the Fortune 500 companies that have profits in the top 20% for their
-- sector (compared to other Fortune 500 companies).

DROP TABLE IF EXISTS profit80;

CREATE TEMP TABLE profit80 AS
SELECT sector,
         percentile_disc(0.8) WITHIN GROUP (ORDER BY profits) AS pct80
FROM fortune500
GROUP BY sector;

-- Select columns, aliasing as needed
SELECT title, fortune500.sector,
       profits, profits/pct80 AS ratio
-- What tables do you need to join?
  FROM fortune500
       LEFT JOIN profit80
-- How are the tables joined?
       ON fortune500.sector=profit80.sector
-- What rows do you want to select?
 WHERE profits > pct80;

 -- Compute the correlations between each pair of profits, profits_change,
 -- and revenues_change from the Fortune 500 data.
 DROP TABLE IF EXISTS correlations;

CREATE TEMP TABLE correlations AS
SELECT 'profits'::varchar AS measure,
       corr(profits, profits) AS profits,
       corr(profits, profits_change) AS profits_change,
       corr(profits, revenues_change) AS revenues_change
  FROM fortune500;

INSERT INTO correlations
SELECT 'profits_change'::varchar AS measure,
       corr(profits_change, profits) AS profits,
       corr(profits_change, profits_change) AS profits_change,
       corr(profits_change, revenues_change) AS revenues_change
  FROM fortune500;

INSERT INTO correlations
SELECT 'revenues_change'::varchar AS measure,
       corr(revenues_change, profits) AS profits,
       corr(revenues_change, profits_change) AS profits_change,
       corr(revenues_change, revenues_change) AS revenues_change
  FROM fortune500;

-- Select each column, rounding the correlations
SELECT measure,
       round(profits::numeric, 2) AS profits,
       round(profits_change::numeric, 2) AS profits_change,
       round(revenues_change::numeric, 2) AS revenues_change
  FROM correlations;
