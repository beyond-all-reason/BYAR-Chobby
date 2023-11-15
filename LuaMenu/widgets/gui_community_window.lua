--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Community Window",
		desc      = "Handles community news and links.",
		author    = "GoogleFrog",
		date      = "14 December 2017",
		license   = "GNU LGPL, v2.1 or later",
		layer     = -100000,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Vars

local IMG_LINK = LUA_DIRNAME .. "images/link.png"
local IMG_MISSING = LUA_DIRNAME .. "images/minimapNotFound1.png"
local IMG_BULLET = LUA_DIRNAME .. "images/bullet.png"

local globalSizeMode = 2

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- News Update
local NEWS_FILE = "news/community.json"

local function LoadStaticCommunityData()
	if not VFS.FileExists(NEWS_FILE) then
		return {}
	end
	local data
	xpcall(
		function()
			data = Spring.Utilities.json.decode(VFS.LoadFile(NEWS_FILE))
		end,
		function(err)
			Spring.Log("community", LOG.ERROR, err)
			Spring.Log("community", LOG.ERROR, debug.traceback(err))
		end
	)
	return data or {}
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Controls

local function GetScroll(window, x, right, y, bottom, verticalScrollbar, borderColor)
	local holder = Control:New {
		x = x,
		y = y,
		right = right,
		bottom = bottom,
		padding = {2, 2, 2, 2},
		parent = window
	}
	return ScrollPanel:New {
		x = 2,
		right = 2,
		y = 2,
		bottom = 2,
		horizontalScrollbar = false,
		verticalScrollbar = verticalScrollbar,
		padding = {4, 4, 4, 4},
		borderColor = borderColor,
		--OnResize = {
		--	function()
		--	end
		--},
		parent = holder
	}
end

local function LeaveIntentionallyBlank(scroll, caption)
	Label:New {
		x = 12,
		y = 10,
		width = 120,
		height = 20,
		align = "left",
		valign = "top",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(1),
		caption = caption,
		parent = scroll
	}
end

local function AddLinkButton(scroll, name, tooltip, link, x, right, y, bottom)
	local button = Button:New {
		x = x,
		y = y,
		right = right,
		bottom = bottom,
		caption = name,
		tooltip = tooltip,
		classname = "link_button",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		OnClick = {
			function ()
				WG.BrowserHandler.OpenUrl(link)
			end
		},
		OnResize = {
			function(obj, xSize, ySize)
				if globalSizeMode == 2 then
					ButtonUtilities.SetFontSizeScale(obj, 5)
				else
					ButtonUtilities.SetFontSizeScale(obj, 4)
				end
			end
		},
		parent = scroll,
	}
	ButtonUtilities.SetFontSizeScale(button, 3)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Ladder Handler

local function GetLadderHandler(parentControl)
	local lobby = WG.LibLobby.lobby

	local holder = Control:New{
		x = 0,
		y = 0,
		right = 0,
		padding = {0,0,0,0},
		parent = parentControl,
	}
	local playerHolder = Control:New{
		x = 28,
		y = 30,
		right = 0,
		bottom = 0,
		padding = {0,0,0,0},
		parent = holder,
	}

	local heading = TextBox:New{
		x = 4,
		y = 7,
		right = 4,
		height = 24,
		align = "left",
		valign = "top",
		text = "Ladder",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		objectOverrideHintFont = WG.Chobby.Configuration:GetFont(3),
		parent = holder,
	}

	local numberBox = {}

	local externalFunctions = {}

	function externalFunctions.UpdateLadder(ladderEntries)
		local offset = 2
		playerHolder:ClearChildren()
		for i = 1, #ladderEntries do
			local data = ladderEntries[i]
			local lobbyData = {
				accountID = data.AccountID,
				icon = data.Icon,
				country = data.Country,
				clan = data.Clan
			}
			lobby:LearnAboutOfflineUser(data.Name, lobbyData)
			local user = WG.UserHandler.GetLadderUser(data.Name)

			user:SetPos(nil, offset)
			playerHolder:AddChild(user)

			if not numberBox[i] then
				numberBox[i] = Label:New{
					x = 1,
					y = offset + 32,
					width = 30,
					height = 24,
					align = "right",
					valign = "top",
					caption = i .. ". ",
					objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
					parent = holder,
				}
			end

			offset = offset + 26
		end

		holder:SetPos(nil, nil, nil, offset + 34)
	end

	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- News

