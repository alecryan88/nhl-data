{{ config(materialized='table') }}

Select 
	game_id ,
	season_id ,
	game_type_id ,
    game_type,
	start_time_utc,
	away_team.id as away_team_id,
	home_team.id as home_team_id
	
	
from {{ ref('stg_games') }}   