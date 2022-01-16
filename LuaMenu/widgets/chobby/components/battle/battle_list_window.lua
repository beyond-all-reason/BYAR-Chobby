BattleListWindow = ListWindow:extends{}

local BATTLE_RUNNING = LUA_DIRNAME .. "images/runningBattle.png"
local BATTLE_NOT_RUNNING = LUA_DIRNAME .. "images/nothing.png"

local IMG_READY    = LUA_DIRNAME .. "images/ready.png"
local IMG_UNREADY  = LUA_DIRNAME .. "images/unready.png"

function BattleListWindow:init(parent)
	self:super("init", parent, "Play or watch a game", true, nil, nil, nil, 34)

	if not Configuration.gameConfig.disableBattleListHostButton then
		self.btnNewBattle = Button:New {
			x = 260,
			y = 7,
			width = 150,
			height = 45,
			caption = i18n("open_mp_game"),
			font = Configuration:GetFont(3),
			classname = "option_button",
			parent = self.window,
			OnClick = {
				function ()
					self:OpenHostWindow()
				end
			},
		}
	end

	local function update()
		self:Update()
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
		font = Configuration:GetFont(3),
	}
	self.infoPanel:SetVisibility(false)

	Label:New {
		x = 20,
		right = 5,
		bottom = 11,
		height = 20,
		font = Configuration:GetFont(2),
		caption = "Filter out:",
		parent = self.window
	}

	local checkPassworded = Checkbox:New {
		x = 110,
		width = 21,
		bottom = 4,
		height = 30,
		boxalign = "left",
		boxsize = 20,
		caption = " Passworded",
		checked = Configuration.battleFilterPassworded2 or false,
		font = Configuration:GetFont(2),
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
		x = 280,
		width = 21,
		bottom = 4,
		height = 30,
		boxalign = "left",
		boxsize = 20,
		caption = " Non-friend",
		checked = Configuration.battleFilterNonFriend or false,
		font = Configuration:GetFont(2),
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
		x = 435,
		width = 21,
		bottom = 4,
		height = 30,
		boxalign = "left",
		boxsize = 20,
		caption = " Running",
		checked = Configuration.battleFilterRunning or false,
		font = Configuration:GetFont(2),
		OnChange = {
			function (obj, newState)
				Configuration:SetConfigValue("battleFilterRunning", newState)
				self:SoftUpdate()
			end
		},
		parent = self.window,
		tooltip = "Hides all battles that are in progress",
	}

    local checkLocked = Checkbox:New {
		x = 575,
		width = 21,
		bottom = 4,
		height = 30,
		boxalign = "left",
		boxsize = 20,
		caption = " Locked",
		checked = Configuration.battleFilterLocked or false,
		font = Configuration:GetFont(2),
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
	end
	WG.Delay(UpdateCheckboxes, 0.2)

	self:SetMinItemWidth(320)
	self.columns = 3
	self.itemHeight = 80
	self.itemPadding = 1

	local function UpdateTimersDelay()
		self:UpdateTimers()
		WG.Delay(UpdateTimersDelay, 30)
	end
	WG.Delay(UpdateTimersDelay, 30)

	self.listenerUpdateDisabled = false
	self.onBattleOpened = function(listener, battleID)
		if self.listenerUpdateDisabled then
			return
		end
		self:AddBattle(battleID, lobby:GetBattle(battleID))
		self:SoftUpdate()
	end
	lobby:AddListener("OnBattleOpened", self.onBattleOpened)

	self.onBattleClosed = function(listener, battleID)
		if self.listenerUpdateDisabled then
			return
		end
		self:RemoveRow(battleID)
		self:SoftUpdate()
	end
	lobby:AddListener("OnBattleClosed", self.onBattleClosed)

	self.onJoinedBattle = function(listener, battleID)
		if self.listenerUpdateDisabled then
			return
		end
		self:JoinedBattle(battleID)
		self:SoftUpdate()
	end
	lobby:AddListener("OnJoinedBattle", self.onJoinedBattle)

	self.onLeftBattle = function(listener, battleID)
		if self.listenerUpdateDisabled then
			return
		end
		self:LeftBattle(battleID)
		self:SoftUpdate()
	end
	lobby:AddListener("OnLeftBattle", self.onLeftBattle)

	self.onUpdateBattleInfo = function(listener, battleID)
		if self.listenerUpdateDisabled then
			return
		end
		self:OnUpdateBattleInfo(battleID)
		self:UpdateButtonColor(battleID)
		self:SoftUpdate()
	end
	lobby:AddListener("OnUpdateBattleInfo", self.onUpdateBattleInfo)

	self.onBattleIngameUpdate = function(listener, battleID, isRunning)
		if self.listenerUpdateDisabled then
			return
		end
		self:OnBattleIngameUpdate(battleID, isRunning)
		self:SoftUpdate()
	end
	lobby:AddListener("OnBattleIngameUpdate", self.onBattleIngameUpdate)

	
	self.onS_Battle_Update_lobby_title = function(listener, battleID, newbattletitle)
		if self.listenerUpdateDisabled then
			return
		end
		self:OnS_Battle_Update_lobby_title(battleID, newbattletitle)
		self:SoftUpdate()
	end
	lobby:AddListener("OnS_Battle_Update_lobby_title", self.onS_Battle_Update_lobby_title)

	local function onConfigurationChange(listener, key, value)
		if key == "displayBadEngines2" then
			update()
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

	update()
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
	if Configuration.battleFilterRedundant then
		self:UpdateAllBattleIDs()
	end
	self:UpdateFilters()
	self:UpdateInfoPanel()
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
		self.infoLabel:SetCaption("No battle rooms found, report this to us on Discord!\nIf the server was just restarted\nwait a few minutes.")
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
		font = Configuration:GetFont(2),
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
	local runningImage = Image:New {
		name = "runningImage",
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		keepAspect = false,
		file = BATTLE_RUNNING,
		parent = minimap,
	}
	runningImage:BringToFront()

	local playerCount = lobby:GetBattlePlayerCount(battleID)
	local lblPlayersOnMap = Label:New {
		name = "playersOnMapCaption",
		x = height + 3,
		right = 0,
		y = 20,
		height = 15,
		valign = 'center',
		font = Configuration:GetFont(1),
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
		font = Configuration:GetFont(1),
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

	local lblTitle = Label:New {
		name = "lblTitle",
		x = height + 3,
		y = 0,
		right = 0,
		height = 20,
		valign = 'center',
		font = Configuration:GetFont(2),
		caption = battle.title,
		parent = parentButton,
		OnResize = {
			function (obj, xSize, ySize)
				obj:SetCaption(StringUtilities.GetTruncatedStringWithDotDot(battle.title, obj.font, obj.width))
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
	local runningImage = Image:New {
		name = "runningImage",
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		keepAspect = false,
		file = (battle.isRunning and BATTLE_RUNNING) or BATTLE_NOT_RUNNING,
		parent = minimap,
	}
	runningImage:BringToFront()

	local lblPlayers = Label:New {
		name = "playersCaption",
		x = height + 3,
		width = 50,
		y = 18,
		height = 22,
		valign = 'bottom',
		font = Configuration:GetFont(2),
		caption = lobby:GetBattlePlayerCount(battleID) .. "/" .. battle.maxPlayers,
		parent = parentButton,
	}

	if battle.passworded then
		local imgPassworded = Image:New {
			name = "password",
			x = height + 50,
			width = 15,
			height = 15,
			y = 20,
			height = 15,
			margin = {0, 0, 0, 0},
			file = CHOBBY_IMG_DIR .. "lock.png",
			parent = parentButton,
		}
	end

	if not Configuration.gameConfig.hideGameExistanceDisplay then
		local imHaveGame = Image:New {
			name = "imHaveGame",
			x = height + 50,
			width = 15,
			height = 15,
			y = 20,
			height = 15,
			file = (VFS.HasArchive(battle.gameName) and IMG_READY or IMG_UNREADY),
			parent = parentButton,
		}
	end

	local lblGame = Label:New {
		name = "gameCaption",
		x = height + 70,
		right = 0,
		y = 20,
		height = 15,
		valign = 'center',
		caption = self:_MakeGameCaption(battle),
		font = Configuration:GetFont(1),
		parent = parentButton,
	}

	local imHaveMap = Image:New {
		name = "imHaveMap",
		x = height + 50,
		width = 15,
		height = 15,
		y = 36,
		height = 15,
		file = (VFS.HasArchive(battle.mapName) and IMG_READY or IMG_UNREADY),
		parent = parentButton,
	}
	local lblMap = Label:New {
		name = "mapCaption",
		x = height + 70,
		right = 0,
		y = 36,
		height = 15,
		valign = 'center',
		caption = battle.mapName:gsub("_", " "),
		font = Configuration:GetFont(1),
		parent = parentButton,
	}

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
	if filterString ~= nil then
		local filterToGame = string.find(battle.gameName, filterString)
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
	-- Help: returns true if id1 should be before id2
	-- Sort 'open games first', by player count
	-- Then empty battles
	-- Then running but unlocked battles , by player count
	-- Then running but locked battles, by player count
	-- Finally private battles, alphabetically

	-- sorted list of params to check by?

	local battle1, battle2 = lobby:GetBattle(id1), lobby:GetBattle(id2)
	if id1 and id2 then
		if not (battle1 and battle2) then
			return false -- just for sanity
		end
		
		if battle1.passworded ~= battle2.passworded then 
			return battle2.passworded --
		elseif battle1.passworded == true and battle2.passworded == true then
			return string.lower(battle1.title) < string.lower(battle2.title )
		end

		if battle1.isRunning ~= battle2.isRunning then 
			return battle2.isRunning 
		end

		if battle1.locked ~= battle2.locked then 
			return battle2.locked
		end

		local countOne = lobby:GetBattlePlayerCount(id1)
		local countTwo = lobby:GetBattlePlayerCount(id2)
		if countOne ~= countTwo then
			return countOne > countTwo
		end
		return id1 > id2 -- stabalize the sort.
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
			if lobby:GetBattlePlayerCount(battleID) < 1 then
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
	--Spring.Echo("BattleListWindow:UpdateButtonColor",battleID,battlebuttonstyle, items.battleButton.backgroundColor,battle.isRunning ,battle.passworded, lobby:GetBattlePlayerCount(battleID))

	if colorChanged then
		--Spring.Echo("BattleListWindow:UpdateButtonColor",battleID,battlebuttonstyle, items.battleButton.backgroundColor,battle.isRunning ,battle.passworded, lobby:GetBattlePlayerCount(battleID))
		items.battleButton.backgroundColor = battlebuttonstyle
		items.battleButton.focusColor = battlebuttonstyle
		items.battleButton:Invalidate()
	end
end

function BattleListWindow:RecalculateOrder(id)
	if lobby.commandBuffer then
		return
	end
	self:super("RecalculateOrder", id)
end

function BattleListWindow:UpdateSync(battleID)
	local battle = lobby:GetBattle(battleID)
	if not (Configuration.displayBadEngines2 or Configuration:IsValidEngineVersion(battle.engineVersion)) then
		return
	end

	local items = self:GetRowItems(battleID)
	if not items then
		self:AddBattle(battleID)
		return
	end

	local imHaveMap = items.battleButton:GetChildByName("imHaveMap")
	if imHaveMap ~= nil then
		imHaveMap.file = (VFS.HasArchive(battle.mapName) and IMG_READY or IMG_UNREADY)
	end

	local imHaveGame = items.battleButton:GetChildByName("imHaveGame")
	if imHaveGame ~= nil then
		imHaveGame.file = (VFS.HasArchive(battle.gameName) and IMG_READY or IMG_UNREADY)
	end
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

	local playersCaption = items.battleButton:GetChildByName("playersCaption")
	if playersCaption then
		playersCaption:SetCaption(lobby:GetBattlePlayerCount(battleID) .. "/" .. battle.maxPlayers)
	else
		local playersOnMapCaption = items.battleButton:GetChildByName("playersOnMapCaption")
		local playerCount = lobby:GetBattlePlayerCount(battleID)
		playersOnMapCaption:SetCaption(playerCount .. ((playerCount == 1 and " player on " ) or " players on ") .. battle.mapName:gsub("_", " "))
	end

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

	local playersCaption = items.battleButton:GetChildByName("playersCaption")
	if playersCaption then
		playersCaption:SetCaption(lobby:GetBattlePlayerCount(battleID) .. "/" .. battle.maxPlayers)
	else
		local playersOnMapCaption = items.battleButton:GetChildByName("playersOnMapCaption")
		local playerCount = lobby:GetBattlePlayerCount(battleID)
		playersOnMapCaption:SetCaption(playerCount .. ((playerCount == 1 and " player on " ) or " players on ") .. battle.mapName:gsub("_", " "))
	end

	self:UpdateButtonColor(battleID)
	self:RecalculateOrder(battleID)
end

function BattleListWindow:OnUpdateBattleInfo(battleID)
	local battle = lobby:GetBattle(battleID)
	if not (Configuration.displayBadEngines2 or Configuration:IsValidEngineVersion(battle.engineVersion)) then
		return
	end

	local items = self:GetRowItems(battleID)
	if not items then
		self:AddBattle(battleID)
		return
	end

	local lblTitle = items.battleButton:GetChildByName("lblTitle")
	local mapCaption = items.battleButton:GetChildByName("mapCaption")
	local imHaveMap = items.battleButton:GetChildByName("imHaveMap")
	local minimapImage = items.battleButton:GetChildByName("minimap"):GetChildByName("minimapImage")
	local password = items.battleButton:GetChildByName("password")

	if imHaveMap then
		-- Password Update
		if password and not battle.passworded then
			password:Dispose()
		elseif battle.passworded and not password then
			local imgPassworded = Image:New {
				name = "password",
				x = items.battleButton.height + 28,
				y = 22,
				height = 30,
				width = 30,
				margin = {0, 0, 0, 0},
				file = CHOBBY_IMG_DIR .. "lock.png",
				parent = items.battleButton,
			}
		end



		-- Resets title and truncates.
		lblTitle.OnResize[1](lblTitle)

		minimapImage.file, minimapImage.checkFileExists = Configuration:GetMinimapSmallImage(battle.mapName)
		minimapImage:Invalidate()

		mapCaption:SetCaption(battle.mapName:gsub("_", " "))
		if VFS.HasArchive(battle.mapName) then
			imHaveMap.file = IMG_READY
		else
			imHaveMap.file = IMG_UNREADY
		end
		imHaveMap:Invalidate()


		local imHaveGame = items.battleButton:GetChildByName("imHaveGame")
		if imHaveGame ~= nil then
			imHaveGame.file = (VFS.HasArchive(battle.gameName) and IMG_READY or IMG_UNREADY)
		end

		local gameCaption = items.battleButton:GetChildByName("gameCaption")
		gameCaption:SetCaption(self:_MakeGameCaption(battle))

		local playersCaption = items.battleButton:GetChildByName("playersCaption")
		playersCaption:SetCaption(lobby:GetBattlePlayerCount(battleID) .. "/" .. battle.maxPlayers)
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

	local runningImage = items.battleButton:GetChildByName("minimap"):GetChildByName("runningImage")
	if isRunning then
		runningImage.file = BATTLE_RUNNING
	else
		runningImage.file = BATTLE_NOT_RUNNING
	end
	runningImage:Invalidate()

	self:UpdateButtonColor(battleID)
	self:RecalculateOrder(battleID)
end


function BattleListWindow:OnS_Battle_Update_lobby_title(battleID, newbattletitle)
	--Spring.Echo("function BattleListWindow:OnS_Battle_Update_lobby_title",battleID, newbattletitle)
	local battle = lobby:GetBattle(battleID)
	if not (Configuration.displayBadEngines2 or Configuration:IsValidEngineVersion(battle.engineVersion)) then
		return
	end
	local items = self:GetRowItems(battleID)
	if not items then
		self:AddBattle(battleID)
		return
	end
	
	battle.title = newbattletitle

	local battletitlelable = items.battleButton:GetChildByName("lblTitle")
	battletitlelable:SetCaption(StringUtilities.GetTruncatedStringWithDotDot(newbattletitle, battletitlelable.font, math.max(battletitlelable.width, 250) ))
	battletitlelable:Invalidate()
	items.battleButton:Invalidate()

	self:UpdateButtonColor(battleID)
	self:RecalculateOrder(battleID)
end



function BattleListWindow:OpenHostWindow()
	local hostBattleWindow = Window:New {
		caption = "",
		name = "hostBattle",
		parent = WG.Chobby.lobbyInterfaceHolder,
		width = 400,
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
		font = Configuration:GetFont(3),
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
		text = "You can host a game by requesting an empty battle room. You can lock the battle rooms (!lock) to prevent anyone from joining, otherwise anyone can join your game.",--i18n("game_name") .. ":",
		font = Configuration:GetFont(2),
		parent = hostBattleWindow,
	}


	local typeLabel = Label:New {
		x = 0,
		right = "49%",
		y = 175,
		align = "right",
		height = 35,
		caption = "Geographical region",-- i18n("game_type") .. ":",
		font = Configuration:GetFont(2),
		parent = hostBattleWindow,
	}

	local typeCombo = ComboBox:New {
		x = "51%",
		width = 150,
		y = 170,
		height = 35,
		itemHeight = 22,
		text = "",
		font = Configuration:GetFont(2),
		items = Configuration.hostRegions,
		itemFontSize = Configuration:GetFont(2).size,
		selected = 1,
		tooltip = "Choose the one closest to you for the best ping. Battle Rooms are not geographically limited.",
		parent = hostBattleWindow,
	}

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
			font = Configuration:GetFont(2),
			OnChange = {
				function (obj, newState)
					userWantsPrivateBattle =  newState
				end
			},
			parent = hostBattleWindow,
			tooltip = "If you want a passworded battleroom, please be patient while we spin up a room for you. You will be PM-ed a 4 character password you can share with your friends.",
		}
	--end

	local errorLabel = Label:New {
		x = 15,
		width = 200,
		y = 235,
		align = "left",
		height = 35,
		caption = "",-- i18n("game_type") .. ":",
		font = Configuration:GetFont(2),
		parent = hostBattleWindow,
	}

	local function CancelFunc()
		hostBattleWindow:Dispose()
	end

	local function HostBattle()
		WG.BattleRoomWindow.LeaveBattle()
		--Attempting to host game at 
		local requestedregion = typeCombo.items[typeCombo.selected]
		--Spring.Echo("Looking for empty host in region", requestedregion)
		if userWantsPrivateBattle then
			local privateclusters = {EU = '[teh]cluster1', US = '[teh]clusterUS', AU = '[balance]cluster'}
			local targetCluster = privateclusters[requestedregion]
			local mypassword = nil
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
			errorLabel:SetCaption("Please wait we spin up a battle room for you.")
			
			local trytime = 30

			local function delayedWatchRooms()
				if trytime < 1 then
					lobby:RemoveListener("OnSaidPrivate", listenForPrivateBattle)
					errorLabel:SetCaption("Unable to spin up a private battle right now.")
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
					lobby:JoinBattle(myprivatebattleID, mypassword)
					lobby:RemoveListener("OnSaidPrivate", listenForPrivateBattle)

					local function bossSelf()
						local myplayername = lobby:GetMyUserName() or ''
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
		end

		local targetbattle = nil
		-- try to get empty matching one
		local battles = lobby:GetBattles()
		local tmp = {}
		for _, battle in pairs(battles) do
			table.insert(tmp, battle)
		end
		battles = tmp
	
		for _, battle in pairs(battles) do
			if string.sub(battle.title,1,string.len(requestedregion)) == requestedregion and
				lobby:GetBattlePlayerCount(battle.battleID) == 0 and 
				battle.spectatorCount == 1 and
				Configuration:IsValidEngineVersion(battle.engineVersion) then

				targetbattle = battle.battleID
				break
			else
				--Spring.Echo('tryhostbattle',battle, battle.battleID, battle.title, lobby:GetBattlePlayerCount(battle.battleID),Configuration:IsValidEngineVersion(battle.engineVersion) )
			end

		end

		if targetbattle == nil then
			--Spring.Echo("Failed to find a battle")
			errorLabel:SetCaption("Could not find a suitable battle room!\nPlease try again.")
		else
			errorLabel:SetCaption("")
			if WG.Analytics then
				WG.Analytics.SendRepeatEvent("lobby:multiplayer:hostgame", {
					hostregion = requestedregion
				})
			end
			--Spring.Echo("Found a battle")
			local function bossSelf() 
				local myplayername = lobby:GetMyUserName() or ''
				lobby:SayBattle("!boss " .. myplayername)
			end

			self:JoinBattle(lobby:GetBattle(targetbattle))
			WG.Delay(bossSelf, 1)
			hostBattleWindow:Dispose()
		end
	end

	local buttonHost = Button:New {
		right = 150,
		width = 135,
		bottom = 1,
		height = 70,
		caption = i18n("host"),
		font = Configuration:GetFont(2),
		parent = hostBattleWindow,
		classname = "action_button",
		OnClick = {
			function()
				HostBattle()
			end
		},
	}

	local buttonCancel = Button:New {
		right = 1,
		width = 135,
		bottom = 1,
		height = 70,
		caption = i18n("cancel"),
		font = Configuration:GetFont(2),
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

function BattleListWindow:JoinBattle(battle)
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

		lobby:JoinBattle(battle.battleID)
	else
		local tryJoin, passwordWindow

		local lblError = Label:New {
			x = 30,
			width = 100,
			y = 110,
			height = 80,
			caption = "",
			font = {
				color = { 1, 0, 0, 1 },
				size = Configuration:GetFont(2).size,
				shadow = Configuration:GetFont(2).shadow,
			},
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
			font = Configuration:GetFont(3),
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
			fontsize = Configuration:GetFont(3).size,
			passwordInput = true,
			useIME = false,
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
			font = Configuration:GetFont(3),
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
			font = Configuration:GetFont(3),
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

		local popupHolder = PriorityPopup(passwordWindow, CancelFunc, tryJoin)
		screen0:FocusControl(ebPassword)
	end
end
