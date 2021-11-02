

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
local ACTIVE = true -- means that we either have an unauthed or an authed connection to server.
						-- Temporarily for server2.beyondallreason.info

local lobby = nil
local isConnected = false
local PRINT_DEBUG = false
------------------------ Connection ---------------------

local machineHash = "DEADBEEF"
local cpuinfo = ""
local gpuinfo = ""
local osinfo = ""
local raminfo = ""

local function lines(str)
	local t = {}
	local function helper(line) table.insert(t, line) return "" end
	helper((str:gsub("(.-)\r?\n", helper)))
	return t
end

local function MachineHash()
	--Spring.Echo("DEADBEEF", debug.getinfo(1).short_src, debug.getinfo(1).source, VFS.GetFileAbsolutePath("infolog.txt"))
	local hashstr = ""
	if Platform and Platform.gpu then
		hashstr = hashstr .."|".. Platform.gpu
		gpuinfo = Platform.gpu
	end
	if Platform and Platform.osFamily then
		hashstr = hashstr .."|" ..Platform.osFamily
		osinfo = Platform.osFamily
	end
	if Platform and Platform.osName then
		hashstr = hashstr .."|" ..Platform.osName
		osinfo = osinfo .. ":" .. Platform.osName

	end
	local hashstr = hashstr .. "|" .. tostring(VFS.GetFileAbsolutePath("infolog.txt") or "")

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
				s,e = string.find(cpustr, ";", nil,true)
				cpuinfo = string.sub(cpustr, 1, s-1)
				rs,re = string.find(cpustr, ",", nil,true)
				raminfo = string.sub(cpustr, s+2, rs -1)

				break
			end
		end
	end
	hashstr = hashstr .."|" ..cpustr
	
	-- e.g. :hashstr = |NVIDIA GeForce RTX 2060/PCIe/SSE2|Windows|Windows 7|N:\Beyond_all_reason\Beyond-All-Reason\data\infolog.txt|Intel(R) Core(TM) i7-2600K CPU @ 3.40GHz; 32751MB RAM, 65500MB pagefile, clhUckpDMG5BZFdVbUNIOFE3K2tXUT09

	machineHash = Spring.Utilities.Base64Encode(VFS.CalculateHash(hashstr,0))

	if PRINT_DEBUG then Spring.Echo("This machine's analytics hash is:", hashstr, machineHash) end
end


local socket = socket
local client
local host = "bar.teifion.co.uk"
local port = 8200

local buffer = ""
local commands = {} -- table with possible commands
local infologDirectory = "log/"

function SendBARAnalytics(cmdName,args,isEvent)
	if PRINT_DEBUG then Spring.Log("Chobby", LOG.WARNING, "Analytics Event", cmdName, args, isEvent, client, "C/A",isConnected, ACTIVE) end

	if client == nil then
		return
	end
	-- events are always tables, properties always just string
	local message
	local istest = ""
	if PRINT_DEBUG then istest = "_test" end
	if isEvent then
		if type(args) ~= "table" then args = {value = args or 0} end
		args = Spring.Utilities.json.encode(args)
		args = Spring.Utilities.Base64Encode(args)		
		message = "c.telemetry.log_client_event".. istest .. " " .. cmdName .. " " ..args.." ".. machineHash .. "\n"
	else
		args = Spring.Utilities.Base64Encode(tostring(args or "nil"))
		message = "c.telemetry.update_client_property".. istest .." " .. cmdName .. " " ..args.." ".. machineHash .. "\n"
	end
	if PRINT_DEBUG then Spring.Log("Chobby", LOG.WARNING, "Message:",message) end
	if isConnected then
		lobby:_SendCommand(message)
	else
		if ACTIVE then
			client:send(message)
		end
	end

end



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


function Analytics.SendCrashReportOneTimeEvent(filename, errortype, errorkey, compressedlog)
	if PRINT_DEBUG then Spring.Log("Chobby", LOG.WARNING, "BAR Analytics.SendCrashReportOneTimeEvent(filename, errortype, errorkey, compressedlog)", filename, errortype, errorkey) end
	if onetimeEvents["reportedcrashes"][filename] then
		return
	end
	onetimeEvents["reportedcrashes"][filename] = true
	
	SendBARAnalytics(errortype, {shorterror = errorkey, fullinfolog = compressedlog, }, true)
end


function Analytics.SendOnetimeEvent(eventName, value)
	if PRINT_DEBUG then Spring.Echo("BAR Analytics.SendOnetimeEvent(eventName, value)", eventName, value) end
	if onetimeEvents[eventName] then
		return
	end
	onetimeEvents[eventName] = true
	
	SendBARAnalytics(eventName, value, false)
end

function Analytics.SendIndexedRepeatEvent(eventName, value, suffix)
	if PRINT_DEBUG then Spring.Echo("BAR Analytics.SendIndexedRepeatEvent(eventName, value)", eventName, value,  suffix) end
	indexedRepeatEvents[eventName] = (indexedRepeatEvents[eventName] or 0) + 1
	eventName = eventName .. "_" .. indexedRepeatEvents[eventName]

	SendBARAnalytics(eventName, value, true)
