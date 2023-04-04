LIB_LOBBY_DIRNAME = "libs/liblobby/lobby/" -- why is this needed? why doesnt api load first?

VFS.Include(LIB_LOBBY_DIRNAME .. "json.lua")
VFS.Include(LIB_LOBBY_DIRNAME .. "utilities.lua")

function widget:GetInfo()
return {
	name    = "ZK wrapper loopback interface",
	desc    = "Creates a commlink between wrapper and chobby",
	author  = "Licho",
	date    = "too late man",
	license = "GNU GPL, v2 or later",
	layer   = -10010,
	enabled = true,
}
end

local socket = socket
local client
local buffer = ""
local commands = {} -- table with possible commands

local PRINT_DEBUG = false

-- debug message/popup
local function Echo(stuff)
	Chotify:Post({
		title = "Wrapper",
		body = stuff,
	})
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Connectivity and sending

-- sends command to wrapper
function SendCommand(cmdName, args)
	if (args == nil) then
		client:send(cmdName .. " {}\n")
	else
		client:send(cmdName .. " " ..json.encode(args).."\n")
	end

	if PRINT_DEBUG then
		Spring.Echo("SendCommand", cmdName .. " " .. ((args and json.encode(args)) or "{}"))
	end
end

local function SocketConnect(host, port)
	client=socket.tcp()
	client:settimeout(0)
	res, err = client:connect(host, port)
	if not res and not res=="timeout" then
		Echo("Error in connect wrapper: "..err)
		return false
	end
	return true
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Callin Functions

-- Use listener interface from configuration when implementing this

-- replay info read
local function ReadReplayInfoDone(args)
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

	]]--
	local data = args.ReplayInfo
	if data then
		WG.ReplayHandler.ReadReplayInfoDone(args.RelativePath, data.Engine, data.Game, data.Map, data.StartScript)
	end
end


local function GetSpringBattleInfoDone(args)
--[[
   [ChobbyMessage]
    public class GetSpringBattleInfoDone
    {
        public string GameID { get; set; }
        public SpringBattleInfo SpringBattleInfo { get; set; }
    }
	    public class SpringBattleInfo
    {
        public int SpringBattleID { get; set; }
        public AutohostMode AutohostMode { get; set; }
        public bool IsMatchMaker { get; set; }
        public string Title { get; set; }
    }
]]--

end


-- reports that download has ended/was aborted
local function DownloadFileDone(args)
	WG.DownloadWrapperInterface.DownloadFinished(args.Name, args.FileType, args.IsSuccess, args.IsAborted)
end

-- reports download progress. 100 might not indicate complation, wait for downloadfiledone
local function DownloadFileProgress(args)
	WG.DownloadWrapperInterface.DownloadFileProgress(args.Name, args.Progress, args.TotalLength)
end

-- notifies that steam is online
local function SteamOnline(args)
	WG.SteamHandler.SteamOnline(args.AuthToken, args.FriendSteamID, args.Friends, args.SuggestedName, args.Dlc)
	if args.FriendSteamID then
		WG.SteamHandler.SteamJoinFriend(args.FriendSteamID)
		WG.SteamCoopHandler.SteamJoinFriend(args.FriendSteamID)
	end
end

-- Join friend upon receiving notification that your acceptance of their invite was accepted.
local function SteamJoinFriend(args)
	WG.SteamHandler.SteamJoinFriend(args.FriendSteamID)
	WG.SteamCoopHandler.SteamJoinFriend(args.FriendSteamID)
end

local function SteamOverlayChanged(args)
	WG.SteamHandler.SteamOverlayChanged(args.IsActive)
end

-- TODO wire this to set initial stuff and pass userid to ZKLS
local function WrapperOnline(args)
	local config = WG.Chobby and WG.Chobby.Configuration
	if config then
		config.DefaultServerPort = args.DefaultServerPort
		config.DefaultServerHost = args.DefaultServerHost
		config.UserID = args.UserID
		config.InstallID = args.InstallID
		config.IsSteamFolder = args.IsSteamFolder
		if config.DefaultServerPort == 8202 and config.DefaultServerHost == "test.zero-k.info" then
			config.ForceDefaultServer = true
		end
	end
end

-- TODO wrapper will send this to confirm friend join on steam (either invite or self join) use to auto accept party join request and to notify player when joining "offline" COOP
local function SteamFriendJoinedMe(args)
	WG.SteamCoopHandler.SteamFriendJoinedMe(args.FriendSteamID, args.FriendSteamName)
	--[[
	    public string FriendSteamID { get; set; }
        public string FriendSteamName { get; set; }
	]]--
