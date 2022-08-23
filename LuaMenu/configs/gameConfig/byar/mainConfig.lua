local shortname = "byar"

local sidedata           = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/sidedata.lua")
local aiBlacklist        = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/aiBlacklist.lua")
local aiSimpleNames      = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/aiSimpleName.lua")
local singleplayerConfig = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/singleplayerMenu.lua")
local helpSubmenuConfig  = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/helpSubmenuConfig.lua")
local skirmishDefault    = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/skirmishDefault.lua")
local defaultModoptions  = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/ModOptions.lua")
local rankFunction       = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/byar/rankFunction.lua")
local backgroundConfig   = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/skinning/skinConfig.lua")
local welcomePanelItems   = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/welcomePanelItems.lua")

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
local loadscreens = VFS.DirList(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/skinning/loadpictures/")
local randomBackgroundImage = loadscreens[1+(math.floor((1000*os.clock())%#loadscreens))] -- hacky hotfix for http://springrts.com/mantis/view.php?id=4572
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
	defaultChatChannels    = {"main", "newbies"},
	sayPrivateSelectAndActivateChatTab = sayPrivateSelectAndActivateChatTab,
	aiBlacklist            = aiBlacklist,
	unversionedGameAis	   = {"SimpleAI","SimpleDefenderAI", "SimpleConstructorAI", "ScavengersAI", "ControlModeAI", "ChickensAI"},
	GetAiSimpleName        = aiSimpleNames.GetAiSimpleName,
	simpleAiOrder          = aiSimpleNames.simpleAiOrder,
	aiTooltip              = aiSimpleNames.aiTooltip,
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
	sidedata               = sidedata,
	defaultModoptions      = defaultModoptions,
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
	--battleListOnlyShow     = "Beyond All Reason",
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
	spadsLobbyFeatures = true,
	filterEmptyRegionalAutohosts = true,
	logoutOpensLoginPanel = logoutOpensLoginPanel,
	SaveLobbyVersionGZPath = "rapid/repos.springrts.com/byar-chobby/versions.gz",
	ShortenNameString = ShortenNameString,
}
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
