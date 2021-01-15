--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Planet config

local function GetPlanet(planetUtilities, planetID)
	
	--local image = planetUtilities.planetImages[math.floor(math.random()*#planetUtilities.planetImages) + 1]
	local image = LUA_DIRNAME .. "images/planets/terran03_damaged.png"
	
	local planetData = {
		name = "Hebat",
		startingPlanet = false,
		mapDisplay = {
			x = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][1]) or 0.22,
			y = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][2]) or 0.68,
			image = image,
			size = planetUtilities.PLANET_SIZE_MAP,
		},
		infoDisplay = {
			image = image,
			size = planetUtilities.PLANET_SIZE_INFO,
			backgroundImage = planetUtilities.backgroundImages[math.floor(math.random()*#planetUtilities.backgroundImages) + 1],
			terrainType = "Sylvan",
			radius = "3300 km",
			primary = "Voblaka",
			primaryType = "F9V",
			milRating = 1,
			feedbackLink = "http://zero-k.info/Forum/Thread/24429",
			text = "This world is covered with islands, with a surprising variety of defenses. Was it used for combat testing?"
			.. "\n "
			.. "\nMany of those islands seem isolated from each-other. I will only need to clear one, hopefully it won't contain any nasty surprises."
			,
			extendedText = "This battle is taking place at high altitude, I can use Wind Generators for cheap and efficient energy income."
			.. "\n "
			.. "\nThose Jumpbots I am up against seem rather strange. Not sure what the best tactics are against them, but I hope my Knight's lightning gun will help."
		},
		tips = {
			{
				image = "unitpics/energywind.png",
				text = [[Wind Generators generate an amount of energy that varies over time from 0 to 2.5 at sea level. If built at higher altitudes the worst-case outcome becomes better.]]
			},
			{
				image = "unitpics/cloakassault.png",
				text = [[Knights are much tougher than the other Cloakbots, and use a lightning gun to damage and stun enemy units. They're effective against medium-weight units and defenses.]]
			},
			{
				image = "unitpics/jumpraid.png",
				text = [[The enemy will use Pyros against you - they have flamethrowers to set your units on fire, and can jump over holes and cliffs.]]
			},
		},
		gameConfig = {
			mapName = "Fairyland 1.31",
			playerConfig = {
				startX = 370,
				startZ = 3500,
				allyTeam = 0,
				useUnlocks = true,
				commanderParameters = {
					facplop = true,
					defeatIfDestroyedObjectiveID = 2,
				},
				extraUnlocks = {
					"energywind",
					"cloakassault",
				},
				startUnits = {
					{
						name = "cloakcon",
						x = 200,
						z = 3550,
						facing = 1,
					},
					{
						name = "cloakassault",
						x = 800,
						z = 3400,
						facing = 1,
					},
					{
						name = "cloakassault",
						x = 800,
						z = 3600,
						facing = 1,
					},
					{
						name = "cloakraid",
						x = 950,
						z = 3500,
						facing = 1,
					},
					{
						name = "cloakraid",
						x = 910,
						z = 3350,
						facing = 1,
					},
					{
						name = "cloakraid",
						x = 990,
						z = 3650,
						facing = 1,
					},
					
				}
			},
			aiConfig = {
				{
					startX = 4800,
					startZ = 1600,
					aiLib = "Circuit_difficulty_autofill",
					humanName = "BurnForever",
					bitDependant = true,
					allyTeam = 1,
					unlocks = {
						"staticmex",
						"energywind",
						"jumpscout",
						"jumpraid",
					},
					difficultyDependantUnlocks = {
						 [2] = {"jumpcon"},
						 [3] = {"jumpcon","jumpassault"},
						 [4] = {"jumpcon","jumpassault"},
					 },
					commanderLevel = 2,
					commander = {
						name = "Firelord",
						chassis = "guardian",
						decorations = {
						},
						modules = {
							"commweapon_flamethrower",
							"commweapon_flamethrower",
						}
					},
					startUnits = {
						{
							name = "jumpcon",
							x = 5000,
							z = 2000,
							facing = 0,
						},
						{
							name = "factoryjump",
							x = 4200,
							z = 1400,
							facing = 0,
						},
						{
							name = "jumpassault",
							x = 4200,
							z = 1400,
							facing = 0,
							difficultyAtLeast = 4,
						},
						{
							name = "jumpblackhole",
							x = 4200,
							z = 2000,
							facing = 0,
							bonusObjectiveID = 2,
						},
						{
							name = "jumpraid",
							x = 4200,
							z = 2100,
							facing = 0,
							difficultyAtLeast = 2,
						},
						{
							name = "jumpblackhole",
							x = 4700,
							z = 400,
							facing = 0,
							bonusObjectiveID = 2,
						},
						{
							name = "jumpraid",
							x = 4200,
							z = 2100,
							facing = 0,
							difficultyAtLeast = 3,
						},
						{
							name = "jumpblackhole",
							x = 2620,
							z = 500,
							facing = 0,
							bonusObjectiveID = 2,
						},
						{
							name = "staticmex",
							x = 4646,
							z = 250,
							facing = 0,
							difficultyAtLeast = 2,
						},
						{
							name = "energysolar",
							x = 4750,
							z = 325,
							facing = 0,
							difficultyAtLeast = 2,
						},
						{
							name = "staticmex",
							x = 4860,
							z = 410,
							facing = 0,
							difficultyAtLeast = 4,
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
						"factoryjump",
					},
					loseAfterSeconds = false,
					allyTeamLossObjectiveID = 1,
				},
			},
			objectiveConfig = {
				-- This is just related to displaying objectives on the UI.
				[1] = {
					description = "Destroy the enemy Commander and Jumpbot Factory",
				},
				[2] = {
					description = "Protect your Commander",
				},
			},
			bonusObjectiveConfig = {
					-- Indexed by bonusObjectiveID
				[1] = { -- Build 25 Windgens
					satisfyOnce = true,
					countRemovedUnits = true, -- count units that previously died.
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 25,
					unitTypes = {
						"energywind",
					},
					image = planetUtilities.ICON_DIR .. "energywind.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.REPAIR,
					description = "Build 25 Wind Turbines",
					experience = planetUtilities.BONUS_EXP,
				},
				[2] = { -- Destroy the Placeholders
					satisfyOnce = true,
					comparisionType = planetUtilities.COMPARE.AT_MOST,
					targetNumber = 0,
					-- See bonusObjectiveID in units table
					image = planetUtilities.ICON_DIR .. "jumpblackhole.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.ATTACK,
					description = "Destroy all three enemy Placeholders",
					experience = planetUtilities.BONUS_EXP,
				},
				[3] = { -- Have 12 mex by 7:30.
					satisfyByTime = 450,
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 12,
					unitTypes = {
						"staticmex",
					},
					image = planetUtilities.ICON_DIR .. "staticmex.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.REPAIR,
					description = "Have 12 Metal Extractors by 7:30",
					experience = planetUtilities.BONUS_EXP,
				},
			},
		},
		completionReward = {
			experience = planetUtilities.MAIN_EXP,
			units = {
				"energywind",
				"cloakassault",
			},
			modules = {
				"commweapon_lightninggun",
			},
			codexEntries = {
			},
		},
	}
	
	return planetData
end

return GetPlanet
