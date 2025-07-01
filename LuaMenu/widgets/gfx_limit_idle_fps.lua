
function widget:GetInfo()
	return {
		name = "Limit idle FPS",
		desc = "reduces fps when user is idle" ,
		author = "Floris",
		date = "2020",
		license = "",
		layer = -math.huge,
		--handler   = true,
		--api       = true, -- Makes KeyPress occur before chili (but also fails with WG.LimitFps)
		enabled   = true,
	}
end

------------
-- Timers --
------------

LIBS_DIR = "libs/"
LCS = loadstring(VFS.LoadFile(LIBS_DIR .. "lcs/LCS.lua"))
LCS = LCS()

Timer = LCS.class{}

function Timer:init(duration, action)
	self.endTime = os.clock() + duration
	self.action = action
end

function Timer:Update()
	if self.endTime < os.clock() and not self.hasFired then
		self.action()
		self.hasFired = true
	end
end

-----------------
-- VSync State --
-----------------

local stateTimer
local awayTimer

local drawAtFullspeed = true
local maxVsync = 6

-- Used to force more frequent updates in periods of known user interaction.
-- This is used as an initial value and in ForceRedrawPeriod.
-- This is equivalent to VSYNC_STATE_INTERACTING, except that it will not
-- time out into idle/sleep/hibernate. 
local VSYNC_STATE_GRACE = 1
-- Used when the user is known to be actively interacting with the application, 
-- e.g. moving the mouse or typing. Outside of grace mode, any measured interaction with Chobby 
-- will return the application to VSYNC_STATE_INTERACTING
local VSYNC_STATE_INTERACTING = 2
-- IDLE, SLEEP, and HIBERNATE are progressively lower-resource modes which trigger after a delay.
local VSYNC_STATE_IDLE = 3
local VSYNC_STATE_SLEEP = 4
local VSYNC_STATE_HIBERNATE = 5
-- OFFSCREEN triggers when the mouse is not being handled by the engine (i.e. another application.)
local VSYNC_STATE_OFFSCREEN = 6

local idleTime = 0.5
local sleepTime = 1
local hibernateTime = 2
local awayTime = 300

local vSyncState = VSYNC_STATE_GRACE

local vSyncStateValues = {
	[VSYNC_STATE_GRACE] = 1,
	[VSYNC_STATE_INTERACTING] = 1,
	[VSYNC_STATE_IDLE] = 1,
	[VSYNC_STATE_SLEEP] = 3,
	[VSYNC_STATE_HIBERNATE] = maxVsync,
	[VSYNC_STATE_OFFSCREEN] = maxVsync,
}

local stateFPSValues = {
	[VSYNC_STATE_GRACE] = 40,
	[VSYNC_STATE_INTERACTING] = 40,
	[VSYNC_STATE_IDLE] = 10, -- lower numbers will result in more severe flicker on some card/driver settings
	[VSYNC_STATE_SLEEP] = 5,
	[VSYNC_STATE_HIBERNATE] = 2,
	[VSYNC_STATE_OFFSCREEN] = 1,
}

local function SetVSyncState(newVSyncState)
	if vSyncState ~= newVSyncState then
		vSyncState = newVSyncState
		Spring.SetConfigInt("VSync", vSyncStateValues[vSyncState])
	end
end

-----------------------
-- State Transitions --
-----------------------

local function enterHibernation()
	SetVSyncState(VSYNC_STATE_HIBERNATE)
end

local function enterSleep()
	SetVSyncState(VSYNC_STATE_SLEEP)
	stateTimer = Timer(hibernateTime - sleepTime, enterHibernation)
end

local function becomeIdle()
	SetVSyncState(VSYNC_STATE_IDLE)
	stateTimer = Timer(sleepTime - idleTime, enterSleep)
end

local function becomeAway()
	local lobby = WG.LibLobby.lobby
	if lobby.SetIngameStatus then
		lobby:SetIngameStatus(nil, true)
	end
end

local function logUserInput()
	if vSyncState == VSYNC_STATE_GRACE or vSyncState == VSYNC_STATE_OFFSCREEN then
		return
	end

	SetVSyncState(VSYNC_STATE_INTERACTING)

	stateTimer = Timer(idleTime, becomeIdle)
	awayTimer = Timer(awayTime, becomeAway)

	local lobby = WG.LibLobby.lobby
	if lobby.SetIngameStatus then
		lobby:SetIngameStatus(nil, false)
	end
end

local function concludeGrace()
	SetVSyncState(VSYNC_STATE_INTERACTING)
	logUserInput()
end

stateTimer = Timer(30, concludeGrace)
awayTimer = Timer(awayTime, becomeAway)

-----------------
-- Cached Data --
-----------------

