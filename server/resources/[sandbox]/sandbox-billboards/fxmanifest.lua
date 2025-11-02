fx_version("cerulean")
games({ "gta5" })
lua54("yes")
client_script("@sandbox-base/exports/cl_error.lua")
client_script("@sandbox-pwnzor/client/check.lua")

author("Dr Nick")
version("v1.0.0")

client_scripts({
	"client/**/*.lua",
})

server_scripts({
	"@oxmysql/lib/MySQL.lua",
	"server/**/*.lua",
})

shared_scripts({
	"shared/**/*.lua",
})
