--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Super Announcement Notifier",
		desc      = "For important news. Opens a priority popup shortly after launch.",
		author    = "Moose, GoogleFrog",
		date      = "11 November 2024",
		version   = "1.0",
		license   = "GNU LGPL, v2.1 or later",
		layer     = 0,
		enabled   = true  --  disabling this won't turn the announcement off
	}
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Initialization
local IMG_SUPERANNOUNCE = LUA_DIRNAME .. "images/trailer.png"
local doNotAskAgainKey = "superAnnouncePopupSeen" -- change this for new announcement

local enableAnnouncement = true -- this is the actual enable/disable switch
local announceDate = {0, 15, 8, 27, 4, 2018} -- second, minute, hour, day, month, year

local function SuperAnnouncePopup()
	local Configuration = WG.Chobby.Configuration

	if enableAnnouncement == false or Configuration[doNotAskAgainKey] then
		return
	end

	local _, timeIsInTheFuture = Spring.Utilities.GetTimeDifferenceTable(announceDate)
	if timeIsInTheFuture then
		return
	end

	local width, height = Spring.GetViewSizes()

	local superAnnounceWindow = Window:New {
		x = (width-760)/2,
		y = (height-670)/2,
		width = 760,
		height = 670,
		caption = "",
		resizable = false,
		draggable = false,
		parent = WG.Chobby.lobbyInterfaceHolder,
		classname = "main_window",
		children = {}
	}

	Label:New {
		x = 0,
		width = superAnnounceWindow.width - 35,
		align = "center",
		y = 23,
		height = 35,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(7),
		objectOverrideHintFont = WG.Chobby.Configuration:GetFont(7),
		caption = "The New BAR Trailer is here!",
		parent = superAnnounceWindow
	}

	Image:New {
		x = 2,
		right = 2,
		align = "center",
		y = 80,
		width = 200,
		height = 200,
		keepAspect = true,
		file = IMG_SUPERANNOUNCE,
		parent = superAnnounceWindow
	}

	local offset = superAnnounceWindow.height * 0.65

	TextBox:New {
		x = 28,
		right = 28,
		y = offset - 120,
		height = 35,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		objectOverrideHintFont = WG.Chobby.Configuration:GetFont(2),
		text = "You can help out by watching the the new trailer for BAR. This lets Youtube know that people are interested in BAR which should, in turn, show the game to more potential players. For more info read the official announcement on our website.",
		parent = superAnnounceWindow
	}

	local function CancelFunc()
		superAnnounceWindow:Dispose()
	end

	Button:New {
		x = "26%",
		y = offset,
		right = "26%",
		height = 65,
		caption = "Watch the Trailer",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(5),
		classname = "action_button",
		padding = {2,4,4,4},
		OnClick = {
			function()
				WG.BrowserHandler.OpenUrl("https://youtu.be/8K_fSWfOC1w?si=XDExlc7a8tuq6bHe")
			end
		},
		parent = superAnnounceWindow
	}
	offset = offset + 74

	Button:New {
		x = "27%",
		y = offset,
		right = "27%",
		height = 42,
		caption = "Read annoucement",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		classname = "option_button",
		padding = {2,4,4,4},
		OnClick = {
			function()
				WG.BrowserHandler.OpenUrl("https://www.beyondallreason.info/news/bar-trailer-2024")
			end
		},
		parent = superAnnounceWindow,
	}

	Button:New {
		right = 2,
		bottom = 2,
		width = 110,
		height = 42,
		classname = "negative_button",
		caption = i18n("close"),
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		OnClick = {
			CancelFunc
		},
		parent = superAnnounceWindow
	}

	Checkbox:New {
		x = 15,
		width = 150,
		bottom = 3,
		height = 35,
		boxalign = "right",
		boxsize = 15,
		caption = i18n("do_not_ask_again"),
		checked = Configuration[doNotAskAgainKey] or false,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(1),
		parent = superAnnounceWindow,
		OnClick = {
			function (obj)
				Configuration:SetConfigValue(doNotAskAgainKey, obj.checked)
			end
		}
	}

	WG.Chobby.PriorityPopup(superAnnounceWindow, CancelFunc, CancelFunc)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

function widget:Initialize()
	CHOBBY_DIR = LUA_DIRNAME .. "widgets/chobby/"
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)
end

function widget:Update()
	WG.Delay(SuperAnnouncePopup, 2)
	widgetHandler:RemoveCallIn("Update")
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
