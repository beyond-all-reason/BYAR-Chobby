--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    main.lua
--  brief:   the entry point from LuaMenu
--  author:  jK
--
--  Copyright (C) 2011-2013.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

LUA_NAME    = Script.GetName()
LUA_DIRNAME = Script.GetName() .. "/"
LUA_VERSION = Script.GetName() .. " v1.0"

VFS.DEF_MODE = VFS.ZIP_FIRST

_G[("%s_DIRNAME"):format(LUA_NAME:upper())] = LUA_DIRNAME -- creates LUAUI_DIRNAME
_G[("%s_VERSION"):format(LUA_NAME:upper())] = LUA_VERSION -- creates LUAUI_VERSION

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- Initialize the Lua LogSection (else messages with level "info" wouldn't been shown)
--

if Spring.SetLogSectionFilterLevel then
	Spring.SetLogSectionFilterLevel(LUA_NAME, "info")
else
	-- backward compability
	local origSpringLog = Spring.Log

	Spring.Log = function(name, level, ...)
		if (type(level) == "string")and(level == "info") then
			Spring.Echo(("[%s]"):format(name), ...)
		else
			origSpringLog(name, level, ...)
		end
	end
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- 
-- Check if Tracy is present
--

if tracy == nil then 
	tracy = {}
	tracy.ZoneBeginN = function() return end
	tracy.ZoneBegin = function() return end
	tracy.ZoneEnd = function() return end
	tracy.Message = function() return end
	tracy.stub = true
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- Load
--

VFS.Include("LuaHandler/Utilities/utils.lua", nil, VFS.DEF_MODE)
VFS.Include("LuaMenu/utils.lua", nil, VFS.DEF_MODE)
Json = VFS.Include("libs/json.lua", nil, VFS.RAW_FIRST)

--// the addon handler
include "LuaHandler/handler.lua"

--// print Lua & LuaUI version
Spring.Log(LUA_NAME, "info", LUA_VERSION .. " (" .. _VERSION .. ")")

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
