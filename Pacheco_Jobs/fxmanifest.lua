fx_version 'cerulean'
game 'gta5'

description 'Pacheco Jobs - Sistema Modular com Tablet'
version '1.0.0'
author 'Pacheco'

dependencies {
    'es_extended',
    'oxmysql',
    'ox_lib'
}

shared_scripts {
    '@ox_lib/init.lua', -- <--- CORRIGIDO PARA init.lua IGUAL AO DO CRAFT!
    '@es_extended/imports.lua',
    'config.lua',
    'jobs/miner/config.lua',
    'jobs/fuel/config.lua'

}

client_scripts {
    'client/tablet_client.lua',
    'client/emprego_client.lua',
    'jobs/miner/client.lua',
    'jobs/fuel/client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/tablet_server.lua',
    'server/emprego_server.lua',
    'jobs/miner/server.lua',
    'jobs/fuel/server.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'jobs/miner/ui/minigame.html',
    'jobs/miner/ui/minigame.css',
    'jobs/miner/ui/minigame.js',
    'jobs/miner/ui/washing.html',
    'jobs/miner/ui/washing.css',
    'jobs/miner/ui/washing.js',
    'html/img/miner/*.png',
    'jobs/miner/ui/shop.html',
    'jobs/miner/ui/shop.css',
    'jobs/miner/ui/shop.js',
    'jobs/miner/ui/minigame2.html',
    'jobs/miner/ui/minigame2.css',
    'jobs/miner/ui/minigame2.js'
}