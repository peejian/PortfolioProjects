SELECT *
FROM PortfolioProject..['covidvacc']
WHERE location LIKE ('Malaysia')
ORDER BY 3,4


--SELECT *
--FROM PortfolioProject..['covidVaccination']
--ORDER BY 3,4

--Select Data that we are going to be using 

SELECT location, date, total_cases,new_cases,total_deaths, population
FROM PortfolioProject..['covidDeath']
WHERE location = 'Malaysia'
ORDER BY 1,2

--Looking at Total Cases vs Total Deaths
--Shows likelihood of dying if you contract covid in your country 

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS deathPercentage
FROM PortfolioProject..['covidDeath']
WHERE total_cases >= 1 AND location = 'Malaysia'
ORDER BY 1,2

-- Looking at the total cases vs Population
-- shows what percentage of population got Covid


SELECT location, date, total_cases,population, (total_cases/population)*100 AS populationPercentage
FROM PortfolioProject..['covidDeath']
WHERE total_cases >= 1 AND location = 'Malaysia'
ORDER BY 1,2

--look at Countries with Highest infection rate compared to population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS InfectionRATE
FROM PortfolioProject..['covidDeath']
WHERE total_cases >= 1
GROUP BY location, population
ORDER BY 4 desc


-- LET'S BREAK THINGS DOWN BY CONTINENT


-- Showing Countires with Highest Death Count per population

SELECT location, MAX(cast(Total_deaths as bigint)) AS TotalDeathCount
FROM PortfolioProject..['covidDeath']
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount desc

--Showing continents with the highest death count 

SELECT continent, MAX(cast(Total_deaths as bigint)) AS TotalDeathCount
FROM PortfolioProject..['covidDeath']
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount desc


--GLOBAL NUMBERS

SELECT  SUM(new_cases) as Totalcases, SUM(cast(new_deaths as int)) AS totaldeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject..['covidDeath']
WHERE total_cases >= 1 AND continent IS NOT NULL 
-- location = 'Malaysia'
--GROUP BY date
ORDER BY 1,2


--Looking at Total Population vs Vax
--What wizardry is this 

SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations,
SUM(CONVERT(bigint, vax.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.Date) AS rollingCounto
FROM PortfolioProject..['covidVacc'] vax
JOIN PortfolioProject..['covidDeath'] dea
	ON dea.location = vax.location
	AND dea.date = vax.date
WHERE dea.continent IS NOT NULL AND vax.new_vaccinations>=1
ORDER BY 2,3


-- use CTE

With PopvsVac (continent, location, date, population, new_vaccinations, rollingCounto)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations,
SUM(CONVERT(bigint, vax.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.Date) AS rollingCounto
FROM PortfolioProject..['covidVacc'] vax
JOIN PortfolioProject..['covidDeath'] dea
	ON dea.location = vax.location
	AND dea.date = vax.date
WHERE dea.continent IS NOT NULL --AND vax.new_vaccinations>=1 
--ORDER BY 2,3
)

SELECT *, (rollingCounto/population)*100
FROM PopvsVac

--TEMP TABLE
Drop table if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
date datetime,
Population Numeric,
New_vaccinations numeric,
Rollingcounto numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations,
SUM(CONVERT(bigint, vax.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.Date) AS rollingCounto
FROM PortfolioProject..['covidVacc'] vax
JOIN PortfolioProject..['covidDeath'] dea
	ON dea.location = vax.location
	AND dea.date = vax.date
WHERE dea.continent IS NOT NULL --AND vax.new_vaccinations>=1 
--ORDER BY 2,3

SELECT *
FROM #PercentPopulationVaccinated
where New_vaccinations >= 1
ORDER BY LOCATION


-- creating view to store data for later visualizations

Create view PercentPopulationVaccinated AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations,
SUM(CONVERT(bigint, vax.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.Date) AS rollingCounto
FROM PortfolioProject..['covidVacc'] vax
JOIN PortfolioProject..['covidDeath'] dea
	ON dea.location = vax.location
	AND dea.date = vax.date
WHERE dea.continent IS NOT NULL --AND vax.new_vaccinations>=1 
--ORDER BY 2,3


SELECT *
FROM PercentPopulationVaccinated
order by 3