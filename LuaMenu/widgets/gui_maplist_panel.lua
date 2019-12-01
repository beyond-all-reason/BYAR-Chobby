function widget:GetInfo()
	return {
		name    = 'Maplist Panel',
		desc    = 'Implements the map panel.',
		author  = 'GoogleFrog',
		date    = '29 July 2016',
		license = 'GNU GPL v2',
		layer   = 0,
		enabled = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Local Variables

local mapListWindow
local lobby
local IMG_READY    = LUA_DIRNAME .. "images/ready.png"
local IMG_UNREADY  = LUA_DIRNAME .. "images/unready.png"

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utilities

local function GetMapType(is1v1, isTeam, isFFA, isChicken, isSpecial)
	if isSpecial then
		return "Special"
	elseif isChicken then
		return "Chicken"
	elseif isFFA then
		return "FFA"
	elseif is1v1 then
		return "1v1"
	elseif isTeam then
		return "Team"
	end
	return "Special"
end

local function GetTerrainType(hillLevel, waterLevel)
	if waterLevel == 3 then
		return "Sea"
	end
	local first
	if hillLevel == 1 then
		first = "Flat "
	elseif hillLevel == 2 then
		first = "Hilly "
	else
		first = "Mountainous "
	end
	local second
	if waterLevel == 1 then
		second = "land"
	else
		second = "mixed"
	end
	
	return first .. second
end

local function CreateMapEntry(mapName, mapData, CloseFunc)--{"ResourceID":7098,"Name":"2_Mountains_Battlefield","SupportLevel":2,"Width":16,"Height":16,"IsAssymetrical":false,"Hills":2,"WaterLevel":1,"Is1v1":false,"IsTeams":true,"IsFFA":false,"IsChickens":false,"FFAMaxTeams":null,"RatingCount":3,"RatingSum":10,"IsSpecial":false},
	local Configuration = WG.Chobby.Configuration
	
	local mapButton = Button:New {
		x = 0,
		y = 0,
		width = "100%",
		caption = "",
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
		OnClick = {
			function()
				lobby:SelectMap(mapName)
				CloseFunc()
			end
		},
	}
	
	local minimap = Panel:New {
		name = "minimap",
		x = 3,
		y = 3,
		width = 52,
		height = 52,
		padding = {1,1,1,1},
		parent = mapButton,
	}
	
	local mapImageFile, needDownload = Configuration:GetMinimapSmallImage(mapName)
	local minimapImage = Image:New {
		name = "minimapImage",
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		keepAspect = true,
		file = mapImageFile,
		fallbackFile = Configuration:GetLoadingImage(2),
		checkFileExists = needDownload,
		parent = minimap,
	}
	
	TextBox:New {
		x = 65,
		y = 12,
		width = 200,
		height = 20,
		valign = 'center',
		fontsize = Configuration:GetFont(2).size,
		text = mapName:gsub("_", " "),
		parent = mapButton,
	}
	
	local haveMap = VFS.HasArchive(mapName)
	local imHaveGame = Image:New {
		x = 612,
		y = 12,
		width = 20,
		height = 20,
		file = (haveMap and IMG_READY) or IMG_UNREADY,
		parent = mapButton,
	}
	
	local sortData
	if mapData then
		TextBox:New {
			x = 274,
			y = 12,
			width = 68,
			height = 20,
			valign = 'center',
			fontsize = Configuration:GetFont(2).size,
			text = (mapData.Width or " ?") .. "x" .. (mapData.Height or " ?"),
			parent = mapButton,
		}
		
		local mapType = GetMapType(mapData.Is1v1, mapData.IsTeams, mapData.IsFFA, mapData.IsChickens, mapData.IsSpecial)
		TextBox:New {
			x = 356,
			y = 12,
			width = 68,
			height = 20,
			valign = 'center',
			fontsize = Configuration:GetFont(2).size,
			text = mapType,
			parent = mapButton,
		}
		
		local terrainType = GetTerrainType(mapData.Hills, mapData.WaterLevel)
		TextBox:New {
			x = 438,
			y = 12,
			width = 160,
			height = 20,
			valign = 'center',
			fontsize = Configuration:GetFont(2).size,
			text = terrainType,
			parent = mapButton,
		}
		
		sortData = {mapName, (mapData.Width or 0)*100 + (mapData.Height or 0), mapType, terrainType, (haveMap and 1) or 0}
	else
		sortData = {mapName, 0, "", "", (haveMap and 1) or 0}
	end
	
	local externalFunctions = {}
	
	function externalFunctions.UpdateHaveMap()
		haveMap = VFS.HasArchive(mapName)
		imHaveGame.file = (haveMap and IMG_READY) or IMG_UNREADY
		imHaveGame:Invalidate()
		sortData[5] = (haveMap and 1) or 0 -- This line is pretty evil.
	end
	
	return mapButton, sortData, externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Controls

local function InitializeControls()
	local Configuration = WG.Chobby.Configuration
	
	local mapListWindow = Window:New {
		classname = "main_window",
		parent = WG.Chobby.lobbyInterfaceHolder,
		height = 700,
		width = 700,
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
	}
	
	Label:New {
		x = 20,
		right = 5,
		y = 17,
		height = 20,
		parent = mapListWindow,
		font = Configuration:GetFont(3),
		caption = "Select a Map",
	}
	
	local function CloseFunc()
		mapListWindow:Hide()
	end
	
	--local loadingPanel = Panel:New {
	--	classname = "overlay_window",
	--	x = "20%",
	--	y = "45%",
	--	right = "20%",
	--	bottom = "45%",
	--	parent = parentControl,
	--}
	--
	--local loadingLabel = Label:New {
	--	x = "5%",
	--	y = "5%",
	--	width = "90%",
	--	height = "90%",
	--	align = "center",
	--	valign = "center",
	--	parent = loadingPanel,
	--	font = Configuration:GetFont(3),
	--	caption = "Loading",
	--}
	
	-------------------------
	-- Map List
	-------------------------
	
	local listHolder = Control:New {
		x = 12,
		right = 15,
		y = 54,
		bottom = 15,
		parent = mapListWindow,
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
	}
	
	local headings = {
		{name = "Name", x = 62, width = 208},
		{name = "Size", x = 272, width = 80},
		{name = "Type", x = 354, width = 80},
		{name = "Terrain", x = 436, width = 172},
		{name = "", tooltip = "Downloaded", x = 610, width = 40, image = "LuaMenu/images/download.png"},
	}
	
	local featuredMapList = WG.CommunityWindow.LoadStaticCommunityData().MapItems or {}
	local mapFuncs = {}
	
	local mapList = WG.Chobby.SortableList(listHolder, headings, 60)
	
	local control, sortData
	for i = 1, #featuredMapList do
		local mapName = featuredMapList[i].Name
		control, sortData, mapFuncs[mapName] = CreateMapEntry(mapName, featuredMapList[i], CloseFunc)
		mapList:AddItem(mapName, control, sortData)
	end
	
	if not Configuration.onlyShowFeaturedMaps then
		for i, archive in pairs(VFS.GetAllArchives()) do
			local info = VFS.GetArchiveInfo(archive)
			if info and info.modtype == 3 and not mapFuncs[info.name] then
				control, sortData, mapFuncs[info.name] = CreateMapEntry(info.name, nil, CloseFunc)
				mapList:AddItem(info.name, control, sortData)
			end
		end
	end
	
	-------------------------
	-- Buttons
	-------------------------
	
	local btnClose = Button:New {
		right = 11,
		y = 7,
		width = 80,
		height = 45,
		caption = i18n("close"),
		font = Configuration:GetFont(3),
		classname = "negative_button",
		parent = mapListWindow,
		OnClick = {
			function()
				CloseFunc()
			end
		},
	}
	
	local btnOnlineMaps = Button:New {
		right = 95,
		y = 7,
		width = 180,
		height = 45,
		caption = i18n("download_maps"),
		font = Configuration:GetFont(3),
		classname = "option_button",
		parent = mapListWindow,
		OnClick = {
			function ()
				WG.BrowserHandler.OpenUrl(Configuration.gameConfig.link_maps())
			end
		},
	}
	WG.Chobby.PriorityPopup(mapListWindow, CloseFunc)
	
	local externalFunctions = {}
	
	function externalFunctions.Show(zoomToMap)
		if not mapListWindow.visible then
			mapListWindow:Show()
		end
		WG.Chobby.PriorityPopup(mapListWindow, CloseFunc)
		if zoomToMap then
			mapList:ScrollToItem(zoomToMap)
		end
	end
	
	function externalFunctions.UpdateHaveMap(thingName)
		if mapFuncs[thingName] then
			mapFuncs[thingName].UpdateHaveMap()
		end
	end
	
	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- External Interface

local MapListPanel = {}

function MapListPanel.Show(newLobby, zoomToMap)
	lobby = newLobby
	if not mapListWindow then
		mapListWindow = InitializeControls()
	end
	mapListWindow.Show(zoomToMap)
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

function widget:Initialize()
	CHOBBY_DIR = LUA_DIRNAME .. "widgets/chobby/"
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	local function DownloadFinished(_, id, thingName)
		if mapListWindow then
			mapListWindow.UpdateHaveMap(thingName)
		end
	end
	WG.DownloadHandler.AddListener("DownloadFinished", DownloadFinished)
	
	WG.MapListPanel = MapListPanel
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------