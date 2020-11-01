--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Battle Room Window",
		desc      = "Battle Room Window handler.",
		author    = "GoogleFrog",
		date      = "30 June 2016",
		license   = "GNU LGPL, v2.1 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Local variables

-- Chili controls
local mainWindow

-- Globals
local battleLobby
local wrapperControl
local mainWindowFunctions

local singleplayerWrapper
local multiplayerWrapper

local singleplayerGame = "Chobby $VERSION"

local IMG_READY    = LUA_DIRNAME .. "images/ready.png"
local IMG_UNREADY  = LUA_DIRNAME .. "images/unready.png"
local IMG_LINK     = LUA_DIRNAME .. "images/link.png"

local MINIMUM_QUICKPLAY_PLAYERS = 4 -- Hax until the server tells me a number.

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Download management

local emptyTeamIndex = 0

local haveMapAndGame = false

local function HasGame(gameName)
	return VFS.HasArchive(gameName)
end

local function UpdateArchiveStatus(updateSync)
	if not battleLobby or not battleLobby:GetMyBattleID() then
		return
	end
	local battle = battleLobby:GetBattle(battleLobby:GetMyBattleID())
	if not battle then
		haveMapAndGame = false
		return
	end
	local haveGame = HasGame(battle.gameName)
	local haveMap = VFS.HasArchive(battle.mapName)

	if mainWindowFunctions and mainWindowFunctions.GetInfoHandler() then
		local infoHandler = mainWindowFunctions.GetInfoHandler()
		infoHandler.SetHaveGame(haveGame)
		infoHandler.SetHaveMap(haveMap)
	end

	haveMapAndGame = (haveGame and haveMap)

	if updateSync and battleLobby then
		battleLobby:SetBattleStatus({
			sync = (haveMapAndGame and 1) or 2, -- 0 = unknown, 1 = synced, 2 = unsynced
		})
	end
end

local function MaybeDownloadGame(battle)
	WG.DownloadHandler.MaybeDownloadArchive(battle.gameName, "game", -1)
end

local function MaybeDownloadMap(battle)
	WG.DownloadHandler.MaybeDownloadArchive(battle.mapName, "map", -1)
end

local OpenNewTeam

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Chili/interface management

