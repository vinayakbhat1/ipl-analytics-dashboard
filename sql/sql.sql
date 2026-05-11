-- ============================================================
-- IPL DASHBOARD — FINAL SQL VIEWS
-- Author: Your Name
-- Description: 15 production-ready views for Power BI dashboard
--              covering Season Overview, Player Deep Dive,
--              and Auction ROI analysis
-- Tables Required: ball_by_ball, matches, players_salary
-- ============================================================


-- ============================================================
-- PAGE 1 — SEASON OVERVIEW
-- ============================================================


-- View 1: Orange Cap — Top Run Scorer per Season
-- Power BI: Add Top N filter = 1 on batter for KPI card
CREATE OR REPLACE VIEW orange_cap AS
SELECT
    season,
    batter,
    SUM(batter_runs) AS total_runs
FROM ball_by_ball
GROUP BY season, batter
ORDER BY season, total_runs DESC;


-- View 2: Purple Cap — Top Wicket Taker per Season
-- Power BI: Add Top N filter = 1 on bowler for KPI card
CREATE OR REPLACE VIEW purple_cap AS
SELECT
    season,
    bowler,
    SUM(is_wicket) AS total_wickets
FROM ball_by_ball
GROUP BY season, bowler
ORDER BY season, total_wickets DESC;


-- View 3: Top 5 Run Scorers per Season (bar chart)
-- Power BI: Add Top N filter = 5 on batter
-- Season slicer filters via ball_by_ball.season relationship
CREATE OR REPLACE VIEW top5_run_scorers AS
SELECT
    season,
    batter,
    SUM(batter_runs) AS total_runs
FROM ball_by_ball
GROUP BY season, batter
ORDER BY total_runs DESC;


-- View 4: Top 5 Wicket Takers per Season (bar chart)
-- Power BI: Add Top N filter = 5 on bowler
CREATE OR REPLACE VIEW top5_wicket_takers AS
SELECT
    season,
    bowler,
    SUM(is_wicket) AS total_wickets
FROM ball_by_ball
GROUP BY season, bowler
ORDER BY total_wickets DESC;


-- View 5: Win % — Batting First vs Chasing (bar chart)
-- Uses pre-computed columns bat_first_won and field_first_won from matches
CREATE OR REPLACE VIEW win_pct_bat_vs_chase AS
SELECT
    season,
    SUM(bat_first_won)                                    AS batting_first_wins,
    SUM(field_first_won)                                  AS chasing_wins,
    COUNT(*)                                              AS total_matches,
    ROUND(100.0 * SUM(bat_first_won)   / COUNT(*), 2)    AS bat_first_win_pct,
    ROUND(100.0 * SUM(field_first_won) / COUNT(*), 2)    AS chase_win_pct
FROM matches
GROUP BY season;


-- View 6: Top Venues by Matches Hosted per Season (bar chart)
-- Power BI: Add Top N filter = 10 on venue
CREATE OR REPLACE VIEW top_venues AS
SELECT
    season,
    venue,
    COUNT(*) AS matches_hosted
FROM matches
GROUP BY season, venue
ORDER BY matches_hosted DESC;


-- ============================================================
-- PAGE 2 — PLAYER DEEP DIVE
-- ============================================================


-- View 7: Runs per Player per Season (line chart)
-- Power BI: Player slicer filters by batter column
CREATE OR REPLACE VIEW player_runs_by_season AS
SELECT
    season,
    batter,
    SUM(batter_runs)                                      AS runs,
    COUNT(CASE WHEN is_wide_ball = 0 THEN 1 END)          AS balls_faced,
    ROUND(
        100.0 * SUM(batter_runs) /
        NULLIF(COUNT(CASE WHEN is_wide_ball = 0 THEN 1 END), 0)
    , 2)                                                  AS strike_rate
FROM ball_by_ball
GROUP BY season, batter
ORDER BY season, runs DESC;


