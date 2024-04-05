-- The API is mostly inspired by the official Spring protocol with some major differences such as:
-- AI is used to denote a game AI, while bot is only used for automated lobby bots
-- TODO: rest

VFS.Include(LIB_LOBBY_DIRNAME .. "observable.lua")
VFS.Include(LIB_LOBBY_DIRNAME .. "utilities.lua")

local spJsonDecode = Spring.Utilities.json.decode
local spGetTimer = Spring.GetTimer
local spDiffTimers = Spring.DiffTimers

function Lobby:init()
	self.listeners = {}
	-- don't use these fields directly, they are subject to change
	self:_Clean()
end

function Lobby:_Clean()
	self.users = {} -- {username = {battlestatustable}}
	self.usersByID = {} -- map (currently serves as a translation from userID to userName.)
	self.userNamesLC = {} -- lookup table for (user name in lower Case) => userName
	-- self.userNamesQueued = {}
	self.userBySteamID = {}
	self.userCount = 0

	self.SOURCE_DISCORD = 0

	self.friends = {} -- list
	self.friendsByID = {} -- list
	self.isFriend = {} -- map
	self.isFriendByID = {} -- map
	self.friendRequests = {} -- list
	self.friendRequestsByID = {} -- list
	self.hasFriendRequest = {} -- map (maybe not needed at all?)
	self.outgoingFriendRequestsByID = {} -- list
	self.hasOutgoingFriendRequestsByID = {} -- map
	self.isDisregardedID = {} -- map

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

	self.team = nil

	self.latency = 0 -- in ms

	self.loginData = nil
	self.loginSent = nil
	self.myUserName = nil
	self.myChannels = {}
	self.myBattleID = nil
	self.scriptPassword = nil
	self.sessionToken = nil
	local am = Platform.macAddrHash or "0"
	local as = Platform.sysInfoHash or "0"
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
		myBattleID = self.myBattleID,
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
	if userName == self.myUserName then return end
	local userInfo = self:GetUser(userName)

	if not (userInfo and userInfo.accountID) then
		local function OnWhoisName(listener, name, userData)
			if name ~= userName then
				return
			end

			self:RemoveListener("OnWhoisName", listener)

			if userData.error then
				Spring.Log(LOG_SECTION, LOG.WARNING, "Couldn't add friend request for name=" .. tostring(userName) .. ".Server message:" .. tostring(userData.error))
			elseif not userData.id then
				Spring.Log(LOG_SECTION, LOG.ERROR, "Couldn't add friend request for name=" .. tostring(userName) .. ".Invalid server response (missing id)")
			else
				self:FriendRequestByID(userData.id)
			end
		end

		self:AddListener("OnWhoisName", OnWhoisName)
		self:WhoisName(userName)
		return
	end
	self:FriendRequestByID(userInfo.accountID)
	return self
end

function Lobby:FriendRequestByID(userID)
	return self
end

function Lobby:AcceptFriendRequest(userName)
	local user = self:GetUser(userName)
	if not (user and user.accountID) then
		return
	end

	self:AcceptFriendRequestByID(user.accountID)
	return self
end

function Lobby:AcceptFriendRequestByID(userID)
	return self
end

function Lobby:DeclineFriendRequest(userName)
	local user = self:GetUser(userName)
	if not (user and user.accountID) then
		return
	end
	self:DeclineFriendRequestByID(user.accountID)
	return self
end

function Lobby:DeclineFriendRequestByID(userID)
	return self
end

function Lobby:RescindFriendRequest(userName)
	local user = self:GetUser(userName)
	if not (user and user.accountID) then
		return
	end

	self:RescindFriendRequestByIDs({user.accountID})
	return self
end

function Lobby:RescindFriendRequestByIDs(userIDs)
	return self
end

function Lobby:Unfriend(userName, steamID)
	return self
end

function Lobby:RemoveFriends(userIDs)
	return self
end

------------------------
-- Battle commands
------------------------

-- unused in bar
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
	local myBattleID = self:GetMyBattleID()
	if myBattleID then
		self:_OnLeaveBattle(myBattleID)
	end
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
	local battle = self.battles[self.myBattleID] or {}
	gameName = gameName or battle.gameName
	mapName = mapName or battle.mapName

	if gameName and not VFS.HasArchive(gameName) then
		local error = "Cannot start game: missing game file '" .. gameName .. "'."
		Spring.Echo(error)
		WG.Chobby.InformationPopup(error)
		return
	end

	if mapName and not VFS.HasArchive(mapName) then
		local error = "Cannot start game: missing map file '" .. mapName .. "'."
		Spring.Echo(error)
		WG.Chobby.InformationPopup(error)
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
			if WG.Chobby and WG.Chobby.InformationPopup then
				WG.Chobby.InformationPopup("This battle uses a different engine, so it will be opened in a new window.")
				Spring.SetConfigInt("Fullscreen", 1, false)
				Spring.SetConfigInt("Fullscreen", 0, false)
			end
			Spring.PauseSoundStream()

			WG.WrapperLoopback.StartNewSpring(params)
		else
			local error = "Cannot start game: wrong Spring engine version. The required version is '" .. engineName .. "', your version is '" .. Spring.Utilities.GetEngineVersion() .. "'."
			Spring.Echo("Error")
			WG.Chobby.InformationPopup(error, {width = 420, height = 260})
		end
		return
	end
	Spring.Echo("Calling OnBattleAboutToStart Listeners...")
	self:_CallListeners("OnBattleAboutToStart", battleType)

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
-- MatchMaking commands (ZK only)
------------------------
--[[
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
--]]