local function SetupInfoButtonsPanel(leftInfo, rightInfo, battle, battleID, myUserName)
	local config = WG.Chobby.Configuration
	local minimapBottomClearance = 135

	local currentMapName
	local mapLinkWidth = 150

	local btnMapLink = Button:New {
		x = 3,
		y = 0,
		right = 3,
		height = 20,
		classname = "button_square",
		caption = "",
		padding = {0, 0, 0, 0},
		parent = rightInfo,
		OnClick = {
			function ()
				if currentMapName and config.gameConfig.link_particularMapPage ~= nil then
					WG.BrowserHandler.OpenUrl(config.gameConfig.link_particularMapPage(currentMapName))
				end
			end
		}
	}

	local tbMapName = TextBox:New {
		name = "tbMapName",
		x = 2,
		y = 3,
		right = 20,
		align = "left",
		parent = btnMapLink,
		fontsize = config:GetFont(2).size,
	}
	local imMapLink = Image:New {
		x = 0,
		y = 1,
		width = 18,
		height = 18,
		keepAspect = true,
		file = IMG_LINK,
		parent = btnMapLink,
	}

	local function SetMapName(mapName, width)
		currentMapName = mapName
		mapLinkWidth = width

		if not currentMapName then
			return
		end

		mapName = battle.mapName:gsub("_", " ")
		mapName = StringUtilities.GetTruncatedStringWithDotDot(mapName, tbMapName.font, width - 22)
		tbMapName:SetText(mapName)
		local length = tbMapName.font:GetTextWidth(mapName)
		imMapLink:SetPos(length + 5)
	end
	SetMapName(battle.mapName, mapLinkWidth)

	btnMapLink.OnResize[#btnMapLink.OnResize + 1] = function (self, xSize, ySize)
		SetMapName(currentMapName, xSize)
	end

	local minimapPanel = Panel:New {
		x = 0,
		y = 0,
		right = 0,
		height = 200,
		padding = {1,1,1,1},
		parent = rightInfo,
	}
	local btnMinimap = Button:New {
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		classname = "button_square",
		caption = "",
		parent = minimapPanel,
		padding = {2,2,2,2},
		OnClick = {
			function()
				WG.MapListPanel.Show(battleLobby, battle.mapName)
			end
		},
	}

	local mapImageFile, needDownload = config:GetMinimapImage(battle.mapName)
	local imMinimap = Image:New {
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		keepAspect = true,
		file = mapImageFile,
		fallbackFile = config:GetLoadingImage(3),
		checkFileExists = needDownload,
		parent = btnMinimap,
	}

	local function RejoinBattleFunc()
    --Spring.Echo("\LuaMenu\widgets\chobby\components\battle\battle_watch_list_window.lua","RejoinBattleFunc()","") -- Beherith Debug
		battleLobby:RejoinBattle(battleID)
		WG.Analytics.SendOnetimeEvent("lobby:multiplayer:custom:rejoin")
	end

	local btnStartBattle = Button:New {
		x = 0,
		bottom = 0,
		right = 0,
		height = 48,
		caption = i18n("start"),
		classname = "action_button",
		font = config:GetFont(4),
		OnClick = {
			function()
				if not haveMapAndGame then
					Spring.Echo("Do something if map or game is missing")
					return
				end

				if battle.isRunning then
					if Spring.GetGameName() == "" then
						RejoinBattleFunc()
					else
						WG.Chobby.ConfirmationPopup(RejoinBattleFunc, "Are you sure you want to leave your current game to rejoin this one?", nil, 315, 200)
					end
				else
					if battleLobby.name == "singleplayer" then
						WG.Analytics.SendOnetimeEvent("lobby:singleplayer:skirmish:start")
						WG.SteamCoopHandler.AttemptGameStart("skirmish", battle.gameName, battle.mapName)
					else
						WG.Analytics.SendOnetimeEvent("lobby:multiplayer:custom:start")
						battleLobby:StartBattle("skirmish")
					end
				end
			end
		},
		parent = rightInfo,
	}

	local btnPlay
	local btnSpectate = Button:New {
		x = "50.5%",
		right = 0,
		bottom = 51,
		height = 48,
		classname = "button_highlight",
		caption = "\255\66\138\201" .. i18n("spectator") ..  "\b",
		font =  config:GetFont(3),
		OnClick = {
			function(obj)
				battleLobby:SetBattleStatus({isSpectator = true})
				ButtonUtilities.SetButtonDeselected(btnPlay)
				ButtonUtilities.SetCaption(btnPlay, i18n("play"))
				ButtonUtilities.SetButtonSelected(obj)
				ButtonUtilities.SetCaption(obj, i18n("spectating"))
				WG.Analytics.SendOnetimeEvent("lobby:multiplayer:custom:spectate")
			end
		},
		parent = rightInfo,
	}

	btnPlay = Button:New {
		x = 0,
		right = "50.5%",
		bottom = 51,
		height = 48,
		classname = "button_highlight",
		caption = "\255\66\138\201" .. i18n("player") ..  "\b",
		font =  config:GetFont(3),
		OnClick = {
			function(obj)
				battleLobby:SetBattleStatus({isSpectator = false})
				ButtonUtilities.SetButtonDeselected(btnSpectate)
				ButtonUtilities.SetCaption(btnSpectate, i18n("spectate"))
				ButtonUtilities.SetButtonSelected(obj)
				ButtonUtilities.SetCaption(obj, i18n("playing"))
				WG.Analytics.SendOnetimeEvent("lobby:multiplayer:custom:play")
			end
		},
		parent = rightInfo,
	}

	rightInfo.OnResize = {
		function (obj, xSize, ySize)
			if xSize + minimapBottomClearance < ySize then
				minimapPanel._relativeBounds.left = 0
				minimapPanel._relativeBounds.right = 0
				minimapPanel:SetPos(nil, nil, nil, xSize)
				minimapPanel:UpdateClientArea()

				btnMapLink:SetPos(nil, xSize + 2)
			else
				local horPadding = ((xSize + minimapBottomClearance) - ySize)/2
				minimapPanel._relativeBounds.left = horPadding
				minimapPanel._relativeBounds.right = horPadding
				minimapPanel:SetPos(nil, nil, nil, ySize - minimapBottomClearance)
				minimapPanel:UpdateClientArea()

				btnMapLink:SetPos(nil, ySize - minimapBottomClearance + 2)
			end
		end
	}

	local leftOffset = 0
	local btnNewTeam = Button:New {
		name = "btnNewTeam",
		x = 5,
		y = leftOffset,
		height = 35,
		right = 5,
		classname = "option_button",
		caption = i18n("add_team") ..  "\b",
		font = config:GetFont(2),
		OnClick = {
			function()
				if OpenNewTeam then
					OpenNewTeam()
				end
			end
		},
		-- Combo box settings
		--ignoreItemCaption = true,
		--itemFontSize = config:GetFont(1).size,
		--itemHeight = 30,
		--selected = 0,
		--maxDropDownWidth = 120,
		--minDropDownHeight = 0,
		--items = {"Join", "Add AI"},
		--OnSelect = {
		--	function (obj)
		--		if obj.selected == 1 then
		--			battleLobby:SetBattleStatus({
		--				allyNumber = emptyTeamIndex,
		--				isSpectator = false,
		--			})
		--		elseif obj.selected == 2 then
		--			WG.PopupPreloader.ShowAiListWindow(battleLobby, battle.gameName, emptyTeamIndex)
		--		end
		--	end
		--},
		parent = leftInfo
	}
	leftOffset = leftOffset + 38

	local btnPickMap = Button:New {
		x = 5,
		y = leftOffset,
		height = 35,
		right = 5,
		classname = "option_button",
		caption = i18n("pick_map") ..  "\b",
		font =  config:GetFont(2),
		OnClick = {
			function()
				WG.MapListPanel.Show(battleLobby, battle.mapName)
			end
		},
		parent = leftInfo,
	}
	leftOffset = leftOffset + 38

	WG.ModoptionsPanel.LoadModotpions(battle.gameName, battleLobby)
	local btnModoptions = Button:New {
		x = 5,
		y = leftOffset,
		height = 35,
		right = 5,
		classname = "option_button",
		caption = "Adv Options" ..  "\b",
		font =  config:GetFont(2),
		OnClick = {
			function()
				WG.ModoptionsPanel.ShowModoptions()
			end
		},
		parent = leftInfo,
	}
	leftOffset = leftOffset + 40

	local lblGame = Label:New {
		x = 8,
		y = leftOffset,
		caption = battle.gameName,
		font = config:GetFont(1),
		parent = leftInfo,
	}
	leftOffset = leftOffset + 26

	local imHaveGame = Image:New {
		x = 8,
		y = leftOffset,
		width = 15,
		height = 15,
		file = IMG_READY,
		parent = leftInfo,
	}
	local lblHaveGame = Label:New {
		x = 28,
		y = leftOffset,
		caption = "",
		font = config:GetFont(1),
		parent = leftInfo,
	}
	leftOffset = leftOffset + 25

	local imHaveMap = Image:New {
		x = 8,
		y = leftOffset,
		width = 15,
		height = 15,
		file = IMG_READY,
		parent = leftInfo,
	}
	local lblHaveMap = Label:New {
		x = 28,
		y = leftOffset,
		caption = "",
		font = config:GetFont(1),
		parent = leftInfo,
	}
	leftOffset = leftOffset + 25

	local modoptionsHolder = Control:New {
		x = 0,
		y = leftOffset,
		right = 0,
		height = 120,
		padding = {2, 0, 2, 0},
		autosize = false,
		resizable = false,
		children = {
			WG.ModoptionsPanel.GetModoptionsControl()
		},
		parent = leftInfo,
	}
	if modoptionsHolder.children[1].visible then
		modoptionsHolder.children[1]:Hide()
	end

	local modoptionTopPosition = leftOffset
	local modoptionBottomPosition = leftOffset + 120
	local downloadVisibility = true
	local function OnDownloaderVisibility(newVisible)
		if newVisible ~= nil then
			downloadVisibility = newVisible
		end
		local newY = downloadVisibility and modoptionBottomPosition or modoptionTopPosition
		local newHeight = math.max(10, leftInfo.clientArea[4] - newY)
		modoptionsHolder:SetPos(nil, newY, nil, newHeight)
	end
	OnDownloaderVisibility(false)
	leftInfo.OnResize = leftInfo.OnResize or {}
	leftInfo.OnResize[#leftInfo.OnResize + 1] = function ()
		OnDownloaderVisibility()
	end

	local downloaderPos = {
		x = 0,
		height = 120,
		right = 0,
		y = leftOffset,
		parent = leftInfo,
	}

	local downloader = WG.Chobby.Downloader(false, downloaderPos, 8, nil, nil, nil, OnDownloaderVisibility)
	leftOffset = leftOffset + 120


	-- Example downloads
	--MaybeDownloadArchive("Titan-v2", "map")
	--MaybeDownloadArchive("tinyskirmishredux1.1", "map")

	local externalFunctions = {}

	function externalFunctions.UpdateBattleMode(disallowCustomTeams)
		local offset = 0
		if disallowCustomTeams then
			btnNewTeam:SetVisibility(false)
		else
			btnNewTeam:SetVisibility(true)
			offset = offset + 38
		end
		btnPickMap:SetPos(nil, offset)
		offset = offset + 38
		btnModoptions:SetPos(nil, offset)
		offset = offset + 40
		lblGame:SetPos(nil, offset)
		offset = offset + 26
		imHaveGame:SetPos(nil, offset)
		lblHaveGame:SetPos(nil, offset)
		offset = offset + 25
		imHaveMap:SetPos(nil, offset)
		lblHaveMap:SetPos(nil, offset)
	end
	externalFunctions.UpdateBattleMode(battle.disallowCustomTeams)

	function externalFunctions.SetHaveGame(newHaveGame)
		if newHaveGame then
			imHaveGame.file = IMG_READY
			lblHaveGame:SetCaption(i18n("have_game"))
		else
			imHaveGame.file = IMG_UNREADY
			lblHaveGame:SetCaption(i18n("dont_have_game"))
		end
		imHaveGame:Invalidate()
	end

	function externalFunctions.SetHaveMap(newHaveMap)
		if newHaveMap then
			imHaveMap.file = IMG_READY
			lblHaveMap:SetCaption(i18n("have_map"))
		else
			imHaveMap.file = IMG_UNREADY
			lblHaveMap:SetCaption(i18n("dont_have_map"))
		end
		imHaveMap:Invalidate()
	end

	-- Lobby interface
	function externalFunctions.UpdateUserTeamStatus(userName, allyNumber, isSpectator)
		if userName == myUserName then
			if isSpectator then
				ButtonUtilities.SetButtonDeselected(btnPlay)
				ButtonUtilities.SetCaption(btnPlay, i18n("play"))
				ButtonUtilities.SetButtonSelected(btnSpectate)
				ButtonUtilities.SetCaption(btnSpectate, i18n("spectating"))
			else
				ButtonUtilities.SetButtonDeselected(btnSpectate)
				ButtonUtilities.SetCaption(btnSpectate, i18n("spectate"))
				ButtonUtilities.SetButtonSelected(btnPlay)
				ButtonUtilities.SetCaption(btnPlay, i18n("playing"))
			end
		end
	end

	function externalFunctions.BattleIngameUpdate(updatedBattleID, isRunning)
		if battleID == updatedBattleID then
			if isRunning then
				btnStartBattle:SetCaption(i18n("rejoin"))
			else
				btnStartBattle:SetCaption(i18n("start"))
			end
		end
	end

	externalFunctions.BattleIngameUpdate(battleID, battle.isRunning)

	function externalFunctions.UpdateBattleInfo(updatedBattleID, battleInfo)
		if battleID ~= updatedBattleID then
			return
		end
		if battleInfo.mapName then
			SetMapName(battleInfo.mapName, mapLinkWidth)
			imMinimap.file, imMinimap.checkFileExists  = config:GetMinimapImage(battleInfo.mapName)
			imMinimap:Invalidate()

			-- TODO: Bit lazy here, seeing as we only need to update the map
			UpdateArchiveStatus(true)
			MaybeDownloadMap(battle)
		end
		-- TODO: messy code, rework; SetBattleStatus is called too many times;
		-- UpdateArchiveStatus(true) is invoked in a couple of places, but also
		-- the battleLobby status is manually checked set separately (why?)
		if battleInfo.gameName then
			lblGame:SetCaption(battleInfo.gameName)
			UpdateArchiveStatus(true)
			MaybeDownloadGame(battle)
		end

		if (battleInfo.mapName and not VFS.HasArchive(battleInfo.mapName)) or (battleInfo.gameName and not HasGame(battleInfo.gameName)) then
			battleLobby:SetBattleStatus({
				sync = 2, -- 0 = unknown, 1 = synced, 2 = unsynced
			})
		end
	end

	function externalFunctions.LeftBattle(leftBattleID, userName)
		if battleID ~= leftBattleID then
			return
		end
		if battleLobby:GetMyUserName() == userName then
			mainWindow:Dispose()
			mainWindow = nil
			if wrapperControl and wrapperControl.visible and wrapperControl.parent then
				wrapperControl:Hide()
			end
		end
	end

	function externalFunctions.JoinedBattle(joinedBattleId, userName)
		if battleID ~= joinedBattleId then
			return
		end
	end

	MaybeDownloadGame(battle)
	MaybeDownloadMap(battle)
	UpdateArchiveStatus(true)

	return externalFunctions
end

local function AddTeamButtons(parent, offX, joinFunc, aiFunc, unjoinable, disallowBots)
	if not disallowBots then
		local addAiButton = Button:New {
			name = "addAiButton",
			x = offX,
			y = 4,
			height = 24,
			width = 72,
			font = WG.Chobby.Configuration:GetFont(2),
			caption = i18n("add_ai") .. "\b",
			OnClick = {aiFunc},
			classname = "option_button",
			parent = parent,
		}
		offX = offX + 82
	end
	if not unjoinable then
		local joinTeamButton = Button:New {
			name = "joinTeamButton",
			x = offX,
			y = 4,
			height = 24,
			width = 72,
			font = WG.Chobby.Configuration:GetFont(2),
			caption = i18n("join") .. "\b",
			OnClick = {joinFunc},
			classname = "option_button",
			parent = parent,
		}
	end
end

local function SetupPlayerPanel(playerParent, spectatorParent, battle, battleID)

	local SPACING = 22
	local disallowCustomTeams = battle.disallowCustomTeams
	local disallowBots = battle.disallowBots

	local mainScrollPanel = ScrollPanel:New {
		x = 0,
		right = 0,
		y = 1,
		bottom = 0,
		parent = playerParent,
		horizontalScrollbar = false,
	}

	local mainStackPanel = Control:New {
		x = 0,
		right = 0,
		y = 0,
		bottom = 0,
		parent = mainScrollPanel,
		preserveChildrenOrder = true,
	}
	mainStackPanel._relativeBounds.bottom = nil
	local spectatorScrollPanel = ScrollPanel:New {
		x = 0,
		right = 0,
		y = 0,
		bottom = 0,
		parent = spectatorParent,
		horizontalScrollbar = false,
	}

	local spectatorStackPanel = Control:New {
		x = 0,
		right = 0,
		y = 0,
		bottom = 0,
		parent = spectatorScrollPanel,
	}
	spectatorStackPanel._relativeBounds.bottom = nil

	-- Object handling
	local player = {}
	local team = {}

	local function PositionChildren(panel, minHeight)
		local children = panel.children

		minHeight = minHeight - 10

		local childrenCount = #children
		local bottomBuffer = 0

		local totalHeight = 0
		local maxHeight = 0
		for i = 1, #children do
			local child = children[i]
			totalHeight = totalHeight + child.height
			if child.height > maxHeight then
				maxHeight = child.height
			end
		end

		if childrenCount * maxHeight + bottomBuffer > minHeight then
			if totalHeight < minHeight then
				totalHeight = minHeight
			end
			panel:SetPos(nil, nil, nil, totalHeight + 15)
			local runningHeight = 0
			for i = 1, #children do
				local child = children[i]
				child:SetPos(nil, runningHeight)
				child:Invalidate()
				runningHeight = runningHeight + child.height
			end
		else
			panel:SetPos(nil, nil, nil, minHeight)
			for i = 1, #children do
				local child = children[i]
				child:SetPos(nil, math.floor(minHeight * (i - 1)/#children))
				child:Invalidate()
			end
		end
		panel:Invalidate()
	end

	local function GetPlayerData(name)
		if not player[name] then
			player[name] = {
				team = false,
				control = WG.UserHandler.GetBattleUser(name, battleLobby.name == "singleplayer"),
			}
		end
		return player[name]
	end

	local function GetTeam(teamIndex)
		teamIndex = teamIndex or -1
		if not team[teamIndex] then
			if teamIndex == emptyTeamIndex then
				local checkTeam = teamIndex + 1
				while team[checkTeam] do
					checkTeam = checkTeam + 1
				end
				emptyTeamIndex = checkTeam
			end

			local humanName, parentStack, parentScroll
			if teamIndex == -1 then
				humanName = "Spectators"
				parentStack = spectatorStackPanel
				parentScroll = spectatorScrollPanel
			else
				if disallowCustomTeams then
					if teamIndex == 0 then
						humanName = "Players"
					else
						humanName = "Bots"
					end
				else
					humanName = "Team " .. (teamIndex + 1)
				end
				parentStack = mainStackPanel
				parentScroll = mainScrollPanel
			end

			local teamHolder = Control:New {
				name = teamIndex,
				x = 0,
				right = 0,
				y = 0,
				height = 50,
				padding = {0, 0, 0, 0},
				parent = parentStack,
			}

			local label = Label:New {
				x = 5,
				y = 0,
				width = 120,
				height = 30,
				valign = "center",
				font = WG.Chobby.Configuration:GetFont(3),
				caption = humanName,
				parent = teamHolder,
			}
			if teamIndex ~= -1 then
				local seperator = Line:New {
					x = 0,
					y = 25,
					right = 0,
					height = 2,
					parent = teamHolder
				}

				AddTeamButtons(
					teamHolder,
					90,
					function()
						battleLobby:SetBattleStatus({
								allyNumber = teamIndex,
								isSpectator = false,
							})
					end,
					function (obj, x, y, button)
						local quickAddAi
						if button == 3 and WG.Chobby.Configuration.lastAddedAiName then
							quickAddAi = WG.Chobby.Configuration.lastAddedAiName
						end
						WG.PopupPreloader.ShowAiListWindow(battleLobby, battle.gameName, teamIndex, quickAddAi)
					end,
					disallowCustomTeams and teamIndex ~= 0,
					(disallowBots or disallowCustomTeams) and teamIndex ~= 1
				)
			end
			local teamStack = Control:New {
				x = 0,
				y = 31,
				right = 0,
				bottom = 0,
				padding = {0, 0, 0, 0},
				parent = teamHolder,
				preserveChildrenOrder = true,
			}

			if teamIndex == -1 then
				-- Empty spectator team is created. Position children to prevent flicker.
				PositionChildren(parentStack, parentScroll.height)
			end

			local teamData = {}

			function teamData.UpdateBattleMode()
				local addAiButton = teamHolder:GetChildByName("addAiButton")
				if addAiButton then
					teamHolder:RemoveChild(addAiButton)
					addAiButton:Dispose()
				end
				local joinTeamButton = teamHolder:GetChildByName("joinTeamButton")
				if joinTeamButton then
					teamHolder:RemoveChild(joinTeamButton)
					joinTeamButton:Dispose()
				end

				if teamIndex ~= -1 then
					AddTeamButtons(
						teamHolder,
						90,
						function()
							battleLobby:SetBattleStatus({
									allyNumber = teamIndex,
									isSpectator = false,
								})
						end,
						function()
							WG.PopupPreloader.ShowAiListWindow(battleLobby, battle.gameName, teamIndex)
						end,
						disallowCustomTeams and teamIndex ~= 0,
						(disallowBots or disallowCustomTeams) and teamIndex ~= 1
					)

					if disallowCustomTeams then
						if teamIndex == 0 then
							humanName = "Players"
						elseif teamIndex == 1 then
							humanName = "Bots"
						else
							humanName = "Invalid"
						end
					else
						humanName = "Team " .. (teamIndex + 1)
					end
				end
				label:SetCaption(humanName)
			end

			function teamData.AddPlayer(name)
				local playerData = GetPlayerData(name)
				if playerData.team == teamIndex then
					return
				end
				playerData.team = teamIndex
				local playerControl = playerData.control
				if name == battleLobby:GetMyUserName() then
					local joinTeam = teamHolder:GetChildByName("joinTeamButton")
					if joinTeam then
						joinTeam:SetVisibility(false)
					end
				end
				if not teamStack:GetChildByName(playerControl.name) then
					teamStack:AddChild(playerControl)
					playerControl:SetPos(nil, (#teamStack.children - 1)*SPACING)
					playerControl:Invalidate()

					teamHolder:SetPos(nil, nil, nil, #teamStack.children*SPACING + 35)
					PositionChildren(parentStack, parentScroll.height)
					teamHolder:Invalidate()
				end
			end

			function teamData.RemoveTeam()
				if teamIndex < emptyTeamIndex then
					emptyTeamIndex = teamIndex
				end

				team[teamIndex] = nil
				parentStack:RemoveChild(parentStack:GetChildByName(teamIndex))
				teamHolder:Dispose()
			end

			function teamData.CheckRemoval()
				if teamStack:IsEmpty() and teamIndex ~= -1 then
					local removeHolder = false

					if disallowCustomTeams then
						if teamIndex > 1 then
							teamData.RemoveTeam()
							return true
						elseif disallowBots and teamIndex > 0 then
							teamData.RemoveTeam()
							return true
						end
					else
						if teamIndex > 1 then
							local maxTeam = 0
							for teamID,_ in pairs(team) do
								maxTeam = math.max(teamID, maxTeam)
							end
							if teamIndex == maxTeam then
								teamData.RemoveTeam()
								return true
							end
						end
					end
				end
				return false
			end

			function teamData.RemovePlayer(name)
				local playerData = GetPlayerData(name)
				if playerData.team ~= teamIndex then
					return
				end
				playerData.team = false
				local index = 1
				local timeToMove = false
				while index <= #teamStack.children do
					if timeToMove then
						teamStack.children[index]:SetPos(nil, (index - 1)*SPACING)
						teamStack.children[index]:Invalidate()
					elseif teamStack.children[index].name == name then
						teamStack:RemoveChild(teamStack.children[index])
						index = index - 1
						timeToMove = true
					end
					index = index + 1
				end
				teamHolder:SetPos(nil, nil, nil, #teamStack.children*SPACING + 35)

				if name == battleLobby:GetMyUserName() then
					local joinTeam = teamHolder:GetChildByName("joinTeamButton")
					if joinTeam then
						joinTeam:SetVisibility(true)
					end
				end

				teamData.CheckRemoval()
				PositionChildren(parentStack, parentScroll.height)
			end

			team[teamIndex] = teamData
		end
		return team[teamIndex]
	end

	-- Object modification
	local function AddPlayerToTeam(allyTeamID, name)
		local teamObject = GetTeam(allyTeamID)
		teamObject.AddPlayer(name)
	end

	local function RemovePlayerFromTeam(name)
		local playerData = GetPlayerData(name)
		if playerData.team then
			local teamObject = GetTeam(playerData.team)
			teamObject.RemovePlayer(name)
		end
	end

	GetTeam(-1) -- Make Spectator heading appear
	GetTeam(0) -- Always show two teams in custom battles
	if not (disallowCustomTeams and disallowBots) then
		GetTeam(1)
	end

	OpenNewTeam = function ()
		if emptyTeamIndex < 254 then
			GetTeam(emptyTeamIndex)
			PositionChildren(mainStackPanel, mainScrollPanel.height)
		end
	end

	mainScrollPanel.OnResize = {
		function (obj)
			PositionChildren(mainStackPanel, mainScrollPanel.height)
		end
	}
	spectatorScrollPanel.OnResize = {
		function ()
			PositionChildren(spectatorStackPanel, spectatorScrollPanel.height)
		end
	}

	local externalFunctions = {}

	function externalFunctions.UpdateBattleMode(newDisallowCustomTeams, newDisallowBots)
		disallowCustomTeams = newDisallowCustomTeams
		disallowBots = newDisallowBots

		if not (disallowCustomTeams and disallowBots) then
			GetTeam(1)
			PositionChildren(mainStackPanel, mainScrollPanel.height)
		end
		for teamIndex, teamData in pairs(team) do
			if not teamData.CheckRemoval() then
				teamData.UpdateBattleMode()
			end
		end
	end

	function externalFunctions.UpdateUserTeamStatus(userName, allyNumber, isSpectator)
		if isSpectator then
			allyNumber = -1
		end
		local playerData = GetPlayerData(userName)
		if playerData.team == allyNumber then
			return
		end
		RemovePlayerFromTeam(userName)
		AddPlayerToTeam(allyNumber, userName)
	end

	function externalFunctions.LeftBattle(leftBattleID, userName)
		if leftBattleID == battleID then
			RemovePlayerFromTeam(userName)
		end
	end

	function externalFunctions.RemoveAi(botName)
		RemovePlayerFromTeam(botName)
	end

	return externalFunctions
end

local function SetupVotePanel(votePanel, battle, battleID)
	local height = votePanel.clientHeight
	local config = WG.Chobby.Configuration
	local offset = 0

	local buttonYesClickOverride
	local buttonNoClickOverride
	local matchmakerModeEnabled = false

	local currentMapName

	local minimapPanel = Panel:New {
		x = 0,
		y = 0,
		bottom = 0,
		width = height,
		padding = {1,1,1,1},
		parent = votePanel,
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
				if currentMapName and config.gameConfig.link_particularMapPage ~= nil then
					WG.BrowserHandler.OpenUrl(config.gameConfig.link_particularMapPage(currentMapName))
				end
			end
		},
	}
	local imMinimap = Image:New {
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		keepAspect = true,
		parent = btnMinimap,
	}

	local activePanel = Control:New {
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		padding = {0, 0, 0, 0},
		parent = votePanel,
	}
	local multiVotePanel = Control:New {
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		padding = {0, 0, 0, 0},
		parent = votePanel,
	}

	local buttonNo
	local buttonYes = Button:New {
		x = offset,
		y = 0,
		bottom = 0,
		width = height,
		caption = "",
		classname = "positive_button",
		OnClick = {
			function (obj)
				ButtonUtilities.SetButtonSelected(obj)
				ButtonUtilities.SetButtonDeselected(buttonNo)
				if buttonYesClickOverride then
					buttonYesClickOverride()
				else
					battleLobby:VoteYes()
				end
			end
		},
		padding = {10,10,10,10},
		children = {
			Image:New {
				x = 0,
				y = 0,
				right = 0,
				bottom = 0,
				autosize = true,
				file = IMG_READY,
			}
		},
		parent = activePanel,
	}
	offset = offset + height

	buttonNo = Button:New {
		x = offset,
		y = 0,
		bottom = 0,
		width = height,
		caption = "",
		classname = "negative_button",
		OnClick = {
			function (obj)
				ButtonUtilities.SetButtonSelected(obj)
				ButtonUtilities.SetButtonDeselected(buttonYes)
				if buttonNoClickOverride then
					buttonNoClickOverride()
				else
					battleLobby:VoteNo()
				end
			end
		},
		padding = {10,10,10,10},
		children = {
			Image:New {
				x = 0,
				y = 0,
				right = 0,
				bottom = 0,
				file = IMG_UNREADY,
			}
		},
		parent = activePanel,
	}
	offset = offset + height

	offset = offset + 2

	local voteName = Label:New {
		x = offset,
		y = 4,
		width = 50,
		bottom = height * 0.4,
		font = config:GetFont(1),
		caption = "",
		parent = activePanel,
	}

	local voteProgress = Progressbar:New {
		x = offset,
		y = height * 0.5,
		right = 55,
		bottom = 0,
		value = 0,
		parent = activePanel,
	}

	local voteCountLabel = Label:New {
		right = 5,
		y = height * 0.5,
		width = 50,
		bottom = 0,
		align = "left",
		font = config:GetFont(2),
		caption = "20/50",
		parent = activePanel,
	}

	local MULTI_POLL_MAX = 4
	local multiPollOpt = {}

	local function SetSelectedMultOpt(index)
		for i = 1, MULTI_POLL_MAX do
			if i == index then
				ButtonUtilities.SetButtonSelected(multiPollOpt[i].button)
			else
				ButtonUtilities.SetButtonDeselected(multiPollOpt[i].button)
			end
		end
	end

	local function ResetButtons()
		ButtonUtilities.SetButtonDeselected(buttonYes)
		ButtonUtilities.SetButtonDeselected(buttonNo)
		SetSelectedMultOpt()
	end

	for i = 1, MULTI_POLL_MAX do
		local opt = {}
		opt.id = i
		opt.button = Button:New {
			x = tostring(math.floor(100*(i - 1)/MULTI_POLL_MAX)) .. "%",
			y = 0,
			bottom = 0,
			width = tostring(math.floor(100/MULTI_POLL_MAX)) .. "%",
			caption = "",
			classname = "option_button",
			OnClick = {
				function (obj)
					SetSelectedMultOpt(i)
					battleLobby:VoteOption(opt.id)
				end
			},
			padding = {5,5,5,5},
			parent = multiVotePanel,
		}
		opt.countLabel = Label:New {
			right = 5,
			y = 7,
			width = 50,
			bottom = 0,
			align = "left",
			font = config:GetFont(3),
			caption = "20/50",
			parent = opt.button,
		}
		opt.imMinimap = Image:New {
			x = 0,
			y = 0,
			bottom = 0,
			width = height,
			keepAspect = true,
			parent = opt.button,
		}
		multiPollOpt[i] = opt
	end

	local voteResultLabel = Label:New {
		x = 5,
		y = 4,
		right = 0,
		bottom = height * 0.4,
		align = "left",
		font = config:GetFont(2),
		caption = "",
		parent = votePanel,
	}

	activePanel:SetVisibility(true)
	multiVotePanel:SetVisibility(false)
	minimapPanel:SetVisibility(false)
	voteResultLabel:SetVisibility(false)

	local function HideVoteResult()
		if voteResultLabel.visible then
			voteResultLabel:Hide()
		end
	end

	local externalFunctions = {}

	local oldPollType, oldMapPoll, oldPollUrl
	local function UpdatePollType(pollType, mapPoll, pollUrl)
		if oldPollType == pollType and oldMapPoll == mapPoll and oldPollUrl == pollUrl then
			return
		end
		oldPollType, oldMapPoll, oldPollUrl = pollType, mapPoll, pollUrl

		if pollType ~= "multi" then
			if mapPoll then
				minimapPanel:SetVisibility(true)
				activePanel:SetPos(height + 2)
				activePanel._relativeBounds.right = 0
				activePanel:UpdateClientArea()
				if pollUrl then
					imMinimap.file, imMinimap.checkFileExists = config:GetMinimapSmallImage(pollUrl)
					imMinimap:Invalidate()
					currentMapName = pollUrl
				end
			else
				minimapPanel:SetVisibility(false)
				activePanel:SetPos(0)
				activePanel._relativeBounds.right = 0
				activePanel:UpdateClientArea()
			end
		end
	end

	local function SetMultiPollCandidates(candidates)
		for i = 1, MULTI_POLL_MAX do
			if candidates[i] then
				multiPollOpt[i].imMinimap.file, multiPollOpt[i].imMinimap.checkFileExists = config:GetMinimapSmallImage(candidates[i].name)
				multiPollOpt[i].imMinimap:Invalidate()
				multiPollOpt[i].button.tooltip = "Vote for " .. candidates[i].name
			end
		end
	end

	function externalFunctions.VoteUpdate(voteMessage, pollType, mapPoll, candidates, votesNeeded, pollUrl)
		UpdatePollType(pollType, mapPoll, pollUrl)
		-- Update votes
		if pollType == "multi" then
			SetMultiPollCandidates(candidates)
			for i = 1, MULTI_POLL_MAX do
				if candidates[i] then
					multiPollOpt[i].countLabel:SetCaption(candidates[i].votes .. "/" .. votesNeeded)
					multiPollOpt[i].button:SetVisibility(true)
					multiPollOpt[i].id = candidates[i].id
				else
					multiPollOpt[i].button:SetVisibility(false)
				end
			end
			activePanel:SetVisibility(false)
			multiVotePanel:SetVisibility(true)
		else
			buttonYesClickOverride = candidates[1].clickFunc
			buttonNoClickOverride = candidates[2].clickFunc
			voteName:SetCaption(voteMessage)
			voteCountLabel:SetCaption(candidates[1].votes .. "/" .. votesNeeded)
			voteProgress:SetValue(100 * candidates[1].votes / votesNeeded)
			activePanel:SetVisibility(true)
			multiVotePanel:SetVisibility(false)
		end
		matchmakerModeEnabled = (pollType == "quickplay")
		HideVoteResult()
	end

	function externalFunctions.VoteEnd(message, success)
		activePanel:SetVisibility(false)
		multiVotePanel:SetVisibility(false)
		minimapPanel:SetVisibility(false)
		local text = ((success and WG.Chobby.Configuration:GetSuccessColor()) or WG.Chobby.Configuration:GetErrorColor()) .. message .. ((success and " Passed.") or " Failed.")
		voteResultLabel:SetCaption(text)
		if not voteResultLabel.visible then
			voteResultLabel:Show()
		end

		matchmakerModeEnabled = false
		ResetButtons()
		WG.Delay(HideVoteResult, 5)
	end

	function externalFunctions.ImmediateVoteEnd()
		activePanel:SetVisibility(false)
		multiVotePanel:SetVisibility(false)
		minimapPanel:SetVisibility(false)

		matchmakerModeEnabled = false
		ResetButtons()
		HideVoteResult()
	end

	function externalFunctions.GetMatchmakerMode()
		return matchmakerModeEnabled
	end

	return externalFunctions
end

local function InitializeSetupPage(subPanel, screenHeight, pageConfig, nextPage, prevPage, selectedOptions, ApplyFunction)
	local Configuration = WG.Chobby.Configuration

	local buttonScale, buttonHeight, buttonFont = 70, 64, 4
	if screenHeight < 900 then
		buttonScale = 60
		buttonHeight = 56
		buttonFont = 4
	end

	subPanel:SetVisibility(not prevPage)

	local lblBattleTitle = Label:New {
		x = "40%",
		right = "40%",
		y = buttonScale,
		height = 30,
		font = Configuration:GetFont(4),
		align = "center",
		valign = "center",
		caption = pageConfig.humanName,
		parent = subPanel,
	}

	local buttons = {}

	local nextButton = Button:New {
		x = "36%",
		right = "36%",
		y = 2*buttonScale + 5 + (#pageConfig.options)*buttonScale,
		height = buttonHeight,
		classname = "action_button",
		caption = (nextPage and "Next") or i18n("start"),
		font = Configuration:GetFont(buttonFont),
		OnClick = {
			function(obj)
				subPanel:SetVisibility(false)
				if nextPage then
					WG.Analytics.SendOnetimeEvent("lobby:singleplayer:skirmish:" .. pageConfig.name, selectedOptions[pageConfig.name])
					nextPage:SetVisibility(true)
				else
					WG.Analytics.SendOnetimeEvent("lobby:singleplayer:skirmish:" .. pageConfig.name, selectedOptions[pageConfig.name])
					WG.Analytics.SendOnetimeEvent("lobby:singleplayer:skirmish:start_quick")
					ApplyFunction(true)
				end
			end
		},
		parent = subPanel,
	}
	nextButton:Hide()

	local tipTextBox
	if pageConfig.tipText then
		tipTextBox = TextBox:New {
			x = "26%",
			y = 3*buttonScale + 20 + (#pageConfig.options)*buttonScale,
			right = "26%",
			height = 200,
			align = "left",
			fontsize = Configuration:GetFont(2).size,
			text = pageConfig.tipText,
			parent = subPanel,
		}
		tipTextBox:Hide()
	end

	local advButton = Button:New {
		x = "78%",
		right = "5%",
		bottom = "4%",
		height = 48,
		classname = "option_button",
		caption = "Advanced",
		tooltip = i18n("advanced_button_tooltip"),
		font = Configuration:GetFont(2),
		OnClick = {
			function(obj)
				WG.Analytics.SendOnetimeEvent("lobby:singleplayer:skirmish:advanced")
				subPanel:SetVisibility(false)
				ApplyFunction(false)
			end
		},
		parent = subPanel,
	}

	if prevPage then
		Button:New {
			x = "5%",
			right = "78%",
			bottom = "4%",
			height = 48,
			classname = "option_button",
			caption = "Back",
			font = Configuration:GetFont(2),
			OnClick = {
				function(obj)
					subPanel:SetVisibility(false)
					prevPage:SetVisibility(true)
				end
			},
			parent = subPanel,
		}
	end

	for i = 1, #pageConfig.options do
		local x, y, right, height, caption, tooltip
		if pageConfig.minimap then
			if i%2 == 1 then
				x, y, right, height = "25%", (i + 1)*buttonScale - 10, "51%", 2*buttonHeight
			else
				x, y, right, height = "51%", i*buttonScale - 10, "25%", 2*buttonHeight
			end
			tooltip = pageConfig.options[i]
			caption = ""
		else
			x, y, right, height = "36%", buttonHeight - 4 + i*buttonScale, "36%", buttonHeight
			caption = pageConfig.options[i]
		end
		buttons[i] = Button:New {
			x = x,
			y = y,
			right = right,
			height = height,
			classname = "button_highlight",
			caption = caption,
			tooltip = tooltip,
			font = Configuration:GetFont(buttonFont),
			tooltip = pageConfig.optionTooltip and pageConfig.optionTooltip[i],
			OnClick = {
				function(obj)
					for j = 1, #buttons do
						if j ~= i then
							ButtonUtilities.SetButtonDeselected(buttons[j])
						end
					end
					ButtonUtilities.SetButtonSelected(obj)
					selectedOptions[pageConfig.name] = i
					nextButton:SetVisibility(true)
					if tipTextBox then
						tipTextBox:SetVisibility(true)
					end
					if advButton then
						advButton:SetVisibility(true)
					end
				end
			},
			parent = subPanel,
		}
		if pageConfig.minimap then
			local mapImageFile, needDownload = Configuration:GetMinimapImage(pageConfig.options[i])
			local imMinimap = Image:New {
				x = 0,
				y = 0,
				right = 0,
				bottom = 0,
				keepAspect = true,
				file = mapImageFile,
				fallbackFile = Configuration:GetLoadingImage(2),
				checkFileExists = needDownload,
				parent = buttons[i],
			}
		end
		ButtonUtilities.SetButtonSelected(buttons[i])
	end

	return subPanel
end

local function SetupEasySetupPanel(mainWindow, standardSubPanel, setupData)
	local pageConfigs = setupData.pages
	local selectedOptions = {} -- Passed and modified by reference

	local function ApplyFunction(startGame)
		local battle = battleLobby:GetBattle(battleLobby:GetMyBattleID())
		setupData.ApplyFunction(battleLobby, selectedOptions)
		if startGame then
			if haveMapAndGame then
				WG.SteamCoopHandler.AttemptGameStart("skirmish", battle.gameName, battle.mapName, nil, true)
			else
				Spring.Echo("Do something if map or game is missing")
			end
		end
		standardSubPanel:SetVisibility(true)
	end

	local _, screenHeight = Spring.GetWindowGeometry()
	local panelOffset = math.max(8, math.min(60, ((screenHeight - 768)*0.16 + 8)))

	local pages = {}
	for i = 1, #pageConfigs do
		pages[i] = Control:New {
			x = 0,
			y = panelOffset,
			right = 0,
			bottom = 0,
			padding = {0, 0, 0, 0},
			parent = mainWindow,
		}
	end

	for i = 1, #pages do
		InitializeSetupPage(pages[i], screenHeight, pageConfigs[i], pages[i + 1], pages[i - 1], selectedOptions, ApplyFunction)
	end
end

local function InitializeControls(battleID, oldLobby, topPoportion, setupData)
	local battle = battleLobby:GetBattle(battleID)

	if not battle then
		Spring.Echo("Attempted to join missing battle", battleID, topPoportion)
		return false
	end

	local Configuration = WG.Chobby.Configuration
	if not Configuration.showMatchMakerBattles and battle.isMatchMaker then
		return
	end

	local isSingleplayer = (battleLobby.name == "singleplayer")
	local isHost = (not isSingleplayer) and (battleLobby:GetMyUserName() == battle.founder)

	local EXTERNAL_PAD_VERT = 9
	local EXTERNAL_PAD_HOR = 12
	local INTERNAL_PAD = 2

	local BOTTOM_SPACING = 50

	mainWindow = Control:New {
		x = 0,
		y = 0,
		width = "100%",
		height = "100%",
		resizable = false,
		padding = {0, 0, 0, 0},
	}

	local subPanel = Control:New {
		x = 0,
		y = 47,
		right = 0,
		bottom = 0,
		padding = {0, 0, 0, 0},
		parent = mainWindow,
	}
	if setupData and Configuration.simplifiedSkirmishSetup then
		subPanel:SetVisibility(false)
		SetupEasySetupPanel(mainWindow, subPanel, setupData)
	end

	local topPanel = Control:New {
		x = 0,
		y = 0,
		right = 0,
		bottom = (100 - topPoportion) .. "%",
		padding = {0, 0, 0, 0},
		parent = subPanel,
	}

	local bottomPanel = Control:New {
		x = 0,
		y = topPoportion .. "%",
		right = 0,
		bottom = 0,
		padding = {0, 0, 0, 0},
		parent = subPanel,
	}

	local playerPanel = Control:New {
		x = 0,
		y = 0,
		right = "52%",
		bottom = BOTTOM_SPACING,
		padding = {EXTERNAL_PAD_HOR, EXTERNAL_PAD_VERT, INTERNAL_PAD, INTERNAL_PAD},
		parent = topPanel,
	}

	local spectatorPanel = Control:New {
		x = "67%",
		y = 0,
		right = 0,
		bottom = 0,
		-- Add 7 to line up with chat
		padding = {INTERNAL_PAD, INTERNAL_PAD, EXTERNAL_PAD_HOR, EXTERNAL_PAD_VERT + 7},
		parent = bottomPanel,
	}

	local playerHandler = SetupPlayerPanel(playerPanel, spectatorPanel, battle, battleID)

	local votePanel = Control:New {
		x = 0,
		right = "33%",
		bottom = 0,
		height = BOTTOM_SPACING,
		padding = {EXTERNAL_PAD_HOR, INTERNAL_PAD, 1, INTERNAL_PAD},
		parent = topPanel,
	}

	local votePanel = SetupVotePanel(votePanel)

	local leftInfo = Control:New {
		x = "48%",
		y = 0,
		right = "33%",
		bottom = BOTTOM_SPACING,
		padding = {INTERNAL_PAD, EXTERNAL_PAD_VERT, 1, INTERNAL_PAD},
		parent = topPanel,
	}

	local rightInfo = Control:New {
		x = "67%",
		y = 0,
		right = 0,
		bottom = 0,
		padding = {1, EXTERNAL_PAD_VERT, EXTERNAL_PAD_HOR, INTERNAL_PAD},
		parent = topPanel,
	}

	local infoHandler = SetupInfoButtonsPanel(leftInfo, rightInfo, battle, battleID, battleLobby:GetMyUserName())

	local btnQuitBattle = Button:New {
		right = 11,
		y = 7,
		width = 80,
		height = 45,
		font = Configuration:GetFont(3),
		caption = (isSingleplayer and i18n("close")) or i18n("leave"),
		classname = "negative_button",
		OnClick = {
			function()
				battleLobby:LeaveBattle()
			end
		},
		parent = mainWindow,
	}

	local btnInviteFriends = Button:New {
		right = 101,
		y = 7,
		width = 180,
		height = 45,
		font = Configuration:GetFont(3),
		caption = i18n("invite_friends"),
		classname = "option_button",
		OnClick = {
			function()
				WG.SteamHandler.OpenFriendList()
			end
		},
		parent = mainWindow,
	}
	btnInviteFriends:SetVisibility(Configuration.canAuthenticateWithSteam)

	local battleTitle = ""
	local lblBattleTitle = Label:New {
		x = 20,
		y = 17,
		right = 100,
		height = 30,
		font = Configuration:GetFont(3),
		caption = "",
		parent = mainWindow,
		OnResize = {
			function (obj, xSize, ySize)
				obj:SetCaption(StringUtilities.GetTruncatedStringWithDotDot(battleTitle, obj.font, obj.width))
			end
		}
	}

	local battleTypeCombo
	if isHost then
		battleTypeCombo = ComboBox:New {
			x = 13,
			width = 125,
			y = 12,
			height = 35,
			itemHeight = 22,
			selectByName = true,
			captionHorAlign = -12,
			text = "",
			font = Configuration:GetFont(3),
			items = {"Coop", "Team", "1v1", "FFA", "Custom"},
			itemFontSize = Configuration:GetFont(3).size,
			selected = Configuration.battleTypeToHumanName[battle.battleMode or 0],
			OnSelectName = {
				function (obj, selectedName)
					if battleTypeCombo then
						battleLobby:SetBattleType(selectedName)
					end
				end
			},
			parent = mainWindow,
		}
		lblBattleTitle:BringToFront()
	end

	local function UpdateBattleTitle()
		if isSingleplayer then
			battleTitle = tostring(battle.title)
			local truncatedTitle = StringUtilities.GetTruncatedStringWithDotDot(battleTitle, lblBattleTitle.font, lblBattleTitle.width)
			lblBattleTitle:SetCaption(truncatedTitle)
			return
		end
		if Configuration.allEnginesRunnable or Configuration:IsValidEngineVersion(battle.engineVersion) then
			if battleTypeCombo then
				lblBattleTitle:SetPos(143)
				lblBattleTitle._relativeBounds.right = 100
				lblBattleTitle:UpdateClientArea()

				battleTypeCombo:SetVisibility(true)
				battleTypeCombo.selected = Configuration.battleTypeToHumanName[battle.battleMode or 0]
				battleTypeCombo.caption = Configuration.battleTypeToHumanName[battle.battleMode or 0]
				battleTypeCombo:Invalidate()
			end

			local battleTypeName = Configuration.battleTypeToName[battle.battleMode]
			if isHost then
				battleTitle = ": " .. tostring(battle.title)
			elseif battleTypeName then
				battleTitle = i18n(battleTypeName) .. ": " .. tostring(battle.title)
			else
				battleTitle = tostring(battle.title)
			end

			local truncatedTitle = StringUtilities.GetTruncatedStringWithDotDot(battleTitle, lblBattleTitle.font, lblBattleTitle.width)
			lblBattleTitle:SetCaption(truncatedTitle)
		else
			battleTitle = "\255\255\0\0Warning: Restart to get correct engine version"
			if battleTypeCombo then
				lblBattleTitle:SetPos(20)
				lblBattleTitle._relativeBounds.right = 100
				lblBattleTitle:UpdateClientArea()
				battleTypeCombo:SetVisibility(false)
			end
			local truncatedTitle = StringUtilities.GetTruncatedStringWithDotDot(battleTitle, lblBattleTitle.font, lblBattleTitle.width)
			lblBattleTitle:SetCaption(truncatedTitle)
		end
	end
	UpdateBattleTitle()

	local function MessageListener(message)
		if message:starts("/me ") then
			battleLobby:SayBattleEx(message:sub(5))
		else
			battleLobby:SayBattle(message)
		end
	end
	local battleRoomConsole = WG.Chobby.Console("Battleroom Chat", MessageListener, true, nil, true)

	local chatPanel = Control:New {
		x = 0,
		y = 0,
		bottom = 0,
		right = "33%",
		padding = {EXTERNAL_PAD_HOR, INTERNAL_PAD, INTERNAL_PAD, EXTERNAL_PAD_VERT},
		itemPadding = {0, 0, 0, 0},
		itemMargin = {0, 0, 0, 0},
		children = {
			battleRoomConsole.panel,
		},
		parent = bottomPanel,
	}

	local CHAT_MENTION = "\255\255\0\0"
	local CHAT_ME = Configuration.meColor

	-- External Functions
	local externalFunctions = {}

	function externalFunctions.ClearChatHistory()
		battleRoomConsole:ClearHistory()
	end

	function externalFunctions.OnBattleClosed(listener, closedBattleID)
		if battleID == closedBattleID and mainWindow then
			mainWindow:Dispose()
			mainWindow = nil
			if wrapperControl and wrapperControl.visible and wrapperControl.parent then
				wrapperControl:Hide()
			end
		end
	end

	function externalFunctions.GetInfoHandler()
		return infoHandler
	end

	function externalFunctions.UpdateInviteButton(newVisibile)
		btnInviteFriends:SetVisibility(newVisibile)
	end

	-- Lobby interface
	local function OnUpdateUserTeamStatus(listener, userName, allyNumber, isSpectator)
		infoHandler.UpdateUserTeamStatus(userName, allyNumber, isSpectator)
		playerHandler.UpdateUserTeamStatus(userName, allyNumber, isSpectator)
	end

	local function OnBattleIngameUpdate(listener, updatedBattleID, isRunning)
		infoHandler.BattleIngameUpdate(updatedBattleID, isRunning)
	end

	local function OnUpdateBattleInfo(listener, updatedBattleID, newInfo)
		if (newInfo.battleMode or newInfo.title or newInfo.engineVersion) and battleID == updatedBattleID then
			UpdateBattleTitle()
			if newInfo.battleMode then
				playerHandler.UpdateBattleMode(newInfo.disallowCustomTeams, newInfo.disallowBots)
				infoHandler.UpdateBattleMode(newInfo.disallowCustomTeams)
			end
		end

		infoHandler.UpdateBattleInfo(updatedBattleID, newInfo)
	end

	local function OnLeftBattle(listener, leftBattleID, userName)
		infoHandler.LeftBattle(leftBattleID, userName)
		playerHandler.LeftBattle(leftBattleID, userName)
	end

	local function OnJoinedBattle(listener, joinedBattleId, userName)
		infoHandler.JoinedBattle(joinedBattleId, userName)
	end

	local function OnRemoveAi(listener, botName)
		playerHandler.RemoveAi(botName)
	end

	local function OnVoteUpdate(listener, voteMessage, pollType, _, mapPoll, candidates, votesNeeded, pollUrl)
		votePanel.VoteUpdate(voteMessage, pollType, mapPoll, candidates, votesNeeded, pollUrl)
	end

	local function OnVoteEnd(listener, message, success)
		votePanel.VoteEnd(message, success)
	end

	local matchmakerCandidates = {
		{
			clickFunc = function()
				battleLobby:AcceptMatchMakingMatch()
			end,
			votes = 0,
		},
		{
			clickFunc = function()
				battleLobby:RejectMatchMakingMatch()
				votePanel.ImmediateVoteEnd()
			end,
			votes = 0,
		},
	}

	local function OnMatchMakerReadyCheck(_, secondsRemaining, minWinChance, isQuickPlay)
		if not isQuickPlay then
			return -- Handled by MM popup
		end
		matchmakerCandidates[1].votes = 0
		matchmakerCandidates[2].votes = 0
		votePanel.VoteUpdate("Do you want to play a small team game with players of similar skill?", "quickplay", false, matchmakerCandidates, MINIMUM_QUICKPLAY_PLAYERS)
	end

	local function OnMatchMakerReadyUpdate(_, readyAccepted, likelyToPlay, queueReadyCounts, battleSize, readyPlayers)
		if not votePanel.GetMatchmakerMode() then
			return
		end
		matchmakerCandidates[1].votes = queueReadyCounts.Teams
		matchmakerCandidates[2].votes = 0
		votePanel.VoteUpdate("Do you want to play a small team game with players of similar skill?", "quickplay", false, matchmakerCandidates, MINIMUM_QUICKPLAY_PLAYERS)
	end

	local function OnMatchMakerReadyResult(_, isBattleStarting, areYouBanned)
		if not votePanel.GetMatchmakerMode() then
			return
		end
		votePanel.VoteEnd((isBattleStarting and "Match starting") or "Not enough players", isBattleStarting)
	end

	local function OnSaidBattle(listener, userName, message)
		local myUserName = battleLobby:GetMyUserName()
		local iAmMentioned = myUserName and userName ~= myUserName and string.find(message, myUserName)
		local chatColour = (iAmMentioned and CHAT_MENTION) or nil
		battleRoomConsole:AddMessage(message, userName, false, chatColour, false)
	end

	local function OnSaidBattleEx(listener, userName, message)
		local myUserName = battleLobby:GetMyUserName()
		local iAmMentioned = myUserName and userName ~= myUserName and string.find(message, myUserName)
		local chatColour = (iAmMentioned and CHAT_MENTION) or CHAT_ME
		battleRoomConsole:AddMessage(message, userName, false, chatColour, true)
	end

	battleLobby:AddListener("OnUpdateUserTeamStatus", OnUpdateUserTeamStatus)
	battleLobby:AddListener("OnBattleIngameUpdate", OnBattleIngameUpdate)
	battleLobby:AddListener("OnUpdateBattleInfo", OnUpdateBattleInfo)
	battleLobby:AddListener("OnLeftBattle", OnLeftBattle)
	battleLobby:AddListener("OnJoinedBattle", OnJoinedBattle)
	battleLobby:AddListener("OnRemoveAi", OnRemoveAi)
	battleLobby:AddListener("OnVoteUpdate", OnVoteUpdate)
	battleLobby:AddListener("OnVoteEnd", OnVoteEnd)
	battleLobby:AddListener("OnSaidBattle", OnSaidBattle)
	battleLobby:AddListener("OnSaidBattleEx", OnSaidBattleEx)
	battleLobby:AddListener("OnBattleClosed", externalFunctions.OnBattleClosed)
	battleLobby:AddListener("OnMatchMakerReadyCheck", OnMatchMakerReadyCheck)
	battleLobby:AddListener("OnMatchMakerReadyUpdate", OnMatchMakerReadyUpdate)
	battleLobby:AddListener("OnMatchMakerReadyResult", OnMatchMakerReadyResult)

	local function OnDisposeFunction()
		emptyTeamIndex = 0

		oldLobby:RemoveListener("OnUpdateUserTeamStatus", OnUpdateUserTeamStatus)
		oldLobby:RemoveListener("OnBattleIngameUpdate", OnBattleIngameUpdate)
		oldLobby:RemoveListener("OnUpdateBattleInfo", OnUpdateBattleInfo)
		oldLobby:RemoveListener("OnLeftBattle", OnLeftBattle)
		oldLobby:RemoveListener("OnJoinedBattle", OnJoinedBattle)
		oldLobby:RemoveListener("OnRemoveAi", OnRemoveAi)
		oldLobby:RemoveListener("OnVoteUpdate", OnVoteUpdate)
		oldLobby:RemoveListener("OnVoteEnd", OnVoteEnd)
		oldLobby:RemoveListener("OnSaidBattle", OnSaidBattle)
		oldLobby:RemoveListener("OnSaidBattleEx", OnSaidBattleEx)
		oldLobby:RemoveListener("OnBattleClosed", externalFunctions.OnBattleClosed)
		oldLobby:RemoveListener("OnMatchMakerReadyCheck", OnMatchMakerReadyCheck)
		oldLobby:RemoveListener("OnMatchMakerReadyUpdate", OnMatchMakerReadyUpdate)
		oldLobby:RemoveListener("OnMatchMakerReadyResult", OnMatchMakerReadyResult)

		WG.BattleStatusPanel.RemoveBattleTab()
	end

	mainWindow.OnDispose = mainWindow.OnDispose or {}
	mainWindow.OnDispose[#mainWindow.OnDispose + 1] = OnDisposeFunction

	return mainWindow, externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

local BattleRoomWindow = {}

function BattleRoomWindow.ShowMultiplayerBattleRoom(battleID)

	if mainWindow then
		mainWindow:Dispose()
		mainWindow = nil
	end

	if multiplayerWrapper then
		WG.BattleStatusPanel.RemoveBattleTab()
		multiplayerWrapper:Dispose()
		multiplayerWrapper = nil
	end

	if singleplayerWrapper then
		singleplayerWrapper = nil
	end

	battleLobby = WG.LibLobby.lobby

	multiplayerWrapper = Control:New {
		x = 0,
		y = 0,
		width = "100%",
		height = "100%",
		resizable = false,
		padding = {0, 0, 0, 0},

		OnParent = {
			function(obj)
				if obj:IsEmpty() then
					wrapperControl = obj

					local battleWindow, functions = InitializeControls(battleID, battleLobby, 55)
					mainWindowFunctions = functions
					if battleWindow then
						obj:AddChild(battleWindow)
					end
				end
			end
		},
		OnHide = {
			function(obj)
				WG.BattleStatusPanel.RemoveBattleTab()
			end
		}
	}

	WG.BattleStatusPanel.AddBattleTab(multiplayerWrapper)

	UpdateArchiveStatus()

	battleLobby:SetBattleStatus({
		allyNumber = 0,
		isSpectator = false,
		sync = (haveMapAndGame and 1) or 2, -- 0 = unknown, 1 = synced, 2 = unsynced
	})
end

function BattleRoomWindow.GetSingleplayerControl(setupData)

	singleplayerWrapper = Control:New {
		name = "singleplayerWrapper",
		x = 0,
		y = 0,
		width = "100%",
		height = "100%",
		resizable = false,
		padding = {0, 0, 0, 0},

		OnParent = {
			function(obj)

				if multiplayerWrapper then
					WG.BattleStatusPanel.RemoveBattleTab()

					if mainWindow then
						mainWindow:Dispose()
						mainWindow = nil
					end
					WG.LibLobby.lobby:LeaveBattle()
					multiplayerWrapper = nil
				elseif mainWindow then
					return
				end

				local singleplayerDefault = WG.Chobby.Configuration.gameConfig.skirmishDefault

				local defaultMap = "Red Comet"
				if singleplayerDefault and singleplayerDefault.map then
					defaultMap = singleplayerDefault.map
				end

				battleLobby = WG.LibLobby.localLobby
				battleLobby:SetBattleState(WG.Chobby.Configuration:GetPlayerName(), singleplayerGame, defaultMap, "Skirmish Battle")

				wrapperControl = obj

				local battleWindow, functions = InitializeControls(1, battleLobby, 70, setupData)
				mainWindowFunctions = functions
				if not battleWindow then
					return
				end

				obj:AddChild(battleWindow)

				UpdateArchiveStatus()

				battleLobby:SetBattleStatus({
					allyNumber = 0,
					isSpectator = false,
					sync = (haveMapAndGame and 1) or 2, -- 0 = unknown, 1 = synced, 2 = unsynced
				})

				if not (setupData and WG.Chobby.Configuration.simplifiedSkirmishSetup) and singleplayerDefault and singleplayerDefault.enemyAI then
					battleLobby:AddAi(singleplayerDefault.enemyAI .. " (1)", singleplayerDefault.enemyAI, 1)
				end
			end
		},
	}

	return singleplayerWrapper
end

function BattleRoomWindow.SetSingleplayerGame(ToggleShowFunc, battleroomObj, tabData)

	local function SetGameFail()
		WG.LibLobby.localLobby:LeaveBattle()
	end

	local function SetGameSucess(name)
		singleplayerGame = name
		ToggleShowFunc(battleroomObj, tabData)
	end

	local config = WG.Chobby.Configuration
	local skirmishGame = config:GetDefaultGameName()
	if skirmishGame then
		SetGameSucess(skirmishGame)
	else
		WG.Chobby.GameListWindow(SetGameFail, SetGameSucess)
	end
end

function BattleRoomWindow.LeaveBattle(onlyMultiplayer, onlySingleplayer)
	if not battleLobby then
		return
	end

	if onlyMultiplayer and battleLobby.name == "singleplayer" then
		return
	end

	if onlySingleplayer and battleLobby.name == "singleplayer" then
		if mainWindow then
			mainWindow:Dispose()
			mainWindow = nil
		end
		return
	end

	battleLobby:LeaveBattle()
	if mainWindowFunctions then
		mainWindowFunctions.OnBattleClosed(_, battleLobby:GetMyBattleID())
	end

	WG.BattleStatusPanel.RemoveBattleTab()
end

function BattleRoomWindow.ClearChatHistory()
	if mainWindowFunctions and mainWindowFunctions.ClearChatHistory then
		mainWindowFunctions.ClearChatHistory()
	end
end
local function DelayedInitialize()
	local function onConfigurationChange(listener, key, value)
		if mainWindowFunctions and key == "canAuthenticateWithSteam" then
			mainWindowFunctions.UpdateInviteButton(value)
		end
	end
	WG.Chobby.Configuration:AddListener("OnConfigurationChange", onConfigurationChange)
end

function widget:Initialize()
	CHOBBY_DIR = LUA_DIRNAME .. "widgets/chobby/"
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	local function downloadFinished()
		UpdateArchiveStatus(true)
	end
	WG.DownloadHandler.AddListener("DownloadFinished", downloadFinished)

	WG.BattleRoomWindow = BattleRoomWindow
	WG.Delay(DelayedInitialize, 0.5)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
