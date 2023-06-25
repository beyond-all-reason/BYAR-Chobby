--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Campaign Technology Panel",
		desc      = "Displays unlocked technology.",
		author    = "GoogleFrog",
		date      = "17 April 2017",
		license   = "GNU LGPL, v2.1 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Local Variables

local REWARD_ICON_SIZE = 58
local MAIN_TITLE_HEIGHT = 28
local PARAGRAPH_TITLE_HEIGHT = 28

local unitRewardList, moduleRewardList, abilityRewardList

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utilities

local function GetIconPosition(index, iconsAcross, paragraphOffset)
	if index%iconsAcross == 0 then
		paragraphOffset = paragraphOffset + (REWARD_ICON_SIZE + 4)
	end

	local x = index%iconsAcross*(REWARD_ICON_SIZE + 4)
	local y = paragraphOffset - REWARD_ICON_SIZE - 4
	return x, y, paragraphOffset
end

local function MakeRewardList(holder, name, rewardsList, tooltipFunction, UnlockedCheck, SortFunction, GetPosition)
	local Configuration = WG.Chobby.Configuration

	local unlockList = {}
	local iconsAcross = math.floor((holder.width - 16)/(REWARD_ICON_SIZE + 4))

	local position = (GetPosition and GetPosition()) or 5

	local x, y, paragraphOffset = 0, 0, -3
	local posIndex = 0

	local rewardsHolder = Control:New {
		x = 13,
		y = position,
		right = 10,
		height = 10,
		padding = {0, 0, 0, 0},
		parent = holder,
	}

	if name then
		TextBox:New {
			x = 1,
			y = paragraphOffset + 5,
			right = 4,
			height = 30,
			text = name,
			font = Configuration:GetFont(3),
			parent = rewardsHolder
		}
		paragraphOffset = MAIN_TITLE_HEIGHT
	end

	local function GetCountLabel(imageControl, count)
		return Label:New {
			x = 2,
			y = "50%",
			right = 4,
			bottom = 6,
			align = "right",
			fontsize = Configuration:GetFont(3).size,
			caption = "\255\0\255\0x" .. count,
			parent = imageControl,
		}
	end

	if SortFunction then
		table.sort(rewardsList, SortFunction)
	end

	local prevCategory
	local paragraphLabels = {}

	for i = 1, #rewardsList do
		local info, imageFile, _, _, categories = tooltipFunction(rewardsList[i])
		if prevCategory ~= info.category then
			paragraphLabels[i] = TextBox:New {
				x = 1,
				y = paragraphOffset + 5,
				right = 4,
				height = 30,
				text = categories[info.category].name,
				font = Configuration:GetFont(3),
				parent = rewardsHolder
			}

			prevCategory = info.category
			paragraphOffset = paragraphOffset + PARAGRAPH_TITLE_HEIGHT
			posIndex = 0
		end

		local unlocked, count = UnlockedCheck(rewardsList[i])
		local statusString = ""
		local color
		if not unlocked then
			color = {0.5, 0.5, 0.5, 0.5}
			statusString = " (locked)"
		end

		x, y, paragraphOffset = GetIconPosition(posIndex, iconsAcross, paragraphOffset)

		local rawTooltip = (info.humanName or "???") .. statusString .. "\n " .. (info.description or "")
		local imageControl = Image:New{
			x = x,
			y = y,
			width = REWARD_ICON_SIZE,
			height = REWARD_ICON_SIZE,
			keepAspect = true,
			color = color,
			tooltip = string.gsub(rawTooltip, "_COUNT_", " Limit: " .. (count or "0")),
			file = imageFile,
			parent = rewardsHolder,
		}
		local countLabel = count and GetCountLabel(imageControl, count)

		function imageControl:HitTest(x,y) return self end

		unlockList[i] = {
			image = imageControl,
			countLabel = countLabel,
			name = rewardsList[i],
			humanName = info.humanName or "???",
			description = info.description or "",
			unlocked = unlocked,
			count = count,
			rawTooltip = rawTooltip
		}

		posIndex = posIndex + 1
	end

	rewardsHolder:SetPos(nil, position, nil, paragraphOffset)

	local function UpdateUnlocked(index)
		local data = unlockList[index]
		local unlocked, count = UnlockedCheck(data.name)
		if unlocked == data.unlocked and count == data.count then
			return
		end
		data.unlocked = unlocked
		data.count = count

		if count then
			if data.countLabel then
				data.countLabel:SetCaption("\255\0\255\0x" .. count)
			else
				data.countLabel = GetCountLabel(data.image, count)
			end
		elseif data.countLabel then
			data.countLabel:SetCaption("")
		end
		data.image.tooltip = string.gsub(data.rawTooltip, "_COUNT_", " Limit: " .. (count or "0"))

		local statusString = ""
		if unlocked then
			color = {1, 1, 1, 1}
		else
			color = {0.5, 0.5, 0.5, 0.5}
			statusString = " (locked)"
		end
		data.image.color = color
		data.image.tooltip = data.humanName .. statusString .. "\n " .. data.description
		data.image:Invalidate()
	end

	local externalFunctions = {}

	function externalFunctions.ResizeFunction(xSize)
		iconsAcross = math.floor((xSize - 16)/(REWARD_ICON_SIZE + 4))
		if GetPosition then
			position = GetPosition()
		end

		paragraphOffset = (name and MAIN_TITLE_HEIGHT) or 0
		posIndex = 0

		for i = 1, #unlockList do
			if paragraphLabels[i] then
				paragraphLabels[i]:SetPos(nil, paragraphOffset + 5)
				paragraphOffset = paragraphOffset + PARAGRAPH_TITLE_HEIGHT
				posIndex = 0
			end

			x, y, paragraphOffset = GetIconPosition(posIndex, iconsAcross, paragraphOffset)
			unlockList[i].image:SetPos(x, y)

			posIndex = posIndex + 1
		end

		rewardsHolder:SetPos(nil, position, nil, paragraphOffset)
	end

	function externalFunctions.UpdateUnlockedList()
		for i = 1, #unlockList do
			UpdateUnlocked(i)
		end
	end
	function externalFunctions.GetBottom()
		return position + paragraphOffset + REWARD_ICON_SIZE
	end

	return externalFunctions
