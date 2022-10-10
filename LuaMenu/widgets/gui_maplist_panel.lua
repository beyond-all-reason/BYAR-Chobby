function widget:GetInfo()
	return {
		name    = 'Maplist Panel',
		desc    = 'Implements the map panel.',
		author  = 'GoogleFrog, Moose',
		date    = '9 Oct 2022',
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
local loadRate = 1
local IMG_READY    = LUA_DIRNAME .. "images/downloadready.png"
local IMG_UNREADY  = LUA_DIRNAME .. "images/downloadnotready.png"

local MINIMAP_TOOLTIP_PREFIX = "minimap_tooltip_"

local listFont2

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

local function GetMapTypeBar(is1v1, isTeam, isFFA)
  local mapTypeString = ""
	if is1v1 then
	mapTypeString = "1v1"
  end
  if isTeam then
	if mapTypeString ~= "" then
	  mapTypeString = mapTypeString .. ", "
	end
	mapTypeString = mapTypeString .. "Team"
  end
	if isFFA then
	if mapTypeString ~= "" then
	  mapTypeString = mapTypeString .. ", "
	end
	mapTypeString = mapTypeString .. "FFA"
  end
  return mapTypeString
end

local function GetTerrainTypeBar(special, flat, hills, water)
  local terrainTypeString = ""
  if special then
	terrainTypeString = terrainTypeString .. special
  end
  if flat then
	if terrainTypeString ~= "" then
	  terrainTypeString = terrainTypeString .. ", "
	end
	terrainTypeString = terrainTypeString .. "Flat"
  end

  if hills then
	if terrainTypeString ~= "" then
	  terrainTypeString = terrainTypeString .. ", "
	end
	terrainTypeString = terrainTypeString .. "Hills"
  end

  if water then
	if terrainTypeString ~= "" then
	  terrainTypeString = terrainTypeString .. ", "
	end
	terrainTypeString = terrainTypeString .. "Water"
  end
  return terrainTypeString
end

local function GetCertifiedLevelBar(isCertified,isClassic)
  if isCertified then return "Certified" end
  if isClassic then return "Classic" end
  return "Unofficial"
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

    local haveMap = VFS.HasArchive(mapName)

    local mapButtonCaption = nil
	if lobby.name == "singleplayer" then
		if not haveMap and (mapData and mapData.IsInPool) then
			mapButtonCaption = "Click to Download this map"
		else
			mapButtonCaption = "Click to choose this map"
		end
	else
		if not haveMap and (mapData and mapData.IsInPool) then
			mapButtonCaption = "Click to Download this map"
		elseif not (mapData and mapData.IsInPool) then
			mapButtonCaption = "Unofficial maps are not available in online play"
		else
			mapButtonCaption = "Click to choose this map"
		end
	end

	local mapButton = Button:New {
		x = 0,
		y = 0,
		width = "100%",
		caption = "",
		resizable = false,
		draggable = false,
		classname = "battle_default_button",
		padding = {0, 0, 0, 0},
		tooltip = MINIMAP_TOOLTIP_PREFIX .. mapName .. "|" .. mapButtonCaption,
		objectOverrideFont = listFont2,
		OnClick = {
			function()
				if (lobby.name == "singleplayer") or (mapData and mapData.IsInPool) then
					lobby:SelectMap(mapName)
					CloseFunc()
				end
			end
		},
	}

	local minimap = Panel:New {
		name = "minimap",
		x = 5,
		y = 4,
		width = 52,
		height = 52,
		padding = {1,1,1,1},
		parent = mapButton,
		noFont = true,
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
		noFont = true,
	}

	TextBox:New {
		x = 65,
		y = 12,
		width = 200,
		height = 20,
		valign = 'center',
		objectOverrideFont = listFont2,
		text = mapName:gsub("_", " "),
		parent = mapButton,
	}

	local imHaveGame = Image:New {
		x = 612,
		y = 12,
		width = 20,
		height = 20,
		file = (haveMap and IMG_READY) or IMG_UNREADY,
		parent = mapButton,
	}

    local certificationLevel = GetCertifiedLevelBar( mapData and mapData.IsCertified, mapData and mapData.IsInPool)
	TextBox:New {
			x = 655,
			y = 12,
			width = 160,
			height = 20,
			valign = 'center',
			objectOverrideFont = listFont2,
			text = certificationLevel,
			parent = mapButton,
	}

	local sortData
	if mapData then
		local mapSizeText = (mapData.Width or " ?") .. "x" .. (mapData.Height or " ?")
        TextBox:New {
			x = 274,
			y = 12,
			width = 68,
			height = 20,
			valign = 'center',
			objectOverrideFont = listFont2,
			text = mapSizeText,
			parent = mapButton,
		}


		local mapType = GetMapTypeBar(mapData.Is1v1, mapData.IsTeam, mapData.IsFFA)
		local maptypetextbox = TextBox:New {
			x = 356,
			y = 12,
			width = 98,
			height = 20,
			valign = 'center',
			objectOverrideFont = listFont2,
			text = mapType,
			parent = mapButton,
		}

		local terrainType = GetTerrainTypeBar(mapData.Special, mapData.Flat, mapData.Hills, mapData.WaterLevel)
		local testtextbox = TextBox:New {
			x = 468,
			y = 12,
			width = 160,
			height = 20,
			valign = 'center',
			objectOverrideFont = listFont2,
			text = terrainType,
			parent = mapButton,
		}

		sortData = {string.lower(mapName), (mapData.Width or 0)*100 + (mapData.Height or 0), string.lower(mapType), string.lower(terrainType), (haveMap and 1) or 0, string.lower(certificationLevel), (haveMap and ' '..mapName) or mapName}
		sortData[7] = sortData[1] .. " " .. mapSizeText .. " " .. sortData[3] .. " " .. sortData[4] .. " " .. sortData[6]-- Used for text filter by name, type, terrain or size.
	else
		sortData = {string.lower(mapName), 0, "", "", (haveMap and 1) or 0, certificationLevel,(haveMap and ' '..mapName) or mapName}
		sortData[7] = sortData[1]
	end

	local externalFunctions = {}

	function externalFunctions.UpdateHaveMap()
		haveMap = VFS.HasArchive(mapName)
		imHaveGame.file = (haveMap and IMG_READY) or IMG_UNREADY
		mapButton.tooltip = (not haveMap and "Click to Download this map") or nil
		mapButton:Invalidate()
		imHaveGame:Invalidate()
		sortData[5] = (haveMap and 1) or 0 -- This line is pretty evil.
	end

	return mapButton, sortData, externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Controls

local function InitializeControls()
	-- ghetto profiling to prove the maplist is a memory hog
	--local lmkb, lmalloc, lgkb, lgalloc = Spring.GetLuaMemUsage()
	--Spring.Echo("LuaMenu KB", lmkb, "allocs", lmalloc, "Lua global KB", lgkb, "allocs", lgalloc)

	local Configuration = WG.Chobby.Configuration

    listFont2 = Font:New(Configuration:GetFont(2))

    local vsx, vsy = Spring.GetViewSizes()
	local mapListWindow = Window:New {
		classname = "main_window",
		parent = WG.Chobby.lobbyInterfaceHolder,
		height = math.max(700, WG.Chobby.lobbyInterfaceHolder.height -100),
		width = 810,
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
	}

	WG.Chobby.lobbyInterfaceHolder.OnResize = WG.Chobby.lobbyInterfaceHolder.OnResize or {}
	WG.Chobby.lobbyInterfaceHolder.OnResize[#WG.Chobby.lobbyInterfaceHolder.OnResize +1] = function()
		-- Spring.Echo("Resized parent of mapListWindow")
		--mapListWindow.height =  math.max(700, WG.Chobby.lobbyInterfaceHolder.height -100)
		local newh = math.max(WG.Chobby.lobbyInterfaceHolder.height -100)
		local newy = math.max(0,(WG.Chobby.lobbyInterfaceHolder.height-newh)/2)
		mapListWindow:SetPos(
			nil,
			newy,
			nil,
			newh)
	end

	local maincaption = "Select any map."
	if lobby.name ~= "singleplayer" then
		maincaption = "Select a Certified or Classic map."
	end

	Label:New {
		x = 35,
		right = 5,
		y = 22,
		height = 21,
		parent = mapListWindow,
		objectOverrideFont = listFont2,
		--font = Configuration:GetFont(2),
		--caption = "Select a Map. Choose a Certified map for the best experience!",
		caption = maincaption,
	}

	local function CloseFunc()
		mapListWindow:Hide()
	end

	local filterTerms
	local function ItemInFilter(sortData)
		if not filterTerms then
			return true
		end

		local textToSearch = sortData[7]
		for i = 1, #filterTerms do
			if not string.find(textToSearch, filterTerms[i]) then
				return false
			end
		end
		return true
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
	--	objectOverrideFont = listFont2,
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
		objectOverrideFont = listFont2,
		parent = mapListWindow,
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
	}

	local headings = {
		{name = "Name", x = 22, width = 248},
		{name = "Size", tooltip = "Choose larger maps for longer games.",x = 272, width = 80},
		{name = "Type", tooltip = "Each map is designed with a specific gameplay setup in mind, but can be played as you desire.\n- 1v1: Designed for small, competitive games\n- Teams: Has resources for multiple players\n- FFA: Free-for-all games", x = 354, width = 110},
		{name = "Terrain", tooltip = "Water maps have underwater resources, and feature naval combat. Bots perform better than vehicles on Hilly maps. Metal maps have unlimited Metal resources.", x = 466, width = 142},
		{name = "", tooltip = "Downloaded", x = 610, width = 40, image = "LuaMenu/images/download.png"},
		{name = "Certified", tooltip = "Certified maps guarantee the best experience, Classic maps offer a great variety of gameplay, and third party maps are marked as Unofficial", x = 652, width = 110},
	}

	local featuredMapList = WG.CommunityWindow.LoadStaticCommunityData().MapItems or {}
	local mapFuncs = {}
	local mapList = WG.Chobby.SortableList(listHolder, headings, 60, 1, true, false, ItemInFilter)

	local featuredMapIndex = 1
	local function AddTheNextBatchOfMaps()
		local mapItems = {}
		local control, sortData
		for i = 1, loadRate do
			if featuredMapList[featuredMapIndex] then
				local mapName = featuredMapList[featuredMapIndex].Name
				control, sortData, mapFuncs[mapName] = CreateMapEntry(mapName, featuredMapList[featuredMapIndex], CloseFunc)
				local certification = sortData[6]
				if lobby.name == "singleplayer" or certification ~= "Unofficial" then
					mapItems[#mapItems + 1] = {mapName, control, sortData}
				end
				featuredMapIndex = featuredMapIndex + 1
			end
		end
		mapList:AddItems(mapItems)

		local addedmaps = {}
		if featuredMapList[featuredMapIndex] then
			WG.Delay(AddTheNextBatchOfMaps, 0.1)
		else
			for i, archive in pairs(VFS.GetAllArchives()) do
				local info = VFS.GetArchiveInfo(archive)
				if info and info.modtype == 3 and not mapFuncs[info.name] then
					addedmaps[info.name] = true
					control, sortData, mapFuncs[info.name] = CreateMapEntry(info.name, Configuration.gameConfig.mapDetails[info.name] , CloseFunc)
					local certification = sortData[6]
					if lobby.name == "singleplayer" or certification ~= "Unofficial" then
						mapItems[#mapItems + 1] = {info.name, control, sortData}
					end
				end
			end
			mapList:AddItems(mapItems)
		end
		for mapname, mapdetails in pairs(Configuration.gameConfig.mapDetails) do
			if addedmaps[mapname] == nil then 
				control, sortData, mapFuncs[mapname] = CreateMapEntry(mapname, mapdetails , CloseFunc)
				local certification = sortData[6]
				if lobby.name == "singleplayer" or certification ~= "Unofficial" then
					mapList:AddItem(mapname, control, sortData)
				end
			end
		end
	end

	WG.Delay(AddTheNextBatchOfMaps, 0.5 / loadRate)

	-------------------------
	-- Buttons
	-------------------------

	local btnClose = Button:New {
		right = 18,
		y = 13,
		width = 80,
		height = 35,
		caption = i18n("close"),
		objectOverrideFont = listFont2,
		--font = Configuration:GetFont(2),
		classname = "negative_button",
		parent = mapListWindow,
		OnClick = {
			function()
				CloseFunc()
			end
		},
	}

	local btnOnlineMaps = Button:New {
		right = 102,
		y = 13,
		width = 180,
		height = 35,
		caption = i18n("download_maps"),
		objectOverrideFont = listFont2,
		--font = Configuration:GetFont(2),
		classname = "option_button",
		parent = mapListWindow,
		OnClick = {
			function ()
				WG.BrowserHandler.OpenUrl(Configuration.gameConfig.link_maps())
			end
		},
	}

	-------------------------
	-- Filtering
	-------------------------

	local ebFilter = EditBox:New {
		right = 288,
		y = 14,
		width = 180,
		height = 33,
		text = '',
		hint = i18n("type_to_filter"),
		objectOverrideFont = listFont2,
		parent = mapListWindow,
		OnKeyPress = {
			function(obj, key, ...)
				if key ~= Spring.GetKeyCode("enter") and key ~= Spring.GetKeyCode("numpad_enter") then
					return
				end
				local visibleItemIds = mapList:GetVisibleItemIds()
				if #visibleItemIds[1] and lobby then
					lobby:SelectMap(visibleItemIds[1])
					CloseFunc()
				end
			end
		},
		OnTextModified = {
			function (self)
				filterTerms = string.lower(self.text):split(" ")
				mapList:RecalculateDisplay()
			end
		}
	}

	-------------------------
	-- External Funcs
	-------------------------

	local externalFunctions = {}

	function externalFunctions.Show(zoomToMap)
		ebFilter:Clear()
		mapList:RecalculateDisplay()

		if not mapListWindow.visible then
			mapListWindow:Show()
		end
		WG.Chobby.PriorityPopup(mapListWindow, CloseFunc)
		if zoomToMap then
			mapList:ScrollToItem(zoomToMap)
		end
		screen0:FocusControl(ebFilter)
	end

	function externalFunctions.UpdateHaveMap(thingName)
		if mapFuncs[thingName] then
			mapFuncs[thingName].UpdateHaveMap()
		elseif not Configuration.onlyShowFeaturedMaps and VFS.HasArchive(thingName) then
			local info = VFS.GetArchiveInfo(thingName)
			if info and info.modtype == 3 and not mapFuncs[info.name] then
				local control, sortData
				control, sortData, mapFuncs[info.name] = CreateMapEntry(info.name, nil, CloseFunc)
				mapList:AddItem(info.name, control, sortData)
			end
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
	loadRate = 40
	if not mapListWindow then
		mapListWindow = InitializeControls()
	end
	mapListWindow.Show(zoomToMap)
end

function MapListPanel.Preload()
	if not mapListWindow then
		mapListWindow = InitializeControls()
	end
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
