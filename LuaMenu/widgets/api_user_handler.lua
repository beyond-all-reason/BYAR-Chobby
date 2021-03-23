--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Users Handler",
		desc      = "Handles user visualisation and interaction.",
		author    = "GoogleFrog",
		date      = "11 July 2016",
		license   = "GNU LGPL, v2.1 or later",
		layer     = -100000,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Local Variables

local battleUsers = {}
local tooltipUsers = {}
local singleplayerUsers = {}
local channelUsers = {}
local debriefingUsers = {}
local partyUsers = {}
local popupUsers = {}
local statusUsers = {}
local profileUsers = {}
local ladderUsers = {}
local friendUsers = {}
local friendRequestUsers = {}
local notificationUsers = {}

local clanDownloadBegun = {}

local userListList = {
	battleUsers,
	tooltipUsers,
	singleplayerUsers,
	channelUsers,
	debriefingUsers,
	partyUsers,
	popupUsers,
	statusUsers,
	profileUsers,
	ladderUsers,
	friendUsers,
	friendRequestUsers,
	notificationUsers,
}

local IMAGE_DIR          = LUA_DIRNAME .. "images/"

local IMAGE_AFK          = IMAGE_DIR .. "away.png"
local IMAGE_BATTLE       = IMAGE_DIR .. "battle.png"
local IMAGE_INGAME       = IMAGE_DIR .. "ingame.png"
local IMAGE_SOLO         = IMAGE_DIR .. "solo.png"
local IMAGE_PARTY_INVITE = IMAGE_DIR .. "partyInvite.png"
local IMAGE_FLAG_UNKNOWN = IMAGE_DIR .. "flags/unknown.png"
local IMAGE_AUTOHOST     = IMAGE_DIR .. "ranks/robot.png"
local IMAGE_MODERATOR    = IMAGE_DIR .. "ranks/moderator.png"
local IMAGE_PLAYER       = IMAGE_DIR .. "ranks/player.png"
local IMAGE_READY        = IMAGE_DIR .. "ready.png"
local IMAGE_UNREADY      = IMAGE_DIR .. "unready.png"
local IMAGE_UNKNOWN_SYNC = IMAGE_DIR .. "unknown_sync.png"
local IMAGE_ONLINE       = IMAGE_DIR .. "online.png"
local IMAGE_OFFLINE      = IMAGE_DIR .. "offline.png"

local IMAGE_CLAN_PATH    = "LuaUI/Configs/Clans/"
local RANK_DIR           = LUA_DIRNAME .. "configs/gameConfig/zk/rankImages/"

local USER_SP_TOOLTIP_PREFIX = "user_single_"
local USER_MP_TOOLTIP_PREFIX = "user_battle_"
local USER_CH_TOOLTIP_PREFIX = "user_chat_s_"

local UserLevelToImageConfFunction

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Globally Applicable Utilities

local function CountryShortnameToFlag(shortname)
	local fileName = LUA_DIRNAME .. "images/flags/" .. string.lower(shortname) .. ".png"
	if VFS.FileExists(fileName) then
		return fileName
	end
end

local function UserLevelToImage(icon, level, skill, isBot, isAdmin)
	if UserLevelToImageConfFunction then
		return UserLevelToImageConfFunction(icon, level, skill, isBot, isAdmin)
	elseif icon then
		return RANK_DIR .. icon .. ".png"
	end
	return IMAGE_PLAYER
end

local function GetUserRankImage(userInfo, isBot)
	return UserLevelToImage(userInfo.icon, userInfo.level, math.max(userInfo.skill or 0, userInfo.casualSkill or 0), isBot, userInfo.isAdmin)
end

local function GetClanImage(clanName)
	if clanName then
		local clanFile = IMAGE_CLAN_PATH .. clanName .. ".png"
		if (not VFS.FileExists(clanFile)) then
			if WG.WrapperLoopback and WG.WrapperLoopback.DownloadImage then
				if not clanDownloadBegun[clanName] then
					Spring.CreateDir("LuaUI/Configs/Clans")
					WG.WrapperLoopback.DownloadImage({ImageUrl = "https://zero-k.info/img/clans/" .. clanName .. ".png", TargetPath = clanFile})
					clanDownloadBegun[clanName] = true
				end
				return clanFile, true
			else
				return false
			end
		end
		return clanFile
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utilities that reference controls

local function GetUserCountryImage(userName, userControl)
	local userInfo = userControl.lobby:GetUser(userName) or {}
	local userBattleInfo = userControl.lobby:GetUserBattleStatus(userName) or {}
	if userInfo.country then
		return CountryShortnameToFlag(userInfo.country)
	end
	if not userBattleInfo.aiLib then
		return IMAGE_FLAG_UNKNOWN
	end
end

local function GetUserSyncStatus(userName, userControl)
	local userBattleInfo = userControl.lobby:GetUserBattleStatus(userName) or {}
	if userBattleInfo.aiLib then
		return
	end
	if userBattleInfo.sync == 1 then
		return IMAGE_READY
	elseif userBattleInfo.sync == 2 then
		return IMAGE_UNREADY
	else
		return IMAGE_UNKNOWN_SYNC
	end
end

local function GetUserClanImage(userName, userControl)
	local userInfo = userControl.lobby:GetUser(userName) or {}
	local file, needDownload = GetClanImage(userInfo.clan)
	return file, needDownload
end

