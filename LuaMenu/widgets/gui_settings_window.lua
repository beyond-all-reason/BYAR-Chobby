--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Settings Window",
		desc      = "Handles settings.",
		author    = "GoogleFrog",
		date      = "4 July 2016",
		license   = "GNU LGPL, v2.1 or later",
		layer     = -100000,
		enabled   = true,  --  loaded by default?
		handler   = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Local Variables

local battleStartDisplay = 1
local lobbyFullscreen = 1

local FUDGE = 0

local inLobby = true
local currentMode = false
local currentManualBorderless = false
local delayedModeSet, delayedBorderOverride

local ITEM_OFFSET = 36

local COMBO_X = "55%"
local COMBO_WIDTH = 85
local CHECK_WIDTH = "55%"
local TEXT_OFFSET = 6

local settingsWindowHandler

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utilities

local function DisableWidget(name, veto)
	if widgetHandler.knownInfos and widgetHandler.knownInfos[name] and widgetHandler.knownInfos[name].active and name ~=veto then
		Spring.Echo("Removing widget", name)
		widgetHandler:RemoveWidget(widgetHandler:FindByName(name))
	end
end

local function DisableAllWidgets()
	if WG.Delay then
		WG.Delay(DisableAllWidgets, 0.1)
	end
	for name, data in pairs(widgetHandler.knownWidgets) do
		DisableWidget(name, "Delay API")
	end
	DisableWidget("Delay API")
end

local function ToPercent(value)
	return tostring(math.floor(0.5 + value)) .. "%"
end

local function ToggleFullscreenOff()
	Spring.SetConfigInt("Fullscreen", 1, false)
	Spring.SetConfigInt("Fullscreen", 0, false)

	if WG.Chobby.Configuration.agressivelySetBorderlessWindowed and not currentManualBorderless then
		local screenX, screenY = Spring.GetScreenGeometry()
		if currentManualBorderless then
			Spring.SetConfigInt("XResolutionWindowed", currentManualBorderless.width or (screenX - FUDGE*2), false)
			Spring.SetConfigInt("YResolutionWindowed", currentManualBorderless.height or (screenY - FUDGE*2), false)
			Spring.SetConfigInt("WindowPosX", currentManualBorderless.x or FUDGE, false)
			Spring.SetConfigInt("WindowPosY", currentManualBorderless.y or FUDGE, false)
		else
			Spring.SetConfigInt("XResolutionWindowed", screenX - FUDGE*2, false)
			Spring.SetConfigInt("YResolutionWindowed", screenY - FUDGE*2, false)
			Spring.SetConfigInt("WindowPosX", FUDGE, false)
			Spring.SetConfigInt("WindowPosY", FUDGE, false)
		end
	end
end

local function ToggleFullscreenOn()
	Spring.SetConfigInt("Fullscreen", 0, false)
	Spring.SetConfigInt("Fullscreen", 1, false)
end

local function SaveWindowPos(width, height, x, y)
	local Configuration = WG.Chobby.Configuration

	if not width then
		width, height, x, y = Spring.GetWindowGeometry()
	end
	local screenX, screenY = Spring.GetScreenGeometry()
	y = screenY - height - y

	if x then
		Configuration:SetConfigValue("window_WindowPosX", x)
	end
	if y then
		Configuration:SetConfigValue("window_WindowPosY", y)
	end
	if width then
		Configuration:SetConfigValue("window_XResolutionWindowed", width)
	end
	if height then
		Configuration:SetConfigValue("window_YResolutionWindowed", height)
	end

	-- WindowState is not saved by Spring. See https://springrts.com/mantis/view.php?id=5624
	Spring.SetConfigInt("WindowState", (x == 0 and 1) or 0, false)
end

local function ManualBorderlessChange(modeName)
	oldBorders = currentManualBorderless
	if not oldBorders then
		return true
	end
	local borders
	if inLobby then
		borders = WG.Chobby.Configuration[modeName].lobby or {}
	else
		borders = WG.Chobby.Configuration[modeName].game or {}
	end

	return not (oldBorders.x == borders.x and oldBorders.y == borders.y and oldBorders.width == borders.width and oldBorders.height == borders.height)
end

local function SetLobbyFullscreenMode(mode, borderOverride)
	mode = mode or delayedModeSet
	borderOverride = borderOverride or delayedBorderOverride
	if mode == currentMode and (not borderOverride) then
		if not ((mode == 4 or mode == 6) and ManualBorderlessChange((mode == 4 and "manualBorderless") or "manualWindowed")) then
			return
		end
	end

	local Configuration = WG.Chobby.Configuration
	local needAgressiveSetting = (mode ~= 2) and (currentMode ~= 2)

	if (currentMode == 2 or not currentMode) and lobbyFullscreen == 2 then
		SaveWindowPos()
	end
	currentMode = mode

	if Configuration.doNotSetAnySpringSettings then
		return
	end

	local screenX, screenY = Spring.GetScreenGeometry()

	Spring.Echo("SetLobbyFullscreenMode", mode)
	--Spring.Log(LOG_SECTION, LOG.ERROR, debug.traceback("problem"))

	if mode == 1 then -- Borderless
		-- Required to remove FUDGE
		currentManualBorderless = false

		Spring.SetConfigInt("Fullscreen", 1)

		Spring.SetConfigInt("XResolutionWindowed", screenX - FUDGE*2, false)
		Spring.SetConfigInt("YResolutionWindowed", screenY - FUDGE*2, false)
		Spring.SetConfigInt("WindowPosX", FUDGE, false)
		Spring.SetConfigInt("WindowPosY", FUDGE, false)

		Spring.SetConfigInt("WindowBorderless", 1, false)
		Spring.SetConfigInt("Fullscreen", 0, false)
	elseif mode == 2 then -- Windowed
		local winSizeX, winSizeY, winPosX, winPosY = Spring.GetWindowGeometry()
		winPosX = Configuration.window_WindowPosX or winPosX
		winSizeX = Configuration.window_XResolutionWindowed or winSizeX
		winSizeY = Configuration.window_YResolutionWindowed or winSizeY
		Spring.SetConfigInt("WindowBorderless", 0, false)
		Spring.SetConfigInt("Fullscreen", 0)

		if Configuration.window_WindowPosY then
			winPosY = Configuration.window_WindowPosY
		else
			winPosY = screenY - winPosY - winSizeY
		end

		if winPosY > 10 then
			-- Window is not stuck at the top of the screen
			Spring.SetConfigInt("WindowPosX", math.min(winPosX, screenX - 50), false)
			Spring.SetConfigInt("WindowPosY", math.min(winPosY, screenY - 50), false)
			Spring.SetConfigInt("XResolutionWindowed",  math.min(winSizeX, screenX), false)
			Spring.SetConfigInt("YResolutionWindowed",  math.min(winSizeY, screenY - 50), false)
		else
			-- Reset window to screen centre
			Spring.SetConfigInt("WindowPosX", screenX/4, false)
			Spring.SetConfigInt("WindowPosY", screenY/8, false)
			Spring.SetConfigInt("XResolutionWindowed", screenX/2, false)
			Spring.SetConfigInt("YResolutionWindowed", screenY*3/4, false)
		end
		Spring.SetConfigInt("WindowBorderless", 0, false)
		Spring.SetConfigInt("Fullscreen", 0)
	elseif mode == 3 then -- Fullscreen
		Spring.SetConfigInt("XResolution", screenX, false)
		Spring.SetConfigInt("YResolution", screenY, false)
		Spring.SetConfigInt("Fullscreen", 1, false)
		--WG.Delay(ToggleFullscreenOn, 0.1)
	elseif mode == 4 or mode == 6 then -- Manual Borderless and windowed
		local borders = borderOverride
		if not borders then
			local modeName = (mode == 4 and "manualBorderless") or "manualWindowed"
			if inLobby then
				borders = WG.Chobby.Configuration[modeName].lobby or {}
			else
				borders = WG.Chobby.Configuration[modeName].game or {}
			end
		end
		currentManualBorderless = Spring.Utilities.CopyTable(borders)

		Spring.SetConfigInt("XResolutionWindowed", borders.width or (screenX - FUDGE*2), false)
		Spring.SetConfigInt("YResolutionWindowed", borders.height or (screenY - FUDGE*2), false)
		Spring.SetConfigInt("WindowPosX", borders.x or FUDGE, false)
		Spring.SetConfigInt("WindowPosY", borders.y or FUDGE, false)

		Spring.SetConfigInt("WindowBorderless", (mode == 4 and 1) or 0, false)
		Spring.SetConfigInt("Fullscreen", (mode == 4 and 1) or 0)
	elseif mode == 5 then -- Manual Fullscreen
		local resolution
		if inLobby then
			resolution = WG.Chobby.Configuration.manualFullscreen.lobby or {}
		else
			resolution = WG.Chobby.Configuration.manualFullscreen.game or {}
		end
		Spring.SetConfigInt("XResolution", resolution.width or screenX, false)
		Spring.SetConfigInt("YResolution", resolution.height or screenY, false)
		Spring.SetConfigInt("Fullscreen", 1, false)
	end

	if delayedModeSet == mode and delayedBorderOverride then
		delayedModeSet = nil
		delayedBorderOverride = nil
	elseif needAgressiveSetting then
		delayedModeSet = mode
		delayedBorderOverride = borderOverride
		currentMode = 2

		-- not sure why this is needed, disabled the switching cause else borderless is like windowed, without the border, but not fullscreen
		--Spring.SetConfigInt("WindowBorderless", 0, false)
		--Spring.SetConfigInt("Fullscreen", 0)

		WG.Delay(SetLobbyFullscreenMode, 0.8)
	end
