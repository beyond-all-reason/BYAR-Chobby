--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Steam Coop Handler",
		desc      = "Handles direct steam cooperative game connections.",
		author    = "GoogleFrog",
		date      = "25 February 2017",
		license   = "GNU LGPL, v2.1 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Globals

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Variables

local friendsInGame, saneFriendsInGame, friendsInGameSteamID
local alreadyIn = {}
local lastStart = {}
local currentStart = {}

local attemptGameType, attemptScriptTable, startReplayFile, startEngineVersion, DownloadUpdateFunction
local coopClient = false
local friendsReplaceAI = false
local doDelayedConnection = true
local downloadPopup = false

local coopPanel, coopHostPanel, replacablePopup

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utilities

local function LeaveCoopFunc()
	coopClient = false
end

local function LeaveHostCoopFunc()
	friendsInGame = nil
	saneFriendsInGame = nil
	friendsInGameSteamID = nil
	DownloadUpdateFunction = nil
	alreadyIn = {}
end

local function ResetHostData()
	attemptScriptTable = nil
	startReplayFile = nil
	startEngineVersion = nil
	DownloadUpdateFunction = nil
end

local function MakeExclusivePopup(text, buttonText, ClickFunc, buttonClass, height)
	if replacablePopup then
		replacablePopup:Close()
	end
	replacablePopup = WG.Chobby.InformationPopup(text, {caption = buttonText, closeFunc = ClickFunc, buttonClass = buttonClass, height = height, width = 500})
end

local function CloseExclusivePopup()
	if replacablePopup then
		replacablePopup:Close()
		replacablePopup = nil
		downloadPopup = false
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Top Notification

local function InitializeCoopStatusHandler(name, text, leaveFunc, statusAndInvitesPanel)
	local panelHolder = Panel:New {
		name = name,
		x = 8,
		y = 0,
		right = 0,
		bottom = 0,
		classname = "overlay_panel",
		width = pos and pos.width,
		height = pos and pos.height,
		padding = {0,0,0,0},
		caption = "",
		resizable = false,
		draggable = false,
		parent = parent
	}

	local rightBound = "50%"
	local bottomBound = 12
	local bigMode = true

	local statusText = TextBox:New {
		x = 22,
		y = 18,
		right = rightBound,
		bottom = bottomBound,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		objectOverrideHintFont = WG.Chobby.Configuration:GetFont(3),
		text = text,
		parent = panelHolder,
	}

	local button = Button:New {
		name = "leaveCoop",
		x = "70%",
		right = 4,
		y = 4,
		bottom = 4,
		padding = {0,0,0,0},
		caption = i18n("leave"),
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		classname = "negative_button",
		OnClick = {
			function()
				leaveFunc()
				statusAndInvitesPanel.RemoveControl(name)
			end
		},
		parent = panelHolder,
	}

	local function Resize(obj, xSize, ySize)
		statusText._relativeBounds.right = rightBound
		statusText._relativeBounds.bottom = bottomBound
		statusText:UpdateClientArea()
		if ySize < 60 then
			statusText:SetPos(xSize/4 - 52, 2)
			statusText.font.size = WG.Chobby.Configuration:GetFont(2).size
			statusText:Invalidate()
			bigMode = false
		else
			statusText:SetPos(xSize/4 - 62, 18)
			statusText.font.size = WG.Chobby.Configuration:GetFont(3).size
			statusText:Invalidate()
			bigMode = true
		end
	end

	panelHolder.OnResize = {Resize}

	local externalFunctions = {}

	function externalFunctions.GetHolder()
		return panelHolder
	end

	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Downloading

-- outcome example: "105.1.1-1354-g72b2d55 BAR105" -> "engine/105.1.1-1354-g72b2d55 bar"
local function GetEnginePath(engineVersion)
	return ("engine/" .. engineVersion:gsub(" BAR105", " bar")):lower() -- maybe there are more special cases to take in mind here for very old demos or future ones!
end

