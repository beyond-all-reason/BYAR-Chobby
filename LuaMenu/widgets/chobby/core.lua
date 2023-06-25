local includes = {
	-- order matters
	"headers/exports.lua",

	-- config
	"components/configuration.lua",

	-- basic components
	"components/component.lua",
	"components/list_window.lua",
	"components/console.lua",
	"components/user_list_panel.lua",
	"components/sortable_list.lua",

	-- misc
	"components/login_window.lua",
	"components/steam_login_window.lua",
	"components/chat_windows.lua",
	"components/team_window.lua",
	"components/downloader.lua",
	"components/background.lua",

	-- battle
	"components/battle/battle_list_window.lua",
	"components/battle/battle_watch_list_window.lua",

	-- friends
	"components/friend_list_window.lua",

	-- new stuff
	"components/interface_root.lua",
	"components/tab_panel_handler.lua",
	"components/submenu_handler.lua",
	"components/priority_popup.lua",
	"components/ai_list_window.lua",
	"components/aioptions_window.lua",
	"components/game_list_window.lua",
	"components/confirmation_popup.lua",
	"components/information_popup.lua",
	"components/control_panel_handler.lua",
}

Chobby = widget

function Chobby:_Initialize()
	for _, file in ipairs(includes) do
		self:WrapCall(function()
			VFS.Include(CHOBBY_DIR .. file, Chobby, VFS.ZIP)
		end)
	end

	-- Invalidate the chili font cache. Without this certain font sizes
	-- will be invisible after Spring.Reload on many systems.
	Chili.FontHandler.InvalidateFontCache()
	self:WrapCall(function()
		WG.Delay(function()
			lobby:AddListener("OnJoinBattle",
				function(listener, battleID)
					local battle = lobby:GetBattle(battleID)
					if not WG.Chobby.Configuration.showMatchMakerBattles and battle and battle.isMatchMaker then
						WG.BattleStatusPanel.RemoveBattleTab()
						return
					end
					Spring.Log("chobby", LOG.NOTICE, "Showing battle with ID", battleID)
					WG.BattleRoomWindow.ShowMultiplayerBattleRoom(battleID)
				end
			)
		end, 0.001)
	end)
	self:WrapCall(function()
		WG.Delay(function()
			lobby:AddListener("OnSayServerMessage",
				function(listener, text, timeSent)
					Chotify:Post({
						title = "Server",
						body = text,
					})
				end
			)
		end, 0.001)
	end)
	self:WrapCall(function()
		WG.Delay(function()
			lobby:AddListener("OnSuggestedEngineVersion",
				function(listener, engineName)
					if engineName and not WG.Chobby.Configuration.gameConfig.ignoreServerVersion and not WG.Chobby.Configuration:IsValidEngineVersion(engineName) then
						WG.Chobby.InformationPopup("Wrong Spring engine version. The required version is '" .. engineName .. "', your version is '" .. Spring.Utilities.GetEngineVersion() .. "'.\n\nRestart the game to get the correct version.", {width = 480, height = 248})
					end
				end
			)
		end, 0.001)
	end)
end

function Chobby:GetRegisteredComponents()
	return Component.registeredComponents
end

function Chobby:_DrawScreen()
	self:WrapCall(function()
	end)
end

function Chobby:_ViewResize(sw, sh)
	self:WrapCall(function()
		for i, comp in pairs(self:GetRegisteredComponents()) do
			comp:ViewResize(sw, sh)
		end
	end)
end

function Chobby:WrapCall(func)
	xpcall(function() func() end,
		function(err) self:_PrintError(err) end )
end

function Chobby:_PrintError(err)
	Spring.Log("Chobby", LOG.ERROR, err)
	Spring.Log("Chobby", LOG.ERROR, debug.traceback(err))
end

function Chobby:_GetConfigData()
	return Configuration:GetConfigData()
end

function Chobby:_SetConfigData(data)
	Configuration:SetConfigData(data)
end

return Chobby
