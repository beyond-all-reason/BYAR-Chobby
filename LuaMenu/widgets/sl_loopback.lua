LIB_LOBBY_DIRNAME = "libs/liblobby/lobby/" -- why is this needed? why doesnt api load first?
VFS.Include(LIB_LOBBY_DIRNAME .. "json.lua")

function widget:GetInfo()
return {
	name	= "Spring-Launcher wrapper loopback interface",
	desc	= "Creates a commlink between spring-launcher's wrapper and chobby",
	author	= "gajop",
	date	= "really late",
	license = "MIT",
	layer	= -10000,
	enabled = true,
}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Callout Functions

local WrapperLoopback = {}

-- opens URL
function WrapperLoopback.OpenUrl(url)
	WG.Connector.Send("OpenFile", {
		path = url
	})
end

-- opens folder (gamedata folder only technically)
function WrapperLoopback.OpenFolder(folder)
	if folder == nil then
		folder = WG.Connector.writePath
	end
	WG.Connector.Send("OpenFile", {
		path = "file://" .. folder
	})
end

function WrapperLoopback.UploadLog()
	WG.Connector.Send("UploadLog")
end

function WrapperLoopback.ReadReplayInfo(relativePath)
	WG.Connector.Send("ReadReplayInfo", {
		relativePath = relativePath
	})
end

function WrapperLoopback.ParseMiniMap(mapPath, destination, miniMapSize)
	WG.Connector.Send("ParseMiniMap", {
		mapPath = mapPath,
		destination = destination,
		miniMapSize = miniMapSize
	})
end

local downloads = {}

-- downloads a file, type can be any of RAPID, MAP, MISSION, DEMO, ENGINE, NOTKNOWN
function WrapperLoopback.DownloadFile(name, type)
	downloads[name] = type

	type = type:lower()
	if type == "rapid" then
		type = "game"
	end
	WG.Connector.Send("Download", {
		name = name,
		type = type
	})
end

-- Starts a new spring instance, generally to play replays.
function WrapperLoopback.StartNewSpring(args)
	WG.Connector.Send("StartNewSpring", args)
end

function WrapperLoopback.AbortDownload(name, type)
	WG.Connector.Send("AbortDownload", {
		name = name,
		type = type
	})
end


-- reports that download has ended/was aborted
local function DownloadFinished(command)
	local type = downloads[command.name]
	WG.DownloadWrapperInterface.DownloadFinished(command.name, type, command.isSuccess, command.isAborted)
	downloads[command.name] = nil
end

-- reports download progress. 100 might not indicate complation, wait for downloadfiledone
local function DownloadProgress(command)
	WG.DownloadWrapperInterface.DownloadFileProgress(command.name, command.progress * 100, command.total)
end

local function ParseMiniMapFinished(command)
	WG.MapHandler.ParseMiniMapFinished(command.mapPath, command.destinationPath)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

-- replay info read
local function ReplayInfo(command)
	--[[
	    public class ReadReplayInfoDone {
                    public string RelativePath { get; set; }
                   public ReplayReader.ReplayInfo ReplayInfo { get; set; }

  public class ReplayInfo
        {
            public string Engine { get; set; }
            public string Game { get; set; }
            public string Map { get; set; }
            public string StartScript { get; set; }
            public DateTime Date { get; set; }
            public int GameLengthRealtime { get; set; }
            public int GameLengthIngameTime { get; set; }
            public string GameID { get; set; }
            public List<PlayerEntry> Players { get; set; } = new List<PlayerEntry>();

            public class PlayerEntry
            {
                public bool IsSpectator { get; set; }
                public bool IsBot { get; set; }
                public string Name { get; set; }
                public int? AllyTeam { get; set; }
            }
        }


		ReplayInfo is nil in case of failure

             }

	--]]

	WG.ReplayHandler.ReadReplayInfoDone(
		command.relativePath,
		command.engine,
		command.game,
		command.map,
		command.players,
		command.gameTime,
		command.winningAllyTeamIds
	)
end


-- init
function widget:Initialize()
	if WG.Connector == nil or not WG.Connector.enabled then
		widgetHandler:RemoveWidget()
		Spring.Log("Chobby", LOG.NOTICE, "spring-launcher doesn't exist.")
		return
	end

	WG.WrapperLoopback = WrapperLoopback

	WG.Connector.Register('ReplayInfo', ReplayInfo)
	WG.Connector.Register('ParseMiniMapFinished', ParseMiniMapFinished)
	WG.Connector.Register('DownloadProgress', DownloadProgress)
	WG.Connector.Register('DownloadFinished', DownloadFinished)
end
