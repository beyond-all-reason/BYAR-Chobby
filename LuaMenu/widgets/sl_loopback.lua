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

local downloads2 = {} -- index table

-- FB 2023-05-14 outdated ?: downloads a file, type can be any of RAPID, MAP, MISSION, DEMO, ENGINE, NOTKNOWN
-- FB 2023-05-14 downloads a file, type can be any of game, map, engine, resource
function WrapperLoopback.DownloadFile(name, type, resource, debug_wherewecomefrom)
	Spring.Echo("WrapperLoopback DownloadFile")
	if type:lower() == "resource" and not resource then
		Spring.Echo("DownloadFile called with type resource, but no resouce infos given")
		-- ToDo: Call Finished
		return false
	end

	table.insert(downloads2, {
		nameSent = type:lower() == "resource" and resource.destination or name, -- FB 2023-05-14: Workaround for now: With "resource" DownloadProgress & DownloadFinished return destination as name
		name     = name,
		type     = type,
		typeSent = type:lower() == "rapid" and "game" or type:lower(),
		resource = resource -- {url, destination, extract}
	})
	Spring.Echo("sent download")
	Spring.Utilities.TableEcho(downloads2)

	WG.Connector.Send("Download", {
		name     = downloads2[#downloads2].nameSent,
		type     = downloads2[#downloads2].typeSent,
		resource = downloads2[#downloads2].resource,
	})
end

-- Starts a new spring instance, generally to play replays.
function WrapperLoopback.StartNewSpring(args)
	Spring.Echo("StartNewSpring")
	Spring.Utilities.TableEcho(args)
	Spring.Echo("StartNewSpring end")
	WG.Connector.Send("StartNewSpring", args)
end

local function GetDownloadByName(name)
	for i, download in ipairs(downloads2) do
		if download.name == name then
			return download, i
		end
	end
	return false, nil
end

local function GetDownloadByNameSent(nameSent)
	Spring.Echo("GetDownloadByNameSent")
	Spring.Utilities.TableEcho(downloads2)
	for i, download in ipairs(downloads2) do
		Spring.Echo("i, download.nameSent", i, download.nameSent)
		if download.nameSent == nameSent then
			return download, i
		end
	end
	return false, nil
end

function WrapperLoopback.AbortDownload(name, type)
	Spring.Echo("WrapperLoopback.AbortDownload(name,type)", name, type)
	local download = GetDownloadByName(name)
	if not download then
		Spring.Echo("AbortDownload, no download found with name:", name)
		-- ToDo: Handle this, e.g. set download = finished or aborted or failed or whatever
		return false
	end
	Spring.Echo("AbortDownload, download found:")
	Spring.Utilities.TableEcho(download)
	WG.Connector.Send("AbortDownload", {
		name = download.sentName,
		type = download.sentType
	})
end

-- reports that download has ended/was aborted
local function DownloadFinished(command)
	Spring.Echo("WrapperLoopback:local DownloadFinished")	
	Spring.Utilities.TableEcho(command)
	if not command.name then
		Spring.Echo("DownloadFinished without name")
		return false
	end

	local download, i = GetDownloadByNameSent(command.name)
	if not download then
		Spring.Echo("DownloadFinished, no download found with name", command.name) -- ERROR
		return false
	end
	Spring.Echo("AbortDownload, download found:")
	Spring.Utilities.TableEcho(download)
	
	WG.DownloadWrapperInterface.DownloadFinished(download.name, download.type, command.isSuccess, command.isAborted)
	table.remove(downloads2, i)
end

-- reports download progress. 100 might not indicate complation, wait for downloadfiledone
local function DownloadProgress(command)
	Spring.Echo("WrapperLoopback:local DownloadProgress")
	Spring.Utilities.TableEcho(command)
	if not command.name then
		Spring.Echo("DownloadProgress without name")
		return false
	end

	local download, i = GetDownloadByNameSent(command.name)
	if not download then
		Spring.Echo("DownloadProgress, no download found with name", command.name) -- ERROR
		Spring.Utilities.TableEcho(download)
		return false
	end
	Spring.Echo("DownloadProgress, download found:")
	Spring.Utilities.TableEcho(download)
	WG.DownloadWrapperInterface.DownloadFileProgress(download.name, command.progress * 100, command.total)
end

local function ParseMiniMapFinished(command)
	WG.MapHandler.ParseMiniMapFinished(command.mapPath, command.destinationPath)
end

-- Discord Rich Presence
function WrapperLoopback.DiscordSetActivity(command)
	WG.Connector.Send("DiscordSetActivity", command)
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
