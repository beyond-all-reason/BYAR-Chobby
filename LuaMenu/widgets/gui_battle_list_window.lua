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

function widget:Initialize()
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)
	WG.BattleListWindowHolder = BattleListWindowHolder
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
