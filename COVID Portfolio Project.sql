Select *
FROM [Portfolio Proj]..CovidDeaths$
WHERE continent is not null
Order By 3,4

--Select *
--FROM "Portfolio Proj"..CovidVaccinations$
--Order By 3,4

--Select data that I will be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM [Portfolio Proj]..CovidDeaths$
ORDER BY 1,2

--Looking at Total Cases vs Total Deaths
--Shows likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths,
(CONVERT(float,total_deaths)/ NULLIF(CONVERT(float,total_cases), 0))*100 AS DeathPercentage
FROM [Portfolio Proj]..CovidDeaths$
WHERE location like '%states%'
ORDER BY 1,2

--Looking at Total Cases vs Population
--Shows what percentage of the population got Covid

SELECT location, date, total_cases, population,
(total_cases/population)*100 AS PercentPopulationInfected
FROM [Portfolio Proj]..CovidDeaths$
WHERE location like '%states%'
ORDER BY 1,2

--Looking at Countries with Highest Infection Rate compared to Population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, 
Max((total_cases/population))*100 AS PercentPopulationInfected
FROM [Portfolio Proj]..CovidDeaths$
--WHERE location like '%states%'
GROUP BY location, population
ORDER BY PercentPopulationInfected desc

--Showing Countries with Highest Death Count per Population

SELECT location,  MAX(cast(total_deaths as int)) AS TotalDeathCount 
FROM [Portfolio Proj]..CovidDeaths$
--WHERE location like '%states%'
GROUP BY location
ORDER BY TotalDeathCount desc

--Let's break things down by continent

SELECT continent, MAX(cast(total_deaths as int)) AS TotalDeathCount 
FROM [Portfolio Proj]..CovidDeaths$
--WHERE location like '%states%'
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount desc

-- Showing the continents with the highest death count per population
SELECT continent,  MAX(cast(total_deaths as int)) AS TotalDeathCount 
FROM [Portfolio Proj]..CovidDeaths$
--WHERE location like '%states%'
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount desc

-- Global Numbers
SELECT SUM(new_cases)AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, 
CASE
	WHEN SUM(new_cases) = 0 THEN NULL
    ELSE SUM(CAST(new_deaths AS int)) * 100/SUM(new_cases)
    END AS DeathPercentage
FROM [Portfolio Proj]..CovidDeaths$
--WHERE location like '%states%'
WHERE continent is not null
--GROUP BY date
ORDER BY 1,2

--Looking at Total Population vs Vaccinations
Select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
SUM(cast(cv.new_vaccinations as bigint))
OVER (Partition by cd.location ORDER BY cd.location, cd.date) AS RollingPeopleVaccinated
FROM [Portfolio Proj]..CovidDeaths$ cd
JOIN [Portfolio Proj]..CovidVaccinations$ cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent is not null
ORDER BY 2,3

--USE CTE

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
Select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
SUM(cast(cv.new_vaccinations as bigint))
OVER (Partition by cd.location ORDER BY cd.location, cd.date) AS RollingPeopleVaccinated
FROM [Portfolio Proj]..CovidDeaths$ cd
JOIN [Portfolio Proj]..CovidVaccinations$ cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent is not null
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac

--Temp Table
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar (255),
Location nvarchar (255),
Date datetime,
population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert Into #PercentPopulationVaccinated
Select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
SUM(cast(cv.new_vaccinations as bigint))
OVER (Partition by cd.location ORDER BY cd.location, cd.date) AS RollingPeopleVaccinated
FROM [Portfolio Proj]..CovidDeaths$ cd
JOIN [Portfolio Proj]..CovidVaccinations$ cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent is not null
--ORDER BY 2,3
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated

--Creating View to store data for later visualizations

Create View PercentPopulationVaccinated AS
Select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
SUM(cast(cv.new_vaccinations as bigint))
OVER (Partition by cd.location ORDER BY cd.location, cd.date) AS RollingPeopleVaccinated
FROM [Portfolio Proj]..CovidDeaths$ cd
JOIN [Portfolio Proj]..CovidVaccinations$ cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent is not null
--ORDER BY 2,3

SELECT *
FROM PercentPopulationVaccinated