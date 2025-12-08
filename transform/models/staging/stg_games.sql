{{ config(materialized='table') }}

Select 

    id as game_id,
    season as season_id,
    gameType::integer as game_type_id,
    case 
        when gameType::integer = 3 then 'Playoffs'
        when gameType::integer = 2 then 'Regular Season'
        when gameType::integer = 1 then 'Preseason'
        else 'Unknown'
    end game_type,
    limitedScoring::boolean as limited_scoring_flag,
    gameDate as game_date,
    json_extract_string(venue, '$.default') as venue_name,
    json_extract_string(venueLocation, '$.default') as venue_location,
    startTimeUTC as start_time_utc,
    easternUTCOffset as eastern_utc_offset,
    venueUTCOffset as venue_utc_offset,
    tvBroadcasts::json[] as tv_broadcasts,
    gameState as game_state,
    gameScheduleState as game_schedule_state,
    periodDescriptor::json as period_descriptor,
    awayTeam::json as away_team,
    homeTeam::json as home_team,
    shootoutInUse::boolean as shootout_in_use,
    otInUse::boolean as ot_in_use,
    clock::json as clock,
    displayPeriod as display_period,
    maxPeriods::integer as max_periods,
    gameOutcome::json as game_outcome,
    plays::json[] as plays,
    rosterSpots::json[] as roster_spots

from read_json('s3://nhl-data-pipeline-data/game_data=*/game_id=*.json')

