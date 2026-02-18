-- Official SpringRTS Lobby protocol implementation
-- http://springrts.com/dl/LobbyProtocol/

VFS.Include(LIB_LOBBY_DIRNAME .. "interface_shared.lua")

local spGetTimer = Spring.GetTimer
local spDiffTimers = Spring.DiffTimers

-- map lobby commands by name
Interface.commands = {}
-- map json lobby commands by name
Interface.jsonCommands = {}
-- define command format with pattern (regex)
Interface.commandPattern = {}

local forcePlayer = false

-------------------------------------------------
-- BEGIN Client commands
-------------------------------------------------

------------------------
-- Connectivity commands
------------------------

function Interface:Register(userName, password, email)
	username = self:TextEraseNewline(userName)
	password = self:TextEraseNewline(password)

	self:super("Register", userName, password, email)
	password = VFS.CalculateHash(password, 0)
	self:_SendCommand(concat("REGISTER", userName, password, email))
	return self
end

local function GetLobbyName()
	local byarchobbyrapidTag = "unknown"
	for i,v in ipairs(VFS.GetLoadedArchives()) do 
			if string.find(v,"BYAR Chobby ", nil, true) then
			byarchobbyrapidTag = string.gsub(string.gsub(v,"test%-", ""), "BYAR Chobby ", "")
			byarchobbyrapidTag = string.gsub(byarchobbyrapidTag, "[^%w]", " ")
			break
		end
	end
	local lobbyname = 'Chobby:'..byarchobbyrapidTag
	--Spring.Utilities.TraceFullEcho()
	return lobbyname
end

function Interface:Login(user, password, cpu, localIP, lobbyVersion)
	-- erase newline-chars in case user copied over incorrectly
	user = self:TextEraseNewline(user)
	password = self:TextEraseNewline(password)

	-- overwrite lobbyVersion by local function, since it´s not provided by caller right now or given as "Chobby"
	lobbyVersion = GetLobbyName()

	self:super("Login", user, password, cpu, localIP, lobbyVersion)
	if localIP == nil then
		localIP = "*"
	end

	if self.buffer then self.buffer = "" end 
	password = VFS.CalculateHash(password, 0)
	sentence = "LuaLobby " .. lobbyVersion .. "\t" .. self.agent .. "\t" .. "b sp"
	cmd = concat("LOGIN", user, password, "0", localIP, sentence)
	self:_SendCommand(cmd)
	return self
end

function Interface:Ping()
	self:super("Ping")
	self:_SendCommand("PING", true)
	return self
end

function Interface:ChangeEmailRequest(newEmail)
	self:_SendCommand(concat("CHANGEEMAILREQUEST", newEmail))
	return self
end

function Interface:ResetPassword(email, verificationCode)
	self:_SendCommand(concat("RESETPASSWORD", email, verificationCode))
	return self
end

function Interface:ResetPasswordRequest(email)
	self:_SendCommand(concat("RESETPASSWORDREQUEST",email))
	return self
end

function Interface:ChangePassword(oldPassword, newPassword)
	self:_SendCommand(concat("CHANGEPASSWORD", oldPassword, newPassword))
	return self
end

------------------------
-- User commands
------------------------

-- depricated, will be removed in near future
function Interface:FriendList()
	self:super("FriendList")
	-- self:_SendCommand("FRIENDLIST", true)
	return self
end

-- depricated, will be removed in near future
function Interface:FriendRequestList()
	self:super("FriendRequestList")
	-- self:_SendCommand("FRIENDREQUESTLIST", true)
	return self
end

-- depricated, will be removed in near future
function Interface:FriendRequest(userName)
	self:super("FriendRequest", userName)
	-- self:_SendCommand(concat("FRIENDREQUEST", "userName="..userName))
	return self
end

function Interface:FriendRequestByID(userID)
	self:super("FriendRequestByID", userID)
	self:_SendCommand(concat("c.user.add_friend", userID))
	return self
end

-- depricated, will be removed in near future
function Interface:AcceptFriendRequest(userName)
	self:super("AcceptFriendRequest", userName)
	-- self:_SendCommand(concat("ACCEPTFRIENDREQUEST", "userName="..userName))
	return self
end

function Interface:AcceptFriendRequestByID(userID)
	self:super("AcceptFriendRequestByID", userID)
	self:_SendCommand(concat("c.user.accept_friend_request", userID))
	return self
end

-- depricated, will be removed in near future
function Interface:DeclineFriendRequest(userName)
	self:super("DeclineFriendRequest", userName)
	-- self:_SendCommand(concat("DECLINEFRIENDREQUEST", "userName="..userName))
	return self
end

function Interface:DeclineFriendRequestByID(userID)
	self:super("DeclineFriendRequestByID", userID)
	self:_SendCommand(concat("c.user.decline_friend_request", userID))
	return self
end

-- can rescind multiple requests at once
function Interface:RescindFriendRequestByIDs(userIDs)
	self:super("RescindFriendRequestByIDs", userIDs)
	self:_SendCommand(concat("c.user.rescind_friend_request", table.concat(userIDs, "\t")))
	return self
end

-- depricated, will be removed in near future
function Interface:Unfriend(userName)
	self:super("Unfriend", userName)
	-- self:_SendCommand(concat("UNFRIEND", "userName="..userName))
	-- fake server response
	-- self:_OnUnfriend(userName)
	return self
end

function Interface:RemoveFriends(userIDs)
	self:super("RemoveFriends", userIDs)
	self:_SendCommand(concat("c.user.remove_friend", table.concat(userIDs, "\t")))
	return self
end

------------------------------------------------------------------------------------------------
-- Those Whois-commands are needed as long as we have a mixed protocol
-- Currently some depend on userName, newer ones already use userIDs
-- byar-chobby will ask for missing userID or userName depending on which info is known
------------------------------------------------------------------------------------------------

local whoisQueueActive = false
local whoisQueue = {}

function Interface:Whois(userID)
	local function SendWhois()
		local commandTxt = ""
		local currentQueueLength = #whoisQueue
		for i=1, currentQueueLength do
			if commandTxt ~= "" then
				commandTxt = commandTxt .. "\n"
			end
			commandTxt = commandTxt .. concat("c.user.whois", whoisQueue[i])
		end
		for i=1, currentQueueLength do
			table.remove(whoisQueue, 1)
		end
		self:_SendCommand(commandTxt)
		return self
	end

	local function ProcessWhoisQueue()
		if #whoisQueue == 0 then
			whoisQueueActive = false
			return self
		end

		SendWhois()
		WG.Delay(ProcessWhoisQueue, 0.4)
		return self
	end

	table.insert(whoisQueue, userID)
	if whoisQueueActive then
		return self
	end
	
	whoisQueueActive = true
	WG.Delay(ProcessWhoisQueue, 0.4)
	return self
end

function Interface:WhoisName(userName)
	self:_SendCommand(concat("c.user.whoisName", userName))
	return self
end

------------------------------------------------------------------------------------------------

function Interface:c_user_list_relationships()
	self:_SendCommand("c.user.list_relationships")
	return self
end

function Interface:c_user_relationship(userName, status)
	local Configuration = WG.Chobby.Configuration

	local statusName = Configuration:GetDisregardStatusName(status)
	-- use these commands instead until c.user.relationship is completly implemented at teiserver (currently it returns an incomplete answer)
	if status == Configuration.IGNORE then
		self:_SendCommand(concat("c.user.ignore", userName))
	elseif status == Configuration.AVOID then
		self:_SendCommand(concat("c.user.avoid", userName))
	elseif status == Configuration.BLOCK then
		self:_SendCommand(concat("c.user.block", userName))
	else
		Spring.Log(LOG_SECTION, LOG.ERROR, "Tried to send a non existing relationship change:", status)
	end
	return self
end

-- removes follows, ignores, avoids, and block
-- provisionally used to unignore sb. until unignore has a working dedicated command
function Interface:c_user_reset_relationship(userName)
	self:_SendCommand(concat("c.user.reset_relationship", userName))
	return self
end

------------------------
-- Battle commands
------------------------
local function UpdateAndCreateMerge(userData, status)
	local battleStatus = {}
	local updated = false
	if status.isReady ~= nil then
		updated = updated or userData.isReady ~= status.isReady
		battleStatus.isReady = status.isReady
	else
		battleStatus.isReady = userData.isReady
	end
	if status.teamNumber ~= nil then
		updated = updated or userData.teamNumber ~= status.teamNumber
		battleStatus.teamNumber = status.teamNumber
	else
		battleStatus.teamNumber = userData.teamNumber or 0
	end
	if status.teamColor ~= nil then
		if userData.teamColor == nil then
			updated = true
		else
			for i, v in ipairs(userData.teamColor) do
				if v ~= status.teamColor[i] then
					updated = true
				end
			end
		end
		battleStatus.teamColor = status.teamColor
	else
		battleStatus.teamColor = userData.teamColor
	end
	if status.allyNumber ~= nil then
		updated = updated or userData.allyNumber ~= status.allyNumber
		battleStatus.allyNumber = status.allyNumber
	else
		battleStatus.allyNumber = userData.allyNumber or 0
	end
	if status.isSpectator ~= nil then
		updated = updated or userData.isSpectator ~= status.isSpectator
		battleStatus.isSpectator = status.isSpectator
	else
		battleStatus.isSpectator = userData.isSpectator
	end
	if status.sync ~= nil then
		updated = updated or userData.sync ~= status.sync
		battleStatus.sync = status.sync
	else
		battleStatus.sync = userData.sync
	end
	if status.side ~= nil then
		updated = updated or userData.side ~= status.side
		battleStatus.side = status.side
	else
		battleStatus.side = userData.side or 0
	end

	return battleStatus, updated
end

