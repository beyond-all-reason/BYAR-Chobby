local RANK_DIR = LUA_DIRNAME .. "configs/gameConfig/zk/rankImages/"
local LARGE_RANK_DIR = LUA_DIRNAME .. "configs/gameConfig/zk/rankImagesLarge/"
local IMAGE_DIR          = LUA_DIRNAME .. "images/"

local IMAGE_AUTOHOST     = IMAGE_DIR .. "ranks/robot.png"
local IMAGE_PLAYER       = IMAGE_DIR .. "ranks/player.png"

local rankUnlocks = {5, 10, 20, 35, 50, 75, 100}
local rankCount = #rankUnlocks

local function GetImageFunction(icon, level, skill, isBot, isModerator)
	if icon then
		return RANK_DIR .. icon .. ".png"
	end
	if isBot then
		return IMAGE_AUTOHOST
	elseif level and skill then
		local levelBracket = 1
		while levelBracket <= rankCount and rankUnlocks[levelBracket] <= level do
			levelBracket = levelBracket + 1
		end
		levelBracket = levelBracket - 1

		local skillBracket = math.max(0, math.min(7, math.floor((skill-1000)/200)))

		return RANK_DIR .. levelBracket .. "_" .. skillBracket .. ".png"
	end
	return IMAGE_PLAYER
end

local function GetLargeImageFunction(icon, level, skill, isBot, isModerator)
	if icon then
		return LARGE_RANK_DIR .. icon .. ".png"
	end
	if isBot then
		return IMAGE_AUTOHOST
	elseif level and skill then
		local levelBracket = 1
		while levelBracket <= rankCount and rankUnlocks[levelBracket] <= level do
			levelBracket = levelBracket + 1
		end
		levelBracket = levelBracket - 1

		local skillBracket = math.max(0, math.min(7, math.floor((skill-1000)/200)))

		return LARGE_RANK_DIR .. levelBracket .. "_" .. skillBracket .. ".png"
	end
	return IMAGE_PLAYER
end

return GetImageFunction, GetLargeImageFunction
