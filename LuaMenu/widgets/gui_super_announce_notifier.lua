--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Super Announcement Notifier 1.02",
		desc      = "For important news. Opens a priority popup shortly after login. Can be restricted to a set of countries.",
		author    = "Moose, GoogleFrog, PtaQ",
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
local IMG_SUPERANNOUNCE = LUA_DIRNAME .. "images/welcomepanel/Commanders _Down_Under.png"
local doNotAskAgainValue = "cdu2026" -- change this for new announcement

local enableAnnouncement = true -- this is the actual enable/disable switch
-- The date from whichforth this announcement is meant to be visbile
-- So that you may make once ahead of time
local announceDate = {0, 0, 0, 1, 7, 2026} -- second, minute, hour, day, month, year (UTC)
local announceEndDate = {0, 0, 0, 25, 10, 2026} -- stop showing when event starts (25 Oct 11:00 AEDT)

-- Country gate. The lobby server hands us an ISO country code per user (ADDUSER),
-- so we can restrict an announcement to a region. Set to nil to show it to everyone.
-- Players whose country the server does not know are treated as not matching.
local allowedCountries = {
	AU = true,
	NZ = true,
}

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

local function InAllowedCountry()
	if not allowedCountries then
		return true
	end

	local lobby = WG.LibLobby and WG.LibLobby.lobby
	local myInfo = lobby and lobby:GetMyInfo()
	local country = myInfo and myInfo.country

	if not country or country == "??" then
		return false
	end
	return allowedCountries[country] or false
end

local function SuperAnnouncePopup()
	local Configuration = WG.Chobby.Configuration

	if enableAnnouncement == false or Configuration.supperAnnouncementKey == doNotAskAgainValue then
		return
	end

	if not InAllowedCountry() then
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

	-- The banner art is 2:1 and spans the full window, so it is 'winW / 2' tall on
	-- its own. That makes the window tall, so clamp to the viewport and let the
	-- banner shrink first on short screens rather than pushing content off-window.
	local winW = math.min(880, width - 60)
	local winH = math.min(1026, height - 40)

	local BOTTOM_STACK = 232 -- everything from the Get Tickets button down
	local HEADER_H = 128     -- title + subtitle
	local TEXT_GAP = 24      -- breathing room between description and Get Tickets

	local TEXT_H = 192 -- 8 lines at font 3, never squeezed below this

	local bannerH = math.floor((winW - 24) / 2)
	local maxBannerH = winH - BOTTOM_STACK - HEADER_H - TEXT_GAP - TEXT_H - 22
	if bannerH > maxBannerH then
		bannerH = math.max(120, maxBannerH)
	end

	local textY = HEADER_H + bannerH + 22
	local textH = winH - BOTTOM_STACK - TEXT_GAP - textY

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

	-- Title. Font 6 is tall, so the subtitle needs to sit well clear of it.
	Label:New {
		x = 0,
		width = winW - 35,
		align = "center",
		y = 18,
		height = 48,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(6),
		objectOverrideHintFont = WG.Chobby.Configuration:GetFont(6),
		caption = "Commanders Down Under",
		parent = superAnnounceWindow
	}

	-- Subtitle
	Label:New {
		x = 0,
		width = winW - 35,
		align = "center",
		y = 94,
		height = 26,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		objectOverrideHintFont = WG.Chobby.Configuration:GetFont(2),
		caption = "Australia's first ever Beyond All Reason tournament",
		parent = superAnnounceWindow
	}

	-- Banner. Full window width, no side margins, so the art is not letterboxed.
	if VFS.FileExists(IMG_SUPERANNOUNCE) then
		Image:New {
			x = 0,
			right = 0,
			y = HEADER_H,
			height = bannerH,
			keepAspect = true,
			file = IMG_SUPERANNOUNCE,
			parent = superAnnounceWindow
		}
	else
		textY = HEADER_H + 12
		textH = winH - BOTTOM_STACK - TEXT_GAP - textY
	end

	-- Description
	TextBox:New {
		x = 40,
		right = 40,
		y = textY,
		height = textH,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		objectOverrideHintFont = WG.Chobby.Configuration:GetFont(3),
		text = "Sunday 25 October 2026, 11:00 - 21:45 AEDT"
			.. " \n"
			.. "Fortress Sydney - Chippendale, NSW"
			.. " \n" .. " \n"
			.. "A seeded 1v1 Swiss bracket, open to every skill level, with a $300+ prize pool"
			.. " supported by Fortress and the Beyond All Reason team."
			.. " \n" .. " \n"
			.. "Tickets include 10% off food and drink at Fortress Sydney from 22-25 October,"
			.. " plus a free 1-hour LAN Lounge pass.",
		parent = superAnnounceWindow
	}

	local function CancelFunc()
		superAnnounceWindow:Dispose()
	end

	-- Main call to action
	Button:New {
		x = "22%",
		right = "22%",
		bottom = 174,
		height = 58,
		caption = "Get Tickets",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(4),
		classname = "action_button",
		padding = {2, 4, 4, 4},
		OnClick = {
			function()
				WG.BrowserHandler.OpenUrl("https://events.humanitix.com/commanders-down-under")
			end
		},
		parent = superAnnounceWindow
	}

	Button:New {
		x = "17%",
		right = "17%",
		bottom = 118,
		height = 46,
		caption = "Join the CDU Discord",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		classname = "option_button",
		padding = {2, 4, 4, 4},
		OnClick = {
			function()
				WG.BrowserHandler.OpenUrl("https://discord.gg/YAcNP5MjEn")
			end
		},
		parent = superAnnounceWindow
	}

	-- Region note. Labels autosize to their text, so keep it well clear of the
	-- button above rather than trusting the declared height.
	Label:New {
		x = 0,
		width = winW - 35,
		align = "center",
		bottom = 64,
		height = 28,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(1),
		objectOverrideHintFont = WG.Chobby.Configuration:GetFont(1),
		caption = "Special announcement visible to AU/NZ players only",
		parent = superAnnounceWindow
	}

	-- Close button
	Button:New {
		right = 14,
		bottom = 14,
		width = 120,
		height = 44,
		classname = "negative_button",
		caption = i18n("close"),
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		OnClick = {
			CancelFunc
		},
		parent = superAnnounceWindow
	}

	Checkbox:New {
		x = 22,
		width = 215,
		bottom = 18,
		height = 36,
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

-- The country only arrives with the user list, so wait for login rather than
-- firing off a plain timer from Initialize.
local function DelayedInitialize()
	local lobby = WG.LibLobby and WG.LibLobby.lobby
	if not lobby then
		return
	end

	lobby:AddListener("OnLoginInfoEnd", function()
		WG.Delay(SuperAnnouncePopup, 2)
	end)
end

function widget:Initialize()
	CHOBBY_DIR = LUA_DIRNAME .. "widgets/chobby/"
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)
	WG.Delay(DelayedInitialize, 1)
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