--n = pow(2,i) -- where i = 0,31
--print('{',n//1000000,',', n%1000000,'},')
local bin2decmillion16 = { -- the <1M and >1M parts of 2^nth powers where n > 16
	{ 0 , 65536 }, --16
	{ 0 , 131072 }, --17
	{ 0 , 262144 }, --18
	{ 0 , 524288 }, --19
	{ 1 , 48576 },
	{ 2 , 97152 },
	{ 4 , 194304 },
	{ 8 , 388608 },
	{ 16 , 777216 }, --24
	{ 33 , 554432 }, --25
	{ 67 , 108864 }, --26
	{ 134 , 217728 }, --27
	{ 268 , 435456 }, --28
	{ 536 , 870912 },  --29
	{ 1073 , 741824 }, --30
	{ 2147 , 483648 }, -- 31
	}

-- Pre-computed bit masks for 16-bit loop (avoids 2^(b-1) exponentiation per iteration)
local _bitmask16 = {}
for _i = 1, 16 do _bitmask16[_i] = 2^(_i-1) end
local bit_and = math.bit_and
local math_floor = math.floor

-- Combine two 16 bit numbers into a string-formatted 32-bit integer
local function lsbmsb16tostring(lsb,msb)
	local aboveamillion = 0
	local belowamillion = lsb
	for b = 1, 16 do
		if bit_and(msb, _bitmask16[b]) > 0 then
			belowamillion = belowamillion + bin2decmillion16[b][2]
			if belowamillion >= 1000000 then
				aboveamillion = aboveamillion + math_floor(belowamillion/1000000)
				belowamillion = belowamillion % 1000000
			end
			aboveamillion = aboveamillion + bin2decmillion16[b][1]
		end
	end

	local statusstr = ""
	if aboveamillion == 0 then
		statusstr = ("%d"):format(belowamillion)
	else
		statusstr = ("%d%06d"):format(aboveamillion,belowamillion)
	end
	--if statusstr ~= tostring(lsb + 65536 * msb) then
	--	Spring.Echo("Possible integer overflow issues!",statusstr, lsb + 65536 * msb)
	--end
	return statusstr
end


local function EncodeBattleStatus(battleStatus)
	local playMode = 1
	if battleStatus.isSpectator then
		playMode = 0
	end

	if type(battleStatus.sync) ~= type(1) then --not integer type, e.g. nil or bool
		Spring.Log("Interface",LOG.WARNING,"Battle status sync state was set as non-integer!", battleStatus.sync)
		if battleStatus.sync == false then battleStatus.sync = 2
		else battleStatus.sync = 1 end
	end

	-- This nasty piece of code is because battlestatus can overflow the 24bits of float that Spring Lua supports:
	local lsb16 =
		(battleStatus.isReady and 2 or 0) +
		lshift(battleStatus.teamNumber % 16, 2) +
		lshift(battleStatus.allyNumber % 16, 6) +
		lshift(playMode, 10)

	local msb16 =
		math.floor((lshift(battleStatus.sync, 6) + --Because sync actually has 3 values, 0, 1, 2 (unknown, synced, unsynced)
		lshift(battleStatus.side, 8))) +
		lshift(rshift(battleStatus.teamNumber, 4), 2) + 
		lshift(rshift(battleStatus.allyNumber, 4), 12)

	return lsbmsb16tostring(lsb16, msb16)
end

local function EncodeTeamColor(teamColor)
	return math.bit_or(
		lshift(math.floor(teamColor[3] * 255), 16),
		lshift(math.floor(teamColor[2] * 255), 8),
		math.floor(teamColor[1] * 255)
	)
end

function Interface:RejoinBattle(battleID)
	local battle = self:GetBattle(battleID)
	if battle then
		self:ConnectToBattle(self.useSpringRestart, battle.ip, battle.port, nil, self:GetScriptPassword(), nil, nil, nil, nil, nil, battle.founder)
	end

	return self
end

-- 2023/04/04 Fireball: Added joinAsPlayer to bypass lastGameSpectatorState
function Interface:JoinBattle(battleID, password, scriptPassword, joinAsPlayer)
	if self.lastJoinTime then -- this is for safety on this lower level - ideally callers should take care of
		local timeDiff = spDiffTimers(spGetTimer(), self.lastJoinTime)
		if timeDiff < 1 then -- avoid more than 1 JOINBATTLE per second, e.g. double-clicking a battle (otherwise answers from teiserver can be confusing)
			return self
		end
	end
	self.lastJoinTime = spGetTimer()

	forcePlayer = joinAsPlayer and true or false -- used by Interfac:_OnRequestBattleStatus
	scriptPassword = scriptPassword or (tostring(math.floor(math.random() * 65536)) .. tostring(math.floor(math.random() * 65536)))
	password = password or "empty"
	self.changedTeamIDOnceAfterJoin = false
	self:super("JoinBattle", battleID, password, scriptPassword)
	self:_SendCommand(concat("JOINBATTLE", battleID, password, scriptPassword))
	return self
end

function Interface:LeaveBattle()
	self:super("LeaveBattle")
	self:_SendCommand("LEAVEBATTLE")
	return self
end

function Interface:SetBattleStatus(status, force)
	-- don't send while unbuffering (because it can lead to a lot of calls after a long game and spads spam protection kicks us)
	-- Instead SetBattleStatus is forced one-time directly when unbuffering finished (see Interface_shared - ProcessBuffer)
	if not self._requestedBattleStatus or self.commandBuffer then
		return
	end
	self:super("SetBattleStatus", status)

  -- FIXME: (or rather FIX UI code)
	-- This function is invoked too many times (before an answer gets received),
	-- so we're setting the values before
	-- they get confirmed from the server, otherwise we end up sending different info
	-- 2020/02/12: Problem partially fixed by ignoring battleStatus that result in no update
	-- 2021/01/21: Which had the unfortunate side effect of not sending the first REQUESTBATTLESTATUS response
	local myUserName = self:GetMyUserName()
	local userData = self.userBattleStatus[myUserName] or {}
	local battleStatus, updated = UpdateAndCreateMerge(userData, status)

	--next(status) will return nil if status is empty table, which it is when it is called from REQUESTBATTLESTATUS
	if not force and next(status) and not updated then
		return self
	end
	local battleStatusString = EncodeBattleStatus(battleStatus)

	local teamColor = battleStatus.teamColor or { math.random(), math.random(), math.random(), 1 }
	teamColor = EncodeTeamColor(teamColor)
	self:_SendCommand(concat("MYBATTLESTATUS", battleStatusString, teamColor))
	self:_OnUpdateUserBattleStatus(myUserName, battleStatus)
	return self
end

-- function Interface:JoinBattleAccept(userName)
-- 	self:super("JoinBattleAccept", userName)
-- 	self:_SendCommand(concat("JOINBATTLEACCEPT", userName))
-- 	return self
-- end
--
-- function Interface:JoinBattleDeny(userName, reason)
-- 	self:super("JoinBattleDeny", userName, reason)
-- 	self:_SendCommand(concat("JOINBATTLEDENY", userName, reason))
-- 	return self
-- end

function Interface:SayBattle(message)
	if (message:find("!") or message:find("$")) and message:find("\n") then
		for _, multiCommandPart in ipairs(ParseMultiCommandMessage(message)) do
			self:super("SayBattle", multiCommandPart):_SendCommand(concat("SAYBATTLE", multiCommandPart))
		end
	else
		self:super("SayBattle", message):_SendCommand(concat("SAYBATTLE", message))
	end
	
	-- Prevent crash for tweakdef referencing "legcomlvl" (NuttyB)
	if message:find("tweakdef") and message:find("bGVnY29tbHZsM") then
		self:SetModOptions({experimentallegionfaction = 1}):SayBattleEx("enabled legion faction since it is referenced in the tweakdef")
	end
	return self
end

function Interface:SayBattleEx(message)
	self:super("SayBattleEx", message)
	self:_SendCommand(concat("SAYBATTLEEX", message))
	return self
end

function Interface:SetModOptions(data)
	for k, v in pairs(data) do
		if self.modoptions[k] ~= v then
			self:SayBattle("!bSet " .. tostring(k) .. " " .. tostring(v))
		end
		-- self:_SendCommand("SETSCRIPTTAGS game/modoptions/" .. k .. '=' .. v)
	end
	return self
end

function Interface:AddAi(aiName, aiLib, allyNumber, version, aiOptions, battleStatusOptions)
	local userData = {
		isReady = true,
		teamNumber = self:GetUnusedTeamID(),
		allyNumber = allyNumber,
		playMode = true,
		sync = 1, -- (0 = unknown, 1 = synced, 2 = unsynced)
		side = 0,
	}

	local battleStatus, updated = UpdateAndCreateMerge(userData, battleStatusOptions or {})

	aiName = aiName:gsub(" ", "")
	local battleStatusString = EncodeBattleStatus(battleStatus)

	local teamColor = battleStatus.teamColor or { math.random(), math.random(), math.random(), 1}
	teamColor = EncodeTeamColor(teamColor)

	self:_SendCommand(concat("ADDBOT", aiName, battleStatusString, teamColor, aiLib))
	return self
end

function Interface:RemoveAi(name)
	self:_SendCommand(concat("REMOVEBOT", name))
	return self
end

function Interface:UpdateAi(aiName, status)
	local userData = self.userBattleStatus[aiName]

	local battleStatus, updated = UpdateAndCreateMerge(userData, status)
	if not updated then
		return self
	end
	local battleStatusString = EncodeBattleStatus(battleStatus)
	local teamColor = battleStatus.teamColor or { math.random(), math.random(), math.random(), 1 }
	teamColor = EncodeTeamColor(teamColor)
	self:_SendCommand(concat("UPDATEBOT", aiName, battleStatusString, teamColor))

	return self
end

-- Ugliness
function Interface:StartBattle()
	self:SayBattle("!cv start")
	return self
end

------------------------
-- Channel & private chat commands
------------------------

function Interface:Join(chanName, key)
	self:super("Join", chanName, key)
	if not self:GetInChannel(chanName) then
		self:_SendCommand(concat("JOIN", chanName, key))
	end
	return self
end

function Interface:Leave(chanName)
	self:super("Leave", chanName)
	self:_SendCommand(concat("LEAVE", chanName))
	return
end

function Interface:Say(chanName, message)
	self:super("Say", chanName, message)
	self:_SendCommand(concat("SAY", chanName, message))
	return self
end

function Interface:SayEx(chanName, message)
	self:super("SayEx", chanName, message)
	self:_SendCommand(concat("SAYEX", chanName, message))
	return self
end

function Interface:SayPrivate(userName, message)
	self:super("SayPrivate", userName, message)
	self:_SendCommand(concat("SAYPRIVATE", userName, message))
	return self
end

-------------------------------------------------
-- END Client commands
-------------------------------------------------

-------------------------------------------------
-- BEGIN Server commands
-------------------------------------------------

------------------------
-- Connectivity commands
------------------------

function Interface:_OnTASServer(protocolVersion, springVersion, udpPort, serverMode)
	self:_OnConnect(protocolVersion, springVersion, udpPort, serverMode)
end
Interface.commands["TASSERVER"] = Interface._OnTASServer
Interface.commandPattern["TASSERVER"] = "(%S+)%s+(%S+)%s+(%S+)%s+(%S+)"

function Interface:_OnMOTD(message)
	-- IGNORED
end
Interface.commands["MOTD"] = Interface._OnMOTD
Interface.commandPattern["MOTD"] = "([^\t]*)"

function Interface:_OnAccepted(newName)
	self:super("_OnAccepted", newName)
end
Interface.commands["ACCEPTED"] = Interface._OnAccepted
Interface.commandPattern["ACCEPTED"] = "(%S+)"

function Interface:_OnDenied(reason)
	self:super("_OnDenied", reason)
end
Interface.commands["DENIED"] = Interface._OnDenied
Interface.commandPattern["DENIED"] = "(.+)"

function Interface:_OnS_System_Disconnect(reason)
	self:_OnDisconnected(reason, false)
end
Interface.commands["s.system.disconnect"] = Interface._OnDenied
Interface.commandPattern["s.system.disconnect"] = "(.+)"

function Interface:_OnAgreement(line)
	self:super("_OnAgreement", line)
end
Interface.commands["AGREEMENT"] = Interface._OnAgreement
Interface.commandPattern["AGREEMENT"] = "(.*)"

function Interface:_OnAgreementEnd()
	self:super("_OnAgreementEnd")
end
Interface.commands["AGREEMENTEND"] = Interface._OnAgreementEnd

function Interface:_OnRegistrationAccepted()
	self:super("_OnRegistrationAccepted")
end
Interface.commands["REGISTRATIONACCEPTED"] = Interface._OnRegistrationAccepted

function Interface:_OnRegistrationDenied(reason)
	self:super("_OnRegistrationDenied", reason)
end
Interface.commands["REGISTRATIONDENIED"] = Interface._OnRegistrationDenied
Interface.commandPattern["REGISTRATIONDENIED"] = "([^\t]+)"

function Interface:_OnLoginInfoEnd()
	self:super("_OnLoginInfoEnd")
end
Interface.commands["LOGININFOEND"] = Interface._OnLoginInfoEnd

function Interface:_OnChangeEmailAccepted()
	self:super("_OnChangeEmailAccepted")
end
Interface.commands["CHANGEEMAILACCEPTED"] = Interface._OnChangeEmailAccepted

function Interface:_OnChangeEmailDenied(errorMsg)
	self:super("_OnChangeEmailDenied", errorMsg)
end
Interface.commands["CHANGEEMAILDENIED"] = Interface._OnChangeEmailDenied
Interface.commandPattern["CHANGEEMAILDENIED"] = "(%S+)"

function Interface:_OnChangeEmailRequestAccepted()
	self:super("_OnChangeEmailRequestAccepted")
end
Interface.commands["CHANGEEMAILREQUESTACCEPTED"] = Interface._OnChangeEmailRequestAccepted

function Interface:_OnChangeEmailRequestDenied(errorMsg)
	self:super("_OnChangeEmailRequestDenied", errorMsg)
end
Interface.commands["CHANGEEMAILREQUESTDENIED"] = Interface._OnChangeEmailRequestDenied
Interface.commandPattern["CHANGEEMAILREQUESTDENIED"] = "(%S+)"

function Interface:_OnResetPasswordAccepted()
	self:super("_OnResetPasswordAccepted")
end
Interface.commands["RESETPASSWORDACCEPTED"] = Interface._OnResetPasswordAccepted

function Interface:_OnResetPasswordDenied(errorMsg)
	self:super("_OnResetPasswordDenied", errorMsg)
end
Interface.commands["RESETPASSWORDDENIED"] = Interface._OnResetPasswordDenied
Interface.commandPattern["RESETPASSWORDDENIED"] = "(%S+)"

function Interface:_OnResetPasswordRequestAccepted()
	self:super("_OnResetPasswordRequestAccepted")
end
Interface.commands["RESETPASSWORDREQUESTACCEPTED"] = Interface._OnResetPasswordRequestAccepted

function Interface:_OnResetPasswordRequestDenied(errorMsg)
	self:super("_OnResetPasswordRequestDenied", errorMsg)
end
Interface.commands["RESETPASSWORDREQUESTDENIED"] = Interface._OnResetPasswordRequestDenied
Interface.commandPattern["RESETPASSWORDREQUESTDENIED"] = "(%S+)"

function Interface:_OnPong()
	self:super("_OnPong")
end
Interface.commands["PONG"] = Interface._OnPong

function Interface:_OnQueued()
	self:super("_OnQueued")
end
Interface.commands["QUEUED"] = Interface._OnQueued

------------------------
-- User commands
------------------------

------------------------------------------------------------------------------------------------
-- Those Whois-commands are needed as long as we have a mixed protocol
-- Currently some depend on userName, newer ones already use userIDs
-- byar-chobby will ask for missing userID or userName depending on which info is known
------------------------------------------------------------------------------------------------

function Interface:_OnWhois(id, data)
	id = tonumber(id)
	local userData = Json.decode(Spring.Utilities.Base64Decode(data))
	if userData and userData.error then
		Spring.Log(LOG_SECTION, LOG.ERROR, "_OnWhois error: " .. tostring(userData.error))
		return self
	end
	self:super("_OnWhois", id, userData)
end
Interface.commands["s.user.whois"] = Interface._OnWhois
Interface.commandPattern["s.user.whois"] = "(%d+)%s+(%S+)"

function Interface:_OnWhoisName(userName, data)
	local userData = Json.decode(Spring.Utilities.Base64Decode(data))
	self:super("_OnWhoisName", userName, userData)
end
Interface.commands["s.user.whoisName"] = Interface._OnWhoisName
Interface.commandPattern["s.user.whoisName"] = "(%S+)%s+(%S+)"

------------------------------------------------------------------------------------------------

function Interface:_OnAddUser(userName, country, accountID, lobbyID)
	local userTable = {
		-- constant
		accountID = tonumber(accountID),
		lobbyID = lobbyID,
		-- persistent
		country = country,
		--cpu = tonumber(cpu),
	}
	self:super("_OnAddUser", userName, userTable)
end
Interface.commands["ADDUSER"] = Interface._OnAddUser
Interface.commandPattern["ADDUSER"] = "(%S+)%s+(%S+)%s+(%S+)%s*(.*)"

function Interface:_OnRemoveUser(userName)
	for channelName, _ in pairs(self:GetChannels()) do
		self:_OnLeft(channelName, userName, "")
	end
	self:super("_OnRemoveUser", userName)
end
Interface.commands["REMOVEUSER"] = Interface._OnRemoveUser
Interface.commandPattern["REMOVEUSER"] = "(%S+)"

function Interface:_OnClientStatus(userName, status)
	status = {
		isInGame = (status%2 == 1),
		isAway = (status%4 >= 2),
		isAdmin = rshift(status, 5) % 2 == 1,
		isBot = rshift(status, 6) % 2 == 1,

		-- level is rank in Spring terminology
		level = rshift(status, 2) % 8 + 1,
	}
	self:_OnUpdateUserStatus(userName, status)

	if status.isInGame ~= nil then
		local battleID = self:GetBattleFoundedBy(userName)
		if battleID then
			self:_OnBattleIngameUpdate(battleID, status.isInGame)
		end
		if self.myBattleID and status.isInGame then
			local myBattle = self:GetBattle(self.myBattleID)
			local myBattleStatus = self.userBattleStatus[self.myUserName]
			if myBattle and myBattle.founder == userName and not (Spring.GetGameName() ~= "" and myBattleStatus.isSpectator) and not self.commandBuffer and (not myBattleStatus.isSpectator or WG.Chobby.Configuration.autoLaunchAsSpectator) then
				local battle = self:GetBattle(self.myBattleID)
				self:ConnectToBattle(self.useSpringRestart, battle.ip, battle.port, nil, self:GetScriptPassword(), nil, nil, nil, nil, nil, battle.founder)
			end
		end
	end
end
Interface.commands["CLIENTSTATUS"] = Interface._OnClientStatus
Interface.commandPattern["CLIENTSTATUS"] = "(%S+)%s+(%S+)"

------------------------------------------------------------------------------------------------
-- friends
------------------------------------------------------------------------------------------------

-- depricated, will be removed in near future
-- NB: added the _Uber suffix so not to conflict with Lobby:_OnFriend
function Interface:_OnFriend_Uber(tags)
	local tags = parseTags(tags)
	local userName = getTag(tags, "userName", true)
	-- self:_OnFriend(userName)
end
Interface.commands["FRIEND"] = Interface._OnFriend_Uber
Interface.commandPattern["FRIEND"] = "(.+)"

function Interface:_OnOutgoingFriendRequestByID(userID, answer)
	userID = tonumber(userID)
	if answer and answer ~= "success" then
		Spring.Log(LOG_SECTION, LOG.WARNING, "error on acknowlege for friend addition. userID=" .. tostring(userID) .. " server message:" .. tostring(answer))
		return
	end
	self:super("_OnOutgoingFriendRequestByID", userID)
end
Interface.commands["s.user.add_friend"] = Interface._OnOutgoingFriendRequestByID
Interface.commandPattern["s.user.add_friend"] = "(%d+)%s+(%S+)"

-- depricated, will be removed in near future
-- NB: added the _Uber suffix so not to conflict with Lobby:_OnUnfriend
function Interface:_OnUnfriend_Uber(tags)
	local tags = parseTags(tags)
	local userName = getTag(tags, "userName", true)
	-- self:_OnUnfriend(userName)
end
Interface.commands["UNFRIEND"] = Interface._OnUnfriend_Uber
Interface.commandPattern["UNFRIEND"] = "(.+)"

function Interface:_OnUnfriendByID(userID, answer)
	userID = tonumber(userID)
	if answer and answer ~= "success" then
		Spring.Log(LOG_SECTION, LOG.WARNING, "error on acknowlege for friend remove. userID=" .. tostring(userID) .. " server message:" .. tostring(answer))
		return
	end
	self:super("_OnUnfriendByID", userID)
end
Interface.commands["s.user.remove_friend"] = Interface._OnUnfriendByID
Interface.commandPattern["s.user.remove_friend"] = "(%d+)%s+(%S+)"


function Interface:_OnFriendDeletedByID(userID)
	userID = tonumber(userID)
	self:_OnUnfriendByID(userID)
end
Interface.commands["s.user.friend_deleted"] = Interface._OnFriendDeletedByID
Interface.commandPattern["s.user.friend_deleted"] = "(%d+)"

-- depricated, will be removed in near future
function Interface:_OnFriendList(tags)
	local tags = parseTags(tags)
	local userName = getTag(tags, "userName", true)
	if not self._friendList then
		Spring.Log(LOG_SECTION, LOG.ERROR, "Received FRIENDLIST command without preceding FRIENDLISTBEGIN")
		self._friendList = {}
	end
	table.insert(self._friendList, userName)
end
Interface.commands["FRIENDLIST"] = Interface._OnFriendList
Interface.commandPattern["FRIENDLIST"] = "(.+)"

-- depricated, will be removed in near future
function Interface:_OnFriendListBegin()
	self._friendList = {}
end
Interface.commands["FRIENDLISTBEGIN"] = Interface._OnFriendListBegin

-- depricated, will be removed in near future
function Interface:_OnFriendListEnd()
	-- self:super("_OnFriendList", self._friendList)
	self._friendList = nil
end
Interface.commands["FRIENDLISTEND"] = Interface._OnFriendListEnd

------------------------------------------------------------------------------------------------
-- friend requests
------------------------------------------------------------------------------------------------

-- depricated, will be removed in near future
-- function Interface:_OnFriendRequest(tags)
-- 	local tags = parseTags(tags)
-- 	local userName = getTag(tags, "userName", true)
-- 	self:super("_OnFriendRequest", userName)
-- end
-- Interface.commands["FRIENDREQUEST"] = Interface._OnFriendRequest
-- Interface.commandPattern["FRIENDREQUEST"] = "(.+)"

-- depricated, will be removed in near future
function Interface:_OnFriendRequestList(tags)
	local tags = parseTags(tags)
	local userName = getTag(tags, "userName", true)
	table.insert(self._friendRequestList, userName)
end
Interface.commands["FRIENDREQUESTLIST"] = Interface._OnFriendRequestList
Interface.commandPattern["FRIENDREQUESTLIST"] = "(.+)"

-- depricated, will be removed in near future
function Interface:_OnFriendRequestListBegin()
	self._friendRequestList = {}
end
Interface.commands["FRIENDREQUESTLISTBEGIN"] = Interface._OnFriendRequestListBegin

-- depricated, will be removed in near future
function Interface:_OnFriendRequestListEnd()
	-- self:super("_OnFriendRequestList", self._friendRequestList)
	self._friendRequestList = {}
end
Interface.commands["FRIENDREQUESTLISTEND"] = Interface._OnFriendRequestListEnd

------------------------
-- Battle commands
------------------------
local msbLsb10 = { -- stores a table of each power of 10 as the 16 bit top and bottom halfs
    { 0 , 1 },
    { 0 , 10 },
    { 0 , 100 },
    { 0 , 1000 },
    { 0 , 10000 },
    { 1 , 34464 },
    { 15 , 16960 },
    { 152 , 38528 },
    { 1525 , 57600 },
    { 15258 , 51712 },
}

-- splits a string-encoded 32bit unsigned integer into 16bit LSB and 16bit MSB
local function split16(bigNumStr)
    local lsb = 0
    local msb = 0
    for i=1, string.len(bigNumStr) do -- for each character of the big number string
        local digit = string.len(bigNumStr)- i + 1 -- start with last character first
        local n = tonumber(string.sub(bigNumStr,digit,digit)) -- get the current character
        for k = 1, n do  -- for each number value of current character
            lsb = lsb + msbLsb10[i][2] -- add the 16bit LSB of 10*i'th power
            if lsb >= 65536 then -- if it overflows LSB, increment MSB
                lsb = lsb - 65536
                msb = msb + 1
            end
            msb = msb + msbLsb10[i][1] -- add the 16 bit MSB of 10*i'th power
        end
    end
    return lsb, msb
end

function Interface:ParseBattleStatus(battleStatus)
	local lsb, msb = split16(battleStatus)
	return {
		isReady      = rshift(lsb, 1) % 2 == 1,
		teamNumber   = (lshift(rshift(msb, 2) % 16, 4) +  rshift(lsb, 2) % 16),
		allyNumber   = (lshift(rshift(msb, 12) % 16, 4) +  rshift(lsb, 6) % 16),
		isSpectator  = rshift(lsb, 10) % 2 == 0,
		handicap     = (lshift(msb, 5) + rshift(lsb, 11) ) % 128,
		sync         = rshift(msb, 6) % 4,
		side         = rshift(msb, 8) % 16,
	}
end

local function ParseTeamColor(teamColor)
	return {
		(teamColor % 256) / 255,
		(rshift(teamColor, 8) % 256) / 255,
		(rshift(teamColor, 16) % 256) / 255,
		1
	}
end

-- mapHash (32bit) will remain a string, since spring lua uses floats (24bit mantissa)
function Interface:_OnBattleOpened(battleID, type, natType, founder, ip, port, maxPlayers, passworded, rank, mapHash, other)
	local engineName, engineVersion, map, title, gameName = unpack(explode("\t", other))

	self:super("_OnBattleOpened", tonumber(battleID), {
		founder = founder,
		users = {founder}, -- initial users

		ip = ip,
		port = tonumber(port),

		maxPlayers = tonumber(maxPlayers),
		passworded = tonumber(passworded) ~= 0,

		engineName = engineName,
		engineVersion = engineVersion,
		mapName = map,
		title = title,
		gameName = gameName,

		spectatorCount = 1, -- To handle the founder joining as a spec
		--playerCount = 0, -- to handle the founder joining as a spec
		isRunning = (self.users[founder] and self.users[founder].isInGame) or false,

		-- Spring stuff
		-- unsupported
		--type = tonumber(type)
		--natType = tonumber(natType)
	})
	self:_OnJoinedBattle(battleID, founder, "") -- so that the founder joins the battle as a spectato
end
Interface.commands["BATTLEOPENED"] = Interface._OnBattleOpened
Interface.commandPattern["BATTLEOPENED"] = "(%d+)%s+(%d)%s+(%d)%s+(%S+)%s+(%S+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%S+)%s+(%S+)%s*(.*)"

function Interface:_OnBattleClosed(battleID)
	battleID = tonumber(battleID)
	self:super("_OnBattleClosed", battleID)
end
Interface.commands["BATTLECLOSED"] = Interface._OnBattleClosed
Interface.commandPattern["BATTLECLOSED"] = "(%d+)"

-- hashCode will be a string due to lua limitations
function Interface:_OnJoinBattle(battleID, hashCode)
	self._requestedBattleStatus = nil
	battleID = tonumber(battleID)
	self:super("_OnJoinBattle", battleID, hashCode)
	self.lastJoinTime = nil
end
Interface.commands["JOINBATTLE"] = Interface._OnJoinBattle
Interface.commandPattern["JOINBATTLE"] = "(%d+)%s+(%S+)"

function Interface:_OnJoinedBattle(battleID, userName, scriptPassword)
	battleID = tonumber(battleID)
	if userName == self.myUserName then
		self.scriptPassword = scriptPassword
	end
	self:super("_OnJoinedBattle", battleID, userName, scriptPassword)
end
Interface.commands["JOINEDBATTLE"] = Interface._OnJoinedBattle
Interface.commandPattern["JOINEDBATTLE"] = "(%d+)%s+(%S+)%s*(%S*)"

-- TODO: Missing _OnBattleScriptPassword

function Interface:_OnLeftBattle(battleID, userName)
	battleID = tonumber(battleID)
	self:super("_OnLeftBattle", battleID, userName)
end
Interface.commands["LEFTBATTLE"] = Interface._OnLeftBattle
Interface.commandPattern["LEFTBATTLE"] = "(%d+)%s+(%S+)"

function Interface:_OnUpdateBattleInfo(battleID, spectatorCount, locked, mapHash, mapName)
	battleID = tonumber(battleID)

	local battleInfo = {
		locked = (locked == "1"),
		mapName = mapName,
		spectatorCount = tonumber(spectatorCount)
	}

	self:super("_OnUpdateBattleInfo", battleID, battleInfo)
end
Interface.commands["UPDATEBATTLEINFO"] = Interface._OnUpdateBattleInfo
Interface.commandPattern["UPDATEBATTLEINFO"] = "(%d+)%s+(%S+)%s+(%S+)%s+(%S+)%s+([^\t]+)"

function Interface:_OnClientBattleStatus(userName, battleStatus, teamColor)
	local status = self:ParseBattleStatus(battleStatus)
	status.teamColor = ParseTeamColor(teamColor)

	local userInfo = self.users[userName]
	if userInfo and (not userInfo.battleID or userInfo.battleID ~= self:GetMyBattleID()) then
		Spring.Log(LOG_SECTION, LOG.WARNING, "Can't update user's battle status, user is not in our battle:  ", userName)
		return
	end

	self:_OnUpdateUserBattleStatus(userName, status)
	if userName == self.myUserName then
		self:_EnsureMyTeamNumberIsUnique()
	end
end
Interface.commands["CLIENTBATTLESTATUS"] = Interface._OnClientBattleStatus
Interface.commandPattern["CLIENTBATTLESTATUS"] = "(%S+)%s+(%S+)%s+(%S+)"

function Interface:_EnsureMyTeamNumberIsUnique()
	local myBattleStatus = self.userBattleStatus[self.myUserName]
	if myBattleStatus == nil then
		return
	end

	if myBattleStatus.isSpectator then
		return
	end

	if self.changedTeamIDOnceAfterJoin then
		return
	end

	for name, data in pairs(self.userBattleStatus) do
		if name ~= self.myUserName and data.teamNumber == myBattleStatus.teamNumber and not data.isSpectator then
			-- need to change teamID so it's unique
			self.changedTeamIDOnceAfterJoin = true
			self:SetBattleStatus({
				teamNumber = self:GetUnusedTeamID()
			})
			break
		end
	end
end

function Interface:_OnAddBot(battleID, name, owner, battleStatus, teamColor, aiDll)
	battleID = tonumber(battleID)
	local status = self:ParseBattleStatus(battleStatus)
	status.teamColor = ParseTeamColor(teamColor)
	-- local ai, dll = unpack(explode("\t", aiDll)))
	status.aiLib = aiDll
	status.owner = owner
	self:_OnAddAi(battleID, name, status)
