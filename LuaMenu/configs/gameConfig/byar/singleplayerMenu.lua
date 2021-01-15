return {
	{
		name = "skirmish",
		control = WG.BattleRoomWindow.GetSingleplayerControl(),
		entryCheck = WG.BattleRoomWindow.SetSingleplayerGame,
	},
	{
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
	},
	--{
		--name = "WiP Editor",
		--control = WG.SpringBoardWindow.GetControl(),
	--},
}
