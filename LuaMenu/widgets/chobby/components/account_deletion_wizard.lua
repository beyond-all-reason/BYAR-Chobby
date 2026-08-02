AccountDeletionWizard = LCS.class {}

function AccountDeletionWizard:init(username)
	self.username = username
	self.currentStep = 1
	self.window = nil

	if WG.LimitFps and WG.LimitFps.ForceRedrawPeriod then
		WG.LimitFps.ForceRedrawPeriod(0.3)
	end

	self:CreateWindow()
	self:ShowStep1()
end

function AccountDeletionWizard:CreateWindow()
	local windowWidth = 650
	local windowHeight = 500
	local screenWidth = screen0.width
	local screenHeight = screen0.height

	local x = (screenWidth - windowWidth) / 2
	local y = (screenHeight - windowHeight) / 2

	self.window = Window:New {
		x = x,
		y = y,
		width = windowWidth,
		height = windowHeight,
		resizable = false,
		draggable = false,
		parent = (WG.Chobby and WG.Chobby.lobbyInterfaceHolder) or nil,
		classname = "main_window_small",
	}
end

function AccountDeletionWizard:ShowStep1()
	self.currentStep = 1
	self.window:ClearChildren()

	local warningText = TextBox:New {
		x = 15,
		right = 15,
		y = 15,
		height = 300,
		objectOverrideFont = (WG.Chobby and WG.Chobby.Configuration and WG.Chobby.Configuration:GetFont(2)) or nil,
		objectOverrideHintFont = (WG.Chobby and WG.Chobby.Configuration and WG.Chobby.Configuration:GetFont(2)) or nil,
		text = i18n("delete_account_warning_text"),
		parent = self.window,
	}

	local btnCancel = Button:New {
		x = 15,
		width = 135,
		bottom = 15,
		height = 70,
		caption = i18n("delete_account_cancel"),
		objectOverrideFont = (WG.Chobby and WG.Chobby.Configuration and WG.Chobby.Configuration:GetFont(3)) or nil,
		classname = "negative_button",
		OnClick = {
			function()
				self:Dispose()
			end
		},
		parent = self.window,
	}

	local btnContinue = Button:New {
		right = 15,
		width = 185,
		bottom = 15,
		height = 70,
		caption = i18n("delete_account_continue"),
		objectOverrideFont = (WG.Chobby and WG.Chobby.Configuration and WG.Chobby.Configuration:GetFont(3)) or nil,
		classname = "action_button",
		OnClick = {
			function()
				self:ShowStep2()
			end
		},
		parent = self.window,
	}

	screen0:FocusControl(btnCancel)
end

function AccountDeletionWizard:ShowStep2()
	self.currentStep = 2
	self.window:ClearChildren()

	local promptText = TextBox:New {
		x = 15,
		right = 15,
		y = 15,
		height = 40,
		objectOverrideFont = (WG.Chobby and WG.Chobby.Configuration and WG.Chobby.Configuration:GetFont(2)) or nil,
		objectOverrideHintFont = (WG.Chobby and WG.Chobby.Configuration and WG.Chobby.Configuration:GetFont(2)) or nil,
		text = i18n("delete_account_confirm_prompt") .. " " .. self.username,
		parent = self.window,
	}

	local ebConfirm = EditBox:New {
		x = 15,
		right = 15,
		y = 60,
		height = 40,
		text = "",
		objectOverrideFont = (WG.Chobby and WG.Chobby.Configuration and WG.Chobby.Configuration:GetFont(2)) or nil,
		parent = self.window,
		OnKeyPress = {
			function(obj, key, mods, isRepeat, label, unicode)
				if key == Spring.GetKeyCode("enter") then
					if obj.text == self.username then
						self:RequestDeletion()
					else
						WG.Delay(function() -- stupid hack to stop the popup from instant closing
							WG.Chobby.InformationPopup(i18n("delete_account_username_error"),
								{
									closeFunc = function()
										obj.text = ""
										screen0:FocusControl(obj)
									end,
								})
						end, 0.01)
					end
				elseif key == Spring.GetKeyCode("esc") then
					self:Dispose()
				end
			end
		},
	}

	local btnConfirm = Button:New {
		right = 15,
		width = 185,
		bottom = 15,
		height = 70,
		caption = i18n("delete_account_confirm_button"),
		objectOverrideFont = (WG.Chobby and WG.Chobby.Configuration and WG.Chobby.Configuration:GetFont(3)) or nil,
		classname = "action_button",
		OnClick = {
			function()
				if ebConfirm.text == self.username then
					self:RequestDeletion()
				else
					WG.Chobby.InformationPopup(i18n("delete_account_username_error"),
						{
							closeFunc = function()
								ebConfirm.text = ""
								screen0:FocusControl(ebConfirm)
							end,
						}
					)
				end
			end
		},
		parent = self.window,
		enabled = false,
	}

	local btnCancel = Button:New {
		x = 15,
		width = 135,
		bottom = 15,
		height = 70,
		caption = i18n("delete_account_cancel"),
		objectOverrideFont = (WG.Chobby and WG.Chobby.Configuration and WG.Chobby.Configuration:GetFont(3)) or nil,
		classname = "negative_button",
		OnClick = {
			function()
				self:Dispose()
			end
		},
		parent = self.window,
	}

	-- Enable confirm button only when text matches username
	ebConfirm.OnFocusUpdate = {
		function(obj)
			btnConfirm.enabled = (obj.text == self.username)
			btnConfirm:Invalidate()
		end
	}

	screen0:FocusControl(ebConfirm)
