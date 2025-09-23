

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
LIB_LOBBY_DIRNAME = "libs/liblobby/lobby/" -- why is this needed? why doesnt api load first?

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

local lobby = nil
local Configuration
local isConnected = false
local PRINT_DEBUG = false
------------------------ Connection ---------------------

local machineHash = "DEADBEEF"
local cpuinfo = ""
local gpuinfo = ""
local osinfo = ""
local raminfo = ""

local promptWidth = 900
local promptHeight = 450

local function lines(str)
	local t = {}
	local function helper(line) table.insert(t, line) return "" end
	helper((str:gsub("(.-)\r?\n", helper)))
	return t
end

local function trim1(s) -- http://lua-users.org/wiki/StringTrim
   return (s:gsub("^%s*(.-)%s*$", "%1"))
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

	local cpustr = Platform.hwConfig
	local s,e = string.find(cpustr, ";", nil,true)
	local rs,re = string.find(cpustr, ",", nil,true)
	cpuinfo = trim1(string.sub(cpustr, 1, s-1))
	if rs and re then
		raminfo = trim1(string.sub(cpustr, s+2, rs -1))
	else
		raminfo = "unknown"
	end

	hashstr = hashstr .. "|" ..cpustr

	machineHash = Spring.Utilities.Base64Encode(VFS.CalculateHash(hashstr,0))

	if PRINT_DEBUG then Spring.Echo("This machine's analytics hash is:", hashstr, machineHash) end
end


local socket = socket
local client
local host = "server4.beyondallreason.info"
local port = 8200

local buffer = ""
local commands = {} -- table with possible commands
local infologDirectory = "log/"

function SendBARAnalytics(cmdName,args,isEvent)
	if PRINT_DEBUG then Spring.Log("Chobby", LOG.WARNING, "Analytics Event", cmdName, args, isEvent, client, "C/A",isConnected, ACTIVE) end

	if not isConnected and client == nil then
		return
	end
	cmdName = string.gsub(cmdName, " ", "_") -- remove spaces from event names
	-- events are always tables, properties always just string
	local message
	local istest = ""
	if PRINT_DEBUG then istest = "_test" end
	if isEvent then
		if type(args) ~= "table" then args = {value = args or 0} end
		args = Json.encode(args)
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
	if client then
		client:close()
	end
	client=socket.tcp()
	client:settimeout(0)
	res, err = client:connect(host, port)
	if not res and err ~= "timeout" then
		if PRINT_DEBUG then Spring.Echo("Error in connection to Analytics server: "..err) end
		client:close()
		client = nil
		return false
	end
	if PRINT_DEBUG then Spring.Echo("Analytics connected") end
	return true
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

local Analytics = {}

local function jsonEscapeString(s)
	s = string.gsub(s, "\b", "\\b")
	s = string.gsub(s, "\f", "\\f")
	s = string.gsub(s, "\n", "\\n")
	s = string.gsub(s, "\r", "\\r")
	s = string.gsub(s, "\t", "\\t")
	s = string.gsub(s, '"', '\"')
	s = string.gsub(s, "\\", "\\")
	return s
end


function Analytics.SendCrashReportOneTimeEvent(filename, errortype, errorkey, compressedlog, private, versionData)
	if PRINT_DEBUG then
		Spring.Log("Chobby", LOG.WARNING, "BAR Analytics.SendCrashReportOneTimeEvent(filename, errortype, errorkey, compressedlog)", filename, errortype, errorkey, private)
	elseif filename ~= "infolog.txt" then
		-- only save it if we are in debug mode
		-- if name is basename then dont clobber 
		if onetimeEvents["reportedcrashes"][filename] then
			return
		end
		onetimeEvents["reportedcrashes"][filename] = true
	end

	if PRINT_DEBUG then Spring.Log("Chobby", LOG.WARNING, "Analytics Event", cmdName, args, isEvent, client, "C/A",isConnected, ACTIVE) end

	if client == nil then
		return
	end
	-- events are always tables, properties always just string
	local message
	local istest = ""
	local Configuration = WG.Chobby.Configuration
	-- c.telemetry.upload_infolog log_type user_hash base64(json({metadata})) base64(gzip(infologcontents))
	local metadata = {
		errortype = errortype,
		shorterror = jsonEscapeString(errorkey),
		gameversion = versionData.game or Configuration.gameConfig.ShortenNameString(Configuration:GetDefaultGameName()),
		engineversion = versionData.engine or Configuration:GetTruncatedEngineVersion(),
		lobbyversion = versionData.lobby,
		map = versionData.map,
		gameID = versionData.gameID,
		private = private,
		filename = filename,
	}
	metadata = Json.encode(metadata)
	--Spring.Echo(metadata)
	metadata = Spring.Utilities.Base64Encode(metadata)

	local contents = compressedlog
	--https://codebeautify.org/gzip-decompress-online
	--https://www.base64decode.org/

	message = "c.telemetry.upload_infolog " .. errortype .. " " .. machineHash .. " ".. metadata .. " " .. contents

	if PRINT_DEBUG then Spring.Log("Chobby", LOG.WARNING, "Message:",message) end
	if isConnected then
		lobby:_SendCommand(message)
	else
		if ACTIVE then
			client:send(message)
		end
	end

