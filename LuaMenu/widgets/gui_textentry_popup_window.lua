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
		caption = opts.caption or "",
		name = "TextEntryWindow",
		parent = screen0,
		width = opts.width or 280,
		height = opts.height or 330,
		resizable = false,
		draggable = opts.draggable or false,
		classname = "main_window",
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
		x = "0%",
		y = "5%",
		width = "90%",
		height = (opts.height or 330) /2,
		align = "center",
		multiline = true,
		font = Configuration:GetFont(2),
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
		font = Configuration:GetFont(2),
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
		font = Configuration:GetFont(2),
		classname = "action_button",
		OnClick = { CloseFunction },
		parent = TextEntryWindow,
	}


	local eb = EditBox:New{
		x = 0,
		width = TextEntryWindow.width * 0.90,
		height = opts.ebheight or 40,
		bottom = 45,
		text = opts.defaultValue or "",
		font = Configuration:GetFont(2),
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
		}
	}


	WG.Chobby.PriorityPopup(TextEntryWindow, CloseFunction, CloseFunction, screen0)
end

function widget:Initialize()
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	WG.TextEntryWindow = {
		CreateTextEntryWindow = CreateTextEntryWindow
	}
end
