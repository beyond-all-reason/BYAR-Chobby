--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "ZK Comm Config",
		desc      = "bla",
		author    = "KingRaptor",
		date      = "2017.02.18",
		license   = "GNU LGPL, v2.1 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- definitions

local moduleDefs, chassisDefs, upgradeUtilities, UNBOUNDED_LEVEL, _, moduleDefNames = VFS.Include("Gamedata/commanders/dynamic_comm_defs.lua")
local chassisDefsByName = {}
for i=1,#chassisDefs do
	local def = chassisDefs[i]
	chassisDefsByName[def.name] = def
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utilities

local function LoadComms()
	-- TBD
	return {
		{
			name = "Sample comm",
			chassis = "assault",
			slots = {
				[1] = {"commweapon_beamlaser"}
			}
		},
		{
			name = "Sample comm 2",
			chassis = "recon",
			slots = {
				[1] = {"commweapon_beamlaser"}
			}
		}
	}
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function CreateSlotEntry() -- redefined later
end

local function CreateModuleEntry(moduleDef, commConfig, level, slotNum, moduleList, slotHolder)
	local holder = Button:New {
		x = 0,
		y = 0,
		width = "100%",
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
		caption = "",
		OnClick = {
			function()
				commConfig.slots[level] = commConfig.slots[level] or {}
				commConfig.slots[level][slotNum] = moduleDef.name
				CreateSlotEntry(commConfig, level, slotNum, nil, moduleList, slotHolder)
			end
		},
	}

	local imagePanel = Panel:New {
		x = 2,
		y = 2,
		width = 76,
		height = 76,
		padding = {1,1,1,1},
		parent = holder,
	}
	local imageFile = moduleDef.image
	if imageFile then
		local image = Image:New {
			name = "image",
			x = 0,
			y = 0,
			right = 0,
			bottom = 0,
			keepAspect = true,
			file = imageFile,
			parent = imagePanel,
		}
	end
	local moduleName = TextBox:New {
		name = "moduleName",
		x = 90,
		y = 8,
		right = 0,
		height = 20,
		valign = 'center',
		fontsize = WG.Chobby.Configuration:GetFont(3).size,
		text = moduleDef.humanName,
		parent = holder,
	}
	local moduleType = TextBox:New {
		name = "moduleType",
		x = 108,
		y = 40,
		right = 0,
		height = 20,
		valign = 'center',
		fontsize = WG.Chobby.Configuration:GetFont(3).size,
		text = moduleDef.slotType,
		parent = holder,
	}
	local moduleCost = TextBox:New {
		name = "moduleCost",
		x = moduleName.x + 300 + 140,
		y = 8,
		right = 0,
		height = 20,
		valign = 'center',
		fontsize = WG.Chobby.Configuration:GetFont(3).size,
		text = "" .. moduleDef.cost,
		parent = holder,
	}

	return holder, {moduleDef.humanName, moduleDef.slotType or "", moduleDef.cost}
end

