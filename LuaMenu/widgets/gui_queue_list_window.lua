--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Queue List Window",
		desc      = "Handles matchMaking queue list display.",
		author    = "GoogleFrog",
		date      = "11 September 2016",
		license   = "GNU LGPL, v2.1 or later",
		layer     = -100000,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Variables

local DEBRIEFING_CHANNEL = "debriefing"

local requiredResources = {}
local requiredResourceCount = 0

local panelInterface

local function HaveRightEngineVersion()
	local configuration = WG.Chobby.Configuration
	if configuration.useWrongEngine then
		return true
	end
	local engineVersion = WG.LibLobby.lobby:GetSuggestedEngineVersion()
	return (not engineVersion) or configuration:IsValidEngineVersion(engineVersion)
end

local BAN_TIME_FORGET_SECONDS = 60*15
local BAN_BASE = 90 -- From match proposed, not from timeout.
local BAN_ADD = 60
local BAN_MAX_COUNT = 5

local function GetCombinedBannedTime(banTimeFromServer)
	local configuration = WG.Chobby.Configuration
	local rejectTime = configuration.matchmakerRejectTime
	local rejectCount = configuration.matchmakerRejectCount
	if not (rejectTime and rejectCount) then
		return banTimeFromServer
	end
	local timeDiff, inFuture = Spring.Utilities.GetTimeDifferenceTable(Spring.Utilities.TimeStringToTable(rejectTime))
	if inFuture or (not timeDiff) then
		configuration:SetConfigValue("matchmakerRejectTime", false)
		configuration:SetConfigValue("matchmakerRejectCount", false)
		return banTimeFromServer
	end
	timeDiff = Spring.Utilities.TimeToSeconds(timeDiff)
	if timeDiff > BAN_TIME_FORGET_SECONDS then
		configuration:SetConfigValue("matchmakerRejectTime", false)
		configuration:SetConfigValue("matchmakerRejectCount", false)
		return banTimeFromServer
	end

	local banTime = BAN_BASE + BAN_ADD*(math.min(rejectCount, BAN_MAX_COUNT) - 1) - timeDiff
	if banTimeFromServer and (banTimeFromServer > banTime) then
		banTime = banTimeFromServer
	end
	return (banTime > 0) and banTime
end

local queueSortOverride = {
	["Coop"] = "A",
	["1v1"] = "AA",
	["Teams"] = "AAA",
	["Sortie"] = "AAAA",
	["Battle"] = "AAAAA",
}

local function QueueSortFunc(a, b)
	return (queueSortOverride[a.name] or a.name) < (queueSortOverride[b.name] or b.name)
end

local function GetQueuePos(pos)
	return pos*55 + 15
end

WG.GetCombinedBannedTime = GetCombinedBannedTime

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Initialization

