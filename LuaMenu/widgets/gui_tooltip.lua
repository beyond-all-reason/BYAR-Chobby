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
local spFormatTime              = Spring.Utilities.FormatTime
local screenWidth, screenHeight = Spring.GetWindowGeometry()

local MAX_WIDTH = 880 -- 220 x 4 for Replay tooltips
local MAX_WINDOW_WIDTH = MAX_WIDTH + 11

local TOOLTIP_TEXT_NAME = "tooltipText"

local IMAGE_MODERATOR    = LUA_DIRNAME .. "images/ranks/moderator.png"
local IMAGE_FRIEND       = LUA_DIRNAME .. "images/ranks/friend.png"
local IMAGE_IGNORE       = LUA_DIRNAME .. "images/ignored.png"
local IMAGE_AVOID        = LUA_DIRNAME .. "images/avoided.png"
local IMAGE_BLOCK        = LUA_DIRNAME .. "images/blocked.png"
local IMAGE_AFK          = LUA_DIRNAME .. "images/away.png"
local IMAGE_BATTLE       = LUA_DIRNAME .. "images/battle.png"
local IMAGE_INGAME       = LUA_DIRNAME .. "images/ingame.png"
local IMAGE_LOCK         = LUA_DIRNAME .. "images/lock.png"
local IMAGE_KEY          = LUA_DIRNAME .. "images/key.png"
local BATTLE_RUNNING     = LUA_DIRNAME .. "images/runningBattle.png"
local BATTLE_NOT_RUNNING = LUA_DIRNAME .. "images/nothing.png"

local PASSWORD_EXPLAINATION = "Battle requires a password to join."
local LOCKED_EXPLAINATION = "Battle is locked."


--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- Variables

local mousePosX, mousePosY
local tipWindow, tipTextDisplay
local tooltipOverride = nil

--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- Helpers
local function sortfunc(t)
	local st = {}
	for k,v in pairs(t) do
		if type(v) ~= "table" then 
			table.insert(st, { k, v })
		end
	end
	table.sort(st, function(a,b) return a[1] < b[1] end )
	return st
 end

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
		},
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
			width = imageWidth or 18,
			height = 18,
			parent = parent,
			keepAspect = true,
			file = nil,
			fallbackFile = WG.Chobby.Configuration:GetLoadingImage(1),
		}
	end

	textDisplay = TextBox:New {
		x = (hasImage and ((imageWidth or 18) + 4 + xOffset)) or xOffset,
		y = 0,
		right = 0,
		height = 20,
		align = "left",
		parent = parent,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(fontSize, "Nimbus" .. fontSize, {font = "fonts/n019003l.pfb"}),
		objectOverrideHintFont = WG.Chobby.Configuration:GetFont(fontSize, "Nimbus" .. fontSize),
		text = "",
	}

	function externalFunctions.Update(newPosition, newText, newImage, newColor, colorName, needDownload)
		if not textDisplay.visible then
			textDisplay:Show()
		end
		textDisplay:SetText(newText)
		textDisplay:SetPos(nil, newPosition)

		if newColor then
			textDisplay.font = WG.Chobby.Configuration:GetFont(fontSize, colorName, {font="fonts/n019003l.pfb", color = newColor})
			textDisplay:Invalidate()
		else
			textDisplay.font = WG.Chobby.Configuration:GetFont(fontSize, "Nimbus" .. fontSize, {font = "fonts/n019003l.pfb"})
		end

		if hasImage then
			if not imageDisplay.visible then
				imageDisplay:Show()
			end
			imageDisplay.file = newImage
			imageDisplay.checkFileExists = needDownload
			imageDisplay:SetPos(nil, newPosition - 3)
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
			imageDisplay:SetPos(nil, newPosition - 3)
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
		return #textDisplay.physicalLines or 1
	end

	function externalFunctions.GetFont()
		return textDisplay.font
	end

	return externalFunctions
end

--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- Battle tooltip
local battleTooltip = {}

local spadsRequestQueue = {}
local spadsRequest = nil
local allowedNextRequestClock = os.clock()