end


-- TODO wrapper will send this to indicate P2P host request is ok and this chobby should start hosting asap, using the given local port
local function SteamHostGameSuccess(args)
	WG.SteamCoopHandler.SteamHostGameSuccess(args.HostPort)
	-- args.HostPort
end

-- TODO p2p hosting has failed
local function SteamHostGameFailed(args)
	WG.SteamCoopHandler.SteamHostGameFailed(args.CausedBySteamID, args.Reason)
	-- args.CausedBySteamID
	-- args.Reason
end

-- TODO when client receives this he should connect given game, it MUST use the passed ClientPort for local game
local function SteamConnectSpring(args)
	WG.SteamCoopHandler.SteamConnectSpring(args.HostIP, args.HostPort, args.ClientPort, args.Name, args.ScriptPassword, args.Map, args.Game, args.Engine)
	--[[
        public string HostIP { get; set; }
        public int HostPort { get; set; }
        public int ClientPort { get; set; }

        public string Name { get; set; }
        public string ScriptPassword { get; set; }
        public string Map { get; set; }
        public string Game { get; set; }

        public string Engine { get; set; }
	]]--
end

local function DownloadImageDone(args)
	--[[
    public class DownloadImageDone
    {
        public string RequestToken { get; set; } // client can set token to track multiple responses/requests
        public string ImageUrl
        public string TargetPath
    }
	]]--
	WG.DownloadWrapperInterface.ImageDownloadFinished(args.RequestToken, args.ImageUrl, args.TargetPath)
end

local function DiscordOnReady(args)
end

local function DiscordOnSpectate(args)
 -- args.Secret
end

local function DiscordOnJoin(args)
 -- args.Secret
end

local function DiscordOnError(args)
 -- args.Message
 -- args.ErrorCode
end

local function DiscordOnDisconnected(args)
  -- args.Message
  -- args.ErrorCode
end

local function DiscordOnJoinRequest(args)
 -- args.userId
 -- args.username
 -- args.discriminator
 -- args.avatar
end

local function UserActivity(args)
	-- args.IdleSeconds
	if WG.AwayTracker_UserActivity then
		WG.AwayTracker_UserActivity(args.IdleSeconds)
	end
end

commands["DownloadFileDone"] = DownloadFileDone
commands["SteamOnline"] = SteamOnline
commands["SteamJoinFriend"] = SteamJoinFriend
commands["SteamOverlayChanged"] = SteamOverlayChanged
commands["WrapperOnline"] = WrapperOnline
commands["SteamFriendJoinedMe"] = SteamFriendJoinedMe
commands["SteamHostGameSuccess"] = SteamHostGameSuccess
commands["SteamHostGameFailed"] = SteamHostGameFailed
commands["SteamConnectSpring"] = SteamConnectSpring
commands["DownloadImageDone"] = DownloadImageDone
commands["DownloadFileProgress"] = DownloadFileProgress
commands["ReadReplayInfoDone"] = ReadReplayInfoDone
commands["GetSpringBattleInfoDone"] = GetSpringBattleInfoDone

commands["DiscordOnReady"] = DiscordOnReady
commands["DiscordOnSpectate"] = DiscordOnSpectate
commands["DiscordOnJoin"] = DiscordOnJoin
commands["DiscordOnError"] = DiscordOnError
commands["DiscordOnDisconnected"] = DiscordOnDisconnected
commands["DiscordOnJoinRequest"] = DiscordOnJoinRequest

commands["UserActivity"] = UserActivity

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Callout Functions

local WrapperLoopback = {}

function WrapperLoopback.ReadReplayInfo(relativePath)
	SendCommand("ReadReplayInfo", {RelativePath = relativePath})
end

function WrapperLoopback.GetSpringBattleInfo(gameId)
	SendCommand("GetSpringBattleInfo", {GameID = gameID})
end

function WrapperLoopback.SendBugReport(title, description)
	SendCommand("SendBugReport", {Title  = title, Description = description})
end

-- opens URL
function WrapperLoopback.OpenUrl(url)
	Spring.Echo("Opening URL", url)
	SendCommand("OpenUrl", {Url = url})
end

-- opens folder (gamedata folder only technically)
function WrapperLoopback.OpenFolder(folder)
	SendCommand("OpenFolder", nil)
end

-- restart chobby
function WrapperLoopback.Restart()
	SendCommand("Restart", nil)
end

-- notifies user/flashes spring window (message ignored atm)
function WrapperLoopback.Alert(message)
	SendCommand("Alert", {Message= message})
end

