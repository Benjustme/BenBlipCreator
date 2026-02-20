fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'BenBlipCreator'
author 'benjustme'
version '1.1.0'
description 'Ingame Blip Creator (ESX Legacy) with NUI + Sprite/Color Picker + SQL + Locales'

ui_page 'web/index.html'

files {
  'web/index.html',
  'web/style.css',
  'web/app.js'
}

shared_scripts {
  '@ox_lib/init.lua',
  'shared/config.lua',
  'shared/locales.lua',
  'shared/locales_en.lua',
  'shared/locales_de.lua'
}

client_scripts {
  'client/main.lua'
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server/main.lua'
}