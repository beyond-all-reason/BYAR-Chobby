-- Sometimes this gets cached, hence the variable..
local ENABLED = false

function widget:GetInfo()
	return {
		name = "Command capture",
		desc = "Captures lobby commands",
		author = "gajop",
		date = "",
		license = "",
		layer = 99999,
		enabled = ENABLED
	}
end

if ENABLED then

local profiled = {}

function widget:Initialize()
	Spring.Echo("===Command capture initialized===")
	lobby = WG.LibLobby.lobby
end

function widget:Shutdown()
	RestoreFunctions()
end

local executed = false
function widget:Update()
	if executed then
		return
	end

	-- TODO: For some reason we can't measure both of these commands
	-- If we try, log information will be done for _OnCommandReceived twice (some lua inheritance magic again?)
	CaptureFunction(lobby, "CommandReceived", "Interface:CommandReceived")
	-- CaptureFunction(lobby, "_OnCommandReceived", "Interface:_OnCommandReceived")

	executed = true
end

function CaptureFunction(obj, fname, registerName)
	Spring.Echo("Capturing function [" .. tostring(fname) .. "] as " .. tostring(registerName))
	local orig = obj[fname]
	local overridenFunction = function(_obj, ...)
		local capturedCall = {}
		for i, arg in ipairs({...}) do
			capturedCall['arg' .. tostring(i)] = arg
		end
		capturedCall["function"] = tostring(registerName)

		capturedCall["start_time"] = os.clock()

		profiled[registerName].orig(_obj, ...)

		capturedCall["end_time"] = os.clock()
		Spring.Echo("|CAPTURE| " .. Json.encode(capturedCall))
	end
	obj[fname] = overridenFunction

	profiled[registerName] = {
		obj = obj,
		fname = fname,
		orig = orig
	}
end

function RestoreFunctions()
	for _, p in pairs(profiled) do
		p.obj[p.fname] = p.orig
	end
end

end