-- View 8: Wickets per Bowler per Season (line chart)
-- Power BI: Player slicer filters by bowler column
CREATE OR REPLACE VIEW player_wickets_by_season AS
SELECT
    season,
    bowler,
    SUM(is_wicket)                                        AS wickets,
    COUNT(CASE WHEN is_wide_ball = 0 AND is_no_ball = 0 THEN 1 END) AS balls_bowled,
    ROUND(
        SUM(total_runs) /
        NULLIF(COUNT(CASE WHEN is_wide_ball = 0 AND is_no_ball = 0 THEN 1 END) / 6.0, 0)
    , 2)                                                  AS economy
FROM ball_by_ball
GROUP BY season, bowler
ORDER BY season, wickets DESC;


-- View 9: Phase Breakdown — Powerplay / Middle / Death
-- Shows runs, wickets, strike rate and economy per phase per season
-- Key insight: shows where matches are won and lost
CREATE OR REPLACE VIEW phase_breakdown AS
SELECT
    season,
    phase,
    SUM(batter_runs)                                                        AS total_runs,
    SUM(is_wicket)                                                          AS total_wickets,
    SUM(is_four)                                                            AS total_fours,
    SUM(is_six)                                                             AS total_sixes,
    ROUND(
        100.0 * SUM(batter_runs) /
        NULLIF(SUM(CASE WHEN is_wide_ball = 0 THEN 1 ELSE 0 END), 0)
    , 2)                                                                    AS strike_rate,
    ROUND(
        SUM(total_runs) /
        NULLIF(SUM(CASE WHEN is_wide_ball = 0 AND is_no_ball = 0 THEN 1 ELSE 0 END) / 6.0, 0)
    , 2)                                                                    AS economy
FROM ball_by_ball
GROUP BY season, phase
ORDER BY season,
    CASE phase
        WHEN 'Powerplay' THEN 1
        WHEN 'Middle'    THEN 2
        WHEN 'Death'     THEN 3
    END;


-- View 10: Average Runs per Innings — Indian vs Overseas Players
-- Joins players_salary for nationality
-- Insight: compares domestic vs overseas batting contribution
CREATE OR REPLACE VIEW avg_runs_indian_vs_overseas AS
SELECT
    p.nationality,
    ROUND(AVG(innings_runs), 2)                           AS avg_runs_per_innings
FROM (
    SELECT batter, match_id, innings, SUM(batter_runs)    AS innings_runs
    FROM ball_by_ball
    GROUP BY batter, match_id, innings
) AS innings_scores
JOIN (
    SELECT DISTINCT Name, nationality
    FROM players_salary
) AS p ON innings_scores.batter = p.Name
GROUP BY p.nationality;


-- View 11: Average Wickets per Match — Indian vs Overseas Players
-- Insight: compares domestic vs overseas bowling contribution
CREATE OR REPLACE VIEW avg_wickets_indian_vs_overseas AS
SELECT
    p.nationality,
    ROUND(AVG(match_wickets), 2)                          AS avg_wickets_per_match
FROM (
    SELECT bowler, match_id, SUM(is_wicket)               AS match_wickets
    FROM ball_by_ball
    GROUP BY bowler, match_id
) AS match_bowl
JOIN (
    SELECT DISTINCT Name, nationality
    FROM players_salary
) AS p ON match_bowl.bowler = p.Name
GROUP BY p.nationality;


-- ============================================================
-- PAGE 3 — AUCTION, RETENTION & ROI
-- ============================================================
-- PERFORMANCE SCORE FORMULA:
--   performance_score = (runs / 30) + (wickets x 5)
--   30 runs = 1 point | 1 wicket = 5 points
--
-- ROI FORMULA:
--   roi = performance_score / price_cr
--   Higher ROI = better value for money
-- ============================================================


-- View 12: ROI Analysis — Base View (BUILD THIS FIRST)
-- All Page 3 views depend on this
-- Joins auction price with actual performance in that auction season
CREATE OR REPLACE VIEW roi_analysis AS
SELECT
    s.Name                                                AS player_name,
    s.TeamName,
    s.nationality,
    s.price_cr,
    s.year                                                AS auction_year,
    COALESCE(bat.runs, 0)                                 AS runs,
    COALESCE(bowl.wickets, 0)                             AS wickets,
    ROUND(
        COALESCE(bat.runs, 0) / 30.0
        + COALESCE(bowl.wickets, 0) * 5.0
    , 2)                                                  AS performance_score,
    ROUND((
        COALESCE(bat.runs, 0) / 30.0
        + COALESCE(bowl.wickets, 0) * 5.0
    ) / NULLIF(s.price_cr, 0), 4)                         AS roi
