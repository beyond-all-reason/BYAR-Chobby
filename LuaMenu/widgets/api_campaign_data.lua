--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Campaign Data Handler",
		desc      = "",
		author    = "KingRaptor & GoogleFrog",
		date      = "2 March 2017",
		license   = "GNU GPL, v2 or later",
		layer     = -1000,
		enabled   = true,  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
-- data
--------------------------------------------------------------------------------

-- this stores anything that goes into a save file
local gamedata = {}
local commanderModuleCounts = {}

local externalFunctions = {}

local SAVE_DIR = "Saves/campaign/"
local SAVE_NAME = "saveFile"
local ICONS_DIR = LUA_DIRNAME .. "configs/gameConfig/zk/unitpics/"

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utilities

local function TranslateModule(moduleName)
	-- Limited copies look like moduleName_LIMIT_A_4
	local limitPos = string.find(moduleName, "_LIMIT_")
	if not limitPos then
		if moduleName and gamedata.modulesUnlockedLimit[moduleName] then
			return moduleName, gamedata.modulesUnlockedLimit[moduleName]
		end
		return moduleName
	end
	local limit = string.sub(moduleName, limitPos + 9)
	moduleName = string.sub(moduleName, 0, limitPos - 1)

	return moduleName, limit
end

local function UnlockThing(thingData, id)
	if thingData.map[id] then
		return false
	end
	thingData.map[id] = true
	thingData.list[#thingData.list + 1] = id
	return true
end

local function UnlockListOfThings(unlockList, unlocksToAdd, translationFunc, unlockLimitTable)
	local saveRequired = false
	for i = 1, #unlocksToAdd do
		if translationFunc then
			local copyInstanceName = unlocksToAdd[i]
			local unlockName, limit = translationFunc(copyInstanceName)
			saveRequired = UnlockThing(unlockList, unlockName) or saveRequired
			if limit then
				if UnlockThing(unlockList, copyInstanceName) then
					unlockLimitTable[unlockName] = (unlockLimitTable[unlockName] or 0) + (tonumber(limit) or 0)
					saveRequired = true
				end
			end
		else
			saveRequired = UnlockThing(unlockList, unlocksToAdd[i]) or saveRequired
		end
	end
	return saveRequired
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Listeners

local listeners = {}

local function CallListeners(event, ...)
	if listeners[event] == nil then
		return nil -- no event listeners
	end
	local eventListeners = Spring.Utilities.ShallowCopy(listeners[event])
	for i = 1, #eventListeners do
		local listener = eventListeners[i]
		args = {...}
		xpcall(function() listener(listener, unpack(args)) end,
			function(err) Spring.Echo("Campaign Listener Error", err) end )
	end
	return true
end

function externalFunctions.AddListener(event, listener)
	if listener == nil then
		Spring.Log(LOG_SECTION, LOG.ERROR, "Event: " .. tostring(event) .. ", listener cannot be nil")
		return
	end
	local eventListeners = listeners[event]
	if eventListeners == nil then
		eventListeners = {}
		listeners[event] = eventListeners
	end
	table.insert(eventListeners, listener)
end

function externalFunctions.RemoveListener(event, listener)
	if listeners[event] then
		for k, v in pairs(listeners[event]) do
			if v == listener then
				table.remove(listeners[event], k)
				if #listeners[event] == 0 then
					listeners[event] = nil
				end
				break
			end
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Game data

local function ResetGamedata()
	gamedata = {
		unitsUnlocked = {map = {}, list = {}},
		modulesUnlocked = {map = {}, list = {}},
		modulesUnlockedLimit = {}, -- Limit for particular modules, eg, 4 speed modules.
		abilitiesUnlocked = {map = {}, list = {}},
		codexEntriesUnlocked = {map = {}, list = {}},
		codexEntryRead = {},
		bonusObjectivesComplete = {map = {}, list = {}},
		completionDifficulty = {}, -- Highest difficulty of completion for planets and bonus objectives.
		planetsCaptured = {map = {}, list = {}},
		commanderExperience = 0,
		difficultySetting = 1, -- 1,2,3 -> easy/medium/hard
		leastDifficulty = false,
		commanderLevel = 0,
		commanderName = "New Save",
		commanderChassis = "knight",
		commanderLoadout = {},
		retinue = {}, -- Unused
		totalPlayFrames = 0,
		totalVictoryPlayFrames = 0,
		initializationComplete = false,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Save Game

local function GetSave(filepath)
	local ret = nil
	local success, err = pcall(function()
		local saveData = VFS.Include(filepath)
		ret = saveData
	end)
	if (not success) then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "Error getting saves: " .. err)
	else
		return ret
	end
end

local function ValidSave(saveData)
	return saveData and type(saveData) == "table" and
		saveData.name and saveData.commanderName and saveData.commanderLevel and
		saveData.date and saveData.initializationComplete
end

-- Loads the list of save files and their contents
local function GetSaves()
	Spring.CreateDir(SAVE_DIR)
	local saves = {}
	local savefiles = VFS.DirList(SAVE_DIR, "*.lua")
	for i = 1, #savefiles do
		local filepath = savefiles[i]
		local saveData = GetSave(filepath)
		if ValidSave(saveData) then
			saves[saveData.name] = saveData
		end
	end
	return saves
end

local function SaveGame()
	local fileName = WG.Chobby.Configuration.campaignSaveFile
	if not fileName then
		local number = WG.Chobby.Configuration.nextCampaignSaveNumber or 1
		for i = 1, 1000 do
			if VFS.FileExists(SAVE_DIR .. SAVE_NAME .. number .. ".lua") then
				number = number + 1
			else
				break
			end
		end
		fileName = SAVE_NAME .. number
		WG.Chobby.Configuration:SetConfigValue("nextCampaignSaveNumber", number + 1)
		WG.Chobby.Configuration:SetConfigValue("campaignSaveFile", fileName)
	end
	local success, err = pcall(function()
		Spring.CreateDir(SAVE_DIR)
		path = SAVE_DIR .. fileName .. ".lua"
		local saveData = Spring.Utilities.CopyTable(gamedata, true)
		saveData.name = fileName
		saveData.date = os.date('*t')
		saveData.description = isAutosave and "" or description
		table.save(saveData, path)
		Spring.Log(widget:GetInfo().name, LOG.INFO, "Saved game to " .. path)
	end)
	if (not success) then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "Error saving game: " .. err)
	end
	return success, WG.Chobby.Configuration.campaignSaveFile
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Modules, Rewards

