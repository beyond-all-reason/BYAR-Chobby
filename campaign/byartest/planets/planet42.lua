--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Planet config

local function GetPlanet(planetUtilities, planetID)
	
	--local image = planetUtilities.planetImages[math.floor(math.random()*#planetUtilities.planetImages) + 1]
	local image = LUA_DIRNAME .. "images/planets/arid01.png"
	
	local planetData = {
		name = "Nanskar",
		startingPlanet = false,
		mapDisplay = {
			x = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][1]) or 0.53,
			y = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][2]) or 0.19,
			image = image,
			size = planetUtilities.PLANET_SIZE_MAP,
		},
		infoDisplay = {
			image = image,
			size = planetUtilities.PLANET_SIZE_INFO,
			backgroundImage = planetUtilities.backgroundImages[math.floor(math.random()*#planetUtilities.backgroundImages) + 1],
			terrainType = "Desert",
			radius = "4450 km",
			primary = "Zamuot",
			primaryType = "G0V",
			milRating = 1,
			feedbackLink = "http://zero-k.info/Forum/Thread/24489",
			text = "This desert planet had one of the greatest mountain ranges in the galaxy, before most of it was flattened by the Empire, as they tracked down fleeing Rebels hidden there. Imperial search parties are still there, looking for Rebels in what little is left of the range."
			.. "\n "
			.. "\nIf I can get rid of them, some Rebel holdout may answer to some of my scavenged codes. Who knows, they may still have useful data..."
			,
			extendedText = "I have taken control of a small search party, but only the sturdier Tanks are still working. Not ideal for this kind of terrain - especially with the other search party using Spiders."
			.. "\n "
			.. "\nTime to take a page from the previous users, and flatten the hills with Tremor heavy artillery. Then, I can finish the job with the super-heavy Cyclops assault tank."
		},
		tips = {
			{
				image = "unitpics/tankheavyarty.png",
				text = [[The Tremor heavy artillery is exceptionally inaccurate and will only hit any given unit by chance. On the other hand, it can fairly reliably hit a hill.]]
			},
			{
				image = "unitpics/tankheavyassault.png",
				text = [[The Cyclops super-heavy assault tank is even tougher than the Minotaur and also comes equipped with a medium-range slowbeam, which should prevent the enemy Spiders from escaping to the hills.]]
			},
			{
				image = "LuaUI/Images/commands/Bold/attack.png",
				text = [[The Tremor fires seismic shells which gradually smooth and flatten terrain. Half a minute of Force Firing at a hill will deprive spiders of a safe hiding place. Terrain modification is only visible in line of sight so remember to use spotters.]]
			},
		},
		gameConfig = {
			mapName = "Desert_Plateaus",
			playerConfig = {
				startX = 2040,
				startZ = 420,
				allyTeam = 0,
				commanderParameters = {
					facplop = false,
					defeatIfDestroyedObjectiveID = 2,
				},
				extraUnlocks = {
					"factorytank",
					"tankcon",
					"tankassault",
					"tankriot",
					"tankarty",
					"tankheavyassault",
					"tankheavyarty",
				},
				startUnits = {
					 					{
						name = "factorytank",
						x = 1872,
						z = 320,
						facing = 0,
					},
 					{
						name = "staticmex",
						x = 1464,
						z = 312,
						facing = 0,
					},
 					{
						name = "staticmex",
						x = 1784,
						z = 760,
						facing = 0,
					},
 					{
						name = "staticmex",
						x = 2280,
						z = 312,
						facing = 0,
					},
 					{
						name = "tankheavyarty",
						x = 1959,
						z = 484,
						facing = 0,
						commands = {
							{cmdID = planetUtilities.COMMAND.ATTACK, pos = {2700, 1200}},
						},
					},
 					{
						name = "tankheavyarty",
						x = 1784,
						z = 469,
						facing = 0,
						commands = {
							{cmdID = planetUtilities.COMMAND.ATTACK, pos = {1300, 1300}},
						},
					},
 					{
						name = "tankriot",
						x = 1941,
						z = 584,
						facing = 0,
					},
					{
						name = "tankriot",
						x = 1776,
						z = 585,
						facing = 0,
					},
					{
						name = "tankcon",
						x = 1868,
						z = 542,
						facing = 0,
					},
 					{
						name = "energysolar",
						x = 2344,
						z = 296,
						facing = 2,
					},
 					{
						name = "energysolar",
						x = 2280,
						z = 376,
						facing = 2,
					},
 					{
						name = "turretlaser",
						x = 2288,
						z = 272,
						facing = 1,
					},
 					{
						name = "energysolar",
						x = 1848,
						z = 808,
						facing = 1,
					},
 					{
						name = "energysolar",
						x = 1768,
						z = 824,
						facing = 1,
					},
 					{
						name = "energysolar",
						x = 1432,
						z = 376,
						facing = 1,
					},
 					{
						name = "energysolar",
						x = 1400,
						z = 296,
						facing = 1,
					},
 					{
						name = "turretlaser",
						x = 1824,
						z = 752,
						facing = 0,
					},
 					{
						name = "turretlaser",
						x = 1488,
						z = 352,
						facing = 3,
					},
 					{
						name = "staticcon",
						x = 2008,
						z = 280,
						facing = 0,
						commands = {
							{cmdID = planetUtilities.COMMAND.PATROL, pos = {2008, 280}},
							{cmdID = planetUtilities.COMMAND.PATROL, pos = {2033, 305}, options = {"shift"}},
						},
					},
 					{
						name = "staticradar",
						x = 1936,
						z = 224,
						facing = 2,
					},
				}
			},
			aiConfig = {
				{
					startX = 4600,
					startZ = 4400,
					aiLib = "Circuit_difficulty_autofill",
					bitDependant = true,
					--aiLib = "Null AI",
					--bitDependant = false,
					humanName = "Lurkers",
					commanderParameters = {
						facplop = false,
					},
					allyTeam = 1,
					unlocks = {
						"staticradar",
						"staticstorage",
						"staticmex",
						"energysolar",
						"energywind",
						"energypylon",
						"staticcon",
						"turretlaser",
						"turretmissile",
						"turretheavylaserlaser",
						"turretriot",
						"turretaalaser",
						"turretaaclose",
						"spidercon",
						"spiderscout",
						"spideremp",
						"spiderriot",
						"spiderassault",
						"spiderskirm",
						"spidercrabe",
						"spideraa",
					},
					difficultyDependantUnlocks = {
						[3] = {"spiderantiheavy"},
						[4] = {"spiderantiheavy"},
					},
					commanderLevel = 5,
					commander = {
						name = "Dory",
						chassis = "recon",
						decorations = {
						},
						modules = {
							"commweapon_shotgun",
							"commweapon_concussion",
							"module_heavy_armor",
							"module_heavy_armor",
							"module_autorepair",
							"module_autorepair",
							"commweapon_personal_shield",
							"module_dmg_booster",
							"module_dmg_booster",
							"module_high_power_servos",
							"module_high_power_servos",
							"module_high_power_servos",
						}
					},
					startUnits = {
						{
							name = "staticmex",
							x = 3480,
							z = 4840,
							facing = 3,
						},
						{
							name = "staticmex",
							x = 2990,
							z = 4330,
							facing = 3,
							difficultyAtLeast = 2,
						},
						{
							name = "staticmex",
							x = 4200,
							z = 3500,
							facing = 3,
							difficultyAtLeast = 3,
						},
						{
							name = "staticmex",
							x = 2360,
							z = 4824,
							facing = 3,
							difficultyAtLeast = 4,
						},
						{
							name = "staticmex",
							x = 1030,
							z = 4888,
							facing = 3,
							difficultyAtLeast = 4,
						},
						{
							name = "staticmex",
							x = 220,
							z = 4840,
							facing = 3,
							difficultyAtLeast = 4,
						},
						{
							name = "turretheavylaser",
							x = 875,
							z = 4270,
							facing = 2,
							difficultyAtLeast = 4,
						},
						{
							name = "turretriot",
							x = 4472,
							z = 3800,
							facing = 2,
						},
 						{
							name = "turretheavylaser",
							x = 2248,
							z = 4536,
							facing = 3,
						},
 						{
							name = "staticheavyradar",
							x = 3920,
							z = 4320,
							facing = 2,
							terraformHeight = 436,
						},
 						{
							name = "turretheavylaser",
							x = 4136,
							z = 3560,
							facing = 3,
						},
 						{
							name = "turretheavylaser",
							x = 4840,
							z = 3288,
							facing = 2,
						},
 						{
							name = "energypylon",
							x = 4632,
							z = 3784,
							facing = 2,
						},
 						{
							name = "energyfusion",
							x = 5080,
							z = 5088,
							facing = 2,
						},
 						{
							name = "energyfusion",
							x = 5080,
							z = 5024,
							facing = 2,
						},
 						{
							name = "staticmex",
							x = 4760,
							z = 4632,
							facing = 2,
						},
 						{
							name = "energypylon",
							x = 4520,
							z = 4744,
							facing = 0,
						},
 						{
							name = "energypylon",
							x = 3528,
							z = 4744,
							facing = 0,
						},
 						{
							name = "energypylon",
							x = 2744,
							z = 4728,
							facing = 0,
						},
 						{
							name = "factoryspider",
							x = 4536,
							z = 4552,
							facing = 3,
						},
 						{
							name = "turretriot",
							x = 3672,
							z = 3832,
							facing = 2,
						},
 						{
							name = "turretheavylaser",
							x = 3096,
							z = 4328,
							facing = 2,
						},
 						{
							name = "turretaaflak",
							x = 2696,
							z = 4568,
							facing = 2,
						},
 						{
							name = "turretriot",
							x = 2664,
							z = 4456,
							facing = 2,
						},
 						{
							name = "spiderscout",
							x = 4199,
							z = 4468,
							facing = 3,
						},
 						{
							name = "turretaaflak",
							x = 3816,
							z = 4200,
							facing = 2,
						},
 						{
							name = "spiderscout",
							x = 4283,
							z = 4354,
							facing = 2,
						},
 						{
							name = "spiderscout",
							x = 4230,
							z = 4426,
							facing = 3,
						},
 						{
							name = "spiderscout",
							x = 4309,
							z = 4322,
							facing = 2,
						},
 						{
							name = "spiderscout",
							x = 4228,
							z = 4389,
							facing = 3,
						},
 						{
							name = "spiderscout",
							x = 4164,
							z = 4506,
							facing = 3,
						},
 						{
							name = "spiderscout",
							x = 4350,
							z = 4209,
							facing = 2,
						},
 						{
							name = "spiderscout",
							x = 4086,
							z = 4624,
							facing = 3,
						},
 						{
							name = "spiderscout",
							x = 4332,
							z = 4279,
							facing = 2,
						},
 						{
							name = "spiderscout",
							x = 4146,
							z = 4544,
							facing = 3,
						},
 						{
							name = "spiderscout",
							x = 4117,
							z = 4591,
							facing = 3,
						},
 						{
							name = "spiderskirm",
							x = 4202,
							z = 4591,
							facing = 0,
						},
 						{
							name = "spiderskirm",
							x = 4263,
							z = 4566,
							facing = 3,
						},
 						{
							name = "spiderriot",
							x = 4422,
							z = 4378,
							facing = 0,
						},
 						{
							name = "spiderriot",
							x = 4372,
							z = 4414,
							facing = 3,
						},
 						{
							name = "spideremp",
							x = 4407,
							z = 4466,
							facing = 2,
						},
 						{
							name = "spideremp",
							x = 4371,
							z = 4502,
							facing = 2,
						},
 						{
							name = "spiderassault",
							x = 4295,
							z = 4679,
							facing = 3,
						},
 						{
							name = "spiderassault",
							x = 4357,
							z = 4628,
							facing = 3,
						},
 						{
							name = "spiderskirm",
							x = 4171,
							z = 4635,
							facing = 3,
						},
 						{
							name = "turretaaflak",
							x = 4568,
							z = 3672,
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
						"factoryspider",
					},
					loseAfterSeconds = false,
					allyTeamLossObjectiveID = 1,
				},
			},
			objectiveConfig = {
				-- This is just related to displaying objectives on the UI.
				[1] = {
					description = "Destroy the enemy Commander and Spider Factory",
				},
				[2] = {
					description = "Protect your Commander",
				},
			},
			bonusObjectiveConfig = {
				[1] = { -- Have two Goliath
					satisfyOnce = true,
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 2,
					unitTypes = {
						"tankheavyassault",
					},
					image = planetUtilities.ICON_DIR .. "tankheavyassault.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.REPAIR,
					description = "Have two Cyclops tanks",
					experience = planetUtilities.BONUS_EXP,
				},
				[2] = { -- Don't lose any Tremors
					satisfyForever = true,
					failOnUnitLoss = true, -- Fails the objective if any units being used to satisfy the objective are lost.
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 0,
					unitTypes = {
						"tankheavyarty",
					},
					image = planetUtilities.ICON_DIR .. "tankheavyarty.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.GUARD,
					description = "Don't lose any Tremors",
					experience = planetUtilities.BONUS_EXP,
				},
				[3] = {
					victoryByTime = 600,
					image = planetUtilities.ICON_OVERLAY.CLOCK,
					description = "Win by 10:00",
					experience = planetUtilities.BONUS_EXP,
				},
			}
		},
		completionReward = {
			experience = planetUtilities.MAIN_EXP,
			units = {
				"tankheavyassault",
				"tankheavyarty",
			},
			modules = {
				"module_heavy_armor_LIMIT_C_2",
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
