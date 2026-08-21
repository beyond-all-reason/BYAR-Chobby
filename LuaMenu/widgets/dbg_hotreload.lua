function widget:GetInfo()
	return {
		name    = 'Dev Hot Reload',
		desc    = 'Ctrl+T: toggle auto reload on file change. Ctrl+R: reload changed widgets.',
		author  = 'tetrisface',
		date    = '2026',
		license = 'GNU GPL v2',
		layer   = 0,
		handler = true, -- grants access to the real widgetHandler (Enable/DisableWidget)
		enabled = true,
	}
end

-- A focused chili EditBox eats all keys except enter/esc/F1-F12 (see
-- editbox.lua inedibleInput), so these binds only work with no text box focused.
local KEY_R = Spring.GetKeyCode("r")
local KEY_T = Spring.GetKeyCode("t")

-- Widgets that cannot survive a Disable/Enable cycle. APIs are skipped via
-- _info.api; these are skipped by name. Edits to them need Ctrl+F8 or a restart.
local UNRELOADABLE = {
	['Dev Hot Reload'] = true, -- self; removal mid-callin breaks the dispatch
	['Chili lobby'] = true,    -- owns the interface tree; Shutdown does not Dispose it
	['Login Window'] = true,   -- re-Initialize re-runs autologin, which disconnects first
}

local AUTO_CHECKS_PER_FRAME = 2

-- Auto-reload state lives in Configuration ("devHotReloadAuto"): the settings
-- window checkbox and Ctrl+T both write it, and Configuration persists it.
local seeded = false

-- In-game, LuaMenu still receives KeyPress/Update (nothing gates the dispatch),
-- so bail unless the lobby is the active UI. KeyPress must return nil when
-- gated so the key falls through gui_block_input to the game.
local function MenuIsActiveUI()
	if Spring.GetGameName() == "" then
		return true -- no game loaded; the lobby is the whole UI
	end
	local root = WG.Chobby and WG.Chobby.interfaceRoot
	return (root and root.GetLobbyInterfaceHolder().visible) or false
end
local fileHashes = {}
local pollNames = {}
local pollFiles = {}
local pollIndex = 1

local function IsReloadable(info)
	return not info.api and not UNRELOADABLE[info.name] and info.filepath ~= nil
end