local function UnlockRewardSet(rewardSet)
	local saveRequired = false
	if rewardSet.units then
		saveRequired = UnlockListOfThings(gamedata.unitsUnlocked, rewardSet.units) or saveRequired
	end
	if rewardSet.modules then
		saveRequired = UnlockListOfThings(gamedata.modulesUnlocked, rewardSet.modules, TranslateModule, gamedata.modulesUnlockedLimit) or saveRequired
	end
	if rewardSet.abilities then
		saveRequired = UnlockListOfThings(gamedata.abilitiesUnlocked, rewardSet.abilities) or saveRequired
	end
	if rewardSet.codexEntries then
		saveRequired = UnlockListOfThings(gamedata.codexEntriesUnlocked, rewardSet.codexEntries) or saveRequired
	end
	return saveRequired
end

local function ApplyUnlocksForCapturedPlanets()
	for i = 1, #gamedata.planetsCaptured.list do
		local planetID = gamedata.planetsCaptured.list[i]
		local planet = WG.Chobby.Configuration.campaignConfig.planetDefs.planets[planetID]
		UnlockRewardSet(planet.completionReward)
	end
end

local function UpdateCommanderModuleCounts()
	local loadout = gamedata.commanderLoadout
	commanderModuleCounts = {}

	local level = 0
	while loadout[level] do
		for i = 1, #loadout[level] do
			commanderModuleCounts[loadout[level][i]] = (commanderModuleCounts[loadout[level][i]] or 0) + 1
		end
		level = level + 1
	end
end

