LoginWindow = LCS.class{}

--TODO: make this a util function, maybe even add this support to chili as a whole?
function createTabGroup(ctrls, visibleFunc)
	for i = 1, #ctrls do
		local ctrl1 = ctrls[i]
		if ctrl1.OnKeyPress == nil then
			ctrl1.OnKeyPress = {}
		end

		table.insert(ctrl1.OnKeyPress,
			function(obj, key, mods, ...)
				if key == Spring.GetKeyCode("tab") then
					local nextIndex = i%(#ctrls) + 1
					local ctrl2
					while (not ctrl2) and nextIndex ~= i do
						if (not visibleFunc[nextIndex]) or visibleFunc[nextIndex]() then
							ctrl2 = ctrls[nextIndex]
						end
						nextIndex = nextIndex%(#ctrls) + 1
					end

					if ctrl2 then
						screen0:FocusControl(ctrl2)
						if ctrl2.classname == "editbox" then
	-- 						ctrl2:Select(1, #ctrl2.text + 1)
							-- HACK
							ctrl2.selStart = 1
							ctrl2.selStartPhysical = 1
							ctrl2.selEnd = #ctrl2.text + 1
							ctrl2.selEndPhysical = #ctrl2.text + 1
						end
					end
				end
			end
		)
	end
end

local function GetLobbyName()
	return 'Chobby'
end

function LoginWindow:init(failFunction, cancelText, windowClassname, params)

	if WG.Chobby.lobbyInterfaceHolder:GetChildByName("loginWindow") then
		Log.Error("Tried to spawn duplicate login window")
		return
	end
	self.emailRequired = (params and params.emailRequired) or false
	self.windowHeight = (params and params.windowHeight) or (self.emailRequired and 430) or 390
	self.loginAfterRegister = (params and params.loginAfterRegister) or false

	local registerChildren = {}

	self.ResetText = function()
		if self.txtError then
			self.txtError:SetText("")
		end
	end

	self.CancelFunc = function ()
		self.window:Dispose()
		if failFunction then
			failFunction()
		end
		self.window = nil
	end

	self.lblLoginInstructions = Label:New {
		x = 15,
		width = 170,
		y = 14,
		height = 35,
		caption = i18n("login_long"),
		font = Configuration:GetFont(3),
	}

	self.lblRegisterInstructions = Label:New {
		x = 15,
		width = 170,
		y = 14,
		height = 35,
		caption = i18n("register_long"),
		font = Configuration:GetFont(3),
	}
	registerChildren[#registerChildren + 1] = self.lblRegisterInstructions

	self.txtUsername = TextBox:New {
		x = 15,
		width = 170,
		y = 60,
		height = 35,
		text = i18n("username") .. ":",
		fontsize = Configuration:GetFont(3).size,
	}
	self.ebUsername = EditBox:New {
		x = 135,
		width = 200,
		y = 51,
		height = 35,
		text = Configuration.userName or Configuration.suggestedNameFromSteam or "",
		font = Configuration:GetFont(3),
		useIME = false,
	}

	self.txtPassword = TextBox:New {
		x = 15,
		width = 170,
		y = 100,
		height = 35,
		text = i18n("password") .. ":",
		fontsize = Configuration:GetFont(3).size,
	}
	self.ebPassword = EditBox:New {
		x = 135,
		width = 200,
		y = 91,
		height = 35,
		text = Configuration.password or "",
		passwordInput = true,
		hint = "Enter password",
		font = Configuration:GetFont(3),
		useIME = false,
		OnKeyPress = {
			function(obj, key, mods, ...)
				if key == Spring.GetKeyCode("enter") or key == Spring.GetKeyCode("numpad_enter") then
					if self.tabPanel.tabBar:IsSelected("login") then
						self:tryLogin()
					else
						self:tryRegister()
					end
				end
			end
		},
	}

	self.txtConfirmPassword = TextBox:New {
		x = 15,
		width = 170,
		y = 140,
		height = 70,
		text = i18n("confirm") .. ":",
		fontsize = Configuration:GetFont(3).size,
		useIME = false,
	}
	registerChildren[#registerChildren + 1] = self.txtConfirmPassword

	self.ebConfirmPassword = EditBox:New {
		x = 135,
		width = 200,
		y = 131,
		height = 35,
		text = "",
		hint = "Confirm password",
		passwordInput = true,
		font = Configuration:GetFont(3),
		OnKeyPress = {
			function(obj, key, mods, ...)
				if key == Spring.GetKeyCode("enter") or key == Spring.GetKeyCode("numpad_enter") then
					if self.tabPanel.tabBar:IsSelected("register") then
						self:tryRegister()
					end
				end
			end
		},
	}
	registerChildren[#registerChildren + 1] = self.ebConfirmPassword

	if self.emailRequired then
		self.txtEmail = TextBox:New {
			x = 15,
			width = 170,
			y = 180,
			height = 35,
			text = i18n("Email") .. ":",
			fontsize = Configuration:GetFont(3).size,
			useIME = false,
		}
		registerChildren[#registerChildren + 1] = self.txtEmail

		self.ebEmail = EditBox:New {
			x = 135,
			width = 200,
			y = 171,
			height = 35,
			text = "",
			font = Configuration:GetFont(3),
			useIME = false,
			OnKeyPress = {
				function(obj, key, mods, ...)
					if key == Spring.GetKeyCode("enter") or key == Spring.GetKeyCode("numpad_enter") then
						if self.tabPanel.tabBar:IsSelected("register") then
							self:tryRegister()
						end
					end
				end
			},
		}
		registerChildren[#registerChildren + 1] = self.ebEmail
	end
  
  self.lblRegistrationMultiplayer = Label:New {
		x = 15,
		width = 170,
		y = 220,
		height = 35,
		caption = "Required for online play only",
		font = Configuration:GetFont(3),
	}
	registerChildren[#registerChildren + 1] = self.lblRegistrationMultiplayer

	self.cbAutoLogin = Checkbox:New {
		x = 15,
		width = 215,
		y = self.windowHeight - 180,
		height = 35,
		boxalign = "right",
		boxsize = 15,
		caption = i18n("autoLogin"),
		checked = Configuration.autoLogin,
		font = Configuration:GetFont(2),
		OnClick = {function (obj)
			Configuration:SetConfigValue("autoLogin", obj.checked)
		end},
	}

	self.txtError = TextBox:New {
		x = 15,
		right = 15,
		y = self.windowHeight - 216,
		height = 90,
		text = "",
		fontsize = Configuration:GetFont(3).size,
	}

	self.btnLogin = Button:New {
		right = 140,
		width = 130,
		y = self.windowHeight - 143,
		height = 70,
		caption = i18n("login_verb"),
		font = Configuration:GetFont(3),
		classname = "action_button",
		OnClick = {
			function()
				self:tryLogin()
			end
		},
	}

	self.btnRegister = Button:New {
		right = 140,
		width = 130,
		y = self.windowHeight - 143,
		height = 70,
		caption = i18n("register_verb"),
		font = Configuration:GetFont(3),
		classname = "option_button",
		OnClick = {
			function()
				self:tryRegister()
			end
		},
	}
	registerChildren[#registerChildren + 1] = self.btnRegister

	self.btnCancel = Button:New {
		right = 2,
		width = 130,
		y = self.windowHeight - 143,
		height = 70,
		caption = i18n(cancelText or "cancel"),
		font = Configuration:GetFont(3),
		classname = "negative_button",
		OnClick = {
			function()
				self.CancelFunc()
			end
		},
	}

	local ww, wh = Spring.GetWindowGeometry()
	local width = 430

	self.tabPanel = Chili.DetachableTabPanel:New {
		x = 0,
		right = 0,
		y = 0,
		minTabWidth = width/2 - 20,
		bottom = 0,
		padding = {0, 0, 0, 0},
		tabs = {
			[1] = { name = "login", caption = i18n("login"), children = {self.btnLogin, self.lblLoginInstructions}, font = Configuration:GetFont(2)},
			[2] = { name = "register", caption = i18n("register_verb"), children = registerChildren, font = Configuration:GetFont(2)},
		},
	}

	self.tabBarHolder = Control:New {
		name = "tabBarHolder",
		x = 9,
		y = 0,
		right = 0,
		height = 30,
		resizable = false,
		draggable = false,
		padding = {0, 2, 0, 0},
		children = {
			self.tabPanel.tabBar
		}
	}

	-- Prompt user to register account if their account has not been registered.
	if Configuration.firstLoginEver then
		self.tabPanel.tabBar:Select("register")
	end

	self.contentsPanel = ScrollPanel:New {
		x = 5,
		right = 5,
		y = 30,
		bottom = 4,
		horizontalScrollbar = false,
		children = {
			self.tabPanel,
			self.txtUsername,
			self.txtPassword,
			self.ebUsername,
			self.ebPassword,
			self.txtError,
			self.cbAutoLogin,
			self.btnCancel
		}
	}

	self.window = Window:New {
		x = math.floor((ww - width) / 2),
		y = math.floor((wh - self.windowHeight) / 2),
		width = width,
		height = self.windowHeight,
		caption = "",
		resizable = false,
		draggable = false,
		classname = windowClassname,
		children = {
			self.tabBarHolder,
			self.contentsPanel,
		},
		parent = WG.Chobby.lobbyInterfaceHolder,
		OnDispose = {
			function()
				self:RemoveListeners()
			end
		},
		OnFocusUpdate = {
			function(obj)
				obj:BringToFront()
			end
		}
	}

	self.window:BringToFront()

	local function IsRegisterInfoVisible()
		return self.tabPanel.tabBar.selected == 2
	end

	if self.emailRequired then
		createTabGroup({self.ebUsername, self.ebPassword, self.ebConfirmPassword, self.ebEmail}, {false, false, IsRegisterInfoVisible, IsRegisterInfoVisible})
	else
		createTabGroup({self.ebUsername, self.ebPassword, self.ebConfirmPassword}, {false, false, IsRegisterInfoVisible})
	end
	screen0:FocusControl(self.ebUsername)
	-- FIXME: this should probably be moved to the lobby wrapper
	self.loginAttempts = 0
end

function LoginWindow:RemoveListeners()
	if self.onAgreementEnd then
		lobby:RemoveListener("OnAgreementEnd", self.onAgreementEnd)
		self.onAgreementEnd = nil
	end
	if self.onAgreement then
		lobby:RemoveListener("OnAgreement", self.onAgreement)
		self.onAgreement = nil
	end
	if self.onConnect then
		lobby:RemoveListener("OnConnect", self.onConnect)
		self.onConnect = nil
	end
	if self.onDisconnected then
		lobby:RemoveListener("OnDisconnected", self.onDisconnected)
		self.onDisconnected = nil
	end
end

function LoginWindow:tryLogin()
	self.txtError:SetText("")

	local username = self.ebUsername.text
	local password = (self.ebPassword.visible and self.ebPassword.text) or nil
	if username == '' then
		return
	end
	Configuration.userName = username
	Configuration.password = password

	if not lobby.connected or self.loginAttempts >= 3 then
		self.loginAttempts = 0
		self:RemoveListeners()

		self.onConnect = function(listener)
			lobby:RemoveListener("OnConnect", self.onConnect)
			self:OnConnected(listener)
		end
		lobby:AddListener("OnConnect", self.onConnect)

		self.onDisconnected = function(listener)
			lobby:RemoveListener("OnDisconnected", self.onDisconnected)
			self.txtError:SetText(Configuration:GetErrorColor() .. "Cannot reach server:\n" .. tostring(Configuration:GetServerAddress()) .. ":" .. tostring(Configuration:GetServerPort()))
		end
		lobby:AddListener("OnDisconnected", self.onDisconnected)

		lobby:Connect(Configuration:GetServerAddress(), Configuration:GetServerPort(), username, password, 3, nil, GetLobbyName())
	else
		lobby:Login(username, password, 3, nil, GetLobbyName())
	end

	self.loginAttempts = self.loginAttempts + 1
end

function LoginWindow:tryRegister()
	if self.ebPassword.text ~= self.ebConfirmPassword.text then
		self.txtError:SetText(Configuration:GetErrorColor() .. "Passwords do not match.")
		return
	end

	WG.Analytics.SendOnetimeEvent("lobby:try_register")
	self.txtError:SetText("")

	local username = self.ebUsername.text
	local password = (self.ebPassword.visible and self.ebPassword.text) or nil
	local email = (self.emailRequired and self.ebEmail.visible and self.ebEmail.text) or nil
	if username == '' then
		return
	end

	if not lobby.connected or self.loginAttempts >= 3 then
		self.loginAttempts = 0
		self:RemoveListeners()

		self.onConnectRegister = function(listener)
			lobby:RemoveListener("OnConnect", self.onConnectRegister)
			self:OnConnected(listener)
		end
		WG.LoginWindowHandler.QueueRegister(username, password, email)
		lobby:AddListener("OnConnect", self.onConnectRegister)

		lobby:Connect(Configuration:GetServerAddress(), Configuration:GetServerPort(), username, password, 3, email, GetLobbyName())
	else
		lobby:Register(username, password, email)
		if self.loginAfterRegister then
			lobby:Login(username, password, 3, nil, GetLobbyName())
		end
	end

	self.loginAttempts = self.loginAttempts + 1
end

function LoginWindow:OnConnected()
	Spring.Echo("OnConnected")
	--self.txtError:SetText(Configuration:GetPartialColor() .. i18n("connecting"))

	self.onAgreement = function(listener, line)
		self.agreementText = ((self.agreementText and (self.agreementText .. " \n")) or "") .. line
	end
	lobby:AddListener("OnAgreement", self.onAgreement)

	self.onAgreementEnd = function(listener)
		self:createAgreementWindow()
		lobby:RemoveListener("OnAgreementEnd", self.onAgreementEnd)
		lobby:RemoveListener("OnAgreement", self.onAgreement)
	end
	lobby:AddListener("OnAgreementEnd", self.onAgreementEnd)
end

function LoginWindow:createAgreementWindow()
	self.agreementWindow = Window:New {
		x = 600,
		y = 200,
		width = 650,
		height = 530,
		caption = "User agreement",
		resizable = false,
		draggable = false,
		parent = WG.Chobby.lobbyInterfaceHolder,
	}

	self.tbAgreement = TextBox:New {
		x = 1,
		width = "100%",
		y = 1,
		height = "100%",
		text = self.agreementText,
		font = Configuration:GetFont(2),
	}

	ScrollPanel:New {
		x = 1,
		right = 7,
		y = 1,
		height = 390,
		children = {
			self.tbAgreement
		},
		parent = self.agreementWindow,
	}

	if self.emailRequired then
		self.txtVerif = TextBox:New {
			x = 1,
			width = 200,
			y = 405,
			height = 35,
			text = i18n("Email Verification Code") .. ":",
			fontsize = Configuration:GetFont(2).size,
			useIME = false,
			parent = self.agreementWindow,
		}
		self.ebVerif = EditBox:New {
			x = 200,
			width = 650-250,
			y = 395,
			height = 35,
			text = "",
			font = Configuration:GetFont(2),
			useIME = false,
			parent = self.agreementWindow,
		}
	end

	self.btnYes = Button:New {
		x = 1,
		width = 135,
		y = 430,
		height = 70,
		caption = "Accept",
		font = Configuration:GetFont(3),
		OnClick = {
			function()
				local verificationCode = ""
				if self.emailRequired then
					verificationCode = self.ebVerif.text
				end
				self:acceptAgreement(verificationCode)
			end
		},
		parent = self.agreementWindow,
	}
	self.btnNo = Button:New {
		x = 240,
		width = 135,
		y = 430,
		height = 70,
		caption = "Decline",
		font = Configuration:GetFont(3),
		OnClick = {
			function()
				self:declineAgreement()
			end
		},
		parent = self.agreementWindow,
	}
end

function LoginWindow:acceptAgreement(verificationCode)
	lobby:ConfirmAgreement(verificationCode)
	self.agreementWindow:Dispose()
end

function LoginWindow:declineAgreement()
	lobby:Disconnect()
	self.agreementWindow:Dispose()
end