-- start/resume sending requests
-- executed on each update()
local function StartResumeSpadsRequest()
	if #spadsRequestQueue == 0 then
		return
	end

	local diff = os.clock() - allowedNextRequestClock
	if diff < 0 then
		return
	end

	-- pop most recent request
	spadsRequest = spadsRequestQueue[#spadsRequestQueue]

	-- empty request queue completly (we only want to ask for the most recent hovered battle)
	spadsRequestQueue = {}

	allowedNextRequestClock = os.clock() + 0.4

	if spadsRequest.battle.isRunning then
		lobby:RequestSpadsGameStatus(spadsRequest.battle.founder)
	else
		lobby:RequestSpadsBattleStatus(spadsRequest.battle.founder)
	end
end

local function OnUpdateBattleInfo(listener, _battleID, _battleInfo)
	-- validate input
	if not spadsRequest then
		return
	end

	local battle       =  spadsRequest.battle
	if battle.battleID ~= _battleID then
		return
	end
	local offset       = spadsRequest.offset

	_battleInfo = _battleInfo or {}
	if not (_battleInfo.thisGameStartedAt or _battleInfo.lastGameEndedAt) then
		return
	end

	-- end validation - it's about our request
	spadsRequest = nil

	local newMessage, elapsed
	if _battleInfo.thisGameStartedAt then
		elapsed = os.clock() - math.floor(_battleInfo.thisGameStartedAt + 0.5)
		newMessage = string.format("Running for %s", spFormatTime(elapsed, true)) -- ToDo: Replace with i18n

	elseif _battleInfo.lastGameEndedAt then
		if type(_battleInfo.lastGameEndedAt) == "string" and _battleInfo.lastGameEndedAt == "unknown" then
			newMessage = "First game for this lobby" -- ToDo: Replace with i18n
		else
			elapsed = os.clock() - math.floor(_battleInfo.lastGameEndedAt)
			newMessage = string.format("Last game ended %sago", spFormatTime(elapsed, true)) -- ToDo: Replace with i18n
		end
	end

	if tipWindow.visible and battleTooltip and battleTooltip.runningOrEndedAt and battleTooltip.battleID and battleTooltip.battleID == _battleID then
		battleTooltip.runningOrEndedAt.Update(offset, newMessage)
	end
end

local function QueueSpadsStatusRequest(battleID, offset)
	local battle = lobby:GetBattle(battleID)

	table.insert(spadsRequestQueue, {
		battle = battle,
		offset = offset,
	})
end

local function GetBattleTooltip(battleID, battle, showMapName)
	local Configuration = WG.Chobby.Configuration

	local width = 320
	if not battleTooltip.mainControl then
		battleTooltip.mainControl = Chili.Control:New {
			x = 0,
			y = 0,
			width = width,
			height = 120,
			padding = {0, 0, 7, 0},
		}
	end
	local offset = 7

	-- Battle Name
	if not battleTooltip.title then
		battleTooltip.title = GetTooltipLine(battleTooltip.mainControl, nil, 3)
	end
	--if battle.isMatchMaker then
	--	title = (title or "") .. " - Click to watch"
	--end
	battleTooltip.title.Update(offset, battle.title)
	offset = offset + 25 * battleTooltip.title.GetLines()

	-- Battle Type (ZK specific)
	-- if battle.battleMode then
	-- 	if not battleTooltip.battleMode then
	-- 		battleTooltip.battleMode = GetTooltipLine(battleTooltip.mainControl)
	-- 	end
	-- 	local modeName = Configuration.battleTypeToName[battle.battleMode]
	-- 	battleTooltip.battleMode.Update(offset, (modeName and i18n(modeName)) or "")
	-- 	offset = offset + 21
	-- elseif battleTooltip.battleMode then
	-- 	battleTooltip.battleMode.Hide()
	-- end

	-- MapName
	if showMapName and battle.mapName then
		if not battleTooltip.mapName then
			battleTooltip.mapName = GetTooltipLine(battleTooltip.mainControl)
		end
		battleTooltip.mapName.Update(offset, "Map: " .. battle.mapName)
		offset = offset + 21
	elseif battleTooltip.mapName then
		battleTooltip.mapName.Hide()
	end

	-- Players and Spectators
	if battle.spectatorCount and battle.maxPlayers and battle.users then
		if not battleTooltip.playerCount then
			battleTooltip.playerCount = GetTooltipLine(battleTooltip.mainControl)
		end
		battleTooltip.playerCount.Update(offset, "Players: " .. lobby:GetPlayerOccupancy(battleID))

		if not battleTooltip.spectatorCount then
			battleTooltip.spectatorCount = GetTooltipLine(battleTooltip.mainControl, nil, nil, 130)
		end
		battleTooltip.spectatorCount.Update(offset,"|    " .. "Spectators: " .. battle.spectatorCount)

		offset = offset + 21
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
				IMAGE_KEY
			)
		end
		battleTooltip.password.UpdatePosition(offset)
		offset = offset + 21
	elseif battleTooltip.password then
		battleTooltip.password.Hide()
	end

	-- Locked
	if battle.locked then
		if not battleTooltip.locked then
			battleTooltip.locked = GetTooltipLine(battleTooltip.mainControl, true)
			battleTooltip.locked.Update(
				offset,
				LOCKED_EXPLAINATION,
				IMAGE_LOCK
			)
		end
		battleTooltip.locked.UpdatePosition(offset)
		offset = offset + 21
	elseif battleTooltip.locked then
		battleTooltip.locked.Hide()
	end

	-- ingame
	if battle.isRunning and not (battle.locked or battle.passworded) then
		if not battleTooltip.isRunning then
			battleTooltip.isRunning = GetTooltipLine(battleTooltip.mainControl, true)
		end
		battleTooltip.isRunning.Update(
			offset,
			battle.isRunning and "Game in progress, join to spectate.",
			battle.isRunning and IMAGE_INGAME or IMAGE_BATTLE
		)
		battleTooltip.isRunning.UpdatePosition(offset)
		offset = offset + 20
	elseif battleTooltip.isRunning then 
		battleTooltip.isRunning.Hide()
	end

	if not battleTooltip.runningOrEndedAt then
		battleTooltip.runningOrEndedAt = GetTooltipLine(battleTooltip.mainControl)
	end

	local message = ""
	battleTooltip.battleID = battleID
	if battle.isRunning then

		message = "Fetching running time..."
		if not battle.thisGameStartedAt then
			QueueSpadsStatusRequest(battle.battleID, offset)
		else
			local elapsed = os.clock() - math.floor(battle.thisGameStartedAt)
			message = string.format("Running for %s", spFormatTime(elapsed, true)) -- ToDo: Replace with i18n
		end

	else -- battle not running

		message = "Fetching last ended time ..."
		if not battle.lastGameEndedAt then
			QueueSpadsStatusRequest(battle.battleID, offset)
		else
			if type(battle.lastGameEndedAt) == "string" and battle.lastGameEndedAt == "unknown" then
				message = "First game for this lobby"
			else
				local elapsed = os.clock() - math.floor(battle.lastGameEndedAt)
				message = string.format("Last game ended %sago", spFormatTime(elapsed, true))
			end
		end
	end
	battleTooltip.runningOrEndedAt.Update( offset, message)
	offset = offset + 21

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
			playerControl:SetPos(6, playerOffset)
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
				margin = {0,0,0,0},
				objectOverrideFont = Configuration:GetFont(10),
				objectOverrideHintFont = Configuration:GetFont(10),
				parent = battleTooltip.mainControl,
			}
		end
		battleTooltip.debugText:SetPos(nil, offset)

		if not battleTooltip.debugText.parent then
			battleTooltip.mainControl:AddChild(battleTooltip.debugText)
		end

		local text = ""
		local n = ""
		local st = sortfunc(battle)
		for _, kv in ipairs(st) do
			text = text .. n .. kv[1] .. " = " .. tostring(kv[2])
			n = "\n"
		end

		battleTooltip.debugText:SetText(text)
		battleTooltip.debugText:UpdateLayout()

		local numLines = #battleTooltip.debugText.physicalLines
		local height = numLines * Configuration.font[10].size
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

	-- Clan (ZK specific)
	-- if userInfo.clan then
	-- 	if not userTooltip.clan then
	-- 		userTooltip.clan = GetTooltipLine(userTooltip.mainControl, true)
	-- 	end
	-- 
	-- 	local clanFile, needDownload = WG.UserHandler.GetClanImage(userInfo.clan)
	-- 	userTooltip.clan.Update(offset, "Clan: " .. userInfo.clan, clanFile, nil, nil, needDownload)
	-- 	offset = offset + 20
	-- elseif userTooltip.clan then
	-- 	userTooltip.clan.Hide()
	-- end

	-- Disregard and Friend
	if userInfo.isDisregarded or userInfo.isFriend then
		if not userTooltip.friendIgnore then
			userTooltip.friendIgnore = GetTooltipLine(userTooltip.mainControl, true)
		end
		local statusText = ""
		local img = IMAGE_FRIEND
		if userInfo.isDisregarded then
			if userInfo.isDisregarded == Configuration.IGNORE then
				statusText = i18n("ignored_status")
				img = IMAGE_IGNORE
			elseif userInfo.isDisregarded == Configuration.AVOID then
				statusText = i18n("avoided_status")
				img = IMAGE_AVOID
			elseif userInfo.isDisregarded == Configuration.BLOCK then
				statusText = i18n("blocked_status")
				img = IMAGE_BLOCK
			end
			if userInfo.isFriend then
				statusText = statusText .. " & " .. i18n("friend_status")
			end
		else
			statusText = i18n("friend_status")
		end
		userTooltip.friendIgnore.Update(offset, statusText, img)
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
				Configuration:GetModeratorColor(),
				"tooltip_moderator"
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
				text = text .. " (σ=".. userInfo.skillUncertainty .. ")"
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


	-- ZK specific
	-- if userInfo.badges and Configuration.gameConfig.badges then
	-- 	if not userTooltip.badge then
	-- 		userTooltip.badge = {}
	-- 	end
	-- 	local badgeDecs = Configuration.gameConfig.badges
	-- 	local i = 1
	-- 	while i <= #userInfo.badges do
	-- 		if not userTooltip.badge[i] then
	-- 			userTooltip.badge[i] = GetTooltipLine(userTooltip.mainControl, true, nil, nil, 46)
	-- 		end
	-- 		local badgeData = badgeDecs[userInfo.badges[i]]
	-- 		if badgeData then
	-- 			userTooltip.badge[i].Update(
	-- 				offset,
	-- 				badgeData.text,
	-- 				badgeData.image
	-- 			)
	-- 			offset = offset + 20
	-- 		else
	-- 			userTooltip.badge[i]:Hide()
	-- 		end
	-- 		i = i + 1
	-- 	end
	-- 	while userTooltip.badge[i] do
	-- 		userTooltip.badge[i]:Hide()
	-- 		i = i + 1
	-- 	end
	-- elseif userTooltip.badge then
	-- 	local i = 1
	-- 	while userTooltip.badge[i] do
	-- 		userTooltip.badge[i]:Hide()
	-- 		i = i + 1
	-- 	end
	-- end

	-- InGameSince (ZK specific)
	-- if userInfo.inGameSince and userInfo.isInGame then
	-- 	if not userTooltip.inGameSince then
	-- 		userTooltip.inGameSince = GetTooltipLine(userTooltip.mainControl, true)
	-- 	end
	-- 	userTooltip.inGameSince.Update(
	-- 		offset,
	-- 		"In game for " .. Spring.Utilities.GetTimeToPast(userInfo.inGameSince, true),
	-- 		IMAGE_INGAME
	-- 	)
	-- 	offset = offset + 20
	-- elseif userTooltip.inGameSince then
	-- 	userTooltip.inGameSince:Hide()
	-- end

	-- Away Since (ZK specific)
	-- if userInfo.awaySince and userInfo.isAway then
	-- 	if not userTooltip.awaySince then
	-- 		userTooltip.awaySince = GetTooltipLine(userTooltip.mainControl, true)
	-- 	end
	-- 	userTooltip.awaySince.Update(
	-- 		offset,
	-- 		"Idle for " .. Spring.Utilities.GetTimeToPast(userInfo.awaySince, true),
	-- 		IMAGE_AFK
	-- 	)
	-- 	offset = offset + 20
	-- elseif userTooltip.awaySince then
	-- 	userTooltip.awaySince:Hide()
	-- end

	-- In Battle
	if (not inBattleroom) and userInfo.battleID and lobby:GetBattle(userInfo.battleID) then
		local battle = lobby:GetBattle(userInfo.battleID)

		if not userTooltip.battleInfoHolder then
			userTooltip.battleInfoHolder = Chili.Control:New {
				x = 0,
				y = offset,
				width = 320,
				height = 120,
				padding = {0, 0, 0, 0},
				parent = userTooltip.mainControl,
			}
		else
			userTooltip.battleInfoHolder:Show()
		end

		local battleOffset = 0

		-- show minimap inside user tooltip ?
		-- if not userTooltip.runningImage then
		-- 	userTooltip.runningImage = Image:New {
		-- 		name = "runningImage",
		-- 		x = 6,
		-- 		y = battleOffset,
		-- 		width = 70,
		-- 		height = 70,
		-- 		keepAspect = false,
		-- 		file = BATTLE_RUNNING,
		-- 		parent = userTooltip.battleInfoHolder,
		-- 	}
		-- end
		-- userTooltip.runningImage:SetVisibility(battle.isRunning == true)
