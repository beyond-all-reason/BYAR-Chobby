--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Planet config

local function GetPlanet(planetUtilities, planetID)
	
	--local image = planetUtilities.planetImages[math.floor(math.random()*#planetUtilities.planetImages) + 1]
	local image = LUA_DIRNAME .. "images/planets/swamp02.png"
	
	local planetData = {
		name = "Mstaras",
		startingPlanet = false,
		mapDisplay = {
			x = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][1]) or 0.28,
			y = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][2]) or 0.07,
			image = image,
			size = planetUtilities.PLANET_SIZE_MAP,
		},
		infoDisplay = {
			image = image,
			size = planetUtilities.PLANET_SIZE_INFO,
			backgroundImage = planetUtilities.backgroundImages[math.floor(math.random()*#planetUtilities.backgroundImages) + 1],
			terrainType = "Terran",
			radius = "5110 km",
			primary = "Jazada",
			primaryType = "G4V",
			milRating = 1,
			feedbackLink = "http://zero-k.info/Forum/Thread/24510",
			text = "Occupation forces on this world have dwindled to a few dormant bots. Hopefully I can land and take them out before they awaken..."
			.. "\n "
			.. "\nAnother rebel planet that fell to a merciless imperial punitive expedition. I wonder what drove so many worlds to rise against the Empire."
			,
			extendedText = "They are waking up earlier than I expected. I should use fast-moving Locust raider gunships to curtail their expansion, then Nimbus support gunships to finish them off."
		},
		tips = {
			{
				image = "unitpics/gunshipcon.png",
				text = [[Gunships are flying units which can hover in place and tend to move faster than land units. Anti-air units and turrets are most effective against Gunships, but most units with a fast-moving projectile or laser will also pose a threat.]]
			},
			{
				image = "unitpics/gunshipraid.png",
				text = [[The Locust raider gunships will repair themselves if left alone for a little while, so try to retreat them when they become damaged. They are particularly vulnerable to enemy riots due to their low range.]]
			},
			{
				image = "unitpics/gunshipheavyskirm.png",
				text = [[If the automatic strafing of your Locusts and Nimbuses is causing them to stray into range of enemy AA, you can disable this behaviour with the corresponding unit toggle.]]
			},
		},
		gameConfig = {
			mapName = "Trojan Hills v05",
			playerConfig = {
				startX = 4220,
				startZ = 2300,
				allyTeam = 0,
				facplop = false,
				commanderParameters = {
					facplop = false,
					defeatIfDestroyedObjectiveID = 2,
				},
				extraUnlocks = {
					"factorygunship",
					"gunshipcon",
					"gunshipraid",
					"gunshipbomb",
					"gunshipheavyskirm",
				},
				startUnits = {
					{
						name = "staticradar",
						x = 4208,
						z = 2176,
						facing = 0,
					},
					{
						name = "staticradar",
						x = 4080,
						z = 3200,
						facing = 0,
					},
					{
						name = "factorygunship",
						x = 4312,
						z = 2840,
						facing = 3,
					},
					{
						name = "staticmex",
						x = 4360,
						z = 2520,
						facing = 0,
					},
					{
						name = "staticmex",
						x = 4552,
						z = 2904,
						facing = 0,
					},
					{
						name = "staticmex",
						x = 4296,
						z = 3160,
						facing = 0,
					},
					{
						name = "energywind",
						x = 4360,
						z = 3096,
						facing = 0,
					},
					{
						name = "energywind",
						x = 4440,
						z = 3032,
						facing = 0,
					},
					{
						name = "energywind",
						x = 4504,
						z = 2968,
						facing = 0,
					},
					{
						name = "energywind",
						x = 4424,
						z = 2584,
						facing = 0,
					},
					{
						name = "energywind",
						x = 4488,
						z = 2664,
						facing = 0,
					},
					{
						name = "energywind",
						x = 4552,
						z = 2744,
						facing = 0,
					},
					{
						name = "energywind",
						x = 4584,
						z = 2840,
						facing = 0,
					},
					{
						name = "staticcon",
						x = 4456,
						z = 2856,
						facing = 3,
						selfPatrol = true,
					},
					{
						name = "gunshipraid",
						x = 4160,
						z = 2788,
						facing = 0,
					},
					{
						name = "gunshipraid",
						x = 4159,
						z = 2891,
						facing = 0,
					},
				}
			},
			aiConfig = {
				{
					startX = 1800,
					startZ = 3600,
					humanName = "Mountain Goats",
					--aiLib = "Null AI",
					--bitDependant = false,
					aiLib = "Circuit_difficulty_autofill",
					bitDependant = true,
					commanderParameters = {
						facplop = false,
					},
					allyTeam = 1,
					unlocks = {
						"staticmex",
						"energywind",
						"energysolar",
						"staticradar",
						"turretlaser",
						"turretmissile",
						"shieldcon",
						"shieldraid",
						"shieldskirm",
						"shieldriot",
						"shieldassault",
						"shieldaa",
						"shieldfelon",
					},
					commanderLevel = 3,
					commander = {
						name = "Xylophone",
						chassis = "recon",
						decorations = {
						},
						modules = {
							"commweapon_shotgun",
							"module_ablative_armor",
							"module_ablative_armor",
							"module_dmg_booster",
							"module_high_power_servos",
							"module_adv_targeting",
						}
					},
					midgameUnits = {
						{
							name = "shieldfelon",
							x = 700,
							z = 3600,
							facing = 2,
							spawnRadius = 50,
							delay = 2*30*60,
							orbitalDrop = true,
						},
						{
							name = "shieldaa",
							x = 700,
							z = 3600,
							facing = 2,
							spawnRadius = 50,
							delay = 2*30*60,
							orbitalDrop = true,
						},
						{
							name = "shieldaa",
							x = 700,
							z = 3600,
							facing = 2,
							spawnRadius = 50,
							delay = 2*30*60,
							difficultyAtLeast = 3,
							orbitalDrop = true,
						},
						{
							name = "shieldaa",
							x = 700,
							z = 3600,
							facing = 2,
							spawnRadius = 50,
							delay = 2*30*60,
							difficultyAtLeast = 3,
							orbitalDrop = true,
						},
						{
							name = "shieldfelon",
							x = 700,
							z = 3600,
							facing = 2,
							spawnRadius = 50,
							delay = 5*30*60,
							orbitalDrop = true,
						},
						{
							name = "shieldaa",
							x = 700,
							z = 3600,
							facing = 2,
							spawnRadius = 50,
							delay = 5*30*60,
							orbitalDrop = true,
						},
						{
							name = "shieldaa",
							x = 700,
							z = 3600,
							facing = 2,
							spawnRadius = 50,
							delay = 5*30*60,
							orbitalDrop = true,
						},
						{
							name = "shieldaa",
							x = 700,
							z = 3600,
							facing = 2,
							spawnRadius = 50,
							delay = 5*30*60,
							orbitalDrop = true,
						},
						{
							name = "shieldfelon",
							x = 700,
							z = 3600,
							facing = 2,
							spawnRadius = 50,
							delay = 8*30*60,
							orbitalDrop = true,
						},
						{
							name = "shieldaa",
							x = 700,
							z = 3600,
							facing = 2,
							spawnRadius = 50,
							delay = 8*30*60,
							orbitalDrop = true,
						},
						{
							name = "shieldaa",
							x = 700,
							z = 3600,
							facing = 2,
							spawnRadius = 50,
							delay = 8*30*60,
							orbitalDrop = true,
						},
						{
							name = "shieldassault",
							x = 700,
							z = 3600,
							facing = 2,
							spawnRadius = 50,
							delay = 8*30*60,
							orbitalDrop = true,
						},
						{
							name = "shieldassault",
							x = 700,
							z = 3600,
							facing = 2,
							spawnRadius = 50,
							delay = 8*30*60,
							orbitalDrop = true,
						},
					},
					startUnits = {
						{
							name = "staticmex",
							x = 1672,
							z = 3224,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 1928,
							z = 2920,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 1864,
							z = 3704,
							facing = 0,
						},
						{
							name = "energywind",
							x = 1704,
							z = 3128,
							facing = 0,
						},
						{
							name = "energywind",
							x = 1768,
							z = 3032,
							facing = 0,
						},
						{
							name = "energywind",
							x = 1848,
							z = 2968,
							facing = 0,
						},
						{
							name = "energywind",
							x = 1656,
							z = 3320,
							facing = 0,
						},
						{
							name = "energywind",
							x = 1688,
							z = 3432,
							facing = 0,
						},
						{
							name = "energywind",
							x = 1720,
							z = 3528,
							facing = 0,
						},
						{
							name = "energywind",
							x = 1784,
							z = 3624,
							facing = 0,
						},
						{
							name = "turretaaclose",
							x = 1880,
							z = 3848,
							facing = 1,
						},
						{
							name = "turretaaclose",
							x = 1448,
							z = 3128,
							facing = 3,
						},
						{
							name = "turretaaclose",
							x = 1720,
							z = 2872,
							facing = 1,
						},
						{
							name = "turretlaser",
							x = 1312,
							z = 3184,
							facing = 3,
						},
						{
							name = "turretlaser",
							x = 1440,
							z = 3488,
							facing = 3,
						},
						{
							name = "turretlaser",
							x = 1856,
							z = 2800,
							facing = 2,
						},
						{
							name = "turretaalaser",
							x = 1912,
							z = 3576,
							facing = 1,
						},
						{
							name = "staticcon",
							x = 1880,
							z = 3464,
							facing = 2,
						},
						{
							name = "factoryshield",
							x = 1856,
							z = 3352,
							facing = 2,
						},
						{
							name = "staticmex",
							x = 168,
							z = 2168,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 2744,
							z = 4456,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 2696,
							z = 536,
							facing = 0,
						},
						{
							name = "turretlaser",
							x = 2928,
							z = 576,
							facing = 1,
						},
						{
							name = "turretlaser",
							x = 2784,
							z = 4288,
							facing = 2,
						},
						{
							name = "turretlaser",
							x = 304,
							z = 2144,
							facing = 1,
						},
						{
							name = "shieldaa",
							x = 1979,
							z = 3238,
							facing = 0,
						},
						{
							name = "shieldraid",
							x = 2046,
							z = 3298,
							facing = 0,
						},
						{
							name = "shieldcon",
							x = 1824,
							z = 3200,
							facing = 0,
						},
						{
							name = "shieldcon",
							x = 1900,
							z = 3200,
							facing = 0,
						},
						{
							name = "shieldraid",
							x = 2048,
							z = 3254,
							facing = 0,
						},
						{
							name = "shieldraid",
							x = 1987,
							z = 3165,
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
						"factoryshield",
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
				[1] = { -- Have 12 Banshees
					satisfyOnce = true,
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 12,
					unitTypes = {
						"gunshipraid",
					},
					image = planetUtilities.ICON_DIR .. "gunshipraid.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.REPAIR,
					description = "Have 12 Locusts",
					experience = planetUtilities.BONUS_EXP,
				},
				[2] = {
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
					description = "Prevent the enemy from having more than 12 Metal Extractors",
					experience = planetUtilities.BONUS_EXP,
				},
			}
		},
		completionReward = {
			experience = planetUtilities.MAIN_EXP,
			units = {
				"factorygunship",
				"gunshipcon",
				"gunshipraid",
				"gunshipbomb",
				"gunshipheavyskirm",
			},
			modules = {
				"module_adv_nano_LIMIT_E_1",
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
