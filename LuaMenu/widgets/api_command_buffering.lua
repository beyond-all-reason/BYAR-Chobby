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

local string_find = string.find
local string_sub = string.sub

local bufferBypass = {
	Ping = true,
	RING = true,
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

-- Commands where only the last message per key matters.
-- During a 30-minute game, hundreds of redundant CLIENTSTATUS/UPDATEBATTLEINFO
-- accumulate in the buffer. Compacting keeps only the last occurrence per key,
-- which can eliminate 50-80% of buffered commands.
local squashableCommands = {
	CLIENTSTATUS = true,       -- keyed by userName (2nd token)
	UPDATEBATTLEINFO = true,   -- keyed by battleID (2nd token)
}

local function CompactBuffer(lobby)
	local buf = lobby.commandBuffer
	if not buf then return end
	local n = lobby.commandsInBuffer
	if not n or n <= 1 then return end

	-- Pass 1: find the last index for each squashable command key
	local lastIndex = {}
	local removeCount = 0

	for i = 1, n do
		local cmd = buf[i]
		local sp1 = string_find(cmd, " ")
		if sp1 then
			local cmdName = string_sub(cmd, 1, sp1 - 1)
			if squashableCommands[cmdName] then
				-- Key is "CMDNAME firstArg" (e.g. "CLIENTSTATUS userName")
				local sp2 = string_find(cmd, " ", sp1 + 1)
				local key
				if sp2 then
					key = string_sub(cmd, 1, sp2 - 1)
				else
					key = cmd
				end
				local prevIdx = lastIndex[key]
				if prevIdx then
					buf[prevIdx] = false  -- mark superseded entry for removal
					removeCount = removeCount + 1
				end
				lastIndex[key] = i
			end
		end
	end

	if removeCount == 0 then return end

	-- Pass 2: compact (remove false entries)
	local j = 0
	for i = 1, n do
		if buf[i] then
			j = j + 1
			buf[j] = buf[i]
		end
	end
	for i = j + 1, n do
		buf[i] = nil
	end
	lobby.commandsInBuffer = j
	lobby.bufferExecutionPos = 0
	Spring.Echo("[Command Buffering] Compacted buffer: " .. n .. " -> " .. j .. " commands (" .. removeCount .. " redundant removed)")
end

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

	-- Compact buffer once before draining starts (removes redundant commands)
	if lobby.commandBuffer and lobby.bufferExecutionPos == 0 then
		CompactBuffer(lobby)
	end

	local repetitions = 1
	local startTime = Spring.GetTimer()
	while Spring.DiffTimers(Spring.GetTimer(), startTime) < 0.05 and lobby:ProcessBuffer() do
		repetitions = repetitions + 1
	end

	lobby.bufferCommandsEnabled = lobby.commandsInBuffer and (lobby.commandsInBuffer > 0)
end
