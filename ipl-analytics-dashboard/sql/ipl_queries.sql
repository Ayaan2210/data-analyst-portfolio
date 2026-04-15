-- =========================================================
-- 🏏 IPL DATA ANALYSIS PROJECT (POSTGRESQL)
-- Dataset: cleaned_matches.csv + cleaned_deliveries.csv
-- Tables : matches | deliveries
-- Focus  : Teams, Players, Venues, Toss, Season Trends
-- =========================================================


-- =========================================================
-- HOW TO IMPORT CSV INTO POSTGRESQL
-- Step 1: Create both tables (run create statements below)
-- Step 2: Right click table in pgAdmin → Import/Export Data
--         → Select your cleaned CSV file → Header: ON
-- =========================================================


-- =========================================================
-- TABLE 1: matches
-- =========================================================
CREATE TABLE IF NOT EXISTS matches (
    id               INTEGER,
    season           INTEGER,
    city             TEXT,
    date             TEXT,
    match_type       TEXT,
    player_of_match  TEXT,
    venue            TEXT,
    team1            TEXT,
    team2            TEXT,
    toss_winner      TEXT,
    toss_decision    TEXT,
    winner           TEXT,
    result           TEXT,
    result_margin    TEXT,
    super_over       TEXT
);

-- =========================================================
-- TABLE 2: deliveries (cleaned_deliveries.csv)
-- =========================================================
CREATE TABLE IF NOT EXISTS deliveries (
    match_id         INTEGER,
    inning           INTEGER,
    batting_team     TEXT,
    bowling_team     TEXT,
    over             INTEGER,
    ball             INTEGER,
    batter           TEXT,
    bowler           TEXT,
    non_striker      TEXT,
    batsman_runs     INTEGER,
    extra_runs       INTEGER,
    total_runs       INTEGER,
    extras_type      TEXT,
    is_wicket        INTEGER,
    player_dismissed TEXT,
    dismissal_kind   TEXT,
    fielder          TEXT,
    season           INTEGER,
    venue            TEXT,
    city             TEXT
);


-- =========================================================
-- 1. Most Successful Teams (Total Wins)
-- Purpose: Find which franchises have dominated IPL
-- =========================================================
SELECT
    winner AS team,
    COUNT(*) AS total_wins
FROM matches
WHERE winner != 'No Result'
GROUP BY winner
ORDER BY total_wins DESC
LIMIT 10;

-- 💡 Insight:
-- Mumbai Indians and CSK dominate — strong squad retention
-- and consistent coaching setups are the main reasons


-- =========================================================
-- 2. Team Win Rate (CTE)
-- Purpose: Wins adjusted for matches played — fairer metric
-- =========================================================
WITH team_matches AS (
    SELECT team1 AS team, id FROM matches
    UNION ALL
    SELECT team2 AS team, id FROM matches
),
matches_played AS (
    SELECT team, COUNT(*) AS total_matches
    FROM team_matches
    GROUP BY team
),
wins AS (
    SELECT winner AS team, COUNT(*) AS total_wins
    FROM matches
    WHERE winner != 'No Result'
    GROUP BY winner
)
SELECT
    m.team,
    m.total_matches,
    w.total_wins,
    ROUND(w.total_wins * 100.0 / m.total_matches, 2) AS win_rate_pct
FROM matches_played m
JOIN wins w ON m.team = w.team
ORDER BY win_rate_pct DESC
LIMIT 10;

-- 💡 Insight:
-- Win rate removes bias of teams playing more seasons
-- A newer team with high win rate signals strong squad building


-- =========================================================
-- 3. Top Run Scorers All Time
-- Purpose: Identify best batsmen across all IPL seasons
-- =========================================================
SELECT
    batter,
    SUM(batsman_runs) AS total_runs,
    COUNT(*)          AS balls_faced,
    ROUND(SUM(batsman_runs) * 100.0 / COUNT(*), 2) AS strike_rate
FROM deliveries
GROUP BY batter
ORDER BY total_runs DESC
LIMIT 10;

-- 💡 Insight:
-- Virat Kohli leads by a wide margin — consistency over 15+ seasons
-- Strike rate alongside runs gives a fuller picture of batting quality


-- =========================================================
-- 4. Top Wicket Takers All Time
-- Purpose: Identify best bowlers across all IPL seasons
-- =========================================================
SELECT
    bowler,
    COUNT(*) AS total_wickets
