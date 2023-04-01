function widget:GetInfo()
	return {
		name    = 'Cursor tooltip',
		desc    = 'Provides a tooltip whilst hovering the mouse',
		author  = 'Funkencool',
		date    = '2013',
		license = 'GNU GPL v2',
		layer   = 0,
		enabled = true,
	}
end

local spGetMouseState           = Spring.GetMouseState
local screenWidth, screenHeight = Spring.GetWindowGeometry()

local MAX_WIDTH = 320
local MAX_WINDOW_WIDTH = MAX_WIDTH + 11

local BATTLE_TOOLTIP_PREFIX = "battle_tooltip_"
local USER_TOOLTIP_PREFIX = "user_"
local USER_SP_TOOLTIP_PREFIX = "user_single_"
local USER_MP_TOOLTIP_PREFIX = "user_battle_"
local USER_CH_TOOLTIP_PREFIX = "user_chat_s_"
local MINIMAP_TOOLTIP_PREFIX = "minimap_tooltip_"

local TOOLTIP_TEXT_NAME = "tooltipText"

local IMAGE_MODERATOR    = LUA_DIRNAME .. "images/ranks/moderator.png"
local IMAGE_FRIEND       = LUA_DIRNAME .. "images/ranks/friend.png"
local IMAGE_MUTE         = LUA_DIRNAME .. "images/ranks/noChat.png"
local IMAGE_AFK          = LUA_DIRNAME .. "images/away.png"
local IMAGE_BATTLE       = LUA_DIRNAME .. "images/battle.png"
local IMAGE_INGAME       = LUA_DIRNAME .. "images/ingame.png"
local IMAGE_LOCK         = LUA_DIRNAME .. "widgets/chobby/images/lock.png"
local BATTLE_RUNNING     = LUA_DIRNAME .. "images/runningBattle.png"
local BATTLE_NOT_RUNNING = LUA_DIRNAME .. "images/nothing.png"

local PASSWORD_EXPLAINATION = "Battle requires a password to join."

--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- Variables

local mousePosX, mousePosY
local tipWindow, tipTextDisplay
local tooltipOverride = nil

--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- Initialization

local function InitWindow()
	tipWindow = Chili.Window:New{
		name      = "tooltipWindow",
		parent    = screen0,
		width     = 75,
		height    = 75,
		minHeight = 1,
		maxWidth  = MAX_WINDOW_WIDTH,
		resizable = false,
		draggable = false,
		padding   = {5,4,6,2},
		classname = "overlay_window",
	}
	tipTextDisplay = Chili.TextBox:New{
		name   = TOOLTIP_TEXT_NAME,
		x      = 2,
		y      = 4,
		width  = MAX_WIDTH,
		parent = tipWindow,
		lineSpacing = 1,
		autoHeight = true,
		margin = {0,0,0,0},
		font = {
			outline          = true,
			autoOutlineColor = true,
			outlineWidth     = 3,
			outlineWeight    = 4,
		}
	}

	tipWindow:Hide()
end

local oldSizeX, oldSizeY
function widget:ViewResize(vsx, vsy)
	oldSizeX, oldSizeY = vsx, vsy
	screenWidth = vsx
	screenHeight = vsy
end

local function EvilHax()
	local screenWidth, screenHeight = Spring.GetWindowGeometry()
	if screenWidth ~= oldSizeX or screenHeight ~= oldSizeY then
		widget:ViewResize(screenWidth, screenHeight)
	end
end

--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- Specific tooltip type utilities