end
Interface.commands["ADDBOT"] = Interface._OnAddBot
Interface.commandPattern["ADDBOT"] = "(%d+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(.*)"

function Interface:_OnRemoveBot(battleID, name)
	battleID = tonumber(battleID)
	self:_OnRemoveAi(battleID, name)
end
Interface.commands["REMOVEBOT"] = Interface._OnRemoveBot
Interface.commandPattern["REMOVEBOT"] = "(%d+)%s+(%S+)"

function Interface:_OnUpdateBot(battleID, name, battleStatus, teamColor)
	battleID = tonumber(battleID)
	local status = self:ParseBattleStatus(battleStatus)
	status.teamColor = ParseTeamColor(teamColor)
	local knownBattleAI = table.ifind(self.battleAis, name)
	if not knownBattleAI then
		Spring.Log(LOG_SECTION, LOG.ERROR, string.format("Tried to update unknown bot:%s in battle:%s", name, battleID))
		return
	end
	status.owner = self.userBattleStatus[name] and self.userBattleStatus[name].owner
	self:_OnUpdateUserBattleStatus(name, status)
end
Interface.commands["UPDATEBOT"] = Interface._OnUpdateBot
Interface.commandPattern["UPDATEBOT"] = "(%d+)%s+(%S+)%s+(%S+)%s+(%S+)"