end


function Analytics.SendOnetimeEvent(eventName, value)
	if PRINT_DEBUG then Spring.Echo("BAR Analytics.SendOnetimeEvent(eventName, value)", eventName, value) end

	-- Do not send onetimeEvents when they dont change. This is to prevent spamming the server with the same data.
	if onetimeEvents[eventName] and (onetimeEvents[eventName] == (value or true)) then
		return
	end
	onetimeEvents[eventName] = value or true

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

local function EscapeSlashesAndQuotes(s)
	s = string.gsub(s, "\"", "")
	s = string.gsub(s, "\'", "")
	s = string.gsub(s, "\\", "/")
	return s
end

-- ParseInfolog
-- This function is used to parse the infolog for errors and warnings.
-- returns nil if no upload was needed, otherwise returns the error data and metadata
-- "errorType","errorLine", "infologcontents", "versionData"
local function ParseInfolog(infologpath)
	local infolog = VFS.LoadFile(infologpath)
	local versionData = {} -- we need 5 bits of info in this, game, engine, lobby, map and gameID

	if PRINT_DEBUG then Spring.Echo("BAR Analytics: ParseInfolog()", infologpath) end
	if infolog then
		if string.len(infolog) > 1000000 then
			infolog = string.sub(infolog,1, 1000000)
		end
		local fileLines = lines(infolog)
		local luauierrorcount = 0
		local userhastestversion = false
		for i, line in ipairs(fileLines) do
			-- look for game or chobby version mismatch, if $VERSION then return

			if string.find(line,"Chobby $VERSION\"", nil, true) then -- BYAR-Chobby or Chobby is dev mode, so dont report
				--if not PRINT_DEBUG then return nil end
				userhastestversion = true
			end
			if string.find(line, "Beyond All Reason $VERSION", nil, true) then -- Game is test version, no reporting
				userhastestversion = true
				--if not PRINT_DEBUG then return nil end

			end
			
			-- [t=00:00:15.691792][f=-000001] GameID: 0237a267f0fa57016ea12465d0a5cce3
			if string.find(line,"] GameID: ", nil, true ) then
				versionData.gameID = string.sub(line, string.find(line,"GameID: ", nil, true) + 8, nil)
			end

			--[t=00:00:11.702325][f=-000001] infologVersionTags:engine=105.1.1-2731-g1e10cdc gldebugannotations,game=Beyond All Reason $VERSION,lobby=BYAR Chobby test-2687-f9eec46,map=All That Glitters v2.2
			if string.find(line, "] infologVersionTags:", nil, true) then
				versionData.engine = string.match(line, "engine=([^,]+)")
				versionData.game = string.match(line, "game=([^,]+)")
				versionData.lobby= string.match(line, "lobby=([^,]+)")
				versionData.map = string.match(line, "map=([^,]+)")
			end


			--plain old luaui errors:
			-- [t=00:00:55.609414][f=-000001] Error: gl.CreateList: error(2) = [string "LuaUI/Widgets/gui_options.lua"]:576: attempt to perform arithmetic on field 'value' (a boolean value)
			-- [t=00:46:28.227318][f=0066863] Error in GameFrame(): [string "LuaUI/Widgets/gui_healthbars_gl4.lua"]:1470: attempt to perform arithmetic on local 'newparalyzeDamage' (a nil value)
			-- [f=0003767] Error in DrawScreen(): [string "LuaUI/Widgets_BAR/gui_unit_stats.lua"]:603: attempt to perform arithmetic on local 'maxHP' (a nil value)

			if (luauierrorcount < 3) and
				string.find(line,"] Error", nil, true) and
				string.find(line,"[string \"LuaUI/", nil, true) then
				-- might as well straight up send an analytics event for this
				luauierrorcount = luauierrorcount + 1
				--local errorstart, errorend = string.find(line,"] Error", nil, true)
				local luauiError = EscapeSlashesAndQuotes(line)
				if PRINT_DEBUG then 
					Spring.Echo("Found a luaui error while parsing infolog", infologpath, luauiError)
				end
				Analytics.SendRepeatEvent("lobby:luauierror", {errorcode = luauiError .. " file:" .. infologpath})
			end

			if string.find(line, "Missing I18N for map feature:", nil, true) then
				local luauiError = EscapeSlashesAndQuotes(line)
				if PRINT_DEBUG then
					Spring.Echo("Found a Missing I18N for map feature: while parsing infolog", infologpath, luauiError)
				end
				Analytics.SendRepeatEvent("lobby:luauierror", {errorcode = luauiError .. " file:" .. infologpath})
			end

			if string.find(line, "Error in Interface:_SendCommand while sending", nil, true) and string.find(line, "timeout", nil, true)  then
				local luauiError = EscapeSlashesAndQuotes(line)
				if PRINT_DEBUG then
					Spring.Echo("Failed to send error report", infologpath, luauiError)
				end
				Analytics.SendRepeatEvent("lobby:infologerror", {errorcode = luauiError .. " file:" .. infologpath})
			end

			if string.find(line, "Error: [LuaRules::RunCallInTraceback] ", nil, true) then -- exact match
				--[t=00:00:37.141179][f=-000001] Error: [LuaRules::RunCallInTraceback] error=2 (LUA_ERRRUN) callin=ViewResize trace=[Internal Lua error: Call failure] [string "LuaRules/Gadgets/dbg_gadget_profiler.lua"]:514: attempt to perform arithmetic on local 'viewWidth' (a table value)
				-- yes we got an error here, then we should use this as error key
				-- "LuaRules/Gadgets/dbg_gadget_profiler.lua"]:514: attempt to perform arithmetic on local 'viewWidth' (a table value)
				--local errorkeystart = string.find(line,"[string ",nil, true ) or 1
				--local errorname = string.sub(line, errorkeystart, nil)
				return "LuaRules",line, infolog, versionData
			end

			-- various luamenu errors
			if string.find(line, "Error: [LuaMenu::RunCallInTraceback] ", nil, true) or
				string.find(line, "] [LuaMenu] Error: In", nil) or
				string.find(line,"] [Chili] Error: stacktrace:", nil) or
				string.find(line, '[liblobby] Error: [string "LuaMenu/', nil, true) then -- exact match
				--Error: [LuaMenu::RunCallInTraceback] error=4 (LUA_ERRMEM) callin=MousePress trace=[Internal Lua error: Call failure] not enough memory
				--[liblobby] Error: [string "LuaMenu/Widgets/api_user_handler.lua"]:929:
				return "LuaMenu",line, infolog, versionData
			end

			if string.find(line, "] Sync error for ", nil, true) and string.find(line,", correct is ", nil, true) then -- exact match
				-- [t=00:57:33.506372][f=0065713] Sync error for [DE]resopmok in frame 65708 (got 3658c9d5, correct is cb2dd8d7)
				--local errorkeystart = string.find(line,"Sync error for ",nil, true ) or 1
				--local errorname = string.sub(line, errorkeystart, nil)
				return "SyncError", line, infolog, versionData
			end

			if (string.find(line, "] Error: Spring ", nil, true) and string.find(line," has crashed", nil, true) )
				or string.find(line, "Error handler invoked", nil, true) then -- exact match
				-- [t=00:35:40.093162][f=0000524] Error: Spring 105.1.1-475-gd112b9e BAR105 has crashed. -- this is the actual crash line

				-- look for the first frame of the stack trace, and get the address
				local stackframe = "spring.exe [0xDEADBEEF]"
				for k=i, #fileLines do
					if string.find(fileLines[k], "[ProgCtr=", nil, true) then
						--stackframe = string.sub(fileLines[k+1], string.find(fileLines[k+1],"engine", nil, true) + 6,nil)
						stackframe = fileLines[k+1]
						break
					end
				end

				if string.find(infolog, 'This stacktrace indicates a problem with a skirmish AI', nil , true) then 
					return "AICrash", stackframe, infolog, versionData
				else
					return "EngineCrash", stackframe, infolog, versionData
				end
			end

			if string.find(line, "TraceFullEcho:[", nil, true) then -- exact match
				-- TraceFullEcho:[
				return "LuaUI", line, infolog, versionData
			end

			if (string.find(line, "] Error: [PoolArchive::operator()]", nil, true) and string.find(line," could not read file ", nil, true) )
				or (string.find(line, "] Error: [PoolArchive::GetFileImpl]", nil, true) and string.find(line," failed to read file ", nil, true) ) then
				--[t=00:00:32.274034][f=-000001] Error: [PoolArchive::operator()] could not read file GZIP reason: "C:\Program Files\Beyond-All-Reason\data\\pool\86\bb62a5817c16400370c72fd3adda9e.gz: incorrect data check", SYSTEM reason: "Unknown error" (bytesRead=-1 fileSize=4295404)
				--[t=00:00:48.760963][f=-000001] Error: [PoolArchive::GetFileImpl] failed to read file "C:\Program Files\Beyond-All-Reason\data\\pool\86\bb62a5817c16400370c72fd3adda9e.gz" after 1000 tries
				return "CorruptPool", line, infolog, versionData
			end

			if (string.find(line, "] Warning:", nil, true) and string.find(line," This stacktrace indicates a problem with your graphics card driver, ", nil, true) )
				or (string.find(line, "] Error:", nil, true) and string.find(line," This stacktrace indicates a problem with your graphics card driver, ", nil, true) ) then
				--[t=08:52:35.906100][f=0057171] Warning: This stacktrace indicates a problem with your graphics card driver, please try upgrading it. Specifically recommended is the latest version; do not forget to use a driver removal utility first.
				--[t=01:04:41.755395][f=0025823] Error: This stacktrace indicates a problem with your graphics card driver, please try upgrading it. Specifically recommended is the latest version; do not forget to use a driver removal utility first.
				return "GraphicsDriverProblem", line, infolog, versionData
			end
		end
	else
		Spring.Echo("Failed to open:", infologpath)
	end
	return nil -- nil if nothing bad happened
end

local function ascii(s)
	-- this function is an abomination born from the fact that lua cant gsub the 0x00 ascii character
	local res = {}
	local validchars = 0
	local invalidchars = 0
	for i=1, string.len(s) do
		local sub = string.sub(s,i,i)
		local val = string.byte(sub)
		if (val >= 9) and (val <= 127) then
			validchars = validchars + 1
			res[validchars] = sub
		else
			--print ("invalid character, number is ", val) 
			invalidchars = invalidchars + 1
		end
	end
	return table.concat(res)
end


local function GetDesyncGameStates()
	local filenames = VFS.DirList('.') -- ipairs
	for i=1, #filenames do
		local filename = filenames[i]
		--Spring.Echo("GetDesyncGameStates",filename)
		if string.find(string.lower(filename), "clientgamestate", nil, true) then
			if onetimeEvents["reportedcrashes"][filename] ~= nil then -- we already reported this one
				Spring.Echo("Already processed an error in ", filename)
			else
				Spring.Echo("Found a desync dump", filename )
				local infolog = VFS.LoadFile(filename)
				if infolog == nil then
					Spring.Echo("Failed to load desync dump", filename)
				end
				if string.len(infolog) > 16000000 then 
					infolog = string.sub(infolog,1,16000000)
				end
				local t0 = Spring.GetTimer()
				infolog = ascii(infolog)
				local compressedlog = Spring.Utilities.Base64Encode(VFS.ZlibCompress(infolog))
				local t1 = Spring.GetTimer()
				--local validate = io.open("tempdump.txt",'w')
				--validate:write(compressedlog)
				--validate:close()
				--Spring.Echo("Crash Dump Header is",string.sub(compressedlog, 1, 1000))
				local header = string.sub(infolog, 1, 1000)
				-- Parse the following fields in the lines of the header:
				local versionData = {
					map = string.match(header, "mapName: ([^\n]+)"),
					game = string.match(header, "modName: ([^\n]+)"),
					engine = string.match(header, "syncVer: ([^\n]+)"),
					gameID = string.match(header, "gameID: ([^\n]+)"),
				}

				Analytics.SendCrashReportOneTimeEvent(filename, "SyncError", filename, compressedlog, false, versionData)
				Spring.Echo("Dump done in ", Spring.DiffTimers(Spring.GetTimer(), t1), Spring.DiffTimers(t1,t0))
			end
		end
	end
end


local function GetInfologs()
	--[[
	local testlog = {}
	for i= 100000, 800000, 3 do 
		testlog[#testlog+1] = tostring(i)
	end 
	testlog = table.concat(testlog,',')
	
	local compressedlog = Spring.Utilities.Base64Encode(VFS.ZlibCompress(testlog))
	Spring.Echo("attempting to send test log", #testlog, #compressedlog)
	Analytics.SendCrashReportOneTimeEvent("infolog.txt", "Testupload", "Testupload", compressedlog, true)
	--]]

	if onetimeEvents["reportedcrashes"] == nil then
		onetimeEvents["reportedcrashes"] = {}
	end

	local filenames = VFS.DirList(infologDirectory) -- ipairs
	table.sort(filenames, function (a,b) return a > b end) -- reverse dir sort, we only need the most recent 2

	if PRINT_DEBUG then Spring.Echo("BAR Analytics: GetInfologs()", #filenames) end

	for i=1, math.min(#filenames, 2) do
		local filename = filenames[i]
 		if onetimeEvents["reportedcrashes"][filename] ~= nil then -- we already reported this one
			Spring.Echo("Already processed an error in ", filename)
		else
			local errortype, errorkey, fullinfolog, versionData = ParseInfolog(filename)
			local function ExitSpring()
				Spring.Echo("Quitting...")
				Spring.Quit()
			end
			if errortype == "CorruptPool" then
				local function DeletePoolAndPackages()
					-- Define the pattern to match filename with 30 char + .gz extension and 2 char location path
					local pattern =	"[^\n](%w%w)[\\/](%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w.gz)[^\n]"

					-- Make a table of corrupt pool files from infolog
					local poolpath = "pool/"
					local poolFiles = {}
					local corruptFiles = {}

					for corruptPoolpath, corruptPoolfilename in string.gmatch(fullinfolog, pattern) do
						table.insert(corruptFiles, #corruptFiles + 1, {path = corruptPoolpath, filename = corruptPoolfilename})
					end
					Spring.Echo("Found corrupt files", #corruptFiles)

					for _, corruptFile in ipairs(corruptFiles) do
						local realFiles = VFS.DirList(poolpath .. corruptFile.path .. "/", corruptFile.filename, VFS.RAW)
						for _, file in ipairs(realFiles) do
							table.insert(poolFiles, file)
						end
					end
					Spring.Echo("Verified corrupt files", #poolFiles)

					-- Delete all packages before pool
					local packagespath = "packages/"
					local packagesFiles = VFS.DirList(packagespath, "*.sdp", VFS.RAW)
					if packagesFiles then
						Spring.Echo("Deleting Packages", #packagesFiles)
						for k = 1, #packagesFiles do
							os.remove(packagesFiles[k])
						end
					else
						Spring.Echo("Deleting Packages error")
						poolFiles = nil --If we can't delete packages first we don't delete pool
					end

					if poolFiles and #poolFiles > 0 then
						Spring.Echo("Deleting Pool", #poolFiles)
						for j = 1, #poolFiles do
							os.remove(poolFiles[j])
						end
						table.remove(packagesFiles)
						table.remove(corruptFiles)
						table.remove(poolFiles)
					else
						table.remove(packagesFiles)
						table.remove(corruptFiles)
						Spring.Echo("Deleting Pool error")
						local function YesFunc()
							WG.WrapperLoopback.OpenFolder()
							ExitSpring()
						end
						WG.Chobby.ConfirmationPopup(YesFunc, "There was a problem removing the corrupted data." .. " \n \n" .. "Press the button to open the Game Data folder, delete the folders /Pool/ and /Packages/, and then run the launcher again with updates checked." .. " \n \n" .. "This will close the game and redownload all of the game content.", nil, promptWidth, promptHeight, "Game Data", "Ignore", nil)
						return
					end
					WG.Chobby.ConfirmationPopup(ExitSpring, "Deletion of corrupted data was successful." .. " \n \n" .. "BAR must be exited and the launcher run again with updates checked." .. " \n \n" .. "This will close the game and redownload some game content.", nil, promptWidth, promptHeight, "Exit Now", "Exit Later", nil)
				end
				WG.Chobby.ConfirmationPopup(DeletePoolAndPackages, "Warning: BAR has detected corrupted game content." .. " \n \n" .. errorkey  .. " \n \n" .. "Press Repair to remove the corrupted game content. The game will then need to be exited and the launcher run again with updates checked." .. " \n \n" .. "Ignoring this will lead to crashes or other problems." .. " \n \n" .. "If game corruption continues to occur this may be an indication of hardware failure. Disable any active system overclocks and run a health check on memory and storage.", nil, promptWidth, promptHeight, "Repair", "Ignore", nil)
			elseif errortype == "GraphicsDriverProblem" then
				WG.Chobby.ConfirmationPopup(ExitSpring, "Warning: BAR has detected a problem with your graphics card drivers." .. " \n \n" .. "Graphics driver corruption can be caused by unexpected shutdowns, conflicting software during installation, or hardware problems." .. " \n \n" .. "Exit the game and uninstall your existing graphics drivers. Then install the latest ones from the official website of the chip manufacturer of your GPU (Nvidia, AMD, or Intel). If problems persist then try uninstalling and reinstalling the drivers again using a driver removal utility." .. " \n \n" .. "Ignoring this will lead to crashes or other problems.", nil, promptWidth, promptHeight, "Exit Now", "Ignore", nil)
			elseif errortype ~= nil then

				if PRINT_DEBUG then Spring.Echo("BAR Analytics: GetInfologs() found an error:", filename, errortype, errorkey, versionData) end

				local compressedlog = Spring.Utilities.Base64Encode(VFS.ZlibCompress(fullinfolog))
				if WG.Chobby.Configuration.uploadLogPrompt == "Prompt" then
					if WG.Chobby.ConfirmationPopup then

						local function reportinfolog()
							if WG.Chobby.Configuration.uploadLogPromptDoNotAskAgain then
								WG.Chobby.Configuration:SetConfigValue("uploadLogPrompt", "Always Yes")
							end
							--Spring.Echo("Uncompressed length:", string.len(fullinfolog), "Compressed base64 length:", string.len(compressedlog))
							Spring.Echo("User agreed to upload infolog", filename, "with error", errortype)
							Analytics.SendCrashReportOneTimeEvent(filename, errortype, errorkey, compressedlog, false, versionData)
						end

						local function dontreportinfolog()
							if WG.Chobby.Configuration.uploadLogPromptDoNotAskAgain then
								WG.Chobby.Configuration:SetConfigValue("uploadLogPrompt", "Always No")
							end
							Spring.Echo("User declined to upload infolog", filename, "with error", errortype)
							compressedlog = Spring.Utilities.Base64Encode(VFS.ZlibCompress("private"))
							Analytics.SendCrashReportOneTimeEvent(filename, errortype, errorkey, compressedlog, true, versionData)
						end

						WG.Chobby.ConfirmationPopup(reportinfolog, "BAR has detected a ["..errortype.."] error during one of your previous games in:\n •    " .. filename .. "\n \nSuch infologs help us fix any bugs you may have encountered.\n \nThis file contains information such as your username, your system configuration and the path the game was installed to. This data will not be made public.\n \nDo you agree to upload this infolog?\n \n → You can specify always yes or always no in the Settings tab -> Error log uploading.", "uploadLogPromptDoNotAskAgain", promptWidth, promptHeight, "Yes", "No", dontreportinfolog, nil)
					end
					return
				else
					if WG.Chobby.Configuration.uploadLogPrompt == "Always Yes" then
						Analytics.SendCrashReportOneTimeEvent(filename,errortype, errorkey, compressedlog, false, versionData)
					else
						compressedlog = Spring.Utilities.Base64Encode(VFS.ZlibCompress("private"))
						Analytics.SendCrashReportOneTimeEvent(filename,errortype, errorkey, compressedlog, true, versionData)
					end

				end
			end
		end
	end
end

local function GetErrorLog()
	local infolog = VFS.LoadFile("infolog.txt") or table.concat(VFS.DirList('.') or {},',') or "Unable to find infolog.txt"
	local compressedlog = Spring.Utilities.Base64Encode(VFS.ZlibCompress(infolog))
	--Spring.Echo("GetErrorLog", string.len(infolog),string.len(compressedlog))
	Analytics.SendCrashReportOneTimeEvent("infolog.txt", "Errorlog", "Errorlog", compressedlog, true)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Graphics

local settings_abbr = {
	CamMode = "CamMode",
	DevUI = "DevUI",
	FullS = "Fullscreen",
	HWCursor = "HardwareCursor",
	MSAA = "MSAA",
	MSAAx = "MSAALevel",
	Shadow = "ShadowMapSize",
	IconD = "UnitIconDist",
	VSync = "VSync",
	VSyncG = "VSyncGame",
	Xrez = "XResolution",
	Yrez = "YResolution",
	XrezW = "XResolutionWindowed",
	YrezW = "YResolutionWindowed",
	bLess = "WindowBorderless",
	water = "water",
	--gPreset = "graphicsPreset", -- TODO support strings too
}

local function IsTesselationShaderSupported()
	return gl.HasExtension and gl.HasExtension("GL_ARB_tessellation_shader") and (gl.SetTesselationShaderParameter ~= nil)
end

local function SendGraphicsSettings()
	local settingsTable = {}
	for shortname, settingkey in pairs(settings_abbr) do
		settingsTable[shortname] = Spring.GetConfigInt(settingkey, -9)
	end
	-- Convert it to json:
	local settingsJson = Json.encode(settingsTable)
	-- check if it matches the previously uploaded client property:

	Analytics.SendOnetimeEvent("graphics:settings", settingsJson)
end

function widget:ActivateGame()
	-- Give time for the settings that the player will use to be applied properly.
	WG.Delay(SendGraphicsSettings, 60)
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
	if Platform.sysInfoHash then Analytics.SendOnetimeEvent("hardware:sysInfoHash",string.match(Platform.sysInfoHash, '([0-9a-f]*)') ) end
	if Platform.macAddrHash then Analytics.SendOnetimeEvent("hardware:macAddrHash",Platform.macAddrHash) end
end

local function LobbyInfo()
	if host ~= Configuration.serverAddress then 
		local t = {address = Configuration.serverAddress, me = Configuration.userName , count = 0}
		if  lobby and lobby.users then 
			for username, _ in pairs(lobby.users) do 
				t.count = t.count + 1
				t[t.count] = username
			end
		end
		local message = "c.telemetry.log_client_event lobby:info " .. Spring.Utilities.Base64Encode(Json.encode(t)).." ".. machineHash .. "\n"
		local client=socket.tcp()
		local res, err = client:connect(host, port)
		if not res and err ~= "timeout" then  Spring.Echo("Lobby:Info Error", res, err) else client:send(message) end
		client:close()
	end
end

local function LoginHWInfo()
	onetimeEvents['hardware:osinfo'] = nil
	onetimeEvents['hardware:cpuinfo'] = nil
	onetimeEvents['hardware:gpuinfo'] = nil
	onetimeEvents['hardware:raminfo'] = nil
	onetimeEvents['hardware:sysInfoHash'] = nil
	onetimeEvents['hardware:macAddrHash'] = nil
	LateHWInfo()
	pcall(LobbyInfo)
end

function DelayedInitialize()
	Configuration = WG.Chobby.Configuration
	local port = 8200
	Spring.Log("Analytics", LOG.NOTICE, "Using port: ", port)
	MachineHash()
	if ACTIVE then 
		ACTIVE = SocketConnect(host, port)
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
			if Configuration then 
				Configuration:SetConfigValue("lastStartedBattleID", myBattleID)
			end
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
	WG.Delay(GetDesyncGameStates, 25)
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
	
	local function OnDisconnected(listener, reason, intentional)
		--Spring.Echo("Analytics OnDisconnected")
		Spring.Echo("Disconnected, reason:", reason, intentional)
		isConnected = false
		ACTIVE = false
	end

	lobby = WG.LibLobby.lobby
	lobby:AddListener("OnConnect", OnConnected)
	lobby:AddListener("OnDisconnected", OnDisconnected)
	lobby:AddListener("OnS_Client_Errorlog", GetErrorLog)

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