local function GetUserComboBoxOptions(userName, isInBattle, userControl, showTeamColor, showSide)
	local userInfo = userControl.lobby:GetUser(userName) or {}
	local userBattleInfo = userControl.lobby:GetUserBattleStatus(userName) or {}
	local myUserName = userControl.lobby:GetMyUserName()
	local comboOptions = {}

	local myPartyID = userControl.lobby:GetMyPartyID()
	local userPartyID = userControl.lobby:GetUserPartyID(userName)

	local Configuration = WG.Chobby.Configuration

	if (not userBattleInfo.aiLib) and userName ~= myUserName then
		comboOptions[#comboOptions + 1] = "Message"

		if (not isInBattle) and userInfo.battleID then
			local battle = lobby:GetBattle(userInfo.battleID)
			if battle and Configuration:IsValidEngineVersion(battle.engineVersion) then
				if not Configuration.showMatchMakerBattles and battle.isMatchMaker then
					comboOptions[#comboOptions + 1] = "Watch Battle"
				else
					comboOptions[#comboOptions + 1] = "Join Battle"
				end
			end
		end

		if not Configuration.hidePartySystem and ((not myPartyID) or myPartyID ~= userPartyID) then
			-- Do not show any party options for people already in my party.
			if (not myPartyID) and userPartyID then
				-- Join others party if they have one and I don't.
				comboOptions[#comboOptions + 1] = "Join Party"
			else
				-- Invite user to make a party or join mine. Note that the
				-- user might be in a party which is not visible to me. In
				-- this case the command might be the same as join party.
				comboOptions[#comboOptions + 1] = "Invite to Party"
			end
		end

		if Configuration.canAuthenticateWithSteam and userControl.steamInvite and userInfo.steamID then
			comboOptions[#comboOptions + 1] = "Invite to Campaign"
		end

		if userInfo.accountID and Configuration.gameConfig.link_userPage ~= nil then
			comboOptions[#comboOptions + 1] = "User Page"
		end

		if userInfo.accountID and Configuration.gameConfig.link_reportPlayer ~= nil then
			comboOptions[#comboOptions + 1] = "Report"
		end

		if userInfo.isIgnored then
			comboOptions[#comboOptions + 1] = "Unignore"
		elseif not userInfo.isAdmin then
			if (Configuration.gameConfig.spadsLobbyFeatures ~= true ) or
				(Configuration.gameConfig.spadsLobbyFeatures == true and not userInfo.isBot) then
				comboOptions[#comboOptions + 1] = "Ignore"
			end
		end

		if userInfo.isFriend then
			comboOptions[#comboOptions + 1] = "Unfriend"
		else
			if (Configuration.gameConfig.spadsLobbyFeatures ~= true ) or
			(Configuration.gameConfig.spadsLobbyFeatures == true and not userInfo.isBot) then
				comboOptions[#comboOptions + 1] = "Friend"
			end
		end
	end

	if userName == myUserName and userInfo.accountID and Configuration.gameConfig.link_userPage ~= nil then
		-- Only add for myself since the same thing is added in the previous block
		comboOptions[#comboOptions + 1] = "User Page"
	end

	if (userName == myUserName or userBattleInfo.aiLib) and
		not userBattleInfo.isSpectator then
		if showTeamColor then
			comboOptions[#comboOptions + 1] = "Change Color"
		end
		if showSide then
			comboOptions[#comboOptions + 1] = "Change Side"
		end
	end

	-- userControl.lobby:GetMyIsAdmin()
	-- Let everyone start kick votes, but dont let they try to kick spads lobby bottomSpacing
	if Configuration.gameConfig.spadsLobbyFeatures then
		if userName ~= myUserName and not userInfo.isBot and
			(isInBattle or (userBattleInfo.aiLib and userBattleInfo.owner == myUserName)) then
			comboOptions[#comboOptions + 1] = "Kick"
		end
	else
		if userName ~= myUserName and
			(isInBattle or (userBattleInfo.aiLib and userBattleInfo.owner == myUserName)) then
			comboOptions[#comboOptions + 1] = "Kick"
		end
	end
	-- Change team of anyone with !force
	if  Configuration.gameConfig.spadsLobbyFeatures and not userBattleInfo.isSpectator and (isInBattle or userBattleInfo.aiLib) then
		comboOptions[#comboOptions + 1] = "Change Team"
	end

	-- Set the handicap value of anyone with !force
	if  Configuration.gameConfig.spadsLobbyFeatures and not userBattleInfo.isSpectator and (isInBattle or userBattleInfo.aiLib) then
		comboOptions[#comboOptions + 1] = "Add Bonus"
	end

	-- Ring: not bot and is in same battle
	if not userInfo.isBot and Configuration.gameConfig.spadsLobbyFeatures and isInBattle and (not userBattleInfo.aiLib) then
		comboOptions[#comboOptions + 1] = "Ring"
	end

	-- Spec: in same battle, is not AI and is not spec:
	if Configuration.gameConfig.spadsLobbyFeatures and
		isInBattle and not userBattleInfo.isSpectator and not userBattleInfo.aiLib then
		comboOptions[#comboOptions + 1] = "Force Spectator"
	end

	-- Spec: in same battle, is not AI and is not spec: 
	if Configuration.gameConfig.spadsLobbyFeatures and
		isInBattle and not userBattleInfo.isSpectator and not userBattleInfo.aiLib then
		comboOptions[#comboOptions + 1] = "Make Boss"
	end


	local whitelist = userControl.dropdownWhitelist
	if whitelist then
		local culled = {}
		for i = 1, #comboOptions do
			if whitelist[comboOptions[i]] then
				culled[#culled + 1] = comboOptions[i]
			end
		end
		comboOptions = culled
	end

	if #comboOptions == 0 then
		comboOptions[1] = Label:New {
			x = 0,
			y = 0,
			width = 100,
			height = 30,
			font = Configuration:GetFont(1),
			caption = "No Actions",
		}
	end
	return comboOptions
end

local function GetUserRankImageName(userName, userControl)
	local userInfo = userControl.lobby:GetUser(userName) or {}
	local userBattleInfo = userControl.lobby:GetUserBattleStatus(userName) or {}

	if userControl.isSingleplayer and not userBattleInfo.aiLib then
		return IMAGE_PLAYER
	end

	local image = GetUserRankImage(userInfo, userInfo.isBot or userBattleInfo.aiLib)
	return image
end

local function GetUserStatusImages(userName, isInBattle, userControl)
	local userInfo = userControl.lobby:GetUser(userName) or {}
	local images = {}

	if userInfo.pendingPartyInvite and not userControl.hideStatusInvite then
		images[#images + 1] = IMAGE_PARTY_INVITE
	end

	if userInfo.isInGame or (userInfo.battleID and not isInBattle) and not userControl.hideStatusIngame then
		if userInfo.isInGame then
			if userInfo.battleID == nil and WG.Chobby.Configuration.gameConfig.showSinglePlayerIngame then
				images[#images + 1] = IMAGE_SOLO
			else
				images[#images + 1] = IMAGE_INGAME
			end
		else
			images[#images + 1] = IMAGE_BATTLE
		end
	end

	if userInfo.isAway and not userControl.hideStatusAway then
		images[#images + 1] = IMAGE_AFK
	end

	return images
end

local function GetUserNameColor(userName, userControl)
	local userInfo = userControl.lobby:GetUser(userName) or {}
	if userControl.showModerator and userInfo.isAdmin then
		return WG.Chobby.Configuration:GetModeratorColor()
	end
	if userControl.showFounder and userInfo.battleID then
		local battle = lobby:GetBattle(userInfo.battleID)
		if battle and battle.founder == userName then
			return WG.Chobby.Configuration:GetFounderColor()
		end
	end
	if userInfo.isIgnored then
		return WG.Chobby.Configuration:GetIgnoredUserNameColor()
	end
	return WG.Chobby.Configuration:GetUserNameColor()
end

-- gets status name, image and color
-- used for large user displays
local function GetUserStatus(userName, isInBattle, userControl)
	local userInfo = userControl.lobby:GetUser(userName) or {}
	if userInfo.isOffline then
		return IMAGE_OFFLINE, "offline", {0.5, 0.5, 0.5, 1}
	elseif userInfo.isInGame or (userInfo.battleID and not isInBattle) then
		if userInfo.isInGame then
			return IMAGE_INGAME, "ingame", {1, 0.5, 0.5, 1}
		else
			return IMAGE_BATTLE, "battle", {0.5, 1, 0.5, 1}
		end
	elseif userInfo.isAway then
		return IMAGE_AFK, "afk", {0.5, 0.5, 1, 1}
	else
		return IMAGE_ONLINE, "online", {1, 1, 1, 1}
	end
end

local function UpdateUserControlStatus(userName, userControls)
	if userControls.hideStatus then
		return
	end
	if userControls.imStatusLarge then
		local imgFile, status, fontColor = GetUserStatus(userName, isInBattle, userControls)
		userControls.tbName.font.color = fontColor
		userControls.tbName:Invalidate()
		userControls.imStatusLarge.file = imgFile
		userControls.imStatusLarge:Invalidate()
		userControls.lblStatusLarge.font.color = fontColor
		userControls.lblStatusLarge:SetCaption(i18n(status .. "_status"))
	elseif not userControls.statusImages then
		return
	end

	local imageFiles = GetUserStatusImages(userName, userControls.isInBattle, userControls)
	local imageControlCount = math.max(#userControls.statusImages, #imageFiles)

	local statusImageOffset = userControls.nameStartY + userControls.nameActualLength + 3
	if userControls.maxNameLength then
		if statusImageOffset + 21*(#imageFiles) > userControls.maxNameLength then
			statusImageOffset = userControls.maxNameLength - 21*(#imageFiles)
		end

		local nameSpace = userControls.maxNameLength - userControls.nameStartY - (userControls.maxNameLength - statusImageOffset)
		local truncatedName = StringUtilities.TruncateStringIfRequiredAndDotDot(userName, userControls.tbName.font, nameSpace)

		if truncatedName then
			userControls.tbName:SetText(truncatedName)
			userControls.nameTruncated = true
		elseif userControls.nameTruncated then
			userControls.tbName:SetText(userName)
			userControls.nameTruncated = false
		end
	end

	for i = 1, imageControlCount do
		if not userControls.statusImages[i] then
			userControls.statusImages[i] = Image:New {
				name = "statusImage" .. i,
				x = statusImageOffset,
				y = 1,
				width = 19,
				height = 19,
				parent = userControls.mainControl,
				keepAspect = true,
				image = imageFiles[i]
			}
		end

		if imageFiles[i] then
			userControls.statusImages[i]:SetVisibility(true)
			userControls.statusImages[i].file = imageFiles[i]
			userControls.statusImages[i]:Invalidate()
			userControls.statusImages[i]:SetPos(statusImageOffset)
		else
			userControls.statusImages[i]:SetVisibility(false)
		end
		statusImageOffset = statusImageOffset + 21
	end
end

local function UpdateUserComboboxOptions(_, userName)
	for i = 1, #userListList do
		local userList = userListList[i]
		local data = userList[userName]
		if data then
			data.mainControl.items = GetUserComboBoxOptions(userName, data.isInBattle, data,
			                                                data.imTeamColor ~= nil, data.imSide ~= nil)
		end
	end
end

local function UpdateUserActivity(listener, userName)
	for i = 1, #userListList do
		local userList = userListList[i]
		local userControls = userList[userName]
		if userControls then
			userControls.mainControl.items = GetUserComboBoxOptions(userName, userControls.isInBattle, userControls,
			                                                        userControls.imTeamColor ~= nil, userControls.imSide ~= nil)
			userControls.imLevel.file = GetUserRankImageName(userName, userControls)
			userControls.imLevel:Invalidate()

			userControls.tbName.font.color = GetUserNameColor(userName, userControls)
			userControls.tbName:Invalidate()

			UpdateUserControlStatus(userName, userControls)
		end
	end
end

local function UpdateUserActivityList(listener, userList)
	for i = 1, #userList do
		UpdateUserActivity(_, userList[i])
	end
end

local function OnIgnoreList(listener, userName)
	if userName then
		local userInfo = lobby:GetUser(userName)
		--Spring.Echo("OnIgnoreList(listener, userList)", userName,userInfo)
		if userInfo then
			userInfo.isIgnored = true
		end
	end
end

local function OnPartyUpdate(listener, partyID, partyUsers)
	if partyID ~= lobby:GetMyPartyID() then
		return
	end
	for i = 1, #partyUsers do
		UpdateUserComboboxOptions(_, partyUsers[i])
	end
end

local function OnPartyLeft(listener, partyID, partyUsers)
	for i = 1, #partyUsers do
		UpdateUserComboboxOptions(_, partyUsers[i])
	end
end

local function UpdateUserBattleStatus(listener, userName)
	UpdateUserComboboxOptions(_, userName)
	for i = 1, #userListList do
		local userList = userListList[i]
		local data = userList[userName]
		if data then
			if data.imSyncStatus then
				data.imSyncStatus.file = GetUserSyncStatus(userName, data)
				data.imSyncStatus:Invalidate()
			end
			local battleStatus = data.lobby:GetUserBattleStatus(userName) or {}
			local imageVisible = not battleStatus.isSpectator
			if data.imTeamColor then
				data.imTeamColor.color = battleStatus.teamColor
				data.imTeamColor:SetVisibility(imageVisible)
				if imageVisible then
					data.imTeamColor:Invalidate()
				end
			end
			if data.imSide then
				local sideSelected = battleStatus.side ~= nil
				if sideSelected then
					data.imSide.file = WG.Chobby.Configuration:GetSideById(battleStatus.side).logo
				end
				data.imSide:SetVisibility(imageVisible and sideSelected)
				if imageVisible then
					data.imTeamColor:Invalidate()
				end
			end
			if data.lblHandicap then
				local handicap = battleStatus.handicap
				if handicap ~= nil then
					local handicaptxt = ''
					if battleStatus.handicap == 0 then
						
						data.lblHandicap:SetVisibility(false)
					else
						if battleStatus.handicap > 0 then
							handicaptxt = '+'..tostring(battleStatus.handicap)
						else
							handicaptxt = tostring(battleStatus.handicap)
						end
						data.lblHandicap:SetCaption(handicaptxt)
						data.lblHandicap:SetVisibility(true)
					end
				end
				if imageVisible then
					data.lblHandicap:SetVisibility(true)
				else
					data.lblHandicap:SetVisibility(false)
				end
				data.lblHandicap:Invalidate()
			end
		end
	end
end

local function UpdateUserCountry(listener, userName)
	for i = 1, #userListList do
		local userList = userListList[i]
		local data = userList[userName]
		if data and data.imCountry then
			data.imCountry.file = GetUserCountryImage(userName, data)
			data.imCountry:Invalidate()
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Control Handling

local function GetUserControls(userName, opts)
	local autoResize         = opts.autoResize
	local maxNameLength      = opts.maxNameLength
	local isInBattle         = opts.isInBattle
	local isSingleplayer     = opts.isSingleplayer
	local reinitialize       = opts.reinitialize
	local disableInteraction = opts.disableInteraction
	local suppressSync       = opts.suppressSync
	local large              = opts.large
	local hideStatus         = opts.hideStatus
	local offset             = opts.offset or 0
	local offsetY            = opts.offsetY or 0
	local height             = opts.height or 22
	local showFounder        = opts.showFounder
	local showModerator      = opts.showModerator
	local comboBoxOnly       = opts.comboBoxOnly
	local showTeamColor      = opts.showTeamColor
	local showSide           = opts.showSide
	local showHandicap		 = opts.showHandicap

	local userControls = reinitialize or {}

	local Configuration = WG.Chobby.Configuration

	userControls.showFounder       = showFounder
	userControls.showModerator     = showModerator
	userControls.isInBattle        = isInBattle
	userControls.lobby             = (isSingleplayer and WG.LibLobby.localLobby) or lobby
	userControls.isSingleplayer    = isSingleplayer
	userControls.steamInvite       = opts.steamInvite
	userControls.hideStatus        = opts.hideStatus
	userControls.hideStatusInvite  = opts.hideStatusInvite
	userControls.hideStatusIngame  = opts.hideStatusIngame
	userControls.hideStatusAway    = opts.hideStatusAway
	userControls.dropdownWhitelist = opts.dropdownWhitelist

	if reinitialize then
		userControls.mainControl:ClearChildren()
	else
		local tooltip = ((isSingleplayer and USER_SP_TOOLTIP_PREFIX) or (isInBattle and USER_MP_TOOLTIP_PREFIX) or USER_CH_TOOLTIP_PREFIX) .. userName

		local ControlType = ComboBox
		if disableInteraction then
			ControlType = Control
		end

		local backgroundColor
		local borderColor
		if not large then
			backgroundColor = {0, 0, 0, 0}
			borderColor = {0, 0, 0, 0}
		end

		userControls.mainControl = ControlType:New {
			name = (not comboBoxOnly) and userName, -- Many can be added to screen0
			x = 0,
			y = 0,
			right = 0,
			height = height,
			backgroundColor = backgroundColor,
			borderColor     = borderColor,
			padding = {0, 0, 0, 0},
			caption = "",
			tooltip = (not disableInteraction) and tooltip,
			ignoreItemCaption = true,
			selectByName = true,
			itemFontSize = Configuration:GetFont(2).size,
			itemHeight = 30,
			selected = 0,
			maxDropDownWidth = large and 220 or 150,
			minDropDownHeight = 0,
			maxDropDownHeight = 300,
			items = GetUserComboBoxOptions(userName, isInBattle, userControls, showTeamColor, showSide),
			OnOpen = {
				function (obj)
					obj.tooltip = nil
					-- Update hovered tooltip
					local x,y = Spring.GetMouseState()
					screen0:IsAbove(x,y)
				end
			},
			OnClose = {
				function (obj)
					obj.tooltip = tooltip
				end
			},
			OnSelectName = {
				function (obj, selectedName)
					if selectedName == "Message" then
						local chatWindow = WG.Chobby.interfaceRoot.OpenPrivateChat(userName)
					elseif selectedName == "Kick" then
						local userBattleInfo = userControls.lobby:GetUserBattleStatus(userName) or {}
						if userBattleInfo and userBattleInfo.aiLib then
							userControls.lobby:RemoveAi(userName)
						else
							if Configuration.gameConfig.spadsLobbyFeatures then
								lobby:SayBattle("!kick "..userName)
							else
								userControls.lobby:KickUser(userName)
							end
						end
					elseif selectedName == "Unfriend" then
						userControls.lobby:Unfriend(userName)
					elseif selectedName == "Friend" then
						local userInfo = userControls.lobby:GetUser(userName)
						if userInfo and userInfo.hasFriendRequest then
							userControls.lobby:AcceptFriendRequest(userName)
						else
							userControls.lobby:FriendRequest(userName)
						end
					elseif selectedName == "Join Party" or selectedName == "Invite to Party" then
						userControls.lobby:InviteToParty(userName)
						local userInfo = userControls.lobby:GetUser(userName)
						if WG.SteamHandler.GetIsSteamFriend(userInfo.steamID) and userInfo.isOffline then
							WG.SteamHandler.InviteUserViaSteam(userName, userInfo.steamID)
						end
					elseif selectedName == "Invite to Campaign" then
						local userInfo = userControls.lobby:GetUser(userName)
						if userInfo.steamID then
							WG.WrapperLoopback.SteamInviteFriendToGame(userInfo.steamID)
						end
					elseif selectedName == "Join Battle" then
						local userInfo = userControls.lobby:GetUser(userName) or {}
						if userInfo.battleID then
							WG.Chobby.interfaceRoot.TryToJoinBattle(userInfo.battleID)
						end
					elseif selectedName == "Watch Battle" then
						local userInfo = userControls.lobby:GetUser(userName) or {}
						if userInfo.battleID then
							lobby:RejoinBattle(userInfo.battleID)
						end
					elseif selectedName == "User Page" and Configuration.gameConfig.link_userPage ~= nil then
						local userInfo = userControls.lobby:GetUser(userName) or {}
						if userInfo.accountID then
							WG.BrowserHandler.OpenUrl(Configuration.gameConfig.link_userPage(userInfo.accountID))
						end
					elseif selectedName == "Change Color" then
						local battleStatus = userControls.lobby:GetUserBattleStatus(userName) or {}
						if battleStatus.isSpectator then
							return
						end
						WG.ColorChangeWindow.CreateColorChangeWindow({
							initialColor = battleStatus.teamColor,
							OnAccepted = function(color)
								if userName == userControls.lobby:GetMyUserName() then
									userControls.lobby:SetBattleStatus({
										teamColor = color
									})
								else
									userControls.lobby:UpdateAi(userName, {
										teamColor = color
									})
								end
							end
						})
					elseif selectedName == "Change Side" then
						local battleStatus = userControls.lobby:GetUserBattleStatus(userName) or {}
						if battleStatus.isSpectator then
							return
						end
						WG.SideChangeWindow.CreateSideChangeWindow({
							initialSide = battleStatus.side or 0,
							OnAccepted = function(sideId)
								if userName == userControls.lobby:GetMyUserName() then
									userControls.lobby:SetBattleStatus({
										side = sideId
									})
								else
									userControls.lobby:UpdateAi(userName, {
										side = sideId
									})
								end
							end
						})
					elseif selectedName == "Change Team" then
						local battleStatus = userControls.lobby:GetUserBattleStatus(userName) or {}
						if battleStatus.isSpectator then
							return
						end
						WG.IntegerSelectorWindow.CreateIntegerSelectorWindow({
							defaultValue = (battleStatus.allyNumber or 1) + 1,
							minValue = 1,
							maxValue = 16,
							caption = "Change Team",
							labelCaption = "Change "..userName.." to Team: ",
							OnAccepted = function(allyTeamID)
								local myUserName = userControls.lobby:GetMyUserName()
								if userName == myUserName then
									userControls.lobby:SetBattleStatus({
										allyNumber = allyTeamID - 1
									})
								else
									local userBattleInfo = userControls.lobby:GetUserBattleStatus(userName) or {}
									if userBattleInfo.aiLib and userBattleInfo.owner == myUserName then
										userControls.lobby:UpdateAi(userName, {
											allyNumber = allyTeamID - 1
										})
									else
										lobby:SayBattle("!force "..userName.." team ".. tostring(allyTeamID)) -- +1 for spads team
									end
								end
							end
						})
					elseif selectedName == "Add Bonus" then
						local battleStatus = userControls.lobby:GetUserBattleStatus(userName) or {}
						if battleStatus.isSpectator then
							return
						end
						local minbonus = 0
						if isSingleplayer then 
							minbonus = -99 
						end
						WG.IntegerSelectorWindow.CreateIntegerSelectorWindow({
							defaultValue = 0,
							minValue = minbonus,
							maxValue = 100,
							caption = "Add Bonus",
							labelCaption = "Give "..userName.." an additional % resource bonus. 100% means that player produces double the normal resource amount. 0% is regular resource production. In single player games, a negative bonus will result in that player getting X% less resources",
							width = 360,
							OnAccepted = function(bonusAmount)
								if isSingleplayer then
									local myUserName = userControls.lobby:GetMyUserName()
									if userName == myUserName then
										userControls.lobby:SetBattleStatus({
											handicap = bonusAmount
										})
									else
										local userBattleInfo = userControls.lobby:GetUserBattleStatus(userName) or {}
										if userBattleInfo.aiLib and userBattleInfo.owner == myUserName then
											userControls.lobby:UpdateAi(userName, {
												handicap = bonusAmount
											})
										end
									end
								else
									lobby:SayBattle("!force "..userName.." bonus ".. tostring(bonusAmount))
								end
							end
						})
					elseif selectedName == "Ring" then
						--lobby:Ring(userName)
						lobby:SayBattle("!ring "..userName)
					elseif selectedName == "Make Boss" then
						lobby:SayBattle("!boss "..userName)
					elseif selectedName == "Force Spectator" then
						lobby:SayBattle("!spec "..userName)
					elseif selectedName == "Report" and Configuration.gameConfig.link_reportPlayer ~= nil then
						local userInfo = userControls.lobby:GetUser(userName) or {}
						if userInfo.accountID then
							WG.BrowserHandler.OpenUrl(Configuration.gameConfig.link_reportPlayer(userInfo.accountID))
						end
					elseif selectedName == "Unignore" then
						userControls.lobby:Unignore(userName)
					elseif selectedName == "Ignore" then
						userControls.lobby:Ignore(userName)
					end
				end
			}
		}
	end

	if comboBoxOnly then
		return userControls
	end

	if isInBattle and not suppressSync then
		offset = offset + 1
		userControls.imSyncStatus = Image:New {
			name = "imSyncStatus",
			x = offset,
			y = offsetY + 1,
			width = 21,
			height = 19,
			parent = userControls.mainControl,
			keepAspect = true,
			file = GetUserSyncStatus(userName, userControls),
		}
		offset = offset + 21
	end

	if not isSingleplayer then
		offset = offset + 1
		userControls.imCountry = Image:New {
			name = "imCountry",
			x = offset + 2,
			y = offsetY + 4,
			width = 16,
			height = 11,
			parent = userControls.mainControl,
			keepAspect = true,
			file = GetUserCountryImage(userName, userControls),
		}
		offset = offset + 21
	end

	offset = offset + 1
	userControls.imLevel = Image:New {
		name = "imLevel",
		x = offset,
		y = offsetY + 1,
		width = 19,
		height = 19,
		parent = userControls.mainControl,
		keepAspect = false,
		file = GetUserRankImageName(userName, userControls),
	}
	offset = offset + 21

	local clanImage, needDownload = GetUserClanImage(userName, userControls)
	if clanImage then
		offset = offset + 1
		userControls.imClan = Image:New {
			name = "imClan",
			x = offset,
			y = offsetY + 1,
			width = 21,
			height = 19,
			parent = userControls.mainControl,
			keepAspect = true,
			file = clanImage,
			fallbackFile = Configuration:GetLoadingImage(1),
			checkFileExists = needDownload,
		}
		offset = offset + 21
	end

	if showSide then
		local battleStatus = userControls.lobby:GetUserBattleStatus(userName) or {}
		offset = offset + 2
		local file = nil
		if battleStatus.side ~= nil then
			file = WG.Chobby.Configuration:GetSideById(battleStatus.side or 0).logo
		end
		userControls.imSide = Image:New {
			name = "imSide",
			x = offset,
			y = offsetY,
			width = 20,
			height = 20,
			parent = userControls.mainControl,
			keepAspect = false,
			file = file,
		}
		offset = offset + 22
		if battleStatus.isSpectator or file == nil then
			userControls.imSide:Hide()
		end
	end

	offset = offset + 2
	userControls.tbName = TextBox:New {
		name = "tbName",
		x = offset,
		y = offsetY + 4,
		right = 0,
		bottom = 4,
		align = "left",
		parent = userControls.mainControl,
		fontsize = Configuration:GetFont(2).size,
		text = userName,
	}
	local userNameStart = offset
	local truncatedName = StringUtilities.TruncateStringIfRequiredAndDotDot(userName, userControls.tbName.font, maxNameLength and (maxNameLength - offset))
	userControls.nameStartY = offset
	userControls.maxNameLength = maxNameLength

	local nameColor = GetUserNameColor(userName, userControls)
	if nameColor then
		userControls.tbName.font.color = nameColor
		userControls.tbName:Invalidate()
	end
	if truncatedName then
		userControls.tbName:SetText(truncatedName)
		userControls.nameTruncated = true
	end
	userControls.nameActualLength = userControls.tbName.font:GetTextWidth(userControls.tbName.text)
	offset = offset + userControls.nameActualLength

	if showTeamColor then
		local battleStatus = userControls.lobby:GetUserBattleStatus(userName) or {}
		offset = offset + 5
		userControls.imTeamColor = Image:New {
			name = "imTeamColor",
			x = offset,
			y = offsetY,
			width = 20,
			height = 20,
			parent = userControls.mainControl,
			keepAspect = false,
			file = "LuaMenu/widgets/chili/skins/Evolved/glassBk.png",
			color = battleStatus.teamColor
		}
		userControls.nameActualLength = userControls.nameActualLength + 25
		if battleStatus.isSpectator then
			userControls.imTeamColor:Hide()
		else
			offset = offset + 20
		end
	end

	if showHandicap then
		local battleStatus = userControls.lobby:GetUserBattleStatus(userName) or {}
		local handicaptxt = ''
		if battleStatus.handicap and battleStatus.handicap > 0 then
			handicaptxt = '+'..tostring(battleStatus.handicap)
		end
		userControls.lblHandicap = Label:New{
			name = "lblHandicap",
			x = offset,
			y = offsetY + 2,
			parent = userControls.mainControl,
			caption = handicaptxt,
			tooltip = "Handicap",
		}
	end

	if not hideStatus then
		userControls.statusImages = {}
		UpdateUserControlStatus(userName, userControls)
		if large then
			offsetY = offsetY + 35
			offset = 5
			local imgFile, status, fontColor = GetUserStatus(userName, isInBattle, userControls)
			userControls.imStatusLarge = Image:New {
				name = "imStatusLarge",
				x = offset,
				y = offsetY,
				width = 25,
				height = 25,
				parent = userControls.mainControl,
				keepAspect = true,
				file = imgFile,
			}
			offset = offset + 35
			userControls.lblStatusLarge = Label:New {
				name = "lblStatusLarge",
				x = offset,
				y = offsetY,
				height = 25,
				valign = 'center',
				parent = userControls.mainControl,
				caption = i18n(status .. "_status"),
				font = Configuration:GetFont(1),
			}
			userControls.lblStatusLarge.font.color = fontColor
			userControls.lblStatusLarge:Invalidate()
			userControls.tbName.font.color = fontColor
			userControls.tbName:Invalidate()
		end
	end


	if autoResize then
		userControls.mainControl.OnResize = userControls.mainControl.OnResize or {}
		userControls.mainControl.OnResize[#userControls.mainControl.OnResize + 1] = function (obj, sizeX, sizeY)
			local maxWidth = sizeX - userNameStart - 40
			local truncatedName = StringUtilities.GetTruncatedStringWithDotDot(userName, userControls.tbName.font, maxWidth)
			userControls.tbName:SetText(truncatedName)

			offset = userNameStart + userControls.tbName.font:GetTextWidth(userControls.tbName.text) + 3
			if userControls.imTeamColor then
				offset = offset + 25
			end
			if userControls.statusImages then
				for i = 1, #userControls.statusImages do
					userControls.statusImages[i]:SetPos(offset)
					offset = offset + 21
				end
			end
		end
	end

	-- This is always checked against main lobby.
	userControls.needReinitialization = lobby.status ~= "connected"

	return userControls
end

local function _GetUserDropdownMenu(userName, isInBattle)
	local opts = {
		isInBattle = isInBattle,
		comboBoxOnly = true
	}
	local userControls = GetUserControls(userName, opts)
	local parentControl = WG.Chobby.interfaceRoot.GetLobbyInterfaceHolder()

	parentControl:AddChild(userControls.mainControl)
	userControls.mainControl:BringToFront()

	local x,y = Spring.GetMouseState()
	local screenWidth, screenHeight = Spring.GetWindowGeometry()
	userControls.mainControl:SetPos(math.max(0, x - 60), screenHeight - y - userControls.mainControl.height + 5, 120)

	local function delayFunc()
		-- Must click on the new ComboBox, otherwise an infinite loop may be caused.
		screen0:MouseDown(x, y + 10, 1)
	end

	WG.Delay(delayFunc, 0.001)

	userControls.mainControl.OnClose = userControls.mainControl.OnClose or {}
	userControls.mainControl.OnClose[#userControls.mainControl.OnClose + 1] =
	function (obj)
		obj:Dispose()
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- External Functions
local userHandler = {
	CountryShortnameToFlag = CountryShortnameToFlag,
	GetUserRankImage = GetUserRankImage,
	GetClanImage = GetClanImage
}

local function _GetUser(userList, userName, opts)
	opts.reinitialize = userList[userName]
	if not userList[userName] or userList[userName].needReinitialization then
		userList[userName] = GetUserControls(userName, opts)
	end
	return userList[userName].mainControl
end

function userHandler.GetBattleUser(userName, isSingleplayer)
	if isSingleplayer then
		return userHandler.GetSingleplayerUser(userName)
	end

	return _GetUser(battleUsers, userName, {
		autoResize     = true,
		isInBattle     = true,
		showModerator  = true,
		showFounder    = true,
		showTeamColor  = not WG.Chobby.Configuration.gameConfig.disableColorChoosing,
		showSide       = WG.Chobby.Configuration:GetSideData() ~= nil,
		showHandicap   = WG.Chobby.Configuration.gameConfig.showHandicap,
	})
end

function userHandler.GetTooltipUser(userName)
	return _GetUser(tooltipUsers, userName, {
		isInBattle     = true,
		suppressSync   = true,
		showModerator  = true,
		showFounder    = true,
	})
end

function userHandler.GetSingleplayerUser(userName)
	return _GetUser(singleplayerUsers, userName, {
		autoResize     = true,
		isInBattle     = true,
		isSingleplayer = true,
		showTeamColor  = not WG.Chobby.Configuration.gameConfig.disableColorChoosing,
		showSide       = WG.Chobby.Configuration:GetSideData() ~= nil,
		showHandicap   = WG.Chobby.Configuration.gameConfig.showHandicap,
	})
end

function userHandler.GetChannelUser(userName)
	return _GetUser(channelUsers, userName, {
		maxNameLength  = WG.Chobby.Configuration.chatMaxNameLength,
		showModerator  = true,
	})
end

function userHandler.GetDebriefingUser(userName)
	return _GetUser(debriefingUsers, userName, {
		maxNameLength  = WG.Chobby.Configuration.chatMaxNameLength,
		showModerator  = true,
	})
end

function userHandler.GetPartyUser(userName)
	return _GetUser(partyUsers, userName, {
	})
end

function userHandler.GetPopupUser(userName)
	return _GetUser(popupUsers, userName, {
	})
end

function userHandler.GetStatusUser(userName)
	return _GetUser(statusUsers, userName, {
		maxNameLength       = WG.Chobby.Configuration.statusMaxNameLength,
		disableInteraction  = true,
	})
end

function userHandler.GetCommunityProfileUser(userName)
	return _GetUser(profileUsers, userName, {
		maxNameLength       = WG.Chobby.Configuration.statusMaxNameLength,
		disableInteraction  = true,
	})
end

function userHandler.GetLadderUser(userName)
	return _GetUser(ladderUsers, userName, {
		hideStatus          = true,
		dropdownWhitelist   = {
			["User Page"] = true,
		},
	})
end

function userHandler.GetFriendUser(userName)
	return _GetUser(friendUsers, userName, {
		large            = true,
		hideStatusAway   = true,
		hideStatusIngame = true,
		offset           = 5,
		offsetY          = 6,
		height           = 80,
		maxNameLength    = WG.Chobby.Configuration.friendMaxNameLength,
		steamInvite      = true,
	})
end

function userHandler.GetFriendRequestUser(userName)
	return _GetUser(friendRequestUsers, userName, {
		large          = true,
		hideStatus     = true,
		offsetY        = 20,
		maxNameLength  = WG.Chobby.Configuration.friendMaxNameLength,
	})
end

function userHandler.GetNotificationUser(userName)
	return _GetUser(notificationUsers, userName, {
		maxNameLength  = WG.Chobby.Configuration.notificationMaxNameLength,
	})
end

function userHandler.GetUserDropdownMenu(userName, isInbattle)
	_GetUserDropdownMenu(userName, isInbattle)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Connection

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Listeners

local function AddListeners()
	lobby:AddListener("OnFriendList", UpdateUserActivityList)
	lobby:AddListener("OnIgnoreList", UpdateUserActivityList)
	lobby:AddListener("OnIgnoreList", OnIgnoreList)
	lobby:AddListener("Ignore", OnIgnoreList)
	lobby:AddListener("OnUpdateUserStatus", UpdateUserActivity)

	lobby:AddListener("OnFriend", UpdateUserActivity)
	lobby:AddListener("OnUnfriend", UpdateUserActivity)
	lobby:AddListener("OnAddIgnoreUser", UpdateUserActivity)
	lobby:AddListener("OnRemoveIgnoreUser", UpdateUserActivity)

	lobby:AddListener("OnPartyInviteSent", UpdateUserActivity)
	lobby:AddListener("OnPartyInviteResponse", UpdateUserActivity)

	lobby:AddListener("OnPartyCreate", OnPartyUpdate)
	lobby:AddListener("OnPartyUpdate", OnPartyUpdate)
	lobby:AddListener("OnPartyLeft", OnPartyLeft)

	lobby:AddListener("OnAddUser", UpdateUserActivity)
	lobby:AddListener("OnRemoveUser", UpdateUserActivity)
	lobby:AddListener("OnAddUser", UpdateUserCountry)
	lobby:AddListener("OnUpdateUserBattleStatus", UpdateUserBattleStatus)
	WG.LibLobby.localLobby:AddListener("OnUpdateUserBattleStatus", UpdateUserBattleStatus)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

local function DelayedInitialize()
	local Configuration = WG.Chobby.Configuration
	UserLevelToImageConfFunction = Configuration.gameConfig.rankFunction

	local function onConfigurationChange(listener, key, value)
		if key == "gameConfigName" then
			UserLevelToImageConfFunction = Configuration.gameConfig.rankFunction
			-- TODO, update all rank icons.
		end
	end

	Configuration:AddListener("OnConfigurationChange", onConfigurationChange)
end


function widget:Initialize()
	CHOBBY_DIR = LUA_DIRNAME .. "widgets/chobby/"
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	AddListeners()
	WG.Delay(DelayedInitialize, 0.1)

	WG.UserHandler = userHandler
end

--local oldTimer
--local awayStatus = false
--function widget:Update()
--	if not oldTimer then
--		oldTimer = Spring.GetTimer()
--	end
--	local newTimer = Spring.GetTimer()
--	local deltaTime = Spring.DiffTimers(newTimer, oldTimer)
--	if deltaTime < 2 then
--		return
--	end
--	oldTimer = newTimer
--	awayStatus = not awayStatus
--	lobby:SetAllUserAway(awayStatus)
--
--	--lobby:SetAllUserStatusRandomly()
--end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
