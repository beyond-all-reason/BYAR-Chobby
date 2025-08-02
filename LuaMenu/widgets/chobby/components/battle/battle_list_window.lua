BattleListWindow = ListWindow:extends{}

local IMG_BATTLE_RUNNING  = LUA_DIRNAME .. "images/ingame.png"
local IMG_LOCK            = LUA_DIRNAME .. "images/lock.png"
local IMG_KEY             = LUA_DIRNAME .. "images/key.png"

local myFont1 = WG.Chobby.Configuration:GetFont(1)
local myFont2 = WG.Chobby.Configuration:GetFont(2)
local myFont3 = WG.Chobby.Configuration:GetFont(3)
local myHintFont = WG.Chobby.Configuration:GetFont(11)


function BattleListWindow:init(parent)

	self:super("init", parent, "Play or watch a game", true, nil, nil, nil, 34)
	self.name = "BattleListWindow"

	self.searchbar = EditBox:New{
		x = 418,
		y = 11,
		right = 100,
		width = 300,
		height = 37,
		hint = i18n("searchbar_hint"),
		text = "",
		objectOverrideFont = myFont3,
		objectOverrideHintFont = myHintFont,
		parent = self.window,
		OnTextModified = {
			function (input)
				Configuration.gameConfig.battleListOnlyShow = input.text
				-- force an update
				if Configuration.battleFilterRedundant then
					self:UpdateAllBattleIDs()
				end
				self:UpdateFilters()
			end
		}
	}


	if not Configuration.gameConfig.disableBattleListHostButton then
		self.btnNewBattle = Button:New {
			x = 250,
			y = 7,
			width = 160,
			height = 45,
			caption = i18n("open_mp_game"),
			objectOverrideFont = myFont3,
			classname = "option_button",
			parent = self.window,
			OnClick = {
				function ()
					self:OpenHostWindow()
				end
			},
		}
	end

	self.infoPanel = Panel:New {
		classname = "overlay_window",
		x = "15%",
		y = "40%",
		right = "15%",
		bottom = "40%",
		parent = self.window,
	}
	self.infoLabel = Label:New {
		x = "5%",
		y = "5%",
		width = "90%",
		height = "90%",
		align = "center",
		valign = "center",
		parent = self.infoPanel,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3, "Nimbus3", {font = "fonts/n019003l.pfb"}),
	}
	self.infoPanel:SetVisibility(false)

	Label:New {
		x = 20,
		right = 5,
		bottom = 15,
		height = 20,
		objectOverrideFont = myFont2,
		caption = "Filter out:",
		parent = self.window
	}

	local checkPassworded = Checkbox:New {
		x = "15%",
		width = 21,
		bottom = 8,
		height = 30,
		boxalign = "left",
		boxsize = 20,
		caption = " Passworded",
		checked = Configuration.battleFilterPassworded2 or false,
		objectOverrideFont = myFont2,
		OnChange = {
			function (obj, newState)
				Configuration:SetConfigValue("battleFilterPassworded2", newState)
				self:SoftUpdate()
			end
		},
		parent = self.window,
		tooltip = "Hides all battles that require a password to join",
	}
	local checkNonFriend = Checkbox:New {
		x = "33%",
		width = 21,
		bottom = 8,
		height = 30,
		boxalign = "left",
		boxsize = 20,
		caption = " Non-friend",
		checked = Configuration.battleFilterNonFriend or false,
		objectOverrideFont = myFont2,
		OnChange = {
			function (obj, newState)
				Configuration:SetConfigValue("battleFilterNonFriend", newState)
				self:SoftUpdate()
			end
		},
		parent = self.window,
		tooltip = "Hides all battles that don't have your friends in them",
	}
	local checkRunning = Checkbox:New {
		x = "50%",
		width = 21,
		bottom = 8,
		height = 30,
		boxalign = "left",
		boxsize = 20,
		caption = " Running",
		checked = Configuration.battleFilterRunning or false,
		objectOverrideFont = myFont2,
		OnChange = {
			function (obj, newState)
				Configuration:SetConfigValue("battleFilterRunning", newState)
				self:SoftUpdate()
			end
		},
		parent = self.window,
		tooltip = "Hides all battles that are in progress",
	}
	local checkVsAI = Checkbox:New {
		x = "65%",
		width = 21,
		bottom = 8,
		height = 30,
		boxalign = "left",
		boxsize = 20,
		caption = " Vs AI",
		checked = Configuration.battleFilterVsAI or false,
		objectOverrideFont = myFont2,
		OnChange = {
			function (obj, newState)
				Configuration:SetConfigValue("battleFilterVsAI", newState)
				self:SoftUpdate()
			end
		},
		parent = self.window,
		tooltip = "Hides all battles with AIs, including PvE",
	}
    local checkLocked = Checkbox:New {
		x = "77%",
		width = 21,
		bottom = 8,
		height = 30,
		boxalign = "left",
		boxsize = 20,
		caption = " Locked",
		checked = Configuration.battleFilterLocked or false,
		objectOverrideFont = myFont2,
		OnChange = {
			function (obj, newState)
				Configuration:SetConfigValue("battleFilterLocked", newState)
				self:SoftUpdate()
			end
		},
		parent = self.window,
		tooltip = "Hides all locked battles",
	}

	local function UpdateCheckboxes()
		checkPassworded:SetToggle(Configuration.battleFilterPassworded2)
		checkNonFriend:SetToggle(Configuration.battleFilterNonFriend)
		checkRunning:SetToggle(Configuration.battleFilterRunning)
        checkLocked:SetToggle(Configuration.battleFilterLocked)
		checkVsAI:SetToggle(Configuration.battleFilterVsAI)
	end
	WG.Delay(UpdateCheckboxes, 0.2)
	-- Delay required as Configuration:GetConfigData (where these values are set) runs after this is initialised.

	self:SetMinItemWidth(100000)
	self.columns = 3
	self.itemHeight = 40
	self.itemPadding = 1

	local function UpdateTimersDelay()
		self:UpdateTimers()
		WG.Delay(UpdateTimersDelay, 30)
	end
	WG.Delay(UpdateTimersDelay, 30)

	self.onBattleOpened = function(listener, battleID)
		self:AddBattle(battleID, lobby:GetBattle(battleID))
		self:SoftUpdate()
	end
	lobby:AddListener("OnBattleOpened", self.onBattleOpened)

	self.onBattleClosed = function(listener, battleID)
		self:RemoveRow(battleID)
		self:SoftUpdate()
	end
	lobby:AddListener("OnBattleClosed", self.onBattleClosed)

	self.onJoinedBattle = function(listener, battleID)
		self:JoinedBattle(battleID)
		self:SoftUpdate()
	end
	lobby:AddListener("OnJoinedBattle", self.onJoinedBattle)

	self.onLeftBattle = function(listener, battleID)
		self:LeftBattle(battleID)
		self:SoftUpdate()
	end
	lobby:AddListener("OnLeftBattle", self.onLeftBattle)

	self.onUpdateBattleInfo = function(listener, battleID)
		self:OnUpdateBattleInfo(battleID)
		self:UpdateButtonColor(battleID)
		self:SoftUpdate()
	end
	lobby:AddListener("OnUpdateBattleInfo", self.onUpdateBattleInfo)

	self.onBattleIngameUpdate = function(listener, battleID, isRunning)
		self:OnBattleIngameUpdate(battleID, isRunning)
		self:SoftUpdate()
	end
	lobby:AddListener("OnBattleIngameUpdate", self.onBattleIngameUpdate)

	self.onUpdateBattleTitle = function(listener, battleID, newbattletitle)
		self:OnUpdateBattleTitle(battleID, newbattletitle)
		self:SoftUpdate()
	end
	lobby:AddListener("OnUpdateBattleTitle", self.onUpdateBattleTitle)

	self.onFriendRequestList = function(listener)
		self:OnFriendRequestList()
		self:SoftUpdate()
	end
	lobby:AddListener("OnFriendRequestList", self.onFriendRequestList)

	local function onConfigurationChange(listener, key, value)
		if key == "displayBadEngines2" then
			self:Update()
		elseif key == "battleFilterRedundant" then
			self:SoftUpdate()
		end
	end
	Configuration:AddListener("OnConfigurationChange", onConfigurationChange)

	local function downloadFinished(listener, downloadID)
		for battleID,_ in pairs(self.itemNames) do
			self:UpdateSync(battleID)
		end
	end
	WG.DownloadHandler.AddListener("DownloadFinished", downloadFinished)

	self:Update()