------------------------
-- Party commands (ZK Only)
------------------------
--[[
function Lobby:InviteToParty(userName)
	return self
end

function Lobby:LeaveParty()
	return self
end

function Lobby:PartyInviteResponse(partyID, accepted)
	return self
end
--]]

------------------------
-- Steam commands (ZK only)
------------------------
--[[
function Lobby:SetSteamAuthToken(steamAuthToken)
	self.steamAuthToken = steamAuthToken
	return self
end

function Lobby:SetSteamDlc(steamDlc)
	self.steamDlc = steamDlc
	return self
end
--]]

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

function Lobby:_OnQueued()
	self:_CallListeners("OnQueued")
end

------------------------
-- User commands
------------------------

function Lobby:_OnAddUser(userName, status)
	if status and status.steamID then
		self.userBySteamID[status.steamID] = userName
	end

	-- ToDo: untested and therefore commented out:
	-- sb. changed userName
	-- if self.usersByID[status.accountID] and self.usersByID[status.accountID] ~= userName then
	-- 	self:_OnRemoveUser(self.usersByID[status.accountID])
	-- 	-- self.users[userName] = nil -- delete outdated user completly
	-- end

	local userInfo = self.users[userName]
	self.userCount = self.userCount + 1 -- correctly fix because lobby didnt clear user count on onAccepted
	if not userInfo then
		userInfo = {
			userName = userName,
			isFriend = status and status.accountID and self.isFriendByID[status.accountID] or false,
			hasFriendRequest = self.hasFriendRequest[userName],
			hasOutgoingFriendRequest = status and status.accountID and self.hasOutgoingFriendRequestsByID[status.accountID] or nil,
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

	if status and status.accountID then
		self.usersByID[userInfo.accountID] = userName
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

	-- preserve isFriend/hasFriendRequest/hasOutgoingFriendRequest
	local isFriend, hasFriendRequest, hasOutgoingFriendRequest = userInfo.isFriend, userInfo.hasFriendRequest, userInfo.hasOutgoingFriendRequest
	local persistentUserInfo = self:_GetPersistentUserInfo(userName)
	self.users[userName] = persistentUserInfo

	if isFriend or hasFriendRequest or hasOutgoingFriendRequest then
		userInfo = self:TryGetUser(userName)
		userInfo.isFriend         = isFriend
		userInfo.hasFriendRequest = hasFriendRequest
		userInfo.hasOutgoingFriendRequest = hasOutgoingFriendRequest
	end
	self.userCount = self.userCount - 1 -- this shows: userCount reflects the "online users"
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

-- reorder remaining queueList (called when a spec changes to player)
function Lobby:ReorderCurrentBattleQueue(userNameJoinedPlayers, oldQueuePos)
	local battleID = self:GetMyBattleID()

	local queueListUpdated = {} -- indexed table of usernames in queue

	local battleUsers = self.battles[battleID].users
	for _, battleUserName in pairs(battleUsers) do
		local queueNr = self.userBattleStatus[battleUserName] and self.userBattleStatus[battleUserName].queuePos or 0
		if queueNr > oldQueuePos then
			queueListUpdated[queueNr-1] = battleUserName
		elseif queueNr > 0 then
			queueListUpdated[queueNr] = battleUserName
		end
	end

	self:_OnUpdateBattleQueue(battleID, queueListUpdated)
end

function Lobby:_OnUpdateBattleQueue(battleID, userNamesQueued)
	for _, battleUserName in pairs(self.battles[battleID].users) do -- all users in battle
		local userInQueue = false
		local queueStatusOld = self.userBattleStatus[battleUserName] and self.userBattleStatus[battleUserName].queuePos or 0

		for posNew, userNameQueued in pairs(userNamesQueued) do -- test each battleUser if in the received queueList
			if battleUserName == userNameQueued then
				--if queueStatusOld ~= posNew or true then
				if queueStatusOld ~= posNew then
					self:_OnUpdateUserBattleStatus(battleUserName, {queuePos = posNew})
					userInQueue = true
					break
				else
					userInQueue = true
					break;
				end
			end
		end
		if userInQueue == false and queueStatusOld > 0 then
			self:_OnUpdateUserBattleStatus(battleUserName, {queuePos = 0})
		end
	end
	return
end

------------------------
-- Friend
------------------------

function Lobby:_OnFriend(userName, userID)
	self:_OnRemoveFriendRequestByID(userID)
	table.insert(self.friends, userName)
	table.insert(self.friendsByID, userID)
	self.isFriend[userName] = true
	local userInfo = self:TryGetUser(userName, userID)
	userInfo.isFriend = true
	self:_CallListeners("OnFriend", userName)
end

function Lobby:_OnFriendByID(userID)
	local userInfo = self:GetUserByID(userID)

	if not userInfo then

		local function OnWhois(listener, id, userData)
			if id ~= userID then
				return
			end

			self:RemoveListener("OnWhois", listener)

			if userData.error then
				Spring.Log(LOG_SECTION, LOG.WARNING, "Couldn't add friend with id=" .. tostring(userID) .. ".Server message:" .. tostring(userData.error))
			elseif not userData.name then
				Spring.Log(LOG_SECTION, LOG.ERROR, "Couldn't add friend with id=" .. tostring(userID) .. ".Invalid server response (missing username)")
			else
				self:_OnFriend(userData.name, userID)
			end
		end
		
		self:AddListener("OnWhois", OnWhois)
		self:Whois(userID)
		
		return
	end
	self:_OnFriend(userInfo.userName, userID)
end

function Lobby:_OnUnfriend(userName)
	local user = self:GetUser(userName)
	if not (user and user.accountID) then
		return
	end
	self:_OnUnfriendByID(user.accountID)
end

function Lobby:_OnUnfriendByID(userID)
	local user = self:GetUserByID(userID)
	if not user then
		return
	end

	local id = table.ifind(self.friends, user.userName)
	if not id then
		return
	end
	table.remove(self.friends, id)
	i = table.ifind(self.friendsByID, userID)
	table.remove(self.friendsByID, id)
	self.isFriend[user.userName] = false
	user.isFriend = false
	self:_CallListeners("OnUnfriendByID", userID, user.userName)
	self:_OnRemoveFriendRequestByID(userID)
end


function Lobby:_OnFriendList(friends)
	local newFriendMap = {}
	for i = 1, #friends do
		local userName = friends[i]
		if not self.isFriend[userName] then
			self:_OnFriend(userName)
		end
		newFriendMap[userName] = true
	end

	for _, userName in pairs(self.friends) do
		if not newFriendMap[userName] then
			self:_OnUnfriend(userName)
		end
	end

	self:_CallListeners("OnFriendList", self:GetFriends())
end

function Lobby:_OnFriendListByID(friendIDs)
	local newFriendMap = {}
	for i = 1, #friendIDs do
		local userID = tonumber(friendIDs[i])
		if not self.isFriendByID[userID] then
			self:_OnFriendByID(userID)
		end
		newFriendMap[userID] = true
	end

	for _, userID in pairs(self.friendsByID) do
		if not newFriendMap[userID] then
			self:_OnUnfriendByID(userID)
		end
	end
end

function Lobby:_OnFriendRequest(userName, userID)
	table.insert(self.friendRequests, userName)
	table.insert(self.friendRequestsByID, userID)
	self.hasFriendRequest[userName] = true
	local userInfo = self:TryGetUser(userName, userID)
	userInfo.hasFriendRequest = true
	self:_CallListeners("OnFriendRequest", userName)
end

function Lobby:_OnOutgoingFriendRequest(userName, userID)
	table.insert(self.outgoingFriendRequestsByID, userID)
	self.hasOutgoingFriendRequestsByID[userID] = true
	local userInfo = self:TryGetUser(userName, userID)
	userInfo.hasOutgoingFriendRequest = true
	self:_CallListeners("OnOutgoingFriendRequest", userName)
end

function Lobby:_OnFriendRequestByID(userID, newRequest)
	local userInfo = self:GetUserByID(userID)

	if not userInfo then

		local function OnWhois(listener, id, userData)
			if id ~= userID then
				return
			end

			self:RemoveListener("OnWhois", listener)

			if userData.error then
				Spring.Log(LOG_SECTION, LOG.WARNING, "Couldn't add friend request with id=" .. tostring(userID) .. ".Server message:" .. tostring(userData.error))
			elseif not userData.name then
				Spring.Log(LOG_SECTION, LOG.ERROR, "Couldn't add friend request with id=" .. tostring(userID) .. ".Invalid server response (missing username)")
			else
				self:_OnFriendRequest(userData.name, userID)
				if newRequest then
					self:_CallListeners("OnNewFriendRequestByID", userID, userData.name)
				end
			end
		end
		
		self:AddListener("OnWhois", OnWhois)
		self:Whois(userID)
		
		return
	end
	self:_OnFriendRequest(userInfo.userName, userID)
	if newRequest then
		self:_CallListeners("OnNewFriendRequestByID", userID, userInfo.userName)
	end
end

function Lobby:_OnOutgoingFriendRequestByID(userID)
	local userInfo = self:GetUserByID(userID)

	if not userInfo then

		local function OnWhois(listener, id, userData)
			if id ~= userID then
				return
			end

			self:RemoveListener("OnWhois", listener)

			if userData.error then
				Spring.Log(LOG_SECTION, LOG.WARNING, "Couldn't add outgoing friend request with id=" .. tostring(userID) .. ".Server message:" .. tostring(userData.error))
			elseif not userData.name then
				Spring.Log(LOG_SECTION, LOG.ERROR, "Couldn't add outgoing friend request with id=" .. tostring(userID) .. ".Invalid server response (missing username)")
			else
				self:_OnOutgoingFriendRequest(userData.name, userID)
			end
		end
		
		self:AddListener("OnWhois", OnWhois)
		self:Whois(userID)
		
		return
	end
	self:_OnOutgoingFriendRequest(userInfo.userName, userID)
end

function Lobby:_OnRemoveFriendRequestByID(userID)
	local user = self:GetUserByID(userID)
	if not user then
		return
	end

	local i = table.ifind(self.friendRequests, user.userName)
	if not i then
		return
	end
	table.remove(self.friendRequests, i)

	i = table.ifind(self.friendRequestsByID, userID)
	if not i then
		return
	end
	table.remove(self.friendRequestsByID, i)
	
	self.hasFriendRequest[user.userName] = false
	user.hasFriendRequest = false
	self:_CallListeners("OnRemoveFriendRequestByID", userID, user.userName)
end

function Lobby:_OnRemoveOutgoingFriendRequestByID(userID)
	local user = self:GetUserByID(userID)
	if not user then
		return
	end

	local i = table.ifind(self.outgoingFriendRequestsByID, userID)
	if not i then
		return
	end
	table.remove(self.outgoingFriendRequestsByID, i)
	self.hasOutgoingFriendRequestsByID[userID] = false

	user.hasOutgoingFriendRequest = false
	self:_CallListeners("OnRemoveOutgoingFriendRequestByID", userID, user.userName)
end

function Lobby:_OnFriendRequestAcceptedByID(userID)
	local user = self:GetUserByID(userID)
	if not user then
		return
	end
	self:_OnRemoveOutgoingFriendRequestByID(userID)
	self:_OnFriendByID(userID)
	self:_CallListeners("OnFriendRequestAcceptedByID", userID, user.userName)
end

function Lobby:_OnFriendRequestList(friendRequests)
	self.friendRequests = friendRequests
	for _, userName in pairs(self.friendRequests) do
		self.hasFriendRequest[userName] = true
		local userInfo = self:TryGetUser(userName)
		userInfo.hasFriendRequest = true
	end

	self:_CallListeners("OnFriendRequestList", self:GetFriendRequests())
end

function Lobby:_OnFriendRequestListByID(friendRequests)
	local newFriendMap = {}
	for i = 1, #friendRequests do
		local userID = tonumber(friendRequests[i])
		if not self.friendRequestsByID[userID] then
			self:_OnFriendRequestByID(userID)
		end
		newFriendMap[userID] = true
	end

	for _, userID in pairs(self.friendRequestsByID) do
		if not newFriendMap[userID] then
			self:_OnRemoveFriendRequest(userID)
		end
	end
end

function Lobby:_OnOutgoingFriendRequestsByID(friendRequests)
	local newFriendMap = {}
	for i = 1, #friendRequests do
		local userID = tonumber(friendRequests[i])
		if not self.hasOutgoingFriendRequestsByID[userID] then
			self:_OnOutgoingFriendRequestByID(userID)
		end
		newFriendMap[userID] = true
	end

	for _, userID in pairs(self.outgoingFriendRequestsByID) do
		if not newFriendMap[userID] then
			self:_OnRemoveOutgoingFriendRequest(userID)
		end
	end
end

function Lobby:_OnAcceptFriendRequestByID(userID)
	self:_OnRemoveFriendRequestByID(userID)
	self:_OnFriendByID(userID)
end

function Lobby:_OnDeclineFriendRequestByID(userID)
	self:_OnRemoveFriendRequestByID(userID)
end

function Lobby:_OnRescindFriendRequestByID(userID)
	self:_OnRemoveOutgoingFriendRequestByID(userID)
end

function Lobby:_OnFriendRequestDeclinedByID(userID)
	self:_OnRemoveOutgoingFriendRequestByID(userID)
end

------------------------
-- Disregard (Ignore/Avoid/Block)
------------------------

function Lobby:_OnDisregard(userName, status)
	local userInfo = self:GetUser(userName)
	if not userInfo then
		Spring.Log(LOG_SECTION, LOG.ERROR, "Couldn't add disregard for username=" .. tostring(userName) .. " - userName not known.")
		return
	end
	self.isDisregardedID[userInfo.accountID] = status
	userInfo.isDisregarded = status
	self:_CallListeners("OnAddDisregardUser", userName)
end

function Lobby:_OnUnDisregard(userName)
	local userInfo = self:GetUser(userName)
	if not userInfo then
		Spring.Log(LOG_SECTION, LOG.ERROR, "Couldn't remove disregard for username=" .. tostring(userName) .. " - userName not known.")
		return
	end
	if not self.isDisregardedID[userInfo.accountID] then
		return
	end
	self.isDisregardedID[userInfo.accountID] = nil
	userInfo.isDisregarded = nil
	self:_CallListeners("OnRemoveDisregardUser", userName)
end

function Lobby:_OnDisregardID(userID, status)
	self.isDisregardedID[userID] = status
	local userInfo = self:GetUserByID(userID)
	if not userInfo then

		local function OnWhois(listener, id, userData)
			if id ~= userID then
				return
			end

			self:RemoveListener("OnWhois", listener)

			if userData.error then
				Spring.Log(LOG_SECTION, LOG.WARNING, "Couldn't add disregarded user with id=" .. tostring(userID) .. ".Server message:" .. tostring(userData.error))
			elseif not userData.name then
				Spring.Log(LOG_SECTION, LOG.ERROR, "Couldn't add disregarded user  with id=" .. tostring(userID) .. ".Invalid server response (missing username)")
			else
				userInfo = self:GetUserByID(userID)
				userInfo.isDisregarded = status
				self:_CallListeners("OnAddDisregardUser", userInfo.userName)
			end
		end
		
		self:AddListener("OnWhois", OnWhois)
		self:Whois(userID)
		
		return
	end
	userInfo.isDisregarded = status
	self:_CallListeners("OnAddDisregardUser", userInfo.userName)
end

function Lobby:_OnUnDisregardID(userID)
	if not self.isDisregardedID[userID] then
		return
	end

	self.isDisregardedID[userID] = nil
	local userInfo = self:GetUserByID(userID) -- don't need to create offline users in this case
	if userInfo then
		userInfo.isDisregarded = nil
	end
	self:_CallListeners("OnRemoveDisregardUser", userInfo.userName)
end

function Lobby:_OnDisregardListID(disregards)
	local newDisregardedMapID = {}
	for i = 1, #disregards do
		local userID = disregards[i].userID
		local status = disregards[i].status
		if not self.isDisregardedID[userID] or self.isDisregardedID[userID] ~= status then
			self:_OnDisregardID(userID, status)
		end
		newDisregardedMapID[userID] = true
	end

	for userID in pairs(self.isDisregardedID) do
		if not newDisregardedMapID[userID] then
			self:_OnUnDisregardID(userID)
		end
	end
end

------------------------
-- Battle commands
------------------------

function Lobby:_OnBattleIngameUpdate(battleID, isRunning)
	if self.battles[battleID] and self.battles[battleID].isRunning ~= isRunning then
		local battleInfo = self.battles[battleID]
		if self.battles[battleID].isRunning ~= nil then
			if isRunning then -- switching to running state
				-- 2023-10-02 FB: disabled one-time requests until timestamp of incoming protocol messages are stored during ingame-buffering
				--                if we store the times here, they get applied on unbuffering and leading to totally wrong timestamps
				-- battleInfo.thisGameStartedAt = os.clock()
				battleInfo.thisGameStartedAt = nil
			else -- switching to lobby state
				-- 2023-10-02 FB: disabled one-time requests until timestamp of incoming protocol messages are stored during ingame-buffering
				--                if we store the times here, they get applied on unbuffering and leading to totally wrong timestamps
				-- battleInfo.lastGameEndedAt = os.clock()
				battleInfo.lastGameEndedAt = nil
				battleInfo.thisGameStartedAt = nil
			end
			self:super("_OnUpdateBattleInfo", battleID, battleInfo)
		end

		battleInfo.isRunning = isRunning -- sets self.battles[battleID].isRunning
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
		-- runningSince = battle.runningSince,
		-- battleMode = battle.battleMode,
		-- disallowCustomTeams = battle.disallowCustomTeams,
		-- disallowBots = battle.disallowBots,
		-- isMatchMaker = battle.isMatchMaker,
	}
	self.battleCount = self.battleCount + 1

	self:_CallListeners("OnBattleOpened", battleID, self.battles[battleID])
