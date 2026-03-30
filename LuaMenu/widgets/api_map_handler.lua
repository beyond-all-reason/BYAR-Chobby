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

function MapHandler.ParseMetalMapFinished(mapPath, destinationPath)
	Spring.Echo("Metal map parsed:", mapPath, destinationPath)
end

function MapHandler.ParseHeightMapFinished(mapPath, destinationPath)
	Spring.Echo("Height map parsed:", mapPath, destinationPath)
end

local MINI_MAPS_DIR = "LuaMenu/Images/Minimaps"
local METAL_MAPS_DIR = "LuaMenu/Images/MetalMaps"
local HEIGHT_MAPS_DIR = "LuaMenu/Images/HeightMaps"

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

function MapHandler.RequestMetalMap(mapName)
	if not WG.WrapperLoopback or not WG.WrapperLoopback.ParseMetalMap then
		return
	end
	if not VFS.FileExists(METAL_MAPS_DIR) then
		Spring.CreateDir(METAL_MAPS_DIR)
	end
	local existing = WG.Chobby.Configuration:GetMetalMapImage(mapName)
	if existing then
		return
	end
	local archivePath = VFS.GetArchivePath(mapName)
	if archivePath then
		local safeName = string.gsub(mapName, " ", "_")
		local destination = METAL_MAPS_DIR .. "/" .. safeName .. ".jpg"
		WG.WrapperLoopback.ParseMetalMap(archivePath, destination, 4)
	end
end

function MapHandler.RequestHeightMap(mapName)
	if not WG.WrapperLoopback or not WG.WrapperLoopback.ParseHeightMap then
		return
	end
	if not VFS.FileExists(HEIGHT_MAPS_DIR) then
		Spring.CreateDir(HEIGHT_MAPS_DIR)
	end
	local existing = WG.Chobby.Configuration:GetHeightMapImage(mapName)
	if existing then
		return
	end
	local archivePath = VFS.GetArchivePath(mapName)
	if archivePath then
		local safeName = string.gsub(mapName, " ", "_")
		local destination = HEIGHT_MAPS_DIR .. "/" .. safeName .. ".jpg"
		WG.WrapperLoopback.ParseHeightMap(archivePath, destination, 4)
	end
end

-- Possible TODO
-- MapHandler.GetMapMinimapImage
-- MapHandler.GetMapInfo (dimensions, wind etc...?)

function widget:Initialize()
	WG.MapHandler = MapHandler

	WG.Delay(ParseAllMinimaps, 1)
end
