--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Planet config

local function GetPlanet(planetUtilities, planetID)
	
	--local image = planetUtilities.planetImages[math.floor(math.random()*#planetUtilities.planetImages) + 1]
	local image = LUA_DIRNAME .. "images/planets/barren01.png"
	
	local planetData = {
		name = "Phisnet-3617",
		startingPlanet = false,
		mapDisplay = {
			x = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][1]) or 0.215,
			y = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][2]) or 0.545,
			image = image,
			size = planetUtilities.PLANET_SIZE_MAP,
		},
		infoDisplay = {
			image = image,
			size = planetUtilities.PLANET_SIZE_INFO,
			backgroundImage = planetUtilities.backgroundImages[math.floor(math.random()*#planetUtilities.backgroundImages) + 1],
			terrainType = "Asteroid",
			radius = "220 km",
			primary = "None",
			primaryType = "N/A",
			milRating = 1,
			feedbackLink = "http://zero-k.info/Forum/Thread/24441",
			text = "On this asteroid is the most powerful communication network of the sector, and its defenses have significantly decayed over time."
			.. "\n "
			.. "\nInterstellar pursuit forces from many worlds have kept dogging me. I can easily outrun them, but no-one is safe from a mistake. With this network, I should be able to shake them off my trail for good."
			,
			extendedText = "All I need to do is to bring my Commander close enough to the Interception Network structure and upload a new set of instructions."
			.. "\n "
			.. "\nShieldbots should do well on this rough terrain."
		},
		tips = {
			{
				image = "unitpics/shieldcon.png",
				text = [[The Shieldbot constructor and assault, Convict and Thug, are equipped with small shields which block incoming projectiles at the cost of shield power. Nearby shields share power, a shield that has recently sustained damage will take power from other nearby shields to compensate.]]
			},
			{
				image = "unitpics/shieldraid.png",
				text = [[Bandits are slower raiders than Glaives but compensate with superior health and range. They are exceptionally versatile units and are particularly effective while sheltered under the shield of a Convict or Thug.]]
			},
			{
				image = "unitpics/shieldriot.png",
				text = [[Outlaws wield an unconventional weapon: a disrupting pulse which damages and slows enemies (but not allies) in a wide radius. Compared to most riots it is very poor against single targets but exceptional when used to protect other units against raider assault.]]
			},
		},
		gameConfig = {
			mapName = "Apophis v2_3",
			playerConfig = {
				startX = 2300,
				startZ = 5900,
				allyTeam = 0,
				commanderParameters = {
					facplop = false,
					victoryAtLocation = {
						x = 5952,
						z = 2896,
						radius = 120,
						objectiveID = 1,
					},
					defeatIfDestroyedObjectiveID = 3,
				},
				extraUnlocks = {
					"factoryshield",
					"shieldcon",
					"shieldraid",
					"shieldassault",
					"shieldriot",
				},
				startUnits = {
					{
						name = "factoryshield",
						x = 2400,
						z = 5712,
						facing = 2,
					},
					{
						name = "staticmex",
						x = 2520,
						z = 5992,
						facing = 0,
					},
					{
						name = "staticmex",
						x = 2856,
						z = 5976,
						facing = 0,
					},
					{
						name = "staticmex",
						x = 2696,
						z = 5704,
						facing = 0,
					},
					{
						name = "energysolar",
						x = 2632,
						z = 5960,
						facing = 0,
					},
					{
						name = "energysolar",
						x = 2760,
						z = 5896,
						facing = 0,
					},
					{
						name = "energysolar",
						x = 2648,
						z = 5784,
						facing = 0,
					},
					{
						name = "shieldcon",
						x = 2536,
						z = 5624,
						facing = 2,
					},
					{
						name = "shieldraid",
						x = 2444,
						z = 5555,
						facing = 2,
					},
					{
						name = "shieldraid",
						x = 2493,
						z = 5511,
						facing = 2,
					},
					{
						name = "shieldraid",
						x = 2578,
						z = 5515,
						facing = 2,
					},
					{
						name = "shieldraid",
						x = 2627,
						z = 5570,
						facing = 0,
					},
					{
						name = "staticradar",
						x = 2912,
						z = 5776,
						facing = 0,
					},
					{
						name = "turretmissile",
						x = 3504,
						z = 5808,
						facing = 0,
					},
					{
						name = "turretmissile",
						x = 3392,
						z = 5648,
						facing = 0,
					},
				}
			},
			aiConfig = {
				{
					startX = 4000,
					startZ = 2000,
					aiLib = "Circuit_difficulty_autofill",
					bitDependant = true,
					--aiLib = "Null AI",
					--bitDependant = false,
					humanName = "Farseers",
					commanderParameters = {
						facplop = false,
						bonusObjectiveID = 3,
					},
					allyTeam = 1,
					unlocks = {
						"staticmex",
						"staticradar",
						"energysolar",
						"cloakraid",
						"cloakriot",
					},
					difficultyDependantUnlocks = {
						[2] = {"cloakassault"},
						[3] = {"cloakassault","cloakcon"},
						[4] = {"cloakassault","cloakcon","cloakarty"},
					},
					commanderLevel = 2,
					commander = {
						name = "Panopticon",
						chassis = "engineer",
						decorations = {
						},
						modules = {
							"commweapon_lparticlebeam",
							"module_autorepair",
							"module_radarnet",
							"module_adv_targeting",
						}
					},
					startUnits = {
						{
							name = "energysolar",
							x = 2722,
							z = 2302,
							facing = 0,
							difficultyAtLeast = 2,
						},
						{
							name = "staticmex",
							x = 2746,
							z = 2215,
							facing = 0,
							difficultyAtLeast = 3,
						},
						{
							name = "staticmex",
							x = 5594,
							z = 2728,
							facing = 0,
							difficultyAtLeast = 4,
						},
						{
							name = "energysolar",
							x = 5574,
							z = 2836,
							facing = 0,
							difficultyAtLeast = 4,
						},
						{
							name = "cloakraid",
							x = 3864,
							z = 1750,
							facing = 0,
							difficultyAtLeast = 2,
						},
						{
							name = "cloakraid",
							x = 3864,
							z = 1775,
							facing = 0,
							difficultyAtLeast = 3,
						},
						{
							name = "cloakraid",
							x = 3864,
							z = 1799,
							facing = 0,
							difficultyAtLeast = 4,
						},
						{
							name = "turretlaser",
							x = 5823,
							z = 3039,
							facing = 0,
							difficultyAtMost = 2,
						},
						{
							name = "turretheavylaser",
							x = 5823,
							z = 3039,
							facing = 0,
							difficultyAtLeast = 3,
						},
						{
							name = "turretlaser",
							x = 5909 ,
							z = 3270,
							facing = 0,
						},
						{
							name = "factorycloak",
							x = 3864,
							z = 1656,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 4056,
							z = 1848,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 4280,
							z = 1656,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 4392,
							z = 1912,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 4344,
							z = 1784,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 4168,
							z = 1768,
							facing = 0,
						},
						{
							name = "turretlaser",
							x = 1600,
							z = 3696,
							facing = 0,
						},
						{
							name = "turretlaser",
							x = 1888,
							z = 3456,
							facing = 0,
						},
						{
							name = "turretlaser",
							x = 5760,
							z = 2832,
							facing = 0,
						},
						{
							name = "turretlaser",
							x = 6128,
							z = 2976,
							facing = 0,
						},
						{
							name = "turretmissile",
							x = 2576,
							z = 2992,
							facing = 0,
						},
						{
							name = "turretmissile",
							x = 3184,
							z = 2320,
							facing = 0,
						},
						{
							name = "turretmissile",
							x = 4080,
							z = 2256,
							facing = 0,
						},
						{
							name = "turretmissile",
							x = 4992,
							z = 2496,
							facing = 0,
						},
						{
							name = "staticradar",
							x = 3440,
							z = 1968,
							facing = 0,
						},
					}
				},
			},
			neutralUnits = {
				{
				name = "pw_interception",
				x = 5952,
				z = 2896,
				facing = 0,
				invincible = true,
				ignoredByAI = true,
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
					description = "Find the Interception Network, then bring your Commander to it",
				},
				[2] = {
					description = "Protect your Commander",
				},
			},
			bonusObjectiveConfig = {
				[1] = { -- Make six Thugs
					satisfyOnce = true,
					countRemovedUnits = true,
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 6,
					unitTypes = {
						"shieldassault",
					},
					image = planetUtilities.ICON_DIR .. "shieldassault.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.REPAIR,
					description = "Build 6 Thugs",
					experience = planetUtilities.BONUS_EXP,
				},
				[2] = {
					victoryByTime = 480,
					image = planetUtilities.ICON_OVERLAY.CLOCK,
					description = "Win by 8:00",
					experience = planetUtilities.BONUS_EXP,
				},
				[3] = { -- Kill enemy commander
					satisfyOnce = true,
					comparisionType = planetUtilities.COMPARE.AT_MOST,
					targetNumber = 0,
					-- See bonusObjectiveID in units table
					image = planetUtilities.ICON_DIR .. "engineer.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.ATTACK,
					description = "Destroy the enemy Commander",
					experience = planetUtilities.BONUS_EXP,
				},
			},
		},
		completionReward = {
			experience = planetUtilities.MAIN_EXP,
			units = {
				"factoryshield",
				"shieldcon",
				"shieldraid",
				"shieldassault",
				"shieldriot",
			},
			modules = {
				"module_adv_nano_LIMIT_A_1",
			},
			abilities = {
			},
			codexEntries = {
				"location_phisnet"
			},
		},
	}
	
	return planetData
end

return GetPlanet
