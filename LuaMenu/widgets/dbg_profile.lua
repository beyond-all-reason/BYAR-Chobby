-- Sometimes this gets cashed, hence the variable..
local ENABLED = true
local CAPTURE_COMMANDS = true
local STREAM_COMMANDS = false
local AUTO_QUIT = false

function widget:GetInfo()
	return {
		name = "Performance profiler",
		desc = "Measures commands execution time and streams saved commands",
		author = "gajop",
		date = "",
		license = "",
		layer = 99999,
		enabled = ENABLED
	}
end

if ENABLED then

local profiled = {}
VFS.Include("libs/json.lua")

function widget:Initialize()
	Spring.Echo("===DEBUG===")
	lobby = WG.LibLobby.lobby

	startClock = os.clock()
end

function widget:Shutdown()
	RestoreFunctions()
end

local executed = false
function widget:Update()
	if executed then
		if AUTO_QUIT then
			Spring.Quit()
		end
		return
	end

	-- Give it some time to load the lobby before streaming commands
	if os.clock() - startClock < 3.0 then
		return
	end

	-- TODO: For some reason we can't measure both of these commands
	-- If we try, log information will be done for _OnCommandReceived twice (some lua inheritance magic again?)
	if CAPTURE_COMMANDS then
		WrapFunction(lobby, "CommandReceived", "Interface:CommandReceived")
	else
		WrapFunction(lobby, "_OnCommandReceived", "Interface:_OnCommandReceived")
	end

	executed = true

	if STREAM_COMMANDS then
		cmds = json.decode(VFS.LoadFile("commands.json"))
		Spring.Echo("Commands: " .. tostring(#cmds))

		for i, v in ipairs(cmds) do
			lobby:CommandReceived(v)
		end
	end
end

function WrapFunction(obj, fname, registerName)
	Spring.Echo("Profiling " .. tostring(registerName))
	local orig = obj[fname]
	local overridenFunction = function(...)
		argsStr = ArgsToStr(...)

		-- local startTimer = Spring.GetTimer()
		local startTimer = os.clock()

		profiled[registerName].orig(...)

		local dt = os.clock() - startTimer
		-- local dt = Spring.DiffTimers(Spring.GetTimer(), startTimer)

		Spring.Echo(
			'|TIMER| {"function":"' .. tostring(registerName) .. '",' .. argsStr .. ', "time":' .. tostring(dt) .. "}"
		)
	end
	obj[fname] = overridenFunction

	profiled[registerName] = {
		obj = obj,
		fname = fname,
		orig = orig
	}
end

function ArgsToStr(...)
	args = {...}
	argsStr = ""
	for i, v in ipairs(args) do
		local valueStr = ""
		if type(v) == "string" then
			valueStr = '"' .. tostring(v:gsub("\t", "\\t")) .. '"'
		elseif type(v) == "number" or type(v) == "boolean" then
			valueStr = tostring(v)
		else
			valueStr = '"' .. type(v) .. '"'
		end
		if i > 1 then
			argsStr = argsStr .. ","
		end
		argsStr = argsStr .. '"args' .. tostring(i - 1) .. '":' .. valueStr
	end
	return argsStr
end

function RestoreFunctions()
	for _, p in pairs(profiled) do
		p.obj[p.fname] = p.orig
	end
end

end
