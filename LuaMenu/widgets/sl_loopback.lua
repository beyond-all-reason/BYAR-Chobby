LIB_LOBBY_DIRNAME = "libs/liblobby/lobby/" -- why is this needed? why doesnt api load first?

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

local downloads = {} -- index table

-- FB 2023-05-14 downloads a file, type can be any of game, map, resource
-- engine not supported yet by launcher, though using resource here for engine downloads with workarounds!
function WrapperLoopback.DownloadFile(name, type, resource)
	LOG_SECTION = "downloader"

	if type:lower() == "resource" and not resource then

		Spring.Log(LOG_SECTION, LOG.ERROR, "DownloadFile called with type resource, but no resource infos given")

		WG.DownloadHandler.CancelDownload(name, type:lower(), "fail")

		return false
	end

	table.insert(downloads, {
		nameSent = type:lower() == "resource" and resource.destination or name, -- FB 2023-05-14: Workaround for now: With "resource" DownloadProgress & DownloadFinished return destination as name, so we just use destination as nameSent here to be forward compatible
		name     = name,
		type     = type,
		typeSent = type:lower() == "rapid" and "game" or type:lower(),
		resource = resource -- {url, destination, extract}
	})

	WG.Connector.Send("Download", {
		name     = downloads[#downloads].nameSent,
		type     = downloads[#downloads].typeSent,
		resource = downloads[#downloads].resource,
	})
end

-- Starts a new spring instance, generally to play replays.
function WrapperLoopback.StartNewSpring(args)
	WG.Connector.Send("StartNewSpring", args)
end

local function GetDownloadByName(name)
	for i, download in ipairs(downloads) do
		if download.name == name then
			return download, i
		end
	end
	return false, nil
end

local function GetDownloadByNameSent(nameSent)
	for i, download in ipairs(downloads) do
		if download.nameSent == nameSent then
			return download, i
		end
	end
	return false, nil
end

-- Replace all minutes (-) by (%-) so that it's not used by string.find as special char
-- example: "engine/105.1.1-1354-g72b2d55 bar" -> "engine/105.1.1%-1354%-g72b2d55 bar"
local function EscapeMinusPattern(text)
	local txt = text:gsub("([%-])", "%%%1")
	return txt
end

local function FindNameReceivedInDownloads(nameReceived)
	for i, download in ipairs(downloads) do
		if nameReceived:gsub("\\", "/"):find(EscapeMinusPattern(download.nameSent)) then -- replace backslashes(windows) with slashes, because that's how we generated it in CoopHandler:local GetEnginePath()
			return download, i
		end
	end
	return false, nil
end

local function startsWith(targetstring, pattern) 
	if string.len(pattern) <= string.len(targetstring) and pattern == string.sub(targetstring,1, string.len(pattern)) then
		return true, string.sub(targetstring, string.len(pattern) + 1)
	else
		return false
	end
end

local SkippingFile_PREFIX = "Skipping "
local SkippingFile_SUFFIX = ": already exists."
local download, dlIndex
-- reports that download has ended/was aborted
local function DownloadFinished(command)
	if not command.name then
		return false
	end

	download, dlIndex = FindNameReceivedInDownloads(command.name)
	if not download then
		Spring.Log(LOG_SECTION, LOG.ERROR, "Received command.name couldn't be matched to any known download:", command.name)
		return false
	end

	WG.DownloadWrapperInterface.DownloadFinished(download.name, download.type, command.isSuccess, command.isAborted)
	table.remove(downloads, dlIndex)
end

-- reports download progress. 100 might not indicate completion, wait for DownloadFinished
local function DownloadProgress(command)
	if not command.name then
		return false
	end

	local download, i = GetDownloadByNameSent(command.name)
	if not download then
		return false
	end
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
