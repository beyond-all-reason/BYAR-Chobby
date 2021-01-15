--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Planet config

local function GetPlanet(planetUtilities, planetID)
	
	--local image = planetUtilities.planetImages[math.floor(math.random()*#planetUtilities.planetImages) + 1]
	local image = LUA_DIRNAME .. "images/planets/arid01.png"
	
	local planetData = {
		name = "Jochu",
		startingPlanet = false,
		mapDisplay = {
			x = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][1]) or 0.33,
			y = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][2]) or 0.53,
			image = image,
			size = planetUtilities.PLANET_SIZE_MAP,
		},
		infoDisplay = {
			image = image,
			size = planetUtilities.PLANET_SIZE_INFO,
			backgroundImage = planetUtilities.backgroundImages[math.floor(math.random()*#planetUtilities.backgroundImages) + 1],
			terrainType = "Arid",
			radius = "4410 km",
			primary = "Ushasis",
			primaryType = "F9V",
			milRating = 1,
			feedbackLink = "http://zero-k.info/Forum/Thread/24441",
			text = "This is the station world of an imperial Rapid Reaction Force - or what is left of it, anyway. If I don't take them out now, they may fall on my back in the middle of another battle some day..."
			,
			extendedText = "The RRF will field Hovercraft and Gunships to cross the oasis which separates our bases. Rogues should take care of the hovercraft and Vandals will shoot the gunships down."
		},
		tips = {
			{
				image = "unitpics/shieldskirm.png",
				text = [[Since their rockets curve through the air, Rogues are a bit worse at hitting mobile targets than other skirmishers. On the upside they outrange most other skirmishers and inflict more damage if they do hit.]]
			},
			{
				image = "unitpics/shieldaa.png",
				text = [[Use anti-air units like Vandals to protect your other units from Gunships. Holding Ctrl when giving an order makes all of your units move at the same speed, so your army is not separated from its Vandal escort.]]
			},
			-- {
				-- image = "unitpics/shieldraid.png",
				-- text = [[A combination of steady pressure with Rogues and raiding parties of Bandits will keep your opponent's expansion under control. Remember to secure Metal Extractors of your own.]]
			-- },
			{
				image = "unitpics/gunshipraid.png",
				text = [[Most units will attempt to fire at low-flying aircraft and some, such as Bandits, are even good at the task. However, dedicated anti-air such as Vandals or Razor turrets are much more effective and have a significant range advantage.]]
			},
		},
		gameConfig = {
			mapName = "DunePatrol_wip_v03",
			playerConfig = {
				startX = 2816,
				startZ = 616,
				allyTeam = 0,
				commanderParameters = {
					facplop = false,
					defeatIfDestroyedObjectiveID = 2,
				},
				extraUnlocks = {
					"factoryshield",
					"shieldaa",
					"shieldskirm",
					"shieldraid",
					"shieldriot",
					"turretaalaser",
				},
				startUnits = {
					{
						name = "staticmex",
						x = 3688,
						z = 840,
						facing = 0,
					},
					{
						name = "staticmex",
						x = 2216,
						z = 872,
						facing = 0,
					},
					{
						name = "staticmex",
						x = 2568,
						z = 920,
						facing = 0,
					},
					{
						name = "staticmex",
						x = 3512,
						z = 488,
						facing = 0,
					},
					{
						name = "energysolar",
						x = 2584,
						z = 984,
						facing = 0,
					},
					{
						name = "staticradar",
						x = 2860,
						z = 500,
						facing = 0,
					},
					{
						name = "factoryshield",
						x = 2960,
						z = 608,
						facing = 0,
					},
					{
						name = "energysolar",
						x = 2200,
						z = 936,
						facing = 0,
					},
					{
						name = "energysolar",
						x = 3576,
						z = 472,
						facing = 0,
					},
					{
						name = "energysolar",
						x = 3704,
						z = 904,
						facing = 0,
					},
					{
						name = "turretlaser",
						x = 3760,
						z = 640,
						facing = 1,
					},
					{
						name = "turretmissile",
						x = 2656,
						z = 1152,
						facing = 0,
					},
					{
						name = "turretmissile",
						x = 3552,
						z = 1088,
						facing = 0,
					},
					{
						name = "turretlaser",
						x = 3072,
						z = 1104,
						facing = 0,
					},
					{
						name = "turretlaser",
						x = 2368,
						z = 816,
						facing = 3,
					},
					{
						name = "shieldcon",
						x = 3097,
						z = 625,
						facing = 0,
						commands = {
							{cmdID = planetUtilities.COMMAND.GUARD, atPosition = {2960, 608}},
						},
					},
					{
						name = "shieldskirm",
						x = 2898,
						z = 767,
						facing = 0,
					},
					{
						name = "shieldskirm",
						x = 2984,
						z = 762,
						facing = 0,
					},
					{
						name = "shieldraid",
						x = 2899,
						z = 835,
						facing = 0,
					},
					{
						name = "shieldraid",
						x = 2984,
						z = 826,
						facing = 0,
					},
					{
						name = "turretaalaser",
						x = 3200,
						z = 800,
						facing = 0,
					},
				}
			},
			aiConfig = {
				{
					startX = 2970,
					startZ = 3500,
					aiLib = "Circuit_difficulty_autofill",
					bitDependant = true,
					--aiLib = "Null AI",
					--bitDependant = false,
					humanName = "Avroka",
					commanderParameters = {
						facplop = false,
					},
					allyTeam = 1,
					unlocks = {
						"staticcon",
						"staticradar",
						"staticmex",
						"energysolar",
						"hovercon",
						"hoverraid",
						"hoverriot",
						"hoverskirm",
						"gunshipraid",
						"gunshipskirm",
					},
					difficultyDependantUnlocks = {
						[3] = {"hoverassault","hoverheavyraid"},
						[4] = {"hoverassault","gunshipheavyskirm","gunshipassault","hoverheavyraid"},
					},
					commanderLevel = 2,
					commander = {
						name = "Chera",
						chassis = "recon",
						decorations = {
						},
						modules = {
							"commweapon_lightninggun",
							"module_radarnet",
							"module_ablative_armor",
							"module_autorepair",
						}
					},
					startUnits = {
						{
							name = "staticmex",
							x = 2456,
							z = 3256,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 2648,
							z = 3624,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 3592,
							z = 3176,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 3944,
							z = 3240,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 3912,
							z = 3144,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 3608,
							z = 3080,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 2472,
							z = 3144,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 2552,
							z = 3592,
							facing = 0,
						},
						{
							name = "turretlaser",
							x = 2352,
							z = 3392,
							facing = 3,
						},
						{
							name = "turretlaser",
							x = 3776,
							z = 3248,
							facing = 2,
						},
						{
							name = "turretlaser",
							x = 3152,
							z = 2832,
							facing = 2,
						},
						{
							name = "turretmissile",
							x = 2832,
							z = 3040,
							facing = 2,
						},
						{
							name = "turretmissile",
							x = 3392,
							z = 2960,
							facing = 2,
						},
						{
							name = "factoryhover",
							x = 3120,
							z = 3408,
							facing = 2,
						},
						{
							name = "factorygunship",
							x = 3500,
							z = 3700,
							facing = 2,
						},
						{
							name = "turretriot",
							x = 3800,
							z = 3700,
							facing = 1,
						},
						{
							name = "hovercon",
							x = 3278,
							z = 3445,
							facing = 0,
						},
						{
							name = "hoverskirm",
							x = 3030,
							z = 3221,
							facing = 2,
						},
						{
							name = "hoverraid",
							x = 3111,
							z = 3266,
							facing = 0,
						},
						{
							name = "hoverraid",
							x = 3112,
							z = 3193,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 4744,
							z = 3513,
							facing = 0,
							difficultyAtLeast = 2,
						},
						{
							name = "energysolar",
							x = 4744,
							z = 3370,
							facing = 0,
							difficultyAtLeast = 2,
						},
						{
							name = "turretlaser",
							x = 4800,
							z = 3600,
							facing = 2,
							difficultyAtLeast = 2,
						},
						{
							name = "staticmex",
							x = 1112,
							z = 3736,
							facing = 0,
							difficultyAtLeast = 3,
						},
						{
							name = "energysolar",
							x = 1112,
							z = 3600,
							facing = 0,
							difficultyAtLeast = 3,
						},
						{
							name = "turretlaser",
							x = 1200,
							z = 3700,
							facing = 2,
							difficultyAtLeast = 3,
						},
						{
							name = "staticmex",
							x = 630,
							z = 3700,
							facing = 0,
							difficultyAtLeast = 4,
						},
						{
							name = "staticmex",
							x = 5114,
							z = 3594,
							facing = 0,
							difficultyAtLeast = 4,
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
						"factoryhover",
						"factorygunship",
					},
					loseAfterSeconds = false,
					allyTeamLossObjectiveID = 1,
				},
			},
			objectiveConfig = {
				-- This is just related to displaying objectives on the UI.
				[1] = {
					description = "Destroy the enemy Commander and all enemy factories",
				},
				[2] = {
					description = "Protect your Commander",
				},
			},
			bonusObjectiveConfig = {
				[1] = { -- Have 20 Rogues
					satisfyOnce = true,
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 20,
					unitTypes = {
						"shieldskirm",
					},
					image = planetUtilities.ICON_DIR .. "shieldskirm.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.REPAIR,
					description = "Have 20 Rogues",
					experience = planetUtilities.BONUS_EXP,
				},
				[2] = { -- Win by 10:00
					victoryByTime = 600,
					image = planetUtilities.ICON_OVERLAY.CLOCK,
					description = "Win by 10:00",
					experience = planetUtilities.BONUS_EXP,
				},
				[3] = { -- Prevent the enemy having more than twelve mex
					satisfyForever = true,
					comparisionType = planetUtilities.COMPARE.AT_MOST,
					targetNumber = 12,
					enemyUnitTypes = {
						"staticmex",
					},
					image = planetUtilities.ICON_DIR .. "staticmex.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.ATTACK,
					description = "Prevent the enemy from building more than twelve Metal Extractors",
					experience = planetUtilities.BONUS_EXP,
				},
			},
		},
		completionReward = {
			experience = planetUtilities.MAIN_EXP,
			units = {
				--"factoryshield",
				--"shieldraid",
				--"shieldriot",
				"turretaalaser",
				"shieldskirm",
				"shieldaa",
			},
			modules = {
				"commweapon_rocketlauncher",
			},
			abilities = {
			},
			codexEntries = {
				"faction_empire"
			},
		},
	}
	
	return planetData
end

return GetPlanet
