--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Planet config

local function GetPlanet(planetUtilities, planetID)
	
	--local image = planetUtilities.planetImages[math.floor(math.random()*#planetUtilities.planetImages) + 1]
	local image = LUA_DIRNAME .. "images/planets/swamp02.png"
	
	local planetData = {
		name = "Cygnet",
		startingPlanet = false,
		mapDisplay = {
			x = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][1]) or 0.13,
			y = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][2]) or 0.63,
			image = image,
			size = planetUtilities.PLANET_SIZE_MAP,
		},
		infoDisplay = {
			image = image,
			size = planetUtilities.PLANET_SIZE_INFO,
			backgroundImage = planetUtilities.backgroundImages[math.floor(math.random()*#planetUtilities.backgroundImages) + 1],
			terrainType = "Terran",
			radius = "5500 km",
			primary = "Adimasi",
			primaryType = "G7V",
			milRating = 1,
			feedbackLink = "http://zero-k.info/Forum/Thread/24417",
			text = "This world was a strategic chokepoint. There are extensive traces of combat damage, some ancient enough to be covered by once-thriving cities."
			.. "\n "
			.. "\nWhoever it was defending - or defending from - there is still an active defense network entrenched down there. I will have to punch through it, if I want access to that sector."
			,
			extendedText = "It is relying on a network of defensive turrets and shielded bots to keep its production infrastructure safe. I will need Slings to weaken its defenses and shields before I can commit to an assault. And I will need spotters for those Slings.",
		},
		tips = {
			{
				image = "unitpics/cloakarty.png",
				text = [[The Sling's cannon has the range to shoot turrets from safety but the Sling itself is weak and has short sight range. Keep out of direct combat.]]
			},
			{
				image = "unitpics/staticradar.png",
				text = [[Radar only reveals the approximate location of enemy forces so, in order to consistently hit their target, most artillery units require a spotter. Once a radar signature is identified as a structure it will no longer wobble.]]
			},
			{
				image = "unitpics/planelightscout.png",
				text = [[Morph a Radar Tower into a Sparrow scout plane to act as a spotter for your Slings. Conjurers may also be used as spotters, as long as they remain cloaked and stay away from enemies.]]
			},
			-- {
				-- image = "unitpics/cloakcon.png",
				-- text = [[The Conjurer's ability to cloak makes it an ideal spotter for Slings. Be carefuly moving around enemy territory as cloak is disrupted by proximity to enemy units and the use of most abilities.]]
			-- },
			--{
			--	image = "unitpics/shieldraid.png",
			--	text = [[Watch out for flanks by Bandits.]]
			--},
		},
		gameConfig = {
			mapName = "Wanderlust v03",
			playerConfig = {
				startX = 2600,
				startZ = 550,
				allyTeam = 0,
				useUnlocks = true,
				commanderParameters = {
					facplop = false,
					defeatIfDestroyedObjectiveID = 2,
				},
				extraUnlocks = {
					"cloakarty",
					"planelightscout",
				},
				startUnits = {
					{
						name = "staticradar",
						x = 2620,
						z = 630,
						facing = 0,
					},
					{
						name = "staticradar",
						x = 2925,
						z = 1605,
						facing = 0,
					},
					{
						name = "staticradar",
						x = 1750,
						z = 1139,
						facing = 0,
					},
					{
						name = "factorycloak",
						x = 2560,
						z = 800,
						facing = 0,
					},
					{
						name = "cloakcon",
						x = 2760,
						z = 800,
						facing = 0,
						commands = {
							{cmdID = planetUtilities.COMMAND.GUARD, atPosition = {2560, 800}},
							--{cmdID = planetUtilities.COMMAND.RAW_MOVE, pos = {1560, 800}, options = {"shift"}},
							--{unitName = "turretmissile", pos = {64, 64}, facing = 3, options = {"shift"}},
						},
					},
					{
						name = "cloakcon",
						x = 2360,
						z = 800,
						facing = 0,
						commands = {
							{cmdID = planetUtilities.COMMAND.GUARD, atPosition = {2560, 800}},
						},
					},
					{
						name = "cloakcon",
						x = 2327,
						z = 1400,
						facing = 0,
						commands = {
							{cmdID = planetUtilities.COMMAND.RAW_MOVE, pos = {2410, 2580}},
						},
					},
					{
						name = "turretlaser",
						x = 1300,
						z = 1350,
						facing = 0,
					},
					{
						name = "turretmissile",
						x =3000,
						z =1200,
						facing = 0,
					},
					{
						name = "turretmissile",
						x =3150,
						z =1150,
						facing = 0,
					},
					{
						name = "cloakriot",
						x =2650,
						z =1150,
						facing = 0,
					},
					{
						name = "cloakraid",
						x =2550,
						z =1180,
						facing = 0,
					},
					{
						name = "cloakraid",
						x =2520,
						z =1195,
						facing = 0,
					},
					{
						name = "cloakarty",
						x =2640,
						z =1050,
						facing = 0,
					},
					{
						name = "cloakarty",
						x =2540,
						z =1080,
						facing = 0,
					},
					{
						name = "staticmex",
						x = 2060,
						z = 330,
						facing = 0,
					},
					{
						name = "staticmex",
						x = 2620,
						z = 330,
						facing = 0,
					},
					{
						name = "staticmex",
						x = 3220,
						z = 250,
						facing = 0,
					},
					{
						name = "staticmex",
						x =2270,
						z =1040,
						facing = 0,
					},
					{
						name = "staticmex",
						x =1550,
						z =635,
						facing = 0,
					},
					{
						name = "energysolar",
						x =2190,
						z =300,
						facing = 0,
					},
					{
						name = "energysolar",
						x =2350,
						z =310,
						facing = 0,
					},
					{
						name = "energysolar",
						x =2510,
						z =305,
						facing = 0,
					},
					{
						name = "energysolar",
						x =2730,
						z =320,
						facing = 0,
					},
					{
						name = "energysolar",
						x =2890,
						z =330,
						facing = 0,
					},
					{
						name = "energysolar",
						x =3050,
						z =330,
						facing = 0,
					},
					{
						name = "energysolar",
						x =2180,
						z =970,
						facing = 0,
					},
					{
						name = "energysolar",
						x =2400,
						z =1040,
						facing = 0,
					},
					{
						name = "energysolar",
						x =2250,
						z =1190,
						facing = 0,
					},
				}
			},
			aiConfig = {
				{
					startX = 2300,
					startZ = 3800,
					aiLib = "Circuit_difficulty_autofill",
					humanName = "Targe Solus",
					bitDependant = true,
					allyTeam = 1,
					unlocks = {
						"shieldcon",
						--"shieldraid",
						"shieldassault",
						"turretmissile",
						"turretlaser",
					},
					difficultyDependantUnlocks = {
						[2] = {"staticmex","energysolar"},
						[3] = {"staticmex","energysolar","shieldraid"},
						[4] = {"staticmex","energysolar","shieldraid","shieldskirm"},
					},
					commanderLevel = 1,
					commander = {
						name = "Porcupine",
						chassis = "engineer",
						decorations = {
						},
						modules = {
							"commweapon_shotgun",
						}
					},
					startUnits = {
						{
							name = "shieldcon",
							x = 2860,
							z = 3800,
							facing = 2,
							difficultyAtLeast = 2,
						},
						{
							name = "shieldskirm",
							x = 2860,
							z = 3700,
							facing = 2,
							difficultyAtLeast = 2,
						},
						{
							name = "staticmex",
							x = 250,
							z = 3880,
							facing = 2,
							difficultyAtLeast = 3,
						},
						{
							name = "shieldcon",
							x = 2890,
							z = 3800,
							facing = 2,
							difficultyAtLeast = 3,
						},
						{
							name = "shieldassault",
							x = 2890,
							z = 3700,
							facing = 2,
							difficultyAtLeast = 3,
						},
						{
							name = "staticmex",
							x = 4910,
							z = 3760,
							facing = 2,
							difficultyAtLeast = 4,
						},
						{
							name = "shieldskirm",
							x = 2830,
							z = 3700,
							facing = 2,
							difficultyAtLeast = 4,
						},
						{
							name = "shieldassault",
							x = 2830,
							z = 3700,
							facing = 2,
							difficultyAtLeast = 4,
						},
						{
							name = "factoryshield",
							x = 2860,
							z = 3960,
							facing = 2,
						},
						{
							name = "turretheavylaser",
							x = 2750,
							z = 2750,
							facing = 2,
						},
						{
							name = "turretheavylaser",
							x =950,
							z =3040,
							facing = 2,
						},
						{
							name = "turretheavylaser",
							x =2280,
							z =3000,
							facing = 2,
						},
						{
							name = "turretheavylaser",
							x =2750,
							z =2990,
							facing = 2,
						},
						{
							name = "turretheavylaser",
							x =4400,
							z =2500,
							facing = 2,
						},
						{
							name = "turretriot",
							x =2460,
							z =2800,
							facing = 2,
						},
						{
							name = "turretriot",
							x =3068,
							z =2565,
							facing = 2,
						},
						{
							name = "turretriot",
							x =4750,
							z =2280,
							facing = 2,
						},
						{
							name = "turretriot",
							x = 2910,
							z = 3500,
							facing = 2,
						},
						{
							name = "energygeo",
							x = 3070,
							z = 3980,
							facing = 2,
						},
						{
							name = "staticmex",
							x = 1920,
							z = 3840,
							facing = 2,
						},
						{
							name = "staticmex",
							x = 2520,
							z = 3780,
							facing = 2,
						},
						{
							name = "staticmex",
							x = 3130,
							z = 3750,
							facing = 2,
						},
						{
							name = "staticmex",
							x = 2870,
							z = 3080,
							facing = 2,
						},
						{
							name = "staticmex",
							x = 770,
							z =3180,
							facing = 2,
						},
						{
							name = "staticmex",
							x = 4970,
							z = 2330,
							facing = 2,
						},
						{
							name = "staticradar",
							x = 3420,
							z = 2860,
							facing = 2,
						},
						{
							name = "staticradar",
							x = 1020,
							z = 2180,
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
						"factoryshield",
					},
					loseAfterSeconds = false,
					allyTeamLossObjectiveID = 1,
				},
			},
			objectiveConfig = {
				-- This is just related to displaying objectives on the UI.
				[1] = {
					description = "Destroy the enemy Commander and Shieldbot Factory",
				},
				[2] = {
					description = "Protect your Commander",
				},
			},
			bonusObjectiveConfig = {
				-- Indexed by bonusObjectiveID
				[1] = { -- Build 12 Slings
					satisfyOnce = true,
					countRemovedUnits = true, -- count units that previously died.
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 12,
					unitTypes = {
						"cloakarty",
					},
					image = planetUtilities.ICON_DIR .. "cloakarty.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.REPAIR,
					description = "Build 12 Slings",
					experience = planetUtilities.BONUS_EXP,
				},
				[3] = { -- Win in 10 minutes
					victoryByTime = 600,
					image = planetUtilities.ICON_OVERLAY.CLOCK,
					description = "Win by 10:00",
					experience = planetUtilities.BONUS_EXP,
				},
				[2] = { -- Protect all mex
					satisfyForever = true,
					failOnUnitLoss = true, -- Fails the objective if any units being used to satisfy the objective are lost.
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 0,
					unitTypes = {
						"staticmex",
					},
					image = planetUtilities.ICON_DIR .. "staticmex.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.GUARD,
					description = "Don't lose any Metal Extractors",
					experience = planetUtilities.BONUS_EXP,
				},
			},
		},
		completionReward = {
			experience = planetUtilities.MAIN_EXP,
			units = {
				"cloakarty",
				"planelightscout",
			},
			modules = {
				"module_adv_targeting_LIMIT_D_2",
			},
			codexEntries = {
				"faction_union"
			},
		},
	}
	
	return planetData
end

return GetPlanet
