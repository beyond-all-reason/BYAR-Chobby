--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Planet config

local function GetPlanet(planetUtilities, planetID)
	
	local image = LUA_DIRNAME .. "images/planets/terran04.png"
	
	local planetData = {
		name = "Cadentem",
		startingPlanet = false,
		mapDisplay = {
			x = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][1]) or 0.17,
			y = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][2]) or 0.28,
			image = image,
			size = planetUtilities.PLANET_SIZE_MAP,
		},
		infoDisplay = {
			image = image,
			size = planetUtilities.PLANET_SIZE_INFO,
			backgroundImage = planetUtilities.backgroundImages[math.floor(math.random()*#planetUtilities.backgroundImages) + 1],
			terrainType = "Terran",
			radius = "6700 km",
			primary = "Sop",
			primaryType = "G2VI",
			milRating = 2,
			feedbackLink = "http://zero-k.info/Forum/Thread/24457",
			text = "With the IFF codes I could scavenge on that last world, one of the armies down there is now recognizing me as an ally. This should be useful for fighting my way through here."
			.. "\n "
			.. "\nThis is a nasty world, with corrosive oceans. I wonder how local life adapted so well."
			,
			extendedText = "If I help my ally to push across the island with Fencer missile trucks and Badger mine artillery, a slow but inevitable push should work just as surely as a lightning assault."
			.. "\n "
			.. "\nThat said, I would prefer a lightning assault. I don't want to stay in a corrosive hydrosphere any longer than necessary."
		},
		tips = {
			{
				image = "unitpics/vehsupport.png",
				text = [[Fencers need to remain stationary and set up before they can fire, making them better at defense than offence. Their guided missiles inflict reliable damage at range.]]
			},
			{
				image = "unitpics/veharty.png",
				text = [[Badgers are very good for grinding down your opposition. They fire mines which can make a region practically impassable for the enemy. They are almost defenseless unless you plan ahead with some well placed mines, so make sure they don't get flanked. Press F to force your Badgers to fire at a given location.]]
			},
			{
				image = "unitpics/module_dmg_booster.png",
				text = [[The water on this planet is acidic. Don't move your Commander into it.]]
			},
			{
				image = "unitpics/spidercrabe.png",
				text = [[Your ally's Spiders can climb up sheer cliffs, so there are some parts of the battlefield which they will be better at fighting over. The heavy Crab spider in particular is a potent fighting force even when alone.]]
			},
		},
		gameConfig = {
			mapName = "Quicksilver 1.1",
			playerConfig = {
				startX = 4900,
				startZ = 2400,
				allyTeam = 0,
				useUnlocks = true,
				commanderParameters = {
					facplop = false,
					defeatIfDestroyedObjectiveID = 2,
				},
				extraUnlocks = {
					"factoryveh",
					"vehcon",
					"vehsupport",
					"veharty",
				},
				startUnits = {
					{
						name = "staticradar",
						x = 4400,
						z = 2868,
						facing = 3,
					},
					{
						name = "factoryveh",
						x = 4792,
						z = 2184,
						facing = 3,
					},
					{
						name = "staticmex",
						x = 4632,
						z = 2344,
						facing = 0,
					},
					{
						name = "staticmex",
						x = 5304,
						z = 1432,
						facing = 0,
					},
					{
						name = "staticmex",
						x = 5656,
						z = 2824,
						facing = 0,
					},
					{
						name = "energysolar",
						x = 5544,
						z = 2856,
						facing = 0,
					},
					{
						name = "energysolar",
						x = 5592,
						z = 2712,
						facing = 0,
					},
					{
						name = "energysolar",
						x = 5336,
						z = 1512,
						facing = 0,
					},
					{
						name = "energysolar",
						x = 4568,
						z = 2424,
						facing = 0,
					},
					{
						name = "vehsupport",
						x = 4491,
						z = 2092,
						facing = 0,
					},
					{
						name = "turretlaser",
						x = 5136,
						z = 2928,
						facing = 0,
					},
					{
						name = "turretlaser",
						x = 4432,
						z = 2320,
						facing = 3,
					},
					{
						name = "vehsupport",
						x = 4553,
						z = 2189,
						facing = 3,
					},
					{
						name = "vehriot",
						x = 4617,
						z = 2061,
						facing = 3,
					},
				}
			},
			aiConfig = {
				{
					--aiLib = "Null AI",
					--bitDependant = false,
					aiLib = "Circuit_difficulty_autofill_ally",
					bitDependant = true,
					humanName = "Arachnid",
					allyTeam = 0,
					unlocks = {
						--"factoryspider",
						"staticcon",
						"spidercon",
						"spiderscout",
						"spiderassault",
						"spideremp",
						"spiderskirm",
						"spiderriot",
						"spidercrabe",
						"staticmex",
						"energysolar",
						"energygeo",
						"staticradar",
						"turretlaser",
						"turretmissile",
						"turretriot",
					},
					commander = false,
					startUnits = {
						{
							name = "factoryspider",
							x = 4104,
							z = 1000,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 3816,
							z = 1016,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 4056,
							z = 1320,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 4568,
							z = 888,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 3688,
							z = 1064,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 3848,
							z = 1128,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 3976,
							z = 1240,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 4472,
							z = 824,
							facing = 0,
						},
						{
							name = "spidercon",
							x = 4165,
							z = 1195,
							facing = 2,
						},
						{
							name = "turretmissile",
							x = 3392,
							z = 1168,
							facing = 0,
						},
						{
							name = "turretmissile",
							x = 3920,
							z = 1536,
							facing = 0,
						},
						{
							name = "spideremp",
							x = 4199,
							z = 1119,
							facing = 1,
						},
						{
							name = "spiderskirm",
							x = 4172,
							z = 1152,
							facing = 2,
						},
						{
							name = "energyfusion",
							x = 4291,
							z = 770,
							facing = 1,
						},
						{
							name = "energypylon",
							x = 4357,
							z = 1232,
							facing = 1,
						},
					},
				},
				{
					startX = 1600,
					startZ = 5100,
					--aiLib = "Null AI",
					--bitDependant = false,
					aiLib = "Circuit_difficulty_autofill",
					bitDependant = true,
					humanName = "Walkers",
					commanderParameters = {
						facplop = false,
					},
					commanderLevel = 3,
					commander = {
						name = "Betty Botty",
						chassis = "strike",
						decorations = {
						},
						modules = {
							"commweapon_beamlaser",
							"commweapon_beamlaser",
							"module_ablative_armor",
							"module_autorepair",
							"module_adv_targeting",
						}
					},
					allyTeam = 1,
					unlocks = {
						"staticcon",
						"staticmex",
						"energysolar",
						"staticradar",
						"turretlaser",
						--"factoryjump",
						--"factorycloak",
						"jumpcon",
						"jumpscout",
						"jumpraid",
						--"jumpblackhole",
						"jumpskirm",
						"cloakcon",
						"cloakraid",
						"cloakriot",
						"cloakbomb",
						"cloakraid",
						"cloakskirm",
						"cloakassault",
						"cloakaa",
						"turretlaser",
						"turretmissile",
						"turretriot",
					},
					difficultyDependantUnlocks = {
						[3] = {"cloakarty"},
						[4] = {"cloakarty","cloakheavyraid"},
					},
					
					startUnits = {
						{
							name = "staticmex",
							x = 760,
							z = 4440,
							facing = 0,
							difficultyAtLeast = 2,
						},
						{
							name = "staticmex",
							x = 2950,
							z = 5420,
							facing = 3,
							difficultyAtLeast = 3,
						},
						{
							name = "staticmex",
							x = 760,
							z = 2380,
							facing = 3,
							difficultyAtLeast = 4,
						},
						{
							name = "staticradar",
							x = 1840,
							z = 4512,
							facing = 3,
						},
						{
							name = "turretlaser",
							x = 1940,
							z = 4610,
							facing = 2,
						},
						{
							name = "turretheavylaser",
							x = 1740,
							z = 3500,
							facing = 1,
						},
						{
							name = "turretheavylaser",
							x = 1080,
							z = 3500,
							facing = 2,
						},
						{
							name = "turretheavylaser",
							x = 1236,
							z = 4440,
							facing = 2,
						},
						{
							name = "turretemp",
							x = 3160,
							z = 5000,
							facing = 2,
						},
						{
							name = "turretlaser",
							x = 3100,
							z = 4850,
							facing = 2,
						},
						{
							name = "turretlaser",
							x = 3280,
							z = 5050,
							facing = 2,
						},
						{
							name = "turretemp",
							x = 1240,
							z = 2140,
							facing = 1,
						},
						{
							name = "turretlaser",
							x = 1240,
							z = 2000,
							facing = 1,
						},
						{
							name = "turretriot",
							x = 1300,
							z = 2200,
							facing = 1,
						},
						{
							name = "turretheavylaser",
							x = 2620,
							z = 3950,
							facing = 1,
							bonusObjectiveID = 2,
							mapMarker = {
								text = "Stinger",
								color = "red_small"
							},
						},
						{
							name = "energypylon",
							x = 2194,
							z = 4224,
							facing = 1,
						},
						{
							name = "energypylon",
							x = 1823,
							z = 5088,
							facing = 1,
						},
						{
							name = "energyfusion",
							x = 1456,
							z = 5400,
							facing = 1,
						},
						{
							name = "energysolar",
							x = 1256,
							z = 5060,
							facing = 1,
						},
						{
							name = "energysolar",
							x = 1256,
							z = 4920,
							facing = 1,
						},
						{
							name = "energysolar",
							x = 1100,
							z = 4920,
							facing = 1,
						},
						{
							name = "turretmissile",
							x = 3000,
							z = 4000,
							facing = 1,
						},
						{
							name = "turretmissile",
							x = 3100,
							z = 4100,
							facing = 2,
						},
						{
							name = "turretriot",
							x = 2600,
							z = 3450,
							facing = 2,
						},
						{
							name = "factoryjump",
							x = 1576,
							z = 5144,
							facing = 2,
						},
						{
							name = "factorycloak",
							x = 1264,
							z = 3944,
							facing = 1,
						},
						{
							name = "staticmex",
							x = 1928,
							z = 5048,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 1944,
							z = 5464,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 1256,
							z = 5176,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 1784,
							z = 3752,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 584,
							z = 3256,
							facing = 0,
						},
						{
							name = "turretriot",
							x = 1912,
							z = 3768,
							facing = 1,
						},
						{
							name = "energysolar",
							x = 2008,
							z = 5352,
							facing = 0,
						},
						{
							name = "turretmissile",
							x = 1920,
							z = 3920,
							facing = 1,
						},
						{
							name = "energysolar",
							x = 1928,
							z = 5192,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 2024,
							z = 5064,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 1352,
							z = 5240,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 648,
							z = 4392,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 632,
							z = 3160,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 1688,
							z = 3672,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 1656,
							z = 3816,
							facing = 0,
						},
						{
							name = "turretmissile",
							x = 1920,
							z = 3616,
							facing = 1,
						},
						{
							name = "jumpcon",
							x = 1773,
							z = 5015,
							facing = 1,
						},
						{
							name = "turretriot",
							x = 1192,
							z = 3032,
							facing = 2,
						},
						{
							name = "turretmissile",
							x = 1040,
							z = 3056,
							facing = 2,
						},
						{
							name = "turretmissile",
							x = 1360,
							z = 3056,
							facing = 2,
						},
						{
							name = "jumpraid",
							x = 1589,
							z = 4880,
							facing = 2,
						},
						{
							name = "cloakskirm",
							x = 1322,
							z = 3520,
							facing = 2,
						},
						{
							name = "jumpskirm",
							x = 1575,
							z = 4910,
							facing = 2,
						},
						{
							name = "cloakskirm",
							x = 1480,
							z = 3975,
							facing = 0,
						},
						{
							name = "cloakskirm",
							x = 1442,
							z = 3904,
							facing = 1,
						},
						{
							name = "cloakraid",
							x = 1420,
							z = 3769,
							facing = 3,
						},
						{
							name = "cloakraid",
							x = 1363,
							z = 3654,
							facing = 2,
						},
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
						"factoryjump",
						"factorycloak",
					},
					loseAfterSeconds = false,
					allyTeamLossObjectiveID = 1,
				},
			},
			objectiveConfig = {
				-- This is just related to displaying objectives on the UI.
				[1] = {
					description = "Destroy all enemy factories",
				},
				[2] = {
					description = "Protect your Commander",
				},
			},
			bonusObjectiveConfig = {
				[1] = { -- Have 10 Badger
					satisfyOnce = true,
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 10,
					unitTypes = {
						"veharty",
					},
					image = planetUtilities.ICON_DIR .. "veharty.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.REPAIR,
					description = "Have 10 Badgers",
					experience = planetUtilities.BONUS_EXP,
				},
				[2] = { -- Kill the enemy Stinger by 12:00
					satisfyByTime = 720,
					comparisionType = planetUtilities.COMPARE.AT_MOST,
					targetNumber = 0,
					-- See bonusObjectiveID in units table
					image = planetUtilities.ICON_DIR .. "turretheavylaser.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.ATTACK,
					description = "Destroy the marked enemy Stinger turret before 12:00",
					experience = planetUtilities.BONUS_EXP,
				},
				-- [3] = { -- Prevent the enemy having more than twelve mex
					-- satisfyForever = true,
					-- comparisionType = planetUtilities.COMPARE.AT_MOST,
					-- targetNumber = 12,
					-- enemyUnitTypes = {
						-- "staticmex",
					-- },
					-- image = planetUtilities.ICON_DIR .. "staticmex.png",
					-- imageOverlay = planetUtilities.ICON_OVERLAY.ATTACK,
					-- description = "Prevent the enemy from building more than twelve Metal Extractors",
					-- experience = planetUtilities.BONUS_EXP,
				-- },
			},
		},
		completionReward = {
			experience = planetUtilities.MAIN_EXP,
			units = {
				"vehsupport",
				"veharty",
			},
			modules = {
				"commweapon_missilelauncher",
			},
			codexEntries = {
			},
		},
	}
	
	return planetData
end

return GetPlanet
