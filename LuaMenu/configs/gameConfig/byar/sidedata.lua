local SIDEPICS_DIR = LUA_DIRNAME .. "configs/gameConfig/byar/sidepics/"

return {
	{	--	0
		name = "Armada",
		logo = SIDEPICS_DIR .. "armada.png",
		logoScale = 0.90,
	},
	{	--	1
		name = "Cortex",
		logo = SIDEPICS_DIR .. "cortex.png",
		logoScale = 0.85,
	},
	{	--	2
		name = "Random",
		logo = SIDEPICS_DIR .. "random.png",
	},
	{	--	3
		name = "Legion",
		logo = SIDEPICS_DIR .. "legion.png",
		requiresModoption = "experimentallegionfaction",
	},
}
