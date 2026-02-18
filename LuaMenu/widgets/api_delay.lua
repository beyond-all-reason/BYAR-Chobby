local versionNumber = "v1.0"

function widget:GetInfo()
	return {
		name      = "Delay API",
		desc      = versionNumber .. " Allows delaying of widget calls.",
		author    = "gajop",
		date      = "future",
		license   = "GNU LGPL, v2.1 or later",
		layer     = -1000000,
		enabled   = true, --  loaded by default?
		api       = true,
	}
end

local currentTime = 0
local calls = {}
local callCount = 0
local ids = 0

-- delay in seconds (os.clock units)
local function DelayCall(f, delay)
	local executeTime = currentTime + delay
	local id = ids
	calls[id] = {f, executeTime}
	callCount = callCount + 1
	ids = ids + 1
end

function widget:Update()
	if callCount == 0 then
		return
	end
	currentTime = os.clock()
	for i, call in pairs(calls) do
		if currentTime >= call[2] then
			local success, err = pcall(call[1])
			if not success then
				Spring.Log("delay_api", "error", "Error with delayed call: " .. tostring(err))
			end
			calls[i] = nil
			callCount = callCount - 1
		end
	end
end

WG.Delay = DelayCall