local function testEncodeDecode()
	Spring.Log(LOG_SECTION, LOG.NOTICE, "Starting testEncodeDecode")
	local error = false
	local bStatus = {}
	local retBStatus = {}
	for isReady=0, 1, 1 do
		for side=0, 2, 1 do
			for isSpectator =0, 1, 1 do
				for sync=0, 2, 1 do
					for teamNumber=15, 17, 1 do -- dont go for all 256 iterations, see below
						for allyNumber=15, 17, 1 do
							bStatus.isReady = isReady == 1 and true or false
							bStatus.teamNumber = teamNumber
							bStatus.allyNumber = allyNumber
							bStatus.isSpectator = isSpectator == 1 and true or false
							bStatus.sync = sync
							bStatus.side = side
							bStatusStr = EncodeBattleStatus(bStatus)
							retBStatus = WG.LibLobby.lobby:ParseBattleStatus(bStatusStr)
							if	retBStatus.isReady ~= bStatus.isReady or
								retBStatus.teamNumber ~= bStatus.teamNumber or
								retBStatus.allyNumber ~= bStatus.allyNumber or
								retBStatus.isSpectator ~= bStatus.isSpectator or
								retBStatus.sync ~= bStatus.sync or
								retBStatus.side ~= bStatus.side then
								error = true
								Spring.Log(LOG_SECTION, LOG.NOTICE,
									bStatus.isReady,
									bStatus.teamNumber, 
									bStatus.allyNumber, 
									bStatus.isSpectator,
									bStatus.sync,
									bStatus.side)
								Spring.Log(LOG_SECTION, LOG.NOTICE,
									retBStatus.isReady,
									retBStatus.teamNumber, 
									retBStatus.allyNumber, 
									retBStatus.isSpectator,
									retBStatus.sync,
									retBStatus.side)
							end
						end
					end
				end
			end
		end
	end

	-- iterate once over all possible allyNumbers
	for allyNumber=0, 255, 1 do
		bStatus.allyNumber = allyNumber
		bStatusStr = EncodeBattleStatus(bStatus)
		retBStatus = WG.LibLobby.lobby:ParseBattleStatus(bStatusStr)
		if	retBStatus.allyNumber ~= bStatus.allyNumber then
			error = true
			Spring.Log(LOG_SECTION, LOG.NOTICE, bStatus.allyNumber)
			Spring.Log(LOG_SECTION, LOG.NOTICE, retBStatus.allyNumber)
		end
	end

	-- iterate once over all possible teamNumbers
	for teamNumber=0, 255, 1 do 
		bStatus.teamNumber = teamNumber
		bStatusStr = EncodeBattleStatus(bStatus)
		retBStatus = WG.LibLobby.lobby:ParseBattleStatus(bStatusStr)
		if	retBStatus.teamNumber ~= bStatus.teamNumber then
			error = true
			Spring.Log(LOG_SECTION, LOG.NOTICE, bStatus.teamNumber)
			Spring.Log(LOG_SECTION, LOG.NOTICE, retBStatus.teamNumber)
		end
	end
	Spring.Log(LOG_SECTION, LOG.NOTICE, "Finished testEncodeDecode, found Errors: ", error)
end

function Interface:_OnSaidBattle(userName, message)
	if (message == "?test EncodeBattleStatus") then
		testEncodeDecode()
	end
	self:super("_OnSaidBattle", userName, message)
end
Interface.commands["SAIDBATTLE"] = Interface._OnSaidBattle
Interface.commandPattern["SAIDBATTLE"] = "(%S+)%s+(.*)"

function Interface:_OnSaidBattleEx(userName, message)
	if startsWith(message, WG.Chobby.Configuration.BTLEX_JOINQUEUE) then
		self:_SendCommand(concat("c.battle.queue_status")) -- request the whole join-queue again, because server doesn´t always send s.battle.queue_status or sends it before the change took affect
		return
	end
	self:super("_OnSaidBattleEx", userName, message)
end
Interface.commands["SAIDBATTLEEX"] = Interface._OnSaidBattleEx
Interface.commandPattern["SAIDBATTLEEX"] = "(%S+)%s+(.*)"

