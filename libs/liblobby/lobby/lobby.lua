-- The API is mostly inspired by the official Spring protocol with some major differences such as:
-- AI is used to denote a game AI, while bot is only used for automated lobby bots
-- TODO: rest

VFS.Include(LIB_LOBBY_DIRNAME .. "observable.lua")
VFS.Include(LIB_LOBBY_DIRNAME .. "utilities.lua")

function Lobby:init()
	self.listeners = {}
	-- don't use these fields directly, they are subject to change
	self:_Clean()
end

function Lobby:_Clean()
	self.users = {}
	self.userNamesLC = {} -- lookup table for (user name in lower Case) => userName
	self.userNamesQueued = {}
	self.userBySteamID = {}
	self.userCount = 0

	self.SOURCE_DISCORD = 0

	self.friends = {} -- list
	self.isFriend = {} -- map
	self.friendCount = 0
	self.friendRequests = {} -- list
	self.hasFriendRequest = {} -- map
	self.friendRequestCount = 0
	self.friendListRecieved = false

	self.ignored = {} -- list
	self.isIgnored = {} -- map
	self.ignoredCount = 0
	self.ignoreListRecieved = false
	self.loginInfoEndSent = false
	self.userCountLimited = false

	self.channels = {}
	self.channelCount = 0

	self.battles = {}
	self.battleCount = 0
	self.modoptions = {}

	self.battleAis = {}
	self.userBattleStatus = {}

	self.joinedQueues = {}
	self.joinedQueueList = {}
	self.queues = {}
	self.queueCount = 0
	self.pendingQueueRequests = 0

	self.partyMap = {}
	self.myPartyID = nil

	self.planetwarsData = {}

	self.team = nil

	self.latency = 0 -- in ms

	self.loginData = nil
	self.loginSent = nil
	self.myUserName = nil
	self.myChannels = {}
	self.myBattleID = nil
	self.scriptPassword = nil
	self.sessionToken = nil
	am = Platform.macAddrHash or "0"
	as = Platform.sysInfoHash or "0"
	self.agent = am.." "..as:sub(1,16)

	-- reconnection delay in seconds
	self.reconnectionDelay = 15
end

function Lobby:_PreserveData()
	self._oldData = {
		--channels = ShallowCopy(self.channels),
		--battles = ShallowCopy(self.battles),
		loginData = ShallowCopy(self.loginData),
		myUserName = self.myUserName,
		host = self.host,
		port = self.port,
	}
end

local function GenerateScriptTxt(battleIp, battlePort, clientPort, scriptPassword, myName)
	local scriptTxt =
[[
[GAME]
{
	HostIP=__IP__;
	HostPort=__PORT__;
	SourcePort=__CLIENT_PORT__;
	IsHost=0;
	MyPlayerName=__MY_PLAYER_NAME__;
	MyPasswd=__MY_PASSWD__;
}]]

	scriptTxt = scriptTxt:gsub("__IP__", battleIp)
                         :gsub("__PORT__", battlePort)
                         :gsub("__CLIENT_PORT__", clientPort or 0)
                         :gsub("__MY_PLAYER_NAME__", myName or lobby:GetMyUserName() or "noname")
                         :gsub("__MY_PASSWD__", scriptPassword)
	return scriptTxt
end

-- TODO: This doesn't belong in the API. Battleroom chat commands are not part of the protocol (yet), and will cause issues with rooms where !start doesn't do anything.
function Lobby:StartBattle()
	return self
end

-- TODO: Provide clean implementation/specification
function Lobby:SelectMap(mapName)
	self:SayBattle("!map " .. mapName)
end

function Lobby:SetBattleType(typeName)
	self:SayBattle("!type " .. typeName)
end

-------------------------------------------------
-- BEGIN Client commands
-------------------------------------------------

------------------------
-- Connectivity commands
------------------------

function Lobby:Connect(host, port)
	self.host = host
	self.port = port
	return self
end

function Lobby:Register(userName, password, email)
	return self
end

function Lobby:Login(user, password, cpu, localIP, lobbyVersion)
	self.myUserName = user
	self.loginData = {user, password, cpu, localIP, lobbyVersion}
	self.loginSent = true
	return self
end

function Lobby:Ping()
	self.pingTimer = Spring.GetTimer()
end

------------------------
-- Status commands
------------------------

function Lobby:SetIngameStatus(isInGame)
	return self
end

function Lobby:SetAwayStatus(isAway)
	return self
end

------------------------
-- User commands
------------------------

-- FIXME: Currently uberserver requires to explicitly ask for the friend and friend request lists. This could be removed to simplify the protocol.
function Lobby:FriendList()
	return self
end
function Lobby:FriendRequestList()
	return self
end

function Lobby:FriendRequest(userName, steamID)
	return self
end

function Lobby:AcceptFriendRequest(userName)
	local user = self:GetUser(userName)
	if user then
		user.hasFriendRequest = false
	end
	return self
end

function Lobby:DeclineFriendRequest(userName)
	local user = self:GetUser(userName)
	if user then
		user.hasFriendRequest = false
	end
	return self
end

function Lobby:Unfriend(userName, steamID)
	return self
end

function Lobby:Ignore(userName)
	return self
end

function Lobby:Unignore(userName)
	return self
end

function Lobby:IgnoreList()
	return self
end

------------------------
-- Battle commands
------------------------

function Lobby:HostBattle(battleName, password)
	return self
end

function Lobby:RejoinBattle(battleID)
	return self
end

function Lobby:JoinBattle(battleID, password, scriptPassword)
	return self
end

function Lobby:LeaveBattle()
	return self
end

function Lobby:SetBattleStatus(status)
	return self
end

function Lobby:AddAi(aiName, aiLib, allyNumber, version, options)
	return self
end

function Lobby:RemoveAi(aiName)
	return self
end

function Lobby:UpdateAi(aiName, status)
	return self
end

function Lobby:KickUser(userName)
	return self
end

function Lobby:SayBattle(message)
	return self
end

function Lobby:SayBattleEx(message)
	return self
end

