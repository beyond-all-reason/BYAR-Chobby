--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Map Handler API",
		desc      = "Loads maps and provides useful map information.",
		author    = "GoogleFrog",
		date      = "30 June 2016",
		license   = "GNU LGPL, v2.1 or later",
		layer     = -10000,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local MapHandler = {}

function MapHandler.GetMapList()
	return {}
end

function MapHandler.GetMapTeamLimit(mapName, gameName) -- Configs should be able to depend on game.
	return false -- false means unlimited. A number means there is a limit.
end

function MapHandler.ParseMiniMapFinished(mapPath, destinationPath)
	Spring.Echo("Minimap parsed:", mapPath, destinationPath)
end

local MINI_MAPS_DIR = "LuaMenu/Images/Minimaps"

local function ParseAllMinimaps()
	if not WG.WrapperLoopback or not WG.WrapperLoopback.ParseMiniMap then
		return
	end

	if not VFS.FileExists(MINI_MAPS_DIR) then
		Spring.CreateDir(MINI_MAPS_DIR)
	end

	local maps = VFS.GetMaps()
	for _, mapName in ipairs(maps) do
		local archivePath = VFS.GetArchivePath(mapName)
		local mapPath, needsDownload = WG.Chobby.Configuration:GetMinimapImage(mapName)
		if needsDownload then
			WG.WrapperLoopback.ParseMiniMap(archivePath, mapPath, 4)
		end
	end
end

-- Possible TODO
-- MapHandler.GetMapMinimapImage
-- MapHandler.GetMapInfo (dimensions, wind etc...?)

function widget:Initialize()
	WG.MapHandler = MapHandler

	WG.Delay(ParseAllMinimaps, 1)
end
