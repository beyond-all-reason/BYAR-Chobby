--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Battle Room Window",
		desc      = "Battle Room Window handler.",
		author    = "GoogleFrog",
		date      = "30 June 2016",
		license   = "GNU LGPL, v2.1 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Local variables

-- Chili controls
local mainWindow

-- Globals
local battleLobby
local wrapperControl
local mainWindowFunctions

local showDefaultStartCheckbox = false
local currentStartRects = {}
local startRectValues = {} -- for exporting the raw values

local singleplayerWrapper
local multiplayerWrapper

local spadsStatusPanel
local barManagerPresent

local singleplayerGame = "Chobby $VERSION"

local IMG_READY    = LUA_DIRNAME .. "images/ready.png"
local IMG_UNREADY  = LUA_DIRNAME .. "images/unready.png"
local IMAGE_DLREADY      = LUA_DIRNAME .. "images/downloadready.png"
local IMAGE_DLUNREADY    = LUA_DIRNAME .. "images/downloadnotready.png"
local IMG_LINK     = LUA_DIRNAME .. "images/link.png"
local IMG_CHECKBOX		= LUA_DIRNAME .. "images/checkbox.png"
local IMG_CHECKARROW		= LUA_DIRNAME .. "images/checkbox_arrow.png"

local MINIMAP_TOOLTIP_PREFIX = "minimap_tooltip_"

local MINIMUM_QUICKPLAY_PLAYERS = 4 -- Hax until the server tells me a number.

local lastUserToChangeStartBoxes = ''

local readyButton
local btnStartBattle = nil

local vote_votingsPattern = "(%d+)/(%d+).-:(%d+)"
local vote_whoCalledPattern = "%* (.*) called a vote for command"
local vote_mapPattern = 'set map (.*)"'

local playerHandler

-- modoptions extra
local factionComboBoxes = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Download management

local emptyTeamIndex = 0

local haveMapAndGame = false

local function HasGame(gameName)
	return VFS.HasArchive(gameName)
end

local function UpdateArchiveStatus(updateSync)
	if not battleLobby or not battleLobby:GetMyBattleID() then
		return
	end
	local battle = battleLobby:GetBattle(battleLobby:GetMyBattleID())
	if not battle then
		haveMapAndGame = false
		return
	end
	local haveGame = HasGame(battle.gameName)
	local haveMap = VFS.HasArchive(battle.mapName)


	if mainWindowFunctions and mainWindowFunctions.GetInfoHandler() then
		local infoHandler = mainWindowFunctions.GetInfoHandler()
		infoHandler.SetHaveGame(haveGame)
		infoHandler.SetHaveMap(haveMap)
	end
	haveMapAndGame = (haveGame and haveMap)

	if btnStartBattle then
		if haveMapAndGame then
			--btnStartBattle.tooltip = "Start the game, or call a vote to start multiplayer, or join a running game"
			btnStartBattle:StyleReady()
			btnStartBattle:SetEnabled(true)
			btnStartBattle:SetCaption(i18n("start"))
			if battleLobby.name == "singleplayer" then
				btnStartBattle.tooltip = i18n("startbtn_tooltip")
			elseif battle.isRunning then
				btnStartBattle:SetCaption(i18n("rejoin"))
				btnStartBattle.tooltip = i18n("startbtn_inprogress_tooltip")
			else
				btnStartBattle.tooltip = i18n("startbtn_votestart_tooltip")
			end
			btnStartBattle.suppressButtonReaction = false
		else
			btnStartBattle.tooltip = i18n("startbtn_gettingcontent_tooltip")
			btnStartBattle:StyleOff()
			btnStartBattle:SetEnabled(false)
			btnStartBattle.suppressButtonReaction = true
		end

	end

	if updateSync and battleLobby then
		battleLobby:SetBattleStatus({
			sync = (haveMapAndGame and 1) or 2, -- 0 = unknown, 1 = synced, 2 = unsynced
		})
	end
end

local function MaybeDownloadGame(battle)
	WG.DownloadHandler.MaybeDownloadArchive(battle.gameName, "game", -1)
end

local function MaybeDownloadMap(battle)
	WG.DownloadHandler.MaybeDownloadArchive(battle.mapName, "map", -1)
end

local OpenNewTeam

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Chili/interface management