local function MakeQueueControl(parentControl, pos, queueName, queueDescription, players, waiting, maxPartySize, GetBanTime)
	local Configuration = WG.Chobby.Configuration
	local lobby = WG.LibLobby.lobby
	local btnLeave, btnJoin

	local currentPartySize = 1
	local inQueue = false

	local queueHolder = Control:New {
		x = 10,
		y = GetQueuePos(pos),
		right = 0,
		height = 45,
		caption = "", -- Status Window
		parent = parentControl,
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
	}

	btnJoin = Button:New {
		x = 0,
		y = 0,
		width = 80,
		bottom = 0,
		caption = i18n("join"),
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		classname = "option_button",
		OnClick = {
			function(obj)
				local banTime = GetBanTime()
				if banTime then
					WG.Chobby.InformationPopup("You are currently banned from matchmaking.\n" .. banTime .. " seconds remaining.")
					return
				end
				if not HaveRightEngineVersion() then
					WG.Chobby.InformationPopup("Engine update required, restart the game to apply.")
					return
				end
				if requiredResourceCount ~= 0 then
					WG.Chobby.InformationPopup("All required maps and games must be downloaded before you can join matchmaking.")
					return
				end

				lobby:JoinMatchMaking(queueName)
				obj:SetVisibility(false)
				btnLeave:SetVisibility(true)
				WG.Analytics.SendOnetimeEvent("lobby:multiplayer:matchmaking:join_" .. queueName)
			end
		},
		parent = queueHolder
	}

	btnLeave = Button:New {
		x = 0,
		y = 0,
		width = 80,
		bottom = 0,
		caption = i18n("leave"),
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		classname = "action_button",
		OnClick = {
			function(obj)
				lobby:LeaveMatchMaking(queueName)
				obj:SetVisibility(false)
				btnJoin:SetVisibility(true)
			end
		},
		parent = queueHolder
	}
	btnLeave:SetVisibility(false)

	local labelDisabled = TextBox:New {
		x = 0,
		y = 18,
		width = 120,
		height = 22,
		right = 5,
		align = "bottom",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(1),
		text = "Party too large",
		parent = queueHolder
	}
	labelDisabled:SetVisibility(false)

	local lblTitle = TextBox:New {
		x = 105,
		y = 15,
		width = 120,
		height = 33,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		text = queueName,
		parent = queueHolder
	}

	local lblDescription = TextBox:New {
		x = 180,
		y = 8,
		width = 120,
		height = 22,
		right = 5,
		align = "bottom",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(1),
		text = queueDescription,
		parent = queueHolder
	}

	local lblPlayers = TextBox:New {
		x = 180,
		y = 30,
		width = 120,
		height = 22,
		right = 5,
		align = "bottom",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(1),
		text = "Playing: " .. players,
		parent = queueHolder
	}

	local lblWaiting = TextBox:New {
		x = 280,
		y = 30,
		width = 120,
		height = 22,
		right = 5,
		align = "bottom",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(1),
		text = "Waiting: " .. waiting,
		parent = queueHolder
	}

	local function UpdateButton()
		if maxPartySize and (currentPartySize > maxPartySize) then
			btnJoin:SetVisibility(false)
			btnLeave:SetVisibility(false)
			labelDisabled:SetVisibility(true)
		else
			btnJoin:SetVisibility(not inQueue)
			btnLeave:SetVisibility(inQueue)
			labelDisabled:SetVisibility(false)
		end
	end

	local externalFunctions = {}

	function externalFunctions.SetPos(newPos)
		queueHolder:SetPos(nil, GetQueuePos(pos))
	end

	function externalFunctions.SetInQueue(newInQueue)
		if newInQueue == inQueue then
			return
		end
		inQueue = newInQueue
		UpdateButton()
	end

	function externalFunctions.UpdateCurrentPartySize(newCurrentPartySize)
		if newCurrentPartySize == currentPartySize then
			return
		end
		currentPartySize = newCurrentPartySize
		UpdateButton()
	end

	function externalFunctions.UpdateQueueInformation(newName, newDescription, newPlayers, newWaiting, newMaxPartySize)
		if newName then
			lblTitle:SetText(newName)
		end
		if newDescription then
			lblDescription:SetText(newDescription)
		end
		if newPlayers then
			lblPlayers:SetText("Playing: " .. newPlayers)
		end
		if newWaiting then
			lblWaiting:SetText("Waiting: " .. newWaiting)
		end
	end

	return externalFunctions
end