local function IsModuleRequirementMet(data)
	if data.requireOneOf then
		local foundRequirement = false
		for j = 1, #data.requireOneOf do
			local reqDefName = data.requireOneOf[j]
			if (commanderModuleCounts[reqDefName] or 0) > 0 then
				foundRequirement = true
				break
			end
		end
		if not foundRequirement then
			return false
		end
	end
	return true
end

local function UpdateModuleRequirements()
	local loadout = gamedata.commanderLoadout

	local commConfig = WG.Chobby.Configuration.campaignConfig.commConfig
	local chassisDef = commConfig.chassisDef
	local moduleDefs = commConfig.moduleDefs
	local moduleDefNames = commConfig.moduleDefNames

	local level = 0
	while loadout[level] do
		for slot = 1, #loadout[level] do
			local oldModuleName = loadout[level][slot]
			local moduleData = moduleDefs[moduleDefNames[oldModuleName]]
			if not IsModuleRequirementMet(moduleData) then
				local newModule = chassisDef.levelDefs[level].upgradeSlots[slot].defaultModule
				loadout[level][slot] = newModule
				UpdateCommanderModuleCounts()
				CallListeners("ModulePutInSlot", newModule, oldModuleName, level, slot)
				level = -1
				break
			end
		end
		level = level + 1
	end
end

local function SelectCommanderModule(level, slot, moduleName, supressEvent)
	if not gamedata.commanderLoadout[level] then
		gamedata.commanderLoadout[level] = {}
	end

	local oldModule = gamedata.commanderLoadout[level][slot]
	if moduleName == oldModule then
		if not supressEvent then
			CallListeners("ModulePutInSlot", moduleName, oldModule, level, slot)
		end
		return
	end
	gamedata.commanderLoadout[level][slot] = moduleName

	if not supressEvent then
		UpdateCommanderModuleCounts()
		if not commanderModuleCounts[oldModule] then
			UpdateModuleRequirements()
		end
		CallListeners("ModulePutInSlot", moduleName, oldModule, level, slot)
	end

	SaveGame()
end

local function UnlockModuleSlots(level)
	local chassisDef = WG.Chobby.Configuration.campaignConfig.commConfig.chassisDef

	level = math.min(level, chassisDef.highestDefinedLevel)
	local initalModules = chassisDef.levelDefs[level].upgradeSlots
	for i = 1, #initalModules do
		SelectCommanderModule(level, i, initalModules[i].defaultModule, true)
	end
end

local function SetupInitialCommander()
	gamedata.commanderChassis = WG.Chobby.Configuration.campaignConfig.commConfig.chassisDef.chassis
	UnlockModuleSlots(0)
end

local function GainExperience(newExperience, gainedBonusExperience)
	local Configuration = WG.Chobby.Configuration
	local oldExperience = gamedata.commanderExperience
	local oldLevel = gamedata.commanderLevel
	gamedata.commanderExperience = gamedata.commanderExperience + newExperience
	for i = 1, 50 do
		local requirement = Configuration.campaignConfig.commConfig.GetLevelRequirement(gamedata.commanderLevel + 1)
		if (not requirement) or (requirement > gamedata.commanderExperience) then
			break
		end
		gamedata.commanderLevel = gamedata.commanderLevel + 1
		UnlockModuleSlots(gamedata.commanderLevel)
	end
	if oldLevel < gamedata.commanderLevel then
		UpdateCommanderModuleCounts()
	end

	CallListeners("GainExperience", oldExperience, oldLevel, gamedata.commanderExperience, gamedata.commanderLevel, gainedBonusExperience)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Load or start new game

local function RecalculateCommanderLevel()
	Spring.Echo("RecalculateCommanderLevel", gamedata.commanderLevel, gamedata.commanderExperience)
	local oldExperience = gamedata.commanderExperience
	local loadout = Spring.Utilities.CopyTable(gamedata.commanderLoadout, true)
	gamedata.commanderLevel = 0
	gamedata.commanderExperience = 0
	GainExperience(oldExperience)

	local level = 0
	while loadout[level] do
		if level > gamedata.commanderLevel then
			gamedata.commanderLoadout[level] = nil
		else
			for slot = 1, #loadout[level] do
				SelectCommanderModule(level, slot, loadout[level][slot], true)
			end
		end
		level = level + 1
	end
	UpdateModuleRequirements()
