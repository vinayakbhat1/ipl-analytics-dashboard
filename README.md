🏏 IPL Analytics Dashboard (2021–2025)
An end-to-end data analytics project on IPL seasons 2021–2025, covering web scraping, data cleaning, MySQL database design, SQL-based KPI views, and an interactive Power BI dashboard.

📌 Project Overview
This project analyzes IPL match and player performance data across 5 seasons to uncover insights on batting trends, bowling efficiency, auction ROI, and match-winning strategies. The full pipeline goes from raw web-scraped data to a 3-page interactive Power BI dashboard.

🗂️ Project Structure
ipl-analytics-dashboard/
│
├── python/
│   ├── scrape.ipynb               # Web scraping auction data using BeautifulSoup
│   ├── ball_by_ball_clean.ipynb   # Cleaning ball-by-ball delivery data
│   ├── ipl_matches_data_clean.ipynb # Cleaning match-level data
│   ├── mergeipl.ipynb             # Merging datasets and feature engineering
│   ├── retain_players_clean.ipynb # Cleaning player retention data
│   └── importtosql.ipynb          # Importing cleaned data into MySQL
│
├── sql/
│   └── sql.sql                    # 15 production-ready SQL views for Power BI
│
├── data/
│   ├── ball_by_ball_clean.csv     # Cleaned delivery-level data
│   ├── matches_clean.csv          # Cleaned match results
│   ├── all_players_salary.csv     # Player auction prices (2021–2025)
│   ├── ipl_auction_team_summary.csv # Team-wise auction spend summary
│   └── retain_clean.csv           # Retained players data
│
└── iplfinal.pbix                  # Power BI Dashboard file

🔧 Tech Stack
ToolUsagePython (Pandas, BeautifulSoup, Requests)Web scraping, data cleaning, EDAMySQLData storage, 15 SQL views for KPI computationPower BI3-page interactive dashboard

📊 Dashboard Pages
Page 1 — Season Overview

Orange Cap & Purple Cap winners per season
Top 5 run scorers and wicket takers
Batting first vs chasing win percentage
Top venues by matches hosted

Page 2 — Player Deep Dive

Runs and strike rate per player per season (line chart)
Wickets and economy per bowler per season
Phase-wise breakdown: Powerplay / Middle / Death overs
Indian vs Overseas player contribution comparison

Page 3 — Auction, Retention & ROI

Team-wise auction spend analysis
Player ROI Score: (runs / 30) + (wickets × 5) / price_cr
Best value signings across seasons
Retained vs auctioned player performance comparison


🔍 Key SQL Views (15 Total)

orange_cap — Top run scorer per season
purple_cap — Top wicket taker per season
phase_breakdown — Powerplay / Middle / Death over stats
roi_analysis — Performance score and ROI per player per auction year
avg_runs_indian_vs_overseas — Domestic vs overseas batting comparison
win_pct_bat_vs_chase — Match strategy win analysis
...and 9 more


💡 Key Insights

Chasing teams have a higher win % in death-over-heavy matches
Overseas players deliver higher average runs per innings but at significantly higher auction cost
ROI analysis reveals consistently undervalued players across multiple seasons
Death over economy is the strongest predictor of team success in close matches


▶️ How to Run

Run notebooks in /python in order: scrape → clean → merge → importtosql
Execute sql/sql.sql in MySQL to create all views
Open iplfinal.pbix in Power BI Desktop and refresh data source connection


📦 Data Sources

Ball-by-ball and match data: Kaggle — IPL Complete Dataset
Auction prices: Web scraped from iplwinners.net
