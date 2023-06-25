--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "WidgetProfiler",
		desc      = "",
		author    = "jK",
		version   = "2.0",
		date      = "2007,2008,2009",
		license   = "GNU GPL, v2 or later",
		layer     = math.huge,
		handler   = true,
		enabled   = false -- loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local callinTimes  = {}

local oldUpdateWidgetCallIn
local oldInsertWidget

local listOfHooks = {}
setmetatable(listOfHooks, { __mode = 'k' })

local inHook = false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local SCRIPT_DIR = Script.GetName() .. '/'

local function IsHook(func)
	return listOfHooks[func]
end

local function Hook(g,name)
	local spGetTimer = Spring.GetTimer
	local spDiffTimers = Spring.DiffTimers
	local widgetName = g._info.name

	local realFunc = g[name]
	g["_old" .. name] = realFunc

	if (widgetName=="WidgetProfiler") then
		return realFunc
	end
	local widgetCallinTime = callinTimes[widgetName] or {}
	callinTimes[widgetName] = widgetCallinTime
	widgetCallinTime[name] = widgetCallinTime[name] or {0,0,0}
	local timeStats = widgetCallinTime[name]

	local t, s

	local helper_func = function(...)
		local dt = spDiffTimers(spGetTimer(),t)
		local ds = collectgarbage("count") - s
		timeStats[1] = timeStats[1] + dt
		timeStats[2] = timeStats[2] + dt
		timeStats[3] = timeStats[3] + ds
		inHook = nil
		return ...
	end

	local hook_func = function(...)
		if (inHook) then
			return realFunc(...)
		end

		inHook = true
		t = spGetTimer()
		s = collectgarbage("count")
		return helper_func(realFunc(...))
	end

	listOfHooks[hook_func] = true

	return hook_func
end

local function ArrayInsert(t, f, g)
	if (f) then
		local layer = g.whInfo.layer
		local index = 1
		for i,v in ipairs(t) do
			if (v == g) then
				return -- already in the table
			end
			if (layer >= v.whInfo.layer) then
				index = i + 1
			end
		end
		table.insert(t, index, g)
	end
end


local function ArrayRemove(t, g)
	for k,v in ipairs(t) do
		if (v == g) then
			table.remove(t, k)
			-- break
		end
	end
end


local function StartHook()
	Spring.Echo("start profiling")

	local wh = widgetHandler

	--// hook all existing callins
	for callin,_ in pairs(wh.knownCallIns) do
		for _,ao in handler.addons:iter() do
			if ao[callin .. "__"] then
				ao[callin .. "old"] =
				wh:RemoveAddonCallIn(callin, ao)
				ao[callin] = Hook(ao,callin)
				wh:UpdateAddonCallIn(callin, ao)
			end
		end
	end

	Spring.Echo("hooked all callins: OK")

	--// hook the UpdateCallin function

	oldUpdateWidgetCallIn =	wh.UpdateWidgetCallIn
	wh.UpdateWidgetCallIn = function(self,name,ao)
		wh:RemoveAddonCallIn(name, ao)
		ao[name] = Hook(ao,name)
		oldUpdateWidgetCallIn(wh, callin, ao)
	end

	-- oldInsertWidget =	wh.InsertWidget
	-- widgetHandler.InsertWidget = function(self,widget)
		-- if (widget == nil) then
			-- return
		-- end

		-- oldInsertWidget(self,widget)

		-- for _,callin in ipairs(CallInsList) do
			-- local func = widget[callin]
			-- if (type(func) == 'function') then
				-- widget[callin] = Hook(widget,callin)
			-- end
		-- end
	-- end

	-- Spring.Echo("hooked UpdateCallin: OK")
end


local function StopHook()
	Spring.Echo("stop profiling")

	local wh = widgetHandler

	--// hook all existing callins
	for callin,_ in pairs(wh.knownCallIns) do
		for _,ao in handler.addons:iter() do
			if (ao["_old" .. callin]) then
				ao[callin] = ao["_old" .. callin]
			end
		end
	end

	Spring.Echo("unhooked all callins: OK")

	--// unhook the UpdateCallin function
	wh.UpdateWidgetCallIn = oldUpdateWidgetCallIn
	--wh.InsertWidget = oldInsertWidget

	Spring.Echo("unhooked UpdateCallin: OK")
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local startTimer

function widget:Update()
	StartHook()
	widgetHandler:RemoveWidgetCallIn("Update", self)
	startTimer = Spring.GetTimer()
end

function widget:Shutdown()
	StopHook()
end

local tick = 0.1
local averageTime = 5
local timeLoadAverages = {}
local spaceLoadAverages = {}

local function CalcLoad(old_load, new_load, t)
	return old_load*math.exp(-tick/t) + new_load*(1 - math.exp(-tick/t))
	--return (old_load-new_load)*math.exp(-tick/t) + new_load
end

local maximum = 0
local totalLoads = {}
local allOverTime = 0
local allOverTimeSec = 0

local sortedList = {}
local function SortFunc(a,b)
	--if (a[2]==b[2]) then
		return a[1]<b[1]
	--else
	--	return a[2]>b[2]
	--end
end

function widget:DrawScreen()
	if not (next(callinTimes)) then
		return --// nothing to do
	end

	local deltaTime = Spring.DiffTimers(Spring.GetTimer(),startTimer)

	if (deltaTime>=tick) then
		startTimer = Spring.GetTimer()

		totalLoads = {}
		maximum = 0
		allOverTime = 0
		local n = 1
		for wname,callins in pairs(callinTimes) do
			local total = 0
			local space = 0
			local cmax = 0
			local cmaxname = ""
			for cname,timeStats in pairs(callins) do
				total = total + timeStats[1]
				space = space + timeStats[3]
				if (timeStats[2]>cmax) then
					cmax = timeStats[2]
					cmaxname = cname
				end
				timeStats[1] = 0
				timeStats[3] = 0
			end

			local relTime = 100 * total / deltaTime
			local relSpace = space / deltaTime
			timeLoadAverages[wname] = CalcLoad(timeLoadAverages[wname] or relTime, relTime, averageTime)
			spaceLoadAverages[wname] = CalcLoad(spaceLoadAverages[wname] or relSpace, relSpace, averageTime)

			allOverTimeSec = allOverTimeSec + total

			local tLoad = timeLoadAverages[wname]
			local sLoad = spaceLoadAverages[wname]
			if (tLoad > 0.01) or (sLoad > 0.01) then
				sortedList[n] = {wname..'('..cmaxname..')',tLoad, sLoad}
				n = n + 1
			end
			allOverTime = allOverTime + tLoad
			if (maximum<tLoad) then maximum=tLoad end
		end

		table.sort(sortedList,SortFunc)
	end

	if (not sortedList[1]) then
		return --// nothing to do
	end

	local vsx, vsy = gl.GetViewSizes()
	local x,y = vsx-300, vsy-40

	for i=1,#sortedList do
		local v = sortedList[i]
		local wname = v[1]
		local tLoad = v[2]
		local sLoad = v[3]
		Spring.Echo(wname, tLoad, sLoad)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
