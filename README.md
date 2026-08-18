# 🚦 Smart Traffic & Transport Database System

![Project Status](https://img.shields.io/badge/Status-Complete-success)
![Database](https://img.shields.io/badge/Database-MySQL%208+-blue)
![Backend](https://img.shields.io/badge/Backend-Node.js%20%7C%20Express-green)
![Frontend](https://img.shields.io/badge/Frontend-Vanilla%20JS%20SPA-yellow)

A full-stack academic Database Management System built around smart city traffic infrastructure. The application monitors real-time traffic flow across 50 major Indian cities, visualizes congestion patterns, and serves as a hands-on demonstration of core DBMS concepts — including **B+ Tree Indexing**, **Query Cost Estimation**, and **Precompiled SQL Views**.

---

## 🧠 DBMS Concepts Demonstrated

### 1. Third Normal Form (3NF) Normalization
The database is structured into **5 normalized tables** (`states`, `cities`, `roads`, `traffic_readings`, `vehicles`) linked through surrogate primary keys and foreign key constraints. All transitive dependencies are eliminated — for example, `state_name` is never stored alongside city data; it is always resolved through a `state_id` join.

### 2. Multi-Level B+ Tree Indexing
Three tiers of indexes are defined on the `traffic_readings` table to demonstrate how InnoDB's B+ Tree engine accelerates lookups at different levels of complexity:

| Level | Index Name | Columns | Purpose |
|-------|-----------|---------|---------|
| **Level 1** — Single Column | `idx_traffic_timestamp` | `reading_timestamp` | Fast range queries on time |
| **Level 2** — Composite | `idx_traffic_road_congestion` | `road_id, congestion_level` | Multi-predicate filtering |
| **Level 2** — Composite | `idx_traffic_road_timestamp` | `road_id, reading_timestamp` | Road-specific time series |
| **Level 3** — Covering | `idx_traffic_covering` | `road_id, reading_timestamp, avg_speed_kmph, vehicle_count` | Query answered entirely from index — zero table lookups |

### 3. Query Cost Estimation
The `/api/dbms/cost-estimation` endpoint runs `EXPLAIN FORMAT=TRADITIONAL` on 4 predefined queries, executing each **with** its index and **without** (using `IGNORE INDEX`). It then computes and compares:
- **Rows examined** (selectivity)
- **I/O cost** (pages read = rows × avg_row_length ÷ 16 KB page size)
- **CPU cost** (rows × 0.01 tuple cost)
- **Total cost** and **improvement percentage**

### 4. Precompiled SQL Views
Two materialized views offload heavy aggregation logic to the database engine:
- `v_city_traffic_summary` — Aggregated traffic metrics per city (avg speed, congestion %, severe counts)
- `v_road_congestion_ranking` — Road-level congestion ranking across all cities

### 5. Stored Procedures
Two stored procedures are created during seeding:
- `sp_congestion_report(city_id, date_from, date_to)` — Generates a congestion breakdown for a specific city and date range
- `sp_traffic_trend(road_id, days)` — Returns hourly traffic trends for a given road

### 6. Referential Integrity & ACID Constraints
- `ON DELETE CASCADE` on `cities → states`, `roads → cities`, `traffic_readings → roads`
- `ON DELETE SET NULL` on `vehicles → states` (registration state can be orphaned gracefully)

---

## 🌟 Features

### Dashboard Page
- **KPI Cards**: Total roads, average speed, congestion rate — with animated counters
- **Congestion Distribution Donut**: Nationwide breakdown of Low / Moderate / High / Severe readings
- **Weather Impact Chart**: How Clear, Rain, Fog, and Storm conditions affect average speed and congestion
- **Top Congested Cities Bar Chart**: City-by-city comparison powered by the `v_city_traffic_summary` view

### Traffic Monitor Page
- **City & Road Selectors**: Dropdown filters for any of the 50 seeded cities and their roads
- **Dynamic KPI Cards**: Road count, average speed, peak vehicles, congestion rate, and dominant weather for the selected city
- **6 Interactive Charts**: Road congestion levels (stacked bar), speed vs speed limit, 7-day traffic trend (line), vehicle load by road type (polar), peak hours analysis (bar), and a city congestion heatmap table
- **Live Traffic Table**: Latest reading per road with color-coded speed, congestion badges, and weather icons
- **Refresh Button**: Re-fetches all data with a toast notification

### DBMS Concepts Page
- **Multi-Level Index Visualizer**: Cards for each index level with columns, cardinality, and type
- **B+ Tree SVG Visualization**: Interactive tree structure diagram rendered directly in the UI
- **O(N) vs O(log N) Live Race**: Animated comparison of a full table scan against a B+ Tree index search
- **All Database Indexes Table**: Every index in the `smart_traffic` schema pulled from `INFORMATION_SCHEMA.STATISTICS`
- **Query Cost Estimation Tab**: Side-by-side cost breakdown for 4 queries, showing I/O pages, CPU cost, rows examined, and improvement percentage with/without indexing

### Global Features
- **Index Toggle**: A header switch (`X-Ignore-Index` header) that forces the backend to inject `IGNORE INDEX` hints on `traffic_readings` queries — instantly demonstrating the performance difference
- **Performance Stopwatch**: Displays the server-side query time (`X-Query-Time` header) for every API call
- **Dark/Light Theme Toggle**: With smooth GSAP transition animation
- **GSAP Entrance Animations**: Page elements animate in with perspective transforms and stagger timing
- **Animated Background Orbs**: Floating gradient orbs with a subtle grid breathing effect
- **Back-to-Top Button** and **SPA Deep-Link Guard** (redirects stale URLs to `/`)

---

## 🏗️ Architecture

### ER Model — Entity Relationships

```
states (1) ──has──▸ (N) cities (1) ──has──▸ (N) roads (1) ──has──▸ (N) traffic_readings
  │
  └─── (1) ──registers──▸ (N) vehicles
```

### Schema (5 Tables)

| Table | Primary Key | Key Columns | Records (approx.) |
|-------|------------|-------------|-------------------|
| `states` | `state_id` | `state_name`, `region` (ENUM) | 36 |
| `cities` | `city_id` | `city_name`, `population`, `is_metro` | 50 |
| `roads` | `road_id` | `road_name`, `road_type` (ENUM), `speed_limit_kmph` | ~250 |
| `traffic_readings` | `reading_id` | `vehicle_count`, `avg_speed_kmph`, `congestion_level`, `weather` | ~15,000+ |
| `vehicles` | `vehicle_id` | `vehicle_type` (ENUM), `registration_state`, `registration_year` | 5,000 |

### Technology Stack

| Layer | Technology |
|-------|-----------|
| **Database** | MySQL 8+ (InnoDB engine) |
| **Backend** | Node.js, Express.js, mysql2/promise |
| **Frontend** | HTML5, Vanilla JS, CSS3 (Single Page App) |
| **Charting** | Chart.js 4.4.0 |
| **Animations** | GSAP 3.12.5 |
| **Live Data** | TomTom Traffic Flow API |
| **Fonts** | Inter, JetBrains Mono (Google Fonts) |

---

## 📡 API Endpoints

### Traffic Routes (`/api/traffic`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/live?city_id=` | Latest reading per road (optional city filter) |
| GET | `/congestion/:cityId` | Congestion analysis per road |
| GET | `/trend/:roadId?days=7` | Hourly time-series data for a road |
| GET | `/heatmap` | City-level congestion ranking |
| GET | `/cities` | All cities for dropdown population |
| GET | `/roads/:cityId` | Roads in a specific city |
| GET | `/city-kpi/:cityId` | Aggregated KPI stats (supports `all`) |
| GET | `/peak-hours/:cityId` | Traffic volume grouped by hour of day |

### Analytics Routes (`/api/analytics`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/overview` | Dashboard KPI data (counts, avg speed, congestion rate) |
| GET | `/city-comparison` | Top 20 cities from `v_city_traffic_summary` view |
| GET | `/congestion-distribution` | Nationwide congestion level breakdown |
| GET | `/weather-impact` | Weather condition impact on speed and congestion |

### DBMS Routes (`/api/dbms`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/indexes` | All indexes from `INFORMATION_SCHEMA`, classified by level |
| GET | `/cost-estimation` | Full cost comparison (4 queries, with/without index) |
| GET | `/index-stats` | Cardinality and selectivity per index |

---

## 🚀 Getting Started

### Prerequisites
- **Node.js** v16 or higher
- **MySQL Server** (running locally)
- **TomTom API Key** (free tier) — optional, synthetic data is generated as fallback

### 1. Clone & Install

```bash
git clone <your-repo-url>
cd DBMS-Project_2
npm install
```

### 2. Configure Environment

Create a `.env` file in the project root:

```env
DB_PASSWORD=your_mysql_password
TOMTOM_API_KEY=your_tomtom_api_key
```

> The TomTom key is optional. If omitted, the seeder generates fully synthetic traffic data using realistic Indian metro congestion weights.

### 3. Seed the Database

This single command handles everything — creates the `smart_traffic` database, runs `schema.sql`, seeds all 5 tables with realistic data, creates views from `procedures.sql`, and registers 2 stored procedures:

```bash
npm run seed
```

The seeder:
- Inserts **36 states/UTs**, **50 cities**, **~250 roads**, **~15,000+ traffic readings**, and **5,000 vehicles**
- Fetches live speed data from the TomTom API for 8 major cities (Mumbai, Delhi, Bangalore, Hyderabad, Chennai, Kolkata, Pune, Ahmedabad) and uses it as a baseline to generate historically realistic readings
- Applies metro congestion weights (e.g., Mumbai 0.85, Delhi 0.82) so metro cities naturally show heavier traffic
- Distributes weather conditions: Clear 70%, Rain 15%, Fog 10%, Storm 5%

### 4. Start the Server

```bash
npm run dev
```

Open **[http://localhost:3000](http://localhost:3000)** in your browser.

> The server also prints a local network URL so you can access the app from other devices on the same Wi-Fi.

### Background Polling
Once running, the server polls the TomTom API every **15 minutes** to insert fresh live traffic readings for the top 5 metro cities, keeping the database continuously updated.

---

## 📂 Project Structure

```
DBMS-Project_2/
├── database/
│   ├── schema.sql              ← 5 tables + 4 B+ tree indexes
│   ├── procedures.sql          ← 2 precompiled SQL views
│   ├── seed.js                 ← Master seeder (schema + data + views + procedures)
│   ├── connection.js           ← MySQL pool with IGNORE INDEX middleware
│   └── fetchLiveTraffic.js     ← TomTom API client (8 city coordinates)
├── routes/
│   ├── traffic.js              ← 8 traffic monitoring endpoints
│   ├── analytics.js            ← 4 dashboard analytics endpoints
│   └── dbms.js                 ← 3 DBMS concept endpoints
├── public/
│   ├── index.html              ← SPA shell (3 pages: Dashboard, Traffic, DBMS)
│   ├── css/styles.css          ← Full design system (dark/light, glassmorphism)
│   ├── js/app.js               ← SPA router, KPI rendering, theme, animations
│   ├── js/charts.js            ← All Chart.js chart renders
│   └── js/dbms.js              ← Index visualization, B+ tree SVG, cost estimation UI
├── server.js                   ← Express server, middleware, background TomTom polling
├── package.json
├── .env                        ← DB_PASSWORD, TOMTOM_API_KEY
├── ER.mwb                      ← MySQL Workbench ER diagram
└── ER_model.png                ← Exported ER diagram image
```

---

## 🔄 Data Flow

```
Browser (SPA)                    Node.js / Express                  MySQL (InnoDB)
─────────────                    ─────────────────                  ──────────────
fetch('/api/traffic/live')  ──▸  routes/traffic.js              ──▸  SELECT ... JOIN
  + X-Ignore-Index header        connection.js intercepts            B+ Tree index scan
                                 injects IGNORE INDEX if toggled     OR full table scan
                            ◂──  JSON response                 ◂──  Optimized result set
  X-Query-Time header            + query duration measured
  Chart.js renders data
```

---

## 👥 Contributors
- KIRITO-899
- HemanthRoyal74
- amohg-byte

