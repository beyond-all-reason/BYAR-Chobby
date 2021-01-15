
local planetUtilities = {}

planetUtilities.planetImages = {
	LUA_DIRNAME .. "images/planets/arid01.png",
	LUA_DIRNAME .. "images/planets/barren01.png",
	LUA_DIRNAME .. "images/planets/barren02.png",
	LUA_DIRNAME .. "images/planets/barren03.png",
	LUA_DIRNAME .. "images/planets/desert01.png",
	LUA_DIRNAME .. "images/planets/desert02.png",
	LUA_DIRNAME .. "images/planets/desert03.png",
	LUA_DIRNAME .. "images/planets/inferno01.png",
	LUA_DIRNAME .. "images/planets/inferno02.png",
	LUA_DIRNAME .. "images/planets/inferno03.png",
	LUA_DIRNAME .. "images/planets/inferno04.png",
	LUA_DIRNAME .. "images/planets/ocean01.png",
	LUA_DIRNAME .. "images/planets/ocean02.png",
	LUA_DIRNAME .. "images/planets/ocean03.png",
	LUA_DIRNAME .. "images/planets/radiated01.png",
	LUA_DIRNAME .. "images/planets/radiated02.png",
	LUA_DIRNAME .. "images/planets/radiated03.png",
	LUA_DIRNAME .. "images/planets/swamp01.png",
	LUA_DIRNAME .. "images/planets/swamp02.png",
	LUA_DIRNAME .. "images/planets/swamp03.png",
	LUA_DIRNAME .. "images/planets/terran01.png",
	LUA_DIRNAME .. "images/planets/terran02.png",
	LUA_DIRNAME .. "images/planets/terran03.png",
	LUA_DIRNAME .. "images/planets/terran03_damaged.png",
	LUA_DIRNAME .. "images/planets/terran04.png",
	LUA_DIRNAME .. "images/planets/tundra01.png",
	LUA_DIRNAME .. "images/planets/tundra02.png",
	LUA_DIRNAME .. "images/planets/tundra03.png",
}

planetUtilities.backgroundImages = {
	LUA_DIRNAME .. "images/starbackgrounds/1.jpg",
	LUA_DIRNAME .. "images/starbackgrounds/2.jpg",
	LUA_DIRNAME .. "images/starbackgrounds/3.jpg",
	LUA_DIRNAME .. "images/starbackgrounds/4.jpg",
}

planetUtilities.MAIN_EXP = 100
planetUtilities.BONUS_EXP = 25

planetUtilities.PLANET_SIZE_MAP = 36
planetUtilities.PLANET_SIZE_INFO = 240
planetUtilities.ICON_DIR = LUA_DIRNAME .. "configs/gameConfig/zk/unitpics/"

planetUtilities.planetPositions = {
	[1] = {34, 762},
	[2] = {73, 636},
	[3] = {44, 522},
	[4] = {27, 379},
	[5] = {166, 607},
	[6] = {232, 703},
	[7] = {256, 854},
	[8] = {58, 247},
	[9] = {101, 392},
	[10] = {159, 264},
	[11] = {205, 93},
	[12] = {260, 211},
	[13] = {238, 536},
	[14] = {270, 408},
	[15] = {321, 535},
	[16] = {318, 312},
	[17] = {368, 416},
	[18] = {413, 515},
	[19] = {177, 436},
	[20] = {300, 662},
	[21] = {504, 509},
	[22] = {329, 795},
	[23] = {337, 929},
	[24] = {439, 954},
	[25] = {416, 847},
	[26] = {372, 644},
	[27] = {429, 747},
	[28] = {475, 608},
	[29] = {409, 305},
	[30] = {503, 850},
	[31] = {586, 928},
	[32] = {706, 910},
	[33] = {603, 818},
	[34] = {580, 644},
	[35] = {690, 779},
	[36] = {292, 55},
	[37] = {351, 129},
	[38] = {385, 37},
	[39] = {510, 41},
	[40] = {368, 225},
	[41] = {451, 199},
	[42] = {538, 217},
	[43] = {120, 156},
	[44] = {506, 301},
	[45] = {591, 293},
	[46] = {626, 186},
	[47] = {635, 386},
	[48] = {546, 420},
	[49] = {606, 526},
	[50] = {707, 578},
	[51] = {762, 492},
	[52] = {223, 327},
	[53] = {521, 742},
	[54] = {439, 111},
	[55] = {773, 697},
	[56] = {616, 63},
	[57] = {771, 809},
	[58] = {688, 255},
	[59] = {704, 96},
	[60] = {840, 867},
	[61] = {842, 538},
	[62] = {702, 422},
	[63] = {797, 357},
	[64] = {855, 384},
	[65] = {894, 252},
	[66] = {784, 139},
	[67] = {898, 727},
	[68] = {929, 104},
	[69] = {55, 890},
	[70] = {666, 678},
	[71] = {539, 130},
}

