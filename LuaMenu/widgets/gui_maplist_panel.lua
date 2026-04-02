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
local favMaps = {}
local FILE_FAV_MAPS = "favourite_maps.txt"
local IMG_READY    	= LUA_DIRNAME .. "images/downloadready.png"
local IMG_UNREADY  	= LUA_DIRNAME .. "images/downloadnotready.png"
local nameShift = 0

local MINIMAP_TOOLTIP_PREFIX = "minimap_tooltip_"
local SIZE_FILTER_LABELS = {"XS", "S", "M", "L", "XL", "XXL", "XXXL"}
local SIZE_FILTER_QUANTILES = {0.08, 0.24, 0.40, 0.60, 0.78, 0.92}
local SIZE_FILTER_FALLBACK_THRESHOLDS = {64, 144, 256, 400, 576, 784}
local SIZE_FILTER_RANK = {
	["XS"] = 1,
	["S"] = 2,
	["M"] = 3,
	["L"] = 4,
	["XL"] = 5,
	["XXL"] = 6,
	["XXXL"] = 7,
	["-"] = 8,
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Planet / Lore categorization
--
-- Keys are lowercase prefixes that an archive name must START WITH (after normalising underscores → spaces) to be assigned to that planet. Longer prefix = more specific; Lua pairs() order is arbitrary, but every collision in the current data maps to the same planet, so order is safe.
local PLANET_MAP_PREFIXES = {
	-- Anamnesis
	["gasbag grabens"]       = "Anamnesis",
	["sector 318c"]          = "Anamnesis",
	["stronghold"]           = "Anamnesis",
	-- Inkussik
	["ascendancy"]           = "Inkussik",
	["blindside"]            = "Inkussik",
	["glacial gap"]          = "Inkussik",
	["ice scream"]           = "Inkussik",
	["melting glacier"]      = "Inkussik",
	["the cold place"]       = "Inkussik",
	-- Galphena
	["canis river"]          = "Galphena",
	["erebos lakes"]         = "Galphena",
	["failed negotiations"]  = "Galphena",
	["hera planum"]          = "Galphena",
	["isidis crack"]         = "Galphena",
	["isidis_crack"]         = "Galphena",
	["starwatcher"]          = "Galphena",
	["white fire"]           = "Galphena",
	["feast of hades"]       = "The Pale Hang",
	["hades ponds"]          = "The Pale Hang",
	["theta crystals"]       = "The Pale Hang",
	-- Kharros
	["gods of war"]          = "Kharros",
	["hellas basin"]         = "Kharros",
	["red river estuary"]    = "Kharros",
	["red river"]            = "Kharros",
	["sinkhole network"]     = "Kharros",
	-- Enborelde
	["angel crossing"]       = "Enborelde",
	["supreme isthmus"]      = "Enborelde",
	-- Osemo
	["cirolata"]             = "Osemo",
	["otago"]                = "Osemo",
	["rustcrown canyon"]     = "Osemo",
	["the rock jungle"]      = "Osemo",
	["twin lakes park"]      = "Osemo",
	["wanderlust"]           = "Osemo",
	-- M3-005
	["azurite shores"]       = "M3-005",
	["hyperion shale"]       = "M3-005",
	-- Jintram-7
	["centerrock"]           = "Jintram-7",
	["colorado"]             = "Jintram-7",
	["emain macha"]          = "Jintram-7",
	["emainmacha"]           = "Jintram-7",   -- CamelCase archive name variant
	["glacier pass"]         = "Jintram-7",
	["greenest fields"]      = "Jintram-7",
	["neurope"]              = "Jintram-7",
	["nuclear winter"]       = "Jintram-7",
	["seths ravine"]         = "Jintram-7",
	["supreme crossing 2"]   = "Jintram-7",
	["timna island"]         = "Jintram-7",
	-- Elderbone
	["eight horses"]         = "Elderbone",
	["pawn retreat"]         = "Elderbone",
	["salmiakki"]            = "Elderbone",
	-- Artturisir
	["titan"]                = "Artturisir",  -- matches both Titan and Titan Duel
	-- Jashenon
	["death valley"]         = "Jashenon",
	["desolation"]           = "Jashenon",
	["into battle redux"]    = "Jashenon",
	["mithril mountain"]     = "Jashenon",
	["red rock desert"]      = "Jashenon",
	["silent sea"]           = "Jashenon",
}

-- Returns the planet name for a given map archive name, or nil if unassigned.
local function GetPlanetForMap(mapName)
	local normalized = string.lower(mapName:gsub("_", " "))
	for prefix, planet in pairs(PLANET_MAP_PREFIXES) do
		if string.sub(normalized, 1, #prefix) == prefix then
			return planet
		end
	end
	return nil
end

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

local function GetTerrainTypeBar(special, flat, hills, water, infoText)
	local parts = {}
	if special then
		parts[#parts + 1] = special
	end
	if flat then
		parts[#parts + 1] = "Flat"
	end
	if hills then
		parts[#parts + 1] = "Hills"
	end
	if water then
		parts[#parts + 1] = "Water"
	end
	-- Append up to two additional flavor tags parsed from the map description so players can see at a glance whether a map is snowy, grassy, volcanic, etc.
	if infoText and infoText ~= "" then
		local lower = string.lower(infoText)
		local flavor = {}
		if string.find(lower, "grass") or string.find(lower, "meadow") then
			flavor[#flavor + 1] = "Grassy"
		end
		if string.find(lower, "snow") or string.find(lower, "ice") or string.find(lower, "frozen") or string.find(lower, "icy") then
			flavor[#flavor + 1] = "Snow"
		end
		if string.find(lower, "desert") or string.find(lower, "arid") then
			flavor[#flavor + 1] = "Desert"
		end
		if string.find(lower, "lava") or string.find(lower, "volcan") or string.find(lower, "vulcanic") then
			flavor[#flavor + 1] = "Lava"
		end
		if string.find(lower, "jungle") or string.find(lower, "tropical") then
			flavor[#flavor + 1] = "Jungle"
		end
		if string.find(lower, "island") then
			flavor[#flavor + 1] = "Island"
		end
		if string.find(lower, "wasteland") then
			flavor[#flavor + 1] = "Wsld"
		end
		if string.find(lower, "asteroid") or string.find(lower, "orbit") then
			flavor[#flavor + 1] = "Space"
		end
		-- Show at most 2 flavor tags to avoid overflowing the column
		for i = 1, math.min(2, #flavor) do
			parts[#parts + 1] = flavor[i]
		end
	end
	return table.concat(parts, ", ")
end

local function GetMapAge(LastUpdate)
  local now = os.time()
  local twoWeeksAgo = now - 60*60*24*14
  local mapAge = 999999999
  if ( LastUpdate == nil ) then LastUpdate = 1 end --some maps can  have lastUpdate = nil
  if ( LastUpdate >= twoWeeksAgo ) then 
	mapAge = now - LastUpdate end
  return mapAge--if it's older then two weeks don't sort by age
end

local function GetSizeCategory(width, height)
	local area = (width or 0) * (height or 0)
	if area <= 64 then
		return "Tiny"
	elseif area <= 196 then
		return "Small"
	elseif area <= 400 then
		return "Medium"
	elseif area <= 576 then
		return "Large"
	else
		return "Huge"
	end
end

local function BuildSizeFilterThresholds(mapDetails)
	local areas = {}
	for _, details in pairs(mapDetails or {}) do
		local width = tonumber(details.Width) or 0
		local height = tonumber(details.Height) or 0
		local area = width * height
		if area > 0 then
			areas[#areas + 1] = area
		end
	end

	if #areas == 0 then
		return SIZE_FILTER_FALLBACK_THRESHOLDS
	end

	table.sort(areas)
	local thresholds = {}
	local lastValue = areas[1]
	for i = 1, #SIZE_FILTER_QUANTILES do
		local q = SIZE_FILTER_QUANTILES[i]
		local idx = math.max(1, math.min(#areas, math.floor((#areas - 1) * q + 1)))
		local value = areas[idx]
		if value < lastValue then
			value = lastValue
		end
		thresholds[i] = value
		lastValue = value
	end

	return thresholds
end

local function GetSizeFilterLabel(area, thresholds)
	area = tonumber(area) or 0
	if area <= 0 then
		return "-"
	end

	thresholds = thresholds or SIZE_FILTER_FALLBACK_THRESHOLDS
	for i = 1, #thresholds do
		if area <= thresholds[i] then
			return SIZE_FILTER_LABELS[i]
		end
	end

	return SIZE_FILTER_LABELS[#SIZE_FILTER_LABELS]
end

-- Returns a space-separated string of terrain/atmosphere flavor tags derived from a map's InfoText description. Used to extend the text filter index.
local function GetInfoTextTags(infoText)
	if not infoText or infoText == "" then
		return ""
	end
	local lower = string.lower(infoText)
	local tags = {}
	if string.find(lower, "grass") or string.find(lower, "meadow") or string.find(lower, "steppe") then
		tags[#tags + 1] = "grassland"
	end
	if string.find(lower, "snow") or string.find(lower, "ice") or string.find(lower, "frozen")
			or string.find(lower, "arctic") or string.find(lower, "tundra") or string.find(lower, "icy") then
		tags[#tags + 1] = "snow"
	end
	if string.find(lower, "desert") or string.find(lower, "arid") then
		tags[#tags + 1] = "desert"
	end
	if string.find(lower, "sand") and not string.find(lower, "desert") then
		tags[#tags + 1] = "sandy"
	end
	if string.find(lower, "lava") or string.find(lower, "volcan") or string.find(lower, "vulcanic") then
		tags[#tags + 1] = "lava"
	end
	if string.find(lower, "jungle") or string.find(lower, "tropical") then
		tags[#tags + 1] = "jungle"
	end
	if string.find(lower, "forest") then
		tags[#tags + 1] = "forest"
	end
	if string.find(lower, "canyon") then
		tags[#tags + 1] = "canyon"
	end
	if string.find(lower, "ruin") then
		tags[#tags + 1] = "ruins"
	end
	if string.find(lower, "wasteland") then
		tags[#tags + 1] = "wasteland"
	end
	if string.find(lower, "asteroid") or string.find(lower, "orbit") then
		tags[#tags + 1] = "space"
	end
	if string.find(lower, "island") then
		tags[#tags + 1] = "island"
	end
	if string.find(lower, "coast") or string.find(lower, "shore") or string.find(lower, "beach") or string.find(lower, "bay") then
		tags[#tags + 1] = "coastal"
	end
	if string.find(lower, "tidal") then
		tags[#tags + 1] = "tidal"
	end
	if string.find(lower, "chokepoint") then
		tags[#tags + 1] = "chokepoints"
	end
	if string.find(lower, "factory") or string.find(lower, "manufacturing") then
		tags[#tags + 1] = "industrial"
	end
	if string.find(lower, "speed boost") or string.find(lower, "speed up") then
		tags[#tags + 1] = "speedzone"
	end
	if string.find(lower, "asymm") then
		tags[#tags + 1] = "asymmetric"
	end
	if string.find(lower, "wind") then
		tags[#tags + 1] = "windy"
	end
	if string.find(lower, "chicken") or string.find(lower, "scavenger") or string.find(lower, "pve") then
		tags[#tags + 1] = "pve"
	end
	return table.concat(tags, " ")
end

local function GetCertifiedLevelBar(isCertified,isClassic,LastUpdate)
  if ( LastUpdate == nil ) then LastUpdate = 1 end --some maps can  have lastUpdate = nil
  if ( GetMapAge(LastUpdate) < 999999999) then return "   NEW!" end
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

local function CreateMapEntry(mapName, mapData, CloseFunc, OnFilterDataChanged, OnPreviewDataChanged, OnMapLocked)--{"ResourceID":7098,"Name":"2_Mountains_Battlefield","SupportLevel":2,"Width":16,"Height":16,"IsAssymetrical":false,"Hills":2,"WaterLevel":1,"Is1v1":false,"IsTeams":true,"IsFFA":false,"IsChickens":false,"FFAMaxTeams":null,"RatingCount":3,"RatingSum":10,"IsSpecial":false},
	local Configuration = WG.Chobby.Configuration
	local compactFont = WG.Chobby.Configuration:GetFont(11)

    local haveMap = VFS.HasArchive(mapName)
	local isFavourite = favMaps[mapName] ~= nil;
	local planet = GetPlanetForMap(mapName)

    local mapButtonCaption = nil

	if not haveMap then
		mapButtonCaption = i18n("click_to_download_map")
	else
		mapButtonCaption = i18n("click_to_pick_map")
	end

	local root = Panel:New {
		x = 0,
		y = 0,
		width = 1046 + nameShift,
		height = 64,
		resizable = false,
		draggable = false,
		padding = {0,0,0,0},
		noFont = true,
	}

	local mapButton = Button:New {
		x = 0,
		y = 0,
		width = 913 + nameShift,
		height = "100%",
		caption = "",
		resizable = false,
		draggable = false,
		classname = "battle_default_button",
		padding = {0, 0, 0, 0},
		parent = root,
		tooltip = mapButtonCaption,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		OnMouseOver = {
			function()
				if OnPreviewDataChanged then
					OnPreviewDataChanged(mapName)
				end
			end
		},
		OnClick = {
			function()
				if (lobby.name == "singleplayer") or (mapData and mapData.IsInPool) then
					if OnMapLocked then
						OnMapLocked(mapName)
					else
						lobby:SelectMap(mapName)
						CloseFunc()
					end
				end
			end
		},
		OnDblClick = {
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
		x = 20,
		y = 5,
		width = 52,
		height = 54,
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

	Label:New {
		x = 87,
		y = 5,
		width = 241 + nameShift,
		height = 54,
		align = 'left',
		valign = 'center',
		autosize = false,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		caption = mapName:gsub("_", " "),
		parent = mapButton,
	}

	local imHaveGame = Image:New {
		x = 1006 + nameShift,
		y = 20,
		width = 16,
		height = 20,
		file = (haveMap and IMG_READY) or IMG_UNREADY,
		parent = root,
	}

	local certificationLevel = GetCertifiedLevelBar( mapData and mapData.IsCertified, mapData and mapData.IsInPool, mapData and mapData.LastUpdate)

	local favouriteBtn = Checkbox:New {
		x = 934 + nameShift,
		y = 18,
		width = 22,
		height = 24,
		caption = "",
		checked = isFavourite,
		classname = "favourite_check",
		tooltip = "Favourited maps will always appear on top.",
		parent = root,
 		OnClick = {
			function ()
				if isFavourite then
					isFavourite = false;
					favMaps[mapName] = nil;
				else
					isFavourite = true;
					favMaps[mapName] = 1;
				end
				if sortData then
					sortData.filterValues[8] = (isFavourite and "Favourited") or "Not favourited"
					if OnFilterDataChanged then
						OnFilterDataChanged(sortData)
					end
				end
			end
		}
	}

	local sortData
	local mapSizeText = "-"
	local playerCount = "-"
	local mapType = "-"
	local terrainType = "-"
	local planetText = planet or "-"
	if mapData then
		local sizeCategory = GetSizeCategory(mapData.Width, mapData.Height)
		mapSizeText = (mapData.Width or "?") .. "x" .. (mapData.Height or "?")
		Label:New {
			x = 334 + nameShift,
			y = 5,
			width = 88,
			height = 54,
			align = 'left',
			valign = 'center',
			autosize = false,
			objectOverrideFont = compactFont,
			caption = mapSizeText,
			parent = mapButton,
		}


		playerCount = mapData.PlayerCount or '0'
		if string.len(playerCount)== 1 then
			playerCount = " " .. playerCount
		end
		Label:New {
			x = 428 + nameShift,
			y = 5,
			width = 37,
			height = 54,
			align = 'left',
			valign = 'center',
			autosize = false,
			objectOverrideFont = compactFont,
			caption = playerCount,
			parent = mapButton,
		}


		mapType = GetMapTypeBar(mapData.Is1v1, mapData.IsTeam, mapData.IsFFA)
		local maptypetextbox = Label:New {
			x = 471 + nameShift,
			y = 5,
			width = 142,
			height = 54,
			align = 'left',
			valign = 'center',
			autosize = false,
			objectOverrideFont = compactFont,
			caption = mapType,
			parent = mapButton,
		}

		terrainType = GetTerrainTypeBar(mapData.Special, mapData.Flat, mapData.Hills, mapData.Water, mapData.InfoText)
		local testtextbox = Label:New {
			x = 619 + nameShift,
			y = 5,
			width = 162,
			height = 54,
			align = 'left',
			valign = 'center',
			autosize = false,
			objectOverrideFont = compactFont,
			caption = terrainType,
			parent = mapButton,
		}

		planetText = planet or "-"
		Label:New {
			x = 787 + nameShift,
			y = 5,
			width = 120,
			height = 54,
			align = 'left',
			valign = 'center',
			autosize = false,
			objectOverrideFont = compactFont,
			caption = planetText,
			parent = mapButton,
		}

		local infoTextTags = GetInfoTextTags(mapData.InfoText)
		local sizeLabel = string.lower(sizeCategory)
		local planetLabel = planet and string.lower(planet) or ""
		sortData = {string.lower(mapName), (mapData.Width or 0) * (mapData.Height or 0), playerCount, string.lower(mapType), string.lower(terrainType), planetLabel, (haveMap and 1) or 0, string.lower(certificationLevel), string.format( "%09d", GetMapAge(mapData.LastUpdate) )  .. mapName }
		-- sortData[10] is the full-text search index: name + size (with category label) + player count + game type + terrain tags (including InfoText flavor) + size category word + infotext tags + planet name + certification level + age token.
		sortData[10] = sortData[1] .. " " .. mapSizeText .. " " .. sizeLabel .. " " .. sortData[3] .. " " .. sortData[4] .. " " .. sortData[5] .. " " .. infoTextTags .. " " .. planetLabel .. " " .. sortData[8] .. " " .. sortData[9]
	else
		local planetLabel = planet and string.lower(planet) or ""
		TextBox:New {
			x = 787 + nameShift,
			y = 22,
			width = 120,
			height = 20,
			valign = 'center',
			objectOverrideFont = compactFont,
			objectOverrideHintFont = compactFont,
			text = planet or "-",
			parent = mapButton,
		}
		sortData = {string.lower(mapName), 0, "", "", "", planetLabel, (haveMap and 1) or 0, certificationLevel, "999999999" .. ((haveMap and ' '..mapName) or mapName)}
		sortData[10] = sortData[1] .. " " .. planetLabel
	end

	sortData.filterValues = {
		mapName:gsub("_", " "),
		mapSizeText,
		playerCount,
		mapType,
		terrainType,
		planetText,
		(haveMap and "Downloaded") or "Missing",
		(isFavourite and "Favourited") or "Not favourited",
	}

	local externalFunctions = {}

	function externalFunctions.UpdateHaveMap()
		haveMap = VFS.HasArchive(mapName)
		imHaveGame.file = (haveMap and IMG_READY) or IMG_UNREADY
		if haveMap then
			mapButton.tooltip = i18n("click_to_pick_map")
		else
			mapButton.tooltip = i18n("click_to_download_map")
		end
		mapButton:Invalidate()
		imHaveGame:Invalidate()
		sortData[7] = (haveMap and 1) or 0 -- This line is pretty evil.
		sortData.filterValues[7] = (haveMap and "Downloaded") or "Missing"
		if OnFilterDataChanged then
			OnFilterDataChanged(sortData)
		end
	end

	function externalFunctions.ShowPreview()
		if OnPreviewDataChanged then
			OnPreviewDataChanged(mapName)
		end
	end

	return root, sortData, externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Controls

local function InitializeControls()
	local Configuration = WG.Chobby.Configuration

	local expandedPreviewWindow -- forward declaration for cleanup in CloseFunc

    local ww, wh = Spring.GetWindowGeometry()
	nameShift = math.max(0, math.min(1200, ww - 60) - 28 - 14 - 1046)
	local mapListWindow = Window:New {
		classname = "main_window",
		parent = WG.Chobby.lobbyInterfaceHolder,
		height = wh -100,
		width = math.min(1200, ww -60),
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
	}

	WG.Chobby.lobbyInterfaceHolder.OnResize = WG.Chobby.lobbyInterfaceHolder.OnResize or {}
	WG.Chobby.lobbyInterfaceHolder.OnResize[#WG.Chobby.lobbyInterfaceHolder.OnResize +1] = function()
		local ww, wh = Spring.GetWindowGeometry()

		local neww = math.min(1200, ww -60)
		local newx = (ww - neww) / 2

		local newh = wh -100
		local newy = (wh - newh) / 2

		mapListWindow:SetPos(
			newx,
			newy,
			neww,
			newh
		)
	end

	local captionHolder = Control:New {
		x = 0,
		y = 0,
		right = 283,
		bottom = 0,
		name = "captionHolder",
		parent = mapListWindow,
		padding = {0, 0, 0, 0},
		children = {}
    }

	local maincaption = i18n("maincaption_singleplayer")
	if	lobby.name ~= "singleplayer" then
		maincaption = i18n("maincaption_multiplayer")
	end

	Label:New {
		x = 22,
		right = 5,
		y = 1,
		height = 21,
		parent = captionHolder,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(1),
		caption = maincaption,
	}

	local CloseAllFilterDropdowns

	local function CloseFunc()
		if expandedPreviewWindow then
			expandedPreviewWindow:Dispose()
			expandedPreviewWindow = nil
			return
		end
		CloseAllFilterDropdowns()
		mapListWindow:Hide()

		--Save "favourite maps" data to file
		local favMapsFile = io.open(FILE_FAV_MAPS, "w");
		favMapsFile:write(Spring.Utilities.GetEngineVersion() .. "\n"); --Game version is always first line
		for mapName in pairs(favMaps) do
			favMapsFile:write(mapName .. "\n");
		end
		io.close(favMapsFile);
		if WG.BattleRoomChatInput then
			screen0:FocusControl(WG.BattleRoomChatInput)
		end
	end

	local filterTerms

	local columnFilterState = {}
	local sizeFilterThresholds = BuildSizeFilterThresholds(Configuration.gameConfig.mapDetails)

	local function NormalizeFilterValue(value)
		if value == nil or value == "" then
			return "-"
		end
		return tostring(value)
	end

	local function GetFilterValueForColumn(sortData, columnIndex)
		if columnIndex == 2 then
			return GetSizeFilterLabel(sortData and sortData[2], sizeFilterThresholds)
		end
		if sortData.filterValues and sortData.filterValues[columnIndex] ~= nil then
			return NormalizeFilterValue(sortData.filterValues[columnIndex])
		end
		return NormalizeFilterValue(sortData[columnIndex])
	end

	local function ColumnHasRestriction(state)
		if not state then
			return false
		end
		local total = 0
		local selected = 0
		for _, option in ipairs(state.optionOrder) do
			total = total + 1
			if state.selected[option] then
				selected = selected + 1
			end
		end
		return total > 0 and selected < total
	end

	local filterQuery -- full lowered query for fuzzy matching

	-- Fuzzy subsequence scorer: returns a positive score if query is a subsequence of target, 0 otherwise.
	-- Awards bonuses for consecutive matches, word boundaries, and start-of-string.
	-- Penalizes gaps between matched characters.
	local function fuzzyScore(query, target)
		local qlen = #query
		local tlen = #target
		if qlen == 0 then return 0 end
		if qlen > tlen then return 0 end

		local score = 0
		local qi = 1
		local consecutive = 0
		local lastMatchPos = 0

		for ti = 1, tlen do
			if qi <= qlen and string.byte(target, ti) == string.byte(query, qi) then
				-- Gap penalty
				if lastMatchPos > 0 then
					local gap = ti - lastMatchPos - 1
					if gap > 0 then
						score = score - gap * 1.0
						consecutive = 0
					end
				end

				-- Base match point
				score = score + 1

				-- Consecutive bonus
				consecutive = consecutive + 1
				if consecutive > 1 then
					score = score + consecutive
				end

				-- Word boundary bonus (after space, underscore, dash)
				if ti > 1 then
					local prev = string.byte(target, ti - 1)
					if prev == 32 or prev == 95 or prev == 45 then -- space, _, -
						score = score + 4
					end
				elseif ti == 1 then
					score = score + 5 -- start of string
				end

				-- Position bonus (earlier = better)
				score = score + math.max(0, (20 - ti) * 0.1)

				lastMatchPos = ti
				qi = qi + 1
			else
				if qi <= qlen then
					consecutive = 0
				end
			end
		end

		if qi <= qlen then return 0 end -- didn't match all query chars

		-- Normalize: prefer shorter targets
		score = score + math.max(0, 3 - (tlen - qlen) * 0.1)

		return score
	end

	local function ItemInFilter(sortData)
		if filterTerms then
			local textToSearch = sortData[10]

			-- Tier 1: All terms must appear as exact substrings
			local allFound = true
			for i = 1, #filterTerms do
				if filterTerms[i] ~= "" and not string.find(textToSearch, filterTerms[i], 1, true) then
					allFound = false
					break
				end
			end

			-- Tier 2: Fuzzy subsequence match against map name (min 4 chars)
			if not allFound then
				if filterQuery and #filterQuery >= 4 then
					local mapName = sortData[1]
					local score = fuzzyScore(filterQuery, mapName)
					if score < #filterQuery * 3 then
						return false
					end
				else
					return false
				end
			end
		end

		for columnIndex, state in pairs(columnFilterState) do
			if ColumnHasRestriction(state) then
				if columnIndex == 5 then
					-- Terrain: pass if at least one of the map's tags is selected.
					local terrainStr = GetFilterValueForColumn(sortData, columnIndex)
					if terrainStr == "-" then
						if not state.selected["-"] then
							return false
						end
					else
						local anySelected = false
						for tag in terrainStr:gmatch("[^,]+") do
							tag = tag:match("^%s*(.-)%s*$")
							if tag ~= "" and state.selected[tag] then
								anySelected = true
								break
							end
						end
						if not anySelected then
							return false
						end
					end
				else
					local value = GetFilterValueForColumn(sortData, columnIndex)
					if not state.selected[value] then
						return false
					end
				end
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
	--	objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
	--	caption = "Loading",
	--}

	-------------------------
	-- Map List
	-------------------------

	local previewMapName
	local lockedPreviewMapName
	local mapArchiveInfoCache = {}

	local function GetMapArchiveInfo(mapName)
		if mapArchiveInfoCache[mapName] ~= nil then
			return mapArchiveInfoCache[mapName] or nil
		end

		local info
		if VFS.HasArchive(mapName) then
			local archivePath = VFS.GetArchivePath(mapName)
			if archivePath then
				info = VFS.GetArchiveInfo(archivePath)
			end
			if (not info) then
				info = VFS.GetArchiveInfo(mapName)
			end
		end

		mapArchiveInfoCache[mapName] = info or false
		return info
	end

	local function GetFirstPresentValue(...)
		local list = {...}
		for i = 1, #list do
			local value = list[i]
			if value ~= nil and value ~= "" then
				return value
			end
		end
		return nil
	end

	local function NormalizeInfoValue(value)
		if value == nil then
			return nil
		end
		if type(value) == "string" then
			local trimmed = value:match("^%s*(.-)%s*$")
			if trimmed == "" then
				return nil
			end
			return trimmed
		end
		if type(value) == "number" then
			return tostring(value)
		end
		if type(value) == "boolean" then
			return value and "Yes" or "No"
		end
		return tostring(value)
	end

	local function FormatTimestamp(ts)
		ts = tonumber(ts)
		if not ts or ts <= 0 then
			return nil
		end
		return os.date("%Y-%m-%d", ts)
	end

	local function TryAddInfoLine(lines, key, value)
		value = NormalizeInfoValue(value)
		if value then
			lines[#lines + 1] = key .. ": " .. value
		end
	end

	local function BuildPreviewInfoText(mapName, mapData)
		local lines = {}
		local archiveInfo = GetMapArchiveInfo(mapName)

		local function AddParamPart(parts, key, value)
			value = NormalizeInfoValue(value)
			if value then
				parts[#parts + 1] = key .. ": " .. value
			end
		end

		local sizeText = mapData and ((mapData.Width or "?") .. " x " .. (mapData.Height or "?")) or nil
		local playersText = mapData and mapData.PlayerCount or nil
		local teamsText = mapData and mapData.TeamCount or nil
		local typeText = mapData and GetMapTypeBar(mapData.Is1v1, mapData.IsTeam, mapData.IsFFA) or nil
		local terrainText = mapData and GetTerrainTypeBar(mapData.Special, mapData.Flat, mapData.Hills, mapData.Water, mapData.InfoText) or nil
		local certText = GetCertifiedLevelBar(mapData and mapData.IsCertified, mapData and mapData.IsInPool, mapData and mapData.LastUpdate)
		local downloadedText = VFS.HasArchive(mapName) and "Downloaded" or "Missing"
		local planetText = GetPlanetForMap(mapName)

		local windMin = GetFirstPresentValue(mapData and mapData.MinWind, archiveInfo and archiveInfo.minWind, archiveInfo and archiveInfo.windMin)
		local windMax = GetFirstPresentValue(mapData and mapData.MaxWind, archiveInfo and archiveInfo.maxWind, archiveInfo and archiveInfo.windMax)
		local tidal = GetFirstPresentValue(mapData and mapData.Tidal, mapData and mapData.TidalStrength, archiveInfo and archiveInfo.tidal, archiveInfo and archiveInfo.tidalStrength)
		local gravity = GetFirstPresentValue(mapData and mapData.Gravity, archiveInfo and archiveInfo.gravity)
		local extractorRadius = GetFirstPresentValue(mapData and mapData.ExtractorRadius, archiveInfo and archiveInfo.extractorRadius)

		local windText
		if windMin and windMax then
			windText = tostring(windMin) .. " - " .. tostring(windMax)
		elseif windMin then
			windText = tostring(windMin)
		elseif windMax then
			windText = tostring(windMax)
		end

		local row1 = {}
		AddParamPart(row1, "Size", sizeText)
		AddParamPart(row1, "Players", playersText)
		AddParamPart(row1, "Teams", teamsText)
		AddParamPart(row1, "Type", typeText)
		AddParamPart(row1, "Terrain", terrainText)

		local row2 = {}
		AddParamPart(row2, "Wind", windText)
		AddParamPart(row2, "Tidal", tidal)
		AddParamPart(row2, "Gravity", gravity)
		AddParamPart(row2, "Extractor", extractorRadius)
		AddParamPart(row2, "Planet", planetText)
		AddParamPart(row2, "Certified", certText)
		AddParamPart(row2, "Status", downloadedText)

		if #row1 > 0 then
			lines[#lines + 1] = table.concat(row1, "   ")
		end
		if #row2 > 0 then
			lines[#lines + 1] = table.concat(row2, "   ")
		end

		local author = GetFirstPresentValue(mapData and mapData.Author, archiveInfo and archiveInfo.author, archiveInfo and archiveInfo.authorname)

		local created = GetFirstPresentValue(
			mapData and mapData.Created,
			archiveInfo and archiveInfo.created,
			archiveInfo and archiveInfo.creationDate,
			archiveInfo and archiveInfo.createdAt
		)

		local updated = GetFirstPresentValue(mapData and mapData.LastUpdate, archiveInfo and archiveInfo.lastUpdate, archiveInfo and archiveInfo.updatedAt)

		local detailRow = {}
		AddParamPart(detailRow, "Author", author)
		AddParamPart(detailRow, "Created", FormatTimestamp(created) or created)
		AddParamPart(detailRow, "Updated", FormatTimestamp(updated) or updated)
		if #detailRow > 0 then
			lines[#lines + 1] = table.concat(detailRow, "   ")
		end

		local description = GetFirstPresentValue(mapData and mapData.InfoText, archiveInfo and archiveInfo.description, archiveInfo and archiveInfo.desc)
		description = NormalizeInfoValue(description)
		if description then
			lines[#lines + 1] = ""
			lines[#lines + 1] = description
		end

		if #lines == 0 then
			return "No map metadata available."
		end

		return table.concat(lines, "\n")
	end

	local previewPanel = Panel:New {
		x = 12,
		right = 15,
		y = 54,
		height = 223,
		parent = mapListWindow,
		classname = "overlay_window",
		padding = {8, 8, 8, 8},
	}

	local previewImageHolder = Panel:New {
		x = 10,
		y = 19,
		width = 296,
		height = 166,
		padding = {1, 1, 1, 1},
		parent = previewPanel,
		noFont = true,
	}

	local previewImage = Image:New {
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		keepAspect = true,
		file = Configuration:GetLoadingImage(3),
		fallbackFile = Configuration:GetLoadingImage(2),
		parent = previewImageHolder,
		noFont = true,
	}

	local previewTitle = Label:New {
		x = 318,
		right = 12,
		y = 12,
		height = 24,
		caption = "Hover a map to preview",
		parent = previewPanel,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
	}

	local previewInfo = TextBox:New {
		x = 318,
		right = 12,
		y = 40,
		bottom = 62,
		text = "Move your cursor over a map row to preview it here.",
		parent = previewPanel,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(11),
		objectOverrideHintFont = WG.Chobby.Configuration:GetFont(11),
	}

	local selectMapButton = Button:New {
		width = 160,
		right = 12,
		bottom = 10,
		height = 44,
		caption = "Select Map",
		isHidden = true,
		classname = "ready_button",
		parent = previewPanel,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		OnClick = {
			function()
				if lockedPreviewMapName then
					lobby:SelectMap(lockedPreviewMapName)
					CloseFunc()
				end
			end
		},
	}
	selectMapButton:StyleReady()

	--------------------------------------------------------------
	-- Expanded Map Preview Window
	--------------------------------------------------------------
	-- expandedPreviewWindow forward-declared at top of InitializeControls

	local function OpenExpandedPreview(mapName)
		if not mapName then
			return
		end

		if expandedPreviewWindow then
			expandedPreviewWindow:Dispose()
			expandedPreviewWindow = nil
		end

		local screenWidth, screenHeight = Spring.GetWindowGeometry()
		local winW = math.min(960, screenWidth - 60)
		local winH = math.min(910, screenHeight - 60)

		expandedPreviewWindow = Window:New {
			caption = "",
			name = "expandedMapPreview",
			parent = screen0,
			width = winW,
			height = winH,
			x = math.floor((screenWidth - winW) / 2),
			y = math.floor((screenHeight - winH) / 2),
			resizable = false,
			draggable = false,
			classname = "main_window",
			padding = {0, 0, 0, 0},
		}

		local function CloseExpandedPreview()
			if expandedPreviewWindow then
				expandedPreviewWindow:Dispose()
				expandedPreviewWindow = nil
			end
		end

		-- Image area fills most of the window
		local imageHolder = Panel:New {
			x = 18,
			right = 18,
			y = 18,
			bottom = 58,
			padding = {12, 12, 12, 12},
			parent = expandedPreviewWindow,
			noFont = true,
		}

		-- Close button at bottom-right, below the image
		local btnClose = Button:New {
			right = 22,
			bottom = 16,
			width = 80,
			height = 35,
			caption = i18n("close"),
			objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
			classname = "negative_button",
			parent = expandedPreviewWindow,
			OnClick = {
				function()
					CloseExpandedPreview()
				end
			},
		}

		local mapImageFile, needDownload = Configuration:GetMinimapImage(mapName)
		Image:New {
			x = 0,
			y = 0,
			right = 0,
			bottom = 0,
			keepAspect = true,
			file = mapImageFile,
			fallbackFile = Configuration:GetLoadingImage(3),
			checkFileExists = needDownload,
			parent = imageHolder,
			noFont = true,
		}
	end

	local expandPreviewButton = Button:New {
		width = 100,
		right = 180,
		bottom = 10,
		height = 44,
		caption = "Preview",
		isHidden = true,
		classname = "option_button",
		parent = previewPanel,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		tooltip = "Open large map preview",
		OnClick = {
			function()
				if previewMapName then
					OpenExpandedPreview(previewMapName)
				end
			end
		},
	}

	local function SetPreviewMap(mapName)
		if not mapName then
			return
		end
		if lockedPreviewMapName and mapName ~= lockedPreviewMapName then
			return
		end
		if previewMapName == mapName then
			return
		end
		previewMapName = mapName
		local mapData = Configuration.gameConfig.mapDetails[mapName]
		local mapImageFile, needDownload = Configuration:GetMinimapImage(mapName)
		previewImage.file = mapImageFile
		previewImage.checkFileExists = needDownload
		previewImage:Invalidate()

		local titleText = mapName:gsub("_", " ")
		previewTitle:SetCaption(titleText)

		previewInfo:SetText(BuildPreviewInfoText(mapName, mapData))
	end

	local function LockPreviewMap(mapName)
		lockedPreviewMapName = nil
		SetPreviewMap(mapName)
		lockedPreviewMapName = mapName
		selectMapButton:Show()
		expandPreviewButton:Show()
	end

	local listHolder = Control:New {
		x = 20,
		right = 18,
		y = 293,
		bottom = 15,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		parent = mapListWindow,
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
	}

	local headings = {
		{name = "Name", tooltip = "Alphabetical order. You can also search by planet name (e.g. \"Kharros\", \"Jintram-7\", \"Osemo\", \"Jashenon\", etc.).", x = 0, width = 328 + nameShift, height = 66, noFilterButton = true},
		{name = "Size", tooltip = "Filtered by area bands: XS, S, M, L, XL, XXL, XXXL.\nBands are auto-derived from the map pool by area quantiles with lighter tails at the smallest/largest ends.", x = 332 + nameShift, width = 92},
		{name = "#", tooltip = "Ideal max playercount (in total).", x = 426 + nameShift, width = 41},
		{name = "Type", tooltip = "Each map is designed with a specific gameplay setup in mind, but can be played as you desire.\n- 1v1: Designed for small, competitive games\n- Teams: Has resources for multiple players\n- FFA: Free-for-all games", x = 469 + nameShift, width = 146},
		{name = "Terrain", tooltip = "Terrain & atmosphere tags drawn from map data and description.\nBase tags: flat, hills, water, metal, lava, tar, air, pve.\nFlavor tags (also text-searchable): grassland, snow, desert, lava, jungle, forest, canyon, ruins, wasteland, island, coastal, tidal, industrial, space, asymmetric, windy, chokepoints, speedzone.", x = 617 + nameShift, width = 166},
		{name = "Planet", tooltip = "Lore planet/category for this map where available.", x = 785 + nameShift, width = 126},
		{name = "", tooltip = "Whether the map archive is installed locally.", x = 982 + nameShift, width = 64, height = 66, imageSize = 24, noFilterButton = true, image = IMG_READY},
		{name = "", tooltip = "Favourited maps are prioritised and appear on top.", x = 913 + nameShift, width = 64, height = 66, imageSize = 24, noFilterButton = true, image = LUA_DIRNAME .. "widgets/chili/skins/Armada Blues/star_on.png"},
	}

	local headerSpacing = 3
	local spacedHeadings = {}
	for i = 1, #headings do
		local source = headings[i]
		local spacingReduction = math.min(headerSpacing, math.floor(source.width*0.35))
		spacedHeadings[i] = {
			name = source.name,
			tooltip = source.tooltip,
			x = source.x + math.floor(spacingReduction/2),
			width = math.max(8, source.width - spacingReduction),
			height = source.height,
			right = source.right,
			image = source.image,
			imageSize = source.imageSize,
		}
	end

	for i = 1, #headings do
		columnFilterState[i] = {
			optionOrder = {},
			hasOption = {},
			selected = {},
			optionCheckboxByValue = {},
			button = nil,
			popup = nil,
			toggleButton = nil,
		}
	end

	local function RegisterSortDataForFilters(sortData)
		for i = 1, #headings do
			if not headings[i].noFilterButton then
				local state = columnFilterState[i]
				if i == 5 then
					-- Terrain: register each individual tag so the filter shows
					-- single categories rather than combinatorial combinations.
					local terrainStr = GetFilterValueForColumn(sortData, i)
					if terrainStr == "-" then
						if not state.hasOption["-"] then
							state.hasOption["-"] = true
							state.optionOrder[#state.optionOrder + 1] = "-"
							state.selected["-"] = true
						end
					else
						for tag in terrainStr:gmatch("[^,]+") do
							tag = tag:match("^%s*(.-)%s*$")
							if tag ~= "" and not state.hasOption[tag] then
								state.hasOption[tag] = true
								state.optionOrder[#state.optionOrder + 1] = tag
								state.selected[tag] = true
								table.sort(state.optionOrder)
							end
						end
					end
				else
					local value = GetFilterValueForColumn(sortData, i)
					if not state.hasOption[value] then
						state.hasOption[value] = true
						state.optionOrder[#state.optionOrder + 1] = value
						state.selected[value] = true
						if i == 2 then
							table.sort(state.optionOrder, function(a, b)
								local rankA = SIZE_FILTER_RANK[a] or 999
								local rankB = SIZE_FILTER_RANK[b] or 999
								if rankA == rankB then
									return tostring(a) < tostring(b)
								end
								return rankA < rankB
							end)
						end
					end
				end
			end
		end
	end

	local mapScrollPanel = ScrollPanel:New {
		x = 0,
		right = 0,
		y = 72,
		bottom = 0,
		borderColor = {0, 0, 0, 0},
		horizontalScrollbar = false,
		parent = listHolder,
	}

	local featuredMapList = WG.CommunityWindow.LoadStaticCommunityData().MapItems or {}
	local featuredMapIndex = 1
	local mapFuncs = {}
	local mapList = WG.Chobby.SortableList(listHolder, spacedHeadings, 64, 1, true, mapScrollPanel, ItemInFilter)
	mapList.priorityList = favMaps

	local function ApplyColumnFilters()
		mapList:RecalculateDisplay()
	end

	local function UpdateFilterButtonCaption(columnIndex)
		local state = columnFilterState[columnIndex]
		if not state or not state.button then
			return
		end
		local total = #state.optionOrder
		local selected = 0
		for _, option in ipairs(state.optionOrder) do
			if state.selected[option] then
				selected = selected + 1
			end
		end
		if total == 0 or selected == total then
			state.button.caption = "All"
		elseif selected == 0 then
			state.button.caption = "None"
		else
			state.button.caption = selected .. "/" .. total
		end
		state.button:Invalidate()
		if state.toggleButton then
			state.toggleButton.caption = (selected == total) and "Deselect all" or "Select all"
			state.toggleButton:Invalidate()
		end
	end

	local function CloseFilterDropdown(columnIndex)
		local state = columnFilterState[columnIndex]
		if not state or not state.popup then
			return
		end
		state.popup:Dispose()
		state.popup = nil
		state.toggleButton = nil
		state.optionCheckboxByValue = {}
	end

	local filterBackdrop

	local function DisposeFilterBackdrop()
		if not filterBackdrop then
			return
		end
		filterBackdrop:Dispose()
		filterBackdrop = nil
	end

	CloseAllFilterDropdowns = function()
		for i = 1, #headings do
			CloseFilterDropdown(i)
		end
		DisposeFilterBackdrop()
	end

	local function ToggleAllInColumn(columnIndex, shouldSelect)
		local state = columnFilterState[columnIndex]
		if not state then
			return
		end
		for _, option in ipairs(state.optionOrder) do
			state.selected[option] = shouldSelect
			local checkbox = state.optionCheckboxByValue[option]
			if checkbox then
				checkbox:SetToggle(shouldSelect)
			end
		end
		UpdateFilterButtonCaption(columnIndex)
		ApplyColumnFilters()
	end

	local function OpenFilterDropdown(columnIndex)
		local heading = spacedHeadings[columnIndex]
		local state = columnFilterState[columnIndex]
		if not heading or not state then
			return
		end
		if state.popup then
			CloseFilterDropdown(columnIndex)
			DisposeFilterBackdrop()
			return
		end

		CloseAllFilterDropdowns()

		filterBackdrop = Control:New {
			x = 0,
			right = 0,
			y = 0,
			bottom = 0,
			parent = listHolder,
			noFont = true,
			noClickThrough = true,
			OnMouseDown = {
				function()
					CloseAllFilterDropdowns()
				end
			},
		}

		local popupWidth = math.max(180, heading.width + 30)
		local popupHeight = 250
		state.popup = Panel:New {
			x = heading.x,
			y = 70,
			width = popupWidth,
			height = popupHeight,
			padding = {4, 4, 4, 4},
			parent = listHolder,
			classname = "overlay_window",
			noClickThrough = true,
		}
		state.popup:BringToFront()

		state.toggleButton = Button:New {
			x = 4,
			right = 4,
			y = 4,
			height = 24,
			caption = "Select all",
			parent = state.popup,
			classname = "button_small",
			OnClick = {
				function()
					state.popup:BringToFront()
					local allSelected = true
					for _, option in ipairs(state.optionOrder) do
						if not state.selected[option] then
							allSelected = false
							break
						end
					end
					ToggleAllInColumn(columnIndex, not allSelected)
				end
			},
		}

		local optionsScroll = ScrollPanel:New {
			x = 4,
			right = 4,
			y = 32,
			bottom = 4,
			horizontalScrollbar = false,
			parent = state.popup,
		}

		for optionIndex, option in ipairs(state.optionOrder) do
			state.optionCheckboxByValue[option] = Checkbox:New {
				x = 4,
				right = 4,
				y = (optionIndex - 1) * 24 + 2,
				height = 22,
				caption = option,
				checked = state.selected[option],
				parent = optionsScroll,
				OnClick = {
					function(self)
						state.popup:BringToFront()
						state.selected[option] = self.checked
						UpdateFilterButtonCaption(columnIndex)
						ApplyColumnFilters()
					end
				},
			}
		end

		UpdateFilterButtonCaption(columnIndex)
	end

	for i = 1, #headings do
		if not headings[i].noFilterButton then
			columnFilterState[i].button = Button:New {
				x = spacedHeadings[i].x,
				y = 42,
				width = spacedHeadings[i].width,
				height = 24,
				caption = "All",
				objectOverrideFont = WG.Chobby.Configuration:GetFont(11),
				tooltip = "Filter " .. ((headings[i].name ~= "" and headings[i].name) or "column") .. " values",
				classname = "button_small",
				parent = listHolder,
				OnClick = {
					function()
						OpenFilterDropdown(i)
					end
				},
			}
		end
	end

	local pendingZoomToMap

	local function AddTheNextBatchOfMaps()
		local mapItems = {}
		local control, sortData
		for i = 1, loadRate do
			if featuredMapList[featuredMapIndex] then
				local mapName = featuredMapList[featuredMapIndex].Name
				control, sortData, mapFuncs[mapName] = CreateMapEntry(mapName, featuredMapList[featuredMapIndex], CloseFunc, function(newSortData)
					RegisterSortDataForFilters(newSortData)
					ApplyColumnFilters()
				end, SetPreviewMap, LockPreviewMap)
				local certification = sortData[8]
				if lobby.name == "singleplayer" or certification ~= "Unofficial" then
					RegisterSortDataForFilters(sortData)
					mapItems[#mapItems + 1] = {mapName, control, sortData}
				end
				featuredMapIndex = featuredMapIndex + 1
			end
		end
		mapList:AddItems(mapItems)
		for i = 1, #headings do
			UpdateFilterButtonCaption(i)
		end
		local addedmaps = {}
		if featuredMapList[featuredMapIndex] then
			WG.Delay(AddTheNextBatchOfMaps, 0.1)
		else
			for i, archive in pairs(VFS.GetAllArchives()) do
				local info = VFS.GetArchiveInfo(archive)
				if info and info.modtype == 3 and not mapFuncs[info.name] then
					addedmaps[info.name] = true
					control, sortData, mapFuncs[info.name] = CreateMapEntry(info.name, Configuration.gameConfig.mapDetails[info.name] , CloseFunc, function(newSortData)
						RegisterSortDataForFilters(newSortData)
						ApplyColumnFilters()
					end, SetPreviewMap, LockPreviewMap)
					local certification = sortData[8]
					if lobby.name == "singleplayer" or certification ~= "Unofficial" then
						RegisterSortDataForFilters(sortData)
						mapItems[#mapItems + 1] = {info.name, control, sortData}
					end
				end
			end
			mapList:AddItems(mapItems)
			for i = 1, #headings do
				UpdateFilterButtonCaption(i)
			end
		end
		for mapname, mapdetails in pairs(Configuration.gameConfig.mapDetails) do
			if addedmaps[mapname] == nil then
				control, sortData, mapFuncs[mapname] = CreateMapEntry(mapname, mapdetails , CloseFunc, function(newSortData)
					RegisterSortDataForFilters(newSortData)
					ApplyColumnFilters()
				end, SetPreviewMap, LockPreviewMap)
				local certification = sortData[8]
				if lobby.name == "singleplayer" or certification ~= "Unofficial" then
					RegisterSortDataForFilters(sortData)
					mapList:AddItem(mapname, control, sortData)
				end
			end
		end
		for i = 1, #headings do
			UpdateFilterButtonCaption(i)
		end
		mapList.sortBy = 9
		mapList:UpdateOrder()
		if not previewMapName and mapItems[1] then
			SetPreviewMap(mapItems[1][1])
		end

		-- Resolve deferred scroll if maps were still loading when Show() was called
		if pendingZoomToMap and mapFuncs[pendingZoomToMap] then
			mapList:ScrollToItem(pendingZoomToMap)
			if mapFuncs[pendingZoomToMap].ShowPreview then
				mapFuncs[pendingZoomToMap].ShowPreview()
			end
			pendingZoomToMap = nil
		end
	end

	local function FetchFavouriteMaps()
		--Clear table first
		for mapName, _ in pairs(favMaps) do
			favMaps[mapName] = nil
		end

		--Load new
		if VFS.FileExists(FILE_FAV_MAPS) then
			local favouriteMapsData = VFS.LoadFile(FILE_FAV_MAPS)
			local fileVersion --In which game version was file created (useful in case of changing file write/read structure in future)
			for mapName in string.gmatch(favouriteMapsData, "[^\r\n]+") do
				if fileVersion == nil then --First line will always be file version
					fileVersion = mapName
				else
					favMaps[mapName] = 1
				end
			end
		end --Otherwise -> no favourite maps/empty table
	end

	FetchFavouriteMaps()
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
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		classname = "negative_button",
		parent = mapListWindow,
		OnClick = {
			function()
				CloseFunc()
			end
		},
	}

	WG.Chobby.PriorityPopup(mapListWindow, CloseFunc)

	local btnOnlineMaps = Button:New {
		right = 286,
		y = 13,
		width = 180,
		height = 35,
		caption = i18n("download_maps"),
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		tooltip = i18n("download_maps_tooltip"),
		classname = "option_button",
		parent = mapListWindow,
		OnClick = {
			function ()
				WG.BrowserHandler.OpenUrl("https://www.beyondallreason.info/maps")
			end
		},
	}

	-------------------------
	-- Filtering
	-------------------------

	local ebFilter = EditBox:New {
		right = 102,
		y = 14,
		width = 180,
		height = 33,
		text = '',
		hint = i18n("mapsearch_hint"),
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		objectOverrideHintFont = WG.Chobby.Configuration:GetFont(11),
		parent = mapListWindow,
		OnKeyPress = {
			function(obj, key, ...)
				if key ~= Spring.GetKeyCode("enter") and key ~= Spring.GetKeyCode("numpad_enter") then
					return
				end
				local visibleItemIds = mapList:GetVisibleItemIds()
				if visibleItemIds[1] and #visibleItemIds[1] and lobby then
					lobby:SelectMap(visibleItemIds[1])
					CloseFunc()
				end
			end
		},
		OnTextModified = {
			function (self)
				local lower = string.lower(self.text)
				filterTerms = lower:split(" ")
				filterQuery = lower:gsub("%s+", "")
				CloseAllFilterDropdowns()
				mapList:RecalculateDisplay()
			end
		}
	}

	-------------------------
	-- External Funcs
	-------------------------

	local externalFunctions = {}

	function externalFunctions.Show(zoomToMap)
		CloseAllFilterDropdowns()
		ebFilter:Clear()
		mapList:RecalculateDisplay()
		lockedPreviewMapName = nil
		selectMapButton:Hide()
		expandPreviewButton:Hide()

		if not mapListWindow.visible then
			mapListWindow:Show()
		end
      
		WG.Chobby.PriorityPopup(mapListWindow, CloseFunc)
		if zoomToMap then
			if mapFuncs[zoomToMap] then
				mapList:ScrollToItem(zoomToMap)
				if mapFuncs[zoomToMap].ShowPreview then
					mapFuncs[zoomToMap].ShowPreview()
				end
			else
				-- Maps may still be loading; defer scroll until ready
				pendingZoomToMap = zoomToMap
			end
		elseif not previewMapName then
			local visibleItemIds = mapList:GetVisibleItemIds()
			if visibleItemIds[1] then
				SetPreviewMap(visibleItemIds[1])
			end
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

	function externalFunctions.Dispose()
		mapListWindow:Dispose()
	end

	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- External Interface

local MapListPanel = {}

function MapListPanel.Show(newLobby, zoomToMap)
	local redraw = false
	if lobby == nil or ((lobby.name == "singleplayer" and newLobby.name ~= "singleplayer" ) or (
		lobby.name ~= "singleplayer" and newLobby.name == "singleplayer" )) then
		redraw = true
	end
	lobby = newLobby
	loadRate = 40
	if redraw and mapListWindow then
		Spring.Echo("Remaking mapListWindow")
		mapListWindow:Dispose()
		mapListWindow = InitializeControls()
	end
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
