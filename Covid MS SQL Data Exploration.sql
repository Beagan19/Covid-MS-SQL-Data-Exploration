SELECT *
FROM [dbo].[CovidDeaths]
ORDER BY 3, 4

SELECT *
FROM [dbo].[CovidVaccinations]
ORDER BY 3, 4


SELECT location, date, total_cases, new_cases, total_deaths, population
From [dbo].[CovidDeaths]
ORDER BY 1,2

-- Total cases vs. total deaths in U.S.
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From [dbo].[CovidDeaths]
WHERE location = 'United States'
ORDER BY 1,2


-- Looking at total cases vs. population in U.S.
SELECT location, date, total_cases, population, (total_cases/population)*100 as PositiveCasesPercentage
From [dbo].[CovidDeaths]
WHERE location = 'United States'
ORDER BY 1,2


-- Looking at countries with highest infection rate compared to population
SELECT location,population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PositiveCasesPercentage
From [dbo].[CovidDeaths]
Group BY location, population
ORDER BY PositiveCasesPercentage DESC

-- Countries with highest death count per population
SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM [dbo].[CovidDeaths]
WHERE continent is not null
Group by location
Order by TotalDeathCount DESC


-- Continents with highest death count
SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM [dbo].[CovidDeaths]
WHERE continent is not null
Group by continent
Order by TotalDeathCount DESC


-- Global numbers
SELECT date, SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From [dbo].[CovidDeaths]
WHERE continent is not null
group by date
ORDER BY 1,2

-- Covid Vaccinations Table
SELECT *
FROM [dbo].[CovidVaccinations]

-- Join tables together
SELECT *
FROM [dbo].[CovidDeaths] cd JOIN
[dbo].[CovidVaccinations] cv ON cd.location = cv.location and cd.date = cv.date

-- Total population vs. vaccinations
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, SUM(cast(cv.new_vaccinations as int)) OVER (Partition by cd.location ORDER BY cd.location, cd.date) as RollingVaccinationCount
FROM [dbo].[CovidDeaths] cd JOIN
[dbo].[CovidVaccinations] cv ON cd.location = cv.location and cd.date = cv.date
WHERE cd.continent is not null
ORDER BY 2, 3

-- Using CTE
With PopvsVac (continent, location, date, population, new_vaccinations, RollingVaccinationCount)
as
(
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, SUM(cast(cv.new_vaccinations as int)) OVER (Partition by cd.location ORDER BY cd.location, cd.date) as RollingVaccinationCount
FROM [dbo].[CovidDeaths] cd JOIN
[dbo].[CovidVaccinations] cv ON cd.location = cv.location and cd.date = cv.date
WHERE cd.continent is not null
)
SELECT *, (RollingVaccinationCount/population)*100 as RollingVaccinationPercentage
FROM PopvsVac


-- Temp Table
DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingVaccinationCount numeric,
)
Insert into #PercentPopulationVaccinated
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, SUM(cast(cv.new_vaccinations as int)) OVER (Partition by cd.location ORDER BY cd.location, cd.date) as RollingVaccinationCount
FROM [dbo].[CovidDeaths] cd JOIN
[dbo].[CovidVaccinations] cv ON cd.location = cv.location and cd.date = cv.date
WHERE cd.continent is not null

SELECT *, (RollingVaccinationCount/population)*100 as RollingVaccinationPercentage
FROM #PercentPopulationVaccinated

-- Creating view to store data for later visualizations
CREATE VIEW PercentPopulaionVaccinated as
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, SUM(cast(cv.new_vaccinations as int)) OVER (Partition by cd.location ORDER BY cd.location, cd.date) as RollingVaccinationCount
FROM [dbo].[CovidDeaths] cd JOIN
[dbo].[CovidVaccinations] cv ON cd.location = cv.location and cd.date = cv.date
WHERE cd.continent is not null