FROM players_salary s
LEFT JOIN (
    SELECT season, batter, SUM(batter_runs)               AS runs
    FROM ball_by_ball
    GROUP BY season, batter
) bat ON s.Name = bat.batter AND s.year = bat.season
LEFT JOIN (
    SELECT season, bowler, SUM(is_wicket)                 AS wickets
    FROM ball_by_ball
    WHERE is_wide_ball = 0 AND is_no_ball = 0
    GROUP BY season, bowler
) bowl ON s.Name = bowl.bowler AND s.year = bowl.season;


-- View 13: Price vs Performance Scatter
-- X = Price | Y = Performance Score | Color = Batter vs Bowler
-- Uses roi_analysis base view
CREATE OR REPLACE VIEW scatter_price_vs_performance AS
SELECT
    r.player_name,
    r.TeamName,
    r.nationality,
    r.price_cr,
    r.performance_score,
    r.roi,
    r.auction_year,
    CASE
        WHEN r.wickets > r.runs / 30 THEN 'Bowler'
        ELSE 'Batter'
    END                                                   AS player_type
FROM roi_analysis r;


-- View 14: Retained vs Auction Average ROI
-- Uses LAG() window function to detect if player was retained
-- Insight: do retained players deliver better value than auction buys?
CREATE OR REPLACE VIEW retained_vs_auction_roi AS
SELECT
    player_type,
    ROUND(AVG(roi), 4)                                    AS avg_roi,
    COUNT(*)                                              AS player_count
FROM (
    SELECT
        r.player_name,
        r.roi,
        r.auction_year,
        CASE
            WHEN prev.prev_year IS NOT NULL
                 AND r.auction_year - prev.prev_year = 1
                 AND prev.prev_price <= r.price_cr
            THEN 'Retained'
            ELSE 'Auction'
        END                                               AS player_type
    FROM roi_analysis r
    LEFT JOIN (
        SELECT
            Name,
            TeamName,
            year,
            LAG(year)     OVER (PARTITION BY Name, TeamName ORDER BY year) AS prev_year,
            LAG(price_cr) OVER (PARTITION BY Name, TeamName ORDER BY year) AS prev_price
        FROM players_salary
    ) prev
        ON  r.player_name  = prev.Name
        AND r.TeamName     = prev.TeamName
        AND r.auction_year = prev.year
) tagged
GROUP BY player_type;


-- View 15: Moneyball — ROI by Price Bucket
-- Key business insight: which price range gives the best return?
-- Buckets: Under 2 Cr | 2-5 Cr | 5-10 Cr | Above 10 Cr
CREATE OR REPLACE VIEW moneyball_price_bucket AS
SELECT
    CASE
        WHEN price_cr < 2                THEN '1. Under 2 Cr'
        WHEN price_cr BETWEEN 2 AND 5    THEN '2. 2 to 5 Cr'
        WHEN price_cr BETWEEN 5 AND 10   THEN '3. 5 to 10 Cr'
        ELSE                                  '4. Above 10 Cr'
    END                                                   AS price_bucket,
    COUNT(*)                                              AS player_count,
    ROUND(AVG(roi), 4)                                    AS avg_roi,
    ROUND(AVG(performance_score), 2)                      AS avg_performance,
    ROUND(AVG(price_cr), 2)                               AS avg_price_cr
FROM roi_analysis
WHERE price_cr > 0
GROUP BY price_bucket
ORDER BY price_bucket;

-- Orange cap should come purely from ball_by_ball
-- NO join with players_salary needed
CREATE OR REPLACE VIEW orange_cap AS
SELECT
    season,
    batter,
    SUM(batter_runs) AS total_runs
FROM ball_by_ball
GROUP BY season, batter
ORDER BY season, total_runs DESC;


