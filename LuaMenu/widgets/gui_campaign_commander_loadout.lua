--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Campaign Commander Loadout",
		desc      = "Displays commanders and modules.",
		author    = "GoogleFrog",
		date      = "9 July 2017",
		license   = "GNU LGPL, v2.1 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Local Variables

local TOP_HEIGHT = 200
local HEADING_OFFSET = 36
local BUTTON_SIZE = 50
local COMMANDER_IMAGE_WIDTH = 120
local COMMANDER_IMAGE_HEIGHT = 160

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utilities

local function ModuleIsValid(data, level, slotAllows, oldModuleName, alreadyOwned, moduleLimit)
	if (not slotAllows[data.slotType]) or (data.requireLevel or 0) > level or data.unequipable then
		return false
	end

	-- Check that requirements are met
	if data.requireOneOf then
		local foundRequirement = false
		for j = 1, #data.requireOneOf do
			local reqDefName = data.requireOneOf[j]
			if (alreadyOwned[reqDefName] or 0) - ((oldModuleName == reqDefName) and 1 or 0) > 0 then
				foundRequirement = true
				break
			end
		end
		if not foundRequirement then
			return false
		end
	end

	-- Check that nothing prohibits this module
	if data.prohibitingModules then
		for j = 1, #data.prohibitingModules do
			-- Modules cannot prohibit themselves otherwise this check makes no sense.
			local probihitDefName = data.prohibitingModules[j]
			if (alreadyOwned[probihitDefName] or 0) - ((oldModuleName == probihitDefName) and 1 or 0) > 0 then
				return false
			end
		end

	end

	-- Check that the module limit is not reached
	local moduleName = data.name
	if (data.limit or moduleLimit[moduleName]) and alreadyOwned[moduleName] then
		local limit = data.limit or moduleLimit[moduleName]
		if data.limit and moduleLimit[moduleName] and moduleLimit[moduleName] < data.limit then
			limit = moduleLimit[moduleName]
		end
		local count = (alreadyOwned[moduleName] or 0) - ((oldModuleName == moduleName) and 1 or 0)
		if count >= limit then
			return false
		end
	end
	return true
end

