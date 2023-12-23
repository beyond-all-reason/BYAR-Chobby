--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Load Game Menu",
		desc      = "UI for Spring save games",
		author    = "KingRaptor",
		date      = "2016.11.24",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local SAVEGAME_BUTTON_HEIGHT = 128
local OUTLINE_COLOR = {0.54,0.72,1,0.3}
local SAVE_DIR = "Saves"
local SAVE_DIR_LENGTH = string.len(SAVE_DIR) + 2
local AUTOSAVE_DIR = SAVE_DIR .. "/auto"
local MAX_SAVES = 999

local Configuration
--------------------------------------------------------------------------------
-- Chili elements
--------------------------------------------------------------------------------
local Chili
local Window
local Panel
local Grid
local StackPanel
local ScrollPanel
local Label
local Button

--------------------------------------------------------------------------------
-- data
--------------------------------------------------------------------------------
local ingame = false

--------------------------------------------------------------------------------
-- General utility functions
--------------------------------------------------------------------------------
local function WriteDate(dateTable)
	return string.format("%02d/%02d/%04d", dateTable.day, dateTable.month, dateTable.year)
	.. "\n" .. string.format("%02d:%02d:%02d", dateTable.hour, dateTable.min, dateTable.sec)
end

local function DateToString(dateTable)
	return string.format("%04d%02d%02d", dateTable.year, dateTable.month, dateTable.day)
	.. " " .. string.format("%02d%02d%02d", dateTable.hour, dateTable.min, dateTable.sec)
end

local function SecondsToClock(seconds)
	local seconds = tonumber(seconds)

	if seconds <= 0 then
		return "00:00";
	else
		hours = string.format("%02d", math.floor(seconds/3600));
		mins = string.format("%02d", math.floor(seconds/60 - (hours*60)));
		secs = string.format("%02d", math.floor(seconds - hours*3600 - mins *60));
		if seconds >= 3600 then
			return hours..":"..mins..":"..secs
		else
			return mins..":"..secs
		end
	end
end

local function Notify(title, stuff)
	Spring.Echo(stuff)
	Chotify:Post({
		title = title,
		body = stuff,
	})
end

--------------------------------------------------------------------------------
-- Savegame utlity functions
--------------------------------------------------------------------------------
-- Returns the data stored in a save file
local function GetSaveExtension(path)
	if VFS.FileExists(path .. ".ssf") then
		return ".ssf"
	end
	return VFS.FileExists(path .. ".slsf") and ".slsf"
end

local function GetSaveWithExtension(path)
	local ext = GetSaveExtension(path)
	return ext and path .. ext
end

local function GetSave(path)
	local ret = nil
	local success, err = pcall(function()
		local saveData = VFS.Include(path)
		saveData.filename = string.sub(path, SAVE_DIR_LENGTH, -5)	-- pure filename without directory or extension
		saveData.path = path
		ret = saveData
	end)
	if (not success) then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "Error getting save " .. path .. ": " .. err)
	else
		local engineSaveFilename = GetSaveWithExtension(string.sub(path, 1, -5))
		if not engineSaveFilename then
			--Spring.Log(widget:GetInfo().name, LOG.ERROR, "Save " .. engineSaveFilename .. " does not exist")
			return nil
		else
			return ret
		end
	end
end

