--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Integer Selector Window",
		desc      = "Displays an integer selector window popup.",
		author    = "Beherith",
		date      = "2020.11",
		license   = "GNU LGPL, v2.1 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end


local function CreateIntegerSelectorWindow(opts)
	opts = opts or {}

	local integerTrackBarValue = opts.defaultValue or 0
	local Configuration = WG.Chobby.Configuration

	local IntegerSelectorWindow = Window:New {
		caption = opts.caption or "",
		name = "IntegerSelectorWindow",
		parent = screen0,
		width = opts.width or 280,
		height = opts.height or 330,
		resizable = false,
		draggable = opts.draggable or false,
		classname = "main_window",
	}

	local function ChangeAccepted()
		if opts.OnAccepted then
			opts.OnAccepted(integerTrackBarValue)
		end
	end

	local function CloseFunction()
		IntegerSelectorWindow:Dispose()
		IntegerSelectorWindow = nil
	end

	local lblTitle = TextBox:New {
		x = "0%",
		y = "5%",
		width = "90%",
		height = (opts.height or 330) /2,
		align = "center",
		multiline = true,
		font = Configuration:GetFont(2),
		text = opts.labelCaption or "",
		parent = IntegerSelectorWindow,
	}
	if opts.imageFile then
		local wideimg = Image:New{
			name = "IntegerSelectorWindowImage",
			x = "5%",
			y = "40%",
			width = opts.imageWidth or "90%",
			height = opts.imageHeight or "33%",
			parent = IntegerSelectorWindow,
			keepAspect = opts.keepAspect and true,
			image = opts.imageFile,
		}
	end

	local btnOK = Button:New {
		x = "2%",
		width = "30%",
		bottom = 1,
		height = 40,
		caption = i18n("ok"),
		font = Configuration:GetFont(2),
		classname = "action_button",
		OnClick = { CloseFunction, ChangeAccepted },
		parent = IntegerSelectorWindow,
	}

	local btnCancel = Button:New {
		right = "2%",
		width = "30%",
		bottom = 1,
		height = 40,
		caption = i18n("cancel"),
		font = Configuration:GetFont(2),
		classname = "negative_button",
		OnClick = { CloseFunction },
		parent = IntegerSelectorWindow,
	}

	local tbValue = TextBox:New{
		right = "45%",
		width = "10%",
		bottom = 5,
		height = 40,
		align = "center",
		caption = tostring(opts.defaultValue),
		font = Configuration:GetFont(2),
		parent = IntegerSelectorWindow,
	}

	tbValue:SetText(tostring(opts.defaultValue))

	local integerTrackBar = Trackbar:New {
		x = 0,
		width  = IntegerSelectorWindow.width * 0.90,
		height = 40,
		bottom = 45,
		value  = opts.defaultValue or 0,
		min    = opts.minValue or 0,
		max    = opts.maxValue or 100,
		step   = opts.step or 1,
		parent = IntegerSelectorWindow,
		OnChange = {
			function(obj, value)
				--Spring.Echo(value)
				integerTrackBarValue = value
				tbValue:SetText(tostring(value))
				tbValue:Invalidate()
			end
		}
	}

	WG.Chobby.PriorityPopup(IntegerSelectorWindow, CloseFunction, CloseFunction, screen0)
end

function widget:Initialize()
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	WG.IntegerSelectorWindow = {
		CreateIntegerSelectorWindow = CreateIntegerSelectorWindow
	}
end
