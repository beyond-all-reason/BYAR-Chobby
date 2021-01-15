------------------------------------------------------------------------
-- Module Definitions
------------------------------------------------------------------------

local moduleImagePath = "LuaMenu/configs/gameConfig/zk/unitpics/"
local moduleDefNames = {}

local moduleDefs = {
	-- Empty Module Slots
	{
		name = "nullmodule",
		humanName = "Empty Slot",
		description = "Put a module in this slot.",
		image = moduleImagePath .. "module_none.png",
		limit = false,
		emptyModule = true,
		cost = 0,
		requireLevel = 0,
		slotType = "module",
	},
	{
		name = "nullbasicweapon",
		humanName = "Empty Weapon Slot",
		description = "Put a weapon in this slot.",
		image = moduleImagePath .. "module_none.png",
		limit = false,
		emptyModule = true,
		cost = 0,
		requireLevel = 0,
		slotType = "basic_weapon",
	},
	{
		name = "nulladvweapon",
		humanName = "Empty Weapon Slot",
		description = "Put a weapon in this slot.",
		image = moduleImagePath .. "module_none.png",
		limit = false,
		emptyModule = true,
		cost = 0,
		requireLevel = 0,
		slotType = "adv_weapon",
	},
	
	-- Weapons
	{
		name = "commweapon_beamlaser",
		humanName = "Beam Laser",
		description = "Beam Laser: An effective short-range cutting tool",
		image = moduleImagePath .. "commweapon_beamlaser.png",
		limit = 1,
		cost = 50,
		requireChassis = {"recon", "assault", "support", "strike"},
		requireLevel = 0,
		slotType = "basic_weapon",
		applicationFunction = function (modules, sharedData)
			if sharedData.noMoreWeapons then
				return
			end
			if not sharedData.weapon1 then
				sharedData.weapon1 = "commweapon_beamlaser"
			else
				sharedData.weapon2 = "commweapon_beamlaser"
			end
		end
	},
	{
		name = "commweapon_flamethrower",
		humanName = "Flamethrower",
		description = "Flamethrower: Good for deep-frying swarmers and large targets alike",
		image = moduleImagePath .. "commweapon_flamethrower.png",
		limit = 1,
		cost = 50,
		requireChassis = {"recon", "assault"},
		requireLevel = 0,
		slotType = "basic_weapon",
		applicationFunction = function (modules, sharedData)
			if sharedData.noMoreWeapons then
				return
			end
			if not sharedData.weapon1 then
				sharedData.weapon1 = "commweapon_flamethrower"
			else
				sharedData.weapon2 = "commweapon_flamethrower"
			end
		end
	},
	{
		name = "commweapon_heatray",
		humanName = "Heatray",
		description = "Heatray: Rapidly melts anything at short range; steadily loses all of its damage over distance",
		image = moduleImagePath .. "commweapon_heatray.png",
		limit = 1,
		cost = 50,
		requireChassis = {"assault"},
		requireLevel = 0,
		slotType = "basic_weapon",
		applicationFunction = function (modules, sharedData)
			if sharedData.noMoreWeapons then
				return
			end
			if not sharedData.weapon1 then
				sharedData.weapon1 = "commweapon_heatray"
			else
				sharedData.weapon2 = "commweapon_heatray"
			end
		end
	},
	{
		name = "commweapon_heavymachinegun",
		humanName = "Machine Gun",
		description = "Machine Gun: Close-in automatic weapon with AoE",
		image = moduleImagePath .. "commweapon_heavymachinegun.png",
		limit = 1,
		cost = 50,
		requireChassis = {"recon", "assault", "strike"},
		requireLevel = 0,
		slotType = "basic_weapon",
		applicationFunction = function (modules, sharedData)
			if sharedData.noMoreWeapons then
				return
			end
			local weaponName = (modules[moduleDefNames.conversion_disruptor] and "commweapon_heavymachinegun_disrupt") or "commweapon_heavymachinegun"
			if not sharedData.weapon1 then
				sharedData.weapon1 = weaponName
			else
				sharedData.weapon2 = weaponName
			end
		end
	},
	--{
	--	name = "commweapon_hpartillery",
	--	humanName = "Plasma Artillery",
	--	description = "Plasma Artillery",
	--	image = moduleImagePath .. "commweapon_assaultcannon.png",
	--	limit = 1,
	--	cost = 300,
	--	requireChassis = {"assault"},
	--	requireLevel = 3,
	--	slotType = "adv_weapon",
	--	applicationFunction = function (modules, sharedData)
	--		if sharedData.noMoreWeapons then
	--			return
	--		end
	--		local weaponName = (modules[moduleDefNames.weaponmod_napalm_warhead] and "commweapon_hpartillery_napalm") or "commweapon_hpartillery"
	--		if not sharedData.weapon1 then
	--			sharedData.weapon1 = weaponName
	--		else
	--			sharedData.weapon2 = weaponName
	--		end
	--	end
	--},
	{
		name = "commweapon_lightninggun",
		humanName = "Lightning Rifle",
		description = "Lightning Rifle: Paralyzes and damages annoying bugs",
		image = moduleImagePath .. "commweapon_lightninggun.png",
		limit = 1,
		cost = 50,
		requireChassis = {"recon", "support", "strike"},
		requireLevel = 0,
		slotType = "basic_weapon",
		applicationFunction = function (modules, sharedData)
			if sharedData.noMoreWeapons then
				return
			end
			local weaponName = (modules[moduleDefNames.weaponmod_stun_booster] and "commweapon_lightninggun_improved") or "commweapon_lightninggun"
			if not sharedData.weapon1 then
				sharedData.weapon1 = weaponName
			else
				sharedData.weapon2 = weaponName
			end
		end
	},
	{
		name = "commweapon_lparticlebeam",
		humanName = "Light Particle Beam",
		description = "Light Particle Beam: Fast, light pulsed energy weapon",
		image = moduleImagePath .. "commweapon_lparticlebeam.png",
		limit = 1,
		cost = 50,
		requireChassis = {"support", "recon", "strike"},
		requireLevel = 0,
		slotType = "basic_weapon",
		applicationFunction = function (modules, sharedData)
			if sharedData.noMoreWeapons then
				return
			end
			local weaponName = (modules[moduleDefNames.conversion_disruptor] and "commweapon_disruptor") or "commweapon_lparticlebeam"
			if not sharedData.weapon1 then
				sharedData.weapon1 = weaponName
			else
				sharedData.weapon2 = weaponName
			end
		end
	},
	{
		name = "commweapon_missilelauncher",
		humanName = "Missile Launcher",
		description = "Missile Launcher: Lightweight seeker missile with good range",
		image = moduleImagePath .. "commweapon_missilelauncher.png",
		limit = 1,
		cost = 50,
		requireChassis = {"support", "strike"},
		requireLevel = 0,
		slotType = "basic_weapon",
		applicationFunction = function (modules, sharedData)
			if sharedData.noMoreWeapons then
				return
			end
			if not sharedData.weapon1 then
				sharedData.weapon1 = "commweapon_missilelauncher"
			else
				sharedData.weapon2 = "commweapon_missilelauncher"
			end
		end
	},
	{
		name = "commweapon_riotcannon",
		humanName = "Riot Cannon",
		description = "Riot Cannon: The weapon of choice for crowd control",
		image = moduleImagePath .. "commweapon_riotcannon.png",
		limit = 1,
		cost = 50,
		requireChassis = {"assault"},
		requireLevel = 0,
		slotType = "basic_weapon",
		applicationFunction = function (modules, sharedData)
			if sharedData.noMoreWeapons then
				return
			end
			local weaponName = (modules[moduleDefNames.weaponmod_napalm_warhead] and "commweapon_riotcannon_napalm") or "commweapon_riotcannon"
			if not sharedData.weapon1 then
				sharedData.weapon1 = weaponName
			else
				sharedData.weapon2 = weaponName
			end
		end
	},
	{
		name = "commweapon_rocketlauncher",
		humanName = "Rocket Launcher",
		description = "Rocket Launcher: Medium-range, low-velocity hitter",
		image = moduleImagePath .. "commweapon_rocketlauncher.png",
		limit = 1,
		cost = 50,
		requireChassis = {"assault"},
		requireLevel = 0,
		slotType = "basic_weapon",
		applicationFunction = function (modules, sharedData)
			if sharedData.noMoreWeapons then
				return
			end
			local weaponName = (modules[moduleDefNames.weaponmod_napalm_warhead] and "commweapon_rocketlauncher_napalm") or "commweapon_rocketlauncher"
			if not sharedData.weapon1 then
				sharedData.weapon1 = weaponName
			else
				sharedData.weapon2 = weaponName
			end
		end
	},
	{
		name = "commweapon_shotgun",
		humanName = "Shotgun",
		description = "Shotgun: Can hammer a single large target or shred several small ones",
		image = moduleImagePath .. "commweapon_shotgun.png",
		limit = 1,
		cost = 50,
		requireChassis = {"recon", "support", "strike"},
		requireLevel = 0,
		slotType = "basic_weapon",
		applicationFunction = function (modules, sharedData)
			if sharedData.noMoreWeapons then
				return
			end
			local weaponName = (modules[moduleDefNames.conversion_disruptor] and "commweapon_shotgun_disrupt") or "commweapon_shotgun"
			if not sharedData.weapon1 then
				sharedData.weapon1 = weaponName
			else
				sharedData.weapon2 = weaponName
			end
		end
	},
	{
		name = "commweapon_hparticlebeam",
		humanName = "Heavy Particle Beam",
		description = "Heavy Particle Beam - Replaces other weapons and requires a level 4 slot. Short range, high-power beam weapon with moderate reload time",
		image = moduleImagePath .. "conversion_hparticlebeam.png",
		limit = 1,
		cost = 150,
		requireChassis = {"support"},
		requireLevel = 1,
		slotType = "adv_weapon",
		applicationFunction = function (modules, sharedData)
			if sharedData.noMoreWeapons then
				return
			end
			local weaponName = (modules[moduleDefNames.conversion_disruptor] and "commweapon_heavy_disruptor") or "commweapon_hparticlebeam"
			sharedData.weapon1 = weaponName
			sharedData.weapon2 = nil
			sharedData.noMoreWeapons = true
		end
	},
	{
		name = "commweapon_shockrifle",
		humanName = "Shock Rifle",
		description = "Shock Rifle - Replaces other weapons and requires a level 4 slot. Long range sniper rifle",
		image = moduleImagePath .. "conversion_shockrifle.png",
		limit = 1,
		cost = 150,
		requireChassis = {"support"},
		requireLevel = 1,
		slotType = "adv_weapon",
		applicationFunction = function (modules, sharedData)
			if sharedData.noMoreWeapons then
				return
			end
			sharedData.weapon1 = "commweapon_shockrifle"
			sharedData.weapon2 = nil
			sharedData.noMoreWeapons = true
		end
	},
	{
		name = "commweapon_clusterbomb",
		humanName = "Cluster Bomb",
		description = "Cluster Bomb - Manually fired burst of bombs. Requires level 4 weapon slot.",
		image = moduleImagePath .. "commweapon_clusterbomb.png",
		limit = 1,
		cost = 150,
		requireChassis = {"recon", "assault"},
		requireLevel = 3,
		slotType = "adv_weapon",
		applicationFunction = function (modules, sharedData)
			if sharedData.noMoreWeapons then
				return
			end
			if not sharedData.weapon1 then
				sharedData.weapon1 = "commweapon_clusterbomb"
			else
				sharedData.weapon2 = "commweapon_clusterbomb"
			end
		end
	},
	{
		name = "commweapon_concussion",
		humanName = "Concussion Shell",
		description = "Concussion Shell - Manually fired high impulse projectile. Requires level 4 weapon slot.",
		image = moduleImagePath .. "commweapon_concussion.png",
		limit = 1,
		cost = 150,
		requireChassis = {"recon"},
		requireLevel = 3,
		slotType = "adv_weapon",
		applicationFunction = function (modules, sharedData)
			if sharedData.noMoreWeapons then
				return
			end
			if not sharedData.weapon1 then
				sharedData.weapon1 = "commweapon_concussion"
			else
				sharedData.weapon2 = "commweapon_concussion"
			end
		end
	},
	{
		name = "commweapon_disintegrator",
		humanName = "Disintegrator",
		description = "Disintegrator - Manually fired weapon that destroys almost everything it touches. Requires level 4 weapon slot.",
		image = moduleImagePath .. "commweapon_disintegrator.png",
		limit = 1,
		cost = 150,
		requireChassis = {"assault", "strike"},
		requireLevel = 3,
		slotType = "adv_weapon",
		applicationFunction = function (modules, sharedData)
			if sharedData.noMoreWeapons then
				return
			end
			if not sharedData.weapon1 then
				sharedData.weapon1 = "commweapon_disintegrator"
			else
				sharedData.weapon2 = "commweapon_disintegrator"
			end
		end
	},
	{
		name = "commweapon_disruptorbomb",
		humanName = "Disruptor Bomb",
		description = "Disruptor Bomb - Manually fired bomb that slows enemies in a large area. Requires level 4 weapon slot.",
		image = moduleImagePath .. "commweapon_disruptorbomb.png",
		limit = 1,
		cost = 150,
		requireChassis = {"recon", "support", "strike"},
		requireLevel = 3,
		slotType = "adv_weapon",
		applicationFunction = function (modules, sharedData)
			if sharedData.noMoreWeapons then
				return
			end
			if not sharedData.weapon1 then
				sharedData.weapon1 = "commweapon_disruptorbomb"
			else
				sharedData.weapon2 = "commweapon_disruptorbomb"
			end
		end
	},
	{
		name = "commweapon_multistunner",
		humanName = "Multistunner",
		description = "Multistunner - Manually fired sustained burst of lightning. Requires level 4 weapon slot.",
		image = moduleImagePath .. "commweapon_multistunner.png",
		limit = 1,
		cost = 150,
		requireChassis = {"support", "recon", "strike"},
		requireLevel = 3,
		slotType = "adv_weapon",
		applicationFunction = function (modules, sharedData)
			if sharedData.noMoreWeapons then
				return
			end
			local weaponName = (modules[moduleDefNames.weaponmod_stun_booster] and "commweapon_multistunner_improved") or "commweapon_multistunner"
			if not sharedData.weapon1 then
				sharedData.weapon1 = weaponName
			else
				sharedData.weapon2 = weaponName
			end
		end
	},
	{
		name = "commweapon_napalmgrenade",
		humanName = "Hellfire Grenade",
		description = "Hellfire Grenade - Manually fired bomb that inflames a large area. Requires level 4 weapon slot.",
		image = moduleImagePath .. "commweapon_napalmgrenade.png",
		limit = 1,
		cost = 150,
		requireChassis = {"assault", "recon"},
		requireLevel = 3,
		slotType = "adv_weapon",
		applicationFunction = function (modules, sharedData)
			if sharedData.noMoreWeapons then
				return
			end
			if not sharedData.weapon1 then
				sharedData.weapon1 = "commweapon_napalmgrenade"
			else
				sharedData.weapon2 = "commweapon_napalmgrenade"
			end
		end
	},
	{
		name = "commweapon_slamrocket",
		humanName = "S.L.A.M. Rocket",
		description = "S.L.A.M. Rocket - Manually fired miniature tactical nuke. Requires level 4 weapon slot.",
		image = moduleImagePath .. "commweapon_slamrocket.png",
		limit = 1,
		cost = 200,
		requireChassis = {"assault"},
		requireLevel = 3,
		slotType = "adv_weapon",
		applicationFunction = function (modules, sharedData)
			if sharedData.noMoreWeapons then
				return
			end
			if not sharedData.weapon1 then
				sharedData.weapon1 = "commweapon_slamrocket"
			else
				sharedData.weapon2 = "commweapon_slamrocket"
			end
		end
	},
	
	-- Unique Modules
	{
		name = "econ",
		humanName = "Vanguard Economy Pack",
		description = "Vanguard Economy Pack - A vital part of establishing a beachhead, this module is equipped by all new commanders to kickstart their economy. Provides 4 metal income and 6 energy income.",
		image = moduleImagePath .. "module_energy_cell.png",
		limit = 1,
		unequipable = true,
		cost = 200,
		requireLevel = 0,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			sharedData.metalIncome = (sharedData.metalIncome or 0) + 4
			sharedData.energyIncome = (sharedData.energyIncome or 0) + 6
		end
	},
	{
		name = "commweapon_personal_shield",
		humanName = "Personal Shield",
		description = "Personal Shield - A small, protective bubble shield. Cannot be used with cloak. Requires at least a level 2 module slot.",
		image = moduleImagePath .. "module_personal_shield.png",
		limit = 1,
		cost = 300,
		prohibitingModules = {"module_personal_cloak"},
		requireLevel = 1,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			-- Do not override area shield
			sharedData.shield = sharedData.shield or "commweapon_personal_shield"
		end
	},
	{
		name = "commweapon_areashield",
		humanName = "Area Shield",
		description = "Area Shield - Projects a large shield. Requires and replaced an installed Personal Shield. Requires at least a level 4 module slot.",
		image = moduleImagePath .. "module_areashield.png",
		limit = 1,
		cost = 250,
		requireChassis = {"assault", "support"},
		requireOneOf = {"commweapon_personal_shield"},
		prohibitingModules = {"module_personal_cloak"},
		requireLevel = 3,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			sharedData.shield = "commweapon_areashield"
		end
	},
	{
		name = "weaponmod_napalm_warhead",
		humanName = "Napalm Warhead",
		description = "Napalm Warhead - Riot Cannon, Rocket Launcher and Plasma Artillery set targets on fire. Reduced direct damage. Requires at least a level 3 module slot.",
		image = moduleImagePath .. "weaponmod_napalm_warhead.png",
		limit = 1,
		cost = 350,
		requireChassis = {"assault"},
		requireOneOf = {"commweapon_rocketlauncher", "commweapon_hpartillery", "commweapon_riotcannon"},
		requireLevel = 2,
		slotType = "module",
	},
	{
		name = "conversion_disruptor",
		humanName = "Disruptor Ammo",
		description = "Disruptor Ammo - Heavy Machine Gun, Shotgun and Particle Beams deal slow damage. Reduced direct damage. Requires at least a level 3 module slot.",
		image = moduleImagePath .. "weaponmod_disruptor_ammo.png",
		limit = 1,
		cost = 450,
		requireChassis = {"strike", "recon", "support"},
		requireOneOf = {"commweapon_heavymachinegun", "commweapon_shotgun", "commweapon_hparticlebeam", "commweapon_lparticlebeam"},
		requireLevel = 2,
		slotType = "module",
	},
	{
		name = "weaponmod_stun_booster",
		humanName = "Flux Amplifier",
		description = "Flux Amplifier - Improves EMP duration and strength of Lightning Rifle and Multistunner. Requires at least a level 3 module slot.",
		image = moduleImagePath .. "weaponmod_stun_booster.png",
		limit = 1,
		cost = 300,
		requireChassis = {"support", "strike", "recon"},
		requireOneOf = {"commweapon_lightninggun", "commweapon_multistunner"},
		requireLevel = 2,
		slotType = "module",
	},
	{
		name = "module_jammer",
		humanName = "Radar Jammer",
		description = "Radar Jammer - Hide the radar signals of nearby units. Requires at least a level 2 module slot.",
		image = moduleImagePath .. "module_jammer.png",
		limit = 1,
		cost = 200,
		requireLevel = 1,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			if not sharedData.cloakFieldRange then
				sharedData.radarJammingRange = 500
			end
		end
	},
	{
		name = "module_radarnet",
		humanName = "Field Radar",
		description = "Field Radar - Attaches a basic radar system. Requires at least a level 2 module slot.",
		image = moduleImagePath .. "module_fieldradar.png",
		limit = 1,
		cost = 75,
		requireLevel = 1,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			sharedData.radarRange = 1800
		end
	},
	{
		name = "module_personal_cloak",
		humanName = "Personal Cloak",
		description = "Personal Cloak - A personal cloaking device. Reduces speed by 8 and cannot be used with shields. Requires at least a level 2 module slot.",
		image = moduleImagePath .. "module_personal_cloak.png",
		limit = 1,
		cost = 400,
		prohibitingModules = {"commweapon_personal_shield", "commweapon_areashield"},
		requireLevel = 1,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			sharedData.decloakDistance = math.max(sharedData.decloakDistance or 0, 150)
			sharedData.personalCloak = true
		end
	},
	{
		name = "module_cloak_field",
		humanName = "Cloaking Field",
		description = "Cloaking Field - Cloaks all nearby units. Requires Radar Jammer. Requires at least a level 4 module slot.",
		image = moduleImagePath .. "module_cloak_field.png",
		limit = 1,
		cost = 600,
		requireChassis = {"support", "strike"},
		requireOneOf = {"module_jammer"},
		requireLevel = 3,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			sharedData.areaCloak = true
			sharedData.decloakDistance = 180
			sharedData.cloakFieldRange = 350
			sharedData.cloakFieldUpkeep = 15
			sharedData.radarJammingRange = 350
		end
	},
	{
		name = "module_resurrect",
		humanName = "Lazarus Device",
		description = "Lazarus Device - Upgrade nanolathe to allow resurrection. Requires at least a level 3 module slot.",
		image = moduleImagePath .. "module_resurrect.png",
		limit = 1,
		cost = 400,
		requireChassis = {"support"},
		requireLevel = 2,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			sharedData.canResurrect = true
		end
	},
	{
		name = "module_jumpjet",
		humanName = "Jumpjets",
		description = "Jumpjets - Leap over obstacles and out of danger. Requires at least a level 4 module slot.",
		image = moduleImagePath .. "module_jumpjet.png",
		limit = 1,
		cost = 400,
		requireChassis = {"knight"},
		requireLevel = 3,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			sharedData.canJump = true
		end
	},
	
	-- Repeat Modules
	{
		name = "module_companion_drone",
		humanName = "Companion Drone",
		description = "Companion Drone - Commander spawns protective drones. Requires at least a level 3 module slot._COUNT_",
		image = moduleImagePath .. "module_companion_drone.png",
		limit = 8,
		cost = 300,
		requireLevel = 2,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			sharedData.drones = (sharedData.drones or 0) + 1
		end
	},
	{
		name = "module_battle_drone",
		humanName = "Battle Drone",
		description = "Battle Drone - Commander spawns heavy drones. Requires Companion Drone and at least a level 4 module slot._COUNT_",
		image = moduleImagePath .. "module_battle_drone.png",
		limit = 8,
		cost = 500,
		requireChassis = {"support"},
		requireOneOf = {"module_companion_drone"},
		requireLevel = 3,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			sharedData.battleDrones = (sharedData.battleDrones or 0) + 1
		end
	},
	{
		name = "module_autorepair",
		humanName = "Autorepair",
		description = "Autorepair - Commander self-repairs at +10 hp/s at the cost of 100 health._COUNT_",
		image = moduleImagePath .. "module_autorepair.png",
		limit = 8,
		cost = 150,
		requireLevel = 0,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			sharedData.autorepairRate = (sharedData.autorepairRate or 0) + 10
			sharedData.healthBonus = (sharedData.healthBonus or 0) - 100
		end
	},
	{
		name = "module_ablative_armor",
		humanName = "Ablative Armour Plates",
		description = "Ablative Armour Plates - Provides 600 health._COUNT_",
		image = moduleImagePath .. "module_ablative_armor.png",
		limit = 8,
		cost = 150,
		requireLevel = 0,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			sharedData.healthBonus = (sharedData.healthBonus or 0) + 600
		end
	},
	{
		name = "module_heavy_armor",
		humanName = "High Density Plating",
		description = "High Density Plating - Provides 1600 health but reduces speed by 3. Requires Ablative Armour Plates and  at least a level 3 module slot._COUNT_",
		image = moduleImagePath .. "module_heavy_armor.png",
		limit = 8,
		cost = 400,
		requireOneOf = {"module_ablative_armor"},
		requireLevel = 2,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			sharedData.healthBonus = (sharedData.healthBonus or 0) + 1600
			sharedData.speedMult = (sharedData.speedMult or 1) - 0.1
		end
	},
	{
		name = "module_dmg_booster",
		humanName = "Damage Booster",
		description = "Damage Booster - Increases damage by 10% but reduces speed by 1._COUNT_",
		image = moduleImagePath .. "module_dmg_booster.png",
		limit = 8,
		cost = 150,
		requireLevel = 0,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			-- Damage boost is applied via clone swapping
			sharedData.damageMult = (sharedData.damageMult or 1) + 0.1
			sharedData.speedMult = (sharedData.speedMult or 1) - 0.025
		end
	},
	{
		name = "module_high_power_servos",
		humanName = "High Power Servos",
		description = "High Power Servos - Increases speed by 3._COUNT_",
		image = moduleImagePath .. "module_high_power_servos.png",
		limit = 8,
		cost = 150,
		requireLevel = 0,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			sharedData.speedMult = (sharedData.speedMult or 1) + 0.1
		end
	},
	{
		name = "module_adv_targeting",
		humanName = "Adv. Targeting System",
		description = "Advanced Targeting System - Increases range by 7.5% but reduces speed by 1._COUNT_",
		image = moduleImagePath .. "module_adv_targeting.png",
		limit = 8,
		cost = 150,
		requireLevel = 0,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			sharedData.rangeMult = (sharedData.rangeMult or 1) + 0.075
			sharedData.speedMult = (sharedData.speedMult or 1) - 0.025
		end
	},
	{
		name = "module_adv_nano",
		humanName = "CarRepairer's Nanolathe",
		description = "CarRepairer's Nanolathe - Increases build power by 4._COUNT_",
		image = moduleImagePath .. "module_adv_nano.png",
		limit = 8,
		cost = 150,
		requireLevel = 0,
		slotType = "module",
		applicationFunction = function (modules, sharedData)
			-- All comms have 10 BP in their unitDef (even support)
			sharedData.bonusBuildPower = (sharedData.bonusBuildPower or 0) + 4
		end
	},
}

