--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "API Script Handler",
		desc      = "Handles the creation of standalone benchmark scripts.",
		author    = "GoogleFrog",
		date      = "2 November 2018",
		license   = "GNU LGPL, v2.1 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local START_UNITS_BLOCK_SIZE = 40

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Encording

local function TableToBase64(inputTable)
	if not inputTable then
		return
	end
	return Spring.Utilities.Base64Encode(Spring.Utilities.TableToString(inputTable))
end

local function MakeCircuitDisableString(unlockedUnits)
	local Configuration = WG.Chobby.Configuration
	local unitList = Configuration.gameConfig.gameUnitInformation.nameList
	if not unitList then
		return nil
	end
	local unlockedMap = {}
	if unlockedUnits then
		for i = 1, #unlockedUnits do
			unlockedMap[unlockedUnits[i]] = true
		end
	end
	local disabled
	for i = 1, #unitList do
		if not unlockedMap[unitList[i]] then
			if not disabled then
				disabled = unitList[i]
			else
				disabled = disabled .. "+" .. unitList[i]
			end
		end
	end
	return disabled
end

local function AddToList(list, inclusionMap, listToAppend)
	if listToAppend then
		for i = 1, #listToAppend do
			if not inclusionMap[listToAppend[i]] then
				list[#list + 1] = listToAppend[i]
			end
		end
	end

	return list
end

local function AddStartUnits(teamTable, unitList, prefix)
	if not (unitList and unitList[1]) then
		return
	end
	local block = 1
	while unitList[(block - 1)*START_UNITS_BLOCK_SIZE + 1] do
		local unitsTable = {}
		local offset = (block - 1)*START_UNITS_BLOCK_SIZE
		for i = 1, START_UNITS_BLOCK_SIZE do
			unitsTable[i] = unitList[offset + i]
		end
		teamTable[prefix .. block] = TableToBase64(unitsTable)
		block = block + 1
	end
end

local function GetPlayerCommWithExtra(playerComm, extraModules)
	local replaceModules = {}
	for i = 1, #extraModules do
		if not extraModules[i].add then
			replaceModules[extraModules[i].name] = true
		end
	end

	local flatModules = {} -- Much simpler
	local modules = playerComm.modules
	for level = 0, #modules do
		for slot = 1, #modules[level] do
			local entry = modules[level][slot]
			if not replaceModules[entry] then
				flatModules[#flatModules + 1] = entry
			end
		end
	end

	for i = 1, #extraModules do
		local extra = extraModules[i]
		for j = 1, extra.count do
			flatModules[#flatModules + 1] = extra.name
		end
	end

	return {
		name = playerComm.name,
		chassis = playerComm.chassis,
		modules = {
			[0] = flatModules,
		},
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Start Game

local function GenerateScriptFromConfig(gameConfig)
	local allyTeams = {}
	local allyTeamCount = 0
	local teams = {}
	local teamCount = 0
	local ais = {}
	local aiCount = 0
	local commanderTypes = {}

	local Configuration = WG.Chobby.Configuration
	local gameName = gameConfig.gameName or Configuration:GetDefaultGameName()
	local bitExtension = (Configuration:GetIsRunning64Bit() and "64") or "32"
	local playerName = Configuration:GetPlayerName()

	-- Add the player, this is to make the player team 0.
	local playerCount = 1
	local players = {
		[0] = {
			Name = playerName,
			Team = teamCount,
			IsFromDemo = 0,
			Spectator = (gameConfig.playerConfig.isSpectator and 1) or nil,
			rank = 0,
		},
	}

	if not gameConfig.playerConfig.isSpectator then
		local commanderName, noCommander
		if gameConfig.playerConfig.commander then
			local commander = gameConfig.playerConfig.commander
			commanderName = "player_commander"
			commanderTypes[commanderName] = {
				name = commander.name,
				chassis = commander.chassis,
				decorations = commander.decorations,
				modules = {
					[0] = commander.modules
				},
			}
		else
			noCommander = 1
		end
		commanderTypes.player_commander = gameConfig.playerConfig.commander

		teams[teamCount] = {
			TeamLeader = 0,
			AllyTeam = gameConfig.playerConfig.allyTeam,
			rgbcolor = '0 0 0',
			start_x = gameConfig.playerConfig.startX,
			start_z = gameConfig.playerConfig.startZ,
			start_metal = gameConfig.playerConfig.startMetal,
			start_energy = gameConfig.playerConfig.startEnergy,
			nocommander = noCommander,
			staticcomm = "player_commander",
			commanderparameters = TableToBase64(gameConfig.playerConfig.commanderParameters),
			midgameunits = TableToBase64(gameConfig.playerConfig.midgameUnits),
			retinuestartunits = TableToBase64(WG.CampaignData.GetActiveRetinue()),
			typevictorylocation = TableToBase64(gameConfig.playerConfig.typeVictoryAtLocation)
		}
		AddStartUnits(teams[teamCount], gameConfig.playerConfig.startUnits, "extrastartunits_")

		teamCount = teamCount + 1
	end

	-- Add the AIs
	for i = 1, #gameConfig.aiConfig do
		local aiData = gameConfig.aiConfig[i]
		local shortName = WG.CampaignData.GetAI(aiData.aiLib)
		local commanderName, noCommander

		if aiData.bitDependant then
			shortName = shortName .. bitExtension
		end

		ais[aiCount] = {
			Name = aiData.humanName or ("AI " .. teamCount),
			Team = teamCount,
			IsFromDemo = 0,
			ShortName = shortName,
			comm_merge = 0,
			Host = 0,
			Options = {
				comm_merge = 0,
				disabledunits = MakeCircuitDisableString(aiData.unlocks)
			}
		}
		aiCount = aiCount + 1

		if aiData.commander then
			local commander = aiData.commander
			commanderName = "ai_commander_" .. aiCount
			commanderTypes[commanderName] = {
				name = commander.name,
				chassis = commander.chassis,
				decorations = commander.decorations,
				modules = {
					[0] = commander.modules
				},
			}
		else
			noCommander = 1
		end

		teams[teamCount] = {
			TeamLeader = 0,
			AllyTeam = aiData.allyTeam,
			rgbcolor = '0 0 0',
			start_x = aiData.startX,
			start_z = aiData.startZ,
			nocommander = noCommander,
			staticcomm = commanderName,
			start_metal = aiData.startMetal,
			start_energy = aiData.startEnergy,
			static_level = (aiData.commanderLevel or 1) - 1, -- Comm level is 0 indexed but on the UI it is 1 indexed.
			campaignunlocks = TableToBase64(availibleUnits),
			commanderparameters = TableToBase64(aiData.commanderParameters),
			midgameunits = TableToBase64(aiData.midgameUnits),
			typevictorylocation = TableToBase64(aiData.typeVictoryAtLocation)
		}
		AddStartUnits(teams[teamCount], aiData.startUnits, "extrastartunits_")
		teamCount = teamCount + 1
	end

	-- Add allyTeams
	for i, teamData in pairs(teams) do
		if not allyTeams[teamData.AllyTeam] then
			allyTeams[teamData.AllyTeam] = {
				numallies = 0,
			}
		end
	end

	local modoptions = {
		commandertypes = TableToBase64(commanderTypes),
		featurestospawn = TableToBase64(gameConfig.initialWrecks),
		planetmissionnewtonfirezones = TableToBase64(gameConfig.playerConfig.newtonFirezones),
		fixedstartpos = 1,
		initalterraform = TableToBase64(gameConfig.terraform),
	}
	AddStartUnits(modoptions, gameConfig.neutralUnits, "neutralstartunits_")

	if WG.Chobby.Configuration.campaignSpawnDebug then
		modoptions.campaign_spawn_debug = 1
	end

	if gameConfig.modoptions then
		for key, value in pairs(gameConfig.modoptions) do
			modoptions[key] = (type(value) == "table" and TableToBase64(value)) or value
		end
	end

	local script = {
		gametype = gameConfig.gameName or gameName,
		mapname = gameConfig.mapName,
		myplayername = playerName,
		nohelperais = 0,
		numplayers = playerCount,
		numusers = playerCount + aiCount,
		startpostype = 2, -- Choose is required to make maps not crash due to undefined start positions.
		GameStartDelay = 0,
		modoptions = modoptions,
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

	WG.SteamCoopHandler.AttemptGameStart("script", script.gametype, script.mapname, script)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- External Functions
local ScriptGenerator = {}

function ScriptGenerator.GenerateScript(gameConfig)
	GenerateScriptFromConfig(gameConfig)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

function widget:Initialize()
	WG.ScriptGenerator = ScriptGenerator
end