local function haveEngineVersion(engineVersion)
	local springExecutable = Platform.osFamily == "Windows" and "spring.exe" or "spring"
	return VFS.FileExists(GetEnginePath(engineVersion) .. "//" .. springExecutable)
end

-- outcome example: https://github.com/beyond-all-reason/spring/releases/download/spring_bar_%7BBAR105%7D105.1.1-1354-g72b2d55/spring_bar_.BAR105.105.1.1-1354-g72b2d55_windows-64-minimal-portable.7z
local function GetEngineDownloadUrl(engineVersion)
	local pureVersion = engineVersion:gsub(" BAR105", "")
	local baseUrl = "https://github.com/beyond-all-reason/spring/releases/download/"
	local versionDir = "spring_bar_%7BBAR105%7D" .. pureVersion .. "/"
	local platform64 = Platform.osFamily:lower() .. "-64"
	local fileName = "spring_bar_.BAR105." .. pureVersion .. "_" .. platform64 .. "-minimal-portable.7z"
	return baseUrl .. versionDir .. fileName
end

-- gameList = nil
-- local oneTimeResourceDl = false
local function CheckDownloads(gameName, mapName, DoneFunc, gameList, engineVersion)
	local haveGame = (not gameName) or WG.Package.ArchiveExists(gameName)
	if not haveGame then
		WG.DownloadHandler.MaybeDownloadArchive(gameName, "game", -1)
	end

	local haveMap = (not mapName) or VFS.HasArchive(mapName)
	if not haveMap then
		WG.DownloadHandler.MaybeDownloadArchive(mapName, "map", -1)
	end

	if gameList then
		for i = 1, #gameList do
			if not WG.Package.ArchiveExists(gameList[i]) then
				WG.DownloadHandler.MaybeDownloadArchive(gameList[i], "game", -1)
				haveGame = false
			end
		end
	end

	local haveEngine = not engineVersion or haveEngineVersion(engineVersion)
	if not haveEngine then
		WG.DownloadHandler.MaybeDownloadArchive(engineVersion, "resource", -1,{ -- FB 2023-05-14: Use resource download until engine-download is supported by launcher
			url = GetEngineDownloadUrl(engineVersion),
			destination = GetEnginePath(engineVersion),
			extract = true,
		})
	end

	if haveGame and haveMap and haveEngine then
		return true
	end

	local function Update()
		if ((not gameName) or WG.Package.ArchiveExists(gameName)) and ((not mapName) or VFS.HasArchive(mapName)) and ((not engineVersion) or haveEngineVersion(engineVersion)) then
			if gameList then
				for i = 1, #gameList do
					if not WG.Package.ArchiveExists(gameList[i]) then
						return
					end
				end
			end
			DoneFunc()
			DownloadUpdateFunction = nil
		end
	end

	local function CancelFunc()
		DownloadUpdateFunction = nil
	end
	DownloadUpdateFunction = Update

	local dlString = "Waiting on content:\nCancel and retry if unsuccessful"
	downloading = {
		downloads = {
		},
		progress = {
		},
	}

	if gameList then
		for i = 1, #gameList do
			if not WG.Package.ArchiveExists(gameList[i]) then
				dlString = dlString .. ("\n - " .. gameList[i] .. ": %d%%")
				downloading.progress[#downloading.progress + 1] = 0
				downloading.downloads[gameList[i]] = #downloading.progress
			end
		end
	elseif gameName and (not haveGame) then
		dlString = dlString .. ("\n - " .. gameName .. ": %d%%")
		downloading.progress[#downloading.progress + 1] = 0
		downloading.downloads[gameName] = #downloading.progress
	end

	if not haveMap then
		dlString = dlString .. ("\n - " .. mapName .. ": %d%%")
		downloading.progress[#downloading.progress + 1] = 0
		downloading.downloads[mapName] = #downloading.progress
	end

	if not haveEngine then
		dlString = dlString .. ("\n - " .. engineVersion .. ": %d%%")
		downloading.progress[#downloading.progress + 1] = 0
		downloading.downloads[engineVersion] = #downloading.progress
	end

	downloading.dlString = dlString
	MakeExclusivePopup(string.format(dlString, unpack(downloading.progress)), "Cancel", CancelFunc, "negative_button", (gameList and (180 + (#gameList)*40)))
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- External functions: Wrapper

local SteamCoopHandler = {
	CheckDownloads = CheckDownloads,
}

function SteamCoopHandler.SteamFriendJoinedMe(steamID, userName)
	if not alreadyIn[steamID] then
		friendsInGame = friendsInGame or {}
		saneFriendsInGame = saneFriendsInGame or {}
		friendsInGameSteamID = friendsInGameSteamID or {}

		friendsInGame[#friendsInGame + 1] = userName
		friendsInGameSteamID[#friendsInGameSteamID + 1] = steamID
		alreadyIn[steamID] = true
	end

	WG.Chobby.InformationPopup((userName or "???") .. " has joined your P2P party. Play a coop game by starting any game via the Singleplayer menu.")

	coopClient = false
	local statusAndInvitesPanel = WG.Chobby.interfaceRoot.GetStatusAndInvitesPanel()
	coopHostPanel = coopHostPanel or InitializeCoopStatusHandler("coopHostPanel", "Hosting Coop\nParty", LeaveHostCoopFunc, statusAndInvitesPanel)
	statusAndInvitesPanel.RemoveControl("coopPanel")
	statusAndInvitesPanel.AddControl(coopHostPanel.GetHolder(), 4.5)
end

function SteamCoopHandler.SteamJoinFriend(joinFriendID)
	coopClient = true
	local statusAndInvitesPanel = WG.Chobby.interfaceRoot.GetStatusAndInvitesPanel()
	coopPanel = coopPanel or InitializeCoopStatusHandler("coopPanel", "In Coop Party\nWaiting on Host", LeaveCoopFunc, statusAndInvitesPanel)
	statusAndInvitesPanel.RemoveControl("coopHostPanel")
	statusAndInvitesPanel.AddControl(coopPanel.GetHolder(), 4.5)
end

function SteamCoopHandler.SteamHostGameSuccess(hostPort)
	lastStart.gameType            = currentStart.gameType
	lastStart.gameName            = currentStart.gameName
	lastStart.mapName             = currentStart.mapName
	lastStart.scriptTable         = currentStart.scriptTable
	lastStart.newFriendsReplaceAI = currentStart.newFriendsReplaceAI
	lastStart.newReplayFile       = currentStart.newReplayFile

	CloseExclusivePopup()
	local myName = WG.Chobby.Configuration:GetPlayerName()
	if startReplayFile then
		WG.Analytics.SendRepeatEvent("game_start:singleplayer:coop_host_replay", (saneFriendsInGame and #saneFriendsInGame) or 1)
		WG.Chobby.localLobby:StartReplay(startReplayFile, myName, hostPort)
	elseif attemptScriptTable then
		local planetID = (attemptScriptTable.modoptions or {}).singleplayercampaignbattleid
		if planetID then
			WG.Analytics.SendRepeatEvent("game_start:singleplayer:coop_host_campaign_" .. planetID, (saneFriendsInGame and #saneFriendsInGame) or 1)
		else
			WG.Analytics.SendRepeatEvent("game_start:singleplayer:coop_host_campaign_unknown", (saneFriendsInGame and #saneFriendsInGame) or 1)
		end
		WG.LibLobby.localLobby:StartGameFromLuaScript(gameType, attemptScriptTable, saneFriendsInGame, hostPort)
	else
		WG.Analytics.SendRepeatEvent("game_start:singleplayer:coop_host_other_" .. (attemptGameType or "skirmish"), (saneFriendsInGame and #saneFriendsInGame) or 1)
		WG.LibLobby.localLobby:StartBattle(attemptGameType or "skirmish", myName, saneFriendsInGame, friendsReplaceAI, hostPort)
	end
	ResetHostData()
end

function SteamCoopHandler.SteamHostGameFailed(steamCaused, reason)
	MakeExclusivePopup("Coop connection failed. " .. (reason or "???") .. ". " .. (steamCaused or "???"))
	ResetHostData()
end

function SteamCoopHandler.SteamConnectSpring(hostIP, hostPort, clientPort, myName, scriptPassword, mapName, gameName, engine)
	if not coopClient then
		-- Do not get forced into a coop game if you have left the coop party.
		return
	end

	local connectionDelay = WG.Chobby.Configuration.coopConnectDelay or 0
	local function DownloadsComplete()
		doDelayedConnection = true
		local function Start()
			if doDelayedConnection then
				doDelayedConnection = false
				WG.LibLobby.localLobby:ConnectToBattle(false, hostIP, hostPort, clientPort, scriptPassword, myName, game, map, engine, "coop")
			end
		end
		local function StartAndClose()
			WG.Analytics.SendOnetimeEvent("lobby:steamcoop:starting")
			WG.Analytics.SendRepeatEvent("game_start:singleplayer:coop_connecting", 1)
			CloseExclusivePopup()
			Start()
		end
		MakeExclusivePopup("Starting coop game.", "Cancel", Start)
		if connectionDelay > 0 then
			WG.Delay(StartAndClose, WG.Chobby.Configuration.coopConnectDelay)
		else
			StartAndClose()
		end
	end

	if CheckDownloads(gameName, mapName, DownloadsComplete) then
		DownloadsComplete()
	else
		connectionDelay = 0 -- Downloading resources
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- External functions: Widget <-> Widget

function SteamCoopHandler.AttemptGameStart(gameType, gameName, mapName, scriptTable, newFriendsReplaceAI, newReplayFile, newEngineVersion)
	if coopClient then -- false
		local statusAndInvitesPanel = WG.Chobby.interfaceRoot.GetStatusAndInvitesPanel()
		if statusAndInvitesPanel and statusAndInvitesPanel.GetChildByName("coopPanel") then
			WG.Chobby.InformationPopup("Only the host of the coop party can launch games.")
			return
		end
		Spring.Echo("LUA_ERRRUN", "coopClient set without visible coop panel.")
	end

	currentStart.gameType            = gameType
	currentStart.gameName            = gameName
	currentStart.mapName             = mapName
	currentStart.scriptTable         = scriptTable
	currentStart.newFriendsReplaceAI = newFriendsReplaceAI
	currentStart.newReplayFile       = newReplayFile
	currentStart.newEngineVersion    = newEngineVersion

	local function DownloadsComplete()
		attemptGameType = gameType
		attemptScriptTable = scriptTable
		friendsReplaceAI = newFriendsReplaceAI
		startReplayFile = newReplayFile
		startEngineVersion = newEngineVersion

		CloseExclusivePopup()

		local Configuration = WG.Chobby.Configuration
		local myName = Configuration:GetPlayerName()

		if startEngineVersion or (not friendsInGame) then
			if friendsInGame then
				-- Off-engine replays with friends are not yet supported.
				MakeExclusivePopup("Coop with old engine versions is not yet supported.")
				return
			end
			lastStart.gameType            = currentStart.gameType
			lastStart.gameName            = currentStart.gameName
			lastStart.mapName             = currentStart.mapName
			lastStart.scriptTable         = currentStart.scriptTable
			lastStart.newFriendsReplaceAI = currentStart.newFriendsReplaceAI
			lastStart.newReplayFile       = currentStart.newReplayFile
			lastStart.newEngineVersion    = currentStart.newEngineVersion

			if startEngineVersion then
				-- Only replay so far.
				if not WG.WrapperLoopback then
					MakeExclusivePopup("Wrapper is required to watch replays with old engine versions.")
					return
				end
				local engine = string.gsub(startEngineVersion, "BAR105", "bar") -- because this is the path we use
				local params = {
					StartDemoName = startReplayFile, -- dont remove the 'demos/' string from it now
					Engine = engine,
					SpringSettings = WG.SettingsWindow.GetSettingsString(),
				}
				if WG.Chobby and WG.Chobby.InformationPopup then
					WG.Chobby.InformationPopup("The replay uses a different engine, so it will be opened in a new window.")
					Spring.SetConfigInt("Fullscreen", 1, false)
					Spring.SetConfigInt("Fullscreen", 0, false)
				end
				WG.WrapperLoopback.StartNewSpring(params)
				Spring.PauseSoundStream()
				return
			end

			if startReplayFile then
				WG.Analytics.SendRepeatEvent("game_start:singleplayer:lone_replay", {
					replayfilename = startReplayFile
				})
				WG.Chobby.localLobby:StartReplay(startReplayFile, myName)
			elseif scriptTable then
				local planetID = (scriptTable.modoptions or {}).singleplayercampaignbattleid
				if planetID then
					WG.Analytics.SendRepeatEvent("game_start:singleplayer:lone_campaign_" .. planetID, 1)
				else
					WG.Analytics.SendRepeatEvent("game_start:singleplayer:lone_campaign_unknown", 1)
				end
				WG.LibLobby.localLobby:StartGameFromLuaScript(gameType, scriptTable)
			else
				WG.Analytics.SendRepeatEvent("game_start:singleplayer:lone_other_" .. (gameType or "skirmish"), {map = lastStart.mapName})
				WG.LibLobby.localLobby:StartBattle(gameType, myName)
			end
			return
		end

		local usedNames = {
			[myName] = true,
		}

		MakeExclusivePopup("Starting game.")

		local appendName = ""
		if startReplayFile then
			appendName = "(spec)"
		end
		WG.Analytics.SendOnetimeEvent("lobby:steamcoop:attemptgamestart")
		local players = {}
		for i = 1, #friendsInGame do
			saneFriendsInGame[i] = Configuration:SanitizeName(friendsInGame[i], usedNames) .. appendName
			players[#players + 1] = {
				SteamID = friendsInGameSteamID[i],
				Name = saneFriendsInGame[i],
				ScriptPassword = "12345",
			}
		end

		local args = {
			Players = players,
			Map = mapName,
			Game = gameName,
			Engine = Spring.Utilities.GetEngineVersion()
		}

		WG.WrapperLoopback.SteamHostGameRequest(args)
	end

	if CheckDownloads(gameName, mapName, DownloadsComplete, _, newEngineVersion) then
		DownloadsComplete()
	end
end

function SteamCoopHandler.RestartGame()
	if lastStart.gameType and not coopClient then
		SteamCoopHandler.AttemptGameStart(lastStart.gameType, lastStart.gameName, lastStart.mapName, lastStart.scriptTable, lastStart.newFriendsReplaceAI, lastStart.newReplayFile)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface
function DelayedInitialize()
	local function downloadFinished(_, name)
		if DownloadUpdateFunction then
			DownloadUpdateFunction()

			local index = downloading and downloading.downloads[name]
			if not index then
				return
			end
			downloading.progress[index] = 100
			replacablePopup:SetText(string.format(downloading.dlString, unpack(downloading.progress)))
		end
	end
	WG.DownloadHandler.AddListener("DownloadFinished", downloadFinished)

	local function DownloadProgress(_, _, sizeCurrent, sizeTotal, name)
		local index = downloading and downloading.downloads[name]
		if not index then
			return
		end
		downloading.progress[index] = ((sizeCurrent < sizeTotal*2) and math.ceil(100*sizeCurrent/sizeTotal)) or 100
		replacablePopup:SetText(string.format(downloading.dlString, unpack(downloading.progress)))
	end

	WG.DownloadHandler.AddListener("DownloadProgress", DownloadProgress)
end

function widget:ActivateMenu()
	lastStart.gameType = nil
end

function widget:Initialize()
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)
	WG.SteamCoopHandler = SteamCoopHandler
	WG.Delay(DelayedInitialize, 0.2)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
