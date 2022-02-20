local supportedResolutions = {}
local infolog = VFS.LoadFile("infolog.txt")
if infolog then
	function lines(str)
		local t = {}
		local function helper(line) table.insert(t, line) return "" end
		helper((str:gsub("(.-)\r?\n", helper)))
		return t
	end
	local fileLines = lines(infolog)
	local desktop = ''
	for i, line in ipairs(fileLines) do
		if addResolutions then
			local resolution = string.match(line, '[0-9]*x[0-9]*')
			if resolution and string.len(resolution) >= 7 then
				local resolution = string.gsub(resolution, "x", " x ")
				local resolutionX = string.match(resolution, '[0-9]*')
				local resolutionY = string.gsub(string.match(resolution, 'x [0-9]*'), 'x ', '')
				if tonumber(resolutionX) >= 640 and tonumber(resolutionY) >= 480 and resolution ~= desktop then
					supportedResolutions[#supportedResolutions+1] = resolution
				end
			else
				break
			end
		end
		if string.find(line, '	display=') then
			if addResolutions then
				break
			end
			addResolutions = true
			local width = string.sub(string.match(line, 'w=([0-9]*)'), 1)
			local height = string.sub(string.match(line, 'h=([0-9]*)'), 1)
			desktop = width..' x '..height
			supportedResolutions[#supportedResolutions+1] = desktop
		end
	end
end

local resolutionOptions = {}
for i, resolution in ipairs(supportedResolutions) do
	local resolutionX = string.match(resolution, '[0-9]*')
	local resolutionY = string.gsub(string.match(resolution, 'x [0-9]*'), 'x ', '')
	resolutionOptions[#resolutionOptions+1] = {
		name = resolution,
		applyFunction = function()
			if not WG.Chobby then
				return
			end
			Spring.SetConfigInt("Fullscreen", Spring.GetConfigInt("Fullscreen",1) == 1 and 0 or 1)
			Spring.SetConfigInt("XResolution", tonumber(resolutionX))
			Spring.SetConfigInt("YResolution", tonumber(resolutionY))
			Spring.SetConfigInt("XResolutionWindowed", tonumber(resolutionX))
			Spring.SetConfigInt("YResolutionWindowed", tonumber(resolutionY))
			Spring.SetConfigInt("Fullscreen", Spring.GetConfigInt("Fullscreen",1) == 1 and 0 or 1)
			return {}
		end
	}
end

local settingsConfig = {
	{
		name = "Graphics",

		settings = {
			{
				name = "DisplayMode",
				humanName = "Ingame Display Mode",
				displayModeToggle = true,
			},
			{
				name = "LobbyDisplayMode",
				humanName = "Menu Display Mode",
				lobbyDisplayModeToggle = true,
			},
		},
	},
}

local settingsDefault = {
}

local settingsNames = {}
for i = 1, #settingsConfig do
	local subSettings = settingsConfig[i].settings
	for j = 1, #subSettings do
		local data = subSettings[j]
		settingsNames[data.name] = data
		if data.options then
			data.optionNames = {}
			for k = 1, #data.options do
				data.optionNames[data.options[k].name] = data.options[k]
			end
		end
	end
end

return settingsConfig, settingsNames, settingsDefault