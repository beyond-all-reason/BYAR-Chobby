--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Campaign Save/Load",
		desc      = "Create and manage campaign saves",
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
local SAVE_DIR = "Saves/campaign"
local SAVE_DIR_LENGTH = string.len(SAVE_DIR) + 2
local AUTOSAVE_DIR = SAVE_DIR .. "/auto"

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

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function GetSaveDescText(saveFile)
	if not saveFile then return "" end
	return (saveFile.description or "no description")
		.. "\n" .. saveFile.chapterTitle
end

local function SaveGame(filename)
	local result = WG.CampaignData.SaveGame(filename)
	if result and WG.CampaignSaveWindow.PopulateSaveList then
		WG.CampaignSaveWindow.PopulateSaveList()
	end
end

local function LoadGame(filename)
	WG.CampaignData.LoadGameByFilename(filename)
	if WG.CampaignSaveWindow.PopulateSaveList then
		WG.CampaignSaveWindow.PopulateSaveList()
	end
end

local function DeleteSave(filename, supressLastSavePrompt)
	WG.CampaignData.DeleteSave(filename, supressLastSavePrompt)
	if WG.CampaignSaveWindow.PopulateSaveList then
		WG.CampaignSaveWindow.PopulateSaveList()
	end
end

local function PromptNewSave(backOnFail)
	local Configuration = WG.Chobby.Configuration
	local saveFile
	if backOnFail then
		saveFile = WG.CampaignData.StartNewGame()
	end

	local Configuration = WG.Chobby.Configuration
	local lobby = WG.LibLobby.lobby
	local defaultCommName = Configuration:GetPlayerName(true)

	local newSaveWindow = Window:New {
		x = 700,
		y = 300,
		width = 316,
		height = 300,
		caption = "",
		resizable = false,
		draggable = false,
		parent = WG.Chobby.lobbyInterfaceHolder,
		classname = "main_window",
		OnDispose = {
			function()
				lobby:RemoveListener("OnJoinBattleFailed", onJoinBattleFailed)
				lobby:RemoveListener("OnJoinBattle", onJoinBattle)
			end
		},
	}

	local offset = 15
	local lblSaveName = Label:New {
		x = 25,
		right = 15,
		y = offset,
		height = 35,
		font = Configuration:GetFont(3),
		caption = i18n("commander_name"),
		parent = newSaveWindow,
	}
	offset = offset + 35
	local ebSaveName = EditBox:New {
		x = 25,
		right = 25,
		y = offset,
		height = 35,
		text = defaultCommName,
		hint = i18n("commander_name"),
		fontsize = Configuration:GetFont(3).size,
		parent = newSaveWindow,
	}
	offset = offset + 52

	local lblDifficulty = Label:New {
		x = 25,
		right = 15,
		y = offset,
		height = 35,
		font = Configuration:GetFont(3),
		caption = "Difficulty",
		parent = newSaveWindow,
	}
	offset = offset + 35
	local comboDifficulty = ComboBox:New {
		x = 25,
		right = 25,
		y = offset,
		height = 35,
		text = "",
		items = {"Easy", "Normal", "Hard", "Brutal"},
		font = Configuration:GetFont(3),
		itemFontSize = Configuration:GetFont(3).size,
		selected = 2,
		parent = newSaveWindow,
	}
	offset = offset + 52

	local function NewSave()
		if ebSaveName.text and ebSaveName.text ~= "" then
			if not saveFile then
				WG.CampaignData.StartNewGame()
			end
			WG.CampaignData.SetupNewSave(ebSaveName.text, comboDifficulty.selected)
			newSaveWindow:Dispose()
		end
	end

	local function CancelFunc()
		if backOnFail then
			WG.Chobby.interfaceRoot.OpenSingleplayerTabByName()
		end
		if saveFile then
			DeleteSave(saveFile, true)
		end
		newSaveWindow:Dispose()
	end

	local btnJoin = Button:New {
		x = 5,
		width = 135,
		bottom = 1,
		height = 70,
		caption = i18n("ok"),
		font = Configuration:GetFont(3),
		classname = "action_button",
		OnClick = {
			function()
				NewSave()
			end
		},
		parent = newSaveWindow,
	}
	local btnClose = Button:New {
		right = 5,
		width = 135,
		bottom = 1,
		height = 70,
		caption = i18n("cancel"),
		font = Configuration:GetFont(3),
		classname = "negative_button",
		OnClick = {
			function()
				CancelFunc()
			end
		},
		parent = newSaveWindow,
	}

	local popupHolder = WG.Chobby.PriorityPopup(newSaveWindow, CancelFunc, NewSave)
	screen0:FocusControl(ebSaveName)
end

--------------------------------------------------------------------------------
-- Save/Load UI
--------------------------------------------------------------------------------