-- 
		-- local mapImageFile, needDownload = Configuration:GetMinimapSmallImage(battle.mapName)
		-- if not userTooltip.minimapImage then
		-- 	userTooltip.minimapImage = Image:New {
		-- 		name = "minimapImage",
		-- 		x = 6,
		-- 		y = battleOffset,
		-- 		width = 70,
		-- 		height = 70,
		-- 		valign = 'top',
		-- 		keepAspect = true,
		-- 		file = mapImageFile,
		-- 		fallbackFile = Configuration:GetLoadingImage(2),
		-- 		checkFileExists = needDownload,
		-- 		parent = userTooltip.battleInfoHolder,
		-- 	}
		-- end
		-- userTooltip.minimapImage.file = mapImageFile
		-- userTooltip.minimapImage.fallbackFile = Configuration:GetLoadingImage(2)
		-- userTooltip.minimapImage.checkFileExists = needDownload
		-- userTooltip.minimapImage:Invalidate()
		-- offset = offset + 25
		-- battleOffset = battleOffset + 25
-- 
		-- if not userTooltip.lblMap then
		-- 	userTooltip.lblMap = Label:New {
		-- 		name = "mapCaption",
		-- 		x = 6 + 70 + 5,
		-- 		y = battleOffset,
		-- 		right = 5,
		-- 		height = 20,
		-- 		valign = 'center',
		-- 		caption = battle.mapName:sub(1, 22),
		-- 		objectOverrideFont = WG.Chobby.Configuration:GetFont(9),
		-- 		parent = userTooltip.battleInfoHolder,
		-- 		OnResize = {
		-- 			function (obj, xSize, ySize)
		-- 				if battle then
		-- 					obj:SetCaption(StringUtilities.GetTruncatedStringWithDotDot(battle.mapName, obj.font, obj.width))
		-- 				end
		-- 			end
		-- 		}
		-- 	}
		-- end
		-- userTooltip.lblMap:SetCaption(battle.mapName:sub(1, 22))
		-- offset = offset + 45
		-- battleOffset = battleOffset + 45

		if not userTooltip.battleTooltipHolder then
			userTooltip.battleTooltipHolder = Chili.Control:New {
				x = 0,
				y = battleOffset,
				width = 320,
				height = 120,
				padding = {0, 0, 0, 0},
				parent = userTooltip.battleInfoHolder,
			}
		else
			userTooltip.battleTooltipHolder:ClearChildren()
			userTooltip.battleTooltipHolder:Show()
		end

		local battleTooltipControl = GetBattleTooltip(userInfo.battleID, battle, true)
		userTooltip.battleTooltipHolder:AddChild(battleTooltipControl)
		local battleHeight = battleTooltipControl.clientHeight
		local battleWidth = battleTooltipControl.clientWidth
		userTooltip.battleTooltipHolder:SetPos(nil, nil, battleWidth, battleHeight)

		offset = offset + battleHeight
		battleOffset = battleOffset + battleHeight
		width = math.max(width, battleWidth)
		userTooltip.battleInfoHolder:SetPos(nil, nil, width, battleOffset)
	elseif userTooltip.battleInfoHolder then
		userTooltip.battleInfoHolder:Hide()
	end

	-- Debug Mode
	if Configuration.debugMode then

		if not userTooltip.debugText then
			userTooltip.debugText = Chili.TextBox:New{
				x      = width,
				y      = 7,
				right  = 5,
				minWidth = 160,
				maxWidth = 320,
				autosize = true,
				bottom = 5,
				margin = {0,0,0,0},
				objectOverrideFont = Configuration:GetFont(10),
				objectOverrideHintFont = Configuration:GetFont(10),
				parent = userTooltip.mainControl,
			}
		end
		userTooltip.debugText:SetPos(width, 7)

		if not userTooltip.debugText.parent then
			userTooltip.mainControl:AddChild(userTooltip.debugText)
		end


		local st = sortfunc(userInfo)
		local n = ""
		local text = ""
		for _, kv in ipairs(st) do
			text = text .. n .. kv[1] .. " = " .. tostring(kv[2])
			n = "\n"
		end
		if next(userBattleInfo) then
			text = text .. "\n" .. "----------------"
			st = sortfunc(userBattleInfo)
			for _, kv in ipairs(st) do
				text = text .. "\n" .. kv[1] .. " = " .. tostring(kv[2])
			end
		end

		userTooltip.debugText:SetText(text)
		local numLines = #userTooltip.debugText.physicalLines
		local height = numLines * Configuration.font[10].size + 7
		offset = math.max(offset, height)
		width = width + userTooltip.debugText.clientWidth + 5 + 6
	elseif userTooltip.debugText and userTooltip.debugText.parent then
		userTooltip.mainControl:RemoveChild(userTooltip.debugText)
	end

	-- Set tooltip sizes
	userTooltip.mainControl:SetPos(nil, nil, width, offset)

	return userTooltip.mainControl