local function GetTooltipLine(parent, hasImage, fontSize, xOffset, imageWidth)
	local textDisplay, imageDisplay

	fontSize = fontSize or 2
	xOffset = xOffset or 6

	local externalFunctions = {}

	if hasImage then
		imageDisplay = Image:New {
			x = xOffset,
			y = 0,
			width = imageWidth or 19,
			height = 19,
			parent = parent,
			keepAspect = true,
			file = nil,
			fallbackFile = WG.Chobby.Configuration:GetLoadingImage(1),
		}
	end

	textDisplay = TextBox:New {
		x = (hasImage and ((imageWidth or 19) + 4 + xOffset)) or xOffset,
		y = 0,
		right = 0,
		height = 20,
		align = "left",
		parent = parent,
		fontsize = WG.Chobby.Configuration:GetFont(fontSize).size,
		text = "",
	}

	function externalFunctions.Update(newPosition, newText, newImage, newColor, needDownload)
		if not textDisplay.visible then
			textDisplay:Show()
		end
		textDisplay:SetText(newText)
		textDisplay:SetPos(nil, newPosition)

		if newColor then
			textDisplay.font.color = newColor
			textDisplay:Invalidate()
		end

		if hasImage then
			if not imageDisplay.visible then
				imageDisplay:Show()
			end
			imageDisplay.file = newImage
			imageDisplay.checkFileExists = needDownload
			imageDisplay:SetPos(nil, newPosition - 4)
			imageDisplay:Invalidate()
		end
	end

	function externalFunctions.UpdatePosition(newPosition)
		if not textDisplay.visible then
			textDisplay:Show()
		end
		textDisplay:SetPos(nil, newPosition)
		if hasImage then
			if not imageDisplay.visible then
				imageDisplay:Show()
			end
			imageDisplay:SetPos(nil, newPosition - 4)
		end
	end

	function externalFunctions.Hide()
		if textDisplay.visible then
			textDisplay:Hide()
		end
		if hasImage and imageDisplay.visible then
			imageDisplay:Hide()
		end
	end

	function externalFunctions.GetLines()
		-- Does not work so always returns 1.
		local text = textDisplay.text
		local _, _, numLines = textDisplay.font:GetTextHeight(text)
		return numLines
	end

	function externalFunctions.GetFont()
		return textDisplay.font
	end

	return externalFunctions
end

