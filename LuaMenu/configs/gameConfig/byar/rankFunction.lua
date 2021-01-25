--local RANK_DIR = LUA_DIRNAME .. "configs/gameConfig/zk/rankImages/"
local IMAGE_DIR          = LUA_DIRNAME .. "images/"

local IMAGE_AUTOHOST     = IMAGE_DIR .. "ranks/robot.png"
local IMAGE_PLAYER       = IMAGE_DIR .. "ranks/player.png"
local IMAGE_MODERATOR    = IMAGE_DIR .. "ranks/moderator.png"

local rankPics = {"1", "2", "3", "4", "5", "6", "7","8"}
local rankCount = #rankPics

local function GetImageFunction(icon,level, skill, isBot, isModerator)
	--Spring.Echo("Warning: ","GetImageFunction(icon,level, skill, isBot, isModerator)",icon,level, skill, isBot, isModerator)
	if isBot and isBot == true then
		return IMAGE_AUTOHOST
	end

	if level and level > 0 then -- for some reason skill contains lobby level
		local rankImg = IMAGE_DIR ..'ranks/'.. rankPics[level]
		if isModerator then
			rankImg = rankImg ..  "M"
		end
		return rankImg .. ".png"
	end

	return IMAGE_PLAYER
end

return GetImageFunction
--[t=00:00:13.117750][f=-000001] Warning: UserLevelToImage(icon, level, skill, isBot, isAdmin), <function>, nil, 4, 0, nil, false
--[t=00:00:13.117750][f=-000001] Warning: , GetImageFunction(level, skill, isBot, isModerator), nil, 4, 0, nil
