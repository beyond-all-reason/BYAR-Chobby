--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Text Entry Popop Window",
		desc      = "Displays a text input window popup.",
		author    = "Beherith",
		date      = "2021.07",
		license   = "GNU LGPL, v2.1 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end


local function CreateTextEntryWindow(opts)
	opts = opts or {}

	local editBoxValue = opts.defaultValue or 0
	local Configuration = WG.Chobby.Configuration

	local TextEntryWindow = Window:New {
		name = "TextEntryWindow",
		parent = screen0,
		width = opts.width or 280,
		height = opts.height or 330,
		resizable = false,
		draggable = opts.draggable or false,
		classname = "main_window_small",
	}

	local captionHolder = Control:New {
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		name = "captionHolder",
		parent = TextEntryWindow,
		--padding = {0, 0, 0, 0},
		children = {}
    }

	Label:New {
		x = 0,
		y = 0,
		width = TextEntryWindow.width - 36,
		bottom = 0,
		align = "center",
		parent = captionHolder,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(5),
		caption = opts.caption or "",
	}

	local function ChangeAccepted()
		if opts.OnAccepted then
			opts.OnAccepted(editBoxValue)
		end
	end

	local function CloseFunction()
		TextEntryWindow:Dispose()
		TextEntryWindow = nil
	end

	local lblTitle = TextBox:New {
		x = "2%",
		y = "20%",
		right = "2%",
		height = (opts.height or 330) /2,
		align = "center",
		multiline = true,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		objectOverrideHintFont = WG.Chobby.Configuration:GetFont(2),
		text = opts.labelCaption or "",
		parent = TextEntryWindow,
	}
	if opts.imageFile then
		local wideimg = Image:New{
			name = "TextEntryWindowImage",
			x = "5%",
			y = "40%",
			width = opts.imageWidth or "90%",
			height = opts.imageHeight or "33%",
			parent = TextEntryWindow,
			keepAspect = opts.keepAspect and true,
			image = opts.imageFile,
		}
	end

	local btnOK = Button:New {
		x = "2%",
		width = "30%",
		bottom = 1,
		height = 40,
		caption = opts.oklabel  or i18n("ok"),
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		classname = "action_button",
		OnClick = { CloseFunction, ChangeAccepted },
		parent = TextEntryWindow,
	}

	local btnCancel = Button:New {
		right = "2%",
		width = "30%",
		bottom = 1,
		height = 40,
		caption = opts.cancellabel or i18n("cancel"),
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		classname = "negative_button",
		OnClick = { CloseFunction },
		parent = TextEntryWindow,
	}


	local eb = EditBox:New{
		x = "2%",
		right = "2%",
		height = opts.ebheight or 40,
		bottom = 45,
		text = opts.defaultValue or "",
		hint = opts.hint or "",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		objectOverrideHintFont = WG.Chobby.Configuration:GetFont(11),
		useIME = false,
		parent = TextEntryWindow,
		--multiline = true,
		OnFocusUpdate = {
			function (obj)
				editBoxValue = obj.text
				if obj.focused then
					return
				end
			end
		},
		OnKeyPress = {
			function(obj, key)
				editBoxValue = obj.text
				if key == Spring.GetKeyCode("enter") or key == Spring.GetKeyCode("numpad_enter") then
					ChangeAccepted()
				end
			end
		},
	}

	if opts.OnOpen then
		opts.OnOpen(eb)
	end

	WG.Chobby.PriorityPopup(TextEntryWindow, CloseFunction, CloseFunction, screen0, nil, opts.disableAcceptHotkey)

	screen0:FocusControl(eb)
end

function widget:Initialize()
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	WG.TextEntryWindow = {
		CreateTextEntryWindow = CreateTextEntryWindow
	}
end
