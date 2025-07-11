ChatWindows = LCS.class{}

function ChatWindows:init()
	self.channelConsoles = {}
	self.userListPanels = {}
	self.tabbars = {}
	self.currentTab = false
	self.storedCurrentTab = false
	self.totalNewMessages = 0

	self.visible = false

	-- setup debug console to listen to commands
	self:CreateDebugConsole()

	lobby:AddListener("OnJoin",
		function(listener, chanName)
			local channelConsole = self:GetChannelConsole(chanName)
		end
	)

	lobby:AddListener("OnChannelTopic",
		function(listener, chanName, author, changedTime, topic)
			local channelConsole = self:GetChannelConsole(chanName)
			if channelConsole ~= nil then
				if self:IsChannelSelected(chanName) and self.activeUnreadMessages and self.activeUnreadMessages ~= 0 then
					self.activeUnreadMessages = self.activeUnreadMessages + 1
				end
				channelConsole:SetTopic(topic)
			end
		end
	)

	self.onJoined = function(listener, chanName, userName)
		if chanName ~= self.currentTab then
			return
		end

		if self.currentTab and self.userListPanels[self.currentTab] then
			self.userListPanels[self.currentTab]:OnJoined(userName)
		end
	end
	lobby:AddListener("OnJoined", self.onJoined)

	self.onLeft = function(listener, chanName, userName)
		if chanName ~= self.currentTab then
			return
		end

		if self.currentTab and self.userListPanels[self.currentTab] then
			self.userListPanels[self.currentTab]:OnLeft(userName)
		end
	end
	lobby:AddListener("OnLeft", self.onLeft)

	self.onClients = function(listener, chanName, clients)
		if self.currentTab and self.userListPanels[self.currentTab] then
			self.userListPanels[self.currentTab]:Update()
		end
	end
	lobby:AddListener("OnClients", self.onClients)

	self.onUserCount = function(listener)
		if self.currentTab and self.userListPanels[self.currentTab] then
			self.userListPanels[self.currentTab]:UpdateUserCount()
		end
	end
	lobby:AddListener("OnUserCount", self.onUserCount)

	local CHAT_EX_MENTION = "\255\255\0\0"
	local CHAT_MENTION ="\255\255\0\0"

	-- channel chat
	lobby:AddListener("OnSaid",
		function(listener, chanName, userName, message, msgDate, source)
			self:ProcessChat(chanName, userName, message, msgDate, CHAT_MENTION, nil, nil, source)
		end
	)
	lobby:AddListener("OnSaidEx",
		function(listener, chanName, userName, message, msgDate)
			self:ProcessChat(chanName, userName, message, msgDate, CHAT_EX_MENTION, Configuration.meColor, true)
		end
	)

	-- private chat
	self.privateChatConsoles = {}
	lobby:AddListener("OnSayPrivate",
		function(listener, userName, message, msgDate)
			local privateChatConsole = self:GetPrivateChatConsole(userName)
			if self:IsChannelSelected(userName .. " messages") and self.activeUnreadMessages and self.activeUnreadMessages ~= 0 then
				self.activeUnreadMessages = self.activeUnreadMessages + 1
			end
			privateChatConsole:AddMessage(message, lobby:GetMyUserName(), msgDate)
		end
	)
	lobby:AddListener("OnSayPrivateEx",
		function(listener, userName, message, msgDate)
			local privateChatConsole = self:GetPrivateChatConsole(userName)
			if self:IsChannelSelected(userName .. " messages") and self.activeUnreadMessages and self.activeUnreadMessages ~= 0 then
				self.activeUnreadMessages = self.activeUnreadMessages + 1
			end
			privateChatConsole:AddMessage(message, lobby:GetMyUserName(), msgDate, nil, true)
		end
	)
	lobby:AddListener("OnSaidPrivate",
		function(listener, userName, message, msgDate)
			local chanName = userName .. " messages"
			local privateChatConsole = self:GetPrivateChatConsole(userName)
			if self:IsChannelSelected(chanName) and self.activeUnreadMessages and self.activeUnreadMessages ~= 0 then
				self.activeUnreadMessages = self.activeUnreadMessages + 1
			end
			privateChatConsole:AddMessage(message, userName, msgDate)
			if userName == 'Coordinator' then
				message = message and message:gsub("#", "")
				if message == "" or nil then
					return
				end
			end
			self:_NotifyTab(chanName, userName, "Private", true, message, "sounds/beep4.wav", 15)
		end
	)
	lobby:AddListener("OnSaidPrivateEx",
		function(listener, userName, message, msgDate)
			local chanName = userName .. " messages"
			local privateChatConsole = self:GetPrivateChatConsole(userName)
			if self:IsChannelSelected(chanName) and self.activeUnreadMessages and self.activeUnreadMessages ~= 0 then
				self.activeUnreadMessages = self.activeUnreadMessages + 1
			end
			privateChatConsole:AddMessage(message, userName, msgDate, Configuration.meColor, true)
			self:_NotifyTab(chanName, userName, "Private", true, message, "sounds/beep4.wav", 15)
		end
	)
	lobby:AddListener("OnRemoveUser",
		function(listener, userName)
			local chanName = userName .. " messages"
			local privateChatConsole = self.privateChatConsoles[chanName]
			if privateChatConsole ~= nil then
				if self:IsChannelSelected(chanName) and self.activeUnreadMessages and self.activeUnreadMessages ~= 0 then
					self.activeUnreadMessages = self.activeUnreadMessages + 1
				end
				privateChatConsole:AddMessage(userName .. " is now offline", nil, nil, Configuration.meColor, true)
			end
		end
	)
	lobby:AddListener("OnAddUser",
		function(listener, userName)
			local chanName = userName .. " messages"
			local privateChatConsole = self.privateChatConsoles[chanName]
			if privateChatConsole ~= nil then
				if self:IsChannelSelected(chanName) and self.activeUnreadMessages and self.activeUnreadMessages ~= 0 then
					self.activeUnreadMessages = self.activeUnreadMessages + 1
				end
				privateChatConsole:AddMessage(userName .. " just got online", nil, nil, Configuration.meColor, true)
			end
		end
	)

	self.oldChatLine = Line:New {
		classname = "lineStandOut",
		x = 0,
		right = 0,
		height = 3,
	}

	self.serverPanel = ScrollPanel:New {
		x = 0,
		right = 5,
		y = 0,
		height = "100%",
	}

	self.tabPanel = Chili.DetachableTabPanel:New {
		x = 7,
		right = 7,
		y = 0,
		bottom = 9,
		padding = {0, 0, 0, 0},
		minTabWidth = 90,
		tabs = {
			[1] = (Configuration.debugMode and { name = "debug", caption = i18n("debug"), children = {
					self.debugConsole.panel}, objectOverrideFont = WG.Chobby.Configuration:GetFont(1)}) or nil,
			--{ name = "server", caption = i18n("server"), children = {self.serverPanel} },
		},
		OnTabChange = {
			function(obj, name)
				self.currentTab = name
				if self.userListPanels[self.currentTab] then
					self.userListPanels[self.currentTab]:Update()
					self.userListPanels[self.currentTab]:UpdateUserCount()
				end
				local console = self.tabbars[name]
				if console then
					self.activeUnreadMessages = console.unreadMessages
					self:UpdateOldChatLinePosition(console)

					self.totalNewMessages = self.totalNewMessages - console.unreadMessages
					interfaceRoot.GetRightPanelHandler().SetActivity("chat", self.totalNewMessages)
					console.unreadMessages = 0
					self:SetTabBadge(name, "")
					self:SetTabActivation(name, false)
					WG.Delay(function()
						screen0:FocusControl(console.ebInputText)
					end, 0.01)
				end
			end
		}
	}
	self.tabPanel.tabBar:DisableHighlight()

	self.tabBarFudgeHolder = Control:New {
		name = "fudgeControl",
		x = 0,
		y = 0,
		width = 100,
		bottom = 0,
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
		children = {
			self.tabPanel.tabBar
		}
	}

	self.tabScrollPanel = ScrollPanel:New {
		x = 0,
		right = 0,
		y = 0,
		bottom = 0,
		padding = {0,0,0,0},
		borderColor = {0,0,0,0},
		backgroundColor = {0,0,0,0},
		verticalScrollbar = false,
		parent = window,
		scrollbarSize = 11,
		children = {
			self.tabBarFudgeHolder
		}
	}

	self.tabBarHolder = Control:New {
		name = "tabBarHolder",
		x = 0,
		y = 0,
		width = "100%",
		height = 50,
		resizable = false,
		draggable = false,
		padding = {0, 10, 0, 0},
		children = {
			self.tabScrollPanel
		}
	}

	self.joinButton = Button:New {
		x = 2000,
		y = 5,
		width = 30,
		height = 30,
		parent = self.tabScrollPanel,
		caption = "+",
		classname = "button_small",
		OnClick = {
			function()
				if self.joinWindow == nil then
					self:CreateJoinChannelWindow()
				end
			end
		},
	}

	self.tabBarHolder:BringToFront()

	self.chatWindow = Control:New {
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		caption = i18n("chat"),
		resizable = false,
		draggable = false,
		padding = {5, 0, 5, 0},
		children = {
			self.tabPanel,
			self.tabBarHolder,
		},
	}

	self.window = Control:New {
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
		OnOrphan = {
			function (obj)
				self.storedCurrentTab = self.currentTab
				self.currentTab = false
				self.tabPanel.tabBar:DisableHighlight()
				self.visible = false
			end
		},
		OnParent = {
			function (obj)
				if self.storedCurrentTab then
					self.tabPanel:CallListeners(self.tabPanel.OnTabChange, self.storedCurrentTab)
				end
				interfaceRoot.GetRightPanelHandler().SetActivity("chat")
				self.tabPanel.tabBar:EnableHighlight()
				self.visible = true
			end
		},
	}

	self.loginButton = Button:New {
		x = "15%",
		y = "45%",
		width = "70%",
		height = "10%",
		caption = i18n("login_to_chat"),
		classname = "button_small",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		parent = self.window,
		OnClick = {function ()
				Spring.Echo("Login")
				WG.LoginWindowHandler.TryLogin()
			end
		}
	}

	local function onConfigurationChange(listener, key, value)
		if key == "debugMode" then
			if value and not self.tabPanel:GetTab("debug") then
				self.ignoreTabClick = true
				self.tabPanel:AddTab(
					{
						name = "debug",
						caption = i18n("debug"),
						objectOverrideFont = WG.Chobby.Configuration:GetFont(1),
						children = {self.debugConsole.panel}
					},
					false
				)
				if not self.window.parent then
					self.tabPanel.tabBar:DisableHighlight()
				end
				self.ignoreTabClick = false
				self:UpdateJoinPosition()
			end
			if (not value) and self.tabPanel:GetTab("debug") then
				self.tabPanel:RemoveTab("debug", false)
				self:UpdateJoinPosition()
			end
		end
	end
	Configuration:AddListener("OnConfigurationChange", onConfigurationChange)

	lobby:AddListener("OnDisconnected",
		function ()
			if self.tabPanel.tabBar.visible then
			--	self.tabPanel.tabBar:Hide()
			--	self.joinButton:Hide()
			end

			-- self.window:ClearChildren()
			-- self.window:AddChild(self.loginButton)
			-- Instead of showing this, how about disabling the text entry boxen with "Login required for chat"
			-- The point being that they need to be enabled again :D
			
			for chanName, channelConsole in pairs(self.channelConsoles) do
				if channelConsole.ebInputText then
					channelConsole.ebInputText.hint = "Login required for chat."
					channelConsole.ebInputText.editable = false
					channelConsole.ebInputText.selectable = false
					channelConsole.ebInputText:Update()
				end
			end

		end
	)

	lobby:AddListener("OnConnect", function ()
			if not self.tabPanel.tabBar.visible then
				self.tabPanel.tabBar:Show()
				self.joinButton:Show()
			end

			for chanName, channelConsole in pairs(self.channelConsoles) do
				if channelConsole.ebInputText then
					channelConsole.ebInputText.hint = ""
					channelConsole.ebInputText.editable = true
					channelConsole.ebInputText.selectable = true
					channelConsole.ebInputText:Update()
				end
			end

			self.window:ClearChildren()
			self.window:AddChild(self.chatWindow)
		end
	)

	if self.tabPanel.tabBar.visible then
		self.tabPanel.tabBar:Hide()
		self.joinButton:Hide()
	end

	self:ReattachTabHolder()
	self:UpdateJoinPosition()
