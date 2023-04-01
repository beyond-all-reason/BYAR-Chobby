--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Planet Battle Handler",
		desc      = "Handles creating the battle for planet invasion as well as reporting results.",
		author    = "GoogleFrog",
		date      = "6 February 2017",
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

local function StartBattleForReal(planetID, planetData)
	gameConfig = planetData.gameConfig

	local allyTeams = {}
	local allyTeamCount = 0
	local teams = {}
	local teamCount = 0
	local ais = {}
	local aiCount = 0
	local commanderTypes = {}

	local Configuration = WG.Chobby.Configuration
	local gameName = Configuration:GetDefaultGameName()
	local missionDifficulty = WG.CampaignData.GetDifficultySetting()
	local bitExtension = (Configuration:GetIsRunning64Bit() and "64") or "32"
	local playerName = Configuration:GetPlayerName()

	WG.Analytics.SendIndexedRepeatEvent("campaign:planet_" .. planetID .. ":difficulty_" .. missionDifficulty .. ":started")

	-- Add the player, this is to make the player team 0.
	local playerCount = 1
	local players = {
		[0] = {
			Name = playerName,
			Team = teamCount,
			IsFromDemo = 0,
			rank = 0,
		},
	}

	local playerUnlocks = WG.CampaignData.GetUnitsUnlocks()
	local playerAbilities = WG.CampaignData.GetAbilityUnlocks()

	commanderTypes.player_commander = WG.CampaignData.GetPlayerCommander()

	if gameConfig.playerConfig.extraModules then
		commanderTypes.player_commander = GetPlayerCommWithExtra(commanderTypes.player_commander, gameConfig.playerConfig.extraModules)
	end

	local fullPlayerUnlocks = AddToList(Spring.Utilities.CopyTable(playerUnlocks.list), playerUnlocks.map, gameConfig.playerConfig.extraUnlocks)
	local fullAbilitiesList = AddToList(Spring.Utilities.CopyTable(playerAbilities.list), playerAbilities.map, gameConfig.playerConfig.extraAbilities)

	if gameConfig.playerConfig.unitWhitelist then
		local map = gameConfig.playerConfig.unitWhitelist
		local i = 1
		while i <= #fullPlayerUnlocks do
			if not map[fullPlayerUnlocks[i]] then
				fullPlayerUnlocks[i] = fullPlayerUnlocks[#fullPlayerUnlocks]
				fullPlayerUnlocks[#fullPlayerUnlocks] = nil
			else
				i = i + 1
			end
		end
	end

	if gameConfig.playerConfig.unitBlacklist then
		local map = gameConfig.playerConfig.unitBlacklist
		local i = 1
		while i <= #fullPlayerUnlocks do
			if map[fullPlayerUnlocks[i]] then
				fullPlayerUnlocks[i] = fullPlayerUnlocks[#fullPlayerUnlocks]
				fullPlayerUnlocks[#fullPlayerUnlocks] = nil
			else
				i = i + 1
			end
		end
	end

	teams[teamCount] = {
		TeamLeader = 0,
		AllyTeam = gameConfig.playerConfig.allyTeam,
		rgbcolor = '0 0 0',
		start_x = gameConfig.playerConfig.startX,
		start_z = gameConfig.playerConfig.startZ,
		start_metal = gameConfig.playerConfig.startMetal,
		start_energy = gameConfig.playerConfig.startEnergy,
		staticcomm = "player_commander",
		static_level = WG.CampaignData.GetPlayerCommanderInformation(),
		campaignunlocks = TableToBase64(fullPlayerUnlocks),
		campaignabilities = TableToBase64(fullAbilitiesList),
		campaignunitwhitelist = TableToBase64(gameConfig.playerConfig.unitWhitelist),
		campaignunitblacklist = TableToBase64(gameConfig.playerConfig.unitBlacklist),
		commanderparameters = TableToBase64(gameConfig.playerConfig.commanderParameters),
		midgameunits = TableToBase64(gameConfig.playerConfig.midgameUnits),
		retinuestartunits = TableToBase64(WG.CampaignData.GetActiveRetinue()),
		typevictorylocation = TableToBase64(gameConfig.playerConfig.typeVictoryAtLocation)
	}
	AddStartUnits(teams[teamCount], gameConfig.playerConfig.startUnits, "extrastartunits_")

	teamCount = teamCount + 1

	-- Add the AIs
	for i = 1, #gameConfig.aiConfig do
		local aiData = gameConfig.aiConfig[i]
		local shortName = WG.CampaignData.GetAI(aiData.aiLib)
		if aiData.bitDependant then
			shortName = shortName .. bitExtension
		end

		local availibleUnits = aiData.unlocks
		local extraUnits = aiData.difficultyDependantUnlocks and aiData.difficultyDependantUnlocks[missionDifficulty]
		if availibleUnits and extraUnits then
			for i = 1, #extraUnits do
				availibleUnits[#availibleUnits + 1] = extraUnits[i]
			end
		end

		ais[aiCount] = {
			Name = aiData.humanName,
			Team = teamCount,
			IsFromDemo = 0,
			ShortName = shortName,
			comm_merge = 0,
			version = "stable",
			Host = 0,
			Options = {
				comm_merge = 0,
				disabledunits = MakeCircuitDisableString(availibleUnits)
			}
		}
		aiCount = aiCount + 1

		local commanderName, noCommander
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

	-- Briefing screen information
	local informationText = {
		name = planetData.name,
		description = planetData.infoDisplay.extendedText or planetData.infoDisplay.text,
		tips = planetData.tips,
	}

	local modoptions = {
		commandertypes = TableToBase64(commanderTypes),
		defeatconditionconfig = TableToBase64(gameConfig.defeatConditionConfig),
		objectiveconfig = TableToBase64(gameConfig.objectiveConfig),
		bonusobjectiveconfig = TableToBase64(gameConfig.bonusObjectiveConfig),
		featurestospawn = TableToBase64(gameConfig.initialWrecks),
		planetmissioninformationtext = TableToBase64(informationText),
		planetmissionnewtonfirezones = TableToBase64(gameConfig.playerConfig.newtonFirezones),
		fixedstartpos = 1,
		planetmissiondifficulty = missionDifficulty,
		singleplayercampaignbattleid = planetID,
		initalterraform = TableToBase64(gameConfig.terraform),
		planetmissionmapmarkers = TableToBase64(gameConfig.mapMarkers),
		campaignpartialsavedata = TableToBase64(WG.CampaignData.GetCampaignPartialSaveData()),
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

	local difficultyModoptions = gameConfig.modoptionDifficulties and gameConfig.modoptionDifficulties[missionDifficulty]
	if difficultyModoptions then
		for key, value in pairs(difficultyModoptions) do
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

	WG.SteamCoopHandler.AttemptGameStart("campaign" .. planetID, script.gametype, script.mapname, script)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- External Functions
local PlanetBattleHandler = {}

function PlanetBattleHandler.StartBattle(planetID, planetData)
	local Configuration = WG.Chobby.Configuration
	local gameConfig = planetData.gameConfig

	local function StartBattleFunc()
		if StartBattleForReal(planetID, planetData) then
			Spring.Echo("Start battle success!")
		end
	end

	if Spring.GetGameName() == "" then
		StartBattleFunc()
	else
		WG.Chobby.ConfirmationPopup(StartBattleFunc, "Are you sure you want to leave your current game to attack this planet?", nil, 315, 200)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

function widget:Initialize()
	WG.PlanetBattleHandler = PlanetBattleHandler
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Circuit Config Handling

local function LoadCircuitConfig(circuitName, version)
	local path = "AI/Skirmish/" .. circuitName .. "/" .. version .. "/config/circuit.json"
	if VFS.FileExists(path) then
		local file = VFS.LoadFile(path)
		return Spring.Utilities.json.decode(file)
	end
	return false
end

local function SaveCircuitConfig(circuitName, version, index, configTable)
	local path = "AI/Skirmish/" .. circuitName .. "/" .. version .. "/config/temp" .. index .. ".json"
	local configFile = io.open(path, "w")
	configFile:write(Spring.Utilities.json.encode(configTable))
	configFile:close()
	return "temp" .. index
end

local function IsBadUnit(str)
	if string.len(str) < 9 then
		return false
	end
	if string.find(str, "cloak") or string.find(str, "gunship") or string.find(str, "plane") then
		return false
	end
	if string.find(str, "factory") or string.find(str, "hub") then
		return true
	end
	return false
end

function RecursivelyDeleteFactories(config)
	-- All passed by reference
	for key, value in pairs(config) do
		if IsBadUnit(key) then
			config[key] = nil
		end
		if type(value) == "table" then
			RecursivelyDeleteFactories(value)
		elseif type(value) == "string" and IsBadUnit(value) then
			if type(key) == "number" then
				local i = 1
				while i <= #config do
					if IsBadUnit(config[i]) then
						config[i] = config[#config]
						config[#config] = nil
					else
						i = i + 1
					end
				end
			else
				config[key] = nil
			end
		end
	end
end

--local config = LoadCircuitConfig(shortName, "stable")
--RecursivelyDeleteFactories(config)
--local configName = SaveCircuitConfig(shortName, "stable", aiCount, config)