local function GetDateTimeDisplay(parentControl, xPosition, yPosition, timeString)
	local localTimeString = Spring.Utilities.ArchaicUtcToLocal(timeString, i18n)
	if localTimeString then
		localTimeString = localTimeString .. " of your local time."
	end
	local utcTimeString = string.gsub(timeString, "T", " at ") .. " UTC"

	local localStart = TextBox:New{
		x = xPosition,
		y = yPosition,
		right = 4,
		height = 22,
		align = "left",
		valign = "top",
		text = localTimeString or utcTimeString, -- Fallback
		tooltip = string.gsub(timeString, "T", " at ") .. " UTC",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		objectOverrideHintFont = WG.Chobby.Configuration:GetFont(2),
		parent = parentControl,
	}

	local countdown = TextBox:New{
		x = xPosition,
		y = yPosition + localStart.height,
		right = 4,
		height = 22,
		align = "left",
		valign = "top",
		tooltip = utcTimeString,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		objectOverrideHintFont = WG.Chobby.Configuration:GetFont(2),
		parent = parentControl,
	}

	-- Activate the tooltip.
	function localStart:HitTest(x,y) return self end
	function countdown:HitTest(x,y) return self end

	local externalFunctions = {
		visible = true
	}

	function externalFunctions.SetPosition(newY)
		localStart:SetPos(nil, newY)
		countdown:SetPos(nil, newY + localStart.height)
	end

	function externalFunctions.GetHeight()
		return localStart.height + countdown.height
	end

	function externalFunctions.SetVisibility(visible)
		localStart:SetVisibility(visible)
		countdown:SetVisibility(visible)
		externalFunctions.visible = visible
	end

	function externalFunctions.UpdateCountdown()
		local difference, inTheFuture, isNow = Spring.Utilities.GetTimeDifference(timeString)

		if isNow then
			countdown:SetText("Starting " .. difference .. ".")
		elseif inTheFuture then
			countdown:SetText("Starting in " .. difference .. ".")
		else
			countdown:SetText( "Started " .. difference .. " ago.")
		end
	end
	externalFunctions.UpdateCountdown()

	return externalFunctions
end

local headingFormats = {
	[2] = {
		buttonSize = 28,
		height = 24,
		linkSize = 16,
		spacing = 2,
		buttonPos = 2,
		inButton = 4,
		paragraphSpacing = 20,
		topHeadingOffset = 60,
		imageSize = 120,
		buttonBot = 6,
		vSpacing = 6,
	},
	[4] = {
		buttonSize = 40,
		height = 34,
		linkSize = 28,
		spacing = 16,
		buttonPos = 5,
		inButton = 7,
		paragraphSpacing = 30,
		topHeadingOffset = 80,
		imageSize = 120,
		buttonBot = 10,
		vSpacing = 6,
	},
}