end

function Analytics.SendRepeatEvent(eventName, value)
	if PRINT_DEBUG then Spring.Echo("BAR Analytics.SendIndexedRepeatEvent(eventName, value)", eventName, value) end

	SendBARAnalytics(eventName, value, true)
end

function Analytics.SendErrorEvent(eventName, severity)
	SendBARAnalytics("login:error", eventName, true)
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


local function ParseInfolog(infologpath)
	local infolog = VFS.LoadFile(infologpath)
	
	if PRINT_DEBUG then Spring.Echo("BAR Analytics: ParseInfolog()", infologpath) end 
	if infolog then
		local fileLines = lines(infolog)
		for i, line in ipairs(fileLines) do
			-- look for game or chobby version mismatch, if $VERSION then return
			if string.find(line,"Chobby $VERSION\"", nil, true) then -- BYAR-Chobby or Chobby is dev mode, so dont report
				if not PRINT_DEBUG then return nil end
			end
			if string.find(line, "Beyond All Reason $VERSION", nil, true) then -- Game is test version, no reporting
				if not PRINT_DEBUG then return nil end
			end

			if string.find(line, "Error: [LuaRules::RunCallInTraceback] ", nil, true) then -- exact match
				--[t=00:00:37.141179][f=-000001] Error: [LuaRules::RunCallInTraceback] error=2 (LUA_ERRRUN) callin=ViewResize trace=[Internal Lua error: Call failure] [string "LuaRules/Gadgets/dbg_gadget_profiler.lua"]:514: attempt to perform arithmetic on local 'viewWidth' (a table value)
				-- yes we got an error here, then we should use this as error key
				-- "LuaRules/Gadgets/dbg_gadget_profiler.lua"]:514: attempt to perform arithmetic on local 'viewWidth' (a table value)
				--local errorkeystart = string.find(line,"[string ",nil, true ) or 1
				--local errorname = string.sub(line, errorkeystart, nil)
				return "LuaRules",line, infolog
			end

			
			if string.find(line, "Error: [LuaMenu::RunCallInTraceback] ", nil, true) then -- exact match
				--Error: [LuaMenu::RunCallInTraceback] error=4 (LUA_ERRMEM) callin=MousePress trace=[Internal Lua error: Call failure] not enough memory
				--local errorkeystart = string.find(line,"[string ",nil, true ) or 1
				--local errorname = string.sub(line, errorkeystart, nil)
				return "LuaMenu",line, infolog
			end

			if string.find(line, "] Sync error for ", nil, true) and string.find(line,", correct is ", nil, true) then -- exact match
				-- [t=00:57:33.506372][f=0065713] Sync error for [DE]resopmok in frame 65708 (got 3658c9d5, correct is cb2dd8d7)
				--local errorkeystart = string.find(line,"Sync error for ",nil, true ) or 1
				--local errorname = string.sub(line, errorkeystart, nil)
				return "SyncError", line, infolog
			end
			
			if string.find(line, "] Error: Spring ", nil, true) and string.find(line," has crashed.", nil, true) then -- exact match
				-- [t=00:35:40.093162][f=0000524] Error: Spring 105.1.1-475-gd112b9e BAR105 has crashed. -- this is the actual crash line

				-- look for the first frame of the stack trace, and get the address
				stackframe = "spring.exe [0xDEADBEEF]"
				for k=i, #fileLines do
					if string.find(fileLines[k], "[ProgCtr=", nil, true) then
						--stackframe = string.sub(fileLines[k+1], string.find(fileLines[k+1],"engine", nil, true) + 6,nil)
						stackframe = fileLines[k+1]
						break
					end
				end
				
				return "EngineCrash", stackframe, infolog
			end

		end
	else
		Spring.Echo("Failed to open:", infologpath)
	end
	return nil -- nil if nothing bad happened
end



