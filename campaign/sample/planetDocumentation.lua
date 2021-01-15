-- Documentation for planet definitions.

planetData = {
	name = "Pong", -- The name of the planet
	startingPlanet = false, -- Whether the planet is availible to be invaded at the start of the campaign.
	predownloadMap = false, -- Whether to have the lobby download this map as soon as it can.
	tutorialSkip = false, -- Whether to allow players to skip this planet as a tutorial.
	
	-- Position and image to be used on the map
	mapDisplay = {
		-- x,y is a proportion of the map area from the top left corner
		x = 0.22,
		y = 0.1,
		
		-- Image is a path to an image using the standard luaMenu directory structure.
		image = planetUtilities.planetImages[1],
		
		-- Size to display on the galaxy map. It is somewhat scaled by the size of the chobby window.
		size = planetUtilities.PLANET_SIZE_MAP,
		
		-- Text to display to the right of the planet when it is targeted.
		hintText = "Continue to the next planet",
		hintSize = {400, 200}, -- Size of the hint box
	},
	
	-- Information displayed on the invasion selection screen.
	infoDisplay = {
		image = planetUtilities.planetImages[1], -- Image path
		size = planetUtilities.PLANET_SIZE_INFO, -- size
		backgroundImage = planetUtilities.backgroundImages[math.floor(math.random()*#planetUtilities.backgroundImages) + 1], -- Background for the invasion screen
		terrainType = "Terran",
		radius = "6550 km",
		primary = "Origin",
		primaryType = "G8V",
		milRating = 1,
		feedbackLink = "http://zero-k.info/Forum/Thread/24489",
		text = [[Your first battle will be straightforward. You have been provided with a starting base. Construct an army of Glaives and Reavers and overwhelm your enemy.]]
		-- extendedText is optional and used as the text for the ingame briefing.
		extendedText = [[Something else]],
	},
	
	-- Tips are displayed on the ingame briefing screen
	tips = {
		-- Each tip can have an image which is a path in the zk game itself.
		{
			image = "unitpics/cloakarty.png",
			text = [[The Sling's cannon has the range to shoot turrets from safety but the Sling itself has a short sight range. Use other units such as Glaives or cloaked Conjurors to spot for your Slings.]]
		},
		{
			image = "unitpics/shieldraid.png",
			text = [[Watch out for flanks by Bandits.]]
		},
	},
	
	-- Configuration for everything related to playing the battle
	gameConfig = {
		-- Name of the mutator to use. For scripted missions.
		gameName = false,
		
		-- Map name, be careful of spaces.
		mapName = "Living Lands v2.03",
		
		-- List of modoptions to apply.
		-- Note that 1 is true and 0 is false for boolean modoptions.
		modoptions = {
			zombies = 1
		},
		
		-- Map of modoptions for particular difficulty levels. Duplicate keys override the general modoptions table.
		modoptionDifficulties = {
			[1] = {
				zombies = 0,
			},
		}
		
		-- Add arbitrary map markers
		mapMarkers = {
			{
				x = 600,
				z = 1200,
				text = "Walk Here",
				color = "green"
			},
		},
		
		-- Configuration for everything owned by the player.
		playerConfig = {
			-- start coordinates of the players commander
			startX = 300,
			startZ = 3800,
			
			-- AllyTeam of the player, always set this to zero.
			allyTeam = 0,
			
			-- Parameters of the player commander.
			commanderParameters = {
				-- Whether the commander starts with facplop
				facplop = false,
				
				-- Override start metal or energy, otherwise the default will be used.
				startMetal = 250,
				startEnergy = 250,
				
				-- Contributed to allyTeam defeat if the unit is destroyed. The objectiveID is purely for UI.
				-- Defeat if destroyed also triggers if the unit is captured.
				defeatIfDestroyedObjectiveID = 2,
				
				-- Causes victory for allyTeam if the unit reaches the location. The objectiveID is purely for UI.
				victoryAtLocation = {
					x = 600,
					z = 1200,
					radius = 100,
					objectiveID = 5,
				},
				
				-- Bonus objective which the unit counts towards.
				bonusObjectiveID = false,
			},
			
			-- A list of newton firezones.
			newtonFirezones = {
				{
					-- All newtons in this rectangle are grouped and given the firezone.
					newtons = {
						x1 = 7800,
						z1 = 3600,
						x2 = 8200,
						z2 = 4000,
					},
					firezone = {
						x1 = 7800,
						z1 = 3660,
						x2 = 8000,
						z2 = 3800,
					}
				}
			},
			
			-- Extra commander modules.
			extraModules = {
				{name = "module_jumpjet", count = 1, add = false},
				-- List of:
				--  * name - Module name. See commConfig.lua.
				--  * count - Number of copies of the module.
				--  * add - Boolean controlling whether count adds to the number of modules of
				--          the type the player has equiped or overwrites the number.
			},
			
			-- Extra unit unlocks that are availible to the player for the duration of the mission.
			extraUnlocks = {
				"factorycloak",
				"cloakraid",
				"cloakriot",
				"staticmex",
				"energysolar",
				"cloakcon",
			},
			
			-- Extra abilities that are availbile to the player
			extraAbilities = {
				"terraform",
			}
			
			-- The whitelist is a list of units that are not disabled for the mission.
			-- The blacklist is a list of units that are disabled for the mission.
			-- These tables are maps, leave them nil to not use them.
			unitWhitelist = nil
			unitBlacklist = {
				turretlaser = true,
			}
			
			-- Win by moving particular unit types to one or more locations.
			typeVictoryAtLocation = {
				cloakraid = {
					{
						x = 600,
						z = 1200,
						radius = 100,
						objectiveID = 5,
						-- Map markers added in map marker table.
					},
				}
			},
			
			-- Units that spawn at the start of the game.
			startUnits = {
				{
					-- Unit def name
					name = "cloakcon",
					
					-- Position and facing
					x = 900,
					z = 850,
					facing = 0,
					
					-- Duration of stun (in seconds) applied to the unit at the start of the game.
					stunTime = 2,
					
					-- Starting shield power as a factor of total shield capacity. Leave as nil for the default.
					shieldFactor = 0.8
					
					-- Set terraform height to make a Skydust
					terraformHeight = 30,
					
					-- Units have victoryAtLocation and defeatIfDestroyedObjectiveID identical to commanderParameters.
					-- Please do not set difficultyAtMost or difficultyAtLeast for initial units with victory/defeat parameters,
					-- who knows what would happen.
					victoryAtLocation = {
						x = 600,
						z = 1200,
						radius = 100,
						objectiveID = 5,
						
						-- Map marker will appear at the victory location. Only set for one unit otherwise duplicates will appear.
						mapMarker = {
							text = "Walk Here",
							color = "green"
						},
					},
					
					-- mapMarker can be set for allied or enemy start units with arbitrary text. The marker is removed on death.
					-- It does not follow the unit so only makes sense on stuctures.
					mapMarker = {
						text = "Protect",
						color = "green"
					},
					
					-- ObjectiveID is for mission UI. See objectiveConfig
					defeatIfDestroyedObjectiveID = 3,
					
					-- List of commands for the initial unit. They are issued in order.See ProcessUnitCommand in
					-- mission_galaxy_campaign_battle gadget.
					commands = {
						-- Commands have:
						--  * cmdID or unitName:
						--    - cmdID is the ID of the command
						--    - unitName is processed into the cmdID required to be a build order for that unit.
						--  * atPosition, pos, params or <nothing>:
						--    - atPosition sets the target of the command to be a unit standing quite close to the position specified.
						--    - pos is an x,z position for the command. This saves you (the mission writer) from looking up y positions.
						--    - params is raw parameter input. Use for state commands perhaps?
						--    - If none of the previous three are set then the command is a sent with no parameters. Use this, for
						--        example, for STOP, WAIT or, with unitName, for factory build order.
						--  * options - These are the modifiers for the command. Used mostly like they are on the keyboard. "shift", "ctrl",
						--    "alt", "meta". Remember to use "shift" for commands beyond the first.
						--  * facing - Build facing for a unitName command with pos.
						--  * radius - Radius of an area command with pos.
						
						{cmdID = planetUtilities.COMMAND.GUARD, atPosition = {2560, 800}},
						{cmdID = planetUtilities.COMMAND.RAW_MOVE, pos = {1560, 800}, options = {"shift"}},
						{unitName = "turretmissile", pos = {64, 64}, facing = 3, options = {"shift"}},
					},
					
					-- patrolRoute is a condensed way of issuing commands to patrol in a route. Do not use it and commands at the same time.
					patrolRoute = {
						{2236, 1635},
						{2742, 1521},
						{3369, 1548},
						{3305, 1691},
						{2767, 1602},
						{2420, 1671},
						{2240, 2052},
						{2477, 2432},
						{2286, 2570},
						{2077, 2102},
					}
					
					-- selfPatrol makes units patrol on the spot. Use for Caretakers
					selfPatrol = false,
					
					-- Whether the unit spawns can be conditional on the difficulty setting.
					-- Both 'at most' and 'at least' are availible and the usual usage would be to
					-- give allied units 'at most' and enemy units 'at least'.
					-- 1 = Easy, 2 = Medium, 3 = Hard, 4 = Brutal
					difficultyAtMost = nil,
					difficultyAtLeast = nil,
					
					-- Units with difficultyAtMost and difficultyAtLeast can have bonusObjectiveID but be careful to make sure that objective makes sense.
					-- See bonusObjectiveConfig
					bonusObjectiveID = false,
					
					-- 'notAutoAttacked = true' makes the unit not automatically targeted by anything. Mainly useful for neutral units.
					notAutoAttacked = false,
					-- Invicible units cannot die. They automatically have 'notAutoAttacked = true'
					invincible = false,
				},
				{
					name = "turretlaser",
					x = 300,
					z = 3450,
					facing = 2,
				},
				{
					name = "armwar",
					x = 850,
					z = 900,
					facing = 0,
					bonusObjectiveID = 1,
				},
				-- etc...
			},
			-- Reinforcements that occur midgame.
			midgameUnits = {
				-- Share all keys with startUnits except terraformHeight
				-- Midgame units automatically check their spawn location for terrain and structure blockages.
				--  * delay - Time, in frames, into the mission that the unit is spawned. Required.
				--  * spawnRadius - Spawn the unit in a random location in a square with sidelength 2*spawnRadius.
				--  * orbitalDrop - Set to true to use the orbital drop effect. This can also be set for initial units.
				--  * repeatDelay - Time in frames for the midgame unit to be repeated.
				{
					name = "cloakriot",
					x = 2400,
					z = 460,
					facing = 1,
					spawnRadius = 50,
					
					delay = 4*30,
					orbitalDrop = true,
				},
				{
					name = "cloakriot",
					x = 2500,
					z = 300,
					facing = 1,
					spawnRadius = 50,
					
					delay = 4*30,
					orbitalDrop = true,
				},
			},
		},
		
		-- Set of neutral units to spawn. Same format as startUnits
		neutralUnits = {
			{
				name = "turretlaser",
				x = 32,
				z = 32,
				facing = 2,
				invincible = true,
			},
		},
		
		-- List of wrecks to spawn. Names tend to be "_dead" and "_heap". Actually spawns any feature.
		initialWrecks = {
			{
				-- Feature def name
				name = "factorycloak_dead",
				
				-- Position and facing. Leave out facing for a random facing.
				x = 1300,
				z = 3750,
				facing = 2,
				
				-- Whether the feature spawns can be conditional on the difficulty setting. Not sure why.
				-- 1 = Easy, 2 = Medium, 3 = Hard, 4 = Brutal
				difficultyAtMost = nil,
				difficultyAtLeast = nil,
			},
		}
		
		-- Configuration for all the AI teams in the game. These are mostly the same as player config.
		aiConfig = {
			{
				-- Start position for AI commander. Better set this even if it has no commander since circuit or Spring may require it.
				startX = 4000,
				startZ = 75,
				
				-- ai library to use to run the AI. Can be any valid AI name string which player are sure to have. See LuaAI.lua in the root directory
				-- of the Zero-K game repository for availible lua AIs, "Null AI" is an entry where which creates a completely passive AI. (For Null AI bitDependant should be set to false.)
				-- If aiLib is a key found in campaignData.aiConfig.aiLibFunctions then it had better be a function that returns an AI appropriate for the
				-- difficulty level. 'Circuit_difficulty_autofill' is one such entry, see aiConfig.lua.
				aiLib = "Circuit_difficulty_autofill",
				
				-- AI name on the playerlist.
				humanName = "Enemy",
				
				-- If bitDependant is true then '32' or '64' will be appended to the final AI name as required by the users system. This is for native AIs
				-- that are compiled to particular systems.
				bitDependant = true,
				
				-- Commander parameters is identical to playerConfig.
				commanderParameters = {
					facplop = false,
				},
				
				-- Ally team of the AI
				allyTeam = 1,
				
				-- Units that the AI can build
				unlocks = {
					"cloakraid",
				},
				
				-- Additional that the AI can build at particular difficulty levels. Indexed by difficulty, don't need to set empty entries.
				-- Don't double up entries with the standard unlocks table or I'll be annoyed.
				difficultyDependantUnlocks = {
					[1] = {"cloakarty"},
					[3] = {"cloakskirm"},
				},
				
				-- Level of the AI commander, if it exists
				commanderLevel = 2,
				
				-- Name and loadout of the AI commander. Set 'commander = false' to not give the AI a commander.
				commander = {
					name = "Most Loyal Opposition",
					chassis = "engineer",
					decorations = {
						"skin_support_dark",
						icon_overhead = {
							image = "UW"
						},
					},
					-- This is just a list of modules. It does not care about slots or levels.
					modules = {
						"commweapon_shotgun",
					}
				},
				
				-- Start units are mostly identical to player config. Exceptions:
				--  * noControl - Set to true to make circuitAI not give any commands to the unit.
				startUnits = {
					{
						name = "staticmex",
						x = 3630,
						z = 220,
						facing = 2,
						noControl = true,
					},
					{
						name = "factorycloak",
						x = 3750,
						z = 340,
						facing = 4,
					},
				},
				-- midgameUnits is identical to playerConfig
				midgameUnits = {
				},
			},
			{
				startX = 200,
				startZ = 200,
				aiLib = "Circuit_difficulty_autofill",
				humanName = "Ally",
				bitDependant = true, -- Whether the AI name needs to be appended with 32bit or 64bit by the handler
				commanderParameters = {
					facplop = false,
				},
				allyTeam = 0,
				unlocks = {
					"dante",
				},
				commanderLevel = 5,
				commander = false,
				startUnits = {
					{
						name = "striderhub",
						x = 1000,
						z = 1300,
						facing = 2,
						defeatIfDestroyedObjectiveID = 4,
					},
					-- etc...
				}
			},
			-- etc..
		},
		
		-- A list of terraforms to apply to the map prior to the game starting
		terraform = {
			-- Terraforms have:
			--  * terraformShape: This is required. Either RECTANGLE, LINE or RAMP
			--  * terraformType: Required for RECTANGLE and LINE. Either LEVEL, RAISE or SMOOTH
			--  * position:
			--    * RECTANGLE - {left, top, right, bottom}
			--    * LINE      - {x1, z1, x2, z2}
			--    * RAMP      - {x1, y1, z1, x2, y2, z2}
			--  * height: Required for LEVEL and RAISE. Absolute for the former and relative for the latter.
			--  * width: Required for RAMP.
			--  * volumeSelection: NONE, RAISE_ONLY or LOWER_ONLY
			--  * needConstruction: boolean. Set to true to create a terraunit.
			--  * teamID: number. This is for use with needConstruction.
			-- Note that terraform has all the restrictions of terraform that occurs during a game. Shapes such
			-- as very thin walls cannot be created.
			{
				terraformShape = planetUtilities.TERRAFORM_SHAPE.RECTANGLE,
				terraformType = planetUtilities.TERRAFORM_TYPE.LEVEL,
				position = {3808, 2544, 3808 + 48, 2544 + 48},
				height = 130,
				volumeSelection = planetUtilities.TERRAFORM_VOLUME.RAISE_ONLY,
			},
			{
				terraformShape = planetUtilities.TERRAFORM_SHAPE.RAMP,
				position = {290, 300, 3900, 765, 103, 3870},
				width = 200,
				volumeSelection = planetUtilities.TERRAFORM_VOLUME.LOWER_ONLY,
			},
			{
				terraformShape = planetUtilities.TERRAFORM_SHAPE.LINE,
				terraformType = planetUtilities.TERRAFORM_TYPE.RAISE,
				position = {400, 90, 556, 120},
				height = 20,
			},
		},
		
		-- Configuration for what causes defeat for each allyTeam. Indexed by allyTeam.
		defeatConditionConfig = {
			[0] = {
				-- AllyTeam 0 had better be the players allyTeam.
				-- The players allyTeam only supports the parameters loseAfterSeconds and timeLossObjectiveID
				
				-- Lose after this many seconds
				loseAfterSeconds = 60,
				
				-- ObjectiveID is purely for the objectives UI. Sets the objective to mark as complete.
				timeLossObjectiveID = 1,
			}
			[1] = {
				-- If ignoreUnitLossDefeat is true then the defeault defeat condition, lose all units, is disabled.
				ignoreUnitLossDefeat = false,
				
				-- This is a list of allyTeams to defeat when this allyTeam is defeated.
				defeatOtherAllyTeamsOnLoss = {2},
				
				-- Stops units on the allyTeam exploding, as they usually do.
				doNotExplodeOnLoss = false,
				
				-- If at least one of vitalCommanders or vitalUnitTypes is set then losing all vital unit types
				-- causes defeat.
				-- * If 'vitalCommanders = true' then commanders are vital unit types.
				-- * If vitalUnitTypes is a list then every unit def name listed is an vital unit type.
				-- The following configuration causes the allyTeam to lose if it loses all commanders and cloaky factories.
				vitalCommanders = true,
				vitalUnitTypes = {
					"factorycloak",
				},
				
				-- All allyTeams can have loseAfterSeconds.
				loseAfterSeconds = false,
				
				-- ObjectiveID is purely for the objectives UI. Sets the objective to mark as complete.
				allyTeamLossObjectiveID = 5,
			},
			[2] = {
			},
		},
		
		-- Objective config is pure UI. The descriptions should be filled with text which relates to the objective. Note that, as per the config,
		-- there are three victory conditions in objective 5.
		-- Objectives can have the following:
		--  * description: The text of the objective on the invasion screen and ingame.
		--  * satisfyCount: The number of sucesses required to satisfy the objective. Only use this for objectives that do not fail. For example
		--                  if there is 4-way FFA then an objective could be "defeat all opponents", to make it tick when all three are defeated
		--                  set allyTeamLossObjectiveID for all opponents and set satisfyCount to 3.
		objectiveConfig = {
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
				description = "Protect your allied Strider Hub",
			},
			[5] = {
				description = "Destroy enemy commanders and factories, move your Commander to the location or move your Glaive to the location.",
			},
		},
		
		-- Configuration for the bonus objectives. Indexed by bonus objective ID.
		bonusObjectiveConfig = {
			-- Objectives have the following simple parameters:
			--  * experience - The experience rewarded to the player if they win a game in which the objective was completed.
			--  * image, imageOverlay - The image used for the objective in the invasion and victory screens.
			--  * description - The text that appears with the objective for the ingame UI and the invasion and victory screens.
			--
			-- Set completeAllBonusObjectives to true to make the bonus objective that is "Complete all objectives".
			--
			-- Not so simple paramters, to be covered later (in order).
			--  * <all the satisfication types>
			--  * victoryByTime - A number of seconds, often false.
			--  * targetNumber - A number
			--  * comparisionType - either planetUtilities.COMPARE.AT_MOST or planetUtilities.COMPARE.AT_LEAST
			--  * unitTypes - a table of unit def names
			--  * enemyUnitTypes - a table of unit def names
			--  * lockUnitsOnSatisfy - true/false
			--  * countRemovedUnits - true/false
			--  * onlyCountRemovedUnits - true/false
			--  * capturedUnitsSatisfy - true/false
			--
			-- Bonus objectives work on the same system. They compare a number of units to their targetNumber and are satisfied based on their
			-- satisfaction type. Ingame, an objective is either satisfied or not satisfied from second to second. It succeeds or failed based on
			-- this constant satisfaction and satisfaction types. Once it succeeds or fails it stops checking.
			--
			-- Here are the satisfaction types, see CheckBonusObjective in the mission_galaxy_campaign_battle gadget for their implementation.
			-- Technically types could be mixed but it is unintended and untested.
			--  * satisfyAtTime = SECONDS
			--      The objective is succeeded if it is satisfied at the time specified. It fails if the time occurs and it is
			--      not satisfied or if the game ends before SECONDS.
			-- * satisfyByTime = SECONDS
			--      Like satisfyAtTime except that the objective succeeded if it is satisfied at any time before SECONDS.
			-- * satisfyUntilTime = SECONDS
			--      The objective fails if it is not satisfied at any time up until SECONDS. It succeeds it has not failed by the time either
			--      either SECONDS has elapsed or the game ends.
			-- * satisfyAfterTime = SECONDS
			--      The objective fails if it is not satisfied at any time after and including SECONDS. It succeeds if the game ends and it has
			--      not yet failed.
			-- * satisfyForeverAfterFirstSatisfied = TRUE/FALSE
			--      If set, the objective fails if it is not satisfied at any time after it is first satisfied. Succeeds if it is satisfied and
			--      the game ends.
			-- * satisfyOnce = TRUE/FALSE
			--      Succeeds if it is satisfied at any point in the game.
			-- * satisfyForever = TRUE/FALSE
			--      Fails if it is ever not satisfied. Succeds if it has not failed and the game ends.
			-- * victoryByTime = SECONDS
			--      A special satisfication type that does not depend on units and targets. Succeeds if the player wins by SECONDS.
			--
			-- An objective is satisfied based on the number of tracked relevant units tracked compared to targetNumber with comparisionType.
			-- The relevant units are:
			--  * All player team units of type unitTypes (note, player team, not allyTeam).
			--  * All enemy allyTeam units of type enemyUnitTypes.
			--  * All initial units with matching bonusObjectiveID.
			--
			-- If 'lockUnitsOnSatisfy = true' then the objective stops tracking new relevant units once it is first satified. This can be used to
			-- make the player build and protect their first four Solars. With 'lockUnitsOnSatisfy = false' the same objective would have the
			-- player build to four Solars and then always have at least four Solars.
			--
			-- If 'countRemovedUnits = false' and 'onlyCountRemovedUnits = false' then the objective stops couting relevant units that died.
			--  * If 'countRemovedUnits = true' then the objective does not reduce the count for dead units, this can be used for an
			--      objective "Make 20 Glaives" which doesn't care what happens to each Glaive after it is built.
			--  * If 'onlyCountRemovedUnits = true' then the objective only counts those units that were relevant units before they died. Set
			--      this to create an objective "Kill 5 Glaive" by making the objective only count removed enemy glaives.
			--  * If 'capturedUnitsSatisfy = true' then captured units can count towards objection completion. Usually only built units count, and
			--      only when on their origional ally team.
			
			[1] = {
				satisfyForever = true,
				comparisionType = planetUtilities.COMPARE.AT_LEAST,
				targetNumber = 1,
				image = planetUtilities.ICON_DIR .. "cloakriot.png",
				imageOverlay = planetUtilities.ICON_OVERLAY.GUARD,
				description = "Keep your Reaver alive.",
				experience = 10,
			},
			[2] = {
				victoryByTime = 480,
				image = planetUtilities.ICON_OVERLAY.CLOCK,
				description = "Win by 8:00",
				experience = 10,
			},
			[3] = { -- Complete all bonus objectives
				completeAllBonusObjectives = true,
				image = planetUtilities.ICON_OVERLAY.ALL,
				description = "Complete all bonus objectives (in one battle).",
				experience = planetUtilities.BONUS_EXP,
			},
			-- See planet definitions for many more examples.
		}
	},
	
	-- Configuration for the rewards gained upon winning the battle. Does not include bonus objectives.
	completionReward = {
		experience = 20, -- Experience gained
		
		-- Unlocks do not need to be unique per planet.
		
		-- Units unlocked, by unitDefName
		units = {
			"factorycloak",
			"cloakraid",
			"cloakriot",
			"cloakcon"
		},
		
		-- Modules unlocked
		modules = {
			-- To unlock a limited number of repeat modules write
			-- "<module name>_LIMIT_X_<N>" where
			-- * 'module name' is the name of the module to be unlocked.
			-- * X is the identifying character. Its purpose is to uniquely identify the module key, allowing the player to unlock multiple
			--   instances of four copies of the module without being able to grind a single planet to unlock all the copies.
			-- * N is the number of modules to unlock, it can be more than one character in case you want more than 9 copies unlocked.
			-- To evenly spread eight copies of a module across two planets give one "module_ablative_armor_LIMIT_A_4" and give the other
			-- "module_ablative_armor_LIMIT_B_4".
			"module_ablative_armor_LIMIT_B_4",
		},
		
		-- Abilities (misc stuff) unlocked. Look up the names of abilities somewhere.
		abilities = {
		}
	},
}
