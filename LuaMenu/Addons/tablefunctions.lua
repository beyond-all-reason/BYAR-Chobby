
Spring.Utilities = Spring.Utilities or {}

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
--deep not safe with circular tables! defaults To false
function Spring.Utilities.CopyTable(tableToCopy, deep)
	local copy = {}
	for key, value in pairs(tableToCopy) do
		if (deep and type(value) == "table") then
			copy[key] = Spring.Utilities.CopyTable(value, true)
		else
			copy[key] = value
		end
	end
	return copy
end

function Spring.Utilities.MergeTable(primary, secondary, deep)
	local new = Spring.Utilities.CopyTable(primary, deep)
	for i, v in pairs(secondary) do
		-- key not used in primary, assign it the value at same key in secondary
		if not new[i] then
			if (deep and type(v) == "table") then
				new[i] = Spring.Utilities.CopyTable(v, true)
			else
				new[i] = v
			end
		-- values at key in both primary and secondary are tables, merge those
		elseif type(new[i]) == "table" and type(v) == "table"  then
			new[i] = Spring.Utilities.MergeTable(new[i], v, deep)
		end
	end
	return new
end

function Spring.Utilities.TableEqual(table1, table2)
	if not table1 then
		return not ((table2 and true) or false)
	end
	if not table2 then
		return false
	end
	for key, value in pairs(table1) do
		if table2[key] ~= value then
			return false
		end
	end
	for key, value in pairs(table2) do
		if table1[key] ~= value then
			return false
		end
	end
	return true
end

-- Returns whether the first table is equal to a subset of the second
function Spring.Utilities.TableSubsetEquals(table1, table2)
	if not table1 then
		return true
	end
	if not table2 then
		return false
	end
	for key, value in pairs(table1) do
		if table2[key] ~= value then
			return false
		end
	end
	return true
end

function Spring.Utilities.TableToString(data, key)
	 local dataType = type(data)
	-- Check the type
	if key then
		if type(key) == "number" then
			key = "[" .. key .. "]"
		end
	end
	if dataType == "string" then
		local cleaned = data:gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t"):gsub("\a", "\\a"):gsub("\v", "\\v"):gsub("\"", "\\\"")
		return key .. [[="]] .. cleaned .. [["]]
	elseif dataType == "number" then
		return key .. "=" .. data
	elseif dataType == "boolean" then
		return key .. "=" .. ((data and "true") or "false")
	elseif dataType == "table" then
		local str
		if key then
			str = key ..  "={"
		else
			str = "{"
		end
		for k, v in pairs(data) do
			str = str .. Spring.Utilities.TableToString(v, k) .. ","
		end
		return str .. "}"
	else
		Spring.Echo("TableToString Error: unknown data type", dataType)
	end
	return ""
end

-- need this because SYNCED.tables are merely proxies, not real tables
local function MakeRealTable(proxy)
	local proxyLocal = proxy
	local ret = {}
	for i,v in spairs(proxyLocal) do
		if type(v) == "table" then
			ret[i] = MakeRealTable(v)
		else
			ret[i] = v
		end
	end
	return ret
end

local function TableEcho(data, name, indent, tableChecked)
	name = name or "TableEcho"
	indent = indent or ""
	if (not tableChecked) and type(data) ~= "table" then
		Spring.Echo(indent .. name, data)
		return
	end
	Spring.Echo(indent .. name .. " = {")
	local newIndent = indent .. "    "
	for name, v in pairs(data) do
		local ty = type(v)
		--Spring.Echo("type", ty)
		if ty == "table" then
			TableEcho(v, name, newIndent, true)
		elseif ty == "boolean" then
			Spring.Echo(newIndent .. name .. " = " .. (v and "true" or "false"))
		elseif ty == "string" or ty == "number" then
			if type(name) == "userdata" then
				Spring.Echo(newIndent, name, v)
			else
				Spring.Echo(newIndent .. name .. " = " .. v)
			end
		elseif ty == "userdata" then
			Spring.Echo(newIndent .. "userdata", name, v)
		else
			Spring.Echo(newIndent .. name .. " = ", v)
		end
	end
	Spring.Echo(indent .. "},")