-- Makes a button for a save game on the save/load screen
local function AddSaveEntryButton(saveFile, saveList)
	local Configuration = WG.Chobby.Configuration
	local current = (saveFile.name == Configuration.campaignSaveFile)

	local container = Panel:New {
		x = 0,
		y = 0,
		width = "100%",
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
	}

	if not current then
		-- load button
		local loadButton = Button:New {
			x = 3,
			y = 3,
			bottom = 3,
			width = 65,
			caption = i18n("load"),
			classname = "action_button",
			font = WG.Chobby.Configuration:GetFont(2),
			OnClick = {
				function()
					LoadGame(saveFile.name)
				end
			},
			parent = container,
		}
	end

	-- save name
	local x = 95

	local saveName = TextBox:New {
		name = "saveName",
		x = x,
		y = 12,
		right = 0,
		height = 20,
		valign = 'center',
		fontsize = Configuration:GetFont(3).size,
		text = saveFile.commanderName .. (current and " \255\0\255\255(current)\008" or ""),
		parent = container,
	}

	local planetsCaptured = (saveFile.planetsCaptured and #saveFile.planetsCaptured.list) or 0
	local saveInformation = TextBox:New {
		name = "saveInformation",
		x = x + 3,
		y = 35,
		right = 0,
		height = 20,
		valign = 'center',
		fontsize = Configuration:GetFont(2).size,
		text = "Level: " .. (saveFile.commanderLevel + 1) .. "\nPlanets: " .. planetsCaptured,
		parent = container,
	}
	x = x + 220

	-- save's campaign name
	--local campaignNameStr = WG.CampaignData.GetCampaignTitle(saveFile.campaignID) or saveFile.campaignID
	--local campaignName = TextBox:New {
	--	name = "gameName",
	--	x = x,
	--	y = 12,
	--	right = 0,
	--	height = 20,
	--	valign = 'center',
	--	fontsize = Configuration:GetFont(2).size,
	--	text = campaignNameStr,
	--	parent = container,
	--}
	--x = x + 220

	-- save date
	local saveDate = TextBox:New {
		name = "saveDate",
		y = 12,
		right = 80,
		width = 110,
		height = 20,
		valign = 'center',
		fontsize = Configuration:GetFont(2).size,
		text = WriteDate(saveFile.date),
		parent = container,
	}
	x = x + 110

	-- save details
	--local details = TextBox:New {
	--	name = "saveDetails",
	--	x = x,
	--	y = 12,
	--	right = 0,
	--	height = 20,
	--	valign = 'center',
	--	fontsize = Configuration:GetFont(2).size,
	--	text = GetSaveDescText(saveFile),
	--	parent = container,
	--}
	--x = x + 200

	-- delete button
	local deleteButton = Button:New {
		parent = container,
		right = 3,
		width = 65,
		y = 4,
		bottom = 4,
		caption = i18n("delete"),
		classname = "action_button",
		font = WG.Chobby.Configuration:GetFont(2),
		OnClick = {
			function(self)
				WG.Chobby.ConfirmationPopup(function(self) DeleteSave(saveFile.name) end, i18n("delete_confirm"), nil, 360, 200)
			end
		}
	}

	return container, {saveFile.name, DateToString(saveFile.date)}
end

local function UpdateSaveList(saveList)
	saveList:Clear()
	local saves = WG.CampaignData.GetSaves()
	local items = {}
	for name, save in pairs(saves) do
		local controls, order = AddSaveEntryButton(save, saveList)
		if controls then
			items[#items + 1] = {save.name, controls, order}
		end
	end

	saveList:AddItems(items)
end

--------------------------------------------------------------------------------
-- Make Chili controls
--------------------------------------------------------------------------------

local function InitializeControls(parent, saveMode)
	local Configuration = WG.Chobby.Configuration

	-------------------------
	-- Generate List
	-------------------------
	local listHolder = Control:New {
		x = 12,
		right = 6,
		y = 60,
		bottom = 15,
		parent = parent,
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
	}

	local headings = {
		{name = "Name", x = 85, right = 215},
		{name = "Date", right = 100, width = 110},
	}

	local saveList = WG.Chobby.SortableList(listHolder, headings, 75, 2)
	UpdateSaveList(saveList)

	local saveButton = Button:New {
		x = 5,
		y = 5,
		width = 160,
		height = 38,
		caption = i18n("new_campaign"),
		font = Configuration:GetFont(3),
		classname = "option_button",
		parent = parent,
		OnClick = {
			function ()
				PromptNewSave()
			end
		},
	}

	local externalFunctions = {}

	function externalFunctions.PopulateSaveList()
		UpdateSaveList(saveList)
	end

	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- External Interface

local CampaignSaveWindow = {}

function CampaignSaveWindow.GetControl()
	local controlFuncs

	local window = Control:New {
		name = "campaignSaveHandler",
		x = "0%",
		y = "0%",
		width = "100%",
		height = "100%",
		OnParent = {
			function(obj)
				if obj:IsEmpty() then
					controlFuncs = InitializeControls(obj, saveMode)
					CampaignSaveWindow.PopulateSaveList = controlFuncs.PopulateSaveList -- hax
				end
			end
		},
	}

	return window
end

function CampaignSaveWindow.PromptPickNewSaveName()
	local Configuration = WG.Chobby.Configuration
	if not Configuration.campaignSaveFile then
		PromptNewSave(true)
	end
end

function CampaignSaveWindow.PromptInitialSaveName()
	local Configuration = WG.Chobby.Configuration
	if not Configuration.campaignSaveFile then
		local lobby = WG.LibLobby.lobby
		local commName = (lobby and lobby.myUserName) or Configuration.suggestedNameFromSteam
		if commName then
			WG.CampaignData.StartNewGame()
			WG.CampaignData.SetupNewSave(commName, 2)
		else
			PromptNewSave(true)
		end
	end
end

--------------------------------------------------------------------------------
-- callins
--------------------------------------------------------------------------------

function widget:Initialize()
	CHOBBY_DIR = "LuaMenu/widgets/chobby/"
	VFS.Include("LuaMenu/widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	WG.CampaignSaveWindow = CampaignSaveWindow
end

function widget:Shutdown()
	WG.CampaignSaveWindow = nil
end
