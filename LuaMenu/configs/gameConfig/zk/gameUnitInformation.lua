local nameList = {
	[1] = "cloakcon",
	[2] = "staticmex",
	[3] = "energysolar",
	[4] = "energyfusion",
	[5] = "energysingu",
	[6] = "energywind",
	[7] = "energygeo",
	[8] = "energyheavygeo",
	[9] = "staticstorage",
	[10] = "energypylon",
	[11] = "staticcon",
	[12] = "staticrearm",
	[13] = "factoryshield",
	[14] = "shieldcon",
	[15] = "factorycloak",
	[16] = "cloakraid",
	[17] = "cloakheavyraid",
	[18] = "cloakskirm",
	[19] = "cloakriot",
	[20] = "cloakassault",
	[21] = "cloakarty",
	[22] = "cloaksnipe",
	[23] = "cloakaa",
	[24] = "cloakbomb",
	[25] = "cloakjammer",
	[26] = "staticjammer",
	[27] = "factoryveh",
	[28] = "vehcon",
	[29] = "factoryplane",
	[30] = "planecon",
	[31] = "factorygunship",
	[32] = "gunshipcon",
	[33] = "factoryhover",
	[34] = "hovercon",
	[35] = "factoryamph",
	[36] = "amphcon",
	[37] = "factoryspider",
	[38] = "spidercon",
	[39] = "factoryjump",
	[40] = "jumpcon",
	[41] = "factorytank",
	[42] = "tankcon",
	[43] = "striderhub",
	[44] = "striderantiheavy",
	[45] = "striderscorpion",
	[46] = "striderdante",
	[47] = "striderarty",
	[48] = "striderfunnelweb",
	[49] = "dronelight",
	[50] = "droneheavyslow",
	[51] = "striderbantha",
	[52] = "striderdetriment",
	[53] = "shipheavyarty",
	[54] = "shipcarrier",
	[55] = "dronecarry",
	[56] = "subtacmissile",
	[57] = "factoryship",
	[58] = "shipcon",
	[59] = "staticradar",
	[60] = "staticheavyradar",
	[61] = "staticshield",
	[62] = "shieldshield",
	[63] = "turretmissile",
	[64] = "turretlaser",
	[65] = "turretimpulse",
	[66] = "turretemp",
	[67] = "turretriot",
	[68] = "turretheavylaser",
	[69] = "turretgauss",
	[70] = "turretantiheavy",
	[71] = "turretheavy",
	[72] = "turrettorp",
	[73] = "turretaalaser",
	[74] = "turretaaclose",
	[75] = "turretaafar",
	[76] = "turretaaflak",
	[77] = "turretaaheavy",
	[78] = "staticantinuke",
	[79] = "staticarty",
	[80] = "staticheavyarty",
	[81] = "staticmissilesilo",
	[82] = "tacnuke",
	[83] = "seismic",
	[84] = "empmissile",
	[85] = "napalmmissile",
	[86] = "staticnuke",
	[87] = "mahlazer",
	[88] = "raveparty",
	[89] = "zenith",
	[90] = "athena",
	[91] = "spiderscout",
	[92] = "shieldraid",
	[93] = "hoverassault",
	[94] = "jumpskirm",
	[95] = "spiderskirm",
	[96] = "tankheavyraid",
	[97] = "vehheavyarty",
	[98] = "spiderantiheavy",
	[99] = "amphtele",
	[100] = "shipscout",
	[101] = "shiptorpraider",
	[102] = "subraider",
	[103] = "shipriot",
	[104] = "shipskirm",
	[105] = "shipassault",
	[106] = "shiparty",
	[107] = "shipaa",
	[108] = "tankraid",
	[109] = "tankriot",
	[110] = "tankassault",
	[111] = "tankheavyassault",
	[112] = "tankarty",
	[113] = "tankheavyarty",
	[114] = "tankaa",
	[115] = "jumpscout",
	[116] = "jumpraid",
	[117] = "jumpblackhole",
	[118] = "jumpassault",
	[119] = "jumpsumo",
	[120] = "jumparty",
	[121] = "jumpaa",
	[122] = "jumpbomb",
	[123] = "spiderassault",
	[124] = "spideremp",
	[125] = "spiderriot",
	[126] = "spidercrabe",
	[127] = "spideraa",
	[128] = "amphraid",
	[129] = "amphimpulse",
	[130] = "amphfloater",
	[131] = "amphriot",
	[132] = "amphassault",
	[133] = "amphaa",
	[134] = "hoverraid",
	[135] = "hoverskirm",
	[136] = "hoverdepthcharge",
	[137] = "hoverriot",
	[138] = "hoverarty",
	[139] = "hoveraa",
	[140] = "gunshipbomb",
	[141] = "gunshipemp",
	[142] = "gunshipraid",
	[143] = "gunshipskirm",
	[144] = "gunshipheavyskirm",
	[145] = "gunshipassault",
	[146] = "gunshipkrow",
	[147] = "gunshipaa",
	[148] = "gunshiptrans",
	[149] = "gunshipheavytrans",
	[150] = "planefighter",
	[151] = "planeheavyfighter",
	[152] = "bomberprec",
	[153] = "bomberriot",
	[154] = "bomberdisarm",
	[155] = "bomberheavy",
	[156] = "planescout",
	[157] = "vehscout",
	[158] = "vehraid",
	[159] = "vehsupport",
	[160] = "vehriot",
	[161] = "vehassault",
	[162] = "vehcapture",
	[163] = "veharty",
	[164] = "wolverine_mine",
	[165] = "vehaa",
	[166] = "shieldscout",
	[167] = "shieldskirm",
	[168] = "shieldassault",
	[169] = "shieldriot",
	[170] = "shieldfelon",
	[171] = "shieldarty",
	[172] = "shieldaa",
	[173] = "shieldbomb",
	[174] = "amphlaunch",
    [175] = "hoverheavyraid",
}

