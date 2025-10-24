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
local sharingModesByGame = {}
local sharingModes
local selectedSharingModeKey
local sharingUI = { modeList = nil, rankedBadge = nil }
local lockedOverlaysByKey = {}

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

-- Enable/disable the interactive control for a given modoption key
local function SetControlLock(key, locked)
    if not modoptionControlNames then return end
    local control = modoptionControlNames[key]
    if not control then return end
    if control.SetEnabled then
        control:SetEnabled(not locked)
    end
    -- If the control is embedded in a row control, try disabling that too
    local parent = control.parent
    if parent and parent.SetEnabled and parent.name ~= "tabPanel" then
        parent:SetEnabled(not locked)
    end
    -- Fallback: disable input handlers if the widget lacks SetEnabled
    if control.OnSelectName then
        control._origOnSelectName = control._origOnSelectName or control.OnSelectName
        control.OnSelectName = locked and {} or control._origOnSelectName
    end
    if control.OnChange then
        control._origOnChange = control._origOnChange or control.OnChange
        control.OnChange = locked and {} or control._origOnChange
    end

    -- Add/remove an input-blocking overlay for controls that don't visually disable
    local parentRow = control.parent
    if parentRow and parentRow.name ~= "tabPanel" then
        local displayValue = localModoptions[key] or modoptionDefaults[key] or ""
        if control.itemKeyToName then
            displayValue = control.itemKeyToName[displayValue] or displayValue
        elseif control.SetToggle then
            if displayValue == "1" or displayValue == 1 or displayValue == true then
                displayValue = "Enabled"
            else
                displayValue = "Disabled"
            end
        else
            displayValue = tostring(displayValue)
        end

        if locked then
            local info = lockedOverlaysByKey[key]
            if not info then
                -- Expand narrow areas (e.g. checkboxes) so text like "Disabled" fits
                local ovX, ovW = control.x, control.width
                if ovW < 100 then ovW = 300 end
                local overlay = Label:New {
                    name = "lockOverlay_" .. key,
                    x = ovX,
                    y = control.y,
                    width = ovW,
                    height = control.height,
                    valign = "center",
                    align = "left",
                    caption = tostring(displayValue),
                    tooltip = control.tooltip,
                    objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
                }
                parentRow:AddChild(overlay)
                lockedOverlaysByKey[key] = { overlay = overlay, oldX = control.x }
                if control.SetPos then control:SetPos(control.x + 4095, control.y) end
            else
                info.overlay:SetCaption(tostring(displayValue))
            end
        else
            local info = lockedOverlaysByKey[key]
            if info then
                if control.SetPos then control:SetPos(info.oldX or control.x, control.y) end
                if info.overlay and info.overlay.parent then
                    info.overlay.parent:RemoveChild(info.overlay)
                end
            end
            lockedOverlaysByKey[key] = nil
        end
    end

    -- Simple visual state: if a control supports SetEnabled, that's sufficient.
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
		width = 625,
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
		local children = PopulateTab(data.options)
		if key == "sharing" then
			-- Create a fresh scroll panel instead of using the potentially corrupted one
			local sharingScroll = ScrollPanel:New {
				name = "sharingTabPanel_" .. (math.random(1000, 9999)),
				x = 10,
				right = 10,
				y = 56,
				bottom = 10,
				horizontalScrollbar = false,
			}

			-- Manually rebuild the sharing content
			local row = 0
			for _, opt in ipairs(data.options or {}) do
				local rowData = nil
				if opt.type == "number" then
					rowData = ProcessNumberOption(opt, row)
				elseif opt.type == "string" then
					rowData = ProcessStringOption(opt, row)
				elseif opt.type == "subheader" then
					rowData = ProcessSubHeader(opt, row)
				elseif opt.type == "bool" then
					rowData = ProcessBoolOption(opt, row)
				elseif opt.type == "list" then
					rowData = ProcessListOption(opt, row)
				elseif opt.type == "separator" then
					rowData = ProcessLineSeparator(opt, row)
					row = row - 0.5
				end
				if rowData then
					local column = math.abs(opt.column or 1)
					rowData.x = rowData.x + (column - 1) * 625
					row = row + 1
					rowData.rowOrginal = rowData.y
					sharingScroll:AddChild(rowData)
				end
			end

			-- Build Mode dropdown controls
			local modeLabel = Label:New {
				x = 15,
				y = 10,
				width = 200,
				height = 30,
				valign = "center",
				align = "left",
				caption = "Mode",
				objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
			}

			local items, itemKeyToName, itemNameToKey = {}, {}, {}
			if sharingModes and sharingModes.modes then
				for i, m in ipairs(sharingModes.modes) do
					local name = m.name or m.key
					items[i] = name
					itemKeyToName[m.key] = name
					itemNameToKey[name] = m.key
				end
			end

			local rankedBadge = Label:New {
				x = 650,
				y = 10,
				width = 220,
				height = 30,
				valign = "center",
				align = "left",
				caption = "",
				objectOverrideFont = WG.Chobby.Configuration:GetFont(2, nil, {color = {1,0.3,0.3,1}}),
			}

			local function applyMode(modeKey)
				if not (sharingModes and sharingModes.modes) then return end
				selectedSharingModeKey = modeKey
				local mode
				for _, m in ipairs(sharingModes.modes) do
					if m.key == modeKey then mode = m; break end
				end
				if not mode then return end

				local allowRanked = (mode.allowRanked ~= false)
				WG.SharingModePolicy = WG.SharingModePolicy or {}
				WG.SharingModePolicy.allowRanked = allowRanked
				WG.SharingModePolicy.modeLocked = {}
				rankedBadge:SetCaption(allowRanked and "" or "Not Ranked")
				
				-- Set the "Ranked Game" modoption when allowRanked is false
				if not allowRanked then
					localModoptions["ranked_game"] = "0"
					UpdateControlValue("ranked_game", "0")
				end
				
				-- Pass the selected mode to the game so it can make its own decisions
				localModoptions["_sharing_mode_selected"] = modeKey
				UpdateControlValue("_sharing_mode_selected", modeKey)
				
				-- Inform the lobby (if it listens) that ranked should be disabled for this mode
				if WG.BattleRoomWindow and WG.BattleRoomWindow.SetRankedModeAllowed then
					WG.BattleRoomWindow.SetRankedModeAllowed(allowRanked)
				end

				if mode.options then
					for optKey, rule in pairs(mode.options) do
						if rule.value ~= nil then
							local value = rule.value
							if type(value) == "boolean" then value = tostring((value and 1) or 0) end
							localModoptions[optKey] = tostring(value)
							UpdateControlValue(optKey, tostring(value))
						end
						if rule.locked then
							lockedOptions[optKey] = 1
							WG.SharingModePolicy.modeLocked[optKey] = true
							SetControlLock(optKey, true)
						else
							lockedOptions[optKey] = nil
							WG.SharingModePolicy.modeLocked[optKey] = nil
							SetControlLock(optKey, false)
						end
						if rule.ui == "hidden" then
							local child = modoptionControlNames[optKey]
							if child then
								-- Hide the row: move its row container off-screen and hide
								if child.parent and child.parent.name ~= "tabPanel" then
									child = child.parent
								end
								if child.SetPos then child:SetPos(child.x - 4095, child.y) end
								if child.SetVisibility then child:SetVisibility(false) end
							end
						else
							-- Ensure the row is visible (override any engine disabled rules)
							local child = modoptionControlNames[optKey]
							if child then
								if child.parent and child.parent.name ~= "tabPanel" then
									child = child.parent
								end
								if child.x and child.x < -1000 then
									child:SetPos(0, child.y)
								end
								if child.SetVisibility then child:SetVisibility(true) end
							end
						end
					end
				end
				battleLobby:SetModOptions(localModoptions)
			end

			local defaultSelected = 1
			if sharingModes and sharingModes.modes then
				for i, m in ipairs(sharingModes.modes) do
					if m.key == (selectedSharingModeKey or "enabled") then
						defaultSelected = i; break
					end
				end
			end

			local modeList = ComboBox:New {
				x = 340,
				y = 11,
				width = 300,
				height = 30,
				items = items,
				selectByName = true,
				selected = defaultSelected,
				objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
				OnSelectName = {
					function (obj, selectedName)
						local key = itemNameToKey[selectedName]
						applyMode(key)
					end
				},
			}

			sharingUI.modeList = modeList
			sharingUI.rankedBadge = rankedBadge

			-- Create a parent panel that contains both header and content
			local parentPanel = Control:New {
				name = "sharingParentPanel_" .. (math.random(1000, 9999)),
				x = 6,
				right = 5,
				y = 10,
				bottom = 8,
				padding = {0,0,0,0},
			}

			-- Add Mode controls to parent panel
			parentPanel:AddChild(modeLabel)
			parentPanel:AddChild(modeList)
			parentPanel:AddChild(rankedBadge)
			parentPanel:AddChild(Line:New { classname = "line_solid", x = 10, y = 48, right = 10, height = 2 })

			-- Add the fresh scroll to the parent panel
			parentPanel:AddChild(sharingScroll)
			
			children = { parentPanel }

			-- Apply the selected mode immediately
			if sharingModes and sharingModes.modes and sharingModes.modes[defaultSelected] then
				applyMode(sharingModes.modes[defaultSelected].key)
			end
		end

		tabs[#tabs + 1] = {
			name = key,
			caption = caption,
			tooltip = tooltip,
			objectOverrideFont = WG.Chobby.Configuration:GetFont(fontSize),
			children = children,
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

	-- Populate the sections; gather sharing_category into a dedicated Sharing tab
	local sharingOptions = {}
	for i = 1, #modoptions do
		local data = modoptions[i]
		if data.type == "section" then
			modoptionStructure.sectionTitles[data.key] = data.name
			modoptionStructure.sectionWeights[data.key] = data.weight
		else
			if data.section then
				if data.hidden ~= true then
					if data.sharing_category then
						sharingOptions[#sharingOptions + 1] = data
					else
						modoptionStructure.sections[data.section] = modoptionStructure.sections[data.section] or {
							title = data.section,
							options = {}
						}
						local options = modoptionStructure.sections[data.section].options
						options[#options + 1] = data
					end
				elseif showHidden and devmode then
					if not data.name:find("(HIDDEN)") then
						data.name = "(HIDDEN) "..data.name
					end
					postpendHiddenOptions[#postpendHiddenOptions + 1] = data
				end
			end
		end
	end

	if #sharingOptions > 0 then
		-- Known categories with explicit ordering
		local knownCategories = {
			security = 1,
			units = 2,
			resources = 3,
			allied_construction = 4,
			allied_capture = 5,
			reclaim = 6,
			upgrades = 7,
		}
		
		-- Humanize category names by converting snake_case to Title Case
		local function humanizeCategory(cat)
			return cat:gsub("_", " "):gsub("(%l)(%w*)", function(a,b) return a:upper()..b end)
		end
		
		-- Collect all categories and assign order values
		local allCategories = {}
		for _, opt in ipairs(sharingOptions) do
			local cat = opt.sharing_category or "other"
			if not allCategories[cat] then
				if knownCategories[cat] then
					allCategories[cat] = knownCategories[cat]
				else
					-- Unknown categories get order 100+ and are sorted alphabetically
					allCategories[cat] = 100
				end
			end
		end
		
		-- Sort unknown categories alphabetically among themselves
		local unknownCats = {}
		for cat, order in pairs(allCategories) do
			if order >= 100 then
				table.insert(unknownCats, cat)
			end
		end
		table.sort(unknownCats)
		for i, cat in ipairs(unknownCats) do
			allCategories[cat] = 100 + i
		end
		
		table.sort(sharingOptions, function(a,b)
			local ca = allCategories[a.sharing_category or 'other'] or 999
			local cb = allCategories[b.sharing_category or 'other'] or 999
			if ca == cb then 
				-- Data-driven dependency ordering: options with depends_on come after their dependency
				local aKey, bKey = a.key or "", b.key or ""
				local aDep, bDep = a.depends_on, b.depends_on
				
				-- If A depends on B, B comes first
				if aDep == bKey then return false end
				if bDep == aKey then return true end
				
				-- If both have no dependencies or different dependencies, sort alphabetically
				return (a.name or aKey) < (b.name or bKey)
			end
			return ca < cb
		end)

		local enriched = {}
		local seenCat = {}
		for _, opt in ipairs(sharingOptions) do
			local cat = opt.sharing_category or "other"
			if not seenCat[cat] then
				seenCat[cat] = true
				local knownTitles = {
					security = "-- Security",
					units = "-- Units", 
					resources = "-- Resources",
					allied_construction = "-- Allied Construction",
					allied_capture = "-- Allied Capture",
					reclaim = "-- Reclaim",
					upgrades = "-- Upgrades",
				}
				local title = knownTitles[cat] or ("-- " .. humanizeCategory(cat))
				enriched[#enriched + 1] = { key = "subheader_"..cat, type = "subheader", name = title, desc = "", font = 2 }
			end
			enriched[#enriched + 1] = opt
		end

		modoptionStructure.sectionTitles["sharing"] = "Sharing"
		-- Place Sharing just after Main (which has weight 7)
		modoptionStructure.sectionWeights["sharing"] = 6
		modoptionStructure.sections["sharing"] = { title = "sharing", options = enriched, weight = 6 }
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

			-- Load sharing modes (if present)
		local function LoadSharingOptions()
			if VFS.FileExists("gamedata/sharingoptions.json") then
				local jsonStr = VFS.LoadFile("gamedata/sharingoptions.json", VFS.ZIP)
				if jsonStr then
					return json.decode(jsonStr)
				end
			end
			return nil
		end
	sharingModes = sharingModesByGame[gameName]
	if not sharingModes then
		sharingModes = VFS.UseArchive(gameName, LoadSharingOptions)
		sharingModesByGame[gameName] = sharingModes
	end


	modoptionDefaults = {}
	if not modoptions then
		return
	end

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
	VFS.Include("libs/json.lua")

	WG.ModoptionsPanel = ModoptionsPanel
end