function Lobby:ConnectToBattle(useSpringRestart, battleIp, battlePort, clientPort, scriptPassword, myName, gameName, mapName, engineName, battleType)
	if gameName and not VFS.HasArchive(gameName) then
		WG.Chobby.InformationPopup("Cannont start game: missing game file '" .. gameName .. "'.")
		return
	end

	if mapName and not VFS.HasArchive(mapName) then
		WG.Chobby.InformationPopup("Cannont start game: missing map file '" .. mapName .. "'.")
		return
	end
	local Config = WG.Chobby.Configuration

	if engineName and (Config.multiplayerLaunchNewSpring or not Config:IsValidEngineVersion(engineName)) and not Config.useWrongEngine then
		if WG.WrapperLoopback and WG.WrapperLoopback.StartNewSpring and WG.SettingsWindow and WG.SettingsWindow.GetSettingsString then
			local params = {
				StartScriptContent = GenerateScriptTxt(battleIp, battlePort, clientPort, scriptPassword, myName),
				Engine = engineName,
				SpringSettings = WG.SettingsWindow.GetSettingsString(),
			}

			if Config.multiplayerDifferentEngine then -- This allows the use of testing engines much more easily
				Spring.Echo("Attempting to start new spring engine window", engineName)
				local scriptfilename = "engine_testing_start_script.txt"
				local scriptfile = io.open(scriptfilename, 'w')
				scriptfile:write(GenerateScriptTxt(battleIp, battlePort, clientPort, scriptPassword, myName))
				scriptfile:close()
				params.StartDemoName = scriptfilename
				params.Engine = string.gsub(engineName, "BAR105", "bar")
			end

			WG.WrapperLoopback.StartNewSpring(params)
		else
			WG.Chobby.InformationPopup("Cannont start game: wrong Spring engine version. The required version is '" .. engineName .. "', your version is '" .. Spring.Utilities.GetEngineVersion() .. "'.", {width = 420, height = 260})
		end
		return
	end

	self:_CallListeners("OnBattleAboutToStart", battleType)

	Spring.Echo("Game starts!")
	if useSpringRestart then
		local springURL = "spring://" .. self:GetMyUserName() .. ":" .. scriptPassword .. "@" .. battleIp .. ":" .. battlePort
		Spring.Echo(springURL)
		Spring.Restart(springURL, "")
	else
		local scriptTxt = GenerateScriptTxt(battleIp, battlePort, clientPort, scriptPassword, myName)

		Spring.Echo(scriptTxt)
		--local scriptFileName = "scriptFile.txt"
		--local scriptFile = io.open(scriptFileName, "w")
		--scriptFile:write(scriptTxt)
		--scriptFile:close()

		Spring.Reload(scriptTxt)
	end
end

function Lobby:VoteYes()
	return self
end

function Lobby:VoteNo()
	return self
end

function Lobby:VoteOption(id)
	return self
end

function Lobby:SetModOptions(data)
	return self
end

------------------------
-- Channel & private chat commands
------------------------

function Lobby:Join(chanName, key)
	return self
end

function Lobby:Leave(chanName)
	self:_OnLeft(chanName, self.myUserName, "left")
	return self
end

function Lobby:Say(chanName, message)
	return self
end

function Lobby:SayEx(chanName, message)
	return self
end

function Lobby:SayPrivate(userName, message)
	return self
end

------------------------
-- MatchMaking commands
------------------------

function Lobby:JoinMatchMaking(queueNamePossiblyList)
	return self
end

function Lobby:LeaveMatchMaking(queueNamePossiblyList)
	return self
end

function Lobby:LeaveMatchMakingAll()
	return self
end

function Lobby:AcceptMatchMakingMatch()
	return self
end

function Lobby:RejectMatchMakingMatch()
	return self
end

------------------------
-- Party commands
------------------------

function Lobby:InviteToParty(userName)
	return self
end

function Lobby:LeaveParty()
	return self
end

function Lobby:PartyInviteResponse(partyID, accepted)
	return self
end

------------------------
-- Battle Propose commands
------------------------

function Lobby:BattleProposalRespond(userName, accepted)
	return self
end

function Lobby:BattleProposalBattleInvite(userName, battleID, password)
	return self
end

------------------------
-- Planetwars commands
------------------------

function Lobby:PwJoinPlanet(planetID)
	return self
end

function Lobby:JoinFactionRequest(factionName)
	return self
end

------------------------
-- Steam commands
------------------------

function Lobby:SetSteamAuthToken(steamAuthToken)
	self.steamAuthToken = steamAuthToken
	return self
end

function Lobby:SetSteamDlc(steamDlc)
	self.steamDlc = steamDlc
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

function Lobby:_OnConnect(protocolVersion, springVersion, udpPort, serverMode)
	if Spring.GetGameName() ~= "" then
		lobby:SetIngameStatus(true)
	end
	self.disconnectTime = nil
	self:_CallListeners("OnConnect", protocolVersion, udpPort, serverMode)
	self:_OnSuggestedEngineVersion(springVersion)
end

function Lobby:_OnSuggestedEngineVersion(springVersion)
	self.suggestedEngineVersion = springVersion
	self:_CallListeners("OnSuggestedEngineVersion", springVersion)
end

function Lobby:_OnSuggestedGameVersion(gameVersion)
	self.suggestedGameVersion = gameVersion
	self:_CallListeners("OnSuggestedGameVersion", gameVersion)
end

function Lobby:_OnAccepted(newName)
	if self.status == "connecting" then
		self.status = "connected"
	end
	if newName then
		self.myUserName = newName
	end
	self.userCount = 0
	self:_CallListeners("OnAccepted")
end

function Lobby:_OnDenied(reason)
	self:_CallListeners("OnDenied", reason)
end

-- TODO: rework, should be only one callin
function Lobby:_OnAgreement(line)
	self:_CallListeners("OnAgreement", line)
end

-- TODO: Merge with _OnAgreement into a single callin
function Lobby:_OnAgreementEnd()
	self:_CallListeners("OnAgreementEnd")
end

function Lobby:_OnRegistrationAccepted()
	self:_CallListeners("OnRegistrationAccepted")
end

function Lobby:_OnRegistrationDenied(reason, accountAlreadyExists)
	self:_CallListeners("OnRegistrationDenied", reason, accountAlreadyExists)
end

function Lobby:_OnLoginInfoEnd()
	-- Can be called from multiple sources internally. Only send once per login
	if self.loginInfoEndSent then
		return
	end
	self.loginInfoEndSent = true
	self:_CallListeners("OnLoginInfoEnd")
end

function Lobby:_OnPong()
	self.pongTimer = Spring.GetTimer()
	if self.pingTimer then
		self.latency = Spring.DiffTimers(self.pongTimer, self.pingTimer, true)
	else
		Spring.Log(LOG_SECTION, "warning", "Missing self.pingTimer in Lobby:_OnPong()")
	end
	self:_CallListeners("OnPong")
end

function Lobby:_OnChangeEmailAccepted()
	self:_CallListeners("OnChangeEmailAccepted")
end

function Lobby:_OnChangeEmailDenied(errorMsg)
	self:_CallListeners("OnChangeEmailDenied", errorMsg)
end

function Lobby:_OnChangeEmailRequestAccepted()
	self:_CallListeners("OnChangeEmailRequestAccepted")
end

function Lobby:_OnChangeEmailRequestDenied(errorMsg)
	self:_CallListeners("OnChangeEmailRequestDenied", errorMsg)
end

function Lobby:_OnResetPasswordAccepted()
	self:_CallListeners("OnResetPasswordAccepted")
end

