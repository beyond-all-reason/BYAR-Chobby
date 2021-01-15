--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Planet config

local function GetPlanet(planetUtilities, planetID)
	
	local image = LUA_DIRNAME .. "images/planets/desert01.png"
	
	local planetData = {
		name = "Hastus",
		startingPlanet = false,
		mapDisplay = {
			x = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][1]) or 0.61,
			y = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][2]) or 0.18,
			image = image,
			size = planetUtilities.PLANET_SIZE_MAP,
		},
		infoDisplay = {
			image = image,
			size = planetUtilities.PLANET_SIZE_INFO,
			backgroundImage = planetUtilities.backgroundImages[math.floor(math.random()*#planetUtilities.backgroundImages) + 1],
			terrainType = "Barren",
			radius = "5250 km",
			primary = "Banbawe",
			primaryType = "G3V",
			milRating = 1,
			feedbackLink = "http://zero-k.info/Forum/Thread/24530",
			text = "Learning from the Rebels, the Empire has placed its main Interception Network in a giant mountain range on a desert planet. This network was covering the entire sector and was the central piece of their war against the Rebels. If I can access it, I can download everything they had on the Rebels."
			,
			extendedText = "This battlefield is exceptionally mountainous. The defenders will field Spiders and I'd better do the same. If I want to force my way to the Interception Network, the Venom EMP and Hermit assault spiders are going to help."
		},
		tips = {
			{
				image = "unitpics/spiderassault.png",
				text = [[The Hermit isn't the strongest assault unit out there, but it is very cheap. The Hermit's plasma cannon is ballistic, so it has much longer range when firing down a hill.]]
			},
			{
				image = "unitpics/spideremp.png",
				text = [[Venom EMP spiders are very effective against raiders, and in large numbers they can even stunlock heavier units like Commanders. Hermits have a much easier time hitting enemies when they're held still by Venoms.]]
			},
			{
				image = "unitpics/spidercon.png",
				text = [[The Spider factory's Weaver constructors are slow, but they have high buildpower, all-terrain movement (obviously), and a short-range radar.]]
			},
		},
		gameConfig = {
			mapName = "Zion_v1",
			playerConfig = {
				startX = 2000,
				startZ = 3800,
				allyTeam = 0,
				facplop = false,
				commanderParameters = {
					facplop = false,
					victoryAtLocation = {
						x = 2048,
						z = 640,
						radius = 120,
						objectiveID = 1,
					},
					defeatIfDestroyedObjectiveID = 2,
				},
				extraUnlocks = {
					"factoryspider",
					"spidercon",
					"spiderassault",
					"spideremp",
					"spiderriot",
				},
				startUnits = {
					{
						name = "staticmex",
						x = 1832,
						z = 3992,
						facing = 0,
					},
 					{
						name = "staticmex",
						x = 2104,
						z = 4008,
						facing = 0,
					},
 					{
						name = "staticmex",
						x = 2344,
						z = 4024,
						facing = 0,
					},
 					{
						name = "energysolar",
						x = 2216,
						z = 4040,
						facing = 0,
					},
 					{
						name = "energysolar",
						x = 1960,
						z = 4024,
						facing = 0,
					},
 					{
						name = "factoryspider",
						x = 2408,
						z = 3864,
						facing = 2,
					},
 					{
						name = "staticcon",
						x = 2440,
						z = 3960,
						facing = 2,
						commands = {
							{cmdID = planetUtilities.COMMAND.PATROL, pos = {2440, 3960}},
							{cmdID = planetUtilities.COMMAND.PATROL, pos = {2415, 3935}, options = {"shift"}},
						},
					},
 					{
						name = "turretlaser",
						x = 2592,
						z = 3888,
						facing = 2,
					},
 					{
						name = "turretlaser",
						x = 2192,
						z = 3792,
						facing = 2,
					},
 					{
						name = "turretlaser",
						x = 1744,
						z = 3904,
						facing = 3,
					},
 					{
						name = "spideremp",
						x = 2483,
						z = 3593,
						facing = 2,
					},
 					{
						name = "spideremp",
						x = 2599,
						z = 3612,
						facing = 2,
					},
 					{
						name = "spiderassault",
						x = 2648,
						z = 3692,
						facing = 2,
					},
 					{
						name = "spiderassault",
						x = 2406,
						z = 3663,
						facing = 2,
					},
 					{
						name = "spidercon",
						x = 2516,
						z = 3685,
						facing = 2,
					},
 					{
						name = "energysolar",
						x = 2104,
						z = 3912,
						facing = 1,
					},
				}
			},
			aiConfig = {
				{
					startX = 2100,
					startZ = 200,
					--aiLib = "Null AI",
					--bitDependant = false,
					aiLib = "Circuit_difficulty_autofill",
					bitDependant = true,
					humanName = "Cliffwalkers",
					commanderParameters = {
						facplop = false,
						bonusObjectiveID = 3,
					},
					allyTeam = 1,
					unlocks = {
						"staticcon",
						"staticradar",
						"staticmex",
						"energysolar",
						"energywind",
						"turretmissile",
						"turretlaser",
						"factoryspider",
						"spidercon",
						"spiderassault",
						"spideremp",
					},
					difficultyDependantUnlocks = {
						[3] = {"spiderriot"},
						[4] = {"spiderriot","spiderscout",},
					},
					commanderLevel = 4,
					commander = {
						name = "Jaa Peros",
						chassis = "guardian",
						decorations = {
							"skin_bombard_steel",
						},
						modules = {
							"commweapon_beamlaser",
							"commweapon_beamlaser",
							"module_adv_targeting",
							"module_adv_targeting",
							"module_adv_targeting",
							"module_adv_targeting",
							"module_high_power_servos",
							"module_adv_targeting",
							"module_autorepair",
						}
					},
					startUnits = {
						 						{
							name = "staticmex",
							x = 2280,
							z = 120,
							facing = 0,
						},
 						{
							name = "staticmex",
							x = 2024,
							z = 120,
							facing = 0,
						},
 						{
							name = "staticmex",
							x = 1752,
							z = 136,
							facing = 0,
						},
 						{
							name = "energysolar",
							x = 1880,
							z = 104,
							facing = 0,
						},
 						{
							name = "energysolar",
							x = 2152,
							z = 88,
							facing = 0,
						},
 						{
							name = "factoryspider",
							x = 1624,
							z = 56,
							facing = 0,
						},
 						{
							name = "staticcon",
							x = 1736,
							z = 24,
							facing = 0,
						},
 						{
							name = "turretlaser",
							x = 1536,
							z = 272,
							facing = 3,
						},
 						{
							name = "turretlaser",
							x = 1920,
							z = 320,
							facing = 0,
						},
 						{
							name = "turretlaser",
							x = 2384,
							z = 160,
							facing = 1,
						},
 						{
							name = "spidercon",
							x = 1620,
							z = 387,
							facing = 0,
							difficultyAtLeast = 2,
						},
 						{
							name = "spideremp",
							x = 1671,
							z = 357,
							facing = 3,
						},
 						{
							name = "spiderassault",
							x = 1602,
							z = 292,
							facing = 0,
						},
						{
							name = "spideremp",
							x = 1736,
							z = 319,
							facing = 2,
							difficultyAtLeast = 2,
						},
 						{
							name = "spiderassault",
							x = 1665,
							z = 232,
							facing = 2,
							difficultyAtLeast = 2,
						},
 						{
							name = "energysolar",
							x = 2328,
							z = 40,
							facing = 1,
						},
						{
							name = "turretmissile",
							x = 2192,
							z = 720,
							facing = 0,
							terraformHeight = 287,
						},
 						{
							name = "turretmissile",
							x = 1920,
							z = 720,
							facing = 0,
						},
 						{
							name = "staticmex",
							x = 1080,
							z = 888,
							facing = 0,
							difficultyAtLeast = 3,
						},
 						{
							name = "energysolar",
							x = 1128,
							z = 968,
							facing = 0,
							difficultyAtLeast = 3,
						},
 						{
							name = "turretlaser",
							x = 1152,
							z = 880,
							facing = 0,
							difficultyAtLeast = 3,
						},
 						{
							name = "staticmex",
							x = 3096,
							z = 904,
							facing = 0,
							difficultyAtLeast = 4,
						},
 						{
							name = "energysolar",
							x = 3032,
							z = 1000,
							facing = 0,
							difficultyAtLeast = 4,
						},
 						{
							name = "turretlaser",
							x = 3008,
							z = 912,
							facing = 0,
							difficultyAtLeast = 4,
						},
					}
				},
			},
			neutralUnits = {
				{
					name = "pw_interception",
					x = 2048,
					z = 640,
					facing = 0,
					invincible = true,
					ignoredByAI = true,
					mapMarker = {
						text = "Interception Network",
						color = "green"
					},
				},
			},
			defeatConditionConfig = {
				-- Indexed by allyTeam.
				[0] = { },
				[1] = {
					ignoreUnitLossDefeat = true,
					loseAfterSeconds = false,
					allyTeamLossObjectiveID = 1,
				},
			},
			objectiveConfig = {
				-- This is just related to displaying objectives on the UI.
				[1] = {
					description = "Bring your Commander to the Interception Network",
				},
				[2] = {
					description = "Protect your Commander",
				},
			},
			bonusObjectiveConfig = {
				[1] = { -- Make twelve Hermits
					satisfyOnce = true,
					countRemovedUnits = true,
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 12,
					unitTypes = {
						"spiderassault",
					},
					image = planetUtilities.ICON_DIR .. "spiderassault.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.REPAIR,
					description = "Build 12 Hermits",
					experience = planetUtilities.BONUS_EXP,
				},
				[2] = {
					victoryByTime = 600,
					image = planetUtilities.ICON_OVERLAY.CLOCK,
					description = "Win by 10:00",
					experience = planetUtilities.BONUS_EXP,
				},
				[3] = { -- Kill enemy commander
					satisfyOnce = true,
					comparisionType = planetUtilities.COMPARE.AT_MOST,
					targetNumber = 0,
					-- See bonusObjectiveID in units table
					image = planetUtilities.ICON_DIR .. "skin_bombard_steel.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.ATTACK,
					description = "Destroy the enemy Commander",
					experience = planetUtilities.BONUS_EXP,
				},
			}
		},
		completionReward = {
			experience = planetUtilities.MAIN_EXP,
			units = {
				"spiderassault",
				"spideremp",
			},
			modules = {
				"module_adv_targeting_LIMIT_C_2",
			},
			abilities = {
			},
			codexEntries = {
				"faction_dynasty",
				"location_hastus",
			},
		},
	}
	
	return planetData
end

return GetPlanet
