FriendListWindow = ListWindow:extends{}

function FriendListWindow:init(parent)
	self:super("init", parent, i18n("friends"), true, nil, true)

	self:SetMinItemWidth(240)
	self.columns = 3
	self.itemHeight = 82
	self.itemPadding = 0

	self.btnSteamFriends = Button:New {
		right = 101,
		y = 7,
		width = 180,
		height = 45,
		caption = i18n("invite_friends"),
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		classname = "option_button",
		parent = self.window,
		OnClick = {
			function ()
				WG.SteamHandler.OpenFriendList()
			end
		},
	}

	if WG.Chobby.Configuration.addFriendWindowButton then
		local addFriendEditBox = EditBox:New {
			right = 400,
			width = 130,
			y = 15,
			height = 30,
			text = "",
			objectOverrideFont = WG.Chobby.Configuration:GetFont(1),
			objectOverrideHintFont = WG.Chobby.Configuration:GetFont(1),
			useIME = false,
			parent = self.window,
			tooltip = "Name of new friend",
		}

		local addFriendButton = Button:New {
			right = 270,
			width = 120,
			y = 15,
			height = 30,
			caption = "Add Friend",
			objectOverrideFont = WG.Chobby.Configuration:GetFont(1),
			classname = "option_button",
			parent = self.window,
			OnClick = {
				function()
					lobby:FriendRequest(addFriendEditBox.text)
				end
			},
		}
	end

	self.btnSteamFriends:SetVisibility(Configuration.canAuthenticateWithSteam)
	local function onConfigurationChange(listener, key, value)
		if key == "canAuthenticateWithSteam" then
			self.btnSteamFriends:SetVisibility(value)
		end
	end
	Configuration:AddListener("OnConfigurationChange", onConfigurationChange)

	lobby:AddListener("OnAddUser",           function(listener, ...) self:OnAddUser(...) end)
	lobby:AddListener("OnRemoveUser",        function(listener, ...) self:OnRemoveUser(...) end)
	lobby:AddListener("OnFriend",            function(listener, ...) self:OnFriend(...) end)
	lobby:AddListener("OnUnfriend",          function(listener, ...) self:OnUnfriend(...) end)
	lobby:AddListener("OnFriendList",        function(listener, ...) self:OnFriendList(...) end)
	lobby:AddListener("OnFriendRequest",     function(listener, ...) self:OnFriendRequest(...) end)
	lobby:AddListener("OnFriendRequestList", function(listener, ...) self:OnFriendRequestList(...) end)
	lobby:AddListener("OnAccepted",          function(listener, ...) self:OnAccepted(...) end)
end

function FriendListWindow:OnAddUser(userName)
	local userInfo = lobby:TryGetUser(userName)
	if userInfo.isFriend and WG.Chobby.Configuration:AllowNotification(userName) then
		local userControl = WG.UserHandler.GetNotificationUser(userName)
		userControl:SetPos(30, 30, 250, 20)
		Chotify:Post({
			title = i18n("User is now online"),
			body  = userControl,
		})
	end
end

function FriendListWindow:OnRemoveUser(userName)
	if (not lobby.status == "connected") then
		return
	end
	local userInfo = lobby:TryGetUser(userName)
	if userInfo and userInfo.isFriend and (not userInfo.isOffline) and WG.Chobby.Configuration:AllowNotification(userName) then
		local userControl = WG.UserHandler.GetNotificationUser(userName)
		userControl:SetPos(30, 30, 250, 20)
		Chotify:Post({
			title = i18n("User is now offline"),
			body  = userControl,
		})
	end
end

function FriendListWindow:CompareItems(userName1, userName2)
	return userName1 < userName2
end

function FriendListWindow:AddFriendRequest(userName)
	userControl = WG.UserHandler.GetFriendRequestUser(userName)
	userControl:SetPos(0, 0, 250, 80)
	local lblFriendRequest = Label:New {
		x = 0,
		y = 0,
		width = 100,
		height = 30,
		caption = i18n("friend_request"),
		objectOverrideFont = WG.Chobby.Configuration:GetFont(1, "friend_request", {color = { 0.5, 0.5, 0.5, 1 }}),
	}
	lblFriendRequest.font.color = { 0.5, 0.5, 0.5, 1 }
	lblFriendRequest:Invalidate()
	local btnAccept = Button:New {
		x = 10,
		y = 50,
		width = 100,
		height = 30,
		caption = i18n("accept"),
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		classname = "option_button",
		OnClick = {
			function()
				self:RemoveRow(userName)
				lobby:AcceptFriendRequest(userName)
			end
		},
	}
	local btnDecline = Button:New {
		x = 250 - 100 - 10,
		y = 50,
		width = 100,
		height = 30,
		caption = i18n("decline"),
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		classname = "negative_button",
		OnClick = {
			function()
				self:RemoveRow(userName)
				lobby:DeclineFriendRequest(userName)
			end
		},
	}
	self:AddRow({lblFriendRequest, btnAccept, btnDecline, userControl}, userName)
end

function FriendListWindow:AddFriend(userName)
	local userControl = WG.UserHandler.GetFriendUser(userName)
	--userControl:SetPos(0, 0, 250, 80)
	self:AddRow({userControl}, userName)
end

function FriendListWindow:OnFriend(userName)
	if WG.Chobby.Configuration.friendActivityNotification then
		interfaceRoot.GetRightPanelHandler().SetActivity("friends", lobby:GetFriendRequestCount())
	end
	self:AddFriend(userName)
end

function FriendListWindow:OnUnfriend(userName)
-- 	interfaceRoot.GetRightPanelHandler().SetActivity("friends", lobby:GetFriendRequestCount())
	self:RemoveRow(userName)
end

function FriendListWindow:OnFriendList(friends)
	if WG.Chobby.Configuration.friendActivityNotification then
		interfaceRoot.GetRightPanelHandler().SetActivity("friends", lobby:GetFriendRequestCount())
	end
	for _, userName in pairs(friends) do
		self:AddFriend(userName)
	end
end

function FriendListWindow:OnFriendRequest(userName)
	if WG.Chobby.Configuration.friendActivityNotification then
		interfaceRoot.GetRightPanelHandler().SetActivity("friends", lobby:GetFriendRequestCount())
	end
	if WG.Chobby.Configuration:AllowNotification() then -- Do not filter out friends here, otherwise nothing makes sense.
		local userControl = WG.UserHandler.GetNotificationUser(userName)
		userControl:SetPos(20, 40, 250, 20)
		Chotify:Post({
			title = i18n("New friend request"),
			body  = userControl,
		})
		self:AddFriendRequest(userName)
	end
end

function FriendListWindow:OnFriendRequestList(friendRequests)
	if WG.Chobby.Configuration.friendActivityNotification then
		interfaceRoot.GetRightPanelHandler().SetActivity("friends", lobby:GetFriendRequestCount())
	end
	for _, userName in pairs(friendRequests) do
		self:AddFriendRequest(userName)
	end
end

function FriendListWindow:OnAccepted(listener)
	self:Clear()
	lobby:FriendList()
	lobby:FriendRequestList()
end

function FriendListWindow:RemoveListeners()
	lobby:RemoveListener("OnFriend",            OnFriend)
	lobby:RemoveListener("OnFriendList",        OnFriendList)
	lobby:RemoveListener("OnFriendRequest",     OnFriendRequest)
	lobby:RemoveListener("OnFriendRequestList", OnFriendRequestList)
	lobby:RemoveListener("OnAccepted",          OnAccepted)
end