-- 2023/03/28 Fireball: we always use "headingFormats[2]"
--						we never use "showBulletHeading"
--						in result "freeHeading" and "heading" is same
--						i simplified this function to use always "heading" and deleted bullets
local function GetNewsEntry(parentHolder, index, headingSize, timeAsTooltip, topHeading, showBulletHeading)
	local linkString
	local controls = {}

	local headFormat = headingFormats[headingSize]

	local holder = Control:New{
		x = 0,
		y = 0,
		right = 0,
		height = 500,
		padding = {15,5,15,0},
		parent = parentHolder,
	}

	local externalFunctions = {}

	-- Fireball: vPositioning doesn't matter here, overwritten by DoResize as soon as the control was created
	function externalFunctions.AddEntry(entryData, parentPosition)
		local textPos = 6
		local headingPos = 2
		local offset = 0

		if entryData.link then
			linkString = entryData.link
			if not controls.linkButton then
				controls.linkButton = Button:New {
					x = 2,
					y = offset + 6, -- Fireball: doesn't matter, overwritten by DoResize, this is totally wrong
					width = 280,
					--right = 400,
					align = "left",
					valign = "top",
					height = 40,
					classname = "link_button",
					objectOverrideFont = WG.Chobby.Configuration:GetButtonFont(0),
					caption = entryData.urlText,
					padding = {0, 0, 0, 0},
					parent = holder,
					OnClick = {
						function ()
							WG.BrowserHandler.OpenUrl(linkString)
						end
					}
				}
			else
				controls.linkButton:SetVisibility(true)
			end
		end

		if not controls.heading then
			controls.heading = TextBox:New{
				x = 4, -- Fireball: Why not textpos(=6) ?
				y = headFormat.inButton,	-- Fireball: doesn't matter, overwritten by DoResize
				right = 4,
				height = headFormat.height,
				align = "center", -- Fireball: What do we want to center here ? the heading is shown aligned to the left and it's good. is this working at all ?
				valign = "top",
				text = entryData.heading,
				objectOverrideFont = WG.Chobby.Configuration:GetButtonFont(7),
				objectOverrideHintFont = WG.Chobby.Configuration:GetFont(7),
				parent = holder,
			}
		else
			controls.heading:SetText(entryData.heading)
		end

		offset = offset + controls.heading.height

		if entryData.imageFile then
			textPos = headFormat.imageSize + 12
			local imagePath = entryData.imageFile
			if not controls.image then
				controls.image = Image:New{
					name = "news" .. index,
					x = 4, -- Fireball: Why not textpos(=6) ?
					y = offset + headFormat.vSpacing,
					width = headFormat.imageSize,
					height = headFormat.imageSize,
					keepAspect = true,
					checkFileExists = true,
					fallbackFile = IMG_MISSING,
					file = imagePath,
					parent = holder
				}
			else
				controls.image.file = imagePath
				controls.image:Invalidate()
				controls.image:SetVisibility(true)
			end
			offset = offset + headFormat.vSpacing + headFormat.imageSize
		elseif controls.image then
			controls.image:SetVisibility(false)
		end

		if entryData.atTime and not timeAsTooltip then
			if not controls.dateTime then
				controls.dateTime = GetDateTimeDisplay(holder, textPos, offset + headFormat.vSpacing, entryData.atTime)
			else
				controls.dateTime.SetVisibility(true)
			end
			offset = offset + headFormat.vSpacing + controls.dateTime.GetHeight()
		elseif controls.dateTime then
			controls.dateTime.SetVisibility(false)
		end

		if entryData.text then
			if not controls.text then
				controls.text = TextBox:New{
					x = textPos,
					y = offset + headFormat.vSpacing,
					right = 4,
					height = 120,
					align = "left",
					valign = "top",
					text = entryData.text,
					objectOverrideFont = WG.Chobby.Configuration:GetButtonFont(2),
					objectOverrideHintFont = WG.Chobby.Configuration:GetFont(2),
					parent = holder,
				}
			else
				controls.text:SetText(entryData.text)
				controls.text:SetVisibility(true)
				controls.text:SetPos(textPos, offset + headFormat.vSpacing)
				controls.text._relativeBounds.right = 4
				controls.text:UpdateClientArea(false)
			end
			offset = offset + headFormat.vSpacing + controls.text.height
		elseif controls.text then
			controls.text:SetVisibility(false)
		end

		return parentPosition + offset
	end

	function externalFunctions.DoResize(parentPosition, numberVisible)
		if numberVisible < index then
			holder:SetVisibility(false)
			return parentPosition
		end
		holder:SetVisibility(true)

		local offset = 0

		local headingSize
		if controls.heading and controls.heading.visible then
			headingSize = (#controls.heading.physicalLines)*headFormat.fontSize
			controls.heading:SetPos(nil, nil, nil, headingSize)
		end
		offset = offset + headingSize + headFormat.spacing

		local offsetImage = 0
		if controls.image and controls.image.visible then
			controls.image:SetPos(nil, offset + headFormat.vSpacing)
			offsetImage = offset + headFormat.vSpacing + headFormat.imageSize
		end

		if controls.dateTime and controls.dateTime.visible then
			controls.dateTime.SetPosition(offset + headFormat.vSpacing)
			offset = offset + headFormat.vSpacing + controls.dateTime.GetHeight()
		end

		if controls.text and controls.text.visible then
			controls.text:SetPos(nil, offset + headFormat.vSpacing)
			offset = offset + headFormat.vSpacing + controls.text.height
		end

		if controls.linkButton and controls.linkButton.visible then
			offset = math.max(offset, offsetImage) + headFormat.vSpacing
			controls.linkButton:SetPos(nil, offset)
			offset = offset + controls.linkButton.height
		else
			offset = math.max(offset, offsetImage)	
		end

		holder:SetPos(nil, parentPosition, nil, offset+10)
		return parentPosition + offset + headFormat.paragraphSpacing
	end

	function externalFunctions.UpdateCountdown()
		if controls.dateTime then
			controls.dateTime.UpdateCountdown()
		end
	end

	return externalFunctions
end

local function GetNewsHandler(parentControl, headingSize, timeAsTooltip, topHeading, showBulletHeading)
	local headFormat = headingFormats[headingSize]
	headFormat.fontSize = WG.Chobby.Configuration:GetFont(headingSize).size

	local offset = topHeading and headFormat.topHeadingOffset or 0
	local visibleItems = 0

	local holder = Control:New{
		x = 0,
		y = 0,
		right = 0,
		padding = {0,15,0,0},
		parent = parentControl,
	}

	local topHeadingLabel = topHeading and TextBox:New{
		x = 4,
		y = 7,
		right = 4,
		height = headFormat.height,
		align = "left",
		valign = "top",
		text = topHeading,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		objectOverrideHintFont = WG.Chobby.Configuration:GetFont(3),
		parent = holder,
	}

	local newsEntries = {}

	local function DoResize()
		offset = topHeading and headFormat.topHeadingOffset or 0
		for i = 1, #newsEntries do
			offset = newsEntries[i].DoResize(offset, visibleItems)
		end
		holder:SetPos(nil, nil, nil, offset - headFormat.paragraphSpacing/2)
	end

	local function UpdateCountdown()
		for i = 1, #newsEntries do
			newsEntries[i].UpdateCountdown()
		end
		WG.Delay(UpdateCountdown, 60)
	end

	local externalFunctions = {}

	function externalFunctions.ReplaceNews(items)
		if not items then
			visibleItems = 0
			DoResize()
			return
		end
		for i = 1, #items do
			Spring.Echo("Adding news item",items[i].Header)
			local entry = {
				heading = items[i].Header,
				link = items[i].Url,
				atTime = items[i].Time,
				text = items[i].Text,
				urlText = items[i].UrlText,
			}
			if items[i].Image then
				local imagePos = string.find(items[i].Image, "news")
				if imagePos then
					local imagePath = string.sub(items[i].Image, imagePos)
					if not VFS.FileExists(imagePath) then
						Spring.CreateDir("news")
						WG.WrapperLoopback.DownloadImage({ImageUrl = items[i].Image, TargetPath = imagePath})
					end
					entry.imageFile = imagePath
				else
					entry.imageFile = items[i].Image
				end
			end

			if not newsEntries[i] then
				newsEntries[i] = GetNewsEntry(holder, i, headingSize, timeAsTooltip, topHeading, showBulletHeading)
			end
			offset = newsEntries[i].AddEntry(entry, offset)
		end

		visibleItems = #items
		DoResize()
	end

	-- Initialization
	UpdateCountdown()

	parentControl.OnResize = parentControl.OnResize or {}
	parentControl.OnResize[#parentControl.OnResize + 1] = function ()
		WG.Delay(DoResize, 0.01)
	end

	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Profile

--{"Name":"GoogleFrog","Awards":[{"AwardKey":"cap","Collected":51},{"AwardKey":"reclaim","Collected":977},{"AwardKey":"pwn","Collected":1824},{"AwardKey":"vet","Collected":362},{"AwardKey":"kam","Collected":70},{"AwardKey":"ouch","Collected":952},{"AwardKey":"shell","Collected":267},{"AwardKey":"terra","Collected":278},{"AwardKey":"navy","Collected":77},{"AwardKey":"nux","Collected":16},{"AwardKey":"fire","Collected":133},{"AwardKey":"air","Collected":74},{"AwardKey":"emp","Collected":112},{"AwardKey":"share","Collected":4},{"AwardKey":"mex","Collected":758},{"AwardKey":"comm","Collected":84},{"AwardKey":"rezz","Collected":3},{"AwardKey":"friend","Collected":1},{"AwardKey":"head","Collected":8},{"AwardKey":"dragon","Collected":2},{"AwardKey":"sweeper","Collected":2},{"AwardKey":"heart","Collected":2},{"AwardKey":"mexkill","Collected":142},{"AwardKey":"slow","Collected":156},{"AwardKey":"silver","Collected":6},{"AwardKey":"bronze","Collected":3},{"AwardKey":"gold","Collected":1}],"Badges":["dev_adv","donator_0"],"Level":133,"LevelUpRatio":"0.69","EffectiveElo":2312,"EffectiveMmElo":2234,"EffectivePwElo":1670,"Kudos":724,"PwMetal":"5105.00","PwDropships":"74.00","PwBombers":"17.00","PwWarpcores":"0.00"}

local function GetAwardsHandler(parentControl, iconWidth, iconHeight, GetEntryData)
	local fontsize = WG.Chobby.Configuration:GetFont(1).size
	local imageList
	local externalFunctions = {}

	function externalFunctions.PositionAwards()
		if not imageList then
			return
		end

		local gridWidth = math.floor(parentControl.width/(iconWidth + 2))
		if gridWidth < 1 then
			return
		end

		for i = 1, #imageList do
			local x, y = (iconWidth + 2)*((i - 1)%gridWidth), (iconHeight + 2)*math.floor((i - 1)/gridWidth)
			imageList[i]:SetPos(x, y)
		end
	end

	function externalFunctions.SetAwards(awardsList)
		parentControl:ClearChildren()
		imageList = {}
		for i = 1, #awardsList do
			local imageName, count = GetEntryData(awardsList[i])
			imageList[i] = Image:New{
				width = iconWidth,
				height = iconHeight,
				keepAspect = true,
				file = imageName,
				parent = parentControl,
			}
			if count and count > 1 then
				Label:New {
					x = 2,
					y = "60%",
					right = 2,
					bottom = 6,
					align = "right",
					objectOverrideFont = WG.Chobby.Configuration:GetFont(fontsize),
					caption = count,
					parent = imageList[i],
				}
			end
		end
	end

	return externalFunctions
end

local function GetProfileHandler(parentControl)

	local holder = Control:New{
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		padding = {0,0,0,0},
		parent = parentControl,
	}
	local nameHolder = Control:New{
		x = "36%",
		y = "7%",
		right = 0,
		height = 28,
		padding = {0,0,0,0},
		parent = holder,
	}

	local awardsHandler, awardsLabel
	local GetAwardImage = WG.Chobby.Configuration.gameConfig.GetAward
	if GetAwardImage then
		local awardsHolder = Control:New{
			x = 10,
			y = "60%",
			right = 6,
			bottom = 0,
			padding = {0,0,0,0},
			parent = holder,
		}
		local function GetAwardInfo(entry)
			return GetAwardImage(entry.AwardKey), entry.Collected
		end
		awardsHandler = GetAwardsHandler(awardsHolder, 38, 38, GetAwardInfo)
	end

	local badgesHandler
	local badgeDecs = WG.Chobby.Configuration.gameConfig.badges
	if badgeDecs then
		local badgeHolder = Control:New{
			x = "42%",
			y = "46%",
			right = 0,
			height = 22,
			padding = {0,0,0,0},
			parent = holder,
		}
		local function GetBadgeInfo(entry)
			return (badgeDecs[entry] or {}).image
		end
		badgesHandler = GetAwardsHandler(badgeHolder, 46, 19, GetBadgeInfo)
	end

	local experienceBar, rankBar, backgroundImage

	local function MakeProgressBar(yPos, tooltip)
		local progressBar = Progressbar:New {
			x = "24%",
			y = yPos,
			right = "24%",
			height = 20,
			value = 0,
			max = 1,
			caption = "Level " .. 2,
			tooltip = tooltip,
			objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
			parent = holder,
		}
		function progressBar:HitTest(x,y) return self end
		return progressBar
	end

	local function DoResize()
		if awardsHandler then
			awardsHandler.PositionAwards()
		end
	end

	parentControl.OnResize = parentControl.OnResize or {}
	parentControl.OnResize[#parentControl.OnResize + 1] = function ()
		WG.Delay(DoResize, 0.01)
	end

	local externalFunctions = {}

	function externalFunctions.UpdateProfile(profileData)
		local level = profileData.Level
		local levelProgress = tonumber(profileData.LevelUpRatio) or 0
		local rank = profileData.Rank
		local rankProgress = tonumber(profileData.RankUpRatio) or 0

		experienceBar = experienceBar or MakeProgressBar("22%", "Your level. Play on the server to level up.")
		rankBar = rankBar or MakeProgressBar("34%", "Your skill rating and progress to the next rank.")

		experienceBar:SetCaption("Level " .. (level or "??"))
		experienceBar:SetValue(levelProgress)

		if awardsHandler and profileData.Awards then
			awardsHandler.SetAwards(profileData.Awards)
			awardsHandler.PositionAwards()
			if not awardsLabel then
				awardsLabel = Label:New {
					x = 5,
					y = "48%",
					width = 80,
					height = 22,
					align = "right",
					objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
					caption = "Awards:",
					parent = holder,
				}
			end
		end
		if badgesHandler and profileData.Badges then
			badgesHandler.SetAwards(profileData.Badges)
			badgesHandler.PositionAwards()
		end

		local GetRankAndImage = WG.Chobby.Configuration.gameConfig.GetRankAndImage
		if rank and GetRankAndImage then
			local rankName, rankImage = GetRankAndImage(rank)

			rankBar:SetCaption(rankName)
			rankBar:SetValue(rankProgress or 0)
			backgroundImage = backgroundImage or Image:New{
				x = 0,
				y = 0,
				right = 0,
				bottom = 0,
				keepAspect = true,
				parent = holder,
			}
			backgroundImage.file = rankImage
			backgroundImage:Invalidate()
			backgroundImage:SendToBack()
		end
	end

	local userControl
	function externalFunctions.UpdateUserName()
		nameHolder:ClearChildren()
		userControl = WG.UserHandler.GetCommunityProfileUser(lobby:GetMyUserName())
		nameHolder:AddChild(userControl)
	end

	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Initialization

local function InitializeControls(window)
	-- Save space
	--Label:New {
	--	x = 15,
	--	y = 11,
	--	width = 180,
	--	height = 30,
	--	parent = window,
	--	objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
	--	caption = "Community",
	local Configuration = WG.Chobby.Configuration

	local lobby = WG.LibLobby.lobby
	local staticCommunityData = LoadStaticCommunityData()

	local topWide     = GetScroll(window, 0, 0, 0, "30%", true) -- GetScroll(window, x, right, y, bottom, verticalScrollbar)
	local leftCenter  = GetScroll(window, 0, 0, "70%", "0%", false, {0,0,0,0})
	--local midCenter   = GetScroll(window, "33.4%", "33.4%", "40%", "1%", true)
	--local rightCenter = GetScroll(window, "66.6%", 0, "40%", "1%", true)
	--local lowerWide   = GetScroll(window, 0, 0, "69%", 0, true)
	--local leftLower   = GetScroll(window, 0, "33.4%", "69%", 0, false)
	--local rightLower  = GetScroll(window, "66.6%", 0, "69%", 0, false)

	LeaveIntentionallyBlank(rightLower, "(reserved)")

	-- Populate link panel
	AddLinkButton(leftCenter, "Donate",   "Help us continue development", "https://www.beyondallreason.info/donate-for-bar",0, 0, "75.5%", 0) --last
	AddLinkButton(leftCenter, "Code of Conduct",  "Code of conduct and terms of use", "https://www.beyondallreason.info/code-of-conduct", 0, 0, "50.5%", "25.5%") --third
	AddLinkButton(leftCenter, "Website", "Visit our website for more, opens https://www.beyondallreason.info/", "https://www.beyondallreason.info/",   0, 0, "25.5%", "50.5%") --second
	AddLinkButton(leftCenter, "Join our Discord", "Opens a link to https://discord.gg/N968ddE in your browser.", "https://discord.gg/N968ddE", 0, 0, 0, "75.5%") --first

	-- News Handler
	--[[
				heading = items[i].Header,
				link = items[i].Url,
				atTime = items[i].Time,
				text = items[i].Text,

	--]]

	local welcomePanelItems = {}
	if WG.Chobby.Configuration and WG.Chobby.Configuration.gameConfig and WG.Chobby.Configuration.gameConfig.welcomePanelItems then
		welcomePanelItems = WG.Chobby.Configuration.gameConfig.welcomePanelItems
	end

	local newsHandler = GetNewsHandler(topWide, 4)
	if welcomePanelItems then
		newsHandler.ReplaceNews(welcomePanelItems)
	end

	local function OnNewsList(_, welcomePanelItems)
		newsHandler.ReplaceNews(welcomePanelItems)
	end
	lobby:AddListener("OnNewsList", OnNewsList)

	-- Forum Handler
	--[[
	local forumHandler = GetNewsHandler(midCenter, 2, true, "Recent Posts", true)
	if staticCommunityData and staticCommunityData.ForumItems then
		forumHandler.ReplaceNews(staticCommunityData.ForumItems)
	end

	local function OnForumList(_, forumItems)
		forumHandler.ReplaceNews(forumItems)
	end
	lobby:AddListener("OnForumList", OnForumList)
	--]]
	-- Ladder Handler
	--[[
	local ladderHandler = GetLadderHandler(rightCenter)
	if staticCommunityData and staticCommunityData.LadderItems then
		ladderHandler.UpdateLadder(staticCommunityData.LadderItems)
	end

	local function OnLadderList(_, ladderItems)
		ladderHandler.UpdateLadder(ladderItems)
	end
	lobby:AddListener("OnLadderList", OnLadderList)
	--]]

	--[[
	-- Profile Handler
	local profileHandle = GetProfileHandler(lowerWide)
	local function OnUserProfile(_, profileData)
		profileHandle.UpdateProfile(profileData)
	end
	lobby:AddListener("OnUserProfile", OnUserProfile)

	local function OnAccepted(listener)
		profileHandle.UpdateUserName()
	end
	lobby:AddListener("OnAccepted", OnAccepted)
	--]]
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- External Interface

local CommunityWindow = {}

function CommunityWindow.GetControl()

	local window = Control:New {
		name = "communityHandler",
		x = "0%",
		y = "0%",
		width = "100%",
		height = "100%",
		padding = {8, 8, 8, 12},
		OnParent = {
			function(obj)
				if obj:IsEmpty() then
					InitializeControls(obj)
				end
			end
		},
		OnResize = {
			function(obj, xSize, ySize)
				if ySize < 650 then
					globalSizeMode = 1
				else
					globalSizeMode = 2
				end
			end
		}
	}
	return window
end

CommunityWindow.LoadStaticCommunityData = LoadStaticCommunityData

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

function widget:ActivateGame()
	if not WG.Chobby.Configuration.firstBattleStarted then
		WG.Chobby.Configuration:SetConfigValue("firstBattleStarted", true)
	end
end

local function DelayedInitialize()
	--if WG.Chobby.Configuration.firstBattleStarted then -- Always show welcome panel
		WG.Chobby.interfaceRoot.OpenRightPanelTab("welcome")
		--Spring.Echo("Opened welcome panel")
	--end
end

function widget:Initialize()
	CHOBBY_DIR = LUA_DIRNAME .. "widgets/chobby/"
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	WG.Delay(DelayedInitialize, 0.6) -- After user handler

	WG.CommunityWindow = CommunityWindow
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
