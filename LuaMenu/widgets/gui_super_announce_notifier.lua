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
local IMG_SUPERANNOUNCE = LUA_DIRNAME .. "images/welcomepanel/koth_2years.png"

local enableAnnouncement = true -- this is the actual enable/disable switch

-- The announcement runs in phases. Each phase has its own doNotAskAgain key,
-- so closing or opting out of one phase does not hide the next one.
-- Dates are second, minute, hour, day, month, year (UTC).
local phases = {
	{
		-- Build-up: no stream to link to yet
		doNotAskAgainValue = "koth2years2026",
		startDate = {0, 0, 0, 27, 10, 2026},
		endDate = {0, 0, 10, 1, 11, 2026}, -- stream starts 1 Nov 11:00 CET
		text = "Sunday 1 November 2026, 10:00 UTC (11:00 CET)"
			.. " \n" .. " \n"
			.. "Two years of Kings, Peasants and absolute chaos! KOTH has grown into BAR's largest"
			.. " player-hosted event, with over 5000 players to date."
			.. " \n" .. " \n"
			.. "Celebrate with us live on the official BAR Twitch and YouTube channels, and keep an eye"
			.. " out for something new dropping halfway through the stream!",
	},
	{
		-- Live: stream is up, show the Watch button
		doNotAskAgainValue = "koth2years2026_live",
		startDate = {0, 0, 10, 1, 11, 2026},
		endDate = {0, 0, 0, 2, 11, 2026},
		watchUrl = "https://www.twitch.tv/beyondallreasonofficial",
		text = "We're live now!"
			.. " \n" .. " \n"
			.. "Two years of Kings, Peasants and absolute chaos! Celebrate KOTH, BAR's largest player-hosted"
			.. " event with over 5000 players to date, and keep an eye out for something new dropping halfway through!"
			.. " \n" .. " \n"
			.. "A huge thank you to everyone who has played and volunteered!",
	},
}

-- Country gate. The lobby server hands us an ISO country code per user (ADDUSER),
-- so we can restrict an announcement to a region. Set to nil to show it to everyone.
-- Players whose country the server does not know are treated as not matching.
local allowedCountries = nil

-- shoutout to PTAQ for breaking things
local function ClampDate(date)
	return {
		math.min(math.max(1, date[1] or 0), 60),
		math.min(math.max(1, date[2] or 0), 60),
		math.min(math.max(1, date[3] or 0), 24),
		math.min(math.max(1, date[4] or 0), 28), -- no way am i checking how this handles 31 in a 28 day month
		math.min(math.max(1, date[5] or 0), 12),
		math.min(math.max(2024, date[6] or 0), 2077)
	}
end

for i = 1, #phases do
	phases[i].startDate = ClampDate(phases[i].startDate)
	phases[i].endDate = ClampDate(phases[i].endDate)
end

local function GetActivePhase()
	for i = 1, #phases do
		local phase = phases[i]
		local _, startIsInTheFuture = Spring.Utilities.GetTimeDifferenceTable(phase.startDate)
		local _, endIsInTheFuture = Spring.Utilities.GetTimeDifferenceTable(phase.endDate)
		if not startIsInTheFuture and endIsInTheFuture then
			return phase
		end
	end
end

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

	if enableAnnouncement == false then
		return
	end

	local phase = GetActivePhase()
	if not phase or Configuration.supperAnnouncementKey == phase.doNotAskAgainValue then
		return
	end

	if not InAllowedCountry() then
		return
	end

	local width, height = Spring.GetViewSizes()

	-- The banner art is 16:9 and spans the full window. Size the window to fit it,
	-- clamped to the viewport, and let the banner shrink first on short screens
	-- rather than pushing content off-window.
	local BANNER_ASPECT = 720 / 1280

	local BOTTOM_STACK = phase.watchUrl and 150 or 70 -- everything from the Watch button (or Close) down
	local HEADER_H = 128     -- title + subtitle
	local TEXT_GAP = 24      -- breathing room between description and the buttons

	local TEXT_H = 192 -- 8 lines at font 3, never squeezed below this

	local winW = math.min(880, width - 60)
	local bannerH = math.floor((winW - 24) * BANNER_ASPECT)
	local winH = math.min(HEADER_H + bannerH + 22 + TEXT_H + TEXT_GAP + BOTTOM_STACK, height - 40)

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
		caption = "King of the Hill Turns 2!",
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
		caption = "AllReasonNoLogic's 2-year anniversary stream",
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
		text = phase.text,
		parent = superAnnounceWindow
	}

	local function CancelFunc()
		superAnnounceWindow:Dispose()
	end

	-- Main call to action, only once there is something to watch
	if phase.watchUrl then
		Button:New {
			x = "22%",
			right = "22%",
			bottom = 78,
			height = 58,
			caption = "Watch the Stream",
			objectOverrideFont = WG.Chobby.Configuration:GetFont(4),
			classname = "action_button",
			padding = {2, 4, 4, 4},
			OnClick = {
				function()
					WG.BrowserHandler.OpenUrl(phase.watchUrl)
				end
			},
			parent = superAnnounceWindow
		}
	end

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
		checked = Configuration.supperAnnouncementKey == phase.doNotAskAgainValue or false,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		parent = superAnnounceWindow,
		OnClick = {
			function (obj)
				if obj.checked then
					Configuration:SetConfigValue("supperAnnouncementKey", phase.doNotAskAgainValue)
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
