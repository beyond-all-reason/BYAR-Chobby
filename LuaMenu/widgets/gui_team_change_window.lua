--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Team change window",
		desc      = "Displays a team change window popup with a drop down list.",
		author    = "oopsbagel",
		date      = "2025-03-12",
		license   = "GNU LGPL, v2.1 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

local function CreateTeamChangeWindow(opts)
	opts = opts or {}
	local Configuration = WG.Chobby.Configuration

	local teamNumbers = {}
	for i = 1, opts.maxTeams do
		table.insert(teamNumbers, tostring(i))
	end

	local teamChangeWindow = Window:New {
		caption = "Change Team",
		name = "teamChangeWindow",
		parent = screen0,
		width = 280,
		height = 200,
		resizable = false,
		draggable = false,
		classname = "main_window",
	}

	local function ChangeAccepted()
		if opts.OnAccepted then
			opts.OnAccepted(opts.initialTeam)
		end
	end
	local function CloseFunction()
		teamChangeWindow:Dispose()
		teamChangeWindow = nil
	end

	local lblTitle = TextBox:New {
		x = 15,
		y = 15,
		width = teamChangeWindow.width - teamChangeWindow.padding[1] - teamChangeWindow.padding[3],
		height = 35,
		align = "center",
		multiline = true,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		text = opts.labelCaption,
		parent = teamChangeWindow,
		-- XXX handle longer strings gracefully
	}

	local btnOK = Button:New {
		x = "10%",
		width = "30%",
		bottom = 1,
		height = 40,
		caption = i18n("ok"),
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		classname = "action_button",
		OnClick = { CloseFunction, ChangeAccepted },
		parent = teamChangeWindow,
	}

	local btnCancel = Button:New {
		right = "10%",
		width = "30%",
		bottom = 1,
		height = 40,
		caption = i18n("cancel"),
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		classname = "negative_button",
		OnClick = { CloseFunction },
		parent = teamChangeWindow,
	}

	local cmbTeams = ComboBox:New {
		x = "5%",
		y = "40%",
		width = "50%",
		height = 35,
		caption = "",
		items = teamNumbers,
		parent = teamChangeWindow,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		itemHeight = 30,
		selected = tostring(opts.initialTeam),
		selectByName = true,
		OnSelectName = {
			function (obj, teamNumber)
				if teamNumber == nil then
					return
				end
				opts.initialTeam = tonumber(teamNumber)
			end
		},
	}

	WG.Chobby.PriorityPopup(teamChangeWindow, CloseFunction, CloseFunction, screen0)
end

function widget:Initialize()
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	WG.TeamChangeWindow = {
		CreateTeamChangeWindow = CreateTeamChangeWindow
	}
end