local categories = {
	cloak = {
		name = "Cloakbots",
		order = 1,
	},
	shield = {
		name = "Shieldbots",
		order = 2,
	},
	veh = {
		name = "Rovers",
		order = 3,
	},
	tank = {
		name = "Tanks",
		order = 4,
	},
	hover = {
		name = "Hovercraft",
		order = 5,
	},
	amph = {
		name = "Amphbots",
		order = 6,
	},
	jump = {
		name = "Jumpbots",
		order = 7,
	},
	spider = {
		name = "Spiders",
		order = 8,
	},
	gunship = {
		name = "Gunships",
		order = 9,
	},
	plane = {
		name = "Planes",
		order = 10,
	},
	ship = {
		name = "Ships",
		order = 11,
	},
	strider = {
		name = "Striders",
		order = 12,
	},
	econ = {
		name = "Economy",
		order = 13,
	},
	defence = {
		name = "Defence",
		order = 14,
	},
	special = {
		name = "Special",
		order = 15,
	},
	missilesilo = {
		name = "Missile Silo",
		order = 16,
	},
	drone = {
		name = "Drones",
		order = 17,
	},
}

local humanNames = {
	-- Cloak
	factorycloak = {
		category = "cloak",
		order = 1,
		description = "Produces Cloakbots, Builds at 10 m/s",
		humanName = "Cloakbot Factory",
	},
	cloakcon = {
		category = "cloak",
		order = 2,
		description = "Cloaked Construction Bot, Builds at 5 m/s",
		humanName = "Conjurer",
	},
	cloakraid = {
		category = "cloak",
		order = 3,
		description = "Light Raider Bot",
		humanName = "Glaive",
	},
	cloakheavyraid = {
		category = "cloak",
		order = 4,
		description = "Cloaked Raider Bot",
		humanName = "Scythe",
	},
	cloakskirm = {
		category = "cloak",
		order = 5,
		description = "Skirmisher Bot (Direct-Fire)",
		humanName = "Ronin",
	},
	cloakriot = {
		category = "cloak",
		order = 6,
		description = "Riot Bot",
		humanName = "Reaver",
	},
	cloakassault = {
		category = "cloak",
		order = 7,
		description = "Lightning Assault Bot",
		humanName = "Knight",
	},
	cloakarty = {
		category = "cloak",
		order = 8,
		description = "Light Artillery Bot",
		humanName = "Sling",
	},
	cloaksnipe = {
		category = "cloak",
		order = 9,
		description = "Cloaked Skirmish/Anti-Heavy Artillery Bot",
		humanName = "Phantom",
	},
	cloakaa = {
		category = "cloak",
		order = 10,
		description = "Cloaked Anti-Air Bot",
		humanName = "Gremlin",
	},
	cloakbomb = {
		category = "cloak",
		order = 11,
		description = "All Terrain EMP Bomb (Burrows)",
		humanName = "Imp",
	},
	cloakjammer = {
		category = "cloak",
		order = 12,
		description = "Area Cloaker/Jammer Walker",
		humanName = "Iris",
	},

	-- Shield
	factoryshield = {
		category = "shield",
		order = 1,
		description = "Produces Tough Robots, Builds at 10 m/s",
		humanName = "Shield Bot Factory",
	},
	shieldcon = {
		category = "shield",
		order = 2,
		description = "Shielded Construction Bot, Builds at 5 m/s",
		humanName = "Convict",
	},
	shieldraid = {
		category = "shield",
		order = 3,
		description = "Medium-Light Raider Bot",
		humanName = "Bandit",
	},
	shieldscout = {
		category = "shield",
		order = 4,
		description = "Box of Dirt",
		humanName = "Dirtbag",
	},
	shieldskirm = {
		category = "shield",
		order = 5,
		description = "Skirmisher Bot (Indirect Fire)",
		humanName = "Rogue",
	},
	shieldriot = {
		category = "shield",
		order = 6,
		description = "Riot Bot",
		humanName = "Outlaw",
	},
	shieldassault = {
		category = "shield",
		order = 7,
		description = "Shielded Assault Bot",
		humanName = "Thug",
	},
	shieldfelon = {
		category = "shield",
		order = 8,
		description = "Shielded Riot/Skirmisher Bot",
		humanName = "Felon",
	},
	shieldarty = {
		category = "shield",
		order = 9,
		description = "Disarming Artillery",
		humanName = "Racketeer",
	},
	shieldaa = {
		category = "shield",
		order = 10,
		description = "Anti-Air Bot",
		humanName = "Vandal",
	},
	shieldbomb = {
		category = "shield",
		order = 11,
		description = "Crawling Bomb (Burrows)",
		humanName = "Snitch",
	},
	shieldshield = {
		category = "shield",
		order = 12,
		description = "Area Shield Walker",
		humanName = "Aspis",
	},

	-- Vehicle
	factoryveh = {
		category = "veh",
		order = 1,
		description = "Produces Light Wheeled Vehicles, Builds at 10 m/s",
		humanName = "Rover Assembly",
	},
	vehcon = {
		category = "veh",
		order = 2,
		description = "Construction Rover, Builds at 5 m/s",
		humanName = "Mason",
	},
	vehscout = {
		category = "veh",
		order = 3,
		description = "Disruptor Raider/Scout Rover",
		humanName = "Dart",
	},
	vehraid = {
		category = "veh",
		order = 4,
		description = "Raider Rover",
		humanName = "Scorcher",
	},
	vehsupport = {
		category = "veh",
		order = 5,
		description = "Deployable Missile Rover (must stop to fire)",
		humanName = "Fencer",
	},
	vehriot = {
		category = "veh",
		order = 6,
		description = "Riot Rover",
		humanName = "Ripper",
	},
	vehassault = {
		category = "veh",
		order = 7,
		description = "Assault Rover",
		humanName = "Ravager",
	},
	veharty = {
		category = "veh",
		order = 8,
		description = "Artillery Minelayer Rover",
		humanName = "Badger",
	},
	vehheavyarty = {
		category = "veh",
		order = 9,
		description = "Precision Artillery Rover",
		humanName = "Impaler",
	},
	vehaa = {
		category = "veh",
		order = 10,
		description = "Fast Anti-Air Rover",
		humanName = "Crasher",
	},
	vehcapture = {
		category = "veh",
		order = 11,
		description = "Capture Rover",
		humanName = "Dominatrix",
	},

	-- Tank
	factorytank = {
		category = "tank",
		order = 1,
		description = "Produces Heavy Tracked Vehicles, Builds at 10 m/s",
		humanName = "Tank Foundry",
	},
	tankcon = {
		category = "tank",
		order = 2,
		description = "Armed Construction Tank, Builds at 7.5 m/s",
		humanName = "Welder",
	},
	tankraid = {
		category = "tank",
		order = 4,
		description = "Raider Tank",
		humanName = "Kodachi",
	},
	tankheavyraid = {
		category = "tank",
		order = 3,
		description = "Lightning Assault/Raider Tank",
		humanName = "Blitz",
	},
	tankriot = {
		category = "tank",
		order = 5,
		description = "Heavy Riot Support Tank",
		humanName = "Ogre",
	},
	tankassault = {
		category = "tank",
		order = 6,
		description = "Assault Tank",
		humanName = "Minotaur",
	},
	tankheavyassault = {
		category = "tank",
		order = 7,
		description = "Very Heavy Tank Buster",
		humanName = "Cyclops",
	},
	tankarty = {
		category = "tank",
		order = 8,
		description = "General-Purpose Artillery",
		humanName = "Emissary",
	},
	tankheavyarty = {
		category = "tank",
		order = 9,
		description = "Heavy Saturation Artillery Tank",
		humanName = "Tremor",
	},
	tankaa = {
		category = "tank",
		order = 10,
		description = "Flak Anti-Air Tank",
		humanName = "Ettin",
	},

	-- Hover
	factoryhover = {
		category = "hover",
		order = 1,
		description = "Produces Hovercraft, Builds at 10 m/s",
		humanName = "Hovercraft Platform",
	},
	hovercon = {
		category = "hover",
		order = 2,
		description = "Construction Hovercraft, Builds at 5 m/s",
		humanName = "Quill",
	},
	hoverraid = {
		category = "hover",
		order = 3,
		description = "Fast Attack Hovercraft",
		humanName = "Dagger",
	},
	hoverskirm = {
		category = "hover",
		order = 4,
		description = "Skirmisher/Anti-Heavy Hovercraft",
		humanName = "Scalpel",
	},
	hoverriot = {
		category = "hover",
		order = 5,
		description = "Riot Hover",
		humanName = "Mace",
	},
	hoverassault = {
		category = "hover",
		order = 6,
		description = "Blockade Runner Hover",
		humanName = "Halberd",
	},
	hoverarty = {
		category = "hover",
		order = 7,
		description = "Anti-Heavy Artillery Hovercraft",
		humanName = "Lance",
	},
	hoveraa = {
		category = "hover",
		order = 8,
		description = "Anti-Air Hovercraft",
		humanName = "Flail",
	},
	hoverdepthcharge = {
		category = "hover",
		order = 9,
		description = "Anti-Sub Hovercraft",
		humanName = "Claymore",
	},
    hoverheavyraid = {
		category = "hover",
		order = 10,
		description = "Disruptor Hovercraft",
		humanName = "Bolas",
	},
	-- Amph
	factoryamph = {
		category = "amph",
		order = 1,
		description = "Produces Amphibious Bots, Builds at 10 m/s",
		humanName = "Amphbot Factory",
	},
	amphcon = {
		category = "amph",
		order = 2,
		description = "Amphibious Construction Bot, Builds at 7.5 m/s",
		humanName = "Conch",
	},
	amphraid = {
		category = "amph",
		order = 3,
		description = "Amphibious Raider Bot (Anti-Sub)",
		humanName = "Duck",
	},
	amphimpulse = {
		category = "amph",
		order = 4,
		description = "Amphibious Raider/Riot Bot",
		humanName = "Archer",
	},
	amphriot = {
		category = "amph",
		order = 5,
		description = "Amphibious Riot Bot (Anti-Sub)",
		humanName = "Scallop",
	},
	amphfloater = {
		category = "amph",
		order = 6,
		description = "Heavy Amphibious Skirmisher Bot",
		humanName = "Buoy",
	},
	amphassault = {
		category = "amph",
		order = 7,
		description = "Heavy Amphibious Assault Walker",
		humanName = "Grizzly",
	},
	amphlaunch = {
		category = "amph",
		order = 8,
		description = "Amphibious Launcher Bot",
		humanName = "Lobster",
	},
	amphaa = {
		category = "amph",
		order = 9,
		description = "Amphibious Anti-Air Bot",
		humanName = "Angler",
	},
	amphbomb = {
		category = "amph",
		order = 10,
		description = "Amphibious Slow Bomb",
		humanName = "Limpet",
	},
	amphtele = {
		category = "amph",
		order = 11,
		description = "Amphibious Teleport Bridge",
		humanName = "Djinn",
	},

	-- Jump
	factoryjump = {
		category = "jump",
		order = 1,
		description = "Produces Jumphet Equipped Robots, Builds at 10 m/s",
		humanName = "Jumpbot Factory",
	},
	jumpcon = {
		category = "jump",
		order = 2,
		description = "Jumpjet Constructor, Builds at 5 m/s",
		humanName = "Constable",
	},
	jumpscout = {
		category = "jump",
		order = 3,
		description = "Walking Missile",
		humanName = "Puppy",
	},
	jumpraid = {
		category = "jump",
		order = 4,
		description = "Raider/Riot Jumper",
		humanName = "Pyro",
	},
	jumpskirm = {
		category = "jump",
		order = 5,
		description = "Disruptor Skirmisher Walker",
		humanName = "Moderator",
	},
	jumpblackhole = {
		category = "jump",
		order = 6,
		description = "Black Hole Launcher",
		humanName = "Placeholder",
	},
	jumpassault = {
		category = "jump",
		order = 7,
		description = "Melee Assault Jumper",
		humanName = "Jack",
	},
	jumpsumo = {
		category = "jump",
		order = 8,
		description = "Heavy Riot Jumper",
		humanName = "Jugglenaut",
	},
	jumparty = {
		category = "jump",
		order = 9,
		description = "Saturation Artillery Walker",
		humanName = "Firewalker",
	},
	jumpaa = {
		category = "jump",
		order = 10,
		description = "Heavy Anti-Air Jumper",
		humanName = "Toad",
	},
	jumpbomb = {
		category = "jump",
		order = 11,
		description = "Cloaked Jumping Anti-Heavy Bomb",
		humanName = "Skuttle",
	},

	-- Spider
	factoryspider = {
		category = "spider",
		order = 1,
		description = "Produces Spiders, Builds at 10 m/s",
		humanName = "Spider Factory",
	},
	spidercon = {
		category = "spider",
		order = 2,
		description = "Construction Spider, Builds at 7.5 m/s",
		humanName = "Weaver",
	},
	spiderscout = {
		category = "spider",
		order = 3,
		description = "Ultralight Scout Spider (Burrows)",
		humanName = "Flea",
	},
	spideremp = {
		category = "spider",
		order = 4,
		description = "Lightning Riot Spider",
		humanName = "Venom",
	},
	spiderriot = {
		category = "spider",
		order = 5,
		description = "Riot Spider",
		humanName = "Redback",
	},
	spiderskirm = {
		category = "spider",
		order = 6,
		description = "Skirmisher Spider (Indirect Fire)",
		humanName = "Recluse",
	},
	spiderassault = {
		category = "spider",
		order = 7,
		description = "All Terrain Assault Bot",
		humanName = "Hermit",
	},
	spidercrabe = {
		category = "spider",
		order = 8,
		description = "Heavy Riot/Skirmish Spider - Curls into Armored Form When Stationary",
		humanName = "Crab",
	},
	spideraa = {
		category = "spider",
		order = 9,
		description = "Anti-Air Spider",
		humanName = "Tarantula",
	},
	spiderantiheavy = {
		category = "spider",
		order = 10,
		description = "Cloaked Scout/Anti-Heavy",
		humanName = "Widow",
	},

	-- Gunship
	factorygunship = {
		category = "gunship",
		order = 1,
		description = "Produces Gunships, Builds at 10 m/s",
		humanName = "Gunship Plant",
	},
	gunshipcon = {
		category = "gunship",
		order = 2,
		description = "Heavy Construction Aircraft, Builds at 7.5 m/s",
		humanName = "Wasp",
	},
	gunshipemp = {
		category = "gunship",
		order = 3,
		description = "Anti-Heavy EMP Drone",
		humanName = "Gnat",
	},
	gunshipraid = {
		category = "gunship",
		order = 4,
		description = "Raider Gunship",
		humanName = "Locust",
	},
	gunshipskirm = {
		category = "gunship",
		order = 5,
		description = "Multi-Role Support Gunship",
		humanName = "Harpy",
	},
	gunshipheavyskirm = {
		category = "gunship",
		order = 6,
		description = "Fire Support Gunship",
		humanName = "Nimbus",
	},
	gunshipassault = {
		category = "gunship",
		order = 7,
		description = "Heavy Raider/Assault Gunship",
		humanName = "Revenant",
	},
	gunshipkrow = {
		category = "gunship",
		order = 8,
		description = "Flying Fortress",
		humanName = "Krow",
	},
	gunshipaa = {
		category = "gunship",
		order = 9,
		description = "Anti-Air Gunship",
		humanName = "Trident",
	},
	gunshipbomb = {
		category = "gunship",
		order = 10,
		description = "Flying Bomb (Burrows)",
		humanName = "Blastwing",
	},
	gunshiptrans = {
		category = "gunship",
		order = 11,
		description = "Air Transport",
		humanName = "Charon",
	},
	gunshipheavytrans = {
		category = "gunship",
		order = 12,
		description = "Armed Heavy Air Transport",
		humanName = "Hercules",
	},

	-- Plane
	factoryplane = {
		category = "plane",
		order = 1,
		description = "Produces Airplanes, Builds at 10 m/s",
		humanName = "Airplane Plant",
	},
	planecon = {
		category = "plane",
		order = 2,
		description = "Construction Aircraft, Builds at 5 m/s",
		humanName = "Crane",
	},
	planefighter = {
		category = "plane",
		order = 3,
		description = "Multi-role Fighter",
		humanName = "Swift",
	},
	planeheavyfighter = {
		category = "plane",
		order = 4,
		description = "Air Superiority Fighter",
		humanName = "Raptor",
	},
	bomberriot = {
		category = "plane",
		order = 5,
		description = "Saturation Napalm Bomber",
		humanName = "Phoenix",
	},
	bomberprec = {
		category = "plane",
		order = 6,
		description = "Precision Bomber",
		humanName = "Raven",
	},
	bomberdisarm = {
		category = "plane",
		order = 7,
		description = "Disarming Lightning Bomber",
		humanName = "Thunderbird",
	},
	bomberheavy = {
		category = "plane",
		order = 8,
		description = "Singularity Bomber",
		humanName = "Likho",
	},
	planelightscout = {
		category = "plane",
		order = 9,
		description = "Light Scout Plane",
		humanName = "Sparrow",
	},
	planescout = {
		category = "plane",
		order = 10,
		description = "Area Jammer, Radar/Sonar Plane",
		humanName = "Owl",
	},

	-- Ship
	factoryship = {
		category = "ship",
		order = 1,
		description = "Produces Naval Units, Builds at 10 m/s",
		humanName = "Shipyard",
	},
	shipcon = {
		category = "ship",
		order = 2,
		description = "Construction Ship, Builds at 7.5 m/s",
		humanName = "Mariner",
	},
	shipscout = {
		category = "ship",
		order = 3,
		description = "Picket Ship (Disarming Scout)",
		humanName = "Cutter",
	},
	shiptorpraider = {
		category = "ship",
		order = 4,
		description = "Torpedo-Boat (Raider)",
		humanName = "Hunter",
	},
	subraider = {
		category = "ship",
		order = 5,
		description = "Attack Submarine (Stealth Raider)",
		humanName = "Seawolf",
	},
	shipskirm = {
		category = "ship",
		order = 6,
		description = "Rocket Boat (Skirmisher)",
		humanName = "Mistral",
	},
	shipriot = {
		category = "ship",
		order = 7,
		description = "Corvette (Raider/Riot)",
		humanName = "Corsair",
	},
	shipassault = {
		category = "ship",
		order = 8,
		description = "Destroyer (Riot/Assault)",
		humanName = "Siren",
	},
	shiparty = {
		category = "ship",
		order = 9,
		description = "Cruiser (Artillery)",
		humanName = "Envoy",
	},
	shipaa = {
		category = "ship",
		order = 10,
		description = "Anti-Air Frigate",
		humanName = "Zephyr",
	},

	-- Strider
	striderhub = {
		category = "strider",
		order = 1,
		description = "Constructs Striders, Builds at 10 m/s",
		humanName = "Strider Hub",
	},
	athena = {
		category = "strider",
		order = 2,
		description = "Airborne SpecOps Engineer, Builds at 7.5 m/s",
		humanName = "Athena",
	},
	striderantiheavy = {
		category = "strider",
		order = 3,
		description = "Cloaked Anti-Heavy/Anti-Strider Walker",
		humanName = "Ultimatum",
	},
	striderscorpion = {
		category = "strider",
		order = 4,
		description = "Cloaked Infiltration Strider",
		humanName = "Scorpion",
	},
	striderdante = {
		category = "strider",
		order = 5,
		description = "Assault/Riot Strider",
		humanName = "Dante",
	},
	striderarty = {
		category = "strider",
		order = 6,
		description = "Heavy Saturation Artillery Strider",
		humanName = "Merlin",
	},
	striderfunnelweb = {
		category = "strider",
		order = 7,
		description = "Drone/Shield Support Strider",
		humanName = "Funnelweb",
	},
	striderbantha = {
		category = "strider",
		order = 8,
		description = "Ranged Support Strider",
		humanName = "Paladin",
	},
	striderdetriment = {
		category = "strider",
		order = 9,
		description = "Ultimate Assault Strider",
		humanName = "Detriment",
	},
	subtacmissile = {
		category = "strider",
		order = 10,
		description = "Tactical Nuke Missile Sub, Drains 20 m/s, 30 second stockpile",
		humanName = "Scylla",
	},
	shipcarrier = {
		category = "strider",
		order = 11,
		description = "Aircraft Carrier (Bombardment), Stockpiles tacnukes at 10 m/s",
		humanName = "Reef",
	},
	shipheavyarty = {
		category = "strider",
		order = 12,
		description = "Battleship (Heavy Artillery)",
		humanName = "Shogun",
	},

	-- Econ
	staticmex = {
		category = "econ",
		order = 1,
		description = "Produces Metal",
		humanName = "Metal Extractor",
	},
	energywind = {
		category = "econ",
		order = 2,
		description = "Small Powerplant",
		humanName = "Wind/Tidal Generator",
	},
	energysolar = {
		category = "econ",
		order = 3,
		description = "Small Powerplant (+2)",
		humanName = "Solar Collector",
	},
	energygeo = {
		category = "econ",
		order = 4,
		description = "Medium Powerplant (+25)",
		humanName = "Geothermal Generator",
	},
	energyfusion = {
		category = "econ",
		order = 5,
		description = "Medium Powerplant (+35)",
		humanName = "Fusion Reactor",
	},
	energyheavygeo = {
		category = "econ",
		order = 6,
		description = "Large Powerplant (+100) - HAZARDOUS",
		humanName = "Advanced Geothermal",
	},
	energysingu = {
		category = "econ",
		order = 7,
		description = "Large Powerplant (+225) - HAZARDOUS",
		humanName = "Singularity Reactor",
	},
	energypylon = {
		category = "econ",
		order = 8,
		description = "Extends overdrive grid",
		humanName = "Energy Pylon",
	},
	staticstorage = {
		category = "econ",
		order = 9,
		description = "Stores Metal and Energy (500)",
		humanName = "Storage",
	},
	staticcon = {
		category = "econ",
		order = 10,
		description = "Construction Assistant, Builds at 10 m/s",
		humanName = "Caretaker",
	},
	staticrearm = {
		category = "econ",
		order = 11,
		description = "Repairs and Rearms Aircraft, repairs at 2.5 e/s per pad",
		humanName = "Airpad",
	},

	-- Defence
	turretlaser = {
		category = "defence",
		order = 1,
		description = "Light Laser Tower",
		humanName = "Lotus",
	},
	turretmissile = {
		category = "defence",
		order = 2,
		description = "Light Missile Tower",
		humanName = "Picket",
	},
	turretriot = {
		category = "defence",
		order = 3,
		description = "Anti-Swarm Turret",
		humanName = "Stardust",
	},
	turretemp = {
		category = "defence",
		order = 4,
		description = "EMP Turret",
		humanName = "Faraday",
	},
	turretgauss = {
		category = "defence",
		order = 5,
		description = "Gauss Turret, 20 health/s when closed",
		humanName = "Gauss",
	},
	turretheavylaser = {
		category = "defence",
		order = 6,
		description = "High-Energy Laser Tower",
		humanName = "Stinger",
	},
	turretaalaser = {
		category = "defence",
		order = 7,
		description = "Hardened Anti-Air Laser",
		humanName = "Razor",
	},
	turretaaclose = {
		category = "defence",
		order = 8,
		description = "Burst Anti-Air Turret",
		humanName = "Hacksaw",
	},
	turretaaflak = {
		category = "defence",
		order = 9,
		description = "Anti-Air Flak Gun",
		humanName = "Thresher",
	},
	turretaafar = {
		category = "defence",
		order = 10,
		description = "Long-Range Anti-Air Missile Battery",
		humanName = "Chainsaw",
	},
	turretaaheavy = {
		category = "defence",
		order = 11,
		description = "Very Long-Range Anti-Air Missile Tower",
		humanName = "Artemis",
	},
	turretimpulse = {
		category = "defence",
		order = 12,
		description = "Gravity Turret",
		humanName = "Newton",
	},
	turrettorp = {
		category = "defence",
		order = 13,
		description = "Torpedo Launcher",
		humanName = "Urchin",
	},
	turretheavy = {
		category = "defence",
		order = 14,
		description = "Medium Range Defense Fortress - Requires connection to a 50 energy grid",
		humanName = "Desolator",
	},
	turretantiheavy = {
		category = "defence",
		order = 15,
		description = "Tachyon Projector - Requires connection to a 50 energy grid",
		humanName = "Lucifer",
	},
	staticshield = {
		category = "defence",
		order = 16,
		description = "Area Shield",
		humanName = "Aegis",
	},

	-- Special
	staticradar = {
		category = "special",
		order = 1,
		description = "Early Warning System",
		humanName = "Radar Tower",
	},
	staticjammer = {
		category = "special",
		order = 2,
		description = "Area Cloaker/Jammer",
		humanName = "Cornea",
	},
	staticheavyradar = {
		category = "special",
		order = 3,
		description = "Long-Range Radar",
		humanName = "Advanced Radar",
	},
	staticantinuke = {
		category = "special",
		order = 4,
		description = "Strategic Nuke Interception System",
		humanName = "Antinuke",
	},
	staticarty = {
		category = "special",
		order = 5,
		description = "Plasma Artillery Battery - Requires connection to a 50 energy grid",
		humanName = "Cerberus",
	},
	staticheavyarty = {
		category = "special",
		order = 6,
		description = "Strategic Plasma Cannon",
		humanName = "Big Bertha",
	},
	staticnuke = {
		category = "special",
		order = 7,
		description = "Strategic Nuclear Launcher, Drains 18 m/s, 3 minute stockpile",
		humanName = "Trinity",
	},
	zenith = {
		category = "special",
		order = 8,
		description = "Meteor Controller",
		humanName = "Zenith",
	},
	raveparty = {
		category = "special",
		order = 9,
		description = "Destructive Rainbow Projector",
		humanName = "Disco Rave Party",
	},
	mahlazer = {
		category = "special",
		order = 10,
		description = "Planetary Energy Chisel",
		humanName = "Starlight",
	},

	-- Missile Silo
	staticmissilesilo = {
		category = "missilesilo",
		order = 1,
		description = "Produces Tactical Missiles, Builds at 10 m/s",
		humanName = "Missile Silo",
	},
	tacnuke = {
		category = "missilesilo",
		order = 2,
		description = "Tactical Nuke",
		humanName = "Eos",
	},
	seismic = {
		category = "missilesilo",
		order = 2,
		description = "Seismic Missile",
		humanName = "Quake",
	},
	empmissile = {
		category = "missilesilo",
		order = 3,
		description = "EMP missile",
		humanName = "Shockley",
	},
	napalmmissile = {
		category = "missilesilo",
		order = 4,
		description = "Napalm Missile",
		humanName = "Inferno",
	},

	-- Drone
	wolverine_mine = {
		category = "drone",
		order = 1,
		description = "Badger Mine",
		humanName = "Claw",
	},
	dronelight = {
		category = "drone",
		order = 2,
		description = "Attack Drone",
		humanName = "Firefly",
	},
	droneheavyslow = {
		category = "drone",
		order = 3,
		description = "Advanced Battle Drone",
		humanName = "Viper",
	},
	dronecarry = {
		category = "drone",
		order = 4,
		description = "Carrier Drone",
		humanName = "Gull",
	},
}