end

function BattleListWindow:RemoveListeners()
	lobby:RemoveListener("OnBattleOpened", self.onBattleOpened)
	lobby:RemoveListener("OnBattleClosed", self.onBattleClosed)
	lobby:RemoveListener("OnJoinedBattle", self.onJoinedBattle)
	lobby:RemoveListener("OnLeftBattle", self.onLeftBattle)
	lobby:RemoveListener("OnUpdateBattleInfo", self.onUpdateBattleInfo)
	lobby:RemoveListener("OnBattleIngameUpdate", self.onBattleIngameUpdate)
	lobby:RemoveListener("OnConfigurationChange", self.onConfigurationChange)
	lobby:RemoveListener("DownloadFinished", self.downloadFinished)
end

function BattleListWindow:UpdateAllBattleIDs()
	self.allBattleIDs = {}
	for i = 1, self.scrollChildren do
		self.allBattleIDs[i] = self.orderPanelMapping[i].id
	end
end

function BattleListWindow:Update()
	self:Clear()

	local battles = lobby:GetBattles()
	local tmp = {}
	for _, battle in pairs(battles) do
		table.insert(tmp, battle)
	end
	battles = tmp

	for _, battle in pairs(battles) do
		self:AddBattle(battle.battleID, battle)
	end

	for _, battle in pairs(battles) do
		self:UpdateButtonColor(battle.battleID)
	end

	self:SoftUpdate()
end


function BattleListWindow:SoftUpdate()
	-- UpdateFilters is quite heavy, because it sorts all the battles on the
	-- list, so instead of just calling SoftUpdate functionality directly,
	-- we only update, if we havent updated in 3 seconds.
	-- Also note, that the previous implementation somehow ran on intermediate states, 
	-- causeing severe bouncing of battles up and down
	if self.lastSoftUpdate == nil then
		self.lastSoftUpdate = Spring.GetTimer()
	end

	self:UpdateInfoPanel()
	if Spring.DiffTimers(Spring.GetTimer(), self.lastSoftUpdate) > 3 then
		self.lastSoftUpdate = Spring.GetTimer()
		if Configuration.battleFilterRedundant then
			self:UpdateAllBattleIDs()
		end
		self:UpdateFilters()
	end

	-- this method, for some godforsaken reason doesnt work as expected. 
	-- It is kept here as a tomb for weary travellers to rest by.
	--[[
	self.lastSoftUpdate = os.clock()

	local battleList = self

	local function RealSoftUpdate()
		if os.clock() - battleList.lastSoftUpdate < 0.1 then
			WG.Delay(RealSoftUpdate, 0.2)
			return
		end

		if Configuration.battleFilterRedundant then
			battleList:UpdateAllBattleIDs()
		end
		battleList:UpdateFilters()
		battleList:UpdateInfoPanel()
		battleList.softUpdateTimerRunning = false
	end

	if not self.softUpdateTimerRunning then
		WG.Delay(RealSoftUpdate, 0.2)
		self.softUpdateTimerRunning = true
	end
	--]]
end

function BattleListWindow:UpdateInfoPanel()
	local battles = lobby:GetBattles()
	local noBattles = true
	for _, battle in pairs(battles) do
		noBattles = false
	end
	if noBattles then
		self.infoPanel:SetVisibility(true)
		self.infoPanel:BringToFront()
		if lobby.status == "connected" then 
			self.infoLabel:SetCaption("No battle rooms found, report this to us on Discord!\nIf the server was just restarted,\nthen wait a few minutes.")
		else
			self.infoLabel:SetCaption("You are not connected to the server.\nPlease wait 30 seconds while we automatically reconnect you.")
		end

		return
	end

	local firstPanel = self.orderPanelMapping[1]
	if firstPanel then
		if not firstPanel.inFilter then
			self.infoPanel:SetVisibility(true)
			self.infoPanel:BringToFront()
			self.infoLabel:SetCaption("No games matching filter criteria.")
			return
		end
	else
		-- Must have hidden games
		self.infoPanel:SetVisibility(true)
		self.infoPanel:BringToFront()
		self.infoLabel:SetCaption("No games matching default filters.\nYou need to update your game!")
		return
	end

	self.infoPanel:SetVisibility(false)
end

function BattleListWindow:MakeWatchBattle(battleID, battle)
	local function RejoinBattleFunc()
		if not VFS.HasArchive(battle.mapName) then
			WG.Chobby.InformationPopup("Map download required. Wait for the download to complete and try again.")
			WG.DownloadHandler.MaybeDownloadArchive(battle.mapName, "map", -1)
			return
		end

		if not VFS.HasArchive(battle.gameName) then
			WG.Chobby.InformationPopup("Game update required. Wait for the download to complete or restart the game.")
			WG.DownloadHandler.MaybeDownloadArchive(battle.gameName, "game", -1)
			return
		end

		lobby:RejoinBattle(battleID)
	end

	local height = self.itemHeight - 20
	local parentButton = Button:New {
		name = "battleButton",
		x = 0,
		right = 0,
		y = 0,
		height = self.itemHeight,
		caption = "",
		OnClick = {
			function()
				if Spring.GetGameName() == "" then
					RejoinBattleFunc()
				else
					WG.Chobby.ConfirmationPopup(RejoinBattleFunc, "Are you sure you want to leave your current game to watch/rejoin this one?", nil, 315, 200)
				end
			end
		},
		tooltip = "battle_tooltip_" .. battleID,
	}

	local lblTitle = Label:New {
		name = "lblTitle",
		x = height + 3,
		y = 0,
		right = 0,
		height = 20,
		valign = 'center',
		objectOverrideFont = myFont2,
		caption = (battle.title or "") .. " - Click to watch",
		parent = parentButton,
		OnResize = {
			function (obj, xSize, ySize)
				obj:SetCaption(StringUtilities.GetTruncatedStringWithDotDot(battle.title .. " - Click to watch", obj.font, xSize or obj.width))
			end
		}
	}
	local minimap = Panel:New {
		name = "minimap",
		x = 3,
		y = 3,
		width = height - 6,
		height = height - 6,
		padding = {1,1,1,1},
		parent = parentButton,
	}

	local mapImageFile, needDownload = Configuration:GetMinimapSmallImage(battle.mapName)
	local minimapImage = Image:New {
		name = "minimapImage",
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		keepAspect = true,
		file = mapImageFile,
		fallbackFile = Configuration:GetLoadingImage(2),
		checkFileExists = needDownload,
		parent = minimap,
	}
	local imgIsRunning = Image:New {
		name = "imgIsRunning",
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		keepAspect = false,
		file =  IMG_BATTLE_RUNNING,
		parent = minimap,
	}
	imgIsRunning:SetVisibility(battle.isRunning == true)

	local playerCount = lobby:GetBattlePlayerCount(battleID)
	local lblPlayersOnMap = Label:New {
		name = "playersOnMapCaption",
		x = height + 3,
		right = 0,
		y = 20,
		height = 15,
		valign = 'center',
		objectOverrideFont = myFont1,
		caption = playerCount .. ((playerCount == 1 and " player on " ) or " players on ") .. battle.mapName:gsub("_", " "),
		parent = parentButton,
	}

	local modeName = battle.battleMode and Configuration.battleTypeToHumanName[battle.battleMode]
	if battle.isRunning then
		if modeName then
			modeName = modeName .. " - "
		else
			modeName = ""
		end
		modeName = modeName .. "Running for " .. Spring.Utilities.GetTimeToPast(battle.runningSince)
	end

	local lblRunningTime = Label:New {
		name = "runningTimeCaption",
		x = height + 3,
		right = 0,
		y = 36,
		height = 15,
		valign = 'center',
		objectOverrideFont = myFont1,
		caption = modeName,
		parent = parentButton,
	}

	return parentButton
