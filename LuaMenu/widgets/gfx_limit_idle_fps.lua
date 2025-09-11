
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

local idleTime = 0.5
local idleFps = 10	-- lower numbers will result in more severe flicker on some card/driver settings
local sleepTime = 1
local sleepFps = 5
local hibernateTime = 2
local hibernateFps = 2
local offscreenFps = 1

local activeFps = 40
local activeFullspeedFps = 70	-- reset in init()
local awayTime = 300

local isIdle = false
local isSleep = false
local isHibernate = false
local isAway = false
local lastUserInputTime = os.clock()
local lastMouseX, lastMouseY = Spring.GetMouseState()
local drawAtFullspeed = true
local isOffscreen = false
local nextFrameTime = os.clock()
local frameDelayTime = 0
local enabled = false

local msaaLevel = tonumber(Spring.GetConfigInt("MSAALevel", 0))

local vsyncValueGame = Spring.GetConfigInt("VSync",1)
if vsyncValueGame > 3 then
	vsyncValueGame = 1
end
vsyncValueGame = Spring.GetConfigInt("VSyncGame", vsyncValueGame) * Spring.GetConfigInt("VSyncFraction", 1)	-- its stored here as assurance cause lobby/game also changes vsync when idle and lobby could think game has set vsync 4+ after a hard crash
local vsyncValueLobby = 1
local vsyncValueSleep = vsyncValueLobby + 2
local maxVsync = 6
local vsyncValueHibernate = maxVsync
local vsyncValueOffscreen = maxVsync

local isLinux = string.find(Platform.osName:lower(), 'linux')	-- not sure what exact implications linux has, but someone reported flickering

local isIntel = (Platform ~= nil and Platform.gpuVendor == 'Intel')
local isNvidia = (Platform ~= nil and Platform.gpuVendor == 'Nvidia')
local isAmd = (Platform ~= nil and Platform.gpuVendor == 'AMD') or (not isIntel and not isNvidia)

