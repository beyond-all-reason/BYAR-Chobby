function widget:GetInfo()
	return {
		name      = "Terraformer Launcher",
		desc      = "Launches straight into the terraform brush on a chosen map.",
		author    = "",
		date      = "2026",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true,
	}
end

local TerraformerWindow = {}

local selectedMap
local selectedProject
local listMode = "maps" -- "maps" | "projects"
-- Matches #LOAD_PHASES in cmd_map_project.lua; the pointer carries it for progress reporting.
local PROJECT_LOAD_PHASES = 11
-- Declared up here because Launch, below, reports download and launch state, and all three are
-- defined further down with the row rendering.
local downloading = {}
local RefreshRowStatus
local startButton


-- Projects live in the write dir as MapProjects/<slug>/project.lua, a plain Lua table. The
-- terraformer owns their format; this only reads the few fields needed to list them.
local function ListProjects()
	local out = {}
	local dirs = VFS.SubDirs("MapProjects/", "*", VFS.RAW) or {}
	for i = 1, #dirs do
		local dir = dirs[i]
		local raw = VFS.LoadFile(dir .. "project.lua", VFS.RAW)
		if raw then
			local chunk = loadstring(raw)
			local ok, manifest = pcall(chunk)
			if ok and type(manifest) == "table" and manifest.map then
				local slug = dir:match("([^/\\]+)[/\\]*$")
				out[#out + 1] = {
					slug = slug,
					name = manifest.name or slug,
					sourceMap = manifest.map.source_map,
					sizeX = manifest.map.size_x,
					sizeZ = manifest.map.size_z,
					baseHeight = manifest.map.base_height,
					baseColor = manifest.map.base_color,
					dnts = manifest.map.dnts,
					skybox = manifest.map.skybox,
					modified = manifest.modified,
				}
			end
		end
	end

	return out
end

-- Manifests record modified as a fixed-width UTC ISO stamp, which sorts lexically. Only the
-- display goes through the local-time conversion; the raw string stays the sort key.
local function FormatModified(iso)
	if not iso then
		return "-"
	end

	local t = Spring.Utilities.UtcToLocal(iso)
	if not t then
		return iso
	end

	return string.format("%04d-%02d-%02d %02d:%02d", t[6], t[5], t[4], t[3], t[2])
end

-- Values the terraformer's own New Map path uses; a project load overwrites the terrain
-- anyway, so these only decide what the canvas looks like for the moment before it streams in.
local NEWMAP_BASE_HEIGHT = 100
local NEWMAP_COLOR = { 110, 130, 90 }

-- The terraformer reads this on the next session and streams the project into the blank map.
-- Writing it here rather than routing through WG.MapProject.open is what keeps this to a
-- single launch: that path rewrites the RUNNING game's script and restarts, which would throw
-- away the editor setup this script carries.
local function WritePendingProject(entry)
	Spring.CreateDir("Terraform Brush")
	local file = io.open("Terraform Brush/pending_project.lua", "w")
	if not file then
		return false
	end
	file:write(string.format(
		"return { path = %q, size_x = %d, size_z = %d, phase = 0, phases = %d }",
		"MapProjects/" .. entry.slug .. "/",
		entry.sizeX,
		entry.sizeZ,
		PROJECT_LOAD_PHASES
	))
	file:close()

	return true
end