CREATE OR REPLACE VIEW win_pct_bat_vs_chase AS
SELECT
    season,
    'Batting First'                                       AS batting_type,
    ROUND(100.0 * SUM(bat_first_won) / COUNT(*), 2)      AS win_pct
FROM matches
GROUP BY season

UNION ALL

SELECT
    season,
    'Chasing'                                             AS batting_type,
    ROUND(100.0 * SUM(field_first_won) / COUNT(*), 2)    AS win_pct
FROM matches
GROUP BY season;

CREATE OR REPLACE VIEW toss_vs_match_winner AS
SELECT
    season,
    toss_decision,
    COUNT(*)                                                AS total_matches,
    SUM(CASE WHEN toss_winner = match_winner THEN 1 ELSE 0 END) AS toss_winner_won,
    SUM(CASE WHEN toss_winner != match_winner THEN 1 ELSE 0 END) AS toss_winner_lost,
    ROUND(100.0 * SUM(CASE WHEN toss_winner = match_winner THEN 1 ELSE 0 END) / COUNT(*), 2) AS win_pct
FROM matches
GROUP BY season, toss_decision;

CREATE OR REPLACE VIEW batting_milestones AS
SELECT
    season,
    batter,
    SUM(CASE WHEN innings_score >= 100 THEN 1 ELSE 0 END) AS hundreds,
    SUM(CASE WHEN innings_score >= 50 
             AND innings_score < 100 THEN 1 ELSE 0 END)   AS fifties
FROM (
    SELECT season, batter, match_id, innings,
           SUM(batter_runs) AS innings_score
    FROM ball_by_ball
    GROUP BY season, batter, match_id, innings
) t
GROUP BY season, batter;

CREATE OR REPLACE VIEW player_runs_by_season AS
SELECT
    season,
    batter,
    SUM(batter_runs)                                      AS runs,
    COUNT(CASE WHEN is_wide_ball = 0 THEN 1 END)          AS balls_faced,
    ROUND(
        100.0 * SUM(batter_runs) /
        NULLIF(COUNT(CASE WHEN is_wide_ball = 0 THEN 1 END), 0)
    , 2)                                                  AS strike_rate
FROM ball_by_ball
GROUP BY season, batter
HAVING COUNT(CASE WHEN is_wide_ball = 0 THEN 1 END) >= 200
ORDER BY season, runs DESC;

CREATE OR REPLACE VIEW highest_innings_score AS
SELECT
    season,
    batter,
    match_id,
    innings,
    SUM(batter_runs) AS innings_score
FROM ball_by_ball
GROUP BY season, batter, match_id, innings
HAVING SUM(batter_runs) > 0
ORDER BY innings_score DESC;

CREATE OR REPLACE VIEW avg_runs_indian_vs_overseas AS
SELECT
    p.nationality,
    innings_scores.season,
    ROUND(AVG(innings_runs), 2) AS avg_runs_per_innings
FROM (
    SELECT 
        batter,
        season,
        match_id, 
        innings,
        SUM(batter_runs) AS innings_runs
    FROM ball_by_ball
    GROUP BY batter, season, match_id, innings
) AS innings_scores
JOIN (
    SELECT DISTINCT Name, nationality
    FROM players_salary
) AS p ON innings_scores.batter = p.Name
GROUP BY p.nationality, innings_scores.season;


CREATE OR REPLACE VIEW avg_wickets_indian_vs_overseas AS
SELECT
    p.nationality,
    match_bowl.season,
    ROUND(AVG(match_wickets), 2) AS avg_wickets_per_match
FROM (
    SELECT 
        bowler,
        season,
        match_id,
        SUM(is_wicket) AS match_wickets
    FROM ball_by_ball
    GROUP BY bowler, season, match_id
) AS match_bowl
JOIN (
    SELECT DISTINCT Name, nationality
    FROM players_salary
) AS p ON match_bowl.bowler = p.Name
GROUP BY p.nationality, match_bowl.season;

