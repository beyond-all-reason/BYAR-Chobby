--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Planet config

local function GetPlanet(planetUtilities, planetID)
	
	--local image = planetUtilities.planetImages[math.floor(math.random()*#planetUtilities.planetImages) + 1]
	local image = LUA_DIRNAME .. "images/planets/desert03.png"
	
	local planetData = {
		name = "Rasia",
		startingPlanet = false,
		mapDisplay = {
			x = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][1]) or 0.41,
			y = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][2]) or 0.035,
			image = image,
			size = planetUtilities.PLANET_SIZE_MAP,
		},
		infoDisplay = {
			image = image,
			size = planetUtilities.PLANET_SIZE_INFO,
			backgroundImage = planetUtilities.backgroundImages[math.floor(math.random()*#planetUtilities.backgroundImages) + 1],
			terrainType = "Desert",
			radius = "7540 km",
			primary = "Jassa Minor",
			primaryType = "M2V",
			milRating = 1,
			feedbackLink = "http://zero-k.info/Forum/Thread/24510",
			text = "A marginal desert world with a few buried scientific outposts. With luck I will find valuable information in those, if I can get rid of the army defending the surface."
			.. "\n "
			.. "\nI have weird readings on that sand, though, and the local army seems to avoid it. I have a bad feeling about this..."
			,
			extendedText = "This planet is infested with Chicken, and now the swarm is waking up! I hate those things. What the hell are they anyway? At least they don't take sides, and equally attack everything. All I have to do is to hold them off long enough to beat the automata."
		},
		tips = {
			{
				image = "unitpics/chicken.png",
				text = [[On this planet 'Chickens' will spawn from roosts to roam the battlefield and attack anything they encounter. They cannot be completely stopped but you can limit the damage with well-placed turrets.]]
			},
			{
				image = "unitpics/roost.png",
				text = [[Destroying Chicken Roosts will prevent chickens from spawning at that location, and will set back their evolution. However it will also make the hive angrier, and more Roosts will be spawned elsewhere.]]
			},
			{
				image = "unitpics/gunshipskirm.png",
				text = [[The Harpy skirmisher gunship will slow down both the chickens and your opponent's units with disruptor missiles. Their conventional damage output is average at best but once the enemy is crippled and slow they can be dispatched at leisure.]]
			},
		},
		gameConfig = {
			mapName = "Cattle and Loveplay NO WORMS 1",
			modoptions = {
				chicken_nominiqueen = 1,
				chicken_minaggro = 0,	-- aggro influences chicken tech-up rate (and queen time reduction from killing burrows, but queens are disabled here)
				chicken_maxaggro = 0,
				chicken_maxtech = 30*60,	-- stops before Sporeshooter/Talon
				chicken_endless = 1,
				chicken_hidepanel = 1,
				chicken_nowavemessages = 1,
			},
			playerConfig = {
				startX = 1415,
				startZ = 1970,
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
					"gunshipskirm",
					"gunshipassault",
				},
				startUnits = {
					{
						name = "staticmex",
						x = 984,
						z = 1288,
						facing = 0,
					},
					{
						name = "staticmex",
						x = 904,
						z = 1032,
						facing = 0,
					},
					{
						name = "staticmex",
						x = 1208,
						z = 1112,
						facing = 0,
					},
					{
						name = "energysolar",
						x = 1080,
						z = 1048,
						facing = 0,
					},
					{
						name = "turretlaser",
						x = 1744,
						z = 1792,
						facing = 1,
					},
					{
						name = "energysolar",
						x = 952,
						z = 1160,
						facing = 0,
					},
					{
						name = "turretlaser",
						x = 1744,
						z = 2224,
						facing = 1,
					},
					{
						name = "factorygunship",
						x = 1336,
						z = 1464,
						facing = 0,
					},
					{
						name = "turretlaser",
						x = 1040,
						z = 1632,
						facing = 3,
					},
					{
						name = "turretlaser",
						x = 1152,
						z = 2096,
						facing = 3,
					},
					{
						name = "staticradar",
						x = 1536,
						z = 976,
						facing = 0,
					},
					{
						name = "staticradar",
						x = 1600,
						z = 2736,
						facing = 0,
					},
					{
						name = "gunshipskirm",
						x = 1300,
						z = 2100,
						facing = 0,
					},
					{
						name = "gunshipskirm",
						x = 1500,
						z = 2100,
						facing = 0,
					},
				}
			},
			aiConfig = {
				{
					startX = 7910,
					startZ = 1624,
					humanName = "Zenics",
					--aiLib = "Null AI",
					--bitDependant = false,
					aiLib = "Circuit_difficulty_autofill",
					bitDependant = true,
					commanderParameters = {
						facplop = false,
						bonusObjectiveID = 2,
					},
					allyTeam = 1,
					unlocks = {
						"staticmex",
						"staticcon",
						"energysolar",
						"energygeo",
						"staticradar",
						"turretlaser",
						"turretmissile",
						"turretaaclose",
						"amphcon",
						"amphraid",
						"amphimpulse",
						"amphfloater",
						"amphriot",
						"amphaa"
					},
					commanderLevel = 4,
					commander = {
						name = "Palladia",
						chassis = "engineer",
						decorations = {
						  "skin_support_dark",
						},
						modules = {
							"commweapon_beamlaser",
							"commweapon_disruptorbomb",
							"module_autorepair",
							"module_autorepair",
							"module_ablative_armor",
							"module_ablative_armor",
							"module_high_power_servos",
							"module_high_power_servos",
							"module_adv_nano"
						}
					},
					midgameUnits = {
						{
							name = "amphfloater",
							x = 8100,
							z = 1800,
							facing = 2,
							spawnRadius = 50,
							delay = 3*30*60,
							orbitalDrop = true,
						},
						{
							name = "amphfloater",
							x = 8100,
							z = 1800,
							facing = 2,
							spawnRadius = 50,
							delay = 3*30*60,
							orbitalDrop = true,
						},
						{
							name = "amphfloater",
							x = 8100,
							z = 1800,
							facing = 2,
							spawnRadius = 50,
							delay = 3*30*60,
							orbitalDrop = true,
						},
						{
							name = "amphaa",
							x = 8100,
							z = 1800,
							facing = 2,
							spawnRadius = 50,
							delay = 6*30*60,
							orbitalDrop = true,
						},
						{
							name = "amphaa",
							x = 8100,
							z = 1800,
							facing = 2,
							spawnRadius = 50,
							delay = 6*30*60,
							orbitalDrop = true,
						},
						{
							name = "amphassault",
							x = 8100,
							z = 1800,
							facing = 2,
							spawnRadius = 50,
							delay = 6*30*60,
							difficultyAtLeast = 3,
							orbitalDrop = true,
						},
						{
							name = "amphassault",
							x = 8100,
							z = 1800,
							facing = 2,
							spawnRadius = 50,
							delay = 6*30*60,
							difficultyAtLeast = 4,
							orbitalDrop = true,
						},
					},
					startUnits = {
						{
							name = "staticmex",
							x = 8136,
							z = 1256,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 8440,
							z = 1176,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 8376,
							z = 1432,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 8408,
							z = 1288,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 8248,
							z = 1240,
							facing = 0,
						},
						{
							name = "staticradar",
							x = 8496,
							z = 592,
							facing = 0,
						},
						{
							name = "staticradar",
							x = 7472,
							z = 2672,
							facing = 0,
						},
						{
							name = "factoryamph",
							x = 8104,
							z = 1528,
							facing = 0,
						},
						{
							name = "turretriot",
							x = 7696,
							z = 1520,
							facing = 3,
						},
						{
							name = "turretriot",
							x = 7632,
							z = 2000,
							facing = 3,
						},
						{
							name = "turretriot",
							x = 8464,
							z = 1520,
							facing = 1,
						},
						{
							name = "turretriot",
							x = 8288,
							z = 1968,
							facing = 1,
						},
						{
							name = "turretaalaser",
							x = 7656,
							z = 2408,
							facing = 3,
						},
						{
							name = "turretaalaser",
							x = 7960,
							z = 1992,
							facing = 3,
						},
						{
							name = "turretaalaser",
							x = 8232,
							z = 1400,
							facing = 3,
						},
						{
							name = "turretaalaser",
							x = 8440,
							z = 904,
							facing = 3,
						},
					}
				},
				{
					humanName = "Chickens",
					aiLib = "Chicken: Very Easy",
					bitDependant = false,
					commanderParameters = {
						facplop = false,
					},
					allyTeam = 2,
					unlocks = {
					},
					commander = false,
					startUnits = {
						{
							name = "roost",
							x = 3530,
							z = 1000,
							facing = 3,
						},
						{
							name = "roost",
							x = 2852,
							z = 4300,
							facing = 3,
						},
					}
				},
			},
			defeatConditionConfig = {
				[0] = { },
				[1] = {
					ignoreUnitLossDefeat = false,
					defeatOtherAllyTeamsOnLoss = {2},
					vitalCommanders = true,
					vitalUnitTypes = {
						"factoryamph",
					},
					loseAfterSeconds = false,
					allyTeamLossObjectiveID = 1,
				},
				[2] = {
					ignoreUnitLossDefeat = true,
					doNotExplodeOnLoss = true, -- It would look a bit weird for the chickens to explode when the robots lose.
				},
			},
			objectiveConfig = {
				[1] = {
					description = "Destroy the enemy Commander and Amphbot Factory",
				},
				[2] = {
					description = "Protect your Commander",
				},
			},
			bonusObjectiveConfig = {
				[1] = { -- Make the enemy lose ten roosts by 10:00
					onlyCountRemovedUnits = true,
					satisfyByTime = 600,
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 10,
					enemyUnitTypes = {
						"roost",
					},
					image = planetUtilities.ICON_DIR .. "roost.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.ATTACK,
					description = "Destroy 10 Chicken Roosts by 10:00",
					experience = planetUtilities.BONUS_EXP,
				},
				[2] = { -- Kill enemy commander by 10:00
					satisfyByTime = 600,
					comparisionType = planetUtilities.COMPARE.AT_MOST,
					targetNumber = 0,
					-- See bonusObjectiveID in units table
					image = planetUtilities.ICON_DIR .. "skin_support_dark.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.ATTACK,
					description = "Destroy the enemy commander before 10:00",
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
				"gunshipskirm",
				"gunshipassault",
			},
			modules = {
				"conversion_disruptor",
			},
			abilities = {
			},
			codexEntries = {
				"threat_chickens",
				"threat_chickens_lifecycle"
			}
		},
	}
	
	return planetData
end

return GetPlanet
