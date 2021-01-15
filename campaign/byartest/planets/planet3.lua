--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Planet config

local function GetPlanet(planetUtilities, planetID)
	
	--local image = planetUtilities.planetImages[math.floor(math.random()*#planetUtilities.planetImages) + 1]
	local image = LUA_DIRNAME .. "images/planets/radiated02.png"
	
	local planetData = {
		name = "Myror",
		startingPlanet = false,
		mapDisplay = {
			x = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][1]) or 0.06,
			y = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][2]) or 0.56,
			image = image,
			size = planetUtilities.PLANET_SIZE_MAP,
		},
		infoDisplay = {
			image = image,
			size = planetUtilities.PLANET_SIZE_INFO,
			backgroundImage = planetUtilities.backgroundImages[math.floor(math.random()*#planetUtilities.backgroundImages) + 1],
			terrainType = "Alpine",
			radius = "1995 km",
			primary = "Magus",
			primaryType = "K4VI",
			milRating = 1,
			feedbackLink = "http://zero-k.info/Forum/Thread/24417",
			text = "This was a major military hub, I can detect the remains of staging grounds and logistic networks. With all those broken plateaus, this area would have been easier to defend. This is bad news for me, I will have to take those defenses out if I want to continue that way."
			.. "\n "
			.. "\nWhoever they were fighting, it was not going well. There is evidence of raids even here, the frontline would not have been far."
			,
			extendedText = "This AI seems to rely on raiding squads of Scorchers. Good thing I had time for scavenging, those Imp EMP bombs will be helpful for shutting them down."
		},
		tips = {
			{
				image = "unitpics/turretmissile.png",
				text = [[The Picket missile turret is very cheap, and in large numbers they are effective against both ground and air targets. Their fragility makes them a poor choice against anything which can survive their initial volley.]]
			},
			{
				image = "unitpics/cloakbomb.png",
				text = [[Imp EMP bombs will stun any nearby units when they explode. They are mostly a defensive tool, and don't kill anything themselves, so make sure you have other units like Reavers to finish the job.]]
			},
			{
				image = "unitpics/vehraid.png",
				text = [[The Scorchers' heat ray weapon is incredibly lethal at point-blank range. Destroy them from a distance or stun them with Imps before engaging.]]
			},
		},
		gameConfig = {
			mapName = "Adamantine Mountain 2",
			playerConfig = {
				startX = 3550,
				startZ = 1150,
				allyTeam = 0,
				useUnlocks = true,
				commanderParameters = {
					facplop = false,
					defeatIfDestroyedObjectiveID = 2,
				},
				extraUnlocks = {
					"cloakbomb",
					"turretmissile"
				},
				startUnits = {
					{
						name = "cloakriot",
						x = 3550,
						z = 1250,
						facing = 0,
						difficultyAtMost = 2,
					},
					{
						name = "factorycloak",
						x = 3276,
						z = 1138,
						facing = 0,
					},
					{
						name = "cloakcon",
						x = 3376,
						z = 1138,
						facing = 0,
						commands = {
							{cmdID = planetUtilities.COMMAND.GUARD, atPosition = {3276, 1138}},
						},
					},
					{
						name = "staticradar",
						x = 3820,
						z = 2880,
						facing = 3,
					},
					{
						name = "staticradar",
						x = 1050,
						z = 30,
						facing = 3,
					},
					{
						name = "staticmex",
						x = 3080,
						z = 980,
						facing = 0,
					},
					{
						name = "staticmex",
						x = 3280,
						z = 970,
						facing = 0,
					},
					{
						name = "staticmex",
						x = 3050,
						z = 1195,
						facing = 0,
					},
					{
						name = "staticmex",
						x = 3670,
						z = 1750,
						facing = 0,
					},
					{
						name = "energysolar",
						x = 3420,
						z = 850,
						facing = 0,
					},
					{
						name = "energysolar",
						x = 3420,
						z = 1010,
						facing = 0,
					},
					{
						name = "energysolar",
						x = 3600,
						z = 850,
						facing = 0,
					},
					{
						name = "energysolar",
						x = 3600,
						z = 1010,
						facing = 0,
					},
					{
						name = "energysolar",
						x = 3780,
						z = 850,
						facing = 0,
					},
					{
						name = "energysolar",
						x = 3780,
						z = 1020,
						facing = 0,
					},
					{
						name = "cloakbomb",
						x = 2050,
						z = 1700,
						facing = 0,
						commands = {
							{cmdID = planetUtilities.COMMAND.RAW_MOVE, pos = {2000, 1720}},
						},
					},
					
					{
						name = "cloakbomb",
						x = 3080,
						z = 2800,
						facing = 3,
						commands = {
							{cmdID = planetUtilities.COMMAND.RAW_MOVE, pos = {3060, 2520}},
						},
					},
					{
						name = "turretmissile",
						x = 1187,
						z = 890,
						facing = 0,
					},
					{
						name = "cloakbomb",
						x = 1200,
						z = 1200,
						facing = 3,
						commands = {
							{cmdID = planetUtilities.COMMAND.RAW_MOVE, pos = {1130, 1200}},
						},
					},
					{
						name = "turretmissile",
						x = 3300,
						z = 2360,
						facing = 0,
					},
					{
						name = "turretmissile",
						x = 3380,
						z = 2340,
						facing = 0,
					},
					{
						name = "turretmissile",
						x = 2700,
						z = 1560,
						facing = 0,
					},
					{
						name = "turretmissile",
						x = 2400,
						z = 975,
						facing = 0,
					},
					{
						name = "turretmissile",
						x = 2375,
						z = 900,
						facing = 3,
					},
				}
			},
			aiConfig = {
				{
					startX = 500,
					startZ = 2500,
					aiLib = "Circuit_difficulty_autofill",
					humanName = "Clowncaps",
					bitDependant = true,
					facplop = false,
					allyTeam = 1,
					unlocks = {
						"vehraid",
						--"vehscout",
					},
					difficultyDependantUnlocks = {
						[2] = {"vehriot",},
						[3] = {"vehriot","staticmex", "energysolar"},
						[4] = {"vehriot","staticmex", "energysolar", "vehcon", "vehassault"},
					},
					commanderLevel = 2,
					commander = {
						name = "BusDriver22",
						chassis = "recon",
						decorations = {
						},
						modules = {
							"commweapon_shotgun",
						}
					},
					startUnits = {
						{
							name = "turretriot",
							x = 340,
							z = 3380,
							facing = 0,
							difficultyAtLeast = 2,
						},
						{
							name = "staticmex",
							x = 2710,
							z = 3600,
							facing = 1,
							difficultyAtLeast = 3,
						},
						{
							name = "turretlaser",
							x = 2710,
							z = 3500,
							facing = 2,
							difficultyAtLeast = 3,
						},
						{
							name = "staticmex",
							x = 2900,
							z = 3750,
							facing = 1,
							difficultyAtLeast = 4,
						},
						{
							name = "staticmex",
							x = 2660,
							z = 3880,
							facing = 1,
							difficultyAtLeast = 4,
						},
						{
							name = "turretriot",
							x = 3000,
							z = 3700,
							facing = 1,
							difficultyAtLeast = 4,
						},
						{
							name = "factoryveh",
							x = 500,
							z = 2700,
							facing = 1,
						},
						{
							name = "turretlaser",
							x = 500,
							z = 2500,
							facing = 2,
						},
						{
							name = "staticcon",
							x = 300,
							z = 2700,
							facing = 1,
						},
						{
							name = "staticradar",
							x = 256,
							z = 1551,
							facing = 2,
						},
						{
							name = "staticradar",
							x = 2330,
							z = 4080,
							facing = 2,
						},
						{
							name = "staticmex",
							x = 215,
							z = 2645,
							facing = 2,
						},
						{
							name = "staticmex",
							x = 440,
							z = 3030,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 424,
							z = 3270,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 700,
							z = 3220,
							facing = 0,
						},
						{
							name = "vehraid",
							x = 1660,
							z = 3100,
							facing = 0,
						},
						{
							name = "vehraid",
							x = 262,
							z = 2220,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 550,
							z = 3160,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 400,
							z = 3150,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 250,
							z = 3160,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 600,
							z = 3330,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 620,
							z = 3480,
							facing = 0,
						},
						{
							name = "vehheavyarty",
							x = 1600,
							z = 3330,
							facing = 0,
							bonusObjectiveID = 2,
						},
						{
							name = "turretlaser",
							x = 2050,
							z = 3010,
							facing = 1,
						},
						{
							name = "turretlaser",
							x = 2070,
							z = 3500,
							facing = 1,
						},
						{
							name = "turretlaser",
							x = 570,
							z = 2050,
							facing = 2,
						},
						{
							name = "turretlaser",
							x = 1315,
							z = 2410,
							facing = 2,
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
						"factoryveh",
					},
					loseAfterSeconds = false,
					allyTeamLossObjectiveID = 1,
				},
			},
			objectiveConfig = {
				-- This is just related to displaying objectives on the UI.
				[1] = {
					description = "Destroy the enemy Commander and Rover Assembly",
				},
				[2] = {
					description = "Protect your Commander",
				},
			},
			bonusObjectiveConfig = {
					-- Indexed by bonusObjectiveID
				[1] = { -- Build 4 Conjurors
					satisfyOnce = true,
					countRemovedUnits = true, -- count units that previously died.
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 5, -- The player starts with a Conjurer
					unitTypes = {
						"cloakcon",
					},
					image = planetUtilities.ICON_DIR .. "cloakcon.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.REPAIR,
					description = "Build 4 Conjurers",
					experience = planetUtilities.BONUS_EXP,
				},
				[2] = { -- Destroy the Impaler
					satisfyOnce = true,
					comparisionType = planetUtilities.COMPARE.AT_MOST,
					targetNumber = 0,
					-- See bonusObjectiveID in units table
					image = planetUtilities.ICON_DIR .. "vehheavyarty.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.ATTACK,
					description = "Destroy the enemy Impaler",
					experience = planetUtilities.BONUS_EXP,
				},
				[3] = {
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
				"cloakbomb",
				"turretmissile"
			},
			modules = {
				"module_autorepair_LIMIT_C_2",
			},
			codexEntries = {
				"faction_union"
			},
		}
	}
	
	return planetData
end

return GetPlanet
