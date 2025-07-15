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
local function DelayedInitialize()
	local lobby = WG.LibLobby.lobby
	local battleList = WG.Chobby.BattleListWindow()

	--Spring.Echo("Saved BattleID: "..WG.Chobby.Configuration.rejoinID)

	local function LoginRejoinOption(listener, battleID)
		-- if no ID is present then there is no server to rejoin
		if not WG.Chobby.Configuration.rejoinID or WG.Chobby.Configuration.rejoinID == 'nil' then
			return
		end

		local battle = lobby:GetBattle(WG.Chobby.Configuration.rejoinID) -- Battle Object
		if battle == nil or battle == 'nil' then return end
		WG.Chobby.ConfirmationPopup(function() battleList:JoinBattle(battle) end,
			"You were connected to a previous lobby last time you were online. Would you like to rejoin it?", nil, 315,
			200, "rejoin", "abandon")
	end

	local function OnJoinedBattle(listener, battleID, userName)
		if userName ~= lobby:GetMyUserName() then return end

		--Spring.Echo('Saving Lobby ID: '..battleID)
		WG.Chobby.Configuration:SetConfigValue("rejoinID", battleID)
	end

	local function OnLeftBattle(listener, battleID, userName)
		if userName ~= lobby:GetMyUserName() then return end

		--Spring.Echo('Removing Lobby ID: '..battleID)
		WG.Chobby.Configuration:SetConfigValue("rejoinID", nil)
	end

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
