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

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Option Control Handling

local function ProcessListOption(data, index)
	local label = Label:New {
		x = 320,
		y = 0,
		width = 1200,
		height = 30,
		valign = "center",
		align = "left",
		caption = data.name,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		tooltip = data.desc,
	}

	local defaultItem = 1
	local defaultKey = localModoptions[data.key] or data.def

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
		end

		if itemData.desc then
			itemsTooltips[i] = itemData.desc
		end
	end

	local list = ComboBox:New {
		x = 5,
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
		OnSelectName = {
			function (obj, selectedName)
				localModoptions[data.key] = itemNameToKey[selectedName]
			end
		},
		itemKeyToName = itemKeyToName, -- Not a chili key
		tooltip = data.desc,
	}
	modoptionControlNames[data.key] = list

	return Control:New {
		x = 0,
		y = index*32,
		width = 1600,
		height = 32,
		padding = {0, 0, 0, 0},
		children = {
			label,
			list
		}
	}
end

local function ProcessBoolOption(data, index)
	local label = Label:New {
		x = 320,
		y = 0,
		width = 1200,
		height = 30,
		valign = "center",
		align = "left",
		caption = data.name,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		tooltip = data.desc,
	}

	local oldText = localModoptions[data.key] or modoptionDefaults[data.key]

	local checked = false
	if localModoptions[data.key] == nil then
		if modoptionDefaults[data.key] == "1" then
			checked = true
		end
	elseif localModoptions[data.key] == "1" then
		checked = true
	end

	local checkBox = Checkbox:New {
		x = 5,
		y = 0,
		width = 300,
		height = 30,
		boxalign = "right",
		boxsize = 25,
		caption = "",--data.name,
		checked = checked,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		tooltip = data.desc,

		OnChange = {
			function (obj, newState)
				localModoptions[data.key] = tostring((newState and 1) or 0)
			end
		},
	}
	modoptionControlNames[data.key] = checkBox

	return Control:New {
		x = 0,
		y = index*32,
		width = 1600,
		height = 32,
		padding = {0, 0, 0, 0},
    tooltip = data.desc,
		children = {
			label,
			checkBox
		}
	}

	--return checkBox
end

local function ProcessNumberOption(data, index)

	local label = Label:New {
		x = 320,
		y = 0,
		width = 1200,
		height = 30,
		valign = "center",
		align = "left",
		caption = data.name,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		tooltip = data.desc,
	}

	local oldText = localModoptions[data.key] or modoptionDefaults[data.key]

	local numberBox = EditBox:New {
		x = 5,
		y = 1,
		width = 300,
		height = 30,
		text   = oldText,
		useIME = false,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		objectOverrideHintFont = WG.Chobby.Configuration:GetHintFont(2),
		tooltip = data.desc,
		OnFocusUpdate = {
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
			end
		}
	}
	modoptionControlNames[data.key] = numberBox

	return Control:New {
		x = 0,
		y = index*32,
		width = 1600,
		height = 32,
		padding = {0, 0, 0, 0},
		tooltip = data.desc,
		children = {
			label,
			numberBox
		}
	}
end

local function ProcessStringOption(data, index)

	local label = Label:New {
		x = 320,
		y = 0,
		width = 1200,
		height = 30,
		valign = "center",
		align = "left",
		caption = data.name,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		tooltip = data.desc,
	}

	local oldText = localModoptions[data.key] or modoptionDefaults[data.key]

	local textBox = EditBox:New {
		x = 5,
		y = 1,
		width = 300,
		height = 30,
		text   = oldText,
		useIME = false,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		objectOverrideHintFont = WG.Chobby.Configuration:GetHintFont(2),
		tooltip = data.desc,
		OnFocusUpdate = {
			function (obj)
				if obj.focused then
					return
				end
				localModoptions[data.key] = obj.text
			end
		}
	}
	modoptionControlNames[data.key] = textBox

	return Control:New {
		x = 0,
		y = index*32,
		width = 1600,
		height = 32,
		padding = {0, 0, 0, 0},
		children = {
			label,
			textBox
		}
	}
end

local function PopulateTab(options)
	-- list = combobox
	-- bool = tickbox
	-- number = sliderbar (with label)
	-- string = editBox

	local contentsPanel = ScrollPanel:New {
		x = 6,
		right = 5,
		y = 10,
		bottom = 8,
		horizontalScrollbar = false,
	}

	for i = 1, #options do
		local data = options[i]
		if data.type == "list" then
			contentsPanel:AddChild(ProcessListOption(data, #contentsPanel.children))
		elseif data.type == "bool" then
			contentsPanel:AddChild(ProcessBoolOption(data, #contentsPanel.children))
		elseif data.type == "number" then
			contentsPanel:AddChild(ProcessNumberOption(data, #contentsPanel.children))
		elseif data.type == "string" then
			contentsPanel:AddChild(ProcessStringOption(data, #contentsPanel.children))
		end
	end
	return {contentsPanel}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Modoptions Window Handler

local function CreateModoptionWindow()
	local modoptionsSelectionWindow = Window:New {
		caption = "",
		name = "modoptionsSelectionWindow",
		parent = WG.Chobby.lobbyInterfaceHolder,
		width = 1366,
		height = 720,
		resizable = true,
		draggable = true,
		classname = "main_window",
	}

	localModoptions = Spring.Utilities.CopyTable(battleLobby:GetMyBattleModoptions() or {})
	modoptionControlNames = {}

	local tabs = {}

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
			weight = data.weight or weight
		}
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
		battleLobby:SetModOptions(localModoptions)
		modoptionsSelectionWindow:Dispose()
	end

	local function ResetFunc()
		for key, value in pairs(modoptionDefaults) do
			UpdateControlValue(key, value)
		end
		localModoptions = {}
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

	local function OnSetModOptions(listener, modopts)
		if not modopts then
			return
		end
		local text = ""
		local empty = true
		modoptions = modopts
		for key, value in pairs(modoptions) do
			if modoptionDefaults[key] == nil or modoptionDefaults[key] ~= value or key == "ranked_game" then
				local option = getModOptionByKey(key)
				local name = option.name and option.name or key
				text = text .. "\255\255\255\255"
				if text ~= "\255\255\255\255" then
					text = text .. "\255\120\120\120" .. "------" .. "\n"
				end
				text = text .. tostring(name).. " = \255\255\255\255" .. shortenedValue(value) .. "\n"
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

	do
		local alreadyLoaded = false
		for _, archive in pairs(VFS.GetLoadedArchives()) do
			if archive == gameName then
				alreadyLoaded = true
				break
			end
		end
		if alreadyLoaded then
			modoptions = VFS.Include("modoptions.lua", nil, VFS.ZIP)
		else
			modoptions = VFS.UseArchive(gameName, LoadModOptions)
		end
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

	WG.ModoptionsPanel = ModoptionsPanel
end
