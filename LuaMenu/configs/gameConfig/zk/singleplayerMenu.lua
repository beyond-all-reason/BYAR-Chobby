local FEEDBACK_LINK = "http://zero-k.info/Forum/Thread/24614"

local planetWhitelist = {
	-- Tutorial Cloaky http://zero-k.info/Forum/Thread/24417
	[69] = true,
	[1] = true,
	[2] = true,
	[3] = true,
	[5] = true,
	-- Adv. Cloaky http://zero-k.info/Forum/Thread/24429
	[4] = true,
	[6] = true,
	[7] = true,
	[8] = true,
	[20] = true,
	-- Shield http://zero-k.info/Forum/Thread/24441
	[13] = true,
	[14] = true,
	[15] = true,
	[16] = true,
	[17] = true,
	[19] = true,
	-- Rover http://zero-k.info/Forum/Thread/24457
	[9] = true,
	[10] = true,
	[11] = true,
	[12] = true,
	[43] = true,
	[52] = true,
	-- Amph and Hover http://zero-k.info/Forum/Thread/24469
	[22] = true,
	[23] = true,
	[24] = true,
	[25] = true,
	[26] = true,
	[27] = true,
	[28] = true,
	-- Tank, Terraform, Dante http://zero-k.info/Forum/Thread/24489
	[18] = true,
	[21] = true,
	[29] = true,
	[40] = true,
	[41] = true,
	[42] = true,
	[71] = true,
	-- Gunship, Firewalker, Skuttle, Athena http://zero-k.info/Forum/Thread/24510
	[36] = true,
	[37] = true,
	[38] = true,
	[39] = true,
	[53] = true,
	[54] = true,
	[56] = true,
	-- Spider and Ships http://zero-k.info/Forum/Thread/24530
	[30] = true,
	[31] = true,
	[32] = true,
	[44] = true,
	[45] = true,
	[46] = true,
	[47] = true,
	-- Planes, Behemoth, Bertha, Missile Silo, Scorpion http://zero-k.info/Forum/Thread/24566
	[33] = true,
	[34] = true,
	[35] = true,
	[48] = true,
	[49] = true,
	[62] = true,
	[70] = true,
	-- Jumps, Nuke, Sea Striders http://zero-k.info/Forum/Thread/24594
	[50] = true,
	[51] = true,
	[55] = true,
	[57] = true,
	[60] = true,
	-- Land Striders and Heavy Defences http://zero-k.info/Forum/Thread/24614
	[58] = true,
	[59] = true,
	[61] = true,
	[63] = true,
	-- Paladin, Detriment and Superweapons http://zero-k.info/Forum/Thread/24642
	[64] = true,
	[65] = true,
	[66] = true,
	[67] = true,
	[68] = true,
}

return {
	{
		name = "campaign",
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
	{
		name = "skirmish",
		control = WG.BattleRoomWindow.GetSingleplayerControl(VFS.Include(LUA_DIRNAME .. "configs/gameConfig/zk/singleplayerQuickSkirmish.lua")),
		entryCheck = WG.BattleRoomWindow.SetSingleplayerGame,
	},
	{
		name = "load",
		control = WG.LoadGameWindow.GetControl(),
		entryCheck = WG.BattleRoomWindow.SetSingleplayerGame,
	},
}

