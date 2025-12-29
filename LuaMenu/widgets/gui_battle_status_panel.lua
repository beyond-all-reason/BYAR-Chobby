--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Battle status panel",
		desc      = "Displays battles status.",
		author    = "gajop",
		date      = "4 July 2016",
		license   = "GNU LGPL, v2.1 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

local IMG_BATTLE_RUNNING     = LUA_DIRNAME .. "images/runningBattle.png"
local IMG_BATTLE_NOT_RUNNING = LUA_DIRNAME .. "images/nothing.png"
local IMG_STATUS_SPECTATOR   = LUA_DIRNAME .. "images/spectating.png"
local IMG_STATUS_PLAYER      = LUA_DIRNAME .. "images/playing.png"

local PLAYER_PREFIX_BIG = "Players: "
local PLAYER_PREFIX_SMALL = ""

------------------------------------------------------------------
------------------------------------------------------------------
-- Info Handlers

local function GetBattleInfoHolder(parent, battleID)
	local externalFunctions = {}

	local playersPrefix = PLAYER_PREFIX_BIG

	local battle = lobby:GetBattle(battleID)
	if not battle then
		return nil
	end

	local Configuration = WG.Chobby.Configuration

	local mainControl = Control:New {
		x = 0,
		y = 0,
		right = 0,
		height = 120,
		padding = {0, 0, 0, 0},
		parent = parent,
	}

	local lblTitle = Label:New {
		name = "title",
		x = 70,
		y = 0,
		width = 225,
		height = 20,
		valign = 'top',
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		parent = mainControl,
	}
	local text = StringUtilities.GetTruncatedStringWithDotDot(battle.title, lblTitle.font, lblTitle.width)
	lblTitle:SetCaption(text)

	local lblPlayerStatus = Label:New {
		name = "lblPlayerStatus",
		x = 108,
		width = 150,
		y = 30,
		height = 20,
		valign = 'top',
		caption = "Spectator",
		parent = mainControl,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
	}
	local imPlayerStatus = Image:New {
		name = "imPlayerStatus",
		x = 84,
		width = 20,
		y = 27,
		height = 20,
		file = IMG_STATUS_SPECTATOR,
		parent = mainControl,
	}

	local lblPlayers = Label:New {
		name = "playersCaption",
		x = 84,
		width = 150,
		y = 54,
		height = 20,
		valign = 'top',
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		caption = playersPrefix .. lobby:GetPlayerOccupancy(battleID),
		parent = mainControl,
	}

	local minimap = Panel:New {
		x = 2,
		y = 2,
		width = 73,
		height = 73,
		padding = {1,1,1,1},
		parent = mainControl,
	}

	local mapImageFile, needDownload = Configuration:GetMinimapSmallImage(battle.mapName)
	local minimapImage = Image:New {
		name = "minimapImage",
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		keepAspect = true,
		file = mapImageFile,
		fallbackFile = Configuration:GetLoadingImage(2),
		checkFileExists = needDownload,
		parent = minimap,
	}
	local runningImage = Image:New {
		name = "runningImage",
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		keepAspect = false,
		file = (battle.isRunning and IMG_BATTLE_RUNNING) or IMG_BATTLE_NOT_RUNNING,
		parent = minimap,
	}
	runningImage:BringToFront()
	imPlayerStatus:BringToFront()

	local currentSmallMode = false

	function externalFunctions.Resize(smallMode)
		currentSmallMode = smallMode

		if smallMode then
			minimap:SetPos(nil, nil, 30, 30)

			lblTitle.font = WG.Chobby.Configuration:GetFont(1)
			lblTitle:SetPos(36, 1, 150)

			lblPlayerStatus.font = WG.Chobby.Configuration:GetFont(1)
			lblPlayerStatus:SetPos(58, 18)

			imPlayerStatus:SetPos(43, 18, 12, 12)

			lblPlayers.font = WG.Chobby.Configuration:GetFont(1)
			lblPlayers:SetPos(165, 18)

			playersPrefix = PLAYER_PREFIX_SMALL
		else
			minimap:SetPos(nil, nil, 68, 68)

			lblTitle.font = WG.Chobby.Configuration:GetFont(2)
			lblTitle:SetPos(76, 2, 225)

			lblPlayerStatus.font = WG.Chobby.Configuration:GetFont(2)
			lblPlayerStatus:SetPos(103, 26)

			imPlayerStatus:SetPos(82, 26, 18, 18)

			lblPlayers.font = WG.Chobby.Configuration:GetFont(2)
			lblPlayers:SetPos(80, 48)

			playersPrefix = PLAYER_PREFIX_BIG
		end
		local text = StringUtilities.GetTruncatedStringWithDotDot(battle.title, lblTitle.font, smallMode and 150 or 180)
		lblTitle:SetCaption(text)

		lblPlayers:SetCaption(playersPrefix .. lobby:GetPlayerOccupancy(battleID))
	end

	function externalFunctions.Update(newBattleID)
		battleID = newBattleID
		battle = lobby:GetBattle(battleID)
		if not battle then
			return
		end

		if not mainControl.visible then
			mainControl:Show()
		end

		minimapImage.file, minimapImage.checkFileExists = Configuration:GetMinimapSmallImage(battle.mapName)
		minimapImage:Invalidate()

		runningImage.file = (battle.isRunning and IMG_BATTLE_RUNNING) or IMG_BATTLE_NOT_RUNNING
		runningImage:Invalidate()
	end

	local function OnUpdateBattleInfo(listeners, updatedBattleID)
		if updatedBattleID ~= battleID then
			return
		end

		minimapImage.file, minimapImage.checkFileExists = Configuration:GetMinimapSmallImage(battle.mapName)
		minimapImage:Invalidate()

		externalFunctions.Resize(currentSmallMode)

		lblPlayers:SetCaption(playersPrefix .. lobby:GetPlayerOccupancy(battleID))
	end
	lobby:AddListener("OnUpdateBattleInfo", OnUpdateBattleInfo)

	local function OnUpdateBattleTitle(listeners, updatedBattleID, battleTitle)
		if updatedBattleID ~= battleID then
			return
		end

		externalFunctions.Resize(currentSmallMode)
	end
	lobby:AddListener("OnUpdateBattleTitle", OnUpdateBattleTitle)

	local function OnBattleIngameUpdate(listeners, updatedBattleID)
		if updatedBattleID ~= battleID then
			return
		end
		runningImage.file = (battle.isRunning and IMG_BATTLE_RUNNING) or IMG_BATTLE_NOT_RUNNING
		runningImage:Invalidate()
	end
	lobby:AddListener("OnBattleIngameUpdate", OnBattleIngameUpdate)

	local function PlayersUpdate(listeners, updatedBattleID)
		if updatedBattleID ~= battleID then
			return
		end
		lblPlayers:SetCaption(playersPrefix .. lobby:GetPlayerOccupancy(battleID))
	end
	lobby:AddListener("OnLeftBattle", PlayersUpdate)
	lobby:AddListener("OnJoinedBattle", PlayersUpdate)

	local function OnUpdateUserTeamStatus(listeners)
		lblPlayers:SetCaption(playersPrefix .. lobby:GetPlayerOccupancy(battleID))
	end
	lobby:AddListener("OnUpdateUserTeamStatus", OnUpdateUserTeamStatus)

	onUpdateUserTeamStatus = function(listener, userName, allyNumber, isSpectator, queuePos)
		if userName ~= lobby:GetMyUserName() then
			return
		end
		if isSpectator then
			if queuePos and queuePos > 0 then
				lblPlayerStatus:SetCaption("Join-Queue")
			else
				lblPlayerStatus:SetCaption("Spectator")
			end
			imPlayerStatus.file = IMG_STATUS_SPECTATOR
			imPlayerStatus:Invalidate()
		else
			lblPlayerStatus:SetCaption("Player")
			imPlayerStatus.file = IMG_STATUS_PLAYER
			imPlayerStatus:Invalidate()
		end
	end
	lobby:AddListener("OnUpdateUserTeamStatus", onUpdateUserTeamStatus)

	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Initialization

