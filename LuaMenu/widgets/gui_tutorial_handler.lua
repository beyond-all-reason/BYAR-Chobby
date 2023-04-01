--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Tutorial Handler",
		desc      = "Popup prompts for tutorial",
		author    = "GoogleFrog",
		date      = "11 May 2020",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Vars

local tutorialPrompt
local TUTORIAL_PLANET = 69

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Tutorial Action

local function StartTutorial()
	if tutorialPrompt then
		tutorialPrompt.Remove()
	end
	WG.Chobby.interfaceRoot.OpenSingleplayerTabByName("campaign")
	WG.CampaignHandler.OpenPlanetScreen(TUTORIAL_PLANET)
	WG.CampaignHandler.StartPlanetMission(TUTORIAL_PLANET)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Status Prompt

local function InitializeTutorialPrompt()
	local queuePanel = Control:New {
		name = "tutorialprompt",
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		padding = {0,0,0,0},
		resizable = false,
		draggable = false,
	}

	local button = Button:New {
		name = "tutorial",
		x = 4,
		right = 4,
		y = 4,
		bottom = 4,
		padding = {0,0,0,0},
		caption = "Play the Tutorial",
		font = WG.Chobby.Configuration:GetFont(4),
		classname = "action_button",
		OnClick = {
			function()
				StartTutorial()
			end
		},
		parent = queuePanel,
	}

	local externalFunctions = {}

	function externalFunctions.GetHolder()
		return queuePanel
	end

	function externalFunctions.Remove()
		local statusAndInvitesPanel = WG.Chobby.interfaceRoot.GetStatusAndInvitesPanel()
		statusAndInvitesPanel.RemoveControl(queuePanel.name)
	end

	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Tutorial Popup

local function CheckTutorialPopup()
	local Configuration = WG.Chobby.Configuration

	local width, height = Spring.GetViewSizes()

	local tutorialWindow = Window:New {
		caption = "",
		name = "tutorialWindow",
		parent = WG.Chobby.lobbyInterfaceHolder,
		width = 520,
		height = 480,
		resizable = false,
		draggable = false,
		classname = "main_window",
	}

	TextBox:New {
		x = 95,
		right = 15,
		y = 23,
		height = 35,
		fontsize = Configuration:GetFont(4).size,
		text = "Welcome to Zero-K",
		parent = tutorialWindow,
	}

	TextBox:New {
		x = 28,
		right = 28,
		y = 76,
		height = 35,
		fontsize = Configuration:GetFont(2).size,
		text = [[From here you can embark on a galaxy-spanning campaign or play a skirmish against the AI - all under Singleplayer & Coop (invite your friends). Alternately, you can click Multiplayer to host a private game, hop into the matchmaker, or participate in massive public games.]],
		parent = tutorialWindow,
	}

	TextBox:New {
		x = 28,
		right = 28,
		y = 208,
		height = 35,
		fontsize = Configuration:GetFont(2).size,
		text = [[To get started we recommend playing the tutorial at the start of the campaign. Click the button below to begin. We hope you have fun, whatever you choose.]],
		parent = tutorialWindow,
	}

	local function CancelFunc()
		if not tutorialPrompt then
			local statusAndInvitesPanel = WG.Chobby.interfaceRoot.GetStatusAndInvitesPanel()
			tutorialPrompt = InitializeTutorialPrompt()
			statusAndInvitesPanel.AddControl(tutorialPrompt.GetHolder(), 15)
		end
		tutorialWindow:Dispose()
	end

	local offset = 285
	Button:New {
		x = "18%",
		y = offset,
		right = "18%",
		height = 70,
		caption = "Play the Tutorial",
		font = Configuration:GetFont(4),
		classname = "action_button",
		padding = {2,4,4,4},
		OnClick = {
			function()
				tutorialWindow:Dispose()
				StartTutorial()
			end
		},
		parent = tutorialWindow,
	}
	offset = offset + 74

	Button:New {
		right = 2,
		bottom = 2,
		width = 110,
		height = 42,
		classname = "negative_button",
		caption = i18n("close"),
		font = Configuration:GetFont(3),
		OnClick = {
			CancelFunc
		},
		parent = tutorialWindow,
	}

	local popupHolder = WG.Chobby.PriorityPopup(tutorialWindow, CancelFunc, CancelFunc)

	return true
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- External Interface

local externalFunctions = {}

--------------------------------------------------------------------------------
-- Callins
--------------------------------------------------------------------------------

function DelayedInitialize()
	if WG.Chobby.Configuration.firstBattleStarted or not WG.Chobby.Configuration.gameConfig.runTutorial then
		return
	end
	CheckTutorialPopup()

	local function onConfigurationChange(listener, key, value)
		if key ~= "firstBattleStarted" then
			return
		end
		if tutorialPrompt then
			tutorialPrompt.Remove()
		end
	end

	Configuration:AddListener("OnConfigurationChange", onConfigurationChange)
end

function widget:Initialize()
	CHOBBY_DIR = "LuaMenu/widgets/chobby/"
	VFS.Include("LuaMenu/widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	WG.TutorialPromptHandler = externalFunctions
	WG.Delay(DelayedInitialize, 1)
end

function widget:Shutdown()
	WG.TutorialPromptHandler = nil
end