end

function BattleListWindow:MakeJoinBattle(battleID, battle)

	local height = self.itemHeight - 20
	local parentButton = Button:New {
		name = "battleButton",
		x = 0,
		right = 0,
		y = 0,
		height = self.itemHeight,
		noFont = true,
		caption = "",
		classname = "battle_default_button",
		OnClick = {
			function()
				local myBattleID = lobby:GetMyBattleID()
				if myBattleID then
					if battleID == myBattleID then
						-- Do not rejoin current battle
						local battleTab = WG.Chobby.interfaceRoot.GetBattleStatusWindowHandler()
						battleTab.OpenTabByName("myBattle")
						return
					end
					if not Configuration.confirmation_battleFromBattle then
						local myBattle = lobby:GetBattle(myBattleID)
						if not WG.Chobby.Configuration.showMatchMakerBattles and myBattle and not myBattle.isMatchMaker then
							local function Success()
								self:JoinBattle(battle)
							end
							ConfirmationPopup(Success, "Are you sure you want to leave your current battle and join a new one?", "confirmation_battleFromBattle")
							return
						end
					end
				end
				self:JoinBattle(battle)
			end
		},
		tooltip = "battle_tooltip_" .. battleID,
	}

	local imgIsRunning = Image:New {
		name = "imgIsRunning",
		x = 0,
		width = 20,
		height = 20,
		y = 0,
		margin = {0, 0, 0, 0},
		file = IMG_BATTLE_RUNNING,
		parent = parentButton,
	}
	imgIsRunning:SetVisibility(battle.isRunning == true)
	
	local lblTitle = Label:New {
		name = "lblTitle",
		x = "4%",
		y = 0,
		right = "55%",
		height = 20,
		align = "left",
		valign = 'center',
		objectOverrideFont = myFont2,
		--caption = battle.title .. " | " .. battle.mapName:gsub("_", " "),
		caption = battle.title,
		parent = parentButton,
		OnResize = {
			function (obj, xSize, ySize)
				--obj:SetCaption(StringUtilities.GetTruncatedStringWithDotDot(battle.title .. " | " .. battle.mapName:gsub("_", " "), obj.font, obj.width))
				obj:SetCaption(StringUtilities.GetTruncatedStringWithDotDot(battle.title, obj.font, obj.width))
			end
		}
	}
	local minimap = Panel:New {
		name = "minimap",
		x = "47%",
		y = 0,
		width = height,
		height = height,
		padding = {0,0,0,0},
		parent = parentButton,
	}

	local mapImageFile, needDownload = Configuration:GetMinimapSmallImage(battle.mapName)
	local minimapImage = Image:New {
		name = "minimapImage",
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		keepAspect = true,
		file = mapImageFile,
		fallbackFile = Configuration:GetLoadingImage(2),
		checkFileExists = needDownload,
		parent = minimap,
	}

	local lblMap = Label:New {
		name = "mapCaption",
		--x = height - 10000, -- Apparently deleting this breaks some things, so let's throw it 10000 pixels to the left, lmao.
		x = "51%",
		right = "14%",
		y = 0, --36
		height = 20,
		--align = "right",
		valign = 'center',
		caption = battle.mapName:gsub("_", " "),
		objectOverrideFont = myFont2,
		parent = parentButton,
		OnResize = {
			function (obj, xSize, ySize)
				obj:SetCaption(StringUtilities.GetTruncatedStringWithDotDot(battle.mapName:gsub("_", " "), obj.font, xSize or obj.width))
			end
		}
	}

	if battle.passworded then
		local imgPassworded = Image:New {
			name = "password",
			x = "86%",
			width = "4%",
			height = 18,
			y = 0,
			align = "right",
			valign = 'center',
			margin = {0, 0, 0, 0},
			file = IMG_KEY,
			parent = parentButton,
		}
	else
		local imgLocked = Image:New {
			name = "imgLocked",
			x = "86%",
			width = "4%",
			height = 20,
			y = 0,
			align = "right",
			valign = 'center',
			margin = {0, 0, 0, 0},
			file = IMG_LOCK,
			parent = parentButton,
		}
		imgLocked:SetVisibility(battle.locked == true)
	end

	local rankimg = Configuration.gameConfig.rankFunction(nil, 1, nil, nil,nil )
	--WG.UserHandler.GetUserRankImage()
	-- Configuration.gameConfig.rankFunction(nil, mybestrank, nil, nil,nil ),
	local imgAvgRank = Image:New {
		name = "imgAvgRank",
		x = "90%",
		width = "4%",
		height = 20,
		y = 0,
		align = "right",
		valign = 'center',
		margin = {0, 0, 0, 0},
		file = rankimg,
		parent = parentButton,
	}
	imgAvgRank:SetVisibility(false)

	local lblPlayers = Label:New {
		name = "playersCaption",
		x = 50,
		right = 0,
		width = 50,
		y = 0,
		height = 20,
		align = "right",
		valign = 'center',
		objectOverrideFont = myFont2,
		caption = lobby:GetPlayerOccupancy(battleID),
		parent = parentButton,
	}

	parentButton.previousMaxPlayers = lobby:GetBattleMaxPlayers(battleID)
	parentButton.previousPlayerCount = lobby:GetBattlePlayerCount(battleID)

	return parentButton
end

function BattleListWindow:AddBattle(battleID, battle)
	battle = battle or lobby:GetBattle(battleID)
	if not (Configuration.displayBadEngines2 or Configuration:IsValidEngineVersion(battle.engineVersion)) then
		return
	end

	if not battle then
		return
	end

	local button
	if battle.isMatchMaker then
		button = self:MakeWatchBattle(battleID, battle)
	else
		button = self:MakeJoinBattle(battleID, battle)
	end

	self:AddRow({button}, battle.battleID)
end

function BattleListWindow:ItemInFilter(id)
	local battle = lobby:GetBattle(id)
	local filterString = Configuration.gameConfig.battleListOnlyShow
	if filterString ~= nil and filterString ~= "" then
		local battleStrings = {battle.title, battle.mapName}
		for _, user in ipairs(battle.users) do
			table.insert(battleStrings, user)
		end

		local filterToGame = nil

		-- try to find the filterString in one battleString {battle.title, battle.mapName, battle.users}
		for _, battleString in ipairs(battleStrings) do
			filterToGame = string.find(string.lower(battleString), string.lower(filterString), nil, true)
			if filterToGame ~= nil then
				break;
			end
		end
		if filterToGame == nil then
			return false
		end
	end
	if not lobby:GetBattleHasFriend(id) then
		if Configuration.battleFilterPassworded2 and battle.passworded then
			return false
		end
		if Configuration.battleFilterNonFriend then
			return false
		end
	end

	if Configuration.battleFilterLocked and battle.locked  then
		return false
	end

	if Configuration.battleFilterRunning and battle.isRunning then
		return false
	end

	if Configuration.battleFilterVsAI and (string.find(battle.title, "vs AI") or string.find(battle.title, "vs Scavengers") or string.find(battle.title, "vs Raptors")) then
		return false
	end

	if Configuration.battleFilterRedundant then
		return self:FilterRedundantBattle(battle, id)
	end

	return true
end

