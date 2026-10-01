Spring.Utilities = Spring.Utilities or {}

local function EncodeChar(c)
	return string.format("%%%02X", string.byte(c))
end

function Spring.Utilities.EncodeURIComponent(s)
	return string.gsub(s, "[^A-Za-z0-9%-_.!~*'()]", EncodeChar)
end
