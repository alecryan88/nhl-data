{{ config(materialized='table') }}

Select 

    game_id,
    partition_date,
    event->>'id' as event_id,
    event->>'season' as season_id,
    (event->>'gameType')::integer as game_type_id,
    case 
        when (event->>'gameType')::integer = 3 then 'Playoffs'
        when (event->>'gameType')::integer = 2 then 'Regular Season'
        when (event->>'gameType')::integer = 1 then 'Preseason'
        else 'Unknown'
    end as game_type,
    (event->>'limitedScoring')::boolean as limited_scoring_flag,
    event->>'gameDate' as game_date,
    event->'venue'->>'default' as venue_name,
    event->'venueLocation'->>'default' as venue_location,
    event->>'startTimeUTC' as start_time_utc,
    event->>'easternUTCOffset' as eastern_utc_offset,
    event->>'venueUTCOffset' as venue_utc_offset,
    event->'tvBroadcasts' as tv_broadcasts,
    event->>'gameState' as game_state,
    event->>'gameScheduleState' as game_schedule_state,
    event->'periodDescriptor' as period_descriptor,
    event->'awayTeam' as away_team,
    event->'homeTeam' as home_team,
    (event->>'shootoutInUse')::boolean as shootout_in_use,
    (event->>'otInUse')::boolean as ot_in_use,
    event->'clock' as clock,
    event->>'displayPeriod' as display_period,
    (event->>'maxPeriods')::integer as max_periods,
    event->'gameOutcome' as game_outcome,
    event->'plays' as plays,
    event->'rosterSpots' as roster_spots

from {{ source('raw_api_data', 'game_data') }}

