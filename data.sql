-- BenBlipCreator v1.1.0 - data.sql
-- Creates the required table (no sample data).

CREATE TABLE IF NOT EXISTS ben_blips (
  id INT AUTO_INCREMENT PRIMARY KEY,

  -- internal functional name (unique)
  name VARCHAR(60) NOT NULL UNIQUE,

  -- label shown on the map/blip
  label VARCHAR(64) NOT NULL,

  sprite INT NOT NULL,
  color INT NOT NULL,
  scale FLOAT NOT NULL DEFAULT 0.9,
  display INT NOT NULL DEFAULT 4,
  short_range TINYINT(1) NOT NULL DEFAULT 1,
  enabled TINYINT(1) NOT NULL DEFAULT 1,

  x DOUBLE NOT NULL,
  y DOUBLE NOT NULL,
  z DOUBLE NOT NULL,

  -- visibility rules
  visibility ENUM('all','job','job_grade') NOT NULL DEFAULT 'all',
  job VARCHAR(50) NULL,
  job_grade INT NULL,

  created_by VARCHAR(60) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
