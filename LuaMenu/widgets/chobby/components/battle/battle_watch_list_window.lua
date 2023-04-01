BattleWatchListWindow = ListWindow:extends{}

local BATTLE_RUNNING = LUA_DIRNAME .. "images/runningBattle.png"

local IMG_READY    = LUA_DIRNAME .. "images/ready.png"
local IMG_UNREADY  = LUA_DIRNAME .. "images/unready.png"

function BattleWatchListWindow:init(parent)
	self:super("init", parent, i18n("spectate_running_games"), true)

	self:SetMinItemWidth(320)
	self.columns = 3
	self.itemHeight = 80
	self.itemPadding = 1

	local update = function() self:Update() end

	self.onBattleOpened = function(listener, battleID)
		self:AddBattle(battleID, lobby:GetBattle(battleID))
	end
	lobby:AddListener("OnBattleOpened", self.onBattleOpened)

	self.onBattleClosed = function(listener, battleID)
		self:RemoveRow(battleID)
	end
	lobby:AddListener("OnBattleClosed", self.onBattleClosed)

	self.onJoinedBattle = function(listener, battleID)
		self:JoinedBattle(battleID)
	end
	lobby:AddListener("OnJoinedBattle", self.onJoinedBattle)

	self.onLeftBattle = function(listener, battleID)
		self:LeftBattle(battleID)
	end
	lobby:AddListener("OnLeftBattle", self.onLeftBattle)

	self.onUpdateBattleInfo = function(listener, battleID)
		self:OnUpdateBattleInfo(battleID)
	end
	lobby:AddListener("OnUpdateBattleInfo", self.onUpdateBattleInfo)

	self.onBattleIngameUpdate = function(listener, battleID, isRunning)
		self:OnBattleIngameUpdate(battleID, isRunning)
	end
	lobby:AddListener("OnBattleIngameUpdate", self.onBattleIngameUpdate)

	local function onConfigurationChange(listener, key, value)
		if key == "displayBadEngines2" then
			update()
		end
	end
	Configuration:AddListener("OnConfigurationChange", onConfigurationChange)

	local function downloadFinished(listener, downloadID)
		for battleID,_ in pairs(lobby:GetBattles()) do
			self:UpdateSync(battleID)
		end
	end
	WG.DownloadHandler.AddListener("DownloadFinished", downloadFinished)

	local function UpdateTimersDelay()
		self:UpdateTimers()
		WG.Delay(UpdateTimersDelay, 30)
	end
	WG.Delay(UpdateTimersDelay, 30)

	update()
end

function BattleWatchListWindow:RemoveListeners()
	lobby:RemoveListener("OnBattleOpened", self.onBattleOpened)
	lobby:RemoveListener("OnBattleClosed", self.onBattleClosed)
	lobby:RemoveListener("OnJoinedBattle", self.onJoinedBattle)
	lobby:RemoveListener("OnLeftBattle", self.onLeftBattle)
	lobby:RemoveListener("OnUpdateBattleInfo", self.onUpdateBattleInfo)
end

function BattleWatchListWindow:Update()
	self:Clear()

	local battles = lobby:GetBattles()
	Spring.Echo("Number of battles: " .. lobby:GetBattleCount())
	local tmp = {}
	for _, battle in pairs(battles) do
		table.insert(tmp, battle)
	end
	battles = tmp
	table.sort(battles,
		function(a, b)
			return lobby:GetBattlePlayerCount(a.battleID) > lobby:GetBattlePlayerCount(b.battleID)
		end
	)

	for _, battle in pairs(battles) do
		self:AddBattle(battle.battleID, battle)
	end
end

function BattleWatchListWindow:AddBattle(battleID)
	local battle = lobby:GetBattle(battleID)

	if (not battle) or battle.passworded or (not battle.isRunning) or (not VFS.HasArchive(battle.mapName)) or (not VFS.HasArchive(battle.gameName)) then
		return
	end

	if (not Configuration.allEnginesRunnable) and not (Configuration.displayBadEngines2 or Configuration:IsValidEngineVersion(battle.engineVersion)) then
		return
	end

	local function RejoinBattleFunc()
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

	local lblRunningTime = Label:New {
		name = "runningTimeCaption",
		x = height + 3,
		right = 0,
		y = 36,
		height = 15,
		valign = 'center',
		font = Configuration:GetFont(1),
		caption = "Running for " .. Spring.Utilities.GetTimeToPast(battle.runningSince),
		parent = parentButton,
	}

	self:AddRow({parentButton}, battle.battleID)
