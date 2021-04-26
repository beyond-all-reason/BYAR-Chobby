--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Planet config

local function GetPlanet(planetUtilities, planetID)
	
	--local image = planetUtilities.planetImages[math.floor(math.random()*#planetUtilities.planetImages) + 1]
	local image = LUA_DIRNAME .. "images/planets/swamp03.png"
	
	local planetData = {
		predownloadMap = true,
		name = "Im Jaleth",
		mapDisplay = {
			x = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][1]) or 0.05,
			y = (planetUtilities.planetPositions and planetUtilities.planetPositions[planetID][2]) or 0.87,
			image = image,
			size = planetUtilities.PLANET_SIZE_MAP,
			hintText = "Click this planet to continue. The galaxy awaits.",
			hintSize = {468, 100},
		},
		infoDisplay = {
			image = image,
			size = planetUtilities.PLANET_SIZE_INFO,
			backgroundImage = planetUtilities.backgroundImages[math.floor(math.random()*#planetUtilities.backgroundImages) + 1],
			terrainType = "Terran",
			radius = "6550 km",
			primary = "Privni",
			primaryType = "G8V",
			milRating = 1,
			feedbackLink = "http://zero-k.info/Forum/Thread/24417",
			text = "How long have I been sleeping? Centuries? No, stars have drifted way too much. And this Commander- I have never seen anything like it. What was I doing in that thing?"
			.. "\n "
			.. "\nI cannot stay there. Those automata are everywhere, and when they are not fighting each-other, they attack me as soon as I stop moving."
			,
			extendedText = "I hoped to avoid local forces, but there are simply too many of them. Still, this battle should be straightforward. I will simply overwhelm them with an army of Glaives and Reavers, and then take that factory out."
			.. "\n "
			.. "\nI can do this."
		},
		tips = {
			{
				image = "unitpics/staticmex.png",
				text = [[Metal Extractors gather the metal required to build an army and crush your opponent. Take mex spots and build as many as you can. Press F4 to highlight mex spots and display their value.]]
			},
			{
				image = "unitpics/energysolar.png",
				text = [[All construction requires equal amounts of metal and energy. Build Solar Collectors to gather energy.]]
			},
			{
				image = "unitpics/cloakriot.png",
				text = [[Reavers are slower than Glaives, but their heavy machine guns allow them to fight Glaives efficiently even when outnumbered.]]
			},
		},
		gameConfig = {
			missionStartscript = false,
--			mapName = "Living Lands 4.1",
			playerConfig = {
				startX = 300,
				startZ = 3800,
				allyTeam = 0,
				commanderParameters = {
					facplop = false,
					defeatIfDestroyedObjectiveID = 2,
				},
				extraUnlocks = {
					"cloakriot",
					"cloakcon",
					"turretlaser",
					"staticradar",
				},
				startUnits = {
					{
						name = "turretlaser",
						x = 250,
						z = 3450,
						facing = 2,
					},
					{
						name = "turretlaser",
						x = 550,
						z = 3380,
						facing = 2,
						difficultyAtMost = 2,
					},
					{
						name = "turretlaser",
						x = 1000,
						z = 3550,
						facing = 1,
						difficultyAtMost = 3,
					},
					{
						name = "turretlaser",
						x = 1050,
						z = 3850,
						facing = 1,
					},
					{
						name = "turretlaser",
						x = 450,
						z = 2200,
						facing = 1,
					},
					{
						name = "staticmex",
						x = 170,
						z = 3900,
						facing = 2,
					},
					{
						name = "energysolar",
						x = 100,
						z = 3800,
						facing = 2,
					},
					{
						name = "cloakraid",
						x = 760,
						z = 3500,
						facing = planetUtilities.FACING.NORTH,
					},
					{
						name = "cloakraid",
						x = 840,
						z = 3500,
						facing = planetUtilities.FACING.NORTH,
					},
					{
						name = "factorycloak",
						x = 800,
						z = 3750,
						facing = 2,
					},
				}
			},
			aiConfig = {
				{
					startX = 4000,
					startZ = 75,
					aiLib = "Circuit_difficulty_autofill",
					humanName = "Enemy",
					bitDependant = true,
					commanderParameters = {
						facplop = false,
					},
					allyTeam = 1,
					unlocks = {
						"cloakraid",
					},
					difficultyDependantUnlocks = {
						 [3] = {"staticmex","energysolar"},
						 [4] = {"staticmex","energysolar","cloakcon"},
					 },
					commanderLevel = 2,
					commander = {
						name = "Most Loyal Opposition",
						chassis = "engineer",
						decorations = {
						  "skin_support_dark",
						},
						modules = {}
					},
					startUnits = {
						{
							name = "staticmex",
							x = 3630,
							z = 220,
							facing = 2,
						},
						{
							name = "staticmex",
							x = 3880,
							z = 200,
							facing = 2,
						},
						{
							name = "turretlaser",
							x = 3500,
							z = 200,
							facing = 3,
							difficultyAtLeast = 2,
						},
						{
							name = "turretlaser",
							x = 3700,
							z = 700,
							facing = 0,
							difficultyAtLeast = 3,
						},
						{
							name = "turretemp",
							x = 3400,
							z = 600,
							facing = 1,
							difficultyAtLeast = 4,
						},
						{
							name = "staticmex",
							x = 3880,
							z = 520,
							facing = 2,
						},
						{
							name = "energysolar",
							x = 3745,
							z = 185,
							facing = 2,
						},
						{
							name = "energysolar",
							x = 3960,
							z = 600,
							facing = 2,
						},
						{
							name = "factorycloak",
							x = 3750,
							z = 340,
							facing = 4,
							mapMarker = {
								text = "Destroy",
								color = "red"
							}
						},
					
					}
				},
			},
			defeatConditionConfig = {
				-- Indexed by allyTeam.
				[0] = { },
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
				[1] = { -- Have 3 mex by 1 minute.
					satisfyByTime = 60,
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 3,
					unitTypes = {
						"staticmex",
					},
					image = planetUtilities.ICON_DIR .. "staticmex.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.REPAIR,
					description = "Have 3 Metal Extractors by 1:00",
					experience = planetUtilities.BONUS_EXP,
				},
				[2] = { -- Have 3 solar by 2 minute.
					satisfyByTime = 120,
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 3,
					unitTypes = {
						"energysolar",
					},
					image = planetUtilities.ICON_DIR .. "energysolar.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.REPAIR,
					description = "Have 3 Solar Generators by 2:00",
					experience = planetUtilities.BONUS_EXP,
				},
				[3] = { -- Build a radar
					satisfyOnce = true,
					countRemovedUnits = true, -- count units that previously died.
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 1,
					unitTypes = {
						"staticradar",
					},
					image = planetUtilities.ICON_DIR .. "staticradar.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.REPAIR,
					description = "Build a Radar Tower",
					experience = planetUtilities.BONUS_EXP,
				},
				[4] = { -- Build 3 Reavers
					satisfyOnce = true,
					countRemovedUnits = true, -- count units that previously died.
					comparisionType = planetUtilities.COMPARE.AT_LEAST,
					targetNumber = 3,
					unitTypes = {
						"cloakriot",
					},
					image = planetUtilities.ICON_DIR .. "cloakriot.png",
					imageOverlay = planetUtilities.ICON_OVERLAY.REPAIR,
					description = "Build 3 Reavers",
					experience = planetUtilities.BONUS_EXP,
				},
				[5] = {
					victoryByTime = 480,
					image = planetUtilities.ICON_OVERLAY.CLOCK,
					description = "Win by 8:00",
					experience = planetUtilities.BONUS_EXP,
				},
			}
		},
		completionReward = {
			experience = planetUtilities.MAIN_EXP,
			units = {
				"cloakriot",
				"cloakcon",
				"turretlaser",
				"staticradar",
			},
			modules = {
				"module_dmg_booster_LIMIT_A_2",
			},
			abilities = {
			},
			codexEntries = {
				"location_im_jaleth",
				"entry_commander"
			}
		},
	}
	
	return planetData
end

return GetPlanet