end

function Lobby:_OnBattleClosed(battleID)

	if not (battleID and self.battles[battleID]) then
		Spring.Log(LOG_SECTION, LOG.ERROR, "Lobby:_OnBattleClosed: Tried to close unknown battle " .. tostring(battleID))
		return
	end
	local battle = self.battles[battleID]

	local battleusers = ShallowCopy(battle.users) -- needs ShallowCopy because _OnLeftBattle is modifying self.battles[battleID].users
	for _, userName in pairs(battleusers) do
		self:_OnLeftBattle(battleID, userName)
	end
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
	local battle = self.battles[battleID]
	if not battle then
		Spring.Log(LOG_SECTION, LOG.WARNING, "_OnJoinedBattle nonexistent battle.")
		return
	end
	local found = false
	local users = battle.users
	for i = 1, #users do
		if users[i] == userName then
			found = true
			break
		end
	end
	battle.spectatorCount = math.max(1, battle.spectatorCount or 1)

	if not found then
		table.insert(battle.users, userName)
	end

	local userInfo = self:TryGetUser(userName)
	userInfo.battleID = battleID
	if userInfo.isOffline == true then
		Spring.Log(LOG_SECTION, LOG.ERROR,
		"Lobby:_OnJoinedBattle: Added unknown user " .. userName .. " to battle: " .. tostring(battleID))
	end

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
			"Lobby:_OnLeftBattle: Tried to remove user " .. userName .. " from unknown battle: " .. tostring(battleID))
		return
	end
	local battle = self.battles[battleID]

	-- remove userName from userBattleStatus
	if self.userBattleStatus[userName] then
		self.userBattleStatus[userName] = nil
	end

	local battleUsers = battle.users
	for i, v in pairs(battleUsers) do
		if v == userName then
			table.remove(battleUsers, i)
			break
		end
	end

	battle.spectatorCount = math.max(1, battle.spectatorCount or 1)

	self.users[userName].battleID = nil
	self:_CallListeners("OnUpdateUserStatus", userName, {battleID = false})

	self:_CallListeners("OnLeftBattle", battleID, userName)
