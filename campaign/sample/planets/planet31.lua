--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Planet config

local function GetPlanet(planetUtilities, planetID)
	
	local image = LUA_DIRNAME .. "images/planets/ocean02.png"
	
	local planetData = {
		name = "Juliburg",
		startingPlanet = false,
		mapDisplay = {
			x = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][1]) or 0.565,
			y = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][2]) or 0.93,
			image = image,
			size = planetUtilities.PLANET_SIZE_MAP,
		},
		infoDisplay = {
			image = image,
			size = planetUtilities.PLANET_SIZE_INFO,
			backgroundImage = planetUtilities.backgroundImages[math.floor(math.random()*#planetUtilities.backgroundImages) + 1],
			terrainType = "Coastal",
			radius = "6270 km",
			primary = "Yastras",
			primaryType = "G8V",
			milRating = 1,
			feedbackLink = "http://zero-k.info/Forum/Thread/24530",
			text = "Invalid IFF? Well, it was worth trying. Local defenses have considearbly decayed, but what's left is still dangerous."
			.. "\n "
			.. "\nThis world had never been disputed to Haven yet, but they knew it would be the next line of defense at the fall of Harsar Lief. With most of the planet covered by water, they could have held it from strategic archipelagoes against a considerable foe."
			,
			extendedText = "With those small islands dotting the ocean, this is ideal for the deployment of ships and submarines. I should move fast to take control of this resource-rich archipelago - once I hold it, I will be safe. The other planetary garrisons have long lost their oversea projection capabilities."
		},
		tips = {
			{
				image = "unitpics/shipriot.png",
				text = [[Corsairs are equipped with twin shotguns that are lethal at close range. Get up close to structures and surface vessels to destroy them quickly.]]
			},
			{
				image = "unitpics/subraider.png",
				text = [[The Seawolf is good for picking off isolated ships and economy structures. Being underwater protects them from many attacks, but they don't have much HP so keep them away from torpedo boats and turrets.]]
			},
			{
				image = "unitpics/staticmex.png",
				text = [[This is a large map with a lot of metal. Expand quickly to secure an advantage.]]
			},
		},
		gameConfig = {
			mapName = "BellicoseIslands_ZK-v01",
			playerConfig = {
				startX = 500,
				startZ = 3300,
				allyTeam = 0,
				facplop = false,
				commanderParameters = {
					facplop = false,
					defeatIfDestroyedObjectiveID = 2,
				},
				extraUnlocks = {
					"factoryship",
					"shipcon",
					"shipriot",
					"subraider",
				},
				startUnits = {
					{
						name = "factoryship",
						x = 352,
						z = 2720,
						facing = 1,
					},
 					{
						name = "staticmex",
						x = 88,
						z = 2920,
						facing = 1,
					},
 					{
						name = "staticmex",
						x = 88,
						z = 3016,
						facing = 1,
					},
 					{
						name = "staticmex",
						x = 88,
						z = 3112,
						facing = 1,
					},
 					{
						name = "energywind",
						x = 56,
						z = 2856,
						facing = 1,
					},
 					{
						name = "energywind",
						x = 136,
						z = 2856,
						facing = 1,
					},
 					{
						name = "energywind",
						x = 152,
						z = 2936,
						facing = 1,
					},
 					{
						name = "energywind",
						x = 152,
						z = 3016,
						facing = 1,
					},
 					{
						name = "energywind",
						x = 152,
						z = 3096,
						facing = 1,
					},
 					{
						name = "energywind",
						x = 152,
						z = 3176,
						facing = 1,
					},
 					{
						name = "energywind",
						x = 72,
						z = 3192,
						facing = 1,
					},
 					{
						name = "staticmex",
						x = 120,
						z = 3576,
						facing = 1,
					},
 					{
						name = "staticmex",
						x = 408,
						z = 3560,
						facing = 1,
					},
 					{
						name = "staticmex",
						x = 584,
						z = 3624,
						facing = 1,
					},
 					{
						name = "energysolar",
						x = 264,
						z = 3560,
						facing = 1,
					},
 					{
						name = "energysolar",
						x = 520,
						z = 3544,
						facing = 1,
					},
 					{
						name = "energysolar",
						x = 392,
						z = 3448,
						facing = 3,
					},
 					{
						name = "staticradar",
						x = 624,
						z = 3504,
						facing = 3,
					},
 					{
						name = "turretmissile",
						x = 832,
						z = 3504,
						facing = 1,
					},
 					{
						name = "turrettorp",
						x = 856,
						z = 3656,
						facing = 1,
					},
 					{
						name = "turretmissile",
						x = 448,
						z = 2576,
						facing = 1,
					},
 					{
						name = "turrettorp",
						x = 552,
						z = 2520,
						facing = 1,
					},
 					{
						name = "staticmex",
						x = 88,
						z = 2456,
						facing = 1,
					},
 					{
						name = "subraider",
						x = 757,
						z = 2725,
						facing = 1,
					},
 					{
						name = "subraider",
						x = 756,
						z = 3051,
						facing = 1,
					},
 					{
						name = "shipriot",
						x = 750,
						z = 2890,
						facing = 1,
					},
 					{
						name = "shipriot",
						x = 768,
						z = 2561,
						facing = 1,
					},
 					{
						name = "staticcon",
						x = 312,
						z = 3064,
						facing = 3,
						commands = {
							{cmdID = planetUtilities.COMMAND.PATROL, pos = {312, 3064}},
							{cmdID = planetUtilities.COMMAND.PATROL, pos = {337, 3039}, options = {"shift"}},
						},
					},
				}
			},
			aiConfig = {
				{
					aiLib = "Circuit_difficulty_autofill",
					bitDependant = true,
					--aiLib = "Null AI",
					--bitDependant = false,
					humanName = "Escorta",
					allyTeam = 1,
					unlocks = {
						"staticmex",
						"energywind",
						"energyfusion",
						"staticradar",
						"staticstorage",
						"staticcon",
						"turrettorp",
						"factoryship",
						"shipcon",
						"shiptorpraider",
						"subraider",
					},
					commander = false,
					startUnits = {
						{
							name = "factoryship",
							x = 7920,
							z = 2000,
							facing = 3,
						},
						{
							name = "staticcon",
							x = 8100,
							z = 2000,
							facing = 3,
						},
						{
							name = "staticstorage",
							x = 8100,
							z = 2200,
							facing = 3,
						},
						{
							name = "turrettorp",
							x = 7500,
							z = 1800,
							facing = 3,
						},
					}
				},
				{
					startX = 7500,
					startZ = 3500,
					humanName = "Bollik",
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
						"energywind",
						"energyfusion",
						"staticradar",
						"staticstorage",
						"staticcon",
						"staticrearm",
						"turretmissile",
						"turrettorp",
						"factoryship",
						"shipcon",
						"shipscout",
						"shiptorpraider",
						"shipskirm",
						"shipaa",
						"shiparty",
						"shipriot",
						"factoryplane",
						"planecon",
						"planescout",
						"planeheavyfighter",
						"bomberprec",
					},
					difficultyDependantUnlocks = {
						[3] = {"shipassault"},
						[4] = {"shipassault"},
					},
					commanderLevel = 6,
					commander = {
						name = "Carn Timber",
						chassis = "guardian",
						decorations = {
						},
						modules = {
							"commweapon_rocketlauncher",
							"commweapon_rocketlauncher",
							"module_ablative_armor",
							"module_ablative_armor",
							"module_ablative_armor",
							"module_ablative_armor",
							"module_high_power_servos",
							"module_high_power_servos",
							"module_high_power_servos",
							"module_high_power_servos",
							"module_autorepair",
							"module_autorepair",
						}
					},
					midgameUnits = {
						{
							name = "bomberprec",
							x = 8000,
							z = 1700,
							facing = 2,
							spawnRadius = 50,
							delay = 3*30*60,
							orbitalDrop = false,
						},
						{
							name = "bomberprec",
							x = 8000,
							z = 1700,
							facing = 2,
							spawnRadius = 50,
							delay = 43*30*60,
							orbitalDrop = false,
							difficultyAtLeast = 3,
						},
						{
							name = "shiparty",
							x = 8000,
							z = 1700,
							facing = 2,
							spawnRadius = 50,
							delay = 4.5*30*60,
							orbitalDrop = false,
						},
						{
							name = "shiparty",
							x = 8000,
							z = 1900,
							facing = 2,
							difficultyAtLeast = 2,
							spawnRadius = 50,
							delay = 4.5*30*60,
							orbitalDrop = false,
						},
						{
							name = "shiparty",
							x = 8000,
							z = 2100,
							facing = 2,
							difficultyAtLeast = 3,
							spawnRadius = 50,
							delay = 4.5*30*60,
							orbitalDrop = false,
						},
						{
							name = "shipheavyarty",
							x = 8000,
							z = 1900,
							facing = 2,
							difficultyAtLeast = 4,
							spawnRadius = 50,
							delay = 7*30*60,
							orbitalDrop = false,
						},
						{
							name = "shipassault",
							x = 8000,
							z = 2100,
							facing = 2,
							difficultyAtLeast = 4,
							spawnRadius = 50,
							delay = 7*30*60,
							orbitalDrop = false,
						},
					},
					startUnits = {
						{
							name = "staticmex",
							x = 7490,
							z = 2750,
							facing = 1,
							difficultyAtLeast = 2,
						},
						{
							name = "staticmex",
							x = 8123,
							z = 1880,
							facing = 1,
							difficultyAtLeast = 3,
						},
						{
							name = "energyfusion",
							x = 7930,
							z = 3125,
							facing = 1,
							difficultyAtLeast = 4,
						},
						{
							name = "staticrearm",
							x = 7970,
							z = 2630,
							facing = 3,
						},
						{
							name = "turretheavylaser",
							x = 6660,
							z = 2280,
							facing = 3,
						},
						{
							name = "turretheavylaser",
							x = 6950,
							z = 1280,
							facing = 3,
						},
						{
							name = "turretheavylaser",
							x = 6000,
							z = 3500,
							facing = 3,
						},
						{
							name = "turrettorp",
							x = 6860,
							z = 3600,
							facing = 3,
						},
						{
							name = "turrettorp",
							x = 7700,
							z = 1600,
							facing = 3,
						},
						{
							name = "factoryship",
							x = 7712,
							z = 2992,
							facing = 3,
						},
 						{
							name = "staticmex",
							x = 8120,
							z = 2872,
							facing = 3,
						},
 						{
							name = "staticmex",
							x = 8120,
							z = 3016,
							facing = 3,
						},
 						{
							name = "staticmex",
							x = 8120,
							z = 3144,
							facing = 3,
						},
 						{
							name = "energywind",
							x = 8152,
							z = 2808,
							facing = 3,
						},
 						{
							name = "energywind",
							x = 8072,
							z = 2808,
							facing = 3,
						},
 						{
							name = "energywind",
							x = 8040,
							z = 2888,
							facing = 3,
						},
 						{
							name = "energywind",
							x = 8040,
							z = 2968,
							facing = 3,
						},
 						{
							name = "energywind",
							x = 8040,
							z = 3048,
							facing = 3,
						},
 						{
							name = "energywind",
							x = 8040,
							z = 3128,
							facing = 3,
						},
 						{
							name = "energywind",
							x = 8040,
							z = 3208,
							facing = 3,
						},
 						{
							name = "energywind",
							x = 8120,
							z = 3208,
							facing = 3,
						},
 						{
							name = "staticmex",
							x = 8040,
							z = 3592,
							facing = 3,
						},
 						{
							name = "staticmex",
							x = 7768,
							z = 3544,
							facing = 3,
						},
 						{
							name = "staticmex",
							x = 7608,
							z = 3656,
							facing = 3,
						},
 						{
							name = "energysolar",
							x = 7672,
							z = 3576,
							facing = 3,
						},
 						{
							name = "energysolar",
							x = 7864,
							z = 3512,
							facing = 3,
						},
 						{
							name = "energysolar",
							x = 8008,
							z = 3496,
							facing = 3,
						},
 						{
							name = "staticradar",
							x = 7616,
							z = 3504,
							facing = 3,
						},
 						{
							name = "staticcon",
							x = 7816,
							z = 2808,
							facing = 1,
							commands = {
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {7816, 2808}},
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {7791, 2783}, options = {"shift"}},
							},
						},
 						{
							name = "turrettorp",
							x = 7704,
							z = 2568,
							facing = 3,
						},
 						{
							name = "turretlaser",
							x = 7792,
							z = 2608,
							facing = 3,
						},
 						{
							name = "shipcon",
							x = 7449,
							z = 3230,
							facing = 3,
						},
 						{
							name = "turrettorp",
							x = 7448,
							z = 3560,
							facing = 3,
						},
 						{
							name = "turretlaser",
							x = 7472,
							z = 3456,
							facing = 3,
						},
 						{
							name = "staticmex",
							x = 8152,
							z = 2456,
							facing = 3,
						},
 						{
							name = "shiptorpraider",
							x = 7334,
							z = 2964,
							facing = 3,
						},
 						{
							name = "shiptorpraider",
							x = 7255,
							z = 3141,
							facing = 3,
						},
						{
							name = "shiptorpraider",
							x = 7255,
							z = 2800,
							facing = 3,
						},
 						{
							name = "shipriot",
							x = 7349,
							z = 3091,
							facing = 3,
						},
 						{
							name = "subraider",
							x = 7454,
							z = 2981,
							facing = 2,
						},
 						{
							name = "subraider",
							x = 7503,
							z = 3053,
							facing = 3,
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
						"factoryship",
						"factoryplane"
					},
					loseAfterSeconds = false,
					allyTeamLossObjectiveID = 1,
				},
			},
			objectiveConfig = {
				-- This is just related to displaying objectives on the UI.
				[1] = {
					description = "Destroy the enemy Commander and Factories",
				},
				[2] = {
					description = "Protect your Commander",
				},
			},
			bonusObjectiveConfig = {
				[1] = {
					satisfyOnce = true,
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 40,
					unitTypes = {
						"staticmex",
					},
					image = planetUtilities.ICON_DIR .. "staticmex.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.REPAIR,
					description = "Have 40 Metal Extractors",
					experience = planetUtilities.BONUS_EXP,
				},
				[2] = {
					victoryByTime = 15*60,
					image = planetUtilities.ICON_OVERLAY.CLOCK,
					description = "Win by 15:00",
					experience = planetUtilities.BONUS_EXP,
				},
				[3] = { -- Prevent the enemy having more than twelve mex
					satisfyForever = true,
					comparisionType = planetUtilities.COMPARE.AT_MOST,
					targetNumber = 25,
					enemyUnitTypes = {
						"staticmex",
					},
					image = planetUtilities.ICON_DIR .. "staticmex.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.ATTACK,
					description = "Prevent the enemy from having more than 25 Metal Extractors",
					experience = planetUtilities.BONUS_EXP,
				},
			},
		},
		completionReward = {
			experience = planetUtilities.MAIN_EXP,
			units = {
				"shipriot",
				"subraider",
			},
			modules = {
				"module_companion_drone_LIMIT_B_2",
			},
			abilities = {
			},
			codexEntries = {
				"faction_haven"
			}
		},
	}
	
	return planetData
end

return GetPlanet
