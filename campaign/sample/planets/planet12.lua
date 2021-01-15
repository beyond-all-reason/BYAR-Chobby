--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Planet config

local function GetPlanet(planetUtilities, planetID)
	
	--local image = planetUtilities.planetImages[math.floor(math.random()*#planetUtilities.planetImages) + 1]
	local image = LUA_DIRNAME .. "images/planets/inferno04.png"
	
	local planetData = {
		name = "Ganong",
		startingPlanet = false,
		mapDisplay = {
			x = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][1]) or 0.24,
			y = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][2]) or 0.22,
			image = image,
			size = planetUtilities.PLANET_SIZE_MAP,
		},
		infoDisplay = {
			image = image,
			size = planetUtilities.PLANET_SIZE_INFO,
			backgroundImage = planetUtilities.backgroundImages[math.floor(math.random()*#planetUtilities.backgroundImages) + 1],
			terrainType = "Rock",
			radius = "540 km",
			primary = "Purlie",
			primaryType = "G8V",
			milRating = 1,
			feedbackLink = "http://zero-k.info/Forum/Thread/24457",
			text = "This rich industrial world is quite well-defended, but a dormant saboteur unit recognized my IFF and signaled me. I should be able to subvert those defenses with its help."
			.. "\n "
			.. "\nAs far as I can tell, it identified me as allied to the rebels against whoever was the Empire controlling this world."
			,
			extendedText = "Hostile forces are well entrenched but, luckily for me, they have a poorly defended outpost and I now have a squad of Dominatrices. Capturing the outpost will give me a head start, then I can steal an army of Tanks and march on their main base."
		},
		tips = {
			{
				image = "unitpics/vehcapture.png",
				text = [[The Dominatrix hacks into enemy units to turn them to your side. Multiple Dominatrices increases the rate of capture and the Dominatrix that dealt the final blow will need several seconds to reload. If a Dominatrix is destroyed then all units controlled by that Dominatrix revert to their original side.]]
			},
			{
				image = "unitpics/tankriot.png",
				text = [[Dominatrices take 12 seconds to recharge after capturing a unit, making them particularly suited to fighting high cost - short range - units.]]
			},
			{
				image = "unitpics/factorytank.png",
				text = [[Dominatrices can capture everything. Capture an enemy factory to use their technology (in addition to your own).]]
			},
		},
		gameConfig = {
			mapName = "Red Comet v1.3",
			playerConfig = {
				startX = 730,
				startZ = 3700,
				allyTeam = 0,
				commanderParameters = {
					facing = 2,
					facplop = false,
					defeatIfDestroyedObjectiveID = 2,
				},
				extraUnlocks = {
					"factoryveh",
					"vehcon",
					"vehcapture",
				},
				startUnits = {
					{
						name = "staticradar",
						x = 1296,
						z = 3072,
						facing = 1,
					},
					{
						name = "vehcapture",
						x = 550,
						z = 3800,
						facing = 2,
						commands = {
							{cmdID = planetUtilities.COMMAND.RAW_MOVE, pos = {550, 3550},}
						},
					},
					{
						name = "vehcapture",
						x = 595,
						z = 3850,
						facing = 2,
						commands = {
							{cmdID = planetUtilities.COMMAND.RAW_MOVE, pos = {595, 3600},}
						},
					},
					{
						name = "vehcapture",
						x = 640,
						z = 3800,
						facing = 2,
						commands = {
							{cmdID = planetUtilities.COMMAND.RAW_MOVE, pos = {640, 3550},}
						},
					},
					{
						name = "vehcapture",
						x = 820,
						z = 3800,
						facing = 2,
						commands = {
							{cmdID = planetUtilities.COMMAND.RAW_MOVE, pos = {820, 3550},}
						},
					},
					{
						name = "vehcapture",
						x = 865,
						z = 3850,
						facing = 2,
						commands = {
							{cmdID = planetUtilities.COMMAND.RAW_MOVE, pos = {865, 3600},}
						},
					},
					{
						name = "vehcapture",
						x = 910,
						z = 3800,
						facing = 2,
						commands = {
							{cmdID = planetUtilities.COMMAND.RAW_MOVE, pos = {910, 3550},}
						},
					},
				}
			},
			aiConfig = {
				{
					startX = 5700,
					startZ = 1060,
					--aiLib = "Null AI",
					--bitDependant = false,
					aiLib = "Circuit_difficulty_autofill",
					bitDependant = true,
					humanName = "Benefactor",
					commanderParameters = {
						facplop = false,
					},
					allyTeam = 1,
					unlocks = {
						"staticmex",
						"energysolar",
						"staticradar",
						"staticstorage",
						"tankheavyraid",
						"turretriot",
						"tankriot",
						"turretlaser",
						"turretmissile",
						"vehassault",
					},
					difficultyDependantUnlocks = {
						[2] = {"staticcon"},
						[3] = {"staticcon"},
						[4] = {"staticcon", "turretheavylaser"},
					},
					commanderLevel = 2,
					commander = {
						name = "Schmuck",
						chassis = "engineer",
						decorations = {
						},
						modules = {
							"commweapon_lparticlebeam",
							"module_radarnet",
							"module_ablative_armor",
							"module_autorepair",
						}
					},
					midgameUnits = {
						-- Welders every 20 seconds because Circuit cannot be trusted to make them
						{
							name = "tankcon",
							x = 6018,
							z = 219,
							facing = 0,
							spawnRadius = 50,
							delay = 45*30,
							repeatDelay = 30*30,
							orbitalDrop = true,
						},
					},
					startUnits = {
						{
							name = "tankcon",
							x = 6018,
							z = 219,
							facing = 2,
							difficultyAtLeast = 2,
						},
						{
							name = "energywind",
							x = 5432,
							z = 2984,
							facing = 0,
						},
						{
							name = "energywind",
							x = 5416,
							z = 2824,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 5960,
							z = 3000,
							facing = 0,
							difficultyAtLeast = 2,
						},
						{
							name = "staticmex",
							x = 5880,
							z = 1192,
							facing = 0,
							difficultyAtLeast = 2,
						},
						{
							name = "energysolar",
							x = 2648,
							z = 808,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 5192,
							z = 632,
							facing = 0,
						},
						{
							name = "energywind",
							x = 5416,
							z = 2904,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 3784,
							z = 952,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 3736,
							z = 744,
							facing = 0,
						},
						{
							name = "factoryveh",
							x = 704,
							z = 2704,
							facing = 1,
						},
						{
							name = "staticmex",
							x = 280,
							z = 2904,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 600,
							z = 3208,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 296,
							z = 2968,
							facing = 1,
						},
						{
							name = "staticmex",
							x = 520,
							z = 1832,
							facing = 0,
						},
						{
							name = "vehcon",
							x = 644,
							z = 2465,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 728,
							z = 2104,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 584,
							z = 1816,
							facing = 1,
						},
						{
							name = "energysolar",
							x = 1880,
							z = 2888,
							facing = 1,
						},
						{
							name = "turretlaser",
							x = 352,
							z = 2800,
							difficultyAtLeast = 2,
							facing = 1,
						},
						{
							name = "energysolar",
							x = 264,
							z = 2840,
							facing = 1,
						},
						{
							name = "turretlaser",
							x = 1840,
							z = 2960,
							facing = 1,
							difficultyAtLeast = 3,
						},
						{
							name = "staticmex",
							x = 1784,
							z = 2904,
							facing = 0,
						},
						{
							name = "turretlaser",
							x = 816,
							z = 2096,
							facing = 0,
							difficultyAtLeast = 2,
						},
						{
							name = "staticradar",
							x = 528,
							z = 2496,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 872,
							z = 2120,
							facing = 3,
						},
						{
							name = "energysolar",
							x = 792,
							z = 2152,
							facing = 2,
						},
						{
							name = "energysolar",
							x = 840,
							z = 2040,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 760,
							z = 2040,
							facing = 0,
						},
						{
							name = "staticradar",
							x = 3680,
							z = 3376,
							facing = 0,
						},
						{
							name = "turretlaser",
							x = 4976,
							z = 2544,
							facing = 3,
						},
						{
							name = "staticmex",
							x = 5640,
							z = 2280,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 5544,
							z = 904,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 5416,
							z = 1992,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 4376,
							z = 1192,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 2424,
							z = 312,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 2936,
							z = 1208,
							facing = 0,
						},
						{
							name = "turretlaser",
							x = 2688,
							z = 736,
							facing = 0,
						},
						{
							name = "turretlaser",
							x = 1904,
							z = 1088,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 1848,
							z = 168,
							facing = 0,
						},
						{
							name = "turretlaser",
							x = 1904,
							z = 96,
							facing = 0,
						},
						{
							name = "turretlaser",
							x = 2928,
							z = 1680,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 2616,
							z = 680,
							facing = 0,
						},
						{
							name = "staticradar",
							x = 3968,
							z = 1424,
							facing = 0,
						},
						{
							name = "energywind",
							x = 3960,
							z = 1720,
							facing = 0,
						},
						{
							name = "energywind",
							x = 3896,
							z = 1752,
							facing = 0,
						},
						{
							name = "energywind",
							x = 3816,
							z = 1752,
							facing = 0,
						},
						{
							name = "energywind",
							x = 3752,
							z = 1736,
							facing = 0,
						},
						{
							name = "energywind",
							x = 4024,
							z = 1560,
							facing = 0,
						},
						{
							name = "energywind",
							x = 3960,
							z = 1608,
							facing = 0,
						},
						{
							name = "energywind",
							x = 3896,
							z = 1416,
							facing = 0,
						},
						{
							name = "turretriot",
							x = 5816,
							z = 3032,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 6008,
							z = 3064,
							facing = 0,
						},
						{
							name = "turretemp",
							x = 5344,
							z = 2624,
							facing = 0,
						},
						{
							name = "energywind",
							x = 5400,
							z = 2744,
							facing = 0,
						},
						{
							name = "turretlaser",
							x = 2224,
							z = 1568,
							facing = 0,
							difficultyAtLeast = 3,
						},
						{
							name = "energysolar",
							x = 2968,
							z = 1592,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 1832,
							z = 104,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 1816,
							z = 40,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 2904,
							z = 1608,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 2840,
							z = 1624,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 2632,
							z = 744,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 1960,
							z = 1096,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 2216,
							z = 1496,
							facing = 0,
						},
						{
							name = "tankraid",
							x = 6127,
							z = 426,
							facing = 2,
							difficultyAtLeast = 2,
						},
						{
							name = "energysolar",
							x = 1944,
							z = 1160,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 1976,
							z = 1032,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 2152,
							z = 1512,
							facing = 0,
						},
						{
							name = "energyfusion",
							x = 5512,
							z = 2128,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 5352,
							z = 2008,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 5400,
							z = 1928,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 5656,
							z = 2344,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 5704,
							z = 2264,
							facing = 0,
						},
						{
							name = "turretgauss",
							x = 5768,
							z = 2904,
							facing = 0,
							terraformHeight = 259,
						},
						{
							name = "staticradar",
							x = 4816,
							z = 1040,
							facing = 3,
						},
						{
							name = "energywind",
							x = 5272,
							z = 696,
							facing = 3,
						},
						{
							name = "energywind",
							x = 5336,
							z = 760,
							facing = 3,
						},
						{
							name = "energywind",
							x = 5400,
							z = 808,
							facing = 3,
						},
						{
							name = "energywind",
							x = 5464,
							z = 856,
							facing = 3,
						},
						{
							name = "turretheavylaser",
							x = 4744,
							z = 1992,
							facing = 3,
						},
						{
							name = "turretlaser",
							x = 3792,
							z = 704,
							facing = 3,
						},
						{
							name = "staticmex",
							x = 4312,
							z = 1944,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 4248,
							z = 1928,
							facing = 3,
						},
						{
							name = "energysolar",
							x = 4296,
							z = 2008,
							facing = 3,
						},
						{
							name = "energysolar",
							x = 4200,
							z = 1848,
							facing = 3,
						},
						{
							name = "turretlaser",
							x = 4256,
							z = 1872,
							facing = 3,
						},
						{
							name = "turretriot",
							x = 5160,
							z = 1768,
							facing = 3,
						},
						{
							name = "staticmex",
							x = 3512,
							z = 3352,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 3528,
							z = 3416,
							facing = 3,
						},
						{
							name = "energysolar",
							x = 3448,
							z = 3368,
							facing = 3,
						},
						{
							name = "turretlaser",
							x = 3568,
							z = 3344,
							facing = 3,
						},
						{
							name = "turretemp",
							x = 5040,
							z = 784,
							facing = 3,
						},
						{
							name = "turretmissile",
							x = 5120,
							z = 608,
							facing = 3,
						},
						{
							name = "turretriot",
							x = 4696,
							z = 1144,
							facing = 3,
						},
						{
							name = "turretheavylaser",
							x = 4376,
							z = 1288,
							facing = 3,
						},
						{
							name = "energysolar",
							x = 4312,
							z = 1208,
							facing = 3,
						},
						{
							name = "energysolar",
							x = 4360,
							z = 1128,
							facing = 3,
						},
						{
							name = "turretlaser",
							x = 4128,
							z = 1424,
							facing = 3,
						},
						{
							name = "tankriot",
							x = 6103,
							z = 223,
							facing = 2,
							difficultyAtLeast = 2,
						},
						{
							name = "tankassault",
							x = 6107,
							z = 342,
							facing = 1,
							difficultyAtLeast = 4,
						},
						{
							name = "tankheavyraid",
							x = 6068,
							z = 281,
							facing = 2,
							difficultyAtLeast = 3,
						},
						{
							name = "tankriot",
							x = 6072,
							z = 85,
							facing = 2,
						},
						{
							name = "tankriot",
							x = 6072,
							z = 205,
							facing = 2,
						},
						{
							name = "tankriot",
							x = 5892,
							z = 85,
							facing = 2,
							difficultyAtLeast = 4,
						},
						{
							name = "tankassault",
							x = 5772,
							z = 85,
							facing = 2,
							difficultyAtLeast = 4,
						},
						{
							name = "tankcon",
							x = 6087,
							z = 533,
							facing = 1,
							difficultyAtLeast = 3,
						},
						{
							name = "vehassault",
							x = 850,
							z = 2562,
							facing = 2,
							difficultyAtLeast = 2,
						},
						{
							name = "vehcon",
							x = 616,
							z = 2839,
							facing = 2,
						},
						{
							name = "tankriot",
							x = 6077,
							z = 415,
							facing = 1,
							difficultyAtLeast = 3,
						},
						{
							name = "turretriot",
							x = 3720,
							z = 856,
							facing = 3,
							terraformHeight = 239,
							difficultyAtLeast = 2,
						},
						{
							name = "energysolar",
							x = 3720,
							z = 936,
							facing = 3,
						},
						{
							name = "energysolar",
							x = 3672,
							z = 760,
							facing = 3,
						},
						{
							name = "energysolar",
							x = 3640,
							z = 920,
							facing = 3,
						},
						{
							name = "energysolar",
							x = 3640,
							z = 840,
							facing = 3,
						},
						{
							name = "energysolar",
							x = 3720,
							z = 680,
							facing = 3,
						},
						{
							name = "energysolar",
							x = 3768,
							z = 1016,
							facing = 3,
						},
						{
							name = "turretlaser",
							x = 3840,
							z = 976,
							facing = 3,
						},
						{
							name = "turretriot",
							x = 4552,
							z = 2216,
							facing = 3,
							terraformHeight = 259,
							difficultyAtLeast = 2,
						},
						{
							name = "energysolar",
							x = 4456,
							z = 2232,
							facing = 3,
						},
						{
							name = "energysolar",
							x = 4504,
							z = 2312,
							facing = 3,
						},
						{
							name = "turretlaser",
							x = 4752,
							z = 2496,
							facing = 3,
						},
						{
							name = "energysolar",
							x = 4728,
							z = 2552,
							facing = 3,
						},
						{
							name = "turretlaser",
							x = 4976,
							z = 288,
							facing = 3,
						},
						{
							name = "turretmissile",
							x = 4256,
							z = 544,
							facing = 3,
						},
						{
							name = "turretmissile",
							x = 5888,
							z = 2496,
							facing = 3,
						},
						{
							name = "turretmissile",
							x = 4336,
							z = 1616,
							facing = 3,
						},
						{
							name = "factorytank",
							x = 5328,
							z = 1296,
							facing = 3,
						},
						{
							name = "energysolar",
							x = 4696,
							z = 1224,
							facing = 3,
						},
						{
							name = "energysolar",
							x = 4712,
							z = 1304,
							facing = 3,
						},
						{
							name = "energysolar",
							x = 4728,
							z = 1384,
							facing = 3,
						},
						{
							name = "energysolar",
							x = 4744,
							z = 1464,
							facing = 3,
							difficultyAtLeast = 2,
						},
						{
							name = "turretlaser",
							x = 4848,
							z = 1472,
							facing = 0,
						},
						{
							name = "turretriot",
							x = 5800,
							z = 1672,
							facing = 0,
							terraformHeight = 259,
							difficultyAtLeast = 2,
						},
						{
							name = "energysolar",
							x = 6104,
							z = 1768,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 5624,
							z = 1704,
							facing = 0,
						},
						{
							name = "turretheavylaser",
							x = 4808,
							z = 488,
							facing = 3,
						},
						{
							name = "energysolar",
							x = 4808,
							z = 552,
							facing = 3,
						},
						{
							name = "energysolar",
							x = 4808,
							z = 424,
							facing = 3,
						},
						{
							name = "energysolar",
							x = 4728,
							z = 488,
							facing = 3,
						},
						{
							name = "turretemp",
							x = 5632,
							z = 2048,
							facing = 3,
							difficultyAtLeast = 2,
						},
						{
							name = "staticmex",
							x = 1832,
							z = 2152,
							facing = 0,
							difficultyAtLeast = 2,
						},
					}
				},
			},
			defeatConditionConfig = {
				-- Indexed by allyTeam.
				[0] = { },
				[1] = {
					ignoreUnitLossDefeat = false,
					vitalCommanders = true,
					vitalUnitTypes = {
						"factorytank",
						"factoryveh",
					},
					loseAfterSeconds = false,
					allyTeamLossObjectiveID = 1,
				},
			},
			objectiveConfig = {
				-- This is just related to displaying objectives on the UI.
				[1] = {
					description = "Make your enemy control no Commanders or Factories",
				},
				[2] = {
					description = "Protect your Commander",
				},
			},
			bonusObjectiveConfig = {
				[1] = { -- Build 6 Dominatrices
					satisfyOnce = true,
					countRemovedUnits = true,
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 12,
					unitTypes = {
						"vehcapture",
					},
					image = planetUtilities.ICON_DIR .. "vehcapture.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.REPAIR,
					description = "Build 6 Dominatrices",
					experience = planetUtilities.BONUS_EXP,
				},
				[2] = { -- Have five Welders
					satisfyOnce = true,
					capturedUnitsSatisfy = true,
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 5,
					unitTypes = {
						"tankcon",
					},
					image = planetUtilities.ICON_DIR .. "tankcon.png",
					--imageOverlay = planetUtilities.ICON_OVERLAY.REPAIR,
					description = "Control 5 Welders",
					experience = planetUtilities.BONUS_EXP,
				},
				[3] = { -- Have a Tank Foundry
					satisfyOnce = true,
					capturedUnitsSatisfy = true,
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 1,
					unitTypes = {
						"factorytank",
					},
					image = planetUtilities.ICON_DIR .. "factorytank.png",
					--imageOverlay = planetUtilities.ICON_OVERLAY.REPAIR,
					description = "Control a Tank Foundry",
					experience = planetUtilities.BONUS_EXP,
				},
				[4] = { -- Win by 8:00
					victoryByTime = 480,
					image = planetUtilities.ICON_OVERLAY.CLOCK,
					description = "Win by 8:00",
					experience = planetUtilities.BONUS_EXP,
				},
			},
		},
		completionReward = {
			experience = planetUtilities.MAIN_EXP,
			units = {
				"vehcapture",
			},
			modules = {
				"module_companion_drone_LIMIT_A_2",
			},
			abilities = {
			},
			codexEntries = {
				"faction_empire"
			},
		},
	}
	
	return planetData
end

return GetPlanet
