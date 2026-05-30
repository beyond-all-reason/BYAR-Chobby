--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Super Announcement Notifier 1.01",
		desc      = "For important news. Opens a priority popup shortly after launch.",
		author    = "Moose, GoogleFrog",
		date      = "11 November 2024",
		version   = "1.0",
		license   = "GNU LGPL, v2.1 or later",
		layer     = 0,
		enabled   = true  -- DO NOT DISABLE? disabling this after enabling won't turn the announcement off 
	}
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Initialization
local IMG_SUPERANNOUNCE = LUA_DIRNAME .. "images/welcomepanel/BAR AlphaCup Series VI - XXS.png"
local doNotAskAgainValue = "acvi" -- change this for new announcement

local enableAnnouncement = false -- this is the actual enable/disable switch
-- The date from whichforth this announcement is meant to be visbile
-- So that you may make once ahead of time
local announceDate = {0, 0, 0, 20, 4, 2026} -- second, minute, hour, day, month, year (UTC)
local announceEndDate = {0, 0, 16, 25, 4, 2026} -- stop showing when event starts

-- shoutout to PTAQ for breaking things
announceDate = {
	math.min(math.max(1, announceDate[1] or 0), 60),
	math.min(math.max(1, announceDate[2] or 0), 60),
	math.min(math.max(1, announceDate[3] or 0), 24),
	math.min(math.max(1, announceDate[4] or 0), 28), -- no way am i checking how this handles 31 in a 28 day month
	math.min(math.max(1, announceDate[5] or 0), 12),
	math.min(math.max(2024, announceDate[6] or 0), 2077)
}
announceEndDate = {
	math.min(math.max(1, announceEndDate[1] or 0), 60),
	math.min(math.max(1, announceEndDate[2] or 0), 60),
	math.min(math.max(1, announceEndDate[3] or 0), 24),
	math.min(math.max(1, announceEndDate[4] or 0), 28),
	math.min(math.max(1, announceEndDate[5] or 0), 12),
	math.min(math.max(2024, announceEndDate[6] or 0), 2077)
}

local function SuperAnnouncePopup()
	local Configuration = WG.Chobby.Configuration

	if enableAnnouncement == false or Configuration.supperAnnouncementKey == doNotAskAgainValue then
		return
	end

	local _, startIsInTheFuture = Spring.Utilities.GetTimeDifferenceTable(announceDate)
	if startIsInTheFuture then
		return
	end

	local _, endIsInTheFuture = Spring.Utilities.GetTimeDifferenceTable(announceEndDate)
	if not endIsInTheFuture then
		return
	end

	local width, height = Spring.GetViewSizes()

	local winW, winH = 640, 740

	local superAnnounceWindow = Window:New {
		x = (width - winW) / 2,
		y = (height - winH) / 2,
		width = winW,
		height = winH,
		caption = "",
		resizable = false,
		draggable = false,
		parent = WG.Chobby.lobbyInterfaceHolder,
		classname = "main_window",
		children = {}
	}

	-- Title
	Label:New {
		x = 0,
		width = winW - 35,
		align = "center",
		y = 15,
		height = 40,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(6),
		objectOverrideHintFont = WG.Chobby.Configuration:GetFont(6),
		caption = "Alpha Cup VI",
		parent = superAnnounceWindow
	}

	-- Subtitle
	Label:New {
		x = 0,
		width = winW - 35,
		align = "center",
		y = 88,
		height = 25,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		objectOverrideHintFont = WG.Chobby.Configuration:GetFont(2),
		caption = "Register before April 24th!",
		parent = superAnnounceWindow
	}

	-- Logo
	Image:New {
		x = "25%",
		right = "25%",
		y = 100,
		height = 180,
		keepAspect = true,
		file = IMG_SUPERANNOUNCE,
		parent = superAnnounceWindow
	}

	-- Description
	TextBox:New {
		x = 36,
		right = 36,
		y = 295,
		height = 35,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		objectOverrideHintFont = WG.Chobby.Configuration:GetFont(2),
		text = "The flagship BAR 1v1 tournament returns - bigger, sharper, and more competitive than ever."
			.. " \n" .. " \n"
			.. "$1,500 prize pool + exclusive Crown of the 1v1 King cosmetic."
			.. " \n" .. " \n"
			.. "Double elimination format, open to all - no player cap!"
			.. " \n" .. " \n"
			.. "Day 1 (Apr 25, 16:00 UTC): Open bracket to Quarter Finals"
			.. " \n"
			.. "Day 2 (Apr 26, 16:00 UTC): Semifinals and Grand Finals"
			.. " \n" .. " \n"
			.. "Signups close April 24th at 21:00 UTC. Don't miss your shot!",
		parent = superAnnounceWindow
	}

	local function CancelFunc()
		superAnnounceWindow:Dispose()
	end

	-- Sign up button
	Button:New {
		x = "18%",
		right = "18%",
		bottom = 130,
		height = 55,
		caption = "Sign Up Now",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(4),
		classname = "action_button",
		padding = {2, 4, 4, 4},
		OnClick = {
			function()
				WG.BrowserHandler.OpenUrl("https://apm.bar/tour/alpha-cup")
			end
		},
		parent = superAnnounceWindow
	}

	-- Details link button
	Button:New {
		x = "25%",
		right = "25%",
		bottom = 80,
		height = 40,
		caption = "Full Details",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		classname = "option_button",
		padding = {2, 4, 4, 4},
		OnClick = {
			function()
				WG.BrowserHandler.OpenUrl("https://www.beyondallreason.info/news/alpha-cup-vi")
			end
		},
		parent = superAnnounceWindow
	}

	-- Close button
	Button:New {
		right = 2,
		bottom = 18,
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
		width = 190,
		bottom = 20,
		height = 35,
		boxalign = "right",
		boxsize = 20,
		caption = "Do not notify again",
		checked = Configuration.supperAnnouncementKey == doNotAskAgainValue or false,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		parent = superAnnounceWindow,
		OnClick = {
			function (obj)
				if obj.checked then
					Configuration:SetConfigValue("supperAnnouncementKey", doNotAskAgainValue)
				end
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
