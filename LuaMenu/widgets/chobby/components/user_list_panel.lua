UserListPanel = LCS.class {}

LOG_SECTION = "UserListPanel"

function UserListPanel:init(userUpdateFunction, spacing, showCount, getUserFunction)
	self.userUpdateFunction = userUpdateFunction
	self.spacing = spacing
	self.getUserFunction = getUserFunction

	self.userComponentMap = {}
	self.users = {}

	if showCount then
		self.textCount =
			TextBox:New {
				name = "textCount",
				x = 7,
				right = 0,
				height = 20,
				bottom = 2,
				align = "left",
				fontsize = Configuration:GetFont(2).size,
				text = lobby:GetUserCount() .. " players online"
			}
	end

	self.userPanel =
		ScrollPanel:New {
			x = 0,
			right = 0,
			y = 0,
			bottom = 28,
			horizontalScrollbar = false
		}

	self.panel =
		Control:New {
			x = 0,
			y = 0,
			right = 0,
			bottom = 0,
			padding = { 0, 0, 0, 0 },
			itemPadding = { 0, 0, 0, 0 },
			itemMargin = { 0, 0, 0, 0 },
			children = {
				self.userPanel,
				self.textCount
			}
		}
	self:Update()
end

function UserListPanel:OnJoined(userName)
	self:AddUser(userName, true)
end

function UserListPanel:OnLeft(userName)
	self:RemoveUser(userName, true)
end

function UserListPanel:CompareItems(userName1, userName2)
	local userData1 = lobby:TryGetUser(userName1)
	local userData2 = lobby:TryGetUser(userName2)
	if userData1.isAdmin ~= userData2.isAdmin then
		return userData1.isAdmin
	end
	return true
end

function UserListPanel:GetUsers()
	local channel = self.userUpdateFunction()
	return (channel and channel.users) or {}
end

local function CompareUsers(userName, otherName)
	local userData = lobby:TryGetUser(userName)
	local otherData = lobby:TryGetUser(otherName)
	if not otherData then
		return true
	end

	if (not (not otherData.isAdmin)) ~= (not (not userData.isAdmin)) then
		return userData.isAdmin
	end

	if (not (not otherData.isIgnored)) ~= (not (not userData.isIgnored)) then
		return otherData.isIgnored
	end

	if (not (not otherData.isOffline)) ~= (not (not userData.isOffline)) then
		return otherData.isOffline
	end
	return string.lower(userName) < string.lower(otherName)
end

function UserListPanel:Update()
	if lobby.commandBuffer then
		if not self.checkingUpdate then
			local CheckUpdate
			function CheckUpdate()
				if lobby.commandBuffer then
					WG.Delay(CheckUpdate, 5)
				else
					self.checkingUpdate = false
					self:Update()
				end
			end

			self.checkingUpdate = true
			WG.Delay(CheckUpdate, 5)
		end
		return
	end

	local actualUsers = self:GetUsers()
	local actualUserMap = {}
	for _, user in ipairs(actualUsers) do
		actualUserMap[user] = user
	end

	for i = 1, #actualUsers do
		local user = actualUsers[i]
		if not self.userComponentMap[user] then
			self:AddUser(user, false)
		end
	end

	local toRemove = {}
	for existingUser, _ in pairs(self.userComponentMap) do
		if not actualUserMap[existingUser] then
			table.insert(toRemove, existingUser)
		end
	end

	for _, user in ipairs(toRemove) do
		self:RemoveUser(user, false)
	end

	self:_AlignComponents(1, #self.users)
end

function UserListPanel:UpdateUserCount()
	if self.textCount then
		self.textCount:SetText(lobby:GetUserCount() .. " players online")
	end
end

function UserListPanel:AddUser(userName, alignComponents)
	local userData = lobby:TryGetUser(userName)
	if not userData then
		Spring.Echo("User data not found", userName)
		return
	end
	if userData.isBot and not Configuration.displayBots then
		return
	end

	if self.userComponentMap[userName] then
		Spring.Log(LOG_SECTION, LOG.ERROR, "User already exists in panel")
		return
	end

	-- Possible optimization: implement as binary search
	local index = 1
	for i, existingUserName in ipairs(self.users) do
		if CompareUsers(userName, existingUserName) then
			break
		end
		index = index + 1
	end
	table.insert(self.users, index, userName)

	local userControl =
		(self.getUserFunction and self.getUserFunction(userName)) or WG.UserHandler.GetChannelUser(userName)
	self.userComponentMap[userName] = userControl
	self.userPanel:AddChild(userControl, false)

	-- Possible optimization: don't update this at the beginning (connection).
	-- Do it post initialization (once)
	if alignComponents then
		self:_AlignComponents(index, #self.users)
	end
end

function UserListPanel:RemoveUser(userName, alignComponents)
	-- Possible optimization: implement as binary search
	local index
	for i, existingUserName in ipairs(self.users) do
		if existingUserName == userName then
			index = i
			break
		end
	end
	if index == nil then
		if WG.Chobby.Configuration and WG.Chobby.Configuration.devMode then
			Spring.Log(LOG_SECTION, LOG.ERROR, "Cannot find user to remove: " .. tostring(userName)) -- only show to devs for now
		end
		return
	end

	self.userPanel:RemoveChild(self.userPanel.childrenByName[userName])
	self.userComponentMap[userName] = nil
	table.remove(self.users, index)
	-- Possible optimization: don't update this at the beginning (connection).
	-- Do it post initialization (once)
	if alignComponents then
		self:_AlignComponents(index, #self.users)
	end
end

function UserListPanel:_AlignComponents(startIndex, endIndex)
	for i = startIndex, endIndex do
		local userName = self.users[i]
		self.userComponentMap[userName]:SetPos(nil, (i - 1) * self.spacing)
	end
end

function UserListPanel:Delete()
	self = nil
end
