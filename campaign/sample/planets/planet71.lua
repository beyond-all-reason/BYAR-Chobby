--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Planet config

local function GetPlanet(planetUtilities, planetID)
	
	--local image = planetUtilities.planetImages[math.floor(math.random()*#planetUtilities.planetImages) + 1]
	local image = LUA_DIRNAME .. "images/planets/barren01.png"
	
	local planetData = {
		name = "Musashi",
		startingPlanet = false,
		mapDisplay = {
			x = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][1]) or 0.45,
			y = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][2]) or 0.23,
			image = image,
			size = planetUtilities.PLANET_SIZE_MAP,
		},
		infoDisplay = {
			image = image,
			size = planetUtilities.PLANET_SIZE_INFO,
			backgroundImage = planetUtilities.backgroundImages[math.floor(math.random()*#planetUtilities.backgroundImages) + 1],
			terrainType = "Asteroid",
			radius = "670 km",
			primary = "Edo",
			primaryType = "K1",
			milRating = 1,
			feedbackLink = "http://zero-k.info/Forum/Thread/24489",
			text = "This remote moon used to broadcast rally races to the entire galaxy. Did I watch those? It feels oddly familiar."
			.. "\n "
			.. "\nI can still pick a signal up, some of the broadcast systems are still working to this day. The show must go on, I guess. Not letting petty distractions like the apocalypse get in the way."
			.. "\n "
			.. "\nLet's try and hack in, see if it rings any bells..."
			,
			extendedText = "...ok, this didn't do anything. Maybe that one?"
			.. "\n "
			.. "\n[Welcome, new challenger, and good luck for the Super Extreme Kodachi Rally! You will be starting---right now!]"
		},
		tips = {
			{
				image = "unitpics/staticmex.png",
				text = [[Your objective in each round is to destroy all the mexes, while killing enemy raiders who give chase and outsmarting fixed defenses. Each level adds increasingly deadlier challenges, so stay on your toes!]]
			},
			{
				image = "unitpics/shieldscout.png",
				text = [[To help you out, there are powerups scattered around the map. Touch them with a Kodachi to activate them.  More powerups will spawn at regular intervals.]]
			},
			{
				image = "unitpics/tankraid.png",
				text = [[If all your Kodachis are dead, you lose the round. Don't worry, you get to try again!]]
			},
		},
		gameConfig = {
			gameName = "Super Extreme Kodachi Rally",
			mapName = "Comet Catcher Redux v3.1",
			playerConfig = {
				startX = 300,
				startZ = 3800,
				allyTeam = 0,
				commanderParameters = {},
				extraUnlocks = {},
			},
			modoptions = {
				integral_disable_defence = 1,
				integral_disable_special = 1,
				cansavegame = 1,
			},
			aiConfig = {
				{
					startX = 4000,
					startZ = 75,
					aiLib = "Null AI",
					humanName = "Enemies",
					allyTeam = 1,
					unlocks = {
						"cloakraid",
						"shieldraid",
						"vehscout",
						"vehraid",
						"hoverraid",
						"jumpscout",
						"tankheavyraid",
						"cloakriot",
						"shieldriot",
						"vehsupport",
						"hoverriot",
						"jumpraid",
						"jumpskirm",
					},
					commander = false,
				},
			},
			defeatConditionConfig = {
				-- Indexed by allyTeam.
				[0] = {
					ignoreUnitLossDefeat = true,
				},
				[1] = {
					ignoreUnitLossDefeat = true,
				},
			},
			objectiveConfig = {
				[1] = {
					description = "Complete all rounds",
				},
			},
			bonusObjectiveConfig = {
				[1] = { -- Lose no more than 50 Kodachis
					onlyCountRemovedUnits = true,
					satisfyForever = true,
					comparisionType = planetUtilities.COMPARE.AT_MOST,
					targetNumber = 50,
					unitTypes = {
						"tankraid",
					},
					image = planetUtilities.ICON_DIR .. "tankraid.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.GUARD,
					description = "Do not lose more than 50 Kodachis",
					experience = planetUtilities.BONUS_EXP,
				},
				[2] = { -- Win by 30:00
					victoryByTime = 1800,
					image = planetUtilities.ICON_OVERLAY.CLOCK,
					description = "Win by 30:00",
					experience = planetUtilities.BONUS_EXP,
				},
			}
		},
		completionReward = {
			experience = planetUtilities.MAIN_EXP,
			modules = {
				"module_high_power_servos_LIMIT_C_2",
			},
			units = {
				"tankraid"
			},
			codexEntries = {
				"location_musashi",
			}
		},
	}
	
	return planetData
end

return GetPlanet