local function GetBattleInfoHolder(parent, offset, battleID)
	local externalFunctions = {}

	local battle = lobby:GetBattle(battleID)
	if not battle then
		return nil
	end

	local Configuration = WG.Chobby.Configuration

	local mainControl = Control:New {
		x = 0,
		y = offset,
		right = 0,
		height = 120,
		padding = {0, 0, 0, 0},
		parent = parent,
	}

	local lblTitle = Label:New {
		name = "title",
		x = 80,
		y = 1,
		right = 5,
		height = 20,
		valign = 'top',
		font = Configuration:GetFont(1),
		caption = battle.title:sub(1, 60),
		parent = mainControl,
		OnResize = {
			function (obj, xSize, ySize)
				if battle then
					obj:SetCaption(StringUtilities.GetTruncatedStringWithDotDot(battle.title, obj.font, obj.width))
				end
			end
		}
	}

	local mapImageFile, needDownload = Configuration:GetMinimapSmallImage(battle.mapName)
	local minimapImage = Image:New {
		name = "minimapImage",
		x = 6,
		y = 0,
		width = 70,
		height = 70,
		keepAspect = true,
		file = mapImageFile,
		fallbackFile = Configuration:GetLoadingImage(2),
		checkFileExists = needDownload,
		parent = mainControl,
	}
	local runningImage = Image:New {
		name = "runningImage",
		x = 6,
		y = 0,
		width = 70,
		height = 70,
		keepAspect = false,
		file = (battle.isRunning and BATTLE_RUNNING) or BATTLE_NOT_RUNNING,
		parent = mainControl,
	}
	runningImage:BringToFront()

	local lblPlayers = Label:New {
		name = "playersCaption",
		x = 80,
		y = 22,
		right = 0,
		height = 20,
		valign = 'top',
		font = Configuration:GetFont(1),
		caption = lobby:GetBattlePlayerCount(battleID) .. "/" .. battle.maxPlayers,
		parent = mainControl,
	}

	local imgPassworded = Image:New {
		name = "password",
		x = 80,
		y = 36,
		height = 30,
		width = 30,
		margin = {0, 0, 0, 0},
		file = IMAGE_LOCK,
		parent = mainControl,
	}
	if not battle.passworded then
		imgPassworded:Hide()
	end

	local lblGame = Label:New {
		name = "game",
		x = 125,
		y = 22,
		right = 5,
		height = 20,
		valign = 'top',
		caption = battle.gameName:sub(1, 22),
		font = Configuration:GetFont(1),
		parent = mainControl,
		OnResize = {
			function (obj, xSize, ySize)
				if battle then
					obj:SetCaption(StringUtilities.GetTruncatedStringWithDotDot(battle.gameName, obj.font, obj.width))
				end
			end
		}
	}

	local lblMap = Label:New {
		name = "mapCaption",
		x = 125,
		y = 40,
		right = 5,
		height = 20,
		valign = 'center',
		caption = battle.mapName:sub(1, 22),
		font = Configuration:GetFont(1),
		parent = mainControl,
		OnResize = {
			function (obj, xSize, ySize)
				if battle then
					obj:SetCaption(StringUtilities.GetTruncatedStringWithDotDot(battle.mapName, obj.font, obj.width))
				end
			end
		}
	}

	function externalFunctions.Update(offset, battleID)
		battle = lobby:GetBattle(battleID)
		if not battle then
			if mainControl.visible then
				mainControl:Hide()
			end
			return
		end

		if not mainControl.visible then
			mainControl:Show()
		end
		mainControl:SetPos(nil, offset)

		lblTitle:SetCaption(StringUtilities.GetTruncatedStringWithDotDot(battle.title, lblTitle.font, lblTitle.width))
		lblPlayers:SetCaption(lobby:GetBattlePlayerCount(battleID) .. "/" .. battle.maxPlayers)
		lblGame:SetCaption(StringUtilities.GetTruncatedStringWithDotDot(battle.gameName, lblTitle.font, lblTitle.width))
		lblMap:SetCaption(StringUtilities.GetTruncatedStringWithDotDot(battle.mapName, lblTitle.font, lblTitle.width))

		if battle.passworded and not imgPassworded.visible then
			imgPassworded:Show()
		end
		if not battle.passworded and imgPassworded.visible then
			imgPassworded:Hide()
		end

		minimapImage.file, minimapImage.checkFileExists = Configuration:GetMinimapSmallImage(battle.mapName)
		minimapImage:Invalidate()

		runningImage.file = (battle.isRunning and BATTLE_RUNNING) or BATTLE_NOT_RUNNING
		runningImage:Invalidate()
	end

	function externalFunctions.Hide()
		if mainControl.visible then
			mainControl:Hide()
		end
	end

	return externalFunctions
end

--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- Battle tooltip
local battleTooltip = {}

