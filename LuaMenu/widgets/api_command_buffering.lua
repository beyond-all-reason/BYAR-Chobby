--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Command Buffering",
		desc      = "Buffers commands while ingame.",
		author    = "GoogleFrog",
		date      = "30 April 2018",
		license   = "GNU LGPL, v2.1 or later",
		layer     = -100005,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Variables

local bufferBypass = {
	Ping = true,
	--[[ ZK only
	Welcome = true,
	AreYouReady = true,
	AreYouReadyUpdate = true,
	AreYouReadyResult = true,
	MatchMakerStatus = true,
	MatchMakerQueueRequestFailed = true,
	SiteToLobbyCommand = true,
	ConnectSpring = true,
	BattleUpdate = true,
	BattleAdded = true,
	BattleRemoved = true,
	BattlePoll = true,
	BattlePollOutcome = true,
	--]]
}

local function NotifyBecamePlayer(arguments)
	local lobby = WG.LibLobby.lobby
	local funArgs = lobby:_GetFunArgs("CLIENTBATTLESTATUS", arguments)
	
	if type(funArgs) ~= "table" or not (funArgs[1] and funArgs[2]) then
		return false
	end

	-- am i mentioned ?
	local myUserName = lobby:GetMyUserName()
	if funArgs[1] ~= myUserName then
		return false
	end

	-- is new status player ?
	local status = lobby:ParseBattleStatus(funArgs[2]) or {}
	if status.isSpectator then
		return false
	end

	-- is my known status spectator ?
	local myBs = lobby:GetUserBattleStatus(lobby.myUserName) or {}
	if not myBs.isSpectator then
	 	return false
	end

	-- this causes a normal CLIENTBATTLESTATUS being applied for all listeners (bypass buffering)
	-- AND play the notification sound !
	return true
end


local CMD_PER_UPDATE = 14

local function AddBufferByPassFunctions()
	local lobby = WG.LibLobby.lobby
	if not lobby then
		return
	end

	local myBs = lobby:GetUserBattleStatus(lobby.myUserName) or {}
	if not myBs.isSpectator then
		return
	end
	lobby.bufferBypass["CLIENTBATTLESTATUS"] = NotifyBecamePlayer

end

function widget:ActivateGame()
	local lobby = WG.LibLobby.lobby
	if not lobby.bufferCommandsEnabled then
		lobby.bufferBypass = table.shallowcopy(bufferBypass)
		AddBufferByPassFunctions()
		lobby.bufferCommandsEnabled = true
	end
	--WG.Chobby.interfaceRoot.GetChatWindow():ClearHistory()
	--WG.BattleRoomWindow.ClearChatHistory()
end

function widget:Update()
	local lobby = WG.LibLobby.lobby
	local isLobbyVisible = WG.Chobby.interfaceRoot.GetLobbyInterfaceHolder().visible
	if not isLobbyVisible then
		if not lobby.bufferCommandsEnabled then
			lobby.bufferBypass = bufferBypass
			lobby.bufferCommandsEnabled = true
		end
		return
	end

	lobby.bufferCommandsEnabled = false
	local repetitions = 1
	local startTime = Spring.GetTimer()
	while Spring.DiffTimers(Spring.GetTimer(), startTime) < 0.05 and lobby:ProcessBuffer() do
		repetitions = repetitions + 1
	end

	lobby.bufferCommandsEnabled = lobby.commandsInBuffer and (lobby.commandsInBuffer > 0)
end
