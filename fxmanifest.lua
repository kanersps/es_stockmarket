--       Licensed under: AGPLv3        --
--  GNU AFFERO GENERAL PUBLIC LICENSE  --
--     Version 3, 19 November 2007     --

fx_version 'bodacious'
games { 'gta5' }

description 'EssentialMode by Kanersps.'

description 'es_ui by Kanersps.'

ui_page 'ui.html'

dependency 'mysql-async'

client_scripts {
	'client.lua'
}

server_scripts {
	'@mysql-async/lib/MySQL.lua',
	'server.lua'
}

-- NUI Files
files {
	'ui.html',
	'ui.js',
	'lcn.jpg'
}