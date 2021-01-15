--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Planet config

local function GetPlanet(planetUtilities, planetID)
	
	--local image = planetUtilities.planetImages[math.floor(math.random()*#planetUtilities.planetImages) + 1]
	local image = LUA_DIRNAME .. "images/planets/tundra03.png"
	
	local planetData = {
		name = "Prasten",
		startingPlanet = false,
		mapDisplay = {
			x = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][1]) or 0.36,
			y = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][2]) or 0.105,
			image = image,
			size = planetUtilities.PLANET_SIZE_MAP,
		},
		infoDisplay = {
			image = image,
			size = planetUtilities.PLANET_SIZE_INFO,
			backgroundImage = planetUtilities.backgroundImages[math.floor(math.random()*#planetUtilities.backgroundImages) + 1],
			terrainType = "Tundra",
			radius = "4640 km",
			primary = "Wipapra",
			primaryType = "G7V",
			milRating = 1,
			feedbackLink = "http://zero-k.info/Forum/Thread/24510",
			text = "This world was on an interstellar crossroad. While it made it wealthy, it was to be its undoing. When neighbouring planets rebelled, it became a battlefield, a capital strategic prize to be fought over."
			.. "\n "
			.. "\nIts terraformation was destabilized by the constant battles, and now it is slowly reverting to the ice world it had once been."
			,
			extendedText = "This is not where I should be! Something went wrong with the landing. I must absolutely expand to the mainland from this resource-poor island using Charon and Hercules transports. Then I can use transports to create a highly mobile land army."
		},
		tips = {
			{
				image = "unitpics/gunshiptrans.png",
				text = [[The Charon can only transport light units but it is cheap and fast. Use them to reposition your slower, high-damage units (like Reavers) as required.]]
			},
			{
				image = "unitpics/gunshipheavytrans.png",
				text = [[A Hercules can transport any land unit and all but the largest ships. The online manual contains more tips and tricks for commanding Tranports effectively using Embark, area commands and ferry routes.]]
			},
			{
				image = "unitpics/gunshipemp.png",
				text = [[Gnat EMP gunships are too inaccurate to reliably hit raiders, but they are very effective at stunlocking medium-to-heavy units like Commanders.]]
			},
		},
		gameConfig = {
			mapName = "Iceland_v1",
			playerConfig = {
				startX = 3280,
				startZ = 7425,
				allyTeam = 0,
				commanderParameters = {
					facplop = true,
					defeatIfDestroyedObjectiveID = 2,
				},
				extraUnlocks = {
					"factorygunship",
					"gunshipcon",
					"gunshipraid",
					"gunshipemp",
					"gunshiptrans",
					"gunshipheavytrans",
					"energygeo",
				},
				startUnits = {
					{
						name = "factorygunship",
						x = 3672,
						z = 7544,
						facing = 0,
					},
					{
						name = "gunshipheavytrans",
						x = 3280,
						z = 7325,
						facing = 0,
					},
					{
						name = "staticmex",
						x = 3448,
						z = 7544,
						facing = 0,
					},
					{
						name = "cloakriot",
						x = 3330,
						z = 7625,
						facing = 0,
					},
					{
						name = "cloakriot",
						x = 3230,
						z = 7625,
						facing = 0,
					},
					{
						name = "cloakriot",
						x = 3130,
						z = 7625,
						facing = 0,
					},
					{
						name = "cloakriot",
						x = 3030,
						z = 7625,
						facing = 0,
					},
					{
						 name = "vehcapture",
						 x = 3080,
						 z = 7600,
						 facing = 0,
					 },
					 {
						 name = "vehcapture",
						 x = 3280,
						 z = 7600,
						 facing = 0,
					 },
					{
						name = "gunshiptrans",
						x = 3030,
						z = 7525,
						facing = 0,
					},
					{
						name = "gunshiptrans",
						x = 3330,
						z = 7525,
						facing = 0,
					},
					{
						name = "gunshiptrans",
						x = 3230,
						z = 7525,
						facing = 0,
					},
					{
						name = "gunshiptrans",
						x = 3130,
						z = 7525,
						facing = 0,
					},
					{
						name = "gunshiptrans",
						x = 3080,
						z = 7550,
						facing = 0,
					},
					{
						name = "gunshiptrans",
						x = 3280,
						z = 7550,
						facing = 0,
					},
					{
						name = "gunshipcon",
						x = 3080,
						z = 7425,
						facing = 2,
					},
					{
						name = "energysolar",
						x = 3512,
						z = 7560,
						facing = 1,
					},
					{
						name = "energysolar",
						x = 3432,
						z = 7608,
						facing = 0,
					},
					{
						name = "energysolar",
						x = 3384,
						z = 7528,
						facing = 3,
					},
					{
						name = "energysolar",
						x = 3464,
						z = 7480,
						facing = 2,
					},
					{
						name = "turretmissile",
						x = 4032,
						z = 7408,
						facing = 2,
					},
					{
						name = "turretmissile",
						x = 3600,
						z = 7232,
						facing = 2,
					},
					{
						name = "turretmissile",
						x = 3056,
						z = 7472,
						facing = 3,
					},
					{
						name = "staticradar",
						x = 3232,
						z = 7136,
						facing = 0,
					},
				}
			},
			aiConfig = {
				{
					startX = 6194,
					startZ = 1143,
					humanName = "Lawbringers",
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
						"staticradar",
						"energysolar",
						"energywind",
						"staticmex",
						-- no cloakcon is intentional
						"cloakraid",
						"cloakskirm",
						"cloakriot",
						-- no cloakaa is also intentional
						"shieldcon",
						"shieldraid",
						"shieldriot",
						"shieldskirm",
						"shieldassault",
						"shieldaa",
						"shieldbomb",
					},
					commanderLevel = 4,
					commander = {
						name = "Justicar",
						chassis = "strike",
						decorations = {
						},
						modules = {
							"commweapon_heavymachinegun",
							"commweapon_missilelauncher",
							"module_autorepair",
							"module_ablative_armor",
							"module_adv_nano",
							"module_high_power_servos",
							"module_adv_nano",
							"module_resurrect",
						}
					},
					startUnits = {
						{
							name = "factorycloak",
							x = 4184,
							z = 2448,
							facing = 0,
						},
						{
							name = "factoryshield",
							x = 6512,
							z = 1816,
							facing = 0,
						},
						{
							name = "turretheavylaser",
							x = 6424,
							z = 1616,
							facing = 2,
						},
						{
							name = "turretriot",
							x = 6364,
							z = 1937,
							facing = 3,
						},
						{
							name = "turretriot",
							x = 6666,
							z = 1860,
							facing = 1,
						},
						{
							name = "turretlaser",
							x = 4144,
							z = 5904,
							facing = 0,
						},
						{
							name = "turretriot",
							x = 3975,
							z = 2708,
							facing = 0,
						},
						{
							name = "turretriot",
							x = 4563,
							z = 2129,
							facing = 0,
						},
						{
							name = "turretlaser",
							x = 3920,
							z = 5696,
							facing = 3,
						},
						{
							name = "staticradar",
							x = 4080,
							z = 5728,
							facing = 3,
						},
						{
							name = "turretlaser",
							x = 1728,
							z = 6864,
							facing = 0,
						},
						{
							name = "turretmissile",
							x = 1328,
							z = 6624,
							facing = 3,
						},
						{
							name = "turretlaser",
							x = 5264,
							z = 6704,
							facing = 0,
						},
						{
							name = "turretmissile",
							x = 1776,
							z = 6336,
							facing = 2,
						},
						{
							name = "staticradar",
							x = 1616,
							z = 6592,
							facing = 2,
						},
						{
							name = "staticradar",
							x = 6672,
							z = 6656,
							facing = 0,
						},
						{
							name = "turretlaser",
							x = 6560,
							z = 6560,
							facing = 3,
						},
						{
							name = "turretlaser",
							x = 6704,
							z = 6784,
							facing = 0,
						},
						{
							name = "turretlaser",
							x = 1024,
							z = 5408,
							facing = 0,
						},
						{
							name = "staticradar",
							x = 1648,
							z = 4096,
							facing = 0,
						},
						{
							name = "turretmissile",
							x = 1808,
							z = 4160,
							facing = 0,
						},
						{
							name = "staticradar",
							x = 6336,
							z = 3968,
							facing = 0,
						},
						{
							name = "turretlaser",
							x = 6464,
							z = 4016,
							facing = 0,
						},
						{
							name = "turretmissile",
							x = 896,
							z = 3552,
							facing = 0,
						},
						{
							name = "turretlaser",
							x = 992,
							z = 3456,
							facing = 0,
						},
						{
							name = "turretlaser",
							x = 6960,
							z = 4992,
							facing = 0,
						},
						{
							name = "turretmissile",
							x = 1136,
							z = 3312,
							facing = 0,
						},
						{
							name = "turretlaser",
							x = 7392,
							z = 4560,
							facing = 3,
							buildProgress = 0.0916,
						},
						{
							name = "turretriot",
							x = 2776,
							z = 3656,
							facing = 0,
						},
						{
							name = "turretaalaser",
							x = 3000,
							z = 3576,
							facing = 0,
						},
						{
							name = "turretaalaser",
							x = 2648,
							z = 3480,
							facing = 0,
						},
						{
							name = "turretlaser",
							x = 2992,
							z = 3408,
							facing = 1,
						},
						{
							name = "turretaaclose",
							x = 5624,
							z = 4600,
							facing = 0,
						},
						{
							name = "turretaaclose",
							x = 5896,
							z = 4712,
							facing = 0,
						},
						{
							name = "turretlaser",
							x = 2736,
							z = 3344,
							facing = 2,
						},
						{
							name = "turretemp",
							x = 5664,
							z = 4816,
							facing = 0,
						},
						{
							name = "turretlaser",
							x = 5552,
							z = 4720,
							facing = 3,
						},
						{
							name = "turretlaser",
							x = 5792,
							z = 4912,
							facing = 1,
						},
						{
							name = "staticradar",
							x = 1840,
							z = 2112,
							facing = 2,
						},
						{
							name = "turretmissile",
							x = 5840,
							z = 4576,
							facing = 2,
						},
						{
							name = "staticmex",
							x = 4136,
							z = 2056,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 4536,
							z = 2456,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 4232,
							z = 2072,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 3992,
							z = 2056,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 4104,
							z = 2200,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 4136,
							z = 1944,
							facing = 0,
						},
						{
							name = "turretaaclose",
							x = 4296,
							z = 2744,
							facing = 0,
						},
						{
							name = "turretaalaser",
							x = 4744,
							z = 2248,
							facing = 0,
						},
						{
							name = "turretaalaser",
							x = 3896,
							z = 2472,
							facing = 0,
						},
						{
							name = "turretaaclose",
							x = 4344,
							z = 1960,
							facing = 0,
						},
						{
							name = "turretmissile",
							x = 1520,
							z = 2000,
							facing = 2,
						},
						{
							name = "turretmissile",
							x = 5456,
							z = 3360,
							facing = 0,
						},
						{
							name = "turretmissile",
							x = 2032,
							z = 1808,
							facing = 0,
						},
						{
							name = "staticradar",
							x = 6368,
							z = 1664,
							facing = 0,
						},
						{
							name = "turretaaclose",
							x = 6280,
							z = 2040,
							facing = 0,
						},
						{
							name = "turretaaclose",
							x = 6792,
							z = 1848,
							facing = 0,
						},
						{
							name = "turretaalaser",
							x = 6136,
							z = 1752,
							facing = 0,
						},
						{
							name = "turretaalaser",
							x = 6760,
							z = 1544,
							facing = 0,
						},
						{
							name = "turretlaser",
							x = 6304,
							z = 1856,
							facing = 0,
						},
						{
							name = "turretlaser",
							x = 6704,
							z = 1728,
							facing = 0,
						},
						{
							name = "turretlaser",
							x = 7104,
							z = 2992,
							facing = 0,
						},
						{
							name = "turretmissile",
							x = 7328,
							z = 2832,
							facing = 1,
						},
					}
				},
			},
			terraform = {
				{
					terraformShape = planetUtilities.TERRAFORM_SHAPE.RECTANGLE,
					terraformType = planetUtilities.TERRAFORM_TYPE.LEVEL,
					position = {3216, 7120, 3248, 7152},
					height = 250,
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
						"factorycloak",
					},
					loseAfterSeconds = false,
					allyTeamLossObjectiveID = 1,
				},
			},
			objectiveConfig = {
				-- This is just related to displaying objectives on the UI.
				[1] = {
					description = "Destroy both enemy factories",
				},
				[2] = {
					description = "Protect your Commander",
				},
			},
			bonusObjectiveConfig = {
				[1] = { -- Build 10 Gnats
					satisfyOnce = true,
					countRemovedUnits = true,
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 10,
					unitTypes = {
						"gunshipemp",
					},
					image = planetUtilities.ICON_DIR .. "gunshipemp.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.REPAIR,
					description = "Build 10 Gnats",
					experience = planetUtilities.BONUS_EXP,
				},
				[2] = { -- Control the enemy com
					satisfyOnce = true,
					capturedUnitsSatisfy = true,
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 1,
					unitTypes = {
						"dynstrike3_00",
					},
					image = planetUtilities.ICON_DIR .. "strike.png",
					--imageOverlay = planetUtilities.ICON_OVERLAY.ATTACK,
					description = "Capture the enemy Commander",
					experience = planetUtilities.BONUS_EXP,
				},
				[3] = { -- Have a geo by 8:00
					satisfyByTime = 480,
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 1,
					unitTypes = {
						"energygeo",
					},
					image = planetUtilities.ICON_DIR .. "energygeo.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.REPAIR,
					description = "Build a Geothermal Generator by 8:00",
					experience = planetUtilities.BONUS_EXP,
				},
			}
		},
		completionReward = {
			experience = planetUtilities.MAIN_EXP,
			units = {
				"gunshipemp",
				"gunshiptrans",
				"gunshipheavytrans",
			},
			modules = {
				"module_battle_drone_LIMIT_D_2",
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
