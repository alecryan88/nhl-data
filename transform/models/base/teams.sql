{{ config(materialized='table') }}

with teams as (
	Select 	
		away_team as team, 
			
	from {{ ref('stg_games') }}
	
	UNION 
	
	
	Select 
		home_team as team
	
	from {{ ref('stg_games') }}
	
)


Select distinct
		team.id::integer as team_id,
		json_extract_string(team, '$.commonName.default') as common_name,
		json_extract_string(team, '$.abbrev') as abbrev,
		--team.score::integer as score,
		--team.sog::integer as shots_on_goal,
		json_extract_string(team, '$.logo') as logo,
		json_extract_string(team, '$.darkLogo') as dark_logo,
		json_extract_string(team, '$.placeName.default') as place_name,
		json_extract_string(team, '$.placeNameWithPreposition.default') as place_name_with_preposition
		
from teams