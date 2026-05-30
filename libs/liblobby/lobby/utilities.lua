LOG_SECTION = "liblobby"

function dumpConfig()
	-- dump all luasocket related config settings to console
	for _, conf in ipairs({"TCPAllowConnect", "TCPAllowListen", "UDPAllowConnect", "UDPAllowListen"  }) do
		Spring.Log(LOG_SECTION, LOG.INFO, conf .. " = " .. Spring.GetConfigString(conf, ""))
	end
end

function explode(div,str)
	if div == '' then
		return false
	end

	local pos = 0
	local arrN = 0
	local arr = {}
	local string_find = string.find
	local string_sub = string.sub
	-- for each divider found
	for st, sp in function() return string_find(str, div, pos, true) end do
		 -- Attach chars left of current divider
		arrN = arrN + 1
		arr[arrN] = string_sub(str, pos, st-1)
		-- Jump past current divider
		pos = sp + 1
	end
	-- Attach chars right of last divider
	arrN = arrN + 1
	arr[arrN] = string_sub(str, pos)
	return arr
end

function ShallowCopy(orig)
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

function concat(...)
	local args = {...}
	local argsClean = {}
	for k, v in pairs(args) do
		if v == nil then
			break
		end
		table.insert(argsClean, v)
	end
	return table.concat(argsClean, " ")
end

function parseTags(tags)
	local tags = explode("\t", tags)
	local tagsMap = {}
	for _, tag in pairs(tags) do
		local indx = string.find(tag, "=")
		if indx ~= nil then
			local key = string.sub(tag, 1, indx - 1)
			local value = string.sub(tag, indx + 1)
			tagsMap[key] = value
		end
	end
	return tagsMap
end

function trim6(s)
	return s:match "^()%s*$" and "" or s:match "^%s*(.*%S)"
 end

function ParseMultiCommandMessage(message)
	local trimmedFilteredMatches = {}
	local broken = {}
	for commandPart in message:gmatch "[^\n]+" do
		local trimmed = trim6(commandPart)
		if trimmed:len() > 0 and (trimmed:find "!" or trimmed:find "$") then
			table.insert(trimmedFilteredMatches, trimmed)
		else
			table.insert(broken, trimmed)
		end
	end

	for _, v in ipairs(broken) do
		table.insert(trimmedFilteredMatches, v)
	end

	return trimmedFilteredMatches
end

function getTag(tags, tagName, mandatory)
	local value = tags[tagName]
	if mandatory and value == nil then
		error("Missing mandatory parameter: " .. tostring(tagName))
	end
	return value
end

-- Pre-computed powers of 2 for bit shift operations (avoids repeated exponentiation)
local _pow2 = {}
for _i = 0, 31 do _pow2[_i] = 2 ^ _i end

function rshift(x, by)
  return math.floor(x / (_pow2[by] or 2 ^ by))
end

function lshift(x, by)
  return x * (_pow2[by] or 2 ^ by)
end

function startsWith(targetstring, pattern)
	local patLen = #pattern
	if patLen <= #targetstring and pattern == string.sub(targetstring, 1, patLen) then
		return true, string.sub(targetstring, patLen + 1)
	else
		return false
	end
end
