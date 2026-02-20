============================================================
README_EN.txt
BenBlipCreator (ESX Legacy) — Ingame Blip Creator (NUI)
Free for all • Open Source • GPL-3.0-or-later
============================================================

OVERVIEW
BenBlipCreator is an in-game blip creator for FiveM (ESX Legacy) with an admin NUI.
You can create, edit, delete and enable/disable blips live — no server restart required.
Includes a visual Sprite & Color Picker (reference data from the official FiveM docs),
SQL persistence, and visibility rules (all/job/job_grade).

FEATURES
- Admin NUI: Create / Edit / Delete / Enable/Disable
- Visual Sprite & Color Picker + manual ID input
- SQL persistence (MySQL/MariaDB)
- Set blip position to player coordinates
- Live sync: changes apply instantly for all players (no restart)
- Visibility: all / job / job_grade (ESX Legacy)
- Locales: German & English (Config.Locale)

REQUIREMENTS
- es_extended (ESX Legacy)
- oxmysql
- ox_lib
- MySQL/MariaDB database

INSTALLATION
1) Make sure dependencies are installed and started.
2) Import the SQL table (see SQL below).
3) Start the resource on your server.

USAGE
Command to open the admin UI:
- /BenBlipCreator
(or whatever you set in Config.Command)

PERMISSIONS
Access can be controlled by ESX groups or optionally via ACE permission.
- ESX groups: Config.AdminGroups
- Optional ACE: Config.AllowAce = true and Config.AcePerm (e.g. "ben.blips")

CONFIGURATION
Important config values:
- Config.Locale: 'de' or 'en'
- Config.Command: e.g. 'blips' or 'benblipcreator'
- Config.AdminGroups: allowed ESX groups
- Config.AllowAce / Config.AcePerm: optional ACE permission system
- Config.JobGradeMode:
  - min   => player grade >= required grade
  - exact => player grade == required grade

NOTES (FIVEM DOCS / ICONS)
Reference data (sprites/colors) is fetched server-side from the official FiveM documentation.
Sprite icons are referenced via URLs from docs.fivem.net.
This project does not redistribute FiveM assets directly.

SQL (TABLE)
Run the following SQL once on your database:

CREATE TABLE IF NOT EXISTS ben_blips (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(60) NOT NULL UNIQUE,
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
  visibility ENUM('all','job','job_grade') NOT NULL DEFAULT 'all',
  job VARCHAR(50) NULL,
  job_grade INT NULL,
  created_by VARCHAR(60) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

LICENSE
This project is licensed under: GNU GPL v3.0 or later (GPL-3.0-or-later)
- You may use it for free, modify it, and keep private changes private.
- If you publish or redistribute it, it must remain Open Source under the same license.
- No warranty / no liability.

Copyright (C) 2026 benjustme
GPL-3.0-or-later — https://www.gnu.org/licenses/
============================================================