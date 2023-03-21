function widget:GetInfo()
	return {
		name = "Command capture",
		desc = "Captures lobby commands",
		author = "gajop",
		date = "",
		license = "",
		layer = 99999,
		enabled = true
	}
end

VFS.Include("libs/json.lua")

local Configuration
local lobby

local captured = {}
local captureFile
local enabled = false

function widget:Initialize()
	lobby = WG.LibLobby.lobby
	WG.Delay(function()
		Configuration = WG.Chobby.Configuration
		SetState(Configuration.captureServerCommands)

		Configuration:AddListener("OnConfigurationChange",
			function(listener, key, value)
				if key == "captureServerCommands" then
					SetState(value)
				end
			end
		)
	end, 0.1)
end

function widget:Shutdown()
	Disable()
end

function SetState(value)
	if enabled == value then
		return
	end
	enabled = value

	if enabled then
		Spring.Echo("===Command capture initialized===")
		-- TODO: For some reason we can't measure both of these commands
		-- If we try, log information will be done for _OnCommandReceived twice (some lua inheritance magic again?)
		CaptureFunction(lobby, "CommandReceived", "Interface:CommandReceived")
		-- CaptureFunction(lobby, "_OnCommandReceived", "Interface:_OnCommandReceived")
	else
		Spring.Echo("===Command capture disabled===")
		Disable()
	end
end

function CaptureFunction(obj, fname, registerName)
	Spring.Echo("Capturing function [" .. tostring(fname) .. "] as " .. tostring(registerName))
	if captureFile == nil then
		captureFile = io.open("commands.log", "a")
	end
	local orig = obj[fname]
	local overridenFunction = function(_obj, ...)
		local capturedCall = {}
		for i, arg in ipairs({...}) do
			capturedCall['arg' .. tostring(i)] = arg
		end
		capturedCall["function"] = tostring(registerName)

		capturedCall["start_time"] = os.clock()

		captured[registerName].orig(_obj, ...)

		capturedCall["end_time"] = os.clock()
		captureFile:write(json.encode(capturedCall))
		captureFile:write("\n")
	end
	obj[fname] = overridenFunction

	captured[registerName] = {
		obj = obj,
		fname = fname,
		orig = orig
	}
end

function Disable()
	if captureFile then
		captureFile:close()
		captureFile = nil
	end

	for _, p in pairs(captured) do
		p.obj[p.fname] = p.orig
	end
end