local function GetDebriefingChat(window, vertPos, channelName, RemoveFunction)
	local Configuration = WG.Chobby.Configuration
	local lobby = WG.LibLobby.lobby

	local function MessageListener(message)
		if message:starts("/me ") then
			lobby:SayEx(channelName, message:sub(5))
		else
			lobby:Say(channelName, message)
		end
	end
	local debriefingConsole = WG.Chobby.Console("Debriefing Chat", MessageListener, true)
	local userListPanel = WG.Chobby.UserListPanel(function() return lobby:GetChannel(channelName) end, 22, nil, WG.UserHandler.GetDebriefingUser)

	local chatPanel = Control:New {
		x = 0,
		y = vertPos,
		bottom = 0,
		right = "33%",
		padding = {12, 2, 2, 9},
		itemPadding = {0, 0, 0, 0},
		itemMargin = {0, 0, 0, 0},
		children = {
			debriefingConsole.panel
		},
		parent = window,
	}
	local spectatorPanel = Control:New {
		x = "67%",
		y = vertPos,
		right = 0,
		bottom = 0,
		-- Add 7 to line up with chat
		padding = {2, 2, 12, 16},
		parent = window,
		children = {
			userListPanel.panel
		},
	}

	local externalFunctions = {}

	local closeChannelButton = Button:New {
		width = 24, height = 24, y = 5, right = 12,
		caption = "x",
		OnClick = {
			function()
				RemoveFunction()
			end
		},
		parent = chatPanel,
	}
	closeChannelButton:BringToFront()

	window:Invalidate()

	function externalFunctions.UpdateUsers()
		userListPanel:Update()
	end

	function externalFunctions.AddMessage(message, userName, msgDate, chatColour, thirdPerson)
		debriefingConsole:AddMessage(message, userName, msgDate, chatColour, thirdPerson)
	end

	function externalFunctions.SetTopic(message)
		debriefingConsole:SetTopic(message)
	end

	function externalFunctions.Delete()
		debriefingConsole:Delete()
		userListPanel:Delete()
		chatPanel:Dispose()
		spectatorPanel:Dispose()
	end

	return externalFunctions
end

local function SetupDebriefingTracker(window)
	local Configuration = WG.Chobby.Configuration
	local lobby = WG.LibLobby.lobby

	local debriefingChat
	local debriefingChannelName
	local ignoredChannels = {}
	local channelTopics = {}

	local function RemoveFunction()
		if debriefingChannelName then
			lobby:Leave(debriefingChannelName)
		end
		if debriefingChat then
			debriefingChat.Delete()
		end
		debriefingChannelName = nil
		debriefingChat = nil
	end

	local function OnJoin(listener, chanName)
		if (not string.find(chanName, DEBRIEFING_CHANNEL, 1, true)) or ignoredChannels[chanName] or chanName == debriefingChannelName then
			return
		end
		if debriefingChannelName then
			lobby:Leave(debriefingChannelName)
			ignoredChannels[debriefingChannelName] = true
		end
		if debriefingChat then
			debriefingChat.Delete()
		end
		debriefingChannelName = chanName
		debriefingChat = GetDebriefingChat(window, 430, debriefingChannelName, RemoveFunction)
		WG.Chobby.interfaceRoot.OpenMultiplayerTabByName("matchmaking")

		if channelTopics[debriefingChannelName] then
			debriefingChat.SetTopic("Post game chat")
			debriefingChat.SetTopic(channelTopics[debriefingChannelName])
			channelTopics = {}
		end
	end
	lobby:AddListener("OnJoin", OnJoin)

	local function UpdateUsers(listener, chanName, userName)
		if not (chanName == debriefingChannelName and debriefingChat) then
			return
		end
		debriefingChat.UpdateUsers()
	end
	lobby:AddListener("OnJoined", UpdateUsers)
	lobby:AddListener("OnLeft", UpdateUsers)
	lobby:AddListener("OnClients", UpdateUsers)

	local CHAT_MENTION ="\255\255\0\0"

	-- channel chat
	local function OnSaid(listener, chanName, userName, message, msgDate)
		if not (chanName == debriefingChannelName and debriefingChat) then
			return
		end
		local iAmMentioned = (string.find(message, lobby:GetMyUserName(), 1, true) and userName ~= lobby:GetMyUserName())
		debriefingChat.AddMessage(message, userName, msgDate, iAmMentioned and CHAT_MENTION)
	end
	lobby:AddListener("OnSaid", OnSaid)

	local function OnSaidEx(listener, chanName, userName, message, msgDate)
		if not (chanName == debriefingChannelName and debriefingChat) then
			return
		end
		local iAmMentioned = (string.find(message, lobby:GetMyUserName(), 1, true) and userName ~= lobby:GetMyUserName())
		debriefingChat.AddMessage(message, userName, msgDate, (iAmMentioned and CHAT_MENTION) or Configuration.meColor, true)
	end
	lobby:AddListener("OnSaidEx", OnSaidEx)

	local function OnBattleDebriefing(listener, url, chanName, serverBattleID, userList)
		local debriefTopic = "Battle link: " .. (url or "not found")
		if debriefingChannelName == chanName and debriefingChat then
			debriefingChat.SetTopic("Post game chat") -- URL doesn't work on line one.
			debriefingChat.SetTopic(debriefTopic)
		elseif chanName and string.find(chanName, DEBRIEFING_CHANNEL, 1, true) then
			channelTopics[debriefingChannelName] = debriefTopic
		end
	end
	lobby:AddListener("OnBattleDebriefing", OnBattleDebriefing)

	local function OnBattleAboutToStart(listener)
		RemoveFunction()
	end
	lobby:AddListener("OnBattleAboutToStart", OnBattleAboutToStart)