end

-- spectatorCount, locked, mapHash, mapName, engineVersion, runningSince, gameName, battleMode, disallowCustomTeams, disallowBots, maxPlayers, title, playerCount, passworded
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
	else
		battle.locked = false
	end

	if battleInfo.boss ~= nil then
		battle.boss = battleInfo.boss
	end
	battle.autoBalance = battleInfo.autoBalance or battle.autoBalance
	battle.teamSize = battleInfo.teamSize or battle.teamSize
	battle.nbTeams = battleInfo.nbTeams or battle.nbTeams
	battle.balanceMode = battleInfo.balanceMode or battle.balanceMode
	battle.preset = battleInfo.preset or battle.preset

	battle.lastGameEndedAt = battleInfo.lastGameEndedAt or battle.lastGameEndedAt
	battle.thisGameStartedAt = battleInfo.thisGameStartedAt or battle.thisGameStartedAt
	battle.spadsStatusRequested = battleInfo.spadsStatusRequested or battle.spadsStatusRequested

	-- ZK specific
	-- battle.runningSince = battleInfo.runningSince or battle.runningSince
	-- battle.battleMode = battleInfo.battleMode or battle.battleMode
	-- if battleInfo.disallowCustomTeams ~= nil then
	-- 	battle.disallowCustomTeams = battleInfo.disallowCustomTeams
	-- end
	-- if battleInfo.disallowBots ~= nil then
	-- 	battle.disallowBots = battleInfo.disallowBots
	-- end
	-- if battleInfo.isMatchMaker ~= nil then
	-- 	battle.isMatchMaker = battleInfo.isMatchMaker
	-- end

	self:_CallListeners("OnUpdateBattleInfo", battleID, battleInfo)
