--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Planetwars List Window",
		desc      = "Handles planetwars battle list display.",
		author    = "GoogleFrog",
		date      = "7 March 2017",
		license   = "GNU LGPL, v2.1 or later",
		layer     = -100000,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Variables

local planetwarsSoon = false
local planetwarsEnabled = false
local planetwarsLevelRequired = false

local IMG_LINK = LUA_DIRNAME .. "images/link.png"

local panelInterface
local PLANET_NAME_LENGTH = 210
local FACTION_SPACING = 156

local phaseTimer
local requiredGame = false

local URGENT_ATTACK_TIME = 3000 -- Fifty minutes
local attackUrgent = false

local MISSING_ENGINE_TEXT = "Game engine update required, restart the menu to apply."
local MISSING_GAME_TEXT = "Game version update required. Wait for a download or restart to apply it immediately."
local PW_SOON_TEXT = "Planetwars is starting soon. "

local updates = 0

local ATTACKER_SOUND = "sounds/marker_place.wav"
local DEFENDER_SOUND = "sounds/alarm.wav"

local DoUnMatchedActivityUpdate -- Activity update function

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utilities

local function HaveRightEngineVersion()
	local configuration = WG.Chobby.Configuration
	if configuration.useWrongEngine then
		return true
	end
	local engineVersion = WG.LibLobby.lobby:GetSuggestedEngineVersion()
	return (not engineVersion) or configuration:IsValidEngineVersion(engineVersion)
end

local function HaveRightGameVersion()
	if not requiredGame then
		return false
	end
	local haveGame = VFS.HasArchive(requiredGame)
	return haveGame
end

local function TryToJoinPlanet(planetData)
	local lobby = WG.LibLobby.lobby

	local mapName = planetData.Map
	if not VFS.HasArchive(mapName) then
		queuePlanetJoin = planetData
		WG.DownloadHandler.MaybeDownloadArchive(mapName, "map", -1)
		WG.Chobby.InformationPopup("Map download required to attack planet. Please wait.")
		return
	end
	queuePlanetJoin = nil

	if not HaveRightEngineVersion() then
		WG.Chobby.InformationPopup("Game engine update required, restart the menu to apply.")
		return
	end

	if not HaveRightGameVersion() then
		WG.Chobby.InformationPopup("Game version update required, restart the menu to apply.")
		return
	end

	lobby:PwJoinPlanet(planetData.PlanetID)
	if panelInterface then
		panelInterface.SetPlanetJoined(planetData.PlanetID)
	end
	WG.Analytics.SendOnetimeEvent("lobby:multiplayer:planetwars:join_site")
end

local function GetAttackingOrDefending(lobby, attackerFaction, defenderFactions)
	local myFaction = lobby:GetMyFaction()
	local attacking = (myFaction == attackerFaction)
	local defending = false
	if defenderFactions then
		for i = 1, #defenderFactions do
			if myFaction == defenderFactions[i] then
				return attacking, true
			end
		end
	end
	return attacking, false
end

local function IsAttackUrgent()
	local timeRemaining = phaseTimer and phaseTimer.GetTimeRemaining()
	return timeRemaining and timeRemaining < URGENT_ATTACK_TIME
end

local function GetActivityToPrompt(lobby, attackerFaction, defenderFactions, currentMode, planets)
	if not (planets and planets[1]) then
		return false
	end

	if lobby.planetwarsData.attackingPlanet and planets then
		local planetID = lobby.planetwarsData.attackingPlanet
		for i = 1, #planets do
			if planets[i].PlanetID == planetID then
				return planets[i], true, true, false
			end
		end
		return false
	end

	local attacking, defending = GetAttackingOrDefending(lobby, attackerFaction, defenderFactions)

	if lobby.planetwarsData.joinPlanet and planets then
		local planetID = lobby.planetwarsData.joinPlanet
		for i = 1, #planets do
			if planets[i].PlanetID == planetID then
				return planets[i], attacking, true, true
			end
		end
		return false
	end

	attacking, defending = (currentMode == lobby.PW_ATTACK) and attacking, (currentMode == lobby.PW_DEFEND) and defending

	if attacking then
		if IsAttackUrgent() then
			local attackPlanet, attackMissing
			for i = 1, #planets do
				local missingPlayers = planets[i].Needed - planets[i].Count
				if (not attackMissing) or (missingPlayers < attackMissing) then
					attackPlanet = planets[i]
					attackMissing = missingPlayers
				end
			end
			return attackPlanet, true
		else
			for i = 1, #planets do
				if planets[i].Count + 1 == planets[i].Needed then
					return planets[i], true
				end
			end
		end
	elseif defending then
		return planets[1], false
	end
	return false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Timing

local function GetPhaseTimer()
	local deadlineSeconds
	local startTimer

	local externalFunctions = {}

	function externalFunctions.SetNewDeadline(newDeadlineSeconds)
		deadlineSeconds = newDeadlineSeconds
		startTimer = Spring.GetTimer()
	end

	function externalFunctions.GetTimeRemaining()
		if not deadlineSeconds then
			return false
		end
		return math.max(0, deadlineSeconds - math.ceil(Spring.DiffTimers(Spring.GetTimer(), startTimer)))
	end

	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Extended Controls

