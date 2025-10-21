fx_version 'bodacious'
game 'gta5'

description 'Dice Roll Script for QBox using ox_lib and ox_inventory'
author 'BruiserX'

ui_page 'web/dice-ui.html'


files {
    'web/dice-ui.html',
    'web/dice-ui.css',
    'web/dice-ui.js'
}

shared_script {
    '@ox_lib/init.lua',
    'config.lua',
    
}
client_scripts {
    'client/client.lua'
}

server_scripts {
    'server/server.lua',
}