if isIntel or isLinux then
	maxVsync = 4	-- intel seems to no support vsync above 4 (but haven't tested the new intel XE)
	vsyncValueHibernate = maxVsync
	vsyncValueOffscreen = maxVsync
	idleTime = 0.25
	idleFps = 30	-- lower numbers will result in more severe flicker on intel gfx
	sleepTime = 1
	sleepFps = 15
	hibernateTime = 2
	hibernateFps = 2
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
	if monitorFrequency >= 110 then
		vsyncValueLobby = 2
	elseif monitorFrequency >= 200 then
		vsyncValueLobby = 3
	else
		vsyncValueLobby = 1
	end
	if not drawAtFullspeed then
		vsyncValueLobby = vsyncValueLobby + 1
	end
	vsyncValueSleep = vsyncValueLobby + 2
	if vsyncValueSleep > maxVsync then vsyncValueSleep = maxVsync end
	if vsyncValueLobby > maxVsync then vsyncValueLobby = maxVsync end
	if vsyncValueHibernate > maxVsync then vsyncValueHibernate = maxVsync end
	if vsyncValueOffscreen > maxVsync then vsyncValueOffscreen = maxVsync end

	activeFullspeedFps = math.ceil(monitorFrequency/vsyncValueLobby)
	if activeFullspeedFps < 60 then
		activeFullspeedFps = 60
	elseif activeFullspeedFps > 80 then
		activeFullspeedFps = 80
	end
end

local function logUserInput()
	local clock = os.clock()
	if clock > lastUserInputTime then
		lastUserInputTime = clock
	end
end

function widget:Initialize()
	Spring.SetConfigInt("VSync", math.min(maxVsync, vsyncValueLobby))

	if WG.Chobby and WG.Chobby.Configuration then
		drawAtFullspeed = WG.Chobby.Configuration.drawAtFullSpeed
	end
	init()

	WG.LimitFps = {}
	WG.LimitFps.ForceRedrawPeriod = function(time)	-- optional time for duration of prolonged wakeness
		lastUserInputTime = os.clock() + (time or 0)
		if nextFrameTime > os.clock() + (1/(drawAtFullspeed and activeFullspeedFps or activeFps)) then
			nextFrameTime = os.clock()
		end
	end
	WG.LimitFps.ForceRedraw = WG.LimitFps.ForceRedrawPeriod

	WG.isAway = function()
		return isAway
	end
end

function widget:Shutdown()
	if WG.Chobby and WG.Chobby.Configuration then
		WG.Chobby.Configuration.drawAtFullSpeed = drawAtFullspeed
	end
	if enabled then
		Spring.SetConfigInt("VSync", vsyncValueGame)
	end
end

function widget:ViewResize(vsx, vsy)
	WG.LimitFps.ForceRedrawPeriod(0.5)
end


local basememlimit = 200000
local garbagelimit = basememlimit -- in kilobytes, will adjust upwards as needed
local lastGCchecktime = Spring.GetTimer()

function widget:Update()
	if Spring.DiffTimers(Spring.GetTimer(), lastGCchecktime) > 1 then
		lastGCchecktime = Spring.GetTimer()
		local ramuse = gcinfo()
		--Spring.Echo("RAMUSE",ramuse)
		if ramuse > garbagelimit then 
			collectgarbage("collect")
			collectgarbage("collect")
			local notgarbagemem = gcinfo()
			local newgarbagelimit = math.min(1000000, notgarbagemem + basememlimit) -- peak 1 GB
			local msg = string.format("Chobby Using %d MB RAM > %d MB limit, performing garbage collection to %d MB and adjusting limit to %d MB",
				math.floor(ramuse/1000), 
				math.floor(garbagelimit/1000), 
				math.floor(notgarbagemem/1000),
				math.floor(newgarbagelimit/1000) ) 
			Spring.Log("Chobby", LOG.NOTICE, msg)
			garbagelimit = newgarbagelimit
		end
	end

	local prevEnabled = enabled
	if WG.Chobby and WG.Chobby.interfaceRoot then
		enabled = WG.Chobby.interfaceRoot.GetLobbyInterfaceHolder().visible
	end
	if prevEnabled ~= enabled then
		Spring.SetConfigInt("VSync", (enabled and vsyncValueLobby or vsyncValueGame))
	end
	if enabled then
		vsyncValueGame = Spring.GetConfigInt("VSyncGame", vsyncValueGame) * Spring.GetConfigInt("VSyncFraction", 1)

		if Spring.GetKeyState(8) then -- backspace pressed
			logUserInput()
		end
		local mouseX, mouseY, lmb, mmb, rmb, mouseOffscreen  = Spring.GetMouseState()
		local clock = os.clock()
		local prevIsSleep = isSleep
		local prevIsHibernate = isHibernate
		local prevIsOffscreen = isOffscreen
		isOffscreen = mouseOffscreen

		if mouseX ~= lastMouseX or mouseY ~= lastMouseY or lmb or mmb or rmb  then
			lastMouseX, lastMouseY = mouseX, mouseY
			logUserInput()
		end

		if isOffscreen ~= prevIsOffscreen then
			Spring.SetConfigInt("VSync", (isOffscreen and vsyncValueOffscreen or vsyncValueLobby))
			if mouseOffscreen then
				lastUserInputTime = clock - 1
			end
		end

		if WG.Chobby.Configuration.drawAtFullSpeed ~= drawAtFullspeed then
			drawAtFullspeed = WG.Chobby.Configuration.drawAtFullSpeed
			init()
			Spring.SetConfigInt("VSync", (isHibernate and vsyncValueHibernate or vsyncValueLobby))
		end

		local prevIsAway = isAway
		local prevIsIdle = isIdle
		isIdle = (lastUserInputTime < clock - idleTime)

		if isIdle ~= prevIsIdle then
			nextFrameTime = clock-1
		end

		-- launch grace period
		if os.clock() < 30 and os.clock() - lastUserInputTime > sleepTime+0.01 then
			lastUserInputTime = clock - (sleepTime+0.01)
		end

		isSleep = (lastUserInputTime < clock - sleepTime)
		if not isOffscreen and isSleep ~= prevIsSleep then
			Spring.SetConfigInt("VSync", (isSleep and vsyncValueSleep or vsyncValueLobby))
		end

		isHibernate = (lastUserInputTime < clock - hibernateTime)
		if not isOffscreen and isHibernate ~= prevIsHibernate then
			Spring.SetConfigInt("VSync", (isHibernate and vsyncValueHibernate or vsyncValueLobby))
		end

		isAway = (lastUserInputTime < clock - awayTime)
		if isAway ~= prevIsAway then
			local lobby = WG.LibLobby.lobby
			if lobby.SetIngameStatus then
				lobby:SetIngameStatus(nil,isAway)
			end
		end
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
	if WG.Chobby.Configuration.fixFlicker then
		return true
	end
	if msaaLevel == 0 then	-- msaaLevel 0 will induce the lobby flicker glitch
		return true
	end
	if isIdle then
		if os.clock() > nextFrameTime then
			if isOffscreen then
				frameDelayTime = 1/offscreenFps
			elseif isHibernate then
				frameDelayTime = 1/hibernateFps
			elseif isSleep then
				frameDelayTime = 1/sleepFps
			else
				frameDelayTime = 1/idleFps
			end
			nextFrameTime = os.clock()+frameDelayTime
			return true
		end
	elseif os.clock() > nextFrameTime then
		nextFrameTime = os.clock() + (1/(drawAtFullspeed and activeFullspeedFps or activeFps))
		frameDelayTime = 0.025	-- reset
		return true
	end
	return false
end