function Lobby:_OnResetPasswordDenied(errorMsg)
	self:_CallListeners("OnResetPasswordDenied", errorMsg)
end

function Lobby:_OnResetPasswordRequestAccepted()
	self:_CallListeners("OnResetPasswordRequestAccepted")
end

function Lobby:_OnResetPasswordRequestDenied(errorMsg)
	self:_CallListeners("OnResetPasswordRequestDenied", errorMsg)
end

------------------------
-- User commands
------------------------

function Lobby:_OnAddUser(userName, status)
	if status and status.steamID then
		self.userBySteamID[status.steamID] = userName
	end

	local userInfo = self.users[userName]
	self.userCount = self.userCount + 1 -- correctly fix because lobby didnt clear user count on onAccepted
	if not userInfo then
		userInfo = {
			userName = userName,
			isFriend = self.isFriend[userName],
			isIgnored = self.isIgnored[userName],
			hasFriendRequest = self.hasFriendRequest[userName],
		}
		self.users[userName] = userInfo
	else
		userInfo.isOffline = false
	end

	local userNameLC = userName:lower()
	if self.userNamesLC[userNameLC] and self.userNamesLC[userNameLC] ~= userName then
		Spring.Log(LOG_SECTION, LOG.WARNING, "Overwriting formerly known lower-case user name " .. self.userNamesLC[userNameLC] .. " by user name " .. userName .. "(2 users with same lower case-variant exist)")
	end
	self.userNamesLC[userName:lower()] = userName

	if status then
		for k, v in pairs(status) do
			userInfo[k] = v
		end
	end
	self:_CallListeners("OnAddUser", userName, userInfo)
end

function Lobby:_OnRemoveUser(userName)
	if not self.users[userName] then
		Spring.Log("liblobby", LOG.ERROR, "Tried to remove missing user", userName)
		return
	end
	local userInfo = self.users[userName]

	if userInfo.battleID then
		self:_OnLeftBattle(userInfo.battleID, userName)
	end

	-- preserve isFriend/hasFriendRequest
	local isFriend, hasFriendRequest = userInfo.isFriend, userInfo.hasFriendRequest
	local persistentUserInfo = self:_GetPersistentUserInfo(userName)
	self.users[userName] =persistentUserInfo

	if isFriend or hasFriendRequest then
		userInfo = self:TryGetUser(userName)
		userInfo.isFriend         = isFriend
		userInfo.hasFriendRequest = hasFriendRequest
	end
	self.userCount = self.userCount - 1
	self:_CallListeners("OnRemoveUser", userName)
end

-- Updates the specified status keys
function Lobby:_OnUpdateUserStatus(userName, status)
	if status and status.steamID then
		self.userBySteamID[status.steamID] = userName
	end
	if self.users[userName] then
		for k, v in pairs(status) do
			self.users[userName][k] = v
		end
		self:_CallListeners("OnUpdateUserStatus", userName, status)
	else
		Spring.Echo("[LuaMenu] Error: In Lobby _OnUpdateUserStatus on invalid user", userName, status)
	end
end

function Lobby:_OnUpdateBattleQueue(battleId, userNamesQueued)
	for _, battleUserName in pairs(self.battles[battleId].users) do -- all users in battle
		local userInQueue = false
		local queueStatusOld = self.userBattleStatus[battleUserName] and self.userBattleStatus[battleUserName].queuePos or 0

		for posNew, userNameQueued in pairs(userNamesQueued) do -- test each battleUser if in the received queueList
			if battleUserName == userNameQueued then
				if queueStatusOld ~= posNew or true then
					self:_OnUpdateUserBattleStatus(battleUserName, {queuePos = posNew})
					userInQueue = true
					break
				else
					userInQueue = true
					break;
				end
			end
		end
		if userInQueue == false then
			if queueStatusOld > 0 then
				self:_OnUpdateUserBattleStatus(battleUserName, {queuePos = 0})
			-- else
				-- Spring.Echo("_OnUpdateBattleQueue Not Updating user,which is has no new queue pos and had none before " .. battleUserName .. " pos " .. tostring(queueStatusOld))
			end
		end
	end
	return
end

------------------------
-- Friend
------------------------

function Lobby:_OnFriend(userName)
	table.insert(self.friends, userName)
	self.isFriend[userName] = true
	self.friendCount = self.friendCount + 1
	local userInfo = self:TryGetUser(userName)
	userInfo.isFriend = true
	self:_CallListeners("OnFriend", userName)
end

function Lobby:_OnUnfriend(userName)
	for i, v in pairs(self.friends) do
		if v == userName then
			table.remove(self.friends, i)
			break
		end
	end
	self.isFriend[userName] = false
	self.friendCount = self.friendCount - 1
	local userInfo = self:GetUser(userName)
	-- don't need to create offline users in this case
	if userInfo then
		userInfo.isFriend = false
	end
	self:_CallListeners("OnUnfriend", userName)
end

function Lobby:_OnFriendList(friends)
	local newFriendMap = {}
	for i = 1, #friends do
		local userName = friends[i]
		if not self.isFriend[userName] then
			self:_OnFriend(userName)
			self:_OnRemoveIgnoreUser(userName)
		end
		newFriendMap[userName] = true
	end

	for _, userName in pairs(self.friends) do
		if not newFriendMap[userName] then
			self:_OnUnfriend(userName)
			self:_OnRemoveIgnoreUser(userName)
		end
	end

	self:_CallListeners("OnFriendList", self:GetFriends())
end

function Lobby:_OnFriendRequest(userName)
	table.insert(self.friendRequests, userName)
	self.hasFriendRequest[userName] = true
	self.friendRequestCount = self.friendRequestCount + 1
	local userInfo = self:TryGetUser(userName)
	userInfo.hasFriendRequest = true
	self:_CallListeners("OnFriendRequest", userName)
end

function Lobby:_OnFriendRequestList(friendRequests)
	self.friendRequests = friendRequests
	self.friendRequestCount = #friendRequests
	for _, userName in pairs(self.friendRequests) do
		self.hasFriendRequest[userName] = true
		local userInfo = self:TryGetUser(userName)
		userInfo.hasFriendRequest = true
	end

	self:_CallListeners("OnFriendRequestList", self:GetFriendRequests())
end

------------------------
-- Ignore
------------------------

function Lobby:_OnAddIgnoreUser(userName)
	table.insert(self.ignored, userName)
	self.isIgnored[userName] = true
	self.ignoredCount = self.ignoredCount + 1
	local userInfo = self:TryGetUser(userName)
	userInfo.isIgnored = true
	self:_CallListeners("OnAddIgnoreUser", userName)
end

function Lobby:_OnRemoveIgnoreUser(userName)
	for i, v in pairs(self.ignored) do
		if v == userName then
			table.remove(self.ignored, i)
			break
		end
	end
	self.isIgnored[userName] = false
	self.ignoredCount = self.ignoredCount - 1
	local userInfo = self:GetUser(userName)
	-- don't need to create offline users in this case
	if userInfo then
		userInfo.isIgnored = false
	end
	self:_CallListeners("OnRemoveIgnoreUser", userName)
