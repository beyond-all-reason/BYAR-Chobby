

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
LIB_LOBBY_DIRNAME = "libs/liblobby/lobby/" -- why is this needed? why doesnt api load first?

VFS.Include(LIB_LOBBY_DIRNAME .. "json.lua")
VFS.Include(LIB_LOBBY_DIRNAME .. "utilities.lua")


function widget:GetInfo()
	return {
		name      = "Analytics Handler",
		desc      = "Handles analytics events for BAR",
		author    = "GoogleFrog, Beherith",
		date      = "20 February 2017",
		license   = "GPL-v2",
		layer     = 0,
		handler   = true,
		enabled   = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Vars

local onetimeEvents = {}
local indexedRepeatEvents = {}

local ANALYTICS_EVENT = "analyticsEvent_"
local ANALYTICS_EVENT_ERROR = "analyticsEventError_"

-- Do not send analytics for dev versions as they will likely be nonsense.
local ACTIVE = true -- not VFS.HasArchive("Zero-K $VERSION")
local VERSION = "events20210625:"

------------------------ Connection ---------------------
-- TODO: 
-- Add machine hash
	-- installation path is a good one?
	-- 	 
local machineHash = "DEADBEEF"

local function MachineHash()
	--Spring.Echo("DEADBEEF", debug.getinfo(1).short_src, debug.getinfo(1).source, VFS.GetFileAbsolutePath("infolog.txt"))
	local hashstr = ""
	if Platform and Platform.gpu then
		hashstr = hashstr .."|".. Platform.gpu
	end
	if Platform and Platform.osFamily then
		hashstr = hashstr .."|" ..Platform.osFamily
	end
	if Platform and Platform.osName then
		hashstr = hashstr .."|" ..Platform.osName
	end
	local hashstr = hashstr .. "|" .. tostring(VFS.GetFileAbsolutePath("infolog.txt") or "")

	local function lines(str)
		local t = {}
		local function helper(line) table.insert(t, line) return "" end
		helper((str:gsub("(.-)\r?\n", helper)))
		return t
  	end
	local cpustr = ''
	local infolog = VFS.LoadFile("infolog.txt")
	if infolog then
		local fileLines = lines(infolog)
		for i, line in ipairs(fileLines) do
			if string.sub(line, 1, 3) == '[F='  then
				break
			end

			if string.find(line:lower(), 'hardware config:') then
				 local s,e = string.find(line:lower(), 'hardware config:')
				cpustr = string.sub(line, e+2)
				break
			end
		end
	end

	hashstr = hashstr .."|" ..cpustr

	machineHash = Spring.Utilities.Base64Encode(VFS.CalculateHash(hashstr,0))

	--Spring.Echo("This machine's analytics hash is:", hashstr, machineHash)
end




local socket = socket
local client
local host = "bar.teifion.co.uk"
local port = 8200

local buffer = ""
local commands = {} -- table with possible commands

local PRINT_DEBUG = false

function SendClientProperty(cmdName, args) -- cannot send table!
	if client == nil then 
		if PRINT_DEBUG then Spring.Echo("Analytics not connected") end
		return
	end
	if args == nil then args = {} end
	args = Spring.Utilities.Base64Encode(Spring.Utilities.json.encode(args))
	local message = "c.telemetry.update_client_property " .. cmdName .. " " ..args.." ".. machineHash .. "\n"
	client:send(message)
	if PRINT_DEBUG then
		Spring.Echo("Analytics SendCommand", message)
	end
end

function SendClientEvent(cmdName, args)
	if client == nil then 
		if PRINT_DEBUG then Spring.Echo("Analytics not connected") end
		return
	end
	if args == nil then args = {} end
	args = Spring.Utilities.Base64Encode(Spring.Utilities.json.encode(args))
	local message = "c.telemetry.log_client_event " .. cmdName .. " " ..args.." ".. machineHash .. "\n"
	client:send(message)
	if PRINT_DEBUG then
		Spring.Echo("Analytics SendCommand", message)
	end
end

function SendBattleEvent(cmdName, args)
	if client == nil then 
		if PRINT_DEBUG then Spring.Echo("Analytics not connected") end
		return
	end
	if args == nil then args = {} end
	args = Spring.Utilities.Base64Encode(Spring.Utilities.json.encode(args))
	local message = "c.telemetry.log_battle_event  " .. cmdName .. " " ..args.." ".. machineHash .. "\n"
	client:send(message)
	if PRINT_DEBUG then
		Spring.Echo("Analytics SendCommand", message)
	end
end

--[[
Spring.Echo( "Json tests")
Spring.Echo( Spring.Utilities.json.encode({}))
Spring.Echo( Spring.Utilities.json.encode(nil))
Spring.Echo( Spring.Utilities.json.encode("1"))
Spring.Echo( Spring.Utilities.json.encode({k=1}))
]]--

local function SocketConnect(host, port)
	client=socket.tcp()
	client:settimeout(0)
	res, err = client:connect(host, port)
	if not res and not res=="timeout" then
		if PRINT_DEBUG then Spring.Echo("Error in connection to Analytics server: "..err) end
		return false
	end
	if PRINT_DEBUG then Spring.Echo("Analytics connected") end
	return true
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

local Analytics = {}

function Analytics.SendOnetimeEvent(eventName, value)
	if PRINT_DEBUG then Spring.Echo("BAR Analytics.SendOnetimeEvent(eventName, value)", eventName, value) end
	--eventName = VERSION .. eventName
	if onetimeEvents[eventName] then
		return
	end
	onetimeEvents[eventName] = true
	if ACTIVE then
		SendClientProperty(eventName, value)
	else
		Spring.Echo("DesignEvent", eventName, value)
	end
end

function Analytics.SendIndexedRepeatEvent(eventName, value, suffix)
	if PRINT_DEBUG then Spring.Echo("BAR Analytics.SendIndexedRepeatEvent(eventName, value)", eventName, value,  suffix) end
	eventName = VERSION .. eventName
	indexedRepeatEvents[eventName] = (indexedRepeatEvents[eventName] or 0) + 1

	eventName = eventName .. "_" .. indexedRepeatEvents[eventName]
	if suffix then
		eventName = eventName .. suffix
	end
	if ACTIVE then
		SendClientEvent(eventName, value)
	else
		Spring.Echo("DesignEvent", eventName, value)
	end
end

function Analytics.SendRepeatEvent(eventName, value)
	if PRINT_DEBUG then Spring.Echo("BAR Analytics.SendIndexedRepeatEvent(eventName, value)", eventName, value) end
	eventName = VERSION .. eventName
	if ACTIVE  then
		SendClientEvent(eventName, value)
	else
		Spring.Echo("DesignEvent", eventName, value)
	end
end

function Analytics.SendErrorEvent(eventName, severity)
	if PRINT_DEBUG then Spring.Echo("BAR Analytics.SendErrorEvent(eventName, value)", eventName, value)  end 
	eventName = VERSION .. eventName
	if onetimeEvents[eventName] then
		return
	end
	severity = severity or "Info"
	if ACTIVE then
		SendClientEvent(eventName, severity)
	else
		Spring.Echo("ErrorEvent", eventName, severity)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utilities

local function HandleAnalytics(msg)
	if string.find(msg, ANALYTICS_EVENT) == 1 then
		msg = string.sub(msg, 16)
		local pipe = string.find(msg, "|")
		if pipe then
			Analytics.SendOnetimeEvent(string.sub(msg, 0, pipe - 1), string.sub(msg, pipe + 1))
		else
			Analytics.SendOnetimeEvent(msg)
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Graphics

local settings = {
	"AllowDeferredMapRendering",
	"AllowDeferredModelRendering",
	"AdvMapShading",
	"AdvUnitShading",
}

local function IsTesselationShaderSupported()
	return gl.HasExtension and gl.HasExtension("GL_ARB_tessellation_shader") and (gl.SetTesselationShaderParameter ~= nil)
end

local function SendGraphicsSettings()
	for i = 1, #settings do
		local value = Spring.GetConfigInt(settings[i], -1)
		Analytics.SendOnetimeEvent("settings:" .. settings[i], value)
	end
end

function widget:ActivateGame()
	-- Give time for the settings that the player will use to be applied properly.
	WG.Delay(SendGraphicsSettings, 30)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Initialize

local function ProcessString(str)
	return string.gsub(string.gsub(str," ","_"),"/","_")
end

function DelayedInitialize()
	local port = 8200
	Spring.Log("Analytics", LOG.NOTICE, "Using wrapper port: ", port)
	MachineHash()
	if ACTIVE then 
		ACTIVE = SocketConnect("bar.teifion.co.uk", port)
	else
		return
	end

	local function OnBattleStartSingleplayer()
		Analytics.SendOnetimeEvent("lobby:singleplayer:game_loading")
		-- Singleplayer events have their own, better, handling.
	end
	local function OnBattleStartMultiplayer(_, battleType)
		Analytics.SendOnetimeEvent("lobby:multiplayer:game_loading")
		Analytics.SendRepeatEvent("game_start:multiplayer:connecting_" .. (battleType or "unknown"))
	end

	WG.LibLobby.localLobby:AddListener("OnBattleAboutToStart", OnBattleStartSingleplayer)
	WG.LibLobby.lobby:AddListener("OnBattleAboutToStart", OnBattleStartMultiplayer)

	Analytics.SendOnetimeEvent("lobby:started")
	if Platform and Platform.glVersionShort and type(Platform.glVersionShort) == "string" then
		Analytics.SendOnetimeEvent("graphics:openglVersion:" .. Platform.glVersionShort)
	else
		Analytics.SendOnetimeEvent("graphics:openglVersion:notFound")
	end

	Analytics.SendOnetimeEvent("graphics:gpu:" .. ProcessString(tostring((Platform and Platform.gpu) or "unknown") or "unknown"))
	Analytics.SendOnetimeEvent("graphics:glRenderer:" .. ProcessString(tostring((Platform and Platform.glRenderer) or "unknown") or "unknown"))
	Analytics.SendOnetimeEvent("graphics:tesselation", ((IsTesselationShaderSupported() and 1) or 0))
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

function widget:RecvLuaMsg(msg)
	if HandleAnalytics(msg) then
		return
	end
end

function widget:Initialize()
	WG.Analytics = Analytics
	WG.Delay(DelayedInitialize, 1)
end

function widget:GetConfigData()
	return {
		onetimeEvents = onetimeEvents,
		indexedRepeatEvents = indexedRepeatEvents,
	}
end

function widget:SetConfigData(data)
	-- Reverse compatibility with onetimeEvents = data
	if data["lobby:started"] then
		onetimeEvents = data or {}
		return
	end
	onetimeEvents = data.onetimeEvents or {}
	indexedRepeatEvents = data.indexedRepeatEvents or {}
end
