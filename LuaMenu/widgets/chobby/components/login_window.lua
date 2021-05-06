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
	self.windowHeight = (params and params.windowHeight) or (self.emailRequired and 430+200) or 390+200
	self.loginAfterRegister = (params and params.loginAfterRegister) or false

	local registerChildren = {}

	local recoverChildren = {}

	local loginChildren = {}


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
	loginChildren[#loginChildren+1] = self.lblLoginInstructions

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
	loginChildren[#loginChildren+1] = self.txtUsername

	self.ebUsername = EditBox:New {
		x = 135,
		width = 200,
		y = 51,
		height = 35,
		text = Configuration.userName or Configuration.suggestedNameFromSteam or "",
		font = Configuration:GetFont(3),
		useIME = false,
	}
	loginChildren[#loginChildren+1] = self.ebUsername

	self.txtPassword = TextBox:New {
		x = 15,
		width = 170,
		y = 100,
		height = 35,
		text = i18n("password") .. ":",
		fontsize = Configuration:GetFont(3).size,
	}
	loginChildren[#loginChildren+1] = self.txtPassword


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
	loginChildren[#loginChildren+1] = self.ebPassword


	self.txtUsernameRegister = TextBox:New {
		x = 15,
		width = 170,
		y = 60,
		height = 35,
		text = i18n("username") .. ":",
		fontsize = Configuration:GetFont(3).size,
	}
	registerChildren[#registerChildren+1] = self.txtUsernameRegister

	self.ebUsernameRegister = EditBox:New {
		x = 135,
		width = 200,
		y = 51,
		height = 35,
		text = Configuration.userName or Configuration.suggestedNameFromSteam or "",
		font = Configuration:GetFont(3),
		useIME = false,
	}
	registerChildren[#registerChildren+1] = self.ebUsernameRegister


	self.txtPasswordRegister = TextBox:New {
		x = 15,
		width = 170,
		y = 100,
		height = 35,
		text = i18n("password") .. ":",
		fontsize = Configuration:GetFont(3).size,
	}
	registerChildren[#registerChildren+1] = self.txtPasswordRegister

	self.ebPasswordRegister = EditBox:New {
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
	registerChildren[#registerChildren+1] = self.ebPasswordRegister


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
	loginChildren[#loginChildren+1] = self.cbAutoLogin

	self.cbAutoLoginRegister = Checkbox:New {
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
	registerChildren[#registerChildren + 1] = self.cbAutoLoginRegister

	self.txtError = TextBox:New {
		x = 15,
		right = 15,
		y = self.windowHeight - 216,
		height = 90,
		text = "",
		fontsize = Configuration:GetFont(3).size,
	}
	loginChildren[#loginChildren+1] = self.txtError

	self.txtErrorRegister = TextBox:New {
		x = 15,
		right = 15,
		y = self.windowHeight - 216,
		height = 90,
		text = "",
		fontsize = Configuration:GetFont(3).size,
	}
	registerChildren[#registerChildren + 1] = self.txtErrorRegister

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
	loginChildren[#loginChildren+1] = self.btnLogin

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


	-- Recovery needs the following abilities
		-- Change user name (requires old email)
			-- Requires user to be logged in
		-- Reset Password (requires old email)
			-- User cant even log in, needs email and then verification code
		-- Change email associated with account
			-- requires user to be logged in
		-- Forgot username
			-- requires email?
		-- Change password
			-- must be logged in

	-- row grid goes by 40 pixels plus 10
	-- col grid is 6 pieces 125 pixels plus 10
	local formw = 150
	local formh = 20
	local pad = 15

-----------------------CHANGE USERNAME-------------------------------
	self.txtChangeUserName = TextBox:New {
		x = pad + formw * 0 ,
		y = pad + formh * 0 ,
		width =   formw * 3 ,
		height =  formh * 2 ,
		-- caption = i18n("register_long"),
		text = "Change user name. You must be logged in, and will be logged out on successful change.",
		font = Configuration:GetFont(1),
	}
	recoverChildren[#recoverChildren+1] = self.txtChangeUserName

	self.lblChangeUserName =  Label:New {
		x = pad + formw * 0 ,
		y = pad + formh * 2 ,
		width =   formw * 1 ,
		height =  formh * 1 ,
		-- caption = i18n("register_long"),
		caption = "New user name:",
		font = Configuration:GetFont(1),
	}
	recoverChildren[#recoverChildren+1] = self.lblChangeUserName

	self.ebChangeUserName = EditBox:New {
		x = pad + formw * 1 ,
		y = pad + formh * 2 ,
		width =   formw * 1 ,
		height =  formh * 1 ,
		text = Configuration.userName or Configuration.suggestedNameFromSteam or "",
		font = Configuration:GetFont(1),
		tooltip = 'User name may contain only letters, numbers, square brackets and underscores',
		useIME = false,
	}
	recoverChildren[#recoverChildren+1] = self.ebChangeUserName

	self.btnChangeUserName = Button:New {
		x = pad + formw * 2 ,
		y = pad + formh * 2 ,
		width =   formw * 1 ,
		height =  formh * 1 ,
		caption = i18n("Change username"),
		font = Configuration:GetFont(1),
		classname = "negative_button",
		OnClick = {
			function()
				self:tryChangeUserName()
			end
		},
	}
	recoverChildren[#recoverChildren+1] = self.btnChangeUserName

	self.txtErrorChangeUserName = TextBox:New {
		x = pad + formw * 0 ,
		y = pad + formh * 3 ,
		width =   formw * 3 ,
		height =  formh * 1 ,
		text = "If this doesnt work contact us on Discord",
		fontsize = Configuration:GetFont(1).size,
	}
	recoverChildren[#recoverChildren+1] = self.txtErrorChangeUserName

	recoverChildren[#recoverChildren+1] = Line:New{x=5,y=formh * 5,right=5, height = 1}

------------------------------RESET PASSWORD----------------------------------
	self.txtResetPassword = TextBox:New {
		x = pad + formw * 0 ,
		y = pad + formh * 5 ,
		width =   formw * 3 ,
		height =  formh * 1 ,
		-- caption = i18n("register_long"),
		text = "Reset forgotten password: Enter your email address used for registration, then enter the validation code sent via email.",
		font = Configuration:GetFont(1),
	}
	recoverChildren[#recoverChildren+1] = self.txtResetPassword

	self.lblResetPasswordEmail =  Label:New {
		x = pad + formw * 0 ,
		y = pad + formh * 7 ,
		width =   formw * 1 ,
		height =  formh * 1 ,
		-- caption = i18n("register_long"),
		caption = "Email address:",
		font = Configuration:GetFont(1),
	}
	recoverChildren[#recoverChildren+1] = self.lblResetPasswordEmail

	self.ebResetPasswordEmail = EditBox:New {
		x = pad + formw * 1 ,
		y = pad + formh * 7 ,
		width =   formw * 1 ,
		height =  formh * 1 ,
		text = "",
		font = Configuration:GetFont(1),
		tooltip = 'Make sure you enter your valid email address',
		useIME = false,
	}
	recoverChildren[#recoverChildren+1] = self.ebResetPasswordEmail

	self.lblResetPasswordVerification =  Label:New {
		x = pad + formw * 0 ,
		y = pad + formh * 8 ,
		width =   formw * 1 ,
		height =  formh * 1 ,
		-- caption = i18n("register_long"),
		caption = "Verification Code:",
		font = Configuration:GetFont(1),
	}
	recoverChildren[#recoverChildren+1] = self.lblResetPasswordVerification

	self.ebResetPasswordVerification = EditBox:New {
		x = pad + formw * 1 ,
		y = pad + formh * 8 ,
		width =   formw * 1 ,
		height =  formh * 1 ,
		text = "",
		font = Configuration:GetFont(1),
		tooltip = 'You will recieve this code via email after submitting your email in the above box',
		useIME = false,
	}
	recoverChildren[#recoverChildren+1] = self.ebResetPasswordVerification

	self.btnResetPasswordEmail = Button:New {
		x = pad + formw * 2 ,
		y = pad + formh * 7 ,
		width =   formw * 1 ,
		height =  formh * 1 ,
		caption = i18n("Submit email"),
		font = Configuration:GetFont(1),
		classname = "negative_button",
		OnClick = {
			function()
				self:tryResetPasswordEmail()
			end
		},
	}
	recoverChildren[#recoverChildren+1] = self.btnResetPasswordEmail

	self.btnResetPasswordVerification = Button:New {
		x = pad + formw * 2 ,
		y = pad + formh * 8 ,
		width =   formw * 1 ,
		height =  formh * 1 ,
		caption = i18n("Submit Verification"),
		font = Configuration:GetFont(1),
		classname = "negative_button",
		OnClick = {
			function()
				self:tryResetPasswordVerification()
			end
		},
	}
	recoverChildren[#recoverChildren+1] = self.btnResetPasswordVerification

	self.txtErrorResetPassword = TextBox:New {
		x = pad + formw * 0 ,
		y = pad + formh * 9 ,
		width =   formw * 3 ,
		height =  formh * 1 ,
		text = "If this doesnt work contact us on Discord",
		fontsize = Configuration:GetFont(1).size,
	}
	recoverChildren[#recoverChildren+1] = self.txtErrorResetPassword

	recoverChildren[#recoverChildren+1] = Line:New{x=5,y=formh * 11,right=5, height = 1}

---------------------------Change Password--------------------------------
	self.txtChangePassword = TextBox:New {
		x = pad + formw * 0 ,
		y = pad + formh * 11 ,
		width =   formw * 3 ,
		height =  formh * 1 ,
		-- caption = i18n("register_long"),
		text = "Change Password: You must be logged in, enter your old and your new password",
		font = Configuration:GetFont(1),
	}
	recoverChildren[#recoverChildren+1] = self.txtChangePassword

	self.lblChangePasswordOld =  Label:New {
		x = pad + formw * 0 ,
		y = pad + formh * 13 ,
		width =   formw * 1 ,
		height =  formh * 1 ,
		-- caption = i18n("register_long"),
		caption = "Old password:",
		font = Configuration:GetFont(1),
	}
	recoverChildren[#recoverChildren+1] = self.lblChangePasswordOld

	self.ebChangePasswordOld = EditBox:New {
		x = pad + formw * 1 ,
		y = pad + formh * 13 ,
		width =   formw * 1 ,
		height =  formh * 1 ,
		text = "",
		font = Configuration:GetFont(1),
		tooltip = 'Enter your old password here',
		useIME = false,
	}
	recoverChildren[#recoverChildren+1] = self.ebChangePasswordOld

	self.lblChangePasswordNew =  Label:New {
		x = pad + formw * 0 ,
		y = pad + formh * 14 ,
		width =   formw * 1 ,
		height =  formh * 1 ,
		-- caption = i18n("register_long"),
		caption = "New Password:",
		font = Configuration:GetFont(1),
	}
	recoverChildren[#recoverChildren+1] = self.lblChangePasswordNew

	self.ebChangePasswordNew = EditBox:New {
		x = pad + formw * 1 ,
		y = pad + formh * 14 ,
		width =   formw * 1 ,
		height =  formh * 1 ,
		text = "",
		font = Configuration:GetFont(1),
		tooltip = 'Enter your new password here',
		useIME = false,
	}
	recoverChildren[#recoverChildren+1] = self.ebChangePasswordNew

	self.btnChangePassword = Button:New {
		x = pad + formw * 2 ,
		y = pad + formh * 13 ,
		width =   formw * 1 ,
		height =  formh * 2 ,
		caption = i18n("Change Password"),
		font = Configuration:GetFont(1),
		classname = "negative_button",
		OnClick = {
			function()
				self:tryChangePassword()
			end
		},
	}
	recoverChildren[#recoverChildren+1] = self.btnChangePassword

	self.txtErrorChangePassword = TextBox:New {
		x = pad + formw * 0 ,
		y = pad + formh * 15 ,
		width =   formw * 3 ,
		height =  formh * 1 ,
		text = "If this doesnt work contact us on Discord",
		fontsize = Configuration:GetFont(1).size,
	}
	recoverChildren[#recoverChildren+1] = self.txtErrorChangePassword

	recoverChildren[#recoverChildren+1] = Line:New{x=5,y=formh * 17,right=5, height = 1}

	---------------------------Change Email-------------------------------
	self.txtChangeEmail = TextBox:New {
		x = pad + formw * 0 ,
		y = pad + formh * 17 ,
		width =   formw * 3 ,
		height =  formh * 1 ,
		-- caption = i18n("register_long"),
		text = "Change email address associated with your account. You must be logged in. Enter the new email address you wish to use, then enter the validation code sent to the new email address.",
		font = Configuration:GetFont(1),
	}
	recoverChildren[#recoverChildren+1] = self.txtChangeEmail

	self.lblChangeEmailEmail =  Label:New {
		x = pad + formw * 0 ,
		y = pad + formh * 20 ,
		width =   formw * 1 ,
		height =  formh * 1 ,
		-- caption = i18n("register_long"),
		caption = "New email address:",
		font = Configuration:GetFont(1),
	}
	recoverChildren[#recoverChildren+1] = self.lblChangeEmailEmail

	self.ebChangeEmailEmail = EditBox:New {
		x = pad + formw * 1 ,
		y = pad + formh * 20 ,
		width =   formw * 1 ,
		height =  formh * 1 ,
		text = "",
		font = Configuration:GetFont(1),
		tooltip = 'Make sure you enter your new email address',
		useIME = false,
	}
	recoverChildren[#recoverChildren+1] = self.ebChangeEmailEmail

	self.lblChangeEmailVerification =  Label:New {
		x = pad + formw * 0 ,
		y = pad + formh * 21 ,
		width =   formw * 1 ,
		height =  formh * 1 ,
		-- caption = i18n("register_long"),
		caption = "Verification Code:",
		font = Configuration:GetFont(1),
	}
	recoverChildren[#recoverChildren+1] = self.lblChangeEmailVerification

	self.ebChangeEmailVerification = EditBox:New {
		x = pad + formw * 1 ,
		y = pad + formh * 21 ,
		width =   formw * 1 ,
		height =  formh * 1 ,
		text = "",
		font = Configuration:GetFont(1),
		tooltip = 'You will recieve this code via email after submitting your email in the above box',
		useIME = false,
	}
	recoverChildren[#recoverChildren+1] = self.ebChangeEmailVerification

	self.btnChangeEmail = Button:New {
		x = pad + formw * 2 ,
		y = pad + formh * 20 ,
		width =   formw * 1 ,
		height =  formh * 1 ,
		caption = i18n("Submit email"),
		font = Configuration:GetFont(1),
		classname = "negative_button",
		OnClick = {
			function()
				self:tryChangeEmail()
			end
		},
	}
	recoverChildren[#recoverChildren+1] = self.btnChangeEmail

	self.btnChangeEmailVerification = Button:New {
		x = pad + formw * 2 ,
		y = pad + formh * 21 ,
		width =   formw * 1 ,
		height =  formh * 1 ,
		caption = i18n("Submit Verification"),
		font = Configuration:GetFont(1),
		classname = "negative_button",
		OnClick = {
			function()
				self:tryChangeEmailVerification()
			end
		},
	}
	recoverChildren[#recoverChildren+1] = self.btnChangeEmailVerification

	self.txtErrorChangeEmail = TextBox:New {
		x = pad + formw * 0 ,
		y = pad + formh * 22 ,
		width =   formw * 3 ,
		height =  formh * 1 ,
		text = "If this doesnt work contact us on Discord",
		fontsize = Configuration:GetFont(1).size,
	}
	recoverChildren[#recoverChildren+1] = self.txtErrorChangeEmail


	--------- just logout button --------
	local function LogoutFunc()
		if lobby:GetConnectionStatus() ~= "offline" then
			Spring.Echo("Logout")
			WG.Chobby.interfaceRoot.CleanMultiplayerState()
			WG.Chobby.Configuration:SetConfigValue("autoLogin", false)
			lobby:Disconnect()
		else
			Spring.Echo("Logout pressed, but already offline")
		end
	end

	self.btnLogOut = Button:New {
		right = 140,
		width = 130,
		y = self.windowHeight - 143,
		height = 70,
		caption = "Logout",
		font = Configuration:GetFont(3),
		classname = "negative_button",
		OnClick = {
			LogoutFunc
		},
	}

	recoverChildren[#recoverChildren+1] = self.btnLogOut

	local ww, wh = Spring.GetWindowGeometry()
	local width = 3 * (formw  + 30) --used to be bout tree fiddy


	self.tabPanel = Chili.DetachableTabPanel:New {
		x = 0,
		right = 0,
		y = 0,
		minTabWidth = width/3 - 20,
		bottom = 0,
		padding = {0, 0, 0, 0},
		tabs = {
			[1] = { name = "login", caption = i18n("login"), children = loginChildren, font = Configuration:GetFont(2)},
			[2] = { name = "register", caption = i18n("register_verb"), children = registerChildren, font = Configuration:GetFont(2)},
			[3] = { name = "reset", caption = "Recover/Change", children = recoverChildren, font = Configuration:GetFont(2)},
			--[3] = { name = "test", caption = "teset2", children = {self.testbutton}, font = Configuration:GetFont(2)},
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
		horizontalScrollbar = true,
		children = {
			self.tabPanel,
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
	-- FIXME: the rest should be removed too
	if self.OnChangeEmailRequestDenied then
		lobby:RemoveListener("OnChangeEmailRequestDenied", self.OnChangeEmailRequestDenied)
	end
end

function LoginWindow:tryLogin()
	self.txtError:SetText("")

	local username = self.ebUsername.text
	local password = (self.ebPassword.visible and self.ebPassword.text) or nil
	--Spring.Echo("isthismd5d?",username,password)
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

function isInValidUserName(username)
	local badwords = {"fuck","cunt","shit","cock","faggot","adolf","hitler","nigger"}

	validUserNameRegex = "^[a-zA-Z%d%[%]_]+$"
	if string.match(username,validUserNameRegex) and string.len( username) == string.len( string.match(username,validUserNameRegex)) then
		--print (username .. " is OK")
		if string.len(username) >20 then
			return "Username too long, 20 characters max"
		end
		if string.len(username) <3 then
			return "Username too short, at least 3 characters"
		end
		for index, badword in ipairs(badwords) do
			if string.match(string.lower( username),badword) then
				return "Username contains banned word: "..badword
			end
		end
		return false
	else
		--print (username .. " is not OK: " .. ( string.match(username,validUserNameRegex) or "") )
		return "Username may only contain letters, numbers, [] and _"
	end
end


function LoginWindow:tryRegister()
	local username = self.ebUsernameRegister.text

	if username == '' then
		return
	end
	local isinValidUserName = isInValidUserName(username)
	if isinValidUserName then
		self.txtErrorRegister:SetText(Configuration:GetErrorColor() .. isinValidUserName)
		return
	end

	if self.ebPasswordRegister.text ~= self.ebConfirmPassword.text then
		self.txtErrorRegister:SetText(Configuration:GetErrorColor() .. "Passwords do not match.")
		return
	end

	WG.Analytics.SendOnetimeEvent("lobby:try_register")
	self.txtErrorRegister:SetText("")

	local password = (self.ebPasswordRegister.visible and self.ebPasswordRegister.text) or nil
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

---------------------------- Change Username ---------------------------

function LoginWindow:tryChangeUserName()
	Spring.Echo("lobby:GetConnectionStatus()",lobby:GetConnectionStatus())
	local newusername = self.ebChangeUserName.text
	local isinValidUserName = isInValidUserName(newusername)
	if isinValidUserName then
		self.txtErrorChangeUserName:SetText(Configuration:GetErrorColor() .. isinValidUserName)
		return
	end
	if lobby:GetConnectionStatus() == "connected" then
		WG.Analytics.SendOnetimeEvent("lobby:try_changeusername")
		lobby:RenameAccount(newusername)
		self.txtErrorChangeUserName:SetText("You will be disconnected on success. Your new user name is: " .. newusername)
	else
		self.txtErrorChangeUserName:SetText(Configuration:GetErrorColor() .. "Must be logged in to change user name!")
	end
end

---------------------------- Change Email Address ---------------------------



function LoginWindow:tryChangeEmail()
	--Spring.Echo("lobby:GetConnectionStatus()",lobby:GetConnectionStatus())
	-- https://springrts.com/dl/LobbyProtocol/ProtocolDescription.html#CHANGEEMAILREQUEST:client
	-- step 1, send a CHANGEEMAILREQUEST packet, which either returns CHANGEEMAILREQUESTDENIED or CHANGEEMAILREQUESTACCEPTED

	local newemail = self.ebChangeEmailEmail.text
	if string.len(newemail) < 5 then
		self.txtErrorChangeEmail:SetText(
		Configuration:GetErrorColor() ..
		"Enter a valid email address, not " .. newemail
		)
		return false
	end

	if  lobby:GetConnectionStatus() ~= "connected" then
		self.txtErrorChangeEmail:SetText(
			Configuration:GetErrorColor() ..
			"Must be logged in to change email address"
		)
		return false
	end

	self.txtErrorChangeEmail:SetText(
		Configuration:GetWarningColor() ..
		"Sending Request for: " .. newemail
	)

	WG.Analytics.SendOnetimeEvent("lobby:try_changeemail")

	self.onChangeEmailRequestDenied = function(listener, errorMsg)
		lobby:RemoveListener("OnChangeEmailRequestDenied", self.onChangeEmailRequestDenied)
		self.txtErrorChangeEmail:SetText(
				Configuration:GetErrorColor() ..
				"Change Email Request Denied: " .. errorMsg
			)
	end

	self.onChangeEmailRequestAccepted = function(listener)
		lobby:RemoveListener("OnChangeEmailRequestAccepted", self.onChangeEmailRequestAccepted)
		self.txtErrorChangeEmail:SetText(
				Configuration:GetSuccessColor() ..
				"Request Accepted, enter verification code recieved via email"
			)
	end

	lobby:AddListener("OnChangeEmailRequestDenied", self.onChangeEmailRequestDenied)
	lobby:AddListener("OnChangeEmailRequestAccepted", self.onChangeEmailRequestAccepted)
	lobby:ChangeEmailRequest(newemail)
end




function LoginWindow:tryChangeEmailVerification ()
	if  lobby:GetConnectionStatus() ~= "connected" then
		self.txtErrorChangeEmail:SetText(
			Configuration:GetErrorColor() ..
			"Must be logged in to verify change email address"
		)
		return false
	end

	local newemail = self.ebChangeEmailEmail.text
	if string.len(newemail) < 5 then
		self.txtErrorChangeEmail:SetText(
		Configuration:GetErrorColor() ..
		"Enter a valid email address, not" .. newemail
		)
		return false
	end

	local verificationCode = self.ebChangeEmailVerification.text

	if string.len(verificationCode) < 3 then
		self.txtErrorChangeEmail:SetText(
			Configuration:GetErrorColor() ..
			"Verification code too short: " .. verificationCode
			)
		return false
	end

	self.txtErrorChangeEmail:SetText(
		Configuration:GetWarningColor() ..
		"Sending Verification Code: " .. verificationCode .. " for ".. newemail
	)

	self.onChangeEmailDenied = function (listener, errorMsg)
		lobby:RemoveListener("OnChangeEmailDenied", self.onChangeEmailDenied)
		self.txtErrorChangeEmail:SetText(
				Configuration:GetErrorColor() ..
				"Change Email Denied: " .. errorMsg
			)
	end

	self.onChangeEmailReqestAccepted = function (listener)
		lobby:RemoveListener("OnChangeEmailAccepted", self.onChangeEmailAccepted)
		self.txtErrorChangeEmail:SetText(
				Configuration:GetSuccessColor() ..
				"Email changed successfully to " .. self.ebChangeEmailEmail.text
			)
	end

	lobby:AddListener("OnChangeEmailDenied", self.onChangeEmailDenied)
	lobby:AddListener("OnChangeEmailAccepted", self.onChangeEmailAccepted)

	WG.Analytics.SendOnetimeEvent("lobby:try_changeemailverification")
	lobby:ChangeEmail(newemail, verificationCode)
end


---------------------------- Reset Password ---------------------------


function LoginWindow:tryResetPasswordEmail()
	Spring.Echo("lobby:GetConnectionStatus()",lobby:GetConnectionStatus())
	-- https://springrts.com/dl/LobbyProtocol/ProtocolDescription.html#RESETPASSWORDREQUEST:client
	if  lobby:GetConnectionStatus() == "connected" then
		self.txtErrorResetPassword:SetText("Already connected, why do need to reset your password?")
		return false
	end

	local emailaddress = self.ebResetPasswordEmail.text
	if string.len(emailaddress) < 5 then
		self.txtErrorResetPassword:SetText(
		Configuration:GetErrorColor() ..
		"Enter a valid email address, not " .. emailaddress
		)
		return false
	end

	self.txtErrorResetPassword:SetText(
		Configuration:GetWarningColor() ..
		"Sending reset request for: " .. emailaddress
	)

	self.onResetPasswordRequestDenied = function(listener,errorMsg)
		lobby:RemoveListener("OnResetPasswordRequestDenied", self.onResetPasswordRequestDenied)
		lobby:Disconnect()
		self.txtErrorResetPassword:SetText(
				Configuration:GetErrorColor() ..
				"Password reset request denied: " .. errorMsg
			)
	end

	self.onResetPasswordRequestAccepted = function(listener)
		lobby:RemoveListener("OnResetPasswordRequestAccepted", self.onResetPasswordRequestAccepted)
		lobby:RemoveListener("OnChangeEmailAccepted", self.onChangeEmailAccepted)
		self.txtErrorResetPassword:SetText(
				Configuration:GetSuccessColor() ..
				"Request Accepted, enter email and verification code recieved via email"
			)
	end

	lobby:AddListener("OnResetPasswordRequestDenied", self.onResetPasswordRequestDenied)
	lobby:AddListener("OnResetPasswordRequestAccepted", self.onResetPasswordRequestAccepted)

	function ResetPasswordRequest()
		lobby:ResetPasswordRequest(emailaddress)
		lobby:RemoveListener("OnConnect",ResetPasswordRequest)
		--lobby:RemoveListener("OnConnect",)
	end

	lobby:AddListener("OnConnect",ResetPasswordRequest)

	lobby:AddListener("OnDenied",ResetPasswordRequest)

	WG.Analytics.SendOnetimeEvent("lobby:try_resetpassword")

	self.txtErrorResetPassword:SetText(
		Configuration:GetErrorColor() ..
		"Attempting to send a reset request..."
	)
	Configuration.userName = false --nuke username so we dont try to log in unsuccessfully
	lobby:Connect(Configuration:GetServerAddress(), Configuration:GetServerPort(), nil, nil, 3, nil, GetLobbyName())

end


function LoginWindow:tryResetPasswordVerification ()
	if  lobby:GetConnectionStatus() == "connected" then
		self.txtErrorResetPassword:SetText("Already connected, why do need to reset your password?")
		return false
	end

	local emailaddress = self.ebResetPasswordEmail.text
	if string.len(emailaddress) < 5 then
		self.txtErrorResetPassword:SetText(
		Configuration:GetErrorColor() ..
		"Enter a valid email address, not " .. emailaddress
		)
		return false
	end

	local verificationCode = self.ebResetPasswordVerification.text
	if string.len(verificationCode) < 3 then
		self.txtErrorResetPassword:SetText(
			Configuration:GetErrorColor() ..
			"Verification code too short: " .. verificationCode
			)
		return false
	end

	self.onResetPasswordDenied = function(listener,errorMsg)
		lobby:RemoveListener("OnResetPasswordDenied", self.onResetPasswordDenied)
		lobby:Disconnect()
		self.txtErrorResetPassword:SetText(
				Configuration:GetErrorColor() ..
				"Reset Password Denied: " .. errorMsg
			)
	end

	self.onResetPasswordAccepted = function(listener)
		lobby:RemoveListener("OnResetPasswordAccepted", self.onResetPasswordAccepted)
		self.txtErrorResetPassword:SetText(
				Configuration:GetSuccessColor() ..
				"Password successfully reset for " .. self.ebResetPasswordEmail.text
			)
	end

	self.txtErrorResetPassword:SetText(
		Configuration:GetWarningColor() ..
		"Sending Verification Code: " .. verificationCode .. " for ".. emailaddress
	)
	lobby:AddListener("OnResetPasswordDenied", self.onResetPasswordDenied)
	lobby:AddListener("OnResetPasswordAccepted", self.onResetPasswordAccepted)

	function ResetPassword()
		lobby:ResetPassword(emailaddress,verificationCode)
		lobby:RemoveListener("OnConnect",ResetPassword)
		--lobby:RemoveListener("OnConnect",)
	end

	lobby:AddListener("OnConnect",ResetPassword)

	lobby:AddListener("OnDenied",ResetPassword)

	WG.Analytics.SendOnetimeEvent("lobby:try_resetpasswordverification")

	Configuration.userName = false --nuke username so we dont try to log in unsuccessfully
	lobby:Connect(Configuration:GetServerAddress(), Configuration:GetServerPort(), nil, nil, 3, nil, GetLobbyName())
end


------------------ Change Password --------------

function LoginWindow:tryChangePassword()
	Spring.Echo("lobby:GetConnectionStatus()",lobby:GetConnectionStatus())
	if lobby:GetConnectionStatus() ~= "connected" then
		self.txtErrorChangePassword:SetText(
			Configuration:GetErrorColor() ..
			"Must be connected to change password!"
		)
		return
	end

	local oldPassword = (self.ebChangePasswordOld.text and string.len(self.ebChangePasswordOld.text) > 0 and VFS.CalculateHash(self.ebChangePasswordOld.text, 0)) or nil
	local newPassword =  (self.ebChangePasswordNew.text and string.len(self.ebChangePasswordNew.text) > 0 and VFS.CalculateHash(self.ebChangePasswordNew.text, 0)) or nil

	if oldPassword == nil or newPassword == nil then
		self.txtErrorChangePassword:SetText(
			Configuration:GetErrorColor() ..
			"At least one password is invalid!"
		)
	end

	WG.Analytics.SendOnetimeEvent("lobby:try_changepassword")
	lobby:ChangePassword(oldPassword, newPassword)

	self.txtErrorChangePassword:SetText(
		Configuration:GetWarningColor() ..
		"Password change request sent, you will be logged out if it succeeds"
	)
end



-----------------  OnConnected ----------------------


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
