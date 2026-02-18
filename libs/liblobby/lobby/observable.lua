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
Spring.Echo("Checking for Tracy profiler build:", tracy, tracy.stub, devmode)

local functionaddresscache = {} -- This tables keys are listener functions, mapped to source lines

-- Using solution in http://lua-users.org/lists/lua-l/2006-02/msg00537.html
-- Performance: module-level error handler avoids creating a closure per listener per dispatch
local function _errorHandler(err)
	Spring.Log(LOG_SECTION, LOG.ERROR, err)
	Spring.Log(LOG_SECTION, LOG.ERROR, debug.traceback(err))
end

function Lobby:_CallListeners(event, ...)
	if self.listeners[event] == nil then
		return nil -- no event listeners
	end
	local eventListeners = ShallowCopy(self.listeners[event])
	local args = {...}
	local n = select("#", ...)
	if devmode then 
		tracy.ZoneBeginN("Lobby:"..event)
	end
	for i = 1, #eventListeners do
		local listener = eventListeners[i]
		
		if devmode then
			local functionaddress = functionaddresscache[listener]
			if functionaddress == nil then
				local finfo = debug.getinfo(listener)
				local src = finfo.source or "unknown listener"
				local srcsplit = src:split('/')
				src = srcsplit[#srcsplit]
				functionaddress = src .. ":" .. tostring(finfo.linedefined or "0")
				functionaddresscache[listener] = functionaddress
			end
			tracy.ZoneBeginN(functionaddress)
		end
		xpcall(function() listener(listener, unpack(args, 1, n)) end, _errorHandler)
		if devmode then
			tracy.ZoneEnd()
			if tracy and tracy.LuaTracyPlot then
				tracy.LuaTracyPlot("LuaMenuMem", gcinfo() * 1000)
			end
		end
			
	end
	if devmode then
		tracy.ZoneEnd()
		if tracy and tracy.LuaTracyPlot then
			tracy.LuaTracyPlot("LuaMenuMem", gcinfo() * 1000)
		end
	end
	return true
end


function Lobby:_PrintError(err)
	-- FIXME: cleanup more
	Spring.Log(LOG_SECTION, LOG.ERROR, err)
	Spring.Log(LOG_SECTION, LOG.ERROR, debug.traceback(err))
end