end

function Lobby:_OnIgnoreList(data)
	self.ignored = data
	self.ignoredCount = #data
	self.isIgnored = {}
	for _, userName in pairs(self.ignored) do
		self.isIgnored[userName] = true
		local userInfo = self:TryGetUser(userName)
		userInfo.isIgnored = true
	end

	self:_CallListeners("OnIgnoreList", self:Getignored())
end

------------------------
-- Battle commands
------------------------

function Lobby:_OnBattleIngameUpdate(battleID, isRunning)
	if self.battles[battleID] and self.battles[battleID].isRunning ~= isRunning then
		self.battles[battleID].isRunning = isRunning
		self:_CallListeners("OnBattleIngameUpdate", battleID, isRunning)
	end
end

function Lobby:_OnRejoinOption(battleID)
	self:_CallListeners("OnRejoinOption", battleID)
end

function Lobby:_OnBattleOpened(battleID, battle)
	self.battles[battleID] = {
		battleID = battleID,

		founder = battle.founder,
		users = battle.users,

		ip = battle.ip,
		port = battle.port,

		maxPlayers = battle.maxPlayers,
		passworded = battle.passworded,

		engineName = battle.engineName,
		engineVersion = battle.engineVersion,
		mapName = battle.mapName,
		title = battle.title,
		gameName = battle.gameName,

		playerCount = battle.playerCount,
		spectatorCount = battle.spectatorCount,
		isRunning = battle.isRunning,

		-- ZK specific
		runningSince = battle.runningSince,
		battleMode = battle.battleMode,
		disallowCustomTeams = battle.disallowCustomTeams,
		disallowBots = battle.disallowBots,
		isMatchMaker = battle.isMatchMaker,
	}
	self.battleCount = self.battleCount + 1

	self:_CallListeners("OnBattleOpened", battleID, self.battles[battleID])
end

function Lobby:_OnBattleClosed(battleID)
	self.battles[battleID] = nil
	self.battleCount = self.battleCount - 1
	self:_CallListeners("OnBattleClosed", battleID)
end

function Lobby:_OnJoinBattle(battleID, hashCode)
	self.myBattleID = battleID
	self.modoptions = {}

	self:_CallListeners("OnJoinBattle", battleID, hashCode)
end

function Lobby:_OnJoinedBattle(battleID, userName, scriptPassword)
	if not self.battles[battleID] then
		Spring.Log(LOG_SECTION, LOG.WARNING, "_OnJoinedBattle nonexistent battle.")
		return
	end
	local found = false
	local users = self.battles[battleID].users
	for i = 1, #users do
		if users[i] == userName then
			found = true
			break
		end
	end
	if not found then
		table.insert(self.battles[battleID].users, userName)
	end

	local userInfo = self:TryGetUser(userName)
	userInfo.battleID = battleID
	self:_CallListeners("OnUpdateUserStatus", userName, {battleID = battleID})

	self:_CallListeners("OnJoinedBattle", battleID, userName, scriptPassword)
end

function Lobby:_OnBattleScriptPassword(scriptPassword)
	self.scriptPassword = scriptPassword
	self:_CallListeners("OnBattleScriptPassword", scriptPassword)
end

function Lobby:_OnLeaveBattle(battleID)
	self.myBattleID = nil
	self.modoptions = {}
	self.battleAis = {}
	self.userBattleStatus = {}

	self:_CallListeners("OnLeaveBattle", battleID)
end

function Lobby:_OnLeftBattle(battleID, userName)
	if self:GetMyUserName() == userName then
		self.myBattleID = nil
		self.modoptions = {}
		self.battleAis = {}
		self.userBattleStatus = {}
	end

	if not (battleID and self.battles[battleID]) then
		Spring.Log(LOG_SECTION, LOG.ERROR,
			"Lobby:_OnLeftBattle: Tried to remove user from unknown battle: " .. tostring(battleID))
		return
	end

	local battleUsers = self.battles[battleID].users
	for i, v in pairs(battleUsers) do
		if v == userName then
			table.remove(battleUsers, i)
			break
		end
	end

	self.users[userName].battleID = nil
	self:_CallListeners("OnUpdateUserStatus", userName, {battleID = false})

	self:_CallListeners("OnLeftBattle", battleID, userName)
end

-- spectatorCount, locked, mapHash, mapName, engineVersion, runningSince, gameName, battleMode, disallowCustomTeams, disallowBots, isMatchMaker, maxPlayers, title, playerCount, passworded
function Lobby:_OnUpdateBattleInfo(battleID, battleInfo)
	local battle = self.battles[battleID]
	if not battle then
		Spring.Log(LOG_SECTION, "warning", "_OnUpdateBattleInfo nonexistent battle.")
		return
	end

	battle.maxPlayers = battleInfo.maxPlayers or battle.maxPlayers
	if battleInfo.passworded ~= nil then
		battle.passworded = battleInfo.passworded
	end

	battle.engineName = battleInfo.engineName or battle.engineName
	battle.engineVersion = battleInfo.engineVersion or battle.engineVersion
	battle.gameName = battleInfo.gameName or battle.gameName
	battle.mapName = battleInfo.mapName or battle.mapName
	battle.title = battleInfo.title or battle.title

	battle.playerCount = battleInfo.playerCount or battle.playerCount
	battle.spectatorCount = battleInfo.spectatorCount or battle.spectatorCount

	if battleInfo.locked == true then -- Because (false or nil) == nil
		battle.locked = true
	elseif battleInfo.locked == false then
		battle.locked = false
	end

	-- ZK specific
	battle.runningSince = battleInfo.runningSince or battle.runningSince
	battle.battleMode = battleInfo.battleMode or battle.battleMode
	if battleInfo.disallowCustomTeams ~= nil then
		battle.disallowCustomTeams = battleInfo.disallowCustomTeams
	end
	if battleInfo.disallowBots ~= nil then
		battle.disallowBots = battleInfo.disallowBots
	end
	if battleInfo.isMatchMaker ~= nil then
		battle.isMatchMaker = battleInfo.isMatchMaker
	end

	self:_CallListeners("OnUpdateBattleInfo", battleID, battleInfo)
end

-- compare 2 tables and return diff
-- also update table properties of 1st table !
local function getDiffAndSetNewValuesToTable(origin, update)
	local diff = {}
	local changed = false
	for uKey, uVal in pairs(update) do
		local changedSub = false
		local oVal = rawget(origin, uKey)
		
		if type(uVal) == "table" then
			if type(oVal) == "table" then -- use recursion if value is table and key exists in origin table
				_, changedSub = getDiffAndSetNewValuesToTable(oVal, uVal)
				changed = changed or changedSub
			else
				changed = true
			end
		else
			-- Spring.Echo("uVal:", uVal, " oVal:", oVal, uVal ~= oVal)
			changed = changed or (uVal ~= oVal)
		end

		if changed then
			rawset(diff, uKey, uVal)
			rawset(origin, uKey, uVal) -- this is the place where origin is updated, e.g. userData in _UpUpdateUserBattleStatus, which is self.userBattleStatus
		end
	end
	return diff, changed