end

local function SanityCheckCommanderLevel()
	local conf = WG.Chobby.Configuration.campaignConfig.commConfig
	local levelExperience = conf.GetLevelRequirement(gamedata.commanderLevel)
	local nextExperiece = conf.GetLevelRequirement(gamedata.commanderLevel + 1)

	if not (levelExperience and nextExperiece and gamedata.commanderExperience) then
		RecalculateCommanderLevel()
		return false
	end

	if (gamedata.commanderExperience < levelExperience) or (nextExperiece < gamedata.commanderExperience) then
		RecalculateCommanderLevel()
		return false
	end

	return true
end

local function GenerateCampaignID()
	gamedata.campaignID = tostring(math.random())
end

local function LoadGame(saveData, refreshGUI)
	local success, err = pcall(function()
		Spring.CreateDir(SAVE_DIR)
		ResetGamedata()
		gamedata = Spring.Utilities.MergeTable(saveData, gamedata, true)

		if not gamedata.campaignID then
			GenerateCampaignID()
		end

		ApplyUnlocksForCapturedPlanets()

		if SanityCheckCommanderLevel() then
			UpdateCommanderModuleCounts()
		end
		SaveGame()
		if refreshGUI then
			CallListeners("CampaignLoaded")
		end
		WG.Chobby.Configuration:SetConfigValue("campaignSaveFile", saveData.name)

		Spring.Log(widget:GetInfo().name, LOG.INFO, "Save file " .. saveData.name .. " loaded")
	end)
	if (not success) then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "Error loading game: " .. err)
	end
end

local function StartNewGame()
	WG.Chobby.Configuration:SetConfigValue("campaignSaveFile", nil) -- Save name generated by campaign data handler
	local campaignConfig = WG.Chobby.Configuration.campaignConfig
	ResetGamedata()
	GenerateCampaignID()

	local planets = campaignConfig.planetDefs.initialPlanets
	UnlockRewardSet(campaignConfig.initialUnlocks)
	for i = 1, #planets do
		externalFunctions.CapturePlanet(planets[i])
	end
	SetupInitialCommander()
	UpdateCommanderModuleCounts()
	local success, saveName = SaveGame()

	CallListeners("CampaignLoaded")
	return success and saveName
end

local function SetupNewSave(commName, difficulty, overrideCampaignID)
	WG.CampaignData.SetCommanderName(commName)
	WG.CampaignData.SetDifficultySetting(difficulty)
	WG.CampaignData.SetCampaignInitializationComplete()
	if WG.CampaignSaveWindow.PopulateSaveList then
		WG.CampaignSaveWindow.PopulateSaveList()
	end
	if overrideCampaignID then
		gamedata.campaignID = overrideCampaignID
	end
end

