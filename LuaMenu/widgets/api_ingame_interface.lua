--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:GetInfo()
	return {
		name      = "Ingame Interface",
		desc      = "Contains the interface between ingame and luaMenu",
		author    = "GoogleFrog",
		date      = "18 November 2016",
		license   = "GPL-v2",
		layer     = -0,
		handler   = true,
		api       = true,
		enabled   = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Externals Functions

local externalFunctions = {}

function externalFunctions.SetLobbyOverlayActive(newActive)
	if Spring.SendLuaUIMsg then
		Spring.SendLuaUIMsg("LobbyOverlayActive" .. ((newActive and "1") or "0"))
	else
		Spring.Echo("Spring.SendLuaUIMsg does not exist in LuaMenu")
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Patterns to match

local TTT_SAY = "textToSpeechSay_"
local TTS_VOLUME = "textToSpeechVolume_"
local REMOVE_BUTTON = "disableLobbyButton"
local ENABLE_OVERLAY = "showLobby"
local LUAMENU_SETTING = "changeSetting "
local OPEN_SETTINGS_TAB = "openSettingsTab "
local LOAD_FILENAME = "loadFilename "
local RESTART_GAME = "restartGame"
local GAME_INIT = "ingameInfoInit"
local GAME_START = "ingameInfoStart"

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utilities

local function StringToDataTable(msg)
	local data = msg:split("_")
	local dataTable = {}
	local index = 3
	while data[index] do
		dataTable[data[index - 1]] = data[index]
		index = index + 2
	end
	return dataTable
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Text To Speech

local function HandleTextToSpeech(msg)
	local Configuration = WG.Chobby.Configuration
	if not Configuration.enableTextToSpeech then
		return false
	end

	if string.find(msg, TTT_SAY) == 1 then
		msg = string.sub(msg, 17)
		local nameEnd = string.find(msg, "%s")
		local name = string.sub(msg, 0, nameEnd)
		msg = string.sub(msg, nameEnd + 1)
		WG.WrapperLoopback.TtsSay(name, msg)
		return true
	end

	if string.find(msg, TTS_VOLUME) == 1 then
		msg = string.sub(msg, 20)
		WG.WrapperLoopback.TtsVolume(tonumber(msg) or 0)
		return true
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Lobby Overlay

local function HandleLobbyOverlay(msg)
	local Chobby = WG.Chobby
	--Spring.Echo("HandleLobbyOverlay", msg)
	local interfaceRoot = Chobby and Chobby.interfaceRoot
	if interfaceRoot then
		if msg == REMOVE_BUTTON then
			interfaceRoot.SetLobbyButtonEnabled(false)
			return true
		elseif msg == ENABLE_OVERLAY then
			Spring.Echo("HandleLobbyOverlay SetMainInterfaceVisibley")
			interfaceRoot.SetMainInterfaceVisible(true)
			return true
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Settings

local function HandleSettingsChange(msg)
	if string.find(msg, LUAMENU_SETTING) ~= 1 then
		return
	end
	local Configuration = WG.Chobby.Configuration
	if Configuration then
		local data = msg:split(" ")
		if data[2] and data[3] then
			Configuration:SetSettingsConfigOption(data[2], tonumber(data[3]) or data[3])
		end
	end
end

local function HandleSettingsOpenTab(msg)
	if string.find(msg, OPEN_SETTINGS_TAB) ~= 1 then
		return
	end
	local data = msg:split(" ")
	if WG.Chobby.interfaceRoot then
		WG.Chobby.interfaceRoot.OpenRightPanelTab("settings")
		WG.Chobby.interfaceRoot.SetMainInterfaceVisible(true)
		if data[2] and WG.SettingsWindow then
			WG.SettingsWindow.OpenTab(data[2])
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Load and Restart

local function HandleLoadGame(msg)
	if string.find(msg, LOAD_FILENAME) ~= 1 then
		return
	end
	local data = msg:split(" ")
	if WG.LoadGame and data and data[2] then
		WG.LoadGame.LoadGameByFilename(data[2])
	end
end

local function HandleRestartGame(msg)
	if string.find(msg, RESTART_GAME) ~= 1 then
		return
	end
	WG.SteamCoopHandler.RestartGame()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Ingame Info

local function MsgToDiscordData(msg)
	local data = msg:split("_")
	if tonumber(data[2]) then
		return {
			isPlayer = (data[2] == "1"),
			playerCount = tonumber(data[3]) or 0,
			teamOnePlayers = tonumber(data[4]) or 0,
			teamTwoPlayers = tonumber(data[5]) or 0,
			teamPlayers = tonumber(data[3]) or 0,
			isFFA = (data[6] == "1"),
			isReplay = (data[7] == "1"),
			isAI = (data[8] == "1"),
			isChicken = (data[9] == "1"),
			isCampaign = (data[10] == "1"),
			planetName = data[11],
		}
	end

	return StringToDataTable(msg)
end

local function HandleGameInfoInit(msg)
	if string.find(msg, GAME_INIT) ~= 1 then
		return
	end
	if WG.DiscordHandler then
		WG.DiscordHandler.SetIngameInfo(MsgToDiscordData(msg))
	end
end

local function HandleGameInfoStart(msg)
	if string.find(msg, GAME_START) ~= 1 then
		return
	end
	if WG.DiscordHandler then
		WG.DiscordHandler.SetIngameInfo(MsgToDiscordData(msg))
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Callins

function widget:RecvLuaMsg(msg)
	if HandleLobbyOverlay(msg) then
		return
	end
	if HandleTextToSpeech(msg) then
		return
	end
	if HandleSettingsChange(msg) then
		return
	end
	if HandleSettingsOpenTab(msg) then
		return
	end
	if HandleLoadGame(msg) then
		return
	end
	if HandleRestartGame(msg) then
		return
	end
	if HandleGameInfoInit(msg) then
		return
	end
	if HandleGameInfoStart(msg) then
		return
	end
end

function widget:ActivateMenu()
	local Chobby = WG.Chobby
	local interfaceRoot = Chobby and Chobby.interfaceRoot

	-- Another game might be started without the ability to display lobby button.
	if interfaceRoot then
		interfaceRoot.SetLobbyButtonEnabled(true)
	end
end

function widget:ActivateGame()
end

function widget:Initialize()
	WG.IngameInterface = externalFunctions
end