function BattleListWindow:FilterRedundantBattle(battle, id)
	if battle.isRunning
	 or lobby:GetBattlePlayerCount(id) > 0
	 or (battle.spectatorCount and battle.spectatorCount > 1) then
		return true
	end

	if true then return true end
	-- for each non-empty battle, only display EU-AUS-USA- hosts first number that is empty
	-- This is no longer needed since spads instances only have 1 extra host
	--[[
	function parseBattleNumber(battleTitle)
		battleKeys = Configuration.battleFilterRedundantRegions or {}
		local hostCountry = nil
		for k, battleKey in pairs(battleKeys) do
			if string.find(battleTitle, battleKey) == 1 then
				hostCountry = battleKey
			end
		end
		if hostCountry == nil then
			return nil
		end

		local hostnumber = tonumber(string.sub(battleTitle, string.len(hostCountry), -1))
		if hostnumber == nil then
			return nil
		end

		return hostCountry, hostnumber
	end
	local myCountry, myNumber = parseBattleNumber(battle.title)
	if myCountry == nil then
		return true
	end

	local lowestEmptyBattleIndex = math.huge
	local lowestEmptyBattleID = nil
	for k, otherBattleID in pairs(self.allBattleIDs) do
		local otherBattle = lobby:GetBattle(otherBattleID)
		if otherBattle then
			local ob_hostCountry, ob_hostnumber = parseBattleNumber(otherBattle.title)
			local otherBattlePlayerCount = lobby:GetBattlePlayerCount(otherBattleID)

			if ob_hostCountry and
				ob_hostnumber < lowestEmptyBattleIndex and
				otherBattlePlayerCount == 0 and
				otherBattle.spectatorCount == 1 and
				myCountry == ob_hostCountry then

				lowestEmptyBattleID = otherBattleID
				lowestEmptyBattleIndex = ob_hostnumber
			end
		else
			Spring.Log("Chobby", LOG.WARNING, "lobby:GetBattle(otherBattleID) was nil while filtering redundant hosts", otherBattle, otherBattleID)
		end
	end

	return lowestEmptyBattleID == nil or lowestEmptyBattleID == id
	]] --
end

function BattleListWindow:CompareItems(id1, id2)
	-- Returns true if id1 should be before id2
	-- Sort:
	-- 0. Public, not running battles with > 0 players
	-- 1. public, running unlocked battles by player count
	-- 2. public locked battles by player count
	-- 3. private battles, alphabetically
	--

	-- sorted list of params to check by?
	local lobby = WG.LibLobby.lobby
	local battle1, battle2 = lobby:GetBattle(id1), lobby:GetBattle(id2)
	if id1 and id2 and battle1 and battle2 then -- validity check
		--Spring.Echo("id", id1, id2, "isrunning", battle1.isRunning, battle2.isRunning,
		--	"pw", battle1.passworded, battle2.passworded,
		--	'locked', battle1.locked, battle2.locked
		--)
		local battle1passworded = (battle1.passworded == true )
		local battle2passworded = (battle2.passworded == true )
		
		if battle1passworded ~= battle2passworded then
			return battle2passworded
		elseif battle1passworded  and battle2passworded then
			--Spring.Echo(id1, battle1.locked, battle1.title, id2, battle2.locked, battle2.title)
			--if battle1.locked ~= battle2.locked then
			--	return battle2.locked
			--else
				-- Sort passworded battles by title
				return string.lower(battle1.title) < string.lower(battle2.title )
			--end
		end
		-- neither are passworded

		-- Dump locked next
		local battle1locked = (battle1.locked == true)
		local battle2locked = (battle2.locked == true)
		if battle1locked ~= battle2locked then
			return battle2locked
		end

		-- Handle silly ass negative counts
		local countOne = math.max(0, lobby:GetBattlePlayerCount(id1))
		local countTwo = math.max(0, lobby:GetBattlePlayerCount(id2))
		--Spring.Echo(id1, countOne, id2, countTwo)
		--Put empty rooms at the back of the list
		-- unless they are running
		local battle1isRunning = (battle1.isRunning == true)
		local battle2isRunning = (battle2.isRunning == true)
		local empty1 = (battle1isRunning == false) and (countOne == 0)
		local empty2 = (battle2isRunning == false) and (countTwo == 0)

		if empty1 ~= empty2 then
			return (empty2 == true)
		end
		
		if countOne == 0 and countTwo > 0 then -- id1 is empty
			return false
		elseif countOne > 0 and countTwo == 0 then  -- id2 is empty
			return true
		end

		-- Put running after open
		if battle1isRunning ~= battle2isRunning then
			return battle2isRunning
		end

		-- Sort by player count
		if countOne ~= countTwo then
			return countOne > countTwo
		end

		return id1 > id2 -- stabilize the sort.
	else
		Spring.Echo("battle1", id1, battle1, battle1 and battle1.users)
		Spring.Echo("battle2", id2, battle2, battle2 and battle2.users)
		return false
	end
end

function BattleListWindow:UpdateButtonColor(battleID)

	local items = self:GetRowItems(battleID)
	if not items then
		return
	end
	local battle = lobby:GetBattle(battleID)
	if battle == nil then return end

	local oldbuttonstyle = items.battleButton.backgroundColor
	local battlebuttonstyle = {0.10, 0.10, 0.95, 0.65} --blue
	if battle.passworded then
		battlebuttonstyle =  {0.60, 0.10, 0.85, 0.65} --violet
	else
		if battle.locked then
			battlebuttonstyle =  {0.90, 0.10, 0.10, 0.65} --red
		else
			if (lobby:GetBattlePlayerCount(battleID) < 1) and (battle.isRunning == false) then
					battlebuttonstyle = {0.10, 0.10, 0.95, 0.65} --blue
			else
				if battle.isRunning then
					battlebuttonstyle =  {0.70, 0.60, 0.1, 0.65} --yellow
				else
					battlebuttonstyle =  {0.10, 0.50, 0.10, 0.65} --green
				end
			end
		end
	end
	local colorChanged = false
	for i, c in ipairs(oldbuttonstyle) do
		if c ~= battlebuttonstyle[i] then
			colorChanged = true
			break
		end
	end

	local imgLocked = items.battleButton:GetChildByName("imgLocked")
	if imgLocked then
		imgLocked:SetVisibility(battle.locked == true)
	end

	--Spring.Echo("BattleListWindow:UpdateButtonColor",battleID,battlebuttonstyle, items.battleButton.backgroundColor,battle.isRunning ,battle.passworded, lobby:GetBattlePlayerCount(battleID))

	if colorChanged then
		--Spring.Echo("BattleListWindow:UpdateButtonColor",battleID,battlebuttonstyle, items.battleButton.backgroundColor,battle.isRunning ,battle.passworded, lobby:GetBattlePlayerCount(battleID))
		items.battleButton.backgroundColor = battlebuttonstyle
		items.battleButton.focusColor = battlebuttonstyle
		items.battleButton:Invalidate()
	end
end

function BattleListWindow:UpdateRankIcon(battleID, battle, items)
	battle = battle or lobby:GetBattle(battleID)
	if battle == nil then return end
	local users = battle.users
	local avgRank = 0
	local numplayers = 0

	local items = items or self:GetRowItems(battleID)
	if not items then return end
	local imgAvgRank = items.battleButton:GetChildByName("imgAvgRank")

	if users then
		for i, userName in ipairs(users) do
			--local userInfo = lobby:TryGetUser(userName)
			local userInfo = lobby:GetUser(userName)
			if userInfo and userInfo.level and userInfo.isBot ~= true then
				avgRank = avgRank + userInfo.level
				numplayers = numplayers + 1
				--Spring.Echo("RANKY", battleID, userName, userInfo.level)
			end
			--Spring.Echo("RANKY", battleID, userName, userInfo and userInfo.level)
			--Spring.Utilities.TableEcho(userInfo)
		end
	end
	--Spring.Echo("UpdateRankIcon", battleID, numplayers, avgRank)

	if numplayers > 0 then
		avgRank = math.round(avgRank/numplayers)--
	end
	imgAvgRank:SetVisibility(numplayers>0)
	local rankimg = Configuration.gameConfig.rankFunction(nil, avgRank , nil, nil,nil )
	imgAvgRank.file = rankimg
	imgAvgRank:Invalidate()