end

function BattleWatchListWindow:CompareItems(id1, id2)
	if id1 and id2 then
		return lobby:GetBattlePlayerCount(id1) > lobby:GetBattlePlayerCount(id2)
	else
		local battle1, battle2 = lobby:GetBattle(id1), lobby:GetBattle(id2)
		Spring.Echo("battle1", id1, battle1, battle1 and battle1.users)
		Spring.Echo("battle2", id2, battle2, battle2 and battle2.users)
		return false
	end
end

function BattleWatchListWindow:UpdateSync(battleID)
	local battle = lobby:GetBattle(battleID)
	if (not Configuration.allEnginesRunnable) and not (Configuration.displayBadEngines2 or Configuration:IsValidEngineVersion(battle.engineVersion)) then
		return
	end
	local items = self:GetRowItems(battleID)

	if not items then
		self:AddBattle(battleID)
		return
	end

	if not (VFS.HasArchive(battle.mapName) and VFS.HasArchive(battle.gameName)) then
		self:RemoveRow(battleID)
	end
end

function BattleWatchListWindow:UpdateTimers()
	for battleID,_ in pairs(self.itemNames) do
		local items = self:GetRowItems(battleID)
		if not items then
			break
		end

		local battle = lobby:GetBattle(battleID)
		local runningTimeCaption = items.battleButton:GetChildByName("runningTimeCaption")
		runningTimeCaption:SetCaption("Running for " .. Spring.Utilities.GetTimeToPast(battle.runningSince))
	end
end

function BattleWatchListWindow:JoinedBattle(battleID)
	local items = self:GetRowItems(battleID)
	if not items then
		return
	end
	local battle = lobby:GetBattle(battleID)
	local playersOnMapCaption = items.battleButton:GetChildByName("playersOnMapCaption")
	local playerCount = lobby:GetBattlePlayerCount(battleID)
	playersOnMapCaption:SetCaption(playerCount .. ((playerCount == 1 and " player on " ) or " players on ") .. battle.mapName:gsub("_", " "))
	self:RecalculateOrder(battleID)
end

function BattleWatchListWindow:LeftBattle(battleID)
	local items = self:GetRowItems(battleID)
	if not items then
		return
	end
	local battle = lobby:GetBattle(battleID)
	local playersOnMapCaption = items.battleButton:GetChildByName("playersOnMapCaption")
	local playerCount = lobby:GetBattlePlayerCount(battleID)
	playersOnMapCaption:SetCaption(playerCount .. ((playerCount == 1 and " player on " ) or " players on ") .. battle.mapName:gsub("_", " "))
	self:RecalculateOrder(battleID)
end

function BattleWatchListWindow:OnUpdateBattleInfo(battleID)
	local battle = lobby:GetBattle(battleID)
	if (not Configuration.allEnginesRunnable) and not (Configuration.displayBadEngines2 or Configuration:IsValidEngineVersion(battle.engineVersion)) then
		return
	end
	local items = self:GetRowItems(battleID)

	if not items then
		self:AddBattle(battleID)
		return
	end

	if not (VFS.HasArchive(battle.mapName) and VFS.HasArchive(battle.gameName)) then
		self:RemoveRow(battleID)
	end

	-- Resets title and truncates.
	local lblTitle = items.battleButton:GetChildByName("lblTitle")
	lblTitle.OnResize[1](lblTitle)

	local minimapImage = items.battleButton:GetChildByName("minimap"):GetChildByName("minimapImage")
	minimapImage.file, minimapImage.checkFileExists = Configuration:GetMinimapSmallImage(battle.mapName)
	minimapImage:Invalidate()

	local playersOnMapCaption = items.battleButton:GetChildByName("playersOnMapCaption")
	local playerCount = lobby:GetBattlePlayerCount(battleID)
	playersOnMapCaption:SetCaption(playerCount .. ((playerCount == 1 and " player on " ) or " players on ") .. battle.mapName:gsub("_", " "))

	self:RecalculateOrder(battleID)
end

function BattleWatchListWindow:OnBattleIngameUpdate(battleID, isRunning)
	local battle = lobby:GetBattle(battleID)
	if (not Configuration.allEnginesRunnable) and not (Configuration.displayBadEngines2 or Configuration:IsValidEngineVersion(battle.engineVersion)) then
		return
	end
	if isRunning then
		self:AddBattle(battleID)
	else
		self:RemoveRow(battleID)
	end
end