end

-- Updates the specified status keys
-- BattleStatus keys Spring protocol: isReady, teamNumber, allyNumber, isSpectator, handicap, sync, side
-- additional keys used by chobby: teamColor
-- additional keys in bar infrastructure: queuePos
-- Bots/AIs have additional keys inside chobby: owner~=nil, aiLib~=nil, aiOptions, aiVersion
-- Example: _OnUpdateUserBattleStatus("gajop", {isReady=false, teamNumber=1})
function Lobby:_OnUpdateUserBattleStatus(userName, status)
	local statusNew = status

	if (statusNew.owner == nil and not self.users[userName]) or
	   (statusNew.owner ~= nil and not self.users[statusNew.owner]) then
		Spring.Log(LOG_SECTION, LOG.ERROR, "Tried to update non connected user in battle: ", userName)
		return
	end
	if not self.userBattleStatus[userName] then
		self.userBattleStatus[userName] = {}
	end

	local battleStatus = self.userBattleStatus[userName]

	local battleStatusDiff, changed = getDiffAndSetNewValuesToTable(battleStatus, statusNew) -- use battleStatusDiff instead of statusNew to only propagate battleStatus properties, that really changed or which are new properties

	if changed then
		if battleStatusDiff.isSpectator ~= nil and battleStatusDiff.isSpectator == false and battleStatus.queuePos and battleStatus.queuePos ~= 0 then
			battleStatus.queuePos = 0 -- always change queuePos to 0, if we switch from spec to player = prevent showing queuePos e.g. in playerbattelist, if we didn�t receive the queue-update from server yet
			battleStatusDiff.queuePos = 0
		end

		self:_CallListeners("OnUpdateUserBattleStatus", userName, battleStatusDiff)

		if battleStatusDiff.allyNumber or battleStatusDiff.isSpectator ~= nil or battleStatusDiff.queuePos then
			self:_CallListeners("OnUpdateUserTeamStatus", userName, battleStatus.allyNumber, battleStatus.isSpectator, battleStatus.queuePos)
		end
	end
end

-- Also calls the OnUpdateUserBattleStatus
function Lobby:_OnAddAi(battleID, aiName, status)
	status.isSpectator = false
	table.insert(self.battleAis, aiName)
	self:_OnUpdateUserBattleStatus(aiName, status)
	self:_CallListeners("OnAddAi", aiName, status)
end

function Lobby:_OnRemoveAi(battleID, aiName, aiLib, allyNumber, owner)
	for i, v in pairs(self.battleAis) do
		if v == aiName then
			table.remove(self.battleAis, i)
			break
		end
	end
	self:_CallListeners("OnLeftBattle", battleID, aiName)
	self.userBattleStatus[aiName] = nil
end

function Lobby:_OnSaidBattle(userName, message, sayTime)
	self:_CallListeners("OnSaidBattle", userName, message, sayTime)
end

function Lobby:_OnSaidBattleEx(userName, message, sayTime)
	self:_CallListeners("OnSaidBattleEx", userName, message, sayTime)
end

function Lobby:_OnVoteUpdate(voteMessage, pollType, notify, mapPoll, candidates, votesNeeded, pollUrl)
	self:_CallListeners("OnVoteUpdate", voteMessage, pollType, notify, mapPoll, candidates, votesNeeded, pollUrl)
end

function Lobby:_OnVoteEnd(message, success)
	self:_CallListeners("OnVoteEnd", message, success)
end

function Lobby:_OnVoteResponse(isYesVote)
	self:_CallListeners("OnVoteResponse", isYesVote)
end

function Lobby:_OnSetModOptions(data)
	self.modoptions = data
	self:_CallListeners("OnSetModOptions", data)
end

function Lobby:_OnResetModOptions()
	local oldModoptions = self.modoptions
	self.modoptions = {}

	self:_CallListeners("OnResetModOptions", oldModoptions)
end

------------------------
-- Channel & private chat commands
------------------------

function Lobby:_OnChannel(chanName, userCount, topic)
	local channel = self:_GetChannel(chanName)
	channel.userCount = userCount
	channel.topic = topic
	self:_CallListeners("OnChannel", chanName, userCount, topic)
end

function Lobby:_OnChannelTopic(chanName, author, changedTime, topic)
	local channel = self:_GetChannel(chanName)
	if topic ~= "" then
		channel.topic = topic
		self:_CallListeners("OnChannelTopic", chanName, author, changedTime, topic)
	else
		channel.topic = nil
		self:_CallListeners("_OnNoChannelTopic", chanName)
	end
end

function Lobby:_OnClients(chanName, users)
	local channel = self:_GetChannel(chanName)

	if channel.users ~= nil then
		for _, user in pairs(users) do
			local found = false
			for _, existingUser in pairs(channel.users) do
				if user == existingUser then
					found = true
					break
				end
			end
			if not found then
				table.insert(channel.users, user)
			end
		end
	else
		channel.users = users
	end
	self:_CallListeners("OnClients", chanName, users)
end

function Lobby:_OnJoined(chanName, userName)
	local channel = self:_GetChannel(chanName)

	-- only add users after CLIENTS was received
	if channel.users ~= nil then
		local isNewUser = true
		for i, v in pairs(channel.users) do
			if v == userName then
				Spring.Log(LOG_SECTION, "warning", "Duplicate user(" .. tostring(userName) .. ") added to channel (" .. tostring(chanName) .. ")")
				isNewUser = false
				break
			end
		end
		if isNewUser then
			table.insert(channel.users, userName)
			self:_CallListeners("OnJoined", chanName, userName)
		end
	end
end

function Lobby:_OnJoinFailed(chanName, reason)
	self:_CallListeners("OnJoinFailed", chanName, reason)
end

function Lobby:_OnJoin(chanName)
	local isNewChannel = not self:GetInChannel(chanName)
	if isNewChannel then
		table.insert(self.myChannels, chanName)
	end
	self:_CallListeners("OnJoin", chanName)
end

function Lobby:_OnLeft(chanName, userName, reason)
	local channel = self:_GetChannel(chanName)

	if not (channel and channel.users) then
		return
	end

	if userName == self.myUserName then
		for i, v in pairs(self.myChannels) do
			if v == chanName then
				table.remove(self.myChannels, i)
				break
			end
		end
	end
	for i, v in pairs(channel.users) do
		if v == userName then
			table.remove(channel.users, i)
			break
		end
	end
	self:_CallListeners("OnLeft", chanName, userName, reason)