------------------------
-- Channel & private chat commands
------------------------

function Interface:_OnJoin(chanName)
	self:super("_OnJoin", chanName)
end
Interface.commands["JOIN"] = Interface._OnJoin
Interface.commandPattern["JOIN"] = "(%S+)"

function Interface:_OnJoined(chanName, userName)
	self:super("_OnJoined", chanName, userName)
end
Interface.commands["JOINED"] = Interface._OnJoined
Interface.commandPattern["JOINED"] = "(%S+)%s+(%S+)"

function Interface:_OnJoinFailed(chanName, reason)
	self:super("_OnJoinFailed", chanName, reason)
end
Interface.commands["JOINFAILED"] = Interface._OnJoinFailed
Interface.commandPattern["JOINFAILED"] = "(%S+)%s+(.*)" -- fix regex to match official protocol

function Interface:_OnLeft(chanName, userName, reason)
	self:super("_OnLeft", chanName, userName, reason)
end
Interface.commands["LEFT"] = Interface._OnLeft
Interface.commandPattern["LEFT"] = "(%S+)%s+(%S+)%s*([^\t]*)"

function Interface:_OnClients(chanName, clientsStr)
	local clients = explode(" ", clientsStr)
	self:super("_OnClients", chanName, clients)
end
Interface.commands["CLIENTS"] = Interface._OnClients
Interface.commandPattern["CLIENTS"] = "(%S+)%s+(.+)"

function Interface:_OnChannel(chanName, userCount, topic)
	userCount = tonumber(userCount)
	self:super("_OnChannel", chanName, userCount, topic)
end
Interface.commands["CHANNEL"] = Interface._OnChannel
Interface.commandPattern["CHANNEL"] = "(%S+)%s+(%d+)%s*(.*)"

function Interface:_OnEndOfChannels()
	self:_CallListeners("OnEndOfChannels")
end
Interface.commands["ENDOFCHANNELS"] = Interface._OnEndOfChannels

function Interface:_OnChannelMessage(chanName, message)
	self:super("_OnChannelMessage", chanName, message)
end
Interface.commands["CHANNELMESSAGE"] = Interface._OnChannelMessage
Interface.commandPattern["CHANNELMESSAGE"] = "(%S+)%s+(%S+)"

function Interface:_OnChannelTopic(chanName, author, topic)
	topic = topic and tostring(topic) or ""
	self:super("_OnChannelTopic", chanName, author, 0, topic)
end
Interface.commands["CHANNELTOPIC"] = Interface._OnChannelTopic
Interface.commandPattern["CHANNELTOPIC"] = "(%S+)%s+(%S+)%s*(.*)"

function Interface:_OnSaid(chanName, userName, message)
	self:super("_OnSaid", chanName, userName, message)
end
Interface.commands["SAID"] = Interface._OnSaid
Interface.commandPattern["SAID"] = "(%S+)%s+(%S+)%s+(.*)"

function Interface:_OnSaidEx(chanName, userName, message)
	self:super("_OnSaidEx", chanName, userName, message)
end
Interface.commands["SAIDEX"] = Interface._OnSaidEx
Interface.commandPattern["SAIDEX"] = "(%S+)%s+(%S+)%s+(.*)"

function Interface:_OnSaidPrivate(userName, message)
	self:super("_OnSaidPrivate", userName, message)
end
Interface.commands["SAIDPRIVATE"] = Interface._OnSaidPrivate
Interface.commandPattern["SAIDPRIVATE"] = "(%S+)%s+(.*)"

function Interface:_OnSaidPrivateEx(userName, message)
	self:super("_OnSaidPrivateEx", userName, message)
end
Interface.commands["SAIDPRIVATEEX"] = Interface._OnSaidPrivateEx
Interface.commandPattern["SAIDPRIVATEEX"] = "(%S+)%s+(.*)"

function Interface:_OnSayPrivate(userName, message)
	self:super("_OnSayPrivate", userName, message)
end
Interface.commands["SAYPRIVATE"] = Interface._OnSayPrivate
Interface.commandPattern["SAYPRIVATE"] = "(%S+)%s+(.*)"

------------
------------
-- LEGACY - QUEUE/MATCHMAKING
------------
------------

--[[
function Interface:CloseQueue(name)
	self:_SendCommand(concat("CLOSEQUEUE", Json.encode(name)))
	return self
end
--]]

function Interface:ConnectUser(userName, ip, port, engine, scriptPassword)
	self:_SendCommand(concat("CONNECTUSER", Json.encode({userName=userName, ip=ip, port=port, engine=engine, scriptPassword=scriptPassword})))
	return self
end

function Interface:InviteTeam(userName)
	self:_SendCommand(concat("INVITETEAM", Json.encode({userName=userName})))
	return self
end

function Interface:InviteTeamAccept(userName)
	self:_SendCommand(concat("INVITETEAMACCEPT", Json.encode({userName=userName})))
	return self
end

function Interface:InviteTeamDecline(userName)
	self:_SendCommand(concat("INVITETEAMDECLINE", Json.encode({userName=userName})))
	return self
end

function Interface:JoinQueue(name, params)
	local tbl = {name=name}
	if params ~= nil then
		tbl["params"] = params
	end
	self:_SendCommand(concat("JOINQUEUE", Json.encode(tbl)))
	return self
end

function Interface:JoinQueueAccept(name, userNames)
	self:_SendCommand(concat("JOINQUEUEACCEPT", Json.encode({name=name,userNames=userNames})))
	return self
end

function Interface:JoinQueueDeny(name, userNames, reason)
	self:_SendCommand(concat("JOINQUEUEDENY", Json.encode({name=name,userNames=userNames,reason=reason})))
	return self
end

function Interface:KickFromTeam(userName)
	self:_SendCommand(concat("KICKFROMTEAM", Json.encode({userName=userName})))
	return self
end

function Interface:LeaveTeam()
	self:_SendCommand("LEAVETEAM")
	return self
end

function Interface:LeaveQueue(name)
	self:_SendCommand(concat("LEAVEQUEUE", Json.encode({name=name})))
	return self
end

function Interface:ListQueues()
	self:_SendCommand("LISTQUEUES")
	return self
end

function Interface:ReadyCheck(name, userNames, responseTime)
	self:_SendCommand(concat("READYCHECK", Json.encode({name=name, userNames=userNames, responseTime=responseTime})))
	return self
end

function Interface:ReadyCheckResponse(name, response, responseTime)
	local response = {name=name, response=response}
	if responseTime ~= nil then
		response.responseTime = responseTime
	end
	self:_SendCommand(concat("READYCHECKRESPONSE", Json.encode(response)))
	return self
end

function Interface:RemoveQueueUser(name, userNames)
	self:_SendCommand(concat("REMOVEQUEUEUSER", {name=name, userNames=userNames}))
	return self
end

-- parse following servermessage:
-- s.battle.queue_status\s<battleID>\t<userName1>\t<userName2>...
function Interface:_OnSBattleQueueStatus(battleID, userNamesChain)
	-- Spring.Echo("_OnSBattleQueueStatus battleID:"..battleID.." userNamesChain:"..userNamesChain, "type of battleID", type(battleID))

	-- validate battleID
	battleID = tonumber(battleID)
	if not self:GetMyBattleID() or self:GetMyBattleID() ~= battleID then
		Spring.Log(LOG_SECTION, LOG.WARNING, "Received s.battle.queue_status with battleID for another battle: ", tostring(battleID))
		return
	end

	local queuedUserNames = {}
	if userNamesChain ~= "" then -- because our explode returns a table with 1 element when join-queue is empty
		queuedUserNames = explode("\t", userNamesChain)
	end

	self:_OnUpdateBattleQueue(battleID, queuedUserNames) -- always update, empty queue must be propagated too
end
Interface.commands["s.battle.queue_status"] = Interface._OnSBattleQueueStatus
Interface.commandPattern["s.battle.queue_status"] = "(%d+)%s*(.*)" -- * on %s because the part right of %d can be total empty for an empty queue

------------
------------
-- TODO
------------
------------


function Interface:AddStartRect(allyNo, left, top, right, bottom)
	self:_SendCommand(concat("ADDSTARTRECT", allyNo, left, top, right, bottom))
	return self
end

function Interface:ChangeEmail(newEmail, userName)
	self:_SendCommand(concat("CHANGEEMAIL", newEmail, userName))
	return self
end


function Interface:_OnChangeEmailRequestDenied(errorMsg)
	self:super("_OnChangeEmailRequestDenied", errorMsg)
end
Interface.commands["CHANGEEMAILREQUESTDENIED"] = Interface._OnChangeEmailRequestDenied
Interface.commandPattern["CHANGEEMAILREQUESTDENIED"] = "(.+)"

function Interface:_OnChangeEmailRequestAccepted()
	self:super("_OnChangeEmailRequestAccepted")
end
Interface.commands["CHANGEEMAILREQUESTACCEPTED"] = Interface._OnChangeEmailRequestAccepted

function Interface:_OnChangeEmailDenied(errorMsg)
	self:super("_OnChangeEmailDenied", errorMsg)
end
Interface.commands["CHANGEEMAILDENIED"] = Interface._OnChangeEmailDenied
Interface.commandPattern["CHANGEEMAILDENIED"] = "(.+)"

function Interface:_OnChangeEmailAccepted()
	self:super("_OnChangeEmailAccepted")
end
Interface.commands["CHANGEEMAILACCEPTED"] = Interface._OnChangeEmailAccepted

function Interface:ChangeEmailRequest(newEmail)
	self:_SendCommand(concat("CHANGEEMAILREQUEST", newEmail))
	return self
end

function Interface:ResetPassword(email, verificationCode)
	self:_SendCommand(concat("RESETPASSWORD", email, verificationCode))
	return self
end

function Interface:_OnResetPasswordAccepted()
	self:super("_OnResetPasswordAccepted")
end
Interface.commands["RESETPASSWORDACCEPTED"] = Interface._OnResetPasswordAccepted

function Interface:_OnResetPasswordDenied(errorMsg)
	self:super("_OnResetPasswordDenied", errorMsg)
end
Interface.commands["RESETPASSWORDDENIED"] = Interface._OnResetPasswordDenied
Interface.commandPattern["RESETPASSWORDDENIED"] = "(.+)"

function Interface:ResetPasswordRequest(email)
	self:_SendCommand(concat("RESETPASSWORDREQUEST",email))
	return self
end
function Interface:_OnResetPasswordRequestAccepted()
	self:super("_OnResetPasswordRequestAccepted")
end
Interface.commands["RESETPASSWORDREQUESTACCEPTED"] = Interface._OnResetPasswordRequestAccepted

function Interface:_OnResetPasswordRequestDenied(errorMsg)
	self:super("_OnResetPasswordRequestDenied", errorMsg)
end
Interface.commands["RESETPASSWORDREQUESTDENIED"] = Interface._OnResetPasswordRequestDenied
Interface.commandPattern["RESETPASSWORDREQUESTDENIED"] = "(.+)"

function Interface:ChangePassword(oldPassword, newPassword)
	self:_SendCommand(concat("CHANGEPASSWORD", oldPassword, newPassword))
	return self
end

function Interface:Channels()
	self:_SendCommand("CHANNELS")
	return self
end

function Interface:ChannelTopic(chanName, topic)
	self:_SendCommand(concat("CHANNELTOPIC", chanName, topic))
	return self
end

function Interface:ConfirmAgreement(verificationCode)
	self:_SendCommand(concat("CONFIRMAGREEMENT", verificationCode))
	return self
end

function Interface:DisableUnits(...)
	self:_SendCommand(concat("DISABLEUNITS", ...))
	return self
