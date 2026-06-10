-- ============================================================
-- Smart Traffic & Transport Database System
-- Schema Definition (5 Normalized Tables in 3NF)
-- ============================================================


-- CREATE DATABASE IF NOT EXISTS smart_traffic;
-- USE smart_traffic;

-- ============================================================
-- Table 1: states — Indian States & Union Territories
-- ============================================================

DROP TABLE IF EXISTS vehicles;

DROP TABLE IF EXISTS traffic_readings;
DROP TABLE IF EXISTS roads;
DROP TABLE IF EXISTS cities;
DROP TABLE IF EXISTS states;

CREATE TABLE states (
    state_id    INT AUTO_INCREMENT PRIMARY KEY,
    state_name  VARCHAR(100) NOT NULL UNIQUE,
    region      ENUM('North','South','East','West','Central','Northeast') NOT NULL
) ENGINE=InnoDB;

-- ============================================================
-- Table 2: cities — Major Indian Cities
-- ============================================================
CREATE TABLE cities (
    city_id     INT AUTO_INCREMENT PRIMARY KEY,
    city_name   VARCHAR(100) NOT NULL,
    state_id    INT NOT NULL,
    population  INT,
    area_sq_km  DECIMAL(10,2),
    is_metro    BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (state_id) REFERENCES states(state_id) ON DELETE CASCADE,
    INDEX idx_city_state (state_id)
) ENGINE=InnoDB;

-- ============================================================
-- Table 3: roads — Roads and Highways
-- ============================================================
CREATE TABLE roads (
    road_id         INT AUTO_INCREMENT PRIMARY KEY,
    road_name       VARCHAR(200) NOT NULL,
    city_id         INT NOT NULL,
    road_type       ENUM('NH','SH','Urban','Arterial','Expressway') NOT NULL,
    length_km       DECIMAL(10,2),
    lanes           INT,
    speed_limit_kmph INT,
    FOREIGN KEY (city_id) REFERENCES cities(city_id) ON DELETE CASCADE,
    INDEX idx_road_city (city_id)
) ENGINE=InnoDB;

-- ============================================================
-- Table 4: traffic_readings — Traffic Sensor Data
-- ============================================================
CREATE TABLE traffic_readings (
    reading_id          INT AUTO_INCREMENT PRIMARY KEY,
    road_id             INT NOT NULL,
    reading_timestamp   DATETIME NOT NULL,
    vehicle_count       INT,
    avg_speed_kmph      DECIMAL(5,2),
    congestion_level    ENUM('Low','Moderate','High','Severe') NOT NULL,
    weather             ENUM('Clear','Rain','Fog','Storm') DEFAULT 'Clear',
    FOREIGN KEY (road_id) REFERENCES roads(road_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- Table 6: vehicles — Registered Vehicles
-- ============================================================
CREATE TABLE vehicles (
    vehicle_id          INT AUTO_INCREMENT PRIMARY KEY,
    vehicle_type        ENUM('Car','Bus','Truck','Two-Wheeler','Auto','Taxi','Emergency') NOT NULL,
    registration_state  INT,
    registration_year   INT,
    FOREIGN KEY (registration_state) REFERENCES states(state_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ============================================================
-- Multi-Level Indexes (B+ Tree — InnoDB default)
-- ============================================================

-- Level 1: Single-column indexes for high-selectivity queries
CREATE INDEX idx_traffic_timestamp
    ON traffic_readings (reading_timestamp);

-- Level 2: Composite indexes for multi-predicate queries
CREATE INDEX idx_traffic_road_congestion
    ON traffic_readings (road_id, congestion_level);

CREATE INDEX idx_traffic_road_timestamp
    ON traffic_readings (road_id, reading_timestamp);

-- Level 3: Covering indexes (include all queried columns)
CREATE INDEX idx_traffic_covering
    ON traffic_readings (road_id, reading_timestamp, avg_speed_kmph, vehicle_count);
