--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "User status panel",
		desc      = "Displays user status and provides interface for logging out and exiting.",
		author    = "gajop",
		date      = "4 July 2016",
		license   = "GNU LGPL, v2.1 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Chili
local btnLogout
local connectivityText
local connectivityImage
local onlineCountText

local IMAGE_DIR          = LUA_DIRNAME .. "images/"
local IMAGE_ONLINE       = IMAGE_DIR .. "online.png"
local IMAGE_CONNECTING   = IMAGE_DIR .. "connecting.png"
local IMAGE_OFFLINE      = IMAGE_DIR .. "offline.png"

local USER_STATUS_X      = 40
local USER_STATUS_Y      = 51
local USER_STATUS_WIDTH  = 325
local ONLINE_COUNT_GAP   = 10
local ONLINE_COUNT_X     = USER_STATUS_X + USER_STATUS_WIDTH + ONLINE_COUNT_GAP
local ONLINE_COUNT_Y     = 53
local ONLINE_COUNT_UPDATE_INTERVAL = 60

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Lobby listeners

local onAccepted, onDisconnected, onPong, onAddUser, onUserCount

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Initialization

local UserStatusPanel = {}

local function SetOnlineCountVisible(visible)
	if onlineCountText then
		onlineCountText:SetVisibility(visible)
	end
end

local function UpdateOnlineCount()
	if onlineCountText and onlineCountText.parent then
		onlineCountText:SetText("\255\180\180\180" .. lobby:GetUserCount() .. " online\b")
	end
end

local function Logout()
	if lobby:GetConnectionStatus() ~= "offline" then
		if WG.Chobby and WG.Chobby.Configuration then
			WG.Chobby.Configuration:SetConfigValue("autoLogin", false)
		end
		if WG.Chobby and WG.Chobby.Configuration and WG.Chobby.Configuration.gameConfig and WG.Chobby.Configuration.gameConfig.logoutOpensLoginPanel then
			WG.LoginWindowHandler.TryLogin()
			--WG.LoginWindowHandler.tabPanel.tabBar:Select("reset")
		else
			Spring.Echo("Logout")
			if WG.Chobby and WG.Chobby.interfaceRoot then
				WG.Chobby.interfaceRoot.CleanMultiplayerState()
			end
			lobby:Disconnect()
		end
	else
		Spring.Echo("Login")
		WG.LoginWindowHandler.TryLogin()
	end
end

local function GoToProfilePage()
	if WG.Chobby and WG.Chobby.Configuration then
		local Configuration = WG.Chobby.Configuration
		if Configuration.gameConfig.link_homePage ~= nil then
			WG.BrowserHandler.OpenUrl(Configuration.gameConfig.link_homePage())
		end
	end
end

local function ShowKeys()
	WG.KeysPanel.Show()
end

local function Quit()
	Spring.Echo("Quitting...")
	Spring.Quit()
end

-- local function UpdateLatency()
-- 	local latency = lobby:GetLatency()
-- 	local color
-- 	latency = math.ceil(latency)
-- 	if latency < 500 then
-- 		color = WG.Chobby.Configuration:GetSuccessColor()
-- 	elseif latency < 1000 then
-- 		color = WG.Chobby.Configuration:GetWarningColor()
-- 	else
-- 		if latency > 9000 then
-- 			latency = "9000+"
-- 		end
-- 		color = "\255\255\125\0"
-- 	end
-- 	connectivityText:SetCaption(color .. latency .. "ms\b")
-- end
--
-- local _lastUpdate = os.clock()
-- function widget:Update()
-- 	if os.clock() - _lastUpdate > 1 then
-- 		_lastUpdate = os.clock()
-- 		UpdateLatency()
-- 	end
-- end

