{{ config(materialized='table') }}

with game_data as (
    select 
        game_id,
        jsonb_array_elements(roster_spots) as roster_spot
    from {{ ref('stg_games') }}
)

select
    game_id,
    (roster_spot->>'teamId')::integer as team_id,
    (roster_spot->>'playerId')::integer as player_id,
    roster_spot->'firstName'->>'default' as first_name,
    roster_spot->'lastName'->>'default' as last_name,
    (roster_spot->>'sweaterNumber')::integer as sweater_number,
    roster_spot->>'positionCode' as position_code,
    roster_spot->>'headshot' as headshot_url
from game_data
