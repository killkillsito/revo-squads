fx_version 'cerulean'
game 'gta5'

client_script {
	"config.lua",
	"client/hook.lua",
	'client/main.lua',
	'client/loop.lua',

}

server_script {
	"config.lua",
	"server/hook.lua",
	"server/main.lua",
}

ui_page "nui/index.html"

files {
	'nui/index.html',
	'nui/script.js',
	'nui/style.css',
	'nui/img/*.png'
}

lua54 'yes'

escrow_ignore {
	"config.lua",
	"client/hook.lua",
	"server/hook.lua",
}