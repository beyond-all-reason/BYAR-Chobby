InformationPopup = LCS.class{}

function InformationPopup:init(infoText, extras)

	extras = extras or {}
	extras.width = extras.width or 320
	extras.height = extras.height or 220
	self.closeFunc = extras.closeFunc

	self.mainWindow = Window:New {
		x = 700,
		y = 300,
		width = extras.width,
		height = extras.height,
		caption = "",
		resizable = false,
		draggable = false,
		parent = WG.Chobby.lobbyInterfaceHolder,
		classname = "main_window_small",
	}

	local function DoneFunc()
		self:Close()
	end

	if extras.heading then
		Label:New {
			x = 0,
			y = 15,
			width = extras.width - self.mainWindow.padding[1] - self.mainWindow.padding[3],
			height = 35,
			align = "center",
			font = Configuration:GetFont(4),
			caption = extras.heading,
			parent = self.mainWindow,
		}
	end

	self.lblText = TextBox:New {
		x = 15,
		right = 15,
		y = (extras.heading and 65) or 15,
		bottom = 75,
		font = Configuration:GetFont(3),
		text = infoText,
		parent = self.mainWindow,
	}

	local btnAccept = Button:New {
		x = "25%",
		right = "25%",
		bottom = 1,
		height = 70,
		caption = extras.caption or i18n("ok"),
		font = Configuration:GetFont(3),
		classname = extras.buttonClass or "action_button",
		OnClick = {
			function()
				DoneFunc()
			end
		},
		parent = self.mainWindow,
	}

	local popupHolder = PriorityPopup(self.mainWindow, DoneFunc, DoneFunc)
end

function InformationPopup:SetText(newText)
	self.lblText:SetText(newText)
end

function InformationPopup:Close()
	if self.closeFunc then
		self.closeFunc()
	end
	self.mainWindow:Dispose()
end