-- sets TTS volume
function WrapperLoopback.TtsVolume(volume)
	SendCommand("TtsVolume", {Volume = volume})
end

-- speaks using TTS, send name of speaker for alternating speaker voices
function WrapperLoopback.TtsSay(name, text)
	SendCommand("TtsSay", {Name = name, Text = text})
end

-- downloads a file, fileType can be any of RAPID, MAP, MISSION, DEMO, ENGINE, NOTKNOWN
function WrapperLoopback.DownloadFile(name, fileType)
	SendCommand("DownloadFile", {Name = name, FileType = fileType})
end

--  aborts existing file download
function WrapperLoopback.AbortDownload(name, fileType)
	SendCommand("AbortDownload", {Name = name, FileType = fileType})
end



function WrapperLoopback.StartNewSpring(args)
--[[
    public class StartNewSpring
    {
        public string StartScriptContent { get; set; }  // content of the script - leave empty if launching demo
        public string StartDemoName { get; set; } // name of the demo to launch

		public string Engine { get; set; } // name of the engine, this file also gets auto checked/downloaded

        public string SpringSettings { get; set;  } // spring settings override

        public List<DownloadFile> Downloads { get; set; } // list of downloads, files here will be downloaded before spring is started. Include demo file here, if its not local already.
														  // each download file contains  FileType and Name
														  // non-rapid entries will be always redownloaded, so check presence of map before requesting it, wrapper does not init unitsync
    }
]]--
	--Spring.Utilities.TableEcho(args, "StartNewSpring")
	SendCommand("StartNewSpring", args)
end

function WrapperLoopback.DownloadSpring(args)
	--args = {Engine = versionString}
	SendCommand("DownloadSpring", args)
end

function WrapperLoopback.DownloadImage(args)
--[[
    [ChobbyMessage]
    public class DownloadImage
    {
        public string RequestToken { get; set; } // client can set token to track multiple responses/requests
        public string ImageUrl { get; set; }
        public string TargetPath { get; set; }
    }
]]--
	SendCommand("DownloadImage", args)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Steam

-- opens steam section, default = "LobbyInvite"
-- WARNING: FPS needs to be increased, overlay works at chobby FPS
function WrapperLoopback.SteamOpenOverlaySection(name)
	local config = WG.Chobby and WG.Chobby.Configuration
	if not (config and config.steamOverlayEnablable) then
		WG.Chobby.InformationPopup("Steam overlay is currently broken on linux. Play coop with friends by inviting via Steam.")
		return
	end
	SendCommand("SteamOpenOverlaySection", {Option = name or "LobbyInvite"})
end

-- opens url in steam browser
-- of overlay not available, opens ext. browser
-- WARNING: FPS needs to be increased, overlay works at chobby FPS
function WrapperLoopback.SteamOpenWebsite(url)
	SendCommand("SteamOpenOverlayWebsite", {Url = url})
end

-- invites friend to a game, even offline
function WrapperLoopback.SteamInviteFriendToGame(steamID)
	SendCommand("SteamInviteFriendToGame", {SteamID = steamID})
end

-- TODO instructs wrapper to establish p2p, punch ports and start clients
function WrapperLoopback.SteamHostGameRequest(args)
	--[[
        public class SteamHostPlayerEntry
        {
            public string SteamID { get; set; }
            public string Name { get; set; }
            public string ScriptPassword { get; set; }
        }

        public List<SteamHostPlayerEntry> Players { get; set; } = new List<SteamHostPlayerEntry>();
        public string Map { get; set; }
        public string Game { get; set; }

        public string Engine { get; set; }
	]]--
	SendCommand("SteamHostGameRequest", args)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Discord

function WrapperLoopback.DiscordUpdatePresence(args)
	--[[
        public string state; /* max 128 bytes */
        public string details; /* max 128 bytes */
        public long startTimestamp;
        public long endTimestamp;
        public string largeImageKey; /* max 32 bytes */
        public string largeImageText; /* max 128 bytes */
        public string smallImageKey; /* max 32 bytes */
        public string smallImageText; /* max 128 bytes */
        public string partyId; /* max 128 bytes */
        public int partySize;
        public int partyMax;
        public string matchSecret; /* max 128 bytes */
        public string joinSecret; /* max 128 bytes */
        public string spectateSecret; /* max 128 bytes */
        public bool instance;
	]]--
	SendCommand("DiscordUpdatePresence", args)
end

function WrapperLoopback.DiscordRespond(args)
	--[[
	public string UserId { get; set; }
          public int Reply { get; set; }
	]]--
	SendCommand("DiscordRespond", args)
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Analytics


