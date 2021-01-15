--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Planet config

local function GetPlanet(planetUtilities, planetID)
	
	local image = planetUtilities.planetImages[math.floor(math.random()*#planetUtilities.planetImages) + 1]
	
	local planetData = {
		name = "Pong",
		startingPlanet = false,
		mapDisplay = {
			x = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][1]) or 0.22,
			y = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][2]) or 0.1,
			image = image,
			size = planetUtilities.PLANET_SIZE_MAP,
		},
		infoDisplay = {
			image = image,
			size = planetUtilities.PLANET_SIZE_INFO,
			backgroundImage = planetUtilities.backgroundImages[math.floor(math.random()*#planetUtilities.backgroundImages) + 1],
			terrainType = "Terran",
			radius = "6700 km",
			primary = "Tau Ceti",
			primaryType = "G8",
			milRating = 1,
			text = [[Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
			Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
			Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.
			Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.]]
		},
		gameConfig = {
			mapName = "TitanDuel",
			playerConfig = {
				startX = 1800,
				startZ = 1800,
				allyTeam = 0,
				facplop = true,
				commanderParameters = {
					victoryAtLocation = {
						x = 600,
						z = 1200,
						radius = 100,
						objectiveID = 4,
					},
					facplop = true,
					defeatIfDestroyedObjectiveID = 2,
				},
				extraUnlocks = {
					"factoryshield",
					"shieldfelon",
					"armdeva",
					"armfus",
					"corllt",
				},
				startUnits = {
					{
						name = "corllt",
						x = 1000,
						z = 300,
						facing = 2,
					},
					{
						name = "armfus",
						x = 1000,
						z = 500,
						facing = 1,
					},
					{
						name = "armfus",
						x = 1200,
						z = 500,
						facing = 0,
					},
					{
						name = "armnanotc",
						x = 1000,
						z = 400,
						facing = 2,
					},
					{
						name = "armwar",
						x = 850,
						z = 850,
						facing = 0,
						bonusObjectiveID = 4,
					},
					{
						name = "blackdawn",
						x = 2200,
						z = 2200,
						facing = 0,
					},
					{
						name = "blackdawn",
						x = 2250,
						z = 2200,
						facing = 0,
					},
					{
						name = "blackdawn",
						x = 2300,
						z = 2200,
						facing = 0,
					},
					{
						name = "blackdawn",
						x = 2350,
						z = 2200,
						facing = 0,
					},
					{
						name = "armpw",
						x = 900,
						z = 850,
						facing = 0,
						victoryAtLocation = {
							x = 600,
							z = 1200,
							radius = 100,
							objectiveID = 4,
						},
						defeatIfDestroyedObjectiveID = 3, -- Also captured
					},
					{
						name = "armwar",
						x = 850,
						z = 900,
						facing = 0,
					},
					{
						name = "armwar",
						x = 900,
						z = 900,
						facing = 0,
					},
					{
						name = "corsktl",
						x = 4210,
						z = 4670,
						facing = 0,
					},
					{
						name = "corsktl",
						x = 300,
						z = 300,
						facing = 0,
					},
				}
			},
			aiConfig = {
				{
					startX = 200,
					startZ = 200,
					aiLib = "Circuit_difficulty_autofill_ally",
					humanName = "Ally",
					bitDependant = true, -- Whether the AI name needs to be appended with 32bit or 64bit by the handler
					commanderParameters = {
						facplop = false,
					},
					allyTeam = 0,
					unlocks = {
						"factorycloak",
						"corllt",
						"cormex",
						"armsolar",
						"armpw",
						"armrock",
						"armwar",
						"armham",
					},
					commanderLevel = 5,
					commander = {
						name = "Verminyan",
						chassis = "engineer",
						decorations = {},
						modules = {
						  {
							"commweapon_shotgun",
							"module_radarnet"
						  },
						  {
							"module_adv_nano",
							"commweapon_personal_shield"
						  },
						  {
							"",
							"",
							"commweapon_shotgun"
						  },
						  {
							"",
							"",
							""
						  },
						  {
							"",
							"",
							""
						  }
						}
					}
				},
				{
					startX = 1250,
					startZ = 250,
					aiLib = "Circuit_difficulty_autofill_ally",
					humanName = "Another Ally",
					bitDependant = true, -- Whether the AI name needs to be appended with 32bit or 64bit by the handler
					commanderParameters = {
						facplop = false,
					},
					allyTeam = 0,
					unlocks = {
						"factorycloak",
						"corllt",
						"cormex",
						"armsolar",
						"armpw",
						"dante",
					},
					startUnits = {
						{
							name = "striderhub",
							x = 1000,
							z = 1300,
							facing = 2,
						},
						{
							name = "dante",
							x = 800,
							z = 1300,
							facing = 2,
							buildProgress = 0.4,
						},
					}
				},
				{
					startX = 3200,
					startZ = 3200,
					aiLib = "Circuit_difficulty_autofill",
					humanName = "Mortal Enemy",
					bitDependant = true,
					commanderParameters = {
						facplop = true,
						bonusObjectiveID = 5,
					},
					allyTeam = 1,
					unlocks = {
						"factorycloak",
						"corllt",
						"cormex",
						"armsolar",
						"armwar",
					},
					commanderLevel = 2,
					commander = {
						name = "You dig.",
						chassis = "engineer",
						decorations = {
						  "skin_support_dark",
						  icon_overhead = { image = "UW" }
						},
						modules = {
						  {
							"commweapon_beamlaser",
							"module_radarnet"
						  },
						  {
							"module_resurrect",
							"module_adv_nano"
						  },
						  {
							"module_adv_nano",
							"module_adv_nano",
							"commweapon_multistunner"
						  },
						  {
							"module_adv_nano",
							"module_adv_nano",
							"module_adv_nano"
						  },
						  {
							"module_adv_nano",
							"module_adv_nano",
							"module_cloak_field"
						  }
						}
					},
				},
			},
			defeatConditionConfig = {
				-- Indexed by allyTeam.
				[0] = {
					-- AllyTeam 0 is the players allyTeam. It can only have loseAfterSeconds.
					loseAfterSeconds = 60,
					timeLossObjectiveID = 1,
				},
				[1] = {
					-- The default behaviour, if no parameters are set, is the defeat condition of an
					-- ordinary game.
					-- If ignoreUnitLossDefeat is true then unit loss does not cause defeat.
					-- If at least one of vitalCommanders or vitalUnitTypes is set then losing all
					-- commanders (if vitalCommanders is true) as well as all the unit types in
					-- vitalUnitTypes (if there are any in the list) causes defeat.
					ignoreUnitLossDefeat = false,
					vitalCommanders = true,
					vitalUnitTypes = {
						"factorycloak",
					},
					loseAfterSeconds = false,
					allyTeamLossObjectiveID = 4,
				},
			},
			objectiveConfig = {
				-- This is just related to displaying objectives on the UI.
				[1] = {
					description = "Win before 1:00",
				},
				[2] = {
					description = "Protect your Commander",
				},
				[3] = {
					description = "Protect your Glaive",
				},
				[4] = {
					description = "Destroy enemy commanders and factories, move your Commander to the location or move your Glaive to the location.",
				},
			},
			bonusObjectiveConfig = {
				-- Indexed by bonusObjectiveID
				[1] = {
					victoryByTime = 50,
					image = planetUtilities.ICON_OVERLAY.CLOCK,
					description = "Win by 0:50",
					experience = planetUtilities.BONUS_EXP,
				},
				[2] = { -- Complete all bonus objectives
					completeAllBonusObjectives = true,
					image = planetUtilities.ICON_OVERLAY.ALL,
					description = "Complete all bonus objectives (in one battle).",
					experience = planetUtilities.BONUS_EXP,
				},
				-- victoryByTime is a special case. All other bonus objectives are based on unit counts.
				-- They have the following format:
				-- * Time Limit: Set by supplying either satisfyAtTime, satisfyByTime, satisfyUntilTime,
				--      satisfyAfterTime, satisfyForeverAfterFirstSatisfied or satisfyForever.
				-- * comparisionType: Set to either planetUtilities.COMPARE.AT_MOST, planetUtilities.COMPARE.AT_LEAST
				-- * targetNumber: The number which is compared to the unit count.
				-- * unitTypes: Unit types owned by the player that count towards the unit count.
				-- * enemyUnitTypes: Unit types owned by enemy allyTeams that count towards unit count.
				-- Note that experience is set in bonusObjectiveEffects
				-- Note that startUnits with bonusObjectiveID set count towards the unit count.
				[3] = { -- Have 3 Glaives by 35 seconds.
					satisfyByTime = 35,
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 3,
					unitTypes = {
						"armpw",
					},
					image = planetUtilities.ICON_DIR .. "armpw.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.REPAIR,
					description = "Have 3 Glaives by 0:35.",
					experience = planetUtilities.BONUS_EXP,
				},
				[4] = { -- Keep a particular Reaver alive for 30 seconds.
					satisfyUntilTime = 30,
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 1,
					-- See bonusObjectiveID in units table
					image = planetUtilities.ICON_DIR .. "armwar.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.GUARD,
					description = "Keep your Reaver alive until 0:30.",
					experience = planetUtilities.BONUS_EXP,
				},
				[5] = { -- Kill enemy commander in 30 seconds.
					satisfyByTime = 30,
					comparisionType = planetUtilities.COMPARE.AT_MOST,
					targetNumber = 0,
					-- See bonusObjectiveID in units table
					image = planetUtilities.ICON_DIR .. "engineer.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.ATTACK,
					description = "Kill the enemy commander before 0:30.",
					experience = planetUtilities.BONUS_EXP,
				},
				[6] = { -- Have at least one cloaky factory after first satisfied
					satisfyForeverAfterFirstSatisfied = true,
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 1,
					unitTypes = {
						"factorycloak",
					},
					image = planetUtilities.ICON_DIR .. "factorycloak.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.REPAIR,
					description = "Have at least one Cloakbot Factory once you do.",
					experience = planetUtilities.BONUS_EXP,
				},
				[7] = { -- Have 5 Glaives at any one time
					satisfyOnce = true,
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 5,
					unitTypes = {
						"armpw",
					},
					image = planetUtilities.ICON_DIR .. "armpw.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.REPAIR,
					description = "Have 5 Glaives.",
					experience = planetUtilities.BONUS_EXP,
				},
				[8] = { -- Build 5 Glaives
					satisfyOnce = true,
					countRemovedUnits = true, -- count units that previously died.
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 5,
					unitTypes = {
						"armpw",
					},
					image = planetUtilities.ICON_DIR .. "armpw.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.REPAIR,
					description = "Build 5 Glaives.",
					experience = planetUtilities.BONUS_EXP,
				},
				[9] = { -- Build and protect a cloaky factory
					satisfyForeverAfterFirstSatisfied = true,
					lockUnitsOnSatisfy = true, -- Makes the units used to satisfy the objective locked in once satisfied. This prevents overbuilding for leeway.
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 1,
					unitTypes = {
						"factorycloak",
					},
					image = planetUtilities.ICON_DIR .. "factorycloak.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.REPAIR,
					description = "Build and protect a Cloakbot factory.",
					experience = planetUtilities.BONUS_EXP,
				},
				[10] = { -- Protect all Reavers
					satisfyForever = true,
					failOnUnitLoss = true, -- Fails the objective if any units being used to satisfy the objective are lost.
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 0,
					unitTypes = {
						"armwar",
					},
					image = planetUtilities.ICON_DIR .. "armwar.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.GUARD,
					description = "Don't lose any Reavers.",
					experience = planetUtilities.BONUS_EXP,
				},
				[11] = { -- Make the enemy have no more than 3 LLT at 40 seconds.
					satisfyAtTime = 40,
					comparisionType = planetUtilities.COMPARE.AT_MOST,
					targetNumber = 4,
					enemyUnitTypes = {
						"corllt",
					},
					image = planetUtilities.ICON_DIR .. "corllt.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.ATTACK,
					description = "Less than 4 enemy LLTs at 0:40.",
					experience = planetUtilities.BONUS_EXP,
				},
			}
		},
		completionReward = {
			experience = planetUtilities.MAIN_EXP,
			units = {
				"cafus",
			},
			modules = {
			},
			abilities = {
				"terraform",
			}
		},
	}
	
	return planetData
end

return GetPlanet