local function GetInfologs()
	if onetimeEvents["reportedcrashes"] == nil then
		onetimeEvents["reportedcrashes"] = {}
	end

	filenames = VFS.DirList(infologDirectory) -- ipairs
	table.sort(filenames, function (a,b) return a > b end) -- reverse dir sort, we only need the most recent 5

	if PRINT_DEBUG then Spring.Echo("BAR Analytics: GetInfologs()", #filenames) end 
	for i=1, math.min(#filenames, 5) do 
		filename = filenames[i]
		if onetimeEvents["reportedcrashes"][filename] ~= nil then -- we already reported this one
			Spring.Echo("Already processed an error in ", filename)
		else
			local errortype, errorkey, fullinfolog = ParseInfolog(filename)
			if errortype ~= nil then 
				
				if PRINT_DEBUG then Spring.Echo("BAR Analytics: GetInfologs() found an error:", filename, errortype, errorkey) end 
				if WG.Chobby.ConfirmationPopup then 
					local function reportinfolog()
						local compressedlog = Spring.Utilities.Base64Encode(VFS.ZlibCompress(fullinfolog))
						--Spring.Echo("Uncompressed length:", string.len(fullinfolog), "Compressed base64 length:", string.len(compressedlog))
						Analytics.SendCrashReportOneTimeEvent(filename,"errorReport:"..errortype, errorkey, compressedlog)
					end

					local function dontreportinfolog()
						Analytics.SendCrashReportOneTimeEvent(filename,"errorReport:"..errortype, errorkey, "UserDenied")
					end

					WG.Chobby.ConfirmationPopup(reportinfolog, "BAR has detected a ["..errortype.."] error during one of your previous games in:\n    " .. filename .. "\nSuch infologs help us fix any bugs you may have encountered. This file contains information such as your username, your system configuration and the path the game was installed to. This data will not be made public. Feel free to reject if you dont want to share this information.\nDo you agree to upload this infolog?", nil, 550, 400, "Yes", "No", dontreportinfolog, nil)
				end
				return
			end
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

local function LateHWInfo()
	if osinfo ~= "" then Analytics.SendOnetimeEvent("hardware:osinfo",osinfo) end
	if cpuinfo ~= "" then Analytics.SendOnetimeEvent("hardware:cpuinfo",cpuinfo) end
	if gpuinfo ~= "" then Analytics.SendOnetimeEvent("hardware:gpuinfo",gpuinfo) end
	if raminfo ~= "" then Analytics.SendOnetimeEvent("hardware:raminfo",raminfo) end
end

local function LoginHWInfo()
	onetimeEvents['hardware:osinfo'] = nil
	onetimeEvents['hardware:cpuinfo'] = nil
	onetimeEvents['hardware:gpuinfo'] = nil
	onetimeEvents['hardware:raminfo'] = nil
	Spring.Log("Analytics", LOG.NOTICE, "LoginHWInfo", isConnected, ACTIVE, client)
	if osinfo ~= "" then Analytics.SendOnetimeEvent("hardware:osinfo",osinfo) end
	if cpuinfo ~= "" then Analytics.SendOnetimeEvent("hardware:cpuinfo",cpuinfo) end
	if gpuinfo ~= "" then Analytics.SendOnetimeEvent("hardware:gpuinfo",gpuinfo) end
	if raminfo ~= "" then Analytics.SendOnetimeEvent("hardware:raminfo",raminfo) end
end

function DelayedInitialize()
	local port = 8200
	Spring.Log("Analytics", LOG.NOTICE, "Using port: ", port)
	MachineHash()
	if ACTIVE then 
		ACTIVE = SocketConnect("bar.teifion.co.uk", port)
	end
	if not ACTIVE then return end

	local function OnBattleStartSingleplayer()
		Analytics.SendOnetimeEvent("lobby:singleplayer:game_loading")
		-- Singleplayer events have their own, better, handling.
	end
	local function OnBattleStartMultiplayer(_, battleType)
		Analytics.SendOnetimeEvent("lobby:multiplayer:game_loading")
		-- get the name of the server, and the number of human players in it
		local myBattleID = lobby:GetMyBattleID()
		local myBattle = {}
		if myBattleID then
			myBattle = lobby:GetBattle(myBattleID) or {}
		end
		Analytics.SendRepeatEvent("game_start:multiplayer:connecting" , {title = myBattle.title, mapName = myBattle.mapName, users 	= # myBattle.users, battleID = myBattle.battleID})
	end

	WG.LibLobby.localLobby:AddListener("OnBattleAboutToStart", OnBattleStartSingleplayer)
	WG.LibLobby.lobby:AddListener("OnBattleAboutToStart", OnBattleStartMultiplayer)
	WG.LibLobby.lobby:AddListener("OnLoginInfoEnd", LoginHWInfo)

	Analytics.SendOnetimeEvent("lobby:started")
	if Platform and Platform.glVersionShort and type(Platform.glVersionShort) == "string" then
		Analytics.SendOnetimeEvent("graphics:openglVersion", Platform.glVersionShort)
	else
		Analytics.SendOnetimeEvent("graphics:openglVersion","notFound")
	end

	Analytics.SendOnetimeEvent("graphics:gpu", ProcessString(tostring((Platform and Platform.gpu) or "unknown") or "unknown"))
	Analytics.SendOnetimeEvent("graphics:glRenderer", ProcessString(tostring((Platform and Platform.glRenderer) or "unknown") or "unknown"))
	Analytics.SendOnetimeEvent("graphics:tesselation", ((IsTesselationShaderSupported() and 1) or 0))
	WG.Delay(LateHWInfo,15)
	WG.Delay(GetInfologs,17)


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

	local function OnConnected()
		--Spring.Echo("Analytics OnConnected")
		isConnected = true
		if client ~= nil then
			client:close()
		end
		ACTIVE = false
		-- disconnect
	end
	
	local function OnDisconnected()
		--Spring.Echo("Analytics OnDisconnected")
		isConnected = false
		ACTIVE = false
	end

	lobby = WG.LibLobby.lobby
	lobby:AddListener("OnConnect", OnConnected)
	lobby:AddListener("OnDisconnected", OnDisconnected)

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
	if PRINT_DEBUG then onetimeEvents = {} end -- so we also resend everything in debugging mode
	indexedRepeatEvents = data.indexedRepeatEvents or {}
end