end

local function SaveLobbyDisplayMode()
	local Configuration = WG.Chobby.Configuration
	if (currentMode == 2 or not currentMode) and lobbyFullscreen == 2 then
		SaveWindowPos()
	end
	inLobby = true
	SetLobbyFullscreenMode(lobbyFullscreen)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Manual Borderless Setting

local function GetValueEntryBox(parent, name, position, currentValue)
	local Configuration = WG.Chobby.Configuration

	local label = Label:New {
		x = 15,
		width = 80,
		y = position + 5,
		align = "right",
		height = 35,
		caption = name .. ":",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		parent = parent,
	}

	local function FocusUpdate(obj)
		local newValue = tonumber(obj.text)

		if not newValue then
			obj:SetText(currentValue)
			return
		end

		currentValue = math.floor(math.max(0, newValue))
		obj:SetText(tostring(currentValue))
	end

	local edit = EditBox:New {
		x = 100,
		width = 160,
		y = position,
		height = 35,
		text = tostring(currentValue),
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		objectOverrideHintFont = WG.Chobby.Configuration:GetFont(3),
		parent = parent,
		OnFocusUpdate = {
			function (obj)
				if obj.focused then
					return
				end
				FocusUpdate(obj)
			end
		}
	}

	local function GetValue()
		FocusUpdate(edit)
		return currentValue
	end

	return GetValue
end

local function ShowWindowGeoConfig(name, modeNum, modeName, retreatPadding)
	local Configuration = WG.Chobby.Configuration

	local manualWindow = Window:New {
		x = 700,
		y = 300,
		width = 316,
		height = 334,
		caption = "",
		resizable = false,
		draggable = false,
		parent = WG.Chobby.lobbyInterfaceHolder,
		classname = "main_window",
	}

	local lblTitle = Label:New {
		x = 35,
		right = 15,
		y = 15,
		height = 35,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		caption = i18n("set_window_position"),
		parent = manualWindow,
	}

	local screenX, screenY = Spring.GetScreenGeometry()
	local borders = WG.Chobby.Configuration[modeName][name] or {}

	local xBox = GetValueEntryBox(manualWindow, "X", 60, borders.x or 0)
	local yBox = GetValueEntryBox(manualWindow, "Y", 100, borders.y or 0)
	local widthBox = GetValueEntryBox(manualWindow, "Width", 140, borders.width or screenX)
	local heightBox = GetValueEntryBox(manualWindow, "Height", 180, borders.height or screenY)

	local function RetreatToSafety(force)
		borders.x = retreatPadding
		borders.y = retreatPadding
		borders.width = screenX - retreatPadding*2
		borders.height = screenY - retreatPadding*2
		if force or ((name == "lobby") == (Spring.GetGameName() == "")) then
			SetLobbyFullscreenMode(modeNum)
		end
	end

	local function FinalApplyFunc()
		local lobbySetting = (name == "lobby")
		if lobbySetting then
			if not inLobby then
				SetLobbyFullscreenMode(battleStartDisplay)
			end
		else
			if inLobby then
				SetLobbyFullscreenMode(lobbyFullscreen)
			end
		end
	end

	local function FinalApplyFailureFunc()
		RetreatToSafety(true)
	end

	local function ApplyFunc()
		borders.x = xBox()
		borders.y = yBox()
		borders.width = widthBox()
		borders.height = heightBox()

		SetLobbyFullscreenMode(modeNum, borders)

		manualWindow:Dispose()
		local confirmation = WG.Chobby.ConfirmationPopup(FinalApplyFunc, "Keep these settings?", nil, 315, 170, i18n("yes"), i18n("no"), FinalApplyFailureFunc, true, 5)
	end

	local function CancelFunc()
		RetreatToSafety(false)
		manualWindow:Dispose()
	end

	local btnApply = Button:New {
		x = 5,
		width = 135,
		bottom = 1,
		height = 70,
		caption = i18n("apply"),
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		classname = "action_button",
		OnClick = {
			function()
				ApplyFunc()
			end
		},
		parent = manualWindow,
	}
	local btnClose = Button:New {
		right = 5,
		width = 135,
		bottom = 1,
		height = 70,
		caption = i18n("cancel"),
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		classname = "negative_button",
		OnClick = {
			function()
				CancelFunc()
			end
		},
		parent = manualWindow,
	}

	local popupHolder = WG.Chobby.PriorityPopup(manualWindow, CancelFunc, ApplyFunc)
	--screen0:FocusControl(ebPassword)
end

local function ShowManualFullscreenEntryWindow(name)
	local Configuration = WG.Chobby.Configuration

	local manualWindow = Window:New {
		x = 700,
		y = 300,
		width = 316,
		height = 254,
		caption = "",
		resizable = false,
		draggable = false,
		parent = WG.Chobby.lobbyInterfaceHolder,
		classname = "main_window",
	}

	local lblTitle = Label:New {
		x = 35,
		right = 15,
		y = 15,
		height = 35,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		caption = i18n("set_resolution"),
		parent = manualWindow,
	}

	local screenX, screenY = Spring.GetScreenGeometry()
	local resolution = WG.Chobby.Configuration.manualFullscreen[name] or {}

	local widthBox = GetValueEntryBox(manualWindow, "Width", 60, resolution.width or screenX)
	local heightBox = GetValueEntryBox(manualWindow, "Height", 100, resolution.height or screenY)

	local function RetreatToSafety(force)
		resolution.width = screenX
		resolution.height = screenY
		if force or ((name == "lobby") == (Spring.GetGameName() == "")) then
			SetLobbyFullscreenMode(5)
		end
	end

	local function FinalApplyFunc()
		local lobbySetting = (name == "lobby")
		if lobbySetting then
			if not inLobby then
				SetLobbyFullscreenMode(battleStartDisplay)
			end
		else
			if inLobby then
				SetLobbyFullscreenMode(lobbyFullscreen)
			end
		end
	end

	local function FinalApplyFailureFunc()
		RetreatToSafety(true)
	end

	local function ApplyFunc()
		resolution.width = widthBox()
		resolution.height = heightBox()

		SetLobbyFullscreenMode(5, resolution)

		manualWindow:Dispose()
		local confirmation = WG.Chobby.ConfirmationPopup(FinalApplyFunc, "Keep these settings?", nil, 315, 170, i18n("yes"), i18n("no"), FinalApplyFailureFunc, true, 5)
	end

	local function CancelFunc()
		RetreatToSafety(false)
		manualWindow:Dispose()
	end

	local btnApply = Button:New {
		x = 5,
		width = 135,
		bottom = 1,
		height = 70,
		caption = i18n("apply"),
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		classname = "action_button",
		OnClick = {
			function()
				ApplyFunc()
			end
		},
		parent = manualWindow,
	}
	local btnClose = Button:New {
		right = 5,
		width = 135,
		bottom = 1,
		height = 70,
		caption = i18n("cancel"),
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		classname = "negative_button",
		OnClick = {
			function()
				CancelFunc()
			end
		},
		parent = manualWindow,
	}

	local popupHolder = WG.Chobby.PriorityPopup(manualWindow, CancelFunc, ApplyFunc)
	--screen0:FocusControl(ebPassword)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Lobby Settings

local function AddCheckboxSetting(offset, caption, key, default, clickFunc, tooltip)
	local Configuration = WG.Chobby.Configuration

	local checked = Configuration[key]
	if checked == nil then
		checked = default
	end

	local control = Checkbox:New {
		x = 20,
		width = CHECK_WIDTH,
		y = offset,
		height = 30,
		boxalign = "right",
		boxsize = 20,
		caption = caption,
		checked = checked,
		tooltip = tooltip,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		OnClick = {function (obj)
			Configuration:SetConfigValue(key, obj.checked)
			if clickFunc then
				clickFunc(obj.checked)
			end
		end},
	}

	return control, offset + ITEM_OFFSET
end

local function AddNumberSetting(offset, caption, desc, key, default, minVal, maxVal, isPercent)
	local Configuration = WG.Chobby.Configuration

	local label = Label:New {
		x = 20,
		y = offset + TEXT_OFFSET,
		width = 350,
		height = 30,
		valign = "top",
		align = "left",
		caption = caption,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		tooltip = desc,
	}

	local function SetEditboxValue(obj, newValue)
		newValue = string.gsub(newValue, "%%", "")
		newValue = tonumber(newValue)

		if not newValue then
			obj:SetText(ToPercent(Configuration[key]*100))
			return
		end

		local newValue = math.max(minVal, math.min(maxVal, math.floor(0.5 + newValue)))
		obj:SetText(newValue .. "%")

		Configuration:SetConfigValue(key, newValue/100)
	end

	local freezeSettings = true
	local numberInput = EditBox:New {
		x = COMBO_X,
		y = offset,
		width = COMBO_WIDTH,
		height = 30,
		text = ToPercent(default*100),
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		objectOverrideHintFont = WG.Chobby.Configuration:GetFont(2),
		OnFocusUpdate = {
			function (obj)
				if obj.focused or freezeSettings then
					return
				end
				SetEditboxValue(obj, obj.text)
			end
		}
	}
	freezeSettings = false

	return label, numberInput, offset + ITEM_OFFSET
