select * from Portfolio_projects1..coviddeaths 
order by 3,4;

Select * from Portfolio_projects1..covidvaccinations
order by 3,4;


select location,date, total_cases, new_cases, total_deaths, population
from Portfolio_projects1..coviddeaths
order by 1,2;

-- total cases vs total deaths
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Death_percentage 
from Portfolio_projects1..coviddeaths
where continent is not null
order by 1,2;

-- likelihood of dying with covid
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Death_percentage 
from Portfolio_projects1..coviddeaths
where location = 'new zealand' 
order by 1,2;

-- Percentage of population got covid
select location, date, total_cases, population, (total_cases/population)*100 as population_percentage
from Portfolio_projects1..coviddeaths
where continent is not null
order by 1,2;

select location, date, total_cases, population, (total_cases/population)*100 as population_percentage
from Portfolio_projects1..coviddeaths
where location ='new zealand'
order by 1,2;

-- countries with highest infection rates compared with population
select location, population, max(total_cases) as highest_infection_count, max((total_cases/population))*100 as max_population_percentage
from Portfolio_projects1..coviddeaths
where continent is not null
group by location, population
order by max_population_percentage desc;


-- countries with highest infection rates compared with population
select location, population, max(total_deaths) as highest_death_count, max((total_deaths/population))*100 as max_death_percentage
from Portfolio_projects1..coviddeaths
where continent is not null
group by location, population
order by max_death_percentage desc;

-- get the highest deaths percentage with the corresponding date
SELECT
    location,
    population,
    MAX(new_deaths) AS highest_death_count,
    MAX((new_deaths / population)) * 100 AS max_death_percentage,
    MAX(CASE WHEN new_deaths = max_total_deaths THEN date END) AS date_of_highest_deaths
FROM (
    SELECT
        location,
        population,
        new_deaths,
        date,
        MAX(new_deaths) OVER (PARTITION BY location) AS max_total_deaths
    FROM Portfolio_projects1..coviddeaths
	where continent is not null
) AS subquery
GROUP BY
    location,
    population
ORDER BY
    location,
    population;

-- get the highets covid cases corresponding with the date
SELECT
    location,
    population,
    MAX(new_cases) AS highest_case_count,
    MAX((new_cases / population)) * 100 AS max_case_percentage,
    MAX(CASE WHEN new_cases = max_total_cases THEN date END) AS date_of_highest_cases
FROM (
    SELECT
        location,
        population,
        new_cases,
        date,
        MAX(new_cases) OVER (PARTITION BY location) AS max_total_cases
    FROM Portfolio_projects1..coviddeaths
	where continent is not null
) AS subquery
GROUP BY
    location,
    population
ORDER BY
    location,
    population;

-- Continent breakdown
select continent, max(total_deaths) as total_death_count
from Portfolio_projects1..coviddeaths
where continent is not null
group by continent
order by total_death_count desc; 



select location, max(total_deaths) as total_death_count
from Portfolio_projects1..coviddeaths
where continent is null
group by location
order by total_death_count desc; 


-- continent with highest death counts
select continent, max(total_deaths/population)* 100 as highest_death_percentage
from Portfolio_projects1..coviddeaths
where continent is not null
group by continent
order by highest_death_percentage desc; 

-- Global numbers
select date, sum(new_cases) as total_global_cases, sum(new_deaths) as total_global_deaths
from Portfolio_projects1..coviddeaths
where continent is not null
group by date
order by 1,2;

select sum(new_cases) as total_global_cases, sum(new_deaths) as total_global_deaths
from Portfolio_projects1..coviddeaths
where continent is not null
order by 1,2;

-- Joins
-- Total population vs vaccination
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
from Portfolio_projects1..coviddeaths as cd
join Portfolio_projects1..covidvaccinations as cv
on cd.location =cv.location
and cd.date = cv.date
where cd.continent is not null
order by 1,2,3; 



select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
sum(cast(cv.new_vaccinations as bigint)) over (partition by cd.location order by cd.location ,cd.date) as rolling_people_vaccinations
from Portfolio_projects1..coviddeaths AS cd
join Portfolio_projects1..covidvaccinations AS cv
on cd.location = cv.location
    and cd.date = cv.date
where cd.continent is not null
order by 2,3;

-- Get the rolling percentage of population as a percentage
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
sum(cast(cv.new_vaccinations as bigint)) over (partition by cd.location order by cd.location ,cd.date) as rolling_people_vaccinations,
(sum(cast(cv.new_vaccinations as bigint)) over (partition by cd.location order by cd.location ,cd.date))/ cd.population * 100 as rolling_percentage_vacinnated
from Portfolio_projects1..coviddeaths AS cd
join Portfolio_projects1..covidvaccinations AS cv
on cd.location = cv.location
    and cd.date = cv.date
where cd.continent is not null
order by 2,3;

-- Get the rolling percentage of population as a percentage use CTE

with PopvsVac (continent, location, date,population, new_vaccination, rolling_percentage_vaccinated)
as 
(
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
sum(cast(cv.new_vaccinations as bigint)) over (partition by cd.location order by cd.location ,cd.date) as rolling_people_vaccinations
-- (sum(cast(cv.new_vaccinations as bigint)) over (partition by cd.location order by cd.location ,cd.date))/ cd.population * 100 as rolling_percentage_vacinnated
from Portfolio_projects1..coviddeaths AS cd
join Portfolio_projects1..covidvaccinations AS cv
on cd.location = cv.location
    and cd.date = cv.date
where cd.continent is not null

)
select * , (rolling_percentage_vaccinated/population)*100 as rolling_percentage_vaccinated
from PopvsVac; 

-- Temp table
drop table if exists #percent_population_vaccinated
Create table #percent_population_vaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_percentage_vaccinated numeric
)

Insert into #percent_population_vaccinated
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
sum(cast(cv.new_vaccinations as bigint)) over (partition by cd.location order by cd.location ,cd.date) as rolling_people_vaccinations
-- (sum(cast(cv.new_vaccinations as bigint)) over (partition by cd.location order by cd.location ,cd.date))/ cd.population * 100 as rolling_percentage_vacinnated
from Portfolio_projects1..coviddeaths AS cd
join Portfolio_projects1..covidvaccinations AS cv
on cd.location = cv.location
    and cd.date = cv.date
--where cd.continent is not null


select * , (rolling_percentage_vaccinated/population)*100 as rolling_percentage_vaccinated
from #percent_population_vaccinated; 

-- Creating views to store data for later visualisation
create view percentage_population_vaccinated as
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
sum(cast(cv.new_vaccinations as bigint)) over (partition by cd.location order by cd.location ,cd.date) as rolling_people_vaccinations
-- (sum(cast(cv.new_vaccinations as bigint)) over (partition by cd.location order by cd.location ,cd.date))/ cd.population * 100 as rolling_percentage_vacinnated
from Portfolio_projects1..coviddeaths AS cd
join Portfolio_projects1..covidvaccinations AS cv
on cd.location = cv.location
    and cd.date = cv.date
where cd.continent is not null

--use view 
select * from percentage_population_vaccinated;

