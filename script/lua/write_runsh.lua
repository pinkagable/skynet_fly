local assert = assert
local ARGV = {...}
local skynet_fly_path = ARGV[1]
local svr_name = ARGV[2]
local thread = tonumber(ARGV[3]) or 4
assert(skynet_fly_path,'缺少 skynet_fly_path')
assert(svr_name,'缺少 svr_name')

local skynet_path = skynet_fly_path .. '/skynet/'
local server_path = "./"
local lua_path = skynet_path .. '/3rd/lua/lua'

local shell_str = "#!bin/bash\n"
shell_str = shell_str .. string.format("%s/skynet %s_config.lua\n",skynet_path,svr_name)
shell_str = shell_str .. string.format("%s %s/script/lua/console.lua %s %s create_mod_config_old\n",lua_path,skynet_fly_path,skynet_fly_path,svr_name)
shell_str = shell_str .. string.format("%s %s/script/lua/console.lua %s %s create_logrotate\n",lua_path,skynet_fly_path,skynet_fly_path,svr_name)

local shell_path = server_path .. '/script/'

if not os.execute("mkdir -p " .. shell_path) then
	error("create shell_path err")
end

local file_path = shell_path .. 'run.sh'

local file = io.open(file_path,'w+')
assert(file)
file:write(shell_str)
file:close()
