--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Friend Window",
		desc      = "Handles friends.",
		author    = "gajop",
		date      = "13 August 2016",
		license   = "GNU LGPL, v2.1 or later",
		layer     = -100000,
		enabled   = true  --  loaded by default?
	}
end

local friendWindow

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Initialization

local initialized = false

local function InitializeControls(window)
	Label:New {
		x = 40,
		y = 40,
		width = 180,
		height = 30,
		parent = window,
		font = WG.Chobby.Configuration:GetFont(4),
		caption = "Friends",
	}

	if WG.Chobby.Configuration.showAddFriendBoxOnFriendWindow then
		local addFriendEditBox = EditBox:New {
			x = 220,
			width = 250,
			y = 35,
			height = 35,
			text = "",
			font = Configuration:GetFont(3),
			useIME = false,
			parent = window,
			tooltip = "Name of new friend",
		}

		local addFriendButton = Button:New {
			right = 470,
			width = 130,
			y = 35,
			height = 35,
			caption = "Add Friend",
			font = Configuration:GetFont(3),
			classname = "option_button",
			parent = window,
			tooltip = "Click to send a friend request",
			OnClick = {
				function()
					lobby:addfriend(addFriendEditBox.text)
				end
			},
		}
	end


end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- External Interface

local FriendWindow = {}

function FriendWindow.GetControl()
	friendWindow = WG.Chobby.FriendListWindow()
	return friendWindow.window
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

local function DelayedInitialize()
end

function widget:Initialize()
	CHOBBY_DIR = LUA_DIRNAME .. "widgets/chobby/"
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	WG.Delay(DelayedInitialize, 1)

	WG.FriendWindow = FriendWindow
end

function widget:Shutdown()
	-- if WG.LibLobby then

	-- end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
