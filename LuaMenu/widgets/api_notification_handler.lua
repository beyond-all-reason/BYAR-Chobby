--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Notification Handler",
		desc      = "Sends OS notification alerts (toast/taskbar flash) via the launcher.",
		author    = "GoogleFrog",
		date      = "23 November 2017",
		license   = "GNU LGPL, v2.1 or later",
		layer     = -100000,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local gameRan = false
local lastMenuActivation = false

local function MaybeAlert(message)
	if WG.WrapperLoopback and WG.WrapperLoopback.Alert then
		WG.WrapperLoopback.Alert(message)
	end
end

-- Battle-flow alerts (start/end/return) are noise for plain spectators, but a
-- spectator waiting in the join-queue is about to play and wants them. Rings
-- are a direct summon and bypass this gate entirely.
local function WantBattleAlerts()
	if not lobby:GetMyIsSpectator() then
		return true
	end
	return lobby:GetMyQueuePos() > 0
end

local function AddListeners()
	local function OnRing(listener, userName)
		MaybeAlert(i18n("alert_user_rang_you", {name = userName}))
	end
	lobby:AddListener("OnRing", OnRing)

	local function OnBattleAboutToStart()
		if WantBattleAlerts() then
			MaybeAlert(i18n("alert_battle_starting"))
		end
	end
	lobby:AddListener("OnBattleAboutToStart", OnBattleAboutToStart)

	local function OnBattleIngameUpdate(listener, battleID, isRunning)
		if isRunning or battleID ~= lobby:GetMyBattleID() then
			return
		end
		-- Returning from a game replays this event from the command buffer;
		-- the return-to-lobby alert already covers that moment.
		if lastMenuActivation and os.clock() - lastMenuActivation < 15 then
			return
		end
		if WantBattleAlerts() then
			MaybeAlert(i18n("alert_battle_ended"))
		end
	end
	lobby:AddListener("OnBattleIngameUpdate", OnBattleIngameUpdate)
end

function widget:ActivateGame()
	gameRan = true
end

function widget:ActivateMenu()
	-- ActivateMenu also fires once at lobby startup; gameRan keeps that silent.
	lastMenuActivation = os.clock()
	if gameRan then
		gameRan = false
		if WantBattleAlerts() then
			MaybeAlert(i18n("alert_returned_to_lobby"))
		end
	end
end

function widget:Initialize()
	CHOBBY_DIR = LUA_DIRNAME .. "widgets/chobby/"
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	AddListeners()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