end

local function UpdateAllUnlocks()
	if unitRewardList then
		unitRewardList.UpdateUnlockedList()
	end
	if moduleRewardList then
		moduleRewardList.UpdateUnlockedList()
	end
	if abilityRewardList then
		abilityRewardList.UpdateUnlockedList()
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Intitialize

local function InitializeControls(parentControl)
	local Configuration = WG.Chobby.Configuration

	Label:New {
		x = 20,
		right = 5,
		y = 17,
		height = 20,
		font = Configuration:GetFont(3),
		caption = i18n("technology"),
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

	local ResizeFunction

	local scrollPanel = ScrollPanel:New {
		x = 12,
		right = 12,
		y = 57,
		bottom = 16,
		horizontalScrollbar = false,
		padding = {4, 4, 4, 4},
		borderColor = {0,0,0,0},
		OnResize = {
			function(self, xSize, ySize)
				if ResizeFunction then
					ResizeFunction(xSize)
				end
			end
		},
		parent = parentControl,
	}

	local unlockList = Configuration.campaignConfig.unlocksList
	unitRewardList = MakeRewardList(scrollPanel, nil, unlockList.units.list,
		WG.CampaignData.GetUnitInfo,
		WG.CampaignData.GetUnitIsUnlocked,
		WG.Chobby.Configuration.gameConfig.gameUnitInformation.UnitOrder
	)
	moduleRewardList = MakeRewardList(scrollPanel, nil, unlockList.modules.list,
		WG.CampaignData.GetModuleInfo,
		WG.CampaignData.GetModuleIsUnlocked,
		WG.Chobby.Configuration.campaignConfig.commConfig.ModuleOrder,
		unitRewardList.GetBottom
	)
	abilityRewardList = MakeRewardList(scrollPanel, "Abilities", unlockList.abilities.list,
		WG.CampaignData.GetAbilityInfo,
		WG.CampaignData.GetAbilityIsUnlocked,
		nil,
		moduleRewardList.GetBottom
	)

	function ResizeFunction(xSize)
		unitRewardList.ResizeFunction(xSize)
		moduleRewardList.ResizeFunction(xSize)
		abilityRewardList.ResizeFunction(xSize)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- External Interface

local TechnologyHandler = {}

function TechnologyHandler.GetControl()

	local window = Control:New {
		name = "technologyHandler",
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


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

function widget:Initialize()
	CHOBBY_DIR = LUA_DIRNAME .. "widgets/chobby/"
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	WG.CampaignData.AddListener("CampaignLoaded", UpdateAllUnlocks)
	WG.CampaignData.AddListener("RewardGained", UpdateAllUnlocks)

	WG.TechnologyHandler = TechnologyHandler
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
