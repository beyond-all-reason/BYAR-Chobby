
function widget:GetInfo()
	return {
		name = "Limit idle FPS",
		desc = "reduces fps when user is idle" ,
		author = "Floris",
		date = "2020",
		license = "",
		layer = 0,
		enabled = true
	}
end

local idleTime = 3		-- when mouse is offscreen its counted as idle as well
local idleFps = 1
local awayTime = 60

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
	if enabled then
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
	if prevEnabled ~= enabled and not enabled then
		Spring.SetConfigInt("VSync", vsyncValueActive)
	end
	if enabled then
		local mouseX, mouseY, lmb, mmb, rmb, mouseOffscreen  = Spring.GetMouseState()
		if mouseX ~= lastMouseX or mouseY ~= lastMouseY or lmb or mmb or rmb  then
			lastMouseX, lastMouseY = mouseX, mouseY
			lastUserInputTime = os.clock()
		end
		if mouseOffscreen then
			lastUserInputTime = os.clock() - idleTime-1
		end

		local prevIsIdle = isIdle
		local prevIsAway = isAway
		isIdle = (lastUserInputTime < os.clock() - idleTime)
		isAway = (lastUserInputTime < os.clock() - awayTime)

		if isIdle ~= prevIsIdle then
			if WG.Chobby and WG.Chobby.Configuration then
				-- when we set vsync to 6 while drawAtFullSpeed=false -> cpu usage goes up instead of down, enabling drawAtFullSpeed prevents this
				WG.Chobby.Configuration.drawAtFullSpeed = isIdle and isIdle or drawAtFullspeed
			end
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

function widget:MousePress()
	lastUserInputTime = os.clock()
end

function widget:MouseWheel()
	lastUserInputTime = os.clock()
end

function widget:KeyPress()
	lastUserInputTime = os.clock()
end

function widget:AllowDraw()
	if isIdle then
		if os.clock() > lastFrameClock + (1/idleFps) then
			lastFrameClock = os.clock()
			return true
		else
			return false
		end
	else
		lastFrameClock = os.clock()
		return true
	end
end