--------- To Generate ------------
--[[
local inNameList = {}
local nameList = {}
local carrierDefs = VFS.Include("LuaRules/Configs/drone_defs.lua")
local function AddUnit(unitName)
	if inNameList[unitName] then
		return
	end
	inNameList[unitName] = true
	nameList[#nameList + 1] = unitName

	local ud = UnitDefNames[unitName]
	if ud.buildOptions then
		for i = 1, #ud.buildOptions do
			AddUnit(UnitDefs[ud.buildOptions[i] ].name)
		end
	end

	if ud.customParams.morphto then
		AddUnit(ud.customParams.morphto)
	end

	if ud.weapons then
		for i = 1, #ud.weapons do
			local wd = WeaponDefs[ud.weapons[i].weaponDef]
			if wd and wd.customParams and wd.customParams.spawns_name then
				AddUnit(wd.customParams.spawns_name)
			end
		end
	end

	if carrierDefs[ud.id] then
		local data = carrierDefs[ud.id]
		for i = 1, #data do
			local droneUnitDefID = data[i].drone
			if droneUnitDefID and UnitDefs[droneUnitDefID] then
				AddUnit(UnitDefs[droneUnitDefID].name)
			end
		end
	end
end

local function GenerateLists()
	AddUnit("cloakcon")
	local humanNames = {}
	for i = 1, #nameList do
		humanNames[nameList[i] ] = {
			humanName = UnitDefNames[nameList[i] ].humanName,
			description = UnitDefNames[nameList[i] ].tooltip,
		}
	end
	Spring.Echo(Spring.Utilities.TableToString(nameList, "nameList"))
	Spring.Echo(Spring.Utilities.TableToString(humanNames, "humanNames"))
end

GenerateLists()
--]]

local function UnitOrder(name1, name2)
	local data1 = name1 and humanNames[name1]
	local data2 = name1 and humanNames[name2]
	if not data1 then
		return (data2 and true)
	end
	if not data2 then
		return true
	end

	local category1 = categories[data1.category].order
	local category2 = categories[data2.category].order
	return category1 < category2 or (category1 == category2 and data1.order < data2.order)
end

return {
	nameList = nameList,
	humanNames = humanNames,
	categories = categories,
	UnitOrder = UnitOrder,
}
