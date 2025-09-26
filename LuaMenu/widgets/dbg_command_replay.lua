-- Sometimes this gets cached, hence the variable..
local ENABLED = false
local AUTO_QUIT_ON_FINISH = false
local REPLAY_START_TIME = 1.0

function widget:GetInfo()
	return {
		name = "Command replay",
		desc = "Replays lobby commands",
		author = "gajop",
		date = "",
		license = "",
		layer = 99999,
		enabled = ENABLED
	}
end

if ENABLED then

local startClock

function widget:Initialize()
	Spring.Echo("===Command replay initialized===")
	lobby = WG.LibLobby.lobby

	startClock = os.clock()
end

local executed = false
function widget:Update()
	if executed then
		if AUTO_QUIT_ON_FINISH then
			Spring.Quit()
		end
		return
	end

	-- Give it some time to load the lobby before streaming commands
	if os.clock() - startClock < REPLAY_START_TIME then
		return
	end

	executed = true

	if STREAM_COMMANDS then
		cmds = Json.Decode(VFS.LoadFile("commands.json"))
		Spring.Echo("Commands: " .. tostring(#cmds))

		for i, v in ipairs(cmds) do
			lobby:CommandReceived(v)
		end
	end
end

end