for i = 1, #planetUtilities.planetPositions do
	local planet = planetUtilities.planetPositions[i]
	planet[1], planet[2] = planet[1]/1000, planet[2]/1000
end

planetUtilities.DEFAULT_RESOURCES = {
	metal = 0,
	energy = 100,
}

planetUtilities.COMMAND = {
	CAPTURE = 130,
	GROUPADD = 36,
	OPT_SHIFT = 32,
	PATROL = 15,
	STOP = 0,
	OPT_META = 4,
	RESURRECT = 125,
	GUARD = 25,
	INSERT = 1,
	FIGHT = 16,
	LOAD_UNITS = 75,
	RESTORE = 110,
	OPT_ALT = 128,
	INTERNAL = 60,
	OPT_INTERNAL = 8,
	MOVESTATE_HOLDPOS = 0,
	OPT_CTRL = 64,
	WAITCODE_DEATH = 2,
	MOVE_STATE = 50,
	WAIT = 5,
	OPT_RIGHT = 16,
	LOOPBACKATTACK = 20,
	AUTOREPAIRLEVEL = 135,
	SQUADWAIT = 8,
	TRAJECTORY = 120,
	MOVESTATE_ROAM = 2,
	REPEAT = 115,
	FIRE_STATE = 45,
	LOAD_ONTO = 76,
	UNLOAD_UNIT = 81,
	TIMEWAIT = 6,
	REMOVE = 2,
	MOVE = 10,
	GROUPCLEAR = 37,
	MANUALFIRE = 105,
	STOCKPILE = 100,
	GROUPSELECT = 35,
	FIRESTATE_FIREATNEUTRAL = 3,
	RECLAIM = 90,
	MOVESTATE_MANEUVER = 1,
	ONOFF = 85,
	FIRESTATE_NONE = -1,
	FIRESTATE_RETURNFIRE = 1,
	FIRESTATE_HOLDFIRE = 0,
	GATHERWAIT = 9,
	IDLEMODE = 145,
	MOVESTATE_NONE = -1,
	AISELECT = 30,
	SET_WANTED_MAX_SPEED = 70,
	FIRESTATE_FIREATWILL = 2,
	SETBASE = 55,
	WAITCODE_GATHER = 4,
	UNLOAD_UNITS = 80,
	DEATHWAIT = 7,
	REPAIR = 40,
	AREA_ATTACK = 21,
	WAITCODE_TIME = 1,
	WAITCODE_SQUAD = 3,
	ATTACK = 20,
	
	-- Custom commands
	RAW_MOVE = 31109,
	JUMP = 38521,
	AREA_GUARD = 13922, -- Don't use, causes recursion
	TRANSFER_UNIT = 38292,
	PLACE_BEACON = 35170,
	WAIT_AT_BEACON = 35171,
}

planetUtilities.ICON_OVERLAY = {
	ATTACK = LUA_DIRNAME .. "images/attack.png",
	GUARD = LUA_DIRNAME .. "images/guard.png",
	REPAIR = LUA_DIRNAME .. "images/repair.png",
	CLOCK = LUA_DIRNAME .. "images/clock.png",
	ALL = LUA_DIRNAME .. "images/battle.png",
}

planetUtilities.DIFFICULTY = {
	EASY = 1,
	MEDIUM = 2,
	HARD = 3,
	BRUTAL = 4,
}

planetUtilities.FACING = {
	SOUTH = 0,
	EAST = 1,
	NORTH = 2,
	WEST = 3,
}

planetUtilities.TERRAFORM_SHAPE = {
	RECTANGLE = 1,
	LINE = 2,
	RAMP = 3,
}

planetUtilities.TERRAFORM_TYPE = {
	LEVEL = 1,
	RAISE = 2,
	SMOOTH = 3,
}

planetUtilities.TERRAFORM_VOLUME = {
	NONE = 0,
	RAISE_ONLY = 1,
	LOWER_ONLY = 2,
}

planetUtilities.COMPARE = {
	AT_LEAST = 1,
	AT_MOST = 2
}

return planetUtilities
