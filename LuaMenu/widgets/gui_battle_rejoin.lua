--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:GetInfo()
	return {
		name    = "Battle Rejoin",
		desc    = "Prompts the user to rejoin a previous battle on login.",
		author  = "Rogshotz",
		date    = "13 July 2025",
		license = "GNU LGPL, v2.1 or later",
		layer   = 0,
		enabled = true
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local lobby, battleList
local MAX_REJOIN_PROMPT_AGE = 4 * 60 * 60 -- 4 hours

local function LoginRejoinOption(listener, battleID)
	-- Check if a battle ID has been stored for rejoining.
	if not WG.Chobby.Configuration.rejoinBattleID then
		return
	end

	local rejoinBattleTimestamp = tonumber(WG.Chobby.Configuration.rejoinBattleTimestamp)
	if not rejoinBattleTimestamp then
		WG.Chobby.Configuration:SetConfigValue("rejoinBattleID", nil)
		return
	end

	local now = os.time()
	if not now or (now - rejoinBattleTimestamp) > MAX_REJOIN_PROMPT_AGE then
		WG.Chobby.Configuration:SetConfigValue("rejoinBattleID", nil)
		WG.Chobby.Configuration:SetConfigValue("rejoinBattleTimestamp", nil)
		return
	end
	-- Spring.Echo("Saved BattleID: "..WG.Chobby.Configuration.rejoinID)

	local battle = lobby:GetBattle(WG.Chobby.Configuration.rejoinBattleID) -- Battle Object
	if battle == nil then
		WG.Chobby.Configuration:SetConfigValue("rejoinBattleID", nil)
		WG.Chobby.Configuration:SetConfigValue("rejoinBattleTimestamp", nil)
		return
	end
	
	local function doJoinBattle()
		battleList:JoinBattle(battle)
	end
	
	WG.Chobby.ConfirmationPopup(doJoinBattle, i18n("rejoinBattlePopup"), nil, 315, 200, i18n("rejoin"), i18n("abandon"))
end

local function OnJoinedBattle(listener, battleID, userName)
	if userName ~= lobby:GetMyUserName() then
		return
	end

	-- Spring.Echo('Saving Lobby ID: '..battleID)
	WG.Chobby.Configuration:SetConfigValue("rejoinBattleID", battleID)
	WG.Chobby.Configuration:SetConfigValue("rejoinBattleTimestamp", os.time())
end

local function OnLeftBattle(listener, battleID, userName)
	if userName ~= lobby:GetMyUserName() then
		return
	end

	-- Spring.Echo('Removing Lobby ID: ' .. battleID)
	WG.Chobby.Configuration:SetConfigValue("rejoinBattleID", nil)
	WG.Chobby.Configuration:SetConfigValue("rejoinBattleTimestamp", nil)
end

local function DelayedInitialize()
	lobby = WG.LibLobby.lobby
	battleList = WG.Chobby.BattleListWindow()

	lobby:AddListener("OnLoginInfoEnd", LoginRejoinOption)
	lobby:AddListener("OnJoinedBattle", OnJoinedBattle)
	lobby:AddListener("OnLeftBattle", OnLeftBattle)
end

function widget:Initialize()
	CHOBBY_DIR = LUA_DIRNAME .. "widgets/chobby/"
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)
	WG.Delay(DelayedInitialize, 1)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