local function InitializeControls(parentControl)
	local statusWindowHandler = WG.Chobby.interfaceRoot.GetBattleStatusWindowHandler()

	local infoHolder = Panel:New {
		x = 68,
		right = 4,
		y = 4,
		bottom = 4,
		parent = parentControl,
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
	}
	--local lblBattle = Label:New {
	--	name = "lblBattle",
	--	x = 8,
	--	width = 85,
	--	y = 27,
	--	height = 20,
	--	align = "left",
	--	valign = "center",
	--	caption = "Battle",
	--	parent = parentControl,
	--	objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
	--}

	local battleInfoHolder = GetBattleInfoHolder(infoHolder, lobby:GetMyBattleID())

	parentControl.OnResize = parentControl.OnResize or {}
	parentControl.OnResize[#parentControl.OnResize + 1] = function (obj, xSize, ySize)
		local smallMode = (ySize < 60)
		if smallMode then
			infoHolder:SetPos(nil, 2, 237)
			infoHolder._relativeBounds.left = 2
			infoHolder._relativeBounds.top = 2
			infoHolder._relativeBounds.bottom = 2
			infoHolder._relativeBounds.right = 2
			infoHolder:UpdateClientArea()

			--lblBattle:SetPos(nil, 6)
		else
			infoHolder:SetPos(nil, 4, 237)
			infoHolder._relativeBounds.left = 3
			infoHolder._relativeBounds.top = 3
			infoHolder._relativeBounds.bottom = 3
			infoHolder._relativeBounds.right = 3
			infoHolder:UpdateClientArea()

			--lblBattle:SetPos(nil, 24)
		end
		if battleInfoHolder then
			battleInfoHolder.Resize(smallMode)
		end
	end

	local unreadMessages = 0
	local voting = false

	parentControl.tooltip = "battle_tooltip_" .. (lobby:GetMyBattleID() or 0)

	parentControl.OnClick = parentControl.OnClick or {}
	parentControl.OnClick[#parentControl.OnClick + 1] = function (obj)
		if unreadMessages > 0 then
			unreadMessages = 0
			statusWindowHandler.SetActivity("myBattle", unreadMessages)
		end
	end

	local function OnSaidBattle(listeners, userName, message)
		local userInfo = lobby:TryGetUser(userName)
		local myUserName = lobby:GetMyUserName()
		if userInfo.isBot then
			return
		end
		local iAmMentioned = myUserName and (string.find(message, myUserName, 1, true) and userName ~= myUserName)
		if statusWindowHandler.IsTabSelected("myBattle") then
			voting = false
			if unreadMessages > 0 then
				unreadMessages = 0
				statusWindowHandler.SetActivity("myBattle", unreadMessages)
			end
			return
		end
		unreadMessages = unreadMessages + 1
		statusWindowHandler.SetActivity("myBattle", unreadMessages, iAmMentioned and 2)
	end
	lobby:AddListener("OnSaidBattle", OnSaidBattle)
	lobby:AddListener("OnSaidBattleEx", OnSaidBattle)

	local function OnVoteUpdate()
		if statusWindowHandler.IsTabSelected("myBattle") then
			voting = false
			if unreadMessages > 0 then
				unreadMessages = 0
				statusWindowHandler.SetActivity("myBattle", unreadMessages)
			end
			return
		end
		if not voting then
			unreadMessages = unreadMessages + 1
			statusWindowHandler.SetActivity("myBattle", unreadMessages, 3)
			voting = true
		end
	end
	lobby:AddListener("OnVoteUpdate", OnVoteUpdate)

	local function OnVoteEnd()
		voting = false
	end
	lobby:AddListener("OnVoteEnd", OnVoteEnd)

	local function onJoinBattle(listener, battleID)
		parentControl.tooltip = "battle_tooltip_" .. battleID
		battleInfoHolder.Update(battleID)
	end
	lobby:AddListener("OnJoinBattle", onJoinBattle)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- External functions

local BattleStatusPanel = {}

function BattleStatusPanel.GetControl(fontSizeScale)
	local button = Button:New {
		x = 0,
		y = 0,
		width = 290,
		bottom = 0,
		padding = {0,0,0,0},
		objectOverrideFont = WG.Chobby.Configuration:GetFont(fontSizeScale),
		caption = "",
		OnParent = {
			function(obj)
				if obj:IsEmpty() then
					InitializeControls(obj)
				end
			end
		},
	}
	return button
end

function BattleStatusPanel.AddBattleTab(control)
	local interfaceRoot = WG.Chobby.interfaceRoot
	local tabPanel = interfaceRoot.GetBattleStatusWindowHandler()
	tabPanel.AddTab("myBattle", "My Battle", control, false, 3, true)
	interfaceRoot.SetBattleTabHolderVisible(true, 10)
end

function BattleStatusPanel.RemoveBattleTab()
	local interfaceRoot = WG.Chobby.interfaceRoot
	local tabPanel = interfaceRoot.GetBattleStatusWindowHandler()
	interfaceRoot.SetBattleTabHolderVisible(false)
	tabPanel.RemoveTab("myBattle", true)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

function widget:Initialize()

	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	WG.BattleStatusPanel = BattleStatusPanel
end

function widget:Shutdown()
	if lobby then
		lobby:RemoveListener("OnUpdateUserTeamStatus", onUpdateUserTeamStatus)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
