
function widget:GetInfo()
	return {
		name = "Limit idle FPS",
		desc = "reduces fps when user is idle" ,
		author = "Floris",
		date = "2020",
		license = "",
		layer = -math.huge,
		enabled = true
	}
end

local idleTime = 4
local idleFps = 2
local offscreenFps = 1
local activeFps = 40	-- max lobby fps
local activeFullspeedFps = 72	-- max fullspeed lobby fps
local awayTime = 60

local doVsyncTrick = false	-- creates rendering actifacts for some
local vsyncValueActive = Spring.GetConfigInt("VSync",1)
if vsyncValueActive > 1 then
	vsyncValueActive = 1
end
local vsyncValueIdle = 4    -- sometimes somehow vsync 6 results in higher fps than 4

local isIdle = false
local isAway = false
local lastUserInputTime = os.clock()
local lastMouseX, lastMouseY = Spring.GetMouseState()
local drawAtFullspeed = true
local enabled = true
local lastFrameClock = os.clock()
local toggledIsIdleClock = 0
local isOffscreen = false

function widget:Initialize()
	if WG.Chobby and WG.Chobby.Configuration then
		drawAtFullspeed = WG.Chobby.Configuration.drawAtFullSpeed
	end
	WG.isIdle = function()
		return isIdle
	end
	WG.isAway = function()
		return isAway
	end
end

function widget:Shutdown()
	if WG.Chobby and WG.Chobby.Configuration then
		WG.Chobby.Configuration.drawAtFullSpeed = drawAtFullspeed
	end
	if enabled and doVsyncTrick then
		Spring.SetConfigInt("VSync", vsyncValueActive)
	end
end

function widget:Update()

	-- detect change by user
	local curVsync = Spring.GetConfigInt("VSync",1)
	if curVsync ~= vsyncValueIdle and curVsync ~= vsyncValueActive then
		vsyncValueActive = curVsync
	end

	local prevEnabled = enabled
	if WG.Chobby and WG.Chobby.interfaceRoot then
		enabled = WG.Chobby.interfaceRoot.GetLobbyInterfaceHolder().visible
	end
	if doVsyncTrick and prevEnabled ~= enabled and not enabled then
		Spring.SetConfigInt("VSync", vsyncValueActive)
	end
	if enabled then
		local clock = os.clock()
		local prevIsOffscreen = isOffscreen
		local mouseX, mouseY, lmb, mmb, rmb, mouseOffscreen  = Spring.GetMouseState()
		isOffscreen = mouseOffscreen
		if Spring.GetKeyState(8) then -- backspace pressed
			lastUserInputTime = clock
		end
		if mouseX ~= lastMouseX or mouseY ~= lastMouseY or lmb or mmb or rmb  then
			lastMouseX, lastMouseY = mouseX, mouseY
			lastUserInputTime = clock
		end
		if mouseOffscreen then
			lastUserInputTime = clock - idleTime-1.5
		end

		drawAtFullspeed = WG.Chobby.Configuration.drawAtFullSpeed

		local prevIsIdle = isIdle
		local prevIsAway = isAway
		isIdle = (lastUserInputTime < clock - idleTime)
		isAway = (lastUserInputTime < clock - awayTime)
		if isIdle ~= prevIsIdle then
			toggledIsIdleClock = os.clock()
        end
		if doVsyncTrick and isOffscreen ~= prevIsOffscreen then
			Spring.SetConfigInt("VSync", (isIdle and vsyncValueIdle or vsyncValueActive))
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
	lastUserInputTime = os.clock()
end

function widget:MouseWheel()
	lastUserInputTime = os.clock()
end

function widget:KeyPress()
	lastUserInputTime = os.clock()
end

function widget:KeyRelease()
	lastUserInputTime = os.clock()
end

function widget:TextInput()
	lastUserInputTime = os.clock()
end

function widget:TextEditing()
	lastUserInputTime = os.clock()
end

function widget:AllowDraw()
	if not enabled then
		return true
	else
		if isIdle then
			if os.clock() > lastFrameClock + (1/(isOffscreen and offscreenFps or idleFps)) then
				lastFrameClock = os.clock()
				return true
			end
		elseif os.clock() > lastFrameClock + (1/(drawAtFullspeed and activeFullspeedFps or activeFps)) then
			lastFrameClock = os.clock()
			return true
		end
		return false
	end
end