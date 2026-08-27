# 🏏 IPL Analytics Dashboard

An end-to-end IPL analytics project analyzing **278,000+ ball-by-ball records** to uncover insights into player performance, team performance, season trends, nationality-based contributions, auction spending, and player ROI using **Python, MySQL, SQL, Excel, and Power BI**.

---

## 📌 Project Overview

This project analyzes IPL ball-by-ball, match, player, and auction data to evaluate batting and bowling performance, team success, season-wise trends, player contributions, and auction value.

The project follows an end-to-end analytics workflow:

**Data Collection → Data Cleaning → MySQL Database → SQL Analysis → Power BI Dashboard → Business Insights**

The final Power BI dashboard contains **3 interactive pages** with slicers for **Season, Team, and Player**.

---

## 🗂️ Project Structure

```text
ipl-analytics-dashboard/
│
├── python/
│   ├── scrape.ipynb
│   ├── ball_by_ball_clean.ipynb
│   ├── ipl_matches_data_clean.ipynb
│   ├── mergeipl.ipynb
│   ├── retain_players_clean.ipynb
│   └── importtosql.ipynb
│
├── sql/
│   └── sql.sql
│
├── data/
│   ├── ball_by_ball_clean.csv
│   ├── matches_clean.csv
│   ├── all_players_salary.csv
│   ├── ipl_auction_team_summary.csv
│   └── retain_clean.csv
│
├── clean data/
│
├── Screenshots/
│
├── ipl_players_classification.csv
├── ipl final resume.pbix
└── README.md
```

---

## 🔧 Tech Stack

| Tool              | Usage                                          |
| ----------------- | ---------------------------------------------- |
| **Python**        | Data cleaning, preprocessing, and web scraping |
| **Pandas**        | Data manipulation and transformation           |
| **BeautifulSoup** | Web scraping auction and player data           |
| **MySQL**         | Database storage and data analysis             |
| **SQL**           | KPI calculations and analytical views          |
| **Excel**         | Supporting data preparation                    |
| **Power BI**      | Interactive dashboard and data visualization   |

---

## 📊 Dashboard Pages

### Page 1 — IPL Overview

Provides a high-level overview of IPL performance across seasons.

**Key KPIs:**

* Total Matches
* Total Runs
* Total Wickets
* Total Sixes
* Winner Team
* Orange Cap
* Purple Cap

**Visualizations:**

* IPL Titles by Team
* Win Percentage by Team
* Indian vs Overseas Players
* Wickets by Season
* Runs by Season

**Interactive slicers:**

* Season
* Team

---

### Page 2 — Player Insights

Provides detailed player-level batting and bowling analysis.

**Key KPIs:**

* Average Strike Rate
* Average Economy
* Highest Team Score
* Highest Player Score
* Most Centuries

**Visualizations:**

* Top Run Scorers
* Top Wicket Takers
* Top Strike Rates
* Best Bowling Economy
* Runs — Indian vs Overseas
* Wickets — Indian vs Overseas

**Interactive slicers:**

* Season
* Team
* Player

---

### Page 3 — Auction & ROI

Analyzes player auction prices and evaluates player value using a custom performance-based ROI model.

**Key KPIs:**

* Most Expensive Player
* Highest ROI Player
* Lowest ROI Player
* Total Auction Spend

**Visualizations:**

* Top ROI Players
* Lowest ROI Players
* ROI by Price Bracket
* Auction Price vs Performance

### ROI Formula

**Performance Score**

```text
Performance Score = (Runs / 30) + (Wickets × 5)
```

**ROI**

```text
ROI = Performance Score / Auction Price (Cr)
```

The ROI analysis focuses on players with an **auction price of ₹1 Cr or more**.

---

## 🗄️ SQL Analytical Views

The MySQL database contains **6 analytical views** that support the Power BI dashboard.

### 1. `player_season_stats`

Player-level batting and bowling statistics, including:

* Runs
* Balls Faced
* Strike Rate
* Fours
* Sixes
* Wickets
* Balls Bowled
* Runs Conceded
* Economy

### 2. `team_season_stats`

Team-level performance metrics, including:

* Matches Played
* Wins
* Losses
* Win Percentage

### 3. `season_summary`

Season-level metrics, including:

* Total Matches
* Total Runs
* Total Wickets
* Total Sixes
* Winning Team

### 4. `roi_dashboard`

Combines auction price with player performance to calculate:

* Runs
* Wickets
* Performance Score
* ROI

### 5. `nationality_season_stats`

Compares Indian and Overseas player contributions by season:

* Players
* Runs
* Wickets
* Sixes

### 6. `auction_spend`

Supports auction spending analysis for players purchased for **₹1 Cr or more**.

---

## 💡 Key Insights

The analysis identified several long-term IPL trends:

* Total IPL runs increased from **17,937 in 2008 to 26,381 in 2025**, representing approximately **47% growth**.
* Total sixes increased from **623 in 2008 to 1,295 in 2025**, representing approximately **108% growth**.
* Player-level analysis highlights major contributors across batting and bowling.
* Auction ROI analysis identifies players who delivered strong performance relative to their auction price.
* Indian vs Overseas analysis compares player contributions across runs, wickets, and sixes.
* Price-versus-performance analysis provides a way to evaluate whether higher auction spending translated into stronger on-field output.

---

## 📈 Key Analytical Areas

The project focuses on:

* Player Performance Analysis
* Batting & Bowling Analysis
* Team Performance
* Season-wise Trends
* Indian vs Overseas Comparison
* Auction Price Analysis
* Player ROI
* Price vs Performance Analysis

---

## ▶️ How to Run

### 1. Data Preparation

Run the Python notebooks in the required sequence to:

1. Collect auction and player data
2. Clean ball-by-ball data
3. Clean match data
4. Merge datasets
5. Prepare player retention data
6. Import cleaned data into MySQL

### 2. MySQL

Create/import the required tables in MySQL and execute:

```text
sql/sql.sql
```

This creates the analytical views used by the Power BI dashboard.

### 3. Power BI

Open:

```text
ipl final resume.pbix
```

Ensure the MySQL data connection is configured correctly, then refresh the dataset to load the latest data.

---

## 📦 Data Sources

* **IPL ball-by-ball and match data:** Kaggle IPL dataset
* **Auction and player data:** Web-scraped IPL auction data
* **Player classification:** Custom Indian/Overseas classification dataset

---

## 📸 Dashboard Preview

Screenshots of the Power BI dashboard are available in:

```text
Screenshots/
```

---

## 🚀 Project Highlights

* **278,000+** IPL ball-by-ball records analyzed
* End-to-end **Python → MySQL → SQL → Power BI** workflow
* **6 analytical SQL views**
* Interactive **3-page Power BI dashboard**
* Player, team, season, nationality, and auction analysis
* Custom performance-based **ROI model**
* Long-term IPL scoring and six-hitting trend analysis
* Auction price vs player performance analysis
