--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Party status panel",
		desc      = "Displays party status.",
		author    = "GoogleFrog",
		date      = "18 January 2017",
		license   = "GNU LGPL, v2.1 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Variables

local partyPanel
local invitePopup

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utilities

local function SecondsToMinutes(seconds)
	if seconds < 60 then
		return seconds .. "s"
	end
	local modSeconds = (seconds%60)
	return math.floor(seconds/60) .. ":" .. ((modSeconds < 10 and "0") or "") .. modSeconds
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Initialization

local function InitializePartyStatusHandler(name)
	local lobby = WG.LibLobby.lobby

	local queuePanel = Panel:New {
		name = name,
		x = 8,
		y = 0,
		right = 0,
		bottom = 0,
		classname = "overlay_panel",
		width = pos and pos.width,
		height = pos and pos.height,
		padding = {0,0,0,0},
		caption = "",
		resizable = false,
		draggable = false,
		parent = parent
	}

	local partyTitle = TextBox:New {
		x = "75%",
		y = 12,
		fontsize = WG.Chobby.Configuration:GetFont(3).size,
		text = i18n("party"),
		parent = queuePanel
	}

	local button = Button:New {
		name = "leaveParty",
		x = "70%",
		y = 4,
		right = 4,
		bottom = 4,
		padding = {0,0,0,0},
		caption = i18n("leave"),
		font = WG.Chobby.Configuration:GetFont(3),
		classname = "negative_button",
		OnClick = {
			function()
				lobby:LeaveParty()
			end
		},
		parent = queuePanel,
	}

	local listPanel = ScrollPanel:New {
		x = 4,
		right = "32%",
		y = 4,
		bottom = 4,
		padding = {1, 1, 1, 1},
		horizontalScrollbar = false,
		parent = queuePanel
	}

	local function Resize(obj, xSize, ySize)
		if ySize < 60 then
			button._relativeBounds.top = 4
		else
			button._relativeBounds.top = 38
		end
		partyTitle:SetVisibility(ySize >= 60)
		button:UpdateClientArea()
	end

	queuePanel.OnResize = {Resize}

	local externalFunctions = {}

	function externalFunctions.UpdateParty(partyUsers)
		listPanel:ClearChildren()
		local position = 0
		for i = 1, #partyUsers do
			local userName = partyUsers[i]
			if userName ~= lobby:GetMyUserName() then
				local userControl = WG.UserHandler.GetPartyUser(userName)
				listPanel:AddChild(userControl)
				userControl:SetPos(nil, position*22)
				position = position + 1
			end
		end
	end

	function externalFunctions.GetHolder()
		return queuePanel
	end

	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Ready Check Popup

