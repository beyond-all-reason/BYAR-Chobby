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
local IMG_SUPERANNOUNCE = LUA_DIRNAME .. "images/welcomepanel/lightbringer.png"
local doNotAskAgainValue = "lb" -- change this for new announcement

local enableAnnouncement = false -- this is the actual enable/disable switch
-- The date from whichforth this announcement is meant to be visbile
-- So that you may make once ahead of time
local announceDate = {0, 0, 0, 0, 0, 0} -- second, minute, hour, day, month, year (UTC)

-- shoutout to PTAQ for breaking things
announceDate = {
	math.min(math.max(1, announceDate[1] or 0), 60),
	math.min(math.max(1, announceDate[2] or 0), 60),
	math.min(math.max(1, announceDate[3] or 0), 24),
	math.min(math.max(1, announceDate[4] or 0), 28), -- no way am i checking how this handles 31 in a 28 day month
	math.min(math.max(1, announceDate[5] or 0), 12),
	math.min(math.max(2024, announceDate[6] or 0), 2077)
}

local function SuperAnnouncePopup()
	local Configuration = WG.Chobby.Configuration

	if enableAnnouncement == false or Configuration.supperAnnouncementKey == doNotAskAgainValue then
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
		height = 700,
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
		caption = "The Lightbringer Update is Here!",
		parent = superAnnounceWindow
	}

	Image:New {
		x = 2,
		right = 2,
		align = "center",
		y = 80,
		width = 450,
		height = 253,
		keepAspect = true,
		file = IMG_SUPERANNOUNCE,
		parent = superAnnounceWindow
	}

	local offset = superAnnounceWindow.height * 0.65
	offset = offset + 40

	TextBox:New {
		x = 28,
		right = 28,
		y = offset - 125,
		height = 35,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		objectOverrideHintFont = WG.Chobby.Configuration:GetFont(2),
		text = "Commanders, after two weeks of a testing run for the Lightbringer Update, we are thrilled to announce the merge went without any major issues. Enjoy BAR battles being more lit than ever!" .. " \n" .. " \n" .. "We have prepared a detailed post about the update and a Cinematic Highlights Video, check it out!",
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
		caption = "Watch the Video",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(5),
		classname = "action_button",
		padding = {2,4,4,4},
		OnClick = {
			function()
				WG.BrowserHandler.OpenUrl("https://www.youtube.com/watch?v=Gq-vKImyKoQ")
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
		caption = "Read the Patchnotes",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		classname = "option_button",
		padding = {2,4,4,4},
		OnClick = {
			function()
				WG.BrowserHandler.OpenUrl("https://www.beyondallreason.info/news/lightbringer-update")
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
		width = 190,
		bottom = 3,
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
