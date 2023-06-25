--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Campaign Handler",
		desc      = "Explore the galaxy",
		author    = "GoogleFrog",
		date      = "25 Jan 2017",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

local GALAXY_IMAGE = LUA_DIRNAME .. "images/heic1403aDowngrade.jpg"
local IMAGE_BOUNDS = {
	x = 810/4000,
	y = 710/2602,
	width = 2400/4000,
	height = 1500/2602,
}

local TRANSFORM_BOUNDS = {
	left = -0.03,
	top = 0,
	right = 1,
	bottom = 1,
}

local difficultyNameMap = {
	[0] = "Import",
	[1] = "Easy",
	[2] = "Normal",
	[3] = "Hard",
	[4] = "Brutal",
}

local edgeDrawList = 0
local planetConfig, planetAdjacency, planetEdgeList

local ACTIVE_COLOR = {0,1,0,0.75}
local INACTIVE_COLOR = {0.2, 0.2, 0.2, 0.75}
local HIDDEN_COLOR = {0.2, 0.2, 0.2, 0}

local PLANET_START_COLOR = {1, 1, 1, 1}
local PLANET_NO_START_COLOR = {0.5, 0.5, 0.5, 1}

local TARGET_IMAGE = LUA_DIRNAME .. "images/niceCircle.png"
local IMG_LINK     = LUA_DIRNAME .. "images/link.png"
local PARTY_LINK     = LUA_DIRNAME .. "images/partyinvite.png"

local REWARD_ICON_SIZE = 58
local DEBUG_UNLOCK_SIZE = 26
local DEBUG_UNLOCK_COLUMNS = 4

local VISIBILITY_DISTANCE = 2 -- Distance from captured at which planets are visible.

local LIVE_TESTING
local PLANET_WHITELIST
local PLANET_COUNT = 0

local debugPlanetSelected, debugPlanetSelectedName

local planetHandler
local planetList
local selectedPlanet
local currentWinPopup

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Edge Drawing

local function IsEdgeVisible(p1, p2)
	if PLANET_WHITELIST and ((not PLANET_WHITELIST[p1]) or (not PLANET_WHITELIST[p2])) then
		return false
	end
	return (planetList[p1] and planetList[p1].GetVisible()) or (planetList[p2] and planetList[p2].GetVisible())
end

local function DrawEdgeLines()
	for i = 1, #planetEdgeList do
		if IsEdgeVisible(planetEdgeList[i][1], planetEdgeList[i][2]) then
			for p = 1, 2 do
				local pid = planetEdgeList[i][p]
				local planetData = planetList[pid]
				local hidden = not (planetData and planetData.GetVisible()) -- Note that planets not in the whitelist have planetData = nil
				local x, y = planetHandler.GetZoomTransform(planetConfig[pid].mapDisplay.x, planetConfig[pid].mapDisplay.y)
				gl.Color((hidden and HIDDEN_COLOR) or (planetData.GetCaptured() and ACTIVE_COLOR) or INACTIVE_COLOR)
				gl.Vertex(x, y)
			end
		end
	end
end

local function CreateEdgeList()
	gl.BeginEnd(GL.LINES, DrawEdgeLines)
end

local function UpdateEdgeList()
	gl.DeleteList(edgeDrawList)
	edgeDrawList = gl.CreateList(CreateEdgeList)
	planetHandler.SendEdgesToBack()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Feedback/testing warning window

local function MakeFeedbackWindow(parent, feedbackLink)
	local Configuration = WG.Chobby.Configuration

	local holder = Control:New {
		right = 60,
		y = 40,
		width = 390,
		height = 240,
		padding = {0,0,0,0},
		parent = parent,
	}

	local textWindow = Window:New{
		classname = "main_window_small",
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		resizable = false,
		draggable = false,
		parent = holder,
	}

	TextBox:New {
		x = 55,
		right = 15,
		y = 15,
		height = 35,
		text = "Campaign Testing",
		fontsize = Configuration:GetFont(4).size,
		parent = textWindow,
	}

	local missionCount = 0
	if PLANET_WHITELIST then
		for _,_ in pairs(PLANET_WHITELIST) do
			missionCount = missionCount + 1
		end
	end

	TextBox:New {
		x = 15,
		right = 15,
		y = 58,
		height = 35,
		lineSpacing = 1,
		text = "New missions are released every Sunday. Currently there are " .. (missionCount or "??") .. " missions. Please post your thoughts, feedback and issues on the forum.",
		fontsize = Configuration:GetFont(2).size,
		parent = textWindow,
	}

	Button:New {
		x = 95,
		right = 95,
		bottom = 12,
		height = 45,
		caption = "Post Feedback",
		classname = "action_button",
		font = WG.Chobby.Configuration:GetFont(3),
		OnClick = {
			function ()
				WG.BrowserHandler.OpenUrl(feedbackLink)
			end
		},
		parent = textWindow,
	}
end

