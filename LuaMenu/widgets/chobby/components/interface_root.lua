function GetInterfaceRoot(optionsParent, mainWindowParent, fontFunction)

	local externalFunctions = {}

	local globalKeyListener = false
	local backgroundCloseListener = false

	local titleWidthRel = 28
	local panelWidthRel = 42

	local userStatusPanelWidth = 300

	local battleStatusWidth = 480
	local panelButtonsWidth = "44.9%"
	local panelButtonsHeight = 42
	local statusWindowGapSmall = 44

	local chatTabHolderHeight = 41

	local battleStatusTopPadding = 20
	local battleStatusBottomPadding = 20
	local battleStatusLeftPadding = 30

	local smallStatusLeftPadding = 5
	local battleStatusTopPaddingSmall = 5

	local chatTabHolderRight = 0

	local titleHeight = 125
	local titleHeightSmall = 82
	local titleWidth = 360

	-- Large title is 180x125
	-- Small title is 140x82

	local mainButtonsWidth = 180
	local mainButtonsWidthSmall = 140

	local userStatusWidth = 265
	local userStatusWidth = 333

	local imageFudge = 0

	local padding = 0

	local statusButtonWidth = 265
	local statusButtonWidthSmall = 265

	local topBarHeight = 42

	-- Switch to single panel mode when below the minimum screen width
	local minScreenWidth = 1350

	local gameRunning = false
	local showTopBar = false
	local doublePanelMode = true
	local autodetectDoublePanel = true
	local wideContentPlace = false

	local buttonSpacingLarge = 4 -- Matches tab panel handler and submenu handler
	local BUTTON_SIDE_SPACING = 1 -- Matches tab panel handler and submenu handler
	local buttonSpacingSmall = 2

	local IMAGE_TOP_BACKGROUND = LUA_DIRNAME .. "images/top-background.png"

	local INVISIBLE_COLOR = {0, 0, 0, 0}
	local VISIBLE_COLOR = {1, 1, 1, 1}

	-------------------------------------------------------------------
	-- Window structure
	-------------------------------------------------------------------
	local ingameInterfaceHolder = Control:New {
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		name = "ingameInterfaceHolder",
		parent = screen0,
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
		children = {},
		preserveChildrenOrder = true
	}
	ingameInterfaceHolder:Hide()

	local lobbyInterfaceHolder = Control:New {
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		name = "lobbyInterfaceHolder",
		parent = screen0,
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
		children = {},
		preserveChildrenOrder = true
	}
	lobbyInterfaceHolder.drawTimer = Spring.GetTimer()
	version_font = WG.Chobby.Configuration:GetFont(1)
	
	local byarchobbyrapidTag = "unknown"
	for i,v in ipairs(VFS.GetLoadedArchives()) do 
		if string.find(v,"BYAR Chobby ", nil, true) then
			byarchobbyrapidTag = string.gsub(string.gsub(v,"test%-", ""), "BYAR Chobby ", "")
			byarchobbyrapidTag = string.gsub(byarchobbyrapidTag, "[^%w]", " ")
			break
		end
	end

	local label_version = Label:New {
		y = "95%",
		width = "20%",
		height = "5%",
		right = "2.25%",
		parent = lobbyInterfaceHolder,
		objectOverrideFont = version_font,
		caption =  "\255\185\185\185" .. "Game: " .. Configuration.gameConfig.ShortenNameString(Configuration:GetDefaultGameName()) .. "  Engine: " .. Configuration:GetTruncatedEngineVersion() .. "  "
			.. 'Chobby:' .. byarchobbyrapidTag,
		align = "right",
		valign = 'bottom',
	}

	-- Direct children of lobbyInterfaceHolder are called holder_<name>
	-- and are each within their own subsection

	-----------------------------------
	-- Ingame top bar holder
	-----------------------------------
	local holder_topBar = Control:New {
		x = 0,
		y = 0,
		right = 0,
		height = topBarHeight,
		name = "holder_topBar",
		parent = lobbyInterfaceHolder,
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
		children = {}
	}
	holder_topBar:Hide()

	-----------------------------------
	-- Heading holder
	-----------------------------------
	local holder_heading = Control:New {
		x = 0,
		y = 0,
		width = titleWidth,
		height = titleHeight,
		name = "holder_heading",
		parent = lobbyInterfaceHolder,
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
		children = {}
	}
	local heading_image = Image:New {
		y = 0,
		x = 0,
		right = 0,
		bottom = 0,
		keepAspect = true,
		file = Configuration:GetHeadingImage(doublePanelMode),
		OnClick = { function()
			Spring.Echo("OpenURL: uncomment me in interface_root.lua")
			-- Uncomment me to try it!
			--Spring.OpenURL("https://gitter.im/Spring-Chobby/Chobby")
			--Spring.OpenURL("/home/gajop")
		end},
		parent = holder_heading,
	}

	local cachingLabel 	= Label:New {
		name = "cachingLabel",
		x = "1.75%",
		y = "95%",
		width = "20%",
		height = "5%",
		parent = lobbyInterfaceHolder,
		objectOverrideFont = version_font,
		caption = "Caching...",
		align = "left",
		valign = 'bottom',
	}
	-----------------------------------
	-- Top middle and top right status
	-----------------------------------
	local holder_status = Control:New {
		x = titleWidth,
		y = 0,
		right = 0,
		height = titleHeight,
		name = "holder_status",
		caption = "", -- Status Window
		parent = lobbyInterfaceHolder,
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
	}

	local holder_statusAndInvites = Control:New {
		x = titleWidth,
		y = 0,
		right = 0,
		height = titleHeightSmall,
		name = "holder_statusAndInvites",
		caption = "", -- Status Window
		parent = holder_status,
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
		children = {}
	}

	local status_userWindow = Control:New {
		y = 0,
		right = 0,
		bottom = panelButtonsHeight,
		width = userStatusWidth,
		padding = {0, 0, 0, 0},
		parent = holder_status,
		children = {
			WG.UserStatusPanel.GetControl(),
		}
	}

	local status_panelButtons = Control:New {
		width = (2 + panelWidthRel) .. "%",
		bottom = 0,
		right = 0,
		height = panelButtonsHeight,
		name = "status_panelButtons",
		parent = holder_status,
		resizable = false,
		draggable = false,
		padding = {0, 0, 20, 0},
		children = {}
	}
	local panelButtons_buttons = Control:New {
		x = "0%",
		y = "0%",
		width = "100%",
		height = "100%",
		name = "panelButtons_buttons",
		caption = "", -- Panel Buttons
		parent = status_panelButtons,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
		children = {}
	}

	-----------------------------------
	-- Right panel holder
	-----------------------------------

	local holder_rightPanel = Control:New {
		x = (100 - panelWidthRel) .. "%",
		y = titleHeight,
		right = 0,
		bottom = 0,
		name = "holder_rightPanel",
		caption = "", -- Panel Window
		parent = lobbyInterfaceHolder,
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
		children = {}
	}
	local rightPanel_window = Window:New {
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		classname = "main_window",
		name = "rightPanel_window",
		caption = "", -- Panel Window
		parent = holder_rightPanel,
		resizable = false,
		draggable = false,
		padding = {5, 4, 5, 2},
		children = {}
	}
	rightPanel_window:Hide()

	-----------------------------------
	-- Main Window
	-----------------------------------
	local holder_mainWindow = Control:New {
		x = 0,
		y = titleHeight,
		width = (100 - panelWidthRel) .. "%",
		bottom = 0,
		name = "holder_mainWindow",
		caption = "", -- Main Window
		parent = lobbyInterfaceHolder,
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
		children = {}
	}
	local mainWindow_buttonsHolder = Control:New {
		x = padding,
		y = padding,
		width = mainButtonsWidth,
		bottom = padding,
		name = "mainWindow_buttonsHolder",
		parent = holder_mainWindow,
		padding = {0, 0, 0, 0},
		children = {},
	}
	local buttonsHolder_buttons = Control:New {
		x = 0,
		y = 0,
		width = "100%",
		height = "100%",
		name = "buttonsHolder_buttons",
		caption = "", -- Main Buttons
		parent = mainWindow_buttonsHolder,
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
		children = {}
	}

	local buttonsHolder = Control:New {

		x = 0,
		y = 0,
		width = "100%",
		height = "100%",
		name = "buttonsHolder",
		caption = "", -- Main Buttons
		--parent = buttonsHolder_buttons,
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
		children = {}
	}

	local buttonsHolder_image = Image:New {
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		file = IMAGE_TOP_BACKGROUND,
		parent = mainWindow_buttonsHolder,
		keepAspect = false,
		color = {0.218, 0.23, 0.49, 0.0},
	}

	local mainWindow_mainContent = Control:New {
		x = mainButtonsWidth,
		y = padding,
		right = padding,
		bottom = padding,
		name = "mainWindow_mainContent",
		caption = "", -- Content Place
		parent = holder_mainWindow,
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
		children = {}
	}
	local mainContent_window = Window:New {
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		classname = "main_window",
		name = "mainContent_window",
		caption = "", -- Content Place
		parent = mainWindow_mainContent,
		resizable = false,
		draggable = false,
		padding = {5, 4, 5, 2},
		children = {}
	}
	mainContent_window:Hide()

	-- Exit button
	local function ExitSpring()
		Spring.Echo("Quitting...")
		WG.Chobby.Configuration:SetConfigValue("rejoinBattleID", nil)
		Spring.Quit()
	end

	local function MakeExitPopup()
		ConfirmationPopup(ExitSpring, i18n("exit_lobby_confirm"), nil, 315, 200)
		return true
	end

	local buttons_exit = Button:New {
		x = BUTTON_SIDE_SPACING,
		bottom = 0,
		right = BUTTON_SIDE_SPACING,
		height = 70,
		caption = i18n("exit"),
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		parent = buttonsHolder_buttons,
		OnClick = {MakeExitPopup},
	}

	-----------------------------------
	-- Submenu window
	-----------------------------------
	-- Note that the position of these controls is maintained by pure evil.
	-- If anything in the UI changes this will need updating to take it into account.

	local holder_submenuWindow = Control:New {
		x = mainButtonsWidth,
		y = titleHeight,
		right = 0,
		bottom = 0,
		name = "holder_submenuWindow",
		caption = "",
		parent = lobbyInterfaceHolder,
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
		children = {}
	}

	local submenuWindow_mainContent = Control:New {
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		name = "submenuWindow_mainContent",
		caption = "",
		parent = holder_submenuWindow,
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
		children = {}
	}

	-----------------------------------
	-- Top image
	-----------------------------------
	local holder_topImage = Image:New {
		x = 0,
		y = 0,
		right = 0,
		height = titleHeight,
		file = IMAGE_TOP_BACKGROUND,
		parent = lobbyInterfaceHolder,
		keepAspect = false,
		color = {0, 0, 0, 0.0},
	}

	-----------------------------------
	-- Background holder is put here to be at the back
	-----------------------------------
	local backgroundHolder = Background(nil, nil, nil, "menuBackgroundBrightness")
	local ingameBackgroundHolder = Background(IMAGE_TOP_BACKGROUND, {0, 0, 0, 0.5}, nil, "gameOverlayOpacity")
	ingameBackgroundHolder:Disable()

	-------------------------------------------------------------------
	-- In-Window Handlers
	-------------------------------------------------------------------
	local chatWindows = ChatWindows()
	local mainWindowHandler

	local function CleanMultiplayerState(notFromBackButton)
		if notFromBackButton then
			mainWindowHandler.SetBackAtMainMenu("multiplayer")
		end
		WG.BattleRoomWindow.LeaveBattle(true)
	end

	local rightPanelTabs = {}
	if not WG.Chobby.Configuration.gameConfig.disableCommunityWindow then
		rightPanelTabs[#rightPanelTabs + 1] = {name = "welcome", control = WG.CommunityWindow.GetControl()}
	end
	rightPanelTabs[#rightPanelTabs + 1] = {name = "chat", control = chatWindows.window}
	rightPanelTabs[#rightPanelTabs + 1] = {name = "friends", control = WG.FriendWindow.GetControl()}
	rightPanelTabs[#rightPanelTabs + 1] = {name = "parties", control = WG.PartyWindow.GetControl()}
	rightPanelTabs[#rightPanelTabs + 1] = {name = "settings", control = WG.SettingsWindow.GetControl()}
	rightPanelTabs[#rightPanelTabs + 1] = {name = "downloads", control = WG.DownloadWindow.GetControl()}

	local battleListWindow, battleListWindowJoinBattle = WG.BattleListWindowHolder.GetControl()

	local SINGLEPLAYER_INDEX = 1
	local MULTIPLAYER_INDEX = 1
	local HELP_INDEX = 1

	local multiPlayerTabs = {}
	multiPlayerTabs[#multiPlayerTabs + 1] = {name = "battle_list", control = battleListWindow}

	-- Goals:
	-- [X] Separate the 6 menus
	-- [X] Multiplayer, Skirmish, Scenarios, Load Game, Replays, Help
	-- [X] No back button
	-- [X] Always get to the first needed one
	-- [ ] Allow SP while queued for MP
	-- [ ] Hide chat panels in single panel mode
		-- [ ] In single panel mode, when coordinater dm's you with play rating limits, the battleroom is hidden
	-- [X] Try it first with all tabs in a single menu
		-- Funnily enough, this kind of works
	-- [X] Fix MP tab not triggering when not auto logging in

	local singleplayerConfig = Configuration.gameConfig.singleplayerConfig

	local multiplayerentrycheck = function (ToggleShowFunc, obj, newTab)
		WG.LoginWindowHandler.TryLoginMultiplayer()
		ToggleShowFunc(obj, newTab)
	end

	local submenus = {
		{
			name = "Main Menu",
			titleText = "Main Menu",
			tabs = {
				{
					name = "multiplayer",
					control = battleListWindow,
					entryCheck = multiplayerentrycheck,
				},
				singleplayerConfig[1],
				singleplayerConfig[2],
				singleplayerConfig[3],
				{
					name = "replays",
					control = WG.ReplayHandler.GetControl()
				},
				Configuration.gameConfig.helpSubmenuConfig[1],
			},
		}
	}

	local battleStatusTabControls = {
		myBattle = WG.BattleStatusPanel.GetControl,
	}

	local battleTabHolder = Control:New {
		name = "battleTabHolder",
		caption = "", -- Battle and MM Status Window
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
	}

	local function UpdateTitle(newTitle)
		heading_image.file = Configuration:GetHeadingImage(doublePanelMode, newTitle)
		heading_image:Invalidate()
	end

	local battleStatusPanelHandler = GetTabPanelHandler("myBattlePanel", {
			buttonWindow        = battleTabHolder,
			displayPanel        = mainContent_window,
			initialTabs         = {},
			tabWidth            = statusButtonWidth,
			tabControlOverride  = battleStatusTabControls,
			analyticsName       = "lobby:battle"
		}
	)

	local rightPanelHandler = GetTabPanelHandler("panelTabs", {
			buttonWindow = panelButtons_buttons,
			displayPanel = rightPanel_window,
			initialTabs = rightPanelTabs,
			analyticsName = "lobby:panel",
		}
	)

	mainWindowHandler = GetSubmenuHandler(buttonsHolder_buttons, mainContent_window, submenuWindow_mainContent, submenus, UpdateTitle)

	--Spring.Utilities.TableEcho(buttonsHolder)

	local statusAndInvitesPanel = GetControlPanelHandler(holder_statusAndInvites)

	-------------------------------------------------------------------
	-- Resizing functions
	-------------------------------------------------------------------

	local function RescaleMainWindow(newFontSize, newButtonHeight, newButtonOffset, newButtonSpacing)
		mainWindowHandler.Rescale(newFontSize, newButtonHeight, newButtonOffset, newButtonSpacing)
		buttons_exit:SetPos(nil, nil, nil, newButtonHeight)

		ButtonUtilities.SetFontSizeScale(buttons_exit, newFontSize)
	end

	local function UpdateChildLayout()
		if doublePanelMode then
			chatWindows:ReattachTabHolder()

			rightPanelHandler.UpdateLayout(rightPanel_window, false)
			if not mainContent_window:IsEmpty() then
				local control, index = rightPanelHandler.GetManagedControlByName(mainContent_window.children[1].name)
				if control then
					mainContent_window:ClearChildren()
					mainContent_window:SetVisibility(false)
					rightPanelHandler.OpenTab(index)
				elseif rightPanel_window.visible then
					rightPanel_window:Hide()
				end
			elseif rightPanel_window.visible then
				rightPanel_window:Hide()
			end

		else
			chatWindows:SetTabHolderParent(holder_mainWindow, smallStatusLeftPadding + mainButtonsWidthSmall + 4, -9, chatTabHolderRight)

			rightPanelHandler.UpdateLayout(mainContent_window, true)
			if mainContent_window:IsEmpty() and not rightPanel_window:IsEmpty() then
				local panelChild = rightPanel_window.children[1]
				local control, index = rightPanelHandler.GetManagedControlByName(panelChild.name)
				rightPanelHandler.OpenTab(index)
			else
				rightPanel_window:ClearChildren()
			end
		end
	end

	local function UpdateDoublePanel(newDoublePanel)
		if newDoublePanel == doublePanelMode then
			return
		end
		doublePanelMode = newDoublePanel

		local topOffset = (showTopBar and topBarHeight) or 0

		if doublePanelMode then
			battleStatusPanelHandler.Rescale(2, nil, statusButtonWidth)
			RescaleMainWindow(3, 70, 50, buttonSpacingLarge)

			-- Make main buttons wider
			mainWindow_mainContent:SetPos(mainButtonsWidth, 0)
			mainWindow_mainContent._relativeBounds.right = 0
			mainWindow_mainContent._relativeBounds.bottom = 0
			mainWindow_mainContent:UpdateClientArea()

			--mainContent_window.color = VISIBLE_COLOR

			mainWindow_buttonsHolder:SetPos(nil, nil, mainButtonsWidth)

			-- Submenu window position
			holder_submenuWindow:SetPos(mainButtonsWidth, titleHeight + topOffset)
			holder_submenuWindow._relativeBounds.right = 0
			holder_submenuWindow._relativeBounds.bottom = 0
			holder_submenuWindow:UpdateClientArea()

			-- Move Panel Buttons
			buttonsHolder_buttons:RemoveChild(panelButtons_buttons)
			status_panelButtons:AddChild(panelButtons_buttons)

			panelButtons_buttons:SetPosRelative("0%","0%", "100%","100%")
			--buttonsHolder_buttons:SetPosRelative("0%","0%", nil,"100%")

			-- Make Main Window take up more space
			status_panelButtons:Show()
			holder_rightPanel:Show()
			holder_rightPanel:SetPos(nil, titleHeight + topOffset)
			holder_rightPanel._relativeBounds.bottom = 0
			holder_rightPanel:UpdateClientArea()

			holder_mainWindow:SetPos(nil, titleHeight + topOffset)
			if wideContentPlace then
				holder_mainWindow._relativeBounds.right = 0
			else
				holder_mainWindow._relativeBounds.right = panelWidthRel .. "%"
			end
			holder_mainWindow._relativeBounds.bottom = 0
			holder_mainWindow:UpdateClientArea()

			buttonsHolder_image:SetPos(nil, 0)
			buttonsHolder_image._relativeBounds.bottom = 0
			buttonsHolder_image:UpdateClientArea()

			-- Align game title and status.
			holder_heading:SetPos(0, topOffset, titleWidth, titleHeight)
			holder_status:SetPos(titleWidth, topOffset, titleHeight, titleHeight)
			holder_status._relativeBounds.right = 0
			holder_status:UpdateClientArea()

			status_userWindow._relativeBounds.bottom = panelButtonsHeight
			status_userWindow:UpdateClientArea()

			holder_topImage:SetPos(nil, topOffset, nil, titleHeight + imageFudge)

			--submenus[1][1].button.captionAlign = -10
			--ButtonUtilities.SetCaption(submenus[1][1].button, i18n("multiplayer_and_coop"))
		else
			rightPanelHandler.Rescale(2, 35, nil, nil, buttonSpacingSmall)
			battleStatusPanelHandler.Rescale(2, nil, statusButtonWidthSmall)
			RescaleMainWindow(2, 35, 46, buttonSpacingSmall)

			-- Make main buttons thinner
			mainWindow_mainContent:SetPos(mainButtonsWidthSmall, chatTabHolderHeight)
			mainWindow_mainContent._relativeBounds.right = 0
			mainWindow_mainContent._relativeBounds.bottom = 0
			mainWindow_mainContent:UpdateClientArea()

			--mainContent_window.color = INVISIBLE_COLOR

			mainWindow_buttonsHolder:SetPos(nil, nil, mainButtonsWidthSmall)

			-- Submenu window position
			holder_submenuWindow:SetPos(mainButtonsWidthSmall, titleHeightSmall + topOffset + chatTabHolderHeight)
			holder_submenuWindow._relativeBounds.right = 0
			holder_submenuWindow._relativeBounds.bottom = 0
			holder_submenuWindow:UpdateClientArea()

			-- Move Panel Buttons
			status_panelButtons:RemoveChild(panelButtons_buttons)
			buttonsHolder_buttons:AddChild(panelButtons_buttons)

			panelButtons_buttons:SetPosRelative("0%","44%", "100%","50%")
			--buttonsHolder_buttons:SetPosRelative("0%","0%", nil,"50%")

			-- Make Main Window take up more space
			status_panelButtons:Hide()
			status_panelButtons:ClearChildren()
			if holder_rightPanel.visible then
				holder_rightPanel:Hide()
			end
			holder_mainWindow:SetPos(nil, titleHeightSmall + topOffset)
			holder_mainWindow._relativeBounds.right = 0
			holder_mainWindow._relativeBounds.bottom = 0
			holder_mainWindow:UpdateClientArea()

			buttonsHolder_image:SetPos(nil, chatTabHolderHeight)
			buttonsHolder_image._relativeBounds.bottom = 0
			buttonsHolder_image:UpdateClientArea()

			-- Align game title and status.
			holder_heading:SetPos(0, topOffset, mainButtonsWidthSmall + padding, titleHeightSmall)
			holder_status:SetPos(mainButtonsWidthSmall, topOffset, titleHeightSmall, titleHeightSmall)
			holder_status._relativeBounds.right = 0
			holder_status:UpdateClientArea()

			status_userWindow._relativeBounds.bottom = 0
			status_userWindow:UpdateClientArea()

			holder_topImage:SetPos(nil, topOffset, nil, titleHeightSmall + imageFudge + chatTabHolderHeight)

			--submenus[1][1].button.captionAlign = 0
			--ButtonUtilities.SetCaption(submenus[1][1].button, i18n("multiplayer"))
		end

		heading_image.file = Configuration:GetHeadingImage(doublePanelMode, mainWindowHandler.GetSubheadingName())
		heading_image:Invalidate()

		UpdateChildLayout()
	end

	local function UpdatePadding(screenWidth, screenHeight)
		local leftPad, rightPad, bottomPad, middlePad
		if screenWidth < 1460 or (not doublePanelMode) then
			leftButtonPad = 0
			leftPad = 0
			rightPad = 0
			bottomPad = 0
			middlePad = 0
		elseif screenWidth < 1650 then
			leftButtonPad = 20
			leftPad = 5
			rightPad = 15
			bottomPad = 20
			middlePad = 10
		else
			leftButtonPad = 30
			leftPad = 10
			rightPad = 40
			bottomPad = 40
			middlePad = 20
		end

		mainContent_window:SetPos(leftPad)
		mainContent_window._relativeBounds.right = middlePad
		mainContent_window._relativeBounds.bottom = bottomPad
		mainContent_window:UpdateClientArea()

		rightPanel_window:SetPos(middlePad)
		rightPanel_window._relativeBounds.right = rightPad
		rightPanel_window._relativeBounds.bottom = bottomPad
		rightPanel_window:UpdateClientArea()

		submenuWindow_mainContent:SetPos(leftPad + leftButtonPad)
		submenuWindow_mainContent._relativeBounds.right = rightPad
		submenuWindow_mainContent._relativeBounds.bottom = bottomPad
		submenuWindow_mainContent:UpdateClientArea()

		status_panelButtons._relativeBounds.right = rightPad
		rightPanel_window:UpdateClientArea()

		buttons_exit._relativeBounds.bottom = (bottomPad > 0 and bottomPad) or 4
		buttons_exit:UpdateClientArea()

		mainWindow_buttonsHolder:SetPos(leftButtonPad)
		local contentOffset = leftButtonPad
		if doublePanelMode then
			contentOffset = contentOffset + mainButtonsWidth
		else
			contentOffset = contentOffset + mainButtonsWidthSmall
		end
		mainWindow_mainContent:SetPos(contentOffset)
		mainWindow_mainContent._relativeBounds.right = 0
		mainWindow_mainContent:UpdateClientArea()
	end

	local function SetWideContentPlace(newWideContentPlace)
		if doublePanelMode then
			if newWideContentPlace then
				holder_mainWindow._relativeBounds.right = 0
			else
				holder_mainWindow._relativeBounds.right = panelWidthRel .. "%"
			end
			holder_mainWindow._relativeBounds.bottom = 0
			holder_mainWindow:UpdateClientArea()
		end
	end


	-------------------------------------------------------------------
	-- Visibility and size handlers
	-------------------------------------------------------------------

	local function SetMainInterfaceVisible(newVisible)
		if lobbyInterfaceHolder.visible == newVisible then
			return
		end
		WG.SetGameInputBlock(newVisible)
		screen0:FocusControl()

		backgroundHolder:SetEnabled(newVisible and not showTopBar)
		ingameBackgroundHolder:SetEnabled(newVisible and showTopBar)

		if newVisible then
			lobbyInterfaceHolder:Show()
			ingameInterfaceHolder:Hide()
			lobbyInterfaceHolder:BringToFront()
		else
			lobbyInterfaceHolder:Hide()
			ingameInterfaceHolder:Show()
			ingameInterfaceHolder:BringToFront()
		end

		if WG.IngameInterface then
			WG.IngameInterface.SetLobbyOverlayActive(newVisible)
		end
	end

	local function SetTopBarVisible(newVisible)
		if newVisible == showTopBar then
			return
		end
		holder_topBar:SetVisibility(newVisible)
		showTopBar = newVisible

		local topOffset = (showTopBar and topBarHeight) or 0
		local titleOffset = (doublePanelMode and titleHeight) or titleHeightSmall

		if doublePanelMode then
			holder_submenuWindow:SetPos(nil, titleHeight + topOffset)
		else
			holder_submenuWindow:SetPos(nil, titleHeightSmall + topOffset + chatTabHolderHeight)
		end
		holder_submenuWindow._relativeBounds.right = 0
		holder_submenuWindow._relativeBounds.bottom = 0
		holder_submenuWindow:UpdateClientArea()

		holder_rightPanel:SetPos(nil, titleOffset + topOffset)
		holder_rightPanel._relativeBounds.bottom = 0
		holder_rightPanel:UpdateClientArea()

		holder_mainWindow:SetPos(nil, titleOffset + topOffset)
		holder_mainWindow._relativeBounds.bottom = 0
		holder_mainWindow:UpdateClientArea()

		holder_topImage:SetPos(nil, topOffset)
		holder_heading:SetPos(nil, topOffset)
		holder_status:SetPos(nil, topOffset)

		if showTopBar then
			buttonsHolder_image.color[4] = 0.0
			buttonsHolder_image:Invalidate()
			holder_topImage.color[4] = 0.0
			holder_topImage:Invalidate()
		else
			backgroundHolder:SetEnabled(true)
			ingameBackgroundHolder:SetEnabled(false)
			buttonsHolder_image.color[4] = 0.0
			buttonsHolder_image:Invalidate()
			holder_topImage.color[4] = 0.0
			holder_topImage:Invalidate()
		end

		local screenWidth, screenHeight = Spring.GetViewSizes()
		screen0:Resize(screenWidth, screenHeight)
	end

	local function UpdateStatusAndInvitesHolderPosition()
		local screenWidth, screenHeight = Spring.GetViewSizes()

		local xPos, yPos, width, height
		local controlCount = statusAndInvitesPanel.GetControlCount()

		if controlCount < 2 then
			width = statusButtonWidthSmall
		else
			width = statusButtonWidthSmall*2 + 6
		end

		if doublePanelMode then
			height = titleHeightSmall
			yPos = 4
			if screenWidth > 1540 or controlCount < 2 then
				yPos = 26
			end
			xPos = 20
		else
			height = titleHeightSmall
			yPos = 2
			xPos = 5
		end

		holder_statusAndInvites:SetPos(xPos, yPos, width, height)
	end

	statusAndInvitesPanel.SetUpdateFunction(UpdateStatusAndInvitesHolderPosition)

	-------------------------------------------------------------------
	-- Top bar initialisation
	-------------------------------------------------------------------

	local switchToMenuButton = Button:New {
		y = 2,
		right = 3,
		width = 108,
		height = 38,
		name = "switchToMenuButton",
		caption = "Menu",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		parent = ingameInterfaceHolder,
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},

		OnClick = {
			function ()
				SetMainInterfaceVisible(true)
			end
		}
	}
	local switchToGameButton = Button:New {
		y = 2,
		right = 3,
		width = 165,
		height = 38,
		name = "switchToGameButton",
		caption = "Return to Battle",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		parent = holder_topBar,
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},

		OnClick = {
			function ()
				SetMainInterfaceVisible(false)
			end
		}
	}

	local function LeaveGameFunction()
		Spring.Reload("")
	end

	local leaveGameButton = Button:New {
		y = 2,
		right = 171,
		width = 162,
		height = 38,
		name = "leaveGameButton",
		caption = "Leave Battle",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		parent = holder_topBar,
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},

		OnClick = {
			function ()
				ConfirmationPopup(LeaveGameFunction, "Are you sure you want to leave the battle?", nil, 315, 200)
			end
		}
	}

	local topBarImage = Image:New {
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		file = IMAGE_TOP_BACKGROUND,
		parent = holder_topBar,
		keepAspect = false,
		color = {0, 0, 0, 0.0},
	}

	-------------------------------------------------------------------
	-- External Functions
	-------------------------------------------------------------------

	function externalFunctions.UpdateStatusAndInvitesHolderPosition()
		UpdateStatusAndInvitesHolderPosition()
	end

	function externalFunctions.ViewResize(screenWidth, screenHeight)
		if autodetectDoublePanel then
			local newDoublePanel = minScreenWidth <= screenWidth
			UpdateDoublePanel(newDoublePanel)
		end
		UpdatePadding(screenWidth, screenHeight)

		UpdateStatusAndInvitesHolderPosition()
	end

	function externalFunctions.SetBattleTabHolderVisible(newVisible, rank)
		local oldVisible = ((statusAndInvitesPanel.GetChildByName(battleTabHolder.name) and true) or false)
		if oldVisible == newVisible then
			return
		end

		if newVisible then
			statusAndInvitesPanel.AddControl(battleTabHolder, rank or 0)
		else
			statusAndInvitesPanel.RemoveControl(battleTabHolder.name)
		end
	end

	function externalFunctions.OpenMultiplayerTabByName(name)
		-- name = nil just opens the MP menu.
		mainWindowHandler.SetBackAtMainMenu()
		mainWindowHandler.OpenSubmenu(MULTIPLAYER_INDEX, name)
	end

	function externalFunctions.OpenSingleplayerTabByName(name)
		-- name = nil just opens the SP menu.
		mainWindowHandler.SetBackAtMainMenu()
		mainWindowHandler.OpenSubmenu(SINGLEPLAYER_INDEX, name)
	end

	function externalFunctions.GetSingleplayerSubmenu()
		return mainWindowHandler.GetPanelHander(SINGLEPLAYER_INDEX)
	end

	function externalFunctions.GetMultiplayerSubmenu()
		return mainWindowHandler.GetPanelHander(MULTIPLAYER_INDEX)
	end

	function externalFunctions.SetPanelDisplayMode(newAutodetectDoublePanel, newDoublePanel)
		autodetectDoublePanel = newAutodetectDoublePanel
		local screenWidth, screenHeight = Spring.GetViewSizes()
		if autodetectDoublePanel then
			UpdateDoublePanel(screenWidth > minScreenWidth)
		else
			UpdateDoublePanel(newDoublePanel)
		end
		UpdatePadding(screenWidth, screenHeight)
		UpdateStatusAndInvitesHolderPosition()
		-- Make all children request realign.
		screen0:Resize(screenWidth, screenHeight)
	end

	function externalFunctions.SetWideContentPlace(newWideContentPlace)
		if wideContentPlace == newWideContentPlace then
			return
		end
		SetWideContentPlace(newWideContentPlace)
	end

	function externalFunctions.SetIngame(newIngame)
		gameRunning = not newIngame
		SetMainInterfaceVisible(not newIngame)
		SetTopBarVisible(newIngame)
		UpdateStatusAndInvitesHolderPosition()
	end

	function externalFunctions.SetMainInterfaceVisible(newVisible)
		SetMainInterfaceVisible(newVisible)
	end

	function externalFunctions.GetChatWindow()
		return chatWindows
	end

	function externalFunctions.OpenPrivateChat(userName)
		chatWindows:GetPrivateChatConsole(userName, true)
		rightPanelHandler.OpenTabByName("chat")
	end

	function externalFunctions.OpenRightPanelTab(tabName)
		rightPanelHandler.OpenTabByName(tabName)
	end

	function externalFunctions.GetContentPlace()
		return mainContent_window
	end

	function externalFunctions.GetStatusWindow()
		return holder_status
	end

	function externalFunctions.GetMainWindowHandler()
		return mainWindowHandler
	end

	function externalFunctions.GetRightPanelHandler()
		return rightPanelHandler
	end

	function externalFunctions.GetBattleStatusWindowHandler()
		return battleStatusPanelHandler
	end

	function externalFunctions.GetStatusAndInvitesPanel()
		return statusAndInvitesPanel
	end

	function externalFunctions.GetDoublePanelMode()
		return doublePanelMode
	end

	function externalFunctions.CleanMultiplayerState()
		CleanMultiplayerState(true)
	end

	function externalFunctions.KeyPressed(key, mods, isRepeat, label, unicode)
		if not lobbyInterfaceHolder.visible then
			return false
		end
		if globalKeyListener then
			return globalKeyListener(key, mods, isRepeat, label, unicode)
		end
		if (not isRepeat) and showTopBar and key == Spring.GetKeyCode("f11") then
			SetMainInterfaceVisible(false)
			return true
		end
		if chatWindows.visible and key == Spring.GetKeyCode("tab") and mods.ctrl then
			if mods.shift then
				chatWindows:CycleTab(-1)
			else
				chatWindows:CycleTab(1)
			end
			return true
		end
		if key == Spring.GetKeyCode("esc") then
			if showTopBar then
				SetMainInterfaceVisible(false)
				return true
			end
			if rightPanelHandler.CloseTabs() or mainWindowHandler.CloseTabs() or
					(backgroundCloseListener and backgroundCloseListener()) or
					mainWindowHandler.BackOneLevel() or MakeExitPopup() then
				return false
			end
		end
		return false
	end

	function externalFunctions.SetGlobalKeyListener(newListenerFunc)
		-- This is intentially set up such that there is only one global key
		-- listener at a time. This is indended for popups that monopolise input.
		globalKeyListener = newListenerFunc
	end

	function externalFunctions.SetBackgroundCloseListener(newListenerFunc)
		-- This is intentially set up such that there is only one global key
		-- listener at a time. This is indended for popups that monopolise input.
		backgroundCloseListener = newListenerFunc
	end

	function externalFunctions.GetIngameInterfaceHolder()
		return ingameInterfaceHolder
	end

	function externalFunctions.GetLobbyInterfaceHolder()
		return lobbyInterfaceHolder
	end

	function externalFunctions.GetBackgroundHolder()
		return backgroundHolder
	end

	function externalFunctions.GetCachingImage()
		return cachingImage
	end

	function externalFunctions.GetCachingLabel()
		return cachingLabel
	end

	function externalFunctions.SetLobbyButtonEnabled(newEnabled)
		Spring.Echo("SetLobbyButtonEnabled", newEnabled)
		if ingameInterfaceHolder:GetChildByName("switchToMenuButton") then
			switchToMenuButton:SetVisibility(newEnabled)
		else
			Spring.Echo("Missing switchToMenuButton")
		end
	end

	function externalFunctions.TryToJoinBattle(battleID)
		local battle = battleID and lobby:GetBattle(battleID)
		if battle and (Configuration.displayBadEngines2 or Configuration:IsValidEngineVersion(battle.engineVersion)) then
			battleListWindowJoinBattle(battle)
		end
	end
	-------------------------------------------------------------------
	-- Listening
	-------------------------------------------------------------------
	local function onConfigurationChange(listener, key, value)
		if key == "panel_layout" then
			if value == 1 then
				externalFunctions.SetPanelDisplayMode(true)
			elseif value == 2 then
				externalFunctions.SetPanelDisplayMode(false, true)
			elseif value == 3 then
				externalFunctions.SetPanelDisplayMode(false, false)
			end
		elseif key == "gameConfigName" or key == "campaignConfigName" then
			Spring.Echo("interface_root:onConfigurationChange",listener, key, value)
			heading_image.file = Configuration:GetHeadingImage(doublePanelMode, mainWindowHandler.GetSubheadingName())
			heading_image:Invalidate()

			WG.BattleRoomWindow.LeaveBattle(false, true)

		end
	end
	Configuration:AddListener("OnConfigurationChange", onConfigurationChange)

	local function CheckHideInterface()
		if #(screen0.children or {}) > 3 then
			-- The three children are two background holders and either the lobby or ingame interface holder.
			-- If there are more than three children then a global popup has appeared.
			return false
		end
		if not ingameInterfaceHolder.visible then
			return false
		end
		return #(ingameInterfaceHolder.children or {}) == 0
	end

	local oldTotalHideInterface = false
	function WG.CheckTotalHideInterface()
		local newHide = CheckHideInterface()
		if newHide ~= oldTotalHideInterface then
			Spring.Echo("TotalHideLobbyInterface", newHide)
			oldTotalHideInterface = newHide
		end
		return newHide
	end

	-------------------------------------------------------------------
	-- Initialization
	-------------------------------------------------------------------
	local screenWidth, screenHeight = Spring.GetViewSizes()

	mainWindowHandler.OpenSubmenu(1)

	battleStatusPanelHandler.Rescale(2, 70)
	rightPanelHandler.Rescale(2, 70)
	RescaleMainWindow(3, 70, 50)

	externalFunctions.ViewResize(screenWidth, screenHeight)
	UpdatePadding(screenWidth, screenHeight)
	UpdateChildLayout()

	return externalFunctions
end

return GetInterfaceRoot
