{{ config(materialized='table') }}

with game_plays as (
    select 
        game_id,
        jsonb_array_elements(plays) as play
    from {{ ref('stg_games') }}
)

select 
    game_id,
    (play->>'eventId')::integer as event_id,
    {{ dbt_utils.generate_surrogate_key(['game_id', "play->>'eventId'"]) }} as game_play_id,
    -- Extracted period descriptor fields
    -- play->'periodDescriptor' as period_descriptor,
    (play->'periodDescriptor'->>'number')::integer as period_number,
    play->'periodDescriptor'->>'periodType' as period_type,
    (play->'periodDescriptor'->>'maxRegulationPeriods')::integer as max_regulation_periods,
    play->>'timeInPeriod' as time_in_period,
    play->>'timeRemaining' as time_remaining,
    play->>'situationCode' as situation_code,
    play->>'homeTeamDefendingSide' as home_team_defending_side,
    (play->>'typeCode')::integer as type_code,
    play->>'typeDescKey' as type_desc_key,
    (play->>'sortOrder')::integer as sort_order,

    play->>'pptReplayUrl' as ppt_replay_url,
    -- Extracted details fields
    -- play->'details' as details,
    (play->'details'->>'eventOwnerTeamId')::integer as event_owner_team_id,
    (play->'details'->>'losingPlayerId')::integer as losing_player_id,
    (play->'details'->>'winningPlayerId')::integer as winning_player_id,
    (play->'details'->>'xCoord')::integer as x_coord,
    (play->'details'->>'yCoord')::integer as y_coord,
    play->'details'->>'zoneCode' as zone_code,
    (play->'details'->>'hittingPlayerId')::integer as hitting_player_id,
    (play->'details'->>'hitteePlayerId')::integer as hittee_player_id,
    play->'details'->>'shotType' as shot_type,
    (play->'details'->>'shootingPlayerId')::integer as shooting_player_id,
    (play->'details'->>'goalieInNetId')::integer as goalie_in_net_id,
    (play->'details'->>'awaySOG')::integer as away_sog,
    (play->'details'->>'homeSOG')::integer as home_sog,
    play->'details'->>'reason' as reason,
    (play->'details'->>'scoringPlayerId')::integer as scoring_player_id,
    (play->'details'->>'scoringPlayerTotal')::integer as scoring_player_total,
    (play->'details'->>'assist1PlayerId')::integer as assist1_player_id,
    (play->'details'->>'assist1PlayerTotal')::integer as assist1_player_total,
    (play->'details'->>'assist2PlayerId')::integer as assist2_player_id,
    (play->'details'->>'assist2PlayerTotal')::integer as assist2_player_total,
    (play->'details'->>'awayScore')::integer as away_score,
    (play->'details'->>'homeScore')::integer as home_score,
    play->'details'->>'highlightClipSharingUrl' as highlight_clip_sharing_url,
    play->'details'->>'highlightClip' as highlight_clip,
    play->'details'->>'discreteClip' as discrete_clip,
    play->'details'->>'discreteClipFr' as discrete_clip_fr,
    (play->'details'->>'playerId')::integer as player_id,
    (play->'details'->>'blockingPlayerId')::integer as blocking_player_id,
    play->'details'->>'typeCode' as details_type_code,
    play->'details'->>'descKey' as desc_key,
    (play->'details'->>'duration')::integer as duration,
    (play->'details'->>'committedByPlayerId')::integer as committed_by_player_id,
    (play->'details'->>'drawnByPlayerId')::integer as drawn_by_player_id,
    play->'details'->>'secondaryReason' as secondary_reason,
    (play->'details'->>'servedByPlayerId')::integer as served_by_player_id,
    play->'details'->>'highlightClipSharingUrlFr' as highlight_clip_sharing_url_fr,
    play->'details'->>'highlightClipFr' as highlight_clip_fr
from game_plays