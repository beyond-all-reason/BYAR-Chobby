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
	local Configuration = WG.Chobby and WG.Chobby.Configuration
	if not Configuration then
		return
	end
	-- Check if a battle ID has been stored for rejoining.
	if not Configuration.rejoinBattleID then
		return
	end
	-- Spring.Echo("Saved BattleID: "..Configuration.rejoinID)

	local battle = lobby:GetBattle(Configuration.rejoinBattleID) -- Battle Object
	if battle == nil then
		Configuration:SetConfigValue("rejoinBattleID", nil)
		return
	end
	
	local function doJoinBattle()
		battleList:JoinBattle(battle)
	end
	
	if WG.Chobby and WG.Chobby.ConfirmationPopup then
		WG.Chobby.ConfirmationPopup(doJoinBattle, i18n("rejoinBattlePopup"), nil, 315, 200, i18n("rejoin"), i18n("abandon"))
	end
end

local function OnJoinedBattle(listener, battleID, userName)
	if userName ~= lobby:GetMyUserName() then
		return
	end

	-- Spring.Echo('Saving Lobby ID: '..battleID)
	local Configuration = WG.Chobby and WG.Chobby.Configuration
	if Configuration then
		Configuration:SetConfigValue("rejoinBattleID", battleID)
	end
end

local function OnLeftBattle(listener, battleID, userName)
	if userName ~= lobby:GetMyUserName() then
		return
	end

	-- Spring.Echo('Removing Lobby ID: ' .. battleID)
	local Configuration = WG.Chobby and WG.Chobby.Configuration
	if Configuration then
		Configuration:SetConfigValue("rejoinBattleID", nil)
	end
end

local function DelayedInitialize()
	lobby = WG.LibLobby and WG.LibLobby.lobby
	battleList = WG.Chobby and WG.Chobby.BattleListWindow and WG.Chobby.BattleListWindow()

	if lobby then
		lobby:AddListener("OnLoginInfoEnd", LoginRejoinOption)
		lobby:AddListener("OnJoinedBattle", OnJoinedBattle)
		lobby:AddListener("OnLeftBattle", OnLeftBattle)
	end
end

function widget:Initialize()
	CHOBBY_DIR = LUA_DIRNAME .. "widgets/chobby/"
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)
	WG.Delay(DelayedInitialize, 1)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