local function GetBattleTooltip(battleID, battle)
	local Configuration = WG.Chobby.Configuration

	local width = 320
	if not battleTooltip.mainControl then
		battleTooltip.mainControl = Chili.Control:New {
			x = 0,
			y = 0,
			width = width,
			height = 120,
			padding = {0, 0, 0, 0},
		}
	end
	local offset = 7

	-- Battle Name
	if not battleTooltip.title then
		battleTooltip.title = GetTooltipLine(battleTooltip.mainControl, nil, 3)
	end
	local title = battle.title
	if battle.isMatchMaker then
		title = (title or "") .. " - Click to watch"
	end
	local truncatedName = StringUtilities.GetTruncatedStringWithDotDot(title, battleTooltip.title.GetFont(), width - 10)
	battleTooltip.title.Update(offset, truncatedName)
	offset = offset + 25 -- * battleTooltip.title.GetLines() -- Not required with truncation

	-- Battle Type
	if battle.battleMode then
		if not battleTooltip.battleMode then
			battleTooltip.battleMode = GetTooltipLine(battleTooltip.mainControl)
		end
		local modeName = Configuration.battleTypeToName[battle.battleMode]
		battleTooltip.battleMode.Update(offset, (modeName and i18n(modeName)) or "")
		offset = offset + 21
	elseif battleTooltip.battleMode then
		battleTooltip.battleMode.Hide()
	end

	-- Players and Spectators
	if battle.spectatorCount and battle.maxPlayers and battle.users then
		if not battleTooltip.playerCount then
			battleTooltip.playerCount = GetTooltipLine(battleTooltip.mainControl)
		end
		battleTooltip.playerCount.Update(offset, "Players: " .. lobby:GetBattlePlayerCount(battleID) .. "/" .. battle.maxPlayers)

		if not battleTooltip.spectatorCount then
			battleTooltip.spectatorCount = GetTooltipLine(battleTooltip.mainControl, nil, nil, 130)
		end
		battleTooltip.spectatorCount.Update(offset, "Spectators: " .. battle.spectatorCount)

		offset = offset + 20
	elseif battleTooltip.playerCount then
		battleTooltip.playerCount.Hide()
	end

	-- Password
	if battle.passworded then
		if not battleTooltip.password then
			battleTooltip.password = GetTooltipLine(battleTooltip.mainControl, true)
			battleTooltip.password.Update(
				offset,
				PASSWORD_EXPLAINATION,
				IMAGE_LOCK
			)
		end
		battleTooltip.password.UpdatePosition(offset)
		offset = offset + 20
	elseif battleTooltip.password then
		battleTooltip.password.Hide()
	end

	if battle.isRunning then
		if not battleTooltip.isRunning then
			battleTooltip.isRunning = GetTooltipLine(battleTooltip.mainControl, true)
		end
		battleTooltip.isRunning.Update(
			offset,
			"Game in progress, join to spectate.",
			IMAGE_INGAME
		)
		battleTooltip.isRunning.UpdatePosition(offset)
		offset = offset + 20
	elseif battleTooltip.isRunning then
		battleTooltip.isRunning:Hide()
	end
  
	-- InGameSince
	if battle.runningSince and battle.isRunning then
		if not battleTooltip.inGameSince then
			battleTooltip.inGameSince = GetTooltipLine(battleTooltip.mainControl, true)
		end
		battleTooltip.inGameSince.Update(
			offset,
			"Running for " .. Spring.Utilities.GetTimeToPast(battle.runningSince, true),
			IMAGE_INGAME
		)
		offset = offset + 20
	elseif battleTooltip.inGameSince then
		battleTooltip.inGameSince:Hide()
	end

	-- Player list
	local userListPosition = offset
	if battle.users then
		offset = offset
		if not battleTooltip.userList then
			battleTooltip.userList = Chili.Control:New {
				x = 0,
				y = userListPosition,
				right = 0,
				bottom = 0,
				padding = {0, 0, 0, 0},
				parent = battleTooltip.mainControl,
			}
		end
		battleTooltip.userList:ClearChildren()
		local playerOffset = 0
		for i = 1, #battle.users do
			local userName = battle.users[i]
			local playerControl = WG.UserHandler.GetTooltipUser(userName)
			battleTooltip.userList:AddChild(playerControl)
			playerControl:SetPos(0, playerOffset)
			playerControl._relativeBounds.right = 0
			playerControl:UpdateClientArea()
			playerOffset = playerOffset + 20
		end
		offset = offset + playerOffset + 5
	end

	-- Debug Mode
	if Configuration.debugMode then
		offset = offset + 10

		if not battleTooltip.debugText then
			battleTooltip.debugText = Chili.TextBox:New{
				x      = 5,
				y      = 200,
				right  = 5,
				bottom = 5,
				parent = tipWindow,
				margin = {0,0,0,0},
				font = {
					outline          = true,
					autoOutlineColor = true,
					outlineWidth     = 3,
					outlineWeight    = 4,
				},
				parent = battleTooltip.mainControl,
			}
		end
		battleTooltip.debugText:SetPos(nil, offset)

		if not battleTooltip.debugText.parent then
			battleTooltip.mainControl:AddChild(battleTooltip.debugText)
		end

		local text = "battleUD = " .. battleID
		for key, value in pairs(battle) do
			text = text .. "\n" .. key .. " = " .. tostring(value)
		end

		battleTooltip.debugText:SetText(text)
		battleTooltip.debugText:UpdateLayout()
		local _, _, numLines = battleTooltip.debugText.font:GetTextHeight(text)
		local height = numLines * 14 + 8 + 7

		offset = offset + height
	elseif battleTooltip.debugText and battleTooltip.debugText.parent then
		battleTooltip.mainControl:RemoveChild(battleTooltip.debugText)
	end

	-- Set tooltip sizes
	battleTooltip.mainControl:SetPos(nil, nil, width, offset)

	if battleTooltip.userList then
		battleTooltip.userList:SetPos(0, userListPosition)
		battleTooltip.userList._relativeBounds.right = 0
		battleTooltip.userList._relativeBounds.bottom = 0
		battleTooltip.userList:UpdateClientArea()
	end

	return battleTooltip.mainControl