local function GetValidReplacementModuleSlot(moduleName, level, slot)
	local commConfig = WG.Chobby.Configuration.campaignConfig.commConfig
	local chassisDef = commConfig.chassisDef
	local moduleDefs = commConfig.moduleDefs
	local moduleDefNames = commConfig.moduleDefNames

	local _, _, _, commanderLoadout = WG.CampaignData.GetPlayerCommanderInformation()
	local loadoutModuleCounts = WG.CampaignData.GetCommanderModuleCounts()
	local moduleList, moduleLimit = WG.CampaignData.GetModuleListAndLimit()

	level = math.min(level, chassisDef.highestDefinedLevel)
	local slotAllows = chassisDef.levelDefs[level].upgradeSlots[slot].slotAllows

	local validList = {}
	for i = 1, #moduleList do
		local newModuleData = moduleDefNames[moduleList[i]] and moduleDefs[moduleDefNames[moduleList[i]]] -- filters out _LIMIT_ unlock entries.
		if newModuleData and ModuleIsValid(newModuleData, level, slotAllows, moduleName, loadoutModuleCounts, moduleLimit) then
			validList[#validList + 1] = moduleList[i]
		end
	end

	if slotAllows.module then
		validList[#validList + 1] = "nullmodule"
	else
		validList[#validList + 1] = "nullbasicweapon"
	end

	return validList
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Experience display

local function GetProgress(commExperience, levelExperience, nextExperiece)
	if not (commExperience and levelExperience) then
		return 0, "?? / ??"
	end
	if not nextExperiece then
		return 1, commExperience  .. " / " .. levelExperience
	end

	local currentProgress = commExperience - levelExperience
	local progressGoal = nextExperiece - levelExperience
	return currentProgress/progressGoal, commExperience  .. " / " .. nextExperiece
end

local function GetExperienceDisplay(parentControl, barHeight, fancy)
	local commLevel, commExperience = WG.CampaignData.GetPlayerCommanderInformation()
	local commConfig = WG.Chobby.Configuration.campaignConfig.commConfig

	local levelExperience = commConfig.GetLevelRequirement(commLevel)
	local nextExperiece = commConfig.GetLevelRequirement(commLevel + 1)

	local progressProportion, progressCaption = GetProgress(commExperience, levelExperience, nextExperiece)

	local experienceBar = Progressbar:New {
		x = 0,
		y = 0,
		right = 0,
		height = barHeight or 32,
		value = progressProportion,
		max = 1,
		caption = "Level " .. (commLevel + 1),
		font = WG.Chobby.Configuration:GetFont(3),
		parent = parentControl,
	}

	local progressLabel = Label:New {
		y = barHeight + 3,
		right = 5,
		width = 90,
		height = 22,
		align = "right",
		font = WG.Chobby.Configuration:GetFont(3),
		caption = progressCaption,
		parent = parentControl
	}

	local newExperienceLabel, newBonusExperienceLabel
	if fancy then
		newExperienceLabel = Label:New {
			y = barHeight + 3,
			x = 5,
			width = 90,
			height = 22,
			align = "left",
			font = WG.Chobby.Configuration:GetFont(3),
			caption = "",
			parent = parentControl
		}
		newBonusExperienceLabel = Label:New {
			y = barHeight + 27,
			x = 5,
			width = 90,
			height = 22,
			align = "left",
			font = WG.Chobby.Configuration:GetFont(3),
			caption = "",
			parent = parentControl
		}
	end

	local function AddExperience(newExperience)
		commExperience = commExperience + newExperience

		if nextExperiece and commExperience >= nextExperiece then
			while nextExperiece and commExperience >= nextExperiece do
				commLevel = commLevel + 1
				nextExperiece = commConfig.GetLevelRequirement(commLevel + 1)
			end
			levelExperience = commConfig.GetLevelRequirement(commLevel)
			experienceBar:SetCaption("Level " .. (commLevel + 1))
		end

		progressProportion, progressCaption = GetProgress(commExperience, levelExperience, nextExperiece)
		experienceBar:SetValue(progressProportion)
		progressLabel:SetCaption(progressCaption)
	end

	local experienceToApply, bonusToApply, totalExperienceToApply, totalBonusToApply
	local function FancyExperienceUpdate()
		if Spring.GetGameName() ~= "" then
			WG.Delay(FancyExperienceUpdate, 0.2)
			return
		end
		if experienceToApply then
			local newExperience = math.min(experienceToApply, 1 + math.floor(experienceToApply/9))
			AddExperience(newExperience)
			experienceToApply = experienceToApply - newExperience
			if experienceToApply <= 0 then
				experienceToApply = false
			end
			newExperienceLabel:SetCaption("Experience: " .. (totalExperienceToApply - (experienceToApply or 0)))
		elseif bonusToApply then
			local newExperience = math.min(bonusToApply, 1 + math.floor(bonusToApply/9))
			AddExperience(newExperience)
			bonusToApply = bonusToApply - newExperience
			if bonusToApply <= 0 then
				newExperience = newExperience - bonusToApply
				bonusToApply = false
			end
			newBonusExperienceLabel:SetCaption("Bonus: " .. (totalBonusToApply - (bonusToApply or 0)))
		end

		if experienceToApply or bonusToApply then
			WG.Delay(FancyExperienceUpdate, 0.03)
		end
		WG.LimitFps.ForceRedraw()
	end

	local externalFunctions = {}

	function externalFunctions.AddFancyExperience(gainedExperience, gainedBonusExperience)
		if fancy then
			experienceToApply = (experienceToApply or 0) + gainedExperience - (gainedBonusExperience or 0)
			totalExperienceToApply = experienceToApply

			bonusToApply = (bonusToApply or 0) + gainedBonusExperience
			totalBonusToApply = bonusToApply

			WG.Delay(FancyExperienceUpdate, 0.2)
		end
	end

	function externalFunctions.SetExperience(newExperience, newCommLevel)
		commExperience = newExperience

		if commLevel ~= newCommLevel then
			commLevel = newCommLevel

			nextExperiece = commConfig.GetLevelRequirement(commLevel + 1)
			levelExperience = commConfig.GetLevelRequirement(commLevel)
			experienceBar:SetCaption("Level " .. (commLevel + 1))
		end

		progressProportion, progressCaption = GetProgress(commExperience, levelExperience, nextExperiece)
		experienceBar:SetValue(progressProportion)
		progressLabel:SetCaption(progressCaption)

		WG.LimitFps.ForceRedraw()
	end

	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Components

local function GetModuleButton(parentControl, ClickFunc, moduleName, level, slot, position, hightlightEmpty)
	local Configuration = WG.Chobby.Configuration
	local moduleDefs = Configuration.campaignConfig.commConfig.moduleDefs
	local moduleDefNames = Configuration.campaignConfig.commConfig.moduleDefNames

	local moduleData = moduleDefs[moduleDefNames[moduleName]]

	local count = select(2,  WG.CampaignData.GetModuleIsUnlocked(moduleName))

	local button = Button:New{
		x = 5,
		y = position,
		right = 5,
		height = BUTTON_SIZE,
		padding = {0, 0, 0, 0},
		caption = "",
		OnClick = {
			function(self)
				ClickFunc(self, moduleName, level, slot)
			end
		},
		tooltip = string.gsub(moduleData.description, "_COUNT_", " Limit: " .. (count or "0")),
		parent = parentControl
	}

	local nameBox = TextBox:New{
		x = BUTTON_SIZE + 4,
		y = 18,
		right = 4,
		height = BUTTON_SIZE,
		text = ((hightlightEmpty and moduleData.emptyModule and Configuration:GetHighlightedColor()) or "") .. moduleData.humanName,
		fontsize = Configuration:GetFont(2).size,
		OnClick = {
			function(self)
				ClickFunc(self, moduleName, level, slot)
			end
		},
		parent = button
	}

	local function UpdateNameBoxPosition()
		if nameBox.physicalLines and #nameBox.physicalLines > 1 then
			nameBox:SetPos(nil, 9)
		else
			nameBox:SetPos(nil, 17)
		end
	end

	parentControl.OnResize = parentControl.OnResize or {}
	parentControl.OnResize[#parentControl.OnResize + 1] = UpdateNameBoxPosition

	local image = Image:New{
		x = 4,
		y = 4,
		width = BUTTON_SIZE - 8,
		height = BUTTON_SIZE - 8,
		keepAspect = true,
		file = moduleData.image,
		parent = button,
	}

	local externalFunctions = {}
	function externalFunctions.SetModuleName(newModuleName)
		newCount = select(2,  WG.CampaignData.GetModuleIsUnlocked(newModuleName))
		if newCount == count and newModuleName == moduleName then
			return
		end
		count = newCount
		moduleName = newModuleName
		moduleData = moduleDefs[moduleDefNames[moduleName]]

		button.tooltip = string.gsub(moduleData.description, "_COUNT_", " Limit: " .. (count or "0"))
		button:Invalidate()
		nameBox:SetText(((hightlightEmpty and moduleData.emptyModule and Configuration:GetHighlightedColor()) or "") .. moduleData.humanName)
		UpdateNameBoxPosition()
		image.file = moduleData.image
		image:Invalidate()
	end

	function externalFunctions.SetVisibility(newVisiblity)
		button:SetVisibility(newVisiblity)
	end

	return externalFunctions
end

local function GetModuleList(parentControl, ClickFunc, left, right)
	local Configuration = WG.Chobby.Configuration

	local listScroll = ScrollPanel:New {
		x = left,
		right = right,
		y = 0,
		bottom = 0,
		horizontalScrollbar = false,
		padding = {4, 4, 4, 4},
		parent = parentControl,
	}

	local offset = 0
	local hightlightEmpty = false
	local buttonList = {}

	local externalFunctions = {}

	function externalFunctions.AddHeading(text)
		local heading = Label:New {
			x = 10,
			y = offset + 7,
			right = 5,
			height = 20,
			align = "left",
			font = Configuration:GetFont(3),
			caption = text,
			parent = listScroll
		}
		offset = offset + HEADING_OFFSET
	end

	function externalFunctions.AddModule(moduleName, level, slot)
		if not moduleName then
			moduleName = "nullmodule"
		end
		local button = GetModuleButton(listScroll, ClickFunc, moduleName, level, slot, offset, hightlightEmpty)
		if slot then
			buttonList[level] = buttonList[level] or {}
			buttonList[level][slot] = button
		else
			buttonList[level] = button
		end
		offset = offset + BUTTON_SIZE + 4
	end

	function externalFunctions.UpdateModule(moduleName, level, slot)
		if slot then
			if buttonList[level] and buttonList[level][slot] then
				buttonList[level][slot].SetModuleName(moduleName)
				buttonList[level][slot].SetVisibility(true)
			else
				externalFunctions.AddModule(moduleName, level, slot)
			end
		else
			if buttonList[level] then
				buttonList[level].SetModuleName(moduleName)
				buttonList[level].SetVisibility(true)
			else
				externalFunctions.AddModule(moduleName, level, slot)
			end
		end
	end

	function externalFunctions.UpdateModuleList(newModuleList)
		-- Only works on modules indexed by 'level' directly
		local count = math.max(#newModuleList, #buttonList)
		for i = 1, count do
			if newModuleList[i] then
				externalFunctions.UpdateModule(newModuleList[i], i)
			else
				buttonList[i].SetVisibility(false)
			end
		end
	end

	function externalFunctions.SetVisibility(newVisiblity)
		listScroll:SetVisibility(newVisiblity)
	end

	function externalFunctions.Clear()
		offset = 0
		buttonList = {}
		listScroll:ClearChildren()
	end

	function externalFunctions.SetHighlightEmpty(newHightlightEmpty)
		hightlightEmpty = newHightlightEmpty
	end

	return externalFunctions
end

local function MakeModulePanelHandler(parentControl)
	local highlightedButton, applyLevel, applySlot

	local function ApplyModule(button, moduleName)
		WG.CampaignData.PutModuleInSlot(moduleName, applyLevel, applySlot)
	end

	local moduleSelector = GetModuleList(parentControl, ApplyModule, "51%", 0)
	moduleSelector.SetVisibility(false)

	local function SelectModuleSlot(button, moduleName, level, slot)
		if highlightedButton then
			ButtonUtilities.SetButtonDeselected(highlightedButton)
		end
		applyLevel, applySlot = level, slot
		highlightedButton = button
		ButtonUtilities.SetButtonSelected(button)

		moduleSelector.UpdateModuleList(GetValidReplacementModuleSlot(moduleName, level, slot))
		moduleSelector.SetVisibility(true)
	end

	local currentLoadout = GetModuleList(parentControl, SelectModuleSlot, 0, "51%")

	local externalFunctions = {}

	function externalFunctions.UpdateLoadoutDisplay(commanderLevel, commanderLoadout, highlightEmpty)
		moduleSelector.SetVisibility(false)
		currentLoadout.Clear()
		currentLoadout.SetHighlightEmpty(highlightEmpty)

		local chassisDef = WG.Chobby.Configuration.campaignConfig.commConfig.chassisDef

		for level = 0, commanderLevel do
			local slots = commanderLoadout[level]
			currentLoadout.AddHeading("Level " .. (level + 1))
			local numSlots = chassisDef.levelDefs[level] and #chassisDef.levelDefs[level].upgradeSlots or 0
			for i = 1, numSlots do
				currentLoadout.AddModule(slots and slots[i], level, i)
			end
		end
	end

	local function ModuleSelected(listener, moduleName, oldModule, level, slot)
		if highlightedButton then
			ButtonUtilities.SetButtonDeselected(highlightedButton)
		end
		moduleSelector.SetVisibility(false)
		currentLoadout.UpdateModule(moduleName, level, slot)
	end

	WG.CampaignData.AddListener("ModulePutInSlot", ModuleSelected)

	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Intitialize

local function InitializeControls(parentControl)
	local Configuration = WG.Chobby.Configuration
	local commConfig = Configuration.campaignConfig.commConfig

	Label:New {
		x = 20,
		right = 5,
		y = 17,
		height = 20,
		font = Configuration:GetFont(3),
		caption = i18n("configure_commander"),
		parent = parentControl
	}

	local btnClose = Button:New {
		right = 11,
		y = 7,
		width = 80,
		height = 45,
		caption = i18n("close"),
		font = Configuration:GetFont(3),
		classname = "negative_button",
		OnClick = {
			function()
				parentControl:Hide()
			end
		},
		parent = parentControl
	}

	local informationPanel = ScrollPanel:New {
		x = 12,
		right = 12,
		y = 57,
		bottom = 8,
		horizontalScrollbar = false,
		verticalScrollbar = false,
		padding = {4, 4, 4, 4},
		borderColor = {0,0,0,0},
		parent = parentControl,
	}

	local experienceHolder = Control:New {
		x = COMMANDER_IMAGE_WIDTH + 8,
		y = 56,
		right = 20,
		height = 100,
		padding = {0, 0, 0, 0},
		parent = informationPanel,
	}

	local commanderLabel = Label:New {
		x = COMMANDER_IMAGE_WIDTH + 12,
		y = 15,
		right = 5,
		height = 18,
		align = "left",
		font = WG.Chobby.Configuration:GetFont(4),
		caption = "",
		parent = informationPanel
	}

	local commanderImage = Image:New{
		x = 5,
		y = 5,
		width = COMMANDER_IMAGE_WIDTH,
		height = COMMANDER_IMAGE_HEIGHT,
		keepAspect = true,
		file = commConfig.chassisDef.image,
		parent = informationPanel,
	}

	local experienceDisplay = GetExperienceDisplay(experienceHolder, 38)

	local modulePanel = Control:New {
		x = 12,
		right = 12,
		y = TOP_HEIGHT + 4,
		bottom = 2,
		horizontalScrollbar = false,
		padding = {0, 0, 0, 0},
		borderColor = {0,0,0,0},
		OnResize = {
			function(self, xSize, ySize)
				if ResizeFunction then
					ResizeFunction(xSize)
				end
			end
		},
		parent = informationPanel,
	}

	local modulePanelHandler = MakeModulePanelHandler(modulePanel)

	local function UpdateCommanderDisplay()
		local commanderLevel, commanderExperience, commanderName, commanderLoadout = WG.CampaignData.GetPlayerCommanderInformation()

		commanderLabel:SetCaption(commanderName)
		modulePanelHandler.UpdateLoadoutDisplay(commanderLevel, commanderLoadout, commanderExperience > 0)
		experienceDisplay.SetExperience(commanderExperience, commanderLevel)
	end
	UpdateCommanderDisplay()

	local function GainExperience(_, oldExperience, oldLevel, newExperience, newLevel)
		if (oldLevel ~= newLevel) or oldExperience == 0 then
			UpdateCommanderDisplay()
		else
			experienceDisplay.SetExperience(newExperience, newLevel)
		end
	end

	local function UpdateCommanderName(_, newName)
		commanderLabel:SetCaption(newName)
	end
	UpdateCommanderName(_, WG.CampaignData.GetPlayerCommander().name)

	WG.CampaignData.AddListener("CommanderNameUpdate", UpdateCommanderName)
	WG.CampaignData.AddListener("CampaignLoaded", UpdateCommanderDisplay)
	WG.CampaignData.AddListener("UpdateCommanderLoadout", UpdateCommanderDisplay)
	WG.CampaignData.AddListener("GainExperience", GainExperience)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- External Interface

local CommanderHandler = {}

function CommanderHandler.GetControl()

	local window = Control:New {
		name = "commanderHandler",
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		padding = {0, 0, 0, 0},
		OnParent = {
			function(obj)
				if obj:IsEmpty() then
					InitializeControls(obj)
				end
			end
		},
	}
	return window
end

CommanderHandler.GetExperienceDisplay = GetExperienceDisplay

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

function widget:Initialize()
	CHOBBY_DIR = LUA_DIRNAME .. "widgets/chobby/"
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	WG.CommanderHandler = CommanderHandler
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