end

function Lobby:_OnRung(userName, message, sayTime, source)
	self:_CallListeners("OnRung", userName, message, sayTime, source)
end

function Lobby:_OnSaid(chanName, userName, message, sayTime, source)
	self:_CallListeners("OnSaid", chanName, userName, message, sayTime, source)
end

function Lobby:_OnSaidEx(chanName, userName, message, sayTime)
	self:_CallListeners("OnSaidEx", chanName, userName, message, sayTime)
end

function Lobby:_OnSaidPrivate(userName, message, sayTime)
	self:_CallListeners("OnSaidPrivate", userName, message, sayTime)
end

function Lobby:_OnSaidPrivateEx(userName, message, sayTime)
	self:_CallListeners("OnSaidPrivateEx", userName, message, sayTime)
end

function Lobby:_OnSayPrivate(userName, message, sayTime)
	self:_CallListeners("OnSayPrivate", userName, message, sayTime)
end

function Lobby:_OnSayPrivateEx(userName, message, sayTime)
	self:_CallListeners("OnSayPrivateEx", userName, message, sayTime)
end

function Lobby:_OnSayServerMessage(message, sayTime)
	self:_CallListeners("OnSayServerMessage", message, sayTime)
end

------------------------
-- MatchMaking commands
------------------------

function Lobby:_OnQueueOpened(name, description, mapNames, maxPartySize, gameNames)
	self.queues[name] = {
		name = name,
		description = description,
		mapNames = mapNames,
		maxPartySize = maxPartySize,
		gameNames = gameNames,
		playersIngame = 0,
		playersWaiting = 0,
	}
	self.queueCount = self.queueCount + 1

	self:_CallListeners("OnQueueOpened", name, description, mapNames, maxPartySize, gameNames)
end

function Lobby:_OnQueueClosed(name)
	if self.queues[name] then
		self.queues[name] = nil
		self.queueCount = self.queueCount - 1
	end

	self:_CallListeners("OnQueueClosed", name)
end

function Lobby:_OnMatchMakerStatus(inMatchMaking, joinedQueueList, queueCounts, ingameCounts, instantStartQueues, currentEloWidth, joinedTime, bannedTime)

	if self.pendingQueueRequests > 0 then
		-- Sent incomplete data, ignore it and wait for the next one that should be arriving shortly.
		self.pendingQueueRequests = self.pendingQueueRequests - 1
		if self.pendingQueueRequests > 0 then
			return
		end
	end

	if inMatchMaking then
		self.joinedQueueList = joinedQueueList
		self.joinedQueues = {}
		for i = 1, #joinedQueueList do
			self.joinedQueues[joinedQueueList[i]] = true
		end
	else
		self.joinedQueues = nil
		self.joinedQueueList = nil
	end

	self.matchMakerBannedTime = bannedTime

	if queueCounts or ingameCounts then
		for name, queueData in pairs(self.queues) do
			queueData.playersIngame = (ingameCounts and ingameCounts[name]) or queueData.playersIngame
			queueData.playersWaiting = (queueCounts and queueCounts[name]) or queueData.playersWaiting
		end
	end

	self:_CallListeners("OnMatchMakerStatus", inMatchMaking, joinedQueueList, queueCounts, ingameCounts, instantStartQueues, currentEloWidth, joinedTime, bannedTime)
end

function Lobby:_OnMatchMakerReadyCheck(secondsRemaining, minWinChance, isQuickPlay)
	self:_CallListeners("OnMatchMakerReadyCheck", secondsRemaining, minWinChance, isQuickPlay)
end

function Lobby:_OnMatchMakerReadyUpdate(readyAccepted, likelyToPlay, queueReadyCounts, myBattleSize, myBattleReadyCount)
	self:_CallListeners("OnMatchMakerReadyUpdate", readyAccepted, likelyToPlay, queueReadyCounts, myBattleSize, myBattleReadyCount)
end

function Lobby:_OnMatchMakerReadyResult(isBattleStarting, areYouBanned)
	self:_CallListeners("OnMatchMakerReadyResult", isBattleStarting, areYouBanned)
end

function Lobby:_OnUserCount(userCount)
	self.fullUserCount = userCount
	self:_CallListeners("OnUserCount", userCount)
end

------------------------
-- Party commands
------------------------

function Lobby:_OnPartyInviteRecieved(partyID, partyUsers, timeoutSeconds)
	self:_CallListeners("OnPartyInviteRecieved", partyID, partyUsers, timeoutSeconds)
end

function Lobby:_OnPartyJoined(partyID, partyUsers)
	self:_CallListeners("OnPartyJoined", partyID, partyUsers)
end

function Lobby:_OnPartyLeft(partyID, partyUsers)
	self:_CallListeners("OnPartyLeft", partyID, partyUsers)
end

function Lobby:_OnPartyCreate(partyID, partyUsers)
	self:_CallListeners("OnPartyCreate", partyID, partyUsers)
end

function Lobby:_OnPartyUpdate(partyID, partyUsers)
	self:_CallListeners("OnPartyUpdate", partyID, partyUsers)
end

function Lobby:_OnPartyDestroy(partyID, partyUsers)
	self:_CallListeners("OnPartyDestroy", partyID, partyUsers)
end

function Lobby:_OnPartyInviteSent(userName) -- Invite sent to another user
	local userInfo = self:TryGetUser(userName)
	userInfo.pendingPartyInvite = true
	self:_CallListeners("OnPartyInviteSent", userName)
end

function Lobby:_OnPartyInviteResponse(userName, accepted) -- Invite response recieved from another user
	local userInfo = self:TryGetUser(userName)
	userInfo.pendingPartyInvite = false
	self:_CallListeners("OnPartyInviteResponse", userName, accepted)
end

------------------------
-- Battle Propose commands
------------------------

function Lobby:_OnBattleProposalResponse(userName, accepted)
	self:_CallListeners("OnBattleProposalResponse", userName, accepted)
end

function Lobby:_OnBattleProposalBattleInvite(userName, battleID, password)
	self:_CallListeners("OnBattleProposalBattleInvite", userName, battleID, password)
end

------------------------
-- Planetwars Commands
------------------------

function Lobby:_OnPwStatus(planetWarsMode, minLevel)
	self:_CallListeners("OnPwStatus", planetWarsMode, minLevel)
end

function Lobby:_OnPwMatchCommand(attackerFaction, defenderFactions, currentMode, planets, deadlineSeconds)
	local modeSwitched = (self.planetwarsData.currentMode ~= currentMode) or (self.planetwarsData.attackerFaction ~= attackerFaction)
	self.planetwarsData.attackerFaction  = attackerFaction
	self.planetwarsData.defenderFactions = defenderFactions
	self.planetwarsData.currentMode      = currentMode
	self.planetwarsData.planets          = planets

	Spring.Echo("OnPwMatchCommand modeSwitched", modeSwitched)
	if modeSwitched then
		self.planetwarsData.joinPlanet = nil
		self.planetwarsData.attackingPlanet = nil
	end

	self:_CallListeners("OnPwMatchCommand", attackerFaction, defenderFactions, currentMode, planets, deadlineSeconds, modeSwitched)
