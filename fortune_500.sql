- What is the most common stackoverflow tag_type?
--      What companies have a tag of that type?

SELECT company.name, tag_type.tag, tag_type.type
  FROM company
  	   -- Join to the tag_company table
       INNER JOIN tag_company
       ON company.id = tag_company.company_id
       -- Join to the tag_type table
       INNER JOIN tag_type
       ON tag_company.tag = tag_type.tag

  WHERE type = (SELECT type
			   		      FROM tag_type
			   		      GROUP BY type
			   		      ORDER BY count(*) DESC
			   		      LIMIT 1)

/************************************************************************/
-- Finding the most commom industry from Fortune500 table

-- Use coalesce() to use the value of sector as the industry when industry is NULL
SELECT COALESCE(industry, sector, 'Unknown') AS industry2,
       COUNT(*)
  FROM fortune500
 GROUP BY industry2
 ORDER BY COUNT DESC
 LIMIT 1;

 /********************************************************************/
 -- Compute the average revenue per employee for Fortune
 -- 500 companies by sector.

SELECT sector,
       AVG(revenues/employees:: NUMERIC) AS avg_rev_employee
  FROM fortune500
 GROUP BY sector
 -- Use the column alias to order the results
 ORDER BY avg_rev_employee;

 /*********************************************************************/
 -- Summarize the profit column in the fortune500 per sector
 SELECT sector,
       MIN(profits),
       MAX(profits),
       AVG(profits),
       STDDEV(profits)
  FROM fortune500
 GROUP BY sector
 ORDER BY AVG;

 /************************************************************************/
 -- Find the Fortune 500 companies that have profits in the top
 -- 20% for their sector (compared to other Fortune 500 companies).

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

 /*********************************************************************/
 -- Creating a correlation matrix between profits, profits_change and
 -- revenues_change

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
