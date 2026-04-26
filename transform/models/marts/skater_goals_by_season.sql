{{ config(materialized='table') }}

with

-- filter plays to goal events with a credited scorer, excluding shootouts
goals as (
    select
        game_id,
        scoring_player_id as player_id
    from {{ ref('plays') }}
    where type_desc_key = 'goal'
      and scoring_player_id is not null
      and period_type != 'SO'
),

-- get each skater's name and position per game, excluding goalies
player_positions as (
    select distinct
        game_id,
        player_id,
        first_name,
        last_name,
        position_code,
        case
            when position_code in ('C', 'L', 'R') then 'Forward'
            when position_code = 'D' then 'Defenseman'
        end as position_group
    from {{ ref('roster') }}
    where position_code in ('C', 'L', 'R', 'D')
),

-- join goals to player context and season metadata
goals_with_context as (
    select
        g.game_id,
        g.player_id,
        p.first_name,
        p.last_name,
        p.position_code,
        p.position_group,
        gm.season_id,
        gm.game_type
    from goals g
    inner join player_positions p
        on g.game_id = p.game_id
        and g.player_id = p.player_id
    inner join {{ ref('games') }} gm
        on g.game_id = gm.game_id
),

-- aggregate to one row per player + season + game_type
player_season_totals as (
    select
        {{ dbt_utils.generate_surrogate_key(['player_id', 'season_id', 'game_type']) }} as id,
        season_id,
        game_type,
        player_id,
        first_name,
        last_name,
        position_code,
        position_group,
        count(*) as goals
    from goals_with_context
    group by
        player_id,
        season_id,
        game_type,
        first_name,
        last_name,
        position_code,
        position_group
)

select * from player_season_totals
