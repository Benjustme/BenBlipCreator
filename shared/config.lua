Config = {}

-- Locale: 'de' or 'en'
Config.Locale = 'en'

-- Command to open UI
Config.Command = 'BenBlipCreator'

-- ESX groups allowed
Config.AdminGroups = {
  ['admin'] = true,
  ['superadmin'] = true
}

-- Optional ACE permission
Config.AllowAce = true
Config.AcePerm = 'ben.blips'

-- JobGrade compare policy:
-- 'min' => grade >= required
-- 'exact' => grade == required

Config.JobGradeMode = 'min'
