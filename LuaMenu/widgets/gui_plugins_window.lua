function widget:GetInfo()
	return {
		name      = "Plugins Window",
		author    = "uBdead",
		date      = "Aug 2025",
		license   = "GNU LGPL, v2.1 or later",
		layer     = -100000,
		enabled   = true  --  loaded by default?
	}
end

local PluginsWindow = {}

function PluginsWindow.GetControl()
	pluginsWindow = pluginsWindow or WG.Chobby.PluginsWindow()
	return pluginsWindow.window
end

function widget:Initialize()
	WG.PluginsWindow = PluginsWindow
end