local function PopulateModuleList(moduleList, commConfig, level, slotNum, slotHolder)
	moduleList:Clear()
	local items = {}
	for i = 1, #moduleDefs do
		local def = moduleDefs[i]
		if not def.emptyModule then
			local controls, order = CreateModuleEntry(def, commConfig, level, slotNum, moduleList, slotHolder)
			items[#items + 1] = {#items, controls, order}
		end
	end
	moduleList:AddItems(items)
end

CreateSlotEntry = function(commConfig, level, slotNum, configuratorStack, moduleList, holder)
	local currentModule = commConfig.slots[level] and commConfig.slots[level][slotNum]
	local currentModuleDef = currentModule and moduleDefNames[currentModule] and moduleDefs[moduleDefNames[currentModule]]

	if not holder then
		holder = Panel:New{
			parent = configuratorStack,
			x = 16,
			height = 70,
			right = 4,
			backgroundColor = {0,0,0,0},
			padding = {0,0,0,0}
		}
	else
		holder:ClearChildren()
	end
	local imagePanel = Panel:New {
		x = 2,
		y = 2,
		width = 66,
		height = 66,
		padding = {1,1,1,1},
		parent = holder,
	}
	local imageFile = currentModuleDef and currentModuleDef.image
	if imageFile then
		local image = Image:New {
			name = "image",
			x = 0,
			y = 0,
			right = 0,
			bottom = 0,
			keepAspect = true,
			file = imageFile,
			parent = imagePanel,
		}
	end
	local button = Button:New{
		parent = holder,
		caption = currentModuleDef and currentModuleDef.humanName or i18n("no module"),
		height = "100%",
		x = 64,
		right = 72,
		fontsize = WG.Chobby.Configuration:GetFont(3).size,
		OnClick = {function() PopulateModuleList(moduleList, commConfig, level, slotNum, holder) end},
	}
	local buttonRemove = Button:New{
		parent = holder,
		caption = i18n("remove"),
		width = 72,
		height = "100%",
		right = 0,
		OnClick = {
			function()
				commConfig.slots[level] = commConfig.slots[level] or {}
				commConfig.slots[level][slotNum] = nil
				CreateSlotEntry(commConfig, level, slotNum, nil, moduleList, holder)
			end
		},
	}
end

local function SetupConfigurator(commConfig, configuratorStack, moduleList)
	local chassisDef = chassisDefsByName[commConfig.chassis]

	configuratorStack:ClearChildren()
	for i=1,5 do
		local level = Label:New{
			parent = configuratorStack,
			caption = "Level " .. (i + 1),
			autosize = true,
			fontsize = WG.Chobby.Configuration:GetFont(3).size,
		}
		local slots = chassisDef.levelDefs[i].upgradeSlots
		for j=1,#slots do
			CreateSlotEntry(commConfig, i, j, configuratorStack, moduleList)
		end
	end
end

local function CreateCommEntry(commConfig, configuratorStack, moduleList)
	local chassisDef = chassisDefsByName[commConfig.chassis]
	local holder = Button:New {
		x = 0,
		y = 0,
		width = "100%",
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
		caption = "",
		OnClick = {
			function()
				SetupConfigurator(commConfig, configuratorStack, moduleList)
			end
		},
	}

	local imagePanel = Panel:New {
		x = 2,
		y = 2,
		width = 76,
		height = 76,
		padding = {1,1,1,1},
		parent = holder,
	}

	local image = Image:New {
		name = "image",
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		keepAspect = true,
		file = "LuaMenu/configs/gameConfig/zk/unitpics/" .. commConfig.chassis .. ".png",
		parent = imagePanel,
	}
	local commName = TextBox:New {
		name = "commName",
		x = 90,
		y = 8,
		right = 0,
		height = 20,
		valign = 'center',
		fontsize = WG.Chobby.Configuration:GetFont(3).size,
		text = commConfig.name,
		parent = holder,
	}
	local commChassis = TextBox:New {
		name = "commChassis",
		x = commName.x + 240,
		y = 8,
		right = 0,
		height = 20,
		valign = 'center',
		fontsize = WG.Chobby.Configuration:GetFont(3).size,
		text = chassisDef.humanName,
		parent = holder,
	}

	return holder, {commConfig.name, chassisDef.humanName}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Controls

local function InitializeControls(parentControl)
	Label:New {
		x = 18,
		y = 16,
		width = 180,
		height = 30,
		parent = parentControl,
		font = WG.Chobby.Configuration:GetFont(3),
		caption = i18n("Configure commanders"),
	}

	local btnLeaveScreen = Button:New {
		right = 11,
		y = 7,
		width = 80,
		height = 45,
		font =  WG.Chobby.Configuration:GetFont(3),
		caption = i18n("close"),
		classname = "negative_button",
		OnClick = {
			function()
				parentControl:Hide()
			end
		},
		parent = parentControl,
	}

	local comms = LoadComms()

	-------------------------
	-- Generate List
	-------------------------

	local configListHolder = Control:New {
		x = 12,
		right = "50%",
		y = 52,
		height = "30%",
		parent = parentControl,
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
	}

	local configurator = Panel:New{
		x = 12,
		right = "50%",
		height = "60%",
		bottom = 12,
		parent = parentControl,
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
	}
	local configuratorScroll = ScrollPanel:New{
		parent = configurator,
		x = 0,
		y = 0,
		width = "100%",
		height = "100%",
		horizontalScrollbar = false,
	}
	local configuratorStack = StackPanel:New{
		parent = configuratorScroll,
		x = 0,
		y = 0,
		width = "100%",
		height = "100%",
		orientation = "vertical",
		autoArrangeV = false,
		autosize = true,
		resizeItems = false,
	}

	local moduleListHolder = Control:New{
		x = "50%",
		right = 12,
		height = "60%",
		bottom = 12,
		parent = parentControl,
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
	}

	local headingsCommanders = {
		{name = "Name", x = 88, width = 240},
		{name = "Chassis", x = 88 + 240, width = 140},
	}
	local commanderList = WG.Chobby.SortableList(configListHolder, headingsCommanders, 80, 1)

	local headingsModules = {
		{name = "Name", x = 88, width = 300},
		{name = "Type", x = 88 + 300, width = 140},
		{name = "Cost", x = 88 + 300 + 140, width = 64}
	}
	local moduleList = WG.Chobby.SortableList(moduleListHolder, headingsModules, 80, 1)

	local items = {}
	for i = 1, #comms do
		local controls, order = CreateCommEntry(comms[i], configuratorStack, moduleList)
		items[#items + 1] = {#items, controls, order}
	end
	commanderList:AddItems(items)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- External Interface

local CommConfig = {}

function CommConfig.GetControl()
	local window = Control:New {
		name = "commConfig",
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		padding = {0, 0, 0, 0},
		OnParent = {
			function(obj)
				if obj:IsEmpty() then
					InitializeControls(obj)
				end
			end
		},
	}
	return window
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

function widget:Initialize()
	CHOBBY_DIR = LUA_DIRNAME .. "widgets/chobby/"
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	WG.CommConfig = CommConfig
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
