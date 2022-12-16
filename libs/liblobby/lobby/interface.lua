-- Official SpringRTS Lobby protocol implementation
-- http://springrts.com/dl/LobbyProtocol/

VFS.Include(LIB_LOBBY_DIRNAME .. "json.lua")
VFS.Include(LIB_LOBBY_DIRNAME .. "interface_shared.lua")

-- map lobby commands by name
Interface.commands = {}
-- map json lobby commands by name
Interface.jsonCommands = {}
-- define command format with pattern (regex)
Interface.commandPattern = {}

-------------------------------------------------
-- BEGIN Client commands
-------------------------------------------------

------------------------
-- Connectivity commands
------------------------

function Interface:Register(userName, password, email)
	self:super("Register", userName, password, email)
	password = VFS.CalculateHash(password, 0)
	self:_SendCommand(concat("REGISTER", userName, password, email))
	return self
end

function Interface:Login(user, password, cpu, localIP, lobbyVersion)
	self:super("Login", user, password, cpu, localIP, lobbyVersion)
	if localIP == nil then
		localIP = "*"
	end
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

function Interface:FriendList()
	self:super("FriendList")
	self:_SendCommand("FRIENDLIST", true)
	return self
end

function Interface:FriendRequestList()
	self:super("FriendRequestList")
	self:_SendCommand("FRIENDREQUESTLIST", true)
	return self
end

function Interface:FriendRequest(userName)
	self:super("FriendRequest", userName)
	self:_SendCommand(concat("FRIENDREQUEST", "userName="..userName))
	return self
end

function Interface:AcceptFriendRequest(userName)
	self:super("AcceptFriendRequest", userName)
	self:_SendCommand(concat("ACCEPTFRIENDREQUEST", "userName="..userName))
	return self
end

function Interface:DeclineFriendRequest(userName)
	self:super("DeclineFriendRequest", userName)
	self:_SendCommand(concat("DECLINEFRIENDREQUEST", "userName="..userName))
	return self
end

function Interface:Unfriend(userName)
	self:super("Unfriend", userName)
	self:_SendCommand(concat("UNFRIEND", "userName="..userName))
	return self
end

function Interface:Ignore(userName)
	self:super("Ignore", userName)
	self:_SendCommand(concat("IGNORE", "userName="..userName))
	return self
end

function Interface:Unignore(userName)
	self:super("Unignore", userName)
	self:_SendCommand(concat("UNIGNORE", "userName="..userName))
	return self
end

function Interface:IgnoreList()
	self:super("IgnoreList")
	self:_SendCommand("IGNORELIST")
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
		userData.isReady     = status.isReady
	else
		battleStatus.isReady = userData.isReady -- self:GetMyIsReady()
	end
	if status.teamNumber ~= nil then
		updated = updated or userData.teamNumber ~= status.teamNumber
		battleStatus.teamNumber = status.teamNumber
		userData.teamNumber     = status.teamNumber
	else
		battleStatus.teamNumber = userData.teamNumber or 0 -- self:GetMyTeamNumber() or 0
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
		userData.teamColor     = status.teamColor
	else
		battleStatus.teamColor = userData.teamColor -- self:GetMyTeamColor()
	end
	if status.allyNumber ~= nil then
		updated = updated or userData.allyNumber ~= status.allyNumber
		battleStatus.allyNumber = status.allyNumber
		userData.allyNumber     = status.allyNumber
	else
		battleStatus.allyNumber = userData.allyNumber or 0 -- self:GetMyAllyNumber() or 0
	end
	if status.isSpectator ~= nil then
		updated = updated or userData.isSpectator ~= status.isSpectator
		battleStatus.isSpectator = status.isSpectator
		userData.isSpectator     = status.isSpectator
	else
		battleStatus.isSpectator = userData.isSpectator -- self:GetMyIsSpectator()
	end
	if status.sync ~= nil then
		updated = updated or userData.sync ~= status.sync
		battleStatus.sync = status.sync
		userData.sync     = status.sync
	else
		battleStatus.sync = userData.sync -- self:GetMySync()
	end
	if status.side ~= nil then
		updated = updated or userData.side ~= status.side
		battleStatus.side = status.side
		userData.side     = status.side
	else
		battleStatus.side = userData.side or 0 -- self:GetMySide() or 0
	end

	--battleStatus.isReady = not battleStatus.isSpectator
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

