{{ config(materialized='table') }}

with game_plays as (
    select 
        game_id,
        unnest(plays) as play
    from {{ ref('stg_games') }}
)

select 
    game_id,
    json_extract_string(play, '$.eventId')::integer as event_id,
    {{ dbt_utils.generate_surrogate_key(['game_id', 'event_id']) }} as game_play_id,
    -- Extracted period descriptor fields
    -- json_extract(play, '$.periodDescriptor') as period_descriptor,
    json_extract_string(play, '$.periodDescriptor.number')::integer as period_number,
    json_extract_string(play, '$.periodDescriptor.periodType') as period_type,
    json_extract_string(play, '$.periodDescriptor.maxRegulationPeriods')::integer as max_regulation_periods,
    json_extract_string(play, '$.timeInPeriod') as time_in_period,
    json_extract_string(play, '$.timeRemaining') as time_remaining,
    json_extract_string(play, '$.situationCode') as situation_code,
    json_extract_string(play, '$.homeTeamDefendingSide') as home_team_defending_side,
    json_extract_string(play, '$.typeCode')::integer as type_code,
    json_extract_string(play, '$.typeDescKey') as type_desc_key,
    json_extract_string(play, '$.sortOrder')::integer as sort_order,

    json_extract_string(play, '$.pptReplayUrl') as ppt_replay_url,
    -- Extracted details fields
    --json_extract(play, '$.details') as details,
    json_extract_string(play, '$.details.eventOwnerTeamId')::integer as event_owner_team_id,
    json_extract_string(play, '$.details.losingPlayerId')::integer as losing_player_id,
    json_extract_string(play, '$.details.winningPlayerId')::integer as winning_player_id,
    json_extract_string(play, '$.details.xCoord')::integer as x_coord,
    json_extract_string(play, '$.details.yCoord')::integer as y_coord,
    json_extract_string(play, '$.details.zoneCode') as zone_code,
    json_extract_string(play, '$.details.hittingPlayerId')::integer as hitting_player_id,
    json_extract_string(play, '$.details.hitteePlayerId')::integer as hittee_player_id,
    json_extract_string(play, '$.details.shotType') as shot_type,
    json_extract_string(play, '$.details.shootingPlayerId')::integer as shooting_player_id,
    json_extract_string(play, '$.details.goalieInNetId')::integer as goalie_in_net_id,
    json_extract_string(play, '$.details.awaySOG')::integer as away_sog,
    json_extract_string(play, '$.details.homeSOG')::integer as home_sog,
    json_extract_string(play, '$.details.reason') as reason,
    json_extract_string(play, '$.details.scoringPlayerId')::integer as scoring_player_id,
    json_extract_string(play, '$.details.scoringPlayerTotal')::integer as scoring_player_total,
    json_extract_string(play, '$.details.assist1PlayerId')::integer as assist1_player_id,
    json_extract_string(play, '$.details.assist1PlayerTotal')::integer as assist1_player_total,
    json_extract_string(play, '$.details.assist2PlayerId')::integer as assist2_player_id,
    json_extract_string(play, '$.details.assist2PlayerTotal')::integer as assist2_player_total,
    json_extract_string(play, '$.details.awayScore')::integer as away_score,
    json_extract_string(play, '$.details.homeScore')::integer as home_score,
    json_extract_string(play, '$.details.highlightClipSharingUrl') as highlight_clip_sharing_url,
    json_extract_string(play, '$.details.highlightClip') as highlight_clip,
    json_extract_string(play, '$.details.discreteClip') as discrete_clip,
    json_extract_string(play, '$.details.discreteClipFr') as discrete_clip_fr,
    json_extract_string(play, '$.details.playerId')::integer as player_id,
    json_extract_string(play, '$.details.blockingPlayerId')::integer as blocking_player_id,
    json_extract_string(play, '$.details.typeCode')::string as details_type_code,
    json_extract_string(play, '$.details.descKey') as desc_key,
    json_extract_string(play, '$.details.duration')::integer as duration,
    json_extract_string(play, '$.details.committedByPlayerId')::integer as committed_by_player_id,
    json_extract_string(play, '$.details.drawnByPlayerId')::integer as drawn_by_player_id,
    json_extract_string(play, '$.details.secondaryReason') as secondary_reason,
    json_extract_string(play, '$.details.servedByPlayerId')::integer as served_by_player_id,
    json_extract_string(play, '$.details.highlightClipSharingUrlFr') as highlight_clip_sharing_url_fr,
    json_extract_string(play, '$.details.highlightClipFr') as highlight_clip_fr
from game_plays