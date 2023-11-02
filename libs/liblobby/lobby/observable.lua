Lobby = LCS.class{}

local LOG_SECTION = "liblobby"

function Lobby:AddListener(event, listener)
	if listener == nil then
		Spring.Log(LOG_SECTION, LOG.ERROR, "Event: " .. tostring(event) .. ", listener cannot be nil")
		return
	end
	local eventListeners = self.listeners[event]
	if eventListeners == nil then
		eventListeners = {}
		self.listeners[event] = eventListeners
	end
	table.insert(eventListeners, listener)
end

function Lobby:RemoveListener(event, listener)
	if self.listeners[event] then
		for k, v in pairs(self.listeners[event]) do
			if v == listener then
				table.remove(self.listeners[event], k)
				if #self.listeners[event] == 0 then
					self.listeners[event] = nil
				end
				break
			end
		end
	end
end

--Spring.Echo("supertrace",WG,WG.Chobby,WG.Chobby.Configuration.devMode)
local devmode = tracy and ((VFS.FileExists("devmode.txt") and true) or false)
Spring.Echo("tracy", tracy, tracy.stub, devmode)

local functionaddresscache = {} -- This tables keys are listener functions, mapped to source lines

-- Using solution in http://lua-users.org/lists/lua-l/2006-02/msg00537.html
function Lobby:_CallListeners(event, ...)
	if self.listeners[event] == nil then
		return nil -- no event listeners
	end
	local eventListeners = ShallowCopy(self.listeners[event])
	local args = {...}
	local n = select("#", ...)
	local rameventstart 
	local ramlistenerstart
	if devmode then 
		tracy.ZoneBeginN("Lobby:"..event)
		rameventstart = gcinfo()
	end
	for i = 1, #eventListeners do
		local listener = eventListeners[i]
		
		local functionaddress = "unknown listener"
		if devmode then
			if functionaddresscache[listener] == nil then
				local finfo = debug.getinfo(listener)
				--Spring.Utilities.TableEcho(finfo)
				local src = finfo.source or functionaddress
				local srcsplit = src:split('/')
				src = srcsplit[#srcsplit]		
				local linedefined = finfo.linedefined or "0"
				functionaddress = src .. ":" .. tostring(linedefined)
				--Spring.Echo(src, finfo.source, linedefined, functionaddress)
				functionaddresscache[listener] = functionaddress
			else
				functionaddress = functionaddresscache[listener]
			end


			if functionaddress then 
				ramlistenerstart = gcinfo()
				tracy.ZoneBeginN(functionaddress)
			end
		end
		xpcall(function() listener(listener, unpack(args, 1, n)) end,
			function(err) self:_PrintError(err) end )
		if devmode and functionaddress then 
			tracy.ZoneEnd()
			local ramlistenerend = gcinfo ()
			if ramlistenerend - ramlistenerstart > 0 then
				tracy.Message(tostring(ramlistenerend - ramlistenerstart))
			end
		end
			
	end
	if devmode then
		tracy.ZoneEnd()
		local rameventend = gcinfo()
		if rameventend - rameventstart > 0 then
			tracy.Message(tostring(rameventend - rameventstart))
		end
	end
	return true
end


function Lobby:_PrintError(err)
	-- FIXME: cleanup more
	Spring.Log(LOG_SECTION, LOG.ERROR, err)
	Spring.Log(LOG_SECTION, LOG.ERROR, debug.traceback(err))
end
