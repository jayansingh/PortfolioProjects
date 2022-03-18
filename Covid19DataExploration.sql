/*
Link to Dataset: https://ourworldindata.org/covid-deaths
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 3,4


-- Select Data that we are going to be starting with

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 1,2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
AND location LIKE '%canada%'
ORDER BY 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

SELECT Location, date, Population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
AND location LIKE '%canada%'
ORDER BY 1,2


-- Countries with Highest Infection Rate compared to Population

SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount,  MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
--AND location LIKE '%canada%'
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC


-- Countries with Highest Death Count per Population

SELECT Location, MAX(CAST(Total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
--AND location LIKE '%canada%'
GROUP BY Location
ORDER BY TotalDeathCount DESC



-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

SELECT Location AS Continent, MAX(CAST(Total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL and Location NOT LIKE '%income%'
--AND location LIKE '%canada%'
GROUP BY Location
ORDER BY TotalDeathCount DESC



-- GLOBAL NUMBERS

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT))/SUM(New_Cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
--AND location LIKE '%canada%'
--GROUP BY date
ORDER BY 1,2



-- Total Population vs Vaccinations
-- Shows Population that has recieved both doses Covid Vaccine

SELECT dea.Location, MAX((vac.people_vaccinated/dea.population))*100 AS PercentPeopleVaccinated,  MAX((vac.people_fully_vaccinated/dea.population))*100 AS PercentPeopleFullyVaccinated
FROM PortfolioProject..CovidDeaths dea
INNER JOIN PortfolioProject..CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
AND dea.location LIKE '%canada%'
GROUP BY dea.Location
ORDER BY PercentPeopleVaccinated DESC


-- Shows Population that has recieved at least one Covid Vaccine

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(BIGINT,vac.new_vaccinations)) OVER (Partition by dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
INNER JOIN PortfolioProject..CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
AND dea.location LIKE '%canada%'
ORDER BY 2,3

-- While checking the output, RollingPeopleVaccinated is displaying more than total population
-- So now displaying unique Population that has recieved at least one Covid Vaccine

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_people_vaccinated_smoothed
, SUM(CONVERT(BIGINT,vac.new_people_vaccinated_smoothed)) OVER (Partition by dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
INNER JOIN PortfolioProject..CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
AND dea.location LIKE '%canada%'
ORDER BY 2,3


-- Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_people_vaccinated_smoothed
, SUM(CONVERT(BIGINT,vac.new_people_vaccinated_smoothed)) OVER (Partition by dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
INNER JOIN PortfolioProject..CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
AND dea.location LIKE '%canada%'
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_people_vaccinated_smoothed
, SUM(CONVERT(BIGINT,vac.new_people_vaccinated_smoothed)) OVER (Partition by dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
INNER JOIN PortfolioProject..CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
AND dea.location LIKE '%canada%'
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated



-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_people_vaccinated_smoothed AS New_vaccinations
, SUM(CONVERT(BIGINT,vac.new_people_vaccinated_smoothed)) OVER (Partition by dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
INNER JOIN PortfolioProject..CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *
FROM PercentPopulationVaccinated