for i = 1, #moduleDefs do
	moduleDefNames[moduleDefs[i].name] = i
end

------------------------------------------------------------------------
-- Chassis Definition
------------------------------------------------------------------------

local highestDefinedLevel = 7
local levelDefs = {
	[0] = {
		upgradeSlots = {
			{
				defaultModule = "commweapon_beamlaser",
				slotAllows = "basic_weapon",
			},
			{
				defaultModule = "nullmodule",
				slotAllows = "module",
			},
		},
	},
	[1] = {
		upgradeSlots = {
			{
				defaultModule = "nullmodule",
				slotAllows = "module",
			},
			{
				defaultModule = "nullmodule",
				slotAllows = "module",
			},
		},
	},
	[2] = {
		upgradeSlots = {
			{
				defaultModule = "nullmodule",
				slotAllows = "module",
			},
			{
				defaultModule = "nullmodule",
				slotAllows = "module",
			},
		},
	},
	[3] = {
		upgradeSlots = {
			{
				defaultModule = "nullbasicweapon",
				slotAllows = {"adv_weapon", "basic_weapon"},
			},
			{
				defaultModule = "nullmodule",
				slotAllows = "module",
			},
			{
				defaultModule = "nullmodule",
				slotAllows = "module",
			},
		},
	},
}