end


function BattleListWindow:RecalculateOrder(id)
	if lobby.commandBuffer then
		return
	end
	self:super("RecalculateOrder", id)
end

function BattleListWindow:UpdateSync(battleID)
	local battle = lobby:GetBattle(battleID)
	if battle == nil then
		--Spring.Utilities.TraceFullEcho(30,nil,nil, "lobby:GetBattle(battleID) == nil", battleID)
		return
	end
	if not (Configuration.displayBadEngines2 or Configuration:IsValidEngineVersion(battle.engineVersion)) then
		return
	end

	local items = self:GetRowItems(battleID)
	if not items then
		self:AddBattle(battleID)
		return
	end

	-- local imHaveMap = items.battleButton:GetChildByName("imHaveMap")
	-- if imHaveMap ~= nil then
	-- 	imHaveMap.file = (VFS.HasArchive(battle.mapName) and IMAGE_DLREADY or IMAGE_DLUNREADY)
	-- end

	-- local imHaveGame = items.battleButton:GetChildByName("imHaveGame")
	-- if imHaveGame ~= nil then
	-- 	imHaveGame.file = (VFS.HasArchive(battle.gameName) and IMAGE_DLREADY or IMAGE_DLUNREADY)
	-- end
end

function BattleListWindow:UpdateTimers()
	for battleID,_ in pairs(self.itemNames) do
		local items = self:GetRowItems(battleID)
		if not items then
			break
		end

		local battle = lobby:GetBattle(battleID)
		local runningTimeCaption = items.battleButton:GetChildByName("runningTimeCaption")
		if battle and runningTimeCaption then
			local modeName = battle.battleMode and Configuration.battleTypeToHumanName[battle.battleMode]
			if modeName then
				modeName = modeName .. " - "
			else
				modeName = ""
			end
			runningTimeCaption:SetCaption(modeName .. "Running for " .. Spring.Utilities.GetTimeToPast(battle.runningSince))
		end
	end
end

function BattleListWindow:_MakeGameCaption(battle)
	local gameCaption = battle.battleMode and Configuration.battleTypeToHumanName[battle.battleMode]
	if gameCaption == nil then
		gameCaption = battle.gameName -- :sub(1, 22)
	end
	if battle.isRunning then
		gameCaption = gameCaption .. " - Running for " .. Spring.Utilities.GetTimeToPast(battle.runningSince)
	end
	gameCaption = string.gsub(gameCaption,"Beyond All Reason test%-","")
	gameCaption = string.sub(gameCaption,1,string.find(gameCaption,'%-')-1)
	return 'BAR-'..gameCaption
end

function BattleListWindow:UpdateBattleRank(battleID)
	local avgRank = items.battleButton:GetChildByName("avgRankImg")
end

function BattleListWindow:JoinedBattle(battleID)
	local battle = lobby:GetBattle(battleID)
	if not (Configuration.displayBadEngines2 or Configuration:IsValidEngineVersion(battle.engineVersion)) then
		return
	end

	local items = self:GetRowItems(battleID)
	if not items then
		self:AddBattle(battleID)
		return
	end
	local battleButton = items.battleButton

	local playersCaption = battleButton:GetChildByName("playersCaption")
	if playersCaption then
		local newPlayerCount = lobby:GetBattlePlayerCount(battleID)
		if battleButton.previousPlayerCount ~= newPlayerCount then 
			playersCaption:SetCaption(lobby:GetPlayerOccupancy(battleID))
			battleButton.previousPlayerCount = newPlayerCount
		end
	else
		local playersOnMapCaption = battleButton:GetChildByName("playersOnMapCaption")
		local playerCount = lobby:GetBattlePlayerCount(battleID)
		playersOnMapCaption:SetCaption(playerCount .. ((playerCount == 1 and " player on " ) or " players on ") .. battle.mapName:gsub("_", " "))
	end

	self:UpdateRankIcon(battleID, battle, items)
	self:UpdateButtonColor(battleID)
	self:RecalculateOrder(battleID)
end

function BattleListWindow:LeftBattle(battleID)
	local battle = lobby:GetBattle(battleID)
	if not (Configuration.displayBadEngines2 or Configuration:IsValidEngineVersion(battle.engineVersion)) then
		return
	end

	local items = self:GetRowItems(battleID)
	if not items then
		self:AddBattle(battleID)
		return
	end
	local battleButton = items.battleButton

	local playersCaption = battleButton:GetChildByName("playersCaption")
	if playersCaption then
		local newPlayerCount = lobby:GetBattlePlayerCount(battleID)
		if battleButton.previousPlayerCount ~= newPlayerCount then 
			playersCaption:SetCaption(lobby:GetPlayerOccupancy(battleID))
			battleButton.previousPlayerCount = newPlayerCount
		end
	else
		local playersOnMapCaption = battleButton:GetChildByName("playersOnMapCaption")
		local playerCount = lobby:GetBattlePlayerCount(battleID)
		playersOnMapCaption:SetCaption(playerCount .. ((playerCount == 1 and " player on " ) or " players on ") .. battle.mapName:gsub("_", " "))
	end

	self:UpdateRankIcon(battleID, battle, items)
	self:UpdateButtonColor(battleID)
	self:RecalculateOrder(battleID)
end

function BattleListWindow:OnUpdateBattleInfo(battleID)
	-- Note that the parameters of UPDATEBATTLEINFO are :
	-- UPDATEBATTLEINFO spectatorCount locked mapHash {mapName}
	local battle = lobby:GetBattle(battleID)
	if not (Configuration.displayBadEngines2 or Configuration:IsValidEngineVersion(battle.engineVersion)) then
		return
	end

	local items = self:GetRowItems(battleID)
	if not items then
		self:AddBattle(battleID)
		return
	end
	local battleButton = items.battleButton
	local lblTitle = battleButton:GetChildByName("lblTitle")
	--local imHaveMap = battleButton:GetChildByName("imHaveMap")
	local password = battleButton:GetChildByName("password")

	if imHaveMap or true then
		-- Password Update
		if password and not battle.passworded then
			password:Dispose()
		elseif battle.passworded and not password then
			local imgPassworded = Image:New {
				name = "password",
				x = battleButton.height + 28,
				y = 22,
				height = 30,
				width = 30,
				margin = {0, 0, 0, 0},
				file = CHOBBY_IMG_DIR .. "lock.png",
				parent = battleButton,
			}
		end

		-- Resets title and truncates.
		lblTitle.OnResize[1](lblTitle)

		-- Update minimap button if changed
		if battleButton.previousMapName ~= battle.mapName then 
			local minimapImage = battleButton:GetChildByName("minimap"):GetChildByName("minimapImage")
			local mapCaption = battleButton:GetChildByName("mapCaption")
			minimapImage.file, minimapImage.checkFileExists = Configuration:GetMinimapSmallImage(battle.mapName)
			minimapImage:Invalidate()
			mapCaption:SetCaption(battle.mapName:gsub("_", " "))
			battleButton.previousMapName = battle.mapName
		end

		-- if VFS.HasArchive(battle.mapName) then
		-- 	imHaveMap.file = IMAGE_DLREADY
		-- else
		-- 	imHaveMap.file = IMAGE_DLUNREADY
		-- end
		-- imHaveMap:Invalidate()


		-- local imHaveGame = items.battleButton:GetChildByName("imHaveGame")
		-- if imHaveGame ~= nil then
		-- 	imHaveGame.file = (VFS.HasArchive(battle.gameName) and IMAGE_DLREADY or IMAGE_DLUNREADY)
		-- end

		-- local gameCaption = items.battleButton:GetChildByName("gameCaption")
		-- gameCaption:SetCaption(self:_MakeGameCaption(battle))
		local newPlayerCount = lobby:GetBattlePlayerCount(battleID)
		local newMaxPlayers = lobby:GetBattleMaxPlayers(battleID)
		if battleButton.previousPlayerCount ~= newPlayerCount or battleButton.previousMaxPlayers ~= newMaxPlayers then 
			local playersCaption = battleButton:GetChildByName("playersCaption")
			playersCaption:SetCaption(lobby:GetPlayerOccupancy(battleID))
			battleButton.previousPlayerCount = newPlayerCount
			battleButton.previousMaxPlayers = newMaxPlayers
		end

	else
		-- Resets title and truncates.
		local lblTitle = items.battleButton:GetChildByName("lblTitle")
		lblTitle.OnResize[1](lblTitle)

		local minimapImage = items.battleButton:GetChildByName("minimap"):GetChildByName("minimapImage")
		minimapImage.file, minimapImage.checkFileExists = Configuration:GetMinimapSmallImage(battle.mapName)
		minimapImage:Invalidate()

		local playersOnMapCaption = items.battleButton:GetChildByName("playersOnMapCaption")
		local playerCount = lobby:GetBattlePlayerCount(battleID)
		playersOnMapCaption:SetCaption(playerCount .. ((playerCount == 1 and " player on " ) or " players on ") .. battle.mapName:gsub("_", " "))
	end

	self:UpdateButtonColor(battleID)
	self:RecalculateOrder(battleID)
