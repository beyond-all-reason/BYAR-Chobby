--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Missions Handles",
		desc      = "Handles missions.",
		author    = "GoogleFrog",
		date      = "24 November 2016",
		license   = "GNU LGPL, v2.1 or later",
		layer     = -100000,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Local Variables

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utilities

local function LoadMissions()
	local path = "missions/missions.json"
	if VFS.FileExists(path) then
		local file = VFS.LoadFile(path)
		return Spring.Utilities.json.decode(file)
	end
	Spring.Log("gui_mission_handler.lua", LOG.ERROR, "Error loading missions.")
	return nil
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Downloads

local alreadyDownloaded = {}

local function DownloadRequirements()
	local config = WG.Chobby.Configuration
	local gameName = config:GetDefaultGameName()
	if gameName ~= nil and not alreadyDownloaded[gameName] then
		WG.DownloadHandler.MaybeDownloadArchive(gameName, "game", 1)
		alreadyDownloaded[gameName] = true
	end
	local missions = LoadMissions()
	if missions ~= nil then
		for i = 1, #missions do
			if string.find(missions[i].DisplayName, "Tutorial") and not alreadyDownloaded[missions[i].Map] then
				WG.DownloadHandler.MaybeDownloadArchive(missions[i].Map, "map", 1)
				alreadyDownloaded[missions[i].Map] = true
			end
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Mission Control Handler

local function CreateMissionEntry(missionData)
	local Configuration = WG.Chobby.Configuration

	local holder = Panel:New {
		x = 0,
		y = 0,
		width = "100%",
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
	}

	local imagePanel = Panel:New {
		x = 2,
		y = 2,
		width = 76,
		height = 76,
		padding = {1,1,1,1},
		parent = holder,
	}
	local imageFile = (missionData.MissionID and "missions/" .. missionData.MissionID .. ".png")
	if imageFile then
		local image = Image:New {
			name = "image",
			x = 0,
			y = 0,
			right = 0,
			bottom = 0,
			keepAspect = true,
			file = imageFile,
			parent = imagePanel,
		}
	end

	local startButton = Button:New {
		x = 86,
		y = 34,
		width = 65,
		height = 34,
		caption = i18n("play"),
		classname = "action_button",
		font = WG.Chobby.Configuration:GetFont(2),
		OnClick = {
			function()
				local startScript = missionData.Script

				local gameName = WG.Chobby.Configuration:GetDefaultGameName()
				local haveGame = VFS.HasArchive(gameName)
				if not haveGame then
					WG.Chobby.InformationPopup("You do not have the game file required. It will now be downloaded.")
					WG.DownloadHandler.MaybeDownloadArchive(gameName, "game", -1)
					return
				end

				local haveMap = VFS.HasArchive(missionData.Map)
				if not haveMap then
					WG.Chobby.InformationPopup("You do not have the map file required. It will now be downloaded.")
					WG.DownloadHandler.MaybeDownloadArchive(missionData.Map, "map", -1)
					return
				end

				local gameName = WG.Chobby.Configuration:GetDefaultGameName()
				if string.find(gameName, ":") then
					gameName = "rapid://" .. gameName
				end

				startScript = startScript:gsub("%%MAP%%",  missionData.Map)
				startScript = startScript:gsub("%%MOD%%",  gameName)
				startScript = startScript:gsub("%%NAME%%", WG.Chobby.localLobby:GetMyUserName())

				WG.Analytics.SendOnetimeEvent("lobby:singleplayer:missions:start_" .. missionData.DisplayName)
				WG.Analytics.SendRepeatEvent("game_start:tutorial:" .. missionData.DisplayName, 1)
				WG.Chobby.localLobby:StartGameFromString(startScript, "tutorial")
			end
		},
		parent = holder,
	}

	--local missionOrder = TextBox:New {
	--	name = "missionOrder",
	--	x = 90,
	--	y = 8,
	--	right = 0,
	--	height = 20,
	--	valign = 'center',
	--	fontsize = Configuration:GetFont(3).size,
	--	text = tostring(missionData.FeaturedOrder or ""),
	--	parent = holder,
	--}

	local missionName = missionData.DisplayName
	if missionData.FeaturedOrder then
		missionName = tostring(missionData.FeaturedOrder) .. ": " .. missionName
	end

	local missionName = TextBox:New {
		name = "missionName",
		x = 90,
		y = 8,
		right = 0,
		height = 20,
		valign = 'center',
		fontsize = Configuration:GetFont(3).size,
		text = missionName,
		parent = holder,
	}
	--local missionDifficulty = TextBox:New {
	--	name = "missionDifficulty",
	--	x = 170,
	--	y = 42,
	--	right = 0,
	--	height = 20,
	--	valign = 'center',
	--	fontsize = Configuration:GetFont(2).size,
	--	text = string.format("Difficulty %.1f", missionData.Difficulty or 0),
	--	parent = holder,
	--}
	--local missionMap = TextBox:New {
	--	name = "missionMap",
	--	x = 320,
	--	y = 42,
	--	right = 0,
	--	height = 20,
	--	valign = 'center',
	--	fontsize = Configuration:GetFont(2).size,
	--	text = missionData.Map,
	--	parent = holder,
	--}

	return holder, {missionData.FeaturedOrder or math.huge, missionData.DisplayName, missionData.Difficulty or 0, missionData.Map}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Controls

