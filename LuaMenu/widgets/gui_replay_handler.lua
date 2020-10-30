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

local DEFLATE =  VFS.Include("libs/LibDeflate/deflate.lua")

local replayListWindow

local delayedAddReplays = {}
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utilities

local function CreateReplayEntry(replayPath, engineName, gameName, mapName)
	local Configuration = WG.Chobby.Configuration
  --[[

  -- params needed: engine name, mapname from 20201021_194926_Tetrad_V2_104.0.1-1553-gd3c0012 maintenance.sdfz
  -- input is replayPath
  local replayFilename = string.sub(replayPath, 7)
  -- WE ARE ASSUMING ALL DEMOS ARE IN demos/ or demos\, this is pure idiocy but ok
  local time_map_engine_branch = string.gsub(replayFilename, "%.sdfz", "")

  --all engine branches are loved equally:
  local time_map_engine = string.gsub(string.gsub(string.gsub(string.gsub(time_map_engine_branch, " maintenance", ""), " develop", ""), " luaVAO",""), " transition", "")
  
  Spring.Echo(replayFilename, time_map_engine_branch, time_map_engine)
  
  --string.find(your_string, "_[^_]*$") -- last underscore
  local engineName = string.sub(time_map_engine,string.find(time_map_engine, "_[^_]*$")+1 )
  local mymapname = string.sub(time_map_engine, 17, string.find(time_map_engine, "_[^_]*$")-1 )
  
  
  local myreplayTime = string.sub(replayFilename, 0, 4) .. "-" .. string.sub(replayFilename, 5, 6) .. "-" .. string.sub(replayFilename, 7, 8) .. " at " .. string.sub(replayFilename, 10, 11) .. ":" .. string.sub(replayFilename, 12, 13) .. ":" .. string.sub(replayFilename, 14, 15)
  Spring.Echo("demo file path Parse complete:", myreplayTime, engineName,mymapname,time_map_engine,replayFilename,replayName)
  ]]--
  
  
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
		classname = "action_button",
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
		x = 435,
		y = 12,
		width = 400,
		height = 20,
		valign = 'center',
		fontsize = Configuration:GetFont(2).size,
		text = gameName,
		parent = replayPanel,
	}
	local replayEngine = TextBox:New {
		name = "replayEngine",
		x = 535,
		y = 16,
		width = 400,
		height = 20,
		valign = 'center',
		fontsize = Configuration:GetFont(2).size,
		text = engineName,
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
		{name = "Game", x = 350, width = 100},
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
        --replayListWindow.AddReplay(replayPath, "NGINE", "BAR", "DUCK", "script")
        --ReplayHandler.ReadReplayInfoDone(replayPath, "NGINE", "BAR", "DUCK", "script")
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
      if line:find("gametype") then
        gameVersion = line:sub(line:find("=")+1,line:find(";")-1)
      end
  end
  --Spring.Echo(scripttext, gameVersion)
  return scripttext, gameVersion

end


function widget:Update() --BECAUSE YOU CANT POPULATE REPLAY LIST WHILE IT IS BEING CREATED: fuck counter++
    if #delayedAddReplays > 1 then -- worlds greatest asyncronous method of loading replays
        local replayPath = delayedAddReplays[#delayedAddReplays]
        
        if replayPath:sub(-string.len('.sdfz')) == '.sdfz' then
          local replayFilename = string.sub(replayPath, 7)
          -- WE ARE ASSUMING ALL DEMOS ARE IN demos/ or demos\, this is pure idiocy but ok
          local time_map_engine_branch = string.gsub(replayFilename, "%.sdfz", "")

          --all engine branches are loved equally:
          local time_map_engine = string.gsub(string.gsub(string.gsub(string.gsub(time_map_engine_branch, " maintenance", ""), " develop", ""), " luaVAO",""), " transition", "")
          
          --string.find(your_string, "_[^_]*$") -- find last underscore
          local replayEngine = string.sub(time_map_engine,string.find(time_map_engine, "_[^_]*$")+1 )
          local mymapname = string.sub(time_map_engine, 17, string.find(time_map_engine, "_[^_]*$")-1 )
          
          --[[
          local zippedreplay = VFS.LoadFile(replayPath,VFS.RAW)
          local unzippedreplay = VFS.ZlibDecompress(zippedreplay,256000) --does not work!
          ]]--
          
          local rfh = io.open(replayPath,'rb')
          local startchunk = rfh:read(8192)
          rfh:close()
          
          if startchunk and string.len(startchunk) > 1000 then
          
            local tmpdemozip = 'demos/temp_zipped_replay_chunk'
            
            local tmpdemounzip = 'demos/temp_unzipped_replay_chunk'
            
            local tmpdemozip_handle = io.open(tmpdemozip,'wb')
            tmpdemozip_handle:write(startchunk)
            tmpdemozip_handle:close()

            local fh = io.open(tmpdemozip,'rb')
            local ofh = io.open(tmpdemounzip,'wb')
            -- we pcall to trap EOF because we are scum.
            if pcall( function () DEFLATE.gunzip {input = fh, output = ofh, disable_crc= true} end ) then
            end
              
            fh:close()
            ofh:close()
            
            local zippedreplay = VFS.LoadFile(tmpdemounzip,VFS.RAW) -- can it load freshly made files?
            --local scumfile = io.open(tmpdemounzip,'rb')
            --local scumfilebin = scumfile:read()
            local scripttext, gameVersion = ParseReplayBinaryString(zippedreplay)
            
            if scripttext ~= nil and gameVersion ~= nil then
              WG.ReplayHandler.ReadReplayInfoDone(replayPath, replayEngine,gameVersion,mymapname,scripttext)
            end
          end
        end
      delayedAddReplays[#delayedAddReplays] = nil -- pop
    end 
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