local function LoadCampaignData()
	Spring.Log(widget:GetInfo().name, LOG.INFO, "Loading campaign data")
	local Configuration = WG.Chobby.Configuration
	local saves = GetSaves()

	-- try loading save whose name is stored in config (this should be the last save we played)
	if Configuration.campaignSaveFile then
		Spring.Log(widget:GetInfo().name, LOG.INFO, "Config save file: " .. Configuration.campaignSaveFile)
		local saveData = saves[Configuration.campaignSaveFile]
		if saveData then
			Spring.Log(widget:GetInfo().name, LOG.INFO, "Save data found, loading")
			LoadGame(saveData, true)
			return true
		else
			Spring.Log(widget:GetInfo().name, LOG.WARNING, "Save data not found")
		end
	else
		Spring.Log(widget:GetInfo().name, LOG.INFO, "No configured save data")
	end

	-- Configuration.campaignSaveFile does not point to a valid save
	-- pick the first save that actually exists (if there's one)
	for savename,saveData in pairs(saves) do
		WG.Chobby.Configuration:SetConfigValue("campaignSaveFile", savename)
		LoadGame(saveData, true)
		return true
	end

	-- we got nothing
	WG.Chobby.Configuration:SetConfigValue("campaignSaveFile", nil)
end

local function LoadGameByFilename(filename)
	WG.Chobby.Configuration:SetConfigValue("campaignSaveFile", filename)
	LoadCampaignData()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Partial save/load

local function FindMatchingSave(campaignID, commName)
	-- Check whether the save is already loaded
	if campaignID == gamedata.campaignID and commName == gamedata.commanderName then
		return false
	end

	local saveFiles = GetSaves()
	for name, save in pairs(saveFiles) do
		if campaignID == save.campaignID and commName == save.commanderName then
			return true, name
		end
	end

	return true
end

function externalFunctions.ApplyCampaignPartialSaveData(saveData)
	if not saveData then
		return
	end

	local commander = saveData.commander
	local planets = saveData.planets
	if not (commander and planets) then
		return
	end

	local needLoad, existingSave = FindMatchingSave(saveData.campaignID, commander.name)
	if needLoad then
		if existingSave then
			LoadGameByFilename(existingSave)
		else
			StartNewGame()
			SetupNewSave(commander.name, saveData.difficultySetting, saveData.campaignID)
		end
	end
	WG.CampaignData.SetDifficultySetting(saveData.difficultySetting)

	local CapturePlanet = WG.CampaignData.CapturePlanet
	for i = 1, #planets do
		local planet = planets[i]
		CapturePlanet(planet.planetID, planet.bonusObjStatus, 0)
	end

	gamedata.commanderLoadout = commander.modules or {}
	CallListeners("UpdateCommanderLoadout")
	SaveGame()
end

function externalFunctions.GetCampaignPartialSaveData()
	local planetList = gamedata.planetsCaptured.list
	local bonusMap = gamedata.bonusObjectivesComplete.map

	local planetDefs = WG.Chobby.Configuration.campaignConfig.planetDefs.planets

	local captureData = {}
	for i = 1, #planetList do
		local planetID = planetList[i]
		local bonusConfig = planetDefs[planetID].gameConfig.bonusObjectiveConfig

		local bonusObjStatus = {}
		if bonusConfig then
			for j = 1, #bonusConfig do
				bonusObjStatus[j] = (bonusMap[planetID .. "_" .. j] and true) or false
			end
		end

		captureData[#captureData + 1] = {
			planetID = planetID,
			bonusObjStatus = bonusObjStatus,
		}
	end

	return {
		campaignID = gamedata.campaignID,
		commander = externalFunctions.GetPlayerCommander(),
		difficultySetting = gamedata.difficultySetting,
		planets = captureData,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Callins

function externalFunctions.GetAI(aiLibName)
	local aiConfig = WG.Chobby.Configuration.campaignConfig.aiConfig
	return (aiConfig.aiLibFunctions[aiLibName] and aiConfig.aiLibFunctions[aiLibName](gamedata.difficultySetting)) or aiLibName
end

function externalFunctions.GetDifficultySetting()
	return gamedata.difficultySetting
end

function externalFunctions.SetDifficultySetting(newDifficulty)
	if (not newDifficulty) or gamedata.difficultySetting == newDifficulty then
		return
	end
	gamedata.difficultySetting = newDifficulty

	CallListeners("CampaignSettingsUpdate")
	SaveGame()
end

function externalFunctions.CapturePlanet(planetID, bonusObjectives, difficulty)
	local planet = WG.Chobby.Configuration.campaignConfig.planetDefs.planets[planetID]
	local saveRequired = false
	local gainedExperience = 0
	local gainedBonusExperience = 0

	if UnlockThing(gamedata.planetsCaptured, planetID) then
		gainedExperience = gainedExperience + (planet.completionReward.experience or 0)
		saveRequired = true
	end
	saveRequired = UnlockRewardSet(planet.completionReward) or saveRequired
	if saveRequired then
		CallListeners("PlanetCaptured", planetID)
		CallListeners("RewardGained", planet.completionReward)
	end

	if difficulty > (gamedata.completionDifficulty[planetID] or 0) then
		gamedata.completionDifficulty[planetID] = difficulty
		saveRequired = true
	end

	if bonusObjectives then
		local bonusConfig = planet.gameConfig.bonusObjectiveConfig
		if bonusConfig then
			for i = 1, #bonusObjectives do
				if bonusObjectives[i] and bonusConfig[i] then
					local bonusIndex = planetID .. "_" .. i
					if UnlockThing(gamedata.bonusObjectivesComplete, bonusIndex) then
						gainedExperience = gainedExperience + bonusConfig[i].experience
						gainedBonusExperience = gainedBonusExperience + bonusConfig[i].experience
						saveRequired = true
					end
					if difficulty > (gamedata.completionDifficulty[bonusIndex] or 0) then
						gamedata.completionDifficulty[bonusIndex] = difficulty
						saveRequired = true
					end
				end
			end
		end
	end

	GainExperience(gainedExperience, gainedBonusExperience)

	if saveRequired then
		-- Only update lowest difficulty if something was achieved. Do not set lowest difficulty for Imported victories (they are shown on planets anyway).
		if difficulty > 0 and ((not gamedata.leastDifficulty) or (difficulty < gamedata.leastDifficulty)) then
			gamedata.leastDifficulty = difficulty
		end
		CallListeners("PlanetUpdate", planetID)
		SaveGame()
	end
end

function externalFunctions.AddPlayTime(battleFrames, missionLost)
	gamedata.totalPlayFrames = (gamedata.totalPlayFrames or 0) + (battleFrames or 0)
	if not missionLost then
		gamedata.totalVictoryPlayFrames = (gamedata.totalVictoryPlayFrames or 0) + (battleFrames or 0)
	end
	if (battleFrames or 0) > 0 then
		SaveGame()
	end
	CallListeners("PlayTimeAdded", battleFrames, missionLost)
end

function externalFunctions.PutModuleInSlot(moduleName, level, slot)
	SelectCommanderModule(level, slot, moduleName)
end

function externalFunctions.SetCommanderName(newName)
	gamedata.commanderName = string.gsub(newName,[["]], [[']])
	CallListeners("CommanderNameUpdate", newName)
	SaveGame()
end

function externalFunctions.SetCampaignInitializationComplete()
	if not gamedata.initializationComplete then
		gamedata.initializationComplete = true
		CallListeners("InitializationComplete")
		SaveGame()
	end
end

function externalFunctions.GetCampaignInitializationComplete()
	return gamedata.initializationComplete
end

function externalFunctions.GetPlanetDefs()
	local planetData = planetDefPath and VFS.FileExists(planetDefPath) and VFS.Include(planetDefPath)
	if planetData then
		return planetData
	end
	return {}
end

function externalFunctions.IsPlanetCaptured(planetID)
	return gamedata.planetsCaptured.map[planetID], gamedata.completionDifficulty[planetID]
end

function externalFunctions.GetCapturedPlanetCount()
	return #gamedata.planetsCaptured.list
end

function externalFunctions.GetPlayTime()
	return gamedata.totalPlayFrames, gamedata.totalVictoryPlayFrames
end

function externalFunctions.GetRetinue()
	return gamedata.retinue
end

function externalFunctions.SetCodexEntryRead(entryName)
	if not gamedata.codexEntryRead[entryName] then
		gamedata.codexEntryRead[entryName] = true
		SaveGame()
		return true
	end
	return false
end

function externalFunctions.GetUnitsUnlocks()
	return gamedata.unitsUnlocked
end

function externalFunctions.GetAbilityUnlocks()
	return gamedata.abilitiesUnlocked
end

function externalFunctions.GetUnitIsUnlocked(unitName)
	return gamedata.unitsUnlocked.map[unitName]
end

function externalFunctions.GetModuleIsUnlocked(moduleName)
	return gamedata.modulesUnlocked.map[moduleName], gamedata.modulesUnlockedLimit[moduleName]
end

function externalFunctions.GetModuleListAndLimit()
	return gamedata.modulesUnlocked.list, gamedata.modulesUnlockedLimit
end

function externalFunctions.GetCommanderModuleCounts()
	return commanderModuleCounts
end

function externalFunctions.GetAbilityIsUnlocked(abilityName)
	return gamedata.abilitiesUnlocked.map[abilityName]
end

function externalFunctions.GetCodexEntryIsUnlocked(entryName)
	return gamedata.codexEntriesUnlocked.map[entryName], gamedata.codexEntryRead[entryName]
end

function externalFunctions.GetBonusObjectiveComplete(planetID, objectiveID)
	local index = planetID .. "_" .. objectiveID
	return gamedata.bonusObjectivesComplete.map[index], gamedata.completionDifficulty[index]
end

function externalFunctions.GetUnitInfo(unitName)
	local unitInformation = WG.Chobby.Configuration.gameConfig.gameUnitInformation
	return unitInformation.humanNames[unitName] or {}, ICONS_DIR .. unitName .. ".png", nil, nil, unitInformation.categories
end

function externalFunctions.GetAbilityInfo(abilityName)
	local ability = WG.Chobby.Configuration.campaignConfig.abilityDefs[abilityName] or {}
	return ability, ability.image
end

function externalFunctions.GetModuleInfo(moduleName)
	local parsedName, limit = TranslateModule(moduleName)
	local commConfig = WG.Chobby.Configuration.campaignConfig.commConfig
	local index = commConfig.moduleDefNames[parsedName]
	return index and commConfig.moduleDefs[index] or {}, ICONS_DIR .. parsedName .. ".png", nil, limit and ("\255\0\255\0x" .. limit), commConfig.categories
end

function externalFunctions.GetCodexEntryInfo(codexEntryName)
	return WG.Chobby.Configuration.campaignConfig.codex[codexEntryName] or {}
end

function externalFunctions.GetGamedataInATroublingWay()
	return gamedata
end

function externalFunctions.GetActiveRetinue()
	local activeRetinue = {}
	for i = 1, #gamedata.retinue do
		if gamedata.retinue[i].active then
			activeRetinue[#activeRetinue + 1] = gamedata.retinue[i]
		end
	end
	return activeRetinue
end

function externalFunctions.GetPlayerCommander()
	return {
		name = gamedata.commanderName,
		chassis = gamedata.commanderChassis,
		modules = gamedata.commanderLoadout,
	}
end

function externalFunctions.GetPlayerCommanderInformation()
	return gamedata.commanderLevel, gamedata.commanderExperience, gamedata.commanderName, gamedata.commanderLoadout
end

function externalFunctions.GetSaves()
	return GetSaves()
end

function externalFunctions.LoadGameByFilename(filename)
	local saves = GetSaves()
	local saveData = saves[filename]
	if saveData then
		LoadGame(saveData, true)
		return
	else
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "Save " .. filename .. " does not exist")
	end
end

function externalFunctions.DeleteSave(filename, supressLastSavePrompt)
	local Configuration = WG.Chobby.Configuration

	local success, err = pcall(function()
		local pathNoExtension = SAVE_DIR .. "/" .. filename
		os.remove(pathNoExtension .. ".lua")
		if (filename == Configuration.campaignSaveFile) then
			-- if this is current save, switch to next available save slot, or revert to "Campaign1" if none are available
			local newName
			local saves = GetSaves()
			for name, save in pairs(saves) do
				-- TODO: sort instead of just picking the first one?
				newName = save.name
				LoadGame(save, true)
				break
			end
			WG.Chobby.Configuration:SetConfigValue("campaignSaveFile", newName)
			if not (newName or supressLastSavePrompt) then
				WG.CampaignSaveWindow.PromptPickNewSaveName()
			end
		end
	end)
	if (not success) then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "Error deleting save " .. filename .. ": " .. err)
	end
	return success
end

externalFunctions.StartNewGame = StartNewGame
externalFunctions.SetupNewSave = SetupNewSave

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Initialiazation

function widget:Initialize()
	CHOBBY_DIR = "LuaMenu/widgets/chobby/"
	VFS.Include("LuaMenu/widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	WG.CampaignData = externalFunctions

	WG.Delay(LoadCampaignData, 0.1)
end

function widget:Shutdown()
	WG.CampaignData = nil
end