end

function Lobby:_OnPwRequestJoinPlanet(planetID)
	self:_CallListeners("OnPwRequestJoinPlanet", planetID)
end

function Lobby:_OnPwJoinPlanetSuccess(planetID)
	self.planetwarsData.joinPlanet = planetID
	self:_CallListeners("OnPwJoinPlanetSuccess", planetID)
end

function Lobby:_OnPwAttackingPlanet(planetID)
	self.planetwarsData.attackingPlanet = planetID
	self:_CallListeners("OnPwAttackingPlanet", planetID)
end

function Lobby:_OnPwFactionUpdate(factionData)
	self.planetwarsData.factionMap = {}
	self.planetwarsData.factionList = factionData
	for i = 1, #factionData do
		self.planetwarsData.factionMap[factionData[i].Shortcut] = true
	end
end

------------------------
-- News and community commands
------------------------

function Lobby:_OnNewsList(newsItems)
	self:_CallListeners("OnNewsList", newsItems)
end

function Lobby:_OnLadderList(ladderItems)
	self:_CallListeners("OnLadderList", ladderItems)
end

function Lobby:_OnForumList(forumItems)
	self:_CallListeners("OnForumList", forumItems)
end

function Lobby:_OnUserProfile(data)
	self:_CallListeners("OnUserProfile", data)
end

------------------------
-- Team commands
------------------------

function Lobby:_OnJoinedTeam(obj)
	local userName = obj.userName
	table.insert(self.team.users, userName)
end

function Lobby:_OnJoinTeam(obj)
	local userNames = obj.userNames
	local leader = obj.leader
	self.team = { users = userNames, leader = leader }
end

function Lobby:_OnLeftTeam(obj)
	local userName = obj.userName
	local reason = obj.reason
	if userName == self.myUserName then
		self.team = nil
	else
		for i, v in pairs(self.team.users) do
			if v == userName then
				table.remove(self.team.users, i)
				break
			end
		end
	end
end

------------------------
-- Misc
------------------------

function Lobby:_OnBattleDebriefing(url, chanName, serverBattleID, userList)
	self:_CallListeners("OnBattleDebriefing", url, chanName, serverBattleID, userList)
end

function Lobby:_OnLaunchRemoteReplay(url, game, map, engine)
	self:_CallListeners("OnLaunchRemoteReplay", url, game, map, engine)
end

-------------------------------------------------
-- END Server commands
-------------------------------------------------

-------------------------------------------------
-- BEGIN Connection handling TODO: This might be better to move into the shared interface
-------------------------------------------------

function Lobby:_OnDisconnected(reason, intentional)
	self:_CallListeners("OnDisconnected", reason, intentional)

	for userName,_ in pairs(self.users) do
		self:_OnRemoveUser(userName)
	end

	for battleID, battle in pairs(self.battles) do
		for _, useName in pairs(battle.users) do
			self:_OnLeftBattle(battleID, useName)
		end
		self:_OnBattleClosed(battleID)
	end

	self:_PreserveData()
	self:_Clean()
	self.disconnectTime = Spring.GetTimer()
end

function Lobby:Reconnect()
	self.lastReconnectionAttempt = Spring.GetTimer()
	self:Connect(self._oldData.host, self._oldData.port, self._oldData.loginData[1], self._oldData.loginData[2], self._oldData.loginData[3], self._oldData.loginData[4])
end

function Lobby:SafeUpdate(...)
	if (self.status == "disconnected" or self.status == "connecting") and self.disconnectTime ~= nil then
		local currentTime = Spring.GetTimer()
		if self.lastReconnectionAttempt == nil or Spring.DiffTimers(currentTime, self.lastReconnectionAttempt) > self.reconnectionDelay then
			self:Reconnect()
		end
	end
end

-------------------------------------------------
-- END Connection handling TODO: This might be better to move into the shared interface
-------------------------------------------------

-- will also create a channel if it doesn't already exist
function Lobby:_GetChannel(chanName)
	local channel = self.channels[chanName]
	if channel == nil then
		channel = { chanName = chanName }
		self.channels[chanName] = channel
		self.channelCount = self.channelCount + 1
	end
	return channel
end

function Lobby:GetUnusedTeamID()
	local unusedTeamID = 0
	local takenTeamID = {}
	for name, data in pairs(self.userBattleStatus) do
		local teamID = data.teamNumber
		if teamID and not data.isSpectator then
			takenTeamID[teamID] = true
			while takenTeamID[unusedTeamID] do
				unusedTeamID = unusedTeamID + 1
			end
		end
	end
	return unusedTeamID
end

-------------------------------------------------
-- BEGIN Data access
-------------------------------------------------

-- users
-- Returns all users, visible users
function Lobby:GetUserCount()
	if self.fullUserCount then
		return self.fullUserCount, self.userCount
	else
		return self.userCount, self.userCount
	end
end

-- gets the userInfo, or creates a new one with an offline user if it doesn't exist
function Lobby:TryGetUser(userName)
	local userInfo = self:GetUser(userName)
	if type(userName) ~= "string" then
		Spring.Log(LOG_SECTION, LOG.ERROR, "TryGetUser called with type: " .. tostring(type(userName)))
		Spring.Log(LOG_SECTION, LOG.ERROR, debug.traceback())
		return {}
	end
	if not userInfo then
		userInfo = {
			userName = userName,
			isOffline = true
		}
		self.users[userName] = userInfo
	end
	return userInfo
end

function Lobby:LearnAboutOfflineUser(userName, data)
	local userInfo = self:TryGetUser(userName)

	if not userInfo.isOffline then
		return
	end

	for key, value in pairs(data) do
		userInfo[key] = value
	end
end

function Lobby:GetUser(userName)
	return self.users[userName]
end

function Lobby:GetLowerCaseUser(userNameLC)
	return self.userNamesLC[userNameLC]
end

function Lobby:GetUserBattleStatus(userName)
	return self.userBattleStatus[userName]
end

-- returns users table (not necessarily an array)
function Lobby:GetUsers()
	return ShallowCopy(self.users)
end

function Lobby:GetSuggestedEngineVersion()
	return self.suggestedEngineVersion or false
end

function Lobby:GetSuggestedGameVersion()
	return self.suggestedGameVersion or false
end

function Lobby:GetUserNameBySteamID(steamID)
	return self.userBySteamID[steamID]
end

-- friends
function Lobby:GetFriendCount()
	return self.friendCount
