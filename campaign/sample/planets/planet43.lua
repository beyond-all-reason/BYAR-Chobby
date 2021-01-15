--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Planet config

local function GetPlanet(planetUtilities, planetID)
	
	local image = LUA_DIRNAME .. "images/planets/tundra02.png"
	
	local planetData = {
		name = "Estann All",
		startingPlanet = false,
		mapDisplay = {
			x = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][1]) or 0.41,
			y = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][2]) or 0.30,
			image = image,
			size = planetUtilities.PLANET_SIZE_MAP,
		},
		infoDisplay = {
			image = image,
			size = planetUtilities.PLANET_SIZE_INFO,
			backgroundImage = planetUtilities.backgroundImages[math.floor(math.random()*#planetUtilities.backgroundImages) + 1],
			terrainType = "Artificial",
			radius = "3433.854 km",
			primary = "Doyaz",
			primaryType = "F3VII",
			milRating = 1,
			feedbackLink = "http://zero-k.info/Forum/Thread/24457",
			text = "This planet is covered by a sprawling metropolis, built by nano-machines, with nobody left to turn them off. I would have preferred avoiding such a place, but there is something down there, something older than the nanites."
			.. "\n "
			.. "\nIf I am fast enough, I should be able to recover whatever it is and get out of there before the nanites become too much of a problem."
			,
			extendedText = "Any destroyed units or buildings will be rebuilt by the nanites, but they will be hostile to everyone. I will have to hold off the 'zombies' for long enough to go through any existing defenses and reach the Artefact."
		},
		tips = {
			{
				image = "unitpics/module_resurrect.png",
				text = [[In this mission, any wrecked units will eventually become alive again, as slower 'zombie' versions of themselves. The zombies will be hostile to all players. Reclaim or destroy the wrecks to prevent this from happening.]]
			},
			{
				image = "unitpics/turretemp.png",
				text = [[The Faraday EMP turret can stun most enemy units (especially when built in groups) but cannot deal any direct damage. Have a few other turrets or units standing by to clean up.]]
			},
			{
				image = "unitpics/turretaaflak.png",
				text = [[The Thresher Flak AA turret will make short work of any light flying units. It is especially effective against large groups of fliers.]]
			},
		},
		gameConfig = {
			mapName = "Intersection v4.1",
			
			modoptions = {
				zombies = 1,
				zombies_delay = 10,
				zombies_rezspeed = 100,
				zombies_permaslow = 1,
				zombies_partial_reclaim = 1,
			},
			
			playerConfig = {
				startX = 4600,
				startZ = 4600,
				allyTeam = 0,
				commanderParameters = {
					facplop = true,
					defeatIfDestroyedObjectiveID = 2,
					victoryAtLocation = {
						x = 1680,
						z = 1680,
						radius = 80,
						objectiveID = 1,
					},
				},
				extraUnlocks = {
					"turretemp",
					"turretaaflak",
				},
				startUnits = {
					{
						name = "staticcon",
						x = 4300,
						z = 4300,
						facing = 2,
						selfPatrol = true,
					},
					{
						name = "turretemp",
						x = 4688,
						z = 4112,
						facing = 2,
					},
 					{
						name = "turretemp",
						x = 4128,
						z = 4112,
						facing = 2,
					},
 					{
						name = "turretemp",
						x = 4112,
						z = 4736,
						facing = 3,
					},
 					{
						name = "turretlaser",
						x = 4112,
						z = 4448,
						facing = 3,
					},
 					{
						name = "turretlaser",
						x = 4416,
						z = 4112,
						facing = 2,
					},
 					{
						name = "turretaaflak",
						x = 4312,
						z = 4600,
						facing = 3,
					},
 					{
						name = "turretaaflak",
						x = 4584,
						z = 4312,
						facing = 2,
					},
 					{
						name = "staticmex",
						x = 4360,
						z = 4360,
						facing = 2,
					},
 					{
						name = "staticmex",
						x = 4360,
						z = 4856,
						facing = 2,
					},
 					{
						name = "staticmex",
						x = 4872,
						z = 4856,
						facing = 2,
					},
 					{
						name = "staticmex",
						x = 4872,
						z = 4344,
						facing = 2,
					},
 					{
						name = "energywind",
						x = 4936,
						z = 4408,
						facing = 2,
					},
 					{
						name = "energywind",
						x = 4936,
						z = 4488,
						facing = 2,
					},
 					{
						name = "energywind",
						x = 4936,
						z = 4568,
						facing = 2,
					},
 					{
						name = "energywind",
						x = 4936,
						z = 4648,
						facing = 2,
					},
 					{
						name = "energywind",
						x = 4936,
						z = 4728,
						facing = 2,
					},
 					{
						name = "energywind",
						x = 4936,
						z = 4808,
						facing = 2,
					},
 					{
						name = "energywind",
						x = 4808,
						z = 4904,
						facing = 2,
					},
 					{
						name = "energywind",
						x = 4728,
						z = 4904,
						facing = 2,
					},
 					{
						name = "energywind",
						x = 4648,
						z = 4904,
						facing = 2,
					},
 					{
						name = "energywind",
						x = 4568,
						z = 4904,
						facing = 2,
					},
 					{
						name = "energywind",
						x = 4488,
						z = 4904,
						facing = 2,
					},
 					{
						name = "energywind",
						x = 4408,
						z = 4904,
						facing = 2,
					},
 					{
						name = "staticradar",
						x = 4160,
						z = 4160,
						facing = 0,
					},
				}
			},
			aiConfig = {
				{
					startX = 100,
					startZ = 100,
					humanName = "Paolaza",
					--aiLib = "Null AI",
					--bitDependant = false,
					aiLib = "Circuit_difficulty_autofill",
					bitDependant = true,
					commanderParameters = {
						facplop = false,
					},
					allyTeam = 1,
					unlocks = {
						"staticcon",
						"staticmex",
						"energysolar",
						"staticradar",
						"shieldcon",
						"shieldraid",
						"shieldriot",
						"shieldassault",
						"shieldskirm",
					},
					commanderLevel = 3,
					commander = {
						name = "Mors",
						chassis = "recon",
						decorations = {
							"skin_recon_dark",
							"commweapon_flamethrower",
							"commweapon_napalmgrenade",
							"module_ablative_armor",
							"module_ablative_armor",
							"module_autorepair",
							"module_autorepair",
						},
						modules = { }
					},
					startUnits = {
						
						{
							name = "turretemp",
							x = 1562,
							z = 1562,
							facing = 0,
						},
						{
							name = "turretemp",
							x = 1920,
							z = 1664,
							facing = 1,
							difficultyAtLeast = 3,
						},
						{
							name = "turretemp",
							x = 1152,
							z = 1920,
							facing = 1,
							difficultyAtLeast = 4,
						},
						{
							name = "turretemp",
							x = 1920,
							z = 1152,
							facing = 1,
							difficultyAtLeast = 4,
						},
						{
							name = "staticmex",
							x = 264,
							z = 744,
							facing = 2,
						},
 						{
							name = "staticmex",
							x = 264,
							z = 264,
							facing = 1,
						},
 						{
							name = "staticmex",
							x = 760,
							z = 264,
							facing = 1,
						},
						{
							name = "turretriot",
							x = 1700,
							z = 2130,
							facing = 0,
							terraformHeight = 90,
						},
						{
							name = "turretriot",
							x = 2130,
							z = 1700,
							facing = 1,
							terraformHeight = 90,
						},
 						{
							name = "turretriot",
							x = 1000,
							z = 824,
							facing = 1,
							terraformHeight = 346,
						},
						{
							name = "turretemp",
							x = 1000,
							z = 680,
							facing = 1,
						},
						{
							name = "turretriot",
							x = 1000,
							z = 536,
							facing = 1,
							terraformHeight = 345,
						},
 						{
							name = "turretriot",
							x = 536,
							z = 1000,
							facing = 0,
							terraformHeight = 346,
						},
						{
							name = "turretemp",
							x = 680,
							z = 1000,
							facing = 0,
						},
 						{
							name = "turretriot",
							x = 840,
							z = 1000,
							facing = 0,
							terraformHeight = 346,
						},
 						{
							name = "staticmex",
							x = 776,
							z = 760,
							facing = 1,
						},
 						{
							name = "energysolar",
							x = 680,
							z = 200,
							facing = 1,
						},
 						{
							name = "energysolar",
							x = 568,
							z = 200,
							facing = 1,
						},
 						{
							name = "turretaalaser",
							x = 1000,
							z = 1000,
							facing = 1,
						},
 						{
							name = "turretaalaser",
							x = 392,
							z = 1000,
							facing = 0,
						},
 						{
							name = "turretaalaser",
							x = 1000,
							z = 392,
							facing = 1,
						},
 						{
							name = "energysolar",
							x = 184,
							z = 680,
							facing = 1,
						},
 						{
							name = "energysolar",
							x = 184,
							z = 568,
							facing = 1,
						},
 						{
							name = "energysolar",
							x = 184,
							z = 456,
							facing = 1,
						},
 						{
							name = "energysolar",
							x = 184,
							z = 344,
							facing = 1,
						},
 						{
							name = "energysolar",
							x = 344,
							z = 200,
							facing = 1,
						},
 						{
							name = "energysolar",
							x = 456,
							z = 200,
							facing = 1,
						},
 						{
							name = "factoryshield",
							x = 536,
							z = 512,
							facing = 1,
						},
 						{
							name = "staticcon",
							x = 408,
							z = 504,
							facing = 1,
							commands = {
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {408, 504}},
								{cmdID = planetUtilities.COMMAND.PATROL, pos = {433, 529}, options = {"shift"}},
							},
						},
 						{
							name = "turretheavylaser",
							x = 1896,
							z = 1896,
							facing = 1,
						},
 						{
							name = "turretlaser",
							x = 1792,
							z = 1920,
							facing = 0,
						},
 						{
							name = "turretlaser",
							x = 1408,
							z = 1920,
							facing = 0,
						},
						{
							name = "turretlaser",
							x = 1920,
							z = 1408,
							facing = 1,
						},
 						{
							name = "turretaaflak",
							x = 1464,
							z = 1464,
							facing = 0,
						},
 						{
							name = "turretheavylaser",
							x = 1664,
							z = 1152,
							facing = 1,
						},
						{
							name = "turretheavylaser",
							x = 1152,
							z = 1664,
							facing = 0,
						},
					}
				},
			},
			neutralUnits = {
				{
					name = "pw_artefact",
					x = 1680,
					z = 1680,
					facing = 0,
					invincible = true,
					ignoredByAI = true,
					mapMarker = {
						text = "Artefact",
						color = "green"
					},
				},
			},
			initialWrecks = {
				{
					name = "staticmex_dead",
					x = 4872,
					z = 248,
					facing = 0,
				},
				{
					name = "staticmex_dead",
					x = 3832,
					z = 776,
					facing = 0,
				},
				{
					name = "staticmex_dead",
					x = 4360,
					z = 1288,
					facing = 0,
				},
				{
					name = "staticmex_dead",
					x = 3320,
					z = 1800,
					facing = 0,
				},
				{
					name = "staticmex_dead",
					x = 2568,
					z = 2568,
					facing = 0,
				},
				{
					name = "staticmex_dead",
					x = 1784,
					z = 3336,
					facing = 0,
				},
				{
					name = "staticmex_dead",
					x = 1288,
					z = 4360,
					facing = 0,
				},
				{
					name = "staticmex_dead",
					x = 264,
					z = 4872,
					facing = 0,
				},
				{
					name = "staticmex_dead",
					x = 760,
					z = 3832,
					facing = 0,
				},
				{
					name = "energysolar_dead",
					x = 4936,
					z = 264,
					facing = 3,
				},
				{
					name = "energysolar_dead",
					x = 328,
					z = 4888,
					facing = 3,
				},
				{
					name = "energysolar_dead",
					x = 4856,
					z = 312,
					facing = 2,
				},
				{
					name = "energysolar_dead",
					x = 4808,
					z = 232,
					facing = 1,
				},
				{
					name = "energysolar_dead",
					x = 248,
					z = 4936,
					facing = 2,
				},
				{
					name = "energysolar_dead",
					x = 200,
					z = 4856,
					facing = 1,
				},
				{
					name = "energysolar_dead",
					x = 4888,
					z = 184,
					facing = 0,
				},
				{
					name = "energysolar_dead",
					x = 280,
					z = 4808,
					facing = 0,
				},
				{
					name = "staticstorage_dead",
					x = 5032,
					z = 136,
					facing = 0,
				},
				{
					name = "staticstorage_dead",
					x = 120,
					z = 5000,
					facing = 0,
				},
				{
					name = "factorygunship_dead",
					x = 584,
					z = 4536,
					facing = 0,
				},
				{
					name = "factorytank_dead",
					x = 4400,
					z = 1008,
					facing = 0,
				},
				{
					name = "turretlaser_dead",
					x = 4880,
					z = 1120,
					facing = 0,
				},
				{
					name = "turretriot_dead",
					x = 4344,
					z = 1528,
					facing = 0,
				},
				{
					name = "turretmissile_dead",
					x = 3600,
					z = 912,
					facing = 3,
				},
				{
					name = "turretmissile_dead",
					x = 3600,
					z = 656,
					facing = 3,
				},
				{
					name = "energysolar_dead",
					x = 4520,
					z = 904,
					facing = 3,
				},
				{
					name = "energysolar_dead",
					x = 4280,
					z = 904,
					facing = 3,
				},
				{
					name = "energywind_dead",
					x = 4392,
					z = 904,
					facing = 3,
				},
				{
					name = "energysolar_dead",
					x = 888,
					z = 3880,
					facing = 3,
				},
				{
					name = "energysolar_dead",
					x = 1384,
					z = 4296,
					facing = 3,
				},
				{
					name = "staticradar_dead",
					x = 2864,
					z = 1840,
					facing = 3,
				},
				{
					name = "turretlaser_dead",
					x = 3264,
					z = 1936,
					facing = 0,
				},
				{
					name = "turretemp_dead",
					x = 1536,
					z = 4416,
					facing = 1,
				},
				{
					name = "turretlaser_dead",
					x = 1520,
					z = 4192,
					facing = 1,
				},
				{
					name = "turretmissile_dead",
					x = 2672,
					z = 2560,
					facing = 0,
				},
				{
					name = "turretaaclose_dead",
					x = 1032,
					z = 3896,
					facing = 1,
				},
				{
					name = "turretlaser_dead",
					x = 976,
					z = 3632,
					facing = 2,
				},
				{
					name = "turretriot_dead",
					x = 1880,
					z = 3272,
					facing = 0,
				},
				{
					name = "turretlaser_dead",
					x = 256,
					z = 4080,
					facing = 2,
				},
				{
					name = "turretmissile_dead",
					x = 1040,
					z = 4864,
					facing = 3,
				},
				{
					name = "turretmissile_dead",
					x = 4080,
					z = 96,
					facing = 3,
				},
				{
					name = "turretmissile_dead",
					x = 4080,
					z = 304,
					facing = 3,
				},
				{
					name = "tankassault_dead",
					x = 4301,
					z = 3600,
					facing = 0,
				},
				{
					name = "shieldraid_dead",
					x = 4224,
					z = 3555,
					facing = 0,
				},
				{
					name = "shieldraid_dead",
					x = 4547,
					z = 3630,
					facing = 0,
				},
				{
					name = "shieldraid_dead",
					x = 2254,
					z = 4457,
					facing = 0,
				},
				{
					name = "shieldraid_dead",
					x = 2450,
					z = 4195,
					facing = 0,
				},
				{
					name = "shieldraid_dead",
					x = 3077,
					z = 1491,
					facing = 0,
				},
				{
					name = "shieldraid_dead",
					x = 3414,
					z = 1539,
					facing = 0,
				},
				{
					name = "shieldraid_dead",
					x = 423,
					z = 2894,
					facing = 0,
				},
				{
					name = "tankriot_dead",
					x = 1529,
					z = 3278,
					facing = 0,
				},
				{
					name = "tankassault_dead",
					x = 2807,
					z = 2177,
					facing = 0,
				},
				{
					name = "gunshipraid_dead",
					x = 537,
					z = 3711,
					facing = 0,
				},
				{
					name = "gunshipraid_dead",
					x = 4675,
					z = 589,
					facing = 0,
				},
			},
			terraform = {
				{
					terraformShape = planetUtilities.TERRAFORM_SHAPE.RECTANGLE,
					terraformType = planetUtilities.TERRAFORM_TYPE.LEVEL,
					position = {1536, 2000, 2032, 2048},
					height = 2,
				},
				{
					terraformShape = planetUtilities.TERRAFORM_SHAPE.RECTANGLE,
					terraformType = planetUtilities.TERRAFORM_TYPE.LEVEL,
					position = {2000, 1536, 2048, 2032},
					height = 2,
				},
				{
					terraformShape = planetUtilities.TERRAFORM_SHAPE.RECTANGLE,
					terraformType = planetUtilities.TERRAFORM_TYPE.LEVEL,
					position = {1536, 1760, 1584, 2032},
					height = 2,
				},
				{
					terraformShape = planetUtilities.TERRAFORM_SHAPE.RECTANGLE,
					terraformType = planetUtilities.TERRAFORM_TYPE.LEVEL,
					position = {1760, 1536, 2032, 1584},
					height = 2,
				},
				{
					terraformShape = planetUtilities.TERRAFORM_SHAPE.RECTANGLE,
					terraformType = planetUtilities.TERRAFORM_TYPE.LEVEL,
					position = {1330, 1760, 1570, 1808},
					height = 2,
				},
				{
					terraformShape = planetUtilities.TERRAFORM_SHAPE.RECTANGLE,
					terraformType = planetUtilities.TERRAFORM_TYPE.LEVEL,
					position = {1760, 1330, 1808, 1570},
					height = 2,
				},
			},
			defeatConditionConfig = {
				[0] = { },
				[1] = {
					ignoreUnitLossDefeat = true,
					loseAfterSeconds = false,
				},
			},
			objectiveConfig = {
				[1] = {
					description = "Bring your Commander to the Artefact",
				},
				[2] = {
					description = "Protect your Commander",
				},
			},
			bonusObjectiveConfig = {
				[1] = { -- Win by 10:00
					victoryByTime = 600,
					image = planetUtilities.ICON_OVERLAY.CLOCK,
					description = "Win by 10:00",
					experience = planetUtilities.BONUS_EXP,
				},
				[2] = { -- Have 16 mex
					satisfyOnce = true,
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 16,
					unitTypes = {
						"staticmex",
					},
					image = planetUtilities.ICON_DIR .. "staticmex.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.REPAIR,
					description = "Have 16 Metal Extractors",
					experience = planetUtilities.BONUS_EXP,
				},
				[3] = { -- Complete all bonus objectives
					completeAllBonusObjectives = true,
					image = planetUtilities.ICON_OVERLAY.ALL,
					description = "Complete all bonus objectives (in one battle).",
					experience = planetUtilities.BONUS_EXP,
				},
			}
		},
		completionReward = {
			experience = planetUtilities.MAIN_EXP,
			units = {
				"turretemp",
				"turretaaflak",
			},
			modules = {
				"module_dmg_booster_LIMIT_B_2",
			},
			abilities = {
			},
			codexEntries = {
				"threat_zombies",
				"anomaly_estann_all",
			}
		},
	}
	
	return planetData
end

return GetPlanet
