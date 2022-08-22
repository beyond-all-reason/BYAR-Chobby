--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name	  = "Replays window",
		desc	  = "Handles local replays.",
		author	  = "GoogleFrog",
		date	  = "20 October 2016",
		license   = "GNU LGPL, v2.1 or later",
		layer	  = -100000,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Local Variables

local replayListWindow
local replayList

-- Size constants for the replay window
local PLAYER_HEIGHT = 18
local REPLAY_LIST_ENTRY_HEIGHT = 120

local myFont1
local myFont2
local myFont3
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utilities

local function ternary(condition, T, F)
  if condition then return T else return F end
end

-- Returns whether the players structure of the replay request corresponds
-- to an FFA game ot not.
local function is_ffa(teams)
	if #teams <= 2	then
		return false
	end

	for _, team in pairs(teams) do
		if #team > 1 then
			return false
		end
	end
	return true
end

-- Returns the battle type as a string. (1v1 / FFA / 8v8 / etc)
local function battleType(teams)
	if is_ffa(teams) then
		return "FFA"
	end

	local teams_lengths = {}
	for _, team in pairs(teams) do
		table.insert(teams_lengths, #team)
	end

	return table.concat(teams_lengths, "v")
end


--	From the flat array of players, build an array of teams
local function buildTeams(players)
	local teams = {}
	for _, player in pairs(players) do
		local team
		if teams[player.allyTeamId + 1] == nil then
			team = {}
			teams[player.allyTeamId + 1] = team
		else
			team = teams[player.allyTeamId + 1]
		end
		table.insert(team, player)
	end
	return teams
end

--	Return a widget containing a player's information
local function playerWidget(playerInfo)
	local Configuration = WG.Chobby.Configuration
	--local userName = playerInfo.name
	local userName = StringUtilities.GetTruncatedStringWithDotDot(playerInfo.name, myFont1, REPLAY_LIST_ENTRY_HEIGHT-5)

	-- Create a control widget to encapsulate the player's information
	local ret = Chili.Control:New {
		x = 0, y = 0, right = 0,
		height=PLAYER_HEIGHT, bottom = 0, padding = {0, 0, 0, 0},
	}

	local image_file
	if playerInfo.aiId then
		image_file = Configuration.gameConfig.rankFunction(nil, 0, 0, true, false)
	else
		image_file = Configuration.gameConfig.rankFunction(
			nil, tonumber(playerInfo.rank), 0, false, false
		)
	end

	-- Get the rank image for the player
	Image:New {
		name = "imRank",
		x = 0,
		y = 0,
		width = 13,
		height = 13,
		parent = ret,
		keepAspect = false,
		file = image_file
	}

	-- Textbox with the user's name
	TextBox:New {
		name = "userName",
		x = 18, y = 0, right = 0, height = PLAYER_HEIGHT,
		valign = "top",
		objectoverridefont = myFont1,
		--fontsize = Configuration:GetFont(1).size,
		text = userName,
		parent = ret,
	}

	-- TODO: We could definitely add some more stuff (flag? TS value?) here.
	return ret
end

local function CreateReplayEntry(
	replayPath, engineName, gameName, mapName, players, time
)

	local Configuration = WG.Chobby.Configuration
	local mapNameTruncated = StringUtilities.GetTruncatedStringWithDotDot(mapName, myFont1, REPLAY_LIST_ENTRY_HEIGHT+50)
	local fileName = string.sub(replayPath, 7)
	if string.sub(fileName, 0, 4) == "hide" then
		return
	end

	local teams = buildTeams(players)

	fileName = string.gsub(string.gsub(fileName, " maintenance", ""), " develop", "")
	fileName = string.gsub(fileName, "%.sdfz", "")

	-- Extract replay time from the filename
	local replayDateString = string.format(
		"%s-%s-%s %s:%s",
		string.match(fileName, "(%d%d%d%d)(%d%d)(%d%d)_(%d%d)(%d%d)")
	)

	-- Compute the time of the replay
	local hours, minutes = math.floor(time / 3600), math.floor(time / 60) % 60
	local replayTimeString

	-- Filter out replays that are less than a minute long, but where the
	-- absolute time is not 0
	if hours + minutes == 0 then
		if time == 0 then
			--	In that case, sdzf-demo-parser returned 0, which very likely
			--	means it couldn't parse the time of the replay because the file
			--	is incomplete. In those case we still want to show the replay
			--	but with a time of "unknown".
			replayTimeString = "time unknown"
		else
			return
		end
	else
		replayTimeString = minutes .. " minutes"
		if hours > 0 then
			replayTimeString = hours .. " hour " .. replayTimeString
		end
	end

	local replayPanel = Panel:New {
		x = 0,
		y = 0,
		width = "100%",
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
	}


	local mapImageFile, needDownload = Configuration:GetMinimapImage(mapName)

	local minimap = Panel:New {
		name = "minimap",
		x = 3, y = 3,
		width = 112, height = 112,
		padding = {1,1,1,1},
		parent = replayPanel,
	}

	local mapImage = Image:New {
		x = 0, y = 0,
		right = 0,
		bottom = 0,
		file = mapImageFile,
		fallbackFile = Configuration:GetLoadingImage(3),
		checkFileExists = needDownload,
		parent = minimap,
		tooltip = "prout"
	}

	TextBox:New {
		name = "replayBattleType",
		x = 135, y = 22,
		right = 0, height = 20,
		valign = 'center',
		objectoverridefont = myFont2,
		fontsize = Configuration:GetFont(2).size,
		text = battleType(teams),
		parent = replayPanel,
	}

	TextBox:New {
		name = "replayDate",
		x = 135, y = 65,
		right = 0, height = 20,
		valign = 'center',
		objectoverridefont = myFont1,
		--fontsize = Configuration:GetFont(1).size,
		text = replayDateString,
		parent = replayPanel,
	}

	TextBox:New {
		name = "replayTime",
		x = 135, y = 82,
		right = 0, height = 20,
		valign = 'center',
		objectoverridefont = myFont1,
		--fontsize = Configuration:GetFont(1).size,
		text = replayTimeString,
		parent = replayPanel,
	}

	TextBox:New {
		name = "replayMap",
		x = 135, y = 42,
		right = 0, height = 20,
		valign = 'center',
		objectoverridefont = myFont2,
		fontsize = Configuration:GetFont(2).size,
		text = mapNameTruncated,
		parent = replayPanel,
	}

	-- Compute the teams/players lists

	local userList = Chili.Control:New {
		x = "50%", y = 10,
		right = "13%", bottom = 0,
		padding = {0, 0, 0, 0},
		parent = replayPanel,
	}

	local xOffset = 0
	local yOffset = 0

	-- Iterate over the teams structure
	for i, team in pairs(teams) do
		if i > 1 then
			yOffset = yOffset + 10
		end

		-- If we're computing a new team, and we can see that it will overflow
		-- the list item's height, create a new column.
		if yOffset > 0
			and yOffset + (#team * PLAYER_HEIGHT) + PLAYER_HEIGHT + 10 >= REPLAY_LIST_ENTRY_HEIGHT
		then
			yOffset = 0
			xOffset = xOffset + REPLAY_LIST_ENTRY_HEIGHT
		end

		-- Show a "Team n" label on the first line for each team
		TextBox:New {
			x = xOffset, y = yOffset, right = 0, height = 10,
			valign = 'center',
			objectoverridefont = myFont1,
			--fontsize = Configuration:GetFont(1).size,
			text = "Team " .. i,
			parent = userList,
		}
		yOffset = yOffset + PLAYER_HEIGHT

		--	Then add each player on a subsequent line
		for _, player in pairs(team) do

			--	If there are too many players to display on one line, just add
			--	an ellipsis and skip subsequent players for the team.
			if yOffset + PLAYER_HEIGHT * 2 >= REPLAY_LIST_ENTRY_HEIGHT then
				local ellipsis = TextBox:New {
					x = xOffset, y = yOffset, text = "...",
					objectoverridefont = myFont1
				}
				userList:AddChild(ellipsis)
				ellipsis:SetPos(xOffset, yOffset)
				ellipsis._relativeBounds.right = 0
				ellipsis:UpdateClientArea()
				break
			end

			-- Else, display the player's info
			local playerControl = playerWidget(player)
			userList:AddChild(playerControl)
			playerControl:SetPos(xOffset, yOffset)
			playerControl._relativeBounds.right = 0
			playerControl:UpdateClientArea()
			yOffset = yOffset + PLAYER_HEIGHT
		 end
	end

	local function CheckReplayFileExists()
		if not VFS.FileExists(replayPath) then
			WG.Chobby.InformationPopup(i18n("replay_not_found"), {width = 315, height = 200})
			return false
		else
			return true
		end
	end

	local function DeleteReplay()
		-- There's no Lua wrapper for FileSystem::Remove() function, available in Spring (/rts/System/FileSystem/FileSystem.cpp)
		os.remove(replayPath)
		-- Also removing a cache file (using a wildcard file mask is dangerous)
		os.remove(replayPath .. ".cache")
		replayList:RemoveItem(replayPath)
	end

	Button:New {
		x = "89%",
		y = "10%",
		bottom = "55%",
		width = "10%",
		caption = i18n("start"),
		tooltip = ternary(
			WG.Chobby.Configuration:IsValidEngineVersion(engineName),
			nil,
			i18n("replay_different_version")
		),
		classname = ternary(
			WG.Chobby.Configuration:IsValidEngineVersion(engineName),
			"action_button",
			"option_button"
		),
		objectoverridefont = myFont1,
		font = WG.Chobby.Configuration:GetFont(1),
		OnClick = {
			function()
				if not replayPath or not CheckReplayFileExists() then
					return
				end
				local offEngine = not WG.Chobby.Configuration:IsValidEngineVersion(engineName)
				WG.SteamCoopHandler.AttemptGameStart(
					"replay", gameName,
					mapName, nil, nil, replayPath, offEngine and engineName
				)
			end
		},
		parent = replayPanel,
	}

	Button:New {
		x = "89%",
		y = "55%",
		bottom = "10%",
		width = "10%",
		caption = i18n("delete_replay"),
		classname = "negative_button",
		font = WG.Chobby.Configuration:GetFont(1),
		objectoverridefont = myFont1,
		tooltip = "Delete the replay from your hard drive",
		OnClick = {
			function()
				if not replayPath or not CheckReplayFileExists() then
					return
				end
				WG.Chobby.ConfirmationPopup(DeleteReplay, i18n("delete_replay_confirm"), nil, 315, 200, i18n("yes"), i18n("no"))
			end
		},
		parent = replayPanel,
	}


	return replayPanel, {replayDateString, string.lower(mapName), gameName}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Controls

local function InitializeControls(parentControl)
	local Configuration = WG.Chobby.Configuration
	myFont1 = Font:New(Configuration:GetFont(1))
	myFont2 = Font:New(Configuration:GetFont(2))
	myFont3 = Font:New(Configuration:GetFont(3))

	Label:New {
		x = 15,
		y = 17,
		width = 180,
		height = 30,
		parent = parentControl,
		--objectoverridefont = myFont3,
		font = Configuration:GetFont(3),
		caption = "Replays",
	}

	local loadingPanel = Panel:New {
		classname = "overlay_window",
		x = "20%",
		y = "45%",
		right = "20%",
		bottom = "45%",
		parent = parentControl,
	}

	Label:New {
		x = "5%",
		y = "5%",
		width = "90%",
		height = "90%",
		align = "center",
		valign = "center",
		parent = loadingPanel,
		objectoverridefont = myFont3,
		--font = Configuration:GetFont(3),
		caption = "Loading",
	}

	-------------------------
	-- Replay List
	-------------------------

	local listHolder = Control:New {
		x = 12,
		right = 15,
		y = 15,
		bottom = 15,
		parent = parentControl,
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
	}

	local headings = {}

	replayList = WG.Chobby.SortableList(
		listHolder, headings, REPLAY_LIST_ENTRY_HEIGHT, nil, false
	)

	local PartialAddReplays, moreButton

	local function AddReplays()

		local replays = VFS.DirList("demos", "*.sdfz")
		local index = #replays

        --  Add one replay to the replay list
		local function AddOneReplay()
			if index < 1 then
				if moreButton then
					moreButton:SetVisibility(false)
				end
				loadingPanel:SetVisibility(false)
				return
			end
			local replayPath = replays[index]
			WG.WrapperLoopback.ReadReplayInfo(replayPath)
			index = index - 1
		end

        --  Add replays to the replays list
		PartialAddReplays = function()
			local remaining = 50

			local function QueueOneReplay()
				AddOneReplay()
				remaining = remaining - 1
				if remaining > 0 then
					WG.Delay(QueueOneReplay, 0.005)
				else
					loadingPanel:SetVisibility(false)
				end
			end

			loadingPanel:SetVisibility(true)
			loadingPanel:BringToFront()
			QueueOneReplay()
		end

		replayList:Clear()

		if moreButton then
			moreButton:SetVisibility(true)
		end

        -- We add 9 replays instantly to the replay list. This is so that it
        -- feels "filled" when you open the window (9 fills the window on an HD
        -- screen). We don't add more because adding replays is still quite
        -- slow Chobby wise, so we'll add the following ones asynchronously.
		for _ = 1, 9 do
			AddOneReplay()
		end
		PartialAddReplays()
	end

	listHolder:Hide()
	AddReplays()
	WG.Delay(function () listHolder:Show() end, 0.05)

	-------------------------
	-- Buttons
	-------------------------

	Button:New {
		right = 15,
		y = 7,
		width = 120,
		height = 45,
		caption = i18n("refresh"),
		objectoverridefont = myFont2,
		font = Configuration:GetFont(2),
		classname = "option_button",
		tooltip = "Refresh the list of replays",
		parent = parentControl,
		OnClick = {AddReplays},
	}

	moreButton = Button:New {
		right = 15 + 130,
		y = 7,
		width = 120,
		height = 45,
		caption = i18n("more"),
		objectoverridefont = myFont2,
		font = Configuration:GetFont(2),
		classname = "option_button",
		parent = parentControl,
		tooltip = "Load more, older replays",
		OnClick = {
			function ()
				if PartialAddReplays then
					PartialAddReplays()
				end
			end
		},
	}

	if Configuration.debugMode then
		local manualreplaypath = ''
		local replaymanual = EditBox:New{
			right = 15 + 520,
			y= 7,
			width = 200,
			height = 45,
			text = "/demos/",
			font = Configuration:GetFont(2),
			useIME = false,
			parent = parentControl,
			tooltip = "Enter the path to the replay",
			OnFocusUpdate = {
				function (obj)
					manualreplaypath = obj.text
					if obj.focused then
						return
					end
				end
			}
		}

		local manualbutton = Button:New{
			right = 15 + 390,
			y = 7,
			width = 120,
			height = 45,
			caption = "force start replay",
			objectoverridefont = myFont2,
			font = Configuration:GetFont(2),
			classname = "option_button",
			parent = parentControl,
			tooltip = "Force start a specific replay",
			OnClick = {
				function ()
					Spring.Echo("Attempting to start a manual replay from", manualreplaypath)
					WG.Chobby.localLobby:StartReplay(manualreplaypath, "BeherithDebugMode")
				end
			},

		}

	end


	if WG.BrowserHandler and Configuration.gameConfig.link_replays ~= nil then
		Button:New {
			right = 15 + 260,
			y = 7,
			width = 120,
			height = 45,
			caption = i18n("download"),
			objectoverridefont = myFont2,
			font = Configuration:GetFont(2),
			classname = "option_button",
			parent = parentControl,
			tooltip = "Get more replays from our website, and download the .sdfz files into your data/demos folder.",
			OnClick = {
				function ()
					WG.BrowserHandler.OpenUrl(Configuration.gameConfig.link_replays())
				end
			},
		}
	end

	local externalFunctions = {}

	function externalFunctions.AddReplay(replayPath, engine, game, map, players, time)
		--	Try to add the replay, show the stack trace in case of error
		xpcall(
			function ()
				local control, sortData = CreateReplayEntry(replayPath, engine, game, map, players, time)

				if control then
					replayList:AddItem(replayPath, control, sortData)
				end
			end,

			function (err)
				Spring.Log("AddReplay", LOG.ERROR, "Couldn't add replay", replayPath)
				Spring.Log("AddReplay", LOG.ERROR, debug.traceback(err))
			end
		)
	end

	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- External Interface

local ReplayHandler = {}

function ReplayHandler.GetControl()

	local window = Control:New {
		name = "replayHandler",
		x = "0%",
		y = "0%",
		width = "100%",
		height = "100%",
		OnParent = {
			function(obj)
				if obj:IsEmpty() then
					replayListWindow = InitializeControls(obj)
				end
			end
		},
	}
	return window
end

function ReplayHandler.ReadReplayInfoDone(path, engine, game, map, players, time)
	if not replayListWindow then
		return
	end

	replayListWindow.AddReplay(path, engine, game, map, players, time)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

local function DelayedInitialize()
end

function widget:Initialize()
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)
	WG.Delay(DelayedInitialize, 1)
	WG.ReplayHandler = ReplayHandler
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