end

--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- Minimap tooltip

local minimapTooltip = {}

local function GetMinimapTooltip(mapName, title)
		local Configuration = WG.Chobby.Configuration
	
		local width = MAX_WINDOW_WIDTH
		local height = width

		if not minimapTooltip.mainControl then
			minimapTooltip.mainControl = Chili.Control:New {
				x = 0,
				y = 0,
				width = width,
				height = height,
				padding = {0, 0, 0, 0},
				title = title,
			}
		end

		if not minimapTooltip.title then
			minimapTooltip.title = GetTooltipLine(minimapTooltip.mainControl, nil, 2)
		end
		
		local mapImageFile, needDownload = Configuration:GetMinimapImage(mapName)
		if minimapTooltip.mainControl:GetChildByName("minimapImageLarge") then
			local minimapImage = minimapTooltip.mainControl:GetChildByName("minimapImageLarge")
			minimapImage.file = mapImageFile
			minimapImage:Invalidate()
		else
			local minimapImage = Image:New {
				name = "minimapImageLarge",
				x = 0,
				y = 0,
				width = width,
				height = width,
				keepAspect = true,
				file = mapImageFile,
				fallbackFile = Configuration:GetLoadingImage(2),
				checkFileExists = needDownload,
				padding = {0, 0, 0, 0},
				parent = minimapTooltip.mainControl,
			}
		end

		minimapTooltip.title.Update(7, mapName.. "\n" .. title)
		-- Set tooltip sizes
		minimapTooltip.mainControl:SetPos(nil, nil, width, height)
	
		return minimapTooltip.mainControl
end

--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- User tooltip
local userTooltip = {}