-- sends error event to GA. Severity must be one of: Undefined, Debug, Info, Warning, Error,Critical,
function WrapperLoopback.GaAddErrorEvent(severity, message)
	SendCommand("GaAddErrorEvent", {Severity = severity, Message = message})
end

-- sends GA design event (for example gui actions). Value is optional, if sent must be double
function WrapperLoopback.GaAddDesignEvent(eventID, value)
	SendCommand("GaAddDesignEvent", {EventID = eventID, Value = value})
end

-- sends GA progression event. Score is optional, if sent must be double. Level3 and 2 are optional but if 3 is sent then 2 and 1 must be set and if 2 is sent then 1 must be set.
function WrapperLoopback.GaAddProgressionEvent(status, progression1, progression2, progression3, score)
	SendCommand("GaAddProgressionEvent", {Status = status, Progression1 = progression1, Progression2 = progression2, Progression3 = progression3, Score = score})
end

-- NOTE: amount must be whole number
function WrapperLoopback.GaAddBusinessEvent(amount, cartType, currency, itemId, itemType)
	SendCommand("GaAddBusinessEvent", {Amount = amount, CartType= cartType, Currency = currency, ItemId = itemId, ItemType = itemType})
end

-- NOTE: flow type:  Undefined | Source | Sink
function WrapperLoopback.GaAddResourceEvent(amount, currency, flowType, itemId, itemType)
	SendCommand("GaAddResourceEvent", {Amount = amount, Currency = currency, FlowType = flowType, ItemId = itemId, ItemType = itemType})
end

function WrapperLoopback.GaConfigureResourceCurrencies(list)
	SendCommand("GaConfigureResourceCurrencies", {List = list})
end

function WrapperLoopback.GaConfigureResourceItemTypes(list)
	SendCommand("GaConfigureResourceItemTypes", {List = list})
end

-- NOTE: level 1-3
function WrapperLoopback.GaConfigureCustomDimensions(level, list)
	SendCommand("GaConfigureCustomDimensions", {Level = level, List = list})
end

-- NOTE: level 1-3
function WrapperLoopback.GaSetCustomDimension(level, list)
	SendCommand("GaSetCustomDimension", {Level = level, List = list})
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Data

function WrapperLoopback.GetSteamAuthToken()

end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

-- init
function widget:Initialize()
	CHOBBY_DIR = LUA_DIRNAME .. "widgets/chobby/"
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	local port = VFS.LoadFile("chobby_wrapper_port.txt"); -- get wrapper port from VFS file
	if not port then
		widgetHandler:RemoveWidget()
		Spring.Log("Chobby", LOG.NOTICE, "No port support, chobby_wrapper_port.txt not found.")
		return
	end
	Spring.Log("Chobby", LOG.NOTICE, "Using wrapper port: ", port)
	SocketConnect("127.0.0.1", port)

	WG.WrapperLoopback = WrapperLoopback
end

-- pocesses raw string line and executes command
local function CommandReceived(command)
	i = command:find(" ")
	if i ~= nil then
		cmdName = command:sub(1, i - 1)
		arguments = command:sub(i + 1)
	else
		cmdName = command
	end

	local commandFunc = commands[cmdName]
	if PRINT_DEBUG then
		if string.find(cmdName, "Download") then
			Spring.Echo("LoopbackCommandReceived", cmdName, arguments)
		else
			Spring.Echo("LoopbackCommandReceived", cmdName)
		end
	end
	if commandFunc ~= nil then
		local success, obj = pcall(json.decode, arguments)
		if not success then
			Spring.Log(LOG_SECTION, LOG.ERROR, "Failed to parse JSON: " .. tostring(arguments))
		else
			commandFunc(obj)
		end
	else
		Spring.Log(LOG_SECTION, LOG.ERROR, "No such function: " .. cmdName .. ", for command: " .. command)
	end
end

-- update socket - receive data and split into lines
function widget:Update()
	local readable, writeable, err = socket.select({client}, {client}, 0)
	if err ~= nil then
		Spring.Echo("Loopback error in select", err)
		--Echo("Error in select: " .. err)
	end
	for _, input in ipairs(readable) do
		local s, status, str = input:receive('*a') --try to read all data
		if (status == "timeout" or status == nil) and str ~= nil and str ~= "" then
			local commandList = explode("\n", str)
			commandList[1] = buffer .. commandList[1]
			for i = 1, #commandList-1 do
				local command = commandList[i]
				if command ~= nil then
					CommandReceived(command)
				end
			end
			buffer = commandList[#commandList]

		elseif status == "closed" then
			input:close()
		end
	end
end
