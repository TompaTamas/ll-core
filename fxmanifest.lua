fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'LL Development'
description 'Story-RP Core System with Survival, Missions & Cutscenes'
version '1.0.0'

shared_scripts {
    '@oxmysql/lib/MySQL.lua',
    'shared/config.lua',
    'shared/events.lua',
    'shared/utils.lua'
}

client_scripts {
    'config/core.lua',
    'config/survival.lua',
    'config/missions.lua',
    'config/cutscenes.lua',
    'client/utils/*.lua',
    'client/main.lua',
    'client/override.lua',
    'client/modules/core/*.lua',
    'client/modules/survival/*.lua',
    'client/modules/missions/*.lua',
    'client/modules/cutscenes/*.lua'
}

server_scripts {
    'config/core.lua',
    'config/survival.lua',
    'config/missions.lua',
    'config/cutscenes.lua',
    'server/utils/*.lua',
    'server/main.lua',
    'server/modules/core/*.lua',
    'server/modules/survival/*.lua',
    'server/modules/missions/*.lua',
    'server/modules/cutscenes/*.lua'
}

ui_page 'html/cutscene-creator/index.html'

files {
    'html/cutscene-creator/index.html',
    'html/cutscene-creator/style.css',
    'html/cutscene-creator/script.js',
    'html/audio/handler.html',
    'missions/*.lua',
    'cutscenes/*.json',
    'audio/**/*.ogg',
    'audio/**/*.mp3'
}

dependencies {
    'oxmysql'
}