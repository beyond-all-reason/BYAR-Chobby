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

	local pos, arr = 0, {}
	-- for each divider found
	for st, sp in function() return string.find(str, div, pos, true) end do
		 -- Attach chars left of current divider
		table.insert(arr, string.sub(str, pos, st-1))
		-- Jump past current divider
		pos = sp + 1
	end
	-- Attach chars right of last divider
	table.insert(arr, string.sub(str,pos))
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

function getTag(tags, tagName, mandatory)
	local value = tags[tagName]
	if mandatory and value == nil then
		error("Missing mandatory parameter: " .. tostring(tagName))
	end
	return value
end

function rshift(x, by)
  return math.floor(x / 2 ^ by)
end

function lshift(x, by)
  return x * 2 ^ by
end