-- Combine two 16 bit numbers into a string-formatted 32-bit integer
local function lsbmsb16tostring(lsb,msb)
	local aboveamillion = 0
	local belowamillion = lsb
	for b = 1, 16 do
		if math.bit_and(msb, 2^(b-1)) > 0 then
			belowamillion = belowamillion + bin2decmillion16[b][2]
			if belowamillion >= 1000000 then
				aboveamillion = aboveamillion + math.floor(belowamillion/1000000)
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
		lshift(battleStatus.teamNumber, 2) +
		lshift(battleStatus.allyNumber, 6) +
		lshift(playMode, 10)

	local msb16 =
		math.floor((lshift(battleStatus.sync, 6) + --Because sync actually has 3 values, 0, 1, 2 (unknown, synced, unsynced)
		lshift(battleStatus.side, 8)))

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
		self:ConnectToBattle(self.useSpringRestart, battle.ip, battle.port, nil, self:GetScriptPassword())
	end

	return self
end

function Interface:JoinBattle(battleID, password, scriptPassword)
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

function Interface:SetBattleStatus(status)
	if not self._requestedBattleStatus then
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
	if not self.userBattleStatus[myUserName] then
		self.userBattleStatus[myUserName] = {}
	end
	local userData = self.userBattleStatus[myUserName]
	local battleStatus, updated = UpdateAndCreateMerge(userData, status)

	--next(status) will return nil if status is empty table, which it is when it is called from REQUESTBATTLESTATUS
	if next(status) and not updated then
		return self
	end
	local battleStatusString = EncodeBattleStatus(battleStatus)

	local teamColor = battleStatus.teamColor or { math.random(), math.random(), math.random(), 1 }
	teamColor = EncodeTeamColor(teamColor)
	self:_SendCommand(concat("MYBATTLESTATUS", battleStatusString, teamColor))
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
	self:super("SayBattle", message)
	self:_SendCommand(concat("SAYBATTLE", message))
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
	local battleStatus = {
		isReady = true,
		teamNumber = self:GetUnusedTeamID(),
		allyNumber = allyNumber,
		playMode = true,
		sync = 1, -- (0 = unknown, 1 = synced, 2 = unsynced)
		side = 0,
	}

	battleStatus, updated = UpdateAndCreateMerge(battleStatus, battleStatusOptions or {})

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

function Interface:_OnAccepted()
	self:super("_OnAccepted")
end
Interface.commands["ACCEPTED"] = Interface._OnAccepted
Interface.commandPattern["ACCEPTED"] = "(%S+)"

function Interface:_OnDenied(reason)
	self:super("_OnDenied", reason)
end
Interface.commands["DENIED"] = Interface._OnDenied
Interface.commandPattern["DENIED"] = "(.+)"

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

------------------------
-- User commands
------------------------

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
Interface.commandPattern["ADDUSER"] = "(%S+)%s+(%S%S%-?%S?%S?%S?)%s+(%S+)%s*(.*)"

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
				self:ConnectToBattle(self.useSpringRestart, battle.ip, battle.port, nil, self:GetScriptPassword())
			end
		end
	end
end
Interface.commands["CLIENTSTATUS"] = Interface._OnClientStatus
Interface.commandPattern["CLIENTSTATUS"] = "(%S+)%s+(%S+)"

--friends
-- NB: added the _Uber suffix so not to conflict with Lobby:_OnFriend
function Interface:_OnFriend_Uber(tags)
	local tags = parseTags(tags)
	local userName = getTag(tags, "userName", true)
	self:_OnFriend(userName)
end
Interface.commands["FRIEND"] = Interface._OnFriend_Uber
Interface.commandPattern["FRIEND"] = "(.+)"

-- NB: added the _Uber suffix so not to conflict with Lobby:_OnUnfriend
function Interface:_OnUnfriend_Uber(tags)
	local tags = parseTags(tags)
	local userName = getTag(tags, "userName", true)
	self:_OnUnfriend(userName)
end
Interface.commands["UNFRIEND"] = Interface._OnUnfriend_Uber
Interface.commandPattern["UNFRIEND"] = "(.+)"

function Interface:_OnFriendList(tags)
	local tags = parseTags(tags)
	local userName = getTag(tags, "userName", true)
	table.insert(self._friendList, userName)
end
Interface.commands["FRIENDLIST"] = Interface._OnFriendList
Interface.commandPattern["FRIENDLIST"] = "(.+)"

function Interface:_OnFriendListBegin()
	self._friendList = {}
end
Interface.commands["FRIENDLISTBEGIN"] = Interface._OnFriendListBegin

function Interface:_OnFriendListEnd()
	self:super("_OnFriendList", self._friendList)
	self._friendList = {}
end
Interface.commands["FRIENDLISTEND"] = Interface._OnFriendListEnd

-- friend requests
function Interface:_OnFriendRequest(tags)
	local tags = parseTags(tags)
	local userName = getTag(tags, "userName", true)
	self:super("_OnFriendRequest", userName)
end
Interface.commands["FRIENDREQUEST"] = Interface._OnFriendRequest
Interface.commandPattern["FRIENDREQUEST"] = "(.+)"

