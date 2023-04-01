--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Steam Release Notifier",
		desc      = "Tells people using standalone ZK when Steam is available.",
		author    = "GoogleFrog",
		date      = "23 April 2018",
		license   = "GNU LGPL, v2.1 or later",
		layer     = 0,
		enabled   = false  --  loaded by default?
	}
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Initialization
local IMG_LINK = LUA_DIRNAME .. "images/link.png"
local doNotAskAgainKey = "steamReleasePopupSeen"
local releaseDate = {0, 15, 8, 27, 4, 2018} -- second, minute, hour, day, month, year

local function SteamCheckPopup()
	local Configuration = WG.Chobby.Configuration

	if WG.Chobby.Configuration.gameConfig.disableSteam or Configuration.canAuthenticateWithSteam or Configuration[doNotAskAgainKey] then
		return
	end

	local _, timeIsInTheFuture = Spring.Utilities.GetTimeDifferenceTable(releaseDate)
	if timeIsInTheFuture then
		return
	end

	local width, height = Spring.GetViewSizes()

	local steamWindow = Window:New {
		x = (width-460)/2,
		y = (height-470)/2,
		width = 460,
		height = 470,
		caption = "",
		resizable = false,
		draggable = false,
		parent = WG.Chobby.lobbyInterfaceHolder,
		classname = "main_window",
	}

	TextBox:New {
		x = 74,
		right = 15,
		y = 23,
		height = 35,
		fontsize = Configuration:GetFont(4).size,
		text = "Zero-K is on Steam!",
		parent = steamWindow,
	}

	TextBox:New {
		x = 28,
		right = 28,
		y = 76,
		height = 35,
		fontsize = Configuration:GetFont(2).size,
		text = "You can help out by switching to the Steam version of Zero-K. This lets Steam know that people are interested in Zero-K which should, in turn, show the game to more potential players. See the settings guide for how to link your account and transfer your settings.",
		parent = steamWindow,
	}

	local function CancelFunc()
		steamWindow:Dispose()
	end

	local offset = 225
	Button:New {
		x = "26%",
		y = offset,
		right = "26%",
		height = 65,
		caption = "Store Page",
		font = Configuration:GetFont(4),
		classname = "action_button",
		padding = {2,4,4,4},
		OnClick = {
			function()
				WG.BrowserHandler.OpenUrl("https://store.steampowered.com/app/334920/ZeroK/")
			end
		},
		parent = steamWindow,
	}
	offset = offset + 74

	Button:New {
		x = "27%",
		y = offset,
		right = "27%",
		height = 42,
		caption = "Settings Guide",
		font = Configuration:GetFont(3),
		classname = "option_button",
		padding = {2,4,4,4},
		OnClick = {
			function()
				WG.BrowserHandler.OpenUrl("http://zero-k.info/mediawiki/index.php?title=Configuration_Files")
			end
		},
		parent = steamWindow,
		children = {
			Image:New {
				right = 2,
				y = 6,
				width = 20,
				height = 20,
				keepAspect = true,
				file = IMG_LINK
			}
		}
	}

	Button:New {
		right = 2,
		bottom = 2,
		width = 110,
		height = 42,
		classname = "negative_button",
		caption = i18n("close"),
		font = Configuration:GetFont(3),
		OnClick = {
			CancelFunc
		},
		parent = steamWindow,
	}

	Checkbox:New {
		x = 15,
		width = 130,
		bottom = 3,
		height = 35,
		boxalign = "right",
		boxsize = 15,
		caption = i18n("do_not_ask_again"),
		checked = Configuration[doNotAskAgainKey] or false,
		font = Configuration:GetFont(1),
		parent = steamWindow,
		OnClick = {
			function (obj)
				Configuration:SetConfigValue(doNotAskAgainKey, obj.checked)
			end
		},
	}

	-- I do not know why this fails to bring the dark background to the front. Leave it.
	--WG.Chobby.PriorityPopup(factionWindow, CancelFunc, CancelFunc)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

function widget:Initialize()
	CHOBBY_DIR = LUA_DIRNAME .. "widgets/chobby/"
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)
end

function widget:Update()
	WG.Delay(SteamCheckPopup, 2)
	widgetHandler:RemoveCallIn("Update")
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
