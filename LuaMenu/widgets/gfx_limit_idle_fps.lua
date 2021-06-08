
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

local vsyncValueActive = Spring.GetConfigInt("VSync",1)
if vsyncValueActive > 1 then
	vsyncValueActive = 1
end
local vsyncValueIdle = 4    -- sometimes somehow vsync 6 results in higher fps than 4

-- disabled code below because it did work on my separate 144hz monitor, not on my laptop 144hz monitor somehow (then 6 results in more fps than even 4)
--
-- detect display frequency > 60 and set vsyncValueIdle to 6
--local tryVsyncSix = true
--local triedVsyncSix = false
--local infolog = VFS.LoadFile("infolog.txt")
--local monitorFrequency = 60
--if infolog then
--	function lines(str)
--		local t = {}
--		local function helper(line) table.insert(t, line) return "" end
--		helper((str:gsub("(.-)\r?\n", helper)))
--		return t
--	end
--
--	-- store changelog into table
--	local fileLines = lines(infolog)
--
--	for i, line in ipairs(fileLines) do
--		if string.sub(line, 1, 3) == '[F='  then
--			break
--		end
--
--		if line:find('(display%-mode set to )') then
--			local s_displaymode = line:sub( line:find('(display%-mode set to )') + 20)
--			if s_displaymode:find('%@') then
--				monitorFrequency = tonumber(s_displaymode:sub(s_displaymode:find('%@')+1, s_displaymode:find('Hz ')-1))
--				if monitorFrequency > 60 then
--					--vsyncValueIdle = 6
--					tryVsyncSix = true
--					break
--				end
--			end
--		end
--	end
--end

local isIdle = false
local isAway = false
local lastUserInputTime = os.clock()
local lastMouseX, lastMouseY = Spring.GetMouseState()
local drawAtFullspeed = true
local enabled = true
local lastFrameClock = os.clock()
local toggledIsIdleClock = 0
local nextSecFps = 0
local nextFps = 0
local currentFps = 0
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
		local clock = os.clock()
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
			Spring.SetConfigInt("VSync", (isIdle and vsyncValueIdle or vsyncValueActive))
			--if isIdle and tryVsyncSix and triedVsyncSix then
			--	triedVsyncSix = os.clock()
			--end
        end
        if isAway ~= prevIsAway then
            local lobby = WG.LibLobby.lobby
			if lobby.SetIngameStatus then
				lobby:SetIngameStatus(nil,isAway)
            end
        end
		--if isIdle and tryVsyncSix then
		--	if not triedVsyncSix then
		--		triedVsyncSix = os.clock()
		--		vsyncValueActive = 6
		--		Spring.SetConfigInt("VSync", vsyncValueActive)
		--	elseif triedVsyncSix+2.5 > os.clock() then
		--		-- check if fps is lower, else revert to vsync 4
		--		if currentFps > monitorFrequency / 5 then
		--			vsyncValueActive = 4
		--			Spring.SetConfigInt("VSync", vsyncValueActive)
		--		end
		--		tryVsyncSix = false
		--	end
		--end
	end
end

-- dont get called
function widget:MousePress()
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

-- calc fps cause Spring.GetFPS doesnt exist here
--function widget:DrawScreen()
--	local clock = os.clock()
--	if nextSecFps ~= math.floor(clock) then
--		nextSecFps = math.floor(clock)
--		currentFps = nextFps
--		nextFps = 1
--	else
--		nextFps = nextFps + 1
--	end
--end

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