end

function Interface:EnableAllUnits()
	self:_SendCommand("ENABLEALLUNITS")
	return self
end

function Interface:EnableUnits(...)
	self:_SendCommand(concat("ENABLEUNITS", ...))
	return self
end

function Interface:Exit(reason)
	-- should this could be set _after_ server has disconnected us?
	self.status = "offline"
	self.finishedConnecting = false
	self:_SendCommand(concat("EXIT", reason))
	return self
end

function Interface:ForceAllyNo(userName, teamNo)
	self:_SendCommand(concat("FORCEALLYNO", userName, teamNo))
	return self
end

function Interface:ForceSpectatorMode(userName)
	self:_SendCommand(concat("FORCESPECTATORMODE", userName))
	return self
end

function Interface:ForceTeamColor(userName, color)
	self:_SendCommand(concat("FORCETEAMCOLOR", userName, color))
	return self
end

function Interface:ForceTeamNo(userName, teamNo)
	self:_SendCommand(concat("FORCETEAMNO", userName, teamNo))
	return self
end

function Interface:GetInGameTime()
	self:_SendCommand("GETINGAMETIME")
	return self
end

function Interface:Handicap(userName, value)
	self:_SendCommand(concat("HANDICAP", userName, value))
	return self
end

function Interface:KickFromBattle(userName)
	self:_SendCommand(concat("KICKFROMBATTLE", userName))
	return self
end


function Interface:ListCompFlags()
	self:_SendCommand("LISTCOMPFLAGS")
	return self
end

function Interface:MuteList(chanName)
	self:_SendCommand(concat("MUTELIST", chanName))
	return self
end

function Interface:MyStatus(status)
	self:_SendCommand(concat("MYSTATUS", status))
	return self
end

function Interface:OpenBattle(type, natType, password, port, maxPlayers, gameHash, rank, mapHash, engineName, engineVersion, map, title, gameName)
	self:_SendCommand(concat("OPENBATTLE", type, natType, password, port, maxPlayers, gameHash, rank, mapHash, engineName, "\t", engineVersion, "\t", map, "\t", title, "\t", gameName))
	return self
end

function Interface:OpenQueue(queue)
	self:_SendCommand(concat("OPENQUEUE", Json.encode({queue=queue})))
	return self
end

function Interface:RecoverAccount(email, userName)
	self:_SendCommand(concat("RECOVERACCOUNT", email, userName))
	return self
end

function Interface:RemoveScriptTags(...)
	self:_SendCommand(concat("REMOVESCRIPTTAGS", ...))
	return self
end

function Interface:RemoveStartRect(allyNo)
	self:_SendCommand(concat("REMOVESTARTRECT", allyNo))
	return self
end

function Interface:RenameAccount(newUsername)
	self:_SendCommand(concat("RENAMEACCOUNT", newUsername))
	return self
end

function Interface:Ring(userName)
	self:_SendCommand(concat("RING", userName))
	return self
end

-- function Interface:SayData(chanName, message)
-- 	self:_SendCommand(concat("SAYDATA", chanName, message))
-- 	return self
-- end
--
-- function Interface:SayDataBattle(message)
-- 	self:_SendCommand(concat("SAYDATABATTLE", message))
-- 	return self
-- end
--
-- function Interface:SayDataPrivate(userName, message)
-- 	self:_SendCommand(concat("SAYDATAPRIVATE", userName, message))
-- 	return self
-- end

function Interface:SayTeam(msg)
	self:_SendCommand(concat("SAYTEAM", Json.encode({msg=msg})))
	return self
end

function Interface:SayTeamEx(msg)
	self:_SendCommand(concat("SAYTEAMEX", Json.encode({msg=msg})))
	return self
end

function Interface:Script(line)
	self:_SendCommand(concat("SCRIPT", line))
	return self
end

function Interface:ScriptEnd()
	self:_SendCommand("SCRIPTEND")
	return self
end

function Interface:ScriptStart()
	self:_SendCommand("SCRIPTSTART")
	return self
end

function Interface:SetScriptTags(...)
	self:_SendCommand(concat("SETSCRIPTTAGS", ...))
	return self
end

function Interface:SetTeamLeader(userName)
	self:_SendCommand(concat("SETTEAMLEADER", Json.encode({userName=userName})))
	return self
end

function Interface:TestLogin(userName, password)
	self:_SendCommand(concat("TESTLOGIN", userName, password))
	return self
end

function Interface:UpdateBattleInfo(spectatorCount, locked, mapHash, mapName)
	self:_SendCommand(concat("UPDATEBATTLEINFO", spectatorCount, locked, mapHash, mapName))
	return self
end

--TODO: should also send a respond with USERID
function Interface:_OnAcquireUserID()
	self:_CallListeners("OnAcquireUserID", username)
end
Interface.commands["ACQUIREUSERID"] = Interface._OnAcquireUserID

function Interface:_OnAddStartRect(allyNo, left, top, right, bottom)
	self:_CallListeners("OnAddStartRect", allyNo, left, top, right, bottom)
end
Interface.commands["ADDSTARTRECT"] = Interface._OnAddStartRect
Interface.commandPattern["ADDSTARTRECT"] = "(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)"

function Interface:_OnBroadcast(message)
	self:_CallListeners("OnBroadcast", message)
end
Interface.commands["BROADCAST"] = Interface._OnBroadcast
Interface.commandPattern["BROADCAST"] = "(.+)"

function Interface:_OnClientIpPort(userName, ip, port)
	self:_CallListeners("OnClientIpPort", userName, ip, port)
end
Interface.commands["CLIENTIPPORT"] = Interface._OnClientIpPort
Interface.commandPattern["CLIENTIPPORT"] = "(%S+)%s+(%S+)%s+(%S+)"

function Interface:_OnCompFlags(compFlags)
	compFlags = explode(" ", compFlags)
	self:_CallListeners("OnCompFlags", compFlags)
end
Interface.commands["COMPFLAGS"] = Interface._OnCompFlags
Interface.commandPattern["COMPFLAGS"] = "(.*)"

function Interface:_OnConnectUser(obj)
	self:_CallListeners("OnConnectUser", obj.ip, obj.port, obj.engine, obj.password)
end
Interface.jsonCommands["CONNECTUSER"] = Interface._OnConnectUser

function Interface:_OnConnectUserFailed(obj)
	self:_CallListeners("OnConnectUserFailed", obj.userName, obj.reason)
end
Interface.jsonCommands["CONNECTUSERFAILED"] = Interface._OnConnectUserFailed

function Interface:_OnDisableUnits(unitNames)
	unitNames = explode(" ", unitNames)
	self:_CallListeners("OnDisableUnits", unitNames)
end
Interface.commands["DISABLEUNITS"] = Interface._OnDisableUnits
Interface.commandPattern["DISABLEUNITS"] = "(.+)"

function Interface:_OnEnableAllUnits()
	self:_CallListeners("OnEnableAllUnits")
end
Interface.commands["ENABLEALLUNITS"] = Interface._OnEnableAllUnits

function Interface:_OnEnableUnits(unitNames)
	unitNames = explode(" ", unitNames)
	self:_CallListeners("OnEnableUnits", unitNames)
end
Interface.commands["ENABLEUNITS"] = Interface._OnEnableUnits
Interface.commandPattern["ENABLEUNITS"] = "(.+)"

function Interface:_OnForceJoinBattle(destinationBattleID, destinationBattlePassword)
	destinationBattleID = tonumber(destinationBattleID)
	self:_CallListeners("OnForceJoinBattle", destinationBattleID, destinationBattlePassword)
end
Interface.commands["FORCEJOINBATTLE"] = Interface._OnForceJoinBattle
Interface.commandPattern["FORCEJOINBATTLE"] = "(%d+)%s*(%S*)"

function Interface:_OnForceJoinBattleFailed(userName, reason)
	self:_CallListeners("OnForceJoinBattleFailed", userName, reason)
end
Interface.commands["FORCEJOINBATTLEFAILED"] = Interface._OnForceJoinBattleFailed
Interface.commandPattern["FORCEJOINBATTLEFAILED"] = "(%S+)%s*([^\t]*)"

function Interface:_OnForceLeaveChannel(chanName, userName, reason)
	self:_CallListeners("OnForceLeaveChannel", chanName, userName, reason)
end
Interface.commands["FORCELEAVECHANNEL"] = Interface._OnForceLeaveChannel
Interface.commandPattern["FORCELEAVECHANNEL"] = "(%S+)%s+(%S+)%s*([^\t]*)"

function Interface:_OnForceQuitBattle()
	self:_CallListeners("OnForceQuitBattle")
end
Interface.commands["FORCEQUITBATTLE"] = Interface._OnForceQuitBattle

function Interface:_OnHostPort(port)
	port = tonumber(port)
	self:_CallListeners("OnHostPort", port)
end
Interface.commands["HOSTPORT"] = Interface._OnHostPort
Interface.commandPattern["HOSTPORT"] = "(%d+)"

function Interface:_OnJoinBattleFailed(reason)
	self:_CallListeners("OnJoinBattleFailed", reason)
	self.lastJoinTime = nil
end
Interface.commands["JOINBATTLEFAILED"] = Interface._OnJoinBattleFailed
Interface.commandPattern["JOINBATTLEFAILED"] = "([^\t]+)"

function Interface:_OnJoinBattleRequest(userName, ip)
	self:_CallListeners("OnJoinBattleRequest", userName, ip)
end
Interface.commands["JOINBATTLEREQUEST"] = Interface._OnJoinBattleRequest
Interface.commandPattern["JOINBATTLEREQUEST"] = "(%S+)%s+(%S+)"

function Interface:_OnJoinQueue(obj)
	local name = obj.name
	self:_CallListeners("OnJoinQueue", name)
end
Interface.jsonCommands["JOINQUEUE"] = Interface._OnJoinQueue

function Interface:_OnJoinQueueRequest(obj)
	local name = obj.name
	local userNames = obj.userNames
	local params = obj.params
	self:_CallListeners("OnJoinQueueRequest", name, userNames, params)
end
Interface.jsonCommands["JOINQUEUEREQUEST"] = Interface._OnJoinQueueRequest

function Interface:_OnJoinedQueue(obj)
	local name = obj.name
	local userNames = obj.userNames
	local params = obj.params
	self:_CallListeners("OnJoinedQueue", name, userNames, params)
end
Interface.jsonCommands["JOINEDQUEUE"] = Interface._OnJoinedQueue

function Interface:_OnJoinQueueFailed(obj)
	local name = obj.name
	local reason = obj.reason
	self:_CallListeners("OnJoinQueueFailed", name, reason)
end
Interface.jsonCommands["JOINQUEUEFAILED"] = Interface._OnJoinQueueFailed

function Interface:_OnJoinTeam(obj)
	local userNames = obj.userNames
	local leader = obj.leader
	self:_CallListeners("OnJoinTeam", userNames, leader)
end
Interface.jsonCommands["JOINTEAM"] = Interface._OnJoinTeam

function Interface:_OnJoinedTeam(obj)
	local userName = obj.userName
	self:_CallListeners("OnJoinedTeam", userName)
end
Interface.jsonCommands["JOINEDTEAM"] = Interface._OnJoinedTeam

function Interface:_OnLeftQueue(obj)
	self:_CallListeners("OnLeftQueue", obj.name, obj.reason)
end
Interface.jsonCommands["LEFTQUEUE"] = Interface._OnLeftQueue

function Interface:_OnLeftTeam(obj)
	local userName = obj.userName
	local reason = obj.reason
	self:_CallListeners("OnLeftTeam", userName, reason)
end
Interface.jsonCommands["LEFTTEAM"] = Interface._OnLeftTeam

