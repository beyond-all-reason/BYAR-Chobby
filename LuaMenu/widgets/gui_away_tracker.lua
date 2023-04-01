function widget:GetInfo()
	return {
		name    = 'Away Tracker',
		desc    = 'Notices when the player is away and sets their away status.',
		author  = 'GoogleFrog',
		date    = '4 September 2016',
		license = 'GNU GPL v3',
		layer   = -2000,
		handler = true,
		api     = true, -- Makes KeyPress occur before chili
		enabled = true,
	}
end

local currentlyAway = false

--------------------------------------------------------------------------
--------------------------------------------------------------------------

local inputTime = Spring.GetTimer()
local AWAY_TIME = 240 -- Seconds?

local function SetNotAway()
	inputTime = Spring.GetTimer()
	if currentlyAway and WG.LibLobby.lobby then
		currentlyAway = false
		WG.LibLobby.lobby:SetAwayStatus(false)
	end
end

local oldX, oldY
function widget:Update()
	local x,y = Spring.GetMouseState()
	if oldX ~= x or oldY ~= y then
		oldX, oldY = x, y
		SetNotAway()
	end

	if currentlyAway then
		return
	end
	local currentTime = Spring.GetTimer()
	local newAway = Spring.DiffTimers(currentTime, inputTime) > AWAY_TIME
	if newAway and WG.LibLobby.lobby then
		currentlyAway = true
		WG.LibLobby.lobby:SetAwayStatus(true)
	end
end

local function AwayTracker_UserActivity(awaySeconds)
	if awaySeconds < 20 then
		SetNotAway()
	end
end

--------------------------------------------------------------------------
--------------------------------------------------------------------------

function widget:MousePress(x,y,button)
	SetNotAway()
	return false
end

function widget:KeyPress(key, mods, isRepeat, label, unicode)
	SetNotAway()
	return false
end

function widget:Initialize()
	WG.AwayTracker_UserActivity = AwayTracker_UserActivity
end

--------------------------------------------------------------------------
--------------------------------------------------------------------------