end
-- returns friends table (not necessarily an array)
function Lobby:GetFriends()
	return ShallowCopy(self.friends)
end
function Lobby:GetFriendRequestCount()
	return self.friendRequestCount
end
-- returns friends table (not necessarily an array)
function Lobby:GetFriendRequests()
	return ShallowCopy(self.friendRequests)
end

-- ignore
function Lobby:GetignoredCount()
	return self.ignoredCount
end
function Lobby:Getignored()
	return ShallowCopy(self.ignored)
end

-- battles
function Lobby:GetBattleCount()
	return self.battleCount
end

function Lobby:GetBattle(battleID)
	return self.battles[battleID]
end

function Lobby:GetBattleHasFriend(battleID)
	local battle = self.battles[battleID]
	if battle and battle.users then
		for i = 1, #battle.users do
			if (self:TryGetUser(battle.users[i]) or {}).isFriend then
				return true
			end
		end
	end
	return false
end

function Lobby:GetBattlePlayerCount(battleID)
	local battle = self:GetBattle(battleID)
	if not battle then
		return 0
	end

	if battle.playerCount then
		return battle.playerCount
	else
		return #battle.users - battle.spectatorCount
	end
end

function Lobby:GetBattleFoundedBy(userName)
	-- TODO, improve data structures to make this search nice
	for battleID, battleData in pairs(self.battles) do
		if battleData.founder == userName then
			return battleID
		end
	end
	return false
end

-- returns battles table (not necessarily an array)
function Lobby:GetBattles()
	return ShallowCopy(self.battles)
end

-- queues
function Lobby:GetQueueCount()
	return self.queueCount
end
function Lobby:GetQueue(queueID)
	return self.queues[queueID]
end
-- returns queues table (not necessarily an array)
function Lobby:GetQueues()
	return ShallowCopy(self.queues)
end

function Lobby:GetJoinedQueues()
	return ShallowCopy(self.joinedQueues)
end

-- parties
function Lobby:GetUserParty(userName)
	local userInfo = self.users[userName]
	return userInfo and userInfo.partyID and self.partyMap[userInfo.partyID]
end

function Lobby:GetUserPartyID(userName)
	local userInfo = self.users[userName]
	return userInfo and userInfo.partyID
end

function Lobby:GetUsersShareParty(userOne, userTwo)
	local userInfoOne = self.users[userOne]
	local userInfoTwo = self.users[userTwo]
	return userInfoOne and userInfoTwo and userInfoOne.partyID and (userInfoOne.partyID == userInfoTwo.partyID)
end

-- team
function Lobby:GetTeam()
	return self.team
end

-- channels
function Lobby:GetChannelCount()
	return self.channelCount
end
function Lobby:GetChannel(channelName)
	return self.channels[channelName]
end

function Lobby:GetInChannel(chanName)
	for i, v in pairs(self.myChannels) do
		if v == chanName then
			return true
		end
	end
	return false
end

function Lobby:GetMyChannels()
	return self.myChannels
end
-- returns channels table (not necessarily an array)
function Lobby:GetChannels()
	return ShallowCopy(self.channels)
end

function Lobby:GetLatency()
	return self.latency
end

-- My data
function Lobby:GetScriptPassword()
	return self.scriptPassword or 0
end

-- My user
function Lobby:GetMyAllyNumber()
	if self.userBattleStatus[self.myUserName] then
		return self.userBattleStatus[self.myUserName].allyNumber
	end
end

function Lobby:GetMyTeamNumber()
	if self.userBattleStatus[self.myUserName] then
		return self.userBattleStatus[self.myUserName].teamNumber
	end
end

function Lobby:GetMyTeamColor()
	if self.userBattleStatus[self.myUserName] then
		return self.userBattleStatus[self.myUserName].teamColor
	end
end

function Lobby:GetMyIsSpectator()
	if self.userBattleStatus[self.myUserName] then
		return self.userBattleStatus[self.myUserName].isSpectator
	end
end

function Lobby:GetMySync()
	if self.userBattleStatus[self.myUserName] then
		return self.userBattleStatus[self.myUserName].sync
	end
end

function Lobby:GetMyIsReady()
	if self.userBattleStatus[self.myUserName] then
		return self.userBattleStatus[self.myUserName].isReady
	end
end

function Lobby:GetMySide()
	if self.userBattleStatus[self.myUserName] then
		return self.userBattleStatus[self.myUserName].side
	end
end

function Lobby:GetMyBattleID()
	return self.myBattleID
end

function Lobby:GetMyPartyID()
	return self.myPartyID
end

function Lobby:GetMyParty()
	local userInfo = self.users[self.myUserName]
	return userInfo and userInfo.partyID and self.partyMap[userInfo.partyID]
end

function Lobby:GetMyBattleModoptions()
	return self.modoptions
end

function Lobby:GetMyUserName()
	return self.myUserName
end

function Lobby:GetMyInfo()
	local userInfo = self.users[self.myUserName]
	return userInfo
end

function Lobby:GetMyFaction()
	if self.myUserName and self.users[self.myUserName] then
		return self.users[self.myUserName].faction
	end
	return false
end

function Lobby:GetFactionData(faction)
	return faction and self.planetwarsData.factionMap and self.planetwarsData.factionMap[faction]
end

function Lobby:GetPlanetwarsData()
	return self.planetwarsData
end

function Lobby:GetMySessionToken()
	return self.sessionToken
end

function Lobby:GetMyIsAdmin()
	if self.myUserName and self.users[self.myUserName] then
		return self.users[self.myUserName].isAdmin
	end
	return false
end

function Lobby:_GetPersistentUserInfo(userName)
	local oldUserInfo = self.users[userName]
	return {
		accountID   = oldUserInfo.accountID,
		steamID     = oldUserInfo.steamID,

		userName    = userName,
		country     = oldUserInfo.country,
		isAdmin     = oldUserInfo.isAdmin,
		level       = oldUserInfo.level,

		isOffline   = true,

		-- custom ZK
		clan        = oldUserInfo.clan,
		faction     = oldUserInfo.faction,

		skill       = oldUserInfo.skill,
		casualSkill = oldUserInfo.casualSkill,
		icon        = oldUserInfo.icon,
	}
end

-------------------------------------------------
-- END Data access
-------------------------------------------------

-------------------------------------------------
-- BEGIN Debug stuff
-------------------------------------------------

function Lobby:SetAllUserStatusRandomly()
	local status = {}
	for userName, data in pairs(self.users) do
		status.isAway = math.random() > 0.5
		status.isInGame = math.random() > 0.5
		self:_OnUpdateUserStatus(userName, status)
	end
end

function Lobby:SetAllUserAway(newAway)
	local status = {isAway = newAway}
	for userName, data in pairs(self.users) do
		self:_OnUpdateUserStatus(userName, status)
	end
end

-------------------------------------------------
-- END Debug stuff
-------------------------------------------------