end

function Spring.Utilities.ShallowCopy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in pairs(orig) do
			copy[orig_key] = orig_value
		end
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end

Spring.Utilities.TableEcho = TableEcho

local function TraceFullEcho(maxdepth, maxwidth, maxtableelements, ...)
    -- Call it at any point, and it will give you the name of each function on the stack (up to maxdepth), 
	-- all arguments and first #maxwidth local variables of that function
	-- if any of the values of the locals are tables, then it will try to shallow print + count them up to maxtablelements numbers. 
	-- It will also just print any args after the first 3. (the ... part)
	-- It will also try to print the source file+line of each function
	local tracedebug = false -- to debug itself
	local functionsource = true
	maxdepth = maxdepth or 16
	maxwidth = maxwidth or 10
    maxtableelements = maxtableelements or 6 -- max amount of elements to expand from table type values

    local function dbgt(t, maxtableelements)
        local count = 0
        local res = ''
        for k,v in pairs(t) do
            count = count + 1
            if count < maxtableelements then
				if tracedebug then Spring.Echo(count, k) end 
				if type(k) == "number" and type(v) == "function" then -- try to get function lists?
					if tracedebug then Spring.Echo(k,v, debug.getinfo(v), debug.getinfo(v).name) end  --debug.getinfo(v).short_src)?
                	res = res .. tostring(k) .. ':' .. ((debug.getinfo(v) and debug.getinfo(v).name) or "<function>") ..', '
				else
                	res = res .. tostring(k) .. ':' .. tostring(v) ..', '
				end
            end
        end
        res = '{'..res .. '}[#'..count..']'
        return res
    end

	local myargs = {...}
	infostr = ""
	for i,v in ipairs(myargs) do
		infostr = infostr .. tostring(v) .. "\t"
	end
	if infostr ~= "" then infostr = "Trace:[" .. infostr .. "]\n" end 
	local functionstr = "" -- "Trace:["
	for i = 2, maxdepth do
		local info = debug.getinfo(i)
		if info then
			local funcName = info.name
			if funcName then
				functionstr = functionstr .. tostring(i-1) .. ": " .. tostring(funcName) .. " "
				local arguments = ""
				if funcName ~= "??" then
					if functionsource and info.source then 
						local source = info.source 
						if string.len(source) > 128 then source = "sourcetoolong" end
						functionstr = functionstr .. " @" .. source
					end 
					if functionsource and info.linedefined then 
						functionstr = functionstr .. ":" .. tostring(info.linedefined) 
					end 
					for j = 1, maxwidth do
						local name, value = debug.getlocal(i, j)
						if not name then break end
						if tracedebug then Spring.Echo(i,j, funcName,name) end 
						local sep = ((arguments == "") and "") or  "; "
                        if tostring(name) == 'self'  then
    						arguments = arguments .. sep .. ((name and tostring(name)) or "name?") .. "=" ..
								(((type(value) == "table" and (value.name or value.classname))) or tostring("??"))
                        else
                            local newvalue
                            if maxtableelements > 0 and type(value) == "table" then newvalue = dbgt(value, maxtableelements) else newvalue = value end 
    						arguments = arguments .. sep .. ((name and tostring(name)) or "name?") .. "=" .. tostring(newvalue)
                        end
					end
				end
				functionstr  = functionstr .. " Locals:(" .. arguments .. ")" .. "\n"
			else 
				functionstr = functionstr .. tostring(i-1) .. ": ??\n"
			end
		else break end
	end
	Spring.Echo(infostr .. functionstr)
end

Spring.Utilities.TraceFullEcho = TraceFullEcho