-- ============================================================
-- POWER BI RELATIONSHIP GUIDE
-- ============================================================
-- Set up these relationships in Power BI Model View:
--
-- CORE:
--   ball_by_ball.match_id  →  matches.match_id
--   matches.season         →  players_salary.year
--
-- PAGE 1 (season slicer flows through matches):
--   matches.season  →  top5_run_scorers.season
--   matches.season  →  top5_wicket_takers.season
--   matches.season  →  orange_cap.season
--   matches.season  →  purple_cap.season
--   matches.season  →  top_venues.season
--   matches.season  →  win_pct_bat_vs_chase.season
--
-- PAGE 2 (season + player slicers):
--   matches.season  →  player_runs_by_season.season
--   matches.season  →  player_wickets_by_season.season
--   matches.season  →  phase_breakdown.season
--
-- PAGE 3 (auction year slicer):
--   players_salary.year  →  roi_analysis.auction_year
-- ============================================================

SELECT DISTINCT auction_year FROM roi_analysis ORDER BY auction_year;

CREATE OR REPLACE VIEW roi_analysis AS
SELECT
    s.Name                                                AS player_name,
    s.TeamName,
    s.nationality,
    s.price_cr,
    s.year,
    COALESCE(bat.runs, 0)                                 AS runs,
    COALESCE(bowl.wickets, 0)                             AS wickets,
    ROUND(
        COALESCE(bat.runs, 0) / 30.0
        + COALESCE(bowl.wickets, 0) * 5.0
    , 2)                                                  AS performance_score,
    ROUND((
        COALESCE(bat.runs, 0) / 30.0
        + COALESCE(bowl.wickets, 0) * 5.0
    ) / NULLIF(s.price_cr, 0), 4)                         AS roi
FROM players_salary s
LEFT JOIN (
    SELECT season, batter, SUM(batter_runs) AS runs
    FROM ball_by_ball
    GROUP BY season, batter
) bat ON s.Name = bat.batter AND s.year = bat.season
LEFT JOIN (
    SELECT season, bowler, SUM(is_wicket) AS wickets
    FROM ball_by_ball
    WHERE is_wide_ball = 0 AND is_no_ball = 0
    GROUP BY season, bowler
) bowl ON s.Name = bowl.bowler AND s.year = bowl.season
HAVING performance_score > 0;

SELECT 
    year,
    COUNT(*) AS total_players,
    SUM(CASE WHEN performance_score > 0 THEN 1 ELSE 0 END) AS players_with_performance,
    SUM(CASE WHEN performance_score = 0 THEN 1 ELSE 0 END) AS players_without_performance
FROM roi_analysis
GROUP BY year
ORDER BY year;

-- Check how many ball_by_ball players match players_salary for 2022
SELECT COUNT(DISTINCT b.batter) AS matched_batters
FROM ball_by_ball b
JOIN players_salary s ON b.batter = s.Name AND b.season = s.year
WHERE b.season = 2022;

-- See what names look like in ball_by_ball for 2022
SELECT DISTINCT batter 
FROM ball_by_ball 
WHERE season = 2022 
LIMIT 20;

-- See what names look like in players_salary for 2022
SELECT DISTINCT Name 
FROM players_salary 
WHERE year = 2022 
LIMIT 20;

SELECT DISTINCT Name 
FROM players_salary 
WHERE year = 2022 
LIMIT 20;

-- Check if ball_by_ball season 2022 actually has data
SELECT COUNT(*) FROM ball_by_ball WHERE season = 2022;

-- Check if the join works manually
SELECT 
    s.Name,
    bat.runs,
    bowl.wickets
FROM players_salary s
LEFT JOIN (
    SELECT season, batter, SUM(batter_runs) AS runs
    FROM ball_by_ball
    WHERE season = 2022
    GROUP BY season, batter
) bat ON s.Name = bat.batter
LEFT JOIN (
    SELECT season, bowler, SUM(is_wicket) AS wickets
    FROM ball_by_ball
    WHERE season = 2022
    AND is_wide_ball = 0 AND is_no_ball = 0
    GROUP BY season, bowler
) bowl ON s.Name = bowl.bowler
WHERE s.year = 2022
LIMIT 10;




-- Check for hidden spaces or characters
SELECT 
    s.Name,
    LENGTH(s.Name) AS salary_name_length,
    b.batter,
    LENGTH(b.batter) AS bb_name_length
