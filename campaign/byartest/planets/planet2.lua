--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Planet config

local function GetPlanet(planetUtilities, planetID)
	
	--local image = planetUtilities.planetImages[math.floor(math.random()*#planetUtilities.planetImages) + 1]
	local image = LUA_DIRNAME .. "images/planets/desert03.png"
	
	local planetData = {
		name = "Beth XVII",
		startingPlanet = false,
		mapDisplay = {
			x = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][1]) or 0.04,
			y = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][2]) or 0.73,
			image = image,
			size = planetUtilities.PLANET_SIZE_MAP,
		},
		infoDisplay = {
			image = image,
			size = planetUtilities.PLANET_SIZE_INFO,
			backgroundImage = planetUtilities.backgroundImages[math.floor(math.random()*#planetUtilities.backgroundImages) + 1],
			terrainType = "Desert",
			radius = "5950 km",
			primary = "Beth",
			primaryType = "G4V",
			milRating = 1,
			feedbackLink = "http://zero-k.info/Forum/Thread/24417",
			text = "Where is everyone? Automated systems and non-sapient life are still there, but no trace of intelligent beings. No humans, no cyborgs, no free machines, nothing..."
			.. "\n "
			.. "\nMost of the unit blueprints are gone. I will need to find new copies on my way out of here."
			,
			extendedText = "There are powerful close-range Stardust turrets and Reavers protecting them from my raiders. Once I have a Cloakbot Factory up and running, I will have to counter them with longer-ranged Ronins and open the way for taking their production systems out."
		},
		tips = {
			{
				image = "unitpics/turretriot.png",
				text = [[Stardusts are riot turrets which will shred any nearby units. Your Ronins can avoid this fate by attacking from just outside the Stardusts' range.]]
			},
			{
				image = "unitpics/cloakskirm.png",
				text = [[Ronins are skirmishers which can safely destroy Reavers from long range. Glaives are fast enough to close the distance while avoiding Ronin rockets.]]
			},
			{
				image = "unitpics/cloakcon.png",
				text = [[Instead of making a second factory, use constructors to assist your first one - it's more cost efficient.]]
			}
			-- {
				-- image = "unitpics/energysolar.png",
				-- text = [[Don't forget to build Metal Extractors and Solar Collectors to power your economy and build up a large army. Connect energy generators to your Mexes to overdrive them, giving you more metal income. (See the manual for more about overdrive.)]]
			-- },
		},
		gameConfig = {
			mapName = "Battle for PlanetXVII-v01",
			playerConfig = {
				startX = 3700,
				startZ = 3700,
				allyTeam = 0,
				useUnlocks = true,
				startMetal = 250,
				startEnergy = 250,
				commanderParameters = {
					facplop = true,
					defeatIfDestroyedObjectiveID = 2,
				},
				extraUnlocks = {
					"cloakskirm",
					"cloakriot",
				},
				startUnits = {
					{
						name = "staticradar",
						x = 3730,
						z = 3625,
						facing = 3,
					},
					{
						name = "staticradar",
						x = 3010,
						z = 2540,
						facing = 3,
					},
					{
						name = "turretriot",
						x = 2540,
						z = 3580,
						facing = 2,
					},
					{
						name = "turretriot",
						x = 3210,
						z = 3060,
						facing = 2,
					},
					{
						name = "turretriot",
						x = 3840,
						z = 2575,
						facing = 3,
					},
					{
						name = "cloakskirm",
						x = 3340,
						z = 3200,
						facing = 0,
					},
					{
						name = "cloakskirm",
						x = 3460,
						z = 3180,
						facing = 0,
					},
					{
						name = "cloakskirm",
						x = 3580,
						z = 3200,
						facing = 0,
					},
					{
						name = "cloakriot",
						x = 3380,
						z = 3280,
						facing = 0,
					},
					{
						name = "cloakriot",
						x = 3540,
						z = 3280,
						facing = 0,
					},
					{
						name = "staticmex",
						x = 3960,
						z = 3640,
						facing = 0,
					},
					{
						name = "energysolar",
						x = 3967,
						z = 3800,
						facing = 0,
					},
					{
						name = "staticmex",
						x = 3975,
						z = 4025,
						facing = 0,
					},
					{
						name = "energysolar",
						x = 3700,
						z = 4000,
						facing = 0,
					},
					{
						name = "staticmex",
						x = 3575,
						z = 3960,
						facing = 0,
					},
				},
			},
			aiConfig = {
				{
					startX = 400,
					startZ = 400,
					aiLib = "Circuit_difficulty_autofill",
					humanName = "Wubrior Master",
					bitDependant = true,
					startMetal = 250,
					startEnergy = 250,
					allyTeam = 1,
					unlocks = {
						"cloakraid",
						"cloakriot",
					},
					 difficultyDependantUnlocks = {
						 [3] = {"staticmex","energysolar"},
						 [4] = {"cloakcon","staticmex","energysolar"},
					 },
					commanderLevel = 2,
					commander = {
						name = "Wub Wub Wub",
						chassis = "guardian",
						decorations = {
						},
						modules = {
							"commweapon_beamlaser",
						}
					},
					startUnits = {
						{
							name = "staticradar",
							x = 1300,
							z = 1014,
							facing = 0,
						},
						{
							name = "turretriot",
							x = 2770,
							z = 1880,
							facing = 0,
						},
						{
							name = "turretriot",
							x = 850,
							z = 1660,
							facing = 0,
						},
						{
							name = "turretriot",
							x = 1830,
							z = 1230,
							facing = 0,
						},
						{
							name = "turretriot",
							x = 3177,
							z = 330,
							facing = 0,
						},
						{
							name = "factorycloak",
							x = 660,
							z = 770,
							facing = 0,
						},
						{
							name = "cloakriot",
							x = 660,
							z = 900,
							facing = 0,
						},
						{
							name = "cloakriot",
							x = 660,
							z = 1000,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 100,
							z = 135,
							facing = 2,
						},
						{
							name = "staticmex",
							x = 610,
							z = 500,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 1300,
							z = 135,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 1510,
							z = 350,
							facing = 0,
						},
						{
							name = "staticmex",
							x = 1800,
							z = 90,
							facing = 0,
						},
						{
							name = "energywind",
							x = 2700,
							z = 580,
							facing = 2,
						},
						{
							name = "energywind",
							x = 2675,
							z = 700,
							facing = 2,
						},
						{
							name = "energywind",
							x = 2700,
							z = 830,
							facing = 2,
						},
						{
							name = "energywind",
							x = 2650,
							z = 950,
							facing = 2,
						},
						{
							name = "energywind",
							x = 2600,
							z = 1070,
							facing = 2,
						},
						{
							name = "energysolar",
							x = 1450,
							z = 200,
							facing = 2,
						},
						{
							name = "energywind",
							x = 220,
							z = 130,
							facing = 2,
						},
					}
				},
			},
			terraform = {
				{
					terraformShape = planetUtilities.TERRAFORM_SHAPE.RECTANGLE,
					terraformType = planetUtilities.TERRAFORM_TYPE.LEVEL,
					position = {3808, 2544, 3808 + 48, 2544 + 48},
					height = 130,
					volumeSelection = planetUtilities.TERRAFORM_VOLUME.RAISE_ONLY,
				},
			},
			defeatConditionConfig = {
				-- Indexed by allyTeam.
				[0] = { },
				[1] = {
					ignoreUnitLossDefeat = false,
					vitalCommanders = true,
					vitalUnitTypes = {
						"factorycloak",
					},
					loseAfterSeconds = false,
					allyTeamLossObjectiveID = 1,
				},
			},
			objectiveConfig = {
				-- This is just related to displaying objectives on the UI.
				[1] = {
					description = "Destroy the enemy Commander and Cloakbot Factory",
				},
				[2] = {
					description = "Protect your Commander",
				},
			},
			bonusObjectiveConfig = {
					-- Indexed by bonusObjectiveID
				[1] = { -- plop your factory
					satisfyOnce = true,
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 1,
					unitTypes = {
						"factorycloak",
					},
					image = planetUtilities.ICON_DIR .. "factorycloak.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.REPAIR,
					description = "Build a Cloakbot Factory",
					experience = planetUtilities.BONUS_EXP,
				},
				[2] = { -- Have 10 mex
					satisfyOnce = true,
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 10,
					unitTypes = {
						"staticmex",
					},
					image = planetUtilities.ICON_DIR .. "staticmex.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.REPAIR,
					description = "Have 10 Metal Extractors",
					experience = planetUtilities.BONUS_EXP,
				},
				[3] = { -- Build 10 Ronins
					satisfyOnce = true,
					countRemovedUnits = true, -- count units that previously died.
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 13,
					unitTypes = {
						"cloakskirm",
					},
					image = planetUtilities.ICON_DIR .. "cloakskirm.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.REPAIR,
					description = "Build 10 Ronins",
					experience = planetUtilities.BONUS_EXP,
				},
				[4] = { -- Kill enemy Stardusts in 8 minutes.
					satisfyByTime = 480,
					comparisionType = planetUtilities.COMPARE.AT_MOST,
					targetNumber = 0,
					enemyUnitTypes = {
						"turretriot",
					},
					image = planetUtilities.ICON_DIR .. "turretriot.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.ATTACK,
					description = "Find and destroy all 4 enemy Stardust turrets before 8:00",
					experience = planetUtilities.BONUS_EXP,
				},
			},
		},
		completionReward = {
			experience = planetUtilities.MAIN_EXP,
			units = {
				"cloakskirm",
			},
			modules = {
				"commweapon_heavymachinegun",
				"module_high_power_servos_LIMIT_A_2",
			},
			codexEntries = {
				"entry_event",
				"threat_automata"
			},
		},
	}
	
	return planetData
end

return GetPlanet