FROM deliveries
WHERE is_wicket = 1
  AND dismissal_kind != 'run out'
GROUP BY bowler
ORDER BY total_wickets DESC
LIMIT 10;

-- 💡 Insight:
-- Death-over specialists dominate this list — Bravo and Malinga
-- Wicket-taking ability is rarer and more valuable than economy in T20


-- =========================================================
-- 5. Toss Impact Analysis (CTE + Window Function)
-- Purpose: Does winning the toss actually help win the match?
-- =========================================================
WITH toss_result AS (
    SELECT
        toss_decision,
        CASE WHEN toss_winner = winner THEN 'Won' ELSE 'Lost' END AS match_result
    FROM matches
    WHERE winner != 'No Result'
)
SELECT
    toss_decision,
    match_result,
    COUNT(*) AS total,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY toss_decision), 2) AS percentage
FROM toss_result
GROUP BY toss_decision, match_result
ORDER BY toss_decision, match_result;

-- 💡 Insight:
-- Toss winner wins ~52% of matches — barely better than a coin flip
-- Teams choosing to field first win slightly more — chasing is easier in T20


-- =========================================================
-- 6. Venue Analysis — Most Matches Hosted
-- Purpose: Identify busiest IPL venues
-- =========================================================
SELECT
    venue,
    COUNT(*) AS matches_hosted
FROM matches
GROUP BY venue
ORDER BY matches_hosted DESC
LIMIT 10;

-- 💡 Insight:
-- Top venues are home grounds of successful franchises
-- Home crowd advantage is a real factor in IPL results


-- =========================================================
-- 7. Highest Scoring Venues (Avg Runs Per Match)
-- Purpose: Find batting-friendly grounds
-- =========================================================
WITH match_runs AS (
    SELECT
        match_id,
        venue,
        SUM(total_runs) AS match_total_runs
    FROM deliveries
    GROUP BY match_id, venue
)
SELECT
    venue,
    COUNT(*)                                    AS matches_played,
    ROUND(AVG(match_total_runs), 2)             AS avg_runs_per_match,
    MAX(match_total_runs)                       AS highest_score
FROM match_runs
GROUP BY venue
HAVING COUNT(*) >= 5
ORDER BY avg_runs_per_match DESC
LIMIT 10;

-- 💡 Insight:
-- Wankhede and Chinnaswamy are notorious for high scores
-- Small boundaries + flat pitches = batting paradise
-- Bowlers need completely different strategies at these venues


-- =========================================================
-- 8. Season-wise Run Trends (Window Function)
-- Purpose: Track how scoring has evolved across IPL seasons
-- =========================================================
WITH season_stats AS (
    SELECT
        season,
        SUM(total_runs)   AS total_runs,
        COUNT(DISTINCT match_id) AS total_matches
    FROM deliveries
    GROUP BY season
)
SELECT
    season,
    total_matches,
    total_runs,
    ROUND(total_runs * 1.0 / total_matches, 2) AS avg_runs_per_match,
    SUM(total_runs) OVER (ORDER BY season)     AS cumulative_runs
FROM season_stats
ORDER BY season;

-- 💡 Insight:
-- Average runs per match has increased every season since 2008
-- Better bats, evolved techniques, and boundary rules all contribute
-- Cumulative runs shows the sheer scale of IPL as a tournament


-- =========================================================
-- 9. Top Player of the Match Winners
-- Purpose: Find most impactful individual performers
-- =========================================================
SELECT
    player_of_match,
    COUNT(*) AS awards_won
FROM matches
WHERE player_of_match IS NOT NULL
GROUP BY player_of_match
ORDER BY awards_won DESC
LIMIT 10;

-- 💡 Insight:
-- Multiple Player of the Match awards = match-winner mentality
-- These players are consistently valuable across different conditions


-- =========================================================
-- 10. Dismissal Type Analysis (Window Function)
-- Purpose: How do most wickets fall in IPL?
-- =========================================================
SELECT
    dismissal_kind,
    COUNT(*) AS total_dismissals,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM deliveries
WHERE is_wicket = 1
  AND dismissal_kind IS NOT NULL
GROUP BY dismissal_kind
ORDER BY total_dismissals DESC;

-- 💡 Insight:
-- Caught is the most common dismissal — aerial shots in T20 carry risk
-- Bowled and LBW show the value of hitting the stumps in T20 cricket
-- Run outs increase under pressure — communication between batsmen breaks down


-- =========================================================
-- END OF PROJECT
-- =========================================================
