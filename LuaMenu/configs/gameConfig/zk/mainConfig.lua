local shortname = "zk"

local aiBlacklist                     = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/aiBlacklist.lua")
local aiSimpleNames                   = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/aiSimpleName.lua")
local oldAiVersions                   = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/oldAiVersions.lua")
local singleplayerConfig              = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/singleplayerMenu.lua")
local helpSubmenuConfig               = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/helpSubmenuConfig.lua")
local skirmishDefault                 = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/skirmishDefault.lua")
local skirmishSetupData               = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/singleplayerQuickSkirmish.lua")
local defaultModoptions               = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/ModOptions.lua")
local rankFunction, largeRankFunction = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/rankFunction.lua")
local backgroundConfig                = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/skinning/skinConfig.lua")
local gameUnitInformation             = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/gameUnitInformation.lua")
local badges                          = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/badges.lua")
local GetRankAndImage                 = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/profilePage.lua")

local link_reportPlayer, link_userPage, link_homePage, link_replays, link_maps, link_particularMapPage = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/linkFunctions.lua")

local settingsConfig, settingsNames, settingsDefault, SettingsPresetFunc = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/settingsMenu.lua")

local headingLarge    = LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/skinning/headingLarge.png"
local headingSmall    = LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/skinning/headingSmall.png"
local backgroundImage = LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/skinning/background.jpg"
local taskbarIcon     = LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/taskbarLogo.png"


local subheadings = {
	large = {
		singleplayer = LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/skinning/headingSingleplayerLarge.png",
		multiplayer  = LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/skinning/headingMultiplayerLarge.png",
		help         = LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/skinning/headingHelpLarge.png",
		campaign     = LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/skinning/headingCampaignLarge.png",
		replays      = LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/skinning/headingReplaysLarge.png",
	},
	small = {
		singleplayer = LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/skinning/headingSingleplayerSmall.png",
		multiplayer  = LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/skinning/headingMultiplayerSmall.png",
		help         = LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/skinning/headingHelpSmall.png",
		campaign     = LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/skinning/headingCampaignSmall.png",
		replays      = LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/skinning/headingReplaysSmall.png",
	},
}

local background = {
	image           = backgroundImage,
	backgroundFocus = backgroundConfig.backgroundFocus,
}

local minimapOverridePath  = LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/minimapOverride/"
local minimapThumbnailPath = LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/minimapThumbnail/"

----- Notes on apparently unused paths -----
-- The lups folder is used by settingsMenu.lua, the lups files are copied next to chobby.exe.
-- Images in rankImages are returned by rankFunction.lua
-- The contents of defaultSettings is copied next to chobby.exe by the wrapper.

---------------------------------------------------------------------------------
-- Getters
---------------------------------------------------------------------------------

local awardDir = LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/awards/trophy_"
local function GetAward(name)
	return awardDir .. name .. ".png"
end

local externalFuncAndData = {
	dirName                 = "zk",
	name                    = "Zero-K",
	_defaultGameArchiveName = "Zero-K v1.7.4.0", -- Do not read directly (except as fallback in case rapid breaks, make sure to keep this version recent enough that it doesn't break on fresh engines)
	_defaultGameRapidTag    = "zk:stable", -- Do not read directly
	aiVersion               = "stable",
	aiBlacklist             = aiBlacklist,
	GetAiSimpleName         = aiSimpleNames.GetAiSimpleName,
	simpleAiOrder           = aiSimpleNames.simpleAiOrder,
	aiTooltip               = aiSimpleNames.aiTooltip,
	oldAiVersions           = oldAiVersions,
	settingsConfig          = settingsConfig,
	settingsNames           = settingsNames,
	settingsDefault         = settingsDefault,
	SettingsPresetFunc      = SettingsPresetFunc,
	singleplayerConfig      = singleplayerConfig,
	helpSubmenuConfig       = helpSubmenuConfig,
	skirmishDefault         = skirmishDefault,
	skirmishSetupData       = skirmishSetupData,
	defaultModoptions       = defaultModoptions,
	rankFunction            = largeRankFunction, --rankFunction,
	largeRankFunction       = largeRankFunction,
	headingLarge            = headingLarge,
	headingSmall            = headingSmall,
	subheadings             = subheadings,
	taskbarTitle            = "Zero-K",
	taskbarTitleShort       = "Zero-K",
	taskbarIcon             = taskbarIcon,
	background              = background,
	minimapOverridePath     = minimapOverridePath,
	minimapThumbnailPath    = minimapThumbnailPath,
	gameUnitInformation     = gameUnitInformation,
	badges                  = badges,
	GetRankAndImage         = GetRankAndImage,
	GetAward                = GetAward,
	link_reportPlayer       = link_reportPlayer,
	link_userPage           = link_userPage,
	link_homePage           = link_homePage,
	link_replays            = link_replays,
	link_maps               = link_maps,
	link_particularMapPage  = link_particularMapPage,
	ignoreServerVersion     = false,
	runTutorial             = true,
	openTrack               = 'sounds/lobbyMusic/The Secret of Ayers Rock.ogg',
	randomTrackList         = {
		"sounds/lobbyMusic/A Magnificent Journey (Alternative Version).ogg",
		"sounds/lobbyMusic/Dream Infinity.ogg",
		"sounds/lobbyMusic/Interstellar.ogg",
		"sounds/lobbyMusic/Tomorrow Landscape.ogg",
	},
	-- I assume ZK doesn't want to show this as it was removed
	hideGameExistanceDisplay = true,
	disableColorChoosing = true,
}

function externalFuncAndData.CheckAvailability()
	return true
end

return externalFuncAndData