local function MakeFeedbackButton(parentControl, link, x, y, right, bottom)
	local feedbackButton = Button:New {
		x = x,
		y = y,
		right = right,
		bottom = bottom,
		width = 116,
		height = 45,
		padding = {0, 0, 0, 0},
		caption = "Feedback   ",
		classname = "option_button",
		font = WG.Chobby.Configuration:GetFont(2),
		tooltip = "Post feedback on the forum",
		OnClick = {
			function ()
				WG.BrowserHandler.OpenUrl(link)
			end
		},
		parent = parentControl,
	}

	local imMapLink = Image:New {
		right = 6,
		y = 13,
		width = 16,
		height = 16,
		keepAspect = true,
		file = IMG_LINK,
		parent = feedbackButton,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Save planet positions

local function EchoPlanetPositionAndEdges()
	Spring.Echo("planetEdgeList = {")
	for i = 1, #planetEdgeList do
		Spring.Echo(string.format("\t{%02d, %02d},", planetEdgeList[i][1], planetEdgeList[i][2]))
	end
	Spring.Echo("}")
	Spring.Echo("planetPositions = {")
	for i = 1, #planetConfig do
		Spring.Echo(string.format("\t[%01d] = {%03f, %03f},", i, math.floor(planetConfig[i].mapDisplay.x*1000), math.floor(planetConfig[i].mapDisplay.y*1000)))
	end
	Spring.Echo("}")
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Difficulty Setting

local difficultyWindow

local function InitializeDifficultySetting()
	local Configuration = WG.Chobby.Configuration

	local window = Control:New{
		right = 170,
		bottom = 0,
		width = 128,
		height = 53,
		padding = {0,0,0,0},
		resizable = false,
		draggable = false,
		parent = nil,
	}
	local freezeSettings = true

	Label:New {
		x = 30,
		y = 2,
		width = 50,
		height = 30,
		valign = "top",
		align = "left",
		font = Configuration:GetFont(2),
		caption = "Difficulty",
		parent = window,
	}
	local comboDifficulty = ComboBox:New {
		x = 4,
		right = 1,
		bottom = 3,
		height = 28,
		--debugPosition = true,
		items = {"Easy", "Normal", "Hard", "Brutal"},
		selected = 2,
		preferComboUp = true,
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
		parent = window,
	}

	local function UpdateSettings()
		freezeSettings = true
		comboDifficulty:Select(WG.CampaignData.GetDifficultySetting())
		freezeSettings = false
	end
	WG.CampaignData.AddListener("CampaignSettingsUpdate", UpdateSettings)
	WG.CampaignData.AddListener("CampaignLoaded", UpdateSettings)

	freezeSettings = false
	return window
end

local function CodexClick(entryName)
	if not WG.CampaignData.GetCodexEntryIsUnlocked(entryName) then
		return
	end
	if currentWinPopup then
		currentWinPopup.CloseWinPopup(true)
	end

	local singleplayerMenu = WG.Chobby.interfaceRoot.GetSingleplayerSubmenu()
	if singleplayerMenu then
		local campaignMenu = singleplayerMenu.GetSubmenuByName("campaign")
		if campaignMenu then
			campaignMenu.OpenTabByName("codex")
			WG.CodexHandler.OpenEntry(entryName)
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Rewards panels

local function MakeRewardList(holder, bottom, name, rewardsTypes, cullUnlocked, widthMult, stackHeight)
	if (not rewardsTypes) or #rewardsTypes == 0 then
		return false
	end

	local Configuration = WG.Chobby.Configuration

	widthMult = widthMult or 1
	stackHeight = stackHeight or 1

	local scroll, rewardsHolder

	local position = 0
	for t = 1, #rewardsTypes do
		local rewardList, tooltipFunction, alreadyUnlockedCheck, overrideTooltip, clickFunc = rewardsTypes[t][1], rewardsTypes[t][2], rewardsTypes[t][3], rewardsTypes[t][4], rewardsTypes[t][5]
		if rewardList then
			for i = 1, #rewardList do
				local alreadyUnlocked = alreadyUnlockedCheck(rewardList[i])
				if not (cullUnlocked and alreadyUnlocked) then
					if not rewardsHolder then
						rewardsHolder = Control:New {
							x = 10,
							right = 10,
							bottom = bottom,
							height = 94,
							padding = {0, 0, 0, 0},
							parent = holder,
						}

						TextBox:New {
							x = 4,
							y = 2,
							right = 4,
							height = 30,
							text = name,
							font = Configuration:GetFont(2),
							parent = rewardsHolder
						}

						scroll = ScrollPanel:New {
							classname = "scrollpanel_borderless",
							x = 3,
							y = 18,
							right = 3,
							bottom = 2,
							scrollbarSize = 12,
							padding = {0, 0, 0, 0},
							parent = rewardsHolder,
						}
					end

					local info, imageFile, imageOverlay, count = tooltipFunction(rewardList[i])

					local x, y = (REWARD_ICON_SIZE*widthMult + 4)*math.floor(position/stackHeight), (position%stackHeight)*REWARD_ICON_SIZE/stackHeight
					if imageFile then
						local color = nil
						local statusString = ""
						if alreadyUnlocked then
							statusString = " (already unlocked)"
						elseif cullUnlocked then
							statusString = " (newly unlocked)"
						else
							color = {0.5, 0.5, 0.5, 0.5}
						end
						local tooltip = (overrideTooltip and info) or ((info.humanName or "???") .. statusString .. "\n " .. (info.description or ""))

						local image = Image:New{
							x = x,
							y = y,
							width = REWARD_ICON_SIZE*widthMult,
							height = REWARD_ICON_SIZE/stackHeight,
							keepAspect = true,
							color = color,
							tooltip = string.gsub(tooltip, "_COUNT_", ""),
							file = imageOverlay or imageFile,
							file2 = imageOverlay and imageFile,
							parent = scroll,
						}
						if count then
							Label:New {
								x = 2,
								y = "50%",
								right = 4,
								bottom = 6,
								align = "right",
								fontsize = Configuration:GetFont(3).size,
								caption = count,
								parent = image,
							}
						end
						function image:HitTest(x,y) return self end
					else
						local tooltip = (overrideTooltip and info) or (info.name or "???")

						Button:New {
							x = x,
							y = y,
							width = REWARD_ICON_SIZE*widthMult,
							height = REWARD_ICON_SIZE/stackHeight,
							caption = string.gsub(tooltip, "_COUNT_", ""),
							font = Configuration:GetFont(2),
							OnClick = clickFunc and {
								function()
									clickFunc(rewardList[i])
								end
							},
							parent = scroll
						}
					end

					position = position + 1
				end
			end
		end
	end

	return (rewardsHolder and true) or false
end

local function MakeBonusObjectiveLine(parent, bottom, planetData, bonusObjectiveSuccess, difficulty)

	local objectiveConfig = planetData.gameConfig.bonusObjectiveConfig
	if not objectiveConfig then
		return bottom
	end

	local difficultyName = difficultyNameMap[difficulty or 0]

	if bonusObjectiveSuccess then
		local function IsObjectiveUnlocked(objectiveID)
			return bonusObjectiveSuccess[objectiveID]
		end
		local function GetObjectiveInfo(objectiveID)
			local tooltip = objectiveConfig[objectiveID].description
			local complete, oldDifficulty = WG.CampaignData.GetBonusObjectiveComplete(planetData.index, objectiveID)
			if complete then
				if bonusObjectiveSuccess[objectiveID] and ((difficulty or 0) > (oldDifficulty or 0)) then
					tooltip = tooltip .. " \n(Improved difficulty from " .. difficultyNameMap[oldDifficulty or 0] .. " to " .. difficultyName .. ")"
				else
					tooltip = tooltip .. " \n(Previously complete on " .. difficultyNameMap[oldDifficulty or 0] .. ")"
				end
			elseif bonusObjectiveSuccess[objectiveID] then
				tooltip = tooltip .. " \n(Newly completed on " .. difficultyName .. ")"
			else
				tooltip = tooltip .. " \n(Incomplete)"
			end
			return tooltip, objectiveConfig[objectiveID].image, objectiveConfig[objectiveID].imageOverlay
		end
		local objectiveList = {}
		for i = 1, #objectiveConfig do
			objectiveList[i] = i
		end
		if MakeRewardList(parent, bottom, "Bonus Objectives", {{objectiveList, GetObjectiveInfo, IsObjectiveUnlocked, true}}, false) then
			return bottom + 98
		end
	else
		local function IsObjectiveUnlocked(objectiveID)
			return WG.CampaignData.GetBonusObjectiveComplete(planetData.index, objectiveID)
		end
		local function GetObjectiveInfo(objectiveID)
			local complete, oldDifficulty = WG.CampaignData.GetBonusObjectiveComplete(planetData.index, objectiveID)
			local tooltip = objectiveConfig[objectiveID].description
			if complete then
				tooltip = tooltip .. "\nHighest difficulty: " .. difficultyNameMap[oldDifficulty or 0]
			end
			return tooltip, objectiveConfig[objectiveID].image, objectiveConfig[objectiveID].imageOverlay
		end
		local objectiveList = {}
		for i = 1, #objectiveConfig do
			objectiveList[i] = i
		end
		if MakeRewardList(parent, bottom, "Bonus Objectives", {{objectiveList, GetObjectiveInfo, IsObjectiveUnlocked, true}}, false) then
			return bottom + 98
		end
	end

	return bottom
end

local function MakeRewardsPanel(parent, bottom, planetData, cullUnlocked, showCodex, bonusObjectiveSuccess, difficulty)
	rewards = planetData.completionReward

	if showCodex then
		if MakeRewardList(parent, bottom, "Codex", {{rewards.codexEntries, WG.CampaignData.GetCodexEntryInfo, WG.CampaignData.GetCodexEntryIsUnlocked, false, CodexClick}}, cullUnlocked, 3.96, 2) then
			bottom = bottom + 98

			local singleplayerMenu = WG.Chobby.interfaceRoot.GetSingleplayerSubmenu()
			if singleplayerMenu then
				local campaignMenu = singleplayerMenu.GetSubmenuByName("campaign")
				if campaignMenu then
					campaignMenu.SetTabHighlighted("codex", true)
				end
			end
		end
	end

	local unlockRewards = {
		{rewards.units, WG.CampaignData.GetUnitInfo, WG.CampaignData.GetUnitIsUnlocked},
		{rewards.modules, WG.CampaignData.GetModuleInfo, WG.CampaignData.GetModuleIsUnlocked},
		{rewards.abilities, WG.CampaignData.GetAbilityInfo, WG.CampaignData.GetAbilityIsUnlocked}
	}

	if MakeRewardList(parent, bottom, "Unlocks", unlockRewards, cullUnlocked) then
		bottom = bottom + 98
	end

	bottom = MakeBonusObjectiveLine(parent, bottom, planetData, bonusObjectiveSuccess, difficulty)

	return bottom
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Zooming

local windowX, windowY, windowWidth, windowHeight
local function RepositionBackgroundAndPlanets(newX, newY, newWidth, newHeight)
	windowX = newX or windowX
	windowY = newY or windowY
	windowWidth = newWidth or windowWidth
	windowHeight = newHeight or windowHeight

	planetHandler.UpdateVisiblePlanetBounds()

	local tX, tY, tScale = planetHandler.GetZoomTransformValues()
	local transformedImageBounds = {
		x = IMAGE_BOUNDS.x + tX*IMAGE_BOUNDS.width,
		y = IMAGE_BOUNDS.y + tY*IMAGE_BOUNDS.height,
		width = IMAGE_BOUNDS.width/tScale,
		height = IMAGE_BOUNDS.height/tScale,
	}

	local background = WG.Chobby.interfaceRoot.GetBackgroundHolder()
	background:SetBoundOverride(transformedImageBounds)

	local x, y, width, height = background:ResizeAspectWindow(windowX, windowY, windowWidth, windowHeight)
	planetHandler.UpdatePosition(x, y, width, height)
	UpdateEdgeList()
end

local function DelayedViewResize()
	if not planetHandler then
		return
	end
	local window = planetHandler.GetParent()
	if not (window and window.parent) then
		return
	end
	local x, y = window:LocalToScreen(0, 0)
	RepositionBackgroundAndPlanets(x, y, window.xSize, window.ySize)
	if selectedPlanet then
		selectedPlanet.SizeUpdate()
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Planet capturing

local function MakeWinPopup(planetData, bonusObjectiveSuccess, difficulty)
	local victoryWindow = Window:New {
		caption = "",
		name = "victoryWindow",
		parent = WG.Chobby.lobbyInterfaceHolder,
		width = 520,
		height = 560,
		resizable = false,
		draggable = false,
		classname = "main_window",
	}

	local childWidth = victoryWindow.width - victoryWindow.padding[1] - victoryWindow.padding[3]

	Label:New {
		x = 0,
		y = 6,
		width = childWidth,
		height = 30,
		align = "center",
		caption = "Victory on " .. planetData.name .. "!",
		font = WG.Chobby.Configuration:GetFont(4),
		parent = victoryWindow
	}

	local experienceHolder = Control:New {
		x = 20,
		y = 58,
		right = 20,
		height = 100,
		padding = {0, 0, 0, 0},
		parent = victoryWindow,
	}

	local experienceDisplay = WG.CommanderHandler.GetExperienceDisplay(experienceHolder, 38, true)

	local rewardsHeight = MakeRewardsPanel(victoryWindow, 82, planetData, true, true, bonusObjectiveSuccess, difficulty)

	victoryWindow:SetPos(nil, nil, nil, 200 + rewardsHeight)

	local openCommanderWindowOnContinue = false
	local function CloseFunc()
		victoryWindow:Dispose()
		if openCommanderWindowOnContinue then
			local singleplayerMenu = WG.Chobby.interfaceRoot.GetSingleplayerSubmenu()
			if singleplayerMenu then
				local campaignMenu = singleplayerMenu.GetSubmenuByName("campaign")
				if campaignMenu then
					campaignMenu.OpenTabByName("commander")
				end
			end
		end
	end

	local buttonClose = Button:New {
		x = (childWidth - 136)/2,
		width = 136,
		bottom = 1,
		height = 70,
		caption = i18n("continue"),
		font = WG.Chobby.Configuration:GetFont(3),
		parent = victoryWindow,
		classname = "action_button",
		OnClick = {
			function()
				CloseFunc()
			end
		},
	}

	if planetData.infoDisplay.feedbackLink then
		MakeFeedbackButton(victoryWindow, planetData.infoDisplay.feedbackLink, nil, nil, 2, 1)
	end

	local popupHolder = WG.Chobby.PriorityPopup(victoryWindow, CloseFunc, CloseFunc)

	local externalFunctions = {}

	function externalFunctions.UpdateExperience(oldExperience, oldLevel, newExperience, newLevel, gainedBonusExperience)
		experienceDisplay.AddFancyExperience(newExperience - oldExperience, gainedBonusExperience)
		if (oldExperience == 100 and newExperience > 100) or (oldLevel ~= newLevel) then
			-- 100 is a crazy hack to open the commander loadout screen on the first completion of the second mission.
			if not openCommanderWindowOnContinue then
				local singleplayerMenu = WG.Chobby.interfaceRoot.GetSingleplayerSubmenu()
				if singleplayerMenu then
					local campaignMenu = singleplayerMenu.GetSubmenuByName("campaign")
					if campaignMenu then
						campaignMenu.SetTabHighlighted("commander", true)
					end
				end
			end
			openCommanderWindowOnContinue = true
		end
	end

	function externalFunctions.CloseWinPopup(cancelCommPopup)
		if cancelCommPopup and openCommanderWindowOnContinue then
			openCommanderWindowOnContinue = false
		end
		CloseFunc()
	end

	return externalFunctions
end

local function MakeRandomBonusVictoryList(winChance, length)
	local list = {}
	for i = 1, length do
		list[i] = (math.random() < winChance)
	end
	return list
end

local function MakeBonusObjectivesList(bonusObjectivesString)
	if not bonusObjectivesString then
		return false
	end
	local list = {}
	local length = string.len(bonusObjectivesString)
	for i = 1, length do
		list[i] = (string.sub(bonusObjectivesString, i, i) == "1")
	end
	return list
end

local function ProcessPlanetVictory(planetID, battleFrames, bonusObjectives, bonusObjectiveString, difficulty)
	if not planetID then
		Spring.Echo("ProcessPlanetVictory error")
		return
	end

	if selectedPlanet then
		selectedPlanet.Close()
		selectedPlanet = nil
	end
	-- It is important to popup before capturing the planet to filter out the
	-- already unlocked rewards.
	currentWinPopup = MakeWinPopup(planetConfig[planetID], bonusObjectives, difficulty)
	WG.CampaignData.AddPlayTime(battleFrames)
	WG.CampaignData.CapturePlanet(planetID, bonusObjectives, difficulty)

	WG.Analytics.SendIndexedRepeatEvent("campaign:planet_" .. planetID .. ":difficulty_" .. difficulty .. ":win", math.floor(battleFrames/30), ":bonus_" .. (bonusObjectiveString or ""))
	WG.Analytics.SendOnetimeEvent("campaign:planets_owned_" .. WG.CampaignData.GetCapturedPlanetCount(), math.floor(WG.CampaignData.GetPlayTime()/30))
end

local function ProcessPlanetDefeat(planetID, battleFrames)
	if selectedPlanet then
		selectedPlanet.Close()
		selectedPlanet = nil
	end
	WG.Chobby.InformationPopup("Battle for " .. planetConfig[planetID].name .. " lost.", {caption = i18n("continue")})
	WG.CampaignData.AddPlayTime(battleFrames, true)

	WG.Analytics.SendIndexedRepeatEvent("campaign:planet_" .. planetID .. ":difficulty_" .. WG.CampaignData.GetDifficultySetting() .. ":lose", math.floor(battleFrames/30), ":defeat")
end

local function ProcessPlanetResign(planetID, battleFrames)
	WG.CampaignData.AddPlayTime(battleFrames, true)
	WG.Analytics.SendIndexedRepeatEvent("campaign:planet_" .. planetID .. ":difficulty_" .. WG.CampaignData.GetDifficultySetting() .. ":lose", math.floor(battleFrames/30), ":resign")
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- TODO: use shader animation to ease info panel in

local function SelectPlanet(popupOverlay, planetHandler, planetID, planetData, startable)
	local Configuration = WG.Chobby.Configuration

	WG.Chobby.interfaceRoot.GetRightPanelHandler().CloseTabs()
	WG.Chobby.interfaceRoot.GetMainWindowHandler().CloseTabs()

	local starmapInfoPanel = Window:New{
		classname = "main_window",
		parent = planetHandler,
		x = 32,
		y = 32,
		right = 32,
		bottom = 32,
		resizable = false,
		draggable = false,
		padding = {12, 7, 12, 7},
	}

	local planetName = string.upper(planetData.name)
	if not LIVE_TESTING then
		planetName = planetName .. " - " .. planetID
	end

	local nameLabel = Label:New{
		x = 8,
		y = 8,
		caption = planetName,
		font = Configuration:GetFont(4),
	}

	local fluffLabels = {
		Label:New{caption = "Primary", font = Configuration:GetFont(3)},
		Label:New{caption = planetData.infoDisplay.primary .. " (" .. planetData.infoDisplay.primaryType .. ") ", font = Configuration:GetFont(3)},
		Label:New{caption = "Type", font = Configuration:GetFont(3)},
		Label:New{caption = planetData.infoDisplay.terrainType or "<UNKNOWN>", font = Configuration:GetFont(3)},
	}
	fluffGrid = Grid:New{
		x = 8,
		y = 60,
		right = 4,
		bottom = "76%",
		columns = 2,
		rows = 2,
		children = fluffLabels,
	}

	local planetDesc = TextBox:New {
		x = 20,
		y = "25%",
		right = 4,
		bottom = "25%",
		padding = {0, 0, 10, 0},
		text = ((startable or Configuration.debugMode) and planetData.infoDisplay.text) or "This planet will need to be approached for further study.",
		font = Configuration:GetFont(3),
	}


	local subPanel = Panel:New{
		parent = starmapInfoPanel,
		x = "3%",
		y = "4%",
		right = "60%",
		bottom = "4%",
		children = {
			nameLabel,
			fluffGrid,
			planetDesc
		}
	}

	MakeRewardsPanel(subPanel, 16, planetData)

	local buttonHolder = Control:New{
		x = "50%",
		y = "4%",
		right = "3%",
		bottom = "4%",
		padding = {0,0,0,0},
		parent = starmapInfoPanel,
	}


	if startable then
		if planetData.infoDisplay.feedbackLink then
			MakeFeedbackButton(buttonHolder, planetData.infoDisplay.feedbackLink, nil, 0, 85, nil)
		end

		difficultyWindow = difficultyWindow or InitializeDifficultySetting()
		buttonHolder:AddChild(difficultyWindow)

		local startButton = Button:New{
			right = 0,
			bottom = 0,
			width = 160,
			height = 58,
			classname = "action_button",
			parent = buttonHolder,
			caption = i18n("start"),
			font = Configuration:GetFont(4),
			OnClick = {
				function(self)
					WG.PlanetBattleHandler.StartBattle(planetID, planetData)
				end
			}
		}
		local btnInviteFriends
		if Configuration.canAuthenticateWithSteam then
			btnInviteFriends = Button:New {
				right = 0,
				bottom = 62,
				width = 160,
				height = 35,
				padding = {0, 0, 0, 0},
				font = Configuration:GetFont(2),
				caption = i18n("invite_friends") .. "   ",
				classname = "option_button",
				OnClick = {
					function()
						WG.SteamHandler.OpenFriendList()
					end
				},
				parent = buttonHolder,
			}
			local imPartyLink = Image:New {
				right = 6,
				y = 4,
				width = 24,
				height = 24,
				keepAspect = true,
				file = PARTY_LINK,
				parent = btnInviteFriends,
			}
		end

		if planetData.tutorialSkip then
			local startButton = Button:New{
				right = 140,
				bottom = 0,
				width = 220,
				height = 65,
				classname = "option_button",
				parent = buttonHolder,
				caption = i18n("skip_tutorial"),
				tooltip = "Skip quick tutorial. Only recommended for Zero-K veterans or players who have completed Tutorials 1 and 2.",
				font = Configuration:GetFont(4),
				OnClick = {
					function(self)
						local function SkipFunc()
							ProcessPlanetVictory(planetID, 0, {}, nil, WG.CampaignData.GetDifficultySetting())
						end
						WG.Chobby.ConfirmationPopup(SkipFunc, "Are you sure you want to skip the quick tutorial? Remember to come back later if you need help.", nil, 315, 220)
					end
				}
			}
		end

		if (not LIVE_TESTING) and (Configuration.debugAutoWin or Configuration.debugMode) then
			local autoWinButton = Button:New{
				right = 0,
				bottom = 100,
				width = 150,
				height = 65,
				classname = "action_button",
				parent = buttonHolder,
				caption = "Auto Win",
				font = Configuration:GetFont(4),
				OnClick = {
					function(self)
						ProcessPlanetVictory(planetID, 352, MakeRandomBonusVictoryList(0.75, 8), nil, WG.CampaignData.GetDifficultySetting())
					end
				}
			}
			local autoLostButton = Button:New{
				right = 155,
				bottom = 100,
				width = 175,
				height = 65,
				classname = "action_button",
				parent = buttonHolder,
				caption = "Auto Lose",
				font = Configuration:GetFont(4),
				OnClick = {
					function(self)
						ProcessPlanetDefeat(planetID, 351)
					end
				}
			}
		end
	end

	-- close button
	local function CloseFunc()
		if starmapInfoPanel then
			starmapInfoPanel:Dispose()
			starmapInfoPanel = nil
			return true
		end
		return false
	end

	Button:New{
		y = 0,
		right = 0,
		width = 80,
		height = 45,
		classname = "negative_button",
		caption = i18n("close"),
		font = Configuration:GetFont(3),
		OnClick = {
			CloseFunc
		},
		parent = buttonHolder,
	}


	WG.Chobby.interfaceRoot.SetBackgroundCloseListener(CloseFunc)

	-- planet image
	local planetImage = Image:New{
		parent = starmapInfoPanel,
		x = "50%",
		right = "2%",
		y = (starmapInfoPanel.height - planetData.infoDisplay.size) / 2,
		height = planetData.infoDisplay.size,
		keepAspect = true,
		file = planetData.infoDisplay.image,
	}

	-- background
	local bg = Image:New{
	name = "bgbgbgbgbg",
		parent = starmapInfoPanel,
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		file = planetData.infoDisplay.backgroundImage,
		keepAspect = false,
	}
	bg:Invalidate()

	starmapInfoPanel:SetLayer(1)

	starmapInfoPanel.OnResize = starmapInfoPanel.OnResize or {}
	starmapInfoPanel.OnResize[#starmapInfoPanel.OnResize + 1] = function(obj, xSize, ySize)
		planetImage:SetPos(nil, math.floor((ySize - planetData.infoDisplay.size)/2))
	end

	local function SizeUpdate()
		local fluffFont = Configuration:GetFont(((planetHandler.height < 720) and 2) or 3)
		local descFont = Configuration:GetFont(((planetHandler.height < 720) and 1) or 2)

		planetDesc.font.size = descFont.size
		planetDesc:Invalidate()
		if planetHandler.height < 560 then
			planetDesc._relativeBounds.top = 60
			fluffGrid:SetVisibility(false)

		elseif planetHandler.height < 820 then
			planetDesc._relativeBounds.top = "26%"
			fluffGrid:SetVisibility(true)

		else
			planetDesc._relativeBounds.top = "25%"
			fluffGrid:SetVisibility(true)
		end
		planetDesc:UpdateClientArea(false)

		if planetHandler.height > 800 then
			subPanel._relativeBounds.right = "50%"
			subPanel._relativeBounds.bottom = "4%"
			planetImage._relativeBounds.left = "50%"
		elseif planetHandler.height > 400 then
			subPanel._relativeBounds.right = "40%"
			subPanel._relativeBounds.bottom = "2%"
			planetImage._relativeBounds.left = "60%"
		else
			subPanel._relativeBounds.right = "30%"
			subPanel._relativeBounds.bottom = 0
			planetImage._relativeBounds.left = "70%"
		end
		subPanel:UpdateClientArea(false)

		for i = 1, 4 do
			fluffLabels[i].font.size = fluffFont.size
			fluffLabels[i]:Invalidate()
		end
		fluffGrid:Invalidate()
	end
	SizeUpdate()

	local externalFunctions = {
		Close = CloseFunc,
		SizeUpdate = SizeUpdate,
	}

	return externalFunctions
end

local function AddDebugUnlocks(parent, unlockList, unlockInfo, offset, columns, unlockSize)
	if unlockList then
		for i = 1, #unlockList do
			local info, imageFile, imageOverlay, count = unlockInfo(unlockList[i])
			local image = Image:New{
				x = (offset%columns) * unlockSize,
				y = math.floor(offset/columns) * unlockSize,
				width = unlockSize - 1,
				height = unlockSize - 1,
				keepAspect = true,
				file = imageOverlay or imageFile,
				file2 = imageOverlay and imageFile,
				parent = parent,
			}
			offset = offset + 1
		end
	end
	return offset
end

local filter = {
	{"cloak", "cloakraid"},
	{"shield", "shieldraid"},
	{"spider", "spideremp"},
	{"jump", "jumpraid"},
	{"amph", "amphraid"},
	{"hover", "hoverraid"},
	{"veh", "vehraid"},
	{"tank", "tankassault"},
	{"plane", "planefighter"},
	{"bomber", "planefighter"},
	{"gunship", "gunshipraid"},
	{"strider", "striderdante"},
	{"ship", "shipriot"},
	{"sub", "shipriot"},
}

local function ProcessAiUnlockDebugView(debugHolder, map, aiConfig, unlockInfo, offset)
	if aiConfig.allyTeam == 0 then
		return offset, map
	end
	local unlocks = aiConfig.unlocks
	if not unlocks then
		return offset, map
	end

	local unlockList = {}
	for i = 1, #unlocks do
		local name = unlocks[i]
		for j = 1, #filter do
			if string.find(name, filter[j][1]) then
				local item = filter[j][2]
				if not map[item] then
					unlockList[#unlockList + 1] = item
					map[item] = true
				end
				break
			end
		end
	end

	offset = AddDebugUnlocks(debugHolder, unlockList, unlockInfo, offset, DEBUG_UNLOCK_COLUMNS, DEBUG_UNLOCK_SIZE)
	return offset, map
end

local function EnablePlanetClick()
	planetClickEnabled = true
end

local function GetPlanet(popupOverlay, planetListHolder, planetID, planetData, adjacency)
	local Configuration = WG.Chobby.Configuration

	local planetSize = planetData.mapDisplay.size
	local xPos, yPos = planetData.mapDisplay.x, planetData.mapDisplay.y

	local captured = WG.CampaignData.IsPlanetCaptured(planetID)
	local startable
	local visible = false
	local distance = false
	local tipHolder

	local target
	local targetSize = math.ceil(math.floor(planetSize*1.35)/2)*2
	local planetOffset = math.floor((targetSize - planetSize)/2)

	local planetHolder = Control:New{
		x = 0,
		y = 0,
		width = targetSize,
		height = targetSize,
		padding = {0, 0, 0, 0},
		parent = planetListHolder,
	}

	local debugHolder
	if (not LIVE_TESTING) and Configuration.debugMode then
		if Configuration.showPlanetUnlocks then
			debugHolder = Control:New{
				x = 0,
				y = 0,
				width = targetSize*3,
				height = targetSize,
				padding = {1, 1, 1, 1},
				parent = planetListHolder,
			}

			local rewards = planetData.completionReward
			local offset = 0
			offset = AddDebugUnlocks(debugHolder, rewards.units, WG.CampaignData.GetUnitInfo, offset, DEBUG_UNLOCK_COLUMNS, DEBUG_UNLOCK_SIZE)
			offset = AddDebugUnlocks(debugHolder, rewards.modules, WG.CampaignData.GetModuleInfo, offset, DEBUG_UNLOCK_COLUMNS, DEBUG_UNLOCK_SIZE)
			offset = AddDebugUnlocks(debugHolder, rewards.abilities, WG.CampaignData.GetAbilityInfo, offset, DEBUG_UNLOCK_COLUMNS, DEBUG_UNLOCK_SIZE)
		elseif Configuration.showPlanetEnemyUnits then
			debugHolder = Control:New{
				x = 0,
				y = 0,
				width = targetSize*3,
				height = targetSize,
				padding = {1, 1, 1, 1},
				parent = planetListHolder,
			}

			local aiConfig = planetData.gameConfig.aiConfig
			local offset = 0
			local map = {}
			for i = 1, #aiConfig do
				offset, map = ProcessAiUnlockDebugView(debugHolder, map, aiConfig[i],  WG.CampaignData.GetUnitInfo, offset)
			end
		end
	end

	local function OpenPlanetScreen()
		if selectedPlanet then
			selectedPlanet.Close()
			selectedPlanet = nil
		end
		selectedPlanet = SelectPlanet(popupOverlay, planetListHolder, planetID, planetData, startable)
	end

	local button = Button:New{
		x = planetOffset,
		y = planetOffset,
		width = planetSize,
		height = planetSize,
		classname = "button_planet",
		caption = "",
		OnClick = {
			function(self, x, y, mouseButton)
				if (not LIVE_TESTING) and Configuration.editCampaign and Configuration.debugMode then
					if debugPlanetSelected and planetID ~= debugPlanetSelected then
						local adjacent = planetAdjacency[debugPlanetSelected][planetID]
						if adjacent then
							for i = 1, #planetEdgeList do
								local edge = planetEdgeList[i]
								if (edge[1] == planetID and edge[2] == debugPlanetSelected) or (edge[2] == planetID and edge[1] == debugPlanetSelected) then
									table.remove(planetEdgeList, i)
									break
								end
							end
						else
							planetEdgeList[#planetEdgeList + 1] = {planetID, debugPlanetSelected}
						end

						planetAdjacency[debugPlanetSelected][planetID] = not adjacent
						planetAdjacency[planetID][debugPlanetSelected] = not adjacent
						UpdateEdgeList()
						debugPlanetSelectedName = nil
						debugPlanetSelected = nil
						return
					end
					debugPlanetSelectedName = self.name
					debugPlanetSelected = planetID
					return
				end

				OpenPlanetScreen()
			end
		},
		parent = planetHolder,
	}
	button:SetVisibility(false)

	local image = Image:New {
		x = 3,
		y = 3,
		right = 3,
		bottom = 3,
		file = planetData.mapDisplay.image,
		keepAspect = true,
		parent = button,
	}

	if (not LIVE_TESTING) and Configuration.debugMode then
		local number = Label:New {
			x = 3,
			y = 3,
			right = 6,
			bottom = 6,
			align = "center",
			valign = "center",
			caption = planetID,
			font = Configuration:GetFont(3),
			parent = image,
		}
	end

	local function UpdateSize(sizeScale)
		planetSize = planetData.mapDisplay.size*sizeScale
		targetSize = math.ceil(math.floor(planetSize*1.35)/2)*2
		planetOffset = math.floor((targetSize - planetSize)/2)

		button:SetPos(planetOffset, planetOffset, planetSize, planetSize)
	end

	local externalFunctions = {}
	externalFunctions.OpenPlanetScreen = OpenPlanetScreen

	function externalFunctions.StartPlanetMission()
		if not startable then
			return
		end
		WG.PlanetBattleHandler.StartBattle(planetID, planetData)
	end

	function externalFunctions.UpdatePosition(xSize, ySize)
		local tX, tY, tSize = planetHandler.GetZoomTransform(xPos, yPos, math.max(1, xSize/1050))
		UpdateSize(tSize)
		local x = math.max(0, math.min(xSize - targetSize, tX*xSize - targetSize/2))
		local y = math.max(0, math.min(ySize - targetSize, tY*ySize - targetSize/2))
		planetHolder:SetPos(x, y, targetSize, targetSize)

		if tipHolder then
			tipHolder:SetPos(x + targetSize, y - 5 + (targetSize - planetData.mapDisplay.hintSize[2])/2)
		end

		if debugHolder then
			debugHolder:SetPos(x, y + planetSize, DEBUG_UNLOCK_COLUMNS*DEBUG_UNLOCK_SIZE + 2, 3*DEBUG_UNLOCK_SIZE + 2)
		end
	end

	function externalFunctions.SetPosition(newX, newY)
		xPos, yPos = newX, newY
		planetConfig[planetID].mapDisplay.x, planetConfig[planetID].mapDisplay.y = newX, newY
		UpdateEdgeList()
	end

	function externalFunctions.UpdateInformation()
		local bonusCount, maxBonus = 0, 0
		local objectiveConfig = planetData.gameConfig.bonusObjectiveConfig
		if objectiveConfig then
			maxBonus = #objectiveConfig
			for i = 1, #objectiveConfig do
				if WG.CampaignData.GetBonusObjectiveComplete(planetID, i) then
					bonusCount = bonusCount + 1
				end
			end
		end
		local conquerString
		local cap, difficulty = WG.CampaignData.IsPlanetCaptured(planetID)
		if cap then
			conquerString = "\nConquered on " .. difficultyNameMap[difficulty or 0]
		end
		button.tooltip = "Planet " .. planetData.name .. (conquerString or "") .. ((maxBonus > 0 and "\nBonus objectives: " .. bonusCount .. " / " .. maxBonus) or "")
	end
	externalFunctions.UpdateInformation()

	function externalFunctions.UpdateStartable(disableStartable)
		captured = WG.CampaignData.IsPlanetCaptured(planetID)
		startable = captured or planetData.startingPlanet
		if not startable then
			for i = 1, #adjacency do
				if adjacency[i] then
					if ((not PLANET_WHITELIST) or PLANET_WHITELIST[i]) and planetList[i].GetCaptured() then
						startable = true
						break
					end
				end
			end
		end

		if captured then
			distance = 0
		elseif startable then
			distance = 1
		else
			distance = false
		end

		if disableStartable then
			startable = false
		end

		if startable then
			image.color = PLANET_START_COLOR
		else
			image.color = PLANET_NO_START_COLOR
		end
		image:Invalidate()

		local targetable = startable and not captured
		if target then
			if not targetable then
				target:Dispose()
				target = nil
			end
		elseif targetable then
			target = Image:New{
				x = 0,
				y = 0,
				right = 0,
				bottom = 0,
				file = TARGET_IMAGE,
				keepAspect = true,
				parent = planetHolder,
			}
			target:SendToBack()
		end

		if tipHolder then
			if not targetable then
				tipHolder:Dispose()
				tipHolder = nil
			end
		elseif targetable and planetData.mapDisplay.hintText then
			tipHolder = Window:New{
				classname = "main_window_small",
				x = planetHolder.x + planetHolder.width,
				y = planetHolder.y - 5 + (planetHolder.height - planetData.mapDisplay.hintSize[2])/2,
				width = planetData.mapDisplay.hintSize[1],
				height = planetData.mapDisplay.hintSize[2],
				resizable = false,
				draggable = false,
				parent = planetListHolder,
			}
			TextBox:New {
				x = 12,
				right = 12,
				y = 8,
				bottom = 8,
				font = Configuration:GetFont(4),
				text = planetData.mapDisplay.hintText,
				parent = tipHolder,
			}
		end

		externalFunctions.UpdateInformation()
	end

	-- Only call this after calling UpdateStartable for all planets. Call at least (VISIBILITY_DISTANCE - 1) times.
	function externalFunctions.UpdateDistance()
		if distance and (distance <= 1) then
			return
		end
		for i = 1, #adjacency do
			if adjacency[i] then
				if ((not PLANET_WHITELIST) or PLANET_WHITELIST[i]) and planetList[i].GetDistance() then
					local newDist = planetList[i].GetDistance() + 1
					if distance then
						if distance > newDist then
							distance = newDist
						end
					else
						distance = newDist
					end
				end
			end
		end
	end
	function externalFunctions.UpdateVisible()
		visible = (distance and distance <= VISIBILITY_DISTANCE) or ((not LIVE_TESTING) and Configuration.debugMode)
		button:SetVisibility(visible)
	end

	function externalFunctions.DownloadMapIfClose()
		if startable or captured then
			WG.DownloadHandler.MaybeDownloadArchive(planetData.gameConfig.mapName, "map", 2)
			return
		end
		for i = 1, #adjacency do
			if adjacency[i] then
				if ((not PLANET_WHITELIST) or PLANET_WHITELIST[i]) and planetList[i].GetCapturedOrStarable_Unsafe() then
					WG.DownloadHandler.MaybeDownloadArchive(planetData.gameConfig.mapName, "map", 1)
					return
				end
			end
		end
	end

	function externalFunctions.GetCaptured()
		return WG.CampaignData.IsPlanetCaptured(planetID)
	end

	function externalFunctions.GetCapturedOrStarable_Unsafe()
		-- Unsafe because an update may be required before the return value is valid
		return startable or captured
	end

	function externalFunctions.GetVisible()
		return visible
	end

	function externalFunctions.GetVisibleEdge() -- Whether an edge to this planet is visible.
		return (distance and distance <= (VISIBILITY_DISTANCE + 1)) or ((not LIVE_TESTING) and Configuration.debugMode)
	end

	function externalFunctions.GetDistance()
		return distance
	end

	return externalFunctions
end

local function UpdateStartableAndVisible()
	for i = 1, PLANET_COUNT do
		if (not PLANET_WHITELIST) or PLANET_WHITELIST[i] then
			planetList[i].UpdateStartable(not WG.CampaignData.GetCampaignInitializationComplete())
		end
	end
	if VISIBILITY_DISTANCE > 2 then
		for j = 1, VISIBILITY_DISTANCE - 1 do
			for i = 1, PLANET_COUNT do
				if (not PLANET_WHITELIST) or PLANET_WHITELIST[i] then
					planetList[i].UpdateDistance()
				end
			end
		end
	end
	for i = 1, PLANET_COUNT do
		if (not PLANET_WHITELIST) or PLANET_WHITELIST[i] then
			planetList[i].UpdateDistance()
			planetList[i].UpdateVisible()
		end
	end
	RepositionBackgroundAndPlanets()
end

local function DownloadNearbyMaps()
	for i = 1, PLANET_COUNT do
		if (not PLANET_WHITELIST) or PLANET_WHITELIST[i] then
			planetList[i].DownloadMapIfClose()
		end
	end
end

local function UpdateGalaxy()
	UpdateStartableAndVisible()
	UpdateEdgeList()
	DownloadNearbyMaps()
end

local function InitializePlanetHandler(parent, newLiveTestingMode, newPlanetWhitelist, feedbackLink)
	LIVE_TESTING = newLiveTestingMode
	PLANET_WHITELIST = newPlanetWhitelist

	local Configuration = WG.Chobby.Configuration

	local debugMode = Configuration.debugMode and (not LIVE_TESTING)

	if feedbackLink then
		MakeFeedbackWindow(parent, feedbackLink)
	end

	local window = ((debugMode and Panel) or Control):New {
		name = "planetsHolder",
		padding = {0,0,0,0},
		parent = parent,
	}
	window:BringToFront()

	local planetWindow = Control:New {
		name = "planetWindow",
		x = 0,
		y = 0,
		width = "100%",
		height = "100%",
		padding = {0,0,0,0},
		hitTestAllowEmpty = true,
		parent = window,
	}

	local popupOverlay = Control:New {
		name = "popupOverlay",
		x = 0,
		y = 0,
		width = "100%",
		height = "100%",
		padding = {0,0,0,0},
		parent = window,
	}
	popupOverlay:BringToFront()

	if debugMode then
		planetWindow.OnMouseDown = planetWindow.OnMouseDown or {}
		planetWindow.OnMouseDown[#planetWindow.OnMouseDown + 1] = function(self, x, y, mouseButton)
			if Configuration.editCampaign and debugPlanetSelected then
				if mouseButton == 3 then
					debugPlanetSelected = nil
					debugPlanetSelectedName = nil
					EchoPlanetPositionAndEdges()
					return true
				end
				local hovered = WG.Chili.Screen0.hoveredControl
				if hovered and (hovered.name == "planetWindow" or hovered.name == debugPlanetSelectedName) then
					planetList[debugPlanetSelected].SetPosition(x/planetWindow.width, y/planetWindow.height)
					planetList[debugPlanetSelected].UpdatePosition(planetWindow.width, planetWindow.height)
				end
			end
			return false
		end
	end

	local planetData = Configuration.campaignConfig.planetDefs
	planetConfig, planetAdjacency, planetEdgeList = planetData.planets, planetData.planetAdjacency, planetData.planetEdgeList

	local transX, transY, transScale = 0, 0, 1

	planetList = {}
	PLANET_COUNT = #planetConfig
	for i = 1, PLANET_COUNT do
		if (not PLANET_WHITELIST) or PLANET_WHITELIST[i] then
			planetList[i] = GetPlanet(popupOverlay, planetWindow, i, planetConfig[i], planetAdjacency[i])
		end
	end

	local graph = Chili.Control:New{
		x       = 0,
		y       = 0,
		height  = "100%",
		width   = "100%",
		padding = {0,0,0,0},
		drawcontrolv2 = true,
		DrawControl = function (obj)
			local x = obj.x
			local y = obj.y
			local w = obj.width
			local h = obj.height

			local _,_,scale = planetHandler.GetZoomTransformValues()

			gl.PushMatrix()
			gl.Translate(x, y, 0)
			gl.Scale(w, h, 1)
			gl.LineWidth(3 * scale)
			gl.CallList(edgeDrawList)
			gl.PopMatrix()
		end,
		parent = window,
	}

	local function PlanetCaptured(listener, planetID)
		if (not PLANET_WHITELIST) or PLANET_WHITELIST[planetID] then
			planetList[planetID].UpdateStartable(not WG.CampaignData.GetCampaignInitializationComplete())
			UpdateGalaxy()
		end
	end
	WG.CampaignData.AddListener("PlanetCaptured", PlanetCaptured)

	local function PlanetUpdate(listener, planetID)
		if (not PLANET_WHITELIST) or PLANET_WHITELIST[planetID] then
			planetList[planetID].UpdateInformation()
		end
	end
	WG.CampaignData.AddListener("PlanetUpdate", PlanetUpdate)

	local externalFunctions = {}

	function externalFunctions.UpdatePosition(x, y, width, height)
		window:SetPos(x and math.floor(x + 0.5), y and math.floor(y + 0.5), width, height)
		if x then
			for i = 1, PLANET_COUNT do
				if (not PLANET_WHITELIST) or PLANET_WHITELIST[i] then
					planetList[i].UpdatePosition(width, height)
				end
			end
		end
	end

	function externalFunctions.GetZoomTransform(x, y, size)
		x = (x - transX)*transScale
		y = (y - transY)*transScale
		return x, y, (size or 1)*transScale
	end

	function externalFunctions.GetZoomTransformValues()
		return transX, transY, transScale
	end

	function externalFunctions.UpdateVisiblePlanetBounds()
		local left, top, right, bottom
		local padding = 0.05
		for i = 1, PLANET_COUNT do
			if ((not PLANET_WHITELIST) or PLANET_WHITELIST[i]) and planetList[i].GetVisibleEdge() then
				local xPos, yPos = planetConfig[i].mapDisplay.x, planetConfig[i].mapDisplay.y
				if planetList[i].GetVisible() then
					left = math.min(left or (xPos - padding), (xPos - padding))
					top = math.min(top or (yPos - padding), (yPos - padding))
					right = math.max(right or (xPos + padding), (xPos + padding))
					bottom = math.max(bottom or (yPos + padding), (yPos + padding))
				else
					left = math.min(left or xPos, xPos)
					top = math.min(top or yPos, yPos)
					right = math.max(right or xPos, xPos)
					bottom = math.max(bottom or yPos, yPos)
				end
			end
		end

		if not left then
			transX, transY, transScale = 0, 0, 1
			return
		end

		left = math.max(left, TRANSFORM_BOUNDS.left)
		top = math.max(top, TRANSFORM_BOUNDS.top)
		right = math.min(right, TRANSFORM_BOUNDS.right)
		bottom = math.min(bottom, TRANSFORM_BOUNDS.bottom)

		-- Make square
		local width = right - left
		local height = bottom - top
		if width > height then
			local mid = top + height/2
			top = mid - width/2
			bottom = mid + width/2

			if top < TRANSFORM_BOUNDS.top then
				bottom = bottom + (TRANSFORM_BOUNDS.top - top)
				top = TRANSFORM_BOUNDS.top
			elseif bottom > TRANSFORM_BOUNDS.bottom then
				top = top + (TRANSFORM_BOUNDS.bottom - bottom)
				bottom = TRANSFORM_BOUNDS.bottom
			end
		else
			local mid = left + width/2
			left = mid - height/2
			right = mid + height/2

			if left < TRANSFORM_BOUNDS.left then
				right = right + (TRANSFORM_BOUNDS.left - left)
				left = TRANSFORM_BOUNDS.left
			elseif right > TRANSFORM_BOUNDS.right then
				left = left + (TRANSFORM_BOUNDS.right - right)
				right = TRANSFORM_BOUNDS.right
			end
		end

		transX, transY, transScale = left, top, 1/(right - left)
	end

	function externalFunctions.SendEdgesToBack()
		if graph then
			graph:SendToBack()
		end
	end

	function externalFunctions.GetParent()
		return parent
	end

	-- Make sure everything loads in the right positions
	DelayedViewResize()
	WG.Delay(DelayedViewResize, 0.1)
	WG.Delay(DelayedViewResize, 0.8)
	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Ingame interface

local BATTLE_WON_STRING = "Campaign_PlanetBattleWon"
local BATTLE_LOST_STRING = "Campaign_PlanetBattleLost"
local BATTLE_RESIGN_STRING = "Campaign_PlanetBattleResign"
local LOAD_CAMPAIGN_STRING = "Campaign_LoadCampaign"

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:RecvLuaMsg(msg)
	if not msg then
		Spring.Echo("LUA_ERR", "Bad campaign message", msg)
		return
	end
	if string.find(msg, LOAD_CAMPAIGN_STRING) then
		local encoded = string.sub(msg, string.len(LOAD_CAMPAIGN_STRING) + 1)
		local saveData = Spring.Utilities.CustomKeyToUsefulTable(encoded)
		WG.CampaignData.ApplyCampaignPartialSaveData(saveData)
		WG.Chobby.interfaceRoot.OpenSingleplayerTabByName("campaign")
	elseif string.find(msg, BATTLE_WON_STRING) then
		Spring.Echo("msg", msg)
		local data = msg:split(" ")
		Spring.Utilities.TableEcho(data, "data")
		local planetID = tonumber(data[2])
		local battleFrames = tonumber(data[3])
		local bonusObjectives = data[4]
		local difficulty = tonumber(data[5]) or 0
		if planetID and planetConfig and planetConfig[planetID] then
			ProcessPlanetVictory(planetID, battleFrames, MakeBonusObjectivesList(bonusObjectives), bonusObjectives, difficulty)
		end
	elseif string.find(msg, BATTLE_LOST_STRING) then
		Spring.Echo("msg", msg)
		local data = msg:split(" ")
		Spring.Utilities.TableEcho(data, "data")
		local planetID = tonumber(data[2])
		local battleFrames = tonumber(data[3])
		if planetID and planetConfig and planetConfig[planetID] then
			ProcessPlanetDefeat(planetID, battleFrames)
		end
	elseif string.find(msg, BATTLE_RESIGN_STRING) then
		Spring.Echo("msg", msg)
		local data = msg:split(" ")
		Spring.Utilities.TableEcho(data, "data")
		local planetID = tonumber(data[2])
		local battleFrames = tonumber(data[3])
		if planetID and planetConfig and planetConfig[planetID] then
			ProcessPlanetResign(planetID, battleFrames)
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- External Interface

local externalFunctions = {}

function externalFunctions.GetControl(newLiveTestingMode, newPlanetWhitelist, feedbackLink)
	local window = Control:New {
		name = "campaignHandler",
		x = 0,
		y = 0,
		width = "100%",
		height = "100%",
		padding = {0,0,0,0},
		OnParentPost = {
			function(obj, parent)
				if obj:IsEmpty() then
					difficultyWindow = difficultyWindow or InitializeDifficultySetting()
					planetHandler = InitializePlanetHandler(obj, newLiveTestingMode, newPlanetWhitelist, feedbackLink)
					UpdateGalaxy()
				end

				local background = WG.Chobby.interfaceRoot.GetBackgroundHolder()
				background:SetImageOverride(GALAXY_IMAGE)
				local x, y = obj:LocalToScreen(0, 0)
				RepositionBackgroundAndPlanets(x, y, obj.width, obj.height)

				obj:UpdateClientArea()
				WG.Chobby.interfaceRoot.GetRightPanelHandler().CloseTabs()
				WG.Chobby.interfaceRoot.GetMainWindowHandler().CloseTabs()
				if WG.LibLobby.lobby and WG.LibLobby.lobby:GetMyBattleID() then
					WG.LibLobby.lobby:LeaveBattle()
				end
			end
		},
		OnOrphan = {
			function(obj)
				if not obj.disposed then -- AutoDispose
					local background = WG.Chobby.interfaceRoot.GetBackgroundHolder()
					background:RemoveOverride()
				end
			end
		},
		OnResize = {
			function(obj, xSize, ySize)
				if not obj.parent then
					return
				end
				local x, y = obj:LocalToScreen(0, 0)
				RepositionBackgroundAndPlanets(x, y, xSize, ySize)
			end
		},
	}
	return window
end

function externalFunctions.CloseSelectedPlanet()
	if selectedPlanet then
		selectedPlanet.Close()
		selectedPlanet = nil
		return true
	end
	return false
end

function externalFunctions.OpenPlanetScreen(planetID)
	if planetList and planetList[planetID] then
		planetList[planetID].OpenPlanetScreen()
	end
end

function externalFunctions.StartPlanetMission(planetID)
	if planetList and planetList[planetID] then
		planetList[planetID].StartPlanetMission()
	end
end


--------------------------------------------------------------------------------
-- Callins
--------------------------------------------------------------------------------


function widget:ViewResize(vsx, vsy)
	WG.Delay(DelayedViewResize, 0.1)
	WG.Delay(DelayedViewResize, 0.8)
end

function widget:Initialize()
	CHOBBY_DIR = "LuaMenu/widgets/chobby/"
	VFS.Include("LuaMenu/widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)
	local function CampaignLoaded(listener)
		if planetList and planetHandler then
			UpdateGalaxy()
			WG.Delay(DelayedViewResize, 0.1)
			if selectedPlanet then
				selectedPlanet.Close()
				selectedPlanet = nil
			end
		end
	end
	WG.CampaignData.AddListener("CampaignLoaded", CampaignLoaded)
	WG.CampaignData.AddListener("InitializationComplete", CampaignLoaded)

	local function GainExperience(listener, oldExperience, oldLevel, newExperience, newLevel, gainedBonusExperience)
		if currentWinPopup then
			currentWinPopup.UpdateExperience(oldExperience, oldLevel, newExperience, newLevel, gainedBonusExperience)
		end
	end
	WG.CampaignData.AddListener("GainExperience", GainExperience)

	WG.CampaignHandler = externalFunctions
end

function widget:Shutdown()
	WG.CampaignHandler = nil
end