local function GetUserTooltip(userName, userInfo, userBattleInfo, inBattleroom)
	local Configuration = WG.Chobby.Configuration

	local width = 240
	if not userTooltip.mainControl then
		userTooltip.mainControl = Chili.Control:New {
			x = 0,
			y = 0,
			width = width,
			height = 120,
			padding = {0, 0, 0, 0},
		}
	end
	local offset = 7

	-- User Name
	if not userTooltip.name then
		userTooltip.name = GetTooltipLine(userTooltip.mainControl, nil, 3)
	end
	local truncatedName = StringUtilities.GetTruncatedStringWithDotDot(userName, userTooltip.name.GetFont(), width - 10)
	userTooltip.name.Update(offset, truncatedName)
	offset = offset + 23

	-- Clan
	if userInfo.clan then
		if not userTooltip.clan then
			userTooltip.clan = GetTooltipLine(userTooltip.mainControl, true)
		end

		local clanFile, needDownload = WG.UserHandler.GetClanImage(userInfo.clan)
		userTooltip.clan.Update(offset, "Clan: " .. userInfo.clan, clanFile, nil, needDownload)
		offset = offset + 20
	elseif userTooltip.clan then
		userTooltip.clan.Hide()
	end

	-- Ignore and Friend
	if userInfo.isIgnored or userInfo.isFriend then
		if not userTooltip.friendIgnore then
			userTooltip.friendIgnore = GetTooltipLine(userTooltip.mainControl, true)
		end
		userTooltip.friendIgnore.Update(
			offset,
			userInfo.isIgnored and "Ignored" or "Friend",
			userInfo.isIgnored and IMAGE_MUTE or IMAGE_FRIEND
		)
		offset = offset + 20
	elseif userTooltip.friendIgnore then
		userTooltip.friendIgnore:Hide()
	end

	-- Country
	if userInfo.country then
		if not userTooltip.country then
			userTooltip.country = GetTooltipLine(userTooltip.mainControl, true)
		end
		userTooltip.country.Update(
			offset,
			Configuration:GetCountryLongname(userInfo.country),
			WG.UserHandler.CountryShortnameToFlag(userInfo.country)
		)
		offset = offset + 20
	elseif userBattleInfo.owner then
		if not userTooltip.country then
			userTooltip.country = GetTooltipLine(userTooltip.mainControl, true)
		end
		userTooltip.country.Update(
			offset,
			"Owner: " .. userBattleInfo.owner,
			IMAGE_BATTLE
		)
		offset = offset + 20
	elseif userTooltip.country then
		userTooltip.country:Hide()
	end

	-- Moderator
	if userInfo.isAdmin then
		if not userTooltip.moderator then
			userTooltip.moderator = GetTooltipLine(userTooltip.mainControl, true)
			userTooltip.moderator.Update(
				offset,
				"Moderator",
				IMAGE_MODERATOR,
				Configuration:GetModeratorColor()
			)
		end
		userTooltip.moderator.UpdatePosition(offset)
		offset = offset + 20
	elseif userTooltip.moderator then
		userTooltip.moderator:Hide()
	end

	-- Level
	if userInfo.level or userBattleInfo.aiLib then
		if not userTooltip.level then
			userTooltip.level = GetTooltipLine(userTooltip.mainControl, true)
		end
		local isBot = (userInfo.isBot or userBattleInfo.aiLib)
		local text
		if userInfo.isBot then
			text = "Autohost"
		elseif userBattleInfo.aiLib then
			text = "AI: " .. userBattleInfo.aiLib
		elseif Configuration.showSkillOpt and Configuration.showSkillOpt > 1 and userInfo.skill and userInfo.skillUncertainty then
			text = "OpenSkill: " .. userInfo.skill 
			if Configuration.showSkillOpt == 3 then
				text = text .. " ± ".. userInfo.skillUncertainty
			end
		else
			text = "Level: " .. userInfo.level
		end

		userTooltip.level.Update(
			offset,
			text,
			WG.UserHandler.GetUserRankImage(userInfo, isBot)
		)
		offset = offset + 20
	elseif userTooltip.level then
		userTooltip.level:Hide()
	end


	if userInfo.badges and Configuration.gameConfig.badges then
		if not userTooltip.badge then
			userTooltip.badge = {}
		end
		local badgeDecs = Configuration.gameConfig.badges
		local i = 1
		while i <= #userInfo.badges do
			if not userTooltip.badge[i] then
				userTooltip.badge[i] = GetTooltipLine(userTooltip.mainControl, true, nil, nil, 46)
			end
			local badgeData = badgeDecs[userInfo.badges[i]]
			if badgeData then
				userTooltip.badge[i].Update(
					offset,
					badgeData.text,
					badgeData.image
				)
				offset = offset + 20
			else
				userTooltip.badge[i]:Hide()
			end
			i = i + 1
		end
		while userTooltip.badge[i] do
			userTooltip.badge[i]:Hide()
			i = i + 1
		end
	elseif userTooltip.badge then
		local i = 1
		while userTooltip.badge[i] do
			userTooltip.badge[i]:Hide()
			i = i + 1
		end
	end

	-- InGameSince
	if userInfo.inGameSince and userInfo.isInGame then
		if not userTooltip.inGameSince then
			userTooltip.inGameSince = GetTooltipLine(userTooltip.mainControl, true)
		end
		userTooltip.inGameSince.Update(
			offset,
			"In game for " .. Spring.Utilities.GetTimeToPast(userInfo.inGameSince, true),
			IMAGE_INGAME
		)
		offset = offset + 20
	elseif userTooltip.inGameSince then
		userTooltip.inGameSince:Hide()
	end

	-- Away Since
	if userInfo.awaySince and userInfo.isAway then
		if not userTooltip.awaySince then
			userTooltip.awaySince = GetTooltipLine(userTooltip.mainControl, true)
		end
		userTooltip.awaySince.Update(
			offset,
			"Idle for " .. Spring.Utilities.GetTimeToPast(userInfo.awaySince, true),
			IMAGE_AFK
		)
		offset = offset + 20
	elseif userTooltip.awaySince then
		userTooltip.awaySince:Hide()
	end

	-- In Battle
	if (not inBattleroom) and userInfo.battleID and lobby:GetBattle(userInfo.battleID) then
		if not userTooltip.battleInfoHolder then
			userTooltip.battleInfoHolder = GetBattleInfoHolder(userTooltip.mainControl, offset, userInfo.battleID)
		else
			userTooltip.battleInfoHolder.Update(offset, userInfo.battleID)
		end
		offset = offset + 75
	elseif userTooltip.battleInfoHolder then
		userTooltip.battleInfoHolder:Hide()
	end

	-- Debug Mode
	if Configuration.debugMode then
		offset = offset + 10

		if not userTooltip.debugText then
			userTooltip.debugText = Chili.TextBox:New{
				x      = 5,
				y      = 200,
				right  = 5,
				bottom = 5,
				parent = tipWindow,
				margin = {0,0,0,0},
				font = {
					outline          = true,
					autoOutlineColor = true,
					outlineWidth     = 3,
					outlineWeight    = 4,
				},
				parent = userTooltip.mainControl,
			}
		end
		userTooltip.debugText:SetPos(nil, offset)

		if not userTooltip.debugText.parent then
			userTooltip.mainControl:AddChild(userTooltip.debugText)
		end

		local text = userName
		for key, value in pairs(userInfo) do
			text = text .. "\n" .. key .. " = " .. tostring(value)
		end
		for key, value in pairs(userBattleInfo) do
			text = text .. "\n" .. key .. " = " .. tostring(value)
		end

		userTooltip.debugText:SetText(text)
		userTooltip.debugText:UpdateLayout()
		local _, _, numLines = userTooltip.debugText.font:GetTextHeight(text)
		local height = numLines * 14 + 8 + 7

		offset = offset + height
	elseif userTooltip.debugText and userTooltip.debugText.parent then
		userTooltip.mainControl:RemoveChild(userTooltip.debugText)
	end

	-- Set tooltip sizes
	userTooltip.mainControl:SetPos(nil, nil, width, offset)

	return userTooltip.mainControl
