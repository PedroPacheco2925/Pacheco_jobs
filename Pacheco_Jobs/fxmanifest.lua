fx_version 'cerulean'
game 'gta5'

author 'RealRP'
description 'Tablet de Gestão de Mineração'

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/style.css',
    'ui/script.js',
    'ui/assets/*.png' -- Se tiveres imagens, coloca nesta pasta
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

shared_scripts {
    '@es_extended/imports.lua',
    'config.lua'
}