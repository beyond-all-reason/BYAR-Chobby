SteamLoginWindow = LCS.class{}

local function GetLobbyName()
	return 'Chobby'
end

function SteamLoginWindow:init(failFunction, cancelText, windowClassname)
	if WG.Chobby.lobbyInterfaceHolder:GetChildByName("loginWindow") then
		Log.Error("Tried to spawn duplicate login window")
		return
	end

	self.CancelFunc = function ()
		self.window:Dispose()
		if failFunction then
			failFunction()
		end
		self.window = nil
	end

	local ww, wh = Spring.GetWindowGeometry()
	local w, h = 386, 304

	self.passwordShown = false

	self.window = Window:New {
		x = math.floor((ww - w) / 2),
		y = math.floor((wh - h) / 2),
		width = w,
		height = h,
		caption = "",
		resizable = false,
		draggable = false,
		classname = windowClassname,
		parent = WG.Chobby.lobbyInterfaceHolder,
		OnFocusUpdate = {
			function(obj)
				obj:BringToFront()
			end
		}
	}

	self.lblRegisterInstructions = Label:New {
		x = 15,
		width = 170,
		y = 16,
		height = 35,
		caption = i18n("register_steam_long"),
		font = Configuration:GetFont(3),
		parent = self.window
	}

	self.txtUsername = TextBox:New {
		x = 15,
		width = 170,
		y = 65,
		height = 35,
		text = i18n("username") .. ":",
		fontsize = Configuration:GetFont(3).size,
		parent = self.window
	}
	self.ebUsername = EditBox:New {
		x = 135,
		width = 200,
		y = 56,
		height = 35,
		text = Configuration.userName or Configuration.suggestedNameFromSteam or "",
		font = Configuration:GetFont(3),
		useIME = false,
		parent = self.window
	}

	self.txtPassword = TextBox:New {
		x = 15,
		width = 170,
		y = 105,
		height = 35,
		text = i18n("password") .. ":",
		fontsize = Configuration:GetFont(3).size,
	}
	self.ebPassword = EditBox:New {
		x = 135,
		width = 200,
		y = 96,
		height = 35,
		text = Configuration.password or "",
		passwordInput = true,
		font = Configuration:GetFont(3),
		useIME = false,
		OnKeyPress = {
			function(obj, key, mods, ...)
				if key == Spring.GetKeyCode("enter") or key == Spring.GetKeyCode("numpad_enter") then
					self:tryRegister()
				end

				if string.len(obj.text) == 0 then
					self.btnRegister:SetCaption(i18n("register_verb"))
				else
					self.btnRegister:SetCaption(i18n("link_verb"))
				end
			end
		},
	}

	self.txtError = TextBox:New {
		x = 15,
		right = 15,
		bottom = 60,
		height = 90,
		text = "",
		fontsize = Configuration:GetFont(3).size,
		parent = self.window
	}

	self.btnRegister = Button:New {
		right = 140,
		width = 130,
		bottom = 2,
		height = 70,
		caption = i18n("connect"),
		font = Configuration:GetFont(3),
		classname = "action_button",
		OnClick = {
			function()
				self:tryRegister()
			end
		},
		parent = self.window
	}

	self.btnCancel = Button:New {
		right = 2,
		width = 130,
		bottom = 2,
		height = 70,
		caption = i18n(cancelText or "cancel"),
		font = Configuration:GetFont(3),
		classname = "negative_button",
		OnClick = {
			function()
				self.CancelFunc()
			end
		},
		parent = self.window
	}

	self.window:BringToFront()

	screen0:FocusControl(self.ebUsername)
	self.loginAttempts = 0
end

function SteamLoginWindow:ShowPassword()
	if self.passwordShown then
		return
	end
	self.passwordShown = true

	self.window:AddChild(self.txtPassword)
	self.window:AddChild(self.ebPassword)

	WG.Chobby.InformationPopup("This account already exists.\n\nIf this is your account then enter your password to link it to Steam.\n\nOtherwise, leave the password blank and try a different name.", {width = 390, height = 290})

	if string.len(self.ebPassword.text) == 0 then
		self.btnRegister:SetCaption(i18n("register_verb"))
	else
		self.btnRegister:SetCaption(i18n("link_verb"))
	end
end

function SteamLoginWindow:tryRegister()
	WG.Analytics.SendOnetimeEvent("lobby:try_register")
	self.txtError:SetText("")

	local username = self.ebUsername.text
	if username == '' then
		return
	end

	local password
	if self.passwordShown and self.ebPassword.text then
		local pwLength = string.len(self.ebPassword.text)
		if pwLength and pwLength ~= 0 then
			password = self.ebPassword.text
		end
	end

	if not lobby.connected or self.loginAttempts >= 3 then
		self.loginAttempts = 0
		if password then
			Configuration.password = password
		else
			WG.LoginWindowHandler.QueueRegister(username)
		end
		lobby:Connect(Configuration:GetServerAddress(), Configuration:GetServerPort(), username, password, 3, nil, GetLobbyName())
	else
		if not password then
			lobby:Register(username, password, nil, true)
		end
		lobby:Login(username, password, 3, nil, GetLobbyName(), true)
	end

	self.loginAttempts = self.loginAttempts + 1
end
