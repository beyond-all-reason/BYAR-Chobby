function widget:GetInfo()
	return {
		name    = 'Keys Panel',
		desc    = 'Shows static pictures of key bindings.',
		author  = 'Fireball',
		date    = '2023-03-16',
		license = 'GNU GPL v2',
		layer   = 0,
		enabled = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Local Variables

local keysWindow

local IMG_KeysDefault = LUA_DIRNAME .. "images/keyboard_shortcuts/keyboardShortcutsDefault.png"
local IMG_KeysCtrl    = LUA_DIRNAME .. "images/keyboard_shortcuts/keyboardShortcutsCtrl.png"
local IMG_KeysAlt     = LUA_DIRNAME .. "images/keyboard_shortcuts/keyboardShortcutsAlt.png"

local listFont2

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utilities
local function ShowImgDef()
	keysWindow.SetImage(IMG_KeysDefault)
end
local function ShowImgCtrl()
	keysWindow.SetImage(IMG_KeysCtrl)
end
local function ShowImgAlt()
	keysWindow.SetImage(IMG_KeysAlt)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Controls

local function InitializeControls()
	local Configuration = WG.Chobby.Configuration

    listFont2 = Font:New(Configuration:GetFont(2))

    local vsx, vsy = Spring.GetViewSizes()
	local keysWindow = Window:New {
		classname = "main_window",
		parent = WG.Chobby.lobbyInterfaceHolder,
		width = WG.Chobby.lobbyInterfaceHolder.width -10,
		height = WG.Chobby.lobbyInterfaceHolder.height -10,
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
	}

	WG.Chobby.lobbyInterfaceHolder.OnResize = WG.Chobby.lobbyInterfaceHolder.OnResize or {}
	WG.Chobby.lobbyInterfaceHolder.OnResize[#WG.Chobby.lobbyInterfaceHolder.OnResize +1] = function()
		local newh = WG.Chobby.lobbyInterfaceHolder.height - 10
		local newy = WG.Chobby.lobbyInterfaceHolder.height - 10
		keysWindow:SetPos(
			nil,
			newy,
			nil,
			newh)
	end

	local labelbottomY = 22+21

	local function CloseFunc()
		keysWindow:Hide()
	end

	-------------------------
	-- Buttons
	-------------------------
	
	local offsetX = 20
	local btnDefault = Button:New {
		x = offsetX,
		y = 13,
		width = 80,
		height = 35,
		caption = "default",
		objectOverrideFont = listFont2,
		classname = "negative_button",
		parent = keysWindow,
		OnClick = {ShowImgDef},
	}
	offsetX = offsetX + 83
	local btnCtrl = Button:New {
		x = offsetX,
		y = 13,
		width = 80,
		height = 35,
		caption = "Ctrl",
		objectOverrideFont = listFont2,
		classname = "negative_button",
		parent = keysWindow,
		OnClick = {ShowImgCtrl},
	}
	offsetX = offsetX + 83
	local btnAlt = Button:New {
		x = offsetX,
		y = 13,
		width = 80,
		height = 35,
		caption = "Alt",
		objectOverrideFont = listFont2,
		classname = "negative_button",
		parent = keysWindow,
		OnClick = {ShowImgAlt},
	}

	local btnClose = Button:New {
		right = 18,
		y = 13,
		width = 80,
		height = 35,
		caption = i18n("close"),
		objectOverrideFont = listFont2,
		classname = "negative_button",
		parent = keysWindow,
		OnClick = {
			function()
				CloseFunc()
			end
		},
	}
	
	-------------------------
	-- Key Binding Image
	-------------------------

	local buttonsHeight = 13+35
	local imKeys = Image:New {
		x = 1,
		y = buttonsHeight+3,
		name = "imKeys",
		width = WG.Chobby.lobbyInterfaceHolder.width - 10,
		height = WG.Chobby.lobbyInterfaceHolder.height - (buttonsHeight+3) - 10,
		parent = keysWindow,
		keepAspect = true,
		file = IMG_KeysDefault,
	}

	-------------------------
	-- External Funcs
	-------------------------

	local externalFunctions = {}
	-- 
	function externalFunctions.Show()
		if not keysWindow.visible then
			keysWindow:Show()
		end
		WG.Chobby.PriorityPopup(keysWindow, CloseFunc)
	end

	function externalFunctions.SetImage(image)
		imKeys.file = image
		imKeys:Invalidate()
	end

	function externalFunctions.Dispose()
		keysWindow:Dispose()
	end

	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- External Interface

local KeysPanel = {}

function KeysPanel.Show()
	if not keysWindow then
		keysWindow = InitializeControls()
	end
	keysWindow.Show()
end

function KeysPanel.Preload()
	if not keysWindow then
		keysWindow = InitializeControls()
	end
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

function widget:Initialize()
	CHOBBY_DIR = LUA_DIRNAME .. "widgets/chobby/"
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)
	WG.KeysPanel = KeysPanel
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