end

-- id must be 1, otherwise some properties return wrong values
local JSONRPCBATTLE = '!#JSONRPC {"jsonrpc": "2.0", "method": "status", "params": ["game"], "id": 1}'
function Lobby:RequestSpadsGameStatus(founder)
	self:SayPrivate(founder, JSONRPCBATTLE)
end

-- id must be 1, otherwise some properties return wrong values
local JSONRPCBATTLE = '!#JSONRPC {"jsonrpc": "2.0", "method": "status", "params": ["battle"], "id": 1}'
function Lobby:RequestSpadsBattleStatus(founder)
	self:SayPrivate(founder, JSONRPCBATTLE)
end

function Lobby:_OnUpdateBattleTitle(battleID, battleTitle)
	local battle = self.battles[battleID]
	if not battle then
		Spring.Log(LOG_SECTION, "warning", "_OnUpdateBattleTitle nonexistent battle.", battleID)
		return
	end
	battle.title = battleTitle or battle.title
	self:_CallListeners("OnUpdateBattleTitle", battleID, battleTitle)
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
				--changed = changed or changedSub
			else
				changedSub = true
			end
		else
			-- Spring.Echo("uVal:", uVal, " oVal:", oVal, uVal ~= oVal)
			changedSub = uVal ~= oVal
		end

		if changedSub then
			rawset(diff, uKey, uVal)
			rawset(origin, uKey, uVal) -- this is the place where origin is updated, e.g. battleStatus in _UpUpdateUserBattleStatus, which is self.userBattleStatus[userName]
		end
		changed = changed or changedSub
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
	-- local debugisReady = battleStatus.isReady
	
	local oldQueuePos = battleStatus.queuePos
	local battleStatusDiff, changed = getDiffAndSetNewValuesToTable(battleStatus, statusNew) -- use battleStatusDiff instead of statusNew to only propagate battleStatus properties, that really changed or which are new properties

	if changed then
		if battleStatusDiff.isSpectator ~= nil and battleStatusDiff.isSpectator == false and battleStatus.queuePos and battleStatus.queuePos ~= 0 then
			battleStatus.queuePos = 0 -- always change queuePos to 0, if we switch from spec to player = prevent showing queuePos e.g. in playerbattelist, if we didn't receive the queue-update from server yet
			battleStatusDiff.queuePos = 0
		end

		self:_CallListeners("OnUpdateUserBattleStatus", userName, battleStatusDiff)

		if battleStatusDiff.allyNumber or battleStatusDiff.isSpectator ~= nil or battleStatusDiff.queuePos then
			self:_CallListeners("OnUpdateUserTeamStatus", userName, battleStatus.allyNumber, battleStatus.isSpectator, battleStatus.queuePos)
		end

		-- call ReorderCurrentBattleQueue last here, because it calls _OnUpdateUserBattleStatus again (for other users);
		-- so we want listeners of this OnUpdateUserBattleStatus have finished before
		-- reorder , because we don't necessarily receive an update of queuelist from server
		if battleStatusDiff.isSpectator ~= nil and battleStatusDiff.isSpectator == false and battleStatusDiff.queuePos and battleStatusDiff.queuePos == 0 then
			self:ReorderCurrentBattleQueue(userName, oldQueuePos) 
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
	-- parse votes (yes|no|blank)
	local messageL = message:lower()
	if messageL:match("^!vote yes$") or messageL:match("^!vote y$") or messageL:match("^!yes$") or messageL:match("^!y$") then
		self:_OnUserVoted(userName, "yes")
	elseif messageL:match("^!vote no$") or messageL:match("^!vote n$") or messageL:match("^!no$") or messageL:match("^!n$") then
		self:_OnUserVoted(userName, "no")
	elseif messageL:match("^!vote blank$") or messageL:match("^!vote b$") or messageL:match("^!blank$") or messageL:match("^!b$") then
		self:_OnUserVoted(userName, "blank")
	end

	self:_CallListeners("OnSaidBattle", userName, message, sayTime)
