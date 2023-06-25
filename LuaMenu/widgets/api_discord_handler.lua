--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:GetInfo()
	return {
		name      = "Discord Handler",
		desc      = "Handles discord stuff.",
		author    = "GoogleFrog",
		date      = "19 December 2017",
		license   = "GPL-v2",
		layer     = 0,
		handler   = true,
		enabled   = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Globals

local lobbyState, prevDetails, prevTime

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utilities

local function SetDiscordPlaying(details)
	--[[
        public string state; /* max 128 bytes */
        public string details; /* max 128 bytes */
        public long startTimestamp;
        public long endTimestamp;
        public string largeImageKey; /* max 32 bytes */
        public string largeImageText; /* max 128 bytes */
        public string smallImageKey; /* max 32 bytes */
        public string smallImageText; /* max 128 bytes */
        public string partyId; /* max 128 bytes */
        public int partySize;
        public int partyMax;
        public string matchSecret; /* max 128 bytes */
        public string joinSecret; /* max 128 bytes */
        public string spectateSecret; /* max 128 bytes */
        public bool instance;
	]]--
	prevDetails = details
	prevTime = nil
	WG.WrapperLoopback.DiscordUpdatePresence({
		details = prevDetails,
		state = lobbyState,
		--startTimestamp = os.time(),
	})
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Rich Presense

local function GetGameType(data)
	if data.isReplay then
		return "Watching Replay"
	end

	if data.isCampaign then
		return "Playing campaign on planet " .. data.planetName
	end

	local meString = ((data.isPlayer and "Playing ") or "Spectating ")
	if teamOnePlayers == 0 then
		if data.isAI then
			if data.isChicken then
				return meString .. "Chicken vs AI"
			else
				return meString .. "AI game"
			end
		end
		return "In custom game"
	end

	if teamTwoPlayers == 0 then
		if data.isAI then
			local friendType = ((teamPlayers > 1 and "coop") or "skirmish")
			if data.isChicken then
				return meString .. friendType .. " vs. AI with Chickens"
			else
				return meString .. friendType .. " vs. AI"
			end
		elseif data.isChicken then
			return meString .. "chicken defense"
		end
		return meString .. "custom game"
	end

	local endStr = ""
	if data.isAI then
		if data.isChicken then
			endStr = " with AI and chickens"
		else
			endStr = " with AI"
		end
	elseif data.isChicken then
		endStr = " with chickens"
	end

	if data.isFFA then
		return meString .. data.teamPlayers .. "-way FFA" .. endStr
	end

	return meString .. data.teamOnePlayers .. "v" .. data.teamTwoPlayers .. endStr
end

local function UpdateIngameString(data)
	prevDetails = GetGameType(data)
	prevTime = os.time()
	WG.WrapperLoopback.DiscordUpdatePresence({
		details = prevDetails,
		startTimestamp = prevTime,
		state = lobbyState,
	})
end

local function RefreshState()
	WG.WrapperLoopback.DiscordUpdatePresence({
		details = prevDetails,
		startTimestamp = prevTime,
		state = lobbyState,
	})
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Externals Functions

local DiscordHandler = {}

function DiscordHandler.SetIngameInfo(data)
	UpdateIngameString(data)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Initialization

local function DelayedInitialize()
	if WG.WrapperLoopback == nil or WG.WrapperLoopback.DiscordUpdatePresence == nil then
		widgetHandler:RemoveWidget(widget)
		return
	end

	SetDiscordPlaying("In menu")

	local function OnBattleAboutToStart(_, battleType)
		if battleType == "replay" then
			SetDiscordPlaying("Loading replay")
		else
			SetDiscordPlaying("Loading battle")
		end
		--if battleType and string.find(battleType, "campaign") then
		--	SetDiscordPlaying("Playing Campaign")
		--elseif battleType == "tutorial" then
		--	SetDiscordPlaying("Playing Tutorial")
		--elseif battleType == "skirmish" then
		--	SetDiscordPlaying("Playing Skirmish")
		--elseif battleType == "replay" then
		--	SetDiscordPlaying("Watching Replay")
		--else
		--	SetDiscordPlaying("Playing Multiplayer")
		--end
	end

	local lobby = WG.LibLobby.lobby

	lobby:AddListener("OnBattleAboutToStart", OnBattleAboutToStart)
	WG.LibLobby.localLobby:AddListener("OnBattleAboutToStart", OnBattleAboutToStart)

	local function InBattleUpdate(listener, newBattleID)
		if myBattleID == newBattleID then
			return
		end

		if newBattleID then
			local battle = lobby:GetBattle(newBattleID)
			lobbyState = "In" .. ((battle.isRunning and " running") or " ") .. " battle lobby"
		else
			lobbyState = nil
		end
		myBattleID = newBattleID
		RefreshState()
	end

	local function OnBattleIngameUpdate(listener, updatedBattleID, isRunning)
		if updatedBattleID ~= myBattleID then
			return
		end
		lobbyState = "In" .. ((isRunning and " running") or " ") .. " battle lobby"
		RefreshState()
	end

	lobby:AddListener("OnJoinBattle", InBattleUpdate)
	lobby:AddListener("OnLeaveBattle", InBattleUpdate)
	lobby:AddListener("OnBattleIngameUpdate", OnBattleIngameUpdate)
end

function widget:ActivateMenu()
	if WG.WrapperLoopback == nil or WG.WrapperLoopback.DiscordUpdatePresence == nil then
		widgetHandler:RemoveWidget(widget)
		return
	end
	SetDiscordPlaying("In menu")
end

function widget:Initialize()
	WG.Delay(DelayedInitialize, 0.5)
	WG.DiscordHandler = DiscordHandler
end
