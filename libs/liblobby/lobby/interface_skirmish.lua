InterfaceSkirmish = Lobby:extends()

function InterfaceSkirmish:init()
	self:super("init")
	self.name = "singleplayer"
	self.myUserName = "Player"
	self.useTeamColor = true
	self.startAllowed = true
end

function InterfaceSkirmish:WriteTable(key, value, tabs)
	local str = tabs..'['..key..']\n'..tabs..'{\n'

	-- First write Tables
	for k, v in pairs(value) do
		if type(v) == 'table' then
			str = str .. self:WriteTable(k, v, tabs .. '\t')
		end
	end

	-- Then the rest (purely for aesthetics)
	for k, v in pairs(value) do
		if type(v) ~= 'table' then
			str = str..tabs..'\t'..k..' = '..v..';\n'
		end
	end

	return str .. tabs .. '}\n'
end

function InterfaceSkirmish:MakeScriptTXT(script)
	local str = '[Game]\n{\n'

	-- First write Tables
	for key, value in pairs(script) do
		if type(value) == 'table' then
			str = str .. self:WriteTable(key, value, '\t') .. '\n'
		end
	end

	-- Then the rest (purely for aesthetics)
	for key, value in pairs(script) do
		if type(value) ~= 'table' then
			str = str..'\t'..key..' = '..value..';\n'
		end
	end
	str = str..'}'
	return str
end

