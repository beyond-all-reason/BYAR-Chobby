--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    config.lua
--  brief:   configfile for handler.lua
--  author:  jK
--
--  Copyright (C) 2011-2013.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--// 0: disabled
--// 1: enabled, but can be overriden by widget.GetInfo().unsafe
--// 2: always enabled
SAFEWRAP = 1
SAFEDRAW = false  --// requires SAFEWRAP to work

--// when false, the handler will `compress` some output (e.g. list of started widgets)
handler.verbose = false or true

local function LoadLibraries()
	for _, lib in pairs(VFS.SubDirs("libs/")) do
		local addonDir = lib .. LUA_NAME .. "/widgets"
		if #VFS.DirList(addonDir) > 0 then
			table.insert(ADDON_DIRS, addonDir)
		end
	end
end

if LUA_NAME == "LuaUI" or LUA_NAME == "LuaMenu" then
	--assert(LUAUI_DIRNAME)

	--// Config & Widget Locations
	ORDER_FILENAME  = LUA_DIRNAME .. 'Config/IGL_order.lua'
	CONFIG_FILENAME = LUA_DIRNAME .. 'Config/IGL_data.lua'
	KNOWN_FILENAME  = LUA_DIRNAME .. 'Config/IGL_known.lua'

	-- VFS.RAW_FIRST loads user widgets first
	-- VFS.ZIP_FIRST loads game widgets first
	-- VFS.ZIP only loads game widgets
	local localWidgets = false

	if VFS.FileExists(CONFIG_FILENAME) then --check config file whether user want to use localWidgetsFirst
		local configData
		local status, rvalue = pcall(VFS.Include, CONFIG_FILENAME)
		if status then
			configData = rvalue
		else
			Spring.Log(LUA_NAME, "error", "Failed to load config: " .. rvalue)
			configData = {}
		end
		localWidgets = configData and configData["Chili lobby"] and configData["Chili lobby"].loadLocalWidgets
	end

	if localWidgets then
		VFSMODE = VFS.RAW_FIRST
	else
		VFSMODE = VFS.ZIP
	end
	VFS.DEF_MODE = VFSMODE


	ADDON_DIRS     = {
		LUA_DIRNAME .. 'Addons/';
		LUA_DIRNAME .. 'Widgets/';
		LUA_DIRNAME .. 'SystemAddons/';
		LUA_DIRNAME .. 'SystemWidgets/';
		LUA_DIRNAME .. 'chili/'; -- DEPRECATED: Scheduled for removal in 103
	}
	--// Create the "LuaUI/Config" directory
	Spring.CreateDir(LUA_DIRNAME .. 'Config') --FIXME LuaRules!
else
	--//
	VFSMODE = VFS.RAW_FIRST

	AddonNames = handler.AddonName .. "s/"

	ADDON_DIRS     = {
		LUA_DIRNAME .. 'Addons/';
		LUA_DIRNAME .. AddonNames;
		LUA_DIRNAME .. 'SystemAddons/';
		LUA_DIRNAME .. 'System' .. AddonNames;
		LUA_DIRNAME .. 'chili/'; -- DEPRECATED: Scheduled for removal in 103
	}
end
LoadLibraries()
