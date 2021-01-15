
local items = 	{{
	name = "skirmish",
	control = WG.BattleRoomWindow.GetSingleplayerControl(),
	entryCheck = WG.BattleRoomWindow.SetSingleplayerGame,
},}

if WG.Chobby.Configuration and
	WG.Chobby.Configuration.gameConfig and
	WG.Chobby.Configuration.gameConfig.ShowCampaignButton then
	items[#items+1] = 	{
		name = "WiP Campaign", 
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

return items


	--{
		--name = "WiP Editor",
		--control = WG.SpringBoardWindow.GetControl(),
	--},

