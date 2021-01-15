--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Planet config

local function GetPlanet(planetUtilities, planetID)
	
	--local image = planetUtilities.planetImages[math.floor(math.random()*#planetUtilities.planetImages) + 1]
	local image = LUA_DIRNAME .. "images/planets/ocean02.png"
	
	local planetData = {
		name = "Bluebell",
		startingPlanet = false,
		mapDisplay = {
			x = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][1]) or 0.465,
			y = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][2]) or 0.10,
			image = image,
			size = planetUtilities.PLANET_SIZE_MAP,
		},
		infoDisplay = {
			image = image,
			size = planetUtilities.PLANET_SIZE_INFO,
			backgroundImage = planetUtilities.backgroundImages[math.floor(math.random()*#planetUtilities.backgroundImages) + 1],
			terrainType = "Tropical",
			radius = "8440 km",
			primary = "Aioa",
			primaryType = "G8V",
			milRating = 1,
			feedbackLink = "http://zero-k.info/Forum/Thread/24510",
			text = "I am surprised a world so geologically active could be terraformed at all, let alone for it to hold for so long on its own."
			.. "\n "
			.. "\nThis is a problem, though, as it is still powering the core of a large defense system. There is no moving through here with those geothermal plants still running."
			,
			extendedText = "I have taken control of one of the major geothermal plants. If I can destroy the three others on this island, the entire defense system should power down. Skuttle jumping bombs could be useful for that..."
		},
		tips = {
			{
				image = "unitpics/jumpbomb.png",
				text = [[The Skuttle can jump on a single target and deal exceptional damage to it. The Skuttle cannot cloak while jumping and its decloak radius is quite large, so be careful how you deliver it to the target.]]
			},
			{
				image = "unitpics/striderdante.png",
				text = [[Heavier units and Commanders are especially vulnerable to the Skuttle, although particularly tough units like the Dante might require two Skuttles to put down for good.]]
			},
			{
				image = "unitpics/energyheavygeo.png",
				text = [[The Advanced Geothermal generator is comparatively cheap and provides a lot of energy. If it's destroyed it will unleash a large explosion, so don't put your Commander nearby!]]
			},
		},
		gameConfig = {
			mapName = "Calamity 1.1",
			playerConfig = {
				startX = 2191,
				startZ = 1715,
				allyTeam = 0,
				commanderParameters = {
					facplop = true,
					defeatIfDestroyedObjectiveID = 2,
				},
				extraUnlocks = {
					"factoryjump",
					"jumpcon",
					"jumpraid",
					"jumpbomb",
					"energygeo",
					"energyheavygeo",
				},
				startUnits = {
					 {
						name = "energyheavygeo",
						x = 2104,
						z = 2280,
						facing = 0,
					},
					{
						name = "jumpraid",
						x = 2235,
						z = 2040,
						facing = 0,
					},
 					{
						name = "jumpraid",
						x = 2422,
						z = 2030,
						facing = 0,
					},
 					{
						name = "jumpbomb",
						x = 2235,
						z = 2093,
						facing = 0,
					},
 					{
						name = "jumpbomb",
						x = 2422,
						z = 2082,
						facing = 0,
					},
 					{
						name = "jumpcon",
						x = 2369,
						z = 1980,
						facing = 0,
					},
 					{
						name = "jumpcon",
						x = 2280,
						z = 1997,
						facing = 0,
					},
 					{
						name = "staticmex",
						x = 1944,
						z = 1496,
						facing = 0,
					},
 					{
						name = "staticmex",
						x = 1672,
						z = 1464,
						facing = 0,
					},
 					{
						name = "staticmex",
						x = 1416,
						z = 2392,
						facing = 0,
					},
 					{
						name = "staticmex",
						x = 2664,
						z = 1304,
						facing = 0,
					},
 					{
						name = "staticmex",
						x = 2968,
						z = 1240,
						facing = 0,
					},
 					{
						name = "staticmex",
						x = 2136,
						z = 2840,
						facing = 3,
					},
 					{
						name = "staticmex",
						x = 2920,
						z = 2744,
						facing = 3,
					},
 					{
						name = "staticmex",
						x = 2376,
						z = 3768,
						facing = 3,
					},
 					{
						name = "staticmex",
						x = 1656,
						z = 4456,
						facing = 3,
					},
 					{
						name = "planescout",
						x = 760,
						z = 752,
						facing = 3,
						commands = {
							{cmdID = planetUtilities.COMMAND.MOVE, pos = {1600, 1900}},
						},
					},
					{
						name = "planescout",
						x = 1200,
						z = 752,
						facing = 3,
						commands = {
							{cmdID = planetUtilities.COMMAND.MOVE, pos = {2500, 1688}},
						},
					},
 					{
						name = "turretriot",
						x = 1640,
						z = 4600,
						facing = 0,
					},
 					{
						name = "turretlaser",
						x = 1456,
						z = 4544,
						facing = 0,
					},
 					{
						name = "turretlaser",
						x = 1808,
						z = 4560,
						facing = 0,
					},
 					{
						name = "staticradar",
						x = 2688,
						z = 4320,
						facing = 0,
					},
 					{
						name = "factoryjump",
						x = 2344,
						z = 1688,
						facing = 0,
					},
 					{
						name = "staticradar",
						x = 1856,
						z = 2256,
						facing = 0,
					},
					{
						name = "staticradar",
						x = 3180,
						z = 1263,
						facing = 0,
					},
 					{
						name = "energypylon",
						x = 1688,
						z = 1976,
						facing = 0,
					},
 					{
						name = "energypylon",
						x = 2520,
						z = 1448,
						facing = 0,
					},
 					{
						name = "staticcon",
						x = 2264,
						z = 1480,
						facing = 0,
						commands = {
							{cmdID = planetUtilities.COMMAND.PATROL, pos = {2264, 1480}},
							{cmdID = planetUtilities.COMMAND.PATROL, pos = {2289, 1505}, options = {"shift"}},
						},
					},
 					{
						name = "turretlaser",
						x = 2832,
						z = 3200,
						facing = 1,
					},
 					{
						name = "turretlaser",
						x = 2832,
						z = 3456,
						facing = 1,
					},
 					{
						name = "turretaaflak",
						x = 1976,
						z = 3672,
						facing = 0,
					},
 					{
						name = "turretlaser",
						x = 3472,
						z = 2288,
						facing = 1,
					},
 					{
						name = "turretlaser",
						x = 3504,
						z = 1840,
						facing = 1,
					},
 					{
						name = "jumpbomb",
						x = 2331,
						z = 2096,
						facing = 0,
					},
 					{
						name = "staticcon",
						x = 2344,
						z = 1480,
						facing = 0,
						commands = {
							{cmdID = planetUtilities.COMMAND.PATROL, pos = {2344, 1480}},
							{cmdID = planetUtilities.COMMAND.PATROL, pos = {2369, 1505}, options = {"shift"}},
						},
					},
				}
			},
			aiConfig = {
				{
					startX = 5642,
					startZ = 6037,
					aiLib = "Circuit_difficulty_autofill",
					bitDependant = true,
					--aiLib = "Null AI",
					--bitDependant = false,
					humanName = "Big Boofers",
					commanderParameters = {
						facplop = false,
						bonusObjectiveID = 1,
					},
					allyTeam = 1,
					unlocks = {
						"staticmex",
						"staticcon",
						"energysolar",
						"energygeo",
						"energyheavygeo",
						"staticradar",
						"tankcon",
						"tankheavyraid",
						"tankriot",
						"tankassault",
						"tankheavyassault",
						"tankaa",
						"striderdante",
						"striderscorpion",
					},
					commanderLevel = 4,
					commander = {
						name = "Yasaga",
						chassis = "guardian",
						decorations = {
						},
						modules = {
							"commweapon_heavymachinegun",
							"commweapon_clusterbomb",
							"module_ablative_armor",
							"module_ablative_armor",
							"module_ablative_armor",
							"module_autorepair",
							"module_autorepair",
							"module_high_power_servos",
						}
					},
					midgameUnits = {
						{
							name = "shipheavyarty",
							x = 7500,
							z = 6500,
							facing = 2,
							difficultyAtLeast = 4,
							spawnRadius = 50,
							delay = 1.5*30*60,
							orbitalDrop = true,
						},
						{
							name = "shipassault",
							x = 7800,
							z = 6000,
							facing = 2,
							difficultyAtLeast = 4,
							spawnRadius = 100,
							delay = 1.5*30*60,
							orbitalDrop = true,
						},
						{
							name = "shipassault",
							x = 7800,
							z = 5500,
							facing = 2,
							difficultyAtLeast = 4,
							spawnRadius = 100,
							delay = 1.5*30*60,
							orbitalDrop = false,
						},
						{
							name = "striderscorpion",
							x = 6150,
							z = 5100,
							facing = 2,
							spawnRadius = 50,
							delay = 3*30*60,
							orbitalDrop = true,
							difficultyAtLeast = 3,
						},
						{
							name = "tankheavyassault",
							x = 6000,
							z = 7000,
							facing = 2,
							difficultyAtLeast = 2,
							spawnRadius = 50,
							delay = 6*30*60,
							orbitalDrop = true,
						},
						{
							name = "amphassault",
							x = 6000,
							z = 7000,
							facing = 2,
							spawnRadius = 50,
							delay = 8*30*60,
							orbitalDrop = true,
						},
					},
					startUnits = {
						 {
							name = "energyheavygeo",
							x = 5352,
							z = 1656,
							facing = 0,
							mapMarker = {
								text = "Adv. Geo",
								color = "red_small"
							},
						},
 						{
							name = "energyheavygeo",
							x = 6072,
							z = 5896,
							facing = 0,
							mapMarker = {
								text = "Adv. Geo",
								color = "red_small"
							},
						},
 						{
							name = "energyheavygeo",
							x = 2872,
							z = 6536,
							facing = 0,
							mapMarker = {
								text = "Adv. Geo",
								color = "red_small"
							},
						},
						{
							name = "tankassault",
							x = 7100,
							z = 4700,
							facing = 2,
						},
						{
							name = "tankassault",
							x = 7400,
							z = 2600,
							facing = 2,
							difficultyAtLeast = 2,
						},
						{
							name = "tankassault",
							x = 2500,
							z = 7400,
							facing = 2,
							difficultyAtLeast = 2,
						},
						{
							name = "striderdante",
							x = 4400,
							z = 4800,
							facing = 2,
							difficultyAtLeast = 3,
						},
						{
							name = "striderdante",
							x = 6350,
							z = 6500,
							facing = 2,
							difficultyAtLeast = 4,
						},
						{
							name = "tankheavyassault",
							x = 6250,
							z = 6500,
							facing = 2,
							difficultyAtLeast = 4,
						},
						{
							name = "turretaalaser",
							x = 4068,
							z = 6883,
							facing = 2,
						},
						{
							name = "turretaalaser",
							x = 7830,
							z = 4222,
							facing = 2,
						},
						{
							name = "turretaalaser",
							x = 6150,
							z = 4000,
							facing = 2,
						},
 						{
							name = "turretlaser",
							x = 7328,
							z = 7168,
							facing = 2,
						},
 						{
							name = "turretlaser",
							x = 7664,
							z = 7520,
							facing = 1,
						},
 						{
							name = "turretaafar",
							x = 6080,
							z = 6320,
							facing = 2,
						},
 						{
							name = "turretaalaser",
							x = 5608,
							z = 6552,
							facing = 2,
						},
 						{
							name = "turretheavylaser",
							x = 6296,
							z = 5592,
							facing = 2,
						},
 						{
							name = "turretheavylaser",
							x = 6808,
							z = 5288,
							facing = 2,
						},
 						{
							name = "turretriot",
							x = 6552,
							z = 5416,
							facing = 2,
						},
 						{
							name = "turretaalaser",
							x = 2360,
							z = 6744,
							facing = 0,
						},
 						{
							name = "staticcon",
							x = 7368,
							z = 7464,
							facing = 2,
							commands = {
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {7368, 7464}},
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {7343, 7439}, options = {"shift"}},
							},
						},
 						{
							name = "turretaaflak",
							x = 7128,
							z = 7480,
							facing = 2,
						},
 						{
							name = "turretaalaser",
							x = 5752,
							z = 1432,
							facing = 0,
						},
 						{
							name = "turretaalaser",
							x = 6600,
							z = 5704,
							facing = 2,
						},
 						{
							name = "turretlaser",
							x = 6016,
							z = 5952,
							facing = 0,
						},
 						{
							name = "turretlaser",
							x = 6144,
							z = 5952,
							facing = 0,
						},
 						{
							name = "turretlaser",
							x = 6144,
							z = 5840,
							facing = 2,
						},
 						{
							name = "turretlaser",
							x = 6016,
							z = 5840,
							facing = 2,
						},
 						{
							name = "turretlaser",
							x = 5408,
							z = 1600,
							facing = 1,
						},
 						{
							name = "turretlaser",
							x = 5408,
							z = 1712,
							facing = 1,
						},
 						{
							name = "turretlaser",
							x = 5296,
							z = 1600,
							facing = 3,
						},
 						{
							name = "turretlaser",
							x = 5296,
							z = 1712,
							facing = 3,
						},
 						{
							name = "turretlaser",
							x = 2944,
							z = 6480,
							facing = 1,
						},
 						{
							name = "turretlaser",
							x = 2944,
							z = 6592,
							facing = 1,
						},
 						{
							name = "turretlaser",
							x = 2832,
							z = 6592,
							facing = 3,
						},
 						{
							name = "turretmissile",
							x = 6704,
							z = 3504,
							facing = 2,
						},
 						{
							name = "turretlaser",
							x = 2832,
							z = 6480,
							facing = 3,
						},
 						{
							name = "turretmissile",
							x = 5328,
							z = 4176,
							facing = 2,
						},
 						{
							name = "turretmissile",
							x = 5776,
							z = 3632,
							facing = 3,
						},
 						{
							name = "turretlaser",
							x = 6544,
							z = 3552,
							facing = 2,
						},
 						{
							name = "turretheavylaser",
							x = 5912,
							z = 2120,
							facing = 1,
						},
 						{
							name = "turretemp",
							x = 5280,
							z = 6720,
							facing = 2,
						},
 						{
							name = "turretgauss",
							x = 4648,
							z = 1848,
							facing = 3,
						},
 						{
							name = "staticmex",
							x = 4296,
							z = 5064,
							facing = 3,
						},
 						{
							name = "staticmex",
							x = 4808,
							z = 4728,
							facing = 3,
						},
 						{
							name = "turretheavylaser",
							x = 5016,
							z = 2168,
							facing = 3,
						},
 						{
							name = "turretheavylaser",
							x = 5432,
							z = 2456,
							facing = 0,
						},
 						{
							name = "staticmex",
							x = 5224,
							z = 6968,
							facing = 0,
						},
 						{
							name = "staticmex",
							x = 5528,
							z = 6904,
							facing = 0,
						},
 						{
							name = "turretheavylaser",
							x = 2280,
							z = 6088,
							facing = 3,
						},
 						{
							name = "turretheavylaser",
							x = 2728,
							z = 5736,
							facing = 2,
						},
 						{
							name = "staticmex",
							x = 6248,
							z = 6712,
							facing = 0,
						},
 						{
							name = "staticmex",
							x = 6520,
							z = 6744,
							facing = 0,
						},
 						{
							name = "turretheavylaser",
							x = 3192,
							z = 6056,
							facing = 1,
						},
 						{
							name = "turretmissile",
							x = 2464,
							z = 5952,
							facing = 2,
						},
 						{
							name = "staticmex",
							x = 6776,
							z = 5816,
							facing = 3,
						},
 						{
							name = "turretmissile",
							x = 3040,
							z = 5808,
							facing = 2,
						},
 						{
							name = "turretaaflak",
							x = 2728,
							z = 6120,
							facing = 2,
						},
 						{
							name = "factorytank",
							x = 5872,
							z = 6656,
							facing = 2,
						},
 						{
							name = "staticcon",
							x = 5864,
							z = 6776,
							facing = 2,
							commands = {
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {5864, 6776}},
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {5839, 6751}, options = {"shift"}},
							},
						},
 						{
							name = "turretriot",
							x = 5144,
							z = 6824,
							facing = 2,
						},
 						{
							name = "turretriot",
							x = 5368,
							z = 6584,
							facing = 3,
						},
 						{
							name = "turretgauss",
							x = 4232,
							z = 1624,
							facing = 0,
						},
 						{
							name = "turretgauss",
							x = 5560,
							z = 5800,
							facing = 3,
						},
 						{
							name = "striderhub",
							x = 4720,
							z = 5104,
							facing = 3,
							commands = {
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {4720, 5104}},
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {4695, 5079}, options = {"shift"}},
							},
						},
 						{
							name = "staticcon",
							x = 4824,
							z = 5032,
							facing = 3,
							commands = {
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {4824, 5032}},
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {4799, 5007}, options = {"shift"}},
							},
						},
 						{
							name = "turretheavylaser",
							x = 4040,
							z = 4936,
							facing = 2,
						},
 						{
							name = "turretriot",
							x = 4216,
							z = 4808,
							facing = 2,
						},
 						{
							name = "turretheavylaser",
							x = 4728,
							z = 4488,
							facing = 2,
						},
 						{
							name = "turretriot",
							x = 4504,
							z = 4616,
							facing = 2,
						},
 						{
							name = "turretaalaser",
							x = 4376,
							z = 5192,
							facing = 2,
						},
 						{
							name = "turretaalaser",
							x = 4920,
							z = 4840,
							facing = 2,
						},
 						{
							name = "turretmissile",
							x = 5248,
							z = 2304,
							facing = 0,
						},
 						{
							name = "turretmissile",
							x = 5744,
							z = 2256,
							facing = 0,
						},
 						{
							name = "turretaaflak",
							x = 5480,
							z = 2088,
							facing = 0,
						},
 						{
							name = "turretimpulse",
							x = 1680,
							z = 6240,
							facing = 0,
						},
 						{
							name = "turretimpulse",
							x = 1968,
							z = 6224,
							facing = 0,
						},
 						{
							name = "turretlaser",
							x = 1824,
							z = 6192,
							facing = 2,
						},
 						{
							name = "turretriot",
							x = 6344,
							z = 1992,
							facing = 0,
						},
 						{
							name = "turretheavylaser",
							x = 3720,
							z = 6456,
							facing = 2,
						},
 						{
							name = "staticheavyradar",
							x = 5520,
							z = 3872,
							facing = 2,
						},
 						{
							name = "staticradar",
							x = 5088,
							z = 1904,
							facing = 0,
						},
 						{
							name = "staticradar",
							x = 2512,
							z = 5840,
							facing = 0,
						},
 						{
							name = "staticradar",
							x = 6256,
							z = 5664,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 1620,
							z = 6488,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 2200,
							z = 7200,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 3140,
							z = 6900,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 6000,
							z = 1000,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 6360,
							z = 980,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 6570,
							z = 1720,
							facing = 0,
						},
					}
				},
			},
			defeatConditionConfig = {
				-- Indexed by allyTeam.
				[0] = { },
				[1] = {
					ignoreUnitLossDefeat = false,
					vitalCommanders = false,
					vitalUnitTypes = {
						"energyheavygeo",
					},
					loseAfterSeconds = false,
					allyTeamLossObjectiveID = 1,
				},
			},
			objectiveConfig = {
				-- This is just related to displaying objectives on the UI.
				[1] = {
					description = "Destroy the enemy Advanced Geothermals",
				},
				[2] = {
					description = "Protect your Commander",
				},
			},
			bonusObjectiveConfig = {
				[1] = { -- Kill enemy commander
					satisfyOnce = true,
					comparisionType = planetUtilities.COMPARE.AT_MOST,
					targetNumber = 0,
					-- See bonusObjectiveID in units table
					image = planetUtilities.ICON_DIR .. "guardian.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.ATTACK,
					description = "Destroy the enemy Commander",
					experience = planetUtilities.BONUS_EXP,
				},
				[2] = { -- Make the enemy lose one Strider Hub
					onlyCountRemovedUnits = true,
					satisfyOnce = true,
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 1,
					enemyUnitTypes = {
						"striderhub",
					},
					image = planetUtilities.ICON_DIR .. "striderhub.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.ATTACK,
					description = "Destroy the enemy Strider Hub",
					experience = planetUtilities.BONUS_EXP,
				},
				[3] = {
					victoryByTime = 720,
					image = planetUtilities.ICON_OVERLAY.CLOCK,
					description = "Win by 12:00",
					experience = planetUtilities.BONUS_EXP,
				},
			}
		},
		completionReward = {
			experience = planetUtilities.MAIN_EXP,
			units = {
				"jumpbomb",
				"energyheavygeo",
			},
			modules = {
				"commweapon_clusterbomb",
			},
			abilities = {
			}
		},
	}
	
	return planetData
end

return GetPlanet