end

-- message = {"BattleStateChanged": {"locked": "locked", "autoBalance": "advanced", "teamSize": "8", "nbTeams": "2", "balanceMode": "clan;skill", "preset": "team", "boss": "Fireball"}}
function Lobby:ParseBarManager(battleID, message)
	local battleInfo = {}
	local barManagerSettings = spJsonDecode(message)
	if not barManagerSettings['BattleStateChanged'] then
		return battleInfo
	end
	
	for k, v in pairs(barManagerSettings['BattleStateChanged']) do
		if k == "boss" and v == "" then
			battleInfo[k] = false
		elseif WG.Chobby.Configuration.barMngSettings[k] then
			battleInfo[k] = v
		end
	end
	return battleInfo
end

function Lobby:_OnSaidBattleEx(userName, message, sayTime)
	
	local found, bmMessage = startsWith(message, WG.Chobby.Configuration.BTLEX_BARMANAGER)
	if found then
		local battleID = self.users[userName] and self.users[userName].battleID
		if not battleID then
			Spring.Log(LOG_SECTION, LOG_WARNING, "couldn't match barmanager message to any known battle", tostring(founder))
			return
		end
		local battleInfo = self:ParseBarManager(battleID, bmMessage)
		if next(battleInfo) then
			self:super("_OnUpdateBattleInfo", battleID, battleInfo)
			-- 2023-07-04 FB: For now: proceed with CallListeners of SaidBattleEx, because gui_battle_room has its own parsing of barmanager message
			-- return
		end
	end
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

