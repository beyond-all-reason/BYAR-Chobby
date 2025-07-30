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

local function LoginRejoinOption(listener, battleID)
	-- Check if a battle ID has been stored for rejoining.
	if not WG.Chobby.Configuration.rejoinBattleID then
		return
	end
	-- Spring.Echo("Saved BattleID: "..WG.Chobby.Configuration.rejoinID)

	local battle = lobby:GetBattle(WG.Chobby.Configuration.rejoinBattleID) -- Battle Object
	if battle == nil then
		WG.Chobby.Configuration:SetConfigValue("rejoinBattleID", nil)
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
end

local function OnLeftBattle(listener, battleID, userName)
	if userName ~= lobby:GetMyUserName() then
		return
	end

	-- Spring.Echo('Removing Lobby ID: ' .. battleID)
	WG.Chobby.Configuration:SetConfigValue("rejoinBattleID", nil)
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