local function InitializeControls(window)
	local menuX = 0

	menuX = menuX + 3
	btnLogout = Button:New {
		y = 2,
		right = menuX,
		width = 108,
		height = 38,
		caption = i18n("login"),
		parent = window,
		objectOverrideFont = (WG.Chobby and WG.Chobby.Configuration and WG.Chobby.Configuration:GetFont(2)) or nil,
		OnClick = {Logout}
	}
	menuX = menuX + 108

	if WG.Chobby and WG.Chobby.Configuration and WG.Chobby.Configuration.gameConfig and WG.Chobby.Configuration.gameConfig.link_homePage ~= nil then
		menuX = menuX + 3
		btnProfile = Button:New {
			y = 2,
			right = menuX,
			width = 108,
			height = 38,
			caption = i18n("home"),
			parent = window,
			objectOverrideFont = (WG.Chobby and WG.Chobby.Configuration and WG.Chobby.Configuration:GetFont(2)) or nil,
			OnClick = {GoToProfilePage}
		}
		menuX = menuX + 108
	end

	menuX = menuX + 3
	btnKeys = Button:New {
		y = 2,
		right = menuX,
		width = 108,
		height = 38,
		caption = i18n("keys"),
		parent = window,
		objectOverrideFont = (WG.Chobby and WG.Chobby.Configuration and WG.Chobby.Configuration:GetFont(2)) or nil,
		OnClick = {ShowKeys}
	}
	menuX = menuX + 108

	connectivityText = TextBox:New {
		name = "connectivityText",
		x = USER_STATUS_X,
		width = 150,
		y = 53,
		height = 20,
		valign = "center",
		text = "\255\180\180\180" .. i18n("offline") .. "\b",
		objectOverrideFont = (WG.Chobby and WG.Chobby.Configuration and WG.Chobby.Configuration:GetFont(2)) or nil,
		objectOverrideHintFont = (WG.Chobby and WG.Chobby.Configuration and WG.Chobby.Configuration:GetFont(2)) or nil,
		parent = window,
	}

	onlineCountText = TextBox:New {
		name = "onlineCountText",
		x = ONLINE_COUNT_X,
		width = 110,
		y = ONLINE_COUNT_Y,
		height = 20,
		valign = "center",
		align = "left",
		text = "\255\180\180\180" .. lobby:GetUserCount() .. " online\b",
		objectOverrideFont = (WG.Chobby and WG.Chobby.Configuration and WG.Chobby.Configuration:GetFont(11)) or nil,
		objectOverrideHintFont = (WG.Chobby and WG.Chobby.Configuration and WG.Chobby.Configuration:GetFont(11)) or nil,
		parent = window,
	}
	SetOnlineCountVisible(lobby:GetConnectionStatus() == "connected")

	connectivityImage = Image:New {
		name = "connectivityImage",
		x = 15,
		y = 52,
		width = 18,
		height = 18,
		keepAspect = false,
		file = IMAGE_OFFLINE,
		parent = window,
	}

	local userControl
	onAccepted = function(listener)
		userControl = WG.UserHandler.GetStatusUser(lobby:GetMyUserName(), USER_STATUS_WIDTH)
		if userControl then
			userControl:SetPos(USER_STATUS_X, USER_STATUS_Y, USER_STATUS_WIDTH)
			window:AddChild(userControl)
			window:RemoveChild(connectivityText)
		end
		WG.Delay(UpdateOnlineCount, 2)
		SetOnlineCountVisible(true)
		lobby:Ping()
	end

	onDisconnected = function(listener)
		if userControl and userControl.parent then
			window:RemoveChild(userControl)
			window:AddChild(connectivityText)
		end
		SetOnlineCountVisible(false)
		UpdateOnlineCount()
	end

	onPong = function(listener)
		--UpdateLatency()
	end

	onAddUser = function(listener, userName, status)
		if userName == lobby:GetMyUserName() and status.accountID then
			if WG.Chobby and WG.Chobby.Configuration then
				WG.Chobby.Configuration:SetConfigValue("myAccountID", status.accountID)
			end
		end
	end

	onUserCount = function(listener)
		UpdateOnlineCount()
	end

	lobby:AddListener("OnDisconnected", onDisconnected)
	lobby:AddListener("OnAccepted", onAccepted)
	lobby:AddListener("OnPong", onPong)
	lobby:AddListener("OnAddUser", onAddUser)
	lobby:AddListener("OnUserCount", onUserCount)
end

function UserStatusPanel.GetControl()
	local window = Control:New {
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

local oldStatus
local onlineCountLastUpdate = 0

function widget:Update()
	local newStatus = lobby:GetConnectionStatus()
	if newStatus ~= oldStatus then
		if newStatus == "disconnected" or newStatus == "offline" then
			btnLogout:SetCaption(i18n("login"))
			connectivityText:SetText("\255\180\180\180" .. i18n("offline") .. "\b")
			connectivityImage.file = IMAGE_OFFLINE
			connectivityImage:Invalidate()
			SetOnlineCountVisible(false)
		else
			if WG.Chobby and WG.Chobby.Configuration and WG.Chobby.Configuration.gameConfig and WG.Chobby.Configuration.gameConfig.logoutOpensLoginPanel then
				btnLogout:SetCaption(i18n("account"))
			else
				btnLogout:SetCaption(i18n("logout"))
			end
		end
		if newStatus == "connecting" then
			connectivityText:SetText((WG.Chobby and WG.Chobby.Configuration and WG.Chobby.Configuration:GetPartialColor()) or ("\255\255\255\255" .. i18n("connecting") .. "\b"))
			connectivityImage.file = IMAGE_CONNECTING
			connectivityImage:Invalidate()
			SetOnlineCountVisible(false)
		elseif newStatus == "connected" then
			connectivityText:SetText((WG.Chobby and WG.Chobby.Configuration and WG.Chobby.Configuration:GetSuccessColor()) or ("\255\255\255\255" .. i18n("online") .. "\b"))
			connectivityImage.file = IMAGE_ONLINE
			connectivityImage:Invalidate()
			SetOnlineCountVisible(true)
		end
		oldStatus = newStatus
	end

	if newStatus == "connected" then
		local now = os.clock()
		if now - onlineCountLastUpdate >= ONLINE_COUNT_UPDATE_INTERVAL then
			UpdateOnlineCount()
			onlineCountLastUpdate = now
		end
	end
end

function widget:Initialize()

	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	WG.UserStatusPanel = UserStatusPanel
end

function widget:Shutdown()
	if lobby then
		lobby:RemoveListener("OnDisconnected", onDisconnected)
		lobby:RemoveListener("OnAccepted", onAccepted)
		lobby:RemoveListener("OnPong", onPong)
		lobby:RemoveListener("OnAddUser", onAddUser)
		lobby:RemoveListener("OnUserCount", onUserCount)
	end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
