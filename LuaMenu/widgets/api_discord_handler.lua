--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:GetInfo()
	return {
		name      = "Discord Rich Presence Handler",
		desc      = "Handles setting and updating Discord Rich Presence activity",
		author    = "GoogleFrog, Lexon",
		date      = "17 February 2024",
		license   = "GPL-v2",
		layer     = 0,
		enabled   = true,
	}
end

local lobby
local isinGame
local state, mapName, startTimestamp, playerCount, maxPlayerCount, partyId

local function UpdateActivity(newState, newDetails, newStartTimestamp, newPlayerCount, newMaxPlayerCount, newPartyId)
	-- Update only if something changed
	if state == newState and
		details == newDetails and
		startTimestamp == newStartTimestamp and
		playerCount == newPlayerCount and
		maxPlayerCount == newMaxPlayerCount and
		partyId == newPartyId
	then return end

	state = newState
	details = newDetails
	startTimestamp = newStartTimestamp
	playerCount = newPlayerCount
	maxPlayerCount = newMaxPlayerCount
	partyId = newPartyId

	WG.WrapperLoopback.DiscordSetActivity({
		state = state,
		details = details,
		startTimestamp = startTimestamp,
		playerCount = playerCount,
		maxPlayerCount = maxPlayerCount,
		partyId = partyId
   })
end

local function GetStateFromBattle(battle, aboutToStart)
	local running = battle.isRunning
	local isSpectator = lobby:GetMyIsSpectator()

	if isSpectator and running and isinGame then
		return "Spectating game"
	elseif isinGame and running then
		return "Playing"
	else
		return "In" .. ((running and " running ") or " ") .. "lobby"
	end
end

local function OnJoinOrUpdateBattle(listener, newBattleID)
	if lobby:GetMyBattleID() ~= newBattleID then
		return
	end

	if newBattleID then
		local battle = lobby:GetBattle(newBattleID)
		local newPlayerCount = lobby:GetBattlePlayerCount(newBattleID)
		local newMaxPlayerCount = battle.maxPlayers
		local mapName = battle.mapName
		local newState = GetStateFromBattle(battle)
		local newStartTimestamp

		if battle.isRunning then
			newStartTimestamp = os.time() + (battle.thisGameStartedAt or 0)
		else
			newStartTimestamp = nil
		end
		
		UpdateActivity(newState, mapName, newStartTimestamp, newPlayerCount, newMaxPlayerCount, newBattleID)
	end
end

local function OnLeaveBattle(listener, battleId)
	UpdateActivity("In menu")
end

local function OnBattleAboutToStart(listener, battleType, gameName, mapName)
	if battleType == "replay" then
		UpdateActivity("Watching replay", mapName, os.time())
	elseif battleType == "skirmish" then
		UpdateActivity("Skirmish", mapName, os.time())
	else
		-- Starting to play/spectate a multiplayer game
		isinGame = true
		OnJoinOrUpdateBattle(listener, lobby:GetMyBattleID())
	end
end

local function DelayedInitialize()
	if WG.WrapperLoopback == nil or WG.WrapperLoopback.DiscordSetActivity == nil then
		widgetHandler:RemoveWidget(widget)
		return
	end

	UpdateActivity("In menu")

	lobby = WG.LibLobby.lobby

	lobby:AddListener("OnJoinBattle", OnJoinOrUpdateBattle)
	lobby:AddListener("OnLeaveBattle", OnLeaveBattle)
	lobby:AddListener("OnBattleIngameUpdate", OnJoinOrUpdateBattle)
	lobby:AddListener("OnUpdateBattleInfo", OnJoinOrUpdateBattle)
	lobby:AddListener("OnBattleAboutToStart", OnBattleAboutToStart)
	WG.LibLobby.localLobby:AddListener("OnBattleAboutToStart", OnBattleAboutToStart)
end

function widget:ActivateMenu()
	if WG.WrapperLoopback == nil or WG.WrapperLoopback.DiscordSetActivity == nil then
		widgetHandler:RemoveWidget(widget)
		return
	end
end

function widget:Initialize()
	WG.Delay(DelayedInitialize, 0.5)
end
