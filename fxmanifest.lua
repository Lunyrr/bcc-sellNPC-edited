fx_version "adamant"
games { "rdr3" }
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

author 'BCC Scripts @iseeyoucopy'

description 'Sell to NPCs'


shared_scripts {
	'config.lua',
	'locale.lua',
  	'languages/*.lua'
}

client_scripts {
	'client.lua',
}

server_scripts {
	'server.lua',
	'@oxmysql/lib/MySQL.lua'
}

version '1.1.0'
