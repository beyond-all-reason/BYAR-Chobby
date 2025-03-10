local shortname = "byar"

local sidedata           = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/sidedata.lua")
local aiBlacklist        = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/aiBlacklist.lua")
local aiSimpleNames      = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/aiSimpleName.lua")
local aiCustomData       = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/aiCustomData.lua")
local singleplayerConfig = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/singleplayerMenu.lua")
local helpSubmenuConfig  = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/helpSubmenuConfig.lua")
local skirmishDefault    = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/skirmishDefault.lua")
local skirmishSetupData  = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/byar/singleplayerQuickSkirmish.lua")
local rankFunction       = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/byar/rankFunction.lua")
local backgroundConfig   = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/skinning/skinConfig.lua")

local welcomePanelItems = {{Header = "Failed to parse welcomePanelItems.lua", Text = "Unknown error"}}

local success, err = pcall(function()
		local wpi = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/welcomePanelItems.lua")
		welcomePanelItems = wpi
	end)
if not success then
	welcomePanelItems[1].Text = err
end

--Map stuff:
local mapDetails   = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/mapDetails.lua")
local mapStartBoxes   = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/mapStartBoxes.lua")
local useDefaultStartBoxes = true


local link_homePage, link_replays, link_maps = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/linkFunctions.lua")

local settingsConfig, settingsNames, settingsDefault = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/settingsMenu.lua")
--local springSettingsPath = LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/springsettings.lua"

local headingLarge    = LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/skinning/headingLarge.png"
local headingSmall    = LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/skinning/headingSmall.png"
local backgroundImage = LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/skinning/background.jpg"
local taskbarIcon     = LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/taskbarLogo.png"