function Lobby:_OnUserVoted(userName, voteOption)
	self:_CallListeners("OnUserVoted", userName, voteOption)
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

local function RpcGetGameStatus(rpc)
	return rpc and rpc.result and rpc.result.game and rpc.result.game.status
end

local function RpcGetBattleStatus(rpc)
	return rpc and rpc.result and rpc.result.battleLobby and rpc.result.battleLobby.status
end

-- fetch (battleStatus and delaySinceLastGame) or (gameStatus and gameTime)
-- returns
-- 1. status = nil | lobby | pregame | running
-- 2. lastGameEndedAt = nil | timestamp
-- 3. thisGameStartedAt = nil | timestamp
function Lobby:ParseRPC(json)
	local status = nil
	local thisGameStartedAt = nil
	local lastGameEndedAt = nil

	local rpc = spJsonDecode(json)
	local statusRpc = RpcGetGameStatus(rpc) or RpcGetBattleStatus(rpc)
	
	if statusRpc then
		if statusRpc.gameTime and statusRpc.gameStatus then -- it's an answer to "status game"
			thisGameStartedAt = math.floor(os.clock() - statusRpc.gameTime)
			status = statusRpc.gameStatus == "waiting" and "pregame" or "running" -- "waiting" = startpos_choosing or "running"
		elseif statusRpc.battleStatus then -- it's an answer to "status battle"
			if statusRpc.delaySinceLastGame then
				lastGameEndedAt = math.floor(os.clock() - statusRpc.delaySinceLastGame)
				status = statusRpc.battleStatus == "waiting" and "lobby" or nil -- ("waiting" = in lobby) or ("running" = not in lobby (could be pregame or running, we don't know !!!))
			else -- battles without previously running battles return null
				lastGameEndedAt = "unknown" -- displayed in gui_tooltip as a new lobby
			end
		else
			-- this case does not normally occur: it's indicating that sth. unexpected was received
			Spring.Log(LOG_SECTION, LOG.ERROR, "Error parsing rpc spads message: \n" ..  json)
		end
	-- (else) "statusRpc" is nil if we ask for "status game" while the game is not running, so it's ok to stay with nil for thisGameStartedAt

	end
	return status, lastGameEndedAt, thisGameStartedAt
end


local MSG_PREFIX_JSONRPC = "!#JSONRPC "
function Lobby:_OnSaidPrivate(userName, message, sayTime)
	local found, json = startsWith(message, MSG_PREFIX_JSONRPC)
	if found then
		local battleID = self.users[userName] and self.users[userName].battleID
		local battle = self.battles[battleID] or {}
		local isFounder = battle.founder == userName

		if isFounder then -- this message came from battle founder
			local status, lastGameEndedAt, thisGameStartedAt = self:ParseRPC(json) -- ignore status: It's not used so far, it can give one additional info, that is pregame state - but it would need to be asked over and over again to use it as a precice state
			lastGameEndedAt = lastGameEndedAt or self.battles[battleID].lastGameEndedAt -- use existing value if parsing returned nil (don't overwrite existing values by nil)
			thisGameStartedAt = thisGameStartedAt or self.battles[battleID].thisGameStartedAt -- use existing value if parsing returned nil (don't overwrite existing values by nil)
			if lastGameEndedAt ~= self.battles[battleID].lastGameEndedAt or thisGameStartedAt ~= self.battles[battleID].thisGameStartedAt then
				local battleInfo = {lastGameEndedAt = lastGameEndedAt, thisGameStartedAt = thisGameStartedAt}
				self:super("_OnUpdateBattleInfo", battleID, battleInfo)
			end
		end
		return self -- hide this message
	end
	self:_CallListeners("OnSaidPrivate", userName, message, sayTime)
end

function Lobby:_OnSaidPrivateEx(userName, message, sayTime)
	self:_CallListeners("OnSaidPrivateEx", userName, message, sayTime)
end

function Lobby:_OnSayPrivate(userName, message, sayTime)
	if startsWith(message, MSG_PREFIX_JSONRPC) then
		return self
	end
	self:_CallListeners("OnSayPrivate", userName, message, sayTime)
end

function Lobby:_OnSayPrivateEx(userName, message, sayTime)
	self:_CallListeners("OnSayPrivateEx", userName, message, sayTime)
end

function Lobby:_OnSayServerMessage(message, sayTime)
	self:_CallListeners("OnSayServerMessage", message, sayTime)
end

------------------------
-- MatchMaking commands (ZK only)
------------------------
--[[
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
			self.joinedQueues[joinedQueueList[i] ] = true
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
--]]

------------------------
-- Party commands (ZK only)
------------------------
--[[
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
--]]

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
		self:_OnBattleClosed(battleID)
	end

	self:_PreserveData()
	self:_Clean()
	self.lastReconnectionAttempt = nil
	self.disconnectTime = Spring.GetTimer()
	self.disconnectTimeDelay = math.random()
end

function Lobby:Reconnect()
	self.lastReconnectionAttempt = Spring.GetTimer()
	self:Connect(self._oldData.host, self._oldData.port, self._oldData.loginData[1], self._oldData.loginData[2], self._oldData.loginData[3], self._oldData.loginData[4])
end

function Lobby:SafeUpdate(...)
	if (self.status == "disconnected" or self.status == "connecting") and self.disconnectTime ~= nil then
		local currentTime = Spring.GetTimer()

		-- We must prevent users from immediately reconnecting upon a disconnect!
		local timeSinceDisconnect
		if self.disconnectTime then 
			timeSinceDisconnect = Spring.DiffTimers(currentTime, self.disconnectTime)
		end

		local timeSinceReconnectionAttempt
		if self.lastReconnectionAttempt then
			timeSinceReconnectionAttempt = Spring.DiffTimers(currentTime, self.lastReconnectionAttempt)
		end
		
		local totalHideInterface = WG and WG.CheckTotalHideInterface and WG.CheckTotalHideInterface()

		--Spring.Echo("Lobby:SafeUpdate:", string.format("ingame = %s, tDC = %s, tRC = %s, rmul =%s", tostring(totalHideInterface), tostring(timeSinceDisconnect),tostring(timeSinceReconnectionAttempt), tostring(self.disconnectTimeDelay) ))

		-- This needs additional leeway to prevent everyone from hammering back in. 
		if timeSinceDisconnect then 
			if totalHideInterface then 
				-- we are probably ingame, so wait 60 + 240 * random secs to reconnect. (1-5 minutes)
				if timeSinceDisconnect < 60 + self.disconnectTimeDelay * 240 then 
					return 
				end
			else
				-- We are probably just in the lobby, and need to wait at least 20 seconds for the server to flush the cache and allow us back in.
				if timeSinceDisconnect < 25 + self.disconnectTimeDelay * 35 then 
					return 
				end
			end
		end

		-- Reconnect if we havent tried to reconnect, and also reconnect if more than reconnectionDelay secs have passed since lastReconnectionAttempt
		if self.lastReconnectionAttempt == nil or (Spring.DiffTimers(currentTime, self.lastReconnectionAttempt) > self.reconnectionDelay) then
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

function Lobby:GetUserId(userName)
	return self
end

-- Returns all users, visible users
function Lobby:GetUserCount()
	return self.userCount
end

-- gets the userInfo, or creates a new one with an offline user if it doesn't exist
function Lobby:TryGetUser(userName, userID)
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
	if userID then
		userInfo.accountID = userID
		self.usersByID[userID] = userName
	end
	return userInfo
end

function Lobby:Whois(userID)
	return self
end

function Lobby:_OnWhois(id, userData)
	local userInfo = self:GetUserByID(id)
	if not userInfo and not userData.error then
		userInfo = {
			isOffline = true,
			accountID = id,
		}
		self.users[userData.name] = userInfo
		self.usersByID[id] = userData.name
	end
	userInfo.userName = userData.name
	self:_CallListeners("OnWhois", id, userData)
end

function Lobby:WhoisName(userName)
	return self
end

function Lobby:_OnWhoisName(userName, userData)
	self:_CallListeners("OnWhoisName", userName, userData)
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

function Lobby:GetUserByID(userID)
	return self.usersByID[userID] and self.users[self.usersByID[userID]]
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
	return #self.friendsByID
end
-- returns friends table (not necessarily an array)
function Lobby:GetFriends()
	return ShallowCopy(self.friends)
end

function Lobby:GetFriendsByID()
	return ShallowCopy(self.friendsByID)
end

function Lobby:GetFriendRequestCount()
	return #self.friendRequestsByID
end
-- returns friends table (not necessarily an array)
function Lobby:GetFriendRequests()
	return ShallowCopy(self.friendRequests)
end

function Lobby:GetOutgoingFriendRequestsByID()
	return ShallowCopy(self.outgoingFriendRequestsByID)
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
		return math.max(0, battle.playerCount)
	else
		-- right now, the number of players cannot ever be more than the number of users - 1 (spads is always a spec)
		local playerCount = #battle.users - battle.spectatorCount
		--[[
			if battle.spectatorCount < 1 or playerCount > 16 or playerCount < 0 then 
				local users = ""
				for i, user in ipairs(battle.users) do
					users = users .. "," .. user
				end
				local s = string.format("GetBattlePlayerCount(ID: %s) #users = %d, #specs = %d, #players = %d, %s", battleID, #battle.users, battle.spectatorCount, playerCount, users)
				Spring.Echo(s)
			end
		--]]
		return math.max(0, playerCount)
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