end

function AccountDeletionWizard:RequestDeletion()
	-- Placeholder for server communication
	-- Will be implemented based on teiserver decision
	local success = self:RequestAccountDeletion()

	if success then
		self:ShowStep3()
	else
		self:ShowError()
	end
end

function AccountDeletionWizard:RequestAccountDeletion()
	-- TODO: Implement actual server communication based on teiserver decision
	-- Option A: Request token from server and open browser to deletion page
	-- Option B: Send Spring protocol command (e.g., c.user.request_deletion)

	-- Placeholder implementation for UI testing
	-- This will be replaced with actual server communication
	local success = true

	-- Example of how it might look with Spring protocol:
	-- if lobby then
	-- 	lobby:AddListener("OnAccountDeletionRequested", function(listener, success, message)
	-- 		if success then
	-- 			self:ShowStep3()
	-- 		else
	-- 			self:ShowError(message)
	-- 		end
	-- 	end)
	-- 	lobby:RequestAccountDeletion()
	-- else
	-- 	success = false
	-- end

	return success
end

function AccountDeletionWizard:ShowStep3()
	self.currentStep = 3
	self.window:ClearChildren()

	local successText = TextBox:New {
		x = 15,
		right = 15,
		y = 15,
		height = 300,
		objectOverrideFont = (WG.Chobby and WG.Chobby.Configuration and WG.Chobby.Configuration:GetFont(2)) or nil,
		objectOverrideHintFont = (WG.Chobby and WG.Chobby.Configuration and WG.Chobby.Configuration:GetFont(2)) or nil,
		text = i18n("delete_account_success"),
		parent = self.window,
	}

	-- Auto-logout after delay
	WG.Delay(function()
		if lobby then
			lobby:Disconnect()
		end
	end, 3)

	local btnClose = Button:New {
		right = 15,
		width = 135,
		bottom = 15,
		height = 70,
		caption = i18n("close"),
		objectOverrideFont = (WG.Chobby and WG.Chobby.Configuration and WG.Chobby.Configuration:GetFont(3)) or nil,
		classname = "negative_button",
		OnClick = {
			function()
				self:Dispose()
			end
		},
		parent = self.window,
	}
end

function AccountDeletionWizard:ShowError()
	self.window:ClearChildren()

	local errorText = TextBox:New {
		x = 15,
		right = 15,
		y = 15,
		height = 300,
		objectOverrideFont = (WG.Chobby and WG.Chobby.Configuration and WG.Chobby.Configuration:GetFont(2)) or nil,
		objectOverrideHintFont = (WG.Chobby and WG.Chobby.Configuration and WG.Chobby.Configuration:GetFont(2)) or nil,
		text = i18n("delete_account_error"),
		parent = self.window,
	}

	local btnClose = Button:New {
		right = 15,
		width = 135,
		bottom = 15,
		height = 70,
		caption = i18n("close"),
		objectOverrideFont = (WG.Chobby and WG.Chobby.Configuration and WG.Chobby.Configuration:GetFont(3)) or nil,
		classname = "negative_button",
		OnClick = {
			function()
				self:Dispose()
			end
		},
		parent = self.window,
	}
end

function AccountDeletionWizard:Dispose()
	if self.window then
		self.window:Dispose()
		self.window = nil
	end
end