end

local function GetLobbyTabControls()
	local freezeSettings = true

	local Configuration = WG.Chobby.Configuration

	local offset = 5

	local children = {}

	children[#children + 1] = Label:New {
		x = 20,
		y = offset + TEXT_OFFSET,
		width = 90,
		height = 40,
		valign = "top",
		align = "left",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		caption = "Split Panel Mode",
	}
	children[#children + 1] = ComboBox:New {
		x = COMBO_X,
		y = offset,
		width = COMBO_WIDTH,
		right = 18,
		height = 30,
		items = {"Autodetect", "Always Two", "Always One"},
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		selected = Configuration.panel_layout or 3,
		OnSelect = {
			function (obj)
				if freezeSettings then
					return
				end
				Configuration:SetConfigValue("panel_layout", obj.selected)
			end
		},
	}
	offset = offset + ITEM_OFFSET

	--children[#children + 1], children[#children + 2], offset = AddNumberSetting(offset, "Lobby Interface Scale", "Increase or decrease interface size, for accessibility and 4k screens.",
	--	"uiScale", Configuration.uiScale, Configuration.minUiScale*100, Configuration.maxUiScale*100, true)

	children[#children + 1] = Label:New {
		x = 20,
		y = offset + TEXT_OFFSET,
		width = 90,
		height = 40,
		valign = "top",
		align = "left",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		caption = "Chat Font Size",
	}
	children[#children + 1] = Trackbar:New {
		x = COMBO_X,
		y = offset,
		width  = COMBO_WIDTH,
		height = 30,
		right = 18,
		value  = Configuration.chatFontSize or 18,
		min    = 12,
		max    = 20,
		step   = 1,
		OnChange = {
			function(obj, value)
				if freezeSettings then
					return
				end
				Configuration:SetConfigValue("chatFontSize", value)
			end
		}
	}
	offset = offset + ITEM_OFFSET

	children[#children + 1] = Label:New {
		x = 20,
		y = offset + TEXT_OFFSET,
		width = 90,
		height = 40,
		valign = "top",
		align = "left",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		caption = "Menu Music Volume",
	}
	children[#children + 1] = Trackbar:New {
		x = COMBO_X,
		y = offset,
		width  = COMBO_WIDTH,
		height = 30,
		right = 18,
		value  = Configuration.menuMusicVolume or 0.3,
		min    = 0,
		max    = 1,
		step   = 0.02,
		OnChange = {
			function(obj, value)
				if freezeSettings then
					return
				end
				Configuration:SetConfigValue("menuMusicVolume", value)
			end
		}
	}
	offset = offset + ITEM_OFFSET

	children[#children + 1] = Label:New {
		x = 20,
		y = offset + TEXT_OFFSET,
		width = 90,
		height = 40,
		valign = "top",
		align = "left",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		caption = "Notification Volume",
	}
	children[#children + 1] = Trackbar:New {
		x = COMBO_X,
		y = offset,
		width  = COMBO_WIDTH,
		height = 30,
		right = 18,
		value  = Configuration.menuNotificationVolume or 0.5,
		min    = 0,
		max    = 1,
		step   = 0.02,
		OnChange = {
			function(obj, value)
				if freezeSettings then
					return
				end
				Configuration:SetConfigValue("menuNotificationVolume", value)
			end
		},
		OnMouseUp = {
			function(obj, value)
				if freezeSettings then
					return
				end
				Spring.PlaySoundFile("sounds/Alarm_light5_mixdown.wav", WG.Chobby.Configuration.menuNotificationVolume or 1) -- RING SOUND
			end
		}

	}
	offset = offset + ITEM_OFFSET

	children[#children + 1] = Label:New {
		x = 20,
		y = offset + TEXT_OFFSET,
		width = 90,
		height = 40,
		valign = "top",
		align = "left",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		caption = "Background Brightness",
	}
	children[#children + 1] = Trackbar:New {
		x = COMBO_X,
		y = offset,
		width  = COMBO_WIDTH,
		height = 30,
		right = 18,
		value  = Configuration.menuBackgroundBrightness or 1,
		min    = 0,
		max    = 1,
		step   = 0.02,
		OnChange = {
			function(obj, value)
				if freezeSettings then
					return
				end
				Configuration:SetConfigValue("menuBackgroundBrightness", value)
			end
		}
	}
	offset = offset + ITEM_OFFSET

	children[#children + 1] = Label:New {
		x = 20,
		y = offset + TEXT_OFFSET,
		width = 90,
		height = 40,
		valign = "top",
		align = "left",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		caption = "Game Overlay Opacity",
	}
	children[#children + 1] = Trackbar:New {
		x = COMBO_X,
		y = offset,
		width  = COMBO_WIDTH,
		height = 30,
		right = 18,
		value  = Configuration.gameOverlayOpacity or 0.5,
		min    = 0,
		max    = 1,
		step   = 0.02,
		OnChange = {
			function(obj, value)
				if freezeSettings then
					return
				end
				Configuration:SetConfigValue("gameOverlayOpacity", value)
			end
		}
	}
	offset = offset + ITEM_OFFSET

	children[#children + 1] = Label:New {
		x = 20,
		y = offset + TEXT_OFFSET,
		width = 90,
		height = 40,
		valign = "top",
		align = "left",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		caption = "User Interface Scale",
	}
	local uiScaleTrackbar = Trackbar:New {
		x = COMBO_X,
		y = offset,
		width  = COMBO_WIDTH,
		height = 30,
		right = 18,
		value  = Configuration.uiScale * 100.0,
		min    = math.ceil(Configuration.minUiScale * 100.0),
		max    = math.floor(Configuration.maxUiScale * 100.0),
		step   = 1,
		OnMouseUp = {
			function(obj)
				if freezeSettings then
					return
				end

				Configuration:SetUiScale(obj.value / 100.0)
			end
		},
		OnChange = {
			function(obj, value)

			end
		}
	}
	children[#children + 1] = uiScaleTrackbar
	offset = offset + ITEM_OFFSET

	Configuration:AddListener("OnUiScaleChange", function(_, newScale)
		uiScaleTrackbar:SetValue(newScale * 100.0)
	end)
	Configuration:AddListener("OnUiScaleMaxMinChange", function(_, newMin, newMax)
		uiScaleTrackbar:SetMinMax(newMin * 100.0, newMax * 100.0)
	end)

	children[#children + 1], offset = AddCheckboxSetting(offset, i18n("showTestingEngines"), "displayBadEngines2", false, nil, i18n("showTestingEnginestooltip"))
	children[#children + 1], offset = AddCheckboxSetting(offset, i18n("autoLaunchAsSpectator"), "autoLaunchAsSpectator", true)

	children[#children + 1] = Label:New {
		x = 20,
		y = offset + TEXT_OFFSET,
		width = 90,
		height = 40,
		valign = "top",
		align = "left",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		caption = i18n("useLastGameSpectatorState"),
	}
	children[#children + 1] = ComboBox:New {
		x = COMBO_X,
		y = offset,
		width = COMBO_WIDTH,
		right = 18,
		height = 30,
		items = {"Remember Last", "Always Spectator", "Always Player"},
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		selected = Configuration.useLastGameSpectatorState or 1,
		OnSelect = {
			function (obj)
				if freezeSettings then
					return
				end
				Configuration:SetConfigValue("useLastGameSpectatorState", obj.selected)
				if obj.selected ~= 1 then
					Configuration:SetConfigValue("lastGameSpectatorState", obj.selected == 2 and true or false)
				end
			end
		},
		tooltip = i18n("useLastGameSpectatorStateTooltip"),
	}
	offset = offset + ITEM_OFFSET

	children[#children + 1], offset = AddCheckboxSetting(offset, i18n("showCountry"), "showCountry", true, nil, i18n("showCountrytooltip"))
	children[#children + 1], offset = AddCheckboxSetting(offset, i18n("showRank"), "showRank", true, nil, i18n("showRanktooltip"))
	children[#children + 1] = Label:New {
		x = 20,
		y = offset + TEXT_OFFSET,
		width = 90,
		height = 40,
		valign = "top",
		align = "left",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		caption = i18n("showSkill"),
	}
	local showSkillOptions = {"No", "Yes", "Detailed"}
	local selectedShowSkillOption = 1
	for k,v in ipairs(showSkillOptions) do
		if v == Configuration.showSkillOpt then
			selectedShowSkillOption = k
		end
	end

	children[#children + 1] = ComboBox:New {
		x = COMBO_X,
		y = offset,
		width = COMBO_WIDTH,
		right = 18,
		height = 30,
		items = {"No", "Yes", "Detailed"},
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		selected = Configuration.showSkillOpt or 1,
		OnSelect = {
			function (obj)
				if freezeSettings then
					return
				end
				Configuration:SetConfigValue("showSkillOpt", obj.selected)
			end
		},
		tooltip = i18n("showSkillOpttooltip"),
	}
	offset = offset + ITEM_OFFSET

	local randomSkirmishOption = Spring.GetConfigInt("randomSkirmishSetup", 1)
	if randomSkirmishOption == 1 then
		Configuration.randomSkirmishSetup = true
	else
		Configuration.randomSkirmishSetup = false
	end
	local randomSkirmishSetup = Checkbox:New {
		x = 20,
		width = CHECK_WIDTH,
		y = offset,
		height = 30,
		boxalign = "right",
		boxsize = 20,
		caption = i18n("randomSkirmishSetup"),
		checked = Configuration.randomSkirmishSetup or false,
		tooltip = i18n("randomSkirmishSetup_tooltip"),
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		OnChange = {function (obj, newState)
			Configuration:SetConfigValue("randomSkirmishSetup", newState)
		end},
	}
	children[#children + 1] = randomSkirmishSetup
	offset = offset + ITEM_OFFSET

	local autoLogin = Checkbox:New {
		x = 20,
		width = CHECK_WIDTH,
		y = offset,
		height = 30,
		boxalign = "right",
		boxsize = 20,
		caption = i18n("autoLogin"),
		checked = Configuration.autoLogin or false,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		OnChange = {function (obj, newState)
			freezeSettings = true
			Configuration:SetConfigValue("autoLogin", newState)
			freezeSettings = false
		end},
	}
	children[#children + 1] = autoLogin
	offset = offset + ITEM_OFFSET

	local rememberPassword = Checkbox:New {
		x = 20,
		width = CHECK_WIDTH,
		y = offset,
		height = 30,
		boxalign = "right",
		boxsize = 20,
		caption = i18n("rememberPassword"),
		checked = Configuration.rememberPassword or false,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		OnChange = {function (obj, newState)
			freezeSettings = true
			Configuration:SetConfigValue("rememberPassword", newState)
			freezeSettings = false
		end},
	}
	children[#children + 1] = rememberPassword
	offset = offset + ITEM_OFFSET

	local cbQueueExitConfirmPromptDoNotAskAgain
	cbQueueExitConfirmPromptDoNotAskAgain, offset = AddCheckboxSetting(offset, i18n("queueExitConfirmPromptDoNotAskAgain"), "queueExitConfirmPromptDoNotAskAgain", true, nil , i18n("queueExitConfirmPromptDoNotAskAgain_tooltip"))
	children[#children + 1] = cbQueueExitConfirmPromptDoNotAskAgain

	children[#children + 1] = Label:New {
		x = 20,
		y = offset + TEXT_OFFSET,
		width = 90,
		height = 40,
		valign = "top",
		align = "left",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		caption = "Error log uploading",
		tooltip = "Prompt will ask you each time an error is detected if you want to upload the infolog.",
	}

	local uploadLogPromptItems = {"Prompt", "Always Yes", "Always No"}
	local selectedUploadLogPrompt = 1
	for k,v in ipairs(uploadLogPromptItems) do
		if v == Configuration.uploadLogPrompt then
			selectedUploadLogPrompt = k
		end
	end

	children[#children + 1] = ComboBox:New {
		x = COMBO_X,
		y = offset,
		width = COMBO_WIDTH,
		right = 18,
		height = 30,
		items = uploadLogPromptItems,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		selected = selectedUploadLogPrompt or 1,
		tooltip = "Prompt will ask you each time an error is detected if you want to upload the infolog.",
		OnSelect = {
			function (obj)
				if freezeSettings then
					return
				end
				Configuration:SetConfigValue("uploadLogPrompt", obj.items[obj.selected])
			end
		},
	}

	offset = offset + ITEM_OFFSET

	if not Configuration.gameConfig.disableSteam then
		children[#children + 1], offset = AddCheckboxSetting(offset, i18n("login_with_steam"), "wantAuthenticateWithSteam", true, nil)
		children[#children + 1], offset = AddCheckboxSetting(offset, i18n("use_steam_browser"), "useSteamBrowser", true)
	end
	--children[#children + 1], offset = AddCheckboxSetting(offset, "Multiplayer in new window", "multiplayerLaunchNewSpring", true)
	children[#children + 1], offset = AddCheckboxSetting(offset, i18n("ingame_notifcations"), "ingameNotifcations", true, nil , i18n("ingame_notifcations_tooltip"))
	children[#children + 1], offset = AddCheckboxSetting(offset, i18n("non_friend_notifications"), "nonFriendNotifications", true, nil,  i18n("non_friend_notifications_tooltip"))
	children[#children + 1], offset = AddCheckboxSetting(offset, "Do Not Disturb", "doNotDisturb", false, nil, "Disables the Chat switching channels when receiving a message")
	--children[#children + 1], offset = AddCheckboxSetting(offset, i18n("notifyForAllChat"), "notifyForAllChat", false)
	--children[#children + 1], offset = AddCheckboxSetting(offset, i18n("only_featured_maps"), "onlyShowFeaturedMaps", true)
	children[#children + 1], offset = AddCheckboxSetting(offset, i18n("simplifiedSkirmishSetup"), "simplifiedSkirmishSetup", true, nil, i18n("simplifiedSkirmishSetup_tooltip"))
	children[#children + 1], offset = AddCheckboxSetting(offset, i18n("animate_lobby"), "animate_lobby", true, nil, i18n("animate_lobby_tooltip"))
	children[#children + 1], offset = AddCheckboxSetting(offset, i18n("drawFullSpeed"), "drawAtFullSpeed", false, nil, i18n("drawFullSpeed_tooltip"))
	children[#children + 1], offset = AddCheckboxSetting(offset, i18n("fixFlicker"), "fixFlicker", true, nil, i18n("fixFlicker_tooltip"))
	children[#children + 1], offset = AddCheckboxSetting(offset, i18n("displayBots"), "displayBots", false, nil, i18n("displayBots_tooltip") )
	children[#children + 1], offset = AddCheckboxSetting(offset, i18n("filterbattleroom"), "filterbattleroom", true, nil, i18n("filterbattleroom_tooltip"))

	children[#children + 1], offset = AddCheckboxSetting(offset, i18n("flushLogs"), "flushLogs",
		Spring.GetConfigInt("LogFlushLevel") == 0,
		function(newstate) Spring.SetConfigInt("LogFlushLevel", (newstate and 0) or 50) end, i18n("flushLogs_tooltip"))

	local enableCacheRapidPoolFunc = function(newState)
		Spring.Echo("Toggling Rapid Pool Cache to", newState)
		widgetHandler:ToggleWidget("Rapid Pool Cache")
	end

	children[#children + 1], offset = AddCheckboxSetting(offset, "Rapid Pool Cache", "enableCacheRapidPool", true, enableCacheRapidPoolFunc)
	--children[#children + 1], offset = AddCheckboxSetting(offset, i18n("keep_queues"), "rememberQueuesOnStart", false, nil, "Stay in matchmaker queues when a battle is launched.")


	children[#children + 1] = Label:New {
		x = 20,
		y = offset + TEXT_OFFSET,
		width = 110,
		height = 40,
		valign = "top",
		align = "left",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		caption = "Server Address",
		tooltip = "Changing this will log you out of the current server, click 'Login' in the top right to reconnect. Current live server: server4.beyondallreason.info",
	}

	local barservers = {"server4.beyondallreason.info",}
	local defaultServerAddress = WG.Server.address -- = address from chobby_config.json
	if not table.ifind(barservers, defaultServerAddress) then
		table.insert(barservers, defaultServerAddress)
	end
	if WG.Chobby.Configuration.devMode then
		table.insert(barservers, "localhost")
		table.insert(barservers, "server5.beyondallreason.info") -- Integration server
	end

	children[#children + 1] = ComboBox:New {
		--name = data.name .. "_combo",
		x = COMBO_X,
		y = offset,
		width = COMBO_WIDTH,
		height = 30,
		right = 18,
		items = barservers,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		selected = Configuration:GetServerAddress(),
		tooltip = "Changing this will log you out of the current server, click 'Login' in the top right to reconnect. Current live server: server4.beyondallreason.info",
		OnSelect = {
			function (obj, num)
				if freezeSettings then -- so that it doesnt run when started, fucking yay
					return
				end
				local oldserveraddress = Configuration:GetServerAddress()
				local newserveraddress = barservers[num]

				Spring.Echo("Choosing a server in settings:", num, oldserveraddress,newserveraddress)

				if oldserveraddress ~= newserveraddress then
					Configuration.serverAddress = newserveraddress

					if WG.LibLobby.lobby then -- force set the new one so that lobby:safeupdate doesnt fuck up
						--Spring.Echo("FORCE SET",obj,num, barservers[num])
						WG.LibLobby.lobby.host = newserveraddress
						WG.LibLobby.lobby:Disconnect("changed lobby server")
						if WG.LoginWindowHandler then
							WG.LoginWindowHandler.TryLogin()
						end
					end
				end
			end
		}
	}

	offset = offset + ITEM_OFFSET

	children[#children + 1] = Label:New {
		x = 20,
		y = offset + TEXT_OFFSET,
		width = 90,
		height = 40,
		valign = "top",
		align = "left",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		caption = "Clear Channel History",
	}
	children[#children + 1] = Button:New {
		x = COMBO_X,
		y = offset,
		width = COMBO_WIDTH,
		height = 30,
		caption = "Apply",
		classname = "negative_button",
		tooltip = "Clears chat history displayed in the lobby, does not affect the chat history files saved to your computer.",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		OnClick = {
			function (obj)
				WG.Chobby.interfaceRoot.GetChatWindow():ClearHistory()
				WG.BattleRoomWindow.ClearChatHistory()
			end
		}
	}
	offset = offset + ITEM_OFFSET

	children[#children + 1] = Label:New {
		x = 20,
		y = offset + TEXT_OFFSET,
		width = 90,
		height = 40,
		valign = "top",
		align = "left",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		caption = "Delete Path Cache",
	}
	children[#children + 1] = Button:New {
		x = COMBO_X,
		y = offset,
		width = COMBO_WIDTH,
		height = 30,
		caption = "Apply",
		classname = "negative_button",
		tooltip = "Deletes path cache. May solve desync.",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		OnClick = {
			function (obj)
				if WG.CacheHandler then
					WG.CacheHandler.DeletePathCache()
				end
			end
		}
	}
	offset = offset + ITEM_OFFSET

	local function onConfigurationChange(listener, key, value)
		if freezeSettings then
			return
		end
		if key == "autoLogin" then
			autoLogin:SetToggle(value)
		end
		if key == "rememberPassword" then
			rememberPassword:SetToggle(value)
		end
		if key == "randomSkirmishSetup" then
			if value == true then
				Spring.SetConfigInt("randomSkirmishSetup", 1)
			else
				Spring.SetConfigInt("randomSkirmishSetup", 0)
			end
		end
		if key == "simplifiedSkirmishSetup" then
			if value == true then
				Spring.SetConfigInt("simplifiedSkirmishSetup", 1)
			else
				Spring.SetConfigInt("simplifiedSkirmishSetup", 0)
			end
		end

		if key == "queueExitConfirmPromptDoNotAskAgain" and cbQueueExitConfirmPromptDoNotAskAgain.checked ~= value then
			cbQueueExitConfirmPromptDoNotAskAgain.checked = value
			cbQueueExitConfirmPromptDoNotAskAgain.state.checked = cbQueueExitConfirmPromptDoNotAskAgain.checked
			cbQueueExitConfirmPromptDoNotAskAgain:Invalidate()
		end
	end

	freezeSettings = false

	Configuration:AddListener("OnConfigurationChange", onConfigurationChange)

	return children
end

local function GetVoidTabControls()
	local freezeSettings = true

	local Configuration = WG.Chobby.Configuration

	local offset = 5

	local children = {}

	children[#children + 1] = TextBox:New {
		x = 20,
		y = offset + TEXT_OFFSET,
		right = 10,
		height = 40,
		valign = "top",
		align = "left",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		objectOverrideHintFont = WG.Chobby.Configuration:GetFont(3),
		text = "Warning: These settings are experimental and not officially supported, proceed at your own risk.",
	}
	offset = offset + 65

	local function EnableProfilerFunc(newState)
		if newState then
			WG.WidgetProfiler.Enable()
		else
			WG.WidgetProfiler.Disable()
		end
	end

	local function EnableInspectorFunc(newState)
		if newState then
			widgetHandler:EnableWidget("ChiliInspector")
		else
			widgetHandler:DisableWidget("ChiliInspector")
		end

	end


	local function toggleCampaignFunc(newState)
		Spring.Echo("Enabling Campaign", newState)
		WG.Chobby.Configuration.showCampaignButton = newState
	end

	children[#children + 1] = Label:New {
		x = 20,
		y = offset + TEXT_OFFSET,
		width = 90,
		height = 30,
		valign = "top",
		align = "left",
		parent = window,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		caption = "Singleplayer",
	}

	local singleplayerSelectedName = Configuration.gameConfigName
	local singleplayerSelected = 1
	for i = 1, #Configuration.gameConfigOptions do
		if Configuration.gameConfigOptions[i] == singleplayerSelectedName then
			singleplayerSelected = i
			break
		end
	end

	children[#children + 1] = ComboBox:New {
		name = "gameSelection",
		x = COMBO_X,
		y = offset,
		width = COMBO_WIDTH,
		height = 30,
		right = 18,
		parent = window,
		items = Configuration.gameConfigHumanNames,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		selected = singleplayerSelected,
		OnSelect = {
			function (obj)
				if freezeSettings then
					return
				end
				Configuration:SetConfigValue("gameConfigName", Configuration.gameConfigOptions[obj.selected])
			end
		},
	}
	offset = offset + ITEM_OFFSET

	children[#children + 1] = Label:New {
		x = 20,
		y = offset + TEXT_OFFSET,
		width = 90,
		height = 40,
		valign = "top",
		align = "left",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		caption = "Reload Modoptions",
	}
	children[#children + 1] = Button:New {
		x = COMBO_X,
		y = offset,
		width = COMBO_WIDTH,
		height = 30,
		right = 18,
		caption = "🔁 Reload",
		classname = "option_button",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		tooltip = "Reload modoptions from game archive and show the panel. Uses the game selected in Singleplayer above.",
		OnClick = {
			function()
				if WG.ModoptionsPanel then
					local gameName = Configuration.gameConfigName
					local lobby = WG.LibLobby and WG.LibLobby.localLobby
					if gameName and lobby then
						WG.ModoptionsPanel.LoadModoptions(gameName, lobby, true)
						WG.ModoptionsPanel.ShowModoptions()
					end
				end
			end
		}
	}
	offset = offset + ITEM_OFFSET

	children[#children + 1] = Label:New {
		x = 20,
		y = offset + TEXT_OFFSET,
		width = 90,
		height = 40,
		valign = "top",
		align = "left",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		caption = "Start position type",
		tooltip = "Default start position type for singleplayer skirmish.",
	}
	local startPosTypeOptions = {"Fixed", "Random", "Choose In Game", "Choose Before Game"}
	local startPosTypeSelected = (Configuration.singleplayerStartPosType ~= nil and Configuration.singleplayerStartPosType + 1) or 3
	children[#children + 1] = ComboBox:New {
		x = COMBO_X,
		y = offset,
		width = COMBO_WIDTH,
		height = 30,
		right = 18,
		items = startPosTypeOptions,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		selected = startPosTypeSelected,
		OnSelect = {
			function(obj)
				if freezeSettings then
					return
				end
				local idx = obj.selected
				if idx and idx >= 1 and idx <= 4 then
					Configuration:SetConfigValue("singleplayerStartPosType", idx - 1)
				end
			end
		},
	}
	offset = offset + ITEM_OFFSET

	children[#children + 1], offset = AddCheckboxSetting(offset, i18n("debugMode"), "debugMode", false)
	children[#children + 1], offset = AddCheckboxSetting(offset, i18n("ShowhiddenModopions"), "ShowhiddenModopions", false, WG.ModoptionsPanel.RefreshModoptions, i18n("ShowhiddenTooltip"))
	children[#children + 1], offset = AddCheckboxSetting(offset, "Debug Auto Win", "debugAutoWin", false)
	children[#children + 1], offset = AddCheckboxSetting(offset, "Enable Profiler", "enableProfiler", false, EnableProfilerFunc)
	local cbInspector
	cbInspector, offset = AddCheckboxSetting(offset, "Enable Inspector", "enableInspector", false, EnableInspectorFunc)
	children[#children + 1] = cbInspector
	-- children[#children + 1], offset = AddCheckboxSetting(offset, "Show Campaign button", "showCampaignButton", false, toggleCampaignFunc)
	-- children[#children + 1], offset = AddCheckboxSetting(offset, "Show Planet Unlocks", "showPlanetUnlocks", false)
	-- children[#children + 1], offset = AddCheckboxSetting(offset, "Show Planet Enemy Units", "showPlanetEnemyUnits", false)
	-- children[#children + 1], offset = AddCheckboxSetting(offset, "Campaign Spawn Debug", "campaignSpawnDebug", false)
	-- children[#children + 1], offset = AddCheckboxSetting(offset, "Edit Campaign", "editCampaign", false)
	children[#children + 1], offset = AddCheckboxSetting(offset, "Debug server messages", "activeDebugConsole", false)
	children[#children + 1], offset = AddCheckboxSetting(offset, "Show channel bots", "displayBots", false)
	-- children[#children + 1], offset = AddCheckboxSetting(offset, "Show wrong engines", "displayBadEngines2", false) -- moved to regular
	-- children[#children + 1], offset = AddCheckboxSetting(offset, "Debug for MatchMaker", "showMatchMakerBattles", false)
	children[#children + 1], offset = AddCheckboxSetting(offset, "Hide interface", "hideInterface", false)
	--children[#children + 1], offset = AddCheckboxSetting(offset, "Neuter Settings", "doNotSetAnySpringSettings", false)
	children[#children + 1], offset = AddCheckboxSetting(offset, "Aggressive Set Borderless", "agressivelySetBorderlessWindowed", false)
	children[#children + 1], offset = AddCheckboxSetting(offset, "Use wrong engine", "useWrongEngine", false)

	children[#children + 1], offset = AddCheckboxSetting(offset, i18n("simple_ai_list"), "simpleAiList", true, nil,  i18n("simple_ai_list_tooltip")) -- should be default on, no need for configuration?

	children[#children + 1], offset = AddCheckboxSetting(offset, "Show old AI versions", "showOldAiVersions", false)
	children[#children + 1], offset = AddCheckboxSetting(offset, "Show AIOptions", "showAiOptions", true)
	if Configuration.gameConfig.filterEmptyRegionalAutohosts then
		children[#children + 1], offset = AddCheckboxSetting(offset, "Filter redundant battles", "battleFilterRedundant", true, nil, "Hides redundant empty regional autohosts.")
	end

	children[#children + 1] = Label:New {
		x = 20,
		y = offset + TEXT_OFFSET,
		width = 90,
		height = 40,
		valign = "top",
		align = "left",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		caption = "Disable Lobby",
	}
	children[#children + 1] = Button:New {
		x = COMBO_X,
		y = offset,
		width = COMBO_WIDTH,
		height = 30,
		right = 18,
		caption = "Disable",
		classname = "negative_button",
		tooltip = "Disables the entire lobby and menu.",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		OnClick = {
			function (obj)
				WG.Chobby.ConfirmationPopup(DisableAllWidgets, "This will break everything. Are you sure?", nil, 315, 170, i18n("yes"), i18n("cancel"))
			end
		}
	}
	offset = offset + ITEM_OFFSET


	children[#children + 1] = Label:New {
		x = 20,
		y = offset + TEXT_OFFSET,
		width = 90,
		height = 40,
		valign = "top",
		align = "left",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		caption = "Server Address",
	}
	children[#children + 1] = EditBox:New {
		x = COMBO_X,
		y = offset,
		width = COMBO_WIDTH,
		height = 30,
		right = 18,
		text = Configuration:GetServerAddress(),
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		objectOverrideHintFont = WG.Chobby.Configuration:GetFont(2),
		tooltip = "Requires a lobby restart for changes to take effect. Current live server: server4.beyondallreason.info",
		OnFocusUpdate = {
			function (obj)
				if obj.focused then
					return
				end
				Configuration.serverAddress = obj.text
				obj:SetText(Configuration:GetServerAddress())
			end
		}
	}
	offset = offset + ITEM_OFFSET

	children[#children + 1] = Label:New {
		x = 20,
		y = offset + TEXT_OFFSET,
		width = 90,
		height = 40,
		valign = "top",
		align = "left",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		caption = "Server Port",
	}
	children[#children + 1] = EditBox:New {
		x = COMBO_X,
		y = offset,
		width = COMBO_WIDTH,
		height = 30,
		right = 18,
		text = tostring(Configuration.serverPort),
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		objectOverrideHintFont = WG.Chobby.Configuration:GetFont(2),
		OnFocusUpdate = {
			function (obj)
				if obj.focused then
					return
				end

				local newValue = tonumber(obj.text)

				if not newValue then
					obj:SetText(tostring(Configuration.serverPort))
					return
				end

				Configuration.serverPort = math.floor(0.5 + math.max(0, newValue))
				obj:SetText(tostring(Configuration.serverPort))
			end
		}
	}
	offset = offset + ITEM_OFFSET


	--children[#children + 1] = Label:New {
	--	x = 20,
	--	y = offset + TEXT_OFFSET,
	--	width = 90,
	--	height = 30,
	--	valign = "top",
	--	align = "left",
	--	parent = window,
	--	objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
	--	caption = "Campaign",
	--}
--
	--local campaignSelectedName = Configuration.campaignConfigName
	--local campaignSelected = 1
	--for i = 1, #Configuration.campaignConfigOptions do
	--	if Configuration.campaignConfigOptions[i] == campaignSelectedName then
	--		campaignSelected = i
	--		break
	--	end
	--end
--
	--children[#children + 1] = ComboBox:New {
	--	name = "campaignSelection",
	--	x = COMBO_X,
	--	y = offset,
	--	width = COMBO_WIDTH,
	--	height = 30,
	--	right = 18,
	--	parent = window,
	--	items = Configuration.campaignConfigHumanNames,
	--	objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
	--	selected = campaignSelected,
	--	OnSelect = {
	--		function (obj)
	--			if freezeSettings then
	--				return
	--			end
	--			Configuration:SetConfigValue("campaignConfigName", Configuration.campaignConfigOptions[obj.selected])
	--		end
	--	},
	--}
	--offset = offset + ITEM_OFFSET

	children[#children + 1] = Label:New {
		x = 20,
		y = offset + TEXT_OFFSET,
		width = 90,
		height = 40,
		valign = "top",
		align = "left",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		caption = "Coop Connection Delay",
		tooltip = "Hosts with poor internet may require their clients to add a delay in order to connect. This is not used by BAR",
	}
	children[#children + 1] = Trackbar:New {
		x = COMBO_X,
		y = offset,
		width  = COMBO_WIDTH,
		height = 30,
		right = 18,
		value  = Configuration.coopConnectDelay or 0,
		min    = 0,
		max    = 100,
		step   = 1,
		OnChange = {
			function(obj, value)
				if freezeSettings then
					return
				end
				Configuration:SetConfigValue("coopConnectDelay", value)
			end
		}
	}
	offset = offset + ITEM_OFFSET

	local function onConfigurationChange(listener, key, value)
		if freezeSettings then
			return
		end
		if key == "enableInspector" and cbInspector.checked ~= value then
			cbInspector.checked = value
			cbInspector.state.checked = cbInspector.checked
			cbInspector:Invalidate()
		end
	end

	freezeSettings = false

	Configuration:AddListener("OnConfigurationChange", onConfigurationChange)

	return children
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Game Settings

local settingsComboBoxes = {}
local settingsUpdateFunction = {}

local function MakePresetsControl(settingPresets, offset)
	local Configuration = WG.Chobby.Configuration

	local presetLabel = Label:New {
		name = "presetLabel",
		x = 20,
		y = offset + TEXT_OFFSET,
		width = 90,
		height = 40,
		valign = "top",
		align = "left",
		parent = window,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		caption = "Preset:",
	}

	local useCustomSettings = true
	local settingsPresetControls = {}

	local function SettingsButton(x, y, caption, settings)
		local button = Button:New {
			name = caption,
			x = 80*x,
			y = ITEM_OFFSET*y,
			width = 75,
			height = 30,
			caption = caption,
			objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
			customSettings = not settings,
			OnClick = {
				function (obj)
					if settings then
						for key, value in pairs(settings) do
							local comboBox = settingsComboBoxes[key]
							if comboBox then
								comboBox:Select(value)
							end
							local updateFunction = settingsUpdateFunction[key]
							if updateFunction then
								updateFunction(value)
							end
						end
					end

					ButtonUtilities.SetButtonSelected(obj)
					for i = 1, #settingsPresetControls do
						local control = settingsPresetControls[i]
						if control.name ~= obj.name then
							ButtonUtilities.SetButtonDeselected(control)
						end
					end
				end
			},
		}

		settingsPresetControls[#settingsPresetControls + 1] = button
		if settings then
			if Spring.Utilities.TableSubsetEquals(settings, Configuration.settingsMenuValues) then
				useCustomSettings = false
				ButtonUtilities.SetButtonSelected(button)
			end
		elseif useCustomSettings then
			ButtonUtilities.SetButtonSelected(button)
		end
		return button
	end

	local x = 0
	local y = 0
	local settingsButtons = {}
	for i = 1, #settingPresets do
		settingsButtons[#settingsButtons + 1] = SettingsButton(x, y, settingPresets[i].name, settingPresets[i].settings)
		x = x + 1
		if x > 2 then
			x = 0
			y = y + 1
		end
	end

	local customSettingsButton = SettingsButton(x, y, "Custom")
	settingsButtons[#settingsButtons + 1] = customSettingsButton

	local settingsHolder = Control:New {
		name = "settingsHolder",
		x = COMBO_X,
		y = offset,
		width = COMBO_WIDTH,
		height = ITEM_OFFSET*(y + 1),
		padding = {0, 0, 0, 0},
		children = settingsButtons
	}

	local function EnableCustomSettings()
		ButtonUtilities.SetButtonSelected(customSettingsButton)
		for i = 1, #settingsPresetControls do
			local control = settingsPresetControls[i]
			if not control.customSettings then
				ButtonUtilities.SetButtonDeselected(control)
			end
		end
	end

	return presetLabel, settingsHolder, EnableCustomSettings, offset + ITEM_OFFSET*(y + 1)
end

local function ProcessScreenSizeOption(data, offset)
	local Configuration = WG.Chobby.Configuration

	local freezeSettings = true

	local label = Label:New {
		name = data.name .. "_label",
		x = 20,
		y = offset + TEXT_OFFSET,
		width = 350,
		height = 30,
		valign = "top",
		align = "left",
		caption = data.humanName,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		tooltip = data.desc,
	}

	local selectedOption
	if data.lobbyDisplayModeToggle then
		selectedOption = Configuration.lobby_fullscreen or 1
	else
		selectedOption = Configuration.game_fullscreen or 1
	end

	local items = {"Borderless Window", "Windowed", "Fullscreen", "Configurable Borderless", "Configurable Fullscreen", "Configurable Windowed"}

    local list = ComboBox:New {
		name = data.name .. "_combo",
		x = COMBO_X,
		y = offset,
		width = COMBO_WIDTH,
		height = 30,
		right = 18,
		items = items,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		selected = selectedOption,
		OnSelect = {
			function (obj)
				if freezeSettings then
					return
				end
				if data.lobbyDisplayModeToggle then
					if obj.selected == 4 then
						ShowWindowGeoConfig("lobby", 4, "manualBorderless", 0)
					elseif obj.selected == 5 then
						ShowManualFullscreenEntryWindow("lobby")
					elseif obj.selected == 6 then
						ShowWindowGeoConfig("lobby", 6, "manualWindowed", 100)
					elseif Spring.GetGameName() == "" then
						SetLobbyFullscreenMode(obj.selected)
					end

					lobbyFullscreen = obj.selected
					Configuration.lobby_fullscreen = obj.selected
				else
					if obj.selected == 4 then
						ShowWindowGeoConfig("game", 4, "manualBorderless", 0)
					elseif obj.selected == 5 then
						ShowManualFullscreenEntryWindow("game")
					elseif obj.selected == 6 then
						ShowWindowGeoConfig("game", 6, "manualWindowed", 100)
					elseif Spring.GetGameName() ~= "" then
						SetLobbyFullscreenMode(obj.selected)
					end

					battleStartDisplay = obj.selected
					Configuration.game_fullscreen = obj.selected

					if Spring.GetConfigInt('SelectedScreenMode', -1) >= 1 then
						Spring.SetConfigInt('SelectedScreenMode', -1)
					end
				end
			end
		},
	}

	freezeSettings = false

	return label, list, offset + ITEM_OFFSET
end

local function ProcessSettingsOption(data, offset, defaults, customSettingsSwitch)
	local Configuration = WG.Chobby.Configuration

	local label = Label:New {
		name = data.name .. "_label",
		x = 20,
		y = offset + TEXT_OFFSET,
		width = 350,
		height = 30,
		valign = "top",
		align = "left",
		caption = data.humanName,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		tooltip = data.desc,
	}

	local defaultItem = 1
	local defaultName = Configuration.settingsMenuValues[data.name] or ((data.defaultFunction and data.defaultFunction()) or defaults[data.name])

	local items = {}
	for i = 1, #data.options do
		local itemName = data.options[i].name
		items[i] = itemName
		if itemName == defaultName then
			defaultItem = i
		end
	end

	local freezeSettings = true

	settingsComboBoxes[data.name] = ComboBox:New {
		name = data.name .. "_combo",
		x = COMBO_X,
		y = offset,
		width = COMBO_WIDTH,
		height = 30,
		right = 18,
		items = items,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		selected = defaultItem,
		OnSelect = {
			function (obj, num)
				if freezeSettings then
					return freezeSettings
				end
				if customSettingsSwitch then
					customSettingsSwitch()
				end
				Configuration:SetSettingsConfigOption(data.name, data.options[num].name)
			end
		}
	}

	freezeSettings = false

	return label, settingsComboBoxes[data.name], offset + ITEM_OFFSET
end

local function ProcessSettingsNumber(data, offset, defaults, customSettingsSwitch)
	local Configuration = WG.Chobby.Configuration

	local FormatFunc = (data.isPercent and ToPercent) or tostring

	local label = Label:New {
		name = data.name .. "_label",
		x = 20,
		y = offset + TEXT_OFFSET,
		width = 350,
		height = 30,
		valign = "top",
		align = "left",
		caption = data.humanName,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		tooltip = data.desc,
	}

	local function SetEditboxValue(obj, newValue)
		newValue = string.gsub(newValue, "%%", "")
		newValue = tonumber(newValue)

		if not newValue then
			obj:SetText(FormatFunc(Configuration.settingsMenuValues[data.name]))
			return
		end

		if customSettingsSwitch then
			customSettingsSwitch()
		end

		local newValue = math.floor(0.5 + math.max(data.minValue, math.min(data.maxValue, newValue)))
		obj:SetText(FormatFunc(newValue))

		Configuration:SetSettingsConfigOption(data.name, newValue)
	end

	local freezeSettings = true

	local numberInput = EditBox:New {
		x = COMBO_X,
		y = offset,
		width = COMBO_WIDTH,
		height = 30,
		right = 18,
		text = FormatFunc(Configuration.settingsMenuValues[data.name] or defaults[data.name]),
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		objectOverrideHintFont = WG.Chobby.Configuration:GetFont(2),
		OnFocusUpdate = {
			function (obj)
				if obj.focused or freezeSettings then
					return
				end
				SetEditboxValue(obj, obj.text)
			end
		}
	}

	freezeSettings = false

	settingsUpdateFunction[data.name] = function (newValue)
		SetEditboxValue(numberInput, newValue)
	end

	return label, numberInput, offset + ITEM_OFFSET
end

local function PopulateTab(settingPresets, settingOptions, settingsDefault)
	local children = {}
	local offset = 5
	local customSettingsSwitch
	local label, list

	if settingPresets then
		label, list, customSettingsSwitch, offset = MakePresetsControl(settingPresets, offset)
		children[#children + 1] = label
		children[#children + 1] = list
	end

	for i = 1, #settingOptions do
		local data = settingOptions[i]
		if data.displayModeToggle or data.lobbyDisplayModeToggle then
			label, list, offset = ProcessScreenSizeOption(data, offset)
		elseif data.isNumberSetting then
			label, list, offset = ProcessSettingsNumber(data, offset, settingsDefault, customSettingsSwitch)
		else
			label, list, offset = ProcessSettingsOption(data, offset, settingsDefault, customSettingsSwitch)
		end
		children[#children + 1] = label
		children[#children + 1] = list
	end

	return children
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Initialization

local function MakeTab(name, children)
	local contentsPanel = ScrollPanel:New {
		x = 5,
		right = 5,
		y = 10,
		bottom = 8,
		padding = {0,0,0,10},
		horizontalScrollbar = false,
		children = children
	}

	return {
		name = name,
		caption = name,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		children = {contentsPanel}
	}
end

local function InitializeControls(window)
	window.OnParent = nil

	local Configuration = WG.Chobby.Configuration

	local tabs = {
		MakeTab("Lobby", GetLobbyTabControls())
	}

	local settingsFile = WG.Chobby.Configuration.gameConfig.settingsConfig
	local settingsDefault = WG.Chobby.Configuration.gameConfig.settingsDefault

	for i = 1, #settingsFile do
		local data = settingsFile[i]
		tabs[#tabs + 1] = MakeTab(data.name, PopulateTab(data.presets, data.settings, settingsDefault))
	end

	if WG.Chobby.Configuration.devMode then
		tabs[#tabs + 1] = MakeTab("Developer", GetVoidTabControls())
	end

	local tabPanel = Chili.DetachableTabPanel:New {
		x = 5,
		right = 5,
		y = 45,
		bottom = 1,
		padding = {0, 0, 0, 0},
		minTabWidth = 120,
		tabs = tabs,
		parent = window,
		OnTabChange = {
		}
	}

	local tabBarHolder = Control:New {
		name = "tabBarHolder",
		x = 0,
		y = 0,
		right = 0,
		height = 55,
		resizable = false,
		draggable = false,
		padding = {14, 8, 14, 0},
		parent = window,
		children = {
			tabPanel.tabBar
		}
	}

	local externalFunctions = {}

	function externalFunctions.OpenTab(tabName)
		tabPanel.tabBar:Select(tabName)
	end

	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- External Interface

local SettingsWindow = {}

function SettingsWindow.GetControl()

	local window = Control:New {
		name = "settingsWindow",
		x = "0%",
		y = "0%",
		width = "100%",
		height = "100%",
		OnParent = {
			function(obj)
				if obj:IsEmpty() then
					settingsWindowHandler = InitializeControls(obj)
				end
			end
		},
	}
	return window
end

function SettingsWindow.OpenTab(tabName)
	if settingsWindowHandler then
		settingsWindowHandler.OpenTab(tabName)
	end
end

function SettingsWindow.WriteGameSpringsettings(fileName)
	local settingsFile, errorMessage = io.open(fileName, 'w+')
	if not settingsFile then
		return
	end
	local fixedSettingsOverride = WG.Chobby.Configuration.fixedSettingsOverride

	local function WriteToFile(key, value)
		value = (fixedSettingsOverride and fixedSettingsOverride[key]) or value
		settingsFile:write(key .. " = " .. value .. "\n")
	end

	local gameSettings = WG.Chobby.Configuration.game_settings
	local settingsOverride = WG.Chobby.Configuration.fixedSettingsOverride
	for key, value in pairs(gameSettings) do
		WriteToFile(key, (settingsOverride and settingsOverride[key]) or value)
	end

	local screenX, screenY = Spring.GetScreenGeometry()
	if battleStartDisplay == 1 then -- Borderless Window
		WriteToFile("XResolutionWindowed", screenX)
		WriteToFile("YResolutionWindowed", screenY)
		WriteToFile("WindowPosX", 0)
		WriteToFile("WindowPosY", 0)
		WriteToFile("WindowBorderless", 1)
	elseif battleStartDisplay == 2 then -- Window
		WriteToFile("WindowPosX", 0)
		WriteToFile("WindowPosY", 80)
		WriteToFile("XResolutionWindowed", screenX)
		WriteToFile("YResolutionWindowed", screenY - 80)
		WriteToFile("WindowBorderless", 0)
		WriteToFile("Fullscreen", 0)
	elseif battleStartDisplay == 3 then -- Fullscreen
		WriteToFile("XResolution", screenX)
		WriteToFile("YResolution", screenY)
		WriteToFile("WindowBorderless", 0)
		WriteToFile("Fullscreen", 1)
	elseif battleStartDisplay == 4 then -- Manual Borderless
		local borders = WG.Chobby.Configuration.manualBorderless.game or {}
		WriteToFile("XResolutionWindowed", borders.width or screenX)
		WriteToFile("YResolutionWindowed", borders.height or screenY)
		WriteToFile("WindowPosX", borders.x or 0)
		WriteToFile("WindowPosY", borders.y or 0)
		WriteToFile("WindowBorderless", 1)
	elseif battleStartDisplay == 5 then -- Manual Fullscreen
		local resolution = WG.Chobby.Configuration.manualFullscreen.game or {}
		WriteToFile("XResolution", resolution.width or screenX)
		WriteToFile("YResolution", resolution.height or screenY)
		WriteToFile("WindowBorderless", 0)
		WriteToFile("Fullscreen", 1)
	end
end

function SettingsWindow.GetSettingsString()
	local settingsString = nil

	local function WriteSetting(key, value)
		if settingsString then
			settingsString = settingsString .. "\n" .. key .. " = " .. value
		else
			settingsString = key .. " = " .. value
		end
	end

	local gameSettings = WG.Chobby.Configuration.game_settings
	local settingsOverride = WG.Chobby.Configuration.fixedSettingsOverride
	for key, value in pairs(gameSettings) do
		WriteSetting(key, (settingsOverride and settingsOverride[key]) or value)
	end

	local screenX, screenY = Spring.GetScreenGeometry()
	if battleStartDisplay == 1 then -- Borderless Window
		WriteSetting("XResolutionWindowed", screenX)
		WriteSetting("YResolutionWindowed", screenY)
		WriteSetting("WindowPosX", 0)
		WriteSetting("WindowPosY", 0)
		WriteSetting("WindowBorderless", 1)
	elseif battleStartDisplay == 2 then -- Window
		WriteSetting("WindowPosX", 0)
		WriteSetting("WindowPosY", 80)
		WriteSetting("XResolutionWindowed", screenX)
		WriteSetting("YResolutionWindowed", screenY - 80)
		WriteSetting("WindowBorderless", 0)
		WriteSetting("Fullscreen", 0)
	elseif battleStartDisplay == 3 then -- Fullscreen
		WriteSetting("XResolution", screenX)
		WriteSetting("YResolution", screenY)
		WriteSetting("WindowBorderless", 0)
		WriteSetting("Fullscreen", 1)
	elseif battleStartDisplay == 4 then -- Manual Borderless
		local borders = WG.Chobby.Configuration.manualBorderless.game or {}
		WriteSetting("XResolutionWindowed", borders.width or screenX)
		WriteSetting("YResolutionWindowed", borders.height or screenY)
		WriteSetting("WindowPosX", borders.x or 0)
		WriteSetting("WindowPosY", borders.y or 0)
		WriteSetting("WindowBorderless", 1)
	elseif battleStartDisplay == 5 then -- Manual Fullscreen
		local resolution = WG.Chobby.Configuration.manualFullscreen.game or {}
		WriteSetting("XResolution", resolution.width or screenX)
		WriteSetting("YResolution", resolution.height or screenY)
		WriteSetting("WindowBorderless", 0)
		WriteSetting("Fullscreen", 1)
	end

	return settingsString
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

local firstCall = true
function widget:ActivateMenu()
	--if firstCall then
	--	local gameSettings = WG.Chobby.Configuration.game_settings
	--	for key, value in pairs(gameSettings) do
	--		WG.Chobby.Configuration:SetSpringsettingsValue(key, value)
	--	end
	--
	--	firstCall = false
	--	return
	--end
	if not (WG.Chobby and WG.Chobby.Configuration) then
		return
	end
	inLobby = true
	SetLobbyFullscreenMode(WG.Chobby.Configuration.lobby_fullscreen)
end

--local oldWidth, oldHeight, oldX, oldY
--function widget:Update()
--	if not ((currentMode == 2 or not currentMode) and lobbyFullscreen == 2) then
--		return
--	end
--
--	local width, height, x, y = Spring.GetWindowGeometry()
--	if width == oldWidth and height == oldHeight and x == oldX and y == oldY then
--		return
--	end
--	oldWidth, oldHeight, oldX, oldY = width, height, x, y
--	SaveWindowPos(width, height, x, y)
--end

local onBattleAboutToStart

local function DelayedInitialize()
	local Configuration = WG.Chobby.Configuration
	battleStartDisplay = Configuration.game_fullscreen or 1
	lobbyFullscreen = Configuration.lobby_fullscreen or 1
end

function widget:Initialize()
	CHOBBY_DIR = LUA_DIRNAME .. "widgets/chobby/"
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	WG.Delay(DelayedInitialize, 0.1)

	onBattleAboutToStart = function(listener)
		local screenX, screenY = Spring.GetScreenGeometry()

		inLobby = false
		SetLobbyFullscreenMode(battleStartDisplay)
		local Configuration = WG.Chobby.Configuration

		-- Settings which rely on io
		if battleStartDisplay == 1 then -- Borderless Window
			Configuration:SetSpringsettingsValue("XResolutionWindowed", screenX)
			Configuration:SetSpringsettingsValue("YResolutionWindowed", screenY)
			Configuration:SetSpringsettingsValue("WindowPosX", 0)
			Configuration:SetSpringsettingsValue("WindowPosY", 0)
			Configuration:SetSpringsettingsValue("WindowBorderless", 1)
		elseif battleStartDisplay == 2 then -- Window
			Configuration:SetSpringsettingsValue("WindowPosX", 0)
			Configuration:SetSpringsettingsValue("WindowPosY", 80)
			Configuration:SetSpringsettingsValue("XResolutionWindowed", screenX)
			Configuration:SetSpringsettingsValue("YResolutionWindowed", screenY - 80)
			Configuration:SetSpringsettingsValue("WindowBorderless", 0)
			Configuration:SetSpringsettingsValue("WindowBorderless", 0)
			Configuration:SetSpringsettingsValue("Fullscreen", 0)
		elseif battleStartDisplay == 3 then -- Fullscreen
			Configuration:SetSpringsettingsValue("XResolution", screenX)
			Configuration:SetSpringsettingsValue("YResolution", screenY)
			Configuration:SetSpringsettingsValue("WindowPosX", 0)
			Configuration:SetSpringsettingsValue("WindowPosY", 0)
			Configuration:SetSpringsettingsValue("Fullscreen", 1)
		elseif battleStartDisplay == 4 then -- Manual Borderless
			local borders = WG.Chobby.Configuration.manualBorderless.game or {}
			Configuration:SetSpringsettingsValue("XResolutionWindowed", borders.width or screenX)
			Configuration:SetSpringsettingsValue("YResolutionWindowed", borders.height or screenY)
			Configuration:SetSpringsettingsValue("WindowPosX", borders.x or 0)
			Configuration:SetSpringsettingsValue("WindowPosY", borders.y or 0)
			Configuration:SetSpringsettingsValue("WindowBorderless", 1)
		elseif battleStartDisplay == 5 then -- Manual Fullscreen
			local resolution = WG.Chobby.Configuration.manualFullscreen.game or {}
			Configuration:SetSpringsettingsValue("XResolution", resolution.width or screenX)
			Configuration:SetSpringsettingsValue("YResolution", resolution.height or screenY)
			Configuration:SetSpringsettingsValue("WindowPosX", 0)
			Configuration:SetSpringsettingsValue("WindowPosY", 0)
			Configuration:SetSpringsettingsValue("Fullscreen", 1)
		end

		-- only run once, ever
		local firstRun = tonumber(Spring.GetConfigInt("FirstRun", 1) or 1) == 1
		if firstRun then
			for key, value in pairs(Configuration.game_settings) do
				Configuration:SetSpringsettingsValue(key, value)
			end
			Spring.SetConfigInt("FirstRun", 0)
		end

		--local compatProfile = Configuration.forcedCompatibilityProfile
		--Spring.Utilities.TableEcho(compatProfile, "compatProfile")
		--if compatProfile then
		--	for key, value in pairs(compatProfile) do
		--		Configuration:SetSpringsettingsValue(key, value, true)
		--	end
		--end
	end
	WG.LibLobby.lobby:AddListener("OnBattleAboutToStart", onBattleAboutToStart)
	WG.LibLobby.localLobby:AddListener("OnBattleAboutToStart", onBattleAboutToStart)

	WG.SettingsWindow = SettingsWindow
end

function widget:Shutdown()
	SaveLobbyDisplayMode()

	if WG.LibLobby then
		WG.LibLobby.lobby:RemoveListener("OnBattleAboutToStart", onBattleAboutToStart)
		WG.LibLobby.localLobby:RemoveListener("OnBattleAboutToStart", onBattleAboutToStart)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
