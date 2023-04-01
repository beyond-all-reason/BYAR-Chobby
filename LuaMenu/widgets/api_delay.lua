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
local ids = 0

-- delay in miliseconds
local function DelayCall(f, delay)
	local executeTime = currentTime + delay
	local id = ids
	calls[id] = {f, executeTime}
	ids = ids + 1
end

function widget:Update()
	currentTime = os.clock()
	for i, call in pairs(calls) do
		if currentTime >= call[2] then
			success, err = pcall(function()
				call[1]()
			end)
			if not success then
				Spring.Log("delay_api", "error", "Error with delayed call: " .. tostring(err))
			end
			calls[i] = nil
		end
	end
end

WG.Delay = DelayCall
