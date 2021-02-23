
local items = 	{
	{
		name = "skirmish",
		control = WG.BattleRoomWindow.GetSingleplayerControl(),
		entryCheck = WG.BattleRoomWindow.SetSingleplayerGame,
	},
	{
		name = "scenarios",
		control = WG.ScenarioHandler.GetControl(),
		startWithTabOpen = 1,
	}
}
--Spring.Echo("campaign Error: ",WG.Chobby.Configuration,WG.Chobby.Configuration.debugMode)
if WG.Chobby.Configuration then --and
	--WG.Chobby.Configuration.showCampaignButton then
	items[#items+1] = 	{
		name = "wip_challenges", 
		entryCheck = WG.CampaignSaveWindow.PromptInitialSaveName,
		entryCheckBootMode = true,
		submenuData = {
			submenuControl = WG.CampaignHandler.GetControl(true),
			tabs = {
				{
					name = "technology",
					control = WG.TechnologyHandler.GetControl(),
				},
				{
					name = "commander",
					control = WG.CommanderHandler.GetControl(),
				},
				--{
				--	name = "codex",
				--	control = WG.CodexHandler.GetControl(),
				--},
				{
					name = "options",
					control = WG.CampaignOptionsWindow.GetControl(),
				},
			},
		},
	}
end
--[[self.btnSteamFriends:SetVisibility(Configuration.canAuthenticateWithSteam)
local function onConfigurationChange(listener, key, value)
	if key == "canAuthenticateWithSteam" then
		self.btnSteamFriends:SetVisibility(value)
	end
end]]--
return items


	--{
		--name = "WiP Editor",
		--control = WG.SpringBoardWindow.GetControl(),
	--},

