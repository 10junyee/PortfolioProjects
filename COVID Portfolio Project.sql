select *
from portfolioproject..COVIDDeaths$
where continent is not null
order by 3,4

--select *
--from portfolioproject..COVIDVaccinations$
--order by 3,4

-- select data to be used
select location, date, total_cases, new_cases, total_deaths, population
from portfolioproject..COVIDDeaths$
order by 1,2

-- total cases vs total deaths
-- shows likelihood of dying if contracting covid in AU
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as deathPercentage
from portfolioproject..COVIDDeaths$
where location like '%australia%'
order by 1,2

-- total cases vs population
-- shows percentage of population contracted covid in AU
select location, date, population, total_cases, (total_cases/population)*100 as casePercentage
from portfolioproject..COVIDDeaths$
where location like '%australia%'
order by 1,2

-- countries with highest infection rate compared to population
select location, population, max(total_cases) as highestInfectionCount, max((total_cases/population))*100 as InfectionPercentage
from portfolioproject..COVIDDeaths$
group by location, population
order by 4 desc,3 desc

-- countries with highest death count per population
select location, max(cast(total_deaths as int)) as TotalDeathCount--, max((total_deaths/population))*100 as InfectionPercentage
from portfolioproject..COVIDDeaths$
where continent is not null
group by location
order by 2 desc

-- CONTINENT BREAKDOWN
-- break down death count by continent
select location, max(cast(total_deaths as int)) as TotalDeathCount--, max((total_deaths/population))*100 as InfectionPercentage
from portfolioproject..COVIDDeaths$
where continent is  null
group by location
order by 2 desc

-- continent with highest death count
select location, max(cast(total_deaths as int)) as TotalDeathCount--, max((total_deaths/population))*100 as InfectionPercentage
from portfolioproject..COVIDDeaths$
where continent is  null
group by location
order by 2 desc

-- GLOBAL NUMBERS
-- total case by date
select date, sum(new_cases) as totalCases, sum(cast(new_deaths as int)) as totaDeaths, (sum(cast(new_deaths as int))/sum(new_cases))*100 as deathPercentage
from portfolioproject..COVIDDeaths$
--where location like '%australia%' 
where continent is not null
group by date
order by 1,2

-- total case
select sum(new_cases) as totalCases, sum(cast(new_deaths as int)) as totaDeaths, (sum(cast(new_deaths as int))/sum(new_cases))*100 as deathPercentage
from portfolioproject..COVIDDeaths$
--where location like '%australia%' 
where continent is not null
order by 1,2

-- total population vs new daily vaccinations
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from portfolioproject..COVIDDeaths$ Dea
join PortfolioProject..COVIDVaccinations$ Vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- total population vs vaccinations (Type 1)
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum(cast(vac.new_vaccinations as bigint)) over (partition by dea.location)
from portfolioproject..COVIDDeaths$ Dea
join PortfolioProject..COVIDVaccinations$ Vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- total population vs vaccinations (Type 2)
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum(convert(bigint, vac.new_vaccinations)) over (partition by dea.location)
from portfolioproject..COVIDDeaths$ Dea
join PortfolioProject..COVIDVaccinations$ Vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- total population vs vaccinations (Type 2) R1
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, sum(convert(bigint, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.Date) as cumulativeSumVac
--	,(cumulativeSumVac/population)*100
from portfolioproject..COVIDDeaths$ Dea
join PortfolioProject..COVIDVaccinations$ Vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- CTE
-- total population vs vaccinations (Type 2) R1
with PopVSVac (continent, location, date, population, new_vaccinations, cumulativeSumVac)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, sum(convert(bigint, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.Date) as cumulativeSumVac
--	,(cumulativeSumVac/population)*100
from portfolioproject..COVIDDeaths$ Dea
join PortfolioProject..COVIDVaccinations$ Vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
select *,(cumulativeSumVac/population)*100
from popvsvac


-- TEMP TABLE
drop table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
cumulativeSumVac numeric,
)

Insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, sum(convert(bigint, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.Date) as cumulativeSumVac
--	,(cumulativeSumVac/population)*100
from portfolioproject..COVIDDeaths$ Dea
join PortfolioProject..COVIDVaccinations$ Vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3

select *,(cumulativeSumVac/population)*100 as VaccinatedPercentage
from #PercentPopulationVaccinated


-- create view to store data for visualisations

create view PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, sum(convert(bigint, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.Date) as cumulativeSumVac
--	,(cumulativeSumVac/population)*100
from portfolioproject..COVIDDeaths$ Dea
join PortfolioProject..COVIDVaccinations$ Vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3