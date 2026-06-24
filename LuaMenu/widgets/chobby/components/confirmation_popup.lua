ConfirmationPopup = LCS.class{}

function ConfirmationPopup:init(successFunction, question, doNotAskAgainKey, width, height, yesText, noText, failureFunction, disableAcceptHotkey, failureTimeout)

	if WG.LimitFps and WG.LimitFps.ForceRedrawPeriod then
		WG.LimitFps.ForceRedrawPeriod(0.3)
	end

	local mainWindow = Window:New {
		x = 700,
		y = 300,
		width = width or 400,
		height = height or 280,
		caption = "",
		resizable = false,
		draggable = false,
		parent = (WG.Chobby and WG.Chobby.lobbyInterfaceHolder) or nil,
		classname = "main_window_small",
	}

	local applyTimeout = true

	local function CancelFunc()
		applyTimeout = false
		if failureFunction then
			failureFunction()
		end
		mainWindow:Dispose()
	end

	local function AcceptFunc()
		applyTimeout = false
		if successFunction then
			successFunction()
		end
		mainWindow:Dispose()
	end

	if failureTimeout then
		local function TimeoutFunc()
			if applyTimeout then
				CancelFunc()
			end
		end
		WG.Delay(TimeoutFunc, failureTimeout)
	end

	local lblText = TextBox:New {
		x = 15,
		right = 15,
		y = 15,
		height = 35,
		objectOverrideFont = (WG.Chobby and WG.Chobby.Configuration and WG.Chobby.Configuration:GetFont(3)) or nil,
		objectOverrideHintFont = (WG.Chobby and WG.Chobby.Configuration and WG.Chobby.Configuration:GetFont(3)) or nil,
		text = question,
		parent = mainWindow,
	}

	local btnAccept = Button:New {
		x = 5,
		width = 135,
		bottom = 1,
		height = 70,
		caption = i18n(yesText or "yes"),
		objectOverrideFont = (WG.Chobby and WG.Chobby.Configuration and WG.Chobby.Configuration:GetFont(3)) or nil,
		classname = "action_button",
		OnClick = {
			function()
				AcceptFunc()
			end
		},
		parent = mainWindow,
	}
	local btnClose = Button:New {
		right = 5,
		width = 135,
		bottom = 1,
		height = 70,
		caption = i18n(noText or "cancel"),
		objectOverrideFont = (WG.Chobby and WG.Chobby.Configuration and WG.Chobby.Configuration:GetFont(3)) or nil,
		classname = "negative_button",
		OnClick = {
			function()
				CancelFunc()
			end
		},
		parent = mainWindow,
	}

	if doNotAskAgainKey then
		local doNotAskAgain = Checkbox:New {
			x = 15,
			width = 150,
			bottom = 75,
			height = 35,
			boxalign = "right",
			boxsize = 15,
			caption = i18n("do_not_ask_again"),
			checked = Configuration[doNotAskAgainKey] or false,
			objectOverrideFont = (WG.Chobby and WG.Chobby.Configuration and WG.Chobby.Configuration:GetFont(1)) or nil,
			parent = mainWindow,
			OnClick = {
				function (obj)
					Configuration:SetConfigValue(doNotAskAgainKey, obj.checked)
				end
			},
		}
	end

	local popupHolder = PriorityPopup(mainWindow, CancelFunc, AcceptFunc, nil, nil, disableAcceptHotkey)
end
