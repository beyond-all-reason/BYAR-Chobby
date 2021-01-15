--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Planet config

local function GetPlanet(planetUtilities, planetID)
	
	--local image = planetUtilities.planetImages[math.floor(math.random()*#planetUtilities.planetImages) + 1]
	local image = LUA_DIRNAME .. "images/planets/tundra02.png"
	
	local planetData = {
		name = "Tremontane",
		startingPlanet = false,
		mapDisplay = {
			x = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][1]) or 0.02,
			y = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][2]) or 0.40,
			image = image,
			size = planetUtilities.PLANET_SIZE_MAP,
		},
		infoDisplay = {
			image = image,
			size = planetUtilities.PLANET_SIZE_INFO,
			backgroundImage = planetUtilities.backgroundImages[math.floor(math.random()*#planetUtilities.backgroundImages) + 1],
			terrainType = "Tundra",
			radius = "4400 km",
			primary = "Taoune",
			primaryType = "F2III",
			milRating = 1,
			feedbackLink = "http://zero-k.info/Forum/Thread/24429",
			text = "This is where the raids on Myror were launched from. Either time or a counterattack crippled them, but the expeditionary force that had captured this world is still there."
			.. "\n "
			.. "\nWhile I should not underestimate them, what is left does not seem well-adapted for defending ground."
			,
			extendedText = "Ground forces seem to have almost entirely decayed, and they now rely on Gunships for combat. I will need anti-air Gremlins and Hacksaw missile turrets to bring them down."
		},
		tips = {
			{
				image = "unitpics/turretaaclose.png",
				text = [[The Hacksaw fires two powerful anti-air missiles at any flying target. It's defenseless against ground units and can be easily baited by cheap fliers, so they should be used in conjunction with other AA and land units.]]
			},
			{
				image = "unitpics/cloakaa.png",
				text = [[Gremlin anti-air bots cloak while they are not firing, so they have a secondary purpose as scouts.]]
			},
			{
				image = "unitpics/strike.png",
				text = [[Don't over-commit to anti-air units: the enemy Commander and defensive turrets still present a significant land-based threat.]]
			},
		},
		gameConfig = {
			mapName = "Avalanche v3.1",
			playerConfig = {
				startX = 580,
				startZ = 3500,
				allyTeam = 0,
				useUnlocks = true,
				commanderParameters = {
					facplop = false,
					defeatIfDestroyedObjectiveID = 2,
				},
				extraUnlocks = {
					"cloakaa",
					"turretaaclose",
				},
				startUnits = {
					{
						name = "factorycloak",
						x = 150,
						z = 3660,
						facing = 1,
					},
					{
						name = "turretaaclose",
						x = 700,
						z = 3000,
						facing = 2,
					},
					{
						name = "turretaaclose",
						x = 1150,
						z = 3500,
						facing = 1,
					},
					{
						name = "cloakraid",
						x = 1000,
						z = 3200,
						facing = 1,
					},
					{
						name = "cloakraid",
						x = 1100,
						z = 3250,
						facing = 1,
					},
					{
						name = "cloakraid",
						x = 1050,
						z = 3290,
						facing = 1,
					},
					{
						name = "cloakraid",
						x = 1100,
						z = 3260,
						facing = 1,
					},
					{
						name = "cloakraid",
						x = 1050,
						z = 3340,
						facing = 1,
					},
					{
						name = "staticradar",
						x = 110,
						z = 3180,
						facing = 2,
					},
					{
						name = "staticmex",
						x = 370,
						z = 3750,
						facing = 2,
					},
					{
						name = "turretmissile",
						x = 260,
						z = 3000,
						facing = 1,
					},
					{
						name = "turretmissile",
						x = 1200,
						z = 3800,
						facing = 1,
					},
				}
			},
			aiConfig = {
				{
					startX = 3800,
					startZ = 200,
					aiLib = "Circuit_difficulty_autofill",
					humanName = "_Havoc",
					bitDependant = true,
					allyTeam = 1,
					unlocks = {
						"gunshipcon",
						"gunshipraid",
						"gunshipemp",
						"gunshipbomb",
						"gunshipskirm",
						"staticmex",
					},
					difficultyDependantUnlocks = {
						[2] = {"energywind"},
						[3] = {"energywind","gunshipheavyskirm"},
						[4] = {"energywind","gunshipheavyskirm","gunshipassault"},
					},
					commanderParameters = {
						facplop = false,
						bonusObjectiveID = 3,
					},
					commanderLevel = 3,
					commander = {
						name = "Top_Gun",
						chassis = "strike",
						decorations = {
						},
						modules = {
							"commweapon_heavymachinegun",
							"module_radarnet",
						}
					},
					startUnits = {
						{
							name = "factorygunship",
							x = 3980,
							z = 110,
							facing = 0,
						},
						{
							name = "gunshipraid",
							x = 3000,
							z = 1000,
							facing = 0,
						},
						{
							name = "gunshipskirm",
							x = 3000,
							z = 1200,
							facing = 0,
						},
						{
							name = "gunshipemp",
							x = 3200,
							z = 1400,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 3110,
							z = 220,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 3910,
							z = 1030,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 3280,
							z = 100,
							facing = 0,
						},
						{
							name = "energysolar",
							x = 4000,
							z = 900,
							facing = 0,
						},
						{
							name = "turretriot",
							x = 3800,
							z = 2100,
							facing = 0,
						},
						{
							name = "turretriot",
							x = 1900,
							z = 400,
							facing = 3,
						},
						{
							name = "turretriot",
							x = 3500,
							z = 570,
							facing = 3,
						},
						{
							name = "turretlaser",
							x = 2960,
							z = 300,
							facing = 3,
						},
						{
							name = "turretemp",
							x = 3000,
							z = 400,
							facing = 3,
						},
						{
							name = "turretlaser",
							x = 3880,
							z = 1360,
							facing = 0,
						},
						{
							name = "turretemp",
							x = 3770,
							z = 1320,
							facing = 0,
						},
						{
							name = "turretemp",
							x = 4000,
							z = 1160,
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
						"factorygunship",
					},
					loseAfterSeconds = false,
					allyTeamLossObjectiveID = 1,
				},
			},
			objectiveConfig = {
				-- This is just related to displaying objectives on the UI.
				[1] = {
					description = "Destroy the enemy Gunship Factory",
				},
				[2] = {
					description = "Protect your Commander",
				},
			},
			bonusObjectiveConfig = {
				[1] = { -- Build 10 Gremlins
					satisfyOnce = true,
					countRemovedUnits = true, -- count units that previously died.
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 10,
					unitTypes = {
						"cloakaa",
					},
					image = planetUtilities.ICON_DIR .. "cloakaa.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.REPAIR,
					description = "Build 10 Gremlins",
					experience = planetUtilities.BONUS_EXP,
				},
				[2] = { -- Protect all Conjurers
					satisfyForever = true,
					failOnUnitLoss = true, -- Fails the objective if any units being used to satisfy the objective are lost.
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 0,
					unitTypes = {
						"cloakcon",
					},
					image = planetUtilities.ICON_DIR .. "cloakcon.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.GUARD,
					description = "Don't lose any Conjurers",
					experience = planetUtilities.BONUS_EXP,
				},
				[3] = { -- Kill enemy commander in 7:30
					satisfyByTime = 450,
					comparisionType = planetUtilities.COMPARE.AT_MOST,
					targetNumber = 0,
					-- See bonusObjectiveID in units table
					image = planetUtilities.ICON_DIR .. "strike.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.ATTACK,
					description = "Destroy the enemy commander before 7:30",
					experience = planetUtilities.BONUS_EXP,
				},
			},
		},
		completionReward = {
			experience = planetUtilities.MAIN_EXP,
			units = {
				"cloakaa",
				"turretaaclose",
			},
			modules = {
				"commweapon_lparticlebeam"
			},
			codexEntries = {
			},
		},
	}
	
	return planetData
end

return GetPlanet