-- Loads the list of save files and their contents
local function GetSaves()
	Spring.CreateDir(SAVE_DIR)
	local saves = {}
	local savefiles = VFS.DirList(SAVE_DIR, "*.lua")
	for i=1,#savefiles do
		local path = savefiles[i]
		local saveData = GetSave(path)
		if saveData then
			saves[#saves + 1] = saveData
		end
	end

	return saves
end

local function GetSaveDescText(saveFile)
	if not saveFile then return "" end
	return saveFile.map .. "\n" .. i18n("time_ingame") .. ": " .. SecondsToClock((saveFile.totalGameframe or saveFile.gameframe or 0)/30)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function LoadGameByFilename(filename)
	Spring.Echo(filename)
	local saveData = GetSave(SAVE_DIR .. '/' .. filename .. ".lua")
	if not saveData then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "Save game " .. filename .. " not found")
		return
	end

	if not (saveData.gameName and saveData.gameVersion and saveData.map) then
		Spring.Echo("Save game missing game or map", saveData.gameName, saveData.gameVersion, saveData.map)
		return
	end

	local game = saveData.gameName .. " " .. saveData.gameVersion
	local map = saveData.map
	local hasGame = true

	if not VFS.HasArchive(game) then
		WG.DownloadHandler.MaybeDownloadArchive(game, "game", -1)
		Notify("Downloading game...", "Retry when complete")
		hasGame = false
	end

	if not VFS.HasArchive(map) then
		WG.DownloadHandler.MaybeDownloadArchive(map, "map", -1)
		Notify("Downloading map...", "Retry when complete")
		return
	end

	local ext = GetSaveExtension(SAVE_DIR .. '/' .. filename)
	if not ext then
		Notify("Load error", "Cannot find save data file " .. SAVE_DIR .. '/' .. filename .. " (.ssf or .slsf).")
		return
	end

	if not hasGame then
		Notify("Load error", "Cannot find game files.")
		return
	end

	if saveData.engineVersion and (Engine.versionFull ~= saveData.engineVersion) then
		-- Both should be "105.1.1-1723-gd990800 BAR105" or whatever
		local ssfFileName = SAVE_DIR .. '/' .. filename .. ".ssf"
		-- we have an engine version mismatch, try in a different engine!
		Spring.Echo("Off-engine savegame found, attempting to start with: ",game,saveData.map, nil,nil, ssfFileName,saveData.engineVersion)

		--This one does not work because the player IDs will mismatch and spam errors
		--WG.SteamCoopHandler.AttemptGameStart("replay", game,saveData.map, nil,nil, ssfFileName,saveData.engineVersion)

		local script = [[
			[GAME]
			{
				SaveFile=__FILE__;
				IsHost=1;
				OnlyLocal=1;
				MyPlayerName=__PLAYERNAME__;
			}
			]]
		script = script:gsub("__FILE__", ssfFileName)
		script = script:gsub("__PLAYERNAME__", saveData.playerName)

		local scriptfilename = "engine_testing_start_script.txt"
		local scriptfile = io.open(scriptfilename, 'w')
		scriptfile:write(script)
		scriptfile:close()

		local params = {
			StartScriptContent = script,
			SpringSettings = WG.SettingsWindow.GetSettingsString(),
			StartDemoName = scriptfilename,
			Engine = string.gsub(saveData.engineVersion, "BAR105", "bar"),
		}
		if WG.Chobby and WG.Chobby.InformationPopup then
			WG.Chobby.InformationPopup("The saved game uses a different engine, so it will be opened in a new window.")
			Spring.SetConfigInt("Fullscreen", 1, false)
			Spring.SetConfigInt("Fullscreen", 0, false)
		end
		Spring.PauseSoundStream()
		WG.WrapperLoopback.StartNewSpring(params)

		return
	end
	-- Gotta check engine version!
	--engineVersion = "105.1.1-1723-gd990800 BAR105",

	local success, err = pcall(
		function()
			--Spring.Log(widget:GetInfo().name, LOG.INFO, "Save file " .. path .. " loaded")
			local script = [[
	[GAME]
	{
		SaveFile=__FILE__;
		IsHost=1;
		OnlyLocal=1;
		MyPlayerName=__PLAYERNAME__;
	}
	]]
			script = script:gsub("__FILE__", filename .. ext)
			script = script:gsub("__PLAYERNAME__", saveData.playerName)
			WG.Chobby.localLobby:StartGameFromString(script)
		end
	)

	if success then
		Notify("Loading save")
	else
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "Error loading game: " .. err)
	end
end

local function DeleteSave(filename, saveList)
	local success, err = pcall(function()
		local pathNoExtension = SAVE_DIR .. "/" .. filename
		os.remove(pathNoExtension .. ".lua")
		local saveFilePath = GetSaveWithExtension(pathNoExtension)
		if saveFilePath then
			os.remove(saveFilePath)
		end

		saveList:RemoveItem(filename)
	end)
	if (not success) then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "Error deleting save " .. filename .. ": " .. err)
	end
end

--------------------------------------------------------------------------------
-- Save/Load UI
--------------------------------------------------------------------------------
local function SaveLoadConfirmationDialogPopup(filename, saveMode)
	local text = i18n("load_confirm")
	local yesFunc = function()
			LoadGameByFilename(filename)
		end
	WG.Chobby.ConfirmationPopup(yesFunc, text, nil, 360, 200)
end

