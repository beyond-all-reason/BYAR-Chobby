Configuration = LCS.class{}

LIB_LOBBY_DIRNAME = "libs/liblobby/lobby/"


-- all configuration attribute changes should use the :Set*Attribute*() and :Get*Attribute*() methods in order to assure proper functionality
function Configuration:init()
	self.listeners = {}

	local fileConfig
	if VFS.FileExists(LUA_DIRNAME .. "configs/liblobby_configuration.lua") then
		fileConfig = VFS.Include(LUA_DIRNAME .. "configs/liblobby_configuration.lua", nil, VFS.RAW_FIRST)
	end
	if not fileConfig.game then
		Spring.Log("Chobby", LOG.WARNING, "Missing game in chobby_config.json file.")
		-- FIXME: This will be changed to "generic" in future versions.
		fileConfig.game = "zk"
	end

	-- self.serverAddress = "localhost"
	self.serverAddress = WG.Server.address
	self.serverPort =  WG.Server.port

	self.chatFontSize = 18
	self.fontName = "fonts/Poppins-Regular.otf"
	self.fontRaw = {
		[0] = {font = "fonts/Poppins-Medium.otf", size = 17, outline = false, shadow = true},
		[1] = {size = 15, outline = true, shadow = false},
		[2] = {size = 17, outline = false, shadow = true},
		[3] = {size = 20, outline = false, shadow = true},
		[4] = {size = 24, outline = true,  shadow = false},
		[5] = {size = 24, outline = false, shadow = true},
		[6] = {size = 28, outline = true, shadow = false},
		[7] = {size = 28, outline = false, shadow = true},
	}
	-- copy of skin Armada Blue
	self.fontRaw[8] = {font = "fonts/n019003l.pfb", size = self.fontRaw[1].size, shadow = true, outlineColor = {0.05,0.05,0.05,0.9},}
	self.fontRaw[9] = {font = "fonts/n019003l.pfb", size = self.fontRaw[2].size, shadow = true, outlineColor = {0.05,0.05,0.05,0.9},}
	self.fontRaw[10] = {font = "fonts/n019003l.pfb", size = 14, shadow = true, outlineColor = {0.05,0.05,0.05,0.9},}
	self.fontRaw[11] = {font = "fonts/n019003l.pfb", size = 17, shadow = true, outline = false, color = {0.5,0.5,0.5,0.9},}

	self.fontSpecial = {}
	-- Lazy font creation: Font:New involves font file I/O + glyph atlas.
	-- Defer until first access via __index metamethod.
	local fontRaw = self.fontRaw
	local fontName = self.fontName
	self.font = setmetatable({}, {
		__index = function(t, i)
			local raw = fontRaw[i]
			if raw then
				local f = Font:New {
					size         = raw.size,
					font         = raw.font or fontName,
					outline      = raw.outline,
					shadow       = raw.shadow,
					outlineColor = raw.outlineColor or {0.05,0.05,0.05,0.7},
					color        = raw.color or {1,1,1,1},
				}
				rawset(t, i, f)
				return f
			end
		end
	})

	-- self.uiScale, WG.uiScale, and self.uiScalesForScreenSizes will be overridden in Configuration:SetConfigData;
	-- We're setting default values here in case something tries to access it before we get there.
	-- See Configuration:SetUiScale() for setting, listen for OnUiScaleChange for updates.
	self.uiScale = 1
	self.defaultUiScale = self.uiScale
	WG.uiScale = self.uiScale
	self.uiScalesForScreenSizes = {}

	self:UpdateUiScaleMaxMin()
	self:SetUiScale()

	self.userListWidth = 240 -- Main user list width. Possibly configurable in the future.
	self.chatMaxNameLength = 250 -- Pixels
	self.statusMaxNameLength = 250
	self.friendMaxNameLength = 250
	self.notificationMaxNameLength = 250
	self.steamOverlayEnablable = (Platform.osFamily ~= "Linux" and Platform.osFamily ~= "FreeBSD")

	self.userName = false
	self.suggestedNameFromSteam = false
	self.password = false
	self.autoLogin = true
	self.rememberPassword = true
	self.uploadLogPrompt = 'Prompt'
	self.firstLoginEver = true
	self.canAuthenticateWithSteam = false
	self.wantAuthenticateWithSteam = true
	self.useSteamBrowser = true
	self.steamLinkComplete = false
	self.alreadySeenFactionPopup4 = false
	self.firstBattleStarted = false
	self.seenWelcomeItems = {}
	self.lobbyTimeoutTime = 60 -- Seconds

	self.battleFilterPassworded2 = true
	self.battleFilterNonFriend = false
	self.battleFilterRunning = false
	self.battleFilterLocked = false
	-- self.battleFilterVsAI = nil
	self.battleFilterRedundant = true
	self.battleFilterRedundantRegions = {"EU - ", "USA - ", "AUS - ","EU - ENGINE TESTING ","US - ","AU - ", "UK - "}
	self.hostRegions = {"DE","EU","EU2","US","US2","AU"}

	self.friendsFilterOnline = false

	self.manualBorderless = {
		game = {},
		lobby = {},
	}
	self.manualFullscreen = {
		game = {},
		lobby = {},
	}
	self.manualWindowed = {
		game = {},
		lobby = {},
	}

	self.IGNORE = 1
	self.AVOID = 2
	self.BLOCK = 3
	self.disregardStatusNames = {"IGNORE", "AVOID", "BLOCK"}

	self.ignoreLevel = false

	self.errorColor = "\255\255\0\0"
	self.warningColor = "\255\255\255\0"
	self.normalColor = "\255\255\255\255"
	self.successColor = "\255\0\255\0"
	self.partialColor = "\255\190\210\50"
	self.selectedColor = "\255\99\184\255"
	self.highlightedColor = "\255\125\255\0"
	self.meColor = "\255\0\190\190"

	self.moderatorColor = {0.2, 1.0, 0.2, 1}
	self.founderColor = {0.7, 1, 0.65, 1}

	self.disregardUserNameColor = {}
	self.disregardUserNameColor[self.IGNORE] = {0.6, 0.6, 0.6, 1}
	self.disregardUserNameColor[self.AVOID] = {0.8, 0.8, 0.6, 1}
	self.disregardUserNameColor[self.BLOCK] = {0.8, 0.6, 0.6, 1}

	self.userNameColor = {1, 1, 1, 1}
	self.myUserNameColor = {0.8, 0.3, 0.9, 1}
	self.friendsColor = {0.8, 0.4, 0.1, 1}

	self.buttonFocusColor = {0.34,0.52,1,0.3}
	self.buttonSelectedColor = {0.1, 0.58, 0.90, 0.9}--{1.0, 1.0, 1.0, 1.0}

	self.skillUncertaintyColors = {
		[0] = {1.00, 0.75, 0.16, 1.0},
		[1] = {0.85, 0.638, 0.137, 1.0},
		[2] = {0.60, 0.45, 0.096, 1.0},
		[3] = {0.40, 0.30, 0.064, 1.0},
	}

	-- uncertainty smaller [1] will show skillUncertaintyColors[0]
	-- uncertainty smaller [2] will show skillUncertaintyColors[1]
	-- ...
	self.skillUncertaintyDistribution = {
		[1] = 1.5,
		[2] = 2.0,
		[3] = 3.0,
	}

	self.voteColor = {
		["yes"]   = {0.00, 1.00, 0.00, 1.0}, -- green
		["no"]    = {1.00, 0.00, 0.00, 1.0}, -- red
		["blank"] = {1.00, 0.80, 0.00, 1.0}, -- yellow
		["initVote"] = {0.80, 0.80, 0.80, 1.0}, -- grey
	}

	self.showRank    = true
	self.showSkillOpt = 2 -- 1: No 2: Yes 3: Detailed (with Uncertainty)
	self.showCountry = false

	self.useLastGameSpectatorState = 1 --1: Remember Last 2: Always Spectator 3: Always Player

	self.loadLocalWidgets = false
	self.displayBots = false
	self.filterbattleroom = true
	self.displayBadEngines2 = false
	self.allEnginesRunnable = true
	self.doNotSetAnySpringSettings = false
	self.agressivelySetBorderlessWindowed = false

	self.useWrongEngine = false
	self.multiplayerLaunchNewSpring = false
	self.myAccountID = false
	self.lastAddedAiName = false
	self.multiplayerDifferentEngine = true

	self.noNaiveConfigOverride = {
		settingsMenuValues = true,
		battleFilterVsAI = true,
	}

	self.battleTypeToName = {
		[5] = "cooperative",
		[6] = "team",
		[3] = "oneVsOne",
		[4] = "freeForAll",
		[0] = "custom",
	}
	self.battleTypeToHumanName = {
		[5] = "Coop",
		[6] = "Team",
		[3] = "1v1",
		[4] = "FFA",
		[0] = "Custom",
	}

	-- Do not ask again tests.
	self.confirmation_mainMenuFromBattle = false
	self.confirmation_battleFromBattle = false
	self.leaveMultiplayerOnMainMenu = false
	self.queueExitConfirmPromptDoNotAskAgain = false
	self.backConfirmation = {
		multiplayer = {
			self.leaveMultiplayerOnMainMenu and {
				doNotAskAgainKey = "confirmation_mainMenuFromBattle",
				question = "You are in a battle and will leave it if you return to the main menu. Are you sure you want to return to the main menu?",
				testFunction = function ()
					local battleID = lobby:GetMyBattleID()
					if not battleID then
						return false
					end
					if self.showMatchMakerBattles then
						return true
					end
					local battle = lobby:GetBattle(battleID)
					return (battle and not battle.isMatchMaker) or false
				end
			} or nil
		},
		singleplayer = {
		}
	}
	local gameConfPath = LUA_DIRNAME .. "configs/gameConfig/"

	self.gameConfigName = fileConfig.game
	self:LoadGameConfig(gameConfPath .. self.gameConfigName .. "/mainConfig.lua")

	-- self.campaignPath = "campaign/byartest"
	-- self.campaignConfigName = "byartest"
	-- self.campaignConfig = VFS.Include("campaign/byartest/mainConfig.lua") -- no campaign yet for BYAR
	-- self.campaignSaveFile = nil -- Set by user
	-- self.nextCampaignSaveNumber = 1
	-- self.campaignConfigOptions = {
	-- 	"sample",
	-- 	"byartest",
	-- 	"--dev"
	-- }
	-- self.campaignConfigHumanNames = {
	-- 	"Sample",
	-- 	"BYARtest",
	-- 	--"Dev"
	-- }
	local gameConfigOptions = {}
	local subdirs = VFS.SubDirs(gameConfPath)
	for index, subdir in ipairs(subdirs) do
		-- get just the folder name
		subdir = string.gsub(subdir, gameConfPath, "")
		subdir = string.sub(subdir, 1, -2)	-- truncate trailing slash
		Spring.Log(LOG_SECTION, LOG.NOTICE, "Detected game config", subdir)
		gameConfigOptions[#gameConfigOptions+1] = subdir
	end

	self.gameConfigOptions = {}
	self.gameConfigHumanNames = {}
	for i = 1, #gameConfigOptions do
		-- Skip re-loading the active game config (already loaded above).
		-- Each mainConfig.lua loads 14+ sub-files, so this saves significant I/O.
		if gameConfigOptions[i] == self.gameConfigName then
			if self.gameConfig.CheckAvailability() then
				self.gameConfigHumanNames[#self.gameConfigHumanNames + 1] = self.gameConfig.name
				self.gameConfigOptions[#self.gameConfigOptions + 1] = gameConfigOptions[i]
			end
		else
			local fileName = gameConfPath .. gameConfigOptions[i] .. "/mainConfig.lua"
			Spring.Log(LOG_SECTION, LOG.INFO, "Attempting to load game config: " .. fileName)
			if VFS.FileExists(fileName) then
				Spring.Log(LOG_SECTION, LOG.INFO, "Game config found:" .. fileName)
				local gameConfig = VFS.Include(fileName, nil, VFS.RAW_FIRST)
				if gameConfig.CheckAvailability() then
					self.gameConfigHumanNames[#self.gameConfigHumanNames + 1] = gameConfig.name
					self.gameConfigOptions[#self.gameConfigOptions + 1] = gameConfigOptions[i]
				end
			else
				Spring.Log(LOG_SECTION, LOG.WARNING, "Game config not found: " .. fileName)
			end
		end
	end

	self.autoLaunchAsSpectator = true
	self.lastLoginChatLength = 25
	self.notifyForAllChat = true
	self.ingameNotifcations = true -- Party, chat
	self.nonFriendNotifications = true -- Party, chat
	self.friendActivityNotification = true
	self.doNotDisturb = false
	self.addFriendWindowButton = true
	self.simplifiedSkirmishSetup = true
	self.debugMode = false
	self.devMode = VFS.FileExists("devmode.txt") or VFS.FileExists("devmode.txt.txt") or VFS.FileExists("devmode.rtf.txt")
	self.ShowhiddenModopions = false
	self.enableProfiler = false
	self.enableInspector = false
	self.enableCacheRapidPool = true
	self.showCampaignButton = false
	self.showPlanetUnlocks = false
	self.showPlanetEnemyUnits = false
	self.campaignSpawnDebug = false
	self.hidePartySystem = true
	self.showAddFriendBoxOnFriendWindow = true
	self.editCampaign = false
	self.activeDebugConsole = false
	self.onlyShowFeaturedMaps = true
	self.simpleAiList = true
	self.useSpringRestart = false
	self.menuMusicVolume = 0.3
	self.menuNotificationVolume = 0.8
	self.menuBackgroundBrightness = 0.8
	self.gameOverlayOpacity = 0.5
	self.coopConnectDelay = 5
	self.showMatchMakerBattles = false
	self.hideInterface = false
	self.enableTextToSpeech = true
	self.showOldAiVersions = false
	self.showAiOptions = true
	self.drawAtFullSpeed = false
	self.fixFlicker = true
	self.lastFactionChoice = 0
	self.lastStartedBattleID = 0
	self.lastGameSpectatorState = false
	self.lobbyIdleSleep = false
	self.rememberQueuesOnStart = false
	self.channels = {}
	if self.gameConfig.defaultChatChannels ~= nil then
		for _, channelName in ipairs(self.gameConfig.defaultChatChannels) do
			self.channels[channelName] = true
		end
	end
	self.staticTooltipPositions = true

	self.language = "en"
	self.languages = {
		["en"] = {locale = "en", name="English"},
		["de"] = {locale = "de", name="Deutsch"},
	}

	self.lobby_fullscreen = 1
	self.game_fullscreen = 1

	-- Lazy-load config param types: Spring.GetConfigParams() returns a large
	-- table but configParamTypes is only used for individual lookups (settings window).
	-- Defer the iteration until first access.
	self.configParamTypes = setmetatable({}, {
		__index = function(t, name)
			-- Populate all entries on first access, then remove metamethod
			for _, param in pairs(Spring.GetConfigParams()) do
				rawset(t, param.name, param.type)
			end
			setmetatable(t, nil)
			return rawget(t, name)
		end
	})

	self.AtiIntelSettingsOverride = {
		Water = 1,
		AdvSky = 0,
		UsePBO = 0,
	}

	self.countryShortnames = VFS.Include(LUA_DIRNAME .. "configs/countryShortname.lua")
	if self.gameConfig.springSettingsPath ~= nil then
		self.game_settings = VFS.Include(self.gameConfig.springSettingsPath)
	else
		self.game_settings = VFS.Include(LUA_DIRNAME .. "configs/springsettings/springsettings.lua")
	end
	self.forcedCompatibilityProfile = VFS.Include(LUA_DIRNAME .. "configs/springsettings/forcedCompatibilityProfile.lua")

	local default = self.gameConfig.SettingsPresetFunc and self.gameConfig.SettingsPresetFunc()
	if default then
		self.settingsMenuValues = {}
		for name, defValue in pairs(default) do
			self:SetSettingsConfigOption(name, defValue)
		end
	else
		self.settingsMenuValues = self.gameConfig.settingsDefault -- Only until configuration data is loaded.
	end

	self.animate_lobby = (gl.CreateShader ~= nil)
	self.minimapDownloads = {}
	self.minimapThumbDownloads = {}
	self.downloadRetryCount = 3

	local saneCharacterList = {
		"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
		"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
		"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "[", "]", "_",
	}
	self.saneCharacters = {}
	for i = 1, #saneCharacterList do
		self.saneCharacters[saneCharacterList[i]] = true
	end

	local engineSaneCharacterList = {
		"-", ".", " ",
	}
	self.engineSaneCharacters = {}
	for i = 1, #engineSaneCharacterList do
		self.engineSaneCharacters[engineSaneCharacterList[i]] = true
	end

	self.barMngSettings = {
		autoBalance = true,
		teamSize = true,
		nbTeams = true,
		balanceMode = true,
		preset = true,
		boss = true,
		mutes = true,
	}
	-- SAIDBATTLEEX Prefixes
	self.BTLEX_JOINQUEUE = "You are now in the join-queue at position"
	self.BTLEX_BARMANAGER = "* BarManager|"

	-- tooltip prefixes
	self.USER_TOOLTIP_PREFIX    = "user_"
	self.USER_SP_TOOLTIP_PREFIX = "user_single_"
	self.USER_CH_TOOLTIP_PREFIX = "user_chat_s_"
	self.USER_MP_TOOLTIP_PREFIX = "user_battle_"
	self.BATTLE_TOOLTIP_PREFIX  = "battle_tooltip_"
	self.MINIMAP_TOOLTIP_PREFIX = "minimap_tooltip_"
	self.REPLAY_TOOLTIP_PREFIX	= "replay_tooltip_"

	-- should be removed at about 1.1.2024 together with all other occurences of tempChangedShowSkill
	-- remember if new default of showSkill was applied
	self.tempChangedShowSkill = false
	self.supperAnnouncementKey = "nil"

	self.rejoinID = "nil"
end


---------------------------------------------------------------------------------
-- Settings
---------------------------------------------------------------------------------

function Configuration:LoadGameConfig(path)
	self.gameConfig = VFS.Include(path)
	if type(self.gameConfig) ~= 'table' then
		Spring.Log("Settings", LOG.ERROR, 'Chobby configuration error. Returned game config is not a table: ' .. tostring(path))
		return
	end
	local mandatoryFields = {"settingsNames"}
	for _, mandatoryField in ipairs(mandatoryFields) do
		if self.gameConfig[mandatoryField] == nil then
			Spring.Log("Settings", LOG.ERROR, "Chobby configuration error. Mandatory field is missing: " .. mandatoryField .. ". Check your game settings")
		end
	end
	localLobby.useTeamColor = not self.gameConfig.disableColorChoosing
end

function Configuration:SetSpringsettingsValue(key, value, compatOverride)
	if self.doNotSetAnySpringSettings then
		return
	end

	if not compatOverride then
		local compatProfile = self.forcedCompatibilityProfile
		if compatProfile and compatProfile[key] then
			return
		end
	end

	value = (self.fixedSettingsOverride and self.fixedSettingsOverride[key]) or value

	local configType = self.configParamTypes[key]
	if configType == "int" then
		Spring.Echo("SetSettings Int", key, value)
		Spring.SetConfigInt(key, value)
	elseif configType == "bool" or configType == "float" then
		Spring.Echo("SetSettings Value", key, value)
		Spring.SetConfigString(key, value)
	elseif configType == nil then
		Spring.Log("Settings", LOG.WARNING, "No such key: " .. tostring(key) .. ", but setting it as string anyway.")
		Spring.SetConfigString(key, value)
	else
		Spring.Log("Settings", LOG.WARNING, "Unexpected key type: " .. configType .. ", but setting it as string anyway.")
		Spring.SetConfigString(key, value)
	end
end

function Configuration:UpdateFixedSettings(newOverride)
	local gameSettings = self.game_settings

	-- Reset old
	local oldOverride = self.fixedSettingsOverride
	self.fixedSettingsOverride = nil
	if oldOverride then
		for key, value in pairs(oldOverride) do
			if gameSettings[key] then
				self:SetSpringsettingsValue(key, gameSettings[key])
			end
		end
	end

	-- Apply new
	self.fixedSettingsOverride = newOverride
	if newOverride then
		for key, value in pairs(newOverride) do
			self:SetSpringsettingsValue(key, value)
		end
	end
end

function Configuration:SetSettingsConfigOption(name, newValue)
	local setting = self.gameConfig.settingsNames[name]
	if not setting then
		return false
	end

	self.settingsMenuValues[name] = newValue

	if setting.isNumberSetting then
		local applyFunction = setting.applyFunction
		if applyFunction then
			local applyData = applyFunction(newValue, self)
			if applyData then
				for applyName, value in pairs(applyData) do
					self.game_settings[applyName] = value
					self:SetSpringsettingsValue(applyName, value)
				end
			end
		else
			local springValue = setting.springConversion(newValue)
			self.game_settings[setting.applyName] = springValue
			self:SetSpringsettingsValue(setting.applyName, springValue)
		end
	else
		if setting.optionNames == nil or (not setting.optionNames[newValue]) then
			return false
		end

		-- Selection from multiple options
		local selectedOption = setting.optionNames[newValue]
		if setting.fileTarget then
			self.settingsMenuValues[name .. "_file"] = selectedOption.file
			if setting.applyFunction then
				setting.applyFunction(selectedOption.file, self)
			else
				local sourceFile = VFS.LoadFile(selectedOption.file)
				local settingsFile = io.open(setting.fileTarget, "w")
				settingsFile:write(sourceFile)
				settingsFile:close()
			end
		else
			local applyData = selectedOption.apply or (selectedOption.applyFunction and selectedOption.applyFunction(nil, self))
			if not applyData then
				return true
			end
			for applyName, value in pairs(applyData) do
				self.game_settings[applyName] = value
				self:SetSpringsettingsValue(applyName, value)
			end
		end
	end
	return true
end

function Configuration:ApplySettingsConfigPreset(preset)
	for name, value in pairs(preset) do
		self:SetSettingsConfigOption(name, value)
	end
end

---------------------------------------------------------------------------------
-- Widget interface callins
---------------------------------------------------------------------------------

local function screenSizeKey()
	local vsx, vsy = Spring.Orig.GetViewSizes()
	-- Scale down to avoid using different keys for only slightly different view sizes.
	return math.floor(vsx / 500) .. "x" .. math.floor(vsy / 250)
end

function Configuration:SetUiScale(newScale)
	newScale = newScale or self.uiScalesForScreenSizes[screenSizeKey()] or self.uiScale

	self.uiScale = math.max(self.minUiScale, math.min(self.maxUiScale, newScale))
	WG.uiScale = self.uiScale
	self.uiScalesForScreenSizes[screenSizeKey()] = newScale

	self:_CallListeners("OnUiScaleChange", newScale)

	local screenWidth, screenHeight = Spring.GetViewSizes()
	screen0:Resize(screenWidth, screenHeight)
end

function Configuration:UpdateUiScaleMaxMin()
	local screenWidth, screenHeight = Spring.Orig.GetViewSizes()
	local oldMin = self.minUiScale
	local oldMax = self.maxUiScale

	self.maxUiScale = math.max(1, screenWidth / 960, screenHeight / 540) -- 200% @ 1080p; 400% @ 4k -- 200% @ 1080p; 400% @ 4k
	-- size it against font sizes, because readability is the lower limit here.
	-- font[0] is outlined and larger, so cap it against font[1]
	self.minUiScale = 7 / self.font[1].size

	if oldMin ~= self.minUiScale or oldMax ~= self.maxUiScale then
		self:_CallListeners("OnUiScaleMaxMinChange", self.minUiScale, self.maxUiScale)
	end
end

function Configuration:SetConfigData(data)
	if data.campaignConfigName == "dev" then
		data.campaignConfigName = "sample"
	end

	self.uiScalesForScreenSizes = data.uiScalesForScreenSizes or {}
	self:SetUiScale()

	if data ~= nil then
		for k, v in pairs(data) do
			if not self.noNaiveConfigOverride[k] then
				self:SetConfigValue(k, v)
			end
		end
	end

	if data.battleFilterVsAI ~= nil then
		self.battleFilterPvMode = data.battleFilterVsAI and 2 or 1
		Spring.Log("Settings", LOG.NOTICE, ("Migrated battleFilterVsAI (%s) -> battleFilterPvMode (%d)"):format(tostring(data.battleFilterVsAI), self.battleFilterPvMode))
	end

	-- should be removed at 1.1.2024
	-- replace showSkillOpt once , if it's not already above 1
	if not self.tempChangedShowSkill then
		if self.showSkillOpt == 1 then
			self:SetConfigValue("showSkillOpt", 2)
		end
		self.tempChangedShowSkill = true
	end

	-- Fix old channel memory.
	for key, value in pairs(self.channels) do
		if string.find(key, "debriefing") or string.find(key, "party_") then
			self.channels[key] = nil
		end
	end

	self.game_settings.XResolutionWindowed = nil
	self.game_settings.YResolutionWindowed = nil
	self.game_settings.WindowPosX = nil
	self.game_settings.WindowPosY = nil
	self.game_settings.WindowBorderless = nil
	self.game_settings.Fullscreen = nil

	-- Fix old memory
	self.game_settings.UnitIconDist = nil

	local newSpringsettings, onlyIfMissingSettings = VFS.Include(LUA_DIRNAME .. "configs/springsettings/springsettingsChanges.lua")
	for key, value in pairs(newSpringsettings) do
		self.game_settings[key] = value
	end
	for key, value in pairs(onlyIfMissingSettings) do
		if self.game_settings[key] == nil then
			self.game_settings[key] = value
		end
	end

	if data.settingsMenuValues then
		for name, value in pairs(data.settingsMenuValues) do
			self:SetSettingsConfigOption(name, value)
		end
	end
end

function Configuration:GetConfigData()
	local rememberedPassword = false
	if self.rememberPassword then
		rememberedPassword = self.password
	end
	return {
		tempChangedShowSkill = self.tempChangedShowSkill, -- should be removed at 1.1.2024
		autoLaunchAsSpectator = self.autoLaunchAsSpectator,
		serverAddress = self.serverAddress,
		serverPort = self.serverPort,
		userName = self.userName,
		suggestedNameFromSteam = self.suggestedNameFromSteam,
		uiScalesForScreenSizes = self.uiScalesForScreenSizes,
		rememberPassword = self.rememberPassword,
		password = rememberedPassword,
		autoLogin = self.autoLogin,
		uploadLogPrompt = self.uploadLogPrompt,
		firstLoginEver = self.firstLoginEver,
		wantAuthenticateWithSteam = self.wantAuthenticateWithSteam,
		useSteamBrowser = self.useSteamBrowser,
		steamLinkComplete = self.steamLinkComplete,
		alreadySeenFactionPopup4 = self.alreadySeenFactionPopup4,
		firstBattleStarted = self.firstBattleStarted,
		seenWelcomeItems = self.seenWelcomeItems,
		battleFilterPassworded2 = self.battleFilterPassworded2,
		battleFilterNonFriend = self.battleFilterNonFriend,
		battleFilterRunning = self.battleFilterRunning,
		battleFilterLocked = self.battleFilterLocked,
		battleFilterVsAI = self.battleFilterVsAI,
		battleFilterPvMode = self.battleFilterPvMode,
		channels = self.channels,
		gameConfigName = self.gameConfigName,
		language = self.language,
		game_fullscreen = self.game_fullscreen,
		panel_layout = self.panel_layout,
		lobby_fullscreen = self.lobby_fullscreen,
		manualBorderless = self.manualBorderless,
		manualFullscreen = self.manualFullscreen,
		manualWindowed = self.manualWindowed,
		animate_lobby = self.animate_lobby,
		game_settings = self.game_settings,
		notifyForAllChat = self.notifyForAllChat,
		ingameNotifcations = self.ingameNotifcations,
		nonFriendNotifications = self.nonFriendNotifications,
		doNotDisturb = self.doNotDisturb,
		simplifiedSkirmishSetup = self.simplifiedSkirmishSetup,
		debugMode = self.debugMode,
		debugAutoWin = self.debugAutoWin,
		enableProfiler = self.enableProfiler,
		enableInspector = self.enableInspector,
		enableCacheRapidPool= self.enableCacheRapidPool,
		showCampaignButton = self.showCampaignButton,
		showPlanetUnlocks = self.showPlanetUnlocks,
		showPlanetEnemyUnits = self.showPlanetEnemyUnits,
		campaignSpawnDebug = self.campaignSpawnDebug,
		hidePartySystem = self.hidePartySystem,
		showAddFriendBoxOnFriendWindow = self.showAddFriendBoxOnFriendWindow,
		editCampaign = self.editCampaign,
		confirmation_mainMenuFromBattle = self.confirmation_mainMenuFromBattle,
		confirmation_battleFromBattle = self.confirmation_battleFromBattle,
		drawAtFullSpeed = self.drawAtFullSpeed,
		fixFlicker = self.fixFlicker,
		lastFactionChoice = self.lastFactionChoice,
		lastStartedBattleID = self.lastStartedBattleID,
		lastGameSpectatorState = self.lastGameSpectatorState,
		lobbyIdleSleep = self.lobbyIdleSleep,
		rememberQueuesOnStart = self.rememberQueuesOnStart,
		loadLocalWidgets = self.loadLocalWidgets,
		activeDebugConsole = self.activeDebugConsole,
		onlyShowFeaturedMaps = self.onlyShowFeaturedMaps,
		simpleAiList = self.simpleAiList,
		coopConnectDelay = self.coopConnectDelay,
		useSpringRestart = self.useSpringRestart,
		displayBots = self.displayBots,
		filterbattleroom = self.filterbattleroom,
		displayBadEngines2 = self.displayBadEngines2,
		useWrongEngine = self.useWrongEngine,
		multiplayerLaunchNewSpring = self.multiplayerLaunchNewSpring,
		multiplayerDifferentEngine = self.multiplayerDifferentEngine,
		doNotSetAnySpringSettings = self.doNotSetAnySpringSettings,
		agressivelySetBorderlessWindowed = self.agressivelySetBorderlessWindowed,
		fixedSettingsOverride = self.fixedSettingsOverride,
		settingsMenuValues = self.settingsMenuValues,
		menuMusicVolume = self.menuMusicVolume,
		menuNotificationVolume = self.menuNotificationVolume,
		menuBackgroundBrightness = self.menuBackgroundBrightness,
		gameOverlayOpacity = self.gameOverlayOpacity,
		showMatchMakerBattles = self.showMatchMakerBattles,
		matchmakerRejectTime = self.matchmakerRejectTime,
		matchmakerRejectCount = self.matchmakerRejectCount,
		matchmakerPopupTime = self.matchmakerPopupTime,
		enableTextToSpeech = self.enableTextToSpeech,
		showOldAiVersions = self.showOldAiVersions,
		showAiOptions = self.showAiOptions,
		chatFontSize = self.chatFontSize,
		myAccountID = self.myAccountID,
		lastAddedAiName = self.lastAddedAiName,
		window_WindowPosX = self.window_WindowPosX,
		window_WindowPosY = self.window_WindowPosY,
		window_XResolutionWindowed = self.window_XResolutionWindowed,
		window_YResolutionWindowed = self.window_YResolutionWindowed,
		campaignSaveFile = self.campaignSaveFile,
		nextCampaignSaveNumber = self.nextCampaignSaveNumber,
		steamReleasePopupSeen = self.steamReleasePopupSeen,
		campaignConfigName = self.campaignConfigName,
		showSkill   = self.showSkill,
		showSkillOpt   = self.showSkillOpt,
		showRank    = self.showRank,
		showCountry = self.showCountry,
		useLastGameSpectatorState = self.useLastGameSpectatorState,
		friendsFilterOnline = self.friendsFilterOnline,
		queueExitConfirmPromptDoNotAskAgain = self.queueExitConfirmPromptDoNotAskAgain,
		supperAnnouncementKey = self.supperAnnouncementKey,
		rejoinBattleID = self.rejoinBattleID
	}
end

---------------------------------------------------------------------------------
-- Setters
---------------------------------------------------------------------------------

function Configuration:SetConfigValue(key, value)
	if self[key] == value then
		return
	end
	-- when a local chobby-install previously used a server formatted like "server%d.beyondallreason.info", then ignore the locally saved address and use the one from chobby_config.json instead (which is already set at chobby start).
	-- this way changes to chobby_config.json take effect for all users with unchanged serverAddress (still users using localhost or anything else stay uneffected)
	if (key == "serverAddress" and string.find(value, "server%d.beyondallreason.info")) then
		return
	end
	self[key] = value
	if key == "useSpringRestart" then
		lobby.useSpringRestart = value
		localLobby.useSpringRestart = value
	end
	if key == "disableColorChoosing" then
		localLobby.useTeamColor = not value
	end
	if key == "gameConfigName" then
		self:LoadGameConfig(LUA_DIRNAME .. "configs/gameConfig/" .. value .. "/mainConfig.lua")
		if self.gameConfig and WG and WG.ScenarioHandler then
			WG.ScenarioHandler.reloadGameVersion()
		end
	end
	-- if key == "campaignConfigName" then
	-- 	self.campaignPath = "campaign/" .. value
	-- 	self.campaignConfig = VFS.Include("campaign/" .. value .. "/mainConfig.lua")
	-- end
	self:_CallListeners("OnConfigurationChange", key, value)
end

---------------------------------------------------------------------------------
-- Getters
---------------------------------------------------------------------------------

function Configuration:GetServerAddress()
	if self.ForceDefaultServer then
		return self.DefaultServerHost
	end
	return self.serverAddress
end

function Configuration:GetServerPort()
	if self.ForceDefaultServer then
		return self.DefaultServerPort
	end
	return self.serverPort
end

function Configuration:GetErrorColor()
	return self.errorColor
end

function Configuration:GetWarningColor()
	return self.warningColor
end

function Configuration:GetNormalColor()
	return self.normalColor
end

function Configuration:GetSuccessColor()
	return self.successColor
end

function Configuration:GetPartialColor()
	return self.partialColor
end

function Configuration:GetSelectedColor()
	return self.selectedColor
end

function Configuration:GetHighlightedColor()
	return self.highlightedColor
end

function Configuration:GetButtonFocusColor()
	return self.buttonFocusColor
end

function Configuration:GetModeratorColor()
	return self.moderatorColor
end

function Configuration:GetFounderColor()
	return self.founderColor
end

function Configuration:GetDisregardUserNameColor(status)
	if type(status) ~= "number" or status < 1 or status > 3 then
		Spring.Log(LOG_SECTION, LOG.ERROR, "Asked for a not existing disregard user name color:", status)
		return self.userNameColor
	else
		return self.disregardUserNameColor[status]
	end
end

function Configuration:GetDisregardStatusName(status)
	if type(status) ~= "number" or status < 1 or status > 3 then
		Spring.Log(LOG_SECTION, LOG.ERROR, "Asked for a not existing disregard status name:", status)
		return "ERROR"
	end
	return self.disregardStatusNames[status]
end

function Configuration:GetUserNameColor()
	return self.userNameColor
end

function Configuration:GetMyUserNameColor()
	return self.myUserNameColor
end

function Configuration:GetFriendsColor()
	return self.friendsColor
end

-- NOTE: this one is in opengl range [0,1]
function Configuration:GetButtonSelectedColor()
	return self.buttonSelectedColor
end

function Configuration:GetChannels()
	return self.channels
end

function Configuration:GetCross()
	return self:GetErrorColor() .. "X"
end

function Configuration:GetTick()
	return self:GetSuccessColor() .. "O"
end

function Configuration:GetFont(sizeScale, specialName, specialData, rawSize)
	if not specialName and not rawSize then
		return self.font[sizeScale]
	end
	local size = (rawSize and sizeScale) or self.fontRaw[sizeScale].size
	if not self.fontSpecial[size] then
		self.fontSpecial[size] = {}
	end
	if not self.fontSpecial[size][specialName] then
		specialData = specialData or {}
		specialData.font = specialData.font or self.fontName
		specialData.size = size
		
		specialData.color        = specialData.color or {1,1,1,1}
		specialData.outlineColor = specialData.outlineColor or {0.05,0.05,0.05,0.9}
		specialData.outline      = specialData.outline or false
		specialData.shadow       = specialData.shadow or true
		self.fontSpecial[size][specialName] = Font:New(specialData)
	end
	return self.fontSpecial[size][specialName]
end

function Configuration:GetHintFont(sizeScale, specialName, specialData, rawSize)
	specialName = (specialName or "") .. "_hint_" .. sizeScale
	specialData = specialData or {}
	specialData.color = {1,1,1,0.48}
	return self:GetFont(sizeScale, specialName, specialData, rawSize)
end

function Configuration:GetButtonFont(sizeScale, specialName, specialData, rawSize)
	specialName = (specialName or "") .. "_button_" .. sizeScale
	specialData = specialData or {}
	specialData.outline = true
	specialData.outlineWidth = 3
	specialData.outlineHeight = 3
	return self:GetFont(sizeScale, specialName, specialData, rawSize)
end

function Configuration:AllowNotification(playerName, playerList)
	if (not self.ingameNotifcations) and (Spring.GetGameName() ~= "") then
		return false
	end
	if lobby and not self.nonFriendNotifications then
		if playerName then
			local userInfo = lobby:TryGetUser(playerName)
			if not userInfo.isFriend then
				return false
			end
		end

		if playerList then
			local foundFriend = false
			for i = 1, #playerList do
				local userInfo = lobby:TryGetUser(playerList[i])
				if userInfo.isFriend then
					foundFriend = true
					break
				end
			end
			if not foundFriend then
				return false
			end
		end
	end
	return true
end

local minimapSmallImageCache = {}
function Configuration:GetMinimapSmallImage(mapName)
	if minimapSmallImageCache[mapName] then
		return minimapSmallImageCache[mapName], false
	end
	local found = false
	if not self.gameConfig.minimapThumbnailPath then
		return LUA_DIRNAME .. "images/minimapNotFound1.png"
	end
	mapName = string.gsub(mapName, " ", "_")
	local filePath = self.gameConfig.minimapThumbnailPath .. mapName .. ".png"
	if not VFS.FileExists(filePath) then
		filePath = "LuaMenu/Images/Minimaps/" .. mapName .. ".jpg"
		if not VFS.FileExists(filePath) then
			Spring.Log("Chobby", LOG.WARNING,"GetMinimapSmallImage not found for",mapName)
			filePath = "LuaMenu/Images/minimapNotFound.png"
		else found = true end
	else found = true end

--[[ 	if WG.WrapperLoopback and WG.WrapperLoopback.DownloadImage and (not VFS.FileExists(filePath)) then
		if not self.minimapThumbDownloads[mapName] then
			Spring.CreateDir("LuaMenu/Images/MinimapThumbnails")
			WG.WrapperLoopback.DownloadImage({ImageUrl = "http://zero-k.info/Resources/" .. mapName .. ".thumbnail.jpg", TargetPath = filePath})
			self.minimapThumbDownloads[mapName] = true
		end
		return filePath, true
	end ]]
	
	if found then
		minimapSmallImageCache[mapName] = filePath
	end
	return filePath, not found
end

function Configuration:GetMinimapImage(mapName)
	if not self.gameConfig.minimapOverridePath then
		return LUA_DIRNAME .. "images/minimapNotFound1.png"
	end
	mapName = string.gsub(mapName, " ", "_")
	local filePath = self.gameConfig.minimapOverridePath .. mapName .. ".jpg"
	if not VFS.FileExists(filePath) then
		filePath = "LuaMenu/Images/Minimaps/" .. mapName .. ".jpg"
	end
	if not VFS.FileExists(filePath) then
	 	Spring.Log("Chobby", LOG.WARNING,"GetMinimapImage not found for",mapName)
	 	filePath = "LuaMenu/Images/minimapNotFound.png"
	end
--[[ 	if WG.WrapperLoopback and WG.WrapperLoopback.DownloadImage and (not VFS.FileExists(filePath)) then
		if not self.minimapDownloads[mapName] then
			Spring.CreateDir("LuaMenu/Images/Minimaps")
			WG.WrapperLoopback.DownloadImage({ImageUrl = "http://zero-k.info/Resources/" .. mapName .. ".minimap.jpg", TargetPath = filePath})
			self.minimapDownloads[mapName] = true
		end
		return filePath, true
	end ]]
	return filePath, not VFS.FileExists(filePath)
end

function Configuration:GetLoadingImage(size)
	if size == 1 then
		return LUA_DIRNAME .. "images/load_img_32.png"
	elseif size == 2 then
		return LUA_DIRNAME .. "images/load_img_128.png"
	elseif size == 3 then
		return LUA_DIRNAME .. "images/load_img_512.png"
	end
	return LUA_DIRNAME .. "images/load_img_128.png"
end

function Configuration:GetCountryLongname(shortname)
	if shortname and self.countryShortnames[shortname] then
		return self.countryShortnames[shortname]
	end
	return shortname
end

function Configuration:GetHeadingImage(fullscreenMode, title)
	local subheadings = self.gameConfig.subheadings
	if fullscreenMode then
		return (subheadings and subheadings.large and subheadings.large[title]) or self.gameConfig.headingLarge
	else
		return (subheadings and subheadings.small and subheadings.small[title]) or self.gameConfig.headingSmall
	end
end

function Configuration:GetTruncatedEngineVersion()
	if tonumber(Spring.Utilities.GetEngineVersion()) then
		-- Master releases lack the '.0' at the end. Who knows what other cases are wrong.
		-- Add as required.
		return (Spring.Utilities.GetEngineVersion() .. ".0")
	else
		return string.gsub(string.gsub(string.gsub(Spring.Utilities.GetEngineVersion(), " maintenance", ""), " develop", "")," BAR", "")
	end
end

function Configuration:IsValidEngineVersion(engineVersion)
	local validengine = (engineVersion == Spring.Utilities.GetEngineVersion() or engineVersion == self:GetTruncatedEngineVersion())
	--Spring.Echo(" Configuration:IsValidEngineVersion(engineVersion)",engineVersion, validengine)
	--Spring.Echo(" Spring.Utilities.GetEngineVersion() ",Spring.Utilities.GetEngineVersion() )
	--Spring.Echo(" self:GetTruncatedEngineVersion()",self:GetTruncatedEngineVersion())
	return validengine
end

function Configuration:SanitizeEngineVersion(engineVersion)
	local ret = ""
	local length = string.len(engineVersion)
	for i = 1, length do
		local c = string.sub(engineVersion, i, i)
		if self.saneCharacters[c] or self.engineSaneCharacters[c] then
			ret = ret .. c
		end
	end

	local oldFormat = "(%d+)%.(%d+)%.(%d+)%-(%d+)%-g([%x][%x][%x][%x][%x][%x][%x])%s"
	local newFormat = "(%d+)%.(%d+)%.(%d+)"
	if not ret:match(oldFormat) and not ret:match(newFormat) then
        Spring.Echo("Invalid engine version format: " .. engineVersion)
		ret = ""
    end

	return ret
end

function Configuration:SanitizeName(name, usedNames)
	local ret = ""
	local length = string.len(name)
	Spring.Echo("SanitizeName", name)
	for i = 1, length do
		local c = string.sub(name, i, i)
		if self.saneCharacters[c] then
			ret = ret .. c
		end
	end

	if ret == "" then
		ret = "Player"
	end
	if usedNames then
		while usedNames[ret] do
			ret = ret .. "1"
		end
		usedNames[ret] = true
	end

	return ret, usedNames
end

function Configuration:GetPlayerName(allowBlank)
	local suggest = (lobby and lobby.myUserName) or self.suggestedNameFromSteam or (allowBlank and "") or "Player"
	if (not allowBlank) and suggest == "" then
		return "Player"
	end
	return suggest
end

function Configuration:GetDefaultGameName()
	local rapidTag = "byar:test"
	if not self.gameConfig then
		Spring.Log(LOG_SECTION, LOG.ERROR, "self.gameConfig not present in Configuration:GetDefaultGameName()")
		return false
	end
	
	if self.gameConfig and self.gameConfig._defaultGameRapidTag then 
		rapidTag = self.gameConfig._defaultGameRapidTag
	else
		Spring.Log(LOG_SECTION, LOG.ERROR, "self.gameConfig._defaultGameRapidTag not present in Configuration:GetDefaultGameName(), using: Beyond All Reason $VERSION")
		return "Beyond All Reason $VERSION"
	end

	if rapidTag and VFS.GetNameFromRapidTag then
		local rapidName = VFS.GetNameFromRapidTag(rapidTag)
		if rapidName then
			return rapidName
		end
	end

	return self.gameConfig._defaultGameArchiveName
end

function Configuration:GetSideData()
	if not self.gameConfig then
		return nil
	end
	return self.gameConfig.sidedata
end

function Configuration:GetSideById(sideId)
	if sideId == nil then
		return { name = nil, logo = nil }
	end
	local sidedata = Configuration:GetSideData()
	if sidedata == nil or sideId < 0 or sideId > #sidedata - 1 then
		return { name = nil, logo = nil }
	end
	return sidedata[sideId + 1]
end

function Configuration:GetIsRunning64Bit()
	if self.isRunning64Bit ~= nil then
		return self.isRunning64Bit
	end
	-- if Platform then
		-- osWordSize is not the same as spring bit version.
		--return Platform.osWordSize == 64
	-- end
	local infologFile, err = io.open("infolog.txt", "r")
	if not infologFile then
		Spring.Echo("Error opening infolog.txt", err)
		return false
	end
	local line = infologFile:read()
	while line do
		if string.find(line, "Physical CPU Cores") then
			break
		end
		if string.find(line, "Word Size") then
			if string.find(line, "64%-bit") then
				self.isRunning64Bit = true
				infologFile:close()
				return true
			else
				self.isRunning64Bit = false
				infologFile:close()
				return false
			end
		end
		line = infologFile:read()
	end
	infologFile:close()
	return false
end

function Configuration:GetIsDevEngine()
	local engine = self:GetTruncatedEngineVersion()
	local splits = engine:split("-")
	if splits and splits[2] and tonumber(splits[2]) then
		return tonumber(splits[2]) > 400
	end
	return false
end

function Configuration:GetIsNotRunningNvidia()
	if self.isNotRunningNvidia ~= nil then
		return self.isNotRunningNvidia
	end
	if Platform then
		return Platform.gpuVendor ~= "Nvidia"
	end
	local infologFile, err = io.open("infolog.txt", "r")
	if not infologFile then
		Spring.Echo("Error opening infolog.txt", err)
		return false
	end
	local line = infologFile:read()
	while line do
		if string.find(line, "PostInit") then
			-- We are past the part of the infolog where NVIDIA would appear
			infologFile:close()
			self.isNotRunningNvidia = true
			return true
		end
		if string.find(line, "NVIDIA") then
			infologFile:close()
			self.isNotRunningNvidia = false
			return false
		end
		line = infologFile:read()
	end
	infologFile:close()
	self.isNotRunningNvidia = true
	return true
end

---------------------------------------------------------------------------------
-- Listener handler
---------------------------------------------------------------------------------
local function ShallowCopy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in pairs(orig) do
			copy[orig_key] = orig_value
		end
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end

function Configuration:AddListener(event, listener)
	if listener == nil then
		Log.Error("Event: " .. tostring(event) .. ", listener cannot be nil")
		return
	end
	local eventListeners = self.listeners[event]
	if eventListeners == nil then
		eventListeners = {}
		self.listeners[event] = eventListeners
	end
	table.insert(eventListeners, listener)
end

function Configuration:RemoveListener(event, listener)
	if self.listeners[event] then
		for k, v in pairs(self.listeners[event]) do
			if v == listener then
				table.remove(self.listeners[event], k)
				if #self.listeners[event] == 0 then
					self.listeners[event] = nil
				end
				break
			end
		end
	end
end

function Configuration:_CallListeners(event, ...)
	if self.listeners[event] == nil then
		return nil -- no event listeners
	end
	local eventListeners = ShallowCopy(self.listeners[event])
	local args = {...}
	local n = select("#", ...)
	for i = 1, #eventListeners do
		local listener = eventListeners[i]
		xpcall(function() listener(listener, unpack(args, 1, n)) end,
			function(err) self:_PrintError(err) end )
	end
	return true
end

function Configuration:_PrintError(err)
	-- FIXME: cleanup more
	Log.Error(err)
	Log.Error(debug.traceback(err))
end

---------------------------------------------------------------------------------
-- 'Initialization'
---------------------------------------------------------------------------------
-- shadow the Configuration class with a singleton
Configuration = Configuration()
