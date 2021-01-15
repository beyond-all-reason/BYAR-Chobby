--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Planet config

local function GetPlanet(planetUtilities, planetID)
	
	local image = LUA_DIRNAME .. "images/planets/tundra02.png"
	
	local planetData = {
		name = "Quora Rosia Dyo",
		startingPlanet = false,
		mapDisplay = {
			x = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][1]) or 0.495,
			y = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][2]) or 0.295,
			image = image,
			size = planetUtilities.PLANET_SIZE_MAP,
		},
		infoDisplay = {
			image = image,
			size = planetUtilities.PLANET_SIZE_INFO,
			backgroundImage = planetUtilities.backgroundImages[math.floor(math.random()*#planetUtilities.backgroundImages) + 1],
			terrainType = "Arctic",
			radius = "4040 km",
			primary = "Nadstan",
			primaryType = "G9V",
			milRating = 1,
			feedbackLink = "http://zero-k.info/Forum/Thread/24530",
			text = "The Rebel forces of this planet took a last stand in the mountains, awaiting an end that never came. Now that everyone is gone, the armies are still waiting."
			.. "\n "
			.. "\nTime to put an end to this."
			,
			extendedText = "Rebel bots aren't going to cut it alone on a battlefield this mountainous. My Redback riot and Recluse skirmish spiders can take control of the high ground, and rain death upon their enemies in the valley below."
		},
		tips = {
			
			{
				image = "unitpics/spiderriot.png",
				text = [[The Redback riot spider is equipped with a short-range particle beam. It doesn't inflict area-of-effect damage, but since it is accurate and non-ballistic it's effective at fighting up hills.]]
			},
			{
				image = "unitpics/spiderskirm.png",
				text = [[Recluse skirmish spiders fire a volley of inaccurate missiles. They are most effective against large groups of enemies, since this guarantees all their rockets will hit something. They can also fire over hills.]]
			},
			{
				image = "unitpics/spidercon.png",
				text = [[The Spider factory's Weaver constructors are slow, but they have high buildpower, all-terrain movement (obviously), and a short-range radar.]]
			},
		},
		gameConfig = {
			mapName = "FrozenPlanetV3",
			playerConfig = {
				startX = 400,
				startZ = 1100,
				allyTeam = 0,
				commanderParameters = {
					facplop = false,
					defeatIfDestroyedObjectiveID = 2,
				},
				extraUnlocks = {
					"factoryspider",
					"spidercon",
					"spiderriot",
					"spiderskirm",
				},
				startUnits = {
					{
						name = "staticmex",
						x = 312,
						z = 1112,
						facing = 0,
					},
 					{
						name = "staticmex",
						x = 104,
						z = 1224,
						facing = 0,
					},
 					{
						name = "staticmex",
						x = 136,
						z = 920,
						facing = 0,
					},
 					{
						name = "energysolar",
						x = 232,
						z = 1000,
						facing = 3,
					},
 					{
						name = "energysolar",
						x = 168,
						z = 1144,
						facing = 3,
					},
 					{
						name = "factoryspider",
						x = 200,
						z = 1400,
						facing = 1,
					},
 					{
						name = "staticcon",
						x = 88,
						z = 1400,
						facing = 1,
						commands = {
							{cmdID = planetUtilities.COMMAND.PATROL, pos = {88, 1400}},
							{cmdID = planetUtilities.COMMAND.PATROL, pos = {113, 1425}, options = {"shift"}},
						},
					},
 					{
						name = "turretlaser",

						x = 256,
						z = 1552,
						facing = 1,
					},
 					{
						name = "turretlaser",
						x = 304,
						z = 928,
						facing = 2,
					},
					{
						name = "spidercon",
						x = 329,
						z = 1474,
						facing = 0,
					},
 					{
						name = "spiderriot",
						x = 495,
						z = 1401,
						facing = 0,
					},
 					{
						name = "spiderskirm",
						x = 456,
						z = 1293,
						facing = 0,
					},
 					{
						name = "spiderriot",
						x = 424,
						z = 1484,
						facing = 0,
					},
 					{
						name = "spiderskirm",
						x = 389,
						z = 1382,
						facing = 0,
					},
				}
			},
			aiConfig = {
				{
					humanName = "Yarwha",
					--aiLib = "Null AI",
					--bitDependant = false,
					aiLib = "Circuit_difficulty_autofill_ally",
					bitDependant = true,
					allyTeam = 0,
					unlocks = {
						"staticradar",
						"staticcon",
						"staticmex",
						"energysolar",
						"energywind",
						"energygeo",
						"turretlaser",
						"turretmissile",
						"factorycloak",
						"cloakcon",
						"cloakraid",
						"cloakskirm",
						"cloakriot",
						"cloakassault",
						"cloakarty",
					},
					commander = false,
					startUnits = {
						{
							name = "staticmex",
							x = 440,
							z = 3240,
							facing = 3,
						},
 						{
							name = "staticmex",
							x = 136,
							z = 3400,
							facing = 3,
						},
 						{
							name = "staticmex",
							x = 232,
							z = 3048,
							facing = 3,
						},
 						{
							name = "energysolar",
							x = 312,
							z = 3160,
							facing = 3,
						},
 						{
							name = "energysolar",
							x = 232,
							z = 3320,
							facing = 3,
						},
 						{
							name = "energysolar",
							x = 152,
							z = 3160,
							facing = 3,
						},
 						{
							name = "factorycloak",
							x = 544,
							z = 3400,
							facing = 1,
						},
 						{
							name = "energysolar",
							x = 376,
							z = 3304,
							facing = 1,
						},
 						{
							name = "turretriot",
							x = 272,
							z = 3488,
							facing = 0,
						},
 						{
							name = "staticcon",
							x = 392,
							z = 3400,
							facing = 1,
							commands = {
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {392, 3400}},
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {417, 3375}, options = {"shift"}},
							},
						},
 						{
							name = "turretriot",
							x = 368,
							z = 3024,
							facing = 2,
						},
						{
							name = "turretriot",
							x = 672,
							z = 3514,
							facing = 1,
						},
 						{
							name = "cloakcon",
							x = 711,
							z = 3299,
							facing = 3,
						},
 						{
							name = "cloakriot",
							x = 678,
							z = 3224,
							facing = 1,
						},
 						{
							name = "cloakskirm",
							x = 687,
							z = 3138,
							facing = 2,
						},
 						{
							name = "cloakskirm",
							x = 824,
							z = 3390,
							facing = 1,
						},
 						{
							name = "cloakskirm",
							x = 710,
							z = 3374,
							facing = 0,
						},
					}
				},
				{
					startX = 3600,
					startZ = 2200,
					humanName = "Colvai",
					--aiLib = "Null AI",
					--bitDependant = false,
					aiLib = "Circuit_difficulty_autofill",
					bitDependant = true,
					commanderParameters = {
						facplop = false,
					},
					allyTeam = 1,
					unlocks = {
						"staticradar",
						"staticcon",
						"staticmex",
						"energysolar",
						"energywind",
						"energygeo",
						"turretlaser",
						"turretmissile",
						"factorycloak",
						"cloakcon",
						"cloakraid",
						"cloakskirm",
						"cloakriot",
						"cloakassault",
						"cloakarty",
					},
					commanderLevel = 4,
					commander = {
						name = "Lucy Bazza",
						chassis = "recon",
						modules = {
							"commweapon_lparticlebeam",
							"commweapon_concussion",
							"module_adv_nano",
							"module_adv_nano",
							"module_ablative_armor",
							"module_ablative_armor",
							"module_companion_drone",
							"module_companion_drone",
							"module_high_power_servos",
						}
					},
					startUnits = {
						{
							name = "staticmex",
							x = 3736,
							z = 2904,
							facing = 3,
						},
 						{
							name = "staticmex",
							x = 3960,
							z = 2792,
							facing = 3,
						},
 						{
							name = "staticmex",
							x = 3928,
							z = 3144,
							facing = 3,
						},
 						{
							name = "energysolar",
							x = 3928,
							z = 3032,
							facing = 3,
						},
 						{
							name = "energysolar",
							x = 3864,
							z = 2872,
							facing = 3,
						},
 						{
							name = "energysolar",
							x = 4040,
							z = 2904,
							facing = 3,
						},
 						{
							name = "turretlaser",
							x = 3984,
							z = 3232,
							facing = 0,
						},
 						{
							name = "turretlaser",
							x = 3712,
							z = 2800,
							facing = 3,
						},
 						{
							name = "factorycloak",
							x = 3920,
							z = 2632,
							facing = 3,
						},
 						{
							name = "staticcon",
							x = 4056,
							z = 2632,
							facing = 3,
							commands = {
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {4056, 2632}},
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {4031, 2607}, options = {"shift"}},
							},
						},
 						{
							name = "turretlaser",
							x = 4064,
							z = 2384,
							facing = 3,
						},
 						{
							name = "staticradar",
							x = 3008,
							z = 2768,
							facing = 2,
						},
 						{
							name = "turretlaser",
							x = 2992,
							z = 2848,
							facing = 3,
						},
 						{
							name = "turretmissile",
							x = 2208,
							z = 3568,
							facing = 3,
						},
 						{
							name = "turretlaser",
							x = 2144,
							z = 3472,
							facing = 3,
						},
 						{
							name = "cloakriot",
							x = 3662,
							z = 2672,
							facing = 3,
						},
 						{
							name = "cloakraid",
							x = 3708,
							z = 2544,
							facing = 0,
						},
 						{
							name = "staticmex",
							x = 3272,
							z = 2136,
							facing = 3,
							difficultyAtLeast = 2,
						},
 						{
							name = "energygeo",
							x = 2984,
							z = 1832,
							facing = 0,
							difficultyAtLeast = 4,
						},
						{
							name = "turretriot",
							x = 2860,
							z = 1832,
							facing = 3,
							difficultyAtLeast = 4,
						},
 						{
							name = "energypylon",
							x = 3576,
							z = 2072,
							facing = 3,
							difficultyAtLeast = 4,
						},
 						{
							name = "energypylon",
							x = 4072,
							z = 2728,
							facing = 3,
							difficultyAtLeast = 4,
						},
 						{
							name = "energysolar",
							x = 3256,
							z = 2216,
							facing = 3,
							difficultyAtLeast = 2,
						},
					}
				},
				{
					humanName = "Kaste Dron",
					--aiLib = "Null AI",
					--bitDependant = false,
					aiLib = "Circuit_difficulty_autofill",
					bitDependant = true,
					allyTeam = 1,
					unlocks = {
						"staticradar",
						"staticcon",
						"staticmex",
						"energysolar",
						"energywind",
						"energygeo",
						"turretlaser",
						"turretmissile",
						"factoryshield",
						"shieldcon",
						"shieldraid",
						"shieldskirm",
						"shieldriot",
					},
					difficultyDependantUnlocks = {
						[3] = {"shieldassault"},
						[4] = {"shieldassault","shieldarty"},
					},
					startUnits = {
						{
							name = "staticmex",
							x = 3784,
							z = 888,
							facing = 3,
						},
 						{
							name = "staticmex",
							x = 4024,
							z = 1032,
							facing = 3,
						},
 						{
							name = "staticmex",
							x = 3944,
							z = 712,
							facing = 3,
						},
 						{
							name = "energysolar",
							x = 3896,
							z = 824,
							facing = 3,
						},
 						{
							name = "energysolar",
							x = 3976,
							z = 936,
							facing = 3,
						},
 						{
							name = "energysolar",
							x = 4040,
							z = 792,
							facing = 3,
						},
 						{
							name = "turretlaser",
							x = 3920,
							z = 608,
							facing = 3,
						},
 						{
							name = "turretlaser",
							x = 3920,
							z = 1168,
							facing = 3,
						},
 						{
							name = "turretlaser",
							x = 2384,
							z = 1248,
							facing = 3,
						},
 						{
							name = "staticcon",
							x = 3912,
							z = 1064,
							facing = 3,
							commands = {
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {3912, 1064}},
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {3887, 1089}, options = {"shift"}},
							},
						},
 						{
							name = "staticradar",
							x = 3312,
							z = 1392,
							facing = 2,
						},
 						{
							name = "turretlaser",
							x = 3024,
							z = 544,
							facing = 3,
						},
 						{
							name = "turretmissile",
							x = 2416,
							z = 1152,
							facing = 3,
						},
 						{
							name = "energysolar",
							x = 4040,
							z = 1144,
							facing = 3,
						},
 						{
							name = "shieldcon",
							x = 3703,
							z = 727,
							facing = 2,
						},
 						{
							name = "shieldraid",
							x = 3451,
							z = 1070,
							facing = 3,
						},
 						{
							name = "staticmex",
							x = 2840,
							z = 1304,
							facing = 0,
							difficultyAtLeast = 3,
						},
 						{
							name = "factoryshield",
							x = 3768,
							z = 1056,
							facing = 3,
						},
 						{
							name = "shieldcon",
							x = 3664,
							z = 830,
							facing = 1,
						},
 						{
							name = "shieldraid",
							x = 3453,
							z = 1026,
							facing = 3,
						},
 						{
							name = "shieldraid",
							x = 3473,
							z = 985,
							facing = 3,
						},
 						{
							name = "shieldraid",
							x = 3485,
							z = 941,
							facing = 3,
							difficultyAtLeast = 2,
						},
 						{
							name = "shieldraid",
							x = 3498,
							z = 896,
							facing = 2,
							difficultyAtLeast = 2,
						},
 						{
							name = "shieldraid",
							x = 3512,
							z = 846,
							facing = 2,
							difficultyAtLeast = 3,
						},
 						{
							name = "shieldriot",
							x = 3565,
							z = 1049,
							facing = 2,
							difficultyAtLeast = 3,
						},
 						{
							name = "shieldriot",
							x = 3598,
							z = 936,
							facing = 2,
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
						"factorycloak",
						"factoryshield",
					},
					loseAfterSeconds = false,
					allyTeamLossObjectiveID = 1,
				},
			},
			objectiveConfig = {
				-- This is just related to displaying objectives on the UI.
				[1] = {
					description = "Destroy the enemy Commander and all enemy Factories",
				},
				[2] = {
					description = "Protect your Commander",
				},
			},
			bonusObjectiveConfig = {
				[1] = { -- Build 10 Recluses
					satisfyOnce = true,
					countRemovedUnits = true, -- count units that previously died.
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 10,
					unitTypes = {
						"spiderskirm",
					},
					image = planetUtilities.ICON_DIR .. "spiderskirm.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.REPAIR,
					description = "Build 10 Recluses",
					experience = planetUtilities.BONUS_EXP,
				},
				[2] = { -- Make the enemy lose one factory by 6:00
					onlyCountRemovedUnits = true,
					satisfyByTime = 480,
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 1,
					enemyUnitTypes = {
						"factoryshield",
						"factorycloak"
					},
					image = planetUtilities.ICON_DIR .. "factoryshield.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.ATTACK,
					description = "Destroy an enemy Factory before 8:00",
					experience = planetUtilities.BONUS_EXP,
				},
			}
		},
		completionReward = {
			experience = planetUtilities.MAIN_EXP,
			units = {
				"spiderriot",
				"spiderskirm",
			},
			modules = {
				"module_ablative_armor_LIMIT_D_2",
			},
			abilities = {
			},
			codexEntries = {
				"faction_rebels"
			},
		},
	}
	
	return planetData
end

return GetPlanet
