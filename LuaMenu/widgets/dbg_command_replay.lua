-- Seems unwise to make this a GUI setting, even if it's Dev-only...
-- I wonder if there's a good way to have local overrides without it being tracked by Git.
local AUTO_QUIT_ON_FINISH = false

function widget:GetInfo()
	return {
		name = "Command replay",
		desc = "Replays lobby commands",
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

local enabled = false

function widget:Initialize()
	lobby = WG.LibLobby.lobby
end

function widget:Initialize()
	lobby = WG.LibLobby.lobby
	WG.Delay(function()
		Configuration = WG.Chobby.Configuration
		SetState(Configuration.replayServerCommands)

		Configuration:AddListener("OnConfigurationChange",
			function(listener, key, value)
				if key == "replayServerCommands" then
					SetState(value)
				end
			end
		)
	end, 0.1)
end

function SetState(value)
	if enabled == value then
		return
	end
	enabled = value

	if enabled then
		Spring.Echo("===Command replay starting...===")

		cmds = json.decode(VFS.LoadFile("commands.json"))
		Spring.Echo("Total commands: " .. tostring(#cmds))

		for i, v in ipairs(cmds) do
			lobby:CommandReceived(v)
		end

		if AUTO_QUIT_ON_FINISH then
			Spring.Quit()
		end
	else
		Spring.Echo("===Command capture disabled===")
	end
end
