local randomSkirmishEnabled = Spring.GetConfigInt("randomSkirmishSetup", 1)

if randomSkirmishEnabled == 1 then
	local listOfCertifiedMaps = VFS.Include("luamenu/configs/gameconfig/byar/mapdetails.lua")
	local convertedListOfMaps = {}
	for pickedMap, mapDetails in pairs(listOfCertifiedMaps) do
		convertedListOfMaps[#convertedListOfMaps+1] = {
			mapName = pickedMap,
			mapSize = mapDetails.Width + mapDetails.Height,
			isFFA = mapDetails.IsFFA,
		}
	end

	local pickedTheMap = false
	local skirmishTable
	while pickedTheMap == false do
		local pickedMap = convertedListOfMaps[math.random(1,#convertedListOfMaps)]
		if not pickedMap.isFFA then
			pickedTheMap = true
			local map = pickedMap.mapName
			local teamSizes = math.ceil(pickedMap.mapSize*0.1)
			local enemyAI = {}
			local friendlyAI = {}
			for i = 1,teamSizes do
				local randomAIList = {"SimpleAI", "BARb"}
				--local randomAIList = {"BARb", "STAI",}
				local randomAI = randomAIList[math.random(1,#randomAIList)]
				if i == 1 then
					enemyAI[#enemyAI+1] = {shortName = "SimpleAI"}
				else
					friendlyAI[#friendlyAI+1] = {shortName = randomAI}
					enemyAI[#enemyAI+1] = {shortName = randomAI}
				end
			end
			local startboxes = {[0] = {0, 0, 40, 200}, [1] = {160, 0, 200, 200}, }
			skirmishTable = {map = map, enemyAI = enemyAI, friendlyAI = friendlyAI,startboxes = startboxes}
			
		end
	end

	return skirmishTable
else
	return { map = "Quicksilver Remake 1.24",}
end

