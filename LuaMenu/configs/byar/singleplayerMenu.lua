return {
	{
		name = "skirmish",
		control = WG.BattleRoomWindow.GetSingleplayerControl(),
		entryCheck = WG.BattleRoomWindow.SetSingleplayerGame,
	},
	{
		name = "editor",
		control = WG.SpringBoardWindow.GetControl(),
	},
}