end

--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- Tooltip maintence

local function GetTooltip()
	if tooltipOverride then
		return tooltipOverride
	end
	if screen0.currentTooltip then -- this gives chili absolute priority, otherwise TraceSreenRay() would ignore the fact ChiliUI is underneath the mouse
		return screen0.currentTooltip
	end
end

local function SetTooltipPos()
	local tooltipChild = tipWindow.children[1]
	if not tooltipChild then
		if tipWindow.visible then
			tipWindow:Hide()
		end
		return
	end

	local x,y = spGetMouseState()
	local width,height

	if tooltipChild.name == TOOLTIP_TEXT_NAME then
		local text = tipTextDisplay.text
		width  = tipTextDisplay.font:GetTextWidth(text) + 15
		height = tooltipChild.height + 14
	else
		-- Fudge numbers correspond to padding
		width, height = tooltipChild.width + 9, tooltipChild.height + 8
	end

	if width > MAX_WINDOW_WIDTH then
		width = MAX_WINDOW_WIDTH
	end

	x = x + 20
	y = screenHeight - y -- Spring y is from the bottom, chili is from the top

	-- Making sure the tooltip is within the boundaries of the screen
	if y + height + 20 > screenHeight then
		if y > height then
			y = y - height
		else
			y = math.max(0, screenHeight - height)
		end
	else
		y = y + 20
	end

	if x + width > screenWidth then
		x = screenWidth - width
	end

	tipWindow:SetPos(x, y, width, height)

	if tipWindow.hidden then
		tipWindow:Show()
	end
	tipWindow:BringToFront()