local function GetLinkButton(holder, x, y, width, text, link)
	local config = WG.Chobby.Configuration

	local btnLink = Button:New {
		x = x,
		y = t,
		width = width,
		height = 24,
		classname = "button_square",
		caption = "",
		padding = {0, 0, 0, 0},
		parent = holder,
		OnClick = {
			function ()
				WG.BrowserHandler.OpenUrl(link)
			end
		},
		--tooltip = link,
	}
	local tbText = TextBox:New {
		x = 2,
		y = 3,
		right = 20,
		align = "left",
		fontsize = config:GetFont(3).size,
		parent = btnLink,
	}
	local imgLink = Image:New {
		x = 0,
		y = 4,
		width = 18,
		height = 18,
		keepAspect = true,
		file = IMG_LINK,
		parent = btnLink,
	}

	local externalFunctions = {}

	function externalFunctions.SetText(newText)
		newText = StringUtilities.GetTruncatedStringWithDotDot(newText, tbText.font, width - 24)
		tbText:SetText(newText)
		local length = tbText.font:GetTextWidth(newText)
		imgLink:SetPos(length + 7)
	end

	function externalFunctions.GetControl()
		return btnLink
	end

	-- Initialization
	externalFunctions.SetText(text)

	return externalFunctions
end

local function GetPlanetImage(holder, x, y, size, planetImage, structureList)
	local children = {}

	if structureList then
		for i = 1, #structureList do
			children[#children + 1] = Image:New {
				x = 0,
				y = 0,
				right = 0,
				bottom = 0,
				keepAspect = true,
				file = "LuaMenu/images/structures/" .. structureList[i],
			}
		end
	end

	local planetImageControl

	if planetImage then
		planetImageControl = Image:New {
			x = "25%",
			y = "25%",
			right = "25%",
			bottom = "25%",
			keepAspect = true,
			file = "LuaMenu/images/planets/" .. planetImage,
		}
		children[#children + 1] = planetImageControl
	end

	local imagePanel = Panel:New {
		classname = "panel_light",
		x = x,
		y = y,
		width = size,
		height = size,
		padding = {1,1,1,1},
		children = children,
		parent = holder,
	}

	return imagePanel
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Battle Nagger

local function InitializeActivityPromptHandler()
	local lobby = WG.LibLobby.lobby
	local Configuration = WG.Chobby.Configuration
	local planetData

	local planetID
	local planetImage
	local planetImageSize = 77
	local oldIsAttacker = false
	local newNotification = true

	local holder = Panel:New {
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		classname = "overlay_panel",
		padding = {0,0,0,0},
		caption = "",
		resizable = false,
		draggable = false,
	}

	local button = Button:New {
		name = "join",
		x = "70%",
		right = 4,
		y = 4,
		bottom = 4,
		padding = {0,0,0,0},
		caption = "Join",
		font = Configuration:GetFont(3),
		classname = "action_button",
		OnClick = {
			function()
				if planetData then
					TryToJoinPlanet(planetData)
				end
			end
		},
		parent = holder,
	}

	local bottomBound = 5
	local bigMode = true

	local planetStatusTextBox = TextBox:New {
		x = 20,
		y = 18,
		width = 195,
		height = 20,
		fontsize = Configuration:GetFont(2).size,
		text = "",
		parent = holder
	}
	local battleStatusTextBox = TextBox:New {
		x = 38,
		y = 18,
		width = 195,
		height = 20,
		fontsize = Configuration:GetFont(2).size,
		text = "",
		parent = holder
	}
	local battleStatusText = ""

	local seperator = Line:New {
		x = 0,
		y = 25,
		width = 195,
		height = 2,
		parent = holder
	}

	local oldXSize, oldYSize
	local function Resize(obj, xSize, ySize)
		if xSize then
			oldXSize, oldYSize = xSize, ySize
		elseif not oldXSize then
			return
		else
			xSize, ySize = oldXSize, oldYSize
		end
		local statusX, statusWidth = 2, 195
		planetImageSize = ySize - 2
		if planetImage then
			planetImage:SetPos(1, 1, planetImageSize, planetImageSize)
			statusX = ySize - 5
		end

		if ySize < 60 then
			planetStatusTextBox:SetPos(statusX + xSize/4 - 52, 2, statusWidth)
			seperator:SetPos(statusX + xSize/4 - 60, 14, statusWidth)
			battleStatusTextBox:SetPos(statusX + xSize/4 - 52, 20, statusWidth)
			bigMode = false
		else
			planetStatusTextBox:SetPos(statusX + xSize/4 - 62, 18, statusWidth)
			seperator:SetPos(statusX + xSize/4 - 70, 34, statusWidth)
			battleStatusTextBox:SetPos(statusX + xSize/4 - 62, 44, statusWidth)
			bigMode = true
		end
	end

	local function PossiblyPlayWarning(isAttacker)
		if (not newNotification) and isAttacker == oldIsAttacker then
			return
		end
		newNotification = false
		oldIsAttacker = isAttacker
		if not Configuration.planetwarsNotifications then
			return
		end
		if WG.WrapperLoopback then
			if isAttacker then
				WG.WrapperLoopback.Alert("Planetwars: attack a planet.")
			else
				WG.WrapperLoopback.Alert("Planetwars: defense required!")
			end
		end

		local snd_volui = Spring.GetConfigString("snd_volui")
		local snd_volmaster = Spring.GetConfigString("snd_volmaster")
		-- These are defaults. Should be audible enough.
		Spring.SetConfigString("snd_volui", 100)
		Spring.SetConfigString("snd_volmaster", 60)
		if Configuration.menuNotificationVolume ~= 0 then
			Spring.PlaySoundFile((isAttacker and ATTACKER_SOUND) or DEFENDER_SOUND, Configuration.menuNotificationVolume or 1, "ui")
		end
		WG.Delay(function()
			Spring.SetConfigString("snd_volui", snd_volui)
			Spring.SetConfigString("snd_volmaster", snd_volmaster)
		end, 10)

	end

	holder.OnResize = {Resize}

	local externalFunctions = {}

	local oldTimeRemaing = ""
	function externalFunctions.UpdateTimer(forceUpdate)
		local timeRemaining = phaseTimer.GetTimeRemaining()
		timeRemaining = (timeRemaining and Spring.Utilities.FormatTime(timeRemaining, false)) or ""
		if timeRemaining == oldTimeRemaing and (not forceUpdate) then
			return
		end
		oldTimeRemaing = timeRemaining

		battleStatusTextBox:SetText(battleStatusText .. timeRemaining)
	end

	function externalFunctions.SetActivity(newPlanetData, isAttacker, alreadyJoined, waitingForAllies)
		planetData = newPlanetData
		PossiblyPlayWarning(isAttacker)
		if alreadyJoined then
			if isAttacker then
				planetStatusTextBox:SetText("Attacking: " .. planetData.PlanetName)
				if waitingForAllies then
					battleStatusText = "Attackers " .. newPlanetData.Count .. "/" .. newPlanetData.Needed .. ", "
				else
					battleStatusText = "Defenders " .. newPlanetData.Count .. "/" .. newPlanetData.Needed .. ", "
				end
			else
				planetStatusTextBox:SetText("Defending: " .. planetData.PlanetName)
				battleStatusText = "Defenders " .. newPlanetData.Count .. "/" .. newPlanetData.Needed .. ", "
			end
		else
			if isAttacker then
				planetStatusTextBox:SetText("Attack: " .. planetData.PlanetName)
				battleStatusText = "Players " .. newPlanetData.Count .. "/" .. newPlanetData.Needed .. ", "
			else
				planetStatusTextBox:SetText("Defend: " .. planetData.PlanetName)
				battleStatusText = "Players " .. newPlanetData.Count .. "/" .. newPlanetData.Needed .. ", "
			end
		end

		externalFunctions.UpdateTimer(true)

		button:SetVisibility(not alreadyJoined)

		if alreadyJoined then
			if planetID ~= newPlanetData.PlanetID then
				if planetImage then
					planetImage:Dispose()
				end
				planetImage = GetPlanetImage(holder, 1, 1, planetImageSize, newPlanetData.PlanetImage, newPlanetData.StructureImages)
			end
		elseif planetImage then
			planetImage:Dispose()
			planetImage = nil
		end

		Resize()
	end

	function externalFunctions.NotifyHidden()
		newNotification = true
	end

	function externalFunctions.GetHolder()
		return holder
	end

	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Planet List

local function MakePlanetControl(planetData, DeselectOtherFunc, attacking, defending)
	local Configuration = WG.Chobby.Configuration
	local lobby = WG.LibLobby.lobby

	local config = WG.Chobby.Configuration
	local mapName = planetData.Map
	local planetID = planetData.PlanetID

	local joinedBattle = false
	local downloading = false
	local currentPlayers = planetData.Count or 0
	local maxPlayers = planetData.Needed or 0

	local btnJoin

	local holder = Panel:New {
		x = 0,
		y = 0,
		width = "100%",
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
	}

	local planetImage = GetPlanetImage(holder, 2, 2, 86, planetData.PlanetImage, planetData.StructureImages)

	local minimapPanel = Panel:New {
		x = 100,
		y = 5,
		width = 26,
		height = 26,
		padding = {1,1,1,1},
		parent = holder,
	}
	local btnMinimap = Button:New {
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		classname = "button_square",
		caption = "",
		parent = minimapPanel,
		padding = {1,1,1,1},
		OnClick = {
			function ()
				if mapName and config.gameConfig.link_particularMapPage ~= nil then
					WG.BrowserHandler.OpenUrl(config.gameConfig.link_particularMapPage(mapName))
				end
			end
		},
	}

	local mapImageFile, needDownload = config:GetMinimapSmallImage(mapName)
	local imMinimap = Image:New {
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		keepAspect = true,
		file = mapImageFile,
		fallbackFile = Configuration:GetLoadingImage(2),
		checkFileExists = needDownload,
		parent = btnMinimap,
	}

	local btnPlanetLink = Button:New {
		x = 130,
		y = 7,
		width = PLANET_NAME_LENGTH,
		height = 24,
		classname = "button_square",
		caption = "",
		padding = {0, 0, 0, 0},
		parent = holder,
		OnClick = {
			function ()
				WG.BrowserHandler.OpenUrl("http://zero-k.info/Planetwars/Planet/" .. planetID)
			end
		}
	}
	local tbPlanetName = TextBox:New {
		x = 2,
		y = 3,
		right = 20,
		align = "left",
		fontsize = config:GetFont(3).size,
		parent = btnPlanetLink,
	}
	local imgPlanetLink = Image:New {
		x = 0,
		y = 4,
		width = 18,
		height = 18,
		keepAspect = true,
		file = IMG_LINK,
		parent = btnPlanetLink,
	}

	local playerCaption = TextBox:New {
		name = "missionName",
		x = 270,
		y = 54,
		width = 350,
		height = 20,
		valign = 'center',
		fontsize = Configuration:GetFont(3).size,
		text = "0/0",
		parent = holder,
	}

	local function SetPlanetName(newPlanetName)
		newPlanetName = StringUtilities.GetTruncatedStringWithDotDot(newPlanetName, tbPlanetName.font, PLANET_NAME_LENGTH - 24)
		tbPlanetName:SetText(newPlanetName)
		local length = tbPlanetName.font:GetTextWidth(newPlanetName)
		imgPlanetLink:SetPos(length + 7)
	end

	local function UpdatePlayerCaption()
		if joinedBattle then
			playerCaption:SetText("Joined - Waiting for players: " .. currentPlayers .. "/" .. maxPlayers)
		else
			playerCaption:SetText(currentPlayers .. "/" .. maxPlayers)
		end
	end

	local function UpdateJoinButton()
		if not (attacking or defending) then
			playerCaption:SetPos(104)
			UpdatePlayerCaption()
			btnJoin:SetVisibility(false)
			return
		end

		if joinedBattle then
			playerCaption:SetPos(104)
		else
			playerCaption:SetPos(270)
			local haveMap = VFS.HasArchive(mapName)
			if haveMap then
				if attacking then
					btnJoin:SetCaption(i18n("attack_planet"))
				elseif defending then
					btnJoin:SetCaption(i18n("defend_planet"))
				end
			else
				if downloading then
					btnJoin:SetCaption(i18n("downloading"))
				else
					btnJoin:SetCaption(i18n("download_map"))
				end
			end
		end
		UpdatePlayerCaption()
		btnJoin:SetVisibility(not joinedBattle)
	end

	btnJoin = Button:New {
		x = 100,
		width = 160,
		bottom = 6,
		height = 45,
		caption = i18n("defend_planet"),
		font = Configuration:GetFont(3),
		classname = "option_button",
		OnClick = {
			function(obj)
				if not VFS.HasArchive(mapName) then
					if not downloading then
						WG.DownloadHandler.MaybeDownloadArchive(mapName, "map", -1)
						downloading = true
						UpdateJoinButton()
					end
					return
				end

				if not HaveRightEngineVersion() then
					WG.Chobby.InformationPopup("Engine update required, restart the game to apply.")
					return
				end

				if not HaveRightGameVersion() then
					WG.Chobby.InformationPopup("Version update required, restart the game to apply.")
					return
				end

				joinedBattle = true
				lobby:PwJoinPlanet(planetID)
				UpdateJoinButton()
				DeselectOtherFunc(planetID)
				WG.Analytics.SendOnetimeEvent("lobby:multiplayer:planetwars:join")
			end
		},
		parent = holder
	}

	-- Initialization
	SetPlanetName(planetData.PlanetName)
	UpdateJoinButton()

	local externalFunctions = {}

	function externalFunctions.UpdatePlanetControl(newPlanetData, newAttacking, newDefending, resetJoinedBattle)
		mapName = newPlanetData.Map
		currentPlayers = newPlanetData.Count or 0
		maxPlayers = newPlanetData.Needed or 0

		if resetJoinedBattle then
			joinedBattle = false
		end

		attacking, defending = newAttacking, newDefending

		if planetID ~= newPlanetData.PlanetID then
			planetImage:Dispose()
			planetImage = GetPlanetImage(holder, 2, 2, 86, newPlanetData.PlanetImage, newPlanetData.StructureImages)

			imMinimap.file, imMinimap.checkFileExists = config:GetMinimapSmallImage(mapName)
			imMinimap:Invalidate()

			SetPlanetName(newPlanetData.PlanetName)
		end
		planetID = newPlanetData.PlanetID

		UpdateJoinButton()
	end

	function externalFunctions.CheckDownload()
		if not holder.visible then
			return
		end
		UpdateJoinButton()
	end

	function externalFunctions.Deselect(exceptionPlanetID)
		if (not holder.visible) or (planetID == exceptionPlanetID) then
			return
		end
		if joinedBattle then
			joinedBattle = false
			UpdateJoinButton()
		end
	end

	function externalFunctions.GetControl()
		return holder
	end

	function externalFunctions.SetPlanetJoinedIfIDMatches(checkPlanetID)
		if (not holder.visible) or (planetID ~= checkPlanetID) then
			return
		end

		joinedBattle = true
		UpdateJoinButton()
		DeselectOtherFunc(planetID)
	end

	return externalFunctions
end

local function GetPlanetList(parentControl)

	local planets = {}

	local function DeselectPlanets(exceptionPlanetID)
		for i = 1, #planets do
			planets[i].Deselect(exceptionPlanetID)
		end
	end

	local sortableList = WG.Chobby.SortableList(parentControl, nil, 90, 1)

	local externalFunctions = {}

	function externalFunctions.SetPlanetList(newPlanetList, attacking, defending, modeSwitched)
		if modeSwitched then
			queuePlanetJoin = nil
		end
		sortableList:Clear()
		local items = {}
		if newPlanetList then
			for i = 1, #newPlanetList do
				if planets[i] then
					planets[i].UpdatePlanetControl(newPlanetList[i], attacking, defending, modeSwitched)
				else
					planets[i] = MakePlanetControl(newPlanetList[i], DeselectPlanets, attacking, defending, modeSwitched)
				end
				items[i] = {i, planets[i].GetControl()}
			end
			sortableList:AddItems(items)
		end
	end

	function externalFunctions.CheckDownload()
		for i = 1, #planets do
			planets[i].CheckDownload()
		end
	end

	function externalFunctions.SetPlanetJoined(planetID)
		for i = 1, #planets do
			planets[i].SetPlanetJoinedIfIDMatches(planetID)
		end
	end

	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Faction Selection

local function MakeFactionSelector(parent, x, y, SelectionFunc, CancelFunc, right, bottom)
	local Configuration = WG.Chobby.Configuration

	local factionText = VFS.Include(LUA_DIRNAME .. "configs/planetwars/factionText.lua") or {}

	local lobby = WG.LibLobby.lobby
	local factionList = lobby and lobby.planetwarsData.factionList
	if not (lobby or factionList) then
		return
	end

	local HolderType = (right and bottom and ScrollPanel) or Control

	local offset = 0
	local holder = HolderType:New {
		x = x,
		y = y,
		width = not (right and bottom) and 400,
		right = right,
		bottom = bottom,
		height = (#factionList)*FACTION_SPACING + 40,
		horizontalScrollbar = false,
		padding = (right and bottom and {5, 5, 5, 5}) or {0, 0, 0, 0},
		parent = parent,
	}

	local startIndex, endIndex, direction = 1, #factionList, 1
	if updates%2 == 0 then
		startIndex, endIndex, direction = #factionList, 1, -1
	end

	for i = startIndex, endIndex, direction do
		local shortname = factionList[i].Shortcut
		local name = factionList[i].Name
		local factionData = factionText[shortname] or {}

		if factionData.imageLarge then
			Image:New {
				x = 2,
				y = offset + 5,
				width = 128,
				height = 128,
				keepAspect = true,
				file = factionData.imageLarge,
				parent = holder,
			}
		end

		Button:New {
			x = 140,
			y = offset,
			width = 260,
			height = 45,
			caption = "Join " .. name,
			font = Configuration:GetFont(3),
			classname = "action_button",
			OnClick = {
				function()
					lobby:JoinFactionRequest(shortname)
					if SelectionFunc then
						SelectionFunc()
					end
				end
			},
			parent = holder,
		}

		if factionData.motto and factionData.desc then
			TextBox:New {
				x = 140,
				y = offset + 56,
				width = 240,
				height = 45,
				fontsize = Configuration:GetFont(2).size,
				text = [["]] .. factionData.motto .. [["]] .. "\n" .. factionData.desc,
				parent = holder,
			}
		end

		offset = offset + FACTION_SPACING
	end

	Button:New {
		x = 140,
		y = offset,
		width = 170,
		height = 35,
		caption = "Factions Page",
		font = Configuration:GetFont(2),
		classname = "option_button",
		padding = {2,4,4,4},
		OnClick = {
			function()
				WG.BrowserHandler.OpenUrl("http://zero-k.info/Factions")
			end
		},
		parent = holder,
		children = {
			Image:New {
				right = 1,
				y = 4,
				width = 18,
				height = 18,
				keepAspect = true,
				file = IMG_LINK
			}
		}
	}

	if CancelFunc then
		Button:New {
			x = 316,
			y = offset,
			width = 84,
			height = 35,
			font =  WG.Chobby.Configuration:GetFont(2),
			caption = i18n("cancel"),
			classname = "negative_button",
			OnClick = {
				function()
					CancelFunc()
				end
			},
			parent = holder,
		}
	end

	return holder
end

local function MakeFactionSelectionPopup()
	local Configuration = WG.Chobby.Configuration
	local lobby = WG.LibLobby.lobby

	local factionList = lobby and lobby.planetwarsData.factionList
	if not factionList then
		return
	end

	local factionWindow = Window:New {
		x = 700,
		y = 300,
		width = 460,
		height = 130 + (#factionList)*FACTION_SPACING,
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

	local function CancelFunc()
		factionWindow:Dispose()
	end

	MakeFactionSelector(factionWindow, 16, 55, CancelFunc, CancelFunc)

	TextBox:New {
		x = 38,
		right = 15,
		y = 15,
		height = 35,
		fontsize = Configuration:GetFont(3).size,
		text = "Join a faction to play Planetwars",
		parent = factionWindow,
	}

	local popupHolder = WG.Chobby.PriorityPopup(factionWindow, CancelFunc, CancelFunc)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Initialization

local function InitializeControls(window)
	local Configuration = WG.Chobby.Configuration
	local lobby = WG.LibLobby.lobby

	local title = "Planetwars"
	local missingResources = false
	local factionLinkButton

	local oldAttackerFaction, oldDefenderFactions, oldMode = "", {}, 1

	local lblTitle = Label:New {
		x = 20,
		right = 5,
		y = 17,
		height = 20,
		font = Configuration:GetFont(3),
		caption = "Planetwars",
		parent = window
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
				window:Hide()
			end
		},
		parent = window
	}

	local listHolder = Control:New {
		x = 5,
		right = 5,
		y = 100,
		bottom = 52,
		padding = {0, 0, 0, 0},
		parent = window,
	}

	Button:New {
		x = 15,
		bottom = 12,
		width = 150,
		height = 32,
		caption = "Galaxy Map",
		font = Configuration:GetFont(2),
		classname = "option_button",
		padding = {2,4,4,4},
		OnClick = {
			function()
				WG.BrowserHandler.OpenUrl("http://zero-k.info/Planetwars")
			end
		},
		children = {
			Image:New {
				right = 1,
				y = 4,
				width = 18,
				height = 18,
				keepAspect = true,
				file = IMG_LINK
			}
		},
		parent = window,
	}
	local seeMorePlanets = TextBox:New {
		x = 174,
		right = 16,
		bottom = 18,
		height = 50,
		fontsize = Configuration:GetFont(2).size,
		text = "Select planets on the Galaxy Map for more options.",
		parent = window
	}

	local planetList = GetPlanetList(listHolder)

	local statusText = TextBox:New {
		x = 20,
		right = 16,
		y = 60,
		height = 50,
		fontsize = Configuration:GetFont(2).size,
		text = "",
		parent = window
	}

	local function CheckPlanetwarsRequirements()
		local myUserInfo = lobby:GetMyInfo()
		if not (planetwarsSoon or planetwarsEnabled) then
			statusText:SetText("Planetwars is offline. Check back later.")
			if factionLinkButton then
				factionLinkButton:SetVisibility(false)
			end
			listHolder:SetVisibility(false)
			return false
		end

		if not myUserInfo then
			statusText:SetText(((planetwarsSoon and PW_SOON_TEXT) or "") .. "Error getting user info. Are you fully logged in?")
			if factionLinkButton then
				factionLinkButton:SetVisibility(false)
			end
			listHolder:SetVisibility(false)
			return false
		end

		if planetwarsLevelRequired and ((myUserInfo.level or 0) < planetwarsLevelRequired) then
			statusText:SetText(((planetwarsSoon and PW_SOON_TEXT) or "") .. "You need to be at least level " .. (planetwarsLevelRequired or "??") .. " to participate in Planetwars.")
			if factionLinkButton then
				factionLinkButton:SetVisibility(false)
			end
			listHolder:SetVisibility(false)
			return false
		end

		if not lobby:GetFactionData(myUserInfo.faction) then
			statusText:SetText(((planetwarsSoon and PW_SOON_TEXT) or "") .. "You need to join a faction.")
			if not factionLinkButton then
				factionLinkButton = MakeFactionSelector(window, 15, 80, nil, nil, 15, 52)
			end
			factionLinkButton:SetVisibility(true)
			listHolder:SetVisibility(false)
			return false
		end

		if factionLinkButton then
			factionLinkButton:Dispose()
			factionLinkButton = nil
		end

		if (not planetwarsEnabled) and planetwarsSoon then
			statusText:SetText(PW_SOON_TEXT)
			if factionLinkButton then
				factionLinkButton:SetVisibility(false)
			end
			listHolder:SetVisibility(false)
			return false
		end

		listHolder:SetVisibility(true)
		return true
	end

	local function UpdateStatusText(attacking, defending, currentMode)
		if not CheckPlanetwarsRequirements() then
			return
		end

		if missingResources then
			return
		end

		if attacking then
			if currentMode == lobby.PW_ATTACK then
				statusText:SetText("Select a planet to attack. The invasion will launch when you are joined by enough players.")
			else
				local planets = lobby.planetwarsData.planets
				local planetName = planets and planets[1] and planets[1].PlanetName
				if lobby.planetwarsData.attackingPlanet then
					statusText:SetText("You have launched an attack on " .. (planetName or "an enemy planet") .. ". The defenders have limited time to respond.")
				else
					statusText:SetText("Your faction is attacking " .. (planetName or "an enemy planet") .. ". The defenders have limited time to respond")
				end
			end
		else
			if currentMode == lobby.PW_ATTACK then
				statusText:SetText("Waiting for your enemies to launch an attack.")
			elseif defending then
				local planets = lobby.planetwarsData.planets
				local planetName = planets and planets[1] and planets[1].PlanetName
				if planetName then
					planetName = " " .. planetName
				end
				statusText:SetText("Your planet" .. (planetName or "") .. " is under attack. Join the defense before it is too late!")
			elseif currentMode == lobby.PW_DEFEND then
				statusText:SetText("Another faction is preparing their response to an invasion.")
			else
				statusText:SetText("Planetwars is either offline or loading.")
			end
		end
	end

	local function OnPwMatchCommand(listener, attackerFaction, defenderFactions, currentMode, planets, deadlineSeconds, modeSwitched)
		oldAttackerFaction, oldDefenderFactions, oldMode = attackerFaction, defenderFactions, currentMode

		if currentMode == lobby.PW_ATTACK then
			if attackerFaction then
				title = "Planetwars: " .. attackerFaction .. " attacking - "
			else
				title = "Planetwars: attacking - "
			end
		else
			if defenderFactions and #defenderFactions then
				local defenderString = ""
				for i = 1, #defenderFactions do
					if i == #defenderFactions then
						defenderString = defenderString .. defenderFactions[i]
					else
						defenderString = defenderString .. defenderFactions[i] .. ", "
					end
					title = "Planetwars: " .. defenderString .. " defending - "
				end
			else
				title = "Planetwars: defending - "
			end
		end

		local attacking, defending = GetAttackingOrDefending(lobby, attackerFaction, defenderFactions)
		UpdateStatusText(attacking, defending, currentMode)

		planetList.SetPlanetList(planets, (currentMode == lobby.PW_ATTACK) and attacking, (currentMode == lobby.PW_DEFEND) and defending, modeSwitched)
	end

	lobby:AddListener("OnPwMatchCommand", OnPwMatchCommand)

	local function OnPwAttackingPlanet()
		local attacking, defending = GetAttackingOrDefending(lobby, oldAttackerFaction, oldDefenderFactions)
		UpdateStatusText(attacking, defending, oldMode)
	end
	lobby:AddListener("OnPwAttackingPlanet", OnPwAttackingPlanet)

	local function OnUpdateUserStatus(listener, userName, status)
		if lobby:GetMyUserName() == userName then
			local attacking, defending = GetAttackingOrDefending(lobby, oldAttackerFaction, oldDefenderFactions)
			UpdateStatusText(attacking, defending, oldMode)
		end
	end
	lobby:AddListener("OnUpdateUserStatus", OnUpdateUserStatus)

	local externalFunctions = {}

	function externalFunctions.CheckDownloads()
		planetList.CheckDownload()
		if not HaveRightEngineVersion() then
			if CheckPlanetwarsRequirements() then
				statusText:SetText(MISSING_ENGINE_TEXT)
			end
			missingResources = true
			return
		end
		if not HaveRightGameVersion() then
			if CheckPlanetwarsRequirements() then
				statusText:SetText(MISSING_GAME_TEXT)
			end
			missingResources = true
			return
		end
		missingResources = false
	end

	externalFunctions.CheckPlanetwarsRequirements = CheckPlanetwarsRequirements

	function externalFunctions.UpdateTimer()
		local timeRemaining = phaseTimer.GetTimeRemaining()
		if timeRemaining then
			lblTitle:SetCaption(title .. Spring.Utilities.FormatTime(timeRemaining, true))
		end
	end

	function externalFunctions.SetPlanetJoined(planetID)
		planetList.SetPlanetJoined(planetID)
	end

	-- Initialization
	externalFunctions.CheckDownloads()

	local planetwarsData = lobby:GetPlanetwarsData()
	OnPwMatchCommand(_, planetwarsData.attackerFaction, planetwarsData.defenderFactions, planetwarsData.currentMode, planetwarsData.planets, 457)

	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- External Interface

local PlanetwarsListWindow = {}

function PlanetwarsListWindow.HaveMatchMakerResources()
	return HaveRightEngineVersion() and HaveRightGameVersion()
end

local queueListWindowControl

function PlanetwarsListWindow.GetControl()
	planetwarsListWindowControl = Control:New {
		name = "planetwarsListWindowControl",
		x = "0%",
		y = "0%",
		width = "100%",
		height = "100%",
		padding = {0, 0, 0, 0},
		OnParent = {
			function(obj)
				if obj:IsEmpty() then
					panelInterface = InitializeControls(obj)
				end
			end
		},
	}

	return planetwarsListWindowControl
end

function DelayedInitialize()
	local Configuration = WG.Chobby.Configuration
	local lobby = WG.LibLobby.lobby

	local statusAndInvitesPanel = WG.Chobby.interfaceRoot.GetStatusAndInvitesPanel()

	phaseTimer = GetPhaseTimer()
	activityPromptHandler = InitializeActivityPromptHandler()

	local function AddQueue(_, queueName, queueDescription, mapNames, maxPartSize, gameNames)
		for i = 1, #gameNames do
			requiredGame = gameNames[i]
		end
		if panelInterface then
			panelInterface.CheckDownloads()
		end
	end
	lobby:AddListener("OnQueueOpened", AddQueue)


	local function UpdateActivity(attackerFaction, defenderFactions, currentMode, planets)
		local planetData, isAttacker, alreadyJoined, waitingForAllies = GetActivityToPrompt(lobby, attackerFaction, defenderFactions, currentMode, planets)
		if planetData then
			activityPromptHandler.SetActivity(planetData, isAttacker, alreadyJoined, waitingForAllies)
			statusAndInvitesPanel.AddControl(activityPromptHandler.GetHolder(), 5)
		else
			activityPromptHandler.NotifyHidden()
			statusAndInvitesPanel.RemoveControl(activityPromptHandler.GetHolder().name)
		end
	end

	local myLevel
	local function CheckFactionPopupCreation(myInfo)
		if not (planetwarsSoon or planetwarsEnabled) then
			return
		end
		if Configuration.alreadySeenFactionPopup4 then
			return
		end
		if planetwarsLevelRequired and (not Configuration.ignoreLevel) and not (myInfo and myInfo.level and myInfo.level >= planetwarsLevelRequired) then
			return
		end
		Configuration.alreadySeenFactionPopup4 = true
		if lobby:GetFactionData(myInfo.faction) then
			return
		end
		MakeFactionSelectionPopup()
	end

	local function OnPwStatus(_, enabledStatus, requiredLevel)
		local myInfo = lobby:GetMyInfo()
		myLevel = myInfo.level
		planetwarsLevelRequired = requiredLevel
		if enabledStatus == lobby.PW_PREGAME then
			planetwarsSoon = true
		elseif enabledStatus == lobby.PW_ENABLED then
			planetwarsEnabled = true
		end
		if panelInterface then
			panelInterface.CheckPlanetwarsRequirements()
		end
		CheckFactionPopupCreation(myInfo)
		local planetwarsData = lobby:GetPlanetwarsData()
		UpdateActivity(planetwarsData.attackerFaction, planetwarsData.defenderFactions, planetwarsData.currentMode, planetwarsData.planets)
	end
	lobby:AddListener("OnPwStatus", OnPwStatus)

	local function OnUpdateUserStatus(listener, userName, status)
		if (lobby:GetMyUserName() ~= userName) or (myLevel and (myLevel == status.level)) then
			return
		end
		myLevel = status.level
		if panelInterface then
			panelInterface.CheckPlanetwarsRequirements()
		end
		CheckFactionPopupCreation(status)
		local planetwarsData = lobby:GetPlanetwarsData()
		UpdateActivity(planetwarsData.attackerFaction, planetwarsData.defenderFactions, planetwarsData.currentMode, planetwarsData.planets)
	end

	lobby:AddListener("OnUpdateUserStatus", OnUpdateUserStatus)
	-- Test data
	--local TestAttack, TestDefend
	--function TestAttack()
	--	activityPromptHandler.SetActivity({PlanetName = "test", Map = "TitanDuel", Count = 2, Needed = 3, PlanetID = 1, PlanetImage = "12.png"}, true, true, true)
	--	statusAndInvitesPanel.AddControl(activityPromptHandler.GetHolder(), 5)
	--
	--	WG.Delay(TestDefend, 3)
	--end
	--function TestDefend()
	--	activityPromptHandler.SetActivity({PlanetName = "test", Map = "TitanDuel", Count = 2, Needed = 3, PlanetID = 2, PlanetImage = "11.png"}, false, false, false)
	--	statusAndInvitesPanel.AddControl(activityPromptHandler.GetHolder(), 5)
	--
	--	WG.Delay(TestAttack, 3)
	--end
	--WG.Delay(TestAttack, 3)

	local function OnPwMatchCommand(listener, attackerFaction, defenderFactions, currentMode, planets, deadlineSeconds, modeSwitched)
		phaseTimer.SetNewDeadline(deadlineSeconds)
		UpdateActivity(attackerFaction, defenderFactions, currentMode, planets)
	end
	lobby:AddListener("OnPwMatchCommand", OnPwMatchCommand)

	local function UnMatchedActivityUpdate()
		local planetwarsData = lobby:GetPlanetwarsData()
		UpdateActivity(planetwarsData.attackerFaction, planetwarsData.defenderFactions, planetwarsData.currentMode, planetwarsData.planets)
	end
	lobby:AddListener("OnPwJoinPlanetSuccess", UnMatchedActivityUpdate)
	lobby:AddListener("OnPwAttackingPlanet", UnMatchedActivityUpdate)
	lobby:AddListener("OnLoginInfoEnd", UnMatchedActivityUpdate)

	local function OnDisconnected()
		UpdateActivity({}, {}, false, {})
	end
	lobby:AddListener("OnDisconnected", OnDisconnected)

	DoUnMatchedActivityUpdate = UnMatchedActivityUpdate

	local function OnPwRequestJoinPlanet(listener, joinPlanetID)
		local planetwarsData = lobby:GetPlanetwarsData()
		local planets = planetwarsData.planets
		for i = 1, #planets do
			if joinPlanetID == planets[i].PlanetID then
				TryToJoinPlanet(planets[i])
				break
			end
		end
	end
	lobby:AddListener("OnPwRequestJoinPlanet", OnPwRequestJoinPlanet)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

function widget:Update()
	if not planetwarsEnabled then
		return
	end
	updates = updates + 1 -- Random number
	if panelInterface then
		panelInterface.UpdateTimer()
	end
	if activityPromptHandler then
		activityPromptHandler.UpdateTimer()
	end
	if DoUnMatchedActivityUpdate then
		local newUrgent = IsAttackUrgent()
		if newUrgent ~= attackUrgent then
			attackUrgent = newUrgent
			DoUnMatchedActivityUpdate()
		end
	end
end

function widget:Initialize()
	CHOBBY_DIR = LUA_DIRNAME .. "widgets/chobby/"
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)
	WG.Delay(DelayedInitialize, 0.3)

	local function downloadFinished()
		if planetwarsEnabled then
			if panelInterface then
				panelInterface.CheckDownloads()
			end
			if queuePlanetJoin then
				TryToJoinPlanet(queuePlanetJoin)
			end
		end
	end
	WG.DownloadHandler.AddListener("DownloadFinished", downloadFinished)

	WG.PlanetwarsListWindow = PlanetwarsListWindow
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