local function RebuildPollList()
	pollNames = {}
	pollFiles = {}
	for _, addon in widgetHandler.addons:iter() do
		local info = addon._info
		if IsReloadable(info) then
			pollNames[#pollNames + 1] = info.name
			pollFiles[info.name] = info.filepath
		end
	end
	pollIndex = 1
end

local function FindControlByName(control, name)
	if control.name == name then
		return control
	end
	local children = control.children
	if not children then
		return nil
	end
	for i = 1, #children do
		local child = children[i]
		if type(child) == "table" then
			local found = FindControlByName(child, name)
			if found then
				return found
			end
		end
	end
end

-- The battle room embeds GetModoptionsControl() once at join, so a reloaded
-- Modoptions Panel is invisible until rejoin. Swap the fresh control into the
-- live holder and re-emit the lobby's cached modoptions so it renders now.
local function ReembedModoptionsPanel()
	local Chili = WG.Chili
	local panel = WG.ModoptionsPanel
	local libLobby = WG.LibLobby
	if not (Chili and Chili.Screen0 and panel and libLobby) then
		return
	end

	local lobby = libLobby.lobby
	local battleID = lobby and lobby.GetMyBattleID and lobby:GetMyBattleID()
	if not battleID then
		lobby = libLobby.localLobby
		battleID = lobby and lobby.GetMyBattleID and lobby:GetMyBattleID()
	end
	local battle = battleID and lobby:GetBattle(battleID)
	if not battle then
		return -- not in a battle room; nothing to re-embed
	end

	local holder = FindControlByName(Chili.Screen0, "modoptionsHolder")
	if not holder then
		Spring.Echo("[DevHotReload] modoptionsHolder not on screen; rejoin the battle room to see the new panel")
		return
	end

	panel.LoadModoptions(battle.gameName, lobby)
	local control = panel.GetModoptionsControl()
	for i = #holder.children, 1, -1 do
		local child = holder.children[i]
		if child ~= control then
			child:Dispose()
		end
	end
	if control.parent ~= holder then
		holder:AddChild(control)
	end
	-- Re-emit current modoptions to all listeners; the fresh panel renders,
	-- other listeners see an empty change diff.
	lobby:_OnSetModOptions(lobby.modoptions or {})
	Spring.Echo("[DevHotReload] re-embedded modoptions panel into the live battle room")
end

-- Widgets whose controls other windows embed at creation need fixing up after
-- a cycle; failures must not crash our Update/KeyPress callins.
local POST_RELOAD = {
	['Modoptions Panel'] = ReembedModoptionsPanel,
}

local function ReloadWidget(name)
	widgetHandler:DisableWidget(name)
	widgetHandler:EnableWidget(name)
	local post = POST_RELOAD[name]
	if post then
		local ok, err = pcall(post)
		if not ok then
			Spring.Echo("[DevHotReload] post-reload hook for " .. name .. " failed: " .. tostring(err))
		end
	end
end

-- Hashes the widget's file; on first sight just records the hash. Returns true
-- when the widget was reloaded because its file content changed.
local function CheckWidgetFile(name, filepath)
	local content = VFS.LoadFile(filepath, VFS.RAW_FIRST)
	if not content then
		return false
	end
	local newHash = VFS.CalculateHash(content, 1)
	local oldHash = fileHashes[name]
	fileHashes[name] = newHash
	if oldHash == nil or newHash == oldHash then
		return false
	end
	-- Never swap in source that does not even parse (protects against
	-- half-written saves); the next good save triggers the reload instead.
	local chunk, err = loadstring(content, name)
	if not chunk then
		Spring.Echo("[DevHotReload] not reloading " .. name .. ", syntax error: " .. tostring(err))
		return false
	end
	ReloadWidget(name)
	Spring.Echo("[DevHotReload] reloaded " .. name)
	return true
end

local function ReloadChangedWidgets()
	RebuildPollList()
	local count = 0
	for i = 1, #pollNames do
		local name = pollNames[i]
		if CheckWidgetFile(name, pollFiles[name]) then
			count = count + 1
		end
	end
	if count == 0 then
		Spring.Echo("[DevHotReload] no widget files changed")
	end
end

function widget:Update()
	-- Seed after all widgets finished loading, not in our own Initialize.
	if not seeded then
		seeded = true
		RebuildPollList()
		for i = 1, #pollNames do
			local name = pollNames[i]
			CheckWidgetFile(name, pollFiles[name])
		end
		return
	end

	if not MenuIsActiveUI() then
		return
	end
	local conf = WG.Chobby and WG.Chobby.Configuration
	if not (conf and conf.devHotReloadAuto) then
		return
	end
	for _ = 1, AUTO_CHECKS_PER_FRAME do
		if pollIndex > #pollNames then
			RebuildPollList() -- also picks up widgets loaded since the last sweep
			if #pollNames == 0 then
				return
			end
		end
		local name = pollNames[pollIndex]
		pollIndex = pollIndex + 1
		CheckWidgetFile(name, pollFiles[name])
	end
end

function widget:KeyPress(key, mods, isRepeat)
	if isRepeat or not mods.ctrl then return end
	if not MenuIsActiveUI() then return end
	if key == KEY_T then
		local conf = WG.Chobby and WG.Chobby.Configuration
		if not conf then
			return true
		end
		conf:SetConfigValue("devHotReloadAuto", not conf.devHotReloadAuto)
		Spring.Echo("[DevHotReload] auto reload " .. (conf.devHotReloadAuto and "ON" or "OFF"))
		return true
	end
	if key == KEY_R then
		ReloadChangedWidgets()
		return true
	end
end
