-- Freshness exclusion set: every prize item_id of the last 5 case-battle boards
-- (stats.tournament type 3, the running one included) UNION the last 5 events' leaderboards
-- (stats.events.extra->'Leaderboard'->'ItemsIds', the running one included).
-- Run: uv run --no-project --with "psycopg[binary]" python db_query.py exclusions.sql > <scratch>/excl.tsv
with cb as (
  select id from stats.tournament where type = 3 and _ab_cdc_deleted_at is null
  order by created_at desc limit 5
), ev as (
  select start_at, substring(extra->>'Home' from 'events/(?:20[0-9]{2}/)?([a-z0-9]+)/') slug, extra->>'Leaderboard' lb
  from stats.events where deleted_at is null order by start_at desc limit 5
)
select distinct a.award_reference as item_id, 'case-battle #' || a.tournament_id as source
from stats.tournament_awards a join cb on cb.id = a.tournament_id
where a._ab_cdc_deleted_at is null
union
select distinct (jsonb_array_elements_text((lb::jsonb)->'ItemsIds'))::int, 'event ' || slug || ' ' || start_at::date
from ev
order by 1