local function CreatePartyInviteWindow(partyID, partyUsers, secondsRemaining, DestroyFunc)
	local Configuration = WG.Chobby.Configuration

	local MAX_USERS = 10
	local USER_SPACE = 22
	local BASE_HEIGHT = 175
	local userHeight = math.max(60, USER_SPACE*math.min(#partyUsers, MAX_USERS))

	local partyInviteWindow = Window:New {
		caption = "",
		name = "partyInviteWindow",
		parent = screen0,
		width = 316,
		height = BASE_HEIGHT + userHeight,
		resizable = false,
		draggable = false,
		classname = "main_window",
	}

	local titleText = i18n("party_invite")
	local title = Label:New {
		x = 20,
		right = 0,
		y = 15,
		height = 35,
		caption = titleText,
		font = Configuration:GetFont(4),
		parent = partyInviteWindow,
	}

	local listPanel = ScrollPanel:New {
		x = 10,
		right = 10,
		y = 60,
		bottom = 80,
		borderColor = (#partyUsers <= MAX_USERS and {0,0,0,0}) or nil,
		horizontalScrollbar = false,
		parent = partyInviteWindow
	}

	for i = 1, #partyUsers do
		local userControl = WG.UserHandler.GetPopupUser(partyUsers[i])
		listPanel:AddChild(userControl)
		userControl:SetPos(1, 1 + (i - 1)*USER_SPACE)
		userControl._relativeBounds.right = 1
		userControl:UpdateClientArea(false)
	end

	--local statusLabel = TextBox:New {
	--	x = 160,
	--	right = 0,
	--	y = 15,
	--	height = 35,
	--	text = "",
	--	fontsize = Configuration:GetFont(4).size,
	--	parent = partyInviteWindow,
	--}

	local startTimer = Spring.GetTimer()
	local timeRemaining = secondsRemaining

	local function DoDispose()
		if partyInviteWindow then
			partyInviteWindow:Dispose()
			partyInviteWindow = nil
			DestroyFunc()
		end
	end

	local function CancelFunc()
		lobby:PartyInviteResponse(partyID, false)
		WG.Delay(DoDispose, 0.1)
	end

	local function AcceptFunc()
		lobby:PartyInviteResponse(partyID, true)
		WG.Delay(DoDispose, 0.1)

		-- Hack for testing until parties work.
		--partyUsers[#partyUsers + 1] = lobby:GetMyUserName() -- Adding to table is highly dangerous
		--lobby:_OnPartyStatus({PartyID = partyID, UserNames = partyUsers})
	end

	local buttonAccept = Button:New {
		x = 5,
		width = 135,
		bottom = 1,
		height = 70,
		caption = i18n("accept"),
		font = Configuration:GetFont(3),
		parent = partyInviteWindow,
		classname = "action_button",
		OnClick = {
			function()
				AcceptFunc()
			end
		},
	}

	local buttonReject = Button:New {
		right = 5,
		width = 135,
		bottom = 1,
		height = 70,
		caption = i18n("reject"),
		font = Configuration:GetFont(3),
		parent = partyInviteWindow,
		classname = "negative_button",
		OnClick = {
			function()
				CancelFunc()
			end
		},
	}

	local popupHolder = WG.Chobby.PriorityPopup(partyInviteWindow, CancelFunc, AcceptFunc, screen0)

	local externalFunctions = {}

	function externalFunctions.UpdateTimer()
		local newTimeRemaining = secondsRemaining - math.ceil(Spring.DiffTimers(Spring.GetTimer(), startTimer))
		if newTimeRemaining < 0 then
			DoDispose()
		end
		if timeRemaining == newTimeRemaining then
			return
		end
		timeRemaining = newTimeRemaining
		title:SetCaption(titleText .. " (" .. SecondsToMinutes(timeRemaining) .. ")")
	end

	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- External functions

local PartyStatusPanel = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

function DelayedInitialize()
	local lobby = WG.LibLobby.lobby

	local statusAndInvitesPanel = WG.Chobby.interfaceRoot.GetStatusAndInvitesPanel()
	partyPanel = InitializePartyStatusHandler("partyPanel")

	local displayingParty = false

	local function OnPartyJoined(_, _, partyUsers)
		if not displayingParty then
			statusAndInvitesPanel.AddControl(partyPanel.GetHolder(), 4)
		end
		displayingParty = true
		partyPanel.UpdateParty(partyUsers)
	end

	local function OnPartyLeft()
		if displayingParty then
			statusAndInvitesPanel.RemoveControl(partyPanel.GetHolder().name)
		end
		displayingParty = false
	end

	local function OnPartyUpdate(_, partyID, partyUsers)
		if partyID == lobby:GetMyPartyID() then
			OnPartyJoined(_, _, partyUsers)
		end
	end

	local function DestroyInvitePopup()
		invitePopup = nil
	end

	local function OnPartyInviteRecieved(_, partyID, partyUsers, secondsRemaining)
		if WG.Chobby.Configuration:AllowNotification(nil, partyUsers) and not invitePopup then
			invitePopup = CreatePartyInviteWindow(partyID, partyUsers, secondsRemaining, DestroyInvitePopup)
		end
	end

	lobby:AddListener("OnPartyInviteRecieved", OnPartyInviteRecieved)
	lobby:AddListener("OnPartyJoined", OnPartyJoined)
	lobby:AddListener("OnPartyLeft", OnPartyLeft)
	lobby:AddListener("OnPartyUpdate", OnPartyUpdate)
	lobby:AddListener("OnDisconnected", OnPartyLeft)
end

function widget:Update()
	if invitePopup then
		invitePopup.UpdateTimer()
	end
end

function widget:Initialize()
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	WG.PartyStatusPanel = PartyStatusPanel
	WG.Delay(DelayedInitialize, 1)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