function Interface:_OnMuteList(muteDescription)
	self:_CallListeners("OnMuteList", muteDescription)
end
Interface.commands["MUTELIST"] = Interface._OnMuteList
Interface.commandPattern["MUTELIST"] = "([^\t]*)"

function Interface:_OnMuteListBegin(chanName)
	self:_CallListeners("OnMuteListBegin", chanName)
end
Interface.commands["MUTELISTBEGIN"] = Interface._OnMuteListBegin
Interface.commandPattern["MUTELISTBEGIN"] = "(%S+)"

function Interface:_OnMuteListEnd()
	self:_CallListeners("OnMuteListEnd")
end
Interface.commands["MUTELISTEND"] = Interface._OnMuteListEnd

function Interface:_OnOpenBattle(battleID)
	battleID = tonumber(battleID)
	self:_CallListeners("OnOpenBattle", battleID)
end
Interface.commands["OPENBATTLE"] = Interface._OnOpenBattle
Interface.commandPattern["OPENBATTLE"] = "(%d+)"

function Interface:_OnOpenBattleFailed(reason)
	self:_CallListeners("OnOpenBattleReason", reason)
end
Interface.commands["OPENBATTLEFAILED"] = Interface._OnOpenBattleFailed
Interface.commandPattern["OPENBATTLEFAILED"] = "([^\t]+)"

--[[ ZK only
function Interface:_QueueOpened(obj)
	self:_OnQueueOpened(obj.name, obj.title, obj.mapNames, nil, obj.gameNames)
end
Interface.jsonCommands["QUEUEOPENED"] = Interface._QueueOpened

function Interface:_QueueClosed(obj)
	self:_OnQueueClosed(obj.name)
end
Interface.jsonCommands["QUEUECLOSED"] = Interface._QueueClosed

function Interface:_OnQueueLeft(obj)
	self:_CallListeners("OnQueueLeft", obj.name, obj.userNames)
end
Interface.jsonCommands["QUEUELEFT"] = Interface._OnQueueLeft
--]]
function Interface:_OnReadyCheck(obj)
	self:_CallListeners("OnReadyCheck", obj.name, obj.responseTime)
end
Interface.jsonCommands["READYCHECK"] = Interface._OnReadyCheck

function Interface:_OnReadyCheckResult(obj)
	self:_CallListeners("OnReadyCheckResult", obj.name, obj.result)
end
Interface.jsonCommands["READYCHECKRESULT"] = Interface._OnReadyCheckResult

function Interface:_OnReadyCheckResponse(obj)
	self:_CallListeners("OnReadyCheckResponse", obj.name, obj.userName, obj.answer, obj.responseTime)
end
Interface.jsonCommands["READYCHECKRESPONSE"] = Interface._OnReadyCheckResponse

function Interface:_OnRedirect(ip)
	self:_CallListeners("OnRedirect", ip)
end
Interface.commands["REDIRECT"] = Interface._OnRedirect
Interface.commandPattern["REDIRECT"] = "(%S+)"

function Interface:_OnRemoveScriptTags(keys)
	keys = explode(" ", keys)
	self:_CallListeners("OnRemoveScriptTags", keys)
end
Interface.commands["REMOVESCRIPTTAGS"] = Interface._OnRemoveScriptTags
Interface.commandPattern["REMOVESCRIPTTAGS"] = "([^\t]+)"

function Interface:_OnRemoveStartRect(allyNo)
	allyNo = tonumber(allyNo)
	self:_CallListeners("OnRemoveStartRect", allyNo)
end
Interface.commands["REMOVESTARTRECT"] = Interface._OnRemoveStartRect
Interface.commandPattern["REMOVESTARTRECT"] = "(%d+)"

function getSyncStatus(battle)
	if not battle then
		return 0
	end

	local haveGame = VFS.HasArchive(battle.gameName)
	local haveMap = VFS.HasArchive(battle.mapName)
	-- Spring.Echo("haveGame, haveMap", haveGame, haveMap)
	return (haveGame and haveMap) and 1 or 2 -- 1: Sync 2: Unsync
end

-- 2023/03/23 Fireball: This request is sent once by the server, directly after hosting or joining a battle
--                      since we do not have any battleStatus(in most cases), we generate a default one
function Interface:_OnRequestBattleStatus()
	-- 2023/03/06 Fireball: moved the action from the only listener to OnRequestBattleStatus in whole chobby from gui_battle_room_window.lua to here
	--                      and don´t call listeners of OnRequestBattleStatus anymore
	self._requestedBattleStatus = true -- allow SetBattleStatus again

	local defaultSpec = true
	if forcePlayer then -- 2023/04/04 Fireball: forcePlayer is set by Interface:JoinBattle; the only use case is forcing player while hosting a battle	
		defaultSpec = false
		forcePlayer = false -- 2023/04/04 set it to false after usage
	else
		defaultSpec = WG.Chobby.Configuration.lastGameSpectatorState 
	end

	self:SetBattleStatus({
		isSpectator = defaultSpec,
		isReady = false,
		side = (WG.Chobby.Configuration.lastFactionChoice or 0) ,
		sync = getSyncStatus(self:GetBattle(self:GetMyBattleID())),
	})
end
Interface.commands["REQUESTBATTLESTATUS"] = Interface._OnRequestBattleStatus

-- 2024-06-06 FB: Ring is bypassed during command buffering. So we make sure, that ingameNotifications is on before playing the sound
function Interface:_OnRing(userName)
	local Configuration = WG.Chobby.Configuration
	if self.bufferCommandsEnabled and not Configuration.ingameNotifcations then
		return
	end
	self:_CallListeners("OnRing", userName)
end
Interface.commands["RING"] = Interface._OnRing
Interface.commandPattern["RING"] = "(%S+)"

-- function Interface:_OnSaidData(chanName, userName, message)
-- 	self:_CallListeners("OnSaidData", chanName, userName, message)
-- end
-- Interface.commands["SAIDDATA"] = Interface._OnSaidData
-- Interface.commandPattern["SAIDDATA"] = "(%S+)%s+(%S+)%s+(.*)"
--
-- function Interface:_OnSaidDataBattle(userName, message)
-- 	self:_CallListeners("OnSaidDataBattle", userName, message)
-- end
-- Interface.commands["SAIDDATABATTLE"] = Interface._OnSaidDataBattle
-- Interface.commandPattern["SAIDDATABATTLE"] = "(%S+)%s+(.*)"
--
-- function Interface:_OnSaidDataPrivate(userName, message)
-- 	self:_CallListeners("OnSaidDataPrivate", userName, message)
-- end
-- Interface.commands["SAIDDATAPRIVATE"] = Interface._OnSaidDataPrivate
-- Interface.commandPattern["SAIDDATAPRIVATE"] = "(%S+)%s+(.*)"

function Interface:_OnSaidTeam(obj)
	local userName = obj.userName
	local msg = obj.msg
	self:_CallListeners("OnSaidTeam", userName, msg)
end
Interface.jsonCommands["SAIDTEAM"] = Interface._OnSaidTeam

function Interface:_OnSaidTeamEx(obj)
	local userName = obj.userName
	local msg = obj.msg
	self:_CallListeners("OnSaidTeamEx", userName, msg)
end
Interface.jsonCommands["SAIDTEAMEX"] = Interface._OnSaidTeamEx

-- function Interface:_OnScript(line)
-- 	self:_CallListeners("OnScript", line)
-- end
-- Interface.commands["SCRIPT"] = Interface._OnScript
-- Interface.commandPattern["SCRIPT"] = "([^\t]+)"
--
-- function Interface:_OnScriptEnd()
-- 	self:_CallListeners("OnScriptEnd")
-- end
-- Interface.commands["SCRIPTEND"] = Interface._OnScriptEnd
--
-- function Interface:_OnScriptStart()
-- 	self:_CallListeners("OnScriptStart")
-- end
-- Interface.commands["SCRIPTSTART"] = Interface._OnScriptStart

function Interface:_OnServerMSG(message)
	self:_CallListeners("OnServerMSG", message)
end
Interface.commands["SERVERMSG"] = Interface._OnServerMSG
Interface.commandPattern["SERVERMSG"] = "([^\t]+)"

function Interface:_OnServerMSGBox(message, url)
	self:_CallListeners("OnServerMSG", message, url)
end
Interface.commands["SERVERMSGBOX"] = Interface._OnServerMSGBox
Interface.commandPattern["SERVERMSGBOX"] = "([^\t]+)\t+([^\t]+)"

-- l = "(" or ""
-- p = "[" or ""
-- d = "#" or ""
local function parseSkillOrigin(l, p, d)
	if l == "("              then return "Rank" end
	if p == "[" and d == ""  then return "Plugin" end
	if p == "[" and d == "#" then return "Plugin_Degraded" end
	if              d == ""  then return "SLDB" end
	if              d == "#" then return "SLDB_Degraded" end
	return "Unknown" -- to make function clean, shouldn't be possible
  end

