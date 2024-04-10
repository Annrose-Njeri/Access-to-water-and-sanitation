/*create Geographic_location Table*/
CREATE TABLE united_nations.Geographic_location (
	country_name VARCHAR(37) PRIMARY KEY,
    sub_region VARCHAR(25),
    region VARCHAR (32),
    Land_area NUMERIC(10,2)
);

/*inserting data into the new table from the old table*/
INSERT INTO united_nations.geographic_location (country_name, sub_region, Region, land_area)
SELECT country_name
		,sub_region
        ,region
        ,AVG(land_area) AS land_area
FROM united_nations.access_to_basic_services
GROUP BY Country_name
		,Sub_region
        ,Region;
        
/*Create Basic.services table*/
CREATE TABLE united_nations.Basic_Services(
		Country_name VARCHAR(37),
        Time_period INTEGER,
        Pct_managed_drinking_water_services NUMERIC(5,2),
        Pct_managed_sanitation_services NUMERIC(5,2),
        PRIMARY KEY (Country_name, Time_period),
        FOREIGN kEY (Country_name) REFERENCES Geographic_location (country_name));

INSERT INTO united_nations.basic_services (country_name, time_period, Pct_managed_drinking_water_services, Pct_managed_sanitation_services)
SELECT Country_name,
		Time_period,
        pct_managed_drinking_water_services,
        pct_managed_sanitation_services
FROM united_nations.access_to_basic_services;

/*Create Economic_Indicators Table*/
CREATE TABLE united_nations.Economic_indicators (
		Country_name VARCHAR(37),
        Time_period INTEGER,
        Est_gdp_in_billions NUMERIC(8,2),
        Est_population_in_millions NUMERIC(11,6),
        Pct_unemployment NUMERIC(5,2),
        PRIMARY KEY (country_name, Time_period),
        FOREIGN KEY (Country_name) REFERENCES Geographic_location (country_name));

INSERT INTO united_nations.economic_indicators (country_name, time_period, Est_gdp_in_billions, Est_population_in_millions, Pct_unemployment)
SELECT Country_name,
        Time_period,
        Est_gdp_in_billions,
        Est_population_in_millions,
        Pct_unemployment
FROM united_nations.access_to_basic_services;

/*adding missing unemployment percentages*/
SELECT 
		loc.country_name,
        eco.time_period,
        IFNULL(eco.pct_unemployment, 19.59) AS Pct_unemployment_inputed
FROM 
	united_nations.geographic_location as loc
LEFT JOIN 
	united_nations.economic_indicators as eco
    ON eco.country_name = loc.country_name
WHERE Region LIKE '%central and southern Asia%'

UNION

SELECT 
		loc.country_name,
        eco.time_period,
        IFNULL(eco.pct_unemployment, 22.64) AS Pct_unemployment_inputed
FROM 
	united_nations.geographic_location as loc
LEFT JOIN 
	united_nations.economic_indicators as eco
    ON eco.country_name = loc.country_name
WHERE Region LIKE '%Eastern and south-eastern Asia%'

UNION
SELECT 
		loc.country_name,
        eco.time_period,
        IFNULL(eco.pct_unemployment, 24.43) AS Pct_unemployment_inputed
FROM 
	united_nations.geographic_location as loc
LEFT JOIN 
	united_nations.economic_indicators as eco
    ON eco.country_name = loc.country_name
WHERE Region LIKE '%Europe and Northern America%'

UNION
SELECT
	loc.country_name,
    eco.time_period,
    IFNULL(eco.pct_unemployment, 24.23) AS Pct_unemployment_imputed
FROM united_nations.Geographic_location AS loc
LEFT JOIN
	united_nations.economic_indicators AS eco
    ON eco.Country_name = loc.country_name
WHERE Region LIKE '%Latin America and the Caribbean%'

UNION 

SELECT 
	loc.country_name,
    eco.Time_period,
    IFNULL(eco.pct_unemployment, 17.84) AS pct_unemployment_imputed
FROM united_nations.Geographic_location AS loc
LEFT JOIN
	united_nations.economic_indicators AS eco
    ON eco.Country_name = loc.country_name
WHERE Region LIKE '%Northern Africa and Western Asia%'

UNION 

SELECT 
	loc.country_name,
    eco.Time_period,
    IFNULL(eco.pct_unemployment, 4.98) AS pct_unemployment_imputed
FROM united_nations.Geographic_location AS loc
LEFT JOIN
	united_nations.economic_indicators AS eco
    ON eco.Country_name = loc.country_name
WHERE Region LIKE 'Oceania%'

UNION

SELECT 
	loc.country_name,
    eco.Time_period,
    IFNULL(eco.pct_unemployment, 33.65) AS pct_unemployment_imputed
FROM united_nations.Geographic_location AS loc
LEFT JOIN
	united_nations.economic_indicators AS eco
    ON eco.Country_name = loc.country_name
WHERE Region LIKE '%Sub-Saharan Africa%';

/*check countries with gdp above global average but still have less than 90% of their population with access to 
managed drinking water using sub-query*/

SELECT 
	econ.Country_name,
    econ.time_period,
    econ.Est_gdp_in_billions,
    service.pct_managed_drinking_water_services
FROM 
	united_nations.economic_indicators AS econ
INNER JOIN
	united_nations.basic_services AS service
ON
	econ.country_name = service.country_name
    AND econ.time_period=service.time_period
WHERE
	econ.Time_period = 2020
    AND service.Pct_managed_drinking_water_services < 90
    AND econ.Est_gdp_in_billions > (SELECT
										AVG(est_gdp_in_billions)
									FROM
										united_nations.economic_indicators
									WHERE
										Time_period = 2020);
                                        
/*countries in sub-saharan Africa with struggling economies that have low access to drinking water and sanitation 
services in the year 2020 using common table expression (CTE)*/

WITH Regional_avg_GDP AS (
SELECT 
	Country_name,
    Region,
    Pct_managed_drinking_water_services,
    Pct_managed_sanitation_services,
    Est_gdp_in_billions,
    AVG (est_gdp_in_billions) OVER(PARTITION BY Region) AS Avg_gdp_for_region
FROM united_nations.access_to_basic_services
WHERE Region = 'sub-saharan Africa'
 AND Time_period = 2020
 AND Pct_managed_drinking_water_services < 60
 order by Est_gdp_in_billions ASC
)
SELECT *
FROM Regional_avg_gdp
WHERE Est_gdp_in_billions < avg_gdp_for_region;
	