function Interface:_OnFriendRequestList(tags)
	local tags = parseTags(tags)
	local userName = getTag(tags, "userName", true)
	table.insert(self._friendRequestList, userName)
end
Interface.commands["FRIENDREQUESTLIST"] = Interface._OnFriendRequestList
Interface.commandPattern["FRIENDREQUESTLIST"] = "(.+)"

function Interface:_OnFriendRequestListBegin()
	self._friendRequestList = {}
end
Interface.commands["FRIENDREQUESTLISTBEGIN"] = Interface._OnFriendRequestListBegin

function Interface:_OnFriendRequestListEnd()
	self:super("_OnFriendRequestList", self._friendRequestList)
	self._friendRequestList = {}
end
Interface.commands["FRIENDREQUESTLISTEND"] = Interface._OnFriendRequestListEnd

------------------------
-- Battle commands
------------------------
local msblsb5 = { -- stores a table of each power of 10 >= 10^5 as the 16 bit top and bottom halfs of digits greater than the 5th digit
	{ 1 , 34464 },
	{ 15 , 16960 },
	{ 152 , 38528 },
	{ 1525 , 57600 },
	{ 15258 , 51712 },
}

-- splits a string-encoded 32bit unsigned integer into 16bit LSB and 16bit MSB
local function split16fast(bignumstr)
	local skipdigits = 5
	local lsb = tonumber(string.sub(bignumstr, -skipdigits)) -- 5 length suffix
	local msb = 0
	for i= skipdigits + 1, string.len(bignumstr) do -- for each character of the big number string
		local n = tonumber(string.sub(bignumstr,-i,-i)) -- get the current character
		--print (i,string.sub(bignumstr,i,i),n)
		for k = 1, n do  -- for each number value of current character
			lsb = lsb + msblsb5[i - skipdigits][2] -- add the 16bit LSB of 10*i'th power
			if lsb >= 65536 then -- if it overflows LSB, increment MSB
				msb = msb + math.floor(lsb / 65536)
				lsb = lsb % 65536
			end
			msb = msb + msblsb5[i - skipdigits][1] -- add the 16 bit MSB of 10*i'th power
		end
	end
	--print (msb, lsb, lsb + msb *65536)
	return lsb, msb
end

local function ParseBattleStatus(battleStatus)
	local lsb, msb = split16fast(battleStatus)

	--battleStatus = tonumber(battleStatus)
	return {
		isReady      = rshift(lsb, 1) % 2 == 1,
		teamNumber   = rshift(lsb, 2) % 16,
		allyNumber   = rshift(lsb, 6) % 16,
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

		spectatorCount = 0,
		--playerCount = nil,
		isRunning = self.users[founder].isInGame,

		-- Spring stuff
		-- unsupported
		--type = tonumber(type)
		--natType = tonumber(natType)
	})
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
	local status = ParseBattleStatus(battleStatus)
	status.teamColor = ParseTeamColor(teamColor)

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
	local status = ParseBattleStatus(battleStatus)
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
	local status = ParseBattleStatus(battleStatus)
	status.teamColor = ParseTeamColor(teamColor)
	-- local ai, dll = unpack(explode("\t", aiDll)))
	status.aiLib = aiDll
	status.owner = owner
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
		for teamNumber=0, 15, 1 do
			for allyNumber=0,15, 1 do
				for isSpectator =0, 1, 1 do
					for sync=0, 2, 1 do
						for side=0, 2, 1 do
							bStatus.isReady = isReady == 1 and true or false
							bStatus.teamNumber = teamNumber
							bStatus.allyNumber = allyNumber
							bStatus.isSpectator = isSpectator == 1 and true or false
							bStatus.sync = sync
							bStatus.side = side
							bStatusStr = EncodeBattleStatus(bStatus)
							retBStatus = ParseBattleStatus(bStatusStr)
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

function Interface:CloseQueue(name)
	self:_SendCommand(concat("CLOSEQUEUE", json.encode(name)))
	return self
end

function Interface:ConnectUser(userName, ip, port, engine, scriptPassword)
	self:_SendCommand(concat("CONNECTUSER", json.encode({userName=userName, ip=ip, port=port, engine=engine, scriptPassword=scriptPassword})))
	return self
end

function Interface:InviteTeam(userName)
	self:_SendCommand(concat("INVITETEAM", json.encode({userName=userName})))
	return self
end

function Interface:InviteTeamAccept(userName)
	self:_SendCommand(concat("INVITETEAMACCEPT", json.encode({userName=userName})))
	return self
end

function Interface:InviteTeamDecline(userName)
	self:_SendCommand(concat("INVITETEAMDECLINE", json.encode({userName=userName})))
	return self
end

function Interface:JoinQueue(name, params)
	local tbl = {name=name}
	if params ~= nil then
		tbl["params"] = params
	end
	self:_SendCommand(concat("JOINQUEUE", json.encode(tbl)))
	return self
