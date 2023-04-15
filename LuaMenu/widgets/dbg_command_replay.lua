function widget:GetInfo()
	return {
		name = "Command replay",
		desc = "Replays lobby commands",
		author = "gajop",
		date = "",
		license = "",
		layer = 99999,
		enabled = false,
	}
end

VFS.Include("libs/json.lua")

--------------------------------------------------------------------------------
-- Local Variables
--------------------------------------------------------------------------------

-- Seems unwise to make this a GUI setting, even if it's Dev-only...
-- I wonder if there's a good way to have local overrides without it being tracked by Git.
local AUTO_QUIT_ON_FINISH = false

local Configuration, lobby
local enabled = false

--------------------------------------------------------------------------------
-- Local Functions
--------------------------------------------------------------------------------
local function SetState(value)
	if enabled == value then
		return
	end
	enabled = value

	if enabled then
		Spring.Log(LOG_SECTION, Log.Debug, "===Command replay starting...===")
		local cmds = json.decode(VFS.LoadFile("commands.json"))
		Spring.Log(LOG_SECTION, Log.Debug, "Total commands: ", #cmds)

		for i, v in ipairs(cmds) do
			lobby:CommandReceived(v)
		end

		if AUTO_QUIT_ON_FINISH then
			Spring.Quit()
		end
	else
		Spring.Log(LOG_SECTION, Log.Notice, "===Command replay disabled===")
	end
end

--------------------------------------------------------------------------------
-- Widget Interface
--------------------------------------------------------------------------------

function widget:Initialize()
	lobby = WG.LibLobby.lobby
	Configuration = WG.Chobby.Configuration
	Configuration:SetConfigValue("replayServerCommands", false)
	SetState(false)
	WG.Delay(function()
		Configuration:AddListener("OnConfigurationChange",
			function(listener, key, value)
				if key == "replayServerCommands" then
					SetState(value)
				end
			end
		)
	end, 0.1)
end


