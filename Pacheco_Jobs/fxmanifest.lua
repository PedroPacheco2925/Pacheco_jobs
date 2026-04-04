fx_version 'cerulean'
game 'gta5'

description 'Pacheco Jobs - Sistema Modular com Tablet'
version '1.0.0'
autor 'Pacheco'

shared_scripts {
    '@es_extended/imports.lua',
    'config.lua',
    'jobs/*/config.lua' -- Lê as configs de todos os trabalhos
}

client_scripts {
    'client/*.lua',
    'jobs/*/client.lua' -- Lê os clients de todos os trabalhos
}

server_scripts {
    '@oxmysql/lib/MySQL.lua', -- Assumindo que usas oxmysql (o padrão atual)
    'server/*.lua',
    'jobs/*/server.lua' -- Lê os servers de todos os trabalhos
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    -- adiciona aqui imagens e outros assets do tablet
}