-- interpret following scripttags
-- playername/skilluncertainty=2
-- playername/skill=<skillformat>
-- skillformat , skillOrigin
-- 1. (6)     , Lobby Rank
-- 2. 6.34    , SLDB
-- 3. #6.34#  , SLDB_Degraded
-- 4. [6.34]  , Plugin
-- 5. [#6.34#], Plugin_Degraded
-- Note: playername is delivered in lower case by protocol rules, see https://springrts.com/dl/LobbyProtocol/ProtocolDescription.html#SETSCRIPTTAGS:client
function Interface:ParseSkillFormat(skillParam)
	return string.match(skillParam, "(%(?)(%[?)(#?)(-?%d+%.?%d*)") -- ignore closings ")", "#", "]"
end

function Interface:GetSkillFromScriptTag(tag)
	local userNameLC, skillKey, skillParam = string.match(tag, "(.+)/(.+)=(.+)")
	if userNameLC == "" or skillKey == "" then
		Spring.Log(LOG_SECTION, LOG.WARNING, "Could not parse scriptTag player/[..]", tag)
		return
	end

	local l, p, d, value = self:ParseSkillFormat(skillParam)
	if value == "" then
		Spring.Log(LOG_SECTION, LOG.WARNING, "Could not parse player/"..skillKey.."/[..]", skillParam)
		return
	end

	local status = {}
	if (skillKey == "skill") then
		status["skillOrigin"] = parseSkillOrigin(l,p,d)
		status["skill"]       = tostring(value) --stay with string, tonumber would change the value in spring lua i.e 10.23 -> 10.229999...
	elseif (skillKey == "skilluncertainty") then
		status["skillUncertainty"] = tostring(value) -- without tostring, we get [number] for value 1 and [string] for value 3, which is strange
	else
		Spring.Log(LOG_SECTION, LOG.NOTICE, "unsupported setScriptTags playerKey:", skillKey)
		return
	end

	return userNameLC, status
end

local function string_starts(String, Start)
	return string.sub(String, 1, string.len(Start)) == Start
end

local mod_opts_pre = "game/modoptions/"
local mod_opts_pre_indx = #mod_opts_pre + 1
local scriptTagPlayers = "game/players/"
local scriptTagPlayersIndx = #scriptTagPlayers + 1
function Interface:_OnSetScriptTags(tagsTxt)
	local tags = explode("\t", tagsTxt)
	if self.modoptions == nil then
		self.modoptions = {}
	end
	for _, tag in pairs(tags) do
		if string_starts(tag, mod_opts_pre) then
			local kv = tag:sub(mod_opts_pre_indx)
			local kvTable = explode("=", kv)
			local k = kvTable[1]
			local v = kvTable[2]
			self.modoptions[k] = v
		elseif string_starts(tag, scriptTagPlayers) then
			local userNameLC, status = self:GetSkillFromScriptTag(tag:sub(scriptTagPlayersIndx))
			local userName = self:GetLowerCaseUser(userNameLC) --lobby:FindBattleUserByLowerCase
			if (userName == nil) or (status == nil) then
				Spring.Log(LOG_SECTION, LOG.WARNING, "Could not parse tag " .. tag)
			else
				self:_OnUpdateUserStatus(userName, status)
			end
		end
	end
	self:_OnSetModOptions(self.modoptions)
end
Interface.commands["SETSCRIPTTAGS"] = Interface._OnSetScriptTags
Interface.commandPattern["SETSCRIPTTAGS"] = "(.*)"
-- Interface.commandPattern["SETSCRIPTTAGS"] = "([^\t]+)"

function Interface:_OnSetTeamLeader(obj)
	local userName = obj.userName
	self:_CallListeners("OnSetTeamLeader", userName)
end
Interface.jsonCommands["SETTEAMLEADER"] = Interface._OnSetTeamLeader

function Interface:_OnTestLoginAccept(message)
	self:_CallListeners("OnTestLoginAccept", message)
end
Interface.commands["TESTLOGINACCEPT"] = Interface._OnTestLoginAccept

function Interface:_OnTestLoginDeny(message)
	self:_CallListeners("OnTestLoginDeny", message)
end
Interface.commands["TESTLOGINDENY"] = Interface._OnTestLoginDeny

function Interface:_OnUDPSourcePort(port)
	port = tonumber(port)
	self:_CallListeners("OnUDPSourcePort", port)
end
Interface.commands["UDPSOURCEPORT"] = Interface._OnUDPSourcePort
Interface.commandPattern["UDPSOURCEPORT"] = "(%d+)"

local function buildDisregardListID(ignores, avoids, blocks)
	local Configuration = WG.Chobby.Configuration
	local disregardListID = {}
	for _, userID in ipairs(blocks) do
		table.insert(disregardListID, {userID = userID, status = Configuration.BLOCK})
	end

	for _, userID in ipairs(avoids) do
		if not table.ifindByKey(disregardListID, userID, "userID") then
			table.insert(disregardListID, {userID = userID, status = Configuration.AVOID})
		end
	end

	for _, userID in ipairs(ignores) do
		if not table.ifindByKey(disregardListID, userID, "userID") then
			table.insert(disregardListID, {userID = userID, status = Configuration.IGNORE})
		end
	end
	return disregardListID
end

function Interface:_On_s_user_list_relationships(data)
	local relationships = Json.decode(Spring.Utilities.Base64Decode(data))

	if not (relationships and relationships.friends and
							  relationships.follows and
							  relationships.ignores and
							  relationships.avoids and
							  relationships.blocks and
							  relationships.incoming_friend_requests and
							  relationships.outgoing_friend_requests) then
		Spring.Log(LOG_SECTION, LOG.ERROR, "missing keys or json could not be parsed in s.user.list_relationships" )
		Spring.Utilities.TableEcho(relationships, "relationships")
		return
	end

	self:_OnFriendListByID(relationships.friends)
	self:_OnFriendRequestListByID(relationships.incoming_friend_requests)
	self:_OnOutgoingFriendRequestsByID(relationships.outgoing_friend_requests)
	self:_OnDisregardListID(buildDisregardListID(relationships.ignores, relationships.avoids, relationships.blocks))
	
	-- ToDo: relationships.follows > waits until completly implemented at teiserver
end
Interface.commands["s.user.list_relationships"] = Interface._On_s_user_list_relationships
Interface.commandPattern["s.user.list_relationships"] = "(.+)"

-- OK cmd=c.user.block	userName=Fireball
function Interface:_OnOK(tags)
	local Configuration = WG.Chobby.Configuration
	local tags = parseTags(tags)
	local cmd = getTag(tags, "cmd", false)

	if not cmd then
		Spring.Log(LOG_SECTION, LOG.WARNING, "Received OK command with wrong format.")
	end

	for index, commandInfo in ipairs(self.commandsAwaitingResponse) do
		if commandInfo.cmd == cmd then
			if commandInfo.successCallback then
				commandInfo.successCallback(tags)
			end
			table.remove(self.commandsAwaitingResponse, index)
			return
		end
	end

	local userName = getTag(tags, "userName", false)
	if not userName then
		Spring.Log(LOG_SECTION, LOG.WARNING, "Received OK command with wrong format.")
	end

	if cmd == 'c.user.ignore' then
		self:_OnDisregard(userName, Configuration.IGNORE)
	elseif cmd == 'c.user.avoid' then
		self:_OnDisregard(userName, Configuration.AVOID)
	elseif cmd == 'c.user.block' then
		self:_OnDisregard(userName, Configuration.BLOCK)
	elseif cmd == 'c.user.reset_relationship' then
		self:_OnUnDisregard(userName)
		-- resets follows too: this waits until completly implemented at teiserver
	else
		Spring.Log(LOG_SECTION, LOG.WARNING, "Unknown OK received for command", cmd)
	end
end
Interface.commands["OK"] = Interface._OnOK
Interface.commandPattern["OK"] = "(.+)"

function Interface:_OnNo(tags)
	local tags = parseTags(tags)
	local cmd = getTag(tags, "cmd", false) or "unknown"

	for index, commandInfo in ipairs(self.commandsAwaitingResponse) do
		if commandInfo.cmd == cmd then
			if commandInfo.errorCallback then
				commandInfo.errorCallback(tags)
			end
			table.remove(self.commandsAwaitingResponse, index)
			return
		end
	end

	local userName = getTag(tags, "userName", false) or "unknown"
	Spring.Log(LOG_SECTION, LOG.ERROR, string.format("Server answered NO to command=%s and userName=%s", cmd, userName))
end
Interface.commands["NO"] = Interface._OnNo
Interface.commandPattern["NO"] = "(.+)"

function Interface:_On_s_user_new_incoming_friend_request(userID)
	userID = tonumber(userID)
	self:_OnFriendRequestByID(userID, true)
end
Interface.commands["s.user.new_incoming_friend_request"] = Interface._On_s_user_new_incoming_friend_request
Interface.commandPattern["s.user.new_incoming_friend_request"] = "(%d+)"

function Interface:_On_s_user_accept_friend_request(userID, answer)
	userID = tonumber(userID)
	if answer ~= "success" then
		Spring.Log(LOG_SECTION, LOG.WARNING, "error on acknowlege for friend request. userID=" .. tostring(userID) .. " server message:" .. tostring(answer))
		return
	end
	self:_OnAcceptFriendRequestByID(userID)
end
Interface.commands["s.user.accept_friend_request"] = Interface._On_s_user_accept_friend_request
Interface.commandPattern["s.user.accept_friend_request"] = "(%d+)%s+(%S+)"

function Interface:_On_s_user_decline_friend_request(userID, answer)
	userID = tonumber(userID)
	if answer ~= "success" then
		Spring.Log(LOG_SECTION, LOG.WARNING, "error on acknowlege for friend request. userID=" .. tostring(userID) .. " server message:" .. tostring(answer))
		return
	end
	self:_OnDeclineFriendRequestByID(userID)
end
Interface.commands["s.user.decline_friend_request"] = Interface._On_s_user_decline_friend_request
Interface.commandPattern["s.user.decline_friend_request"] = "(%d+)%s+(%S+)"

function Interface:_On_s_user_rescind_friend_request(userID, answer)
	userID = tonumber(userID)
	if answer ~= "success" then
		Spring.Log(LOG_SECTION, LOG.WARNING, "error on acknowlege for friend rescind. userID=" .. tostring(userID) .. " server message:" .. tostring(answer))
		return
	end
	self:_OnRescindFriendRequestByID(userID)
end
Interface.commands["s.user.rescind_friend_request"] = Interface._On_s_user_rescind_friend_request
Interface.commandPattern["s.user.rescind_friend_request"] = "(%d+)%s+(%S+)"

function Interface:_On_s_user_friend_request_rescinded(userID)
	userID = tonumber(userID)
	self:_OnRemoveFriendRequestByID(userID)
end
Interface.commands["s.user.friend_request_rescinded"] = Interface._On_s_user_friend_request_rescinded
Interface.commandPattern["s.user.friend_request_rescinded"] = "(%d+)"

function Interface:_OnFriendRequestAcceptedByID(userID)
	userID = tonumber(userID)
	self:super("_OnFriendRequestAcceptedByID", userID)

end
Interface.commands["s.user.friend_request_accepted"] = Interface._OnFriendRequestAcceptedByID
Interface.commandPattern["s.user.friend_request_accepted"] = "(%d+)"

function Interface:_OnFriendRequestDeclinedByID(userID)
	userID = tonumber(userID)
	self:super("_OnFriendRequestDeclinedByID", userID)

end
Interface.commands["s.user.friend_request_declined"] = Interface._OnFriendRequestDeclinedByID
Interface.commandPattern["s.user.friend_request_declined"] = "(%d+)"



function Interface:_OnInviteTeam(obj)
	self:_CallListeners("OnInviteTeam", obj.userName)
end
Interface.jsonCommands["INVITETEAM"] = Interface._OnInviteTeam

function Interface:_OnInviteTeamAccepted(obj)
	self:_CallListeners("OnInviteTeamAccepted", obj.userName)
end
Interface.jsonCommands["INVITETEAMACCEPTED"] = Interface._OnInviteTeamAccepted

function Interface:_OnInviteTeamDeclined(obj)
	self:_CallListeners("OnInviteTeamDeclined", obj.userName, obj.reason)
end
Interface.jsonCommands["INVITETEAMDECLINED"] = Interface._OnInviteTeamDeclined

function Interface:_OnListQueues(queues)
	self.queueCount = 0
	self.queues = {}
	for _, queue in pairs(queues) do
		self:_OnQueueOpened(obj.name, obj.title, obj.mapNames, nil, obj.gameNames)
	end
end
Interface.jsonCommands["LISTQUEUES"] = Interface._OnListQueues

-- Teiserver Tachyon commands for BAR:

function Interface:_OnUpdateBattleTitle(battleID, battleTitle)
	self:super("_OnUpdateBattleTitle", tonumber(battleID), battleTitle)
end
Interface.commands["s.battle.update_lobby_title"] = Interface._OnUpdateBattleTitle
Interface.commandPattern["s.battle.update_lobby_title"] = "(%S+)%s+(.*)"

function Interface:_OnBattleExtraData(battleID, data)
	-- do nothing for now, but suppress errors in log
end
Interface.commands["s.battle.extra_data"] = Interface._OnBattleExtraData
Interface.commandPattern["s.battle.extra_data"] = "(%S+)%s+(.*)"

-- Handle s.battle.teams messages
function Interface:_OnBattleTeams(data)
	local teamsData = Json.decode(Spring.Utilities.Base64Decode(data))
	if not teamsData then
		Spring.Log(LOG_SECTION, LOG.ERROR, "Failed to parse s.battle.teams data: " .. tostring(data))
		return
	end
	
	-- Update each battle with its team data
	for battleID, teamInfo in pairs(teamsData) do
		battleID = tonumber(battleID)
		if battleID then
			self:super("_OnUpdateBattleInfo", battleID, {
				teamSize = teamInfo.teamSize,
				nbTeams = teamInfo.nbTeams
			})
		end
	end
end
Interface.commands["s.battle.teams"] = Interface._OnBattleTeams
Interface.commandPattern["s.battle.teams"] = "(.+)"

function Interface:_OnS_Client_Errorlog()
	self:_CallListeners("OnS_Client_Errorlog")
end

Interface.commands["s.client.errorlog"] = Interface._OnS_Client_Errorlog
--Interface.commandPattern["s.client.errorlog"] = "(%S+)"

return Interface
