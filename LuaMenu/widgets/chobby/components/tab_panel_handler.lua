function GetTabPanelHandler(name, conf)

	local buttonWindow        = conf.buttonWindow
	local displayPanel        = conf.displayPanel
	local submenuDisplayPanel = conf.submenuDisplayPanel
	local initialTabs         = conf.initialTabs
	local tabsVertical        = conf.tabsVertical
	local backFunction        = conf.backFunction
	local cleanupFunction     = conf.cleanupFunction
	local fontSizeScale       = conf.fontSizeScale
	local tabWidth            = conf.tabWidth
	local tabControlOverride  = conf.tabControlOverride
	local submenuControl      = conf.submenuControl
	local titleUpdateFunction = conf.titleUpdateFunction
	local analyticsName       = conf.analyticsName
	local hideMyButtons       = conf.hideMyButtons
	local startWithTabOpen    = conf.startWithTabOpen

	local externalFunctions = {}

	-- Matches interface root and submenu handler
	local buttonSpacing = 4
	local BUTTON_SIDE_SPACING = 1

	-------------------------------------------------------------------
	-- Local variables
	-------------------------------------------------------------------
	local buttonsHolder

	local fontSizeScale = fontSizeScale or 3
	local buttonOffset = 0
	local buttonWidth = tabWidth
	local buttonHeight = 70

	local backButton

	local tabs = {}

	-------------------------------------------------------------------
	-- Local functions
	-------------------------------------------------------------------

	local function SetSubmenuDisplayVisibility(newVisibility)
		if not (submenuDisplayPanel and submenuControl) then
			return
		end
		if newVisibility then
			submenuDisplayPanel:AddChild(submenuControl)
		else
			submenuDisplayPanel:ClearChildren()
		end
		submenuDisplayPanel:SetVisibility(newVisibility)
	end

	local function OpenSubmenu(panelHandler)
		externalFunctions.Hide()
		panelHandler.Show()
	end

	local function ToggleShow(obj, tab, openOnly, closeOnly)
		if analyticsName then
			WG.Analytics.SendOnetimeEvent(analyticsName .. ":" .. tab.name)
		end
		if tab.panelHandler then
			OpenSubmenu(tab.panelHandler)
			return true
		end

		local control = tab.control
		if not control then
			return false
		end

		if displayPanel.visible then
			if displayPanel:GetChildByName(control.name) then
				if not openOnly then
					displayPanel:ClearChildren()
					return true
				end
				return false
			end
		end

		if closeOnly then
			return false
		end

		displayPanel:ClearChildren()
		displayPanel:AddChild(control)
		if not displayPanel.visible then
			displayPanel:Show()
		end

		ButtonUtilities.SetButtonSelected(obj)
		return true
	end

	local function SetButtonPositionAndSize(index)
		if tabsVertical then
			tabs[index].button:SetPos(
				BUTTON_SIDE_SPACING,
				(index - 1) * (buttonHeight + buttonSpacing) + buttonOffset,
				nil,
				buttonHeight
			)
			tabs[index].button._relativeBounds.right = BUTTON_SIDE_SPACING
			tabs[index].button:UpdateClientArea()
		elseif buttonWidth then
			tabs[index].button:SetPos(
				(index - 1) * (buttonWidth + buttonSpacing) + buttonOffset,
				nil,
				buttonWidth
			)
			tabs[index].button._relativeBounds.right = nil
			tabs[index].button:SetPosRelative(
				nil,
				"0%",
				nil,
				"100%"
			)
		else
			local buttonSize = 100/#tabs
			local pos = (index - 1)*buttonSize .. "%"
			tabs[index].button._relativeBounds.right = nil
			tabs[index].button:SetPosRelative(
				(index - 1)*buttonSize .. "%",
				0,
				buttonSize .. "%",
				"100%"
			)
		end
	end

	local function UpdateButtonLayout(newTabsVertical)
		if newTabsVertical ~= nil then
			tabsVertical = newTabsVertical
		end
		for i = 1, #tabs do
			SetButtonPositionAndSize(i)
		end
	end


	local function OpenConfirmationPopup(sucessFunction)
		local backConfirm = Configuration.backConfirmation[name]
		if not backConfirm then
			return false
		end
		for i = 1, #backConfirm do
			local confirmData = backConfirm[i]
			if (not Configuration[confirmData.doNotAskAgainKey]) and confirmData.testFunction() then
				ConfirmationPopup(sucessFunction, confirmData.question, confirmData.doNotAskAgainKey)
				return true
			end
		end
		return false
	end

	local function IsTabSelectedByIndex(index, tabName)
		return tabs[index].control and tabs[index].control.parent and tabs[index].control.visible and ((not tabName) or tabName == tabs[index].name)
	end

	-------------------------------------------------------------------
	-- External Functions
	-------------------------------------------------------------------
	function externalFunctions.UpdateLayout(panelParent, newTabsVertical)
		displayPanel = panelParent
		UpdateButtonLayout(newTabsVertical)
	end

	function externalFunctions.Hide()
		if displayPanel.children[1] and externalFunctions.GetManagedControlByName(displayPanel.children[1].name) then
			displayPanel:ClearChildren()
			if displayPanel.visible then
				displayPanel:Hide()
			end
		end

		SetSubmenuDisplayVisibility(false)
		buttonsHolder:SetVisibility(false)
	end

	function externalFunctions.Show()
		SetSubmenuDisplayVisibility(true)
		buttonsHolder:SetVisibility(true)
		if titleUpdateFunction then
			titleUpdateFunction(name)
		end
		if startWithTabOpen then
			externalFunctions.OpenTab(startWithTabOpen)
		end
	end

	function externalFunctions.IsVisible()
		return buttonsHolder.visible
	end

	function externalFunctions.IsTabSelected(tabName)
		for i = 1, #tabs do
			if IsTabSelectedByIndex(i, tabName) then
				return true
			end
		end
		return false
	end

	function externalFunctions.Rescale(newFontSize, newButtonHeight, newButtonWidth, newButtonOffset, newButtonSpacing)
		for i = 1, #tabs do
			if tabs[i].panelHandler then
				tabs[i].panelHandler.Rescale(newFontSize, newButtonHeight, newButtonWidth, newButtonOffset)
			end
		end

		fontSizeScale = newFontSize or fontSizeScale
		buttonWidth = newButtonWidth or buttonWidth
		buttonHeight = newButtonHeight or buttonHeight
		buttonSpacing = newButtonSpacing or buttonSpacing

		if newButtonOffset then
			buttonOffset = newButtonOffset - buttonSpacing
		end
		if backButton then
			local size = Configuration:GetFont(fontSizeScale).size
			local buttonSize = math.floor(size * 1.75)
			local horSpacing = math.floor(size * 1.2)
			backButton:SetPos(horSpacing, nil, nil, buttonSize)
			backButton._relativeBounds.right = horSpacing
			backButton:UpdateClientArea()
		end

		for i = 1, #tabs do
			if tabs[i].button then
				SetButtonPositionAndSize(i)
				ButtonUtilities.SetFontSizeScale(tabs[i].button, fontSizeScale)
			end
		end
		if backButton then
			ButtonUtilities.SetFontSizeScale(backButton, fontSizeScale)
		end
	end

	function externalFunctions.OpenTab(tabIndex)
		if tabs[tabIndex] then
			ToggleShow(tabs[tabIndex].button, tabs[tabIndex], true)
		end
	end

	function externalFunctions.CloseTabs()
		for i = 1, #tabs do
			if IsTabSelectedByIndex(i, tabs[i].name) then
				return ToggleShow(tabs[i].button, tabs[i], nil, true)
			end
		end
		return false
	end

	function externalFunctions.CloseSubTabs()
		for i = 1, #tabs do
			if tabs[i].panelHandler then
				local tabsClosed = tabs[i].panelHandler.CloseTabs()
				local isSelected = tabs[i].panelHandler.CloseSubTabs()
				if isSelected or tabsClosed then
					return isSelected or tabsClosed, tabsClosed
				end
			end
		end
		return false, false
	end

	function externalFunctions.OpenTabByName(tabName)
		for i = 1, #tabs do
			if tabs[i].name == tabName then
				externalFunctions.OpenTab(i)
				return
			end
		end
	end

	function externalFunctions.GetTabByName(tabName)
		for i = 1, #tabs do
			if tabs[i].name == tabName then
				return i
			end
		end
	end

	function externalFunctions.GetSubmenuByName(tabName)
		for i = 1, #tabs do
			if tabs[i].name == tabName then
				return tabs[i].panelHandler
			end
		end
	end

	function externalFunctions.GetManagedControlByName(controlName)
		for i = 1, #tabs do
			if tabs[i].control and tabs[i].control.name == controlName then
				return tabs[i].control, i
			end
		end
		return false
	end

	function externalFunctions.Destroy()
		for i = 1, #tabs do
			if tabs[i].control then
				tabs[i].control:Dispose()
			end
			tabs[i].button:Dispose()
		end
		buttonsHolder:Dispose()
		tabs = nil
	end

	function externalFunctions.RemoveTab(name, killControl)
		local index = 1
		local found = false
		while index <= #tabs do
			if found then
				tabs[index] = tabs[index + 1]
				index = index + 1
			elseif tabs[index].name == name then
				tabs[index].button:Dispose()
				if killControl then
					tabs[index].control:Dispose()
				end
				found = true
			else
				index = index + 1
			end
		end
		if found then
			UpdateButtonLayout()
		end
	end

	function externalFunctions.SetActivity(tabName, activityCount, priorityLevel)
		priorityLevel = priorityLevel or 1
		activityCount = activityCount or 0
		for i = 1, #tabs do
			local tab = tabs[i]
			if tab.name == tabName and tab.activityLabel then
				local activityLabel
				if activityCount > 0 then
					tab.priorityLevel = math.max(priorityLevel, tab.priorityLevel or 1)
					activityLabel = "(" .. tostring(activityCount) .. ")"
				else
					tab.priorityLevel = 1
					activityLabel = ""
				end
				if tab.priorityLevel == 1 then
					tab.activityLabel.font.outline = true
					tab.activityLabel.font.outlineColor = {1,1,1,1}
					tab.activityLabel.font.color = {1,1,1,1}
				elseif tab.priorityLevel == 2 then
					tab.activityLabel.font.outline = true
					tab.activityLabel.font.outlineColor = {1,0,0,1}
					tab.activityLabel.font.color = {1,0,0,1}
				else
					tab.activityLabel.font.outline = true
					tab.activityLabel.font.outlineColor = {0.8,1,0,1}
					tab.activityLabel.font.color = {0.8,1,0,1}
				end
				tab.activityLabel:SetCaption(activityLabel)
			end
		end
	end

	function externalFunctions.SetTabHighlighted(tabName, onlyIfNotSelected)
		for i = 1, #tabs do
			local tab = tabs[i]
			if tab.name == tabName and not (onlyIfNotSelected and IsTabSelectedByIndex(i, tabName)) then
				ButtonUtilities.SetButtonHighlighted(tab.button)
			end
		end
	end

	function externalFunctions.SetTabCaption(name, caption)
		for i = 1, #tabs do
			if tabs[i].name == name and tabs[i].activityLabel then
				ButtonUtilities.SetCaption(tabs[i].button, caption)
			end
		end
	end

	function externalFunctions.AddTab(name, humanName, control, onClick, rank, selected, entryCheck, submenuData, entryCheckBootMode)
		local newTab = {}

		newTab.name = name
		newTab.rank = rank or (#tabs + 1)
		newTab.control = control
		newTab.entryCheck = entryCheck
		newTab.entryCheckBootMode = entryCheckBootMode
		local button

		if tabControlOverride and tabControlOverride[name] then
			button = tabControlOverride[name](fontSizeScale)
		else
			button = Button:New {
				name = name .. "_button",
				x = "0%",
				y = "0%",
				width = "100%",
				height = "100%",
				padding = {0,0,0,0},
				caption = humanName,
				font = Configuration:GetFont(fontSizeScale),
			}
		end

		if not hideMyButtons then
			buttonsHolder:AddChild(button)
		end
		ButtonUtilities.SetFontSizeScale(button, fontSizeScale)

		button.OnClick = button.OnClick or {}
		button.OnClick[#button.OnClick + 1] = function(obj)
			if newTab.entryCheck then
				if newTab.entryCheckBootMode then
					newTab.entryCheck()
					ToggleShow(obj, newTab)
				else
					newTab.entryCheck(ToggleShow, obj, newTab)
				end
			else
				ToggleShow(obj, newTab)
			end
		end

		if submenuData then
			local function BackToSubmenu(subPanelHandler)
				subPanelHandler.Hide()
				externalFunctions.Show()

				if displayPanel.children[1] and subPanelHandler.GetManagedControlByName(displayPanel.children[1].name) then
					displayPanel:ClearChildren()
					if displayPanel.visible then
						displayPanel:Hide()
					end
				end
			end

			local subConfg = {
				buttonWindow = buttonWindow,
				displayPanel = displayPanel,
				submenuDisplayPanel = submenuDisplayPanel,
				initialTabs = submenuData.tabs,
				tabsVertical = tabsVertical,
				backFunction = BackToSubmenu,
				cleanupFunction = submenuData.cleanupFunction,
				fontSizeScale = fontSizeScale,
				tabWidth = tabWidth,
				tabControlOverride = tabControlOverride,
				submenuControl = submenuData.submenuControl,
				titleUpdateFunction = titleUpdateFunction,
				analyticsName = (analyticsName and (analyticsName .. ":" .. name)) or nil,
				hideMyButtons = submenuData.hideMyButtons,
				startWithTabOpen = submenuData.startWithTabOpen,
			}

			local panelHandler = GetTabPanelHandler(name, subConfg)
			panelHandler.Hide()
			newTab.panelHandler = panelHandler
		end

		newTab.activityLabel = Label:New {
			name = "activity_label",
			y = 2,
			right = 2,
			width = 50,
			height = 5,
			valign = "top",
			align = "right",
			parent = button,
			font = Configuration:GetFont(1),
			caption = "",
		}

		newTab.activityLabel:BringToFront()

		if selected then
			ToggleShow(button, newTab)
		end

		if control then
			control.OnOrphan = control.OnOrphan or {}
			control.OnOrphan[#control.OnOrphan + 1] = function(obj)
				ButtonUtilities.SetButtonDeselected(button)

				if (displayPanel:IsEmpty() or displayPanel:GetChildByName(control.name))
						and displayPanel.visible then
					displayPanel:Hide()
				end
			end
		end

		newTab.button = button

		local index = #tabs + 1
		while index > 1 and newTab.rank < tabs[index - 1].rank do
			tabs[index] = tabs[index - 1]
			index = index - 1
		end
		tabs[index] = newTab

		UpdateButtonLayout()
	end

	function externalFunctions.CloseSubmenu()
		local closedSubmenu = false
		for i = 1, #tabs do
			if tabs[i].panelHandler then
				closedSubmenu = tabs[i].panelHandler.CloseSubmenu() or closedSubmenu
			end
		end

		externalFunctions.Hide()
		if externalFunctions.IsTabSelected() then
			return true
		end
		return closedSubmenu
	end

	function externalFunctions.BackOneLevel()
		if externalFunctions.IsVisible() then
			backFunction(externalFunctions)
			return true
		end
		for i = 1, #tabs do
			if tabs[i].panelHandler and tabs[i].panelHandler.BackOneLevel() then
				return true
			end
		end
		return false
	end

	-------------------------------------------------------------------
	-- Initialization
	-------------------------------------------------------------------
	buttonsHolder = Control:New {
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		name = "buttons_" .. name,
		parent = buttonWindow,
		padding = {0, 0, 0, 0},
		children = {}
	}

	if backFunction then
		-- Add back button
		buttonOffset = 50 - buttonSpacing

		local function SucessFunction()
			if cleanupFunction then
				cleanupFunction() -- Cleans up state information created by the submenu
			end
			backFunction(externalFunctions) -- Returns UI to main menu
		end

		local size = Configuration:GetFont(fontSizeScale).size
		local buttonSize = math.min(size * 1.5)
		backButton = Button:New {
			name = name .. "_back_button",
			x = 16,
			y = 4,
			right = 16,
			height = buttonSize,
			caption = "      Back",
			padding = {1,0,1,1},
			font = Configuration:GetFont(fontSizeScale),
			children = {
				Image:New {
					x = 0,
					y = 0,
					bottom = 1,
					width = "50%",
					file = LUA_DIRNAME .. "widgets/chobby/images/left.png",
				}
			},
			parent = buttonsHolder,
			OnClick = {
				function (obj)
					if OpenConfirmationPopup(SucessFunction) then
						return
					end
					SucessFunction()
				end
			},
		}
	end

	for i = 1, #initialTabs do
		externalFunctions.AddTab(
			initialTabs[i].name,
			i18n(initialTabs[i].name),
			initialTabs[i].control,
			nil, nil, nil,
			initialTabs[i].entryCheck,
			initialTabs[i].submenuData,
			initialTabs[i].entryCheckBootMode
		)
	end

	externalFunctions.Rescale()

	return externalFunctions
end
