--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Planet config

local function GetPlanet(planetUtilities, planetID)
	
	--local image = planetUtilities.planetImages[math.floor(math.random()*#planetUtilities.planetImages) + 1]
	local image = LUA_DIRNAME .. "images/planets/arid01.png"
	
	local planetData = {
		name = "Shabun",
		startingPlanet = false,
		mapDisplay = {
			x = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][1]) or 0.45,
			y = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][2]) or 0.95,
			image = image,
			size = planetUtilities.PLANET_SIZE_MAP,
		},
		infoDisplay = {
			image = image,
			size = planetUtilities.PLANET_SIZE_INFO,
			backgroundImage = planetUtilities.backgroundImages[math.floor(math.random()*#planetUtilities.backgroundImages) + 1],
			terrainType = "Minimal",
			radius = "4650 km",
			primary = "Yasta",
			primaryType = "M0VI",
			milRating = 1,
			feedbackLink = "http://zero-k.info/Forum/Thread/24469",
			text = "This world's terraforming has been interrupted half-stage. While it is not a desert world anymore, and water is becoming abundant, few lifeforms have managed to adapt its still-toxic atmosphere."
			.. "\n "
			.. "\nI feel like this is a common theme in this sector, and judging by geological records, there seem to be cycles of terraforming collateral destruction from conflicts."
			,
			extendedText = "I have to launch an attack across the river, with an army capable of fighting underwater - the amphibious Duck raider and Scallop riot bots."
		},
		tips = {
			{
				image = "unitpics/amphraid.png",
				text = [[Ducks are slower than most raiders but they can move and heal underwater. They are armed with a dual purpose torpedo launcher which allows them to fight both above and below the water.]]
			},
			{
				image = "unitpics/amphriot.png",
				text = [[Scallops are armed with depth charges for underwater targets, and a shotgun for use on land. Both weapons are lethal up close.]]
			},
			{
				image = "unitpics/turrettorp.png",
				text = [[Urchin torpedo launchers are a cheap and reliable solution to underwater threats.]]
			},
			{
				image = "unitpics/energywind.png",
				text = [[When built in water, Wind Generators become Tidal Generators, which generate a constant amount of energy rather than the variable amount of Wind Generators.]]
			},
		},
		gameConfig = {

			mapName = "Rapids_v1",
			playerConfig = {
				startX = 3570,
				startZ = 100,
				allyTeam = 0,
				commanderParameters = {
					facplop = false,
					defeatIfDestroyedObjectiveID = 2,
				},
				extraUnlocks = {
					"factoryamph",
					"amphcon",
					"amphraid",
					"amphriot",
					"energywind",
				},
				startUnits = {
					{
						name = "staticmex",
						x = 3704,
						z = 472,
						facing = 1,
					},
					{
						name = "factoryamph",
						x = 3464,
						z = 664,
						facing = 0,
					},
					{
						name = "staticmex",
						x = 3272,
						z = 520,
						facing = 1,
					},
					{
						name = "staticmex",
						x = 3608,
						z = 856,
						facing = 1,
					},
					{
						name = "energysolar",
						x = 3656,
						z = 760,
						facing = 1,
					},
					{
						name = "energysolar",
						x = 3656,
						z = 584,
						facing = 1,
					},
					{
						name = "energysolar",
						x = 3544,
						z = 504,
						facing = 1,
					},
					{
						name = "energysolar",
						x = 3384,
						z = 504,
						facing = 1,
					},
					{
						name = "staticmex",
						x = 3880,
						z = 1688,
						facing = 1,
					},
					{
						name = "amphraid",
						x = 3464,
						z = 907,
						facing = 1,
					},
					{
						name = "amphraid",
						x = 3324,
						z = 736,
						facing = 1,
					},
					{
						name = "amphraid",
						x = 3251,
						z = 666,
						facing = 2,
					},
					{
						name = "staticcon",
						x = 3592,
						z = 680,
						facing = 1,
						commands = {
							{cmdID = planetUtilities.COMMAND.PATROL, pos = {3464, 472}},
						},
					},
					{
						name = "amphraid",
						x = 3409,
						z = 833,
						facing = 3,
					},
					{
						name = "amphcon",
						x = 3327,
						z = 818,
						facing = 3,
					},
					{
						name = "turretlaser",
						x = 2544,
						z = 384,
						facing = 0,
					},
					{
						name = "turretlaser",
						x = 3072,
						z = 1072,
						facing = 0,
					},
					{
						name = "turretlaser",
						x = 3680,
						z = 1504,
						facing = 0,
					},
					{
						name = "staticradar",
						x = 3520,
						z = 1040,
						facing = 0,
					},
				}
			},
			aiConfig = {
				{
					startX = 100,
					startZ = 3570,
					humanName = "Allegro",
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
						"staticstorage",
						"staticmex",
						"energywind",
						"energysolar",
						"turretlaser",
						"turretmissile",
						"turrettorp",
						"amphaa",
						"amphbomb",
						"amphcon",
						"amphfloater",
						"amphimpulse",
						"amphraid",
						"amphriot",
					},
					commanderLevel = 3,
					commander = {
						name = "Platypus",
						chassis = "engineer",
						decorations = {
						  "skin_support_zebra",
						},
						modules = {
							"commweapon_shotgun",
							"module_autorepair",
							"module_ablative_armor",
							"module_high_power_servos",
							"module_adv_nano",
						}
					},
					midgameUnits = {
						{
							name = "amphassault",
							x = 350,
							z = 3800,
							facing = 2,
							difficultyAtLeast = 4,
							spawnRadius = 50,
							delay = 6*30*60,
							orbitalDrop = true,
						},
						{
							name = "amphassault",
							x = 350,
							z = 3800,
							facing = 2,
							difficultyAtLeast = 4,
							spawnRadius = 50,
							delay = 9*30*60,
							orbitalDrop = true,
						},
						{
							name = "amphassault",
							x = 350,
							z = 3800,
							facing = 2,
							difficultyAtLeast = 4,
							spawnRadius = 50,
							delay = 12*30*60,
							orbitalDrop = true,
						},
					},
					startUnits = {
						{
							name = "amphriot",
							x = 840,
							z = 3455,
							facing = 0,
							difficultyAtLeast = 2,
						},
						{
							name = "staticmex",
							x = 2075,
							z = 2055,
							facing = 0,
							difficultyAtLeast = 3,
						},
						{
							name = "factoryamph",
							x = 670,
							z = 3420,
							facing = 2,
						},
						{
							name = "staticmex",
							x = 520,
							z = 3288,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 840,
							z = 3640,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 440,
							z = 3704,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 232,
							z = 2424,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 552,
							z = 3720,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 728,
							z = 3688,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 488,
							z = 3384,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 488,
							z = 3560,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 312,
							z = 2520,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 120,
							z = 2456,
							facing = 0,
						},
						{
							name = "turretlaser",
							x = 800,
							z = 2416,
							facing = 2,
						},
						{
							name = "turretlaser",
							x = 1024,
							z = 2544,
							facing = 2,
						},
						{
							name = "turrettorp",
							x = 376,
							z = 1880,
							facing = 2,
						},
						{
							name = "amphriot",
							x = 926,
							z = 3465,
							facing = 0,
						},
						{
							name = "turrettorp",
							x = 1496,
							z = 2712,
							facing = 2,
						},
						{
							name = "turrettorp",
							x = 2408,
							z = 3576,
							facing = 1,
						},
						{
							name = "turretlaser",
							x = 1520,
							z = 3008,
							facing = 1,
						},
						{
							name = "turretlaser",
							x = 1648,
							z = 3392,
							facing = 1,
						},
						{
							name = "turretlaser",
							x = 1952,
							z = 1952,
							facing = 2,
						},
						{
							name = "turretlaser",
							x = 2176,
							z = 2112,
							facing = 1,
						},
						{
							name = "staticcon",
							x = 648,
							z = 3592,
							facing = 1,
						},
						{
							name = "staticradar",
							x = 688,
							z = 3152,
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
						"factoryamph",
					},
					loseAfterSeconds = false,
					allyTeamLossObjectiveID = 1,
				},
			},
			objectiveConfig = {
				-- This is just related to displaying objectives on the UI.
				[1] = {
					description = "Destroy the enemy Amphbot Factory",
				},
				[2] = {
					description = "Protect your Commander",
				},
			},
			bonusObjectiveConfig = {
				[1] = { -- Make five Scallops
					satisfyOnce = true,
					countRemovedUnits = true, -- count units that previously died.
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 5,
					unitTypes = {
						"amphriot",
					},
					image = planetUtilities.ICON_DIR .. "amphriot.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.REPAIR,
					description = "Build 5 Scallops",
					experience = planetUtilities.BONUS_EXP,
				},
				[2] = { -- Own nine mex by 5:00
					satisfyByTime = 300,
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 9,
					unitTypes = {
						"staticmex",
					},
					image = planetUtilities.ICON_DIR .. "staticmex.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.REPAIR,
					description = "Have 9 Metal Extractors before 5:00",
					experience = planetUtilities.BONUS_EXP,
				},
			}
		},
		completionReward = {
			experience = planetUtilities.MAIN_EXP,
			units = {
				"amphraid",
				"amphriot",
			},
			modules = {
				"commweapon_shotgun",
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