-- A blank canvas ships no SSMF splat textures, so the detail normals the project was captured
-- with have to be handed to the generator or the terrain loads as flat diffuse. The project
-- carries its own copies under assets/, which is why these resolve against the project rather
-- than the shared library.
local function BuildSplatKeys(entry)
	local dnts = entry.dnts
	if type(dnts) ~= "table" then
		return {}
	end

	local prefix = "MapProjects/" .. entry.slug .. "/"
	local textures = type(dnts.textures) == "table" and dnts.textures or {}
	local scales = dnts.scales or {}
	local mults = dnts.mults or {}

	local keys = {}
	for ch = 1, 4 do
		local texture = textures[ch]
		if type(texture) == "string" and texture ~= "" then
			keys[#keys + 1] = "blank_map_splatdetailnormaltex" .. ch .. "=" .. prefix .. texture .. ";"
			keys[#keys + 1] = "blank_map_splattexscale" .. ch .. "=" .. (scales[ch] or 0.01) .. ";"
			keys[#keys + 1] = "blank_map_splattexmult" .. ch .. "=" .. (mults[ch] or 1.0) .. ";"
		end
	end

	-- Older SMFReadMap paths only switch splats on when a detail texture is present, even where
	-- the normals are the real source, so channel 1 stands in when the project captured none.
	local detail = dnts.detail or textures[1]
	if type(detail) == "string" and detail ~= "" then
		keys[#keys + 1] = "blank_map_splatdetailtex=" .. prefix .. detail .. ";"
	end

	if #keys > 0 then
		local diffuseAlpha = (tonumber(dnts.diffuse_alpha) == 1) and 1 or 0
		keys[#keys + 1] = "blank_map_splatdetailnormaldiffusealpha=" .. diffuseAlpha .. ";"
	end

	return keys
end

-- Manifests record only the skybox's file name, so it has to be found in the library again.
local function FindSkybox(name)
	if type(name) ~= "string" or name == "" then
		return nil
	end

	local files = VFS.DirList("Terraform Brush/SkyBoxes/", "*.dds", VFS.RAW_FIRST) or {}
	for i = 1, #files do
		local file = files[i]:gsub("\\", "/")
		if file:match("([^/]+)$") == name then
			return file
		end
	end

	Spring.Echo("[Map Editor] Project skybox '" .. name .. "' is not in the library; launching without one.")

	return nil
end

-- Game-scope keys and the [mapoptions] block the engine needs to synthesise a blank map.
-- The name keeps the "Editor Flat WxH" prefix the terraformer's own matchers look for, and
-- carries a timestamp because reusing a generated map name can resolve to a stale archive
-- cache entry.
local function BuildBlankMapKeys(entry, seed)
	local color = entry.baseColor or NEWMAP_COLOR

	local options = {
		"blank_map_x=" .. entry.sizeX .. ";",
		"blank_map_y=" .. entry.sizeZ .. ";",
		"blank_map_height=" .. (tonumber(entry.baseHeight) or NEWMAP_BASE_HEIGHT) .. ";",
		"blank_map_color_r=" .. color[1] .. ";",
		"blank_map_color_g=" .. color[2] .. ";",
		"blank_map_color_b=" .. color[3] .. ";",
	}

	local skybox = FindSkybox(entry.skybox)
	if skybox then
		options[#options + 1] = "blank_map_skybox=" .. skybox .. ";"
	end

	local splat = BuildSplatKeys(entry)
	for i = 1, #splat do
		options[#options + 1] = splat[i]
	end

	for i = 1, #options do
		options[i] = "\t\t" .. options[i]
	end

	return table.concat({
		"\tInitBlank=1;",
		"\tMapSeed=" .. seed .. ";",
		"",
		"\t[mapoptions]",
		"\t{",
		table.concat(options, "\n"),
		"\t}",
	}, "\n")
end

-- No teams at all: the start unit is spawned per team, so declaring none is what keeps the
-- canvas clear. The player joins as a spectator, which is the only way to be in a game with
-- no teams to belong to. deathmode=neverend still matters, as an empty game ends instantly.
local function BuildStartScript(mapName, projectEntry, blankSeed)
	local Configuration = WG.Chobby.Configuration
	local gameName = Configuration:GetDefaultGameName()
	if not gameName then
		return nil, "no game version available"
	end
	if string.find(gameName, ":") and not string.find(gameName, "rapid://") then
		gameName = "rapid://" .. gameName
	end

	local playerName = Configuration:GetPlayerName()

	return table.concat({
		"[GAME]",
		"{",
		"\tMapname=" .. mapName .. ";",
		"\tGameType=" .. gameName .. ";",
		"\tMyPlayerName=" .. playerName .. ";",
		"\tIsHost=1;",
		"\tHostIP=127.0.0.1;",
		"\tHostPort=0;",
		"\tNoHelperAIs=0;",
		"\tGameStartDelay=0;",
		projectEntry and BuildBlankMapKeys(projectEntry, blankSeed) or "",
		"",
		"\t[MODOPTIONS]",
		"\t{",
		"\t\tdeathmode=neverend;",
		"\t\tmapeditor=1;",
		"\t}",
		"",
		"\tNumPlayers=1;",
		"\tNumTeams=0;",
		"\tNumAllyTeams=0;",
		"",
		"\t[PLAYER0]",
		"\t{",
		"\t\tName=" .. playerName .. ";",
		"\t\tSpectator=1;",
		"\t}",
		"}",
	}, "\n")
end

local function Launch()
	local Configuration = WG.Chobby.Configuration
	local mapName, projectEntry, blankSeed

	if listMode == "projects" then
		if not selectedProject then
			Spring.Echo("[Map Editor] Pick a project first.")
			return
		end
		projectEntry = selectedProject
		if not (selectedProject.sizeX and selectedProject.sizeZ) then
			Spring.Echo("[Map Editor] Project manifest has no map size.")
			return
		end
		os.remove("Terraform Brush/pending_newmap.lua")
		os.remove("Terraform Brush/pending_newmap_env.lua")

		if not WritePendingProject(selectedProject) then
			Spring.Echo("[Map Editor] Could not write the pending-project pointer.")
			return
		end
		-- The engine synthesises this map from the blank_map options; the name only has to keep
		-- the prefix the terraformer matches on, and be unique so it cannot hit a stale archive
		-- cache entry.
		blankSeed = os.time()
		mapName = string.format("Editor Flat %dx%d s%d", selectedProject.sizeX, selectedProject.sizeZ, blankSeed)
	else
		if not selectedMap then
			Spring.Echo("[Map Editor] Pick a map first.")
			return
		end
		if not VFS.HasArchive(selectedMap) then
			if not (WG.DownloadHandler and WG.DownloadHandler.MaybeDownloadArchive) then
				Spring.Echo("[Map Editor] No download handler available.")
				return
			end
			downloading[selectedMap] = true
			WG.DownloadHandler.MaybeDownloadArchive(selectedMap, "map", -1)
			RefreshRowStatus(selectedMap)
			Spring.Echo("[Map Editor] Downloading " .. selectedMap .. " ...")
			return
		end
		mapName = selectedMap
	end

	local script, err = BuildStartScript(mapName, projectEntry, blankSeed)
	if not script then
		Spring.Echo("[Map Editor] Cannot launch: " .. tostring(err))
		return
	end

	if startButton then
		startButton:SetEnabled(false)
		startButton:SetCaption("Starting")
	end

	-- The same two paths skirmish takes: hand the script to the wrapper where that is how this
	-- install starts games, otherwise reload this engine onto it.
	if
		Configuration.multiplayerLaunchNewSpring
		and WG.WrapperLoopback
		and WG.WrapperLoopback.StartNewSpring
		and WG.SettingsWindow
	then
		WG.WrapperLoopback.StartNewSpring({
			StartScriptContent = script,
			Engine = Configuration:GetTruncatedEngineVersion(),
			SpringSettings = WG.SettingsWindow.GetSettingsString(),
		})
		return
	end

	Spring.Echo("[Map Editor] Launching " .. (projectEntry and projectEntry.slug or mapName) .. " ...")
	WG.Delay(function()
		Spring.Reload(script)
	end, 0.4)
end

local ROW_HEIGHT = 64
local IMG_HAVE = LUA_DIRNAME .. "images/downloadready.png"
local IMG_MISSING = LUA_DIRNAME .. "images/downloadnotready.png"
-- No third icon ships for "in progress", so the missing one is tinted amber instead.
local TINT_IDLE = {1, 1, 1, 1}
local TINT_BUSY = {1, 0.8, 0.2, 1}

local FOOTER_HEIGHT = 60

-- One spec drives both the heading buttons and the row cells, so a cell can never sit anywhere
-- but under its own heading. Edges are percentages because the panel is as wide as the lobby
-- window: fixed pixel columns would leave the table bunched on the left of a big screen. The
-- gaps between the percentages are what stops adjacent heading buttons touching.
--
-- Heading captions are centred by the button skin, so cells centre too; the leading name column
-- is the exception, since it reads as the row's label rather than as a value.
local MAP_COLUMNS = {
	{name = "Name", x = "0%", right = "70%", align = "left"},
	{name = "Size", x = "30.5%", right = "61%"},
	{name = "Players", x = "39.5%", right = "54%", tooltip = "Ideal player count in total"},
	{name = "Teams", x = "46.5%", right = "47%"},
	{name = "Type", x = "53.5%", right = "34%"},
	{name = "Terrain", x = "66.5%", right = "11%"},
	{name = "Status", x = "89.5%", right = "0%", tooltip = "Whether the map archive is installed locally"},
}

local PROJECT_COLUMNS = {
	{name = "Project", x = "0%", right = "58%", align = "left"},
	{name = "Captured from", x = "42.5%", right = "34%"},
	{name = "Size", x = "66.5%", right = "24%"},
	{name = "Modified", x = "76.5%", right = "0%"},
}

local COLUMN_MODIFIED = 4
local COLUMN_STATUS = #MAP_COLUMNS

local rows = {}
local projectRows = {}
local filterText = ""
local mapList
local SetSelectedForward
-- LuaMenu survives Spring.Reload, so the panel built on first show outlives every editor
-- session launched from it. Assigned in InitializeControls, called on the way back.
local RefreshProjects

-- One entry per column between Name and Status, in that order. Sort values are kept apart from
-- the captions so the counts order by magnitude rather than by how they read.
local function DescribeMap(data)
	data = data or {}

	local width = tonumber(data.Width)
	local height = tonumber(data.Height)
	local players = tonumber(data.PlayerCount)
	local teams = tonumber(data.TeamCount)

	local kinds = {}
	if data.Is1v1 then
		kinds[#kinds + 1] = "1v1"
	end
	if data.IsTeam then
		kinds[#kinds + 1] = "Team"
	end
	if data.IsFFA then
		kinds[#kinds + 1] = "FFA"
	end

	local terrain = {}
	if data.Flat then
		terrain[#terrain + 1] = "Flat"
	end
	if data.Hills then
		terrain[#terrain + 1] = "Hills"
	end
	if data.Water then
		terrain[#terrain + 1] = "Water"
	end
	if data.Special then
		terrain[#terrain + 1] = data.Special
	end

	local kindText = table.concat(kinds, "/")
	local terrainText = table.concat(terrain, " ")

	return {
		{caption = (width and height) and (width .. "x" .. height) or "-", sort = (width or 0) * (height or 0)},
		{caption = players and tostring(players) or "-", sort = players or 0},
		{caption = teams and tostring(teams) or "-", sort = teams or 0},
		{caption = kindText ~= "" and kindText or "-", sort = kindText:lower()},
		{caption = terrainText ~= "" and terrainText or "-", sort = terrainText:lower()},
	}
end

-- Sorted as text so the Status heading orders installed maps first, then in-flight, then the rest.
local function StatusSortKey(mapName)
	if VFS.HasArchive(mapName) then
		return "1 installed"
	end

	return downloading[mapName] and "2 downloading" or "3 not downloaded"
end

local function Highlight(button, chosen)
	if chosen then
		ButtonUtilities.SetButtonSelected(button)
	else
		ButtonUtilities.SetButtonDeselected(button)
	end
end

local function SetSelectedProject(entry)
	selectedProject = entry
	for i = 1, #projectRows do
		Highlight(projectRows[i].button, projectRows[i].entry == entry)
	end

	if startButton then
		startButton:SetEnabled(entry ~= nil)
		startButton:SetCaption("Start")
	end
end

SetSelectedForward = function(mapName)
	selectedMap = mapName
	for i = 1, #rows do
		Highlight(rows[i].button, rows[i].mapName == mapName)
	end

	if not startButton then
		return
	end

	local busy = mapName and downloading[mapName]
	startButton:SetEnabled(mapName ~= nil and not busy)
	-- mapDetails lists every map the lobby knows of, most of them not downloaded. Rather
	-- than hide those, the button offers to fetch the one you picked.
	local have = mapName and VFS.HasArchive(mapName)
	if busy then
		startButton:SetCaption("Downloading...")
	else
		startButton:SetCaption((mapName and not have) and "Download" or "Start")
	end
end

-- Row shell both lists are built on: the panel is what the list positions, the button inside
-- it is what takes the click and carries the selected tint.
local function CreateRow(OnPick, OnLaunch)
	local root = Panel:New {
		x = 0,
		y = 0,
		width = "100%",
		height = ROW_HEIGHT,
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
		noFont = true,
	}

	local button = Button:New {
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		caption = "",
		classname = "battle_default_button",
		padding = {0, 0, 0, 0},
		parent = root,
		OnClick = { OnPick },
		OnDblClick = { OnLaunch },
	}

	return root, button
end

-- Contents are built on first parent, not in GetControl: that runs while Configuration is
-- still being constructed (the game config includes this file), so Configuration:GetFont has
-- no font table yet. Same deferral the scenario window uses.
local function InitializeControls(parent)
	local Configuration = WG.Chobby.Configuration

	Label:New {
		parent = parent,
		x = 15,
		right = 5,
		y = 17,
		height = 20,
		caption = "Map Editor",
		objectOverrideFont = Configuration:GetFont(3),
	}

	local mapsTab, projectsTab

	local searchBox = EditBox:New {
		parent = parent,
		x = 400,
		right = 147,
		y = 11,
		height = 37,
		text = "",
		hint = "Search",
		objectOverrideFont = Configuration:GetFont(2),
		objectOverrideHintFont = Configuration:GetFont(11),
	}

	-- The maps list comes from a static config, so only the projects list has anything to rescan.
	local refreshButton = Button:New {
		parent = parent,
		right = 15,
		y = 7,
		width = 120,
		height = 45,
		caption = i18n("refresh"),
		classname = "option_button",
		objectOverrideFont = Configuration:GetFont(2),
		tooltip = "Rescan the MapProjects folder",
		OnClick = {
			function()
				RefreshProjects()
			end,
		},
	}

	local mapHolder = Control:New {
		parent = parent,
		x = 12,
		right = 15,
		y = 62,
		bottom = FOOTER_HEIGHT,
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
	}

	local projectHolder = Control:New {
		parent = parent,
		x = 12,
		right = 15,
		y = 62,
		bottom = FOOTER_HEIGHT,
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
	}

	-- Sort fields hold whatever each column orders by, counts included, so the text to match a
	-- query against rides alongside them under its own key.
	local function ItemInFilter(sortData)
		return filterText == "" or (sortData.search or ""):find(filterText, 1, true) ~= nil
	end

	mapList = WG.Chobby.SortableList(mapHolder, MAP_COLUMNS, ROW_HEIGHT, 1, true, nil, ItemInFilter)

	local projectList =
		WG.Chobby.SortableList(projectHolder, PROJECT_COLUMNS, ROW_HEIGHT, COLUMN_MODIFIED, false, nil, ItemInFilter)

	-- Same source the map browser uses. VFS.GetMaps is not it: the lobby knows maps through
	-- the generated mapDetails config, which is also what carries their metadata.
	local maps = {}
	for mapName in pairs(Configuration.gameConfig.mapDetails or {}) do
		maps[#maps + 1] = mapName
	end
	table.sort(maps)

	rows = {}
	local mapItems = {}
	for i = 1, #maps do
		local mapName = maps[i]
		local data = Configuration.gameConfig.mapDetails[mapName]
		local root, button = CreateRow(function()
			SetSelectedForward(mapName)
		end, function()
			SetSelectedForward(mapName)
			Launch()
		end)

		local minimap = Panel:New {
			name = "minimap",
			x = 3,
			y = 3,
			width = ROW_HEIGHT - 6,
			height = ROW_HEIGHT - 6,
			padding = {1, 1, 1, 1},
			parent = button,
		}

		local mapImageFile, needDownload = Configuration:GetMinimapImage(mapName)
		Image:New {
			x = 0,
			y = 0,
			right = 0,
			bottom = 0,
			file = mapImageFile,
			fallbackFile = Configuration:GetLoadingImage(3),
			checkFileExists = needDownload,
			parent = minimap,
		}

		Label:New {
			parent = button,
			x = ROW_HEIGHT + 6,
			y = 0,
			right = MAP_COLUMNS[1].right,
			height = ROW_HEIGHT,
			align = MAP_COLUMNS[1].align,
			autosize = false,
			valign = "center",
			caption = mapName,
			objectOverrideFont = Configuration:GetFont(3),
		}

		local sortData = {mapName:lower()}
		local searchable = {mapName:lower()}

		local facts = DescribeMap(data)
		for f = 1, #facts do
			local column = MAP_COLUMNS[f + 1]
			Label:New {
				parent = button,
				x = column.x,
				y = 0,
				right = column.right,
				height = ROW_HEIGHT,
				align = column.align or "center",
				autosize = false,
				valign = "center",
				caption = facts[f].caption,
				objectOverrideFont = Configuration:GetFont(1),
			}
			sortData[f + 1] = facts[f].sort
			searchable[#searchable + 1] = facts[f].caption:lower()
		end

		-- An icon rather than the words: the browser uses these same two for exactly this.
		-- keepAspect is what centres it in the column, since the image spans the whole cell.
		local statusColumn = MAP_COLUMNS[COLUMN_STATUS]
		local statusImage = Image:New {
			parent = button,
			x = statusColumn.x,
			y = math.floor((ROW_HEIGHT - 20) / 2),
			right = statusColumn.right,
			height = 20,
			keepAspect = true,
			file = VFS.HasArchive(mapName) and IMG_HAVE or IMG_MISSING,
			tooltip = VFS.HasArchive(mapName) and "Installed" or "Not downloaded",
		}

		sortData[COLUMN_STATUS] = StatusSortKey(mapName)
		sortData.search = table.concat(searchable, " ")
		rows[i] = {
			button = button,
			status = statusImage,
			mapName = mapName,
			sortData = sortData,
		}
		mapItems[i] = {mapName, root, sortData}
	end
	mapList:AddItems(mapItems)

	local function BuildProjectItems()
		projectRows = {}
		local projects = ListProjects()
		local projectItems = {}
		for i = 1, #projects do
			local entry = projects[i]
			local root, button = CreateRow(function()
				SetSelectedProject(entry)
			end, function()
				SetSelectedProject(entry)
				Launch()
			end)

			local sourceMap = entry.sourceMap or "-"
			local cells = {
				{caption = entry.name, font = 3},
				{caption = sourceMap, font = 1},
				{caption = string.format("%dx%d", entry.sizeX or 0, entry.sizeZ or 0), font = 1},
				{caption = FormatModified(entry.modified), font = 1},
			}
			for c = 1, #cells do
				local column = PROJECT_COLUMNS[c]
				Label:New {
					parent = button,
					x = column.x,
					y = 0,
					right = column.right,
					height = ROW_HEIGHT,
					align = column.align or "center",
					autosize = false,
					valign = "center",
					caption = cells[c].caption,
					objectOverrideFont = Configuration:GetFont(cells[c].font),
				}
			end

			local sortData = {
				entry.name:lower(),
				sourceMap:lower(),
				(entry.sizeX or 0) * (entry.sizeZ or 0),
				entry.modified or "",
			}
			sortData.search = entry.name:lower() .. " " .. sourceMap:lower()

			projectRows[i] = {button = button, entry = entry}
			projectItems[i] = {entry.slug, root, sortData}
		end

		return projectItems
	end

	projectList:AddItems(BuildProjectItems())

	startButton = Button:New {
		parent = parent,
		right = 15,
		bottom = 8,
		width = 160,
		height = 45,
		caption = "Start",
		classname = "action_button",
		objectOverrideFont = Configuration:GetFont(3),
		OnClick = { Launch },
	}

	local function ApplyFilter()
		mapList:RecalculateDisplay()
		projectList:RecalculateDisplay()
	end

	local function SetMode(mode)
		listMode = mode
		mapHolder:SetVisibility(mode == "maps")
		projectHolder:SetVisibility(mode == "projects")
		refreshButton:SetVisibility(mode == "projects")
		Highlight(mapsTab, mode == "maps")
		Highlight(projectsTab, mode == "projects")
		if mode == "maps" then
			SetSelectedForward(selectedMap)
		else
			SetSelectedProject(selectedProject)
		end
	end

	-- Rows carry the manifest table they were built from, and selection is identity on that
	-- table, so the pick has to be re-resolved by slug against the rebuilt rows.
	RefreshProjects = function()
		local selectedSlug = selectedProject and selectedProject.slug

		projectList:Clear()
		projectList:AddItems(BuildProjectItems())

		selectedProject = nil
		for i = 1, #projectRows do
			if projectRows[i].entry.slug == selectedSlug then
				selectedProject = projectRows[i].entry
				break
			end
		end

		SetMode(listMode)
	end

	mapsTab = Button:New {
		parent = parent,
		x = 150,
		y = 7,
		width = 110,
		height = 45,
		caption = "Maps",
		classname = "option_button",
		objectOverrideFont = Configuration:GetFont(2),
		OnClick = {
			function()
				SetMode("maps")
			end,
		},
	}

	-- Projects are the terraformer's own saves; keeping them on a separate list avoids implying
	-- a project is just another map, which it is not (it restarts into a blank canvas).
	projectsTab = Button:New {
		parent = parent,
		x = 266,
		y = 7,
		width = 110,
		height = 45,
		caption = "Projects",
		classname = "option_button",
		objectOverrideFont = Configuration:GetFont(2),
		OnClick = {
			function()
				SetMode("projects")
			end,
		},
	}

	SetMode(listMode)

	-- One handler only. Hooking both OnKeyPress and OnTextInput ran the filter twice per key.
	searchBox.OnKeyPress = searchBox.OnKeyPress or {}
	searchBox.OnKeyPress[#searchBox.OnKeyPress + 1] = function(obj)
		filterText = (obj.text or ""):lower()
		ApplyFilter()
	end
end

function TerraformerWindow.GetControl()
	return Control:New {
		name = "terraformerWindow",
		x = "0%",
		y = "0%",
		width = "100%",
		height = "100%",
		padding = {0, 0, 0, 0},
		OnParent = {
			function(obj)
				if obj:IsEmpty() then
					InitializeControls(obj)
				end
			end,
		},
	}
end

-- Without this the button keeps reading Download after the map has arrived, until the user
-- reselects it.
RefreshRowStatus = function(mapName)
	for i = 1, #rows do
		local row = rows[i]
		if row.mapName == mapName and row.status then
			local have = VFS.HasArchive(mapName)
			local busy = downloading[mapName]
			row.status.file = have and IMG_HAVE or IMG_MISSING
			row.status.color = busy and TINT_BUSY or TINT_IDLE
			row.status.tooltip = (busy and "Downloading...")
				or (have and "Installed")
				or "Not downloaded"
			row.status:Invalidate()

			row.sortData[COLUMN_STATUS] = StatusSortKey(mapName)
			mapList:UpdateItemSorting(mapName, row.sortData)
		end
	end
	if mapName == selectedMap then
		SetSelectedForward(selectedMap)
	end
end

local function OnDownloadStarted(_, _, thingName)
	if thingName and downloading[thingName] ~= nil then
		downloading[thingName] = true
		RefreshRowStatus(thingName)
	end
end

local function OnDownloadFinished(_, _, thingName)
	if thingName then
		downloading[thingName] = nil
		RefreshRowStatus(thingName)
	end
end

local function OnDownloadFailed(_, _, _, thingName)
	if thingName then
		downloading[thingName] = nil
		RefreshRowStatus(thingName)
		Spring.Echo("[Map Editor] Download failed: " .. tostring(thingName))
	end
end

function widget:ActivateMenu()
	if RefreshProjects then
		RefreshProjects()
	end
end

function widget:Initialize()
	CHOBBY_DIR = LUA_DIRNAME .. "widgets/chobby/"
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	WG.DownloadHandler.AddListener("DownloadStarted", OnDownloadStarted)
	WG.DownloadHandler.AddListener("DownloadFinished", OnDownloadFinished)
	WG.DownloadHandler.AddListener("DownloadFailed", OnDownloadFailed)

	WG.TerraformerWindow = TerraformerWindow
end
