{{ config(materialized='table') }}

with game_data as (
    select 
        game_id,
        unnest(roster_spots) as roster_spot
    from {{ ref('stg_games') }}
)

select
    game_id,
    json_extract_string(roster_spot, '$.teamId')::integer as team_id,
    json_extract_string(roster_spot, '$.playerId')::integer as player_id,
    json_extract_string(roster_spot, '$.firstName.default')::varchar as first_name,
    json_extract_string(roster_spot, '$.lastName.default')::varchar as last_name,
    json_extract_string(roster_spot, '$.sweaterNumber')::integer as sweater_number,
    json_extract_string(roster_spot, '$.positionCode')::varchar as position_code,
    json_extract_string(roster_spot, '$.headshot')::varchar as headshot_url
from game_data
