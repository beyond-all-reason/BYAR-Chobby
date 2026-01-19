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
local replayTooltipUsers = {}
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

local namedUserList = {
	battleUsers = battleUsers,
	tooltipUsers = tooltipUsers,
	replayTooltipUsers = replayTooltipUsers,
	singleplayerUsers = singleplayerUsers,
	channelUsers = channelUsers,
	debriefingUsers = debriefingUsers,
	partyUsers = partyUsers,
	popupUsers = popupUsers,
	statusUsers = statusUsers,
	profileUsers = profileUsers,
	ladderUsers = ladderUsers,
	friendUsers = friendUsers,
	friendRequestUsers = friendRequestUsers,
	notificationUsers = notificationUsers,
}

local userListList = {
	battleUsers,
	tooltipUsers,
	replayTooltipUsers,
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

local clanDownloadBegun = {}

local IMAGE_DIR            = LUA_DIRNAME .. "images/"
  
local IMAGE_AFK            = IMAGE_DIR .. "away.png"
local IMAGE_BATTLE         = IMAGE_DIR .. "battle.png"
local IMAGE_INGAME         = IMAGE_DIR .. "ingame.png"
local IMAGE_SOLO           = IMAGE_DIR .. "solo.png"
local IMAGE_PARTY_INVITE   = IMAGE_DIR .. "partyInvite.png"
local IMAGE_FLAG_UNKNOWN   = IMAGE_DIR .. "flags/unknown.png"
local IMAGE_AUTOHOST       = IMAGE_DIR .. "ranks/robot.png"
local IMAGE_MODERATOR      = IMAGE_DIR .. "ranks/moderator.png"
local IMAGE_PLAYER         = IMAGE_DIR .. "ranks/player.png"
local IMAGE_READY          = IMAGE_DIR .. "ready.png"
local IMAGE_UNREADY        = IMAGE_DIR .. "unready.png"
local IMAGE_DLREADY        = IMAGE_DIR .. "downloadready.png"
local IMAGE_DLUNREADY      = IMAGE_DIR .. "downloadnotready.png"
local IMAGE_DOWNLOAD       = IMAGE_DIR .. "download.png"
local IMAGE_UNKNOWN_SYNC   = IMAGE_DIR .. "unknown_sync.png"
local IMAGE_ONLINE         = IMAGE_DIR .. "online.png"
local IMAGE_OFFLINE        = IMAGE_DIR .. "offline.png"
local IMAGE_BOSS           = IMAGE_DIR .. "boss-icon.png"
local IMAGE_RUNNING_BATTLE = IMAGE_DIR .. "runningBattle.png"
local IMAGE_MUTED          = IMAGE_DIR .. "mute.png"

local DEFAULT_SNAPSHOT_PATH = "data-processing-main/data-processing-main/data_export/player_skill_snapshot.csv"

local openSkillCache = nil
local openSkillLoaded = false
local openSkillLoadFailed = false
-- Incremental snapshot loading state.
local openSkillLoadCo = nil
local openSkillLoading = false
local OPEN_SKILL_LINES_PER_STEP = 500 -- Tune per-frame parse budget.
local openSkillPendingUpdates = {}

local IMAGE_CLAN_PATH    = "LuaUI/Configs/Clans/"
local RANK_DIR           = LUA_DIRNAME .. "configs/gameConfig/zk/rankImages/"

local UserLevelToImageConfFunction

local votedUsers = {} -- 2023-06-29 FB: ToDo: Does not get reset, if user leaves battle during vote, but has no impact
local usersAllowedToVote = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Globally Applicable Utilities

local function CountryShortnameToFlag(shortname)
	local fileName = LUA_DIRNAME .. "images/flags/" .. string.lower(shortname) .. ".png"
	if VFS.FileExists(fileName) then
		return fileName
	else
		return IMAGE_FLAG_UNKNOWN
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
	return UserLevelToImage(userInfo.icon, userInfo.level, userInfo.skill or 0, isBot, userInfo.isAdmin)
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
local function SplitCsvLine(line)
	local fields = {}
	local field = ""
	for i = 1, #line do
		local ch = line:sub(i, i)
		if ch == "," then
			fields[#fields + 1] = field
			field = ""
		else
			field = field .. ch
		end
	end
	fields[#fields + 1] = field
	return fields
end

local function LoadOpenSkillSnapshot()
	if openSkillLoaded then
		return
	end
	if openSkillLoading then
		return
	end
	if openSkillLoadFailed then
		local snapshotPath = (WG and WG.OpenSkillSnapshotPath) or DEFAULT_SNAPSHOT_PATH
		if not VFS.FileExists(snapshotPath) then
			return
		end
		openSkillLoadFailed = false
	end

	local snapshotPath = (WG and WG.OpenSkillSnapshotPath) or DEFAULT_SNAPSHOT_PATH
	local raw = VFS.LoadFile(snapshotPath)
	if not raw then
		openSkillLoadFailed = true
		return
	end

	openSkillCache = {}
	openSkillLoading = true

	-- Parse in steps to avoid stalling menu on startup
	openSkillLoadCo = coroutine.create(function(lineBudget)
		local processed = 0
		local isHeader = true
		for line in raw:gmatch("[^\r\n]+") do
			if isHeader then
				isHeader = false
			else
				local row = SplitCsvLine(line)
				local id = tonumber(row[1])
				if id then
					openSkillCache[id] = {
						id = id,
						name = row[2],
						duelSkill = tonumber(row[3]),
						duelSkillUn = tonumber(row[4]),
						ffaSkill = tonumber(row[5]),
						ffaSkillUn = tonumber(row[6]),
						teamSkill = tonumber(row[7]),
						teamSkillUn = tonumber(row[8]),
						lastDuel = row[9],
						lastFFA = row[10],
						lastTeam = row[11],
						countryCode = row[12],
						lastSmallTeam = row[13],
						smallTeamSkill = tonumber(row[14]),
						smallTeamSkillUn = tonumber(row[15]),
					}
				end
			end

			processed = processed + 1
			if processed >= lineBudget then
				processed = 0
				lineBudget = coroutine.yield()
				if not lineBudget then
					lineBudget = OPEN_SKILL_LINES_PER_STEP
				end
			end
		end

	-- Apply any live updates received while loading
	for id, update in pairs(openSkillPendingUpdates) do
		openSkillCache[id] = openSkillCache[id] or { id = id }
		local entry = openSkillCache[id]
		if update.name then
			entry.name = update.name
		end
		entry[update.skillKey] = update.skill
		entry[update.unKey] = update.un
	end
	openSkillPendingUpdates = {}

	openSkillLoaded = true
	openSkillLoadFailed = false
	openSkillLoading = false
	WG.OpenSkillCache = openSkillCache
	end)
	local ok, err = coroutine.resume(openSkillLoadCo, OPEN_SKILL_LINES_PER_STEP)
	if not ok then
		openSkillLoadFailed = true
		openSkillLoading = false
		openSkillLoadCo = nil
		Spring.Echo("OpenSkill snapshot load failed: " .. tostring(err))
	end
end

local function ResolveSnapshotColumns(battle)
	local ratingType = battle and battle.ratingType
	if ratingType == "Duel" then
		return "duelSkill", "duelSkillUn"
	elseif ratingType == "FFA" then
		return "ffaSkill", "ffaSkillUn"
	elseif ratingType == "Small Team" then
		return "smallTeamSkill", "smallTeamSkillUn"
	elseif ratingType == "Large Team" then
		return "teamSkill", "teamSkillUn"
	end

	if battle and battle.teamSize and battle.nbTeams then
		local teamSize = tonumber(battle.teamSize)
		local nbTeams = tonumber(battle.nbTeams)
		if teamSize and nbTeams then
			if teamSize == 1 and nbTeams == 2 then
				return "duelSkill", "duelSkillUn"
			elseif teamSize == 1 and nbTeams > 2 then
				return "ffaSkill", "ffaSkillUn"
			elseif teamSize <= 5 then
				return "smallTeamSkill", "smallTeamSkillUn"
			else
				return "teamSkill", "teamSkillUn"
			end
		end
	end

	return "teamSkill", "teamSkillUn"
end

local function GetSnapshotSkill(userID, battle)
	LoadOpenSkillSnapshot()
	if not openSkillCache or not userID then
		return
	end

	local entry = openSkillCache[userID]
	if not entry then
		return
	end

	local skillKey, unKey = ResolveSnapshotColumns(battle)
	return entry[skillKey], entry[unKey]
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utilities that reference controls

local function GetUserCountryImage(userName, userControl)
	local userInfo = userControl.replayUserInfo or userControl.lobby:GetUser(userName) or {}
	local bs = userControl.replayUserInfo or userControl.lobby:GetUserBattleStatus(userName) or {}
	if userInfo.country then
		return CountryShortnameToFlag(userInfo.country)
	end
	if not bs.aiLib then
		return IMAGE_FLAG_UNKNOWN
	end
end

local function GetUserSyncStatus(userName, userControl)
	local bs = userControl.lobby:GetUserBattleStatus(userName) or {}
	if bs.aiLib then
		return
	end
	if bs.sync == 1 then
		return IMAGE_DLREADY
	elseif bs.sync == 2 then
		return IMAGE_DLUNREADY
	else
		return IMAGE_UNKNOWN_SYNC
	end
end

local function GetUserReadyStatus(userName, userControl)
	local bs = userControl.lobby:GetUserBattleStatus(userName) or {}
	if bs.aiLib then
		return
	end
	if bs.isReady then
		return IMAGE_READY
	else
		return IMAGE_UNREADY
	end
end

local function GetUserClanImage(userName, userControl)
	local userInfo = userControl.replayUserInfo or userControl.lobby:GetUser(userName) or {}
	local file, needDownload = GetClanImage(userInfo.clan)
	return file, needDownload
end

local function GetUserComboBoxOptions(userName, isInBattle, control, showTeamColor, showSide)
	local Configuration = WG.Chobby.Configuration
	local info = control.lobby:GetUser(userName) or {}
	local bs = control.lobby:GetUserBattleStatus(userName) or {}
	local myUserName = control.lobby:GetMyUserName()
	local itsme = userName == myUserName
	local iPlay = not control.lobby:GetMyIsSpectator()
	local comboOptions = {}
	local iAmBoss = control.lobby:GetMyIsBoss()
	local isBoss = bs.isBoss or false
	local bossed = info.battleID and control.lobby.battles[info.battleID] and control.lobby.battles[info.battleID].bossed
	local validEngine = info.battleID and control.lobby.battles[info.battleID] and (Configuration.displayBadEngines2 or Configuration:IsValidEngineVersion(control.lobby.battles[info.battleID].engineVersion))

	local inMyParty, invitedToMyParty
	if control.lobby.myPartyID then
		local myParty = control.lobby.parties[control.lobby.myPartyID]
		inMyParty = myParty.members[userName] ~= nil
		invitedToMyParty = myParty.invites[userName] ~= nil
	end

	if not (itsme or bs.aiLib) then																					comboOptions[#comboOptions + 1] = "Message" end
	if isInBattle and not (itsme or bs.aiLib or info.isBot) then													comboOptions[#comboOptions + 1] = "Ring" end
	if not (itsme or bs.aiLib or isInBattle) and info.battleID and validEngine then									comboOptions[#comboOptions + 1] = "Join Battle" end
	if not (itsme or inMyParty or invitedToMyParty or info.isBot or bs.aiLib) then									comboOptions[#comboOptions + 1] = "Invite to Party" end
	if not (itsme) and invitedToMyParty then																		comboOptions[#comboOptions + 1] = "Cancel Party Invite" end
	if not (itsme or bs.aiLib or info.isBot) then																	comboOptions[#comboOptions + 1] = info.isFriend and "Unfriend" or "Friend"
									  if info.isDisregarded and info.isDisregarded == Configuration.IGNORE then     comboOptions[#comboOptions + 1] = "Unignore"
																													comboOptions[#comboOptions + 1] = "Avoid"
									  elseif info.isDisregarded and info.isDisregarded == Configuration.AVOID then  comboOptions[#comboOptions + 1] = "Unavoid"
																													comboOptions[#comboOptions + 1] = "Block"
									  elseif info.isDisregarded and info.isDisregarded == Configuration.BLOCK then  comboOptions[#comboOptions + 1] = "Unblock"
									  else																		    comboOptions[#comboOptions + 1] = "Ignore" end
	end
	if showSide and not bs.isSpectator and (itsme or (bs.aiLib and bs.owner == myUserName)) then					comboOptions[#comboOptions + 1] = "Change Faction" end
	if isInBattle and not bs.isSpectator and (iAmBoss or (iPlay and not bossed) or (bs.aiLib and bs.owner == myUserName)) then		comboOptions[#comboOptions + 1] = "Change Team"
																													comboOptions[#comboOptions + 1] = "Add Bonus" end
	if (iAmBoss or (iPlay and not bossed)) and not bs.aiLib and isInBattle and not bs.isSpectator then								comboOptions[#comboOptions + 1] = "Force Spectator" end
	if (iAmBoss or (iPlay and not bossed)) and not itsme and not info.isBot and isInBattle and not bs.aiLib then						comboOptions[#comboOptions + 1] = "Kickban" end
	if bs.aiLib then																								comboOptions[#comboOptions + 1] = "Clone AI" end
	if bs.aiLib and bs.owner == myUserName and isInBattle then														comboOptions[#comboOptions + 1] = "Remove" end
	if not itsme and not info.isBot and not bs.aiLib then															comboOptions[#comboOptions + 1] = "Report User" end
																													comboOptions[#comboOptions + 1] = "Copy Name"
	if (iAmBoss or iPlay) and not (control.isSingleplayer or bs.aiLib or info.isBot) and isInBattle  then			comboOptions[#comboOptions + 1] = "\255\128\128\128" .. "--------------"
																													comboOptions[#comboOptions + 1] =  isBoss and "Disable Boss" or "Make Boss" end

	if #comboOptions == 0 then
		comboOptions[1] = Label:New {
			x = 0,
			y = 0,
			width = 100,
			height = 30,
			objectOverrideFont = WG.Chobby.Configuration:GetFont(1),
			caption = "No Actions",
		}
	end
	return comboOptions
end

local function GetUserRankImageName(userName, userControl)
	local userInfo = userControl.replayUserInfo or userControl.lobby:GetUser(userName) or {}
	local bs = userControl.replayUserInfo or userControl.lobby:GetUserBattleStatus(userName) or {}

	if userControl.isSingleplayer and not bs.aiLib then
		return IMAGE_PLAYER
	end

	local image = GetUserRankImage(userInfo, userInfo.isBot or bs.aiLib)
	return image
end

-- returns skill, skillUncertaintyColorFont
-- default to skill="  ", sigma = 0, if no skill is known for userName (skill wasn´t set yet in Interface:_OnSetScriptTags)
-- skill format: "XX" or " X" (leading whitespace)
-- takes skillUncertaintyColors values from configuration.lua
local function GetUserSkillFont(userName, userControl)
	local config = WG.Chobby.Configuration
	local skill = "  "
	local sigma = 0
	local uncertaintyColorIndex = 0

	local bs = userControl.replayUserInfo or userControl.lobby:GetUserBattleStatus(userName) or {}
	if userControl.isSingleplayer or bs.aiLib ~= nil or userControl.showSkill == false then
		return "  ", config:GetFont(1)
	end

	local userInfo = userControl.replayUserInfo or userControl.lobby:GetUser(userName) or {}
	if userControl.useSnapshotSkill then
		local battle = userControl.tooltipBattle or (userInfo.battleID and userControl.lobby:GetBattle(userInfo.battleID))
		local snapSkill, snapUn = GetSnapshotSkill(userInfo.accountID, battle)
		if snapSkill and snapSkill >= 0 then
			local adjustedSkill = snapSkill - (snapUn or 0)
			if adjustedSkill < 0 then
				adjustedSkill = 0
			end
			skill = math.floor(adjustedSkill + 0.5)
			if skill < 10 and skill > -10 then skill = " " .. skill end
			skill = tostring(skill)
			if snapUn and snapUn > 6.65 then
				skill = "??"
			end
		else
			local bs = userControl.replayUserInfo or userControl.lobby:GetUserBattleStatus(userName) or {}
			local fallbackSkill = tonumber(userInfo.skill or bs.skill)
			if fallbackSkill and fallbackSkill >= 0 then
				skill = math.floor(fallbackSkill + 0.5)
				if skill < 10 and skill > -10 then skill = " " .. skill end
				skill = tostring(skill)
			else
				skill = "  "
			end
		end
	elseif userInfo.skill then
		local adjustedSkill = tonumber(userInfo.skill)
		if adjustedSkill and adjustedSkill < 0 then
			adjustedSkill = 0
		end
		skill = math.floor(adjustedSkill + 0.5)
		if skill < 10 and skill > -10 then skill = " " .. skill end

		skill = tostring(skill)

		if userInfo.skillUncertainty and tonumber(userInfo.skillUncertainty) > 6.65 then
			skill = "??"
		end
	end
	
	if config.showSkillOpt == 3 and userInfo.skillUncertainty then
		sigma = tonumber(userInfo.skillUncertainty)
		if sigma >= config.skillUncertaintyDistribution[3] then
			uncertaintyColorIndex = 3
		elseif sigma >= config.skillUncertaintyDistribution[2] then
			uncertaintyColorIndex = 2
		elseif sigma >= config.skillUncertaintyDistribution[1] then
			uncertaintyColorIndex = 1
		else
			uncertaintyColorIndex = 0
		end
	end
	return skill, config:GetFont(1, "skill" .. uncertaintyColorIndex, {color = config.skillUncertaintyColors[uncertaintyColorIndex]})
end

local function GetUserStatusImages(userName, isInBattle, userControl)
	local userInfo = userControl.replayUserInfo or userControl.lobby:GetUser(userName) or {}
	local battleStatus = userControl.lobby:GetUserBattleStatus(userName) or {}
	local images = {}

	if userInfo.pendingPartyInvite and not userControl.hideStatusInvite then
		images[#images + 1] = IMAGE_PARTY_INVITE
	end

	if isInBattle and battleStatus.isMuted then
		images[#images + 1] = IMAGE_MUTED
	end

	if isInBattle and userControl.isBoss then
		images[#images + 1] = IMAGE_BOSS
	end

	if not isInBattle or userControl.isPlaying == false then
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
	end

	if userInfo.isAway and not userControl.hideStatusAway then
		images[#images + 1] = IMAGE_AFK
	end

	return images
end

local function GetUserNameColorFont(userName, userControl)
	local Configuration = WG.Chobby.Configuration

	if usersAllowedToVote[userName] then
		return userControl.tbName.font
	end

	local userInfo = userControl.lobby:GetUser(userName) or {}

	if userControl.showModerator and userInfo.isAdmin then
		return Configuration:GetFont(1, "Moderator", {color = Configuration:GetModeratorColor()} )
	end
	if userControl.showFounder and userInfo.battleID then
		local battle = lobby:GetBattle(userInfo.battleID)
		if battle and battle.founder == userName then
			return Configuration:GetFont(1, "Founder", {color = Configuration:GetFounderColor()} )
		end
	end
	if userControl.colorizeFriends and userName == userControl.lobby:GetMyUserName() then
		return Configuration:GetFont(1, "User", {color = Configuration:GetMyUserNameColor()} )
	end
	-- priorize showing friend color over disregard color, though both may be applied at the same time. So user is reminded to unfriend.
	if userControl.colorizeFriends and userInfo.isFriend then
		return Configuration:GetFont(1, "Friend", {color = Configuration:GetFriendsColor()})
	end
	if userInfo.isDisregarded then
		return Configuration:GetFont(1, "Disregard" .. userInfo.isDisregarded, {color = Configuration:GetDisregardUserNameColor(userInfo.isDisregarded)} )
	end
	return Configuration:GetFont(1, "UserName", {color = Configuration:GetUserNameColor()} )
end

-- gets status name, image and colorFont
-- used for large user displays
local function GetUserStatusFont(userName, isInBattle, userControl)
	local userInfo = userControl.replayUserInfo or userControl.lobby:GetUser(userName) or {}
	if userInfo.isOffline then
		return IMAGE_OFFLINE, "offline", WG.Chobby.Configuration:GetFont(1, "offline", {color = {0.5, 0.5, 0.5, 1}} )
	elseif userInfo.isInGame or (userInfo.battleID and not isInBattle) then
		if userInfo.isInGame then
			return IMAGE_INGAME, "ingame", WG.Chobby.Configuration:GetFont(1, "ingame", {color = {1, 0.5, 0.5, 1}} )
		else
			return IMAGE_BATTLE, "battle", WG.Chobby.Configuration:GetFont(1, "battle", {color = {0.5, 1, 0.5, 1}} )
		end
	elseif userInfo.isAway then
		return IMAGE_AFK, "afk", WG.Chobby.Configuration:GetFont(1, "afk", {color = {0.5, 0.5, 1, 1}} )
	else
		return IMAGE_ONLINE, "online", WG.Chobby.Configuration:GetFont(1, "online", {color = {1, 1, 1, 1}} )
	end
end

local function getUserStatusImage(userName, userControls)
	local bs = userControls.replayUserInfo or userControls.lobby:GetUserBattleStatus(userName) or {}
	local userInfo = userControls.replayUserInfo or userControls.lobby:GetUser(userName) or {}
	
	-- 1. Check if someone is ingame - If yes, swords, if not, go to point 2.
	-- 2. Check if someone is synced - If not, red download arrow, if yes, go to point 3.
	-- 3. Check if someone is ready - if not, red cross, if yes, green checkmark
	local statusImage = IMAGE_UNKNOWN_SYNC
	if userControls.isInBattle then
		if userInfo.isInGame then
			if userInfo.battleID == nil and WG.Chobby.Configuration.gameConfig.showSinglePlayerIngame then
				statusImage = IMAGE_SOLO
			else
				statusImage = IMAGE_INGAME
			end
		elseif userControls.isPlaying then
			if not userControls.suppressSync and (bs and bs.sync and bs.sync == 2) then
				--statusImage = IMAGE_DLUNREADY
				statusImage = IMAGE_DOWNLOAD
			else
				statusImage = GetUserReadyStatus(userName, userControls)
			end
		end
	end
	return statusImage
end

local function UpdateUserStatusImage(userName, userControls)
	if userControls.imStatus then
		userControls.imStatus:SetVisibility(userControls.isPlaying)
		if userControls.isPlaying then
			userControls.imStatus.file = getUserStatusImage(userName, userControls)
			--userControls.imStatus:Invalidate()
		end
	end
end

local function UpdateUserControlStatus(userName, userControls)
	if userControls.hideStatus then
		return
	end
	if userControls.imStatusLarge then
		local imgFile, status, font = GetUserStatusFont(userName, isInBattle, userControls)
		userControls.tbName.font = font
		userControls.tbName:Invalidate()
		userControls.imStatusLarge.file = imgFile
		userControls.imStatusLarge:Invalidate()
		userControls.lblStatusLarge.font = font
		userControls.lblStatusLarge:SetCaption(i18n(status .. "_status"))
		return
	elseif not userControls.statusImages then
		return
	end

	local imageFiles = GetUserStatusImages(userName, userControls.isInBattle, userControls)
	local imageControlCount = math.max(#userControls.statusImages, #imageFiles)

	local handiCapLength = 0
	if userControls.lblHandicap and userControls.lblHandicap.visible then
		handiCapLength = userControls.lblHandicap.font:GetTextWidth(userControls.lblHandicap.caption)
	end

	local statusImageOffset = userControls.nameStartY + userControls.nameActualLength + handiCapLength + 3

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

local function UpdateVisualPartyStatus(userControls)
	if userControls.partyStatus and userControls.showPartyStatus and userControls.showPartyStatus[userControls.partyStatus] then
		if not userControls.tbPartyStatus then
			userControls.tbPartyStatus = TextBox:New {
				x = userControls.tbName.x + userControls.nameActualLength + 5,
				y = userControls.tbName.y,
				right = 0,
				bottom = 4,
				objectOverrideFont = WG.Chobby.Configuration:GetFont(1, "party_invite", {color = {0.5, 0.5, 0.5, 1}}),
				parent = userControls.mainControl
			}
		end
		userControls.tbPartyStatus:SetText(string.format("(%s)", i18n(userControls.partyStatus)))
	else
		if userControls.tbPartyStatus then
			userControls.tbPartyStatus:Dispose()
			userControls.tbPartyStatus = nil
		end
	end
end

local function UpdateUserComboboxOptions(_, userName)
	for i = 1, #userListList do
		local userList = userListList[i]
		if userList ~= namedUserList["replayTooltipUsers"] then
			local data = userList[userName]
			if data then
				data.mainControl.items = GetUserComboBoxOptions(userName, data.isInBattle, data,
																data.imTeamColor ~= nil, data.imSide ~= nil)
			end
		end
	end
end

local function UpdateUserActivitySingleList(userList, userName, status)
	local userControls = userList[userName]
	if userControls then
		userControls.mainControl.items = GetUserComboBoxOptions(userName, userControls.isInBattle, userControls,
																userControls.imTeamColor ~= nil, userControls.imSide ~= nil)
		if userControls.imLevel then
			userControls.imLevel.file = GetUserRankImageName(userName, userControls)
			userControls.imLevel:Invalidate()
		end

		userControls.tbName.font = GetUserNameColorFont(userName, userControls)
		userControls.tbName:Invalidate()

		UpdateUserStatusImage(userName, userControls)
		UpdateUserControlStatus(userName, userControls)

		if status and (status["skill"] or status["skillUncertainty"]) then
			local userInfo = userControls.replayUserInfo or userControls.lobby:GetUser(userName) or {}
			local userID = tonumber(userInfo.accountID)
			local battle = userControls.tooltipBattle or (userInfo.battleID and userControls.lobby:GetBattle(userInfo.battleID))
			local skillKey, unKey = ResolveSnapshotColumns(battle)
			if userID and skillKey and unKey then
				local liveSkill = tonumber(status["skill"] or userInfo.skill)
				if liveSkill then
					local update = {
						name = userInfo.name,
						skillKey = skillKey,
						unKey = unKey,
						skill = liveSkill,
						-- Live lobby skill is already adjusted; don't subtract again.
						un = 0,
					}
					if openSkillLoaded and openSkillCache then
						openSkillCache[userID] = openSkillCache[userID] or { id = userID }
						local entry = openSkillCache[userID]
						if update.name then
							entry.name = update.name
						end
						entry[update.skillKey] = update.skill
						entry[update.unKey] = update.un
					else
						openSkillPendingUpdates[userID] = update
					end
				end
			end
		end

		if status and (status["skill"] or status["skillUncertainty"]) and userControls.showSkill then
			local displaySkill = userControls.showSkillAlways or ((userControls.isPlaying or userControls.replayUserInfo) and WG.Chobby.Configuration.showSkillOpt > 1)
			if displaySkill then
				local skill, skillColorFont = GetUserSkillFont(userName, userControls)
				userControls.tbSkill:SetText(skill)
				userControls.tbSkill.font = skillColorFont
				userControls.tbSkill:Invalidate()
			end
		end
	end
end

local function UpdateUserActivity(listener, userName, status)
	for i = 1, #userListList do
		local userList = userListList[i]
		if userList ~= namedUserList["replayTooltipUsers"] then
			UpdateUserActivitySingleList(userList, userName, status)
		end
	end
end

local function UpdateUserActivityList(listener, userList)
	for i = 1, #userList do
		UpdateUserActivity(_, userList[i])
	end
end

-- only reacts to map changes
local function UpdateBattleInfo(listener, battleID, battleInfo)
	local Configuration  = WG.Chobby.Configuration

	if battleInfo.mapName ~= nil then
		for userName, userControls in pairs(friendUsers) do	
			local userInfo = userControls.lobby:TryGetUser(userName)
			if userControls.minimapImage and userInfo.battleID and userInfo.battleID == battleID then
				if battleInfo.mapName then
					local mapImageFile, needDownload = Configuration:GetMinimapSmallImage(battleInfo.mapName)
					userControls.minimapImage.file = mapImageFile
					userControls.minimapImage.checkFileExists = needDownload
					userControls.minimapImage:Show()
				else
					userControls.minimapImage:Hide()
				end
			end	
		end
	end
end

local function UpdateUserBattle(listener, battleID, userName)
	if not friendUsers[userName] then
		return
	end
	local userControls = friendUsers[userName]

	if userControls.minimapImage then
		local userInfo = userControls.lobby:TryGetUser(userName)
		local battleInfo = userControls.lobby:GetBattle(battleID)
		if battleID == userInfo.battleID and battleInfo.mapName then
			local mapImageFile, needDownload = WG.Chobby.Configuration:GetMinimapSmallImage(battleInfo.mapName)
			userControls.minimapImage.file = mapImageFile
			userControls.minimapImage.checkFileExists = needDownload
			userControls.minimapImage:Show()
		else
			userControls.minimapImage:Hide()
		end
	end	
end

--[[ ZK only
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
--]]

local function GetPartyStatus(partyID, username)
	local party = lobby.parties[partyID]
	if party then
		if party.members[username] then
			return "party_status_member"
		elseif party.invites[username] then
			return "party_status_invite"
		end
	end
end


local function OnPartyStatusUpdate(listener, partyID, username)
	if lobby.myUserName == username then
		for name, list in pairs(namedUserList) do
			for _username, userControls in pairs(list) do
				userControls.partyStatus = GetPartyStatus(lobby.parties[name] and name or lobby.myPartyID, _username)
				UpdateVisualPartyStatus(userControls)
				userControls.mainControl.items = GetUserComboBoxOptions(
					_username, userControls.isInBattle, userControls, userControls.imTeamColor ~= nil, userControls.imSide ~= nil
				)
			end
		end
	else
		for name, list in pairs(namedUserList) do
			local userControls = list[username]
			if userControls then
				userControls.partyStatus = GetPartyStatus(lobby.parties[name] and name or lobby.myPartyID, username)
				UpdateVisualPartyStatus(userControls)
				userControls.mainControl.items = GetUserComboBoxOptions(
					username, userControls.isInBattle, userControls, userControls.imTeamColor ~= nil, userControls.imSide ~= nil
				)
			end
		end
	end
end

local function UpdateUserBattleStatus(listener, userName, battleStatusDiff)
	local Configuration = WG.Chobby.Configuration
	UpdateUserComboboxOptions(_, userName)
	for i = 1, #userListList do
		local userList = userListList[i]
		if userList ~= namedUserList["replayToolTipUsers"] then
			local userControls = userList[userName]
			if userControls then

				-- if this battleStatus is about us and we are switching between spec and player > Then update ComboboxOption of all users in my battle, because the right to access options is dependent of our own spec status (e.g. changeTeam, AddBonus, MakeBoss, ForceSpectator... are only allowed if we are a player)
				if userList == namedUserList["battleUsers"] and battleStatusDiff
					and (
						(battleStatusDiff['isSpectator'] ~= nil and userName == userControls.lobby:GetMyUserName())
					or battleStatusDiff['isBoss'] ~= nil) then
					for username, _ in pairs(battleUsers) do
						UpdateUserComboboxOptions(_, username)
					end
				end

				local bs = userControls.lobby:GetUserBattleStatus(userName) or {}
				userControls.isPlaying = bs.isSpectator == false
				userControls.isBoss = bs.isBoss or false
				userControls.isMuted = bs.isMuted or false

				UpdateUserActivity(_, userName, {})

				local offset = 0
				if userControls.tbQueuePos then
					userControls.isInQueue = bs.queuePos and bs.queuePos > 0 or false
					userControls.tbQueuePos:SetVisibility(userControls.isInQueue)
					if userControls.isInQueue then
						local queuePos = bs.queuePos .. "."
						offset = offset + 2
						userControls.tbQueuePos:SetPos(offset)
						offset = offset + 23
						userControls.tbQueuePos:SetText(queuePos)
						userControls.tbQueuePos:Invalidate()
					end
				end

				if userControls.imStatus then
					UpdateUserStatusImage(userName, userControls)
					if userControls.isPlaying then
						offset = offset + 1
						userControls.imStatus:SetPos(offset)
						offset = offset + 21
					end
				end

				--[[
				local offset = 0
				local displaySync = userControls.isPlaying and bs.sync and bs.sync == 2 -- 2 = Sync Status Downloading
				if userControls.imSyncStatus then
					userControls.imSyncStatus:SetVisibility(displaySync)
					if displaySync then
						userControls.imSyncStatus.file = GetUserSyncStatus(userName, userControls)
						offset = offset + 1
						userControls.imSyncStatus:SetPos(offset)
						offset = offset + 21
					end
				end

				local displayReady = userControls.isPlaying and not displaySync	
				if userControls.imReadyStatus and not isSingleplayer then
					userControls.imReadyStatus:SetVisibility(displayReady)
					if displayReady then
						userControls.imReadyStatus.file = GetUserReadyStatus(userName, userControls)
						offset = offset + 1
						userControls.imReadyStatus:SetPos(offset)
						offset = offset + 21
					end
				end
				--]]

				if not userControls.isSingleplayer then
					
					if userControls.showCountry then
						userControls.imCountry:SetVisibility(Configuration.showCountry)
						if Configuration.showCountry then	
							offset = offset + 1
							userControls.imCountry:SetPos(offset + 2)
							offset = offset + 21
						end
					end

					if userControls.showRank then
						userControls.imLevel:SetVisibility(Configuration.showRank)
						if Configuration.showRank then
							offset = offset + 1
							userControls.imLevel:SetPos(offset)
							offset = offset + 21
						end
					end

					-- Skill: show only in battlelist (limited by spring lobby protocol, skill not available for users outside of own battle)
					if userControls.showSkill then
						local displaySkill = userControls.showSkillAlways or (userControls.isPlaying and Configuration.showSkillOpt > 1)
						userControls.tbSkill:SetVisibility(displaySkill)
						if displaySkill then
							offset = offset + 2
							userControls.tbSkill:SetPos(offset)
							offset = offset + 18
							local skill, skillColorFont = GetUserSkillFont(userName, userControls)
							userControls.tbSkill:SetText(skill)
							userControls.tbSkill.font = skillColorFont
							userControls.tbSkill:Invalidate()
						end
					end
				end

				if userControls.imClan then
					offset = offset + 1
					userControls.imClan:SetPos(offset)
					offset = offset + 21
				end

				if userControls.imSide then
					local sideSelected = bs.side ~= nil
					userControls.imSide:SetVisibility(userControls.isPlaying and sideSelected)
					if sideSelected then
						userControls.imSide.file = Configuration:GetSideById(bs.side).logo
					end
					if userControls.isPlaying and sideSelected then
						offset = offset + 2
						userControls.imSide:SetPos(offset)
						offset = offset + 22
					end
				end

				offset = offset + 2
				userControls.tbName:SetPos(offset)
				userControls.nameStartY = offset
				local truncatedName = StringUtilities.TruncateStringIfRequiredAndDotDot(userName, userControls.tbName.font, userControls.maxNameLength and (userControls.maxNameLength - offset))
				userControls.nameStartY = offset
				
				userControls.tbName.font = GetUserNameColorFont(userName, userControls)
				userControls.tbName:Invalidate()
				if truncatedName then
					userControls.tbName:SetText(truncatedName)
					userControls.nameTruncated = true
				end
				userControls.nameActualLength = userControls.tbName.font:GetTextWidth(userControls.tbName.text)
				offset = offset + userControls.nameActualLength

				if userControls.imTeamColor then
					userControls.imTeamColor.color = bs.teamColor
					userControls.imTeamColor:SetVisibility(userControls.isPlaying)
					offset = offset + 5
					userControls.imTeamColor:SetPos(offset)
					offset = offset + 20
					userControls.imTeamColor:Invalidate()
				end

				if userControls.lblHandicap then
					local handicap = bs.handicap
					if handicap ~= nil then
						local handicaptxt = ''
						if bs.handicap == 0 then
							userControls.lblHandicap:SetVisibility(false)
						else
							if bs.handicap > 0 then
								handicaptxt = '+'..tostring(bs.handicap)
							else
								handicaptxt = tostring(bs.handicap)
							end
							userControls.lblHandicap:SetCaption(handicaptxt)
							userControls.lblHandicap:SetVisibility(true)
							userControls.lblHandicap:SetPos(offset)
						end
					end
					if not userControls.isPlaying or handicap == nil then
						-- If the player is spectating, don't show handicap label regardless of its value.
						userControls.lblHandicap:SetVisibility(false)
					end
					userControls.lblHandicap:Invalidate()
				end
				UpdateUserControlStatus(userName, userControls) -- moves status images right of userName according to nameStartY and nameActualLength
			end
		end
	end
end

-- 2023-06-29 FB: can be called in 3 modes
-- 1. userName is given and voteOption is either yes/no/blank -> color of user is changed to green/red/orange
-- 2. username nil and voteOption = default -> all username colors, that were changed before, are returned to default (e.g white or moderator/friend/bot color)
-- 3. username nil and voteOption = initVote -> all username colors are overwritten with grey
local function OnUserVoted(listener, userName, voteOption)
	if voteOption ~= "yes" and voteOption ~= "no" and voteOption ~= "blank" and voteOption ~= "default" and voteOption ~= "initVote" then
		return
	end
	
	if not userName then
		
		if voteOption == "default" then -- revert all changed username colors to default after vote
			usersAllowedToVote = {}
			for _, userName2 in pairs(votedUsers) do
				OnUserVoted(_, userName2, voteOption)
			end
			votedUsers = {}
			
		elseif voteOption == "initVote" --[[and next(votedUsers) == nil]] then -- set all playing battleUsers colors to white on vote start
			OnUserVoted(_, _, "default") -- 1. revert any changed colors (could be spectator by now, too, or left battle)
			for userName2, userControls2 in pairs(battleUsers) do -- 2. set all users that are allowed to vote to grey (allowed are only users that were "isPlaying" on time of vote start)
				if userControls2.isPlaying then
					usersAllowedToVote[userName2] = true
					OnUserVoted(_, userName2, voteOption)
				end
			end
		end
		return
	end
	
	local userControls = battleUsers[userName]
	if not userControls then
		return
	end

	if userControls.tbName then
		if voteOption == "default" then
			userControls.tbName.font = GetUserNameColorFont(userName, userControls)
			userControls.tbName:Invalidate()
			return
		end
		if userControls.isPlaying then
			userControls.tbName.font = WG.Chobby.Configuration:GetFont(1, "vote1" .. voteOption, {color = WG.Chobby.Configuration.voteColor[voteOption]}) -- voteOption can be yes, no, blank, initVote
			userControls.tbName:Invalidate()
		end
	end

	if not votedUsers[userName] then
		table.insert(votedUsers, userName)
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
	local showReady          = opts.showReady
	local showFounder        = opts.showFounder
	local showModerator      = opts.showModerator
	local comboBoxOnly       = opts.comboBoxOnly
	local showTeamColor      = opts.showTeamColor
	local showSide           = opts.showSide
	local showHandicap		 = opts.showHandicap
	local showJoinQueue		 = opts.showJoinQueue

	local userControls = reinitialize or {}

	local Configuration = WG.Chobby.Configuration

	userControls.showFounder        = showFounder
	userControls.showModerator      = showModerator
	userControls.isInBattle         = isInBattle
	userControls.lobby              = (isSingleplayer and WG.LibLobby.localLobby) or lobby
	userControls.isSingleplayer     = isSingleplayer
	userControls.disableInteraction = disableInteraction
	userControls.steamInvite        = opts.steamInvite
	userControls.hideStatus         = opts.hideStatus
	userControls.hideStatusInvite   = opts.hideStatusInvite
	userControls.hideStatusIngame   = opts.hideStatusIngame
	userControls.hideStatusAway     = opts.hideStatusAway
	userControls.dropdownWhitelist  = opts.dropdownWhitelist
	userControls.showSkill          = opts.showSkill or false
	userControls.showSkillAlways    = opts.showSkillAlways or false
	userControls.showRank           = opts.showRank or false
	userControls.showCountry        = opts.showCountry or false
	userControls.isSingleplayer     = opts.isSingleplayer or false -- is needed by UpdateUserBattleStatus
	userControls.replayUserInfo		= opts.replayUserInfo or false
	userControls.colorizeFriends    = opts.colorizeFriends or false
	userControls.partyStatus        = opts.partyStatus
	userControls.showPartyStatus    = opts.showPartyStatus
	userControls.useSnapshotSkill   = opts.useSnapshotSkill or false
	userControls.tooltipBattle      = opts.tooltipBattle

	local userInfo = userControls.replayUserInfo or userControls.lobby:GetUser(userName) or {}
	local bs = userControls.replayUserInfo or userControls.lobby:GetUserBattleStatus(userName) or {}

	userControls.isPlaying = bs.isSpectator == false
	userControls.isInQueue = bs.queuePos and bs.queuePos > 0 or false
	userControls.isBoss = bs.isBoss or false
	userControls.isMuted = bs.isMuted or false

	if reinitialize then
		userControls.mainControl:ClearChildren()
	else
		local tooltip = ((isSingleplayer and Configuration.USER_SP_TOOLTIP_PREFIX) or (isInBattle and Configuration.USER_MP_TOOLTIP_PREFIX) or Configuration.USER_CH_TOOLTIP_PREFIX) .. userName

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
			showSelection = false,
			objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
			--objectOverrideFont = WG.Chobby.Configuration:GetFont(2,{shadow = false}), -- this for some reason allocates a new font object :(
			itemHeight = 30,
			selected = 0,
			maxDropDownWidth = large and 220 or 170,
			minDropDownHeight = 0,
			maxDropDownHeight = 400,
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
					elseif selectedName == "Copy Name" then
						Spring.SetClipboard(userName)
					elseif selectedName == "Kickban" then
						local function YesFunc()
							lobby:SayBattle("!kickban "..userName)
						end
						WG.Chobby.ConfirmationPopup(YesFunc, "Are you sure you want to kickban " .. userName .. "? This will call a vote if not boss.", nil, nil, nil, "Kickban", "Cancel", nil)
					elseif selectedName == "Remove" then
						userControls.lobby:RemoveAi(userName)
					elseif selectedName == "Unfriend" then
						local function YesFunc()
							userControls.lobby:RemoveFriends({userInfo.accountID})
						end
						WG.Chobby.ConfirmationPopup(YesFunc, "Are you sure you want to remove " .. userName .. " from your friends list?", nil, nil, nil, "Unfriend", "Cancel", nil)
					elseif selectedName == "Friend" then
						local userInfo = userControls.lobby:GetUser(userName)
						if userInfo and userInfo.hasFriendRequest then
							userControls.lobby:AcceptFriendRequestByID({userInfo.accountID})
						else
							userControls.lobby:FriendRequestByID(userInfo.accountID)
						end
					--[[ ZK only
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
					--]]
					elseif selectedName == "Join Battle" then
						local userInfo = userControls.lobby:GetUser(userName) or {}
						if userInfo.battleID then
							WG.Chobby.interfaceRoot.TryToJoinBattle(userInfo.battleID)
						end
					--[[ ZK only
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
					--]]
					elseif selectedName == "Invite to Party" then
						if lobby.myPartyID then
							lobby:InvitePlayerToMyParty(userName, nil, function(errorMessage) WG.Chobby.ErrorPopup(i18n("error_party_invite_player_failed", { error_message = errorMessage })) end)
						else
							lobby:CreateParty(function()
								lobby:InvitePlayerToMyParty(userName, nil, function(errorMessage) WG.Chobby.ErrorPopup(i18n("error_party_invite_player_failed", { error_message = errorMessage })) end)
							end,
							function(errorMessage)
								WG.Chobby.ErrorPopup(i18n("error_party_invite_player_failed", { error_message = errorMessage }))
							end)
						end
					elseif selectedName == "Cancel Party Invite" then
						lobby:CancelInviteToMyParty(userName, nil, function(errorMessage) WG.Chobby.ErrorPopup(i18n("error_party_cancel_invite_failed", { error_message = errorMessage })) end)
					elseif selectedName == "Change Color" then
						local battleStatus = userControls.lobby:GetUserBattleStatus(userName) or {}
						if battleStatus.isSpectator then
							return
						end
						WG.ColorChangeWindow.CreateColorChangeWindow({
							initialColor = battleStatus.teamColor,
							OnAccepted = function(color)
								if userName == userControls.lobby:GetMyUserName() then
									userControls.lobby._requestedBattleStatus = true -- fake the request to ensure it gets sent
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
					elseif selectedName == "Change Faction" then
						local battleStatus = userControls.lobby:GetUserBattleStatus(userName) or {}
						if battleStatus.isSpectator then
							return
						end
						WG.SideChangeWindow.CreateSideChangeWindow({
							initialSide = battleStatus.side or 0,
							OnAccepted = function(sideId)
								if userName == userControls.lobby:GetMyUserName() then
									Configuration:SetConfigValue("lastFactionChoice", sideId)
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
						local bonusAmount = battleStatus.handicap
						if battleStatus.isSpectator then
							return
						end
						WG.TeamChangeWindow.CreateTeamChangeWindow({
							initialTeam = (battleStatus.allyNumber or 1) + 1,
							maxTeams = 16,
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
										if not isSingleplayer and bonusAmount and bonusAmount ~= 0 then
											lobby:SayBattle("!force "..userName.." bonus ".. tostring(bonusAmount))
										end
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
					elseif selectedName == "Clone AI" then
						local function CloneFunc(numberOfClones)
							local status = userControls.lobby:GetUserBattleStatus(userName)
								if not status then return end

								local aiSettings = {
									aiLib = status.aiLib,
									allyNumber = status.allyNumber,
									aiVersion = status.aiVersion,
									aiOptions = status.aiOptions,
									battleStatusOptions = {
										teamColor = status.teamColor,
										side = status.side,
										handicap = status.handicap,
									}
								}
								for i = 1, numberOfClones do
									local counter = 1
									local aiName

									local found = true
									while found do
										found = false
										aiName = userName:gsub("%(%d+%)", "(" .. tostring(counter) .. ")")
										for _, existingName in pairs(userControls.lobby.battleAis) do
											if aiName == existingName then
												found = true
												break
											end
										end
										counter = counter + 1
									end
									userControls.lobby:AddAi(
										aiName,
										aiSettings.aiLib,
										aiSettings.allyNumber,
										aiSettings.aiVersion,
										aiSettings.aiOptions,
										aiSettings.battleStatusOptions
									)

									if not isSingleplayer and aiSettings.battleStatusOptions.handicap and aiSettings.battleStatusOptions.handicap ~= 0 then
										lobby:SayBattle("!force " .. aiName .. " bonus ".. tostring(aiSettings.battleStatusOptions.handicap))
									end
								end

						end
						if isSingleplayer == true then
							WG.IntegerSelectorWindow.CreateIntegerSelectorWindow({
								defaultValue = 1,
								minValue = 1,
								maxValue = 16,
								caption = "Clone AI",
								labelCaption = "Create this many new AI players with the same profile, settings, and bonus as "..userName..":",
								OnAccepted = function(numberOfClones)
									CloneFunc(numberOfClones)
								end
							})
						else
							CloneFunc(1) -- Limit to 1 clone in multiplayer to prevent flood protection kick
						end
					elseif selectedName == "Ring" then
						--lobby:Ring(userName)
						lobby:SayBattle("!ring "..userName)
					elseif selectedName == "Make Boss" then
						lobby:SayBattle("!boss "..userName)
					elseif selectedName == "Disable Boss" then
						lobby:SayBattle("!unboss "..userName)
					elseif selectedName == "Force Spectator" then
						lobby:SayBattle("!spec "..userName)
					elseif selectedName == "Report" and Configuration.gameConfig.link_reportPlayer ~= nil then
						local userInfo = userControls.lobby:GetUser(userName) or {}
						if userInfo.accountID then
							WG.BrowserHandler.OpenUrl(Configuration.gameConfig.link_reportPlayer(userInfo.accountID))
						end
					elseif selectedName == "Unignore" then
						userControls.lobby:c_user_reset_relationship(userName) -- provisionally: removes disregards and follows
					elseif selectedName == "Ignore" or selectedName == "Unavoid" then
						local function YesFunc()
							userControls.lobby:c_user_relationship(userName, Configuration.IGNORE)
						end
						WG.Chobby.ConfirmationPopup(YesFunc, "Are you sure you want to ignore " .. userName .. "?", nil, nil, nil, "Ignore", "Cancel", nil)
					elseif selectedName == "Avoid" or selectedName == "Unblock" then
						userControls.lobby:c_user_relationship(userName, Configuration.AVOID)
					elseif selectedName == "Block" then
						userControls.lobby:c_user_relationship(userName, Configuration.BLOCK)
					elseif selectedName == "Report User" and not isSingleplayer then
						WG.Chobby.ConfirmationPopup(
							function()
								lobby:ReportPlayer(userName, "lobby", "nil", "dummyReason")
							end,
							"Report ".. userName .."\n \n" .. "Open the Chat tab after clicking OK, check the message from Coordinator, click the link to the website and fill the report out there.",
							nil,
							nil,
							nil,
							"OK"
						)
						-- WG.TextEntryWindow.CreateTextEntryWindow({
						-- 	defaultValue = "",
						-- 	caption = "Report "..userName,
						-- 	labelCaption = "Report ".. userName .." for abusive behaviour or violation of the terms of service. Please specify a description of the event.",
						-- 	width = 360,
						-- 	--ebheight = 120,
						-- 	oklabel = "Report",
						-- 	disableAcceptHotkey = true,
						-- 	url = 'https://www.beyondallreason.info/code-of-conduct',
						-- 	OnAccepted = function(reportreason)
						-- 		if isSingleplayer then
						-- 			-- hell no
						-- 		else
						-- 			lobby:ReportPlayer(userName,"lobby","nil",reportreason)
						-- 		end
						-- 	end
						-- })
					end
				end
			}
		}
	end

	if comboBoxOnly then
		return userControls
	end

	if not isSingleplayer and isInBattle and not suppressSync then
		offset = offset + 1
		userControls.imStatus = Image:New {
			name = "imStatus",
			x = offset,
			y = offsetY + 1,
			width = 21,
			height = 19,
			parent = userControls.mainControl,
			keepAspect = true,
			file = getUserStatusImage(userName, userControls),
		}
		userControls.imStatus:SetVisibility(userControls.isPlaying)
		if userControls.isPlaying then
			offset = offset + 21
		else
			offset = offset - 1
		end
	end

	--[[
	local displaySync = userControls.isPlaying and (bs and bs.sync and bs.sync == 2) -- 2 = Sync Status Downloading
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
		userControls.imSyncStatus:SetVisibility(displaySync)
		if displaySync then
			offset = offset + 21
		else
			offset = offset - 1
		end
	end

	local displayReady = userControls.isPlaying and not displaySync
	if showReady then
		offset = offset + 1
		userControls.imReadyStatus = Image:New {
			name = "imReadyStatus",
			x = offset,
			y = offsetY + 1,
			width = 21,
			height = 19,
			parent = userControls.mainControl,
			keepAspect = true,
			file = GetUserReadyStatus(userName, userControls),
		}
		userControls.imReadyStatus:SetVisibility(displayReady)
		if displayReady then
			offset = offset + 21
		else
			offset = offset - 1
		end
	end
	--]]

	if not isSingleplayer and showJoinQueue then
		offset = offset + 2
		local queuePos = bs and bs.queuePos or 0
		queuePos = queuePos .. "."
		userControls.tbQueuePos = TextBox:New {
			name = "queuePos",
			x = offset,
			y = offsetY + 4,
			right = 0,
			bottom = 5,
			align = "left",
			parent = userControls.mainControl,
			objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
			objectOverrideHintFont = WG.Chobby.Configuration:GetFont(2),
			text = tostring(queuePos),
		}
		userControls.tbQueuePos:Invalidate()
		userControls.tbQueuePos:SetVisibility(userControls.isInQueue)
		if userControls.isInQueue then
			offset = offset + 23
		else
			offset = offset - 2
		end
	end
	
	if not isSingleplayer then
		if userControls.showCountry then
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
			userControls.imCountry:SetVisibility(Configuration.showCountry)
			if Configuration.showCountry then
				offset = offset + 21
			else
				offset = offset - 1
			end
		end

		if userControls.showRank then
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
			userControls.imLevel:SetVisibility(Configuration.showRank)
			if Configuration.showRank then
				offset = offset + 21
			else
				offset = offset - 1
			end
		end

		if userControls.showSkill then
			local skill, skillColorFont = GetUserSkillFont(userName, userControls)
			offset = offset + 2
			userControls.tbSkill = TextBox:New {
				name = "skill",
				x = offset,
				y = offsetY + 4,
				right = 0,
				bottom = 5,
				align = "left",
				parent = userControls.mainControl,
				objectOverrideFont = skillColorFont,
				objectOverrideHintFont = skillColorFont,
				text = skill,
			}
			local displaySkill = userControls.showSkillAlways or ((userControls.isPlaying or userControls.replayUserInfo) and Configuration.showSkillOpt > 1)
			userControls.tbSkill:SetVisibility(displaySkill)
			if displaySkill then
				offset = offset + 20
			else
				offset = offset - 2
			end
		end
	end

	-- ZK specific
	-- local clanImage, needDownload = GetUserClanImage(userName, userControls)
	-- if clanImage then
	-- 	offset = offset + 1
	-- 	userControls.imClan = Image:New {
	-- 		name = "imClan",
	-- 		x = offset,
	-- 		y = offsetY + 1,
	-- 		width = 21,
	-- 		height = 19,
	-- 		parent = userControls.mainControl,
	-- 		keepAspect = true,
	-- 		file = clanImage,
	-- 		fallbackFile = Configuration:GetLoadingImage(1),
	-- 		checkFileExists = needDownload,
	-- 	}
	-- 	offset = offset + 21
	-- end

	if showSide then
		local file = nil
		bs = bs or {}
		if bs.side ~= nil then
			file = Configuration:GetSideById(bs.side or 0).logo
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
		if bs.isSpectator or file == nil then
			userControls.imSide:Hide()
		else
			offset = offset + 22
		end
	end

	offset = offset + 2

	-- This is also used for top name tag
	userControls.tbName = TextBox:New { 
		name = "tbName",
		x = offset,
		y = offsetY + 4,
		right = 0,
		bottom = 4,
		align = "left",
		parent = userControls.mainControl,
		objectOverrideFont = Configuration:GetFont(1),
		objectOverrideHintFont = Configuration:GetFont(1),
		text = userName,
	}

	local truncatedName = StringUtilities.TruncateStringIfRequiredAndDotDot(userName, userControls.tbName.font, maxNameLength and (maxNameLength - offset))
	userControls.nameStartY = offset
	userControls.maxNameLength = maxNameLength

	userControls.tbName.font = GetUserNameColorFont(userName, userControls)
	userControls.tbName:Invalidate()

	if truncatedName then
		userControls.tbName:SetText(truncatedName)
		userControls.nameTruncated = true
	end
	userControls.nameActualLength = userControls.tbName.font:GetTextWidth(userControls.tbName.text)
	offset = offset + userControls.nameActualLength

	if showTeamColor then
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
			color = bs.teamColor
		}
		userControls.nameActualLength = userControls.nameActualLength + 25
		if bs.isSpectator then
			userControls.imTeamColor:Hide()
			offset = offset - 5
		else
			offset = offset + 20
		end
	end

	if bs and showHandicap then
		local handicaptxt = ''
		if bs.handicap and bs.handicap > 0 then
			handicaptxt = '+'..tostring(bs.handicap)
		elseif bs.handicap and bs.handicap < 0 then
			handicaptxt = tostring(bs.handicap)
		end
		userControls.lblHandicap = Label:New{
			name = "lblHandicap",
			x = offset,
			y = offsetY,
			parent = userControls.mainControl,
			caption = handicaptxt,
			objectOverrideFont = Configuration:GetFont(8),
			tooltip = "Handicap",
		}
	end

	--Spring.Utilities.TraceEcho(userName,"hide", hideStatus == true,"large",large == true) 
	if not hideStatus then
		userControls.statusImages = {}
		UpdateUserControlStatus(userName, userControls)
		if large then
			offsetY = offsetY + 35
			offset = 5
			local imgFile, status, font = GetUserStatusFont(userName, isInBattle, userControls)
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
				objectOverrideFont = font,
			}

			userControls.tbName.font = font
			userControls.tbName:Invalidate()

			local battle = userControls.lobby:GetBattle(userInfo.battleID)
			local mapImageFile = nil
			local needDownload = nil
			if battle and battle.mapName then
				local mapImageFile, needDownload = Configuration:GetMinimapSmallImage(battle.mapName)
			end
			if not userControls.minimapImage then
				userControls.minimapImage = Image:New {
					name = "minimapImage",
					x = -76,
					y = 6,
					width = 70,
					height = 70,
					valign = 'top',
					keepAspect = true,
					file = mapImageFile,
					fallbackFile = Configuration:GetLoadingImage(2),
					checkFileExists = needDownload,
					parent = userControls.mainControl,
				}
			end
			userControls.minimapImage:SetVisibility(battle and battle.mapName and true or false)
		end
	end

	UpdateVisualPartyStatus(userControls)

	if autoResize then
		userControls.mainControl.OnResize = userControls.mainControl.OnResize or {}
		userControls.mainControl.OnResize[#userControls.mainControl.OnResize + 1] = function (obj, sizeX, sizeY)
			local maxWidth = sizeX - userControls.nameStartY - 40
			
			local truncatedName = StringUtilities.GetTruncatedStringWithDotDot(userName, userControls.tbName.font, maxWidth)
			userControls.tbName:SetText(truncatedName)

			offset = userControls.nameStartY + userControls.tbName.font:GetTextWidth(userControls.tbName.text) + 3
			if userControls.imTeamColor then
				offset = offset + 25
			end
			if not large and userControls.statusImages then
				for i = 1, #userControls.statusImages do
					userControls.statusImages[i]:SetPos(offset)
					offset = offset + 21
				end
			end

			if userControls.tbPartyStatusInvite then
				userControls.tbPartyStatusInvite:SetPos(offset)
			end
		end
	end

	local function OnConfigurationChange(listener, key, value)
		if key == "showCountry" and userControls.showCountry then
			UpdateUserBattleStatus(_, userName)
		elseif key == "showRank" and userControls.showRank then
			UpdateUserBattleStatus(_, userName)
		elseif key == "showSkillOpt" and userControls.showSkill then
			UpdateUserBattleStatus(_, userName)
		end
	end

	Configuration:AddListener("OnConfigurationChange", OnConfigurationChange)

	-- This is always checked against main lobby.
	userControls.needReinitialization = lobby.status ~= "connected"

	return userControls
end
local prevram = 0
local function plotMem()
	if tracy then
		local ramuse = gcinfo()
		Spring.LuaTracyPlot("ChobbyMem",  ramuse)
		if ramuse > prevram then
			tracy.Message((debug.getinfo(2, 'n') and debug.getinfo(2, 'n').name) or "???")
		end
		prevram = ramuse
	end
end
local function GetUserControlsWrapper(userName,opts)
	debug.sethook(plotMem, 'c r')
	local res =  GetUserControlsWrapped(userName, opts)
	debug.sethook()
	return res
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
	userControls.mainControl:SetPos(math.max(0, x - 60), screenHeight - y - userControls.mainControl.height + 5, 170)

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

function userHandler.SetTooltipBattle(battle)
	userHandler._tooltipBattle = battle
end

function userHandler.GetSnapshotSkillValue(userID, battle)
	local numericUserID = tonumber(userID)
	if not numericUserID then
		return
	end
	local snapSkill, snapUn = GetSnapshotSkill(numericUserID, battle)
	if not snapSkill or snapSkill < 0 then
		return
	end
	local adjusted = snapSkill - (snapUn or 0)
	if adjusted < 0 then
		adjusted = 0
	end
	return adjusted
end

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
		autoResize      = true,
		isInBattle      = true,
		showReady       = true,
		showCountry     = true,
		showRank        = true,
		showSkill       = true,
		showSync        = WG.Chobby.Configuration.showSync,
		showModerator   = true,
		showFounder     = true,
		showTeamColor   = not WG.Chobby.Configuration.gameConfig.disableColorChoosing,
		showSide        = WG.Chobby.Configuration:GetSideData() ~= nil,
		showHandicap    = WG.Chobby.Configuration.gameConfig.showHandicap,
		showJoinQueue   = true,
		colorizeFriends = true,
	})
end

function userHandler.GetTooltipUser(userName)
	return _GetUser(tooltipUsers, userName, {
		isInBattle         = true,
		suppressSync       = true,
		showModerator      = true,
		showFounder        = true,
		showCountry        = true,
		showRank           = true,
		showSkill          = true,
		showSkillAlways    = true,
		useSnapshotSkill   = true,
		tooltipBattle      = userHandler._tooltipBattle,
		disableInteraction = true,
		colorizeFriends    = true,
	})
end

function userHandler.GetReplayTooltipUser(replayUserInfo, maxNameLength)
	if replayTooltipUsers[replayUserInfo.name] then
		local replayUser = replayTooltipUsers[replayUserInfo.name]
		replayUser.replayUserInfo = replayUserInfo
		UpdateUserActivitySingleList(replayTooltipUsers, replayUserInfo.name, replayUserInfo)
		return replayUser.mainControl
	end

	return _GetUser(replayTooltipUsers, replayUserInfo.name, {
		isInBattle         = false,
		suppressSync       = true,
		showModerator      = false,
		showFounder        = false,
		showCountry        = true,
		showRank           = true,
		disableInteraction = true,
		hideStatus         = true,
		showSkill          = true,
		replayUserInfo     = replayUserInfo,
		colorizeFriends    = true,
		maxNameLength      = maxNameLength,
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
		showCountry    = true,
		colorizeFriends    = true,
	})
end

function userHandler.GetDebriefingUser(userName)
	return _GetUser(debriefingUsers, userName, {
		maxNameLength  = WG.Chobby.Configuration.chatMaxNameLength,
		showModerator  = true,
	})
end

function userHandler.GetPartyUser(userName, partyID, partyStatus)
	local partyUsers = namedUserList[partyID]
	if not partyUsers then
		partyUsers = {}
		namedUserList[partyID] = partyUsers
		userListList[#userListList] = partyUsers
	end
	return _GetUser(partyUsers, userName, {
		showCountry = true,
		showRank = true,
		colorizeFriends = true,
		height = WG.Chobby.PartyWrapper.ROW_HEIGHT,
		partyStatus = partyStatus,
		showPartyStatus = { party_status_invite = true },
		hideStatus = true -- Ideally we'd show this, but it has so much of a hardcoded position that I don't want to change it out for the invite.
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
		showPartyStatus = { party_status_invite = true, party_status_member = true },
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
	-- OnFriendList leads to duplicate updates, each friend is propagated by OnFriend already
	-- lobby:AddListener("OnFriendList", UpdateUserActivityList)

	lobby:AddListener("OnUpdateUserStatus", UpdateUserActivity)

	lobby:AddListener("OnFriend", UpdateUserActivity)
	
	-- little dirty here. this one is meant to exist temporarily until api_user_handler is switched to use accountID as primary anchor
	lobby:AddListener("OnUnfriendByID", function(listener, userID, userName)
		UpdateUserActivity(_, userName)
	end)
	lobby:AddListener("OnAddDisregardUser", UpdateUserActivity)
	lobby:AddListener("OnRemoveDisregardUser", UpdateUserActivity)

	--[[ ZK only
	lobby:AddListener("OnPartyInviteSent", UpdateUserActivity)
	lobby:AddListener("OnPartyInviteResponse", UpdateUserActivity)

	lobby:AddListener("OnPartyCreate", OnPartyUpdate)
	lobby:AddListener("OnPartyUpdate", OnPartyUpdate)
	lobby:AddListener("OnPartyLeft", OnPartyLeft)
	--]]

	lobby:AddListener("OnAddUser", UpdateUserActivity)
	lobby:AddListener("OnRemoveUser", function(listener, username)
		UpdateUserActivity(listener, username)
		OnPartyStatusUpdate(listener, nil, username)
	end)
	lobby:AddListener("OnAddUser", UpdateUserCountry)
	lobby:AddListener("OnUpdateUserBattleStatus", UpdateUserBattleStatus)
	WG.LibLobby.localLobby:AddListener("OnUpdateUserBattleStatus", UpdateUserBattleStatus)

	lobby:AddListener("OnUserVoted", OnUserVoted)
	lobby:AddListener("OnUpdateBattleInfo", UpdateBattleInfo)
	
	lobby:AddListener("OnJoinedBattle", UpdateUserBattle)
	lobby:AddListener("OnLeftBattle", UpdateUserBattle)

	lobby:AddListener("OnInvitedToParty", OnPartyStatusUpdate)
	lobby:AddListener("OnPartyInviteCancelled", OnPartyStatusUpdate)
	lobby:AddListener("OnJoinedParty", OnPartyStatusUpdate)
	lobby:AddListener("OnLeftParty", function(listener, partyID, username, partyDestroyed)
		local partyUsers = namedUserList[partyID]
		namedUserList[partyID] = nil
		for i = 1, #namedUserList do
			if namedUserList[i] == partyUsers then
				table.remove(namedUserList, i)
			end
		end
		OnPartyStatusUpdate(listener, partyID, username)
	end)
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
	--Spring.LuaTracyPlotConfig("ChobbyMem","Number", true, true, 255)
	AddListeners()
	WG.Delay(DelayedInitialize, 0.1)
	-- Warm the cache without blocking the first user-list update.
	WG.Delay(LoadOpenSkillSnapshot, 0.2)

	WG.UserHandler = userHandler
end

function widget:Update()
	-- Continue incremental snapshot parsing.
	if not openSkillLoadCo or not openSkillLoading then
		return
	end
	if coroutine.status(openSkillLoadCo) ~= "suspended" then
		return
	end
	local ok, err = coroutine.resume(openSkillLoadCo, OPEN_SKILL_LINES_PER_STEP)
	if not ok then
		openSkillLoadFailed = true
		openSkillLoading = false
		openSkillLoadCo = nil
		Spring.Echo("OpenSkill snapshot load failed: " .. tostring(err))
	elseif coroutine.status(openSkillLoadCo) == "dead" then
		openSkillLoadCo = nil
	end
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
