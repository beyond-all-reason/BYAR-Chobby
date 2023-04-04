TeamWindow = LCS.class{}

function TeamWindow:init()
	self.btnInvitePlayer = Button:New {
		caption = i18n("invite_player"),
		width = 150,
		y = 80,
		x = "40%",
		height = 40,
		OnClick = { function()
			self:CreateInvitePlayerWindow()
		end },
	}

	lobby:AddListener("OnJoinedTeam",
		function(listner, ...)
			self:OnJoinedTeam(...)
		end
	)

	lobby:AddListener("OnJoinTeam",
		function(listner, ...)
			self:OnJoinTeam(...)
		end
	)

	lobby:AddListener("OnLeftTeam",
		function(listner, ...)
			self:OnLeftTeam(...)
		end
	)

	lobby:AddListener("OnInviteTeamDeclined",
		function(listner, ...)
			self:OnInviteTeamDeclined(...)
		end
	)

	lobby:AddListener("OnInviteTeam",
		function(listner, ...)
			self:OnInviteTeam(...)
		end
	)

	lobby:AddListener("OnSetTeamLeader",
		function(listner, ...)
			self:OnSetTeamLeader(...)
		end
	)

	-- team chat
	lobby:AddListener("OnSaidTeam",
		function(listener, userName, msg)
			if self.teamConsole ~= nil then
				self.teamConsole:AddMessage(msg, userName)
			end
		end
	)
	lobby:AddListener("OnSaidTeamEx",
		function(listener, userName, msg)
			if self.teamConsole ~= nil then
				self.teamConsole:AddMessage(msg, userName, nil, Configuration.meColor, true)
			end
		end
	)

	self.window = Window:New {
		right = 0,
		width = "39%",
		y = 60,
		bottom = 510,
		height = 500,
		parent = WG.Chobby.lobbyInterfaceHolder,
		caption = i18n("team"),
		resizable = false,
		draggable = false,
		padding = {5, 0, 5, 0},
		children = {
			self.btnInvitePlayer,
		}
	}
end

function TeamWindow:CreateInvitePlayerWindow()
	local ebPlayerName = EditBox:New {
		hint = "Player name",
		text = ""
	}
	local window
	window = Window:New {
		caption = i18n("invite_player"),
		parent = WG.Chobby.lobbyInterfaceHolder,
		x = "45%",
		y = "45%",
		width = 200,
		height = 180,
		resizable = false,
		children = {
			StackPanel:New {
				x = 0, y = 0,
				right = 0, bottom = 0,
				children = {
					ebPlayerName,
					Button:New {
						caption = i18n("ok"),
						OnClick = { function()
							local playerName = ebPlayerName.text
							if playerName == "" then
								return
							end
							lobby:InviteTeam(playerName)
							window:Dispose()
						end},
					},
					Button:New {
						caption = i18n("cancel"),
						OnClick = { function()
							window:Dispose()
						end},
					},
				},
			}
		},
	}
end

function TeamWindow:OnInviteTeam(userName)
	window = Window:New {
		caption = i18n("invited_to_team"),
		parent = WG.Chobby.lobbyInterfaceHolder,
		x = "45%",
		y = "45%",
		width = 200,
		height = 180,
		resizable = false,
		children = {
			StackPanel:New {
				x = 0, y = 0,
				right = 0, bottom = 0,
				children = {
					Label:New {
						caption = userName .. i18n("invites_you_to_join_team"),
					},
					Button:New {
						caption = i18n("accept"),
						OnClick = { function()
							lobby:InviteTeamAccept(userName)
							window:Dispose()
						end},
					},
					Button:New {
						caption = i18n("decline"),
						OnClick = { function()
							lobby:InviteTeamDecline(userName)
							window:Dispose()
						end},
					},
				},
			}
		},
	}
end

function TeamWindow:OnJoinedTeam(userName)
--     Chotify:Post({
--         title = i18n("Team"),
--         body = userName .. i18n("joined_team"),
--     })
end