for i = 4, highestDefinedLevel do
	levelDefs[i] = {
		upgradeSlots = {
			{
				defaultModule = "nullmodule",
				slotAllows = "module",
			},
			{
				defaultModule = "nullmodule",
				slotAllows = "module",
			},
			{
				defaultModule = "nullmodule",
				slotAllows = "module",
			},
		},
	}
end

local chassisDef = {
	name = "knight",
	chassis = "knight",
	humanName = "Knight",
	image = LUA_DIRNAME .. "images/chassis_cremcom.png",
	secondPeashooter = true,
	highestDefinedLevel = highestDefinedLevel,
	levelDefs = levelDefs
}

------------------------------------------------------------------------
-- Processing
------------------------------------------------------------------------

-- Transform from human readable format into number indexed format
--for i = 1, #moduleDefs do
--	local data = moduleDefs[i]
--
--	-- Required modules are a list of moduleDefIDs
--	if data.requireOneOf then
--		local newRequire = {}
--		for j = 1, #data.requireOneOf do
--			local reqModuleID = moduleDefNames[data.requireOneOf[j]]
--			if reqModuleID then
--				newRequire[#newRequire + 1] = reqModuleID
--			end
--		end
--		data.requireOneOf = newRequire
--	end
--
--	-- Prohibiting modules are a list of moduleDefIDs too
--	if data.prohibitingModules then
--		local newProhibit = {}
--		for j = 1, #data.prohibitingModules do
--			local reqModuleID = moduleDefNames[data.prohibitingModules[j]]
--			if reqModuleID then
--				newProhibit[#newProhibit + 1] = reqModuleID
--			end
--		end
--		data.prohibitingModules = newProhibit
--	end
--end

for i = 0, chassisDef.highestDefinedLevel do
	local slots = chassisDef.levelDefs[i].upgradeSlots
	for j = 1, #slots do
		local newSlotAllows = {}
		if type(slots[j].slotAllows) == "string" then
			newSlotAllows[slots[j].slotAllows] = true
		else
			for allow = 1, #slots[j].slotAllows do
				newSlotAllows[slots[j].slotAllows[allow]] = true
			end
		end
		slots[j].slotAllows = newSlotAllows
	end
end

------------------------------------------------------------------------
-- Module Ordering
------------------------------------------------------------------------

for i = 1, #moduleDefs do
	local data = moduleDefs[i]
	data.category = (data.slotType == "module" and "module") or "weapon"
	data.order = i
end

local categories = {
	module = {
		name = "Modules",
		order = 1
	},
	weapon = {
		name = "Weapons",
		order = 2
	}
}

local function ModuleOrder(name1, name2)
	local data1 = name1 and moduleDefNames[name1] and moduleDefs[moduleDefNames[name1]]
	local data2 = name1 and moduleDefNames[name2] and moduleDefs[moduleDefNames[name2]]
	if not data1 then
		return (data2 and true)
	end
	if not data2 then
		return true
	end
	
	local category1 = categories[data1.category].order
	local category2 = categories[data2.category].order
	return category1 < category2 or (category1 == category2 and data1.order < data2.order)
end

------------------------------------------------------------------------
-- Commander Configuration
------------------------------------------------------------------------
local levelRequirement = {
	[0] = 0,
	[1] = 500,
	[2] = 1200,
	[3] = 2500,
	[4] = 5000,
	[5] = 8500,
	[6] = 12000,
}

local function GetLevelRequirement(level)
	return levelRequirement[level]
end

return {
	moduleDefs = moduleDefs,
	moduleDefNames = moduleDefNames,
	chassisDef = chassisDef,
	GetLevelRequirement = GetLevelRequirement,
	categories = categories,
	ModuleOrder = ModuleOrder,
}
