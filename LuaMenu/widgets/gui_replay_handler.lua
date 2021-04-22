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

-- Size constants for the replay window
local PLAYER_HEIGHT = 18
local REPLAY_LIST_ENTRY_HEIGHT = 120

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utilities

local function ShortenGameName(gameName)
	gameName = gameName:gsub("Beyond All Reason","BAR")
	gameName = gameName:gsub("test","")
	if gameName:find("-[^-]*$") then
	  gameName = gameName:sub(1, gameName:find("-[^-]*$") -1 )
	end
	return gameName
  end

  local function ShortenEngineName(engineName)
	if engineName:find("-[^-]*$") then
	  engineName = engineName:sub(1, engineName:find("-[^-]*$") -1)
	end
	return engineName
  end

  local function ternary(condition, T, F)
	  if condition then return T else return F end
  end

-- Returns whether the players structure of the replay request corresponds
-- to an FFA game ot not.
local function is_ffa(teams)
	if #teams <= 2	then
		return false
	end

	for i, team in pairs(teams) do
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
	for i, team in pairs(teams) do
		table.insert(teams_lengths, #team)
	end

	return table.concat(teams_lengths, "v")
end


--	From the flat array of players, build an array of teams
local function buildTeams(players)
	teams = {}
	for i, player in pairs(players) do
		local team
		if teams[player.allyTeamId] == nil then
			team = {}
			teams[player.allyTeamId] = team
		else
			team = teams[player.allyTeamId]
		end
		table.insert(team, player)
	end
	return teams
end

local function playerWidget(playerInfo)
	local Configuration = WG.Chobby.Configuration
	userName = playerInfo.name

	-- Create a control widget to encapsulate the player's information
	local ret = Chili.Control:New {
		x = 0, y = 0, right = 0,
		height=PLAYER_HEIGHT, bottom = 0, padding = {0, 0, 0, 0},
	}

	-- Get the rank image for the player
	local imageRank = Image:New {
		name = "imRank",
		x = 0,
		y = 0,
		width = 13,
		height = 13,
		parent = ret,
		keepAspect = false,
		file = Configuration.gameConfig.rankFunction(
			nil, tonumber(playerInfo.rank), 0, false, false
		)
	}

	-- Textbox with the user's name
	local userName = TextBox:New {
		name = "userName",
		x = 21, y = 0, right = 0, height = PLAYER_HEIGHT,
		valign = "top",
		fontsize = Configuration:GetFont(1).size,
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
	local replayTimeString = ""

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

	local imMinimap = Image:New {
		x = 0, y = 0,
		right = 0,
		bottom = 0,
		file = mapImageFile,
		fallbackFile = Configuration:GetLoadingImage(3),
		checkFileExists = needDownload,
		parent = minimap,
		tooltip = "prout"
	}

	local replayBattleType = TextBox:New {
		name = "replayBattleType",
		x = 135, y = 22,
		right = 0, height = 20,
		valign = 'center',
		fontsize = Configuration:GetFont(2).size,
		text = battleType(teams),
		parent = replayPanel,
	}

	local replayDate = TextBox:New {
		name = "replayDate",
		x = 135, y = 65,
		right = 0, height = 20,
		valign = 'center',
		fontsize = Configuration:GetFont(1).size,
		text = replayDateString,
		parent = replayPanel,
	}

	local replayTime = TextBox:New {
		name = "replayTime",
		x = 135, y = 82,
		right = 0, height = 20,
		valign = 'center',
		fontsize = Configuration:GetFont(1).size,
		text = replayTimeString,
		parent = replayPanel,
	}

	local replayMap = TextBox:New {
		name = "replayMap",
		x = 135, y = 42,
		right = 0, height = 20,
		valign = 'center',
		fontsize = Configuration:GetFont(2).size,
		text = mapName,
		parent = replayPanel,
	}

	-- Compute the teams/players lists

	local userList = Chili.Control:New {
		x = 415, y = 10,
		right = 0, bottom = 0,
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
		local teamId = TextBox:New {
			x = xOffset, y = yOffset, right = 0, height = 10,
			valign = 'center',
			fontsize = Configuration:GetFont(1).size,
			text = "Team " .. i,
			parent = userList,
		}
		yOffset = yOffset + PLAYER_HEIGHT

		--	Then add each player on a subsequent line
		for i, player in pairs(team) do

			--	If there are too many players to display on one line, just add
			--	an ellipsis and skip subsequent players for the team.
			if yOffset + PLAYER_HEIGHT * 2 >= REPLAY_LIST_ENTRY_HEIGHT then
				local ellipsis = TextBox:New {
					x = xOffset, y = YOffset, text = "..."
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

	local startButton = Button:New {
		x = "90%",
		y = 3,
		bottom = 3,
		width = "8%",
		caption = i18n("start"),
		classname = ternary(WG.Chobby.Configuration:IsValidEngineVersion(engineName),"action_button",option_button),
		font = WG.Chobby.Configuration:GetFont(2),
		OnClick = {
			function()
				if not replayPath then
					return
				end
				local offEngine = not WG.Chobby.Configuration:IsValidEngineVersion(engineName)
				WG.SteamCoopHandler.AttemptGameStart("replay", gameName, mapName, nil, nil, replayPath, offEngine and engineName)
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
	Label:New {
		x = 15,
		y = 11,
		width = 180,
		height = 30,
		parent = parentControl,
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

	local loadingLabel = Label:New {
		x = "5%",
		y = "5%",
		width = "90%",
		height = "90%",
		align = "center",
		valign = "center",
		parent = loadingPanel,
		font = Configuration:GetFont(3),
		caption = "Loading",
	}

	-------------------------
	-- Replay List
	-------------------------

	local listHolder = Control:New {
		x = 12,
		right = 15,
		y = 60,
		bottom = 15,
		parent = parentControl,
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
	}

	local headings = {}

	local replayList = WG.Chobby.SortableList(
		listHolder, headings, REPLAY_LIST_ENTRY_HEIGHT, nil, false
	)

	local PartialAddReplays, moreButton

	local function AddReplays()
		local replays = VFS.DirList("demos")
		--Spring.Utilities.TableEcho(replays, "replaysList")

		replayList:Clear()

		if moreButton then
			moreButton:SetVisibility(true)
		end

		local index = #replays
		PartialAddReplays = function()
			loadingPanel:SetVisibility(true)
			loadingPanel:BringToFront()
			local items = {}
			for i = 1, 20 do
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

			loadingPanel:SetVisibility(false)
		end

		PartialAddReplays()
	end

	AddReplays()

	-------------------------
	-- Buttons
	-------------------------

	Button:New {
		x = 100,
		y = 7,
		width = 110,
		height = 45,
		caption = i18n("refresh"),
		font = Configuration:GetFont(3),
		classname = "option_button",
		parent = parentControl,
		OnClick = {
			function ()
				AddReplays()
			end
		},
	}

	moreButton = Button:New {
		x = 340,
		y = 7,
		width = 110,
		height = 45,
		caption = i18n("more"),
		font = Configuration:GetFont(3),
		classname = "option_button",
		parent = parentControl,
		OnClick = {
			function ()
				if PartialAddReplays then
					PartialAddReplays()
				end
			end
		},
	}
	--local btnClose = Button:New {
	--	right = 11,
	--	y = 7,
	--	width = 80,
	--	height = 45,
	--	caption = i18n("close"),
	--	font = Configuration:GetFont(3),
	--	classname = "negative_button",
	--	OnClick = {
	--		function()
	--			parentControl:Hide()
	--		end
	--	},
	--	parent = parentControl
	--}

	if WG.BrowserHandler and Configuration.gameConfig.link_replays ~= nil then
		Button:New {
			x = 220,
			y = 7,
			width = 110,
			height = 45,
			caption = i18n("download"),
			font = Configuration:GetFont(3),
			classname = "option_button",
			parent = parentControl,
			OnClick = {
				function ()
					WG.BrowserHandler.OpenUrl(Configuration.gameConfig.link_replays())
				end
			},
		}
	end

	local externalFunctions = {}

	function externalFunctions.AddReplay(replayPath, engine, game, map, players, time)
		local control, sortData = CreateReplayEntry(replayPath, engine, game, map, players, time)
		if control then
			replayList:AddItem(replayPath, control, sortData)
		end
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
	local Configuration = WG.Chobby.Configuration
	battleStartDisplay = Configuration.game_fullscree
end

function widget:Initialize()
	CHOBBY_DIR = LUA_DIRNAME .. "widgets/chobby/"
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	WG.Delay(DelayedInitialize, 1)

	WG.ReplayHandler = ReplayHandler
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