end

function Interface:JoinQueueAccept(name, userNames)
	self:_SendCommand(concat("JOINQUEUEACCEPT", json.encode({name=name,userNames=userNames})))
	return self
end

function Interface:JoinQueueDeny(name, userNames, reason)
	self:_SendCommand(concat("JOINQUEUEDENY", json.encode({name=name,userNames=userNames,reason=reason})))
	return self
end

function Interface:KickFromTeam(userName)
	self:_SendCommand(concat("KICKFROMTEAM", json.encode({userName=userName})))
	return self
end

function Interface:LeaveTeam()
	self:_SendCommand("LEAVETEAM")
	return self
end

function Interface:LeaveQueue(name)
	self:_SendCommand(concat("LEAVEQUEUE", json.encode({name=name})))
	return self
end

function Interface:ListQueues()
	self:_SendCommand("LISTQUEUES")
	return self
end

function Interface:ReadyCheck(name, userNames, responseTime)
	self:_SendCommand(concat("READYCHECK", json.encode({name=name, userNames=userNames, responseTime=responseTime})))
	return self
end

function Interface:ReadyCheckResponse(name, response, responseTime)
	local response = {name=name, response=response}
	if responseTime ~= nil then
		response.responseTime = responseTime
	end
	self:_SendCommand(concat("READYCHECKRESPONSE", json.encode(response)))
	return self
end

function Interface:RemoveQueueUser(name, userNames)
	self:_SendCommand(concat("REMOVEQUEUEUSER", {name=name, userNames=userNames}))
	return self
end

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
	self:_SendCommand(concat("OPENQUEUE", json.encode({queue=queue})))
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
	self:_SendCommand(concat("SAYTEAM", json.encode({msg=msg})))
	return self
end

function Interface:SayTeamEx(msg)
	self:_SendCommand(concat("SAYTEAMEX", json.encode({msg=msg})))
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
	self:_SendCommand(concat("SETTEAMLEADER", json.encode({userName=userName})))
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
	compFlags = explode("\t", compflags)
	self:_CallListeners("OnCompFlags", compFlags)
end
Interface.commands["COMPFLAGS"] = Interface._OnCompFlags
Interface.commandPattern["COMPFLAGS"] = "(%S+)%s+(%S+)"

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

function Interface:_OnRequestBattleStatus()
	self._requestedBattleStatus = true
	self:_CallListeners("OnRequestBattleStatus")
	self:SetBattleStatus({})
end
Interface.commands["REQUESTBATTLESTATUS"] = Interface._OnRequestBattleStatus

function Interface:_OnRing(userName)
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

local mod_opts_pre = "game/modoptions/"
local mod_opts_pre_indx = #mod_opts_pre + 1
local function string_starts(String, Start)
	return string.sub(String, 1, string.len(Start)) == Start
end
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

function Interface:_OnIgnoreListParse(tags)
	local tags = parseTags(tags)
	local userName = getTag(tags, "userName", true)
	local reason = getTag(tags, "reason")
	self:_OnIgnoreList(userName, reason)
end

function Interface:_OnIgnoreList(userName, reason)
	self:_CallListeners("OnIgnoreList", userName, reason)
end
Interface.commands["IGNORELIST"] = Interface._OnIgnoreListParse
Interface.commandPattern["IGNORELIST"] = "(.+)"

function Interface:_OnIgnoreListBegin()
	self:_CallListeners("OnIgnoreListBegin")
end
Interface.commands["IGNORELISTBEGIN"] = Interface._OnIgnoreListBegin

function Interface:_OnIgnoreListEnd()
	self:_CallListeners("OnIgnoreListEnd")
end
Interface.commands["IGNORELISTEND"] = Interface._OnIgnoreListEnd

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

function Interface:_OnS_Battle_Update_lobby_title(battleID, newbattletitle)
	--self:super("_OnS_Battle_Update_lobby_title", tonumber(battleID), newbattletitle)
	battleID = tonumber(battleID)
	if battleID then 
		self:_CallListeners("OnS_Battle_Update_lobby_title", battleID, newbattletitle)
		--Spring.Echo("Interface:_OnS_Battle_Update_lobby_title",battleID, newbattletitle)
	end
end
Interface.commands["s.battle.update_lobby_title"] = Interface._OnS_Battle_Update_lobby_title
Interface.commandPattern["s.battle.update_lobby_title"] = "(%S+)%s+(.*)"

function Interface:_OnS_Client_Errorlog()
	self:_CallListeners("OnS_Client_Errorlog")
end

Interface.commands["s.client.errorlog"] = Interface._OnS_Client_Errorlog
--Interface.commandPattern["s.client.errorlog"] = "(%S+)"

return Interface
