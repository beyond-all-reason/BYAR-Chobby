local SIDEPICS_DIR = LUA_DIRNAME .. "configs/gameConfig/byar/sidepics/"

return {
	{
		name = "Armada",
		logo = SIDEPICS_DIR .. "armada.png",
	},
	{
		name = "Cortex",
		logo = SIDEPICS_DIR .. "cortex.png",
	},
	{
		name = "Random",
		logo = SIDEPICS_DIR .. "random.png",
	},
	{
		name = "Legion",
		logo = SIDEPICS_DIR .. "legion.png",
		requiresModoption = "experimentallegionfaction",
	},
}