local function TraceEcho(...)
	local myargs = {...}
	infostr = ""
	for i,v in ipairs(myargs) do
		infostr = infostr .. tostring(v) .. "\t"
	end
	if infostr ~= "" then infostr = infostr .. " " end 
	local functionstr = "Trace:["
	for i = 2, 10 do
		if debug.getinfo(i) then
			local funcName = (debug and debug.getinfo(i) and debug.getinfo(i).name)
			if funcName then
				functionstr = functionstr .. tostring(funcName) .. " <- "
			else break end
		else break end
	end
	functionstr = functionstr .. "]"
	local arguments = ""
	local funcName1 = (debug and debug.getinfo(2) and debug.getinfo(2).name) or "??"
	if funcName1 ~= "??" then 
		for i = 1, 10 do
			local name, value = debug.getlocal(2, i)
			if not name then break end
			local sep = ((arguments == "") and "") or  "; "
			arguments = arguments .. sep .. ((name and tostring(name)) or "name?") .. "=" .. tostring(value)
		end
	end
	Spring.Echo(infostr .. functionstr .. " Args:(" .. arguments .. ")")
	return infostr, functionstr, arguments
end

Spring.Utilities.TraceEcho = TraceEcho

local function TraceEchoStr(...)
	local myargs = {...}
	infostr = ""
	for i,v in ipairs(myargs) do
		infostr = infostr .. tostring(v) .. "\t"
	end
	if infostr ~= "" then infostr = infostr .. " " end 
	local functionstr = "Trace:["
	for i = 2, 15 do
		if debug.getinfo(i) then
			local funcName = (debug and debug.getinfo(i) and debug.getinfo(i).name)
			if funcName then
				functionstr = functionstr .. tostring(funcName) .. " <- "
			else 
				--break 
			end
		else 
			break 
		end
	end
	functionstr = functionstr .. "]"
	local arguments = ""
	local funcName1 = (debug and debug.getinfo(2) and debug.getinfo(2).name) or "??"
	if funcName1 ~= "??" then 
		for i = 1, 10 do
			local name, value = debug.getlocal(2, i)
			if not name then break end
			local sep = ((arguments == "") and "") or  "; "
			arguments = arguments .. sep .. ((name and tostring(name)) or "name?") .. "=" .. tostring(value)
		end
	end
	--Spring.Echo(infostr .. functionstr .. " Args:(" .. arguments .. ")")
	return infostr, functionstr, arguments
end

Spring.Utilities.TraceEchoStr = TraceEchoStr

-- Ok some notes on this StartCallHook
-- When you enable StartCallHook, it will hook into every function call and return until you EndCallHook
-- Printing the name of the function and the arguments on the top of the stack. 
-- Goes maxdepth calls deep
-- Prints maxwidth local variables
-- DO NOT NEST THESE
-- EXTREMELY VERBOSE

Spring.Utilities.HookDepth = 0
Spring.Utilities.HookDepthMax = 1000
local function StartCallHook(maxdepth, maxwidth, hidereturns)
	maxdepth = maxdepth or 10
	maxwidth = maxwidth or 10
	Spring.Utilities.HookDepthMax = maxdepth

	local function enterhook(event, line)
		if event == 'call' and Spring and Spring.Utilities then 
			Spring.Utilities.HookDepth = Spring.Utilities.HookDepth + 1
			if Spring and Spring.Utilities and Spring.Utilities.HookDepth and Spring.Utilities.HookDepthMax and debug and debug.getlocal and debug.getinfo and (Spring.Utilities.HookDepth < Spring.Utilities.HookDepthMax) then 
				local locals = ''
				local fname = (debug.getinfo(2, 'n') and debug.getinfo(2, 'n').name) or "???"
				for i = 1, maxwidth do 
					--Spring.Echo(fname,i,locals)
					local name, value = debug.getlocal(2,i)
					--Spring.Echo(name, value )
					if not name then 
						break 
					else
						if name == 'self' then -- as this triggers a c stack overflow on tostring(value)
							locals = locals .. "self, "
						else
							locals = locals .. ((name and tostring(name)) or "name?") .. "=" .. tostring(value) .. ", " 
						end
					end
				end
				local fmt = string.format("+%s %s (%s)", 
						string.rep('>', Spring.Utilities.HookDepth), 
						fname, 
						locals)
				Spring.Echo(fmt)
			end
		elseif event == 'return' then  
			if not hidereturns and Spring.Utilities.HookDepth < Spring.Utilities.HookDepthMax then 
				-- attempt to get name, value of last local (retval)
				local i = 1
				local penultimate = '?'
				local retval = '?'
				while (true) do
					local name, value = debug.getlocal(2,i)
					if name then
						penultimate = retval 
						if name == 'self' then 
							retval = 'self'
						else
							retval = tostring(value)
						end
					else
						break
					end
					i = i + 1
				end

				local fmt = string.format('-%s %s returns( %s or %s )', 
					string.rep('<', Spring.Utilities.HookDepth), 
					(debug.getinfo(2, 'n') and debug.getinfo(2, 'n').name) or "???", penultimate, retval)
				Spring.Echo(fmt)

			end
			Spring.Utilities.HookDepth = math.max(Spring.Utilities.HookDepth -1, 0)
		end
	end
	debug.sethook(enterhook, 'c r')
	return true
