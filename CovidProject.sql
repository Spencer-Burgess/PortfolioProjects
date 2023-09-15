This is an exploratory project looking at COVID statistics in 2020 - 2021

-- Altering new_cases data type

ALTER TABLE PortfolioProject1..CovidDeaths
ALTER COLUMN new_cases bigint;


-- Selecting the data that is going to be used from the CovidDeaths table

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject1..CovidDeaths
WHERE continent is NOT NULL
ORDER BY date


-- Taking a look at total cases vs total deaths, percentages, etc. Shows the chance of dying if you contract Covid in your country.

SELECT location, date, total_cases, total_deaths, total_deaths/total_cases*100 AS DeathPercentage
FROM PortfolioProject1..CovidDeaths
WHERE location LIKE '%states%' AND continent is NOT NULL
ORDER BY location, date


-- Total Cases vs Population, this gives us a percentage of the total population that has had a case of COVID.

SELECT location, date, population, total_cases, (CAST(total_cases as numeric))/(Cast(population as numeric))*100 as PopulationPercentage
FROM PortfolioProject1..CovidDeaths
WHERE continent is NOT NULL
ORDER BY location, date


-- Countries with highest infection rate compared to population, listed as percentages.

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX(CAST(total_cases as numeric))/(Cast(population as numeric))*100 as PopulationInfectionPercentage
FROM PortfolioProject1..CovidDeaths
WHERE continent is NOT NULL
GROUP BY location, population
ORDER BY PopulationInfectionPercentage DESC


-- Showing Countries with highest death count per population, using cast on total_deaths as it is an nvarchar data type, using continent is NOT NULL so that it doesn't show the continent as it's own row

SELECT location, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject1..CovidDeaths
WHERE continent is NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC


-- Now breaking down by continent, using continent is null as the rows with the continent as the location value has their continent column as null

SELECT location, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject1..CovidDeaths
WHERE continent is NULL
GROUP BY location
ORDER BY TotalDeathCount DESC


-- Total global cases vs total global deaths, further illustrated as a percentage

SELECT SUM(new_cases) AS TotalCases, SUM(cast(new_deaths as int)) AS TotalDeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject1..CovidDeaths
WHERE continent is NOT NULL


-- Join the tables (CovidDeaths and CovidVaccinations), Total Population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinationTotal
FROM PortfolioProject1..CovidDeaths AS dea
JOIN PortfolioProject1..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is NOT NULL AND population IS NOT NULL AND new_vaccinations is NOT NULL
ORDER BY location, date


-- Using a CTE so that I can make calculations based off of the RollingPeopleVaccinated. This next one is calculating the percentage of the rolling total of vaccinated people

WITH PopVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject1..CovidDeaths AS dea
JOIN PortfolioProject1..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is NOT NULL AND population IS NOT NULL AND new_vaccinations is NOT NULL
)

SELECT *, (RollingPeopleVaccinated/Population)*100 AS RollingPercentage
FROM PopVac


-- Creating a temp table so that I can perform calculations off of a specified subset of the entire table, DROP TABLE IF EXISTS ensures that I don't try to make additional temp tables when making edits.

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject1..CovidDeaths AS dea
JOIN PortfolioProject1..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is NOT NULL AND population IS NOT NULL AND new_vaccinations is NOT NULL
ORDER BY location, date

SELECT *, (RollingPeopleVaccinated/Population)*100 AS RollingPercentage
FROM #PercentPopulationVaccinated


-- Creating Views to use for visualizations (The first being the percentage of the population being vaccinated over time, the second being the percentage of people who die after contracting COVID, and the third showing the countries with the highest infection rate as a percentage).

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject1..CovidDeaths AS dea
JOIN PortfolioProject1..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is NOT NULL AND population IS NOT NULL AND new_vaccinations is NOT NULL


CREATE VIEW DeathPercentage AS
SELECT location, date, total_cases, total_deaths, total_deaths/total_cases*100 AS DeathPercentage
FROM PortfolioProject1..CovidDeaths
WHERE continent is NOT NULL


CREATE VIEW CountriesHighestInfectionPercentage AS
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX(CAST(total_cases as numeric))/(Cast(population as numeric))*100 as PopulationInfectionPercentage
FROM PortfolioProject1..CovidDeaths
WHERE continent is NOT NULL
GROUP BY location, population

