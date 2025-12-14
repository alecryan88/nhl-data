{{ config(materialized='table') }}

with teams as (
	Select 	
		away_team as team 
			
	from {{ ref('stg_games') }}
	
	UNION 
	
	
	Select 
		home_team as team
	
	from {{ ref('stg_games') }}
	
)


Select distinct
		(team->>'id')::integer as team_id,
		team->'commonName'->>'default' as common_name,
		team->>'abbrev' as abbrev,
		--team.score::integer as score,
		--team.sog::integer as shots_on_goal,
		team->>'logo' as logo,
		team->>'darkLogo' as dark_logo,
		team->'placeName'->>'default' as place_name,
		team->'placeNameWithPreposition'->>'default' as place_name_with_preposition
		
from teams