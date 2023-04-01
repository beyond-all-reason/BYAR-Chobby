local RANK_DIR = LUA_DIRNAME .. "images/ranks/"
local IMAGE_DIR          = LUA_DIRNAME .. "images/"

local IMAGE_AUTOHOST     = IMAGE_DIR .. "ranks/robot.png"
local IMAGE_PLAYER       = IMAGE_DIR .. "ranks/player.png"

local levelFileMap = {
	[1] = "1.png",
	[2] = "2.png",
	[3] = "3.png",
	[4] = "4.png",
	[5] = "14.png",
	[6] = "17.png",
	[7] = "18.png",
	[8] = "21.png",
}

local function GetImageFunction(icon, level, skill, isBot, isModerator)
	if isBot then
		return IMAGE_AUTOHOST
	elseif level then
		return RANK_DIR .. (levelFileMap[level] or "21.png")
	end
	return IMAGE_PLAYER
end

return GetImageFunction
