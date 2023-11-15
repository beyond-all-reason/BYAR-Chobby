local shortname = "generic"

local singleplayerConfig = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/singleplayerMenu.lua")
local rankFunction       = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/rankFunction.lua")
local backgroundConfig   = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/skinning/skinConfig.lua")

-- local settingsConfig, settingsNames, settingsDefault, SettingsPresetFunc = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/zk/settingsMenu.lua")

local springSettingsPath = LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/springsettings.lua"
local headingLarge       = LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/skinning/headingLarge.png"
local headingSmall       = LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/skinning/headingSmall.png"
local backgroundImage    = LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/skinning/background.png"

local background = {
	image           = backgroundImage,
	backgroundFocus = backgroundConfig.backgroundFocus,
}

local minimapOverridePath  = LUA_DIRNAME .. "configs/gameConfig/zk/minimapOverride/"
local minimapThumbnailPath = LUA_DIRNAME .. "configs/gameConfig/zk/minimapThumbnail/"

---------------------------------------------------------------------------------
-- Getters
---------------------------------------------------------------------------------

local externalFuncAndData = {
	dirName                = "generic",
	name                   = "Generic",
	editor                 = "rapid://sbc:test",
	--editor                 = "SpringBoard Core $VERSION",
	defaultChatChannels    = {"main"},
	settingsConfig         = settingsConfig,
	settingsNames          = settingsNames,
	settingsDefault        = settingsDefault,
	SettingsPresetFunc     = SettingsPresetFunc,
	singleplayerConfig     = singleplayerConfig,
	helpSubmenuConfig      = {},
	rankFunction           = rankFunction,
	springSettingsPath     = springSettingsPath,
	headingLarge           = headingLarge,
	headingSmall           = headingSmall,
	background             = background,
	minimapOverridePath     = minimapOverridePath,
	minimapThumbnailPath    = minimapThumbnailPath,

	ignoreServerVersion     	= true,
	disableBattleListHostButton = true, -- Hides "Host" button as this function is not working as one might imagine
	disableSteam 				= true, -- removes settings related to steam
	disablePlanetwars 			= true, -- removes settings related to planetwars
	disableMatchMaking 			= true, -- removes match making
	disableCommunityWindow 		= true, -- removes Community Window
	disableZKMapFiltering       = true, -- removes ZK "featured" map filter
}

function externalFuncAndData.CheckAvailability()
	return true
end

return externalFuncAndData