end

--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- Replay tooltip

-- demos may have no skill values
local function SortPlayersBySkill(a, b)
	local skillA = tonumber(a.skill)
	local skillB = tonumber(b.skill)
	return (skillA and skillB and skillA > skillB) or false
end

local function SortTeamsBySkill(a, b)
	local skillA = tonumber(a[1].skill)
	local skillB = tonumber(b[1].skill)
	return (skillA and skillB and skillA > skillB) or false
end

local replayTooltip = {}
local PLAYERWIDTH, PLAYERHEIGHT = 220, 22

local function getReplayPlayerListTooltip(teamList)

	local showTeams = true
	if #teamList > 2 then
		showTeams = false -- assume ffa 
		for i = 1, #teamList do
			if #teamList[i] > 1 then -- no, it's teamFFA
				showTeams = true
			end
		end
	end

	local cols = #teamList
	local divisor
	if showTeams then
		cols = math.ceil(#teamList / math.ceil(#teamList / 4))
	else
		if #teamList < 33 then
			divisor = 8 -- max 4 columns
		else
			divisor = 16 -- big ffas are difficult to handle
		end
		cols = math.ceil(#teamList / divisor)

		table.sort(teamList, SortTeamsBySkill)
	end

	if (cols ~= cols) then
		cols = 0
	end

	replayTooltip.mainStackPanel = Panel:New {
			name = 'mainStackPanel',
			x = 0,
			y = 0,
			width = cols * PLAYERWIDTH,
		}

	local xOffsetTeam = 0
	local yOffsetTeam = 0
	local function newTeamStack()
		return Control:New {
			x = xOffsetTeam,
			y = yOffsetTeam,
			autosize = true,
			padding = {0, 0, 0, 0},
			parent = replayTooltip.mainStackPanel,
		}
	end

	local xOffsetPlayer = 0
	local yOffsetPlayer = 0
	local yOffsetTeamMax = 0
	local teamStack
	local prevRowHeightMax = 0
	local totalHeight = 0

	for teamNr = 1, #teamList do

		local players = teamList[teamNr]
		table.sort(players, SortPlayersBySkill)

		if showTeams or teamNr == 1 then
			xOffsetTeam = (teamNr - 1) % cols * PLAYERWIDTH
			if xOffsetTeam == 0 then
				prevRowHeightMax = yOffsetTeamMax
				totalHeight = totalHeight + prevRowHeightMax + math.floor((teamNr - 1) / cols) * 23
				yOffsetTeamMax = 0
			end
			yOffsetTeam = math.floor((teamNr - 1) / cols) * (prevRowHeightMax + 23)

			teamStack = newTeamStack()

			-- team title
			if not teamStack.teamTitle then
				teamStack.teamTitle = GetTooltipLine(teamStack, nil, 3)
			end
			local teamTitle = ""
			if showTeams then
				teamTitle = "Team " .. tostring(teamNr) .. " (" .. #teamList[teamNr] .. ")"
			else
				teamTitle = "FFA (" .. #teamList .. ")"
			end
			local truncatedTitle = StringUtilities.GetTruncatedStringWithDotDot(teamTitle, teamStack.teamTitle.GetFont(), PLAYERWIDTH - 10)
			teamStack.teamTitle.Update(0, truncatedTitle)

			yOffsetPlayer = 23
		else
			xOffsetPlayer = math.floor((teamNr - 1) / divisor)  * PLAYERWIDTH
			yOffsetPlayer = 23 + (teamNr-1) % divisor * PLAYERHEIGHT
		end

		for playerNr = 1, #teamList[teamNr] do
			local playerHolder = Control:New {
				x = xOffsetPlayer,
				y = yOffsetPlayer,
				width = PLAYERWIDTH,
				height = PLAYERHEIGHT,
				padding = {0, 0, 0, 0},
				parent = teamStack,
			}

			local playerControl = WG.UserHandler.GetReplayTooltipUser(teamList[teamNr][playerNr], PLAYERWIDTH)
			playerHolder:AddChild(playerControl)

			yOffsetPlayer = yOffsetPlayer + PLAYERHEIGHT
			yOffsetTeamMax = math.max(yOffsetTeamMax, yOffsetPlayer)
		end

	end
	totalHeight = totalHeight + yOffsetTeamMax

	-- Set tooltip sizes

	replayTooltip.mainStackPanel:SetPos(nil, nil, cols * PLAYERWIDTH, totalHeight + 5)

	return replayTooltip.mainStackPanel
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
	local Configuration = WG.Chobby.Configuration
	if inputText:starts(Configuration.USER_TOOLTIP_PREFIX) then
		local userName = string.sub(inputText, 13)
		local myLobby, inBattleroom
		if inputText:starts(Configuration.USER_SP_TOOLTIP_PREFIX) then
			myLobby = WG.LibLobby.localLobby
			inBattleroom = true
		else
			myLobby = lobby
			if inputText:starts(Configuration.USER_MP_TOOLTIP_PREFIX) then
				inBattleroom = true
			end
		end
		local userInfo = myLobby:TryGetUser(userName)
		local userBattleInfo = myLobby:GetUserBattleStatus(userName) or {}

		local tooltipControl = GetUserTooltip(userName, userInfo, userBattleInfo, inBattleroom)

		tipWindow:ClearChildren()
		tipWindow:AddChild(tooltipControl)

	elseif inputText:starts(Configuration.BATTLE_TOOLTIP_PREFIX) then
		local battleID = tonumber(string.sub(inputText, 16))
		local battle = lobby:GetBattle(battleID)
		if battle then
			local tooltipControl = GetBattleTooltip(battleID, battle)

			tipWindow:ClearChildren()
			tipWindow:AddChild(tooltipControl)
		end
	elseif inputText:starts(Configuration.MINIMAP_TOOLTIP_PREFIX) then
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
	elseif inputText:starts(Configuration.REPLAY_TOOLTIP_PREFIX) then
		local replayPath = string.sub(inputText, 16)
		local replayControl = WG.ReplayHandler.GetReplayById(replayPath)
		local tooltipControl = getReplayPlayerListTooltip(replayControl.teams)
		tipWindow:ClearChildren()
		tipWindow:AddChild(tooltipControl)
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
	StartResumeSpadsRequest()
end

function widget:Initialize()
	CHOBBY_DIR = LUA_DIRNAME .. "widgets/chobby/"
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	InitWindow()
	WG.TooltipHandler = TooltipHandler
	lobby:AddListener("OnUpdateBattleInfo", OnUpdateBattleInfo)
end

function widget:Shutdown()
	lobby:RemoveListener("OnUpdateBattleInfo", OnUpdateBattleInfo)
	tipWindow:Dispose()
end

