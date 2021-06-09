
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

local idleTime = 0.05	-- not actual idle, just threshold when to decrease fps quickly
local idleFps = 6		-- (not instant) lowering to this fps quickly
local idleFrameTimeDelay = 0.04 -- slowing fps increasingly by this much
local sleepTime = 1
local sleepFps = 3
local hibernateTime = 5
local hibernateFps = 1
local offscreenFps = 1

local activeFps = 40
local activeFullspeedFps = 80
local awayTime = 60

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
local enabled = true

local vsyncValueGame = Spring.GetConfigInt("VSync",1)
local vsyncValueLobby = 1
local vsyncValueHibernate = 4
local vsyncValueOffscreen = 6    -- sometimes somehow vsync 6 results in higher fps than 4

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
					vsyncValueLobby = 2
					if monitorFrequency >= 200 then
						vsyncValueLobby = 3
					end
					break
				end
			end
		end
	end
end

local function logUserInput()
	local clock = os.clock()
	if clock > lastUserInputTime then
		lastUserInputTime = clock
	end
end

function widget:Initialize()
	if WG.Chobby and WG.Chobby.Configuration then
		drawAtFullspeed = WG.Chobby.Configuration.drawAtFullSpeed
	end

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

function widget:Update()

	local prevEnabled = enabled
	if WG.Chobby and WG.Chobby.interfaceRoot then
		enabled = WG.Chobby.interfaceRoot.GetLobbyInterfaceHolder().visible
	end
	if prevEnabled ~= enabled then
		Spring.SetConfigInt("VSync", (enabled and vsyncValueLobby or vsyncValueGame))
	end
	if enabled then
		local clock = os.clock()
		local prevIsOffscreen = isOffscreen
		local prevIsHibernate = isHibernate
		local mouseX, mouseY, lmb, mmb, rmb, mouseOffscreen  = Spring.GetMouseState()
		isOffscreen = mouseOffscreen
		if Spring.GetKeyState(8) then -- backspace pressed
			logUserInput()
		end
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

		drawAtFullspeed = WG.Chobby.Configuration.drawAtFullSpeed

		local prevIsAway = isAway
		local prevIsIdle = isIdle
		isIdle = (lastUserInputTime < clock - idleTime)

		if isIdle ~= prevIsIdle then
			nextFrameTime = clock-1
		end
		isSleep = (lastUserInputTime < clock - sleepTime)
		isHibernate = (lastUserInputTime < clock - hibernateTime)
		isAway = (lastUserInputTime < clock - awayTime)

		if not isOffscreen and  isHibernate ~= prevIsHibernate then
			Spring.SetConfigInt("VSync", (isHibernate and vsyncValueHibernate or vsyncValueLobby))
		end

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

function widget:AllowDraw()
	if isIdle then
		if os.clock() > nextFrameTime then
			if isHibernate then
				frameDelayTime = 1/hibernateFps
			elseif isSleep then
				frameDelayTime = 1/sleepFps
			else
				frameDelayTime = math.max(1/idleFps, frameDelayTime + idleFrameTimeDelay)
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