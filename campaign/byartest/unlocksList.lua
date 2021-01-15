-- A list of all unlocks
local shortname = "byartest"

local planetDefs     = VFS.Include("campaign/" .. shortname .. "/planetDefs.lua")
local initialUnlocks = VFS.Include("campaign/" .. shortname .. "/initialUnlocks.lua")

local unitsUnlocked = {list = {}, map = {}}
local modulesUnlocked = {list = {}, map = {}}
local abilitiesUnlocked = {list = {}, map = {}}

local function TranslateModule(moduleName)
	-- Limited copies look like moduleName_LIMIT_A_4
	local limitPos = string.find(moduleName, "_LIMIT_")
	if not limitPos then
		return moduleName
	end
	return string.sub(moduleName, 0, limitPos - 1)
end

local function UnlockThing(thingData, id)
	if thingData.map[id] then
		return false
	end
	thingData.map[id] = true
	thingData.list[#thingData.list + 1] = id
	return true
end

local function UnlockListOfThings(unlockList, unlocksToAdd, translationFunc)
	for i = 1, #unlocksToAdd do
		if translationFunc then
			UnlockThing(unlockList, translationFunc(unlocksToAdd[i]))
		else
			UnlockThing(unlockList, unlocksToAdd[i])
		end
	end
end

local function UnlockRewardSet(rewardSet)
	if not rewardSet then
		return
	end
	if rewardSet.units then
		UnlockListOfThings(unitsUnlocked, rewardSet.units)
	end
	if rewardSet.modules then
		UnlockListOfThings(modulesUnlocked, rewardSet.modules, TranslateModule)
	end
	if rewardSet.abilities then
		UnlockListOfThings(abilitiesUnlocked, rewardSet.abilities)
	end
end

UnlockRewardSet(initialUnlocks)
for i = 1, #planetDefs.planets do
	UnlockRewardSet(planetDefs.planets[i].completionReward)
end

return {
	units = unitsUnlocked,
	modules = modulesUnlocked,
	abilities = abilitiesUnlocked,
	TranslateModule = TranslateModule,
}
