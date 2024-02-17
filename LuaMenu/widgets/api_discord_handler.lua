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

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Globals

local lobby
local state, details, startTimestamp, playerCount, maxPlayerCount, partyId

local function UpdateActivity(newState, newDetails, newStartTimestamp, newPlayerCount, newMaxPlayerCount, newPartyId)
	state = newState or state
	details = newDetails or details
	startTimestamp = newStartTimestamp or startTimestamp
	playerCount = newPlayerCount or playerCount
	maxPlayerCount = newMaxPlayerCount or maxPlayerCount
	partyId = newPartyId or partyId

	WG.WrapperLoopback.DiscordSetActivity({
		state = state,
		details = details,
		startTimestamp = startTimestamp,
		playerCount = playerCount,
		maxPlayerCount = maxPlayerCount,
		partyId = partyId
   })
end

local function ResetState(newState)
	state = newState
	details = nil
	startTimestamp = nil
	playerCount = nil
	maxPlayerCount = nil
	partyId = nil

	UpdateActivity(state, nil, nil, nil, nil, nil)
end


local function GetStateFromBattle(battle)
	-- Can't access in game status directly
	-- If actually spectating -> spectating = true
	-- If only in lobby -> spectating = nil
	-- If playing -> spectating = false
	local spectating = lobby:GetMyIsSpectator()
	local running = battle.isRunning
	local playing = spectating == false and running

	if spectating and running then
		return "Spectating ongoing game"
	elseif playing then
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
		playerCount = lobby:GetBattlePlayerCount(newBattleID)
		maxPlayerCount = battle.maxPlayers
		details = battle.mapName
		state = GetStateFromBattle(battle)

		if battle.isRunning then
			startTimestamp = os.time() + (battle.thisGameStartedAt or 0)
		end
	else
		state = nil
	end

	UpdateActivity(state, details, startTimestamp, playerCount, maxPlayerCount, newBattleID)
end

local function OnLeaveBattle(listener, battleId)
	ResetState("In menu")
end

local function OnBattleAboutToStart(listener, battleType)--, gameName, mapName)
	if battleType == "replay" then
		UpdateActivity("Watching replay", mapName, os.time(), nil, nil)
	elseif battleType == "skirmish" then
		UpdateActivity("Skirmish", mapName, os.time(), nil, nil)
	else
		-- Starting to play/spectate a multiplayer game
		local battle = lobby:GetBattle(lobby:GetMyBattleID())
		if battle then
			state = GetStateFromBattle(battle)
			startTimestamp = os.time() + (battle.thisGameStartedAt or 0)
		end
		UpdateActivity(state, mapName)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Initialization

local function DelayedInitialize()
	if WG.WrapperLoopback == nil or WG.WrapperLoopback.DiscordSetActivity == nil then
		widgetHandler:RemoveWidget(widget)
		return
	end

	ResetState("In menu")

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
