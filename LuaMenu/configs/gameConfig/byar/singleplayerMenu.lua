
local items = 	{
	{
		name = "Skirmish",
		control = WG.BattleRoomWindow.GetSingleplayerControl(),
		entryCheck = WG.BattleRoomWindow.SetSingleplayerGame,
	},
	{
		name = "Scenarios",
		control = WG.ScenarioHandler.GetControl(),
		--startWithTabOpen = 1,
	},
	{
		name = "Load Game",
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