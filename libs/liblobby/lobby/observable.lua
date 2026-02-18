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
	-- Invalidate cached listener copy for this event
	if self._listenerCache then
		self._listenerCache[event] = nil
	end
end

function Lobby:RemoveListener(event, listener)
	if self.listeners[event] then
		for k, v in pairs(self.listeners[event]) do
			if v == listener then
				table.remove(self.listeners[event], k)
				if #self.listeners[event] == 0 then
					self.listeners[event] = nil
				end
				-- Invalidate cached listener copy for this event
				if self._listenerCache then
					self._listenerCache[event] = nil
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

-- Reusable dispatch slots for _CallListeners.
-- Each recursion depth gets its own slot to avoid clobbering.
-- Eliminates per-call closure creation and vararg table packing.
local _callDepth = 0
local _dispatchSlots = {}

local function _makeSlot()
	local slot = { args = {}, n = 0 }
	slot.fn = function()
		slot.listener(slot.listener, unpack(slot.args, 1, slot.n))
	end
	return slot
end

function Lobby:_CallListeners(event, ...)
	if self.listeners[event] == nil then
		return nil -- no event listeners
	end

	-- Use cached listener copy when available (invalidated by AddListener/RemoveListener)
	local lc = self._listenerCache
	if not lc then
		lc = {}
		self._listenerCache = lc
	end
	local eventListeners = lc[event]
	if not eventListeners then
		eventListeners = ShallowCopy(self.listeners[event])
		lc[event] = eventListeners
	end

	-- Get reusable dispatch slot for current recursion depth
	_callDepth = _callDepth + 1
	local depth = _callDepth
	local slot = _dispatchSlots[depth]
	if not slot then
		slot = _makeSlot()
		_dispatchSlots[depth] = slot
	end

	-- Pack args into reusable table (avoids {…} allocation)
	local args = slot.args
	local n = select("#", ...)
	for i = 1, n do
		args[i] = select(i, ...)
	end
	slot.n = n

	if devmode then
		tracy.ZoneBeginN("Lobby:"..event)
	end
	for i = 1, #eventListeners do
		slot.listener = eventListeners[i]

		if devmode then
			local functionaddress = functionaddresscache[slot.listener]
			if functionaddress == nil then
				local finfo = debug.getinfo(slot.listener)
				local src = finfo.source or "unknown listener"
				local srcsplit = src:split('/')
				src = srcsplit[#srcsplit]
				functionaddress = src .. ":" .. tostring(finfo.linedefined or "0")
				functionaddresscache[slot.listener] = functionaddress
			end
			tracy.ZoneBeginN(functionaddress)
		end
		xpcall(slot.fn, _errorHandler)
		if devmode then
			tracy.ZoneEnd()
			if tracy and tracy.LuaTracyPlot then
				tracy.LuaTracyPlot("LuaMenuMem", gcinfo() * 1000)
			end
		end

	end

	-- Clear references to avoid preventing GC
	slot.listener = nil
	for i = 1, n do
		args[i] = nil
	end

	if devmode then
		tracy.ZoneEnd()
		if tracy and tracy.LuaTracyPlot then
			tracy.LuaTracyPlot("LuaMenuMem", gcinfo() * 1000)
		end
	end

	_callDepth = _callDepth - 1
	return true
end


function Lobby:_PrintError(err)
	-- FIXME: cleanup more
	Spring.Log(LOG_SECTION, LOG.ERROR, err)
	Spring.Log(LOG_SECTION, LOG.ERROR, debug.traceback(err))
end