local lastMouseX, lastMouseY = Spring.GetMouseState()
local nextFrameTime = os.clock()

local initialized

------------
-- Config --
------------

local msaaLevel = tonumber(Spring.GetConfigInt("MSAALevel", 0))

local defaultVSyncGame = Spring.GetConfigInt("VSync",1)
if defaultVSyncGame > 3 then
	defaultVSyncGame = 1
end
defaultVSyncGame = Spring.GetConfigInt("VSyncGame", defaultVSyncGame)	-- its stored here as assurance cause lobby/game also changes vsync when idle and lobby could think game has set vsync 4+ after a hard crash

local isLinux = string.find(Platform.osName:lower(), 'linux')	-- not sure what exact implications linux has, but someone reported flickering

local isIntel = (Platform ~= nil and Platform.gpuVendor == 'Intel')
local isNvidia = (Platform ~= nil and Platform.gpuVendor == 'Nvidia')
local isAmd = (Platform ~= nil and Platform.gpuVendor == 'AMD') or (not isIntel and not isNvidia)

if isIntel or isLinux then
	maxVsync = 4	-- intel seems to no support vsync above 4 (but haven't tested the new intel XE)
	vSyncStateValues[VSYNC_STATE_OFFSCREEN] = maxVsync
	
	idleTime = 0.25
	stateFPSValues[VSYNC_STATE_IDLE] = 30	-- lower numbers will result in more severe flicker on intel gfx
	
	sleepTime = 1
	stateFPSValues[VSYNC_STATE_SLEEP] = 15

	hibernateTime = 2
	stateFPSValues[VSYNC_STATE_HIBERNATE] = 2
	vSyncStateValues[VSYNC_STATE_HIBERNATE] = maxVsync
end

if isAmd then 
	maxVsync = 4 -- This is an attempted fix at AMD Driver 24.6.1, as it always seems to crash at interval = 5
	local initVsync = Spring.GetConfigInt("VSync", 1)
	if initVsync > maxVsync then
		Spring.SetConfigInt("VSync", maxVsync)
	end
end

Spring.Echo("Limit Idle FPS is enabled:", widget:GetInfo().enabled, "max set to ", maxVsync, 'for platform', Platform.gpuVendor, isAmd)
-- detect display frequency > 60 and set vsyncValueIdle to 6
local infolog = VFS.LoadFile("infolog.txt")
local monitorFrequency = 60
if infolog then
	function lines(str)
		local t = {}
		local function helper(line) table.insert(t, line) return "" end
		helper((str:gsub("(.-)\r?\n", helper)))
		return t
	end

	-- store changelog into table
	local fileLines = lines(infolog)

	for i, line in ipairs(fileLines) do
		if string.sub(line, 1, 3) == '[F='  then
			break
		end

		if line:find('(display%-mode set to )') then
			local s_displaymode = line:sub( line:find('(display%-mode set to )') + 20)
			if s_displaymode:find('%@') then
				monitorFrequency = tonumber(s_displaymode:sub(s_displaymode:find('%@')+1, s_displaymode:find('Hz ')-1))
				if monitorFrequency >= 100 then
					break
				end
			end
		end
	end
end

local function init()
	if monitorFrequency >= 200 then
		vSyncStateValues[VSYNC_STATE_INTERACTING] = 3
	elseif monitorFrequency >= 110 then
		vSyncStateValues[VSYNC_STATE_INTERACTING] = 2
	else
		vSyncStateValues[VSYNC_STATE_INTERACTING] = 1
	end

	if drawAtFullspeed then
		stateFPSValues[VSYNC_STATE_INTERACTING] = math.ceil(monitorFrequency/vSyncStateValues[VSYNC_STATE_INTERACTING])
		if stateFPSValues[VSYNC_STATE_INTERACTING] < 60 then
			stateFPSValues[VSYNC_STATE_INTERACTING] = 60
		elseif stateFPSValues[VSYNC_STATE_INTERACTING] > 80 then
			stateFPSValues[VSYNC_STATE_INTERACTING] = 80
		end
	else
		stateFPSValues[VSYNC_STATE_INTERACTING] = 40
		vSyncStateValues[VSYNC_STATE_INTERACTING] = vSyncStateValues[VSYNC_STATE_INTERACTING] + 1
	end

	stateFPSValues[VSYNC_STATE_GRACE] = stateFPSValues[VSYNC_STATE_INTERACTING]
	vSyncStateValues[VSYNC_STATE_GRACE] = vSyncStateValues[VSYNC_STATE_INTERACTING]
	vSyncStateValues[VSYNC_STATE_SLEEP] = vSyncStateValues[VSYNC_STATE_INTERACTING] + 2

	if vSyncStateValues[VSYNC_STATE_SLEEP] > maxVsync then vSyncStateValues[VSYNC_STATE_SLEEP] = maxVsync end
	if vSyncStateValues[VSYNC_STATE_INTERACTING] > maxVsync then vSyncStateValues[VSYNC_STATE_INTERACTING] = maxVsync end
	if vSyncStateValues[VSYNC_STATE_HIBERNATE] > maxVsync then vSyncStateValues[VSYNC_STATE_HIBERNATE] = maxVsync end
	if vSyncStateValues[VSYNC_STATE_OFFSCREEN] > maxVsync then vSyncStateValues[VSYNC_STATE_OFFSCREEN] = maxVsync end
end

function widget:Initialize()
	-- We delay init to ensure we get first access to UI callins, but still init after WG.Chobby.
	if not WG.Chobby then return end

	if WG.Chobby and WG.Chobby.Configuration then
		drawAtFullspeed = WG.Chobby.Configuration.drawAtFullSpeed
	end
	init()

	Spring.SetConfigInt("VSync", math.min(maxVsync, vSyncStateValues[vSyncState]))
	
	WG.LimitFps = {}
	WG.LimitFps.ForceRedrawPeriod = function(time)	-- optional time for duration of prolonged wakeness
		time = time or 0
		if vSyncState == VSYNC_STATE_GRACE then
			stateTimer.endTime = math.max(stateTimer.endTime, os.clock() + time)
		else
			stateTimer = Timer(time or 0, concludeGrace)
		end
		
		nextFrameTime = os.clock()
	end
	WG.LimitFps.ForceRedraw = WG.LimitFps.ForceRedrawPeriod

	WG.Chobby.interfaceRoot.GetLobbyInterfaceHolder().OnShow = { function()
		Spring.SetConfigInt("VSync", vSyncStateValues[VSYNC_STATE_INTERACTING])
	end }
	WG.Chobby.interfaceRoot.GetLobbyInterfaceHolder().OnHide = { function()
		Spring.SetConfigInt("VSync", Spring.GetConfigInt("VSyncGame", defaultVSyncGame))
	end }
end

function widget:Shutdown()
	if WG.Chobby.interfaceRoot.GetLobbyInterfaceHolder().visible then
		Spring.SetConfigInt("VSync", Spring.GetConfigInt("VSyncGame", defaultVSyncGame))
	end
end

------------
-- Update --
------------

function widget:ViewResize(vsx, vsy)
	if not initialized then return end
	WG.LimitFps.ForceRedrawPeriod(0.5)
end

function widget:Update()
	if not initialized then
		self:Initialize()
		initialized = true
	end

	if not WG.Chobby.interfaceRoot.GetLobbyInterfaceHolder().visible then
		return
	end

	if WG.Chobby.Configuration.drawAtFullSpeed ~= drawAtFullspeed then
		drawAtFullspeed = WG.Chobby.Configuration.drawAtFullSpeed
		init()
		Spring.SetConfigInt("VSync", vSyncStateValues[vSyncState])
	end

	if vSyncState == VSYNC_STATE_GRACE then
		stateTimer:Update()
		awayTimer:Update()
		return
	end

	local mouseX, mouseY, lmb, mmb, rmb, mouseOffscreen = Spring.GetMouseState()
	
	if vSyncState == VSYNC_STATE_OFFSCREEN then
		if not mouseOffscreen then
			logUserInput()
		end
	else
		if mouseOffscreen then
			SetVSyncState(VSYNC_STATE_OFFSCREEN)
		else
			if mouseX ~= lastMouseX or mouseY ~= lastMouseY or lmb or mmb or rmb  then
				lastMouseX, lastMouseY = mouseX, mouseY
				logUserInput()
			end
			stateTimer:Update()
		end
		awayTimer:Update()
	end
end

function widget:MousePress()	-- doesnt get called
	logUserInput()
end

function widget:MouseWheel()
	logUserInput()
end

function widget:KeyPress()
	logUserInput()
end

function widget:KeyRelease()
	logUserInput()
end

function widget:TextInput()
	logUserInput()
end

function widget:TextEditing()
	logUserInput()
end

-- Enables Draw{Genesis,Screen,ScreenPost} callins if true is returned, otherwise they are called once every 30 seconds. Only active when a game isn't running.
function widget:AllowDraw()
	if not initialized then return end
	if WG.Chobby.Configuration.fixFlicker then
		return true
	end
	if msaaLevel == 0 then	-- msaaLevel 0 will induce the lobby flicker glitch
		return true
	end

	if os.clock() > nextFrameTime then
		nextFrameTime = os.clock() + 1 / stateFPSValues[vSyncState]
		return true
	else
		return false
	end
end