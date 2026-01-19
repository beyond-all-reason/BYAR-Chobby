#!/usr/bin/env python
# Exportiung latest OpenSkill values per player into a CSV snapshot using most recent parquet files
#this script needs to be ran in the datadump BAR repository
import argparse
import sys

try:
    import duckdb
except ImportError as exc:
    raise SystemExit(
        "duckdb is required. Install with: python -m pip install duckdb"
    ) from exc


DEFAULT_MATCHES_URL = "https://data-marts.beyondallreason.dev/matches.parquet"
DEFAULT_MATCH_PLAYERS_URL = "https://data-marts.beyondallreason.dev/match_players.parquet"
DEFAULT_PLAYERS_URL = "https://data-marts.beyondallreason.dev/players.parquet"


def build_query(matches_url, match_players_url, players_url):
    return f"""
WITH
  matches AS (
    SELECT
      match_id,
      start_time,
      lower(game_type) AS game_type_l
    FROM read_parquet('{matches_url}')
    WHERE is_ranked = true
  ),
  match_players AS (
    SELECT
      match_id,
      user_id,
      new_skill,
      new_uncertainty
    FROM read_parquet('{match_players_url}')
  ),
  players AS (
    SELECT
      user_id,
      name,
      country AS countryCode
    FROM read_parquet('{players_url}')
  ),
  joined AS (
    SELECT
      mp.user_id,
      p.name,
      p.countryCode,
      m.start_time,
      CASE
        WHEN m.game_type_l LIKE '%duel%' THEN 'duel'
        WHEN m.game_type_l LIKE '%ffa%' THEN 'ffa'
        WHEN m.game_type_l LIKE '%large%' THEN 'large'
        WHEN m.game_type_l LIKE '%small%' THEN 'small'
        ELSE NULL
      END AS game_type,
      mp.new_skill,
      mp.new_uncertainty
    FROM match_players mp
    JOIN matches m USING (match_id)
    JOIN players p USING (user_id)
  )
SELECT
  user_id AS id,
  name,
  arg_max(new_skill, start_time) FILTER (WHERE game_type = 'duel')  AS duelSkill,
  arg_max(new_uncertainty, start_time) FILTER (WHERE game_type = 'duel') AS duelSkillUn,
  arg_max(new_skill, start_time) FILTER (WHERE game_type = 'ffa')   AS ffaSkill,
  arg_max(new_uncertainty, start_time) FILTER (WHERE game_type = 'ffa')  AS ffaSkillUn,
  arg_max(new_skill, start_time) FILTER (WHERE game_type = 'large') AS teamSkill,
  arg_max(new_uncertainty, start_time) FILTER (WHERE game_type = 'large') AS teamSkillUn,
  arg_max(start_time, start_time) FILTER (WHERE game_type = 'duel')  AS lastDuel,
  arg_max(start_time, start_time) FILTER (WHERE game_type = 'ffa')   AS lastFFA,
  arg_max(start_time, start_time) FILTER (WHERE game_type = 'large') AS lastTeam,
  countryCode,
  arg_max(start_time, start_time) FILTER (WHERE game_type = 'small') AS lastSmallTeam,
  arg_max(new_skill, start_time) FILTER (WHERE game_type = 'small')  AS smallTeamSkill,
  arg_max(new_uncertainty, start_time) FILTER (WHERE game_type = 'small') AS smallTeamSkillUn
FROM joined
WHERE game_type IS NOT NULL
GROUP BY user_id, name, countryCode
ORDER BY user_id
"""


def main():
    parser = argparse.ArgumentParser(
        description="Export latest OpenSkill values per player into a CSV."
    )
    parser.add_argument(
        "--matches-url",
        default=DEFAULT_MATCHES_URL,
        help="Parquet URL for matches.",
    )
    parser.add_argument(
        "--match-players-url",
        default=DEFAULT_MATCH_PLAYERS_URL,
        help="Parquet URL for match players.",
    )
    parser.add_argument(
        "--players-url",
        default=DEFAULT_PLAYERS_URL,
        help="Parquet URL for players.",
    )
    parser.add_argument(
        "--output",
        default="player_skill_snapshot.csv",
        help="Output CSV path.",
    )
    args = parser.parse_args()

    con = duckdb.connect()
    query = build_query(args.matches_url, args.match_players_url, args.players_url)
    con.execute(
        f"COPY ({query}) TO '{args.output}' (HEADER, DELIMITER ',')"
    )

    print(f"Wrote {args.output}")


if __name__ == "__main__":
    sys.exit(main())
