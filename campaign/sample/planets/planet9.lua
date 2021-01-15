--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Planet config

local function GetPlanet(planetUtilities, planetID)
	
	--local image = planetUtilities.planetImages[math.floor(math.random()*#planetUtilities.planetImages) + 1]
	local image = LUA_DIRNAME .. "images/planets/desert02.png"
	
	local planetData = {
		name = "Happika",
		startingPlanet = false,
		mapDisplay = {
			x = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][1]) or 0.11,
			y = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][2]) or 0.42,
			image = image,
			size = planetUtilities.PLANET_SIZE_MAP,
		},
		infoDisplay = {
			image = image,
			size = planetUtilities.PLANET_SIZE_INFO,
			backgroundImage = planetUtilities.backgroundImages[math.floor(math.random()*#planetUtilities.backgroundImages) + 1],
			terrainType = "Desert",
			radius = "6600 km",
			primary = "Xar",
			primaryType = "B2Ia",
			milRating = 1,
			feedbackLink = "http://zero-k.info/Forum/Thread/24457",
			text = "This ugly desert world would have been a large industrial hub at one time. Mineral resources, mostly flat terrain, calm weather, lying at an interstellar crossroads and no environment to ruin with pollution."
			.. "\n "
			.. "\nNo wonder they fought so hard to keep it. War vehicles are still crisscrossing its empty sand plains, eternally waiting for the next invasion."
			,
			extendedText = "Besides the occasional strange hills dotting the landscape, this is a smooth and level battlefield. This area is lightly defended, but local forces will start tapping into that resource extraction network as soon as I arrive to reinforce themselves. I should take as many extractors out as I can with Scorchers, as fast as possible."
		},
		tips = {
			{
				image = "unitpics/vehraid.png",
				text = [[The heatray weapon of the Scorcher does little damage at a distance and massive damage at close range. Move them right next to an enemy unit and watch it melt.]]
			},
			{
				image = "unitpics/vehriot.png",
				text = [[Rippers have low damage for a riot but make up for it with impressive speed and area of effect. They are very effective as escorts for other Rovers against raiders.]]
			},
			{
				image = "unitpics/vehassault.png",
				text = [[Ravagers are a fast assault unit that are even capable of outrunning some factory's raiders. They give up some of their toughness to achieve this.]]
			},
		},
		gameConfig = {
			mapName = "AlienDesert",
			playerConfig = {
				startX = 1475,
				startZ = 400,
				allyTeam = 0,
				useUnlocks = true,
				commanderParameters = {
					facplop = false,
					facing = 0,
					defeatIfDestroyedObjectiveID = 2,
				},
				extraUnlocks = {
					"factoryveh",
					"vehcon",
					"vehraid",
					"vehriot",
					"vehassault",
				},
				startUnits = {
					{
						name = "factoryveh",
						x = 1688,
						z = 312,
						facing = 0,
					},
					{
						name = "vehcon",
						x = 1475,
						z = 550,
						facing = 0,
						commands = {
							{cmdID = planetUtilities.COMMAND.RAW_MOVE, pos = {1550, 270}},
							{cmdID = planetUtilities.COMMAND.GUARD, atPosition = {1688, 312}, options = {"shift"}}
						},
					},
					{
						name = "vehraid",
						x = 1200,
						z = 550,
						facing = 0,
						commands = {
							{cmdID = planetUtilities.COMMAND.RAW_MOVE, pos = {200, 2300}},
						},
					},
					{
						name = "vehraid",
						x = 1300,
						z = 550,
						facing = 0,
						commands = {
							{cmdID = planetUtilities.COMMAND.RAW_MOVE, pos = {300, 2300}},
						},
					},
					{
						name = "vehraid",
						x = 1200,
						z = 650,
						facing = 0,
						commands = {
							{cmdID = planetUtilities.COMMAND.RAW_MOVE, pos = {400, 2300}},
						},
					},
					{
						name = "vehraid",
						x = 1300,
						z = 650,
						facing = 0,
						commands = {
							{cmdID = planetUtilities.COMMAND.RAW_MOVE, pos = {500, 2300}},
						},
					},
					{
						name = "vehraid",
						x = 1650,
						z = 550,
						facing = 1,
						commands = {
							{cmdID = planetUtilities.COMMAND.RAW_MOVE, pos = {4300,800}},
						},
					},
					{
						name = "vehraid",
						x = 1650,
						z = 650,
						facing = 1,
						commands = {
							{cmdID = planetUtilities.COMMAND.RAW_MOVE, pos = {4300,900}},
						},
					},
					{
						name = "vehraid",
						x = 1750,
						z = 550,
						facing = 1,
						commands = {
							{cmdID = planetUtilities.COMMAND.RAW_MOVE, pos = {4300,1000}},
						},
					},
					{
						name = "vehraid",
						x = 1750,
						z = 650,
						facing = 1,
						commands = {
							{cmdID = planetUtilities.COMMAND.RAW_MOVE, pos = {4300,1100}},
						},
					},
					{
						name = "staticradar",
						x = 2016,
						z = 928,
						facing = 0,
					},
					{
						name = "staticmex",
						x = 1560,
						z = 952,
						facing = 0,
					},
					{
						name = "staticmex",
						x = 2152,
						z = 440,
						facing = 0,
					},
					{
						name = "staticmex",
						x = 2536,
						z = 232,
						facing = 0,
					},
					{
						name = "staticmex",
						x = 376,
						z = 856,
						facing = 0,
					},
					{
						name = "energysolar",
						x = 2600,
						z = 40,
						facing = 0,
					},
					{
						name = "energysolar",
						x = 2600,
						z = 120,
						facing = 0,
					},
					{
						name = "staticmex",
						x = 72,
						z = 952,
						facing = 0,
					},
					{
						name = "energysolar",
						x = 2600,
						z = 200,
						facing = 0,
					},
					{
						name = "energysolar",
						x = 136,
						z = 936,
						facing = 0,
					},
					{
						name = "energysolar",
						x = 56,
						z = 1016,
						facing = 0,
					},
					{
						name = "energysolar",
						x = 2216,
						z = 456,
						facing = 0,
					},
					{
						name = "energysolar",
						x = 2136,
						z = 504,
						facing = 0,
					},
					{
						name = "energysolar",
						x = 1624,
						z = 936,
						facing = 0,
					},
					{
						name = "energysolar",
						x = 1576,
						z = 1016,
						facing = 0,
					},
					{
						name = "energysolar",
						x = 1496,
						z = 1016,
						facing = 0,
					},
					{
						name = "turretlaser",
						x = 1520,
						z = 960,
						facing = 0,
					},
					{
						name = "turretmissile",
						x = 336,
						z = 1104,
						facing = 0,
					},
					{
						name = "turretlaser",
						x = 2112,
						z = 448,
						facing = 0,
					},
					{
						name = "turretmissile",
						x = 272,
						z = 1120,
						facing = 0,
					},
					{
						name = "turretlaser",
						x = 2544,
						z = 192,
						facing = 0,
					},
					{
						name = "staticradar",
						x = 288,
						z = 1072,
						facing = 0,
					},
				},
			},
			aiConfig = {
				{
					startX = 4904,
					startZ = 3500,
					aiLib = "Circuit_difficulty_autofill",
					humanName = "Chamagut",
					bitDependant = true,
					commanderParameters = {
						facplop = false,
					},
					allyTeam = 1,
					unlocks = {
						"vehraid",
						"vehassault",
						"vehriot",
						"vehaa",
						"turretmissile",
						"energysolar",
						"staticradar",
					},
					difficultyDependantUnlocks = {
						[2] = {"staticmex"},
						[3] = {"staticmex","turretlaser"},
						[4] = {"staticmex","turretlaser"},
					},
					commanderLevel = 3,
					commander = {
						name = "Yuni Sellis",
						chassis = "assault",
						decorations = {
						},
						modules = {
							"commweapon_heavymachinegun",
							"module_dmg_booster",
							"module_ablative_armor",
							"module_autorepair",
						}
					},
					startUnits = {
						{
							name = "staticmex",
							x = 5128,
							z = 600,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 5288,
							z = 328,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 5896,
							z = 1016,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 6008,
							z = 1144,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 152,
							z = 3000,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 248,
							z = 3144,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 872,
							z = 3832,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 1016,
							z = 3544,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 3624,
							z = 3928,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 3992,
							z = 3720,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 4600,
							z = 3208,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 5896,
							z = 3304,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 6104,
							z = 3272,
							facing = 0,
						},
						{
							name = "factoryveh",
							x = 4904,
							z = 3640,
							facing = 2,
						},
						{
							name = "turretlaser",
							x = 5536,
							z = 3392,
							facing = 2,
						},
						{
							name = "energysolar",
							x = 3480,
							z = 3976,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 3576,
							z = 3832,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 3704,
							z = 3784,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 3800,
							z = 3704,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 3928,
							z = 3624,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 4504,
							z = 3208,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 4648,
							z = 3112,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 5992,
							z = 3336,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 5880,
							z = 1128,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 952,
							z = 3672,
							facing = 0,
						},
						{
							name = "turretmissile",
							x = 640,
							z = 3216,
							facing = 2,
						},
						{
							name = "turretmissile",
							x = 960,
							z = 3328,
							facing = 2,
						},
						{
							name = "turretmissile",
							x = 320,
							z = 3040,
							facing = 2,
						},
						{
							name = "turretlaser",
							x = 5408,
							z = 512,
							facing = 3,
						},
						{
							name = "turretlaser",
							x = 5904,
							z = 864,
							facing = 3,
						},
						{
							name = "turretemp",
							x = 4384,
							z = 3568,
							facing = 2,
							difficultyAtLeast = 2,
						},
						{
							name = "turretlaser",
							x = 4256,
							z = 3664,
							facing = 2,
						},
						{
							name = "turretlaser",
							x = 4496,
							z = 3456,
							facing = 2,
						},
						{
							name = "turretlaser",
							x = 3680,
							z = 3936,
							facing = 2,
						},
						{
							name = "turretlaser",
							x = 5872,
							z = 2944,
							facing = 2,
						},
						{
							name = "staticradar",
							x = 5136,
							z = 3376,
							facing = 0,
						},
						{
							name = "turretriot",
							x = 4904,
							z = 3336,
							facing = 2,
						},
						{
							name = "vehassault",
							x = 4619,
							z = 3745,
							facing = 2,
							difficultyAtLeast = 2,
						},
						{
							name = "vehassault",
							x = 4675,
							z = 3755,
							facing = 2,
							difficultyAtLeast = 2,
						},
						{
							name = "turretemp",
							x = 5456,
							z = 3488,
							facing = 2,
							difficultyAtLeast = 2,
						},
						{
							name = "vehassault",
							x = 4560,
							z = 3743,
							facing = 2,
							difficultyAtLeast = 2,
						},
						{
							name = "turretriot",
							x = 4920,
							z = 3832,
							facing = 2,
						},
						{
							name = "staticstorage",
							x = 4872,
							z = 4008,
							facing = 0,
							difficultyAtLeast = 2,
						},
						{
							name = "staticstorage",
							x = 4952,
							z = 3992,
							facing = 0,
							difficultyAtLeast = 3,
						},
						{
							name = "staticcon",
							x = 5050,
							z = 3700,
							facing = 0,
							difficultyAtLeast = 3,
						},
						{
							name = "vehcon",
							x = 5050,
							z = 3600,
							facing = 0,
							difficultyAtLeast = 3,
						},
					},
				}
			},
			defeatConditionConfig = {
				-- Indexed by allyTeam.
				[0] = { },
				[1] = {
					ignoreUnitLossDefeat = false,
					vitalCommanders = false,
					vitalUnitTypes = {
						"staticmex",
					},
					loseAfterSeconds = false,
					allyTeamLossObjectiveID = 1,
				},
			},
			objectiveConfig = {
				-- This is just related to displaying objectives on the UI.
				[1] = {
					description = "Destroy all of the enemy Metal Extractors",
				},
				[2] = {
					description = "Protect your Commander",
				},
			},
			bonusObjectiveConfig = {
				[1] = { -- Make the enemy lose eight mex by 1:30
					onlyCountRemovedUnits = true,
					satisfyByTime = 90,
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 8,
					enemyUnitTypes = {
						"staticmex",
					},
					image = planetUtilities.ICON_DIR .. "staticmex.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.ATTACK,
					description = "Destroy eight enemy Metal Extractors by 1:30",
					experience = planetUtilities.BONUS_EXP,
				},
				[2] = { -- Own twelve mex
					satisfyOnce = true,
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 12,
					unitTypes = {
						"staticmex",
					},
					image = planetUtilities.ICON_DIR .. "staticmex.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.REPAIR,
					description = "Have twelve Metal Extractors",
					experience = planetUtilities.BONUS_EXP,
				},
				[3] = { -- Win by 6:00
					victoryByTime = 360,
					image = planetUtilities.ICON_OVERLAY.CLOCK,
					description = "Win by 6:00",
					experience = planetUtilities.BONUS_EXP,
				},
			},
		},
		completionReward = {
			experience = planetUtilities.MAIN_EXP,
			units = {
				"factoryveh",
				"vehcon",
				"vehraid",
				"vehriot",
				"vehassault",
			},
			modules = {
				"module_adv_nano_LIMIT_I_1",
			},
			codexEntries = {
			},
		},
	}
	
	return planetData
end

return GetPlanet
