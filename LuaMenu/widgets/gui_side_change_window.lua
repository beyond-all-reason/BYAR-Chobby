--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Faction change window",
		desc      = "Displays a faction change window popup.",
		author    = "escaped",
		date      = "2nd wave of new world re-order",
		license   = "GNU LGPL, v2.1 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

local function CreateSideChangeWindow(opts)
	opts = opts or {}
	local selectedFaction = opts.initialSide

	local Configuration = WG.Chobby.Configuration
	local sidedata = Configuration:GetSideData()

	local factionMap = {}
	local factionNames = {}
	for index, data in ipairs(sidedata) do
		factionMap[data.name] = index - 1
		table.insert(factionNames, data.name)
	end

	local sideChangeWindow = Window:New {
		caption = "",
		name = "sideChangeWindow",
		parent = screen0,
		width = 280,
		height = 330,
		resizable = false,
		draggable = false,
		classname = "main_window",
	}

	local function ChangeAccepted()
		if opts.OnAccepted then
			opts.OnAccepted(selectedFaction)
		end
	end
	local function CloseFunction()
		sideChangeWindow:Dispose()
		sideChangeWindow = nil
	end

	local lblTitle = Label:New {
		x = 0,
		y = 15,
		width = sideChangeWindow.width - sideChangeWindow.padding[1] - sideChangeWindow.padding[3],
		height = 35,
		align = "center",
		objectOverrideFont = Configuration:GetFont(4),
		caption = "Choose Faction",
		parent = sideChangeWindow,
	}

	local btnOK = Button:New {
		x = "10%",
		width = "30%",
		bottom = 1,
		height = 40,
		caption = i18n("ok"),
		objectOverrideFont = Configuration:GetFont(2),
		classname = "action_button",
		OnClick = { CloseFunction, ChangeAccepted },
		parent = sideChangeWindow,
	}

	local btnCancel = Button:New {
		right = "10%",
		width = "30%",
		bottom = 1,
		height = 40,
		caption = i18n("cancel"),
		objectOverrideFont = Configuration:GetFont(2),
		classname = "negative_button",
		OnClick = { CloseFunction },
		parent = sideChangeWindow,
	}

	local imTeamFaction
	local cmbFactions = ComboBox:New {
		x = sideChangeWindow.width * 0.05,
		y = 150,
		width = sideChangeWindow.width * 0.5,
		height = 40,
		items = factionNames,
		parent = sideChangeWindow,
		objectOverrideFont = Configuration:GetFont(2),
		itemFontSize = Configuration:GetFont(2).size,
		itemHeight = 30,
		selected = selectedFaction + 1,
		selectByName = true,
		OnSelectName = {
			function (obj, name)
				local faction = factionMap[name]
				if faction == nil then
					return
				end
				selectedFaction = faction
				imTeamFaction.file = Configuration:GetSideById(faction).logo
				imTeamFaction:Invalidate()
			end
		},
	}

	imTeamFaction = Image:New {
		name = "imTeamFaction",
		x = cmbFactions.x + cmbFactions.width + 20,
		y = 150,
		width = 40,
		height = 40,
		parent = sideChangeWindow,
		keepAspect = false,
		file = Configuration:GetSideById(selectedFaction).logo,
	}

	WG.Chobby.PriorityPopup(sideChangeWindow, CloseFunction, CloseFunction, screen0)
end

function widget:Initialize()
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	WG.SideChangeWindow = {
		CreateSideChangeWindow = CreateSideChangeWindow
	}
end
