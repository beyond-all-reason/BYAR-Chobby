function widget:GetInfo()
	return {
		name    = 'Optionpreset Panel',
		desc    = 'Implements the Optionpreset panel.',
		author  = 'jere0500',
		date    = '22 June 2024',
		license = 'GNU GPL v2',
		layer   = 0,
		enabled = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- const:
local placeHolder        = "<noPresetSelected>"

-- Variables
local battleLobby
local battle
local OptionpresetsPanel = {}
local window
local multiplayer        = false

-- enabled options
local enabledOptions     = {}
local optionCaptions     = {
	["Modoptions"] = "Settings part of the adv. options menu",
	["Map"] = "Current selected map",
	["Bots"] = "All bots (settings, team)",
	["Start Boxes"] = "All start areas with position",
	["Multiplayer Battle Settings"] = "Multiplayer specific settings (battle preset, #teams, ...)"
}

-- edited by the preset
local currentModoptions
local currentMap
local currentAITable
local currentStartRects
local currentMPBattleSettings

-- used to generate a point to resume
local multiplayerModoptions

-- now we need to store the object in this class
local jsondata;

-- preset that is selected in the dropdown menu
local selectedPresetName = placeHolder;

-- preset that is currently applied
local appliedPresetName  = placeHolder;

-- defining function to later overwrite
local refreshPresetMenu  = function()
end

-- errorStr
local errorStr           = ""

-- write to the error Panel
local writeError         = function(errorM)
	errorStr = errorM
end


--------------------------------------------------------------------------------
--- Helper functions
--------------------------------------------------------------------------------
local function refreshJSONData()
	local modfile = io.open("optionsPresets.json", 'r')
	if modfile ~= nil then
		local boolOut
		boolOut, jsondata = pcall(Json.decode, modfile:read())

		-- handles broken json file
		if not boolOut or jsondata == nil or type(jsondata) ~= "table" then
			--error during file reading, should output read text TODO
			local localtime = os.date('%Y-%m-%d-%H:%M:%S')
			local oldfile = "optionsPresets.json"
			local errorfile = "optionsPresetsError:" .. localtime .. ".json"
			writeError("Error reading preset file\n " .. oldfile .. " was moved to \n" .. errorfile)

			modfile:close()
			local renamesuccess = os.rename(oldfile, errorfile)
			if not renamesuccess then
				Spring.Echo("fail during rename")
				return
			end
			-- generate a new file
			refreshJSONData()
			return
		end
	end
	if modfile == nil then
		-- creates file when it does not exist
		jsondata = {}
		-- jsondata["defaultPreset"] = {}
		modfile = io.open("optionsPresets.json", 'w')
		local jsonobj = Json.encode(jsondata)
		modfile:write(jsonobj)
	end

	modfile:close()
end

-- writes preset changes to file
local function saveJSONData()
	local modfile = io.open("optionsPresets.json", 'w')
	if modfile == nil then
		-- maybe some logging
		return
	end
	local jsonobj = Json.encode(jsondata)
	modfile:write(jsonobj)
	modfile:close()
end

-- apply specific preset to the current Lobby
local function applyPreset(presetName)
	appliedPresetName = presetName

	local presetObj = jsondata[presetName]
	if presetObj ~= nil then
		-- only apply in multiplayer
		local presetMPBattleSettings = presetObj["Multiplayer Battle Settings"]
		if presetMPBattleSettings ~= nil and multiplayer and enabledOptions["Multiplayer Battle Settings"] then
			battleLobby:SayBattle("!preset " .. presetMPBattleSettings["preset"])
			if presetMPBattleSettings["locked"] then
				battleLobby:SayBattle("!lock")
			else
				battleLobby:SayBattle("!unlock")
			end
			battleLobby:SayBattle("!autobalance " .. presetMPBattleSettings["autoBalance"])
			battleLobby:SayBattle("!balanceMode " .. presetMPBattleSettings["balanceMode"])
			battleLobby:SayBattle("!set teamSize " .. presetMPBattleSettings["teamSize"])
			battleLobby:SayBattle("!nbTeams " .. presetMPBattleSettings["nbTeams"])
		end

		-- map
		local presetMapName = presetObj["Map"]
		if (presetMapName ~= nil and enabledOptions["Map"]) then
			battleLobby:SelectMap(presetMapName)
		end

		-- starting Areas
		local presetRectangles = presetObj["Start Boxes"]
		-- calculated the required team size, when it is undefined for the preset
		if multiplayer and presetMPBattleSettings == nil then
			battleLobby:SayBattle("!nbTeams " .. #presetRectangles)
		end

		if (presetRectangles ~= nil and enabledOptions["Start Boxes"]) then
			WG.BattleRoomWindow.RemoveStartRect()
			for index, value in ipairs(presetRectangles) do
				local l = value["left"]
				local r = value["right"]
				local t = value["top"]
				local b = value["bottom"]

				WG.BattleRoomWindow.AddStartRect(index - 1, l, t, r, b)
			end
		end

		-- AIs with their settings
		local presetAi = presetObj["Bots"]
		if presetAi ~= nil and enabledOptions["Bots"] then
			local saidBattleExOnce = false

			for key, _ in pairs(currentAITable) do
				battleLobby:RemoveAi(key)
			end
			currentAITable = {}
			for key, value in pairs(presetAi) do
				currentAITable[key] = value
				local battlestatusoptions = {}
				battlestatusoptions.teamColor = value.teamColor
				battlestatusoptions.side = value.side
				battlestatusoptions.handicap = value.handicap
				battleLobby:AddAi(key, value.aiLib, value.allyNumber, value.aiVersion, value.aiOptions,
					battlestatusoptions)
				if (multiplayer) and battlestatusoptions.handicap then
					local isBoss = battle.bossed
					if isBoss and isBoss == true then
						battleLobby:SayBattle("!force "..key.." bonus ".. tostring(battlestatusoptions.handicap))
					elseif saidBattleExOnce == false then
							WG.Delay(function() battleLobby:SayBattleEx("tried to apply bonuses to AI, but was prevented due to not being boss") end, 1.5)
							saidBattleExOnce = true
					end
				end
			end
		end

		-- modoptions
		currentModoptions = presetObj["Modoptions"]
		if (currentModoptions ~= nil and enabledOptions["Modoptions"]) then
			-- if multiplayer have to disable other modoptions first:
			if (multiplayer) then
				local isBoss = battle.bossed
				if isBoss and isBoss == true then
					-- now apply the modoptions as the baseline
					local combinedModoptions = multiplayerModoptions
					for key, value in pairs(currentModoptions) do
						multiplayerModoptions[key] = value
					end
					currentModoptions = combinedModoptions
				else
					WG.Delay(function() battleLobby:SayBattleEx("tried to apply a preset containing modoptions, but was prevented due to not being boss") end, 1.5)
					return
				end
			end
			battleLobby:SetModOptions(currentModoptions)
		end
	end
end

-- deletes a preset by name
local function deletePreset(presetName)
	if presetName ~= placeHolder or presetName ~= "<new>" then
		jsondata[presetName] = nil
		saveJSONData()
		refreshPresetMenu()
	end
end

-- applies changes to specified preset
-- (creates new preset if none with that name exists)
local function writePreset(presetName)
	local preset = presetName
	if (presetName == nil) then
		preset = "defaultPreset"
	end

	if jsondata[preset] == nil then
		jsondata[preset] = {}
	end

	if currentModoptions ~= nil and enabledOptions["Modoptions"] then
		if jsondata[preset]["Modoptions"] == nil then
			jsondata[preset]["Modoptions"] = {}
		end
		jsondata[preset]["Modoptions"] = currentModoptions
	end

	if currentMap ~= nil and enabledOptions["Map"] then
		if jsondata[preset]["Map"] == nil then
			jsondata[preset]["Map"] = {}
		end
		jsondata[preset]["Map"] = currentMap
	end


	if currentAITable ~= nil then
		if jsondata[preset]["Bots"] and enabledOptions["ai"] == nil then
			jsondata[preset]["Bots"] = {}
		end
		jsondata[preset]["Bots"] = currentAITable
	end

	if currentStartRects ~= nil then
		if jsondata[preset]["Start Boxes"] and enabledOptions["Start Boxes"] == nil then
			jsondata[preset]["Start Boxes"] = {}
		end
		jsondata[preset]["Start Boxes"] = currentStartRects
	end

	if currentMPBattleSettings ~= nil then
		if jsondata[preset]["Multiplayer Battle Settings"] == nil and enabledOptions["MPBattleSettings"] then
			jsondata[preset]["Multiplayer Battle Settings"] = {}
		end
		jsondata[preset]["Multiplayer Battle Settings"] = currentMPBattleSettings
	end

	-- selects to apply preset
	selectedPresetName = preset

	saveJSONData()
	refreshPresetMenu()
end

--------------------------------------------------------------------------------
--- Gui functions
--------------------------------------------------------------------------------

-- generate checkbox panel for disabling/ enabling loading
local function ProcessBoolOption(name, active, index)
	local label = Label:New {
		x = 35,
		y = 0,
		width = 1200,
		height = 30,
		valign = "center",
		align = "left",
		tooltip = optionCaptions[name], --data.name,
		caption = name,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
	}

	local checkBox = Checkbox:New {
		x = 5,
		y = 0,
		width = 30,
		height = 30,
		boxalign = "left",
		boxsize = 25,
		caption = "",
		tooltip = optionCaptions[name], --data.name,
		checked = active,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),

		OnChange = {
			function(_, newState)
				enabledOptions[name] = ((newState and true) or false)
			end
		},
	}

	return Control:New {
		x = 0,
		y = index * 32,
		width = 1600,
		height = 32,
		padding = { 0, 0, 0, 0 },
		children = {
			label,
			checkBox
		}
	}
end

-- generates the view for the preset selection panel
local function PopulatePresetPanel(parentPanel)
	-- reading the default Preset options from the json data
	refreshJSONData()

	local function disableSelectedPreset()
		deletePreset(selectedPresetName)
	end


	-- popup for entering a new preset Name
	local function OpenPresetPopup()
		
		local openPresetPopup = Window:New {
			caption = "Create new preset",
			name = "createNewPreset",
			parent = parentPanel,
			align = "center",
			width = 450,
			height = 200,
			resizable = false,
			draggable = false,
			classname = "main_window",
		}

		local presetEditBox = EditBox:New {
			x                      = 10,
			y                      = 10,
			width                  = 300,
			right                  = 10,
			height                 = 30,
			text                   = "",
			useIME                 = false,
			hint                   = "Enter a name for your preset",
			parent                 = openPresetPopup,
			objectOverrideFont     = WG.Chobby.Configuration:GetFont(2),
			objectOverrideHintFont = WG.Chobby.Configuration:GetFont(11),
			tooltip                = "Enter a name for your new preset",
			OnKeyPress = {
				function(obj, key)
					presetName = obj.text
					if key == Spring.GetKeyCode("enter") or key == Spring.GetKeyCode("numpad_enter") then
						SavePresetName()
					end
				end
			},
		}

		local saveButton = Button:New {
			x = 10,
			width = 135,
			y = 50,
			height = 70,
			caption = "Save",
			parent = openPresetPopup,
			objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
			classname = "action_button",
			OnClick = {
				function()
					SavePresetName()
				end
			},
		}

		local cancelButton = Button:New {
			x = 155,
			width = 135,
			y = 50,
			height = 70,
			caption = i18n("cancel"),
			parent = openPresetPopup,
			objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
			classname = "negative_button",
			OnClick = {
				function()
					refreshPresetMenu()
					openPresetPopup:Dispose()
				end
			},
		}

		function SavePresetName()
			local presetName = "defaultPreset"
			if (presetEditBox.text ~= nil) then
				presetName = presetEditBox.text
			end

			if presetName == "<new>" or presetName == "" then
				refreshPresetMenu()
				openPresetPopup:Dispose()
				return
			end
			-- validate presetName

			writePreset(presetName)
			openPresetPopup:Dispose()
		end

		screen0:FocusControl(presetEditBox)
	end

	local presetNames = {}
	local presetList = {}
	-- (re)generates the dropdown list of presets
	refreshPresetMenu = function()
		presetNames = {}
		if jsondata[selectedPresetName] == nil then
			selectedPresetName = placeHolder
		end

		table.sort(jsondata)
		table.insert(presetNames, selectedPresetName)
		table.insert(presetNames, "<new>")
		local jsonNames = {}
		for key, _ in pairs(jsondata) do
			table.insert(jsonNames, key)
		end
		table.sort(jsonNames)
		for _, value in pairs(jsonNames) do
			if (value ~= selectedPresetName) then
				table.insert(presetNames, value)
			end
		end


		parentPanel:RemoveChild(presetList)
		presetList = ComboBox:New {
			x = 10,
			y = 0,
			width = 425,
			height = 30,
			valign = "center",
			align = "left",
			objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
			items = presetNames,
			selectByName = true,
			selected = selectedPresetName,
			OnSelectName = {
				function(obj, selectedName)
					if (selectedName == "<new>") then
						OpenPresetPopup()
						presetList.selected = appliedPresetName
						selectedPresetName = appliedPresetName
					else
						selectedPresetName = selectedName
					end
				end
			},
			itemKeyToName = presetNames,
		}
		parentPanel:AddChild(presetList)
	end


	local buttonSave = Button:New {
		x = 10,
		width = 135,
		y = 40,
		height = 70,
		caption = "Overwrite",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		classname = "action_button",
		OnClick = {
			function()
				--verify deletable preset
				if selectedPresetName == "" or selectedPresetName == placeHolder or selectedPresetName == "<new>" then
					return
				end
				writePreset(selectedPresetName)
				window:Dispose()
				-- battleLobby:SetModOptions(localModoptions)
			end
		},
	}


	local buttonLoad = Button:New {
		x = 155,
		width = 135,
		y = 40,
		height = 70,
		caption = i18n("load"),
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		classname = "action_button",
		OnClick = {
			function()
				if (selectedPresetName == nil or selectedPresetName == placeHolder or selectedPresetName == "<new>") then
					return
				end
				applyPreset(selectedPresetName)
				window:Dispose()
			end
		},
	}

	local buttonDelete = Button:New {
		x = 300,
		width = 135,
		y = 40,
		height = 70,
		caption = i18n("delete_replay"), --seem to contain the appropriate term
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		classname = "negative_button",
		OnClick = {
			function()
				--verify deletable preset
				if selectedPresetName == "" or selectedPresetName == "<new>" or selectedPresetName == placeHolder then
					return
				end

				WG.Chobby.ConfirmationPopup(disableSelectedPreset,
					"This will delete preset: \"" .. selectedPresetName .. "\". Are you sure?", nil,
					315,
					170, i18n("yes"), i18n("cancel"))
			end
		},
	}

	local errorLabel = Label:New {
		x = 10,
		width = 200,
		y = 130,
		align = "left",
		height = 35,
		caption = errorStr, --start with the errorstring defined before
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
	}
	-- reset errorStr to only show it once
	errorStr = ""

	-- overload the writeError function
	writeError = function(errorM)
		errorLabel.caption = errorM
	end

	refreshPresetMenu()

	parentPanel:AddChild(buttonLoad)
	parentPanel:AddChild(buttonDelete)
	parentPanel:AddChild(buttonSave)
	parentPanel:AddChild(errorLabel)
	return { parentPanel }
end

local function CreateOptionpresetWindow()
	local ww, wh = Spring.GetWindowGeometry()

	local optionpresetWindow = Window:New {
		caption = "",
		align = "center",
		name = "OptionpresetsWindow",
		parent = WG.Chobby.lobbyInterfaceHolder,
		width = math.min(505, ww - 50),
		height = math.min(380, wh - 50),
		resizable = false,
		draggable = false,
		classname = "main_window",
	}
	-- first panel
	local contentsPanel = ScrollPanel:New {
		x = 4,
		right = 0,
		y = 10,
		bottom = 0,
		horizontalScrollbar = false,
	}

	-- add the tabs
	local tabs = {}
	tabs[1] = {
		name = "presets",
		caption = "Presets",
		tooltip = "Manage presets",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		children = { contentsPanel },
		weight = 1,
	}


	-- potential panel 2
	local optionpanel = ScrollPanel:New {
		x = 4,
		y = 10,
		right = 0,
		bottom = 0,
		-- height = 100,
		-- width = 400,
		-- parent = contentsPanel,
		horizontalScrollbar = false,
	}
	tabs[2] = {
		name = "options",
		caption = "Load Options",
		tooltip = "Specify which options are saved and loaded.",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		children = { optionpanel },
		weight = 2,
	}

	-- initiate the tab layout
	local tabPanel = Chili.DetachableTabPanel:New {
		x = 4,
		right = 4,
		y = 49,
		bottom = 75,
		padding = { 0, 0, 0, 0 },
		minTabWidth = 210,
		tabs = tabs,
		parent = optionpresetWindow,
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
		padding = { 18, 6, 18, 0 },
		parent = optionpresetWindow,
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

	local buttonCancel = Button:New {
		right = 6,
		width = 135,
		bottom = 1,
		height = 70,
		caption = i18n("cancel"),
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		parent = optionpresetWindow,
		classname = "negative_button",
		OnClick = {
			function()
				-- CancelFunc()
				window:Dispose()
			end
		},
	}

	WG.Chobby.lobbyInterfaceHolder.OnResize = WG.Chobby.lobbyInterfaceHolder.OnResize or {}
	WG.Chobby.lobbyInterfaceHolder.OnResize[#WG.Chobby.lobbyInterfaceHolder.OnResize + 1] = function()
		local ww, wh = Spring.GetWindowGeometry()

		local neww = math.min(1666, ww - 50)
		local newx = (WG.Chobby.lobbyInterfaceHolder.width - neww) / 2

		local newh = math.min(420, wh - 50)
		local newy = (WG.Chobby.lobbyInterfaceHolder.height - newh) / 2

		optionpresetWindow:SetPos(
			newx,
			newy,
			neww,
			newh
		)
	end

	local function CancelFunc()
		window:Dispose()
	end

	local popupHolder = WG.Chobby.PriorityPopup(optionpresetWindow, CancelFunc, nil)
	window = optionpresetWindow
	PopulatePresetPanel(contentsPanel)

	-- adding the enabled/ disabled options
	-- preparing the array
	-- first all should be enabled, keys are the same as in the localjson
	-- only redefine if undefined
	if (enabledOptions["Bots"] == nil) then
		enabledOptions["Bots"] = true
		enabledOptions["Map"] = true
		enabledOptions["Modoptions"] = true
		enabledOptions["Start Boxes"] = true
	end
	if multiplayer and enabledOptions["Multiplayer Battle Settings"] == nil then
		enabledOptions["Multiplayer Battle Settings"] = multiplayer
	end

	-- disable multiplayer options again when back to singleplayer
	if not multiplayer then
		enabledOptions["Multiplayer Battle Settings"] = nil
	end


	local counter = 0
	for key, value in pairs(enabledOptions) do
		optionpanel:AddChild(ProcessBoolOption(key, value, counter))
		counter = counter + 1
	end
end

-- clones the multiplayer modoptions to have a reset point that can be used when applying reset value
function OptionpresetsPanel.cloneMPModoptions(force)
	if multiplayerModoptions == nil or force then
		battleLobby = WG.LibLobby.localLobby
		multiplayerModoptions = Spring.Utilities.CopyTable(battleLobby:GetMyBattleModoptions() or {})
	end
end

-- external function to open the preset Panel
function OptionpresetsPanel.ShowPresetPanel()
	battleLobby = WG.LibLobby.localLobby
	battle = battleLobby:GetBattle(battleLobby:GetMyBattleID())

	-- multiplayer case, battle/ lobby are the WG.LibLobby.lobby
	if not battle then
		battleLobby = WG.LibLobby.lobby
		battle = battleLobby:GetBattle(battleLobby:GetMyBattleID())
		multiplayer = true
	else
		multiplayer = false
	end


	-- copy all options from the battle/ lobby for managing:

	currentModoptions = Spring.Utilities.CopyTable(battleLobby:GetMyBattleModoptions() or {})

	if battle then
		currentMap = battle.mapName
	else
		Spring.Echo("No battle found")
	end


	local currentAINames = battleLobby.battleAis
	currentAITable = {}
	for _, value in pairs(currentAINames) do
		local aiStatus = battleLobby:GetUserBattleStatus(value)
		if (aiStatus ~= nil) then
			currentAITable[value] = aiStatus
		end
	end

	currentStartRects = WG.BattleRoomWindow.GetCurrentStartRects()

	-- multiplayer specific options
	if multiplayer then
		-- if
		WG.OptionpresetsPanel.cloneMPModoptions(false)


		if currentMPBattleSettings == nil then
			currentMPBattleSettings = {}
		end
		currentMPBattleSettings["locked"] = battle.locked
		currentMPBattleSettings["autoBalance"] = battle.autoBalance
		currentMPBattleSettings["teamSize"] = battle.teamSize
		currentMPBattleSettings["nbTeams"] = battle.nbTeams
		currentMPBattleSettings["balanceMode"] = battle.balanceMode
		currentMPBattleSettings["preset"] = battle.preset
	end

	CreateOptionpresetWindow()
end

-- make the widget accessible from the preset Panel
function widget:Initialize()
	CHOBBY_DIR = LUA_DIRNAME .. "widgets/chobby/"
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	-- clone multiplayer options, if they are defined
	WG.OptionpresetsPanel = OptionpresetsPanel
end
