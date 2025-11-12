function widget:GetInfo()
	return {
		name    = 'Modoptions Panel',
		desc    = 'Implements the modoptions panel.',
		author  = 'GoogleFrog',
		date    = '29 July 2016',
		license = 'GNU GPL v2',
		layer   = 0,
		enabled = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Structure
local modoptionDefaults = {}
local modoptionStructure = {}

-- Variables
local battleLobby
local localModoptions = {}
local modoptionControlNames = {}
local modoptions
local modoptionsByGame = {}

-- constants
local MARKED_AS_CHANGED_COLOR = {0.99, 0.75, .3, 1} -- {0.07, 0.66, 0.92, 1.0}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utility Function

local function UpdateControlValue(key, value)
	if not modoptionControlNames then
		return
	end
	local control = modoptionControlNames[key]
	if control then
		if control.SetText then -- editbox
			control:SetText(value)
			control:FocusUpdate()
		elseif control.Select and control.itemKeyToName then -- combobox
			control:Select(control.itemKeyToName[value])
		elseif control.SetToggle then -- checkbox
			control:SetToggle(value == true or value == 1 or value == "1")
		end
	end
end

local function TextFromNum(num, step)

	-- remove excess accuracy
	local places = 0
	if step < 0.01  then
		places = 3
	elseif step < 0.1 then
		places = 2
	elseif step < 1 then
		places = 1
	end
	local text = string.format("%." .. places .. "f", num)

	-- remove trailing 0s
	while text:find("%.") and (text:find("0", text:len()) or text:find("%.", text:len())) do
		text = text:sub(0, text:len() - 1)
	end

	return text
end

local function getModOptionByKey(key)
	local retOption = {}
	for _, option in ipairs(modoptions) do
		if option.key and option.key == key then
			retOption = option
			break
		end
	end
	return retOption
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Lock Handling
local lockedOptions = {}
local postLock = {}
local function processChildrenLocks(unlock, lock, bitmask)
	local item, itemLock, child

	if unlock then for i = 1, #unlock do
		item = unlock[i]
		itemLock = lockedOptions[item]
		if itemLock then
			itemLock = math.bit_and(math.bit_inv(bitmask), itemLock)
			if itemLock > 0 then
				lockedOptions[item] = itemLock
			else
				lockedOptions[item] = nil
				child = modoptionControlNames[item]
				if child then
					if child.parent.name ~= "tabPanel" then
						child = child.parent
					end
					local tabPanel, cachedY = child.parent, child.rowOrginal
					child:SetPos(child.x - 4095)

					for j = 1, #tabPanel.children do
						if tabPanel.children[j].rowOrginal > cachedY then
							tabPanel.children[j]:SetPos(nil, tabPanel.children[j].y + 32)
						end
					end
				end
			end
		end
	end end

	if lock then for i = 1, #lock do
		item = lock[i]
		itemLock = lockedOptions[item] or 0
		if itemLock == 0 then
			child = modoptionControlNames[item]
			if child then
				if child.parent.name ~= "tabPanel" then
					child = child.parent
				end
				local tabPanel, cachedY = child.parent, child.rowOrginal
				child:SetPos(child.x + 4095)

				for j = 1, #tabPanel.children do
					if tabPanel.children[j].rowOrginal > cachedY then
						tabPanel.children[j]:SetPos(nil, tabPanel.children[j].y - 32)
					end
				end
			end
		end
		itemLock = math.bit_or(itemLock, bitmask)
		lockedOptions[item] = itemLock
	end end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Option Control Handling

local function ProcessListOption(data, index)
	local control

	local defaultItem = 1
	local defaultKey = localModoptions[data.key] or data.def

	local lock, unlock, locking = {}, {}, false
	local items = {}
	local itemNameToKey = {}
	local itemKeyToName = {}
	local itemsTooltips = {}
	for i, itemData in pairs(data.items) do
		items[i] = itemData.name
		itemNameToKey[itemData.name] = itemData.key
		itemKeyToName[itemData.key] = itemData.name

		if itemData.key == defaultKey then
			defaultItem = i
			if itemData.lock then
				postLock[#postLock+1] = {itemData.lock, data.bitmask or 1, data.name}
			end
		end

		if itemData.desc then
			itemsTooltips[i] = itemData.desc
		end

		if itemData.lock or itemData.unlock then
			lock[itemData.key] = itemData.lock
			unlock[itemData.key] = itemData.unlock
			locking = true
		end
	end

	local label = Label:New {
		x = 5,
		y = 0,
		width = 320,
		height = 30,
		valign = "center",
		align = "left",
		caption = data.name,
		objectOverrideFont = data.def == defaultKey and WG.Chobby.Configuration:GetFont(2) or WG.Chobby.Configuration:GetFont(2, "Changed2", {color = MARKED_AS_CHANGED_COLOR}),
		tooltip = data.desc,
	}

	local list
	list = ComboBox:New {
		x = 325,
		y = 1,
		width = 300,
		height = 30,
		valign = "center",
		align = "left",
		items = items,
		itemsTooltips = itemsTooltips,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		selectByName = true,
		selected = defaultItem,
		OnSelectName =
			locking and { function (obj, selectedName)
				processChildrenLocks(unlock and unlock[itemNameToKey[selectedName]] or nil, lock and lock[itemNameToKey[selectedName]] or nil, data.bitmask or 1)
				if itemNameToKey[selectedName] == data.def then
						label.font = WG.Chobby.Configuration:GetFont(2)
						list.font = WG.Chobby.Configuration:GetFont(2)
				else
						label.font = WG.Chobby.Configuration:GetFont(2, "Changed2", {color = MARKED_AS_CHANGED_COLOR})
						list.font = WG.Chobby.Configuration:GetFont(2, "Changed2", {color = MARKED_AS_CHANGED_COLOR})
				end
				localModoptions[data.key] = itemNameToKey[selectedName]
			end
		} or
			{function (obj, selectedName)	
				if itemNameToKey[selectedName] == data.def then
						label.font = WG.Chobby.Configuration:GetFont(2)
						list.font = WG.Chobby.Configuration:GetFont(2)
				else
						label.font = WG.Chobby.Configuration:GetFont(2, "Changed2", {color = MARKED_AS_CHANGED_COLOR})
						list.font = WG.Chobby.Configuration:GetFont(2, "Changed2", {color = MARKED_AS_CHANGED_COLOR})
				end
				localModoptions[data.key] = itemNameToKey[selectedName]
			end
		},
		itemKeyToName = itemKeyToName, -- Not a chili key
		tooltip = data.desc,
	}
	list.font = data.def == defaultKey and WG.Chobby.Configuration:GetFont(2) or WG.Chobby.Configuration:GetFont(2, "Changed2", {color = MARKED_AS_CHANGED_COLOR})

	modoptionControlNames[data.key] = list
	control = Control:New {
		x = 0,
		y = index*32,
		width = 625,
		height = 32,
		padding = {0, 0, 0, 0},
		tooltip = data.desc,
		greedyHitTest = data.desc ~= nil,
		children = {
			label,
			list,
		}
	}
	return control
end

local function ProcessBoolOption(data, index)
	local checked = false
	if localModoptions[data.key] == nil then
		if modoptionDefaults[data.key] == "1" then
			checked = true
		end
	elseif localModoptions[data.key] == "1" then
		checked = true
	end

	local control

	local label = Label:New {
		x = 5,
		y = 0,
		width = 320,
		height = 30,
		valign = "center",
		align = "left",
		caption = data.name,
		objectOverrideFont =
			(checked and "1" or "0") == modoptionDefaults[data.key] and WG.Chobby.Configuration:GetFont(2)
			or WG.Chobby.Configuration:GetFont(2, "Changed2", {color = MARKED_AS_CHANGED_COLOR}),
		tooltip = data.desc,
	}

	local checkBox = Checkbox:New {
		x = 320,
		y = 0,
		width = 30,
		height = 30,
		boxalign = "right",
		boxsize = 25,
		caption = "",
		checked = checked,
		tooltip = data.desc,
		OnChange =
			(data.unlock or data.lock) and { function (obj, newState)
				if newState then -- on enable
					processChildrenLocks(data.unlock, data.lock, data.bitmask or 1)
				else -- on disable
					processChildrenLocks(data.lock, data.unlock, data.bitmask or 1)
				end
				localModoptions[data.key] = tostring((newState and 1) or 0)
				if (newState and modoptionDefaults[data.key] == "1") or (not newState and modoptionDefaults[data.key] == "0") then
					label.font = WG.Chobby.Configuration:GetFont(2)
				else
					label.font = WG.Chobby.Configuration:GetFont(2, "Changed2", {color = MARKED_AS_CHANGED_COLOR})
				end
			end
		} or
			{ function (obj, newState)
				if (newState and modoptionDefaults[data.key] == "1") or (not newState and modoptionDefaults[data.key] == "0") then
					label.font = WG.Chobby.Configuration:GetFont(2)
				else
					label.font = WG.Chobby.Configuration:GetFont(2, "Changed2", {color = MARKED_AS_CHANGED_COLOR})
				end
				localModoptions[data.key] = tostring((newState and 1) or 0)
			end
		},
	}

	if checked then
		if data.lock then
			postLock[#postLock+1] = {data.lock, data.bitmask or 1, data.name}
		end 
	elseif data.unlock then
		postLock[#postLock+1] = {data.unlock, data.bitmask or 1, data.name}
	end

	modoptionControlNames[data.key] = checkBox

	control = Control:New {
		x = 0,
		y = index*32,
		width = 350,
		height = 32,
		padding = {0, 0, 0, 0},
		tooltip = data.desc,
		greedyHitTest = data.desc ~= nil,
		children = {
			label,
			checkBox,
		}
	}

	return control
end

local function ProcessNumberOption(data, index)
	local control
	local oldText = localModoptions[data.key] or modoptionDefaults[data.key]

	local label = Label:New {
		x = 5,
		y = 0,
		width = 320,
		height = 30,
		valign = "center",
		align = "left",
		caption = data.name,
		objectOverrideFont = oldText == modoptionDefaults[data.key] and WG.Chobby.Configuration:GetFont(2) or WG.Chobby.Configuration:GetFont(2, "Changed2", {color = MARKED_AS_CHANGED_COLOR}),
		tooltip = data.desc,
	}

	local numberBox
	numberBox = EditBox:New {
		x = 325,
		y = 1,
		width = 300,
		height = 30,
		text   = oldText,
		hint = data.hint,
		objectOverrideFont = oldText == modoptionDefaults[data.key] and WG.Chobby.Configuration:GetFont(2) or WG.Chobby.Configuration:GetFont(2, "Changed2", {color = MARKED_AS_CHANGED_COLOR}),
		objectOverrideHintFont = WG.Chobby.Configuration:GetFont(11),
		tooltip = data.desc,
		OnFocusUpdate = (data.lock or data.unlock) and {
			function (obj)
				if obj.focused then
					return
				end

				local newValue = tonumber(obj.text)

				if not newValue then
					obj:SetText(oldText)
					return
				end

				-- Bound the number
				newValue = math.min(data.max, math.max(data.min, newValue))
				-- Round to step size
				newValue = math.floor(newValue/data.step + 0.5)*data.step + 0.01*data.step

				oldText = TextFromNum(newValue, data.step)
				localModoptions[data.key] = oldText
				obj:SetText(oldText)

				if oldText == modoptionDefaults[data.key] then
					numberBox.font = WG.Chobby.Configuration:GetFont(2)
					label.font = WG.Chobby.Configuration:GetFont(2)
					processChildrenLocks(data.lock, data.unlock, data.bitmask or 1)
				else
					numberBox.font = WG.Chobby.Configuration:GetFont(2, "Changed2", {color = MARKED_AS_CHANGED_COLOR})
					label.font = WG.Chobby.Configuration:GetFont(2, "Changed2", {color = MARKED_AS_CHANGED_COLOR})
					processChildrenLocks(data.unlock, data.lock, data.bitmask or 1)
				end
			end
			} or {
			function (obj)
				if obj.focused then
					return
				end

				local newValue = tonumber(obj.text)

				if not newValue then
					obj:SetText(oldText)
					return
				end

				-- Bound the number
				newValue = math.min(data.max, math.max(data.min, newValue))
				-- Round to step size
				newValue = math.floor(newValue/data.step + 0.5)*data.step + 0.01*data.step

				oldText = TextFromNum(newValue, data.step)
				localModoptions[data.key] = oldText
				obj:SetText(oldText)

				if oldText == modoptionDefaults[data.key] then
					numberBox.font = WG.Chobby.Configuration:GetFont(2)
					label.font = WG.Chobby.Configuration:GetFont(2)
				else
					numberBox.font = WG.Chobby.Configuration:GetFont(2, "Changed2", {color = MARKED_AS_CHANGED_COLOR})
					label.font = WG.Chobby.Configuration:GetFont(2, "Changed2", {color = MARKED_AS_CHANGED_COLOR})
				end
			end
		}
	}

	if oldText == modoptionDefaults[data.key] then
		if data.unlock then
			postLock[#postLock+1] = {data.unlock, data.bitmask or 1, data.name}
		end
	elseif data.lock then
		postLock[#postLock+1] = {data.lock, data.bitmask or 1, data.name}
	end

	modoptionControlNames[data.key] = numberBox

	control = Control:New {
		x = 0,
		y = index*32,
		width = 625,
		height = 32,
		padding = {0, 0, 0, 0},
		tooltip = data.desc,
		greedyHitTest = data.desc ~= nil,
		children = {
			label,
			numberBox
		}
	}
	return control
end

local function ProcessStringOption(data, index)

	local control
	local oldText = localModoptions[data.key] or modoptionDefaults[data.key]

	local textHidden = string.len(oldText) <= 1

	local label = Label:New {
		x = 5,
		y = 0,
		width = 320,
		height = 30,
		valign = "center",
		align = "left",
		caption = data.name,
		objectOverrideFont = textHidden and WG.Chobby.Configuration:GetFont(2) or WG.Chobby.Configuration:GetFont(2, "Changed2", {color = MARKED_AS_CHANGED_COLOR}),
		tooltip = data.desc,
	}

	local textBox
	textBox = EditBox:New {
		x = 325,
		y = 1,
		width = 300,
		height = 30,
		text   = textHidden and "" or oldText,
		hint = data.hint,
		objectOverrideFont = textHidden and WG.Chobby.Configuration:GetFont(2) or WG.Chobby.Configuration:GetFont(2, "Changed2", {color = MARKED_AS_CHANGED_COLOR}),
		objectOverrideHintFont = WG.Chobby.Configuration:GetFont(11),
		tooltip = data.desc,
		OnFocusUpdate = {
			function (obj)
				if obj.focused then
					return
				end

				if string.len(obj.text) <= 1 then
					if not textHidden then
						localModoptions[data.key] = 0
					end
					obj.text = ""
					textBox.font = WG.Chobby.Configuration:GetFont(2)
					label.font = WG.Chobby.Configuration:GetFont(2)

				else
					localModoptions[data.key] = obj.text
					if obj.text == modoptionDefaults[data.key] then
						textBox.font = WG.Chobby.Configuration:GetFont(2)
						label.font = WG.Chobby.Configuration:GetFont(2)
					else
						textBox.font = WG.Chobby.Configuration:GetFont(2, "Changed2", {color = MARKED_AS_CHANGED_COLOR})
						label.font = WG.Chobby.Configuration:GetFont(2, "Changed2", {color = MARKED_AS_CHANGED_COLOR})
					end
				end
			end
		}
	}
	modoptionControlNames[data.key] = textBox

	control = Control:New {
		x = 0,
		y = index*32,
		width = 625,
		height = 32,
		padding = {0, 0, 0, 0},
		tooltip = data.desc,
		greedyHitTest = data.desc ~= nil,
		children = {
			label,
			textBox
		}
	}
	return control
end

local function ProcessSubHeader(data, index)
	local label = Label:New {
		x = 5,
		y = index * 32,
		width = 1600,
		height = 30,
		valign = "center",
		align = "left",
		caption = data.name,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(tonumber(data.font) or 2),
		tooltip = data.desc,
	}
	modoptionControlNames[data.key] = label
	return label
end

local function ProcessLink(data, index)
	local button = Button:New {
		x = 5,
		y = index * 32,
		width = data.width or 150,
		height = 30,
		valign = "center",
		align = "left",
		caption = data.name,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(tonumber(data.font) or 2),
		tooltip = data.desc,
		padding = {2, 2, 2, 2},
		OnMouseUp = {
			function()
				WG.Chobby.ConfirmationPopup(
					function() WG.BrowserHandler.OpenUrl(data.link) end,
						"\255\255\128\128".."External Website\nOpen in your web browser?"
						..	(data.linkdesc and "\n \n"..data.linkdesc or "")
						..	(data.linkhide and "" or "\n \n"..data.link),
					nil, nil, nil, "Open Link", "Cancel", nil)
			end
		}
	}
	local externalWebsite = Image:New {
		name = 'externalWebsite',
		x = button.width-25,
		y = 0,
		right = 0,
		bottom = 0,
		keepAspect = true,
		file = LUA_DIRNAME .. "images/external-website.png",
		parent = button,
		tooltip = button.tooltip,
	}
	return button
end

local function ProcessLineSeparator(data, index)
	return Line:New {
		x = 0,
		y = index*32 + 3,
		width = 1600,
	}
end

local function PopulateTab(options)
	-- list = combobox
	-- bool = tickbox
	-- number = sliderbar (with label)
	-- string = editBox

	local contentsPanel = ScrollPanel:New {
		name = "tabPanel",
		x = 6,
		right = 5,
		y = 10,
		bottom = 8,
		horizontalScrollbar = false,
	}

	local column, row = 1, 0
	local data, rowData
	for i = 1, #options do
		data = options[i]
		if data then
			if (data.column or -1) > column then
				row = row - 1
			end

			rowData = nil
			if data.type == "number" then
				rowData = ProcessNumberOption(data, row)

			elseif data.type == "string" then
				rowData = ProcessStringOption(data, row)

			elseif data.type == "subheader" then
				rowData = ProcessSubHeader(data, row)

			elseif data.type == "bool" then
				rowData = ProcessBoolOption(data, row)

			elseif data.type == "list" then
				rowData = ProcessListOption(data, row)

			elseif data.type == "separator" then
				rowData = ProcessLineSeparator(data, row)
				row = row - 0.5
			elseif data.type == "link" and data.link then
				rowData = ProcessLink(data, row)
			end
			if rowData then
				column = math.abs(data.column or 1)
				rowData.x = rowData.x + (column - 1) * 625
				row = row + 1
				rowData.rowOrginal = rowData.y
				contentsPanel:AddChild(rowData)
			end
		end
	end
	return {contentsPanel}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Modoptions Window Handler

local function CreateModoptionWindow()
	local ww, wh = Spring.GetWindowGeometry()

	local modoptionsSelectionWindow = Window:New {
		caption = "",
		name = "modoptionsSelectionWindow",
		parent = WG.Chobby.lobbyInterfaceHolder,
		width = math.min(1366, ww - 50),
		height = math.min(720, wh - 50),
		resizable = true,
		draggable = false,
		classname = "main_window",
	}

	localModoptions = Spring.Utilities.CopyTable(battleLobby:GetMyBattleModoptions() or {})
	modoptionControlNames = {}

	local tabs = {}
	lockedOptions = {}

	local tabWidth = 120

	for key, data in pairs(modoptionStructure.sections) do
		local caption = modoptionStructure.sectionTitles[data.title] or data.title
		local weight = modoptionStructure.sectionWeights[data.title] or -#tabs
		local fontSize = 2
		local tooltip = data.desc
		local origCaption = caption
		caption = StringUtilities.GetTruncatedStringWithDotDot(caption, WG.Chobby.Configuration:GetFont(fontSize), tabWidth)
		if origCaption ~= caption then
			tooltip = origCaption
		end
		tabs[#tabs + 1] = {
			name = key,
			caption = caption,
			tooltip = tooltip,
			objectOverrideFont = WG.Chobby.Configuration:GetFont(fontSize),
			children = PopulateTab(data.options),
			weight = data.weight or weight,
		}
	end

	for i = 1, #postLock do
		processChildrenLocks(nil, postLock[i][1], postLock[i][2], postLock[i][3])
		postLock[i] = nil
	end

	table.sort(tabs, function(a,b) return a.weight > b.weight end)

	local tabPanel = Chili.DetachableTabPanel:New {
		x = 4,
		right = 4,
		y = 49,
		bottom = 75,
		padding = {0, 0, 0, 0},
		minTabWidth = tabWidth,
		tabs = tabs,
		parent = modoptionsSelectionWindow,
		OnTabChange = {
		}
	}

	local tabBarHolder = Control:New {
		name = "tabBarHolder",
		x = 0,
		y = 0,
		right = 0,
		height = 60,
		resizable = false,
		draggable = false,
		padding = {18, 6, 18, 0},
		parent = modoptionsSelectionWindow,
		children = {
			Line:New {
				classname = "line_solid",
				x = 0,
				y = 52,
				right = 0,
				bottom = 0,
			},
			tabPanel.tabBar
		}
	}
	local function CancelFunc()
		modoptionsSelectionWindow:Dispose()
	end

	local buttonAccept, buttonReset

	local function AcceptFunc()
		screen0:FocusControl(buttonAccept) -- Defocus the text entry
		local isBoss = false
		if not isBoss then
			for k, v in pairs(localModoptions) do
				if lockedOptions[k] then
					localModoptions[k] = battleLobby.modoptions[k]
				end
			end
		end
		battleLobby:SetModOptions(localModoptions)
		modoptionsSelectionWindow:Dispose()
	end

	local function ResetFunc()
		localModoptions = {}
		for key, value in pairs(modoptionDefaults) do
			UpdateControlValue(key, value)
		end
	end

	buttonReset = Button:New {
		right = 294,
		width = 135,
		bottom = 1,
		height = 70,
		caption = i18n("reset"),
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		parent = modoptionsSelectionWindow,
		classname = "option_button",
		OnClick = {
			function()
				ResetFunc()
			end
		},
	}

	buttonAccept = Button:New {
		right = 150,
		width = 135,
		bottom = 1,
		height = 70,
		caption = i18n("apply"),
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		parent = modoptionsSelectionWindow,
		classname = "action_button",
		OnClick = {
			function()
				AcceptFunc()
			end
		},
	}

	local buttonCancel = Button:New {
		right = 6,
		width = 135,
		bottom = 1,
		height = 70,
		caption = i18n("cancel"),
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		parent = modoptionsSelectionWindow,
		classname = "negative_button",
		OnClick = {
			function()
				CancelFunc()
			end
		},
	}

	local popupHolder = WG.Chobby.PriorityPopup(modoptionsSelectionWindow, CancelFunc, AcceptFunc)

	WG.Chobby.lobbyInterfaceHolder.OnResize = WG.Chobby.lobbyInterfaceHolder.OnResize or {}
	WG.Chobby.lobbyInterfaceHolder.OnResize[#WG.Chobby.lobbyInterfaceHolder.OnResize +1] = function()
		local ww, wh = Spring.GetWindowGeometry()

		local neww = math.min(1366, ww - 50)
		local newx = (WG.Chobby.lobbyInterfaceHolder.width - neww) / 2

		local newh = math.min(720, wh - 50)
		local newy = (WG.Chobby.lobbyInterfaceHolder.height - newh) / 2

		modoptionsSelectionWindow:SetPos(
			newx,
			newy,
			neww,
			newh
		)
	end
end

local function InitializeModoptionsDisplay()
	local currentLobby = battleLobby

	local mainScrollPanel = ScrollPanel:New {
		x = 0,
		right = 0,
		y = 0,
		bottom = 0,
		horizontalScrollbar = false,
	}

	local lblText = TextBox:New {
		x = 1,
		right = 1,
		y = 1,
		autoresize = true,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(1),
		objectOverrideHintFont = WG.Chobby.Configuration:GetFont(1),
		text = "",
		parent = mainScrollPanel,
	}

	local function shortenedValue(value)
		value = tostring(value)
		local valueLength = value:len()
		if valueLength > 32 then
			value = string.format("%d:%s_%s", valueLength, value:sub(1,16), value:sub(-16))
		end
		return value
	end

local function tweakSummary(value)
	value = tostring(value)
	local hash = Spring.Utilities.Base64Encode(VFS.CalculateHash(value,1))
	local tweakText = string.format("%d:%s", value:len(), hash:sub(1, 4))
	if value:find("[^%w%-_=]") then -- Non-base64url character found
		return tweakText
	end
	for line in Spring.Utilities.Base64Decode(value):gmatch("([^\r\n]*)[\r\n]?") do
		if line:sub(1, 2) ~= "--" then -- Line doesn't start with a comment
			return tweakText
		end
		local comment = line:sub(3, 27)
		if not comment:find("[^%w%p ]") then -- Only whitelisted characters found
			return tweakText .. "\n[" .. comment .. "]"
		end
	end

	return tweakText
end

	local panelModoptions

	local function OnSetModOptions(listener, modopts)
		local hidenOptions = {}
		local text = ""
		local empty = true
		panelModoptions = modopts or panelModoptions or {}
		if not modoptions then return end

		for _, option in pairs(modoptions) do
			if option.type == "bool" then
				if panelModoptions[option.key] == "1" then
					if option.lock then
						for i = 1, #option.lock do
							hidenOptions[option.lock[i]] = true
						end
					end
				elseif option.unlock then
					for i = 1, #option.unlock do
						hidenOptions[option.unlock[i]] = true
					end
				end
			elseif option.type == "list" then
				for j = 1, #option.items do
					if option.items[j].key == panelModoptions[option.key] and option.items[j].lock then
						for i = 1, #option.items[j].lock do
							hidenOptions[option.items[j].lock[i]] = true
						end
						break
					end
				end
			elseif option.type == "number" then
				if option.lock and panelModoptions[option.key] and panelModoptions[option.key] ~= modoptionDefaults[option.key] then
					for i = 1, #option.lock do
						hidenOptions[option.lock[i]] = true
					end
				elseif option.unlock and panelModoptions[option.key] == modoptionDefaults[option.key] then
					for i = 1, #option.unlock do
						hidenOptions[option.unlock[i]] = true
					end
				end
			elseif option.type == "string" then
				if panelModoptions[option.key] and string.len(panelModoptions[option.key]) == 1 then
					hidenOptions[option.key] = true
				end
			end
		end

		for key, value in pairs(panelModoptions) do
			if (modoptionDefaults[key] == nil or modoptionDefaults[key] ~= value or key == "ranked_game") and key:find("^mapmetadata_") == nil and not hidenOptions[key] then
				local option = getModOptionByKey(key)
				local name = option.name and option.name or key
				text = text .. "\255\255\255\255"
				if text ~= "\255\255\255\255" then
					text = text .. "\255\128\128\128" .. "------" .. "\n"
				end
				text = text .. tostring(name).. " = \255\255\255\255"
				if (key:sub(1,10) == "tweakunits" or key:sub(1,9) == "tweakdefs") then
					local success, result = pcall(tweakSummary, value)
					if success then
						text = text .. result
					else
						text = text .. "\255\255\75\75".."Couldn't Parse\n".."\255\128\128\128"..shortenedValue(value)
					end
				else
					text = text .. shortenedValue(value)
				end
				text = text .. "\n"
				empty = false
			end
		end
		lblText:SetText(text)

		if mainScrollPanel.parent then
			if empty and mainScrollPanel.visible then
				mainScrollPanel:Hide()
			end
			if (not empty) and (not mainScrollPanel.visible) then
				mainScrollPanel:Show()
			end
		end
	end
	battleLobby:AddListener("OnSetModOptions", OnSetModOptions)
	battleLobby:AddListener("OnResetModOptions", OnSetModOptions)

	local externalFunctions = {}

	function externalFunctions.Update()
		if currentLobby then
			currentLobby:RemoveListener("OnSetModOptions", OnSetModOptions)
			currentLobby:RemoveListener("OnResetModOptions", OnSetModOptions)
		end
		battleLobby:AddListener("OnSetModOptions", OnSetModOptions)
		battleLobby:RemoveListener("OnResetModOptions", OnSetModOptions)
		currentLobby = battleLobby

		OnSetModOptions()
	end

	function externalFunctions.GetControl()
		return mainScrollPanel
	end

	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- External Interface

local modoptionsDisplay

local ModoptionsPanel = {}

function ModoptionsPanel.RefreshModoptions()
	if not (modoptions and battleLobby) then
		return
	end
	local showHidden = WG.Chobby.Configuration.ShowhiddenModopions
	local devmode = WG.Chobby.Configuration.devMode
	local postpendHiddenOptions = {}
	modoptionStructure = {
		sectionTitles = {},
		sectionWeights = {},
		sections = {}
	}

	-- Populate the sections
	for i = 1, #modoptions do
		local data = modoptions[i]
		if data.type == "section" then
			modoptionStructure.sectionTitles[data.key] = data.name
			modoptionStructure.sectionWeights[data.key] = data.weight
		else
			if data.section then
				if data.hidden ~= true then
					modoptionStructure.sections[data.section] = modoptionStructure.sections[data.section] or {
						title = data.section,
						options = {}
					}

					local options = modoptionStructure.sections[data.section].options
					options[#options + 1] = data
				elseif showHidden and devmode then
					if not data.name:find("(HIDDEN)") then
						data.name = "(HIDDEN) "..data.name
					end
					postpendHiddenOptions[#postpendHiddenOptions + 1] = data
				end
			end
		end
	end

	if not devmode then
		modoptionStructure.sections["dev"] = nil
	end
	if showHidden and devmode then
		for i = 1, #postpendHiddenOptions do
			local data = postpendHiddenOptions[i]
			modoptionStructure.sections[data.section] = modoptionStructure.sections[data.section] or {
				title = data.section,
				options = {}
			}
			local options = modoptionStructure.sections[data.section].options
			options[#options + 1] = data
		end	
	end
end

function ModoptionsPanel.LoadModoptions(gameName, newBattleLobby)
	battleLobby = newBattleLobby

	if not (gameName and VFS.HasArchive(gameName)) then
		Spring.Log(LOG_SECTION, LOG.ERROR, "Missing game archive, cannot fetch modoptions")
		return
	end

	local function LoadModOptions()
		return VFS.Include("modoptions.lua", nil, VFS.ZIP)
	end

	if modoptionsByGame[gameName] then
		modoptions = modoptionsByGame[gameName]
	else

		local alreadyLoaded = false
		for _, archive in pairs(VFS.GetLoadedArchives()) do
			if archive == gameName then
				alreadyLoaded = true
				break
			end
		end

		if alreadyLoaded then
			Spring.Log(LOG_SECTION, LOG.ERROR, "Game archive already loaded, cannot fetch modoptions")
		else
			modoptions = VFS.UseArchive(gameName, LoadModOptions)
			modoptionsByGame[gameName] = modoptions
		end

	end


	modoptionDefaults = {}
	if not modoptions then
		return
	end

	local unixDate = os.time()

	-- Set modoptionDefaults
	for i = 1, #modoptions do
		local data = modoptions[i]
		if data.key and data.def ~= nil then -- dont check for hidden here yet, as undefined defaults mean they will appear in the modopts list
			if type(data.def) == "boolean" then
				modoptionDefaults[data.key] = tostring((data.def and 1) or 0)
			elseif type(data.def) == "number" then
				-- can't use tostring because of float inaccuracy, eg. 0.6 ends up as "0.6000000002"
				modoptionDefaults[data.key] = TextFromNum(data.def, data.step)
			else
				modoptionDefaults[data.key] = tostring(data.def)
			end
		end
		if data.hidden and type(data.hidden) == "number" then
			data.hidden = data.hidden < unixDate
		end
	end

	-- Populate the sections
	ModoptionsPanel.RefreshModoptions()
end

-- call after LoadModoptions
function ModoptionsPanel.ReturnModoptions()
	return modoptions
end

function ModoptionsPanel.ShowModoptions()
	if modoptions then
		CreateModoptionWindow()
	end
end

function ModoptionsPanel.GetModoptionsControl()
	if not modoptionsDisplay then
		modoptionsDisplay = InitializeModoptionsDisplay()
	else
		modoptionsDisplay.Update()
	end
	return modoptionsDisplay.GetControl()
end

--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- Initialization

function widget:Initialize()
	CHOBBY_DIR = LUA_DIRNAME .. "widgets/chobby/"
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	WG.ModoptionsPanel = ModoptionsPanel
end
