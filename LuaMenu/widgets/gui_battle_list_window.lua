--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Battle List Window",
		desc      = "Handles battle list display.",
		author    = "GoogleFrog",
		date      = "1 May 2018",
		license   = "GNU LGPL, v2.1 or later",
		layer     = -100000,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Variables

local BATTLE_LIST_NAME = "battle_list"
local oldVisible = true
local battleListWindow

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- External Interface

local BattleListWindowHolder = {}
function BattleListWindowHolder.GetControl()
	battleListWindow = WG.Chobby.BattleListWindow()
	local function JoinBattleFunc(battle)
		battleListWindow:JoinBattle(battle)
	end
	return battleListWindow.window, JoinBattleFunc
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

function widget:Update()
	local multiplayerSubmeu = WG.Chobby and WG.Chobby.interfaceRoot and WG.Chobby.interfaceRoot.GetMultiplayerSubmenu()
	if not (multiplayerSubmeu and battleListWindow) then
		return
	end
	local visible = false
	local lobby = WG.LibLobby.lobby
	if not lobby.commandBuffer then
		local isLobbyVisible = WG.Chobby.interfaceRoot.GetLobbyInterfaceHolder().visible
		if isLobbyVisible then
			if oldVisible or (multiplayerSubmeu.IsVisible() and multiplayerSubmeu.IsTabSelected(BATTLE_LIST_NAME)) then
				visible = true
			end
		end
	end

	if visible == oldVisible then
		return
	end
	oldVisible = visible

	if visible then
		battleListWindow.listenerUpdateDisabled = false
		battleListWindow:Update()
	elseif battleListWindow then
		battleListWindow.listenerUpdateDisabled = true
	end
end

function widget:Initialize()
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)
	WG.BattleListWindowHolder = BattleListWindowHolder
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