end

function BattleListWindow:OnBattleIngameUpdate(battleID, isRunning)
	local battle = lobby:GetBattle(battleID)
	if not (Configuration.displayBadEngines2 or Configuration:IsValidEngineVersion(battle.engineVersion)) then
		return
	end

	local items = self:GetRowItems(battleID)
	if not items then
		self:AddBattle(battleID)
		return
	end

	local imgIsRunning = items.battleButton:GetChildByName("imgIsRunning")
	imgIsRunning:SetVisibility(battle.isRunning == true)

	self:UpdateButtonColor(battleID)
	self:RecalculateOrder(battleID)
end

function BattleListWindow:OnFriendRequestList()
	--Spring.Echo("BattleListWindow:OnFriendRequestList")
	collectgarbage("collect")
	collectgarbage("collect")
	if self.itemNames then
		for battleID, item in pairs(self.itemNames) do
			self:UpdateRankIcon(battleID, nil, item)
		end
	end
end

function BattleListWindow:OnUpdateBattleTitle(battleID, battleTitle)
	local battle = lobby:GetBattle(battleID)
	if not (Configuration.displayBadEngines2 or Configuration:IsValidEngineVersion(battle.engineVersion)) then
		return
	end
	local items = self:GetRowItems(battleID)
	if not items then
		self:AddBattle(battleID)
		return
	end

	local battletitlelable = items.battleButton:GetChildByName("lblTitle")
	battletitlelable:SetCaption(StringUtilities.GetTruncatedStringWithDotDot(battleTitle, battletitlelable.font, math.max(battletitlelable.width, 250) ))
	battletitlelable:Invalidate()
	items.battleButton:Invalidate()

	self:UpdateButtonColor(battleID)
	self:RecalculateOrder(battleID)
end



