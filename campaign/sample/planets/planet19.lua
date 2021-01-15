--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Planet config

local function GetPlanet(planetUtilities, planetID)
	
	--local image = planetUtilities.planetImages[math.floor(math.random()*#planetUtilities.planetImages) + 1]
	local image = LUA_DIRNAME .. "images/planets/terran02.png"
	
	local planetData = {
		name = "Yeta",
		startingPlanet = false,
		mapDisplay = {
			x = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][1]) or 0.185,
			y = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][2]) or 0.45,
			image = image,
			size = planetUtilities.PLANET_SIZE_MAP,
		},
		infoDisplay = {
			image = image,
			size = planetUtilities.PLANET_SIZE_INFO,
			backgroundImage = planetUtilities.backgroundImages[math.floor(math.random()*#planetUtilities.backgroundImages) + 1],
			terrainType = "Minimal",
			radius = "7100 km",
			primary = "Alain Anora",
			primaryType = "G4V",
			milRating = 1,
			feedbackLink = "http://zero-k.info/Forum/Thread/24441",
			text = "The two forces here are both too entrenched for automated raids to dislodge the other. One of them recognized my IFF, luckily enough, so I should be able to break the stalemate. All I need is to find a way to break some tough defenses."
			.. "\n "
			.. "\nI wonder how much initiative those AIs have been given. Can it decide to make tactical alliances on its own? Or did it somehow know my IFF?"
			,
			extendedText = "I can finish the Cerberus artillery piece and link it to my ally's power plants. Then this cannon will break the enemy's defensive line and allow us to destroy their base once and for all."
		},
		tips = {
			{
				image = "unitpics/staticarty.png",
				text = [[The Cerberus is a long-range artillery structure capable of outranging and destroying the enemies defense as well as suppressing the movement of their mobile units. Toggle it into high-trajectory mode to fire over hills.]]
			},
			{
				image = "unitpics/energypylon.png",
				text = [[In order to fire, your Cerberus needs to be connected to a power grid with at least 50 energy, although it does not consume this energy. Use Energy Pylons to extend the grid from your ally's Fusions. The Economy view (F4) displays your power grid as coloured circles.]]
			},
			{
				image = "unitpics/staticmex.png",
				text = [[Connecting Metal Extractors to your energy production structures can give you more metal income through Overdrive. Check the online manual for more information about how Overdrive works.]]
			},
			{
				image = "unitpics/staticcon.png",
				text = [[Caretakers are stationary constructors with large build range and high build power for their cost. They are limited by their inability to initiate construction, but they are the most cost-efficient way to get more production out of a factory.]]
			},
		},
		gameConfig = {
			mapName = "Tombstone Desert V2",
			playerConfig = {
				startX = 3435,
				startZ = 3171,
				allyTeam = 0,
				commanderParameters = {
					facplop = true,
					defeatIfDestroyedObjectiveID = 2,
				},
				extraUnlocks = {
					"staticcon",
					"energypylon",
					"staticarty",
				},
				startUnits = {
					{
						name = "staticarty",
						x = 3048,
						z = 2936,
						facing = 2,
						buildProgress = 0.05,
					},
					{
						name = "staticradar",
						x = 3120,
						z = 2850,
						facing = 0,
					},
					{
						name = "staticcon",
						x = 3245,
						z = 3000,
						facing = 3,
						selfPatrol = true,
					},
				}
			},
			aiConfig = {
				{
					humanName = "Ally",
					--aiLib = "Null AI",
					--bitDependant = false,
					aiLib = "Circuit_difficulty_autofill_ally",
					bitDependant = true,
					allyTeam = 0,
					unlocks = {
						"turretlaser",
						"turretmissile",
						"staticradar",
						"cloakcon",
						"staticmex",
						"energysolar",
						"cloakraid",
						"cloakskirm",
						"cloakriot",
						"cloakassault",
					},
					commander = false,
					startUnits = {
						{
							name = "energyfusion",
							x = 4024,
							z = 3536,
							facing = 0,
						},
						{
							name = "energyfusion",
							x = 4024,
							z = 3376,
							facing = 0,
						},
						{
							name = "energyfusion",
							x = 4024,
							z = 3232,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 3672,
							z = 3576,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 4008,
							z = 3752,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 3720,
							z = 3912,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 3128,
							z = 3736,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 3960,
							z = 2360,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 2184,
							z = 3528,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 1560,
							z = 4008,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 3800,
							z = 1032,
							facing = 0,
						},
						{
							name = "turretlaser",
							x = 3584,
							z = 1120,
							facing = 2,
						},
						{
							name = "turretlaser",
							x = 3872,
							z = 832,
							facing = 2,
						},
						{
							name = "turretlaser",
							x = 1312,
							z = 4048,
							facing = 3,
						},
						{
							name = "turretlaser",
							x = 1872,
							z = 3648,
							facing = 2,
						},
						{
							name = "turretlaser",
							x = 2288,
							z = 3296,
							facing = 2,
						},
						{
							name = "turretlaser",
							x = 3024,
							z = 2176,
							facing = 2,
						},
						{
							name = "turretlaser",
							x = 3424,
							z = 1648,
							facing = 2,
						},
						{
							name = "turretriot",
							x = 3224,
							z = 1864,
							facing = 2,
						},
						{
							name = "turretriot",
							x = 2056,
							z = 3368,
							facing = 2,
						},
						{
							name = "turretriot",
							x = 2968,
							z = 2680,
							facing = 2,
						},
						{
							name = "energysolar",
							x = 3880,
							z = 3720,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 3720,
							z = 3672,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 3640,
							z = 3800,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 3448,
							z = 3832,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 3272,
							z = 3784,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 3096,
							z = 3800,
							facing = 0,
						},
						{
							name = "factorycloak",
							x = 3496,
							z = 3608,
							facing = 2,
						},
						{
							name = "staticcon",
							x = 3464,
							z = 3720,
							facing = 0,
						},
						{
							name = "staticcon",
							x = 3528,
							z = 3704,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 2536,
							z = 2760,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 2824,
							z = 2472,
							facing = 0,
						},
					}
				},
				{
					startX = 100,
					startZ = 100,
					humanName = "Trenchers",
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
						"turretlaser",
						"turretmissile",
						"staticradar",
						"cloakcon",
						"staticmex",
						"energysolar",
						"vehscout",
						"vehraid",
						"vehsupport",
						"vehriot",
						"vehassault",
						"vehaa",
						"shieldraid",
						"shieldassault",
						"shieldriot",
						"shieldskirm",
						"shieldaa",
					},
					difficultyDependantUnlocks = {
						[2] = {"shieldfelon"},
						[3] = {"shieldfelon","shieldarty"},
						[4] = {"shieldfelon","shieldarty","vehheavyarty",},
					},
					commanderLevel = 2,
					commander = {
						name = "Maginot",
						chassis = "engineer",
						decorations = {
						},
						modules = {
							"commweapon_shotgun",
							"module_radarnet"
						}
					},
					startUnits = {
						{
							name = "turretheavy",
							x = 2680,
							z = 1176,
							facing = 0,
						},
						{
							name = "turretheavy",
							x = 1240,
							z = 3080,
							facing = 1,
						},
						{
							name = "turretheavylaser",
							x = 2840,
							z = 344,
							facing = 1,
						},
						{
							name = "turretheavylaser",
							x = 2168,
							z = 1624,
							facing = 0,
						},
						{
							name = "turretheavylaser",
							x = 1560,
							z = 2216,
							facing = 0,
						},
						{
							name = "turretriot",
							x = 1432,
							z = 2424,
							facing = 0,
						},
						{
							name = "turretriot",
							x = 2344,
							z = 1480,
							facing = 0,
						},
						{
							name = "turretriot",
							x = 3000,
							z = 200,
							facing = 1,
						},
						{
							name = "turretriot",
							x = 2920,
							z = 552,
							facing = 1,
						},
						{
							name = "turretheavylaser",
							x = 232,
							z = 3288,
							facing = 0,
						},
						{
							name = "turretriot",
							x = 440,
							z = 3304,
							facing = 0,
						},
						{
							name = "turretheavylaser",
							x = 1640,
							z = 1704,
							facing = 2,
						},
						{
							name = "turretriot",
							x = 808,
							z = 2888,
							facing = 1,
						},
						{
							name = "turretriot",
							x = 2440,
							z = 744,
							facing = 0,
						},
						{
							name = "factoryveh",
							x = 1800,
							z = 136,
							facing = 0,
						},
						{
							name = "factoryshield",
							x = 128,
							z = 1728,
							facing = 1,
						},
						{
							name = "staticmex",
							x = 200,
							z = 408,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 248,
							z = 168,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 456,
							z = 296,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 264,
							z = 1112,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 1464,
							z = 248,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 280,
							z = 280,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 456,
							z = 200,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 616,
							z = 280,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 824,
							z = 280,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 1016,
							z = 264,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 1192,
							z = 248,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 1368,
							z = 216,
							facing = 0,
						},
						{
							name = "energywind",
							x = 728,
							z = 296,
							facing = 0,
						},
						{
							name = "energypylon",
							x = 536,
							z = 600,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 200,
							z = 520,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 200,
							z = 696,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 200,
							z = 872,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 184,
							z = 1032,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 872,
							z = 2152,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 1784,
							z = 744,
							facing = 0,
						},
						{
							name = "turretlaser",
							x = 80,
							z = 1936,
							facing = 0,
						},
						{
							name = "turretlaser",
							x = 368,
							z = 1712,
							facing = 0,
						},
						{
							name = "turretlaser",
							x = 160,
							z = 1392,
							facing = 0,
						},
						{
							name = "turretlaser",
							x = 1536,
							z = 144,
							facing = 0,
						},
						{
							name = "turretlaser",
							x = 1920,
							z = 432,
							facing = 0,
						},
						{
							name = "turretlaser",
							x = 2128,
							z = 128,
							facing = 0,
						},
						{
							name = "energypylon",
							x = 968,
							z = 2616,
							facing = 0,
						},
						{
							name = "energypylon",
							x = 632,
							z = 1864,
							facing = 0,
						},
						{
							name = "energypylon",
							x = 984,
							z = 1160,
							facing = 0,
						},
						{
							name = "energypylon",
							x = 1880,
							z = 1048,
							facing = 0,
						},
						{
							name = "energypylon",
							x = 2552,
							z = 952,
							facing = 0,
						},
						{
							name = "energyfusion",
							x = 344,
							z = 432,
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
						"factoryshield",
						"factoryveh",
					},
					loseAfterSeconds = false,
					allyTeamLossObjectiveID = 1,
				},
			},
			objectiveConfig = {
				-- This is just related to displaying objectives on the UI.
				[1] = {
					description = "Destroy the enemy Shieldbot Factory and Rover Assembly",
				},
				[2] = {
					description = "Protect your Commander",
				},
			},
			bonusObjectiveConfig = {
				-- Indexed by bonusObjectiveID
				[1] = { -- Destroy both DDMs
					satisfyOnce = true,
					comparisionType = planetUtilities.COMPARE.AT_MOST,
					targetNumber = 0,
					enemyUnitTypes = {
						"turretheavy",
					},
					image = planetUtilities.ICON_DIR .. "turretheavy.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.ATTACK,
					description = "Destroy all enemy Desolator turrets",
					experience = planetUtilities.BONUS_EXP,
				},
				[2] = { -- Build two Tyrants
					satisfyOnce = true,
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 2,
					unitTypes = {
						"staticarty",
					},
					image = planetUtilities.ICON_DIR .. "staticarty.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.REPAIR,
					description = "Build two Cerberuses",
					experience = planetUtilities.BONUS_EXP,
				},
				[3] = { -- Win in 12 minutes
					victoryByTime = 720,
					image = planetUtilities.ICON_OVERLAY.CLOCK,
					description = "Win by 12:00",
					experience = planetUtilities.BONUS_EXP,
				},
			},
		},
		completionReward = {
			experience = planetUtilities.MAIN_EXP,
			units = {
				"staticcon",
				"energypylon",
			},
			modules = {
				"module_heavy_armor_LIMIT_A_2",
			},
			abilities = {
			}
		},
	}
	
	return planetData
end

return GetPlanet
