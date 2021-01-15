--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Planet config

local function GetPlanet(planetUtilities, planetID)
	
	--local image = planetUtilities.planetImages[math.floor(math.random()*#planetUtilities.planetImages) + 1]
	local image = LUA_DIRNAME .. "images/planets/swamp02.png"
	
	local planetData = {
		name = "Vis Ragstrom",
		startingPlanet = false,
		mapDisplay = {
			x = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][1]) or 0.50,
			y = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][2]) or 0.49,
			image = image,
			size = planetUtilities.PLANET_SIZE_MAP,
		},
		infoDisplay = {
			image = image,
			size = planetUtilities.PLANET_SIZE_INFO,
			backgroundImage = planetUtilities.backgroundImages[math.floor(math.random()*#planetUtilities.backgroundImages) + 1],
			terrainType = "Terran",
			radius = "6070 km",
			primary = "Laria",
			primaryType = "G9V",
			milRating = 1,
			feedbackLink = "http://zero-k.info/Forum/Thread/24489",
			text = "There was a major military R&D complex here. Most of it is unusable by now, but there is a functional Strider Hub down there. If I can access it, it could be very useful."
			.. "\n "
			.. "\nSomething seems to have escaped its containment. I detect sporadic engagements between the local defense and whatever is hiding in the ground..."
			,
			extendedText = "I have captured a Strider Hub capable of building the heavy Dante riot strider. But with the restrictions of this place, I will need to extract an entire Dante to get the blueprint."
			.. "\n "
			.. "\nBetween the angry security systems and incoming waves of Chickens, getting one off the surface is going to be a challenge."
		},
		tips = {
			{
				image = "unitpics/striderdante.png",
				text = [[The Dante likes to get up close and personal so its heatrays can inflict maximum damage. Fire a large barrage of napalm rockets with manual fire (default hotkey D).]]
			},
			{
				image = "unitpics/chickens.png",
				text = [[The Chicken Hive has been thoroughly agitated, and it's sending out some nasty critters - get your business on this planet done as quickly as possible. Reclaim chicken eggs to build up quickly.]]
			},
			{
				image = "unitpics/guardian.png",
				text = [[The faction you stole the Strider Hub from is still pretty pissed as well. They're hard pressed by the chickens, but don't expect them to make your escape easy.]]
			},
		},
		gameConfig = {
			mapName = "Otago 1.4",
			modoptions = {
				graceperiod = 0.5, -- =30s, which is the minimum
				chicken_nominiqueen = 1,
				chicken_minaggro = 5,	-- aggro influences chicken tech-up rate (and queen time reduction from killing burrows, but queens are disabled here)
				chicken_maxaggro = 5,
				chicken_endless = 1,
				chicken_hidepanel = 1,
				chicken_nowavemessages = 1,
				campaign_chicken_types_special = {},
			},
			modoptionDifficulties = {
				[1] = {
					chickenspawnrate = 60,
					burrowspawnrate = 90,
					campaign_chicken_types_offense = {
						chicken				=  {time = -4,  squadSize = 5},
						chicken_pigeon		=  {time = 5,  squadSize = 1.4},
						chickens			=  {time = 1,  squadSize = 1.0}, --spiker
						chickena			=  {time = 3,  squadSize = 0.5}, --cockatrice
						chicken_sporeshooter=  {time = 5,  squadSize = 0.5},
						chicken_leaper	=  {time = 10,  squadSize = 0.8},
						chickenr			=  {time = 13,  squadSize = 1.2}, -- lobber
						chickenc			=  {time = 20,  squadSize = 0.5}, -- basilisk
						chicken_tiamat		=  {time = 25,  squadSize = 0.2},
					},
					campaign_chicken_types_defense = {
						chickend = {time = 4, squadSize = 0.6, cost = 1 },
						chicken_rafflesia =  {time = 8, squadSize = 0.4, cost = 2 },
					},
					campaign_chicken_types_support = {
						chicken_shield =  {time = 18, squadSize = 0.4},
						chicken_dodo = {time = 4, squadSize = 2},
						chicken_spidermonkey =  {time = 18, squadSize = 0.6},
					},
				},
				[2] = {
					chickenspawnrate = 50,
					burrowspawnrate = 70,
					campaign_chicken_types_offense = {
						chicken				=  {time = -4,  squadSize = 5},
						chicken_pigeon		=  {time = 5,  squadSize = 1.4},
						chickens			=  {time = 1,  squadSize = 1.0}, --spiker
						chickena			=  {time = 3,  squadSize = 0.5}, --cockatrice
						chicken_sporeshooter=  {time = 5,  squadSize = 0.5},
						chicken_leaper	=  {time = 10,  squadSize = 0.8},
						chickenr			=  {time = 11,  squadSize = 1.2}, -- lobber
						chickenc			=  {time = 15,  squadSize = 0.5}, -- basilisk
						chicken_tiamat		=  {time = 20,  squadSize = 0.2},
					},
					campaign_chicken_types_defense = {
						chickend = {time = 4, squadSize = 0.6, cost = 1 },
						chicken_rafflesia =  {time = 8, squadSize = 0.4, cost = 2 },
					},
					campaign_chicken_types_support = {
						chicken_shield =  {time = 16, squadSize = 0.4},
						chicken_dodo = {time = 4, squadSize = 2},
						chicken_spidermonkey =  {time = 16, squadSize = 0.6},
					},
				},
				[3] = {
					chickenspawnrate = 38,
					burrowspawnrate = 60,
					campaign_chicken_types_offense = {
						chicken				=  {time = -4,  squadSize = 6},
						chicken_pigeon		=  {time = 5,  squadSize = 1.4},
						chickens			=  {time = 1,  squadSize = 1.6}, --spiker
						chickena			=  {time = 3,  squadSize = 1.2}, --cockatrice
						chicken_sporeshooter=  {time = 5,  squadSize = 0.8},
						chicken_leaper	=  {time = 10,  squadSize = 0.8},
						chickenr			=  {time = 10,  squadSize = 1.2}, -- lobber
						chickenc			=  {time = 13,  squadSize = 0.5}, -- basilisk
						chicken_tiamat		=  {time = 16,  squadSize = 0.2},
					},
					campaign_chicken_types_defense = {
						chickend = {time = 4, squadSize = 0.6, cost = 1 },
						chicken_rafflesia =  {time = 8, squadSize = 0.4, cost = 2 },
					},
					campaign_chicken_types_support = {
						chicken_shield =  {time = 14, squadSize = 0.4},
						chicken_dodo = {time = 4, squadSize = 2},
						chicken_spidermonkey =  {time = 14, squadSize = 0.6},
					},
				},
				[4] = {
					chickenspawnrate = 30,
					burrowspawnrate = 40,
					campaign_chicken_types_offense = {
						chicken				=  {time = -4,  squadSize = 6},
						chicken_pigeon		=  {time = 5,  squadSize = 1.4},
						chickens			=  {time = 1,  squadSize = 1.6}, --spiker
						chickena			=  {time = 3,  squadSize = 1.2}, --cockatrice
						chicken_sporeshooter=  {time = 5,  squadSize = 0.8},
						chicken_leaper	=  {time = 10,  squadSize = 0.8},
						chickenr			=  {time = 9,  squadSize = 1.4}, -- lobber
						chickenc			=  {time = 11,  squadSize = 0.6}, -- basilisk
						chicken_tiamat		=  {time = 13,  squadSize = 0.2},
					},
					campaign_chicken_types_defense = {
						chickend = {time = 4, squadSize = 0.6, cost = 1 },
						chicken_rafflesia =  {time = 8, squadSize = 0.4, cost = 2 },
					},
					campaign_chicken_types_support = {
						chicken_shield =  {time = 12, squadSize = 0.4},
						chicken_dodo = {time = 4, squadSize = 2},
						chicken_spidermonkey =  {time = 12, squadSize = 0.6},
					},
				},
			},
			playerConfig = {
				startX = 1100,
				startZ = 4900,
				allyTeam = 0,
				commanderParameters = {
					facplop = true,
					defeatIfDestroyedObjectiveID = 2,
				},
				extraUnlocks = {
					"striderdante",
				},
				unitBlacklist = {
					striderhub = true, --you start with one that you should protect
				},
				typeVictoryAtLocation = {
					striderdante = {
						{
							x = 8256,
							z = 3680,
							radius = 400,
							objectiveID = 1,
						},
					}
				},
				startUnits = {
					{
						name = "shieldcon",
						x = 1000,
						z = 4700,
						facing = 0,
					},
					{
						name = "shieldcon",
						x = 1100,
						z = 4700,
						facing = 0,
					},
					{
						name = "shieldcon",
						x = 1200,
						z = 4700,
						facing = 0,
					},
					{
						name = "staticmex",
						x = 408,
						z = 4680,
						facing = 1,
					},
 					{
						name = "staticmex",
						x = 408,
						z = 4328,
						facing = 1,
					},
 					{
						name = "staticmex",
						x = 888,
						z = 5192,
						facing = 0,
					},
 					{
						name = "staticmex",
						x = 920,
						z = 5480,
						facing = 0,
					},
 					{
						name = "staticmex",
						x = 1624,
						z = 5944,
						facing = 0,
					},
 					{
						name = "staticmex",
						x = 1960,
						z = 5944,
						facing = 0,
					},
 					{
						name = "energysolar",
						x = 344,
						z = 4440,
						facing = 1,
					},
 					{
						name = "energysolar",
						x = 344,
						z = 4600,
						facing = 1,
					},
 					{
						name = "energysolar",
						x = 904,
						z = 5336,
						facing = 1,
					},
 					{
						name = "energysolar",
						x = 1848,
						z = 6008,
						facing = 1,
					},
 					{
						name = "energysolar",
						x = 1720,
						z = 6008,
						facing = 1,
					},
 					{
						name = "energygeo",
						x = 56,
						z = 5944,
						facing = 0,
					},
 					{
						name = "energypylon",
						x = 616,
						z = 5688,
						facing = 0,
					},
 					{
						name = "energypylon",
						x = 1352,
						z = 5864,
						facing = 0,
					},
 					{
						name = "energypylon",
						x = 504,
						z = 4984,
						facing = 0,
					},
 					{
						name = "staticradar",
						x = 2224,
						z = 4480,
						facing = 0,
					},
 					{
						name = "striderhub",
						x = 1408,
						z = 4912,
						facing = 0,
						commands = {
							{cmdID = planetUtilities.COMMAND.PATROL, pos = {1408, 4923}},
							{cmdID = planetUtilities.COMMAND.PATROL, pos = {1433, 4898}, options = {"shift"}},
						},
					},
 					{
						name = "striderdante",
						x = 1403,
						z = 5089,
						facing = 0,
					},
 					{
						name = "turretlaser",
						x = 2336,
						z = 4416,
						facing = 1,
					},
 					{
						name = "turretlaser",
						x = 2288,
						z = 4768,
						facing = 1,
					},
 					{
						name = "turretlaser",
						x = 2000,
						z = 4416,
						facing = 2,
					},
 					{
						name = "turretlaser",
						x = 1376,
						z = 3648,
						facing = 2,
					},
 					{
						name = "turretlaser",
						x = 384,
						z = 3184,
						facing = 2,
					},
 					{
						name = "staticradar",
						x = 192,
						z = 2992,
						facing = 2,
					},
 					{
						name = "turretriot",
						x = 888,
						z = 3480,
						facing = 2,
					},
 					{
						name = "turretriot",
						x = 1496,
						z = 4152,
						facing = 2,
					},
 					{
						name = "turretriot",
						x = 2552,
						z = 5224,
						facing = 2,
					},
 					{
						name = "turretriot",
						x = 2872,
						z = 5608,
						facing = 2,
					},
 					{
						name = "turretlaser",
						x = 3168,
						z = 5888,
						facing = 1,
					},
 					{
						name = "turretaalaser",
						x = 2168,
						z = 5352,
						facing = 0,
					},
 					{
						name = "turretaalaser",
						x = 600,
						z = 4120,
						facing = 0,
					},
				}
			},
			aiConfig = {
				{
					startX = 6500,
					startZ = 3000,
					humanName = "Hastur3",
					aiLib = "Circuit_difficulty_autofill",
					bitDependant = true,
					--aiLib = "Null AI",
					--bitDependant = false,
					commanderParameters = {
						facplop = false,
					},
					allyTeam = 1,
					unlocks = {
						"staticmex",
						"energysolar",
						"energywind",
						"energygeo",
						"staticcon",
						"staticradar",
						--"turretheavylaser", a bit too good against Dante
						"turretriot",
						"turretaaclose",
						"turretaalaser",
						"factoryshield",
						"shieldcon",
						"shieldraid",
						"shieldriot",
						"shieldassault",
						"shieldskirm",
						"factoryspider",
						"spidercon",
						"spiderscout",
						"spideremp",
						"spiderriot",
						"spiderskirm",
						"spiderassault",
						"factoryveh",
						"vehraid",
						"vehriot",
						"vehsupport",
						"vehassault",
					},
					difficultyDependantUnlocks = {
						[3] = {"turretmissile"},
						[4] = {"spiderantiheavy","turretmissile","turretlaser"},
					},
					commanderLevel = 4,
					commander = {
						name = "Firekeeper",
						chassis = "guardian",
						decorations = {
						},
						modules = {
							"weaponmod_napalm_warhead",
							"commweapon_riotcannon",
							"commweapon_rocketlauncher",
							"module_ablative_armor",
							"module_ablative_armor",
							"module_autorepair",
							"module_autorepair",
							"module_high_power_servos",
							"module_high_power_servos",
						}
					},
					startUnits = {
 						{
							name = "staticmex",
							x = 6936,
							z = 5848,
							facing = 0,
						},
 						{
							name = "staticmex",
							x = 4312,
							z = 4984,
							facing = 0,
						},
 						{
							name = "staticmex",
							x = 6696,
							z = 3656,
							facing = 0,
						},
 						{
							name = "staticmex",
							x = 5976,
							z = 4104,
							facing = 0,
						},
 						{
							name = "staticmex",
							x = 4856,
							z = 4984,
							facing = 0,
						},
 						{
							name = "staticmex",
							x = 4952,
							z = 3704,
							facing = 0,
						},
 						{
							name = "staticmex",
							x = 7704,
							z = 2648,
							facing = 0,
						},
 						{
							name = "staticmex",
							x = 8824,
							z = 1848,
							facing = 0,
						},
 						{
							name = "staticmex",
							x = 8808,
							z = 1416,
							facing = 0,
						},
 						{
							name = "staticmex",
							x = 8808,
							z = 4696,
							facing = 0,
						},
 						{
							name = "staticmex",
							x = 8424,
							z = 4152,
							facing = 0,
						},
 						{
							name = "energygeo",
							x = 5704,
							z = 5224,
							facing = 0,
						},
 						{
							name = "energygeo",
							x = 7240,
							z = 4120,
							facing = 0,
						},
 						{
							name = "energyfusion",
							x = 7320,
							z = 5920,
							facing = 0,
						},
 						{
							name = "energyfusion",
							x = 8856,
							z = 5056,
							facing = 0,
						},
 						{
							name = "energypylon",
							x = 8600,
							z = 4680,
							facing = 0,
						},
 						{
							name = "energypylon",
							x = 7864,
							z = 4152,
							facing = 0,
						},
 						{
							name = "energypylon",
							x = 5992,
							z = 4664,
							facing = 0,
						},
 						{
							name = "energypylon",
							x = 6664,
							z = 4040,
							facing = 0,
						},
 						{
							name = "energypylon",
							x = 6632,
							z = 5416,
							facing = 0,
						},
 						{
							name = "energysolar",
							x = 6040,
							z = 4120,
							facing = 0,
						},
 						{
							name = "energysolar",
							x = 5960,
							z = 4168,
							facing = 3,
						},
 						{
							name = "energysolar",
							x = 5912,
							z = 4088,
							facing = 2,
						},
 						{
							name = "energysolar",
							x = 5992,
							z = 4040,
							facing = 1,
						},
 						{
							name = "energysolar",
							x = 8488,
							z = 4168,
							facing = 0,
						},
 						{
							name = "energysolar",
							x = 8408,
							z = 4216,
							facing = 3,
						},
 						{
							name = "energysolar",
							x = 8440,
							z = 4088,
							facing = 1,
						},
 						{
							name = "energysolar",
							x = 6760,
							z = 3672,
							facing = 0,
						},
 						{
							name = "energysolar",
							x = 6680,
							z = 3720,
							facing = 3,
						},
 						{
							name = "energysolar",
							x = 6632,
							z = 3640,
							facing = 2,
						},
 						{
							name = "energysolar",
							x = 6712,
							z = 3592,
							facing = 1,
						},
 						{
							name = "energysolar",
							x = 7000,
							z = 5864,
							facing = 0,
						},
 						{
							name = "energysolar",
							x = 6920,
							z = 5912,
							facing = 3,
						},
 						{
							name = "energysolar",
							x = 6872,
							z = 5832,
							facing = 2,
						},
 						{
							name = "energysolar",
							x = 6952,
							z = 5784,
							facing = 1,
						},
 						{
							name = "factoryshield",
							x = 5000,
							z = 4616,
							facing = 2,
						},
 						{
							name = "staticcon",
							x = 5000,
							z = 4744,
							facing = 2,
							commands = {
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {8264, 4744}},
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {8239, 4719}, options = {"shift"}},
							},
						},
 						{
							name = "staticcon",
							x = 6536,
							z = 5224,
							facing = 2,
							commands = {
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {6536, 5224}},
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {6511, 5199}, options = {"shift"}},
							},
						},
 						{
							name = "factoryveh",
							x = 6536,
							z = 5096,
							facing = 2,
						},
 						{
							name = "turretlaser",
							x = 8768,
							z = 5152,
							facing = 3,
						},
 						{
							name = "turretlaser",
							x = 8944,
							z = 4976,
							facing = 2,
						},
 						{
							name = "factoryspider",
							x = 8072,
							z = 5656,
							facing = 2,
						},
 						{
							name = "staticcon",
							x = 8072,
							z = 5768,
							facing = 2,
							commands = {
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {8072, 5768}},
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {8047, 5743}, options = {"shift"}},
							},
						},
 						{
							name = "turretheavylaser",
							x = 8072,
							z = 3848,
							facing = 3,
						},
 						{
							name = "turretheavylaser",
							x = 8472,
							z = 3528,
							facing = 1,
						},
 						{
							name = "turretemp",
							x = 8072,
							z = 3544,
							facing = 2,
						},
 						{
							name = "turretemp",
							x = 8472,
							z = 3848,
							facing = 0,
						},
 						{
							name = "turretaalaser",
							x = 8264,
							z = 3416,
							facing = 3,
						},
 						{
							name = "energysolar",
							x = 6456,
							z = 5208,
							facing = 3,
						},
 						{
							name = "energysolar",
							x = 6472,
							z = 5288,
							facing = 3,
						},
 						{
							name = "energysolar",
							x = 6552,
							z = 5288,
							facing = 3,
						},
 						{
							name = "turretaalaser",
							x = 8248,
							z = 3976,
							facing = 3,
						},
 						{
							name = "energysolar",
							x = 6600,
							z = 5208,
							facing = 3,
						},
 						{
							name = "turretlaser",
							x = 6512,
							z = 5184,
							facing = 3,
						},
 						{
							name = "staticradar",
							x = 5968,
							z = 5616,
							facing = 3,
						},
 						{
							name = "turretaaclose",
							x = 5896,
							z = 5784,
							facing = 3,
						},
 						{
							name = "turretheavylaser",
							x = 5816,
							z = 5944,
							facing = 3,
						},
 						{
							name = "turretriot",
							x = 5672,
							z = 5368,
							facing = 3,
						},
 						{
							name = "turretlaser",
							x = 5808,
							z = 5072,
							facing = 3,
						},
 						{
							name = "turretheavylaser",
							x = 5816,
							z = 4664,
							facing = 3,
						},
 						{
							name = "turretmissile",
							x = 5696,
							z = 4864,
							facing = 3,
						},
 						{
							name = "turretmissile",
							x = 5872,
							z = 4384,
							facing = 3,
						},
 						{
							name = "energysolar",
							x = 4920,
							z = 5000,
							facing = 2,
						},
 						{
							name = "spideremp",
							x = 7995,
							z = 5383,
							facing = 3,
						},
 						{
							name = "energysolar",
							x = 4840,
							z = 5048,
							facing = 1,
						},
 						{
							name = "energysolar",
							x = 4792,
							z = 4968,
							facing = 0,
						},
 						{
							name = "energysolar",
							x = 4872,
							z = 4920,
							facing = 3,
						},
 						{
							name = "energysolar",
							x = 7128,
							z = 5880,
							facing = 3,
						},
 						{
							name = "energysolar",
							x = 4376,
							z = 5000,
							facing = 2,
						},
 						{
							name = "energysolar",
							x = 4296,
							z = 5048,
							facing = 1,
						},
 						{
							name = "energysolar",
							x = 4328,
							z = 4920,
							facing = 3,
						},
 						{
							name = "turretheavylaser",
							x = 7096,
							z = 3128,
							facing = 2,
						},
 						{
							name = "turretheavylaser",
							x = 7880,
							z = 2520,
							facing = 2,
						},
 						{
							name = "turretaaclose",
							x = 7432,
							z = 5016,
							facing = 1,
						},
 						{
							name = "turretaaclose",
							x = 7256,
							z = 4312,
							facing = 1,
						},
 						{
							name = "turretlaser",
							x = 7104,
							z = 4192,
							facing = 3,
						},
 						{
							name = "turretlaser",
							x = 7200,
							z = 3936,
							facing = 2,
						},
 						{
							name = "turretriot",
							x = 7400,
							z = 2712,
							facing = 2,
						},
 						{
							name = "turretlaser",
							x = 7376,
							z = 4128,
							facing = 1,
						},
 						{
							name = "turretmissile",
							x = 7248,
							z = 2880,
							facing = 2,
						},
 						{
							name = "turretmissile",
							x = 7376,
							z = 2848,
							facing = 2,
						},
 						{
							name = "turretmissile",
							x = 7520,
							z = 2784,
							facing = 2,
						},
 						{
							name = "turretmissile",
							x = 7584,
							z = 2640,
							facing = 2,
						},
 						{
							name = "turretemp",
							x = 8440,
							z = 2344,
							facing = 2,
						},
 						{
							name = "turretmissile",
							x = 8256,
							z = 2464,
							facing = 2,
						},
 						{
							name = "turretmissile",
							x = 8432,
							z = 2512,
							facing = 2,
						},
 						{
							name = "turretmissile",
							x = 8608,
							z = 2432,
							facing = 2,
						},
 						{
							name = "staticradar",
							x = 4464,
							z = 4608,
							facing = 2,
						},
 						{
							name = "turretriot",
							x = 5800,
							z = 3064,
							facing = 2,
						},
 						{
							name = "turretlaser",
							x = 3984,
							z = 4992,
							facing = 3,
						},
 						{
							name = "turretlaser",
							x = 3984,
							z = 4608,
							facing = 3,
						},
 						{
							name = "turretriot",
							x = 4024,
							z = 4792,
							facing = 3,
						},
 						{
							name = "staticmex",
							x = 3832,
							z = 3912,
							facing = 3,
						},
 						{
							name = "turretlaser",
							x = 3632,
							z = 4048,
							facing = 3,
						},
 						{
							name = "turretlaser",
							x = 3840,
							z = 3696,
							facing = 2,
						},
 						{
							name = "turretheavylaser",
							x = 5432,
							z = 3256,
							facing = 2,
						},
 						{
							name = "turretlaser",
							x = 5312,
							z = 3264,
							facing = 2,
						},
 						{
							name = "turretlaser",
							x = 5520,
							z = 3136,
							facing = 2,
						},
 						{
							name = "turretheavylaser",
							x = 6264,
							z = 3032,
							facing = 2,
						},
 						{
							name = "turretlaser",
							x = 8560,
							z = 1728,
							facing = 3,
						},
 						{
							name = "turretlaser",
							x = 8640,
							z = 1456,
							facing = 3,
						},
 						{
							name = "turretlaser",
							x = 8720,
							z = 1216,
							facing = 3,
						},
 						{
							name = "turretmissile",
							x = 8672,
							z = 1616,
							facing = 3,
						},
 						{
							name = "turretmissile",
							x = 8736,
							z = 1328,
							facing = 3,
						},
 						{
							name = "turretemp",
							x = 4136,
							z = 3592,
							facing = 2,
						},
 						{
							name = "turretriot",
							x = 4728,
							z = 3432,
							facing = 2,
						},
 						{
							name = "turretmissile",
							x = 4864,
							z = 3440,
							facing = 2,
						},
 						{
							name = "turretmissile",
							x = 4592,
							z = 3536,
							facing = 2,
						},
 						{
							name = "turretmissile",
							x = 4288,
							z = 3600,
							facing = 2,
						},
 						{
							name = "turretmissile",
							x = 4032,
							z = 3696,
							facing = 2,
						},
 						{
							name = "turretaalaser",
							x = 5912,
							z = 3352,
							facing = 2,
						},
 						{
							name = "turretaalaser",
							x = 4456,
							z = 3752,
							facing = 2,
						},
 						{
							name = "turretriot",
							x = 6696,
							z = 2952,
							facing = 2,
						},
 						{
							name = "turretmissile",
							x = 6128,
							z = 3168,
							facing = 2,
						},
 						{
							name = "turretmissile",
							x = 6368,
							z = 3136,
							facing = 2,
						},
 						{
							name = "turretmissile",
							x = 6592,
							z = 3104,
							facing = 2,
						},
 						{
							name = "turretmissile",
							x = 6816,
							z = 3056,
							facing = 2,
						},
 						{
							name = "turretmissile",
							x = 7536,
							z = 3632,
							facing = 3,
						},
 						{
							name = "turretmissile",
							x = 7632,
							z = 3360,
							facing = 3,
						},
 						{
							name = "turretmissile",
							x = 5040,
							z = 4352,
							facing = 3,
						},
 						{
							name = "turretmissile",
							x = 5072,
							z = 4592,
							facing = 3,
						},
 						{
							name = "turretmissile",
							x = 7728,
							z = 3104,
							facing = 3,
							terraformHeight = 8,
						},
 						{
							name = "turretmissile",
							x = 5056,
							z = 5024,
							facing = 3,
						},
 						{
							name = "turretmissile",
							x = 4784,
							z = 5360,
							facing = 3,
						},
 						{
							name = "turretmissile",
							x = 4544,
							z = 5616,
							facing = 3,
						},
 						{
							name = "turretmissile",
							x = 4480,
							z = 5824,
							facing = 3,
						},
 						{
							name = "turretemp",
							x = 5656,
							z = 3848,
							facing = 3,
						},
 						{
							name = "turretriot",
							x = 6440,
							z = 4408,
							facing = 3,
						},
					}
				},
				{
					humanName = "Chickens",
					aiLib = "Chicken: Custom",
					bitDependant = false,
					--aiLib = "Null AI",
					--bitDependant = false,
					commanderParameters = {
						facplop = false,
					},
					allyTeam = 2,
					unlocks = {
					},
					commander = false,
					midgameUnits = {
						{
							name = "chicken_dragon",
							x = 7650,
							z = 300,
							facing = 0,
							spawnRadius = 100,
							delay = 14*30*60,
							orbitalDrop = true,
							difficultyAtLeast = 4,
						},
					},
					startUnits = {
						{
							name = "roost",
							x = 4280,
							z = 600,
							facing = 0,
						},
 						{
							name = "roost",
							x = 4792,
							z = 520,
							facing = 0,
						},
 						{
							name = "roost",
							x = 2600,
							z = 824,
							facing = 0,
						},
 						{
							name = "roost",
							x = 2344,
							z = 488,
							facing = 0,
						},
 						{
							name = "roost",
							x = 4520,
							z = 280,
							facing = 0,
						},
 						{
							name = "roost",
							x = 6392,
							z = 248,
							facing = 0,
						},
 						{
							name = "roost",
							x = 376,
							z = 984,
							facing = 0,
						},
 						{
							name = "roost",
							x = 5624,
							z = 1112,
							facing = 0,
						},
 						{
							name = "roost",
							x = 6792,
							z = 360,
							facing = 0,
						},
 						{
							name = "chickend",
							x = 6296,
							z = 664,
							facing = 0,
						},
 						{
							name = "chickend",
							x = 6600,
							z = 648,
							facing = 0,
						},
 						{
							name = "chickend",
							x = 6984,
							z = 520,
							facing = 0,
						},
 						{
							name = "chickend",
							x = 7096,
							z = 360,
							facing = 0,
						},
 						{
							name = "chickend",
							x = 6376,
							z = 456,
							facing = 0,
						},
 						{
							name = "chickend",
							x = 6808,
							z = 216,
							facing = 0,
						},
 						{
							name = "chickend",
							x = 4216,
							z = 824,
							facing = 0,
						},
 						{
							name = "chickend",
							x = 4456,
							z = 664,
							facing = 0,
						},
 						{
							name = "chickend",
							x = 4984,
							z = 712,
							facing = 0,
						},
 						{
							name = "chickend",
							x = 4824,
							z = 264,
							facing = 0,
						},
 						{
							name = "chickend",
							x = 4728,
							z = 728,
							facing = 0,
						},
 						{
							name = "chickend",
							x = 3928,
							z = 1576,
							facing = 0,
						},
 						{
							name = "chickend",
							x = 4552,
							z = 1432,
							facing = 0,
						},
 						{
							name = "chickend",
							x = 5432,
							z = 1336,
							facing = 0,
						},
 						{
							name = "chickend",
							x = 5688,
							z = 1336,
							facing = 0,
						},
 						{
							name = "chickend",
							x = 2520,
							z = 1176,
							facing = 0,
						},
 						{
							name = "chickend",
							x = 2664,
							z = 1160,
							facing = 0,
						},
 						{
							name = "chickend",
							x = 232,
							z = 1496,
							facing = 0,
						},
 						{
							name = "chickend",
							x = 696,
							z = 1320,
							facing = 0,
						},
 						{
							name = "chickend",
							x = 2760,
							z = 696,
							facing = 0,
						},
 						{
							name = "chickend",
							x = 1976,
							z = 248,
							facing = 0,
						},
					}
				},
			},
			neutralUnits = {
				{
					name = "pw_dropfac",
					x = 8256,
					z = 3680,
					facing = 0,
					invincible = true,
					ignoredByAI = true,
					mapMarker = {
						text = "Dropship Factory",
						color = "green_small"
					},
				},
			},
			defeatConditionConfig = {
				-- Indexed by allyTeam.
				[0] = {
					ignoreUnitLossDefeat = false,
					vitalCommanders = false,
					vitalUnitTypes = {
						"striderhub",
						"striderdante",
					},
					loseAfterSeconds = false,
					allyTeamLossObjectiveID = 3,
				},
				[1] = {
					ignoreUnitLossDefeat = false,
					loseAfterSeconds = false,
				},
				[2] = {
					ignoreUnitLossDefeat = true,
					doNotExplodeOnLoss = true, -- It would look a bit weird for the chickens to explode when the robots lose.
				},
			},
			objectiveConfig = {
				-- This is just related to displaying objectives on the UI.
				[1] = {
					description = "Bring a Dante to the Dropship Factory",
				},
				[2] = {
					description = "Protect your Commander",
				},
				[3] = {
					description = "Do not lose your Strider Hub and all Dantes",
				},
			},
			bonusObjectiveConfig = {
				[1] = { -- Protect the Strider Hub
					satisfyForever = true,
					failOnUnitLoss = true, -- Fails the objective if any units being used to satisfy the objective are lost.
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 0,
					unitTypes = {
						"striderhub",
					},
					image = planetUtilities.ICON_DIR .. "striderhub.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.GUARD,
					description = "Don't lose the Strider Hub",
					experience = planetUtilities.BONUS_EXP,
				},
				[2] = { -- Make the enemy lose seven roosts
					onlyCountRemovedUnits = true,
					satisfyOnce = true,
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 7,
					enemyUnitTypes = {
						"roost",
					},
					image = planetUtilities.ICON_DIR .. "roost.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.ATTACK,
					description = "Destroy 7 Chicken Roosts",
					experience = planetUtilities.BONUS_EXP,
				},
				[3] = { -- Lose no more than 1 dante
					onlyCountRemovedUnits = true,
					satisfyForever = true,
					comparisionType = planetUtilities.COMPARE.AT_MOST,
					targetNumber = 1,
					unitTypes = {
						"striderdante"
					},
					image = planetUtilities.ICON_DIR .. "striderdante.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.GUARD,
					description = "Do not lose more than 1 Dante",
					experience = planetUtilities.BONUS_EXP,
				},
			}
		},
		completionReward = {
			experience = planetUtilities.MAIN_EXP,
			units = {
				"striderhub",
				"striderdante",
			},
			modules = {
				"weaponmod_napalm_warhead",
			},
			abilities = {
			},
			codexEntries = {
				"threat_chickens",
				"threat_chickens_travel"
			}
		},
	}
	
	return planetData
end

return GetPlanet
