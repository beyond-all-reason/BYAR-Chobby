local shortname = "byar"

local sidedata           = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/sidedata.lua")
local mapWhitelist       = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/mapWhitelist.lua")
local aiBlacklist        = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/aiBlacklist.lua")
local singleplayerConfig = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/singleplayerMenu.lua")
local helpSubmenuConfig  = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/helpSubmenuConfig.lua")
local skirmishDefault    = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/skirmishDefault.lua")
local defaultModoptions  = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/ModOptions.lua")
--local rankFunction       = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/zk/rankFunction.lua")
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



local function ShortenNameString(instring)
	local shortenNameStrings = {
		['Beyond All Reason test'] = "BAR",
		['Beyond all Reason test'] = "BAR",
		['Beyond All Reason'] = "BAR",
		['Beyond all Reason'] = "BAR",
	}
	for longstring, shortstring in pairs(shortenNameStrings) do
		instring = instring:gsub(longstring, shortstring)
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
	mapWhitelist           = mapWhitelist,
	aiBlacklist            = aiBlacklist,
	mapDetails             = mapDetails,
	mapStartBoxes          = mapStartBoxes,
	useDefaultStartBoxes   = useDefaultStartBoxes,
	welcomePanelItems      = welcomePanelItems,
	settingsConfig         = settingsConfig,
	settingsNames          = settingsNames,
	settingsDefault        = settingsDefault,
	singleplayerConfig     = singleplayerConfig,
	helpSubmenuConfig      = helpSubmenuConfig,
	skirmishDefault        = skirmishDefault,
	sidedata               = sidedata,

	simpleAiOrder = {
		['SimpleAI']= 2,
		['SimpleCheaterAI']= 3,
		['SimpleDefenderAI']= 4,
		['ScavengersAI']= 7,
		['DAI']= 5,
		['STAI']= 6,
		--['BARbarIAn 0.57']= 6,
		--['BARbarIAn 0.58']= 7,
		--['BARbarIAn 0.59']= 8,
		['BARbarIAn stable'] = 1,
		['Chicken: Very Easy']= 9,
		['Chicken: Easy']= 10,
		['Chicken: Normal']= 11,
		['Chicken: Hard']= 12,
		['Chicken: Very Hard']= 13,
		['Chicken: Epic!']= 14,
		['Chicken: Survival']= 15,
		['NullAI 0.1']= 16,
	},

	aiTooltip = {
		['SimpleAI']= "A simple, easy playing beginner AI (Great for your first game!)",
		['SimpleCheaterAI']= "A moderately difficult AI, cheats!",
		['SimpleDefenderAI']= "An easy AI, mostly defends and doesnt attack much",
		['ScavengersAI']= "This is a PvE game mode, with an increasing difficulty waves of Scavenger AI controlled units attacking the players. Only add 1 per game.",
		['DAI']=  "Recommended medium difficulty stable non-cheating AI, with great offense. Add more for extra difficulty, but that can slow things down in late game.",
		['STAI']= "A medium to hard difficulty, experimental, non cheating AI.",
		['NullAI 0.1']= "A game-testing AI. Literally does nothing.",
		--['BARbarIAn 0.57']= "A hard difficulty non-cheating AI, add more for extra difficulty.",
		--['BARbarIAn 0.58']= "A hard difficulty non-cheating AI, add more for extra difficulty.",
		--['BARbarIAn 0.59']= "A hard difficulty non-cheating AI, add more for extra difficulty.",
		['BARbarIAn stable']= "The recommended excellent performance, adjustable difficulty, non-cheating AI. Add as many as you wish!",
		['Chicken: Very Easy']= "A moderate difficulty PvE AI, where hordes of alien creatures attack the players. Only add 1 per game.",
		['Chicken: Easy']= "An intermediate difficulty PvE AI, where hordes of alien creatures attack the players. Only add 1 per game.",
		['Chicken: Normal']= "A hard difficulty PvE AI, where hordes of alien creatures attack the players. Only add 1 per game.",
		['Chicken: Hard']= "A hard difficulty PvE AI, where hordes of alien creatures attack the players. Only add 1 per game.",
		['Chicken: Very Hard']= "A very hard difficulty PvE AI, where hordes of alien creatures attack the players. Only add 1 per game.",
		['Chicken: Epic!']= "An extreme difficulty PvE AI, where hordes of alien creatures attack the players. Only add 1 per game.",
		['Chicken: Survival']= "An extreme difficulty PvE AI, where ENDLESS hordes of alien creatures attack the players. Only add 1 per game.",
	},

	defaultModoptions      = defaultModoptions,
	--rankFunction           = rankFunction,
	--springSettingsPath     = springSettingsPath,
	headingLarge           = headingLarge,
	headingSmall           = headingSmall,
	skinName               = "Evolved",
	taskbarTitle           = "Beyond All Reason",
	taskbarTitleShort      = "BAR",
	taskbarIcon            = taskbarIcon,
	background             = background,
	minimapOverridePath    = minimapOverridePath,
	minimapThumbnailPath   = minimapThumbnailPath,
	ignoreServerVersion    = true,
	--battleListOnlyShow     = "Beyond All Reason",
	disableBattleListHostButton = true, -- Hides "Host" button as this function is not working as one might imagine
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
		"LuaMenu/configs/gameConfig/byar/lobbyMusic/ProfessorKliq-TensionGrowl.ogg",
		"LuaMenu/configs/gameConfig/byar/lobbyMusic/RobRichert-AliasZero.ogg",
	},
	disableColorChoosing = false,
	showHandicap = true,
	spadsLobbyFeatures = true,
	filterEmptyRegionalAutohosts = true,

	ShortenNameString = ShortenNameString,
}

function externalFuncAndData.CheckAvailability()
	return true
end

return externalFuncAndData
