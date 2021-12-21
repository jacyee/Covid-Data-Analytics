/*covid data exploration*/

use [coviddata]
select top 10 * from covid_death$

-- Explore data fields from the covid death table
select location,date,total_cases,new_cases,cast (total_deaths as int)as total_deaths,cast (new_deaths as int)as new_deaths,population
from [coviddata]..covid_death$
where continent is not null
order by 1,2 desc

-- total global cases & fatality death rate over the world
select sum(new_cases) as total_cases, sum(cast (new_deaths as int)) as total_deaths, 
round(sum(cast (new_deaths as int))/sum(new_cases)*100 ,2)as global_death_rate
from [coviddata]..covid_death$
where continent is not null 

-- select country with top total cases
select top 10 location, max(total_cases) as totalcases
from [coviddata]..covid_death$
where continent is not null 
group by location
having max(total_cases) is not null
order by 2 desc

--select ranking for total cases in e.g. UK
select t.location,t.case_rank
from(
select location,
rank() over(order by max(total_cases)desc) case_rank
from [coviddata]..covid_death$
where continent is not null
group by location
having max(total_cases) is not null)t
where t.location='United Kingdom'

-- Fatality death rate by country
select top 5 t.location,t.c_death_rate,t.c_death_rank
from(
select location, round((max(total_deaths)/max(total_cases))*100 ,2)as c_death_rate,
rank() over(order by max(total_deaths)/max(total_cases)desc) c_death_rank
from  [coviddata]..covid_death$
where continent is not null
group by location
having  max(total_deaths)/max(total_cases)is not null)t

--Mortality death rate by country
select top 5 t.location,t.p_death_rate,t.p_death_rank
from(
select location, round((max(total_deaths)/max(population))*100,2)as p_death_rate,
rank() over(order by max(total_deaths)/max(population)desc) p_death_rank
from  [coviddata]..covid_death$
where continent is not null
group by location
having  max(total_deaths)/max(population)is not null)t

--Infection Rate by country
select top 5 t.location,t.infection_rate,t.infection_rank
from(
select location, round((max(total_cases)/max(population))*100,2)as infection_rate,
rank() over(order by max(total_cases)/max(population)desc) infection_rank
from  [coviddata]..covid_death$
where continent is not null
group by location
having  max(total_cases)/max(population)is not null)t

--explore vaccinations table
select top 10 * from [coviddata]..covid_vaccination$

--proportion of population fully vaccinated by country
select de.location,max(cast(va.people_fully_vaccinated as int)) as num_of_vaccinated,max(de.population) as total_population,
round(max(cast(va.people_fully_vaccinated as int))/max(de.population)*100,2)as pct_full_vaccinated
from [coviddata]..covid_vaccination$ va
join [coviddata]..covid_death$ de
on va.location=de.location
and va.date=de.date
where de.continent is not null
group by de.location
order by 4 desc

--rolling vaccination rate with at least one shot over time by country
with rollvac(date,location,population,new_people_vaccinated_smoothed,rollingvaccinated)
as(
select va.date, de.location,de.population,va.new_people_vaccinated_smoothed,sum(cast(va.new_people_vaccinated_smoothed as int)) over(partition by de.location order by va.date)as rollingvaccinated
from [coviddata]..covid_vaccination$ va
join [coviddata]..covid_death$ de
on va.location=de.location
and va.date=de.date
where de.continent is not null and va.new_people_vaccinated_smoothed is not null
)

select *, (rollingvaccinated/population)*100 as pct_rolling_vaccinated
from rollvac
order by 1 desc

-- create view for visualization of death & vaccination rate

create view RollingCaseDeathVacc as

select de.date, de.location,de.population,
de.new_cases,sum(cast(de.new_cases as float)) over(partition by de.location order by de.date)as rollingcase,
de.new_deaths,sum(cast(de.new_deaths as float)) over(partition by de.location order by de.date)as rollingdeath,
va.new_people_vaccinated_smoothed,sum(cast(va.new_people_vaccinated_smoothed as float)) over(partition by va.location order by va.date)as rollingvaccinated
from [coviddata]..covid_death$ de
left join [coviddata]..covid_vaccination$ va
on va.location=de.location
and va.date = de.date
where de.continent is not null