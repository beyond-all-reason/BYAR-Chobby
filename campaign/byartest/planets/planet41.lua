--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Planet config

local function GetPlanet(planetUtilities, planetID)
	
	--local image = planetUtilities.planetImages[math.floor(math.random()*#planetUtilities.planetImages) + 1]
	local image = LUA_DIRNAME .. "images/planets/terran03_damaged.png"
	
	local planetData = {
		name = "Aspiris",
		startingPlanet = false,
		mapDisplay = {
			x = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][1]) or 0.435,
			y = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][2]) or 0.19,
			image = image,
			size = planetUtilities.PLANET_SIZE_MAP,
		},
		infoDisplay = {
			image = image,
			size = planetUtilities.PLANET_SIZE_INFO,
			backgroundImage = planetUtilities.backgroundImages[math.floor(math.random()*#planetUtilities.backgroundImages) + 1],
			terrainType = "Terran",
			radius = "5350 km",
			primary = "Ahdas Las",
			primaryType = "G7V",
			milRating = 1,
			feedbackLink = "http://zero-k.info/Forum/Thread/24489",
			text = "If I can take control of this planet's warp gates, it will open up half the sector. What is surprising is that the local forces are not imperial. How did the Empire lose control of such an important sector to an independent warlord?"
			.. "\n "
			.. "\nThis gives me an idea... still, better load my Commander for a fight, just in case."
			,
			extendedText = "I thought I could hack the warlord's Commander, but its AI just glitched on me. Time for plan B: take the Gates by force."
		},
		tips = {
			{
				image = "unitpics/tankcon.png",
				text = [[Unlike all other constructors, the Welder is armed and sturdy. It is better able to weather raids until reinforcements arrive and can even beat a small number of raiders in a fight.]]
			},
			{
				image = "unitpics/tankheavyraid.png",
				text = [[The Blitz heavy tank raider will go toe-to-toe with any other raider - its high HP and lightning weaponry give it a significant edge. However, it is fairly inefficient due to its comparatively high cost.]]
			},
			{
				image = "unitpics/cremcom.png",
				text = [[Your Commander begins this mission in an exposed location. After you survive the ambush, build turrets quickly or retreat to your main base to keep your Commander safe.]]
			},
		},
		gameConfig = {
			mapName = "Rogues River v1.2",
			playerConfig = {
				startX = 2060,
				startZ = 4760,
				allyTeam = 0,
				facplop = false,
				commanderParameters = {
					facplop = false,
					defeatIfDestroyedObjectiveID = 2,
					facing = 1,
				},
				extraUnlocks = {
					"factorytank",
					"tankcon",
					"tankassault",
					"tankriot",
					"tankheavyraid",
				},
				startUnits = {
 					{
						name = "factorytank",
						x = 3216,
						z = 480,
						facing = 0,
					},
 					{
						name = "staticmex",
						x = 3304,
						z = 136,
						facing = 0,
					},
 					{
						name = "staticmex",
						x = 3100,
						z = 167,
						facing = 0,
					},
 					{
						name = "staticmex",
						x = 2660,
						z = 103,
						facing = 0,
					},
					{
						name = "staticmex",
						x = 2820,
						z = 88,
						facing = 0,
					},
 					{
						name = "tankheavyraid",
						x = 3400,
						z = 950,
						facing = 0,
					},
 					{
						name = "tankheavyraid",
						x = 3250,
						z = 950,
						facing = 0,
					},
 					{
						name = "tankarty",
						x = 3250,
						z = 825,
						facing = 0,
					},
 					{
						name = "tankarty",
						x = 3400,
						z = 825,
						facing = 0,
					},
 					{
						name = "energysolar",
						x = 2840,
						z = 216,
						facing = 0,
					},
 					{
						name = "energysolar",
						x = 2984,
						z = 152,
						facing = 0,
					},
 					{
						name = "energysolar",
						x = 2530,
						z = 72,
						facing = 0,
					},
 					{
						name = "energysolar",
						x = 3016,
						z = 296,
						facing = 0,
					},
 					{
						name = "energysolar",
						x = 3178,
						z = 268,
						facing = 0,
					},
 					{
						name = "energysolar",
						x = 2696,
						z = 216,
						facing = 0,
					},
 					{
						name = "energysolar",
						x = 2792,
						z = 328,
						facing = 0,
					},
 					{
						name = "turretlaser",
						x = 2480,
						z = 272,
						facing = 0,
					},
 					{
						name = "turretlaser",
						x = 2736,
						z = 544,
						facing = 0,
					},
 					{
						name = "tankcon",
						x = 2940,
						z = 500,
						facing = 0,
					},
 					{
						name = "tankcon",
						x = 2940,
						z = 700,
						facing = 0,
					},
 					{
						name = "turretlaser",
						x = 3488,
						z = 688,
						facing = 1,
					},
 					{
						name = "turretlaser",
						x = 3584,
						z = 336,
						facing = 1,
					},
 					{
						name = "turretaaclose",
						x = 3000,
						z = 408,
						facing = 0,
					},
 					{
						name = "staticradar",
						x = 3360,
						z = 1056,
						facing = 0,
					},
 					{
						name = "tankriot",
						x = 2103,
						z = 4973,
						facing = 1,
					},
 					{
						name = "tankriot",
						x = 2120,
						z = 4547,
						facing = 1,
					},
 					{
						name = "planelightscout",
						x = 1846,
						z = 4698,
						facing = 1,
						commands = {
							{cmdID = planetUtilities.COMMAND.RAW_MOVE, pos = {1200, 4698}},
						},
					},
 					{
						name = "staticmex",
						x = 4296,
						z = 408,
						facing = 0,
						difficultyAtMost = 3,
					},
 					{
						name = "staticmex",
						x = 4408,
						z = 136,
						facing = 0,
						difficultyAtMost = 3,
					},
					{
						name = "turretlaser",
						x = 4416,
						z = 320,
						facing = 0,
						difficultyAtMost = 3,
					},
				}
			},
			aiConfig = {
				{
					startX = 2626,
					startZ = 4743,
					aiLib = "Circuit_difficulty_autofill",
					bitDependant = true,
					--aiLib = "Null AI",
					--bitDependant = false,
					humanName = "Spurs",
					commanderParameters = {
						facplop = false,
						bonusObjectiveID = 1,
						facing = 3,
					},
					allyTeam = 1,
					unlocks = {
						"staticcon",
						"staticradar",
						"staticmex",
						"energysolar",
						"energygeo",
						"hovercon",
                        "hoverheavyraid",
						"hoverraid",
						"hoverriot",
						"hoverassault",
						"hoveraa",
						"shieldraid",
						"shieldriot",
						"shieldskirm",
						"shieldassault",
						"shieldbomb",
						"shieldaa",
					},
					difficultyDependantUnlocks = {
						[2] = {"hoverskirm"},
						[3] = {"hoverskirm","shieldcon"},
						[4] = {"hoverskirm","shieldcon","hoverarty","shieldarty"},
					},
					commanderLevel = 4,
					commander = {
						name = "DeeTeeCee",
						chassis = "strike",
						decorations = {
						},
						modules = {
							"commweapon_lparticlebeam",
							"commweapon_missilelauncher",
							"module_high_power_servos",
							"module_adv_nano",
							"module_adv_nano",
							"module_jammer",
							"module_adv_targeting",
							"module_autorepair",
							"module_dmg_booster"
						}
					},
					startUnits = {
 						{
							name = "turretaalaser",
							x = 6600,
							z = 4248,
							facing = 3,
						},
 						{
							name = "turretheavylaser",
							x = 3848,
							z = 6536,
							facing = 2,
						},
 						{
							name = "turretheavylaser",
							x = 4312,
							z = 6584,
							facing = 2,
						},
 						{
							name = "turretheavylaser",
							x = 4872,
							z = 7032,
							facing = 2,
						},
 						{
							name = "turretheavylaser",
							x = 3336,
							z = 6808,
							facing = 2,
						},
 						{
							name = "turretheavylaser",
							x = 6152,
							z = 3768,
							facing = 3,
						},
 						{
							name = "turretheavylaser",
							x = 6904,
							z = 3480,
							facing = 3,
						},
 						{
							name = "turretheavylaser",
							x = 6488,
							z = 4440,
							facing = 3,
						},
 						{
							name = "turretheavylaser",
							x = 6888,
							z = 5016,
							facing = 3,
						},
 						{
							name = "turretemp",
							x = 6560,
							z = 3728,
							facing = 3,
						},
 						{
							name = "turretemp",
							x = 6256,
							z = 4144,
							facing = 3,
						},
 						{
							name = "turretemp",
							x = 6768,
							z = 4704,
							facing = 3,
						},
 						{
							name = "turretriot",
							x = 3624,
							z = 6760,
							facing = 2,
						},
 						{
							name = "turretriot",
							x = 4104,
							z = 6360,
							facing = 2,
						},
 						{
							name = "turretriot",
							x = 4648,
							z = 6808,
							facing = 2,
						},
 						{
							name = "turretriot",
							x = 3304,
							z = 7048,
							facing = 3,
						},
 						{
							name = "staticstorage",
							x = 3560,
							z = 7128,
							facing = 0,
						},
 						{
							name = "staticstorage",
							x = 3640,
							z = 7128,
							facing = 0,
						},
 						{
							name = "staticstorage",
							x = 7096,
							z = 4616,
							facing = 0,
						},
 						{
							name = "staticstorage",
							x = 7096,
							z = 4696,
							facing = 0,
						},
 						{
							name = "energysolar",
							x = 4100,
							z = 6900,
							facing = 0,
						},
 						{
							name = "energysolar",
							x = 4232,
							z = 6936,
							facing = 0,
						},
 						{
							name = "energysolar",
							x = 4230,
							z = 7064,
							facing = 0,
						},
 						{
							name = "energysolar",
							x = 6936,
							z = 4232,
							facing = 0,
						},
 						{
							name = "energysolar",
							x = 7048,
							z = 4152,
							facing = 0,
						},
 						{
							name = "energysolar",
							x = 6890,
							z = 4345,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 3864,
							z = 7030,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 4072,
							z = 7016,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 4345,
							z = 7100,
							facing = 0,
						},
						{
							name = "staticmex",
							z = 3864,
							x = 7030,
							facing = 0,
						},
						{
							name = "staticmex",
							z = 4072,
							x = 7016,
							facing = 0,
						},
						{
							name = "staticmex",
							z = 4345,
							x = 7100,
							facing = 0,
						},
 						{
							name = "factoryhover",
							x = 3580,
							z = 6980,
							facing = 2,
						},
 						{
							name = "factoryshield",
							x = 6880,
							z = 3950,
							facing = 3,
						},
 						{
							name = "turretgauss",
							x = 360,
							z = 3064,
							facing = 1,
						},
 						{
							name = "turretlaser",
							x = 464,
							z = 2992,
							facing = 1,
						},
 						{
							name = "turretlaser",
							x = 240,
							z = 3008,
							facing = 2,
						},
 						{
							name = "turretlaser",
							x = 368,
							z = 3184,
							facing = 0,
						},
 						{
							name = "turretaafar",
							x = 4080,
							z = 6528,
							facing = 2,
						},
 						{
							name = "turretaaclose",
							x = 6296,
							z = 3912,
							facing = 3,
						},
 						{
							name = "turretaalaser",
							x = 6744,
							z = 3816,
							facing = 3,
						},
						{
							name = "staticradar",
							x = 6090,
							z = 4000,
							facing = 3,
						},
						{
							name = "shieldskirm",
							x = 6700,
							z = 3900,
							facing = 3,
						},
						{
							name = "shieldriot",
							x = 6700,
							z = 4030,
							facing = 3,
							difficultyAtLeast = 2,
						},
						{
							name = "shieldcon",
							x = 6700,
							z = 4060,
							facing = 3,
							difficultyAtLeast = 3,
						},
						{
							name = "shieldfelon",
							x = 6700,
							z = 4100,
							facing = 3,
							difficultyAtLeast = 4,
						},
						{
							name = "hovercon",
							x = 4480,
							z = 6900,
							facing = 3,
						},
						{
							name = "hoverskirm",
							x = 4500,
							z = 6900,
							facing = 3,
							difficultyAtLeast = 2,
						},
						{
							name = "hoverriot",
							x = 4530,
							z = 6900,
							facing = 3,
							difficultyAtLeast = 3,
						},
						{
							name = "hoverarty",
							x = 4600,
							z = 6900,
							facing = 3,
							difficultyAtLeast = 4,
						},
					}
				},
				{
					humanName = "Ambushers",
					aiLib = "Null AI",
					bitDependant = false,
					--aiLib = "Circuit_difficulty_autofill",
					--bitDependant = true,
					allyTeam = 1,
					unlocks = {
					},
					commander = false,
					startUnits = {
						{
							name = "hoverriot",
							x = 2687,
							z = 4864,
							facing = 3,
							commands = {
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {2060, 4760}},
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {3200, 500}, options = {"shift"}},
							},
						},
						{
							name = "shieldraid",
							x = 1240,
							z = 3945,
							facing = 3,
							commands = {
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {2060, 4760}},
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {3200, 500}, options = {"shift"}},
							},
						},
 						{
							name = "shieldskirm",
							x = 1411,
							z = 3854,
							facing = 2,
							commands = {
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {2060, 4760}},
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {3200, 500}, options = {"shift"}},
							},
						},
 						{
							name = "shieldassault",
							x = 1324,
							z = 3897,
							facing = 0,
							difficultyAtLeast = 2,
							difficultyAtMost = 3,
							commands = {
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {2060, 4760}},
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {3200, 500}, options = {"shift"}},
							},
						},
						{
							name = "shieldfelon",
							x = 1324,
							z = 3897,
							facing = 0,
							difficultyAtLeast = 4,
							commands = {
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {2060, 4760}},
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {3200, 500}, options = {"shift"}},
							},
						},
 						{
							name = "shieldraid",
							x = 1521,
							z = 3806,
							facing = 0,
							commands = {
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {2060, 4760}},
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {3200, 500}, options = {"shift"}},
							},
						},
 						{
							name = "shieldskirm",
							x = 1188,
							z = 5455,
							facing = 0,
							commands = {
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {2060, 4760}},
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {3200, 500}, options = {"shift"}},
							},
						},
 						{
							name = "shieldassault",
							x = 1312,
							z = 5543,
							facing = 0,
							difficultyAtLeast = 2,
							commands = {
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {2060, 4760}},
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {3200, 500}, options = {"shift"}},
							},
						},
 						{
							name = "shieldraid",
							x = 1442,
							z = 5636,
							facing = 0,
							commands = {
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {2060, 4760}},
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {3200, 500}, options = {"shift"}},
							},
						},
 						{
							name = "shieldraid",
							x = 1594,
							z = 5665,
							facing = 3,
							commands = {
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {2060, 4760}},
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {3200, 500}, options = {"shift"}},
							},
						},
 						{
							name = "hoverskirm",
							x = 2751,
							z = 4735,
							facing = 3,
							difficultyAtLeast = 3,
							commands = {
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {2060, 4760}},
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {3200, 500}, options = {"shift"}},
							},
						},
 						{
							name = "hoverassault",
							x = 2683,
							z = 4596,
							facing = 3,
							commands = {
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {2060, 4760}},
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {3200, 500}, options = {"shift"}},
							},
						},
					}
				},
			},
			neutralUnits = {
				{
					name = "pw_warpgate",
					x = 4072,
					z = 6672,
					facing = 0,
					invincible = true,
					ignoredByAI = true,
					mapMarker = {
						text = "Warp Gate",
						color = "green_small"
					},
				},
				{
					name = "pw_warpgate",
					x = 6504,
							z = 4000,
					facing = 0,
					invincible = true,
					ignoredByAI = true,
					mapMarker = {
						text = "Warp Gate",
						color = "green_small"
					},
				},
			},
			defeatConditionConfig = {
				-- Indexed by allyTeam.
				[0] = { },
				[1] = {
					ignoreUnitLossDefeat = false,
					vitalCommanders = false,
					vitalUnitTypes = {
						"factoryshield",
						"factoryhover",
						"turretheavylaser",
						"turretemp",
						"turretriot",
						"turretaaclose",
						"turretaafar",
						"turretaalaser",
					},
					loseAfterSeconds = false,
					allyTeamLossObjectiveID = 1,
				},
			},
			objectiveConfig = {
				-- This is just related to displaying objectives on the UI.
				[1] = {
					description = "Destroy the factory and turrets surrounding each Warp Gate",
				},
				[2] = {
					description = "Protect your Commander",
				},
			},
			bonusObjectiveConfig = {
				[1] = { -- Kill enemy commander before 2:00
					satisfyByTime = 2*60,
					comparisionType = planetUtilities.COMPARE.AT_MOST,
					targetNumber = 0,
					-- See bonusObjectiveID in units table
					image = planetUtilities.ICON_DIR .. "strike.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.ATTACK,
					description = "Destroy the enemy commander before 2:00",
					experience = planetUtilities.BONUS_EXP,
				},
				[2] = {
					onlyCountRemovedUnits = true,
					satisfyUntilTime = 2*60,
					comparisionType = planetUtilities.COMPARE.AT_MOST,
					targetNumber = 0,
					unitTypes = {
						"tankriot"
					},
					image = planetUtilities.ICON_DIR .. "tankriot.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.GUARD,
					description = "Do not lose any Ogres before 2:00",
					experience = planetUtilities.BONUS_EXP,
				},
				[3] = { -- Complete all bonus objectives
					completeAllBonusObjectives = true,
					image = planetUtilities.ICON_OVERLAY.ALL,
					description = "Complete all bonus objectives (in one battle)",
					experience = planetUtilities.BONUS_EXP,
				},
			}
		},
		completionReward = {
			experience = planetUtilities.MAIN_EXP,
			units = {
				"factorytank",
				"tankcon",
				"tankriot",
				"tankheavyraid",
			},
			modules = {
				"module_adv_nano_LIMIT_F_1",
			},
			abilities = {
			},
			codexEntries = {
				"faction_lawless"
			}
		},
	}
	
	return planetData
end

return GetPlanet
