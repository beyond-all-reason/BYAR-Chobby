-- $Id: savetable.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--	file:    savetable.lua
--	brief:   a human friendly table writer
--	author:  Dave Rodgers
--
--	Copyright (C) 2007.
--	Licensed under the terms of the GNU GPL, v2 or later.
--
--	2 Sept 2008, quantum: added table.show and table.print
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (table.echo) then
	return
end

local indentString = '	'

local savedTables = {}

-- setup a lua keyword map
local keyWords = {
 "and", "break", "do", "else", "elseif", "end", "false", "for", "function",
 "if", "in", "local", "nil", "not", "or", "repeat", "return", "then", "true",
 "until", "while"
}
local keyWordSet = {}
for _,w in ipairs(keyWords) do
	keyWordSet[w] = true
end
keyWords = nil	-- don't need the array anymore


--------------------------------------------------------------------------------

local function encloseStr(s)
	return string.format('%q', s)
end


local function encloseKey(s)
	local wrap = not (string.find(s, '^%a[_%a%d]*$'))
	if (not wrap) then
		if (string.len(s) <= 0) then wrap = true end
	end
	if (not wrap) then
		if (keyWordSet[s]) then wrap = true end
	end
	
	if (wrap) then
		return string.format('[%q]', s)
	else
		return s
	end
end


local keyTypes = {
	['string']	= true,
	['number']	= true,
	['boolean'] = true,
}

local valueTypes = {
	['string']	= true,
	['number']	= true,
	['boolean'] = true,
	['table']	 = true,
}


local function CompareKeys(kv1, kv2)
	local k1, v1 = kv1[1], kv1[2]
	local k2, v2 = kv2[1], kv2[2]

	local ktype1 = type(k1)
	local ktype2 = type(k2)
	if (ktype1 ~= ktype2) then
		return (ktype1 > ktype2)
	end

	local vtype1 = type(v1)
	local vtype2 = type(v2)
	if ((vtype1 == 'table') and (vtype2 ~= 'table')) then
		return false
	end
	if ((vtype1 ~= 'table') and (vtype2 == 'table')) then
		return true
	end

	return (k1 < k2)
end


local function MakeSortedTable(t)
	local st = {}
	for k,v in pairs(t) do
		if (keyTypes[type(k)] and valueTypes[type(v)]) then
			table.insert(st, { k, v })
		end
	end
	table.sort(st, CompareKeys)
	return st
end


local function SaveTable(t, file, indent)
	file:write('{\n')
	local indent = indent .. indentString
	
	local st = MakeSortedTable(t)
	
	for _,kv in ipairs(st) do
		local k, v = kv[1], kv[2]
		local ktype = type(k)
		local vtype = type(v)
		-- output the key
		if (ktype == 'string') then
			file:write(indent..encloseKey(k)..' = ')
		else
			file:write(indent..'['..tostring(k)..'] = ')
		end
		-- output the value
		if (vtype == 'string') then
			file:write(encloseStr(v)..',\n')
		elseif (vtype == 'number') then
			file:write(tostring(v)..',\n')
		elseif (vtype == 'boolean') then
			file:write(tostring(v)..',\n')
		elseif (vtype == 'table') then
			if (savedTables[v]) then
				error("table.save() does not support recursive tables")
			end
			if (next(v)) then
				savedTables[t] = true
				SaveTable(v, file, indent)
				file:write(indent..'},\n')
				savedTables[t] = nil
			else
				file:write('{},\n') -- empty table
			end
		end
	end
end


function ShowTable(t, indent)
	local strings = {}
	strings[#strings+1] = '{\n'
	local indent = indent .. indentString
	
	local st = MakeSortedTable(t)
	
	for _,kv in ipairs(st) do
		local k, v = kv[1], kv[2]
		local ktype = type(k)
		local vtype = type(v)
		-- output the key
		if (ktype == 'string') then
			strings[#strings+1] = (indent..encloseKey(k)..' = ')
		else
			strings[#strings+1] = (indent..'['..tostring(k)..'] = ')
		end
		-- output the value
		if (vtype == 'string') then
			strings[#strings+1] = (encloseStr(v)..',\n')
		elseif (vtype == 'number') then
			strings[#strings+1] = (tostring(v)..',\n')
		elseif (vtype == 'boolean') then
			strings[#strings+1] = (tostring(v)..',\n')
		elseif (vtype == 'table') then
			if (savedTables[v]) then
				error("table.save() does not support recursive tables")
			end
			if (next(v)) then
				savedTables[t] = true
				strings[#strings+1] = ShowTable(v, indent)
				strings[#strings+1] = (indent..'},\n')
				savedTables[t] = nil
			else
				strings[#strings+1] = ('{},\n') -- empty table
			end
		end
	end
	return table.concat(strings)
end


function table.show(t, header)
	local strings = {}
	
	if (header) then
		strings[#strings+1] = (header..'\n')
	end
	
	strings[#strings+1] = 'return '
	strings[#strings+1] = ShowTable(t, '')
	strings[#strings+1] = '}\n'
	for k,v in pairs(savedTables) do
		savedTables[k] = nil
	end
	return table.concat(strings)
end


function table.print(t, header)
	print(table.show(t, header))
end


function table.echo(t, header)
	Spring.Echo(table.show(t, header))
end


function table.save(t, filename, header)
	if (not filename) then
		error("Error while saving.")
		return
	end
	local file, errMsg = io.open(filename, 'w')
	if (not file) then
		error(errMsg .. "\nFile not saved.")
		return
	end
	if (header) then
		file:write(header..'\n')
	end
	file:write('return ')
	SaveTable(t, file, '')
	file:write('}\n')
	file:close()
	for k,v in pairs(savedTables) do
		savedTables[k] = nil
	end
end