function InterfaceSkirmish:_StartScript(gameName, mapName, playerName, friendList, friendsReplaceAI, hostPort, startPosType)
	if not self.startAllowed then
		Spring.Echo("Start blocked due to recent start")
		return false
	end
	local allyTeams = {}
	local allyTeamCount = 0
	local teams = {} -- OHO this is teams, not allyteams!
	local teamCount = 0
	local players = {} -- player can still be a spectator, thus not have a 'team'
	local playerCount = 0
	local maxAllyTeamID = -1
	local ais = {}
	local aiCount = 0

	friendList = friendList or {} -- we can safely say for that this will be empty for BAR
	local friendAllyTeam
	local aiReplaceCount = 0

	local defaultColor = '0.99609375 0.546875 0'
	local function getTeamColor(userName)
		if not self.useTeamColor then
			return defaultColor
		end

		local teamColor = self.userBattleStatus[userName].teamColor
		if teamColor == nil then
			return defaultColor
		end

		return tostring(teamColor[1]) .. " " .. tostring(teamColor[2]) .. " " .. tostring(teamColor[3])
	end

	local playerNames = {}
	-- Add the player, this is to make the player team 0.
	-- except that it doesnt actually work, and makes the player in the _last_ allyteam :/
	-- so we will rewrite it to reflect actual chobby single player setup

	for userName, data in pairs(self.userBattleStatus) do
		if data.allyNumber and not data.aiLib then --every player must have an allynumber!
			local sideData = WG.Chobby.Configuration:GetSideById(data.side)
			if sideData and sideData.requiresModoption and
			   (not self.modoptions or self.modoptions[sideData.requiresModoption] ~= "1") then
				data.side = math.random(0, 1)
			end
			players[playerCount] = {
				Name = userName,
				Team = teamCount,
				IsFromDemo = 0,
				Spectator = (data.isSpectator and 1) or nil,
				rank = 0,
			}
			playerNames[#playerNames+1] = userName

			if not data.isSpectator then
				teams[teamCount] = {
					TeamLeader = 0,
					AllyTeam = data.allyNumber,
					RgbColor = getTeamColor(userName),
					Side = WG.Chobby.Configuration:GetSideById(data.side).name,
					Handicap = data.handicap or 0,
				}
				maxAllyTeamID = math.max(maxAllyTeamID, data.allyNumber)
				teamCount = teamCount + 1
			end
			playerCount = playerCount + 1

			for i = 1, #friendList do
				local friendName = friendList[i]

				players[playerCount] = {
					Name = friendName,
					Team = data.allyNumber,
					IsFromDemo = 0,
					Spectator = (data.isSpectator and 1) or nil,
					Password = "12345",
					rank = 0,
				}

				if not data.isSpectator then
					teams[data.allyNumber] = {
						TeamLeader = playerCount,
						AllyTeam = data.allyNumber,
						RgbColor = getTeamColor(userName),
						Side = WG.Chobby.Configuration:GetSideById(data.side).name,
						Handicap = data.handicap or 0,
					}
					teamCount = teamCount + 1
					if friendsReplaceAI then
						friendAllyTeam = data.allyNumber
						aiReplaceCount = aiReplaceCount + 1
					end
				end
				playerCount = playerCount + 1
			end
		end
		--Spring.Echo("userName, data in pairs(self.userBattleStatus)", userName, data, Spring.Utilities.TableToString(data))
		--Spring.Echo("teams:", userName, data.allyNumber, Spring.Utilities.TableToString(teams[data.allyNumber]))
	end

	-- Check for chicken difficutly modoption. Possibly add an AI due to it.
	local chickenName
	if self.modoptions and self.modoptions.chickenailevel and self.modoptions.chickenailevel ~= "none" then
		chickenName = self.modoptions.chickenailevel
	end

	-- Add the AIs
	local chickenAdded = false
	for userName, data in pairs(self.userBattleStatus) do
		if data.allyNumber and data.aiLib then
			local sideData = WG.Chobby.Configuration:GetSideById(data.side)
			if sideData and sideData.requiresModoption and
			   (not self.modoptions or self.modoptions[sideData.requiresModoption] ~= "1") then
				data.side = 2 -- Random faction
			end
			if friendAllyTeam == data.allyNumber and aiReplaceCount > 0 and not string.find(data.aiLib, "Raptor") then
				aiReplaceCount = aiReplaceCount - 1
			else
				if chickenName and string.find(data.aiLib, "Raptor") then
					-- Override chicken AI if difficulty modoption is present
					ais[aiCount] = {
						Name = chickenName,
						Team = teamCount,
						--Team = data.allyNumber,
						IsFromDemo = 0,
						ShortName = chickenName,
						Host = 0,
					}
					chickenAdded = true
				else
					ais[aiCount] = {
						Name = userName,
						Team = teamCount,
						--Team = data.allyNumber,
						IsFromDemo = 0,
						ShortName = data.aiLib,
						Version = data.aiVersion,
						options = data.aiOptions,
						Host = 0,
					}
				end

				teams[teamCount] = {
					TeamLeader = 0,
					AllyTeam = data.allyNumber,
					RgbColor = getTeamColor(userName),
					Side = WG.Chobby.Configuration:GetSideById(data.side).name,
					Handicap = data.handicap or 0,
				}
				maxAllyTeamID = math.max(maxAllyTeamID, data.allyNumber)

				teamCount = teamCount + 1
				aiCount = aiCount + 1
			end
		end
	end

	-- Add chicken from the modoption if no chicken is present
	if chickenName and not chickenAdded then
		ais[aiCount] = {
			Name = chickenName,
			Team = teamCount,
			IsFromDemo = 0,
			ShortName = chickenName,
			Host = 0,
		}
		aiCount = aiCount + 1

		teams[teamCount] = {
			TeamLeader = 0,
			AllyTeam = maxAllyTeamID + 1,
			RgbColor = defaultColor,
		}
		maxAllyTeamID = maxAllyTeamID + 1
		teamCount = teamCount + 1
	end


	-- calc the number of allyTeamCount
	local allyTeamMap = {}
	for i, teamData in pairs(teams) do
		if not allyTeamMap[teamData.AllyTeam] then
			--Spring.Echo(teamData.AllyTeam,"not in allyTeamMap",allyTeamCount)
			allyTeamMap[teamData.AllyTeam] = teamData.AllyTeam
			allyTeamCount = allyTeamCount + 1
		end
		teamData.AllyTeam = allyTeamMap[teamData.AllyTeam]
		--Spring.Echo("calc the number of allyTeamCount=",allyTeamCount," teamData.Allyteam=", teamData.AllyTeam )
	end

	-- time to parse our nice boxen
	local Configuration = WG.Chobby.Configuration

	local startBoxes  = nil
	--if Configuration.gameConfig.mapStartBoxes then
	--  Spring.Echo("Number of mapStartBoxes is",#Configuration.gameConfig.mapStartBoxes, allyTeamCount)
	--end

	if Configuration.gameConfig and
		Configuration.gameConfig.useDefaultStartBoxes and
		Configuration.gameConfig.mapStartBoxes then
		if Configuration.gameConfig.mapStartBoxes.singleplayerboxes and next(Configuration.gameConfig.mapStartBoxes.singleplayerboxes) ~= nil then
			startBoxes = Configuration.gameConfig.mapStartBoxes.singleplayerboxes
			Spring.Echo("Skirmish: Using custom startboxes",startBoxes)
			--Spring.Echo(Spring.Utilities.TableToString(startBoxes))
		elseif Configuration.gameConfig.mapStartBoxes.savedBoxes and
			Configuration.gameConfig.mapStartBoxes.savedBoxes[mapName] then
			startBoxes = Configuration.gameConfig.mapStartBoxes.savedBoxes[mapName]
			Spring.Echo("Skirmish: Using default startboxes",startBoxes)
			startBoxes = Configuration.gameConfig.mapStartBoxes.selectStartBoxesForAllyTeamCount(startBoxes,allyTeamCount)
		end
	else
		Spring.Echo("No map startBoxes found or disabled for map",mapName)
	end

	for i, teamData in pairs(teams) do
		if not allyTeams[teamData.AllyTeam] then
		    if startBoxes then
				allyTeams[teamData.AllyTeam] = Configuration.gameConfig.mapStartBoxes.makeAllyTeamBox(startBoxes,teamData.AllyTeam)
		    else
				allyTeams[teamData.AllyTeam] = {
							numallies = 0,
						}
			end
		end
	end

	-- This kind of thing would prevent holes in allyTeams
	--local allyTeamMap = {}
	--for i, teamData in pairs(teams) do
	--	if not allyTeamMap[teamData.AllyTeam] then
	--		allyTeamMap[teamData.AllyTeam] = allyTeamCount
	--		allyTeams[allyTeamCount] = {
	--			numallies = 0,
	--		}
	--		allyTeamCount = allyTeamCount + 1
	--	end
	--	teamData.AllyTeam = allyTeamMap[teamData.AllyTeam]
	--end

	-- FIXME: I dislike treating rapid tags like this.
	-- We shouldn't give special treatment for rapid tags, and just use them interchangabily with normal archives.
	-- So we could just pass "rapid://tag:version" as gameName, while "tag:version" should be invalid.
	-- The engine treats rapid dependencies just like normal archives and I see no reason we do otherwise.
	if string.find(gameName, ":") and not string.find(gameName, "rapid://") then
		gameName = "rapid://" .. gameName
	end

	local numplayers = 0
	local foundname = false
	for _, name in pairs(playerNames) do
		numplayers = numplayers + 1
		if name == playerName then
			foundname = name
		end
	end
	
	if (foundname == false) and (numplayers == 1) then
		Spring.Echo("Found a different player name in skirmish startscript than reported by lobby. Fixing.", playername)
		if players[0] then players[0].Name = playerName end
	end

	local script = {
		gametype = gameName,
		hostip = "127.0.0.1",
		hostport = hostPort or 0,
		ishost = 1,
		mapname = mapName,
		myplayername = playerName,
		nohelperais = 0,
		numplayers = playerCount,
		numusers = playerCount + aiCount,
		startpostype = startPosType or 2,
		modoptions = self.modoptions,
		GameStartDelay = WG.Chobby.Configuration.devMode and 0 or 5,
	}

	for i, ai in pairs(ais) do
		script["ai" .. i] = ai
	end
	for i, player in pairs(players) do
		script["player" .. i] = player
	end
	for i, team in pairs(teams) do
		script["team" .. i] = team
	end
	for i, allyTeam in pairs(allyTeams) do
		script["allyTeam" .. i] = allyTeam
	end

	local scriptTxt = self:MakeScriptTXT(script)

	Spring.Echo(scriptTxt)
	--local scriptFileName = "scriptFile.txt"
	--local scriptFile = io.open(scriptFileName, "w")
	--scriptFile:write(scriptTxt)
	--scriptFile:close()

	local Config = WG.Chobby.Configuration
	if Config.multiplayerLaunchNewSpring then
		if WG.WrapperLoopback and WG.WrapperLoopback.StartNewSpring and WG.SettingsWindow and WG.SettingsWindow.GetSettingsString then
			local params = {
				StartScriptContent = scriptTxt,
				Engine = Config:GetTruncatedEngineVersion(),
				SpringSettings = WG.SettingsWindow.GetSettingsString(),
			}
			WG.WrapperLoopback.StartNewSpring(params)
			return
		end
	end

	local function ResetAllowStart()
		self.startAllowed = true
	end
	WG.Delay(ResetAllowStart, 10)

	local function DelayedStart()
		Spring.Reload(scriptTxt)
	end
	WG.Delay(DelayedStart, 0.4)

	self.startAllowed = false
end

function InterfaceSkirmish:StartReplay(replayFilename, myName, hostPort)
	if not self.startAllowed then
		Spring.Echo("Start blocked due to recent start")
		return false
	end
	local scriptTxt =
[[
[GAME]
{
	DemoFile=__FILE__;
	HostIP=__IP__;
	HostPort=__PORT__;
	MyPlayerName=__MY_PLAYER_NAME__;
	IsHost=1;
}
]]

	scriptTxt = scriptTxt:gsub("__FILE__", replayFilename)
                         :gsub("__IP__", "127.0.0.1")
                         :gsub("__MY_PLAYER_NAME__", myName or "(spec)")
                         :gsub("__PORT__", hostPort or 0)
	self:_CallListeners("OnBattleAboutToStart", "replay")

	Spring.Echo(scriptTxt)
	--local scriptFileName = "scriptFile.txt"
	--local scriptFile = io.open(scriptFileName, "w")
	--scriptFile:write(scriptTxt)
	--scriptFile:close()

	local function ResetAllowStart()
		self.startAllowed = true
	end
	WG.Delay(ResetAllowStart, 10)

	local function DelayedStart()
		Spring.Reload(scriptTxt)
	end
	WG.Delay(DelayedStart, 0.4)

	self.startAllowed = false
	return false
end

function InterfaceSkirmish:StartGameFromLuaScript(gameType, scriptTable, friendList, hostPort)
	if not self.startAllowed then
		Spring.Echo("Start blocked due to recent start")
		return false
	end
	self:_CallListeners("OnBattleAboutToStart", gameType)

	friendList = friendList or {}
	playerCount = 1 -- Local player is already present

	for i = 1, #friendList do
		local friendName = friendList[i]
		scriptTable["player" .. i] = {
			Name = friendName,
			Team = 0, -- Player is always team 0 (I hope)
			IsFromDemo = 0,
			Password = "12345",
			rank = 0,
		}
		playerCount = playerCount + 1
	end

	scriptTable.numplayers = playerCount
	scriptTable.numusers = (playerCount - 2) + scriptTable.numusers

	scriptTable.hostip = "127.0.0.1"
	scriptTable.hostport = hostPort or 0
	scriptTable.ishost = 1

	local scriptTxt = self:MakeScriptTXT(scriptTable)

	Spring.Echo(scriptTxt)
	--local scriptFileName = "scriptFile.txt"
	--local scriptFile = io.open(scriptFileName, "w")
	--scriptFile:write(scriptTxt)
	--scriptFile:close()

	local function ResetAllowStart()
		self.startAllowed = true
	end
	WG.Delay(ResetAllowStart, 10)

	local function DelayedStart()
		Spring.Reload(scriptTxt)
	end
	WG.Delay(DelayedStart, 0.4)
	self.startAllowed = false
end

function InterfaceSkirmish:StartGameFromString(scriptString, gameType)
	if not self.startAllowed then
		Spring.Echo("Start blocked due to recent start")
		return false
	end
	self:_CallListeners("OnBattleAboutToStart", gameType)
	local function ResetAllowStart()
		self.startAllowed = true
	end
	WG.Delay(ResetAllowStart, 10)

	local function DelayedStart()
		Spring.Reload(scriptString)
	end
	WG.Delay(DelayedStart, 0.4)
	self.startAllowed = false
	return false
end

function InterfaceSkirmish:StartGameFromFile(scriptFileName, gameType)
	self:_CallListeners("OnBattleAboutToStart", gameType)
	local function DelayedStart()
		if self.useSpringRestart then
			Spring.Restart(scriptFileName, "")
		else
			Spring.Start(scriptFileName, "")
		end
	end
	WG.Delay(DelayedStart, 0.5)
	return false
end

-- TODO: Needs clean implementation in lobby.lua
function InterfaceSkirmish:StartBattle(gameType, myName, friendList, friendsReplaceAI, hostPort)
	local battle = self:GetBattle(self:GetMyBattleID())
	if not battle.gameName then
		Spring.Log(LOG_SECTION, LOG.ERROR, "Missing battle.gameName. Game cannot start")
		return self
	end
	if not battle.mapName then
		Spring.Log(LOG_SECTION, LOG.ERROR, "Missing battle.mapName. Game cannot start")
		return self
	end

	self:_CallListeners("OnBattleAboutToStart", gameType, battle.gameName, battle.mapName)
	self:_OnSaidBattleEx("Battle", "about to start", battle.gameName, battle.mapName, myName)
	local function DelayedStart()
		self:_StartScript(battle.gameName, battle.mapName, myName, friendList, friendsReplaceAI, hostPort, battle.startPosType)
	end
	WG.Delay(DelayedStart, 0.5)
	return self
end

function InterfaceSkirmish:SelectMap(mapName)
	self:_OnUpdateBattleInfo(self:GetMyBattleID(), {
		mapName = mapName,
	})
end

-- Skirmish only
function InterfaceSkirmish:SetBattleState(myUserName, gameName, mapName, title)
	local myBattleID = 1

	-- Clear all data when a new battle is created
	self:_Clean()

	self.battleAis = {}
	self.userBattleStatus = {}

	self:_OnAddUser(myUserName)
	self.myUserName = myUserName
	--(battleID, type, natType, founder, ip, port, maxPlayers, passworded, rank, mapHash, other, engineVersion, mapName, title, gameName, spectatorCount)
	self:_OnBattleOpened(myBattleID, {
		founder = myUserName,
		users = {},
		gameName = gameName,
		mapName = mapName,
		title = title,
	})
	self:_OnJoinBattle(myBattleID, myUserName)
	self:_OnJoinedBattle(myBattleID, myUserName)
	local modoptions = {}
	if VFS.FileExists(LUA_DIRNAME .. "configs/testingModoptions.lua") then
		modoptions = VFS.Include(LUA_DIRNAME .. "configs/testingModoptions.lua")
	end
	self:_OnSetModOptions(modoptions)

	return self
end

-------------------------------------------------
-- BEGIN Client commands
-------------------------------------------------

function InterfaceSkirmish:AddAi(aiName, aiLib, allyNumber, version, aiOptions, battleStatusOptions)
	self:super("AddAi", aiName, aiLib, allyNumber, version, aiOptions, battleStatusOptions)
	self:_OnAddAi(self:GetMyBattleID(), aiName, {
		aiLib = aiLib,
		allyNumber = allyNumber,
		owner = self:GetMyUserName(),
		aiVersion = version,
		aiOptions = aiOptions,
		teamColor = battleStatusOptions and battleStatusOptions.teamColor,
		side = battleStatusOptions and battleStatusOptions.side,
		handicap = battleStatusOptions and battleStatusOptions.handicap,
	})
end

function InterfaceSkirmish:SayBattle(message)
	self:super("SayBattle", message)
	self:_OnSaidBattle(self:GetMyUserName(), message)
	return self
end

function InterfaceSkirmish:SayBattleEx(message)
	self:super("SayBattleEx", message)
	self:_OnSaidBattleEx(self:GetMyUserName(), message)
	return self
end

function InterfaceSkirmish:SetBattleStatus(status)
	self:super("SetBattleStatus", status)
	self:_OnUpdateUserBattleStatus(self:GetMyUserName(), status)
	return self
end

function InterfaceSkirmish:LeaveBattle()
	self:super("LeaveBattle")
	local myBattleID = self:GetMyBattleID()
	if myBattleID then
		self:_OnLeftBattle(myBattleID, self:GetMyUserName())
		self:_OnBattleClosed(myBattleID)
	end
	return self
end

function InterfaceSkirmish:RemoveAi(aiName)
	self:_OnRemoveAi(self:GetMyBattleID(), aiName)
	return self
end

function InterfaceSkirmish:UpdateAi(aiName, status)
	self:super("SetBattleStatus", status)
	self:_OnUpdateUserBattleStatus(aiName, status)
end

function InterfaceSkirmish:SetModOptions(data)
	self:_OnSetModOptions(data)
	return self
end

-------------------------------------------------
-- END Client commands
-------------------------------------------------

-------------------------------------------------
-- BEGIN Server commands
-------------------------------------------------

-------------------------------------------------
-- END Server commands
-------------------------------------------------

return InterfaceSkirmish