-- Makes a button for a save game on the save/load screen
local function AddSaveEntryButton(saveFile, saveList)
	local container = Panel:New {
		x = 0,
		y = 0,
		width = "100%",
		height = 65,
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
	}

	-- load button
	local actionButton = Button:New {
		right = 3,
		y = 3,
		height = 35,
		width = 65,
		caption = i18n("load"),
		classname = "action_button",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		OnClick = {
			function()
				if ingame then
					SaveLoadConfirmationDialogPopup(saveFile.filename, false)
				else
					LoadGameByFilename(saveFile.filename)
				end
			end
		},
		parent = container,
	}

	-- save's map and image

	local x = 3

	local mapImageFile, needDownload = Configuration:GetMinimapImage(saveFile.map)
	local minimap = Panel:New {
		name = "minimap",
		x = x,
		y = 3,
		width = 74,
		height = 74,
		valign = 'center',
		padding = {1,1,1,1},
		parent = container,
	}

	local mapImage = Image:New {
		x = 0, y = 0,
		right = 0,
		bottom = 0,
		file = mapImageFile,
		fallbackFile = Configuration:GetLoadingImage(3),
		checkFileExists = needDownload,
		parent = minimap,
	}

	x = x + 80

	local details = TextBox:New {
		name = "saveDetails",
		x = x,
		y = 12,
		right = 65,
		height = 20,
		valign = 'center',
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		objectOverrideHintFont = WG.Chobby.Configuration:GetFont(2),
		text = GetSaveDescText(saveFile),
		parent = container,
	}

	-- save date
	x = x + 220
	local saveDate = TextBox:New {
		name = "saveDate",
		x = x + 10,
		y = 12,
		right = 65,
		height = 20,
		valign = 'center',
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		objectOverrideHintFont = WG.Chobby.Configuration:GetFont(2),
		text = WriteDate(saveFile.date),
		parent = container,
	}

	-- save gamename
	x = x + 140
	local shortenname = WG.Chobby.Configuration.gameConfig.ShortenNameString(saveFile.gameName .. " " .. saveFile.gameVersion)
	local gameName = TextBox:New {
		name = "gameName",
		x = x,
		y = 12,
		right = 65,
		height = 20,
		valign = 'center',
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		objectOverrideHintFont = WG.Chobby.Configuration:GetFont(2),
		text = shortenname,
		parent = container,
	}

	-- delete button

	local deleteButton = Button:New {
		parent = container,
		right = 3,
		width = 65,
		height = 35,
		bottom = 4,
		caption = i18n("delete_replay"),
		classname = "negative_button",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		OnClick = { function(self)
				WG.Chobby.ConfirmationPopup(function(self) DeleteSave(saveFile.filename, saveList) end, i18n("delete_confirm"), nil, 360, 200)
			end
		}
	}

	return saveFile.filename, container, {saveFile.filename, saveFile.gameName .. "" .. saveFile.gameVersion, DateToString(saveFile.date), saveFile.map}
end

local function PopulateSaveList(saveList)
	saveList:Clear()
	local saves = GetSaves()
	local items = {}
	for i = 1, #saves do
		local filename, controls, order = AddSaveEntryButton(saves[i], saveList)
		items[#items + 1] = {filename, controls, order}
	end

	saveList:AddItems(items)
end
--------------------------------------------------------------------------------
-- Make Chili controls
--------------------------------------------------------------------------------

local function InitializeControls(parent)
	Configuration = WG.Chobby.Configuration

	Label:New {
		x = 15,
		right = 5,
		y = 14,
		height = 20,
		parent = parent,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		caption = i18n("load_saved_game"),
	}

	-------------------------
	-- Generate List
	-------------------------

	local listHolder = Control:New {
		x = 4,
		right = 7,
		y = 52,
		bottom = 15,
		parent = parent,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
	}

	local headings = {
		{name = i18n("map"), x = 10, width = 298},
		{name = i18n("date"), x = 10 + 298, width = 130},
		{name = i18n("game_version"), x = 10 + 298 + 130, right = 10},
	}

	local saveList = WG.Chobby.SortableList(listHolder, headings, 80, 3)
	PopulateSaveList(saveList)

	local externalFunctions = {}

	function externalFunctions.PopulateSaveList()
		PopulateSaveList(saveList)
	end

	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- External Interface

local LoadGameWindow = {}

function LoadGameWindow.GetControl()
	local controlFuncs

	local window = Control:New {
		name = "loadGameHandler",
		x = "0%",
		y = "0%",
		width = "100%",
		height = "100%",
		OnParent = {
			function(obj)
				if obj:IsEmpty() then
					controlFuncs = InitializeControls(obj)
				else
					-- update save list
					controlFuncs.PopulateSaveList()
				end
			end
		},
	}
	return window
end

--------------------------------------------------------------------------------
-- callins
--------------------------------------------------------------------------------
-- called when returning to menu from a game
function widget:ActivateMenu()
	Spring.Log(widget:GetInfo().name, LOG.INFO, "ActivateMenu called", runningMission)
	ingame = false
end

function widget:Initialize()
	CHOBBY_DIR = "LuaMenu/widgets/chobby/"
	VFS.Include("LuaMenu/widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	Chili = WG.Chili
	Window = Chili.Window
	Panel = Chili.Panel
	StackPanel = Chili.StackPanel
	ScrollPanel = Chili.ScrollPanel
	Label = Chili.Label
	Button = Chili.Button

	WG.LoadGameWindow = LoadGameWindow

	local function OnBattleAboutToStart()
		ingame = true
	end
	WG.LibLobby.localLobby:AddListener("OnBattleAboutToStart", OnBattleAboutToStart)

	WG.LoadGame = {
		LoadGameByFilename = LoadGameByFilename,
	}
end

function widget:Shutdown()
	WG.LoadGame = nil
end
