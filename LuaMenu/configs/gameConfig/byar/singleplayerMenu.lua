local items = 	{
	{
		name = "skirmish",
		control = WG.BattleRoomWindow.GetSingleplayerControl(VFS.Include(LUA_DIRNAME .. "configs/gameConfig/byar/singleplayerQuickSkirmish.lua")),
		entryCheck = WG.BattleRoomWindow.SetSingleplayerGame,
	},
	{
		name = "scenarios",
		control = WG.ScenarioHandler.GetControl(),
		--startWithTabOpen = 1,
	},
	{
		-- devOnly is honoured by interface_root, which is where Configuration.devMode is
		-- readable: this file is included while Configuration is still being built.
		name = "terraformer",
		control = WG.TerraformerWindow.GetControl(),
		devOnly = true,
	},
	{
		name = "load_game",
		control = WG.LoadGameWindow.GetControl(),
		entryCheck = WG.BattleRoomWindow.SetSingleplayerGame,
	},
}

--[[self.btnSteamFriends:SetVisibility(Configuration.canAuthenticateWithSteam)
local function onConfigurationChange(listener, key, value)
	if key == "canAuthenticateWithSteam" then
		self.btnSteamFriends:SetVisibility(value)
	end
end
--]]
return items