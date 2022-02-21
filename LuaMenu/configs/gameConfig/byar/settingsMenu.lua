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

local settingsDefault = {}

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