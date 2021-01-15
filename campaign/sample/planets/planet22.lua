--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Planet config

local function GetPlanet(planetUtilities, planetID)
	
	--local image = planetUtilities.planetImages[math.floor(math.random()*#planetUtilities.planetImages) + 1]
	local image = LUA_DIRNAME .. "images/planets/tundra01.png"
	
	local planetData = {
		name = "Blackmire",
		startingPlanet = false,
		mapDisplay = {
			x = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][1]) or 0.35,
			y = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][2]) or 0.80,
			image = image,
			size = planetUtilities.PLANET_SIZE_MAP,
		},
		infoDisplay = {
			image = image,
			size = planetUtilities.PLANET_SIZE_INFO,
			backgroundImage = planetUtilities.backgroundImages[math.floor(math.random()*#planetUtilities.backgroundImages) + 1],
			terrainType = "Arctic",
			radius = "3430 km",
			primary = "Tsuz",
			primaryType = "F3V",
			milRating = 1,
			feedbackLink = "http://zero-k.info/Forum/Thread/24469",
			text = "Whoever named this near-frozen iceball Blackmire had a weird sense of humour, or something went very wrong with terraforming efforts. Probably the latter, given how many layers of battle damage are buried below all that snow."
			,
			extendedText = "Despite the ever-prevalent snow, those equatorial ranges still have unfrozen bodies of water. It would be a problem for most factories, but the Amphbot Factory can take advantage of them instead."
		},
		tips = {
			{
				image = "unitpics/amphfloater.png",
				text = [[Amphibious units walk on the land beneath the water, and regenerate HP while underwater. Buoys surface to fire their disruption cannon.]]
			},
			{
				image = "unitpics/amphimpulse.png",
				text = [[Archers fire water jets which push enemy units away. If a non-amphibious unit is pushed into water it will become helpless - keep this in mind!]]
			},
			{
				image = "unitpics/amphbomb.png",
				text = [[The Limpet does not float, but its large disruption pulse can reach surface targets even from the seafloor. The Limpet's explosion does not damage or slow friendly units, so it is safer to use than other bombs.]]
			},
		},
		gameConfig = {
			mapName = "Iced Coffee v4.3",
			playerConfig = {
				startX = 2830,
				startZ = 3625,
				allyTeam = 0,
				commanderParameters = {
					facplop = false,
					defeatIfDestroyedObjectiveID = 2,
				},
				extraUnlocks = {
					"factoryamph",
					"amphcon",
					"amphimpulse",
					"amphbomb",
					"amphfloater",
					"turrettorp",
				},
				startUnits = {
					{
						name = "factoryamph",
						x = 2680,
						z = 3592,
						facing = 2,
					},
					{
						name = "staticmex",
						x = 2392,
						z = 3736,
						facing = 0,
					},
					{
						name = "staticmex",
						x = 2872,
						z = 3192,
						facing = 0,
					},
					{
						name = "staticmex",
						x = 3560,
						z = 3976,
						facing = 0,
					},
					{
						name = "staticmex",
						x = 3928,
						z = 3784,
						facing = 0,
					},
					{
						name = "turretlaser",
						x = 3712,
						z = 3072,
						facing = 2,
					},
					{
						name = "turretlaser",
						x = 2624,
						z = 3008,
						facing = 2,
					},
					{
						name = "energywind",
						x = 3272,
						z = 3128,
						facing = 0,
					},
					{
						name = "energywind",
						x = 3256,
						z = 3000,
						facing = 0,
					},
					{
						name = "energywind",
						x = 3192,
						z = 2952,
						facing = 0,
					},
					{
						name = "energywind",
						x = 3304,
						z = 3064,
						facing = 0,
					},
					{
						name = "energywind",
						x = 3160,
						z = 2856,
						facing = 0,
					},
					{
						name = "amphimpulse",
						x = 2732,
						z = 3433,
						facing = 0,
					},
					{
						name = "amphimpulse",
						x = 2855,
						z = 3440,
						facing = 0,
					},
				}
			},
			aiConfig = {
				{
					startX = 1530,
					startZ = 470,
					--aiLib = "Null AI",
					--bitDependant = false,
					aiLib = "Circuit_difficulty_autofill",
					bitDependant = true,
					humanName = "Furious",
					commanderParameters = {
						facplop = false,
					},
					allyTeam = 1,
					unlocks = {
						"staticmex",
						"staticstorage",
						"energysolar",
						"energywind",
						"staticradar",
						"vehcon",
						"vehraid",
						"vehriot",
						"vehassault",
						"vehsupport",
					},
					difficultyDependantUnlocks = {
						 [2] = {"veharty"},
						 [3] = {"veharty","staticcon"},
						 [4] = {"veharty","staticcon","turretlaser"},
					},
					commanderLevel = 3,
					commander = {
						name = "Hydrophobe",
						chassis = "recon",
						decorations = {
						  "skin_recon_red",
						  icon_overhead = { image = "UW" }
						},
						modules = {
							"commweapon_flamethrower",
							"module_dmg_booster",
							"module_high_power_servos",
							"module_heavy_armor",
						}
					},
					startUnits = {
						{
							name = "staticmex",
							x = 1226,
							z = 902,
							facing = 0,
							difficultyAtLeast = 2,
						},
						{
							name = "turretriot",
							x = 1610,
							z = 1250,
							facing = 0,
							difficultyAtLeast = 2,
						},
						{
							name = "staticcon",
							x = 1270,
							z = 370,
							facing = 0,
							difficultyAtLeast = 2,
						},
						{
							name = "staticmex",
							x = 536,
							z = 136,
							facing = 0,
							difficultyAtLeast = 3,
						},
						{
							name = "staticmex",
							x = 166,
							z = 326,
							facing = 0,
							difficultyAtLeast = 3,
						},
						{
							name = "energysolar",
							x = 240,
							z = 200,
							facing = 0,
							difficultyAtLeast = 3,
						},
						{
							name = "energysolar",
							x = 415,
							z = 120,
							facing = 0,
							difficultyAtLeast = 3,
						},
						{
							name = "turretriot",
							x = 1115,
							z = 820,
							facing = 0,
							difficultyAtLeast = 3,
						},
						{
							name = "staticmex",
							x = 182,
							z = 2054,
							facing = 0,
							difficultyAtLeast = 4,
						},
						{
							name = "energyfusion",
							x = 2346,
							z = 560,
							facing = 0,
							difficultyAtLeast = 4,
						},
						{
							name = "turretheavylaser",
							x = 540,
							z = 2090,
							facing = 1,
							difficultyAtLeast = 4,
						},
						{
							name = "turretriot",
							x = 520,
							z = 2200,
							facing = 0,
							difficultyAtLeast = 4,
						},
						{
							name = "turretriot",
							x = 2170,
							z = 850,
							facing = 0,
							difficultyAtLeast = 4,
						},
						{
							name = "staticcon",
							x = 1400,
							z = 370,
							facing = 0,
							difficultyAtLeast = 4,
						},
						{
							name = "factoryveh",
							x = 1320,
							z = 520,
							facing = 0,
						},
						{
							name = "turretaaclose",
							x = 1100,
							z = 520,
							facing = 0,
						},
						{
							name = "turretaaclose",
							x = 1320,
							z = 300,
							facing = 0,
						},
						{
							name = "turretaalaser",
							x = 2350,
							z = 890,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 2312,
							z = 712,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 2312,
							z = 712,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 1704,
							z = 376,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 2600,
							z = 888,
							facing = 0,
						},
						{
							name = "turretlaser",
							x = 2416,
							z = 336,
							facing = 2,
						},
						{
							name = "turretlaser",
							x = 2624,
							z = 464,
							facing = 2,
						},
						{
							name = "staticmex",
							x = 2600,
							z = 616,
							facing = 0,
						},
						{
							name = "turretheavylaser",
							x = 1416,
							z = 1144,
							facing = 0,
						},
						{
							name = "energywind",
							x = 2376,
							z = 696,
							facing = 0,
						},
						{
							name = "energywind",
							x = 2456,
							z = 680,
							facing = 0,
						},
						{
							name = "energywind",
							x = 2520,
							z = 648,
							facing = 0,
						},
						{
							name = "energywind",
							x = 2504,
							z = 760,
							facing = 0,
						},
						{
							name = "energywind",
							x = 2536,
							z = 808,
							facing = 0,
						},
						{
							name = "energywind",
							x = 1960,
							z = 1032,
							facing = 0,
						},
						{
							name = "energywind",
							x = 2056,
							z = 1048,
							facing = 0,
						},
						{
							name = "energywind",
							x = 1928,
							z = 1128,
							facing = 0,
						},
						{
							name = "turretlaser",
							x = 1904,
							z = 1312,
							facing = 0,
						},
						{
							name = "turretlaser",
							x = 464,
							z = 400,
							facing = 0,
						},
						{
							name = "staticradar",
							x = 2448,
							z = 1024,
							facing = 0,
						},
						{
							name = "vehraid",
							x = 1372,
							z = 814,
							facing = 0,
						},
						{
							name = "vehraid",
							x = 1465,
							z = 807,
							facing = 0,
						},
						{
							name = "vehraid",
							x = 1565,
							z = 806,
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
					vitalCommanders = true,
					vitalUnitTypes = {
						"factoryveh"
					},
					loseAfterSeconds = false,
					allyTeamLossObjectiveID = 1,
				},
			},
			objectiveConfig = {
				-- This is just related to displaying objectives on the UI.
				[1] = {
					description = "Destroy the enemy Commander and Factory",
				},
				[2] = {
					description = "Protect your Commander",
				},
			},
			bonusObjectiveConfig = {
				[1] = { -- Build 10 Buoys
					satisfyOnce = true,
					countRemovedUnits = true, -- count units that previously died.
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 10,
					unitTypes = {
						"amphfloater",
					},
					image = planetUtilities.ICON_DIR .. "amphfloater.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.REPAIR,
					description = "Build 10 Buoys",
					experience = planetUtilities.BONUS_EXP,
				},
				[2] = { -- Don't lose any mexes
					satisfyForever = true,
					failOnUnitLoss = true, -- Fails the objective if any units being used to satisfy the objective are lost.
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 0,
					unitTypes = {
						"staticmex",
					},
					image = planetUtilities.ICON_DIR .. "staticmex.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.GUARD,
					description = "Don't lose any Metal Extractors",
					experience = planetUtilities.BONUS_EXP,
				},
			}
		},
		completionReward = {
			experience = planetUtilities.MAIN_EXP,
			units = {
				"factoryamph",
				"amphcon",
				"amphimpulse",
				"amphbomb",
				"amphfloater",
				"turrettorp",
			},
			modules = {
				"module_adv_nano_LIMIT_B_1",
			},
			abilities = {
			}
		},
	}
	
	return planetData
end

return GetPlanet