end

local function UpdateTooltip(inputText)
	if inputText:starts(USER_TOOLTIP_PREFIX) then
		local userName = string.sub(inputText, 13)
		local myLobby, inBattleroom
		if inputText:starts(USER_SP_TOOLTIP_PREFIX) then
			myLobby = WG.LibLobby.localLobby
			inBattleroom = true
		else
			myLobby = lobby
			if inputText:starts(USER_MP_TOOLTIP_PREFIX) then
				inBattleroom = true
			end
		end
		local userInfo = myLobby:TryGetUser(userName)
		local userBattleInfo = myLobby:GetUserBattleStatus(userName) or {}

		local tooltipControl = GetUserTooltip(userName, userInfo, userBattleInfo, inBattleroom)

		tipWindow:ClearChildren()
		tipWindow:AddChild(tooltipControl)

	elseif inputText:starts(BATTLE_TOOLTIP_PREFIX) then
		local battleID = tonumber(string.sub(inputText, 16))
		local battle = lobby:GetBattle(battleID)
		if battle then
			local tooltipControl = GetBattleTooltip(battleID, battle)

			tipWindow:ClearChildren()
			tipWindow:AddChild(tooltipControl)
		end
	elseif inputText:starts(MINIMAP_TOOLTIP_PREFIX) then
		local mapName = string.sub(inputText, 17)
		local tooltiptext = ""
		if mapName:find("|",1, true) then
			tooltiptext = string.sub(mapName, mapName:find("|", 1, true) + 1) or ""
			mapName = string.sub(mapName, 1, mapName:find("|", 1, true) -1) 
		end
		if mapName then
			local tooltipcontrol = GetMinimapTooltip(mapName,tooltiptext)
			tipWindow:ClearChildren()
			tipWindow:AddChild(tooltipcontrol)
		end
	else -- For everything else display a normal tooltip
		tipWindow:ClearChildren()
		tipTextDisplay:SetText(inputText)
		tipWindow:AddChild(tipTextDisplay)
		tipTextDisplay:UpdateLayout()
	end
end

local currentTooltipText = false
local function CheckTooltipUpdate(newText)
	if newText then
		if currentTooltipText ~= newText then
			currentTooltipText = newText
			UpdateTooltip(newText)
			SetTooltipPos() 
		else
			-- Changed to dont update tooltip pos if not desired
			if WG.Chobby.Configuration and WG.Chobby.Configuration.staticTooltipPositions ~= true then
				SetTooltipPos()
			end
		end
	else
		if tipWindow.visible then
			tipWindow:Hide()
			currentTooltipText = false
		end
	end
end

--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- External Functions

local TooltipHandler = {}

function TooltipHandler.TooltipOverrideClear()
	tooltipOverride = nil
	CheckTooltipUpdate(GetTooltip())
end

function TooltipHandler.TooltipOverride(newText, overrideTime)
	tooltipOverride = newText
	CheckTooltipUpdate(GetTooltip())
	if overrideTime then
		WG.Delay(TooltipHandler.TooltipOverrideClear, overrideTime)
	end
end

--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- Widget callins

function widget:Update()
	EvilHax()
	CheckTooltipUpdate(GetTooltip())
end

function widget:Initialize()
	CHOBBY_DIR = LUA_DIRNAME .. "widgets/chobby/"
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	InitWindow()
	WG.TooltipHandler = TooltipHandler
end

function widget:Shutdown()
	tipWindow:Dispose()
end