local background = {
	image           = backgroundImage,
	backgroundFocus = backgroundConfig.backgroundFocus,
}
-- random background
local loadscreens = VFS.DirList(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/skinning/loadpictures/", "*.jpg")
local randomBackgroundImage = loadscreens[math.random(#loadscreens)]
if VFS.FileExists(randomBackgroundImage) then
	background.image = randomBackgroundImage
end

local minimapOverridePath  = LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/minimapOverride/"
local minimapThumbnailPath = LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/minimapThumbnail/"

local sayPrivateSelectAndActivateChatTab = true
local showSinglePlayerIngame = true
local logoutOpensLoginPanel = true

local function ShortenNameString(instring)
	local shortenNameStrings = {
		'Beyond All Reason test',
		'Beyond all Reason test',
		'Beyond All Reason',
		'Beyond all Reason'
	}
	for i,  longstring in ipairs(shortenNameStrings) do
		instring = instring:gsub(longstring, "BAR")
	end
	return instring
end

---------------------------------------------------------------------------------
-- Getters
---------------------------------------------------------------------------------

local externalFuncAndData = {
	dirName                = "byar",
	name                   = "Beyond All Reason",
	--_defaultGameArchiveName = "??", fill this in.
	_defaultGameRapidTag   = "byar:test", -- Do not read directly
	--editor                 = "rapid://sb-byar:test",
	--editor                 = "SpringBoard BYAR $VERSION",
	defaultChatChannels    = {"main"},
	sayPrivateSelectAndActivateChatTab = sayPrivateSelectAndActivateChatTab,
	aiBlacklist            = aiBlacklist,
	unversionedGameAis     = {"SimpleAI","SimpleDefenderAI", "SimpleConstructorAI", "ScavengersAI", "RaptorsAI"},
	GetAiSimpleName        = aiSimpleNames.GetAiSimpleName,
	simpleAiOrder          = aiSimpleNames.simpleAiOrder,
	aiTooltip              = aiSimpleNames.aiTooltip,
	CustomAiProfiles       = aiCustomData.CustomAiProfiles,
	mapDetails             = mapDetails,
	mapStartBoxes          = mapStartBoxes,
	useDefaultStartBoxes   = useDefaultStartBoxes,
	welcomePanelItems      = welcomePanelItems,
	showSinglePlayerIngame = showSinglePlayerIngame,
	settingsConfig         = settingsConfig,
	settingsNames          = settingsNames,
	settingsDefault        = settingsDefault,
	singleplayerConfig     = singleplayerConfig,
	helpSubmenuConfig      = helpSubmenuConfig,
	skirmishDefault        = skirmishDefault,
	skirmishSetupData      = skirmishSetupData,
	sidedata               = sidedata,
	rankFunction           = rankFunction,
	--springSettingsPath     = springSettingsPath,
	headingLarge           = headingLarge,
	headingSmall           = headingSmall,
	skinName               = "Armada Blues",
	taskbarTitle           = "Beyond All Reason",
	taskbarTitleShort      = "BAR",
	taskbarIcon            = taskbarIcon,
	background             = background,
	minimapOverridePath    = minimapOverridePath,
	minimapThumbnailPath   = minimapThumbnailPath,
	ignoreServerVersion    = true,
	battleListOnlyShow     = "",
	disableBattleListHostButton = false, -- Hides "Host" button as this function is not working as one might imagine
	disableSteam 				= true, -- removes settings related to steam
	disablePlanetwars 			= true, -- removes settings related to planetwars
	disableMatchMaking 			= true, -- removes match making
	disableCommunityWindow 		= false, -- removes Community Window
	featuredMapsSelectionDisable 	= true, -- removes the setting to enable a filter that allows featured (by Zero-K) map
	link_homePage           = link_homePage,
	link_replays            = link_replays,
	link_maps               = link_maps,
	openTrack = "LuaMenu/configs/gameConfig/byar/lobbyMusic/Ryan Krause - Friend Or Foe.ogg",	-- dont leave empty
	randomTrackList = {
		"LuaMenu/configs/gameConfig/byar/lobbyMusic/Ryan Krause - Confined Chaos.ogg",
		"LuaMenu/configs/gameConfig/byar/lobbyMusic/Ryan Krause - Friend Or Foe.ogg",
	},
	disableColorChoosing = true,
	showHandicap = true,
	filterEmptyRegionalAutohosts = true,
	logoutOpensLoginPanel = logoutOpensLoginPanel,
	ShortenNameString = ShortenNameString,
}

-- Hack to figure out which versions.gz do we need to cache when downloading
-- any updates with rapid and then restore afterwards. If we don't set
-- SaveLobbyVersionGZPath correctly the game will crash in the following scenario:
-- 1. User starts lobby and joins game for which they don't have the game version downloaded
-- 2. Change happens on the server in BYAR chobby repository, that repoints byar-chobby:test to a new package
-- 3. Lobby starts downloading game, pr-downloader updates all version.gz files in all repos because download
--    of game is done by *springname" not by rapid tag (pr-downloader can't figure out to which repo given
--    springname belongs)
-- 4. New version of the game is downloaded, but byar-chobby:test points at new, not downloaded package
--    as pr-downloaded only downloaded game.
-- 5. Crash, because spring can't load byar-chobby:test package.
local chobbyRepoDomain = "repos.springrts.com"
local rapidTagResolutionOrder = Spring.GetConfigString("RapidTagResolutionOrder")
if rapidTagResolutionOrder ~= "" then
	-- We assume that the first one is ok.
	chobbyRepoDomain = rapidTagResolutionOrder:split(';')[1]
end
externalFuncAndData.SaveLobbyVersionGZPath = "rapid/" .. chobbyRepoDomain .."/byar-chobby/versions.gz"

if Spring.GetConfigInt('soundtrack', 2) == 3 then
	externalFuncAndData.openTrack = "LuaMenu/configs/gameConfig/byar/lobbyMusic/ProfessorKliq-TensionGrowl.ogg"
	externalFuncAndData.randomTrackList = {
		"LuaMenu/configs/gameConfig/byar/lobbyMusic/ProfessorKliq-TensionGrowl.ogg",
		"LuaMenu/configs/gameConfig/byar/lobbyMusic/RobRichert-AliasZero.ogg",
	}
end

function externalFuncAndData.CheckAvailability()
	return true
end

return externalFuncAndData
