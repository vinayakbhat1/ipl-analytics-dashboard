
### 1. `player_season_stats`

CREATE OR REPLACE VIEW player_season_stats AS

SELECT
    p.season,
    p.player_name,

    p.runs,
    p.balls_faced,

    ROUND(
        100.0 * p.runs / NULLIF(p.balls_faced, 0),
        2
    ) AS strike_rate,

    p.fours,
    p.sixes,

    COALESCE(b.wickets, 0) AS wickets,
    COALESCE(b.balls_bowled, 0) AS balls_bowled,
    COALESCE(b.runs_conceded, 0) AS runs_conceded,

    ROUND(
        COALESCE(b.runs_conceded, 0) /
        NULLIF(b.balls_bowled / 6.0, 0),
        2
    ) AS economy

FROM
(
    SELECT
        season,
        batter AS player_name,
        SUM(batter_runs) AS runs,

        COUNT(
            CASE
                WHEN is_wide_ball = 0
                 AND is_no_ball = 0
                THEN 1
            END
        ) AS balls_faced,

        SUM(is_four) AS fours,
        SUM(is_six) AS sixes

    FROM ball_by_ball
    GROUP BY season, batter
) p

LEFT JOIN
(
    SELECT
        season,
        bowler AS player_name,

        COUNT(
            CASE
                WHEN is_wide_ball = 0
                 AND is_no_ball = 0
                THEN 1
            END
        ) AS balls_bowled,

        SUM(
            CASE
                WHEN wicket_kind IN (
                    'bowled',
                    'caught',
                    'lbw',
                    'stumped',
                    'caught and bowled',
                    'hit wicket'
                )
                THEN 1
                ELSE 0
            END
        ) AS wickets,

        SUM(
            CASE
                WHEN is_wide_ball = 1
                  OR is_no_ball = 1
                THEN total_runs
                ELSE batter_runs
            END
        ) AS runs_conceded

    FROM ball_by_ball
    GROUP BY season, bowler
) b

ON p.season = b.season
AND p.player_name = b.player_name;


### 2. `team_season_stats`

CREATE OR REPLACE VIEW team_season_stats AS

SELECT
    season,
    team,

    COUNT(*) AS matches_played,

    SUM(
        CASE
            WHEN match_winner = team THEN 1
            ELSE 0
        END
    ) AS wins,

    SUM(
        CASE
            WHEN match_winner IS NOT NULL
             AND match_winner <> ''
             AND match_winner <> team
            THEN 1
            ELSE 0
        END
    ) AS losses,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN match_winner = team THEN 1
                ELSE 0
            END
        )
        /
        NULLIF(
            SUM(
                CASE
                    WHEN match_winner IS NOT NULL
                     AND match_winner <> ''
                    THEN 1
                    ELSE 0
                END
            ),
            0
        ),
        2
    ) AS win_percentage

FROM
(
    SELECT
        season,
        team1 AS team,
        match_winner
    FROM matches
    WHERE team1 IS NOT NULL
      AND team1 <> ''

    UNION ALL

    SELECT
        season,
        team2 AS team,
        match_winner
    FROM matches
    WHERE team2 IS NOT NULL
      AND team2 <> ''
) AS team_matches

GROUP BY season, team;


### 3. `season_summary`

CREATE OR REPLACE VIEW season_summary AS

SELECT
    m.season,

    COUNT(DISTINCT m.match_id) AS total_matches,

    COALESCE(SUM(b.total_runs), 0) AS total_runs,

    COALESCE(
        SUM(
            CASE
                WHEN b.wicket_kind IN (
                    'bowled',
                    'caught',
                    'caught and bowled',
                    'hit wicket',
                    'lbw',
                    'stumped'
                )
                THEN 1
                ELSE 0
            END
        ),
        0
    ) AS total_wickets,

    COALESCE(
        SUM(
            CASE
                WHEN b.is_six = 1 THEN 1
                ELSE 0
            END
        ),
        0
    ) AS total_sixes,

    w.winner

FROM matches m

LEFT JOIN ball_by_ball b
    ON m.match_id = b.match_id

LEFT JOIN ipl_winners w
    ON m.season = w.season

GROUP BY
    m.season,
    w.winner;


### 4. `roi_dashboard`

CREATE OR REPLACE VIEW roi_dashboard AS

SELECT
    s.Name AS player_name,
    s.TeamName,
    s.nationality,
    s.price_cr,
    s.year AS auction_year,

    COALESCE(bat.runs, 0) AS runs,
    COALESCE(bowl.wickets, 0) AS wickets,

    ROUND(
        COALESCE(bat.runs, 0) / 30.0
        + COALESCE(bowl.wickets, 0) * 5.0,
        2
    ) AS performance_score,

    ROUND(
        (
            COALESCE(bat.runs, 0) / 30.0
            + COALESCE(bowl.wickets, 0) * 5.0
        ) / NULLIF(s.price_cr, 0),
        4
    ) AS roi

FROM players_salary s

LEFT JOIN (
    SELECT
        season,
        batter,
        SUM(batter_runs) AS runs
    FROM ball_by_ball
    GROUP BY season, batter
) bat
    ON (
        TRIM(s.Name) = TRIM(bat.batter)
        OR (
            s.Name = 'Rishabh Pant'
            AND bat.batter = 'RR Pant'
        )
    )
    AND s.year = bat.season

LEFT JOIN (
    SELECT
        season,
        bowler,
        SUM(is_wicket) AS wickets
    FROM ball_by_ball
    WHERE is_wide_ball = 0
      AND is_no_ball = 0
    GROUP BY season, bowler
) bowl
    ON (
        TRIM(s.Name) = TRIM(bowl.bowler)
        OR (
            s.Name = 'Rishabh Pant'
            AND bowl.bowler = 'RR Pant'
        )
    )
    AND s.year = bowl.season

WHERE s.price_cr >= 1.00
  AND (
      COALESCE(bat.runs, 0) > 0
      OR COALESCE(bowl.wickets, 0) > 0
  );

### 5. `nationality_season_stats`

CREATE OR REPLACE VIEW nationality_season_stats AS

SELECT
    p.season,
    c.Nationality AS nationality,

    COUNT(DISTINCT p.player_name) AS players,

    SUM(COALESCE(p.runs, 0)) AS runs,

    SUM(COALESCE(p.wickets, 0)) AS wickets,

    SUM(COALESCE(p.sixes, 0)) AS sixes

FROM player_season_stats p

INNER JOIN ipl_players_classification c
    ON TRIM(p.player_name) = TRIM(c.Player)

GROUP BY
    p.season,
    c.Nationality;

### 6. `auction_spend`

CREATE OR REPLACE VIEW auction_spend AS

SELECT
    Name AS player_name,
    TeamName,
    nationality,
    price_cr,
    year AS auction_year

FROM players_salary

WHERE price_cr >= 1.00;


### Final list
