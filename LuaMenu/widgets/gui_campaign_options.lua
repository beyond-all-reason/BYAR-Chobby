--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Campaign Options Window",
		desc      = "Stuff",
		author    = "GoogleFrog, KingRaptor",
		date      = "4 July 2016",
		license   = "GNU LGPL, v2.1 or later",
		layer     = -100000,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Configuration

local ITEM_OFFSET = 38

local COMBO_X = 230
local COMBO_WIDTH = 235
local CHECK_WIDTH = 230
local TEXT_OFFSET = 6

local DIFFICULTY_NAME_MAP = {"Imported", "Easy", "Normal", "Hard", "Brutal", "None"}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utilities

local function PopulateTab(settingPresets, settingOptions, settingsDefault)
	local children = {}
	local offset = 5
	local customSettingsSwitch
	local label, list

	if settingPresets then
		label, list, customSettingsSwitch, offset = MakePresetsControl(settingPresets, offset)
		children[#children + 1] = label
		children[#children + 1] = list
	end

	for i = 1, #settingOptions do
		local data = settingOptions[i]
		if data.displayModeToggle then
			label, list, offset = ProcessScreenSizeOption(data, offset)
		elseif data.isNumberSetting then
			label, list, offset = ProcessSettingsNumber(data, offset, settingsDefault, customSettingsSwitch)
		else
			label, list, offset = ProcessSettingsOption(data, offset, settingsDefault, customSettingsSwitch)
		end
		children[#children + 1] = label
		children[#children + 1] = list
	end

	return children
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Difficulty Window

local function InitializeDifficultyWindow(parent)
	local Configuration = WG.Chobby.Configuration

	local offset = 5
	local freezeSettings = true

	Label:New {
		x = 20,
		y = offset + TEXT_OFFSET,
		width = 90,
		height = 30,
		valign = "top",
		align = "left",
		font = Configuration:GetFont(2),
		caption = "Difficulty",
		parent = parent,
	}
	local comboDifficulty = ComboBox:New {
		x = COMBO_X,
		y = offset,
		width = COMBO_WIDTH,
		height = 30,
		items = {"Easy", "Normal", "Hard", "Brutal"},
		selected = 2,
		font = Configuration:GetFont(2),
		itemFontSize = Configuration:GetFont(2).size,
		selected = WG.CampaignData.GetDifficultySetting(),
		OnSelect = {
			function (obj)
				if freezeSettings then
					return
				end
				WG.CampaignData.SetDifficultySetting(obj.selected)
			end
		},
		parent = parent,
	}
	offset = offset + ITEM_OFFSET

	local function UpdateSettings()
		freezeSettings = true
		comboDifficulty:Select(WG.CampaignData.GetDifficultySetting())
		freezeSettings = false
	end
	WG.CampaignData.AddListener("CampaignSettingsUpdate", UpdateSettings)
	WG.CampaignData.AddListener("CampaignLoaded", UpdateSettings)

	freezeSettings = false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Stats Window

local function MakeStatLabel(parent, offset, name)
	local fontSize = WG.Chobby.Configuration:GetFont(2).size

	TextBox:New {
		x = 20,
		y = offset + TEXT_OFFSET,
		width = 200,
		height = 30,
		fontsize = fontSize,
		text = name,
		parent = parent,
	}
	local infoText = TextBox:New {
		x = COMBO_X + 8,
		y = offset + TEXT_OFFSET,
		width = 200,
		height = 30,
		fontsize = fontSize,
		text = "",
		parent = parent,
	}
	return offset + ITEM_OFFSET, infoText
end

local function InitializeStatsWindow(parent)
	local Configuration = WG.Chobby.Configuration

	local offset = 5
	local freezeSettings = true

	local leastDifficulty, totalTime, totalVictoryTime, planets, bonusObjectives, level, experience

	offset, leastDifficulty  = MakeStatLabel(parent, offset, "Lowest difficulty")
	offset, totalTime        = MakeStatLabel(parent, offset, "Ingame time")
	offset, totalVictoryTime = MakeStatLabel(parent, offset, "Victory ingame time")
	offset, planets          = MakeStatLabel(parent, offset, "Planets captured")
	offset, bonusObjectives  = MakeStatLabel(parent, offset, "Bonus objectives")
	offset, level            = MakeStatLabel(parent, offset, "Commander level")
	offset, experience       = MakeStatLabel(parent, offset, "Commander experience")

	local function UpdateStats()
		local gamedata = WG.CampaignData.GetGamedataInATroublingWay()
		leastDifficulty:SetText(DIFFICULTY_NAME_MAP[gamedata.leastDifficulty or 5])
		totalTime:SetText(Spring.Utilities.FormatTime((gamedata.totalPlayFrames or 0)/30, true))
		totalVictoryTime:SetText(Spring.Utilities.FormatTime((gamedata.totalVictoryPlayFrames or 0)/30, true))
		planets:SetText(tostring(#(gamedata.planetsCaptured.list or {})))
		bonusObjectives:SetText(tostring(#(gamedata.bonusObjectivesComplete.list or {})))
		level:SetText(tostring((gamedata.commanderLevel or 0) + 1))
		experience:SetText(tostring(gamedata.commanderExperience or 0))
	end

	UpdateStats()

	WG.CampaignData.AddListener("CampaignLoaded", UpdateStats)
	WG.CampaignData.AddListener("PlanetUpdate", UpdateStats)
	WG.CampaignData.AddListener("PlayTimeAdded", UpdateStats)
	WG.CampaignData.AddListener("GainExperience", UpdateStats)

	freezeSettings = false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Initialization

local function MakeTab(name, children)
	local contentsPanel = ScrollPanel:New {
		x = 5,
		right = 5,
		y = 10,
		bottom = 8,
		horizontalScrollbar = false,
		verticalScrollbar = false,
		children = children
	}

	return {
		name = name,
		caption = name,
		font = WG.Chobby.Configuration:GetFont(3),
		children = {contentsPanel}
	}
end

local function MakeStandardTab(name, ChildrenFunction)
	local window = Control:New {
		name = "statsHandler",
		x = "0%",
		y = "0%",
		width = "100%",
		height = "100%",
		OnParent = {
			function(obj)
				if obj:IsEmpty() then
					ChildrenFunction(obj)
				end
			end
		},
	}

	local contentsPanel = ScrollPanel:New {
		x = 5,
		right = 5,
		y = 10,
		bottom = 8,
		horizontalScrollbar = false,
		verticalScrollbar = false,
		children = {window}
	}

	return {
		name = name,
		caption = name,
		font = WG.Chobby.Configuration:GetFont(3),
		children = {contentsPanel}
	}
end

local function RefreshControls(window)
	WG.CampaignSaveWindow.PopulateSaveList()
end

local function InitializeControls(window)
	window.OnParent = nil

	local btnClose = Button:New {
		right = 11,
		y = 7,
		width = 80,
		height = 45,
		caption = i18n("close"),
		font = WG.Chobby.Configuration:GetFont(3),
		classname = "negative_button",
		OnClick = {
			function()
				window:Hide()
			end
		},
		parent = window
	}

	local tabs = {
		MakeTab("Save/Load", {WG.CampaignSaveWindow.GetControl()}),
		--MakeStandardTab("Difficulty", InitializeDifficultyWindow),
		MakeStandardTab("Stats", InitializeStatsWindow),
	}

	local tabPanel = Chili.DetachableTabPanel:New {
		x = 7,
		right = 7,
		y = 50,
		bottom = 6,
		padding = {0, 0, 0, 0},
		minTabWidth = 120,
		tabs = tabs,
		parent = window,
		OnTabChange = {
		}
	}

	local tabBarHolder = Control:New {
		name = "tabBarHolder",
		x = 6,
		y = 5,
		right = 65,
		height = 55,
		resizable = false,
		draggable = false,
		padding = {14, 8, 14, 0},
		parent = window,
		children = {
			tabPanel.tabBar
		}
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- External Interface

local CampaignOptionsWindow = {}

function CampaignOptionsWindow.GetControl()

	local window = Control:New {
		name = "campaignOptionsWindow",
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		padding = {0, 0, 0, 0},
		OnParentPost = {
			function(obj)
				if obj:IsEmpty() then
					InitializeControls(obj)
				else
					RefreshControls(obj)
				end
			end
		},
	}
	return window
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Callins

function widget:Initialize()
	CHOBBY_DIR = LUA_DIRNAME .. "widgets/chobby/"
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	WG.CampaignOptionsWindow = CampaignOptionsWindow
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
