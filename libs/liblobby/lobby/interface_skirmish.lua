InterfaceSkirmish = Lobby:extends()

function InterfaceSkirmish:init()
	self:super("init")
	self.name = "singleplayer"
	self.myUserName = "Player"
	self.useTeamColor = true
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

function InterfaceSkirmish:_StartScript(gameName, mapName, playerName, friendList, friendsReplaceAI, hostPort)
	local allyTeams = {}
	local allyTeamCount = 0
	local teams = {}
	local teamCount = 0
	local players = {}
	local playerCount = 0
	local maxAllyTeamID = -1
	local ais = {}
	local aiCount = 0

	friendList = friendList or {}
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

	-- Add the player, this is to make the player team 0.
	for userName, data in pairs(self.userBattleStatus) do
		if data.allyNumber and not data.aiLib then
			players[playerCount] = {
				Name = userName,
				Team = teamCount,
				IsFromDemo = 0,
				Spectator = (data.isSpectator and 1) or nil,
				rank = 0,
			}

			if not data.isSpectator then
				teams[teamCount] = {
					TeamLeader = 0,
					AllyTeam = data.allyNumber,
					RgbColor = getTeamColor(userName),
				}
				maxAllyTeamID = math.max(maxAllyTeamID, data.allyNumber)
				teamCount = teamCount + 1
			end
			playerCount = playerCount + 1

			for i = 1, #friendList do
				local friendName = friendList[i]

				players[playerCount] = {
					Name = friendName,
					Team = teamCount,
					IsFromDemo = 0,
					Spectator = (data.isSpectator and 1) or nil,
					Password = "12345",
					rank = 0,
				}

				if not data.isSpectator then
					teams[teamCount] = {
						TeamLeader = playerCount,
						AllyTeam = data.allyNumber,
						RgbColor = getTeamColor(userName),
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
			if friendAllyTeam == data.allyNumber and aiReplaceCount > 0 and not string.find(data.aiLib, "Chicken") then
				aiReplaceCount = aiReplaceCount - 1
			else
				if chickenName and string.find(data.aiLib, "Chicken") then
					-- Override chicken AI if difficulty modoption is present
					ais[aiCount] = {
						Name = chickenName,
						Team = teamCount,
						IsFromDemo = 0,
						ShortName = chickenName,
						Host = 0,
					}
					chickenAdded = true
				else
					ais[aiCount] = {
						Name = userName,
						Team = teamCount,
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
					Side = data.side,
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
      allyTeamMap[teamData.AllyTeam] = allyTeamCount
      allyTeamCount = allyTeamCount + 1
    end
    teamData.AllyTeam = allyTeamMap[teamData.AllyTeam]
	end
  
  -- time to parse our nice boxen
  local Configuration = WG.Chobby.Configuration
  
  local startBoxes  = nil
  --if Configuration.gameConfig.mapStartBoxes then
  --  Spring.Echo("Number of mapStartBoxes is",#Configuration.gameConfig.mapStartBoxes, allyTeamCount)
  --end
  if Configuration.gameConfig.useDefaultStartBoxes then
    Spring.Echo("Skirmish: Using default startboxes")
  else
    
    Spring.Echo("Skirmish: Default startboxes disabled")
  end
  
  if Configuration.gameConfig and Configuration.gameConfig.useDefaultStartBoxes and Configuration.gameConfig.mapStartBoxes and Configuration.gameConfig.mapStartBoxes[mapName] then 
    startBoxes = Configuration.gameConfig.mapStartBoxes[mapName] 
    if startBoxes[allyTeamCount] then
      Spring.Echo("Found startbox table for allyTeamCount",allyTeamCount)
    else
      Spring.Echo("No startbox table for allyTeamCount",allyTeamCount)
    end
  else
    Spring.Echo("No map startBoxes found for map",mapName)
  end
  
	-- rules for boxes placement:
  -- if there is a box set of the number of allyteams, use that
  -- if there is no box set for the number of allyteams, but there is one that is larger, then use that
  -- if there is no box set for the number of allyteams, but there is one that is smaller, then use that and blank the rest
  
  local function selectStartBoxesForAllyTeamCount(startboxes, allyteamcount) 
    if startboxes == nil then return nil end
    local mystartboxes = nil
    local closestlarger = 10000
    local closestsmaller = 0
    for i, boxset in pairs(startboxes) do
      if i == allyteamcount then 
        Spring.Echo("Found exact boxset for allyteamcount ",allyteamcount)
        return boxset 
      end
      if i > allyteamcount and i < closestlarger then 
        closestlarger = i
      end
      if i < allyteamcount and i > closestsmaller then
        closestsmaller = i
      end
    end
    if closestlarger < 10000 then
      Spring.Echo("Found larger boxset ",closestlarger ," for allyteamcount ",allyteamcount)
      return startboxes[closestlarger]
    end
    if closestsmaller > 0 then
      Spring.Echo("Found smaller boxset ",closestsmaller, " for allyteamcount", allyteamcount)
      return startboxes[closestsmaller]
    end
    return nil
  end
  
  local function makeallyteambox(startboxes, allyteamindex) 
      -- -- spads style boxen: 	!addBox <left> <top> <right> <bottom> [<teamNumber>] - adds a new start box (0,0 is top left corner, 200,200 is bottom right corner)
      --  startrectbottom=1;
      --  startrectleft=0;
      --  startrecttop=0.75;
      --  startrectright=1;
      local allyteamtable = {
          numallies = 0,
        }
      if startboxes and startboxes[allyteamindex + 1] then
        allyteamtable = {
          numallies = 0,
          startrectleft  = startboxes[allyteamindex + 1][1],
          startrecttop   = startboxes[allyteamindex + 1][2],
          startrectright = startboxes[allyteamindex + 1][3],
          startrectbottom= startboxes[allyteamindex + 1][4],
        }
      end
      return allyteamtable
  end
  
  local goodboxes = selectStartBoxesForAllyTeamCount(startBoxes,allyTeamCount)
  
	for i, teamData in pairs(teams) do
		if not allyTeams[teamData.AllyTeam] then
       allyTeams[teamData.AllyTeam] = makeallyteambox(goodboxes,teamData.AllyTeam)
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
		startpostype = 2,
		modoptions = self.modoptions,
		GameStartDelay = 5,
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

	Spring.Reload(scriptTxt)
end

function InterfaceSkirmish:StartReplay(replayFilename, myName, hostPort)
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

	Spring.Reload(scriptTxt)
	return false
end

function InterfaceSkirmish:StartGameFromLuaScript(gameType, scriptTable, friendList, hostPort)
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

	Spring.Reload(scriptTxt)
end

function InterfaceSkirmish:StartGameFromString(scriptString, gameType)
	self:_CallListeners("OnBattleAboutToStart", gameType)
	Spring.Reload(scriptString)
	return false
end

function InterfaceSkirmish:StartGameFromFile(scriptFileName, gameType)
	self:_CallListeners("OnBattleAboutToStart", gameType)
	if self.useSpringRestart then
		Spring.Restart(scriptFileName, "")
	else
		Spring.Start(scriptFileName, "")
	end
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
	self:_StartScript(battle.gameName, battle.mapName, myName, friendList, friendsReplaceAI, hostPort)
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

function InterfaceSkirmish:AddAi(aiName, aiLib, allyNumber, version, options)
	self:super("AddAi", aiName, aiLib, allyNumber, version, options)
	self:_OnAddAi(self:GetMyBattleID(), aiName, {
		aiLib = aiLib,
		allyNumber = allyNumber,
		owner = self:GetMyUserName(),
		aiVersion = version,
		aiOptions = options,
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
