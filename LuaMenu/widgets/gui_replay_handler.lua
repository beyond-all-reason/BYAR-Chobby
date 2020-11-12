--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Replays window",
		desc      = "Handles local replays.",
		author    = "GoogleFrog",
		date      = "20 October 2016",
		license   = "GNU LGPL, v2.1 or later",
		layer     = -100000,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Local Variables

local DEFLATE = VFS.Include("libs/LibDeflate/deflate.lua")

local replayListWindow

local delayedAddReplays = {}
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

local function CreateReplayEntry(replayPath, engineName, gameName, mapName)
	local Configuration = WG.Chobby.Configuration
  
	local fileName = string.sub(replayPath, 7)
	if string.sub(fileName, 0, 4) == "hide" then
		return
	end

	fileName = string.gsub(string.gsub(fileName, " maintenance", ""), " develop", "")
	fileName = string.gsub(fileName, "%.sdfz", "")

	local replayTime = string.sub(fileName, 0, 15)
	replayTime = string.sub(fileName, 0, 4) .. "-" .. string.sub(fileName, 5, 6) .. "-" .. string.sub(fileName, 7, 8) .. " " .. string.sub(fileName, 10, 11) .. ":" .. string.sub(fileName, 12, 13) 

	local replayPanel = Panel:New {
		x = 0,
		y = 0,
		width = "100%",
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
	}

	local startButton = Button:New {
		x = 3,
		y = 3,
		bottom = 3,
		width = 65,
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

	local replayDate = TextBox:New {
		name = "replayDate",
		x = 85,
		y = 12,
		right = 0,
		height = 20,
		valign = 'center',
		fontsize = Configuration:GetFont(2).size,
		text = replayTime,
		parent = replayPanel,
	}
	local replayMap = TextBox:New {
		name = "replayMap",
		x = 250,
		y = 12,
		right = 0,
		height = 20,
		valign = 'center',
		fontsize = Configuration:GetFont(2).size,
		text = mapName,
		parent = replayPanel,
	}
	local replayVersion = TextBox:New {
		name = "replayVersion",
		x = 425,
		y = 12,
		width = 400,
		height = 20,
		valign = 'center',
		fontsize = Configuration:GetFont(2).size,
		text = ShortenGameName(gameName),
		parent = replayPanel,
	}
  
	local replayEngine = TextBox:New {
		name = "replayEngine",
		x = 530,
		y = 12,
		width = 200,
		height = 20,
		valign = 'center',
		fontsize = Configuration:GetFont(2).size,
		text = ShortenEngineName(engineName),
		parent = replayPanel,
	}

	return replayPanel, {replayTime, string.lower(mapName), gameName}
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

	local headings = {
		{name = "Time", x = 88, width = 150},
		{name = "Map", x = 250, width = 100},
		{name = "Game", x = 420, width = 100},
		{name = "Engine", x = 530, right = 5},
	}

	local replayList = WG.Chobby.SortableList(listHolder, headings, nil, nil, false)

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
				--Spring.Echo("WG.WrapperLoopback.ReadReplayInfo(replayPath) commented out",replayPath)
				--WG.WrapperLoopback.ReadReplayInfo(replayPath)
        delayedAddReplays[#delayedAddReplays + 1 ] = replayPath
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

	function externalFunctions.AddReplay(replayPath, engine, game, map, script)
		local control, sortData = CreateReplayEntry(replayPath, engine, game, map)
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

function ReplayHandler.ReadReplayInfoDone(path, engine, game, map, script)
	if not replayListWindow then
		return
	end
	replayListWindow.AddReplay(path, engine, game, map, script)
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

-- replay struct looks like this:
--https://github.com/spring/spring/blob/30862626214bd263b1c4489bb197ef1c3dbc0738/rts/System/LoadSave/demofile.h#L53
local function ParseReplayBinaryString(rs)
  --local header = rs:sub(1,352)
  
  --local magic = rs:sub(1,16)                   --///< DEMOFILE_MAGIC
	--local version = VFS.UnpackU32(rs:sub(16,19)) --///< DEMOFILE_VERSION
	--local headerSize = VFS.UnpackU32(rs:sub(20,23)) --///< Size of the DemoFileHeader, minor version number.
  --Spring.Echo(magic, version, headerSize)
  
	--local versionString = rs:sub(24,279)  --///< Spring version string, e.g. "0.75b2", "0.75b2+svn4123"
  --Spring.Echo(versionString)
	--local gameID = rs:sub(278, 278+15) --///< Unique game identifier. Identical for each player of the game.
  --local unixTime =  VFS.UnpackU32(rs:sub(278+15,278+15+3)) --     ///< Unix time when game was started.
  local int32params = VFS.UnpackU32(rs,305,12)
  --[[
	int scriptSize;               ///< Size of startscript.
	int demoStreamSize;           ///< Size of the demo stream.
	int gameTime;                 ///< Total number of seconds game time.
	int wallclockTime;            ///< Total number of seconds wallclock time.
	int numPlayers;               ///< Number of players for which stats are saved. (this contains also later joined spectators!)
	int playerStatSize;           ///< Size of the entire player statistics chunk.
	int playerStatElemSize;       ///< sizeof(CPlayer::Statistics)
	int numTeams;                 ///< Number of teams for which stats are saved.
	int teamStatSize;             ///< Size of the entire team statistics chunk.
	int teamStatElemSize;         ///< sizeof(CTeam::Statistics)
	int teamStatPeriod;           ///< Interval (in seconds) between team stats.
	int winningAllyTeamsSize;     ///< The size of the vector of the winning ally teams
  ]]--

  local scriptsize = int32params[1]
  local scripttext = rs:sub(305+48,305+48+scriptsize -2) -- -2 to remove null terminator
  --Spring.Echo('scriptsize:',scriptsize,'scripttxt:',scripttext)
  local gameVersion = nil

  for line in scripttext:gmatch("[^\n]+") do
      if line:find("gametype=") then --gametype=Beyond All Reason test-13561-f7b35a8;
        gameVersion = line:sub(line:find("=")+1,line:find(";")-1)
        break;
      end
  end

  local mapName = nil --  mapname=Tropical;  --because the demo file name does not contain the name of the map after the first '.' character
	for line in scripttext:gmatch("[^\n]+") do
		if line:find("mapname=") then --gametype=Beyond All Reason test-13561-f7b35a8;
			mapName = line:sub(line:find("=")+1,line:find(";")-1)
			break;
		end
	end

  --Spring.Echo(scripttext, gameVersion,mapName)
  return scripttext, gameVersion, mapName

end

local function UnzipReplayHeaderString(replayPath)
	if replayPath:sub(-string.len('.sdfz')) ~= '.sdfz' then return nil end -- ignore other file types in /demos
    
    local replayFilename = string.sub(replayPath, 7)
    -- We assume all replays are in demos/ or demos\, dangerous!
	local time_map_engine = replayFilename
	
    --all engine branches are loved equally:
	local validEngineBranches = {"maintenance","develop","luaVAO","transition","BAR"}
	for k, branch in pairs(validEngineBranches) do
		--Spring.Echo(time_map_engine,branch)
		time_map_engine = string.gsub( time_map_engine," "..branch..".sdfz","")
		time_map_engine = string.gsub( time_map_engine,"_"..branch..".sdfz","")
	end
 

    --string.find(your_string, "_[^_]*$") -- find last underscore
    local replayEngine = string.sub(time_map_engine,string.find(time_map_engine, "_[^_]*$")+1 )
    local mymapname = string.sub(time_map_engine, 17, string.find(time_map_engine, "_[^_]*$")-1 )  --because the demo file name does not contain the name of the map after the first '.' character
    
    --[[ local zippedreplay = VFS.LoadFile(replayPath,VFS.RAW)
    local unzippedreplay = VFS.ZlibDecompress(zippedreplay,256000) --does not work!  ]]--
    
    local replayFileHandle = io.open(replayPath,'rb')
    local replayFile8kChunk = replayFileHandle:read(8192) --read an 8k chunk and hope that it contains the script
    replayFileHandle:close()
    
    if replayFile8kChunk == nil or string.len(replayFile8kChunk) < 1000 then return nil end
    
    local demoZipFilename = 'demos/replayFile8kChunk_zipped.tmp'
    local demoUnzippedFilename = 'demos/replayFile8kChunk_unzipped.tmp'
    
    local demoZipFile = io.open(demoZipFilename,'wb')
    demoZipFile:write(replayFile8kChunk)
    demoZipFile:close()

    demoZipFile = io.open(demoZipFilename,'rb')
    local demoUnzippedFile = io.open(demoUnzippedFilename,'wb')
    -- we pcall to trap EOF error  because we are only unzipping an 8k chunk of replay
    if pcall( function () DEFLATE.gunzip {input = demoZipFile, output = demoUnzippedFile, disable_crc= true} end ) then  end
      
    demoZipFile:close()
    demoUnzippedFile:close()
    
	local unzippedReplay = VFS.LoadFile(demoUnzippedFilename,VFS.RAW) -- can it load freshly made files?
	return unzippedReplay, replayEngine
end


function widget:Update() 
  -- This is needed because you cant populate a replay list efficiently
  -- So we process on on each update which has the side effect of looking nice
  if #delayedAddReplays > 1 then 
    local replayPath = delayedAddReplays[#delayedAddReplays]
    delayedAddReplays[#delayedAddReplays] = nil -- pop last one
    
	local unzippedReplayString, replayEngine = UnzipReplayHeaderString(replayPath)
	if unzippedReplayString == nil then 
		Spring.Log("Chobby",LOG.NOTICE,"Unable to unzip replay file", replayPath)
		return 
	end
	
	local scripttext, gameVersion, mapName= ParseReplayBinaryString(unzippedReplayString)
	if scripttext == nil or gameVersion == nil or mapName == nil then 
		Spring.Log("Chobby",LOG.NOTICE,"Unable to parse replay header", replayPath,gameVersion,replayEngine,mapname)
		return 
	end
	
	Spring.Log("Chobby",LOG.INFO,"Parsed replay", replayPath,gameVersion,mapname)
    WG.ReplayHandler.ReadReplayInfoDone(replayPath, replayEngine,gameVersion,mapName,scripttext)
  end 
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