function BattleListWindow:OpenHostWindow()
	-- Enumerate all known clusters and their number of children
	local regions = {'EU','US','AU','EA'}
	local clusters = {
		['Host[AU1]'] = {limit = 150,  current = 0, online = false, priority = 1.0, region = 'AU', location = "Sydney"},   -- HostHatch is a good provider
		['Host[AU2]'] = {limit = 40,  current = 0, online = false, priority = 1.0, region = 'AU', location = "Sydney"},    -- higher priority OVH host

		['Host[EU1]'] = {limit = 150, current = 0, online = false, priority = 1.0, region = 'EU', location = "Vienna"}, 
		['Host[EU2]'] = {limit = 120, current = 0, online = false, priority = 1.0, region = 'EU', location = "Vienna"},
		['Host[EU3]'] = {limit = 25,  current = 0, online = false, priority = 0.5, region = 'EU', location = "Frankfurt"}, -- Lower prio because it runs files
		['Host[EU4]'] = {limit = 150, current = 0, online = false, priority = 1.0, region = 'EU', location = "Dusseldorf"},-- this is pointed to integration server
		['Host[EU5]'] = {limit = 150, current = 0, online = false, priority = 0.1, region = 'EU', location = "Frankfurt"}, -- Further deproiritize because ssdnodes is trash
		['Host[EU6]'] = {limit = 120, current = 0, online = false, priority = 1.0, region = 'EU', location = "Amsterdam"},
		['Host[EU7]'] = {limit = 250, current = 0, online = false, priority = 1.0, region = 'EU', location = "Amsterdam"}, -- This runs on integration server, but has plenty of capacity
		['Host[EU8]'] = {limit = 150, current = 0, online = false, priority = 1.0, region = 'EU', location = "Zurich"},    -- TEMPORARILY BUMP CAPACITY FOR SWAP LOAD TEST
		
		['Host[US1]'] = {limit = 120, current = 0, online = false, priority = 1.0, region = 'US', location = "Virginia"},
		['Host[US2]'] = {limit = 50,  current = 0, online = false, priority = 1.0, region = 'US', location = "Chicago"},
		['Host[US3]'] = {limit = 80,  current = 0, online = false, priority = 1.0, region = 'US', location = "St. Louis"},
		['Host[US4]'] = {limit = 150, current = 0, online = false, priority = 0.3, region = 'US', location = "Seattle"}, -- Seems to see more cpu steal than the rest
		['Host[US5]'] = {limit = 150, current = 0, online = false, priority = 1.0, region = 'US', location = "Chicago"}, 

		['Host[EA1]'] = {limit = 120, current = 0, online = false, priority = 1.0, region = 'EA', location = "HK"}, 
	}

	-- Try to check for their engine version too. It is unlikely that a cluster has multiple engines (except during a switch, so scratch that)
	local numusers = 0
	local users = lobby:GetUsers()

	local hostPrefix = "Host["
	local sortedusers = {}
	for username, _ in pairs(users) do sortedusers[#sortedusers+1] = username end
	table.sort(sortedusers)

	for _, userName in ipairs(sortedusers) do
		if lobby.users[userName].isBot and string.sub(userName, 1, string.len(hostPrefix)) == hostPrefix then
			-- Parse the region, cluster number, instance number
			local clustermanager = string.match(userName, '^(Host%[%a+%d+%])$')
			if clustermanager then  -- this is a manager
				if clusters[clustermanager] then 
					clusters[clustermanager].online = true
				else
					-- This seems to be a novel cluster, we could initialize it with some sane defaults:
					clusters[clustermanager] = {limit = 80,  current = 0, online = true, priority = 1.0, region = 'EU'}
				end
			else
				local clustermanager, instancenumber = string.match(userName, '^(Host%[%a+%d+%])%[(%d+)%]$')
				if clustermanager and clusters[clustermanager] then
					clusters[clustermanager].online = true
					clusters[clustermanager].current = clusters[clustermanager].current + 1
				end
			end
		end
	end

	-- return a cluster manager name and error code
	local function TryGetRegion(targetregion)
		local emptiness = {} -- key is manager name, value is fullness
		local sum = 0
		for manager, data in pairs(clusters) do
			if data.region == targetregion and data.online then
				-- The relative probability of a cluster being picked is a product of
				-- 1. The current fullness of the cluster
				-- 2. The actual capacity of the cluster itself.
				-- Any one of these measures by themselves are insufficient, because of repeated sampling. 
				-- if its only actual capacity, then smaller clusters wont ever get loaded

				local probability =  (1.0 - data.current/data.limit) * (data.limit - data.current)
				probability = math.max(probability * (data.priority or 1.0), 0)
				sum = sum + probability
				emptiness[manager] = probability
				Spring.Echo("Manager", manager, data.current,  data.limit, emptiness[manager], sum)
			end
		end

		-- choose
		local randomval = math.random() * sum
		local total = 0
		for manager, probability in pairs(emptiness) do -- This doesnt seem as truly random as it looks :/
			total = total + probability
			if randomval <= total then
				Spring.Echo("Found a manager for this request", manager, total, probability, randomval)
				return manager, nil
			end
		end
		if next(emptiness) == nil then
			Spring.Echo( "No cluster managers for", targetregion)
			return 'Host[EU1]' , "No cluster managers"
		else
			Spring.Echo("Couldnt find host in ", targetregion)
			for manager, probability in pairs(emptiness) do
				return manager, "no free hosts"
			end
		end
	end

	local hostBattleWindow = Window:New {
		caption = "",
		name = "hostBattle",
		parent = WG.Chobby.lobbyInterfaceHolder,
		width = 500,
		height = 400,
		resizable = false,
		draggable = false,
		classname = "main_window",
	}

	local title = Label:New {
		x = "10%",
		width = "80%",
		y = 15,
		height = 35,
		align = "center",
		caption = i18n("open_mp_game"),
		objectOverrideFont = myFont3,
		parent = hostBattleWindow,
	}

	local hostinfo = TextBox:New {
		x = '5%',
		width = '90%',
		y = 50,
		align = "left",
		--multiline = true,
		valign = "top",
		height = 150,
		--text = "You can host a game by requesting an empty battle room. You can lock the battle rooms (!lock) to prevent anyone from joining, otherwise anyone can join your game.",--i18n("game_name") .. ":",
		text = "Choose whether you want a public or a private custom battle where you are the boss and only you may change game settings. Only the boss leaving the room can unboss them. Anyone may join public battles, but private battles are password protected.",
		--i18n("game_name") .. ":",
		objectOverrideFont = myFont2,
		objectOverrideHintFont = myFont2,
		parent = hostBattleWindow,
	}

	local typeLabel = Label:New {
		x = 0,
		right = "49%",
		y = 175,
		align = "right",
		height = 35,
		caption = "Geographical region",-- i18n("game_type") .. ":",
		objectOverrideFont = myFont2,
		parent = hostBattleWindow,
	}

	local typeCombo = ComboBox:New {
		x = "51%",
		width = 150,
		y = 170,
		height = 35,
		itemHeight = 22,
		text = "",
		items = {'Europe', 'North America', 'Australia', 'East Asia'}, -- {'EU','US','AU','EA'}
		objectOverrideFont = myFont2,
		selected = 1,
		tooltip = "You may choose any region you wish, BAR is not sensitive to latency.",
		parent = hostBattleWindow,
	}

	local friendCheckbox = Checkbox:New {
		x = 15,
		width = 300,
		y = 225,
		height = 35,
		boxalign = "left",
		boxsize = 20,
		caption = "Friends only",
		checked =  false,
		objectOverrideFont = myFont2,
		OnChange = {
			function (obj, newState)
				allowFriendsToJoin =  newState
			
			end
		},
		parent = hostBattleWindow,
		tooltip = "Only friends can join your battle, but they can do so without the password.",
	}
	friendCheckbox:Hide()

	local userWantsPrivateBattle = false
	--if lobby:GetMyIsAdmin() then -- TODO: remove this when feature goes live
		local privateCheckbox = Checkbox:New {
			x = 15,
			width = 300,
			y = 200,
			height = 35,
			boxalign = "left",
			boxsize = 20,
			caption = "Passworded private battle",
			checked =  false,
			objectOverrideFont = myFont2,
			OnChange = {
				function (obj, newState)
					userWantsPrivateBattle =  newState
					if newState then
						friendCheckbox:Show()
					else
						friendCheckbox:Hide()
					end
				end
			},
			parent = hostBattleWindow,
			tooltip = "If you want a passworded battleroom, please be patient while we spin up a room for you. You will be PM-ed a 4 character password you can share with your friends.",
		}

	--end

	local errorLabel = Label:New {
		x = 15,
		width = 200,
		y = 245,
		align = "left",
		height = 35,
		caption = "",-- i18n("game_type") .. ":",
		objectOverrideFont = myFont2,
		parent = hostBattleWindow,
	}

	local function CancelFunc()
		hostBattleWindow:Dispose()
	end

	local function HostBattle()
		
		--Attempting to host game at
		--local requestedregion = typeCombo.items[typeCombo.selected] ---self.hostRegions = {"DE","EU","EU2","US","AU"}
		local regionStrings = {'Europe', 'North America', 'Australia', 'East Asia'} -- {'EU','US','AU','EA'}
		local regions = {'EU','US','AU','EA'}
		local requestedregion = regions[typeCombo.selected]
		Spring.Echo("Looking for empty host in region", requestedregion)
		local targetCluster, errmsg = TryGetRegion(requestedregion)

		if userWantsPrivateBattle then
			local mypassword = ""
			local function listenForPrivateBattle(listener, userName, message, msgDate)
				--Spring.Echo("listenForPrivateBattle",listener, userName, message, msgDate)
				if userName == targetCluster and string.find(message,"Starting a new private instance in", nil, true) then
					local pwindex = string.find(message,"password=", nil, true)
					mypassword = string.sub(message, pwindex + 9, pwindex + 9 + 3)
					Spring.Echo("Got the password:", mypassword)
				end
			end
			

			lobby:AddListener("OnSaidPrivate", listenForPrivateBattle)
			lobby:SayPrivate(targetCluster, "!privatehost")
			errorLabel:SetCaption("Please wait while we spin up a \nbattle room for you.")

			local trytime = 30

			local function delayedWatchRooms()
				if trytime < 1 then
					lobby:RemoveListener("OnSaidPrivate", listenForPrivateBattle)
					errorLabel:SetCaption("Unable to spin up a private battle right now. Try a different region.")
					return
				end
				local myplayername = lobby:GetMyUserName() or ''
				--lobby:SayBattle("!boss " .. myplayername)
				local myprivatebattleID = nil
				local battles = lobby:GetBattles()
				local tmp = {}
				for _, battle in pairs(battles) do
					table.insert(tmp, battle)
				end
				battles = tmp
				for _, battle in pairs(battles) do
					if string.sub(battle.title,1,string.len(myplayername)) == myplayername and
						Configuration:IsValidEngineVersion(battle.engineVersion) then
							myprivatebattleID = battle.battleID
						break
					end
				end
				if myprivatebattleID ~= nil then
					trytime = -1

					WG.BattleRoomWindow.LeaveBattle()
					-- Configuration:SetConfigValue("lastGameSpectatorState", false) -- assume that private hoster wants to play, needed so he can boss self!
					lobby:JoinBattle(myprivatebattleID, mypassword, _, true) -- forcePlayer = true
					lobby:RemoveListener("OnSaidPrivate", listenForPrivateBattle)

					local function listenForBoss(listener, userName, message, msgDate)
						if string.find(userName, targetCluster, nil, true) and string.find(message, "* Boss mode enabled for", nil, true) then
							Spring.Echo(userName)
							lobby:SayBattle("$gatekeeper friends")
							lobby:RemoveListener("OnSaidBattleEx", listenForBoss)
						end
					end

					local function bossSelf()
						local myplayername = lobby:GetMyUserName() or ''
						if allowFriendsToJoin then
							-- sets the gatekeeper after being set to boss
							lobby:AddListener("OnSaidBattleEx", listenForBoss)
						end
						lobby:SayBattle("Password is: " .. mypassword)
						lobby:SayBattle("!boss " .. myplayername)
					end

					WG.Delay(bossSelf, 1)
					hostBattleWindow:Dispose()
				end
				trytime = trytime -1
			end

			for i=1, trytime do -- poll every sec for success
				WG.Delay(delayedWatchRooms, i)
			end

			return
		else
			targetCluster = targetCluster .. '['

			local targetbattle = nil
			-- try to get empty matching one
			local battles = lobby:GetBattles()
			local tmp = {}
			for _, battle in pairs(battles) do
				table.insert(tmp, battle)
			end
			battles = tmp
			--if requestedregion == 'DE' then requestedregion = "EU - 2" end -- nasty
			-- targetCluster
			for _, battle in pairs(battles) do
				if string.find(battle.founder, targetCluster, nil, true) and
					battle.spectatorCount == 1 and
					battle.isRunning ~= true and -- this is needed after server restarts
					battle.passworded ~= true and
					battle.locked ~= true and
					lobby:GetBattlePlayerCount(battle.battleID) == 0 and
					Configuration:IsValidEngineVersion(battle.engineVersion) then
						-- TODO: THIS MIGHT STILL JOIN "MANAGED" BATTLES WITH MANAGER BOTS
						targetbattle = battle.battleID
					break
				else
					--Spring.Echo('tryhostbattle',battle, battle.battleID, battle.title, battle.founder, targetCluster, lobby:GetBattlePlayerCount(battle.battleID),Configuration:IsValidEngineVersion(battle.engineVersion) )
				end
			end

			if targetbattle == nil then
				--Spring.Echo("Failed to find a battle")
				errorLabel:SetCaption("Could not find a suitable battle room in your selected region!\nPlease try another.")
			else
				errorLabel:SetCaption("")
				if WG.Analytics then
					WG.Analytics.SendRepeatEvent("lobby:multiplayer:hostgame", {
						hostregion = requestedregion
					})
				end
				-- Configuration:SetConfigValue("lastGameSpectatorState", false) -- assume that private hoster wants to play, needed so he can boss self!

				--Spring.Echo("Found a battle")
				local function bossSelf()
					local myplayername = lobby:GetMyUserName() or ''
					lobby:SayBattle("!boss " .. myplayername)
					lobby:SayBattle("!preset custom")
				end

				self:JoinBattle(lobby:GetBattle(targetbattle), _, _, true)
				WG.Delay(bossSelf, 1)
				hostBattleWindow:Dispose()
			end
		end
	end

	local function reEnableBtnHost()
		buttonHost.tooltip = "Request a hosted battle. Please be patient while the lobby spins up."
		buttonHost.suppressButtonReaction = false
		buttonHost:SetEnabled(true)
		buttonHost.OnClick = {
			function()
				buttonHostOnClick()
			end
		}
	end

	function buttonHostOnClick()
		buttonHost.tooltip = "Please wait for more time before requesting another hosted battle"
		buttonHost.suppressButtonReaction = true
		buttonHost:SetEnabled(false)
		buttonHost.OnClick = {}
		HostBattle()
		WG.Delay(reEnableBtnHost, 15)
	end

	buttonHost = Button:New {
		right = 150,
		width = 135,
		bottom = 1,
		height = 70,
		caption = i18n("host"),
		objectOverrideFont = myFont3,
		parent = hostBattleWindow,
		classname = "action_button",
		tooltip = "Request a hosted battle. Please be patient while the lobby spins up.",
		OnClick = {
			function()
				buttonHostOnClick()
			end
		},
	}

	local buttonCancel = Button:New {
		right = 1,
		width = 135,
		bottom = 1,
		height = 70,
		caption = i18n("cancel"),
		objectOverrideFont = myFont3,
		parent = hostBattleWindow,
		classname = "negative_button",
		OnClick = {
			function()
				CancelFunc()
			end
		},
	}

	local popupHolder = PriorityPopup(hostBattleWindow, CancelFunc, HostBattle)
end

function BattleListWindow:JoinBattle(battle, _, _, joinAsPlayer)
	-- We can be force joined to an invalid engine version. This widget is not
	-- the place to deal with this case.
	if not battle.passworded then
		WG.BattleRoomWindow.LeaveBattle()

		local removeListeners

		local function onJoinBattle(listener)
			removeListeners()
		end

		local function onJoinBattleFailed(listener, reason)
			WG.Chobby.InformationPopup("Unable to join battle: " .. (reason or ""))
			removeListeners()
		end

		removeListeners = function ()
			lobby:RemoveListener("OnJoinBattleFailed", onJoinBattleFailed)
			lobby:RemoveListener("OnJoinBattle", onJoinBattle)
		end

		lobby:AddListener("OnJoinBattleFailed", onJoinBattleFailed)
		lobby:AddListener("OnJoinBattle", onJoinBattle)

		lobby:JoinBattle(battle.battleID, _, _, joinAsPlayer)
	else
		local tryJoin, passwordWindow

		local lblError = Label:New {
			x = 30,
			width = 100,
			y = 110,
			height = 80,
			caption = "",
			objectOverrideFont = WG.Chobby.Configuration:GetFont(2, "error_red", {color = { 1, 0, 0, 1 }}),
			parent = passwordWindow,
		}

		local function onJoinBattleFailed(listener, reason)
			lblError:SetCaption(reason)
		end

		local function onJoinBattle(listener)
			passwordWindow:Dispose()
		end

		passwordWindow = Window:New {
			x = 700,
			y = 300,
			width = 316,
			height = 240,
			caption = "",
			objectOverrideFont = WG.Chobby.Configuration:GetFont(10),
			resizable = false,
			draggable = false,
			parent = WG.Chobby.lobbyInterfaceHolder,
			classname = "main_window",
			OnDispose = {
				function()
					lobby:RemoveListener("OnJoinBattleFailed", onJoinBattleFailed)
					lobby:RemoveListener("OnJoinBattle", onJoinBattle)
				end
			},
		}


		local lblPassword = Label:New {
			x = 25,
			right = 15,
			y = 15,
			height = 35,
			objectOverrideFont = myFont3,
			caption = i18n("enter_battle_password"),
			parent = passwordWindow,
		}

		local ebPassword = EditBox:New {
			x = 30,
			right = 30,
			y = 60,
			height = 35,
			text = "",
			hint = i18n("password"),
			objectOverrideFont = myFont3,
			objectOverrideHintFont = myHintFont,
			passwordInput = true,
			parent = passwordWindow,
		}

		function tryJoin()
			lblError:SetCaption("")
			WG.BattleRoomWindow.LeaveBattle()
			lobby:JoinBattle(battle.battleID, ebPassword.text)
		end

		local function CancelFunc()
			passwordWindow:Dispose()
		end

		local btnJoin = Button:New {
			x = 5,
			width = 135,
			bottom = 1,
			height = 70,
			caption = i18n("join"),
			objectOverrideFont = myFont3,
			classname = "action_button",
			OnClick = {
				function()
					tryJoin()
				end
			},
			parent = passwordWindow,
		}
		local btnClose = Button:New {
			right = 5,
			width = 135,
			bottom = 1,
			height = 70,
			caption = i18n("cancel"),
			objectOverrideFont = myFont3,
			classname = "negative_button",
			OnClick = {
				function()
					CancelFunc()
				end
			},
			parent = passwordWindow,
		}

		lobby:AddListener("OnJoinBattleFailed", onJoinBattleFailed)
		lobby:AddListener("OnJoinBattle", onJoinBattle)
			
		-- try to join first without a password, succeeds when lobby is open to friends
		tryJoin()
		local popupHolder = PriorityPopup(passwordWindow, CancelFunc, tryJoin)
		screen0:FocusControl(ebPassword)
	end
end