local function InitializeControls(parentControl)
	local Configuration = WG.Chobby.Configuration

	Label:New {
		x = 15,
		y = 11,
		width = 180,
		height = 30,
		parent = parentControl,
		font = Configuration:GetFont(3),
		caption = "Learn advanced techniques in these tutorials",
	}

	local btnLeaveScreen = Button:New {
		right = 11,
		y = 7,
		width = 80,
		height = 45,
		font =  WG.Chobby.Configuration:GetFont(3),
		caption = i18n("close"),
		classname = "negative_button",
		OnClick = {
			function()
				parentControl:Hide()
			end
		},
		parent = parentControl,
	}

	local missions = LoadMissions()

	if not missions then
		local missingPanel = Panel:New {
			classname = "overlay_window",
			x = "10%",
			y = "44%",
			right = "10%",
			bottom = "44%",
			parent = parentControl,
		}

		local missingLabel = Label:New {
			x = "5%",
			y = "5%",
			width = "90%",
			height = "40%",
			align = "center",
			valign = "center",
			parent = missingPanel,
			font = Configuration:GetFont(3),
			caption = "Error Loading Missions",
		}
		local missingLabel = Label:New {
			x = "5%",
			y = "50%",
			width = "90%",
			height = "40%",
			align = "center",
			valign = "center",
			parent = missingPanel,
			font = Configuration:GetFont(3),
			caption = "check that your install directory is writable.",
		}
		return
	end

	-------------------------
	-- Generate List
	-------------------------

	local listHolder = Control:New {
		x = 12,
		right = 15,
		y = 52,
		bottom = 15,
		parent = parentControl,
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
	}

	--local headings = {
	--	{name = "#", x = 88, width = 36},
	--	{name = "Name", x = 124, width = 157},
	--	{name = "Difficulty", x = 286, width = 125},
	--	{name = "Map", x = 416, right = 5},
	--}
	--local missionList = WG.Chobby.SortableList(listHolder, headings, 80, 1)

	local missionList = WG.Chobby.SortableList(listHolder, nil, 80, 1)

	local items = {}
	for i = 1, #missions do
		if string.find(missions[i].DisplayName, "Tutorial") then
			local controls, order = CreateMissionEntry(missions[i])
			items[#items + 1] = {#items, controls, order}
		end
	end

	missionList:AddItems(items)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- External Interface

local MissionHandler = {}

function MissionHandler.GetControl()

	local window = Control:New {
		name = "missionHandler",
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		padding = {0, 0, 0, 0},
		OnParent = {
			function(obj)
				if obj:IsEmpty() then
					InitializeControls(obj)
				end
			end
		},
	}

	WG.Delay(DownloadRequirements, 0.1)
	return window
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

function widget:Initialize()
	CHOBBY_DIR = LUA_DIRNAME .. "widgets/chobby/"
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	WG.MissionHandler = MissionHandler
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