end

Spring.Utilities.StartCallHook = StartCallHook

local function EndCallHook()
	debug.sethook()
	Spring.Echo("EndCallHook",Spring.Utilities.HookDepth)
end

Spring.Utilities.EndCallHook = EndCallHook

function Spring.Utilities.CustomKeyToUsefulTable(dataRaw)
	if not dataRaw then
		return
	end
	if not (dataRaw and type(dataRaw) == 'string') then
		if dataRaw then
			Spring.Echo("Customkey data error for team", teamID)
		end
	else
		dataRaw = string.gsub(dataRaw, '_', '=')
		dataRaw = Spring.Utilities.Base64Decode(dataRaw)
		local dataFunc, err = loadstring("return " .. dataRaw)
		if dataFunc then
			local success, usefulTable = pcall(dataFunc)
			if success then
				if collectgarbage then
					collectgarbage("collect")
				end
				return usefulTable
			end
		end
		if err then
			Spring.Echo("Customkey error", err)
		end
	end
	if collectgarbage then
		collectgarbage("collect")
	end
end

-- Because Luas built in table.sort function is by default mergesort, which is always N*logN
-- Insertion sort, however has a best case N, worst case N*N/2
-- Very often, we are dealing with almost sorted tables, in which case insertion sort is 
-- N*K, where K is the number of out-of-order elements. 
function Spring.Utilities.insertionSort(array, a_gt_b, inplace, reverse)
	if a_gt_b == nil then
		a_gt_b = function(a,b) return a>b end
	end
	local comparisons = 0
	local sorted
	if inplace then
		sorted = array
	else
		sorted = {}
		for i, v in ipairs(array) do
			sorted[i] = v
		end
	end

	local len = #sorted
	if len <= 1 then return sorted, 0 end -- single element or less tables are already sorted

	-- validation:
	local biggestkey = 0 
	local numkeys = 0
	local max = math.max
	for k,v in pairs(array) do 
		numkeys = numkeys+1
		biggestkey = max(biggestkey, k)
	end
	if biggestkey ~= numkeys or len ~= numkeys then
		Spring.Echo("Spring.Utilities.insertionSort received an invalid array", len, biggestkey, numkeys)
		Spring.Utilities.TableEcho(array)
		return array, nil
	end


	for j = 2, len do
		local key = sorted[j]
		local i = j - 1
		if reverse then
			while i > 0 and a_gt_b(key, sorted[i])  do
				sorted[i + 1] = sorted[i]
				i = i - 1
			end
		else
			while i > 0 and a_gt_b(sorted[i], key) do
				sorted[i + 1] = sorted[i]
				i = i - 1
			end
		end
		comparisons = comparisons + (j-i)
		sorted[i + 1] = key
	end
	return sorted, comparisons
end