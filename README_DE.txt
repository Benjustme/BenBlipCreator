============================================================
README_DE.txt
BenBlipCreator (ESX Legacy) — Ingame Blip Creator (NUI)
Free for all • Open Source • GPL-3.0-or-later
============================================================

ÜBERBLICK
BenBlipCreator ist ein Ingame-Blip-Creator für FiveM (ESX Legacy) mit Admin-NUI.
Du kannst Blips live erstellen, bearbeiten, löschen und aktivieren/deaktivieren — ohne Server-Neustart.
Enthalten sind ein grafischer Sprite- und Color-Picker (mit Referenzdaten aus den offiziellen FiveM Docs),
SQL-Speicherung und Sichtbarkeitsregeln (all/job/job_grade).

FEATURES
- Admin NUI: Erstellen / Bearbeiten / Löschen / Aktivieren/Deaktivieren
- Sprite- & Color-Picker (grafisch) + manuelle Eingabe per ID möglich
- SQL Speicherung (MySQL/MariaDB)
- Position auf Spielerposition setzen
- Live Sync: Änderungen gelten sofort für alle Spieler (kein Neustart)
- Sichtbarkeit: all / job / job_grade (ESX Legacy)
- Lokalisierung: Deutsch & Englisch (Config.Locale)

VORAUSSETZUNGEN
- es_extended (ESX Legacy)
- oxmysql
- ox_lib
- MySQL/MariaDB Datenbank

INSTALLATION
1) Stelle sicher, dass die Abhängigkeiten installiert und gestartet sind.
2) Importiere die SQL-Tabelle (siehe SQL weiter unten).
3) Starte die Resource auf deinem Server.

NUTZUNG
Command zum Öffnen der Admin-UI:
- /BenBlipCreator
(oder der Command, den du in Config.Command gesetzt hast)

BERECHTIGUNGEN
Zugriff kann über ESX Gruppen oder optional über ACE Permission geregelt werden.
- ESX Gruppen: Config.AdminGroups
- ACE optional: Config.AllowAce = true und Config.AcePerm (z.B. "ben.blips")

KONFIGURATION
Wichtige Config Werte:
- Config.Locale: 'de' oder 'en'
- Config.Command: z.B. 'blips' oder 'benblipcreator'
- Config.AdminGroups: erlaubte ESX Gruppen
- Config.AllowAce / Config.AcePerm: optionales ACE Permission System
- Config.JobGradeMode:
  - min   => grade >= required grade
  - exact => grade == required grade

HINWEISE (FIVEM DOCS / ICONS)
Die Referenzdaten (Blips/Farben) werden serverseitig aus den offiziellen FiveM Docs geladen.
Die Blip-Icons werden per URL von docs.fivem.net eingebunden.
Dieses Projekt redistribuiert keine FiveM-Assets direkt.

SQL (TABELLE)
Führe den folgenden SQL-Befehl einmal in deiner Datenbank aus:

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

LIZENZ
Dieses Projekt ist lizenziert unter: GNU GPL v3.0 or later (GPL-3.0-or-later)
- Du darfst es kostenlos nutzen, modifizieren und privat anpassen.
- Wenn du es veröffentlichst oder weitergibst, muss es Open Source bleiben und unter derselben Lizenz stehen.
- Keine Garantie / Haftung.

Copyright (C) 2026 benjustme
GPL-3.0-or-later — https://www.gnu.org/licenses/
============================================================