end

local function InitializeControls(window)
	local Configuration = WG.Chobby.Configuration
	local lobby = WG.LibLobby.lobby

	local banStart
	local banDuration

	local lblTitle = Label:New {
		x = 20,
		right = 5,
		y = 17,
		height = 20,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		caption = "Join matchmaking queues",
		parent = window
	}

	local btnClose = Button:New {
		right = 12,
		y = 7,
		width = 80,
		height = 45,
		caption = i18n("close"),
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		classname = "negative_button",
		OnClick = {
			function()
				window:Hide()
			end
		},
		parent = window
	}

	local btnInviteFriends = Button:New {
		right = 101,
		y = 7,
		width = 180,
		height = 45,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		caption = i18n("invite_friends"),
		classname = "option_button",
		OnClick = {
			function()
				WG.SteamHandler.OpenFriendList()
			end
		},
		parent = window,
	}
	btnInviteFriends:SetVisibility(Configuration.canAuthenticateWithSteam)

	local listPanel = ScrollPanel:New {
		x = 5,
		right = 5,
		y = 55,
		height = 250,
		borderColor = {0,0,0,0},
		horizontalScrollbar = false,
		parent = window
	}

	local statusText = TextBox:New {
		x = 12,
		right = 5,
		y = 320,
		height = 200,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		text = "",
		parent = window
	}

	local requirementText = TextBox:New {
		x = 12,
		right = 5,
		y = 400,
		height = 200,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		text = "",
		parent = window
	}

	local function GetBanTime()
		if banStart and banDuration then
			return (banDuration or 0) - math.ceil(Spring.DiffTimers(Spring.GetTimer(), banStart))
		end
		return false
	end

	local queues = 0
	local queueHolders = {}
	local function AddQueue(_, queueName, queueDescription, mapNames, maxPartySize)
		local queueData = lobby:GetQueue(queueName) or {}
		if queueHolders[queueName] then
			queueHolders[queueName].UpdateQueueInformation(queueName, queueDescription, queueData.playersIngame or "?", queueData.playersWaiting or "?", maxPartySize)
			return
		end

		queueHolders[queueName] = MakeQueueControl(listPanel, queues, queueName, queueDescription, queueData.playersIngame or "?", queueData.playersWaiting or "?", maxPartySize, GetBanTime)
		queues = queues + 1

		local possibleQueues = lobby:GetQueues()
		local sortedQueues = {}

		for name, data in pairs(possibleQueues) do
			sortedQueues[#sortedQueues + 1] = data
		end
		for i = 1, #sortedQueues do
			local data = sortedQueues[i]
			if queueHolders[data.name] then
				queueHolders[data.name].SetPos(i)
			end
		end
	end

	local function InitializeQueues()
		local possibleQueues = lobby:GetQueues()
		local sortedQueues = {}

		for name, data in pairs(possibleQueues) do
			sortedQueues[#sortedQueues + 1] = data
		end

		table.sort(sortedQueues, QueueSortFunc)
		local added = {}
		for i = 1, #sortedQueues do
			local data = sortedQueues[i]
			if not added[data.name] then
				AddQueue(_, data.name, data.description, data.mapNames, data.maxPartySize)
			end
		end
	end

	local function UpdateBannedTime(bannedTime)
		bannedTime = GetCombinedBannedTime(bannedTime)
		if bannedTime then
			statusText:SetText("You are banned from matchmaking for " .. bannedTime .. " seconds")
			banStart = Spring.GetTimer()
			banDuration = bannedTime
			for queueName, queueHolder in pairs(queueHolders) do
				queueHolder.SetInQueue(false)
			end
			return true
		end
	end

	local function UpdateQueueStatus(listener, inMatchMaking, joinedQueueList, queueCounts, ingameCounts, _, _, _, bannedTime)
		local joinedQueueNames = {}
		if joinedQueueList then
			for i = 1, #joinedQueueList do
				local queueName = joinedQueueList[i]
				if queueHolders[queueName] then
					joinedQueueNames[queueName] = true
					queueHolders[queueName].SetInQueue(true)
				end
			end
		end

		if queueCounts then
			for queueName, waitingCount in pairs(queueCounts) do
				queueHolders[queueName].UpdateQueueInformation(nil, nil, ingameCounts and ingameCounts[queueName], waitingCount)
			end
		end

		for queueName, queueHolder in pairs(queueHolders) do
			if not joinedQueueNames[queueName] then
				queueHolder.SetInQueue(false)
			end
		end

		if not UpdateBannedTime(bannedTime) then
			banDuration = false
		end
	end

	local function OnPartyUpdate(listener, partyID, partyUsers)
		if lobby:GetMyPartyID() ~= partyID then
			return
		end
		for name, queueHolder in pairs(queueHolders) do
			queueHolder.UpdateCurrentPartySize(#partyUsers)
		end
	end

	local function OnPartyLeft(listener, partyID, partyUsers)
		for name, queueHolder in pairs(queueHolders) do
			queueHolder.UpdateCurrentPartySize(1)
		end
	end

	lobby:AddListener("OnQueueOpened", AddQueue)
	lobby:AddListener("OnMatchMakerStatus", UpdateQueueStatus)

	lobby:AddListener("OnPartyCreate", OnPartyUpdate)
	lobby:AddListener("OnPartyUpdate", OnPartyUpdate)
	lobby:AddListener("OnPartyDestroy", OnPartyUpdate)
	lobby:AddListener("OnPartyLeft", OnPartyLeft)

	local function onConfigurationChange(listener, key, value)
		if key == "canAuthenticateWithSteam" then
			btnInviteFriends:SetVisibility(value)
		end
		if key == "matchmakerRejectTime" then
			UpdateBannedTime(banDuration)
		end
	end
	Configuration:AddListener("OnConfigurationChange", onConfigurationChange)

	-- Initialization
	InitializeQueues()
	UpdateBannedTime(lobby.matchMakerBannedTime)

	if lobby:GetMyPartyID() then
		OnPartyUpdate(_, lobby:GetMyPartyID(), lobby:GetMyParty())
	end

	SetupDebriefingTracker(window)

	-- External functions
	local externalFunctions = {}

	function externalFunctions.UpdateBanTimer()
		if not banStart then
			return
		end
		local timeRemaining = (banDuration or 0) - math.ceil(Spring.DiffTimers(Spring.GetTimer(), banStart))
		if timeRemaining < 0 then
			banStart = false
			statusText:SetText("")
			return
		end
		statusText:SetText("You are banned from matchmaking for " .. timeRemaining .. " seconds")
	end

	function externalFunctions.UpdateRequirementText()
		local newText = ""
		local firstEntry = true
		for name,_ in pairs(requiredResources) do
			if firstEntry then
				newText = "Required resources: "
			else
				newText = newText .. ", "
			end
			firstEntry = false
			newText = newText .. name
		end

		if not HaveRightEngineVersion() then
			if firstEntry then
				newText = "Game engine update required, restart the menu to apply."
			else
				newText = "\nGame engine update required, restart the menu to apply."
			end
		end
		requirementText:SetText(newText)
	end

	externalFunctions.UpdateRequirementText()

	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- External Interface

local QueueListWindow = {}

function QueueListWindow.HaveMatchMakerResources()
	return requiredResourceCount == 0 and HaveRightEngineVersion()
end

local queueListWindowControl

function QueueListWindow.GetControl()

	queueListWindowControl = Control:New {
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

	return queueListWindowControl
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Timeout

local lobbyTimeoutTime = false
local function ResetLobbyTimeout()
	local lobbyStatus = WG.LibLobby.lobby.status
	if WG.LibLobby and WG.LibLobby.lobby and (lobbyStatus == "connected" or lobbyStatus == "connecting") then
		lobbyTimeoutTime = Spring.GetTimer()
	end
end

local function TryLogin()
	local lobbyStatus = WG.LibLobby.lobby.status
	if (not lobbyStatus) or lobbyStatus == "offline" or lobbyStatus == "disconnected" then
		WG.LoginWindowHandler.TryLogin()
	end
end

local function UpdateLobbyTimeout()
	local Configuration = WG.Chobby.Configuration
	if not (lobbyTimeoutTime and Configuration.lobbyTimeoutTime) then
		return
	end
	local logoutTime = Configuration.lobbyTimeoutTime
	if Spring.GetGameName() ~= "" then
		logoutTime = 180 -- Possibility of long load times.
	end

	local lobbyStatus = WG.LibLobby.lobby.status
	if lobbyStatus == "connecting" then
		lobbyTimeoutTime = Spring.GetTimer()
		return
	end

	if (Spring.DiffTimers(Spring.GetTimer(), lobbyTimeoutTime) or 0) > logoutTime then
		Spring.Echo("Lost connection - Automatic logout.")
		WG.Chobby.interfaceRoot.CleanMultiplayerState()
		WG.LibLobby.lobby:Disconnect()
		WG.Delay(TryLogin, 2 + math.random()*60)
		lobbyTimeoutTime = false
	end
end

local function OnDisconnected(_, reason, intentional)
	if intentional then
		lobbyTimeoutTime = false
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

function widget:ActivateGame()
	-- You can enter debriefing before you look at the queue list window.
	-- Need to create it if a game starts.
	if not (queueListWindowControl and queueListWindowControl:IsEmpty()) then
		return
	end

	panelInterface = InitializeControls(queueListWindowControl)
end

local updateCheckTime = 0
function widget:Update(dt)
	if panelInterface then
		panelInterface.UpdateBanTimer()
	end
	updateCheckTime = updateCheckTime + (dt or 1)
	if updateCheckTime > 5 then
		UpdateLobbyTimeout()
		updateCheckTime = updateCheckTime - 5
	end
end

function widget:Initialize()
	CHOBBY_DIR = LUA_DIRNAME .. "widgets/chobby/"
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	local function AddQueue(_, queueName, queueDescription, mapNames, maxPartSize, gameNames)
		for i = 1, #mapNames do
			local mapName = mapNames[i]
			if not requiredResources[mapName] then
				local haveMap = VFS.HasArchive(mapName)
				if not haveMap then
					requiredResources[mapName] = true
					requiredResourceCount = requiredResourceCount + 1
					WG.DownloadHandler.MaybeDownloadArchive(mapName, "map", 1)
				end
			end
		end

		for i = 1, #gameNames do
			local gameName = gameNames[i]
			if not requiredResources[gameName] then
				local haveGame = VFS.HasArchive(gameName)
				if not haveGame then
					requiredResources[gameName] = true
					requiredResourceCount = requiredResourceCount + 1
					WG.DownloadHandler.MaybeDownloadArchive(gameName, "game", 1)
				end
			end
		end

		if panelInterface then
			panelInterface.UpdateRequirementText()
		end
	end

	WG.LibLobby.lobby:AddListener("OnQueueOpened", AddQueue)

	local function downloadFinished()
		for resourceName,_ in pairs(requiredResources) do
			local haveResource = VFS.HasArchive(resourceName)
			if haveResource then
				requiredResources[resourceName] = nil
				requiredResourceCount = requiredResourceCount - 1
			end
		end

		if panelInterface then
			panelInterface.UpdateRequirementText()
		end
	end
	WG.DownloadHandler.AddListener("DownloadFinished", downloadFinished)

	WG.QueueListWindow = QueueListWindow

	WG.LibLobby.lobby:AddListener("OnDisconnected", OnDisconnected)
	WG.LibLobby.lobby:AddListener("OnCommandReceived", ResetLobbyTimeout)
	WG.LibLobby.lobby:AddListener("OnCommandBuffered", ResetLobbyTimeout)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
