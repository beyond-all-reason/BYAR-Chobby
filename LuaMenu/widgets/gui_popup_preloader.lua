function widget:GetInfo()
	return {
		name    = 'Popup Preloader',
		desc    = 'Preloads popups which otherwise take too long to load.',
		author  = 'GoogleFrog',
		date    = '19 October 2016',
		license = 'GNU GPL v2',
		layer   = 0,
		enabled = true,
	}
end

local oldLobby
local oldGameName
local aiListWindow
local aiPopup

local showOldAiVersions = false
local showAiOptions = false
local simpleAiList = true

--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- AI List window updating

local function UpdateAiListWindow(battleLobby, gameName)
	if aiPopup then
		aiPopup:ClosePopup()
	end
	aiListWindow = WG.Chobby.AiListWindow(battleLobby, gameName)
	aiListWindow.window:Hide()
end

--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- Initialization

local function InitializeListeners(battleLobby)
	local function OnUpdateBattleInfo(listener, updatedBattleID, spectatorCount, locked, mapHash, mapName,
			engineVersion, runningSince, gameName, battleMode, disallowCustomTeams, disallowBots, isMatchMaker, newPlayerList, maxPlayers, title)

		if updatedBattleID ~= battleLobby:GetMyBattleID() then
			return
		end
		local newGameName = battleLobby:GetBattle(updatedBattleID).gameName
		if newGameName == oldGameName then
			return
		end

		oldLobby = battleLobby
		oldGameName = newGameName
		UpdateAiListWindow(battleLobby, newGameName)
	end

	local function OnJoinedBattle(listener, joinedBattleId, userName)
		if userName ~= battleLobby:GetMyUserName() then
			return
		end
		local newGameName = battleLobby:GetBattle(joinedBattleId).gameName
		if newGameName == oldGameName then
			return
		end

		oldLobby = battleLobby
		oldGameName = newGameName
		UpdateAiListWindow(battleLobby, newGameName)
	end

	battleLobby:AddListener("OnUpdateBattleInfo", OnUpdateBattleInfo)
	battleLobby:AddListener("OnJoinedBattle", OnJoinedBattle)
end

--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- External Functions

local PopupPreloader = {}

function PopupPreloader.ShowAiListWindow(battleLobby, newGameName, teamIndex, quickAddAi)
	local conf = WG.Chobby.Configuration
	if newGameName ~= oldGameName or conf.simpleAiList ~= simpleAiList or oldLobby ~= battleLobby
		or conf.showOldAiVersions ~= showOldAiVersions or conf.showAiOptions ~= showAiOptions
	then
		oldLobby = battleLobby
		oldGameName = newGameName
		showOldAiVersions = conf.showOldAiVersions
		showAiOptions = conf.showAiOptions
		simpleAiList = conf.simpleAiList
		UpdateAiListWindow(battleLobby, newGameName)
	end

	aiListWindow:SetAllyTeam(teamIndex)
	if quickAddAi and aiListWindow:QuickAdd(quickAddAi) then
		return
	end

	aiListWindow.window:Show()
	aiListWindow.window:SetPos(nil, nil, 500, 700)
	aiPopup = WG.Chobby.PriorityPopup(aiListWindow.window, nil, nil, nil, true)
end

--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- Initialization
local function DelayedInitialize()
	--InitializeListeners(WG.LibLobby.localLobby)
	--InitializeListeners(WG.LibLobby.lobby)
end

function widget:Initialize()
	CHOBBY_DIR = LUA_DIRNAME .. "widgets/chobby/"
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	WG.PopupPreloader = PopupPreloader

	WG.Delay(DelayedInitialize, 1)
end
