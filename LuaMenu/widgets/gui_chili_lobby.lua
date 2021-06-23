--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:GetInfo()
	return {
		name      = "Chili lobby",
		desc      = "Chili example lobby",
		author    = "gajop",
		date      = "in the future",
		license   = "GPL-v2",
		layer     = 1001,
		enabled   = true,
	}
end

include("keysym.h.lua")

LIBS_DIR = "libs/"
LCS = loadstring(VFS.LoadFile(LIBS_DIR .. "lcs/LCS.lua"))
LCS = LCS()

CHOBBY_DIR = LUA_DIRNAME .. "widgets/chobby/"

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Callins

local interfaceRoot

local oldSizeX, oldSizeY
function widget:ViewResize(vsx, vsy, viewGeometry)
	oldSizeX, oldSizeY = vsx, vsy
	if interfaceRoot then
		interfaceRoot.ViewResize(vsx, vsy)
	end
	--Spring.Utilities.TableEcho(viewGeometry, "viewGeometry")
	WG.Chobby:_ViewResize(vsx, vsy)
end

function widget:Update()
	local screenWidth, screenHeight = Spring.GetWindowGeometry()
	if screenWidth ~= oldSizeX or screenHeight ~= oldSizeY then
		widget:ViewResize(screenWidth, screenHeight)
	end
end

local function SetIngameTrue()
	lobby:SetIngameStatus(true)
end

local function SetIngameFalse()
	lobby:SetIngameStatus(false)
end

local ignoreFirstCall = true
function widget:ActivateMenu()
	if ignoreFirstCall then
		ignoreFirstCall = false
		return
	end
	interfaceRoot.SetIngame(false)
	WG.Delay(SetIngameFalse, 1)
end

function widget:ActivateGame()
	interfaceRoot.SetIngame(true)
	WG.Delay(SetIngameTrue, 1)
end

function widget:Initialize()
	WG.LimitFps.ForceRedrawPeriod(5) -- High FPS for the first few seconds to shorten the initial white flash.
	if not WG.LibLobby then
		Spring.Log("chobby", LOG.ERROR, "Missing liblobby.")
		widgetHandler:RemoveWidget(widget)
		return
	end
	if not WG.Chili then
		Spring.Log("chobby", LOG.ERROR, "Missing chiliui.")
		widgetHandler:RemoveWidget(widget)
		return
	end

	Chobby = VFS.Include(CHOBBY_DIR .. "core.lua", nil)

	WG.Chobby = Chobby
	WG.Chobby:_Initialize()

	interfaceRoot = WG.Chobby.GetInterfaceRoot()

	lobbyInterfaceHolder = interfaceRoot.GetLobbyInterfaceHolder()
	Chobby.lobbyInterfaceHolder = lobbyInterfaceHolder
	Chobby.interfaceRoot = interfaceRoot

	local taskbarTitle = Chobby.Configuration.gameConfig.taskbarTitle
	local taskbarTitleShort = Chobby.Configuration.gameConfig.taskbarTitleShort or taskbarTitle
	if taskbarTitle then
		Spring.SetWMCaption(taskbarTitle, taskbarTitleShort)
	end
	local taskbarIcon = Chobby.Configuration.gameConfig.taskbarIcon
	if taskbarIcon then
		Spring.SetWMIcon(taskbarIcon, true)
	end

	local function OnBattleAboutToStart()
		lobby:SetIngameStatus(true)
	end
	WG.LibLobby.localLobby:AddListener("OnBattleAboutToStart", OnBattleAboutToStart)
	WG.LibLobby.lobby:AddListener("OnBattleAboutToStart", OnBattleAboutToStart)

	local function onConfigurationChange(listener, key, value)
		if key == "gameConfigName" then
			local taskbarTitle = Chobby.Configuration.gameConfig.taskbarTitle
			local taskbarTitleShort = Chobby.Configuration.gameConfig.taskbarTitleShort or taskbarTitle
			if taskbarTitle then
				Spring.SetWMCaption(taskbarTitle, taskbarTitleShort)
			end
			local taskbarIcon = Chobby.Configuration.gameConfig.taskbarIcon
			if taskbarIcon then
				Spring.SetWMIcon(taskbarIcon, true)
			end
		end
		if key == "language" then
			Spring.Echo("Set language to "..value)
			i18n.setLocale(value)
		end
	end
	Chobby.Configuration:AddListener("OnConfigurationChange", onConfigurationChange)
end

function widget:KeyPress(key, mods, isRepeat, label, unicode)
	if interfaceRoot then
		return interfaceRoot.KeyPressed(key, mods, isRepeat, label, unicode)
	end
end

function widget:Shutdown()
	Spring.Log("Chobby", LOG.NOTICE, "Chobby Shutdown")
	WG.Chobby = nil
end

function widget:DrawScreen()
	WG.Chobby:_DrawScreen()
end

function widget:GetConfigData()
	if WG.Chobby == nil then
		Spring.Log("Chobby", LOG.ERROR, "No WG.Chobby available during widget:GetConfigData()")
		return
	end
	return WG.Chobby:_GetConfigData()
end

function widget:SetConfigData(...)
	WG.Chobby:_SetConfigData(...)
end
