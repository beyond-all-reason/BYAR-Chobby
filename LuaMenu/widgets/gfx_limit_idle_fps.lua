
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

local idleTime = 3
local awayTime = 60

local vsyncValueActive = Spring.GetConfigInt("VSync",1)
if vsyncValueActive > 1 then
	vsyncValueActive = 1
end
local vsyncValueIdle = 4    -- sometimes somehow vsync 6 results in higher fps than 4

-- disabled code below because it did work on my separate 144hz monitor, not on my laptop 144hz monitor somehow (then 6 results in more fps than even 4)
--
-- detect display frequency > 60 and set vsyncValueIdle to 6
--local infolog = VFS.LoadFile("infolog.txt")
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
--				local frequency = s_displaymode:sub(s_displaymode:find('%@')+1, s_displaymode:find('Hz ')-1)
--				if tonumber(frequency) > 60 then
--					vsyncValueIdle = 6
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

function widget:Initialize()
	if WG.Chobby and WG.Chobby.Configuration then
		drawAtFullspeed = WG.Chobby.Configuration.drawAtFullSpeed
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