local function SetupInfoButtonsPanel(leftInfo, rightInfo, battle, battleID, myUserName)
	local config = WG.Chobby.Configuration
	local minimapBottomClearance = 160

	local currentMapName
	local oldSelectedBoxes = 1
	local startBoxSelect = {}
	local startBoxDefaultImage = LUA_DIRNAME .. "images/load_img_128.png"
	local freezeSettings = true

	local mapLinkWidth = 150
	currentStartRects = {}

	local externalFunctions = {}

	local startBoxPanel = Control:New{
		name = 'startBoxPanel',
		x = 0,
		y = 24,
		width = "100%",
		height = 25,
		padding = {0,0,0,0},
		parent = rightInfo,
	}

	local startBoxImageHolder = Control:New{
		name = 'startBoxImageHolder',
		x = "12%",
		y = 0,
		width = "15%",
		height = "100%",
		parent = startBoxPanel,
	}

	local startBoxImage = Image:New {
		name = 'startBoxImage',
		x = 0,
		y = 0,
		width = "100%",
		height = "100%",
		keepAspect = true,
		file = startBoxDefaultImage,
		parent = startBoxImageHolder,
	}

	local startBoxSelectorNames = {"Default Boxes", "East vs West", "North vs South", "NW vs SE", "NE vs SW", "4 Corners", "4 Sides"}
	local startBoxSelectorTooltips = {"Reset to default", "East vs West", "North vs South", "Northwest vs Southeast", "Northeast vs Southwest", "Southwest vs Northeast vs Northwest vs Southeast", "West vs East vs North vs South"}
	local startBoxSelectorImages = {startBoxDefaultImage, LUA_DIRNAME .. "images/startboxsplit_v.png", LUA_DIRNAME .. "images/startboxsplit_h.png", LUA_DIRNAME .. "images/startboxsplit_c1.png", LUA_DIRNAME .. "images/startboxsplit_c2.png", LUA_DIRNAME .. "images/startboxsplit_c.png", LUA_DIRNAME .. "images/startboxsplit_s.png"}
	local startBoxComboBox = ComboBox:New{
		name = 'startBoxComboBox',
		x = "12.25%",
		y = 1,
		right = "12.5%",
		bottom = 1,
		items = startBoxSelectorNames,
		itemsTooltips = startBoxSelectorTooltips,
		itemImages = startBoxSelectorImages,
		itemKeyToName = startBoxSelectorNames,
		objectOverrideFont = config:GetFont(2),
		parent = startBoxPanel,
		selectByName = true,
		tooltip = "Change the layout of the start boxes",
		OnSelectName = {
			function(obj, selected, item)
				if freezeSettings then return end -- so these funcs dont run on first init

				local newSelectedBoxes = selected

				local function cancelFunc()
					freezeSettings = true
					obj:Select(oldSelectedBoxes)
					freezeSettings = false
				end

				local imageFileMap = {
					["Default Boxes"] = startBoxSelectorImages[1],
					["East vs West"] = startBoxSelectorImages[2],
					["North vs South"] = startBoxSelectorImages[3],
					["NW vs SE"] = startBoxSelectorImages[4],
					["NE vs SW"] = startBoxSelectorImages[5],
					["4 Corners"] = startBoxSelectorImages[6],
					["4 Sides"] = startBoxSelectorImages[7],
				}

				local function UpdateBoxes()
					oldSelectedBoxes = newSelectedBoxes

					local newImageFile = imageFileMap[selected]
					startBoxImage.file = newImageFile
					startBoxImage:Invalidate()
				end

				local function MakeIntegerSelectorWindow()
					WG.IntegerSelectorWindow.CreateIntegerSelectorWindow({
						defaultValue = 20,
						minValue = startBoxSelect.Min,
						maxValue = startBoxSelect.Max,
						caption = "Change start boxes",
						imageFile = imageFileMap[selected],
						keepAspect = true,
						labelCaption = startBoxSelect.Caption,
						OnAccepted = function(integervalue)
							if battleLobby.name == "singleplayer" then
								externalFunctions.RemoveStartRect()
								startBoxSelect.AcceptFuncSingleplayer(integervalue)
							else
								startBoxSelect.AcceptFunc(integervalue)
							end
							UpdateBoxes()
						end,
						OnCancelled = function () cancelFunc() end
					})
				end

				if selected == "Default Boxes" then
					local function defaultBoxes()
						if battleLobby.name == "singleplayer" then
							battleLobby:SelectMap(battle.mapName)
						elseif battle.nbTeams and tonumber(battle.nbTeams) > 1 then --Minimum 2 teams in multiplayer until PvE boxes are supported
							battleLobby:SayBattle("!loadboxes")
						else
							battleLobby:SayBattle("!loadboxes \""..battle.mapName.."\" 2 0")
						end
						UpdateBoxes()
					end
					WG.Chobby.ConfirmationPopup(defaultBoxes, "Restore default start boxes for the current number of teams: (" .. (battle.nbTeams or emptyTeamIndex or 1) .. ")", nil, 330, 230, i18n("ok"),nil, cancelFunc)
					return
				else
					if selected == "East vs West" then
						startBoxSelect.Min = 3
						startBoxSelect.Max = 50
						startBoxSelect.Caption = "Split the map start boxes vertically, with X percent of the map going to left and right start boxes."
						startBoxSelect.AcceptFunc = function(integervalue)
							battleLobby:SayBattle("!split v "..tostring(integervalue))
						end
						startBoxSelect.AcceptFuncSingleplayer = function(integervalue)
							externalFunctions.AddStartRect(0, 0, 0, integervalue *2, 200)
							externalFunctions.AddStartRect(1, 200 - integervalue *2, 0, 200, 200)
						end
					elseif selected == "North vs South" then
						startBoxSelect.Min = 3
						startBoxSelect.Max = 50
						startBoxSelect.Caption = "Split the map start boxes horizontally, with X percent of the map going to top and bottom start boxes."
						startBoxSelect.AcceptFunc = function(integervalue)
							battleLobby:SayBattle("!split h "..tostring(integervalue))
						end
						startBoxSelect.AcceptFuncSingleplayer = function(integervalue)
							externalFunctions.AddStartRect(0, 0, 0, 200, integervalue * 2)
							externalFunctions.AddStartRect(1, 0, 200 - integervalue *2, 200, 200)
						end
					elseif selected == "NW vs SE" then
						startBoxSelect.Min = 3
						startBoxSelect.Max = 50
						startBoxSelect.Caption = "Split the map start boxes along the corners, with X percent of the map going to top left and bottom right start boxes."
						startBoxSelect.AcceptFunc = function(integervalue)
							battleLobby:SayBattle("!split c1 "..tostring(integervalue))
						end
						startBoxSelect.AcceptFuncSingleplayer = function(integervalue)
							externalFunctions.AddStartRect(0, 0, 0, integervalue *2, integervalue * 2)
							externalFunctions.AddStartRect(1, 200 - integervalue *2, 200 - integervalue *2, 200, 200)
						end
					elseif selected == "NE vs SW" then
						startBoxSelect.Min = 3
						startBoxSelect.Max = 50
						startBoxSelect.Caption = "Split the map start boxes along the corners, with X percent of the map going to bottom left and top right start boxes."
						startBoxSelect.AcceptFunc = function(integervalue)
							battleLobby:SayBattle("!split c2 "..tostring(integervalue))
						end
						startBoxSelect.AcceptFuncSingleplayer = function(integervalue)
							externalFunctions.AddStartRect(0, 0, 200- integervalue*2 , integervalue *2, 200)
							externalFunctions.AddStartRect(1, 200-integervalue *2, 0, 200, integervalue *2 )
						end
					elseif selected == "4 Corners" then
						startBoxSelect.Min = 3
						startBoxSelect.Max = 50
						startBoxSelect.Caption = "Split the map start boxes along the corners, with X percent of the map going to all 4 corners."
						startBoxSelect.AcceptFunc = function(integervalue)
							battleLobby:SayBattle("!split c "..tostring(integervalue))
						end
						startBoxSelect.AcceptFuncSingleplayer = function(integervalue)
							externalFunctions.AddStartRect(0, 0, 200- integervalue*2 , integervalue *2, 200)
							externalFunctions.AddStartRect(1, 200-integervalue *2, 0, 200, integervalue *2 )
							externalFunctions.AddStartRect(2, 0, 0, integervalue *2, integervalue * 2)
							externalFunctions.AddStartRect(3, 200 - integervalue *2, 200 - integervalue *2, 200, 200)
						end
					elseif selected == "4 Sides" then
						startBoxSelect.Min = 3
						startBoxSelect.Max = 33
						startBoxSelect.Caption = "Split the map start boxes along the sides, with X percent of the map going to all 4 sides."
						startBoxSelect.AcceptFunc = function(integervalue)
							battleLobby:SayBattle("!split s "..tostring(integervalue))
						end
						startBoxSelect.AcceptFuncSingleplayer = function(integervalue)
							externalFunctions.AddStartRect(0, 0, 100 - integervalue , integervalue *2, 100 + integervalue)
							externalFunctions.AddStartRect(1, 200-integervalue *2, 100-integervalue, 200, 100 + integervalue)
							externalFunctions.AddStartRect(2, 100 - integervalue , 0, 100 + integervalue, integervalue * 2)
							externalFunctions.AddStartRect(3, 100 - integervalue , 200 - integervalue *2, 100+ integervalue, 200)
						end
					end
				MakeIntegerSelectorWindow()
				end
			end
		}
	}

	StartBoxComboBoxSelectDefault = function()
		startBoxComboBox:Select(1)
		oldSelectedBoxes = 1
		startBoxImage.file = startBoxDefaultImage
		startBoxImage:Invalidate()
	end

	local btnAddBox = Button:New{
		name = 'btnAddBox',
		x = 0,
		y = 1,
		width = "12%",
		bottom = 1,
		maxHeight = 50,
		parent = startBoxPanel,
		classname = "button_small",
		caption = "",
		noFont = true,
		padding = {0, 0, 0, 0},
		tooltip = "Add a new start box in the center",
		OnClick = {
			function ()
				if battleLobby.name == "singleplayer" then
					externalFunctions.AddStartRect(#currentStartRects,66, 66, 133, 133)
				else
					battleLobby:SayBattle("!addbox 66 66 133 133")
				end
			end
		}
	}

	local imAddBox = Image:New {
		name = 'imAddBox',
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		keepAspect = true,
		file = LUA_DIRNAME .. "images/startboxsplit_add.png",
		parent = btnAddBox,
		tooltip = btnAddBox.tooltip,
	}

	local btnClearBox = Button:New{
		name = 'btnClearBox',
		y = 1,
		width = "12%",
		bottom = 1,
		right = 1,
		maxHeight = 50,
		parent = startBoxPanel,
		classname = "button_small",
		caption = "",
		noFont = true,
		padding = {0, 0, 0, 0},
		tooltip = "Remove last start box",
		OnClick = {
			function ()
				if battleLobby.name == "singleplayer" then
					if #currentStartRects > 0 then
						externalFunctions.RemoveStartRect(#currentStartRects -1)
					end
				else
					battleLobby:SayBattle("!clearbox ".. tostring(#currentStartRects))
				end
			end
		}
	}

	local imClearBox = Image:New {
		name = 'imClearBox',
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		keepAspect = true,
		file = LUA_DIRNAME .. "images/startboxsplit_remove.png",
		parent = btnClearBox,
		tooltip = btnClearBox.tooltip,
	}

	local function UpdateStartRectPositionsInMinimap(width)

		for i, rect in pairs(currentStartRects) do
			-- FIXME: THIS IS IMPORTANt
			--Spring.Log("Chobby",LOG.WARNING,"start rect resized",width, height,obj.x, obj.y) --this works!
			--obj.x = math.max(0, math.min(obj.parent.width - obj.minWidth,	obj.x))
			--obj.y = math.max(0, math.min(obj.parent.height - obj.minHeight, obj.y))

			--obj.width = math.max(obj.minWidth ,math.min(obj.parent.width - obj.x, obj.width))
			--obj.height= math.max(obj.minHeight,math.min(obj.parent.height- obj.y, obj.height))
			if false then --could check width?
				rect:SetPos(
					math.floor(width*(rect.spadsSizes.left)/200),
					math.floor(width*(rect.spadsSizes.top)/200),
					math.floor(width*(rect.spadsSizes.right - rect.spadsSizes.left)/200),
					math.floor(width*(rect.spadsSizes.bottom - rect.spadsSizes.top)/200)
				) -- x,y,w,h
			else
				rect:SetPos(
					math.floor(rect.parent.width*(rect.spadsSizes.left)/200),
					math.floor(rect.parent.height*(rect.spadsSizes.top)/200),
					math.floor(rect.parent.width*(rect.spadsSizes.right - rect.spadsSizes.left)/200),
					math.floor(rect.parent.height*(rect.spadsSizes.bottom - rect.spadsSizes.top)/200)
				) -- x,y,w,h
			end
			rect:Invalidate()
			rect:BringToFront()

		end

	end

	externalFunctions.UpdateStartRectPositionsInMinimap = UpdateStartRectPositionsInMinimap

	local lblMapName = Label:New {
		name = "lblMapName",
		autosize = false,
		x = 4,
		y = 1,
		right = 4,
		align = "center",
		valign = "center",
		padding = {0, 0, 0, 0},
		parent = rightInfo,
		objectOverrideFont = config:GetFont(2),
		objectOverrideHintFont = WG.Chobby.Configuration:GetFont(2),
	}

	local function SetMapName(mapName, width)
		currentMapName = mapName
		mapLinkWidth = width

		UpdateStartRectPositionsInMinimap(width)
		if not currentMapName then
			return
		end
		mapName = battle.mapName:gsub("_", " ")
		mapName = StringUtilities.GetTruncatedStringWithDotDot(mapName, lblMapName.font, width)
		lblMapName:SetCaption(mapName)
	end
	SetMapName(battle.mapName, mapLinkWidth)

	lblMapName.OnResize[#lblMapName.OnResize + 1] = function (self, xSize, ySize)
		SetMapName(currentMapName, xSize)
	end

	local minimapPanel = Panel:New {
		name = 'minimapPanel',
		x = 0,
		y = 0,
		right = 0,
		height = 200,
		padding = {0,0,0,0},
		parent = rightInfo,
	}

	local mapImageFile, needDownload = config:GetMinimapImage(battle.mapName)
	local imMinimap = Image:New {
		name = 'imMinimap',
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		keepAspect = false, -- force wrong aspect ratio for correct start boxes display
		file = mapImageFile,
		fallbackFile = config:GetLoadingImage(3),
		checkFileExists = needDownload,
		parent = minimapPanel,
		tooltip = "Currently selected map. Green boxes show where each team will start"
	}

	if battleLobby.name == "singleplayer" and WG.Chobby.Configuration.simplifiedSkirmishSetup ~= true and config.devMode then
		local comboboxstartpostype = ComboBox:New{
			name = 'comboboxstartpostype',
			x = "60%",
			right = 98,
			y = 15,
			height = 30,
			itemHeight = 22,
			selectByName = true,
			captionHorAlign = -12,
			text = "",
			objectOverrideFont = config:GetFont(2),
			items = {"Fixed", "Random", "Choose In Game", "Choose Before Game"},
			selected = "Choose In Game",
			OnSelectName = {
				function (obj, selectedName)
					for k,v in ipairs  {"Fixed", "Random", "Choose In Game", "Choose Before Game"} do
						if selectedName == v then
							battle.startPosType = k - 1
							--Spring.Echo("Selected startPosType", k,v, k-1,selectedName)
							return
						end
					end
					battle.startPosType = nil
				end
			},
			parent = mainWindow,
		}
	end

	local function RejoinBattleFunc()
		--Spring.Echo("\LuaMenu\widgets\chobby\components\battle\battle_watch_list_window.lua","RejoinBattleFunc()","") -- Beherith Debug
		battleLobby:RejoinBattle(battleID)
		WG.Analytics.SendOnetimeEvent("lobby:multiplayer:custom:rejoin")
	end

	if battleLobby.name ~= "singleplayer" then
		readyButton = Button:New {
			name = 'readyButton',
			x = 0,
			align = "right",
			right = "50.5%",
			bottom = 0,
			height = 48,
			classname = "ready_button",
			objectOverrideFont = config:GetFont(3),
			caption = i18n("ready"),
			tooltip = i18n("ready_tooltip"), -- Set in OnUpdateUserBattleStatus
			OnClick = {
				function(readyButton)
					if not readyButton.state.enabled then return end
					local newReady = not battleLobby.userBattleStatus[battleLobby.myUserName].isReady
					battleLobby:SetBattleStatus({ isReady = newReady })
				end
			},
			parent = rightInfo,
		}

		readyButtonCheck = Image:New {
			name = 'readyButtonCheck',
			--x = "5%",
			y = 6,
			right = "84%",
			width = 16,
			height = 16,
			keepAspect = true,
			file = IMG_CHECKBOX,
			parent = readyButton,
		}

		readyButtonCheckArrow = Image:New {
			name = 'readyButtonCheckArrow',
			width = 16,
			height = 16,
			file = IMG_CHECKARROW,
			parent = readyButtonCheck,
		}

		readyButton:SetEnabled(false)
		readyButton:StyleOff()
		readyButton.suppressButtonReaction = true
	end

	btnStartBattle = Button:New {
		name = 'btnStartBattle',
		x = ((battleLobby.name == "singleplayer") and 0 or "50.5%"),
		right = 0,
		bottom = 0,
		height = 48,
		caption = i18n("start"),
		classname = "ready_button",
		objectOverrideFont = config:GetFont(3),
		-- disabledFont = config:GetFont(3),
		-- hasDisabledFont = true,
		tooltip = "Start the game, or call a vote to start multiplayer, or join a running game",
		OnClick = {
			function()
				if not haveMapAndGame then
					Spring.Echo("Do something if map or game is missing")
					return
				end

				if battle.isRunning then
					if Spring.GetGameName() == "" then
						RejoinBattleFunc()
					else
						WG.Chobby.ConfirmationPopup(RejoinBattleFunc, "Are you sure you want to leave your current game to rejoin this one?", nil, 315, 200)
					end
				else
					if battleLobby.name == "singleplayer" then
						local Configuration = WG.Chobby.Configuration
						if Configuration.gameConfig.mapStartBoxes.singleplayerboxes then
							if currentStartRects ~= {} then
								Configuration.gameConfig.mapStartBoxes.singleplayerboxes = currentStartRects
							end
						end
						WG.Analytics.SendOnetimeEvent("lobby:singleplayer:skirmish:start")
						WG.SteamCoopHandler.AttemptGameStart("skirmish", battle.gameName, battle.mapName)
					else
						WG.Analytics.SendOnetimeEvent("lobby:multiplayer:custom:start")
						battleLobby:StartBattle("skirmish")
					end
				end
			end
		},
		parent = rightInfo,
	}
	ButtonUtilities.SetButtonDeselected(btnStartBattle)

	local btnPlay
	local btnSpectate

	local function SetButtonStatePlaying()
		-- Spring.Echo("SetButtonStatePlaying !!!")
		ButtonUtilities.SetButtonDeselected(btnSpectate)
		ButtonUtilities.SetCaption(btnSpectate, i18n("spectate"))
		ButtonUtilities.SetButtonSelected(btnPlay)
		ButtonUtilities.SetCaption(btnPlay, i18n("playing"))

		btnPlay.suppressButtonReaction = true
		btnSpectate.suppressButtonReaction = false

		btnPlay.tooltip = i18n("tooltip_is_player")
		btnSpectate.tooltip = i18n("tooltip_become_spectator")

	end
	local function SetButtonStateSpectating()
		-- Spring.Echo("SetButtonStateSpectating !!!")
		-- playBtn
		ButtonUtilities.SetButtonDeselected(btnPlay)
		ButtonUtilities.SetCaption(btnPlay, i18n("play"))
		btnPlay.suppressButtonReaction = false

		-- SpecBtn
		ButtonUtilities.SetButtonSelected(btnSpectate)
		btnSpectate.suppressButtonReaction = true

		btnSpectate.tooltip = i18n("tooltip_is_spectator")
		btnPlay.tooltip = i18n("tooltip_become_player")

		ButtonUtilities.SetCaption(btnSpectate, i18n("spectating"))
	end

	btnSpectate = Button:New { -- Some properties set by SetButtonStatePlaying() after both buttons are initialised.
		name = 'btnSpectate',
		x = "50.5%",
		right = 0,
		bottom = 51,
		height = 32,
		classname = "playing_button",
		caption = "",
		objectOverrideFont = config:GetFont(2),
		OnClick = {
			function(obj)
				if btnSpectate.selected then
					return
				end

				if battleLobby.name == "singleplayer" then
					SetButtonStateSpectating()
					battleLobby:SetBattleStatus({
						isSpectator = true,
						isReady = false
					})
				else
					local battleStatus = battleLobby:GetUserBattleStatus(myUserName) or {}
					local myBs = battleLobby:GetUserBattleStatus(battleLobby.myUserName) or {}
					local iAmQueued = myBs.queuePos and myBs.queuePos > 0
					local function becomeSpec()
						battleLobby:SayBattle('$leaveq')
						battleLobby:_OnUpdateUserBattleStatus(battleLobby:GetMyUserName(), {queuePos = 0}) -- we proactive change our queuePos; because we don't reliable receicve s.battle.queue_status on fast clicking play/spectate
						battleLobby:SetBattleStatus({
							isSpectator = true,
							isReady = false
						})
					end
					if (battleStatus.isSpectator and not iAmQueued) or WG.Chobby.Configuration.queueExitConfirmPromptDoNotAskAgain then
						becomeSpec()
					else
						WG.Chobby.ConfirmationPopup(becomeSpec, i18n("queue_exit_confirm"), "queueExitConfirmPromptDoNotAskAgain", 450, 225, i18n("yes"), i18n("cancel"))
					end
				end

				WG.Analytics.SendOnetimeEvent("lobby:multiplayer:custom:spectate")
				if WG.Chobby.Configuration.useLastGameSpectatorState == 1 then
					WG.Chobby.Configuration:SetConfigValue("lastGameSpectatorState", true)
				end
			end
		},
		parent = rightInfo,
	}

	btnPlay = Button:New { -- Some properties set by SetButtonStatePlaying() after both buttons are initialised.
		name = 'btnPlay',
		x = 0,
		right = "50.5%",
		bottom = 51,
		height = 32,
		classname = "playing_button",
		caption = "",
		objectOverrideFont = config:GetFont(2),
		OnClick = {
			function(obj)
				if btnPlay.selected then
					return
				end
				local unusedTeamID = battleLobby:GetUnusedTeamID()
				--Spring.Echo("unusedTeamID",unusedTeamID)
				battleLobby:SetBattleStatus({
					isSpectator = false,
					isReady = false,
					side = (WG.Chobby.Configuration.lastFactionChoice or 0),
					teamNumber = unusedTeamID})

				if battleLobby.name == "singleplayer" then
					SetButtonStatePlaying()
				end

				WG.Analytics.SendOnetimeEvent("lobby:multiplayer:custom:play")
				if WG.Chobby.Configuration.useLastGameSpectatorState == 1 then
					WG.Chobby.Configuration:SetConfigValue("lastGameSpectatorState", false)
				end
			end
		},
		parent = rightInfo,
	}

	-- Spring.Echo("debug_initialSetButtonStatePlayingbefore")
	SetButtonStatePlaying()
	-- Spring.Echo("debug_initialSetButtonStatePlayingafter")

	local function SetBtnPlayState(selected, caption)
		local myBs = battleLobby:GetUserBattleStatus(battleLobby.myUserName) or {}
		local myQueuePos = myBs.queuePos or "?"
		-- Spring.Echo("SetBtnPlayState selected, caption", selected, caption)
		if selected then
			ButtonUtilities.SetButtonSelected(btnPlay)
			if caption == "playing" then
				btnPlay.tooltip = i18n("tooltip_is_player")
			elseif caption == "queued" then
				btnPlay.tooltip = i18n("tooltip_queued")
			end
		else
			ButtonUtilities.SetButtonDeselected(btnPlay)
			if caption == "play" then
				btnPlay.tooltip = i18n("tooltip_become_player")
			elseif caption == "join_queue" then
				btnPlay.tooltip = i18n("tooltip_join_queue")
			end
		end
		local newCaption = i18n(caption)
		newCaption = caption ~= "queued" and newCaption or (newCaption .. " " ..myQueuePos)
		ButtonUtilities.SetCaption(btnPlay, newCaption)
		btnPlay.suppressButtonReaction = selected
	end

	local function SetBtnSpecState(selected, caption)
		-- Spring.Echo("SetBtnSpecState selected, caption", selected, caption)
		if selected then
			ButtonUtilities.SetButtonSelected(btnSpectate)
			btnSpectate.tooltip = i18n("tooltip_is_spectator")
		else
			ButtonUtilities.SetButtonDeselected(btnSpectate)
			if caption == "spectate" then
				btnSpectate.tooltip = i18n("tooltip_become_spectator")
			elseif caption == "leave_queue" then
				btnSpectate.tooltip = i18n("tooltip_leave_queue")
			end
		end
		ButtonUtilities.SetCaption(btnSpectate, i18n(caption))
		btnSpectate.suppressButtonReaction = selected
	end

	function externalFunctions.SetBtnsPlaySpec(playSelected, playCaption, specSelected, specCaption, force)
		-- local inputParamsPlay = {
		-- 	playSelected = playSelected,
		-- 	playCaption  = playCaption,
		-- }
		-- 
		-- local inputParamsSpec = {
		-- 	specSelected = specSelected,
		-- 	specCaption  = specCaption,
		-- }

		if not btnPlay then
			-- Spring.Echo("SetBtnsPlaySpec btnPlay not initialized")
			return
		end

		--local playBtnStatus = {
		--	selected               = btnPlay.selected,
		--	suppressButtonReaction = btnPlay.suppressButtonReaction,
		--	tooltip                = btnPlay.tooltip,
		--	caption                = btnPlay.oldCaption, -- strange behaviour, returns strange strings
		--}
		--
		--local specBtnStatus = {
		--	selected               = btnSpectate.selected,
		--	suppressButtonReaction = btnSpectate.suppressButtonReaction,
		--	tooltip                = btnSpectate.tooltip,
		--	caption                = btnSpectate.oldCaption, -- strange behaviour, returns strange strings
		--}

		if btnPlay.selected ~= playSelected or btnPlay.oldCaption ~= playCaption or force then
			-- Spring.Utilities.TableEcho(inputParamsPlay)
			-- Spring.Utilities.TableEcho(playBtnStatus)
			SetBtnPlayState(playSelected, playCaption)
		end

		if btnSpectate.selected ~= specSelected or btnSpectate.oldCaption ~= specCaption or force then
			-- Spring.Utilities.TableEcho(inputParamsSpec)
			-- Spring.Utilities.TableEcho(specBtnStatus)
			SetBtnSpecState(specSelected, specCaption)
		end
	end

	rightInfo.OnResize = {
		function (obj, xSize, ySize)
			-- Spring.Utilities.TraceFullEcho(nil,nil,nil,"rightInfo.OnResize", xSize, ySize )
			if xSize + minimapBottomClearance < ySize then
				minimapPanel._relativeBounds.left = 0
				minimapPanel._relativeBounds.right = 0

				minimapPanel:SetPos(nil, nil, nil, xSize)
				UpdateStartRectPositionsInMinimap()
				minimapPanel:UpdateClientArea()

				lblMapName:SetPos(nil, xSize + 2)
				startBoxPanel:SetPos(nil,xSize + 24,nil, math.min(50, math.round(xSize / 8)))

			else
				local horPadding = ((xSize + minimapBottomClearance) - ySize)/2
				minimapPanel._relativeBounds.left = horPadding
				minimapPanel._relativeBounds.right = horPadding
				minimapPanel:SetPos(nil, nil, nil, ySize - minimapBottomClearance)

				UpdateStartRectPositionsInMinimap()
				minimapPanel:UpdateClientArea()

				lblMapName:SetPos(nil, ySize - minimapBottomClearance + 2)
				startBoxPanel:SetPos(nil,ySize - minimapBottomClearance + 24, nil, math.min(50, math.round(xSize / 8)))


			end
		end
	}

	local leftOffset = 0
	local btnNewTeam = Button:New {
		name = "btnNewTeam",
		x = 5,
		y = leftOffset,
		height = 35,
		right = 5,
		classname = "option_button",
		caption = i18n("add_team") .. "\b",
		objectOverrideFont = config:GetFont(2),
		tooltip = "Add another team for players or AI to join into",
		OnClick = {
			function()
				if OpenNewTeam then
					OpenNewTeam()
				end
			end
		},
		-- Combo box settings
		--ignoreItemCaption = true,
		--itemFontSize = config:GetFont(1).size,
		--itemHeight = 30,
		--selected = 0,
		--maxDropDownWidth = 120,
		--minDropDownHeight = 0,
		--items = {"Join", "Add AI"},
		--OnSelect = {
		--	function (obj)
		--		if obj.selected == 1 then
		--			battleLobby:SetBattleStatus({
		--				allyNumber = emptyTeamIndex,
		--				isSpectator = false,
		--			})
		--		elseif obj.selected == 2 then
		--			WG.PopupPreloader.ShowAiListWindow(battleLobby, battle.gameName, emptyTeamIndex)
		--		end
		--	end
		--},
		parent = leftInfo
	}
	leftOffset = leftOffset + 38

	local btnPickMap = Button:New {
		name = 'btnPickMap',
		x = 5,
		y = leftOffset,
		height = 35,
		right = 5,
		classname = "option_button",
		caption = i18n("pick_map") .. "\b",
		objectOverrideFont = config:GetFont(2),
		tooltip = "Select a map from the maps you have downloaded",
		OnClick = {
			function()
				WG.MapListPanel.Show(battleLobby, battle.mapName)
			end
		},
		parent = leftInfo,
	}
	leftOffset = leftOffset + 38


	-- modoptions
	WG.ModoptionsPanel.LoadModoptions(battle.gameName, battleLobby)
	-- if load modoptions failed there may be modoptions from the previous game
	local modoptions = WG.ModoptionsPanel.ReturnModoptions()



	local tooltip = modoptions
			and "Configure custom gameplay options"
			--or "Error: Could not retrieve modoptions, your game files may be corrupted or the lobby may be invalid"
			or "Game Update may still be downloading"
	local modoptionsLoaded = modoptions
	local btnModoptions = Button:New {
		name = 'btnModoptions',
		x = 5,
		y = leftOffset,
		height = 35,
		right = 5,
		classname = "option_button",
		caption = "Adv Options" .. "\b",
		objectOverrideFont = config:GetFont(2),
		objectOverrideDisabledFont = config:GetFont(1),
		hasDisabledFont = true,
		tooltip = tooltip,
		OnClick = {
			function()
				if modoptionsLoaded then
					WG.ModoptionsPanel.ShowModoptions()
				end
			end
		},
		parent = leftInfo,
	}
	leftOffset = leftOffset + 40


	local tooltip = modoptions
			and "Create and Load Presets for gameplay options"
			or "Game Update may still be downloading"
	local btnOptionPresets = Button:New {
		name = 'btnOptionPresets',
		x = 5,
		y = leftOffset,
		height = 35,
		right = 5,
		classname = "option_button",
		caption = "Option Presets" .. "\b",
		objectOverrideFont = config:GetFont(2),
		objectOverrideDisabledFont = config:GetFont(1),
		hasDisabledFont = true,
		tooltip = tooltip,
		OnClick = {
			function()
				if modoptionsLoaded then
					WG.OptionpresetsPanel.ShowPresetPanel()
				end
			end
		},
		parent = leftInfo,
	}
	leftOffset = leftOffset + 40

	-- gray out the button if we don't have a modoptions panel to show
	if not modoptions then
		-- cosmetics when disabled
		btnModoptions.suppressButtonReaction = true
		btnModoptions:SetEnabled(false)
		-- preset loading is useless if modification of modoptions not allow
		btnOptionPresets.suppressButtonReaction = true
		btnOptionPresets:SetEnabled(false)
	end

	-- the modoptions panel needing a refresh is independant on if we have a modoptions panel from a diffrent version to fall back onto
	if not VFS.HasArchive(battle.gameName) then
		-- Listener function to re-enable the button
		local function gameArchiveReady(k,v)
			if VFS.HasArchive(battle.gameName) then
				WG.ModoptionsPanel.LoadModoptions(battle.gameName, battleLobby)

				-- cosmetics for re-enabling
				btnModoptions.suppressButtonReaction = false
				btnModoptions.tooltip = "Configure custom gameplay options"
				btnModoptions:SetEnabled(true)
				modoptionsLoaded = true

				--enable also btnOptionPresets
				btnOptionPresets.suppressButtonReaction = false
				btnOptionPresets.tooltip = "Create and Load Presets for gameplay options"
				btnOptionPresets:SetEnabled(true)

				local modoptionspanelExternalFunctions = WG.ModoptionsPanel.GetModoptionsControl()
				modoptionspanelExternalFunctions:Update()

				WG.DownloadHandler.RemoveListener("DownloadFinished", gameArchiveReady)
			end
		end

		WG.DownloadHandler.AddListener("DownloadFinished", gameArchiveReady)
	end


	local lblGame = Label:New {
		name = 'lblGame',
		x = 8,
		y = leftOffset,
		right = 3,
		caption = WG.Chobby.Configuration.gameConfig.ShortenNameString(battle.gameName),
		objectOverrideFont = config:GetFont(2),
		parent = leftInfo,
		OnResize = {
			function (obj, xSize, ySize)
				obj:SetCaption(StringUtilities.GetTruncatedStringWithDotDot(WG.Chobby.Configuration.gameConfig.ShortenNameString(battle.gameName), obj.font, xSize or obj.width))
			end
		}
	}
	leftOffset = leftOffset + 26

	local imHaveGame = Image:New {
		name = 'imHaveGame',
		x = 8,
		y = leftOffset,
		width = 15,
		height = 15,
		file = IMAGE_DLREADY,
		parent = leftInfo,
	}
	local lblHaveGame = Label:New {
		name = 'lblHaveGame',
		x = 28,
		y = leftOffset,
		caption = "",
		objectOverrideFont = config:GetFont(2),
		parent = leftInfo,
	}
	leftOffset = leftOffset + 25

	local imHaveMap = Image:New {
		name = 'imHaveMap',
		x = 8,
		y = leftOffset,
		width = 15,
		height = 15,
		file = IMAGE_DLREADY,
		parent = leftInfo,
	}
	local lblHaveMap = Label:New {
		name = 'lblHaveMap',
		x = 28,
		y = leftOffset,
		caption = "",
		objectOverrideFont = config:GetFont(2),
		parent = leftInfo,
	}
	leftOffset = leftOffset + 30

	local modoptionsHolder = Control:New {
		name = 'modoptionsHolder',
		x = 0,
		y = leftOffset,
		right = 0,
		height = 120,
		padding = {2, 0, 2, 0},
		autosize = false,
		resizable = false,
		tooltip = "All custom gameplay options are listed here",
		children = {
			WG.ModoptionsPanel.GetModoptionsControl()
		},
		parent = leftInfo,
	}
	if modoptionsHolder.children[1].visible then
		modoptionsHolder.children[1]:Hide()
	end

	local modoptionTopPosition = leftOffset
	local modoptionBottomPosition = leftOffset + 120
	local downloadVisibility = true
	local function OnDownloaderVisibility(newVisible)
		if newVisible ~= nil then
			downloadVisibility = newVisible
		end
		local newY = downloadVisibility and modoptionBottomPosition or modoptionTopPosition
		local newHeight = math.max(10, leftInfo.clientArea[4] - newY)
		modoptionsHolder:SetPos(nil, newY, nil, newHeight)
	end
	OnDownloaderVisibility(false)
	leftInfo.OnResize = leftInfo.OnResize or {}
	leftInfo.OnResize[#leftInfo.OnResize + 1] = function ()
		OnDownloaderVisibility()
	end

	local downloaderPos = {
		x = 0,
		height = 120,
		right = 3,
		y = leftOffset,
		parent = leftInfo,
	}

	local downloader = WG.Chobby.Downloader(false, downloaderPos, 8, nil, nil, nil, OnDownloaderVisibility)
	leftOffset = leftOffset + 120


	-- Example downloads
	--MaybeDownloadArchive("Titan-v2", "map")
	--MaybeDownloadArchive("tinyskirmishredux1.1", "map")

	function externalFunctions.UpdateBattleMode(disallowCustomTeams)
		local offset = 0
		if disallowCustomTeams then
			btnNewTeam:SetVisibility(false)
		else
			btnNewTeam:SetVisibility(true)
			offset = offset + 38
		end
		btnPickMap:SetPos(nil, offset)
		offset = offset + 38
		btnModoptions:SetPos(nil, offset)
		offset = offset + 40
		btnOptionPresets:SetPos(nil, offset)
		offset = offset + 40
		lblGame:SetPos(nil, offset)
		offset = offset + 26
		imHaveGame:SetPos(nil, offset)
		lblHaveGame:SetPos(nil, offset)
		offset = offset + 25
		imHaveMap:SetPos(nil, offset)
		lblHaveMap:SetPos(nil, offset)
	end
	externalFunctions.UpdateBattleMode(battle.disallowCustomTeams)

	function externalFunctions.SetHaveGame(newHaveGame)
		if newHaveGame then
			imHaveGame.file = IMAGE_DLREADY
			lblHaveGame:SetCaption(i18n("have_game"))
		else
			imHaveGame.file = IMAGE_DLUNREADY
			lblHaveGame:SetCaption(i18n("dont_have_game"))
		end
		imHaveGame:Invalidate()
	end

	function externalFunctions.SetHaveMap(newHaveMap)
		if newHaveMap then
			imHaveMap.file = IMAGE_DLREADY
			lblHaveMap:SetCaption(i18n("have_map"))
		else
			imHaveMap.file = IMAGE_DLUNREADY
			lblHaveMap:SetCaption(i18n("dont_have_map"))
		end
		imHaveMap:Invalidate()
	end

	-- Lobby interface
	function externalFunctions.UpdateUserTeamStatus(userName, allyNumber, isSpectator, queuePos)
		if userName == myUserName then
			if battleLobby.name ~= "singleplayer" and battle.bossed ~= true and (isSpectator or (queuePos and queuePos > 0)) then
				-- SetButtonStateSpectating()
				startBoxPanel:Hide()
				minimapPanel.disableChildrenHitTest = true --omg this is amazing
			else
				-- SetButtonStatePlaying()
				startBoxPanel:Show()
				minimapPanel.disableChildrenHitTest = false
			end
		end
	end

	function externalFunctions.BattleIngameUpdate(updatedBattleID, isRunning)
		if battleID == updatedBattleID then
			if isRunning then
				btnStartBattle:SetCaption(i18n("rejoin"))
				readyButton.tooltip = i18n("inprogress_tooltip")
			else
				btnStartBattle:SetCaption(i18n("start"))
			end
		end
	end

	externalFunctions.BattleIngameUpdate(battleID, battle.isRunning)

	function externalFunctions.UpdateBattleInfo(updatedBattleID, battleInfo)
		if battleID ~= updatedBattleID then
			return
		end
		if battleInfo.mapName then
			SetMapName(battleInfo.mapName, mapLinkWidth)
			imMinimap.file, imMinimap.checkFileExists = config:GetMinimapImage(battleInfo.mapName)
			imMinimap:Invalidate()

			local isSingleplayer = (battleLobby.name == "singleplayer")
			local mapName = battleInfo.mapName
			local allyTeamCount = emptyTeamIndex
			local startboxes = nil
			local Configuration = WG.Chobby.Configuration

			if isSingleplayer then
				imMinimap.children = {}
				if Configuration.gameConfig and
						Configuration.gameConfig.useDefaultStartBoxes and
						Configuration.gameConfig.mapStartBoxes and
						Configuration.gameConfig.mapStartBoxes.savedBoxes then

					local mapStartBoxes = Configuration.gameConfig.mapStartBoxes
					-- remove the old one
					externalFunctions.RemoveStartRect()
					mapStartBoxes.clearBoxes()

					-- then the next step is if the boxes get changed, add them to custom?
					startBoxes = mapStartBoxes.savedBoxes[mapName]
					-- todo on add team then add a box too

					startBoxes = Configuration.gameConfig.mapStartBoxes.savedBoxes[mapName]
					--Spring.Echo("Skirmish: Using default startboxes for",mapName, startBoxes)
					startBoxes = Configuration.gameConfig.mapStartBoxes.selectStartBoxesForAllyTeamCount(startBoxes,allyTeamCount)
					if startBoxes then
						--externalFunctions.RemoveStartRect()
						for i = 1, allyTeamCount do
							if startBoxes[i] then
								externalFunctions.AddStartRect(i-1,200*startBoxes[i][1],200*startBoxes[i][2],200*startBoxes[i][3],200*startBoxes[i][4])
							end
						end
					else
						-- !split v 20
						externalFunctions.AddStartRect(0,0,0,40,200)
						externalFunctions.AddStartRect(1,160,0,200,200)
					end

					StartBoxComboBoxSelectDefault()
				else
					Spring.Echo("No map startBoxes found or disabled for map",mapName,"teamcount:",allyTeamCount)
				end
			end

			-- TODO: Bit lazy here, seeing as we only need to update the map
			UpdateArchiveStatus(true)
			MaybeDownloadMap(battle)
		end
		-- TODO: messy code, rework; SetBattleStatus is called too many times;
		-- UpdateArchiveStatus(true) is invoked in a couple of places, but also
		-- the battleLobby status is manually checked set separately (why?)
		if battleInfo.gameName then
			lblGame:SetCaption(battleInfo.gameName)
			UpdateArchiveStatus(true)
			MaybeDownloadGame(battle)
		end

		if (battleInfo.mapName and not VFS.HasArchive(battleInfo.mapName)) or (battleInfo.gameName and not HasGame(battleInfo.gameName)) then
			battleLobby:SetBattleStatus({
				sync = 2, -- 0 = unknown, 1 = synced, 2 = unsynced
			})
		end
	end

	function externalFunctions.LeftBattle(leftBattleID, userName)
		if battleID ~= leftBattleID then
			return
		end
		if battleLobby:GetMyUserName() == userName then
			mainWindow:Dispose()
			mainWindow = nil
			if wrapperControl and wrapperControl.visible and wrapperControl.parent then
				wrapperControl:Hide()
			end
		end
	end

	function externalFunctions.JoinedBattle(joinedBattleId, userName)
		if battleID ~= joinedBattleId or userName == battleLobby:GetMyUserName() then
			return
		else
			--Spring.Echo('JoinedBattle(joinedBattleId, userName)',joinedBattleId, userName)

			local iAmFirstPlayer = true
			local playersthatarentme = 0
			local mynewbestfriend = ""
			local myUserName = battleLobby:GetMyUserName()
			local lobby = WG.LibLobby.lobby

			for name, data in pairs(battleLobby.userBattleStatus) do
				local lobbyuserinfo = lobby:TryGetUser(name)
				--Spring.Echo("userBattleStatus:",name)
				--Spring.Utilities.TableEcho(data)
				--Spring.Utilities.TableEcho(lobbyuserinfo)
				if data.aiLib == nil and lobbyuserinfo.isBot ~= true then
					if name ~= myUserName then
						playersthatarentme = playersthatarentme + 1
						if playersthatarentme == 1 then
							mynewbestfriend = name
						end
						iAmFirstPlayer = false
					end
				end
			end
			--Spring.Echo("YAY A BUDDY!", iAmFirstPlayer, playersthatarentme, mynewbestfriend)

			if playersthatarentme == 0 then -- cause the first time someone joines, they dont yet have a userbattlestatus
				playersthatarentme = 1
				mynewbestfriend = userName
			end

			if playersthatarentme == 1 and mynewbestfriend ~= "" then
				local userInfo = lobby:TryGetUser(mynewbestfriend)
				if userInfo then
					Spring.PlaySoundFile("sounds/Alarm_light5_mixdown.wav", WG.Chobby.Configuration.menuNotificationVolume or 1) -- RING SOUND

					local userControl = WG.UserHandler.GetNotificationUser(mynewbestfriend)
					userControl:SetPos(30, 30, 250, 80)
					Chotify:Post({
						title = i18n("A Player Joined You"),
						body = userControl,
					})
				end
			end

		end
	end

	function externalFunctions.AddStartRect(allyNo, left, top, right, bottom)
		-- Spring.Log("Chobby AddStartRect",LOG.WARNING,"AddStartRect", allyNo, left, top, right, bottom,minimapPanel.width,minimapPanel.height)
		-- FIXME: minimap.width is sometimes only 10 at this point :/
		-- it doesnt even know how big it is right nowhere
		-- Spring.Utilities.TraceFullEcho()

		-- adding the raw values
		startRectValues[allyNo+1]={["left"]=left, ["top"]=top, ["right"]=right, ["bottom"]=bottom}

		local minimapPanelMaxSize = math.max(minimapPanel.width,minimapPanel.height) -1
		local ox = math.floor(left * minimapPanelMaxSize / 200)
		local oy = math.floor(top * minimapPanelMaxSize / 200)
		local ow = math.floor((right-left) * minimapPanelMaxSize / 200)
		local oh = math.floor((bottom-top) * minimapPanelMaxSize / 200)
		if currentStartRects[allyNo+1] then externalFunctions.RemoveStartRect(allyNo) end
		local newStartRect = Window:New {
			name = 'newStartRect'..tostring(allyNo + 1),

			spadsSizes = {left = left,top = top,right = right,bottom = bottom, caption = tostring(allyNo + 1)},
			x = ox,
			y = oy,
			width = ow,
			height = oh,
			minWidth = 15,
			minHeight = 15,
			objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
			caption = tostring(allyNo + 1),
			classname = "startbox_window",
			parent = minimapPanel,
			captionColor = {1.0, 1.0, 1.0, 1.0},
			backgroundColor = {0.9, 0.1, 1.0, 1.0},
			borderColor = {0.1, 0.9, 0.1,0.5},
			focusColor = {0.0, 0.9, 0.1, 1.0},
			padding = {0,0,0,0},
			tooltip = "Drag box to move, drag corner to resize\nLast changed by "..lastUserToChangeStartBoxes,
			oldSizes = {ox,oy,ow,oh}, -- this stores its previous state so we dont spam boxes on no change
			OnClick = {
				function(obj)
					-- Spring.Log("Chobby",LOG.WARNING,"start rect clicked",obj.caption,obj.width, obj.height,obj.x, obj.y)

					if math.abs(obj.oldSizes[1] - obj.x) < 1.0 and
						math.abs(obj.oldSizes[2] - obj.y) < 1.0 and
						math.abs(obj.oldSizes[3] - obj.width) < 1.0 and
						math.abs(obj.oldSizes[4] - obj.height) < 1.0 then
						--Spring.Echo("no change in boxes")
					else
						local pw = obj.parent.width - 1
						local ph = obj.parent.height - 1
						obj.x = math.max(0, math.min(pw - obj.minWidth, obj.x))
						obj.y = math.max(0, math.min(ph - obj.minHeight, obj.y))

						obj.width = math.max(obj.minWidth ,math.min(pw - obj.x, obj.width))
						obj.height= math.max(obj.minHeight,math.min(ph- obj.y, obj.height))

						obj.oldSizes = {obj.x,obj.y, obj.width,obj.height}

						local l = 200* obj.x / pw
						local t = 200* obj.y / ph
						local r = 200* obj.width / pw + l
						local b = 200* obj.height / ph + t
						--Spring.Log("Chobby",LOG.WARNING,"start rect changed:",l,t,r,b)
						--also do the fact that it should be red on change, and turn back black on successfull modification
						--try to manage clicking on the startbox not changing it.
						--TODO: problematic when resizing entire UI :/

						-- updating the raw values
						startRectValues[tonumber(obj.caption)]={["left"]=l, ["top"]=t, ["right"]=r, ["bottom"]=b}

						obj:Invalidate() --doesnt do much
						if battleLobby.name == "singleplayer" then
							WG.Chobby.Configuration.gameConfig.mapStartBoxes.addBox(l,t,r,b,obj.caption)
							obj.spadsSizes = {left = l, top = t, right = r, bottom = b, caption = obj.caption}
						else
							battleLobby:SayBattle(string.format("!addbox %d %d %d %d %s", l,t,r,b,obj.caption))
						end
					end
				end
			},
			OnResize = {
				-- FIXME: the big problem, is that if a start box is dragged outside of the minimap panel,
				-- and then the mouse is released while it is outside, we get no callbacks
				-- So then the box is pretty much stuck
				function (obj, width, height)
					--Spring.Log("Chobby",LOG.WARNING,"start rect resized",width, height,obj.x, obj.y) --this works!
					obj.x = math.max(0, math.min(obj.parent.width - obj.minWidth, obj.x))
					obj.y = math.max(0, math.min(obj.parent.height - obj.minHeight, obj.y))

					obj.width = math.max(obj.minWidth ,math.min(obj.parent.width - obj.x -1, obj.width ))
					obj.height= math.max(obj.minHeight,math.min(obj.parent.height- obj.y -1, obj.height))

				end
			},
		}

		currentStartRects[allyNo+1] = newStartRect

		for i,rect in pairs(currentStartRects) do
			rect:BringToFront()
		end
		--Spring.Echo("Start rect table:",newStartRect.classname, newStartRect)

	end

	function externalFunctions.RemoveStartRect(allyNo)
		if allyNo == nil then
			for i,rect in pairs(currentStartRects) do
				rect:Dispose()
			end
			currentStartRects = {}
		else
			if currentStartRects[allyNo+1] then
				currentStartRects[allyNo+1]:Dispose()
				currentStartRects[allyNo+1] = nil
				startRectValues[allyNo+1] = nil
			end
			for i,rect in pairs(currentStartRects) do
				rect:BringToFront()
			end
		end

	end

	function externalFunctions.GetStartRects()
		return currentStartRects
	end

	MaybeDownloadGame(battle)
	MaybeDownloadMap(battle)
	UpdateArchiveStatus(true)
	freezeSettings = false
	externalFunctions.rightInfo = rightInfo

	return externalFunctions
end

local ARM_MASK = 2^0
local COR_MASK = 2^1
local LEG_MASK = 2^2
local FULL_BITMASK = math.bit_or(ARM_MASK, COR_MASK, LEG_MASK)
local function AddTeamButtons(parent, offX, joinFunc, aiFunc, unjoinable, disallowBots, allyTeam)
	if not disallowBots then
		local addAiButton = Button:New {
			name = "addAiButton",
			x = offX,
			y = 0, --5
			height = 24,
			width = 95,
			objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
			caption = i18n("add_ai") .. "\b",
			OnClick = {aiFunc},
			classname = "button_small",
			parent = parent,
			tooltip = "Add an AI to the game",
		}
		offX = offX + 95
	end
	if not unjoinable then
		local joinTeamButton = Button:New {
			name = "joinTeamButton",
			x = offX,
			y = 0, --5
			height = 24,
			width = 95,
			objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
			caption = i18n("join") .. "\b",
			OnClick = {joinFunc},
			classname = "button_small",
			parent = parent,
			tooltip = "Change your team to this one",
		}
	end

	-- the faction limiter is limited to only 8 teams, this is due to the 24 bit limit:
	-- 3*8 = 24
	if allyTeam <= 7 then
		local firstTime = true
		local myAllyTeam = allyTeam


		-- isolate our 3 bits
		local ourBitmask = FULL_BITMASK
		for i = 1, myAllyTeam do
			ourBitmask = ourBitmask * 8
		end
		local currentBitmask, currentOurBitmask = 0, 0

		local teamFactionsSigns = {"ALL","✔  ","✔  ","✔  ","RESET"}
		local teamFactionsNames = {"ALL", "Armada", "Cortex", "Legion", "RESET"}
		local teamFactionsTooltips = {
			nil,
			"Toggle Armada Playability for this team",
			"Toggle Cortex Playability for this team",
			"Toggle Legion Playability for this team",
			"Re-Enable All Factions for All Teams",
		}
		local teamFactionsImages = {
			nil,
			LUA_DIRNAME .. "configs/gameConfig/byar/sidepics/" .. "armada.png",
			LUA_DIRNAME .. "configs/gameConfig/byar/sidepics/" .. "cortex.png",
			LUA_DIRNAME .. "configs/gameConfig/byar/sidepics/" .. "legion.png",
			nil,
		}
		local setCaption
		local teamFactionsSet, factionFlagHolder, factionArm, factionCor, factionLeg
		local factionWraper = {
			Hide=function()
				teamFactionsSet:Hide()
				setCaption()
			end,
			Show=function()
				teamFactionsSet:Show()
				setCaption()
			end,
			updateBitmaskReading=function(bitmask)
				teamFactionsSet.updateBitmaskReading(bitmask)
			end,
		}
		teamFactionsSet = ComboBox:New{
			name = "teamFactionsSet",
			x = offX+95,
			y = 0, --5
			height = 24,
			width = 72+15,
			objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
			parent = parent,
			showSelection = true, -- we have custom behaviour
			tooltip = "Limit Which Factions this team may start as.",
			items = teamFactionsSigns,
			itemsTooltips = teamFactionsTooltips,
			itemImages = teamFactionsImages,
			itemKeyToName = teamFactionsNames,
			selected = 5,
			OnDispose = {function()
					if factionComboBoxes[allyTeam] == factionWraper then
						factionComboBoxes[allyTeam] = nil
					end
				end},
			OnSelect = {
				function (obj, selected, item)
					if firstTime then
						firstTime = false
						return
					end
					local newbitmask = 0
					if selected == 5 then
						battleLobby:SetModOptions({
							factionlimiter="0"
						})
						setCaption()
						return
					elseif selected == 1 then
						newbitmask = 0
						newbitmask = math.bit_and(currentBitmask, math.bit_inv(ourBitmask))
					else
						-- Shift 2,3 and 4 into 1,2, and 4 to match the faction bit value
						local bit = selected == 4 and 4 or selected - 1
						if currentOurBitmask == bit then
							newbitmask = math.bit_xor(FULL_BITMASK, bit)
						else
							newbitmask = math.bit_xor(currentOurBitmask, bit)
						end

						if newbitmask == FULL_BITMASK then
							newbitmask = 0
						end
						newbitmask = math.bit_or(
							math.bit_and(currentBitmask, math.bit_inv(ourBitmask)),
							newbitmask*(2^(myAllyTeam*3))
						)
					end
					battleLobby:SetModOptions({
						factionlimiter=tostring(newbitmask)
					})
					setCaption()
				end
			},
			updateBitmaskReading = function(bitmask)
				if bitmask == currentBitmask then
					return
				end

				local newbitmask = math.bit_and(bitmask or 0, ourBitmask)
				newbitmask = math.floor(newbitmask/2^(myAllyTeam*3))

				if newbitmask == 0 then
					teamFactionsSigns[2] = "✔  "
					teamFactionsSigns[3] = "✔  "
					teamFactionsSigns[4] = "✔  "
				else
					teamFactionsSigns[2] = math.bit_and(newbitmask, ARM_MASK) ~= 0 and "✔  " or "🔒  "
					teamFactionsSigns[3] = math.bit_and(newbitmask, COR_MASK) ~= 0 and "✔  " or "🔒  "
					teamFactionsSigns[4] = math.bit_and(newbitmask, LEG_MASK) ~= 0 and "✔  " or "🔒  "
				end
				currentBitmask = bitmask
				currentOurBitmask = newbitmask
				setCaption()
			end,
		}
		factionComboBoxes[allyTeam] = factionWraper
		setCaption = function()
			teamFactionsSet.selected = 5
			if currentBitmask == 0 then
				factionArm:Hide()
				factionCor:Hide()
				factionLeg:Hide()
			elseif currentOurBitmask == 0 then
				factionArm:Show()
				factionCor:Show()
				factionLeg:Show()
			else
				if math.bit_and(currentOurBitmask, ARM_MASK) ~= 0 then
					factionArm:Show()
				else
					factionArm:Hide()
				end
				if math.bit_and(currentOurBitmask, COR_MASK) ~= 0 then
					factionCor:Show()
				else
					factionCor:Hide()
				end
				if math.bit_and(currentOurBitmask, LEG_MASK) ~= 0 then
					factionLeg:Show()
				else
					factionLeg:Hide()
				end
			end
			teamFactionsSet.caption = ""
		end
		factionArm = Image:New {
			name = "factionArm",
			x = offX+95+5,
			y = 0,
			height = 24,
			width = 24,
			parent = parent,
			keepAspect = true,
			file = LUA_DIRNAME .. "configs/gameConfig/byar/sidepics/" .. "armada.png",
		}
		factionCor = Image:New {
			name = "factionCor",
			x = offX+95+5+24,
			y = 0,
			height = 24,
			width = 24,
			parent = parent,
			keepAspect = true,
			file = LUA_DIRNAME .. "configs/gameConfig/byar/sidepics/" .. "cortex.png",
		}
		factionLeg = Image:New {
			name = "factionLeg",
			x = offX+95+5+48,
			y = 0,
			height = 24,
			width = 24,
			parent = parent,
			keepAspect = true,
			file = LUA_DIRNAME .. "configs/gameConfig/byar/sidepics/" .. "legion.png",
		}
		local modoptions = battleLobby:GetMyBattleModoptions()
		if modoptions and modoptions.factionlimiter then
			teamFactionsSet.updateBitmaskReading(tonumber(modoptions.factionlimiter))
			setCaption()
		end
		modoptions = nil

		if battleLobby.name == "singleplayer" then
			if not WG.Chobby.Configuration.ShowhiddenModopions then
				factionWraper:Hide()
			end
		else
			local a = battleLobby:GetBattle(battleLobby:GetMyBattleID())
			local myBs = battleLobby:GetUserBattleStatus(battleLobby.myUserName) or {}
			if not myBs.isBoss then
				factionWraper:Hide()
			end
		end
	end

end

local function SortPlayersBySkill(a, b)
	local sA = battleLobby:GetUser(a.name)
	local sB = battleLobby:GetUser(b.name)
	local joinA = tonumber((sA and sA.skill) or 0)
	local joinB = tonumber((sB and sB.skill) or 0)
	if tonumber((sA and sA.skillUncertainty) or 0) > 6.65 then
		joinA = 0
	end
	if tonumber((sB and sB.skillUncertainty) or 0) > 6.65 then
		joinB = 0
	end
	return joinA > joinB
end

local function SortPlayersByQueued(a, b)
	local sA = battleLobby:GetUserBattleStatus(a.name)
	local sB = battleLobby:GetUserBattleStatus(b.name)
	local queuePosA = tonumber((sA and sA.queuePos) or 0)
	local queuePosB = tonumber((sB and sB.queuePos) or 0)
	local battle = battleLobby:GetBattle(battleLobby:GetMyBattleID()) or {}
	local founder = battle.founder

	if queuePosA ~= queuePosB then
		return queuePosA < queuePosB
	-- sort normal spectator list by name, founder top
	elseif a.name == founder or b.name == founder then
		return a.name == founder
	end
	return string.lower(a.name) < string.lower(b.name)
end

local function SortTeams(a, b)
	-- use abs to place queued(-1) above specs(-2)
	local teamA = math.abs(tonumber(a.name))
	local teamB = math.abs(tonumber(b.name))
	return teamA < teamB
end

local function SetupPlayerPanel(playerParent, spectatorParent, battle, battleID)

	local SPACING = 24
	local disallowCustomTeams = battle.disallowCustomTeams
	local disallowBots = battle.disallowBots

	local mainScrollPanel = ScrollPanel:New {
		name = 'mainScrollPanel',
		x = 0,
		right = 0,
		y = 1,
		bottom = 0,
		parent = playerParent,
		horizontalScrollbar = false,
	}

	local mainStackPanel = Control:New {
		name = 'mainStackPanel',
		x = 0,
		right = 0,
		y = 0,
		bottom = 0,
		parent = mainScrollPanel,
		preserveChildrenOrder = true,
	}
	mainStackPanel._relativeBounds.bottom = nil
	local spectatorScrollPanel = ScrollPanel:New {
		name = 'spectatorScrollPanel',
		x = 0,
		right = 0,
		y = 0,
		bottom = 0,
		parent = spectatorParent,
		horizontalScrollbar = false,
	}

	local spectatorStackPanel = Control:New {
		name = 'spectatorStackPanel',
		x = 0,
		right = 0,
		y = 0,
		bottom = 0,
		parent = spectatorScrollPanel,
	}
	spectatorStackPanel._relativeBounds.bottom = nil

	-- Object handling
	local player = {}
	local team = {}

	local function PositionChildren(panel, minHeight)
		local children = panel.children
		table.sort(children, SortTeams)

		minHeight = minHeight - 10

		local childrenCount = #children
		local bottomBuffer = 0

		local totalHeight = 0
		local maxHeight = 0
		for i = 1, #children do
			local child = children[i]
			totalHeight = totalHeight + child.height
			if child.height > maxHeight then
				maxHeight = child.height
			end
		end

		if childrenCount * maxHeight + bottomBuffer > minHeight then
			if totalHeight < minHeight then
				totalHeight = minHeight
			end
			panel:SetPos(nil, nil, nil, totalHeight + 0) -- +15
			local runningHeight = 0
			for i = 1, #children do
				local child = children[i]
				child:SetPos(nil, runningHeight)
				child:Invalidate()
				runningHeight = runningHeight + child.height
			end
		else
			panel:SetPos(nil, nil, nil, minHeight)
			for i = 1, #children do
				local child = children[i]
				child:SetPos(nil, math.floor(minHeight * (i - 1)/#children))
				child:Invalidate()
			end
		end
		panel:Invalidate()
	end

	local function GetPlayerData(name)
		if not player[name] then
			player[name] = {
				team = false,
				control = WG.UserHandler.GetBattleUser(name, battleLobby.name == "singleplayer"),
			}
		end
		return player[name]
	end

	local function GetTeam(teamIndex)
		teamIndex = teamIndex or -2 -- default to -2 = Spectator team
		if not team[teamIndex] then
			if teamIndex == emptyTeamIndex then
				local checkTeam = teamIndex + 1
				while team[checkTeam] do
					checkTeam = checkTeam + 1
				end
				emptyTeamIndex = checkTeam
			end

			local humanName, parentStack, parentScroll
			if teamIndex == -1 then
				humanName = "Join-Queue"
				parentStack = spectatorStackPanel
				parentScroll = spectatorScrollPanel
			elseif teamIndex == -2 then
				humanName = "Spectators"
				parentStack = spectatorStackPanel
				parentScroll = spectatorScrollPanel
			else
				if disallowCustomTeams then
					if teamIndex == 0 then
						humanName = "Players"
					else
						humanName = "Bots"
					end
				else
					humanName = "Team " .. (teamIndex + 1)
				end
				parentStack = mainStackPanel
				parentScroll = mainScrollPanel
			end

			local teamHolder = Control:New {
				name = 'teamHolder',
				name = teamIndex,
				x = 0,
				right = 0,
				y = 0,
				height = 50,
				padding = {0, 0, 0, 0},
				parent = parentStack,
			}

			local label = Label:New {
				name = 'label',
				x = 5,
				y = 0,
				width = 120,
				height = 25, --30
				valign = "center",
				objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
				caption = humanName,
				parent = teamHolder,
			}
			if teamIndex ~= -1 and teamIndex ~= -2 then
				local seperator = Line:New {
					name = 'seperator',
					x = 0,
					y = 20, --25
					right = 0,
					height = 2,
					parent = teamHolder
				}

				AddTeamButtons(
					teamHolder,
					90,
					function()
						battleLobby:SetBattleStatus({
								allyNumber = teamIndex,
								isSpectator = false,
							})
					end,
					function (obj, x, y, button)
						local quickAddAi
						if button == 3 and WG.Chobby.Configuration.lastAddedAiName then
							quickAddAi = WG.Chobby.Configuration.lastAddedAiName
						end

						WG.PopupPreloader.ShowAiListWindow(battleLobby, battle.gameName, teamIndex, quickAddAi)
					end,
					disallowCustomTeams and teamIndex ~= 0,
					(disallowBots or disallowCustomTeams) and teamIndex ~= 1,
					teamIndex
				)
			end
			local teamStack = Control:New {
				name = 'teamStack',
				x = 0,
				y = 26, --31
				right = 0,
				objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
				bottom = 0,
				padding = {0, 0, 0, 0},
				parent = teamHolder,
				preserveChildrenOrder = true,
			}

			local labelTeamPlayerCount = Label:New {
				x = -20, -- hand crafted
				y = 0,
				width = 40,
				height = 25, -- same as label (for team names)
				align = "right",
				valign = "center",
				objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
				caption = "0",
				parent = teamHolder,
			}
			local function UpdateTeamPlayerCount()
				labelTeamPlayerCount.caption = string.format("%d", #teamStack.children)
			end

			local function UpdatePlayerPositions()
				if teamIndex ~= -1 and teamIndex ~= -2 then
					table.sort(teamStack.children, SortPlayersBySkill)
				else
					-- Spring.Echo("Sorting teamIndex: " .. tostring(teamIndex))
					table.sort(teamStack.children, SortPlayersByQueued)
				end

				local position = 1

				for i = 1, #teamStack.children do
					teamStack.children[i]:SetPos(nil, position)
					teamStack.children[i]:Invalidate()
					position = position + SPACING
				end
			
				teamHolder:SetPos(nil, nil, nil, position + 30) -- 35
				PositionChildren(parentStack, parentScroll.height)
				teamHolder:Invalidate()
			end

			if teamIndex == -1 or teamIndex == -2 then
				-- Empty spectator team is created. Position children to prevent flicker.
				PositionChildren(parentStack, parentScroll.height)
				teamHolder:SetVisibility(false)
			end

			local teamData = {}

			function teamData.UpdateBattleMode()
				local addAiButton = teamHolder:GetChildByName("addAiButton")
				if addAiButton then
					teamHolder:RemoveChild(addAiButton)
					addAiButton:Dispose()
				end
				local joinTeamButton = teamHolder:GetChildByName("joinTeamButton")
				if joinTeamButton then
					teamHolder:RemoveChild(joinTeamButton)
					joinTeamButton:Dispose()
				end

				if teamIndex ~= -1 and teamIndex ~= -2 then
					AddTeamButtons(
						teamHolder,
						90,
						function()
							battleLobby:SetBattleStatus({
									allyNumber = teamIndex,
									isSpectator = false,
								})
						end,
						function()
							WG.PopupPreloader.ShowAiListWindow(battleLobby, battle.gameName, teamIndex)
						end,
						disallowCustomTeams and teamIndex ~= 0,
						(disallowBots or disallowCustomTeams) and teamIndex ~= 1,
						teamIndex
					)

					if disallowCustomTeams then
						if teamIndex == 0 then
							humanName = "Players"
						elseif teamIndex == 1 then
							humanName = "Bots"
						else
							humanName = "Invalid"
						end
					else
						humanName = "Team " .. (teamIndex + 1)
					end
				end
				label:SetCaption(humanName)
			end

			function teamData.AddPlayer(name)
				local playerData = GetPlayerData(name)
				if playerData.team == teamIndex then
					return
				end
				playerData.team = teamIndex
				local playerControl = playerData.control
				if name == battleLobby:GetMyUserName() then
					local joinTeam = teamHolder:GetChildByName("joinTeamButton")
					if joinTeam then
						joinTeam:SetVisibility(false)
					end
				end
				if not teamStack:GetChildByName(playerControl.name) then
					teamStack:AddChild(playerControl)
					teamHolder:SetVisibility(true)
					UpdatePlayerPositions()
				end
				UpdateTeamPlayerCount()
			end

			function teamData.RemoveTeam()
				if teamIndex < emptyTeamIndex then
					emptyTeamIndex = teamIndex
				end

				team[teamIndex] = nil
				parentStack:RemoveChild(parentStack:GetChildByName(teamIndex))
				teamHolder:Dispose()
			end

			function teamData.CheckRemoval()
				if teamStack:IsEmpty() and teamIndex ~= -2 then

					if disallowCustomTeams then
						if teamIndex > 1 then
							teamData.RemoveTeam()
							return true
						elseif disallowBots and teamIndex > 0 then
							teamData.RemoveTeam()
							return true
						end
					else
						if teamIndex > 1 then
							teamData.RemoveTeam()
							return true
						elseif teamIndex == -1 then
							teamHolder:SetVisibility(false)
							return true
						end
					end
				end
				return false
			end

			function teamData.RemovePlayer(name)
				local playerData = GetPlayerData(name)
				if playerData.team ~= teamIndex or playerData.team == false then
					return
				end
				playerData.team = false

				local playerControl = teamStack:GetChildByName(name)
				if not playerControl then
					return
				end

				teamStack:RemoveChild(playerControl)
				UpdatePlayerPositions()
				
				if name == battleLobby:GetMyUserName() then
					local joinTeam = teamHolder:GetChildByName("joinTeamButton")
					if joinTeam then
						joinTeam:SetVisibility(true)
					end
				end

				teamData.CheckRemoval()
				PositionChildren(parentStack, parentScroll.height)
				UpdateTeamPlayerCount()
			end

			team[teamIndex] = teamData
		end
		return team[teamIndex]
	end

	-- Object modification
	local function AddPlayerToTeam(allyTeamID, name)
		local teamObject = GetTeam(allyTeamID)
		teamObject.AddPlayer(name)
	end

	local function RemovePlayerFromTeam(name)
		local playerData = GetPlayerData(name)
		if playerData.team then
			local teamObject = GetTeam(playerData.team)
			teamObject.RemovePlayer(name)
		end
	end

	GetTeam(-1) -- Make Queue heading appear
	GetTeam(-2) -- Make Spectator heading appear

	GetTeam(0) -- Always show two teams in custom battles
	if not (disallowCustomTeams and disallowBots) then
		GetTeam(1)
	end

	OpenNewTeam = function ()
		if emptyTeamIndex < 254 then
			GetTeam(emptyTeamIndex)
			PositionChildren(mainStackPanel, mainScrollPanel.height)
		end
	end

	mainScrollPanel.OnResize = {
		function (obj)
			PositionChildren(mainStackPanel, mainScrollPanel.height)
		end
	}
	spectatorScrollPanel.OnResize = {
		function ()
			PositionChildren(spectatorStackPanel, spectatorScrollPanel.height)
		end
	}

	local externalFunctions = {}

	function externalFunctions.UpdateBattleMode(newDisallowCustomTeams, newDisallowBots)
		disallowCustomTeams = newDisallowCustomTeams
		disallowBots = newDisallowBots

		if not (disallowCustomTeams and disallowBots) then
			GetTeam(1)
			PositionChildren(mainStackPanel, mainScrollPanel.height)
		end
		for teamIndex, teamData in pairs(team) do
			if not teamData.CheckRemoval() then
				teamData.UpdateBattleMode()
			end
		end
	end

	function externalFunctions.UpdateUserTeamStatus(userName, teamNew, isSpectator, queuePos)
		if isSpectator then
			if (queuePos and queuePos > 0) then
				teamNew = -1 -- virtual team "Join-Queue"
			else
				teamNew = -2 -- virtual team "Spectator"
			end
		end
		local playerData = GetPlayerData(userName)
		if playerData.team == teamNew then
			return -- team didn't change, so don't update
		end
		if playerData.team ~= false then
			RemovePlayerFromTeam(userName)
		end
		AddPlayerToTeam(teamNew, userName)
	end

	function externalFunctions.LeftBattle(leftBattleID, userName)
		if leftBattleID == battleID then
			RemovePlayerFromTeam(userName)
		end
	end

	function externalFunctions.RemoveAi(botName)
		RemovePlayerFromTeam(botName)
	end

	function externalFunctions.GetTeam(index)
		if(index >= emptyTeamIndex)then
			OpenNewTeam()
		end
		return GetTeam(index)
	end

	return externalFunctions
end

local function SetupVotePanel(votePanel, battle, battleID)
	local height = votePanel.clientHeight
	local config = WG.Chobby.Configuration
	local offset = 0

	local buttonYesClickOverride
	local buttonNoClickOverride
	-- local matchmakerModeEnabled = false

	local currentMapName

	local minimapPanel = Panel:New {
		name = 'minimapPanel',
		x = 0,
		y = 0,
		bottom = 0,
		width = height,
		padding = {1,1,1,1},
		parent = votePanel,
	}
	local btnMinimap = Button:New {
		name = 'btnMinimap',
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		classname = "option_button",
		caption = "",
		objectOverrideFont = WG.Chobby.Configuration:GetButtonFont(10),
		parent = minimapPanel,
		padding = {1,1,1,1},
		OnClick = {
			function ()
				if currentMapName and config.gameConfig.link_particularMapPage ~= nil then
					WG.BrowserHandler.OpenUrl(config.gameConfig.link_particularMapPage(currentMapName))
				end
			end
		},
	}
	local imMinimap = Image:New {
		name = 'imMinimap',
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		keepAspect = true,
		parent = btnMinimap,
	}

	local activePanel = Control:New {
		name = 'activePanel',
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		padding = {0, 0, 0, 0},
		parent = votePanel,
	}

	local buttonNo
	local buttonYes = Button:New {
		name = 'buttonYes',
		x = offset,
		y = 0,
		bottom = 0,
		width = height,
		caption = "",
		noFont = true,
		classname = "positive_button",
		tooltip = "Vote YES on the current poll",
		OnClick = {
			function (obj)
				ButtonUtilities.SetButtonSelected(obj)
				ButtonUtilities.SetButtonDeselected(buttonNo)
				if buttonYesClickOverride then
					buttonYesClickOverride()
				else
					battleLobby:VoteYes()
				end
			end
		},
		padding = {10,10,10,10},
		children = {
			Image:New {
				name = 'buttonYes',
				x = 0,
				y = 0,
				right = 0,
				bottom = 0,
				autosize = true,
				file = IMG_READY,
			}
		},
		parent = activePanel,
	}
	offset = offset + height

	buttonNo = Button:New {
		name = 'buttonNo',
		x = offset,
		y = 0,
		bottom = 0,
		width = height,
		caption = "",
		noFont = true,
		classname = "negative_button",
		tooltip = "Vote NO on the current poll",
		OnClick = {
			function (obj)
				ButtonUtilities.SetButtonSelected(obj)
				ButtonUtilities.SetButtonDeselected(buttonYes)
				if buttonNoClickOverride then
					buttonNoClickOverride()
				else
					battleLobby:VoteNo()
				end
			end
		},
		padding = {10,10,10,10},
		children = {
			Image:New {
				x = 0,
				y = 0,
				right = 0,
				bottom = 0,
				file = IMG_UNREADY,
			}
		},
		parent = activePanel,
	}
	offset = offset + height

	offset = offset + 2

	local voteName = Label:New {
		name = 'voteName',
		x = offset,
		y = 4,
		width = 50,
		bottom = height * 0.4,
		objectOverrideFont = config:GetFont(2),
		caption = "",
		parent = activePanel,
	}

	local voteProgressNo = Progressbar:New {
		name = 'voteProgressNo',
		x = offset,
		y = height * 0.90,
		right = 55,
		bottom = 0,
		value = 0,
		parent = activePanel,
		tooltip = "How many players have voted yes out of the required number have voted to pass",
		color     = {1, 0, 0, 1},
		noFont = true,
	}

	local voteProgressYes = Progressbar:New {
		name = 'voteProgressYes',
		x = offset,
		y = height * 0.80,
		right = 55,
		bottom = height * 0.10,
		value = 0,
		parent = activePanel,
		tooltip = "How many players have voted no out of the required number have voted to fail",
		color     = {0, 1, 0, 1},
		noFont = true,
	}

	local voteCountLabel = Label:New {
		name = 'voteCountLabel',
		right = 5,
		y = height * 0.5,
		width = 50,
		bottom = 0,
		align = "left",
		objectOverrideFont = config:GetFont(2),
		caption = "20/50",
		parent = activePanel,
		tooltip = "How many votes have been cast (#yes / #needed)",
	}



	local function ResetButtons()
		ButtonUtilities.SetButtonDeselected(buttonYes)
		ButtonUtilities.SetButtonDeselected(buttonNo)
	end

	local voteResultLabel = Label:New {
		name = 'voteResultLabel',
		x = 5,
		y = 4,
		right = 0,
		bottom = height * 0.4,
		align = "left",
		objectOverrideFont = config:GetFont(2),
		caption = "",
		parent = votePanel,
	}

	activePanel:SetVisibility(false)
	minimapPanel:SetVisibility(false)
	voteResultLabel:SetVisibility(false)

	local function HideVoteResult()
		if voteResultLabel.visible then
			voteResultLabel:Hide()
		end
		--if not spadsStatusPanel.visible then
		--Spring.Echo("HideVoteResult")
		if barManagerPresent then spadsStatusPanel:SetVisibility(true) end
		--end
	end

	local externalFunctions = {}

	local oldPollType, oldMapPoll, oldPollUrl
	local function UpdatePollType(pollType, mapPoll, pollUrl)
		--Spring.Echo("UpdatePollType(pollType, mapPoll, pollUrl)", pollType, mapPoll, pollUrl)
		if mapPoll then
			minimapPanel:SetVisibility(true)
		end
		if oldPollType == pollType and oldMapPoll == mapPoll and oldPollUrl == pollUrl then
			return
		end
		oldPollType, oldMapPoll, oldPollUrl = pollType, mapPoll, pollUrl

		if mapPoll then
			activePanel:SetPos(height + 2)
			activePanel._relativeBounds.right = 0
			activePanel:UpdateClientArea()
			if pollUrl then
				imMinimap.file, imMinimap.checkFileExists = config:GetMinimapSmallImage(pollUrl)
				imMinimap:Invalidate()
				currentMapName = pollUrl
			end
		else
			minimapPanel:SetVisibility(false)
			activePanel:SetPos(0)
			activePanel._relativeBounds.right = 0
			activePanel:UpdateClientArea()
		end
	end

	local oldVoteInitiator = ""
	local oldTitle = ""

	function externalFunctions.VoteUpdate(voteMessage, pollType, mapPoll, candidates, votesNeeded, pollUrl, voteInitiator, resetButtons)
		--Spring.Echo("externalFunctions.VoteUpdate(voteMessage, pollType, mapPoll, candidates, votesNeeded, pollUrl, voteInitiator)",voteMessage, pollType, mapPoll, candidates, votesNeeded, pollUrl, voteInitiator)
		UpdatePollType(pollType, mapPoll, pollUrl)

		if voteInitiator then oldVoteInitiator = voteInitiator end
		-- Update votes

		buttonYesClickOverride = candidates[1].clickFunc
		buttonNoClickOverride = candidates[2].clickFunc
		timeleft = ''
		if candidates[1].timeleft then
			timeleft = ' ('..timeleft..'s)'
		end
		oldTitle = oldVoteInitiator.. " called a vote for:\n"..voteMessage..timeleft

		voteName:SetCaption(oldTitle)
		if votesNeeded == -1 then 
			voteCountLabel:SetCaption(tostring(candidates[1].votes))
			voteProgressYes:SetValue(0)
			voteProgressNo:SetValue(0)
		else
			voteCountLabel:SetCaption(candidates[1].votes .. "/" .. votesNeeded)
			voteProgressYes:SetValue(100 * candidates[1].votes / votesNeeded)
			voteProgressNo:SetValue( 100 * candidates[2].votes / votesNeeded)
		end

		activePanel:SetVisibility(true)
		spadsStatusPanel:SetVisibility(false)
		spadsStatusPanel:Invalidate()

		if resetButtons then
			ResetButtons()
			externalFunctions.VoteButtonVisible(true)
		end
		-- matchmakerModeEnabled = (pollType == "quickplay")
		--HideVoteResult()
	end

	local function HideVotedUsers()
		WG.LibLobby.lobby:_OnUserVoted(_, "default")
	end

	function externalFunctions.VoteEnd(message, success)
		activePanel:SetVisibility(false)
		minimapPanel:SetVisibility(false)
		if message then oldTitle = message end
		local text = ((success and WG.Chobby.Configuration:GetSuccessColor()) or WG.Chobby.Configuration:GetErrorColor()) .. oldTitle .. ((success and " Passed.") or " Failed.")
		voteResultLabel:SetCaption(text)
		if not voteResultLabel.visible then
			voteResultLabel:Show()
		end

		-- matchmakerModeEnabled = false
		ResetButtons()
		WG.Delay(HideVoteResult, 3)
		WG.Delay(HideVotedUsers, 3)

	end

	function externalFunctions.ImmediateVoteEnd()
		activePanel:SetVisibility(false)
		minimapPanel:SetVisibility(false)
		if barManagerPresent then spadsStatusPanel:SetVisibility(true) end
		-- matchmakerModeEnabled = false
		ResetButtons()
		HideVoteResult()
		HideVotedUsers()
	end

	function externalFunctions.VoteButtonVisible(visible)
		--Spring.Echo("VoteButtonVisible(visible)",visible)
		buttonNo:SetVisibility(visible)
		buttonYes:SetVisibility(visible)
	end

	--[[
	function externalFunctions.GetMatchmakerMode()
		return matchmakerModeEnabled
	end
	--]]

	function externalFunctions.visible()
		return activePanel.visible
	end

	return externalFunctions
end

local function SetupSpadsStatusPanel(battle, battleID)

	local freezeSettings = true

	local spadsSettingsOrder = {'teamSize','nbTeams','preset','autoBalance','balanceMode','locked'}
	spadsSettingsTable = {
		teamSize = {
			current = "2",
			allowed = {"1","2","3","4","5","6","7","8"},
			caption = "TeamSize",
			tooltip = "How many players should be on each team",
			spadscommand = "!set teamSize",
		},
		nbTeams = {
			current = "2",
			allowed = {"1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16"},
			caption = "#Teams",
			tooltip = "How many teams should SPADS make",
			spadscommand = "!nbTeams",
		},
		preset = {
			current = "team",
			allowed = {"team","ffa","coop","duel","tourney","custom"},
			caption = "Preset",
			tooltip = "Team - Game of multiple Teams\nFFA - Free-For-All\nCoop - Humans vs AI\nDuel - 1v1\nCustom - For custom battles",
			spadscommand = "!preset",
		},
		autoBalance = {
			current = "off",
			allowed = {"off","advanced"},
			caption = "Autobalance",
			tooltip = "Balance teams and fix IDs automatically.\nUse Coop preset to play vs AIs.",
			spadscommand = "!autobalance",
		},
		balanceMode = {
			current = "skill",
			allowed = {"skill","clan;skill","random"},
			caption = "BalanceMode",
			tooltip = "Method to use when auto balancing teams",
			spadscommand = "!balanceMode",
		},
		locked = {
			current = "unlocked",
			allowed = {"unlocked","locked"},
			caption = "Locked",
			tooltip = "Is the game locked?",
			spadscommand = {unlocked = "!unlock", locked = "!lock"},
		},
		--[[
		boss = {
			current = "None",
			allowed = {"None"},
			caption = "Boss",
			tooltip = "Is there a boss currently set",
			spadscommand = "!boss",
		},
		stop = {
			current = "stopped",
			allowed = {"stopped","running"},
			caption = "Stop",
			tooltip = "Select stop to stop the game",
			spadscommand = "!stop",
		},
		autoLock = { -- key is spads setting name
			current = "off",
			allowed = {"off","on","advanced"},
			caption = "Autolock",
			tooltip = "If the battle must be locked when the target number of players are reached",
			spadscommand = "!autolock",
		},
		autoStart = {
			current = "off",
			allowed = {"off","on","advanced"},
			caption = "Autostart",
			tooltip = "Start game automatically if target number of players is reached",
			spadscommand = "!autostart",
		},
		autoFixColors = { 
			current = "off",
			allowed = {"off","on","advanced"},
			caption = "Autofixcolors",
			tooltip = "Automatically choose colors based on number of players",
			spadscommand = "!autofixcolors",
		},
		clanMode = { 
			current = "off",
			allowed = {"off","on","advanced"},
			caption = "ClanMode",
			tooltip = "Do not touch",
			spadscommand = "!clanMode",
		},
		--]]
	}


	local rows = 3
	local cols = 3
	local i = 0
	for j, k in ipairs(spadsSettingsOrder) do
		local sts = spadsSettingsTable[k]
		local xpos = tostring(math.fmod(i,cols) * 100/cols) ..'%'
		local stslabel = Label:New {
			name = 'stslabel'..tostring(j),
			x = tostring(math.fmod(i,cols) * 100/cols + 1) ..'%',
			y = tostring(math.floor(i/cols) * 100/rows + 1) ..'%',
			width = tostring(100.0/cols -2 ) ..'%',
			height = tostring(100.0/rows -2) ..'%',
			objectOverrideFont = WG.Chobby.Configuration:GetFont(8),
			align = "left",
			valign = "center",
			parent = spadsStatusPanel,
			caption = sts.caption,
			tooltip = sts.tooltip
		}

		local stsCBdefault = sts.current
		local stsCB = ComboBox:New{
			name = 'stsCB'..tostring(j),
			x = tostring(50/cols + math.fmod(i,cols) * 100/cols + 1 ) ..'%',
			y = tostring(math.floor(i/cols) * 100/rows + 1) ..'%',
			width = tostring(50.0/cols - 2) ..'%',
			height = tostring(100.0/rows - 2) ..'%',
			itemHeight = 22,
			selectByName = true,
			captionHorAlign = -1,
			text = "winkydink",
			objectOverrideFont = WG.Chobby.Configuration:GetFont(8),
			items = sts.allowed,
			align = "right",
			valign = "center",
			name = k,
			selected = stsCBdefault,
			OnSelectName = {
				function (obj, selectedName)
					if freezeSettings then return end -- so these funcs dont run on first init
					if type(sts.spadscommand) == "table" then
						battleLobby:SayBattle(sts.spadscommand[selectedName])
					else
						battleLobby:SayBattle(sts.spadscommand .." "..selectedName)
					end
				end
			},
			parent = spadsStatusPanel,
			tooltip = sts.tooltip,
		}
		sts.control = stsCB
		i = i+1
	end

	local balanceButton = Button:New {
		name = 'balanceButton',
		x = '1%',
		y = '68%',
		width = '31%',
		height = '31%',
		caption = "Balance",
		tooltip = "Attempt to balance the teams. In Coop Preset this splits Humans and AIs.",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		parent = spadsStatusPanel,
		classname = "button_small",
		OnClick = {
			function()
				battleLobby:SayBattle('!balance')
			end
		},
	}

	local lockButton = Button:New {
		name = 'lockButton',
		x = '34%',
		y = '68%',
		width = '31%',
		height = '31%',
		caption = "Lock",
		tooltip = "Lock the battleroom, preventing everyone from joining",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		parent = spadsStatusPanel,
		classname = "button_small",
		OnClick = {
			function()
				battleLobby:SayBattle('!lock')
			end
		},
	}

	local unlockButton = Button:New {
		name = 'unlockButton',
		x = '67%',
		y = '68%',
		width = '31%',
		height = '31%',
		caption = "Unlock",
		tooltip = "Unlock the battleroom, to allow players to join",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		parent = spadsStatusPanel,
		classname = "button_small",
		OnClick = {
			function()
				battleLobby:SayBattle('!unlock')
			end
		},
	}
	freezeSettings = false
end

local function InitializeSetupPage(subPanel, screenHeight, pageConfig, nextPage, prevPage, selectedOptions, ApplyFunction)
	local Configuration = WG.Chobby.Configuration

	local buttonScale, buttonHeight, buttonFont = 80, 70, 3
	if screenHeight < 900 then
		buttonScale = 57
		buttonHeight = 56
		buttonFont = 3
	end

	subPanel:SetVisibility(not prevPage)

	local titleLabel = Label:New {
		name = 'titleLabel',
		x = "36%",
		right = "36%",
		y = 20,
		height = 30,
		align = "center",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		caption = pageConfig.humanName,
		parent = subPanel,
	}

	local options = pageConfig.options
	if pageConfig.getDynamicOptions then
		options = pageConfig.getDynamicOptions(selectedOptions)
	end
	if not options then
		Spring.Echo("No options available for page", pageConfig.name)
		options = {}
	end
	local numOptions = #options

	local nextButton = Button:New {
		name = 'nextButton',
		x = "36%",
		right = "36%",
		bottom = "4%",
		height = buttonHeight,
		classname = (nextPage and "action_button") or "ready_button",
		caption = (nextPage and "Next") or i18n("start"),
		objectOverrideFont = WG.Chobby.Configuration:GetFont(buttonFont),
		OnClick = {
			function(obj)
				if nextPage then
					subPanel:SetVisibility(false)
					WG.Analytics.SendOnetimeEvent("lobby:singleplayer:skirmish:" .. pageConfig.name, selectedOptions[pageConfig.name])
					nextPage:SetVisibility(true)
				else
					WG.Analytics.SendOnetimeEvent("lobby:singleplayer:skirmish:" .. pageConfig.name, selectedOptions[pageConfig.name])
					WG.Analytics.SendOnetimeEvent("lobby:singleplayer:skirmish:start_quick")
					ApplyFunction(true)
				end
			end
		},
		parent = subPanel,
	}
	if not nextPage then
		nextButton:StyleReady()
	end
	nextButton:Hide()

	local tipTextBox
	if pageConfig.tipText then
		tipTextBox = Label:New {
			name = 'tipTextBox',
			x = "6%",
			y = 3*buttonScale + 20 + numOptions*buttonScale,
			right = "5%",
			height = 200,
			align = "center",
			objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
			objectOverrideHintFont = WG.Chobby.Configuration:GetFont(2),
			caption = pageConfig.tipText,
			parent = subPanel,
		}
		tipTextBox:Hide()
	end

	local advButton = Button:New {
		name = 'advButton',
		x = "78%",
		right = "5%",
		bottom = "4%",
		height = 48,
		classname = "option_button",
		caption = "Advanced",
		tooltip = i18n("advanced_button_tooltip"),
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		OnClick = {
			function(obj)
				WG.Analytics.SendOnetimeEvent("lobby:singleplayer:skirmish:advanced")
				subPanel:SetVisibility(false)
				ApplyFunction(false)
			end
		},
		parent = subPanel,
	}

	if prevPage then
		Button:New {
			name = 'prevPage',
			x = "5%",
			right = "78%",
			bottom = "4%",
			height = 48,
			classname = "option_button",
			caption = "Back",
			objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
			OnClick = {
				function(obj)
					subPanel:SetVisibility(false)
					prevPage:SetVisibility(true)
				end
			},
			parent = subPanel,
		}
	end

	local function GenerateSimpleSkirmishButtons(pageConfig, selectedOptions, nextButton)
		local buttons = {}
		local options = pageConfig.options
		local tipTextBox = selectedOptions.currentControl:GetChildByName('tipTextBox')
		if pageConfig.getDynamicOptions then
			options = pageConfig.getDynamicOptions(selectedOptions)
		end
		if not options then
			Spring.Echo("Simple Skirmish: No options available for page ", pageConfig.name)
			return {}
		end

		for i = 1, #options do
			local x, y, right, height, caption, tooltip
			local mapImageFile, needDownload = Configuration:GetMinimapImage(options[i])
			local haveMap = VFS.HasArchive(options[i])
			local mapButtonCaption = nil
			if pageConfig.minimap then
				WG.DownloadHandler.MaybeDownloadArchive(options[i], "map", -1)
				if i%2 == 1 then
					x, y, right, height = "25%", (i + 1)*buttonScale - 10, "51%", 2*buttonHeight
				else
					x, y, right, height = "51%", i*buttonScale - 10, "25%", 2*buttonHeight
				end
				caption = ""
			else
				x, y, right, height = "36%", buttonHeight - 4 + i*buttonScale, "36%", buttonHeight
				caption = options[i]
			end
			if not haveMap then
				mapButtonCaption = i18n("click_to_download_map")
			else
				mapButtonCaption = i18n("click_to_pick_map")
			end
			buttons[i] = Button:New {
				x = x,
				y = y,
				right = right,
				height = height,
				classname = "button_simple",
				caption = caption,
				objectOverrideFont = WG.Chobby.Configuration:GetFont(buttonFont),
				tooltip = (pageConfig.optionTooltip and pageConfig.optionTooltip[i]) or (pageConfig.minimap and MINIMAP_TOOLTIP_PREFIX .. options[i] .. "|" .. mapButtonCaption),
				OnClick = {
					function(obj)
						for j = 1, #buttons do
							if j ~= i then
								ButtonUtilities.SetButtonDeselected(buttons[j])
							end
						end
						ButtonUtilities.SetButtonSelected(obj)
						selectedOptions[pageConfig.name] = i
						if pageConfig.name == "gameType" and selectedOptions.currentControl then
							Spring.Echo("Simple Skirmish: Selected game type: " .. options[i])
							local mapPage
							for _, page in ipairs(selectedOptions.pages) do
								if page.name == "map" then
									mapPage = page
									break
								end
							end
							if mapPage and mapPage.getDynamicOptions then
								local nextButton = selectedOptions.currentControl:GetChildByName('nextButton')
								selectedOptions.gameType = i
								local children = selectedOptions.currentControl.children
								for j = #children, 1, -1 do
									local child = children[j]
									if child.name:find("nextButton") or child.name:find("tipTextBox") or child.name:find("advButton") or child.name:find("prevPage") or child.name:find("titleLabel") then
										-- Leave these buttons alone
									else
										selectedOptions.currentControl:RemoveChild(child)
									end
								end
								local newButtons = GenerateSimpleSkirmishButtons(mapPage, selectedOptions, nextButton)
								for _, button in ipairs(newButtons) do
									selectedOptions.currentControl:AddChild(button)
								end
							end
						elseif pageConfig.name == "difficulty" then
							Spring.Echo("Simple Skirmish: Selected difficulty: " .. options[i])
						elseif pageConfig.name == "map" then
							Spring.Echo("Simple Skirmish: Selected map: " .. options[i])
							WG.DownloadHandler.MaybeDownloadArchive(options[i], "map", -1)
						end
						nextButton:SetVisibility(true)
						if tipTextBox then
							tipTextBox:SetVisibility(true)
						end
					end
				},
				parent = subPanel,
			}
			if pageConfig.minimap then
				local imMinimap = Image:New {
					x = 0,
					y = 0,
					right = 0,
					bottom = 0,
					keepAspect = true,
					file = mapImageFile,
					fallbackFile = Configuration:GetLoadingImage(2),
					checkFileExists = needDownload,
					parent = buttons[i],
				}
			else
				if i == 1  then
					if pageConfig.name ~= "faction" then
						ButtonUtilities.SetButtonSelected(buttons[i])
						selectedOptions[pageConfig.name] = i
					end
					nextButton:SetVisibility(true)
				end
			end
		end
		return buttons
	end
	GenerateSimpleSkirmishButtons(pageConfig, selectedOptions, nextButton)
	return subPanel
end

local function SetupEasySetupPanel(mainWindow, standardSubPanel, setupData)
	local pageConfigs = setupData.pages
	local selectedOptions = {
		pages = pageConfigs,
		currentControl = nil
	}

	local function ApplyFunction(startGame)
		local battle = battleLobby:GetBattle(battleLobby:GetMyBattleID())
		setupData.ApplyFunction(battleLobby, selectedOptions)
		if startGame then
			if haveMapAndGame then
				local Configuration = WG.Chobby.Configuration
					if Configuration.gameConfig.mapStartBoxes.singleplayerboxes then
						if currentStartRects ~= {} then
							Configuration.gameConfig.mapStartBoxes.singleplayerboxes = currentStartRects
						end
					end
				WG.SteamCoopHandler.AttemptGameStart("skirmish", battle.gameName, battle.mapName, nil, true)
			else
				MaybeDownloadMap(battle)
				WG.Chobby.InformationPopup("You do not have the map for this skirmish, check your downloads tab to see the download progress.", {caption = "OK"})
				return
			end
		else
			standardSubPanel:SetVisibility(true)
		end
	end

	local _, screenHeight = Spring.GetWindowGeometry()
	local panelOffset = math.max(8, math.min(60, ((screenHeight - 768)*0.16 + 8)))

	local pages = {}
	for i = 1, #pageConfigs do
		pages[i] = Control:New {
			name = 'pageConfigs'..tostring(i),
			x = 0,
			y = panelOffset,
			right = 0,
			bottom = 0,
			padding = {0, 0, 0, 0},
			parent = mainWindow,
		}
		if pageConfigs[i].name == "map" then
			selectedOptions.currentControl = pages[i]
		end
	end

	for i = 1, #pages do
		InitializeSetupPage(pages[i], screenHeight, pageConfigs[i], pages[i + 1], pages[i - 1], selectedOptions, ApplyFunction)
	end
end

local function InitializeControls(battleID, oldLobby, topPoportion, setupData)
	local battle = battleLobby:GetBattle(battleID)

	if not battle then
		Spring.Echo("Attempted to join missing battle", battleID, topPoportion)
		return false
	end

	local Configuration = WG.Chobby.Configuration
	-- if not Configuration.showMatchMakerBattles and battle.isMatchMaker then
	-- 	return
	-- end

	local isSingleplayer = (battleLobby.name == "singleplayer")
	showDefaultStartCheckbox = isSingleplayer
	local isHost = (not isSingleplayer) and (battleLobby:GetMyUserName() == battle.founder)

	local EXTERNAL_PAD_VERT = 9
	local EXTERNAL_PAD_HOR = 12
	local INTERNAL_PAD = 2

	local BOTTOM_SPACING = 96
	if isSingleplayer then BOTTOM_SPACING = 5 end

	mainWindow = Control:New {
		name = 'mainWindow',
		x = 0,
		y = 0,
		width = "100%",
		height = "100%",
		resizable = false,
		padding = {0, 0, 0, 0},
	}

	local subPanel = Control:New {
		name = 'subPanel',
		x = 0,
		y = 47,
		right = 0,
		bottom = 0,
		padding = {0, 0, 0, 0},
		parent = mainWindow,
	}
	if setupData and Configuration.simplifiedSkirmishSetup then
		subPanel:SetVisibility(false)
		SetupEasySetupPanel(mainWindow, subPanel, setupData)
	end

	local topPanel = Control:New {
		name = 'topPanel',
		x = 0,
		y = 0,
		right = 0,
		bottom = (100 - topPoportion) .. "%",
		padding = {0, 0, 0, 0},
		parent = subPanel,
	}

	local bottomPanel = Control:New {
		name = 'bottomPanel',
		x = 0,
		y = topPoportion .. "%",
		right = 0,
		bottom = 0,
		padding = {0, 0, 0, 0},
		parent = subPanel,
	}

	local playerPanel = Control:New {
		name = 'playerPanel',
		x = 0,
		y = 0,
		right = "52%",
		bottom = BOTTOM_SPACING,
		padding = {EXTERNAL_PAD_HOR, EXTERNAL_PAD_VERT, INTERNAL_PAD, 0},
		parent = topPanel,
	}

	local spectatorPanel = Control:New {
		name = 'spectatorPanel',
		x = "67%",
		y = 0,
		right = 0,
		bottom = 0,
		-- Add 7 to line up with chat
		padding = {INTERNAL_PAD, INTERNAL_PAD, EXTERNAL_PAD_HOR, EXTERNAL_PAD_VERT + 7},
		parent = bottomPanel,
	}

	playerHandler = SetupPlayerPanel(playerPanel, spectatorPanel, battle, battleID)


	spadsStatusPanel = Control:New{
		name = 'spadsStatusPanel',
		x = 0,
		right = "33%",
		bottom = 0,
		height = BOTTOM_SPACING,
		padding = {EXTERNAL_PAD_HOR, INTERNAL_PAD, 1, INTERNAL_PAD},
		parent = topPanel,
		backgroundColor = {1,1,1,0.5},
	}

	--spadsStatusPanel = 
	SetupSpadsStatusPanel() -- git stash for scumbags
	spadsStatusPanel:SetVisibility(not isSingleplayer) -- start hidden

	local votePanel = Control:New {
		name = 'votePanel',
		x = 0,
		right = "33%",
		bottom = 0,
		height = BOTTOM_SPACING,
		padding = {EXTERNAL_PAD_HOR, INTERNAL_PAD, 1, INTERNAL_PAD},
		parent = topPanel,
	}



	local votePanel = SetupVotePanel(votePanel)

	local leftInfo = Control:New {
		name = 'leftInfo',
		x = "48%",
		y = 0,
		right = "33%",
		bottom = BOTTOM_SPACING,
		padding = {INTERNAL_PAD, EXTERNAL_PAD_VERT, 1, INTERNAL_PAD},
		parent = topPanel,
	}

	local rightInfo = Control:New {
		name = 'rightInfo',
		x = "67%",
		y = 0,
		right = 0,
		bottom = 0,
		padding = {1, EXTERNAL_PAD_VERT, EXTERNAL_PAD_HOR, INTERNAL_PAD},
		parent = topPanel,
	}

	local infoHandler = SetupInfoButtonsPanel(leftInfo, rightInfo, battle, battleID, battleLobby:GetMyUserName())

	local btnQuitBattle = Button:New {
		name = 'btnQuitBattle',
		right = 12,
		y = 7,
		width = (isSingleplayer and 80) or 160,
		height = 45,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		caption = (isSingleplayer and i18n("close")) or i18n("leave_lobby"),
		classname = "negative_button",
		tooltip = (isSingleplayer and "Close the battleroom") or "Leave the multiplayer battleroom",
			OnClick = {
				function()
					battleLobby:LeaveBattle()
					if WG and WG.Chobby and WG.Chobby.interfaceRoot and WG.Chobby.interfaceRoot.OpenMultiplayerTabByName and not isSingleplayer then
						WG.Chobby.interfaceRoot.OpenMultiplayerTabByName("multiplayer")
					end
				end
			},
			parent = mainWindow,
	}

	local btnInviteFriends = Button:New {
		name = 'btnInviteFriends',
		right = 101,
		y = 7,
		width = 180,
		height = 45,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		caption = i18n("invite_friends"),
		classname = "option_button",
		OnClick = {
			function()
				WG.SteamHandler.OpenFriendList()
			end
		},
		parent = mainWindow,
	}
	btnInviteFriends:SetVisibility(Configuration.canAuthenticateWithSteam)

	local battleTitle = ""
	local btnBattleTitle = Button:New {
		name = "btnBattleTitle",
		x = (battleLobby.name == "singleplayer") and 20 or 13,
		y = 7,
		right = (battleLobby.name ~= "singleplayer") and 180 or nil,
		width = (battleLobby.name == "singleplayer") and 146 or nil,
		height = 45,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		caption = "",
		tooltip = "",
		classname = "option_button",
		parent = mainWindow,
		OnResize = {
			function (obj)
				if battleLobby.name == "singleplayer" then
					obj.backgroundColor = {0, 0, 0, 0}
					obj.focusColor = {0, 0, 0, 0}
					obj.suppressButtonReaction = true
					obj.tooltip = nil
				else
					obj.backgroundColor = {0.65, 0.65, 0.65, 0.75}
					obj.focusColor  = {0.05, 0.58, 1.0, 1.0}
					obj.suppressButtonReaction = false
					obj.tooltip = i18n("rename_tooltip")
				end
				obj:SetCaption(StringUtilities.GetTruncatedStringWithDotDot(battleTitle, obj.font, obj.width))
			end
		},
		OnClick = {
			function ()
				if battleLobby.name ~= "singleplayer" then
					if WG.TextEntryWindow then
						WG.TextEntryWindow.CreateTextEntryWindow({
							defaultValue = battleTitle:gsub("(.*)|.*$", "%1"):gsub("%s*$", ""),
							caption = i18n("rename_battle"),
							labelCaption = i18n("rename_caption"),
							hint = i18n("rename_hint"),
							height = 280,
							width = 550,
							oklabel = i18n("rename"),
							OnAccepted = function(newname)
								lobby:SayBattle("!rename " .. newname)
							end,
							OnOpen = function(editBox)
								editBox:SelectAll()
							end
						})
					end
				end
			end
		}
	}

	local battleTypeCombo
	if isHost then
		battleTypeCombo = ComboBox:New {
			name = 'battleTypeCombo',
			x = 13,
			width = 125,
			y = 12,
			height = 35,
			itemHeight = 22,
			selectByName = true,
			captionHorAlign = -12,
			text = "",
			objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
			items = {"Coop", "Team", "1v1", "FFA", "Custom"},
			selected = Configuration.battleTypeToHumanName[battle.battleMode or 0],
			OnSelectName = {
				function (obj, selectedName)
					if battleTypeCombo then
						battleLobby:SetBattleType(selectedName)
					end
				end
			},
			parent = mainWindow,
		}
		btnBattleTitle:BringToFront()
	end

	local function UpdateBattleTitle()
		if isSingleplayer then
			battleTitle = tostring(battle.title)
			local truncatedTitle = StringUtilities.GetTruncatedStringWithDotDot(battleTitle, btnBattleTitle.font, btnBattleTitle.width)
			btnBattleTitle:SetCaption(truncatedTitle)
			return
		end
		if Configuration.allEnginesRunnable or Configuration:IsValidEngineVersion(battle.engineVersion) then
			if battleTypeCombo then
				btnBattleTitle:SetPos(143)
				btnBattleTitle._relativeBounds.right = 100
				btnBattleTitle:UpdateClientArea()

				battleTypeCombo:SetVisibility(true)
				battleTypeCombo.selected = Configuration.battleTypeToHumanName[battle.battleMode or 0]
				battleTypeCombo.caption = Configuration.battleTypeToHumanName[battle.battleMode or 0]
				battleTypeCombo:Invalidate()
			end

			local battleTypeName = Configuration.battleTypeToName[battle.battleMode]
			if isHost then
				battleTitle = ": " .. tostring(battle.title)
			elseif battleTypeName then
				battleTitle = i18n(battleTypeName) .. ": " .. tostring(battle.title)
			else
				battleTitle = tostring(battle.title)
			end

			local truncatedTitle = StringUtilities.GetTruncatedStringWithDotDot(battleTitle, btnBattleTitle.font, math.max(btnBattleTitle.width, 250))
			btnBattleTitle:SetCaption(truncatedTitle)
		else
			battleTitle = "\255\255\0\0Warning: Restart to get correct engine version"
			if battleTypeCombo then
				btnBattleTitle:SetPos(20)
				btnBattleTitle._relativeBounds.right = 100
				btnBattleTitle:UpdateClientArea()
				battleTypeCombo:SetVisibility(false)
			end
			local truncatedTitle = StringUtilities.GetTruncatedStringWithDotDot(battleTitle, btnBattleTitle.font, btnBattleTitle.width)
			btnBattleTitle:SetCaption(truncatedTitle)
		end
	end
	UpdateBattleTitle()

	local function MessageListener(message)
		if message:starts("/me ") then
			battleLobby:SayBattleEx(message:sub(5))
		else
			battleLobby:SayBattle(message)
		end
	end

	if battleLobby.name == "singleplayer" then
		local realMessageListener = MessageListener
		MessageListener = function(message)
			if message:find("!bset ") then
				local cmdCounter = 0
				local modoptions = battleLobby:GetMyBattleModoptions()
				for line in message:gmatch("[^\n]+") do
					if line:starts("!bset ") then
						local key, value = line:match("^!bset%s+([%a_][%w_]*)%s+(.*%S)%s*$")
						if key and value then
							modoptions[key] = value
							cmdCounter = cmdCounter + 1
						else
							battleLobby:SayBattleEx("\255\128\128\255Malformed bset:  \255\255\128\128" .. line)
						end
					end
				end
				if cmdCounter > 0 then
					battleLobby:SetModOptions(modoptions)
					battleLobby:SayBattleEx(
						"\255\128\128\255"..-- My Cool Blue™ (it purple)
						"Applied: "..cmdCounter.." \"bset\" commands"
					)
				end
			else
				realMessageListener(message)
			end
		end
	end
	local battleRoomConsole = WG.Chobby.Console("Battleroom Chat", MessageListener, true, nil, true)

	local chatPanel = Control:New {
		name = 'chatPanel',
		x = 0,
		y = 0,
		bottom = 0,
		right = "33%",
		padding = {EXTERNAL_PAD_HOR, INTERNAL_PAD, INTERNAL_PAD, EXTERNAL_PAD_VERT},
		itemPadding = {0, 0, 0, 0},
		itemMargin = {0, 0, 0, 0},
		children = {
			battleRoomConsole.panel,
		},
		parent = bottomPanel,
	}

	local CHAT_MENTION = "\255\255\0\0"
	local CHAT_ME = Configuration.meColor

	-- External Functions
	local externalFunctions = {}

	function externalFunctions.ClearChatHistory()
		battleRoomConsole:ClearHistory()
	end

	function externalFunctions.OnBattleClosed(listener, closedBattleID)
		if battleID == closedBattleID and mainWindow then
			mainWindow:Dispose()
			mainWindow = nil
			if wrapperControl and wrapperControl.visible and wrapperControl.parent then
				wrapperControl:Hide()
			end
		end
	end

	function externalFunctions.GetInfoHandler()
		return infoHandler
	end

	function externalFunctions.UpdateInviteButton(newVisibile)
		btnInviteFriends:SetVisibility(newVisibile)
	end

	-- 23/03/19 Fireball update: only react, when dependent status.properties are present = were updated for this current event
	-- reacts to: isSpectator, isReady, queuePos
	local function OnUpdateUserBattleStatus(listener, username, status)

		------------------------
		-- Buttons Play and Spec

		local battleID = battleLobby:GetMyBattleID()
		local maxPlayers = (battleLobby and battleLobby.battles and battleLobby.battles[battleID].maxPlayers) or 0
		local playerCount = (battleLobby and battleLobby:GetBattlePlayerCount(battleID)) or 0
		local myBs = battleLobby:GetUserBattleStatus(battleLobby.myUserName) or {}
		local iAmPlayer = myBs.isSpectator ~= nil and myBs.isSpectator == false
		local iAmQueued = myBs.queuePos and myBs.queuePos > 0
		-- Spring.Echo("OnUpdateUserBattleStatus battleID, maxPlayers, playerCount, iAmPlayer, iAmQueued", battleID, maxPlayers, playerCount, iAmPlayer, iAmQueued)

		-- somebody switched to player
		if status.isSpectator ~= nil and status.isSpectator == false then
			if not iAmPlayer then
				if not iAmQueued then
					if playerCount >= maxPlayers then
						-- Spring.Echo("OnUpdateUserBattleStatus players full > SET play = join_queue")
						infoHandler.SetBtnsPlaySpec(false, "join_queue", true, "spectating", false)
					else
						-- Spring.Echo("OnUpdateUserBattleStatus players not full > SET play = play")
						infoHandler.SetBtnsPlaySpec(false, "play", true, "spectating", false)
					end
				else
					-- Spring.Echo("OnUpdateUserBattleStatus SET play = queued; Spec = leave_queue")
					infoHandler.SetBtnsPlaySpec(true, "queued", false, "Leave Queue", false)
				end
			end
		end

		if battleLobby.name ~= "singleplayer" and username == battleLobby.myUserName then
			if status.isBoss ~= nil then
				if status.isBoss == true then
					for i = 0, 7 do
						local locker = factionComboBoxes[i]
						if locker then
							locker:Show()
						end
					end
				else
					for i = 0, 7 do
						local locker = factionComboBoxes[i]
						if locker then
							locker:Hide()
						end
					end
				end
			end
		end

		if username ~= battleLobby.myUserName or battleLobby.name == "singleplayer" or (status.isSpectator == nil and status.isReady == nil and status.queuePos == nil) then
			-- Spring.Echo("Canceled")
			return
		end
		------------------------
		-- (else) Update affects ME

		if status.isSpectator ~= nil then
			-- we switched to player
			if status.isSpectator == false then
				-- Spring.Echo("OnUpdateUserBattleStatus[me] we became player > SET play = playing and spec = spectate")
				infoHandler.SetBtnsPlaySpec(true, "playing", false, "spectate", true)
				-- if we were were in queuePos before switching to player, play a sound
				if status.queuePos then
					local Configuration = WG.Chobby.Configuration
					Spring.PlaySoundFile("sounds/BAR_Joined_queue6D_mixdown.wav", Configuration.menuNotificationVolume or 1, "ui")
				end

			-- we switched to spec
			else
				-- Spring.Echo("OnUpdateUserBattleStatus[me] we became spec > SET play = play|join_queue and spec = spectating|leave_queue")
				if not iAmQueued then
					if playerCount >= maxPlayers then
						-- Spring.Echo("OnUpdateUserBattleStatus[me] players full > SET play = join_queue")
						infoHandler.SetBtnsPlaySpec(false, "join_queue", true, "spectating", true)
					else
						-- Spring.Echo("OnUpdateUserBattleStatus[me] players not full > SET play = play")
						infoHandler.SetBtnsPlaySpec(false, "play", true, "spectating", true)
					end
				else
					-- Spring.Echo("OnUpdateUserBattleStatus[me] SET play = Queued; Spec = leave_queue")
					infoHandler.SetBtnsPlaySpec(true, "queued", false, "leave_queue", true)
				end
			end
		end

		if iAmQueued then
			-- Spring.Echo("OnUpdateUserBattleStatus[me] SET play = Queued; Spec = leave_queue")
			infoHandler.SetBtnsPlaySpec(true, "queued", false, "leave_queue")
		elseif not iAmPlayer then
			if playerCount >= maxPlayers then
				-- Spring.Echo("OnUpdateUserBattleStatus[me] players full > SET play = join_queue")
				infoHandler.SetBtnsPlaySpec(false, "join_queue", true, "spectating")
			else
				-- Spring.Echo("OnUpdateUserBattleStatus[me] players not full > SET play = play")
				infoHandler.SetBtnsPlaySpec(false, "play", true, "spectating")
			end
		end

		------------------------
		-- Button Ready

		local tooltipCandidate = ""
		if status.isSpectator ~= nil then
			-- Spring.Log(LOG_SECTION, LOG.NOTICE, status.isSpectator and "Disabling readyButton" or "Enabling readyButton")
			readyButton:SetEnabled(not status.isSpectator)
			if status.isSpectator then
				-- Spring.Log(LOG_SECTION, LOG.NOTICE, "uncheck readyButton and StyleOff")
				readyButtonCheckArrow.file = nil
				readyButtonCheckArrow:Invalidate()
				readyButton:StyleOff()
				readyButton.suppressButtonReaction = true
				tooltipCandidate = i18n("unready_notplaying_tooltip")
			else
				readyButton.suppressButtonReaction = false
			end
		end
		if not status.isSpectator then
			if status.isReady ~= nil and status.isReady then
				-- Spring.Log(LOG_SECTION, LOG.NOTICE, "check readyButton and StyleReady")
				readyButton:StyleReady()
				readyButtonCheckArrow.file = IMG_CHECKARROW
				readyButtonCheckArrow:Invalidate()
				tooltipCandidate = i18n("ready_tooltip")
			else
				-- Spring.Log(LOG_SECTION, LOG.NOTICE, "uncheck readyButton and StyleUnready")
				readyButton:StyleUnready()
				readyButtonCheckArrow.file = nil
				readyButtonCheckArrow:Invalidate()
				tooltipCandidate = i18n("unready_tooltip")
			end
        end

		-- 23/04/04 Fireball: moved readyButton tooltip change on battle.isRunning to BattleIngameUpdate
		if not battle.isRunning then
			readyButton.tooltip = tooltipCandidate
		end

	end

	local function OnUpdateUserTeamStatus(listener, userName, allyNumber, isSpectator, queuePos)
		-- Spring.Echo("room:OnUpdateUserTeamStatus userName:" .. tostring(userName) .. " allyNumber:" .. tostring(allyNumber) .. " isSpectator:" .. tostring(isSpectator))
		--votePanel.VoteButtonVisible(isSpectator == false)
		infoHandler.UpdateUserTeamStatus(userName, allyNumber, isSpectator, queuePos)
		playerHandler.UpdateUserTeamStatus(userName, allyNumber, isSpectator, queuePos)
	end

	local function OnBattleIngameUpdate(listener, updatedBattleID, isRunning)
		infoHandler.BattleIngameUpdate(updatedBattleID, isRunning)
		if votePanel.visible and isRunning and battleID == updatedBattleID then
			votePanel.VoteEnd("Match starting", true)
		end
	end

	local function OnUpdateBattleInfo(listener, updatedBattleID, newInfo)
		if (newInfo.battleMode or newInfo.title or newInfo.engineVersion) and battleID == updatedBattleID then
			UpdateBattleTitle()
			if newInfo.battleMode then
				playerHandler.UpdateBattleMode(newInfo.disallowCustomTeams, newInfo.disallowBots)
				infoHandler.UpdateBattleMode(newInfo.disallowCustomTeams)
			end
		end

		infoHandler.UpdateBattleInfo(updatedBattleID, newInfo)
	end

	local function OnLeftBattle(listener, leftBattleID, userName)
		infoHandler.LeftBattle(leftBattleID, userName)
		playerHandler.LeftBattle(leftBattleID, userName)
	end

	local function OnJoinedBattle(listener, joinedBattleId, userName)
		infoHandler.JoinedBattle(joinedBattleId, userName)
		lastUserToChangeStartBoxes = battleLobby:GetBattle(joinedBattleId).founder
	end

	local function OnRemoveAi(listener, botName)
		playerHandler.RemoveAi(botName)
	end

	local function OnVoteUpdate(listener, voteMessage, pollType, _, mapPoll, candidates, votesNeeded, pollUrl)
		votePanel.VoteUpdate(voteMessage, pollType, mapPoll, candidates, votesNeeded, pollUrl)
	end

	local function OnVoteEnd(listener, message, success)
		votePanel.VoteEnd(message, success)
	end

	--[[ ZK only
	local matchmakerCandidates = {
		{
			clickFunc = function()
				battleLobby:AcceptMatchMakingMatch()
			end,
			votes = 0,
		},
		{
			clickFunc = function()
				battleLobby:RejectMatchMakingMatch()
				votePanel.ImmediateVoteEnd()
			end,
			votes = 0,
		},
	}

	local function OnMatchMakerReadyCheck(_, secondsRemaining, minWinChance, isQuickPlay)
		if not isQuickPlay then
			return -- Handled by MM popup
		end
		matchmakerCandidates[1].votes = 0
		matchmakerCandidates[2].votes = 0
		votePanel.VoteUpdate("Do you want to play a small team game with players of similar skill?", "quickplay", false, matchmakerCandidates, MINIMUM_QUICKPLAY_PLAYERS)
	end

	local function OnMatchMakerReadyUpdate(_, readyAccepted, likelyToPlay, queueReadyCounts, battleSize, readyPlayers)
		if not votePanel.GetMatchmakerMode() then
			return
		end
		matchmakerCandidates[1].votes = queueReadyCounts.Teams
		matchmakerCandidates[2].votes = 0
		votePanel.VoteUpdate("Do you want to play a small team game with players of similar skill?", "quickplay", false, matchmakerCandidates, MINIMUM_QUICKPLAY_PLAYERS)
	end

	local function OnMatchMakerReadyResult(_, isBattleStarting, areYouBanned)
		if not votePanel.GetMatchmakerMode() then
			return
		end
		votePanel.VoteEnd((isBattleStarting and "Match starting") or "Not enough players", isBattleStarting)
	end
	--]]

	local function pyPartition(s,p,left)
		if string.find(s,p,nil,true) then
			local startfind, endfind = string.find(s,p,nil,true)
			if left then
				return string.sub(s,1,startfind-1)
			else
				return string.sub(s,endfind+1)
			end
		else
			return s
		end
	end

	local function startsWith(targetstring, pattern) 
		if string.len(pattern) <= string.len(targetstring) and pattern == string.sub(targetstring,1, string.len(pattern)) then
		  return true, string.sub(targetstring, string.len(pattern) + 1)
		else
		  return false
		end
	end

	-- whoever wrote lua string parser needs to get rammed by a horse

	local function dontshowvote()
	end

	local function ParseSpadsMessage(userName, message) -- return hidemessage bool
		-- should only be called on messages from founder (host)
		local myUserName = battleLobby:GetMyUserName()
		local iAmMentioned = (string.find(message,myUserName,nil,true) ~= nil)

		-- Restore default position on startbox selector when map, preset or teamcount changes
		if string.match(message, "Global setting changed by .- %((nbTeams=%d+)%)$")
		or string.match(message, "Loaded boxes of map .%w+. ")
		or string.match(message, "Map changed by .-%: .+$")
		or string.match(message, "Preset .%w+. %(.-%) applied by .+$")
		then
			StartBoxComboBoxSelectDefault()
			return false
		end

		if iAmMentioned then return false end

		-- filter some basic things that are 'private' to me
		if string.match(message, "you cannot vote currently, there is no vote in progress.$") then return true end

		if string.match(message, ", there is already a vote in progress, please wait for it to finish before calling another one.$") then return true end

		if string.match(message, ", please wait .* more second.s. before calling another vote .vote flood protection..$") then return true end

		if string.match(message, ".* you have already voted for current vote.$") then return true end

		if string.match(message, ". Away vote mode for .*$") then return true end

		-- TODO: prepare for BarManager
		-- i can still multi-vote!
		if string.match(message, ". Hi .*! Current battle type is .*.$") then return false end

		if string.match(message, ". BattleStatus = .*") then return true end

		if string.match(message, "Player .* has already been added in game") then return true end

		return false -- false if it should be displayed to user, true if not
	end

	local function ParseUserMessage(userName,message) -- returns hidemessage bool
		local mine = userName == battleLobby:GetMyUserName() 

		if string.match(message, "^!split ") or string.match(message, "^!addbox ") then
			lastUserToChangeStartBoxes = userName 
			if not mine then return true end
		end

		if mine then return false end -- alway show own messages from here:

		if message == '!vote y' or message == '!vote n' or message == '!vote b' then
			--return true --not yet
		end

		if string.match(message, "^!joinas spec$") then return true end

		if string.match(message, "^!cv .*") then return true end

		if string.match(message, "^!ring .*") then return true end

		if string.match(message, "^!endvote$") then return true end
	end


	local function ParseForVotingSaidBattle(userName,message)
		-- https://github.com/beyond-all-reason/Beyond-All-Reason/blob/master/luaui/Widgets_BAR/gui_vote_interface.lua#L193

		-- New vote:
		-- [teh]BaNa called a vote for command "forcestart" [!vote y, !vote n, !vote b]
		-- [teh]cluster1[00], * Vote in progress: "set map DSDR 4.0" [y:1/2, n:0/1(2)] (25s remaining)
		local newlycalledvote = string.match(message, "called a vote for command") 
		if newlycalledvote or string.match(message,"Vote in progress") then 
			local userwhocalledvote = nil
			local ismapppoll = false
			local mapname = ''
			local votesNeeded = -1
			local yesvotes = 1
			local novotes = 0
			local timeleft = nil

			if newlycalledvote == nil then
				yesvotes, votesNeeded, novotes = string.match(message, vote_votingsPattern)
				yesvotes = tonumber(yesvotes)
				votesNeeded = tonumber(votesNeeded or -1)
				novotes = tonumber(novotes or 0)
				-- Spring.Echo("votes", message, 'yes:', yesvotes, "needed:", votesNeeded, "no:", novotes)
			end

			local candidates = {}
			candidates[1] = {
				id = nil,
				votes = yesvotes,
				url = "",
			}
			candidates[2] = {
				id = nil,
				votes = novotes,
				url = "",
			}

			if newlycalledvote then
				userwhocalledvote = string.match(message, vote_whoCalledPattern)
				WG.LibLobby.lobby:_OnUserVoted(_, "initVote")
				WG.LibLobby.lobby:_OnUserVoted(userwhocalledvote, "yes")
			end 
			--[teh]Behe_Chobby3 called a vote for command "set map Tetrad_V2" [!vote y, !vote n, !vote b]
			if string.find(message, ' "set map ', nil, true) then
				mapname = string.match(message, vote_mapPattern)
				ismapppoll = true
			end

			if string.match(message,"..s remaining.$") then
				timeleft = pyPartition(pyPartition(message,"] (",false),"s remaining",true)
				candidates[1].timeleft = timeleft
				candidates[2].timeleft = timeleft
			end

			local title = string.sub(message, string.find(message, ' "',nil,true) + 2, string.find(message, '" ', nil, true) - 1)
			title = title:sub(1, 1):upper() .. title:sub(2)
			votePanel.VoteUpdate(title,nil, ismapppoll, candidates, votesNeeded, mapname, userwhocalledvote, newlycalledvote)
			return true

		elseif string.match(message, "Vote for command.*passed" ) then	--[21:13:58] * [teh]host * Vote for command "bSet coop 1" passed. --voteend
			votePanel.VoteEnd(nil, true)
			return true

		elseif string.match(message, "Vote for command.*failed" )then	--[21:13:58] * [teh]host * Vote for command "bSet coop 1" passed. --voteend
			votePanel.VoteEnd(nil, false)
			return true

		elseif string.find(message, "Vote cancelled by", nil, true) then --votecancel
			--[14:42:53] * [teh]host * Vote cancelled by [teh]BaNa
			votePanel.ImmediateVoteEnd()
			return true

		elseif string.find(message, "command executed directly by", nil, true) and string.find(string.lower(message), " cancelling ", nil, true) then --votecancel
			--[14:43:19] * [teh]host * Cancelling "set map Throne Acidic" vote (command executed directly by [teh]Beherith)
			votePanel.ImmediateVoteEnd()
			return true
		elseif string.find(message, "Game starting, cancelling", nil, true) then
			votePanel.ImmediateVoteEnd()
			return false
		end

		return false
	end

	local function ParseBarManagerSaidBattleEx(userName,message)
		local BARMANAGER_PREFIX = "* BarManager|"
		local doesStartWith, barManagerMessage = startsWith(message,BARMANAGER_PREFIX)
		if doesStartWith then
			-- Spring.Echo("BarManagerMessage",barManagerMessage)
			if barManagerPresent ~= true then
				spadsStatusPanel:SetVisibility(true)
				barManagerPresent = true
			end

			barManagerTable = Json.decode(barManagerMessage)
			if barManagerTable['BattleStateChanged'] then
				for settingKey, settingValue in pairs(barManagerTable['BattleStateChanged']) do
					local settingCB = spadsStatusPanel:GetChildByName(settingKey)
					if settingCB and settingCB.items and settingCB.caption ~= settingValue then
						for i = 1, #settingCB.items do
							if settingCB.items[i] == settingValue then settingCB:Select(i) end
						end
					else

					end
				end
			end
				--* BarManager|{"BattleStateChanged": {"locked": "locked"}}".

			return true
		end
		return false
	end

	local function OnSaidBattle(listener, userName, message)
		--ParseForVotingSaidBattle(userName,message) --only on EX?
		local myUserName = battleLobby:GetMyUserName()
		local iAmMentioned = myUserName and userName ~= myUserName and string.find(message, myUserName, nil, true)
		local chatColour = (iAmMentioned and CHAT_MENTION) or nil
		local hidemessage = ParseUserMessage(userName,message)
		if Configuration.filterbattleroom and hidemessage and not iAmMentioned then return end
		battleRoomConsole:AddMessage(message, userName, false, chatColour, false)
	end

	local function OnSaidBattleEx(listener, userName, message)
		local battle = battleLobby:GetBattle(battleID)
		local hidemessage = false

		if userName == battle.founder then -- todo dont do this for self-hosted
			local hidespads = ParseSpadsMessage(userName,message)
			local hidevote = ParseForVotingSaidBattle(userName,message)
			local hidebarmanager = ParseBarManagerSaidBattleEx(userName, message)
			if hidevote or hidespads or hidebarmanager then
				hidemessage = true
				--Spring.Echo("Hiding",message,hidevote, hidespads)
			end

		end

		hidemessage = hidemessage

		if Configuration.filterbattleroom and hidemessage then -- displayBots
			--Spring.Echo("Hiding message|"..message)
			return 
		end
		local myUserName = battleLobby:GetMyUserName()
		local iAmMentioned = myUserName and userName ~= myUserName and string.find(message, myUserName)
		local chatColour = (iAmMentioned and CHAT_MENTION) or CHAT_ME
		battleRoomConsole:AddMessage(message, userName, false, chatColour, true)
	end

	local function OnRemoveStartRect(listener, allyNo)
		--Spring.Log("Chobby gui_battle_room_window.lua",LOG.INFO,"OnRemoveStartRect", allyNo)
		infoHandler.RemoveStartRect(allyNo)
	end

	local function OnAddStartRect(listener, allyNo, left, top, right, bottom)
		--Spring.Log("Chobby gui_battle_room_window.lua",LOG.WARNING,"OnAddStartRect", allyNo, left, top, right, bottom)
		infoHandler.AddStartRect(allyNo, left, top, right, bottom)
	end

	local function OnRing(listener, userName) -- userName is who rang you
		Spring.PlaySoundFile("sounds/Alarm_light5_mixdown.wav", WG.Chobby.Configuration.menuNotificationVolume or 1)

		local userInfo = lobby:TryGetUser(userName)
		if userInfo then
			local userControl = WG.UserHandler.GetNotificationUser(userName)
			userControl:SetPos(30, 30, 250, 80)
			Chotify:Post({
				title = "User Rang You", --i18n("User Rang You"),
				body = userControl,
			})

		end
	end

	local function OnEnableAllUnits(listener)
	end

	local function OnDisableUnits(listener,unitNames)
	end

	local function PickRandomColor()
		local colorOptions = {
			{math.random(50,255),	0,						0					},
			{0,						math.random(50,255),	0					},
			{0,						0,						math.random(50,255)},

			{math.random(50,255),	math.random(0,255),		0					},
			{math.random(50,255),	0,						math.random(0,255)	},
			{math.random(50,255),	math.random(0,200),		math.random(0,200)	},

			{math.random(0,255),	math.random(50,255),	0					},
			{0,						math.random(50,255),	math.random(0,255)	},
			{math.random(0,200),	math.random(50,255),	math.random(0,200)	},

			{math.random(0,255),	0,						math.random(50,255)},
			{0,						math.random(0,255),		math.random(50,255)},
			{math.random(0,200),	math.random(0,200),		math.random(50,255)},
		}

		local r = math.random(1,#colorOptions)
		return {colorOptions[r][1]/255, colorOptions[r][2]/255, colorOptions[r][3]/255,}
	end


	local function OnRequestBattleStatus(listener)
		-- if the server is requesting our battle status, that means we have free reign over teamcolor
		-- if there are 0 players in the lobby, then we should always go as player
		-- we should also save last picked choice
		local wespecnow =  (WG.Chobby.Configuration.lastGameSpectatorState or false)
		--Spring.Echo("OnRequestBattleStatus, wespecnow?:",wespecnow,WG.Chobby.Configuration.lastGameSpectatorState)
		battleLobby:SetBattleStatus({
			isSpectator = wespecnow,
			isReady = false,
			side = (WG.Chobby.Configuration.lastFactionChoice or 0) ,
			sync = (haveMapAndGame and 1) or 2, -- 0 = unknown, 1 = synced, 2 = unsynced
			-- tamColor = PickRandomColor()
			-- teamColor = {
			-- 	math.random() * 0.7 + 0.1,
			-- 	math.random() * 0.7 + 0.1,
			-- 	math.random() * 0.7 + 0.1,
			-- },
		})
	end

	local function OnUpdateBattleTitle(listener, changedbattleID, newbattletitle)
		--Spring.Echo("battle_room: OnUpdateBattleTitle")
		if battleID == changedbattleID then
			UpdateBattleTitle()
		end
	end

	local function OnSetModOptions(listener, modoptions)
		if not modoptions then
			return
		end
		local factionlimiter = modoptions.factionlimiter
		if factionlimiter then
			factionlimiter = tonumber(factionlimiter)
			for i = 0, 7 do
				local locker = factionComboBoxes[i]
				if locker then
					locker.updateBitmaskReading(factionlimiter)
				end
			end
		end
	end

	battleLobby:AddListener("OnUpdateUserTeamStatus", OnUpdateUserTeamStatus)
	battleLobby:AddListener("OnUpdateUserBattleStatus", OnUpdateUserBattleStatus)
	battleLobby:AddListener("OnBattleIngameUpdate", OnBattleIngameUpdate)
	battleLobby:AddListener("OnUpdateBattleInfo", OnUpdateBattleInfo)
	battleLobby:AddListener("OnLeftBattle", OnLeftBattle)
	battleLobby:AddListener("OnJoinedBattle", OnJoinedBattle)
	battleLobby:AddListener("OnRemoveAi", OnRemoveAi)
	battleLobby:AddListener("OnVoteUpdate", OnVoteUpdate)
	battleLobby:AddListener("OnVoteEnd", OnVoteEnd)
	battleLobby:AddListener("OnSaidBattle", OnSaidBattle)
	battleLobby:AddListener("OnSaidBattleEx", OnSaidBattleEx)
	battleLobby:AddListener("OnBattleClosed", externalFunctions.OnBattleClosed)
	-- battleLobby:AddListener("OnMatchMakerReadyCheck", OnMatchMakerReadyCheck)
	-- battleLobby:AddListener("OnMatchMakerReadyUpdate", OnMatchMakerReadyUpdate)
	-- battleLobby:AddListener("OnMatchMakerReadyResult", OnMatchMakerReadyResult)
	battleLobby:AddListener("OnRemoveStartRect", OnRemoveStartRect)
	battleLobby:AddListener("OnAddStartRect", OnAddStartRect)
	battleLobby:AddListener("OnRing", OnRing)
	battleLobby:AddListener("OnEnableAllUnits", OnEnableAllUnits)
	battleLobby:AddListener("OnDisableUnits", OnDisableUnits)
	battleLobby:AddListener("OnRequestBattleStatus", OnRequestBattleStatus)
	battleLobby:AddListener("OnUpdateBattleTitle", OnUpdateBattleTitle)
	battleLobby:AddListener("OnSetModOptions", OnSetModOptions)

	local function OnDisposeFunction()
		emptyTeamIndex = 0

		oldLobby:RemoveListener("OnUpdateUserTeamStatus", OnUpdateUserTeamStatus)
		oldLobby:RemoveListener("OnUpdateUserBattleStatus", OnUpdateUserBattleStatus)
		oldLobby:RemoveListener("OnBattleIngameUpdate", OnBattleIngameUpdate)
		oldLobby:RemoveListener("OnUpdateBattleInfo", OnUpdateBattleInfo)
		oldLobby:RemoveListener("OnLeftBattle", OnLeftBattle)
		oldLobby:RemoveListener("OnJoinedBattle", OnJoinedBattle)
		oldLobby:RemoveListener("OnRemoveAi", OnRemoveAi)
		oldLobby:RemoveListener("OnVoteUpdate", OnVoteUpdate)
		oldLobby:RemoveListener("OnVoteEnd", OnVoteEnd)
		oldLobby:RemoveListener("OnSaidBattle", OnSaidBattle)
		oldLobby:RemoveListener("OnSaidBattleEx", OnSaidBattleEx)
		oldLobby:RemoveListener("OnBattleClosed", externalFunctions.OnBattleClosed)
		-- oldLobby:RemoveListener("OnMatchMakerReadyCheck", OnMatchMakerReadyCheck)
		-- oldLobby:RemoveListener("OnMatchMakerReadyUpdate", OnMatchMakerReadyUpdate)
		-- oldLobby:RemoveListener("OnMatchMakerReadyResult", OnMatchMakerReadyResult)
		oldLobby:RemoveListener("OnRemoveStartRect", OnRemoveStartRect)
		oldLobby:RemoveListener("OnAddStartRect", OnAddStartRect) -- or else they pile up XD
		oldLobby:RemoveListener("OnRing", OnRing)
		oldLobby:RemoveListener("OnEnableAllUnits", OnEnableAllUnits)
		oldLobby:RemoveListener("OnDisableUnits", OnDisableUnits)
		oldLobby:RemoveListener("OnRequestBattleStatus", OnRequestBattleStatus)
		oldLobby:RemoveListener("OnSetModOptions", OnSetModOptions)

		WG.BattleStatusPanel.RemoveBattleTab()
	end

	mainWindow.OnDispose = mainWindow.OnDispose or {}
	mainWindow.OnDispose[#mainWindow.OnDispose + 1] = OnDisposeFunction

	return mainWindow, externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

local BattleRoomWindow = {}

function BattleRoomWindow.ShowMultiplayerBattleRoom(battleID)

	if mainWindow then
		mainWindow:Dispose()
		mainWindow = nil
	end

	if multiplayerWrapper then
		WG.BattleStatusPanel.RemoveBattleTab()
		multiplayerWrapper:Dispose()
		multiplayerWrapper = nil
	end

	if singleplayerWrapper then
		singleplayerWrapper = nil
	end

	battleLobby = WG.LibLobby.lobby

	multiplayerWrapper = Control:New {
		name = 'multiplayerWrapper',
		x = 0,
		y = 0,
		width = "100%",
		height = "100%",
		resizable = false,
		padding = {0, 0, 0, 0},

		OnParent = {
			function(obj)
				if obj:IsEmpty() then
					wrapperControl = obj

					local battleWindow, functions = InitializeControls(battleID, battleLobby, 65)
					mainWindowFunctions = functions
					if battleWindow then
						obj:AddChild(battleWindow)
					end
				end
				BattleRoomWindow.UpdateMinimapstartBoxes()
			end
		},
		OnHide = {
			function(obj)
				WG.BattleStatusPanel.RemoveBattleTab()
			end
		}
	}

	WG.BattleStatusPanel.AddBattleTab(multiplayerWrapper)

	UpdateArchiveStatus(true)

	battleLobby:SetBattleStatus({
		allyNumber = 0,
		sync = (haveMapAndGame and 1) or 2, -- 0 = unknown, 1 = synced, 2 = unsynced
	})

	WG.OptionpresetsPanel.cloneMPModoptions(true)
end

function BattleRoomWindow.GetSingleplayerControl(setupData)

	singleplayerWrapper = Control:New {
		name = "singleplayerWrapper",
		x = 0,
		y = 0,
		width = "100%",
		height = "100%",
		resizable = false,
		padding = {0, 0, 0, 0},

		OnParent = {
			function(obj)
				--Spring.Utilities.TraceFullEcho()
				if multiplayerWrapper then
					WG.BattleStatusPanel.RemoveBattleTab()

					if mainWindow then
						mainWindow:Dispose()
						mainWindow = nil
					end
					WG.LibLobby.lobby:LeaveBattle()
					multiplayerWrapper = nil
				elseif mainWindow then
					--Spring.Echo("mainWindo exists", mainWindowFunctions, mainWindowFunctions.GetInfoHandler())
					if mainWindowFunctions and mainWindowFunctions.GetInfoHandler() then
						local infoHandler = mainWindowFunctions.GetInfoHandler()
						--Spring.Utilities.TableEcho(infoHandler)
						infoHandler.rightInfo:Invalidate()
						infoHandler.UpdateStartRectPositionsInMinimap()
					end
					return
				end

				local singleplayerDefault = WG.Chobby.Configuration.gameConfig.skirmishDefault

				local defaultMap = "Red Comet"
				if singleplayerDefault and singleplayerDefault.map then
					defaultMap = singleplayerDefault.map
				end

				battleLobby = WG.LibLobby.localLobby
				battleLobby:SetBattleState(WG.Chobby.Configuration:GetPlayerName(), singleplayerGame, defaultMap, "Skirmish Battle")

				wrapperControl = obj

				local battleWindow, functions = InitializeControls(1, battleLobby, 70, setupData)
				mainWindowFunctions = functions
				--Spring.Echo("battleWindow, functions, mainWindow", battleWindow, functions, mainWindow)
				if not battleWindow then
					return
				end

				obj:AddChild(battleWindow)

				UpdateArchiveStatus(true)

				battleLobby:SetBattleStatus({
					allyNumber = 0,
					isSpectator = false,
					sync = (haveMapAndGame and 1) or 2, -- 0 = unknown, 1 = synced, 2 = unsynced

					side = WG.Chobby.Configuration.lastFactionChoice or 0, -- Our default side is Armada
					teamColor = {0,.32,1},
				})

				if not (setupData and WG.Chobby.Configuration.simplifiedSkirmishSetup) and singleplayerDefault then
					local totalAIcount = 1
					local function AddAI(counter, shortName, version, allyTeam, side, color)
						if not shortName then
							return counter
						end

						local fullName = shortName
						if version then
							fullName = fullName .. " " .. version
						end

						if WG.Chobby.Configuration.simpleAiList and WG.Chobby.Configuration.gameConfig.GetAiSimpleName then
							fullName = WG.Chobby.Configuration.gameConfig.GetAiSimpleName(fullName)
							if not fullName then
								return counter
							end
						end

						fullName = fullName .. " (".. counter ..")"
						-- Ubserver AI names cannot include whitespace
						-- Not required for singleplayer, but breaks counter otherwise
						if WG.Server.protocol == "spring" then
							fullName = fullName:gsub(" ", "")
						end

						battleLobby:AddAi(fullName, shortName, allyTeam, version, nil, {
								side = side,
								teamColor = color,
							})

						return counter + 1
					end

					for i, ai in ipairs(singleplayerDefault.friendlyAI or {}) do
						totalAIcount = AddAI(totalAIcount, ai.shortName, ai.version, 0,
							0, -- Default side for friendly AI is Armada
							{.45,0,.68})
					end

					for i, ai in ipairs(singleplayerDefault.enemyAI or {}) do
						totalAIcount = AddAI(totalAIcount, ai.shortName, ai.version, 1,
							1, -- Default side for enemy AI is Cortex
							GetStarterEnemyAIColorAssignment(i))
					end
					if singleplayerDefault.startboxes then 
						for startboxindex, startboxcoords in pairs(singleplayerDefault.startboxes) do 
							--Spring.Utilities.TraceFullEcho(100,100,100,"INIT BOXEN", battleWindow, mainWindowFunctions)
							--Spring.Utilities.TableEcho(mainWindowFunctions)
							local infoHandler = mainWindowFunctions.GetInfoHandler()
							--Spring.Utilities.TableEcho(infoHandler)
							infoHandler.AddStartRect(startboxindex, startboxcoords[1], startboxcoords[2],startboxcoords[3],startboxcoords[4])
							infoHandler.rightInfo:Invalidate()
							infoHandler.UpdateStartRectPositionsInMinimap()
						end
					end
				end
				BattleRoomWindow.UpdateMinimapstartBoxes()
			end
		},
	}

	return singleplayerWrapper
end

function BattleRoomWindow.UpdateMinimapstartBoxes()
	local function IsMousePressed()
		local x,y, lmb, mmb, rmb = Spring.GetMouseState()
		return lmb or mmb or rmb
	end

	if mainWindowFunctions and mainWindowFunctions.GetInfoHandler() and not IsMousePressed() then
		local infoHandler = mainWindowFunctions.GetInfoHandler()
		infoHandler.rightInfo:Invalidate()
		infoHandler.UpdateStartRectPositionsInMinimap()
		infoHandler.rightInfo:UpdateClientArea()
	end

	if WG.Delay then
		WG.Delay(BattleRoomWindow.UpdateMinimapstartBoxes, 0.5)
	end
end

function GetStarterEnemyAIColorAssignment(i)
	local red = {1,.07,.02};
	local orange = {.96,.42,0};

	if (i==1) then return red
	elseif (i==2) then return orange
	end
end

function BattleRoomWindow.SetSingleplayerGame(ToggleShowFunc, battleroomObj, tabData)
	local function SetGameFail()
		WG.LibLobby.localLobby:LeaveBattle()
	end

	local function SetGameSucess(name)
		singleplayerGame = name
		ToggleShowFunc(battleroomObj, tabData)
	end

	local config = WG.Chobby.Configuration
	local skirmishGame = config:GetDefaultGameName()
	if skirmishGame then
		SetGameSucess(skirmishGame)
	else
		WG.Chobby.GameListWindow(SetGameFail, SetGameSucess)
	end
end

function BattleRoomWindow.LeaveBattle(onlyMultiplayer, onlySingleplayer)
	if not battleLobby then
		return
	end

	if onlyMultiplayer and battleLobby.name == "singleplayer" then
		return
	end

	if onlySingleplayer and battleLobby.name == "singleplayer" then
		if mainWindow then
			mainWindow:Dispose()
			mainWindow = nil
		end
		return
	end

	battleLobby:LeaveBattle()
	barManagerPresent = true
	if mainWindowFunctions then
		mainWindowFunctions.OnBattleClosed(_, battleLobby:GetMyBattleID())
	end

	WG.BattleStatusPanel.RemoveBattleTab()
end

function BattleRoomWindow.ClearChatHistory()
	if mainWindowFunctions and mainWindowFunctions.ClearChatHistory then
		mainWindowFunctions.ClearChatHistory()
	end
end


function BattleRoomWindow.GetCurrentStartRects()
	return startRectValues
end

function BattleRoomWindow.AddStartRect(allyNo, left, top, right, bottom)
	if battleLobby.name == "singleplayer" then
		local infoHandler = mainWindowFunctions.GetInfoHandler()
		infoHandler.AddStartRect(allyNo, left, top, right, bottom)
	else
		battleLobby:SayBattle(string.format("!addbox %d %d %d %d %s", left, top, right, bottom, allyNo+1))
	end
end

function BattleRoomWindow.RemoveStartRect(allyNo)
	if battleLobby.name == "singleplayer" then
		local infoHandler = mainWindowFunctions.GetInfoHandler()
		infoHandler.RemoveStartRect(allyNo)
	end
end


function BattleRoomWindow.SetTeams(numberOfTeams)
	if battleLobby.name ~= "singleplayer" then
		-- command to set the teams
		battleLobby:SayBattle(string.format("!nbTeams %d", numberOfTeams))
	end
end

function BattleRoomWindow.SetStart(allyNo)
	local infoHandler = mainWindowFunctions.GetInfoHandler()
	infoHandler.RemoveStartRect(allyNo)
end

function BattleRoomWindow.GetPlayerHandler()
	return playerHandler
end

local function DelayedInitialize()
	local function onConfigurationChange(listener, key, value)
		if mainWindowFunctions and key == "canAuthenticateWithSteam" then
			mainWindowFunctions.UpdateInviteButton(value)
		end
	end
	WG.Chobby.Configuration:AddListener("OnConfigurationChange", onConfigurationChange)

	if mainWindowFunctions and mainWindowFunctions.GetInfoHandler() then
		local infoHandler = mainWindowFunctions.GetInfoHandler()
		infoHandler.rightInfo:Invalidate()
		infoHandler.UpdateStartRectPositionsInMinimap()
	else
		--Spring.Echo("Cannot find mainWindowFunctions in battle room window",mainWindowFunctions)
	end
end

function widget:Initialize()
	CHOBBY_DIR = LUA_DIRNAME .. "widgets/chobby/"
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	local function downloadFinished()
		UpdateArchiveStatus(true)
	end
	WG.DownloadHandler.AddListener("DownloadFinished", downloadFinished)

	WG.BattleRoomWindow = BattleRoomWindow
	WG.Delay(DelayedInitialize, 0.5)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