end

function ChatWindows:IsChannelSelected(chanName)
	return self.tabPanel.tabBar:IsSelected(chanName)
end

function ChatWindows:UpdateOldChatLinePosition(console)
	if not (self:IsChannelSelected(console.channelName) and console.tbHistory) then
		return
	end

	if self.oldChatLine.parent then
		self.oldChatLine.parent:RemoveChild(self.oldChatLine)
	end

	if not (self.activeUnreadMessages and self.activeUnreadMessages ~= 0) then
		return
	end
	console.spHistory:AddChild(self.oldChatLine)

	local position = console.tbHistory:GetPhysicalLinePosition(self.activeUnreadMessages) - 6
	self.oldChatLine:SetPos(0, position)
	self.oldChatLine._relativeBounds.right = 0
	self.oldChatLine:UpdateClientArea()
	self.oldChatLine:BringToFront()
end

function ChatWindows:CycleTab(direction)
	local selected = self.tabPanel.tabBar.selected
	local children = self.tabPanel.tabBar.children
	if not (selected and children) then
		return
	end
	selected = (selected + direction - 1)%(#children) + 1
	local child = children[selected]
	if not child then
		return
	end
	self.tabPanel.tabBar:Select(child.name)
end

function ChatWindows:ProcessChat(chanName, userName, message, msgDate, notifyColor, chatColor, thirdPerson, source)
	local channelConsole = self.channelConsoles[chanName]
	if not channelConsole then
		return
	end

	-- When we attempt to process messages that happen while we are disconnected:
	local lobbyUserName = lobby and lobby:GetMyUserName()
	if not lobbyUserName then 
		lobbyUserName = userName
	end
	local iAmMentioned = (string.find(message, lobbyUserName, 1, true) and userName ~= lobbyUserName) -- needs 1, true or brackets will screw it up
	local chatColour = (iAmMentioned and notifyColor) or chatColor
	if self:IsChannelSelected(chanName) and self.activeUnreadMessages and self.activeUnreadMessages ~= 0 then
		self.activeUnreadMessages = self.activeUnreadMessages + 1
	end
	local nameColor
	if source == lobby.SOURCE_DISCORD then
		channelConsole:AddMessage(message, userName, msgDate, chatColour, thirdPerson, "\255\40\210\220", "Discord user.", true)
	else
		channelConsole:AddMessage(message, userName, msgDate, chatColour, thirdPerson, nameColor)
	end
	if iAmMentioned then
		self:_NotifyTab(chanName, userName, chanName, true, message, "sounds/beep4.wav", 15)
	elseif Configuration.notifyForAllChat then
		self:_NotifyTab(chanName, userName, chanName, false)
	end
	-- Spring.Echo("ChatWindows:ProcessChat(chanName, userName, message, msgDate, notifyColor, chatColor, thirdPerson, source)", chanName, userName, message, msgDate, notifyColor, chatColor, thirdPerson, source, "Results: iAmMentioned= ",iAmMentioned, "")
end

function ChatWindows:ReattachTabHolder()
	if not self.chatWindow:GetChildByName(self.tabBarHolder.name) then
		self.chatWindow:AddChild(self.tabBarHolder)
	end
	self.tabBarHolder:SetPos(13,0)
	self.tabBarHolder:BringToFront()
	self.tabBarHolder._relativeBounds.right = 0
	self.tabBarHolder:UpdateClientArea(false)

	self.tabPanel._relativeBounds.top = 50
	self.tabPanel:UpdateClientArea(false)
	self.tabPanel:Invalidate()
end

function ChatWindows:SetTabHolderParent(newParent, newX, newY, newRight)
	if not newParent:GetChildByName(self.tabBarHolder.name) then
		newParent:AddChild(self.tabBarHolder)
	end
	self.tabBarHolder:SetPos(newX, newY)
	self.tabBarHolder:BringToFront()
	self.tabBarHolder._relativeBounds.right = newRight
	self.tabBarHolder:UpdateClientArea(false)

	self.tabPanel._relativeBounds.top = 15
	self.tabPanel:UpdateClientArea(false)
	self.tabPanel:Invalidate()

	self.tabPanel.OnTabClick = {
		function()
			if self.ignoreTabClick then
				return
			end
			local rightPanelHandler = interfaceRoot.GetRightPanelHandler()
			local control, index = rightPanelHandler.GetManagedControlByName(self.window.name)
			rightPanelHandler.OpenTab(index)
		end
	}
end

function ChatWindows:_GetTabBarItem(tabName)
	local tabbar = self.tabPanel.tabBar
	for i=1,#tabbar.children do
		local c = tabbar.children[i]
		if c.name == tabName then
			return c
		end
	end
end

function ChatWindows:SetTabActivation(tabName, activationLevel, outlineColor)
	local ctrl = self:_GetTabBarItem(tabName)
	if not ctrl then
		return
	end

	if activationLevel then
		if (ctrl.activationLevel or 0) > activationLevel then
			return
		end
		ctrl.font = Configuration:GetFont(1, "chat_badge_" .. activationLevel, {
			outline = true,
			outlineColor = outlineColor,
			color = outlineColor,
		})
		if ctrl._badge then
			ctrl._badge.font = Configuration:GetFont(1, "chat_badge_" .. activationLevel, {
				outline = true,
				outlineColor = outlineColor,
				color = outlineColor,
			})
		end
	else
		ctrl.font = Configuration:GetFont(1, "chat_badge_white", {
			outline = true,
			outlineColor = {0,0,0,1},
			color = {1,1,1,1},
		})
	end
	ctrl.activationLevel = activationLevel

	ctrl:Invalidate()
end

function ChatWindows:SetTabBadge(tabName, text)
	local ctrl = self:_GetTabBarItem(tabName)
	if not ctrl then
		Spring.Echo("SetTabBadge missing control", tabName, text)
		return
	end
	local badge = ctrl._badge
	if not ctrl._badge then
		ctrl._badge = Label:New {
			y = -37,
			right = 0,
			width = 14,
			height = 12,
			caption = text,
			objectOverrideFont = WG.Chobby.Configuration:GetFont(1, "chat_badge_black", {
				outline = true,
				autoOutlineColor = false,
				outlineColor = { 0, 0, 0, 0.6 },
			}),
			parent = ctrl
		}
	end

	ctrl._badge:SetCaption(text)
end

function ChatWindows:_NotifyTab(tabName, userName, chanName, nameMentioned, message, sound, popupDuration)
	if tabName ~= self.currentTab then
		-- TODO: Fix naming of self.tabbars (these are consoles)
		if (nameMentioned or chanName == "Private") and WG.Chobby.Configuration.gameConfig.sayPrivateSelectAndActivateChatTab and not WG.Chobby.Configuration.doNotDisturb then
			WG.Chobby.interfaceRoot.OpenRightPanelTab("chat")
			self.tabPanel.tabBar:Select(tabName)
		end
		local console = self.tabbars[tabName]
		local oldMessages = console.unreadMessages
		console.unreadMessages = console.unreadMessages + 1
		self:SetTabBadge(tabName, tostring(console.unreadMessages))
		local mentionNumber = (nameMentioned and 0) or 1
		self:SetTabActivation(tabName, (nameMentioned and 2) or 1, {1, mentionNumber, mentionNumber, 1})
		self.totalNewMessages = self.totalNewMessages + (console.unreadMessages - oldMessages)

		if not self.window.parent then
			interfaceRoot.GetRightPanelHandler().SetActivity("chat", self.totalNewMessages, 2 - mentionNumber)
		end

		if nameMentioned and WG.Chobby.Configuration:AllowNotification(userName) then
			Chotify:Post({
				title = userName .. " in " .. chanName .. ":",
				body = message,
				sound = sound,
				soundVolume = (WG.Chobby.Configuration.menuNotificationVolume or 1)*0.5,
				time = popupDuration,
			})
		end
	end
end

function ChatWindows:SetParent(newParent)
	self.window:SetParent(newParent)
end

function ChatWindows:RedactMessage(msg)
	local sessionPos = string.find(msg, [["SessionToken":"]])
	if sessionPos then
		sessionPos = sessionPos + 15
		local endPos = string.find(msg, [["]], sessionPos + 1)
		if endPos then
			msg = string.sub(msg, 0, sessionPos) .. "REDACTED" .. string.sub(msg, endPos)
		end
	end
	local passwordPos = string.find(msg, [["PasswordHash":"]])
	if passwordPos then
		passwordPos = passwordPos + 15
		local endPos = string.find(msg, [["]], passwordPos + 1)
		if endPos then
			msg = string.sub(msg, 0, passwordPos) .. "REDACTED" .. string.sub(msg, endPos)
		end
	end
	local steamAuthTokenPos = string.find(msg, [["SteamAuthToken":"]])
	if steamAuthTokenPos then
		steamAuthTokenPos = steamAuthTokenPos + 17
		local endPos = string.find(msg, [["]], steamAuthTokenPos + 1)
		if endPos then
			msg = string.sub(msg, 0, steamAuthTokenPos) .. "REDACTED" .. string.sub(msg, endPos)
		end
	end
	local UserIDPos = string.find(msg, [["UserID":"]])
	if UserIDPos then
		UserIDPos = UserIDPos + 9
		local endPos = string.find(msg, [["]], UserIDPos + 1)
		if endPos then
			msg = string.sub(msg, 0, UserIDPos) .. "REDACTED" .. string.sub(msg, endPos)
		end
	end
	return msg
end

function ChatWindows:CreateDebugConsole()
	local function MessageListener(message)
		if message:starts("!") then
			-- simulate receiving a message from the server
			lobby:CommandReceived(message:sub(2))
		else
			lobby:SendCustomCommand(message)
		end
	end
	self.debugConsole = Console(nil, MessageListener)
	self.debugConsole.ebInputText.hint = "Type text here to send commands to server. Prefix with ! to simulate receiving commands from server."
	self.debugConsole.ebInputText.OnKeyPress = self.debugConsole.ebInputText.OnKeyPress or {}
	table.insert(self.debugConsole.ebInputText.OnKeyPress,
		function(obj, key, ...)
			-- allow tabs for the debug window
			if key == 9 then
				obj:TextInput("\t")
			end
		end
	)
	lobby:AddListener("OnCommandReceived",
		function(listner, command)
			command = self:RedactMessage(command)
			if Configuration.activeDebugConsole then
				Spring.Log("ServerMessage", LOG.NOTICE, command)
				self.debugConsole:AddMessage("<--" .. command)
			end
		end
	)
	lobby:AddListener("OnCommandSent",
		function(listner, command)
			command = self:RedactMessage(command)
			if Configuration.activeDebugConsole then
				Spring.Log("ClientMessage", LOG.NOTICE, command)
				self.debugConsole:AddMessage("-->" .. command)
			end
		end
	)
	self.tabbars["Debug"] = self.debugConsole
end

function ChatWindows:UpdateChannels(channelsArray)
	self.serverPanel:ClearChildren()

	self.serverPanel:AddChild(
		Label:New {
			x = 0,
			width = 100,
			y = 0,
			height = 20,
			caption = "#",
		}
	)
	self.serverPanel:AddChild(
		Label:New {
			x = 50,
			width = 100,
			y = 0,
			height = 20,
			caption = i18n("channel"),
		}
	)
	self.serverPanel:AddChild(
		Label:New {
			x = 130,
			width = 100,
			y = 0,
			height = 20,
			caption = i18n("topic") ,
		}
	)
	for i, channel in pairs(channelsArray) do
		self.serverPanel:AddChild(Control:New {
			x = 0,
			width = "100%",
			y = i * 50,
			height = 40,
			children = {
				Label:New {
					x = 0,
					width = 100,
					y = 5,
					height = 20,
					caption = channel.userCount,
				},
				Label:New {
					x = 50,
					width = 100,
					y = 5,
					height = 20,
					caption = channel.chanName,
				},
				Button:New {
					x = 130,
					width = 60,
					y = 0,
					height = 30,
					caption = i18n("join"),
					OnClick = {
						function()
							lobby:Join(channel.chanName)
						end
					},
				},
			}
		})
	end
end

function ChatWindows:UpdateJoinPosition()
	self.joinButton:SetPos(#self.tabPanel.tabBar.children * 90 + 10)
	self.tabBarFudgeHolder:SetPos(nil, nil, #self.tabPanel.tabBar.children * 90 + 5)
end

function ChatWindows:GetChannelConsole(chanName)
	if string.find(chanName, "debriefing") then
		return false
	end
	local channelConsole = self.channelConsoles[chanName]

	if channelConsole == nil then
		local function MessageListener(message)
			if message:starts("/me ") then
				lobby:SayEx(chanName, message:sub(5))
			else
				lobby:Say(chanName, message)
			end
		end
		local function Resize(obj)
			self:UpdateOldChatLinePosition(obj)
		end
		channelConsole = Console(chanName, MessageListener, nil, Resize, false)
		self.channelConsoles[chanName] = channelConsole

		Configuration.channels[chanName] = true

		local userListPanel
		if chanName == 'main' or chanName == 'newbies' then
			-- keep it nil like scum
			-- userListPanel = UserListPanel(function() return {}  end, 22, true)
		else
			userListPanel = UserListPanel(function() return lobby:GetChannel(chanName) end, 22, true, nil, chanName)
		end
		self.userListPanels[chanName] = userListPanel
		local caption = "#" .. chanName
		local tooltip = nil
		local origCaption = caption
		local fontSize = 1
		caption = StringUtilities.GetTruncatedStringWithDotDot(caption, Configuration:GetFont(fontSize), 86)
		if origCaption ~= caption then
			tooltip = origCaption
		end

		local closeChannelButton = Button:New {
			width = 24, height = 24, y = 5, right = Configuration.userListWidth + 18,
			caption = "x",
			objectOverrideFont = WG.Chobby.Configuration:GetFont(1),
			classname = "button_small",
			OnClick = {
				function()
					self.channelConsoles[chanName] = nil
					lobby:Leave(chanName)
					Configuration.channels[chanName] = nil
					self.tabPanel:RemoveTab(chanName, true)
					self:UpdateJoinPosition()
				end
			},
		}

		self.ignoreTabClick = true
		if chanName == "main" or chanName == "newbies" then
			self.tabPanel:AddTab(
				{
					name = chanName,
					caption = caption,
					objectOverrideFont = WG.Chobby.Configuration:GetFont(fontSize),
					tooltip = tooltip,
					children = {
						Control:New {
							x = 0, y = 0, right = 0, bottom = 0,
							padding={0,0,0,0}, itemPadding={0,0,0,0}, itemMargin={0,0,0,0},
							children = { channelConsole.panel, },
						},
						--closeChannelButton,
					}
				},
				false
			)
		else
			self.tabPanel:AddTab(
				{
					name = chanName,
					caption = caption,
					objectOverrideFont = WG.Chobby.Configuration:GetFont(fontSize),
					tooltip = tooltip,
					children = {
						Control:New {
							x = 0, y = 0, right = Configuration.userListWidth, bottom = 0,
							padding={0,0,0,0}, itemPadding={0,0,0,0}, itemMargin={0,0,0,0},
							children = { channelConsole.panel, },
						},
						Control:New {
							width = Configuration.userListWidth, y = 0, right = 0, bottom = 0,
							padding={0,0,0,7}, itemPadding={0,0,0,0}, itemMargin={0,0,0,0},
							children = { userListPanel.panel, },
						},
						closeChannelButton,
					}
				},
				false
			)
		end


		closeChannelButton:BringToFront()

		if not self.window.parent then
			self.tabPanel.tabBar:DisableHighlight()
		end
		self.ignoreTabClick = false
		self.tabbars[chanName] = channelConsole
		self:UpdateJoinPosition()

		if self.switchToTabOnJoin and self.switchToTabOnJoin == chanName then
			self.tabPanel.tabBar:Select(chanName)
			self.switchToTabOnJoin = false
		end
	end

	return channelConsole
end

function ChatWindows:GetPrivateChatConsole(userName, switchTo)
	local chanName = userName .. " messages"
	local privateChatConsole = self.privateChatConsoles[chanName]

	if privateChatConsole == nil then
		local function MessageListener(message)
			if message:starts("/me ") then
				lobby:SayPrivateEx(userName, message:sub(5))
			else
				lobby:SayPrivate(userName, message)
			end
		end
		local function Resize(obj)
			self:UpdateOldChatLinePosition(obj)
		end
		
		local monospaced = userName ~= "Coordinator" and lobby.users[userName] and lobby.users[userName].isBot
		privateChatConsole = Console(chanName, MessageListener, nil, Resize, false, monospaced)
		self.privateChatConsoles[chanName] = privateChatConsole

		local caption = "@" .. userName
		local tooltip = nil
		local origCaption = caption
		local fontSize = 1
		caption = StringUtilities.GetTruncatedStringWithDotDot(caption, Configuration:GetFont(fontSize), 86)
		if origCaption ~= caption then
			tooltip = origCaption
		end

		local closeChannelButton = Button:New {
			width = 24, height = 24, y = 5, right = 18,
			objectOverrideFont = WG.Chobby.Configuration:GetFont(10),
			caption = "x",
			OnClick = {
				function()
					self.privateChatConsoles[chanName] = nil
					self.tabPanel:RemoveTab(chanName, true)
					self:UpdateJoinPosition()
				end
			},
		}

		self.ignoreTabClick = true
		self.tabPanel:AddTab(
			{
				name = chanName,
				caption = caption,
				tooltip = tooltip,
				objectOverrideFont = WG.Chobby.Configuration:GetFont(fontSize),
				children = {
					privateChatConsole.panel,
					closeChannelButton
				}
			},
			true
		)

		closeChannelButton:BringToFront()

		if not self.window.parent then
			self.tabPanel.tabBar:DisableHighlight()
		end
		self.ignoreTabClick = false
		self.tabbars[chanName] = privateChatConsole

		self:UpdateJoinPosition()
	end

	if switchTo then
		self.tabPanel.tabBar:Select(chanName)
	end
	return privateChatConsole
end

function ChatWindows:CreateJoinChannelWindow()
	self.joinWindow = Window:New {
		caption = "",
		name = "hostBattle",
		parent = WG.Chobby.lobbyInterfaceHolder,
		width = 318,
		height = 216,
		resizable = false,
		draggable = false,
		classname = "main_window",
	}

	local title = Label:New {
		x = 15,
		width = 252,
		align = "center",
		y = 5,
		height = 35,
		caption = i18n("join_channel"),
		objectOverrideFont = WG.Chobby.Configuration:GetFont(5),
		parent = self.joinWindow,
	}

	local channelEdit = EditBox:New {
		x = 3,
		right = 3,
		y = 66,
		height = 35,
		text = "",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		objectOverrideHintFont = WG.Chobby.Configuration:GetFont(3),
		parent = self.joinWindow,
	}

	local function CancelFunc()
		self.joinWindow:Dispose()
		self.joinWindow = nil
	end

	local function JoinChannel()
		local channelName = channelEdit.text:gsub("#", "")
		if channelName ~= "" then
			lobby:Join(channelName)
			self.switchToTabOnJoin = channelEdit.text
		end
		self.joinWindow:Dispose()
		self.joinWindow = nil
	end

	local buttonJoin = Button:New {
		right = 150,
		width = 135,
		bottom = 1,
		height = 70,
		caption = i18n("join"),
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		parent = self.joinWindow,
		classname = "action_button",
		OnClick = {
			function()
				JoinChannel()
			end
		},
	}

	local buttonCancel = Button:New {
		right = 1,
		width = 135,
		bottom = 1,
		height = 70,
		caption = i18n("cancel"),
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		parent = self.joinWindow,
		classname = "negative_button",
		OnClick = {
			function()
				CancelFunc()
			end
		},
	}

	local popupHolder = PriorityPopup(self.joinWindow, CancelFunc, JoinChannel)
	screen0:FocusControl(channelEdit)
end

function ChatWindows:ClearHistory()
	if self.debugConsole then
		self.debugConsole:ClearHistory()
	end
	for _,console in pairs(self.channelConsoles) do
		console:ClearHistory()
	end
	for _,console in pairs(self.privateChatConsoles) do
		console:ClearHistory()
	end
end