FROM players_salary s
LEFT JOIN ball_by_ball b ON TRIM(s.Name) = TRIM(b.batter)
    AND b.season = 2022
WHERE s.year = 2022
AND b.batter IS NULL
LIMIT 10;

-- Check if Virat Kohli exists in ball_by_ball 2022
SELECT DISTINCT batter, SUM(batter_runs) AS runs
FROM ball_by_ball
WHERE season = 2022
AND batter LIKE '%Kohli%'
GROUP BY batter;

-- Check Bumrah as bowler
SELECT DISTINCT bowler, SUM(is_wicket) AS wickets
FROM ball_by_ball
WHERE season = 2022
AND bowler LIKE '%Bumrah%'
GROUP BY bowler;


-- 2022 Name Fixes
UPDATE players_salary SET Name = 'V Kohli'        WHERE Name = 'Virat Kohli'        AND year = 2022;
UPDATE players_salary SET Name = 'JJ Bumrah'      WHERE Name = 'Jasprit Bumrah'     AND year = 2022;
UPDATE players_salary SET Name = 'RD Gaikwad'     WHERE Name = 'Ruturaj Gaikwad'    AND year = 2022;
UPDATE players_salary SET Name = 'MM Ali'         WHERE Name = 'Moeen Ali'          AND year = 2022;
UPDATE players_salary SET Name = 'SA Yadav'       WHERE Name = 'Suryakumar Yadav'   AND year = 2022;
UPDATE players_salary SET Name = 'GJ Maxwell'     WHERE Name = 'Glenn Maxwell'      AND year = 2022;
UPDATE players_salary SET Name = 'AD Russell'     WHERE Name = 'Andre Russell'      AND year = 2022;
UPDATE players_salary SET Name = 'MS Dhoni'       WHERE Name = 'MS Dhoni'           AND year = 2022;
UPDATE players_salary SET Name = 'KS Williamson'  WHERE Name = 'Kane Williamson'    AND year = 2022;
UPDATE players_salary SET Name = 'HH Pandya'      WHERE Name = 'Hardik Pandya'      AND year = 2022;
UPDATE players_salary SET Name = 'RR Pant'        WHERE Name = 'Rishabh Pant'       AND year = 2022;
UPDATE players_salary SET Name = 'AR Patel'       WHERE Name = 'Axar Patel'         AND year = 2022;
UPDATE players_salary SET Name = 'Umran Malik'    WHERE Name = 'Umran Malik'        AND year = 2022;
UPDATE players_salary SET Name = 'Abdul Samad'    WHERE Name = 'Abdul Samad'        AND year = 2022;
UPDATE players_salary SET Name = 'SP Narine'      WHERE Name = 'Sunil Narine'       AND year = 2022;
UPDATE players_salary SET Name = 'KA Pollard'     WHERE Name = 'Kieron Pollard'     AND year = 2022;
UPDATE players_salary SET Name = 'RG Sharma'      WHERE Name = 'Rohit Sharma'       AND year = 2022;
UPDATE players_salary SET Name = 'RA Jadeja'      WHERE Name = 'Ravindra Jadeja'    AND year = 2022;
UPDATE players_salary SET Name = 'VR Iyer'        WHERE Name = 'Venkatesh Iyer'     AND year = 2022;
UPDATE players_salary SET Name = 'CV Varun'       WHERE Name = 'Varun Chakravarthy' AND year = 2022;
UPDATE players_salary SET Name = 'Mohammed Siraj' WHERE Name = 'Mohammed Siraj'     AND year = 2022;
UPDATE players_salary SET Name = 'F du Plessis'   WHERE Name = 'Faf du Plessis'     AND year = 2022;
UPDATE players_salary SET Name = 'Q de Kock'      WHERE Name = 'Quinton de Kock'    AND year = 2022;
UPDATE players_salary SET Name = 'DA Warner'      WHERE Name = 'David Warner'       AND year = 2022;
UPDATE players_salary SET Name = 'DA Miller'      WHERE Name = 'David Miller'       AND year = 2022;
UPDATE players_salary SET Name = 'DJ Bravo'       WHERE Name = 'Dwayne Bravo'       AND year = 2022;
UPDATE players_salary SET Name = 'KL Rahul'       WHERE Name = 'KL Rahul'           AND year = 2022;
UPDATE players_salary SET Name = 'SS Iyer'        WHERE Name = 'Shreyas Iyer'       AND year = 2022;
UPDATE players_salary SET Name = 'SV Samson'      WHERE Name = 'Sanju Samson'       AND year = 2022;
UPDATE players_salary SET Name = 'Rashid Khan'    WHERE Name = 'Rashid Khan'        AND year = 2022;
UPDATE players_salary SET Name = 'YS Chahal'      WHERE Name = 'Yuzvendra Chahal'   AND year = 2022;
UPDATE players_salary SET Name = 'R Ashwin'       WHERE Name = 'Ravichandran Ashwin' AND year = 2022;
UPDATE players_salary SET Name = 'PJ Cummins'     WHERE Name = 'Pat Cummins'        AND year = 2022;
UPDATE players_salary SET Name = 'JC Buttler'     WHERE Name = 'Jos Buttler'        AND year = 2022;
UPDATE players_salary SET Name = 'TA Boult'       WHERE Name = 'Trent Boult'        AND year = 2022;
UPDATE players_salary SET Name = 'JR Hazlewood'   WHERE Name = 'Josh Hazlewood'     AND year = 2022;
UPDATE players_salary SET Name = 'MP Stoinis'     WHERE Name = 'Marcus Stoinis'     AND year = 2022;
UPDATE players_salary SET Name = 'LS Livingstone' WHERE Name = 'Liam Livingstone'   AND year = 2022;
UPDATE players_salary SET Name = 'TH David'       WHERE Name = 'Tim David'          AND year = 2022;
UPDATE players_salary SET Name = 'SO Hetmyer'     WHERE Name = 'Shimron Hetmyer'    AND year = 2022;
UPDATE players_salary SET Name = 'N Pooran'       WHERE Name = 'Nicholas Pooran'    AND year = 2022;
UPDATE players_salary SET Name = 'Shubman Gill'   WHERE Name = 'Shubman Gill'       AND year = 2022;
UPDATE players_salary SET Name = 'WP Saha'        WHERE Name = 'Wriddhiman Saha'    AND year = 2022;
UPDATE players_salary SET Name = 'KD Karthik'     WHERE Name = 'Dinesh Karthik'     AND year = 2022;
UPDATE players_salary SET Name = 'AM Rahane'      WHERE Name = 'Ajinkya Rahane'     AND year = 2022;
UPDATE players_salary SET Name = 'S Dhawan'       WHERE Name = 'Shikhar Dhawan'     AND year = 2022;
UPDATE players_salary SET Name = 'Arshdeep Singh' WHERE Name = 'Arshdeep Singh'     AND year = 2022;
UPDATE players_salary SET Name = 'B Kumar'        WHERE Name = 'Bhuvneshwar Kumar'  AND year = 2022;
UPDATE players_salary SET Name = 'AT Rayudu'      WHERE Name = 'Ambati Rayudu'      AND year = 2022;
UPDATE players_salary SET Name = 'Avesh Khan'     WHERE Name = 'Avesh Khan'         AND year = 2022;
UPDATE players_salary SET Name = 'D Padikkal'     WHERE Name = 'Devdutt Padikkal'   AND year = 2022;

SELECT 
    COUNT(*) AS total,
    SUM(CASE WHEN performance_score > 0 THEN 1 ELSE 0 END) AS with_performance
FROM roi_analysis
WHERE year = 2022;

-- How many unique players in ball_by_ball for 2022
SELECT COUNT(DISTINCT batter) AS total_batters
FROM ball_by_ball
WHERE season = 2022;

-- How many players in players_salary for 2022
SELECT COUNT(*) AS total_salary_players
FROM players_salary
WHERE year = 2022;


SELECT 
    player_name,
    price_cr,
    runs,
    wickets,
    performance_score,
    roi,
    year
FROM roi_analysis
WHERE player_name LIKE '%Karanveer%';