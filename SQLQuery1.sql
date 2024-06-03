SELECT *
FROM
PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4;

--SELECT *
--FROM
--PortfolioProject..CovidVaccinations
--ORDER BY 3,4;

-- Select data we gonna use 

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM
PortfolioProject..CovidDeaths
ORDER BY 1,2;


-- Looking at total cases vs Total Deaths
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
FROM
PortfolioProject..CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1,2;

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
FROM
PortfolioProject..CovidDeaths
WHERE location LIKE '%Kazakhstan%'
ORDER BY 1,2;

-- Looking at total cases vs Population
SELECT location, date, total_cases, population, (total_cases/population)*100 as virus_percentage
FROM
PortfolioProject..CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1,2;

-- We gotta know which country has the highest infection rate;
SELECT location, MAX(total_cases) as highest_infection_count, population, MAX((total_cases/population)*100) as virus_percentage
FROM
PortfolioProject..CovidDeaths
GROUP BY population, location
ORDER BY virus_percentage desc;
-- NOTE!
-- In SQL, when you use aggregate functions (like MAX, SUM, AVG, etc.), all non-aggregated columns selected in the SELECT clause must be included in the GROUP BY clause. This is to ensure that the results are logically consistent.

-- We gotta know which country has the highest death rate and death rate compared to population;
SELECT location, MAX(cast(total_deaths as int)) as highest_death_count, population, (MAX(cast(total_deaths as int))/population)*100 as death_percentage
FROM
PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY population, location
ORDER BY death_percentage desc;

SELECT location, MAX(cast(total_deaths as int)) as highest_death_count
FROM
PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY highest_death_count desc;


-- We gotta break things down by continent
-- Showing continents with the highest death count per population;
-- This is not fully correct
SELECT continent, MAX(cast(total_deaths as int)) as highest_death_count
FROM
PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY highest_death_count desc;

-- This is correct
SELECT location, MAX(cast(total_deaths as int)) as highest_death_count
FROM
PortfolioProject..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY highest_death_count desc;

-- GLOBAL NUMBERS
SELECT date, SUM(new_cases) as total_cases, SUM(CAST(new_deaths as INT)) as total_deaths, (SUM(CAST(new_deaths as INT))/SUM(new_cases))*100 as death_percentage_globally
FROM
PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2;

SELECT SUM(new_cases) as total_cases, SUM(CAST(new_deaths as INT)) as total_deaths, (SUM(CAST(new_deaths as INT))/SUM(new_cases))*100 as death_percentage_globally
FROM
PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;


-- Vaccination

SELECT * 
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date;

-- Total Vaccination per countries
SELECT location, SUM(CAST(new_vaccinations as INT)) as total_vaccinations
FROM PortfolioProject..CovidVaccinations
WHERE continent IS NOT NULL -- AND location like '%Kazakhstan%'
GROUP BY location
ORDER BY 1;

-- Total Vaccination vs Population
SELECT dea.continent, dea.location, dea.date, population, vac.new_vaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON  dea.location = vac.location
	AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	ORDER BY 2,3;

SELECT dea.continent, dea.location, dea.date, population, vac.new_vaccinations, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location)
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON  dea.location = vac.location
	AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	ORDER BY 2,3;
-- this is incorrect, see why
SELECT dea.continent, dea.location, dea.date, population, vac.new_vaccinations, SUM(CONVERT(int, vac.new_vaccinations)) as total_tac
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON  dea.location = vac.location
	AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	GROUP BY dea.continent, dea.location, dea.date, population, vac.new_vaccinations
	ORDER BY 2,3;

	-- Use CTE
WITH Pop_vs_Vac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated) as
(
SELECT dea.continent, dea.location, dea.date, population, vac.new_vaccinations
 ,SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rolling_people_vaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON  dea.location = vac.location
	AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
)
SELECT *, (rolling_people_vaccinated/population)*100 as populations_vs_vaccinations 
FROM Pop_vs_Vac;

-- TEMP TABLE, CREATING A TABLE AND INSERTING QUERIES INTO THE TABLE
DROP TABLE IF EXISTS #percent_table_vaccinated
CREATE TABLE #percent_table_vaccinated
(
continent nvarchar(255),
location nvarchar(225),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_people_vaccinated numeric
)

INSERT INTO #percent_table_vaccinated
SELECT dea.continent, dea.location, dea.date, population, vac.new_vaccinations
 ,SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, 
 dea.date) as rolling_people_vaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON  dea.location = vac.location
	AND dea.date = vac.date
SELECT *, (rolling_people_vaccinated/population)*100 as populations_vs_vaccinations 
FROM #percent_table_vaccinated
ORDER BY 2;



-- CREATING VIEW TO STORE DATA FOR LATER VISUALIZATIONS
DROP VIEW percent_table_vaccinated
CREATE VIEW percent_table_vaccinated AS
SELECT dea.continent, dea.location, dea.date, population, vac.new_vaccinations
 ,SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, 
 dea.date) as rolling_people_vaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON  dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null

SELECT * FROM percent_table_vaccinated;