function TeamWindow:OnJoinTeam()
--     Chotify:Post({
--         title = i18n("Team"),
--         body = i18n("join_team"),
--     })
	self.btnInvitePlayer:Hide()
	self:ShowTeamConsole()
end

function TeamWindow:OnLeftTeam(userName, reason)
	if reason ~= nil then
		reason = ": " .. reason
	else
		reason = ""
	end
	if userName == lobby:GetMyUserName() then
		self.btnInvitePlayer:Show()
		Chotify:Post({
			title = i18n("Team"),
			body = i18n("self_left_team") .. reason,
		})
		for _, child in pairs(self.teamPanel) do
			child:Hide()
		end
	else
		Chotify:Post({
			title = i18n("Team"),
			body = userName .. i18n("left_team") .. reason,
		})
	end
end

function TeamWindow:OnInviteTeamDeclined(userName)
	Chotify:Post({
		title = i18n("Team"),
		body = userName .. i18n("declined_invite_team"),
	})
end

function TeamWindow:UpdateTeamLeader()
	if lobby:GetTeam() ~= nil and lobby:GetTeam().leader == lobby:GetMyUserName() then
		self.btnInviteTeam.children[1].file = CHOBBY_IMG_DIR .. "add_friend.png"
		self.btnInviteTeam.OnClick = { function()
			self:CreateInvitePlayerWindow()
		end}
	else
		self.btnInviteTeam.children[1].file = CHOBBY_IMG_DIR .. "add_friend_off.png"
		self.btnInviteTeam.OnClick = {}
	end
	self.btnInviteTeam:Invalidate()
end

function TeamWindow:MakeTeamConsole()
	self.teamConsole = Console()

	self.teamConsole.listener = function(message)
		lobby:SayTeam(message)
	end

	self.userListPanel = UserListPanel()

	self.btnInviteTeam = Button:New {
		x = 4,
		width = 36,
		height = 36,
		y = 4,
		caption = '',
		padding = {0, 0, 0, 0},
		itemPadding = {0, 0, 0, 0},
		borderThickness = 0,
		backgroundColor = {0, 0, 0, 0},
		focusColor      = {0.4, 0.4, 0.4, 1},
		children = {
			Image:New {
				x = 4,
				y = 4,
				width = 28,
				height = 28,
				margin = {0, 0, 0, 0},
			},
		},
	}

	self.btnLeaveTeam = Button:New {
		x = 90,
		width = 36,
		height = 36,
		y = 4,
		caption = '',
		padding = {0, 0, 0, 0},
		itemPadding = {0, 0, 0, 0},
		borderThickness = 0,
		backgroundColor = {0, 0, 0, 0},
		focusColor      = {0.4, 0.4, 0.4, 1},
		children = {
			Image:New {
				x = 4,
				y = 4,
				width = 28,
				height = 28,
				margin = {0, 0, 0, 0},
				file = CHOBBY_IMG_DIR .. "download.png"
			},
		},
		OnClick = { function()
			lobby:LeaveTeam()
		end},
	}

	self.teamPanel = {
		Control:New {
			x = 0, y = 40, right = 145, bottom = 10,
			padding={0,0,0,0}, itemPadding={0,0,0,0}, itemMargin={0,0,0,0},
			children = { self.teamConsole.panel, },
		},
		Control:New {
			width = 144, y = 40, right = 0, bottom = 10,
			padding={0,0,0,0}, itemPadding={0,0,0,0}, itemMargin={0,0,0,0},
			children = { self.userListPanel.panel, },
		},
		self.btnInviteTeam,
		self.btnLeaveTeam,
	}
end

function TeamWindow:ShowTeamConsole()
	if self.teamPanel == nil then
		self:MakeTeamConsole()
	else
		for _, child in pairs(self.teamPanel) do
			child:Show()
		end
	end

	self:UpdateTeamLeader()
	for _, child in pairs(self.teamPanel) do
		self.window:AddChild(child)
	end
end
