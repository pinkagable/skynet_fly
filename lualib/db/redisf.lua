local skynet = require "skynet"
local contriner_client = require "contriner_client"
local redis = require "skynet.db.redis"
local log = require "log"

local setmetatable = setmetatable
local assert = assert
local pcall = pcall
local ipairs = ipairs

local M = {}
local meta = {__index = M}

function M.new_client(db_name)
	local cli = contriner_client:new('share_config_m')
	local conf_map = cli:mod_call('query','redis')
	assert(conf_map and conf_map[db_name],"not redis conf")

	local conf = conf_map[db_name]
	local ok,conn = pcall(redis.connect,conf)
	if not ok then
		log.fatal("redisf new_client err ",conn,conf)
		return nil
	end

	return conn
end

function M.new_watch(db_name,subscribe_list,psubscribe_list,call_back)
	local cli = contriner_client:new('share_config_m')
	local conf_map = cli:mod_call('query','redis')
	assert(conf_map and conf_map[db_name],"not redis conf")
	local conf = conf_map[db_name]

	local ok,watch = pcall(redis.watch,conf)
	if not ok then
		log.fatal("redisf new_watch err ",conf)
		return nil
	end

	for _,key in ipairs(subscribe_list) do
		watch:subscribe(key)
	end

	for _,key in ipairs(psubscribe_list) do
		watch:psubscribe(key)
	end

	local is_cancel = false

	skynet.fork(function()
		while not is_cancel do
			local ok,msg,key,psubkey = pcall(watch.message,watch)
			if ok then
				call_back(msg,key,psubkey)
			else
				log.fatal("watch.message err :",msg,key,psubkey)
				break
			end
		end
	end)

	return function()
		for _,key in ipairs(subscribe_list) do
			watch:unsubscribe(key)
		end
	
		for _,key in ipairs(psubscribe_list) do
			watch:punsubscribe(key)
		end
		watch:disconnect()
		is_cancel = true
		return true
	end
end

return M