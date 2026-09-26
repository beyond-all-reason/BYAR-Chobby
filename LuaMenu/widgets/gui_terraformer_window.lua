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
local listMode = "maps"
-- Must match #LOAD_PHASES in the game's cmd_map_project.lua.
local PROJECT_LOAD_PHASES = 11
local downloading = {}
local RefreshRowStatus
local startButton
-- Chili delivers a row's OnClick alongside its OnDblClick, so the launch has to lock the caption.
local launching = false


local PROJECTS_DIR = "MapProjects/"

-- Walks into folders, since the terraformer files projects under them, and the slug carries
-- the path because that is what the pointer and the DNTS paths are built from.
local function ListProjects()
	local out = {}
	local pending = {PROJECTS_DIR}
	while #pending > 0 do
		local dir = table.remove(pending)
		local raw = VFS.LoadFile(dir .. "project.lua", VFS.RAW)
		if raw then
			local chunk = loadstring(raw)
			local ok, manifest = pcall(chunk)
			if ok and type(manifest) == "table" and manifest.map then
				local slug = dir:gsub("^" .. PROJECTS_DIR, ""):gsub("/$", "")
				out[#out + 1] = {
					slug = slug,
					folder = slug:match("^(.*)/[^/]+$"),
					name = manifest.name or slug:match("([^/]+)$") or slug,
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
		else
			local subs = VFS.SubDirs(dir, "*", VFS.RAW) or {}
			for i = 1, #subs do
				pending[#pending + 1] = subs[i]:gsub("\\", "/"):gsub("/*$", "") .. "/"
			end
		end
	end

	return out
end

-- Manifests record modified as a fixed-width UTC ISO stamp, so the raw string sorts lexically.
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

-- Mirrors the defaults the terraformer's own New Map path uses, including the even-only
-- sizes its sliders snap to.
local NEWMAP_BASE_HEIGHT = 100
local NEWMAP_COLOR = { 110, 130, 90 }
local NEWMAP_SIZE = 12
local NEWMAP_MIN_SIZE = 4
local NEWMAP_MAX_SIZE = 32

local NEW_PROJECT = {
	slug = "\0newmap",
	name = "New Map",
	sizeX = NEWMAP_SIZE,
	sizeZ = NEWMAP_SIZE,
	isNew = true,
}

local NEWMAP_SIZES = {}
for size = NEWMAP_MIN_SIZE, NEWMAP_MAX_SIZE, 2 do
	NEWMAP_SIZES[#NEWMAP_SIZES + 1] = tostring(size)
end

local function SizeToItem(size)
	return (size - NEWMAP_MIN_SIZE) / 2 + 1
end

local UpdateNewMapControls

-- Bypasses WG.MapProject.open, which restarts a running game and loses the editor setup.
local function WritePendingProject(entry)
	Spring.CreateDir("Terraform Brush")
	local file = io.open("Terraform Brush/pending_project.lua", "w")
	if not file then
		return false
	end
	file:write(string.format(
		"return { path = %q, size_x = %d, size_z = %d, phase = 0, phases = %d }",
		PROJECTS_DIR .. entry.slug .. "/",
		entry.sizeX,
		entry.sizeZ,
		PROJECT_LOAD_PHASES
	))
	file:close()

	return true
end

-- The terraformer reads an existing but empty recipe as "flat map, default environment", where a
-- missing one leaves whatever the last session wrote in place.
local function WriteNewMapRecipe()
	Spring.CreateDir("Terraform Brush")
	os.remove("Terraform Brush/pending_project.lua")

	for _, name in ipairs({"pending_newmap.lua", "pending_newmap_env.lua"}) do
		local file = io.open("Terraform Brush/" .. name, "w")
		if not file then
			return false
		end
		file:close()
	end

	return true
end

-- A blank canvas ships no SSMF splat textures, so without these the terrain loads as flat diffuse.
local function BuildSplatKeys(entry)
	local dnts = entry.dnts
	if type(dnts) ~= "table" then
		return {}
	end

	local prefix = PROJECTS_DIR .. entry.slug .. "/"
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

	-- Older SMFReadMap paths only switch splats on when a detail texture is present.
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

-- The game spawns a start unit per team, and an empty game ends instantly without neverend.
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
	-- Chobby stays up alongside the editor, and the panel is reachable again while it runs.
	if launching then
		return
	end

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

		if selectedProject.isNew then
			if not WriteNewMapRecipe() then
				Spring.Echo("[Map Editor] Could not clear the pending New Map recipe.")
				return
			end
		else
			os.remove("Terraform Brush/pending_newmap.lua")
			os.remove("Terraform Brush/pending_newmap_env.lua")

			if not WritePendingProject(selectedProject) then
				Spring.Echo("[Map Editor] Could not write the pending-project pointer.")
				return
			end
		end
		-- Keeps the prefix the terraformer matches on; the stamp dodges a stale archive cache entry.
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

	launching = true
	if startButton then
		startButton:SetEnabled(false)
		startButton:SetCaption("Running")
	end
	if UpdateNewMapControls then
		UpdateNewMapControls()
	end

	-- The same two paths skirmish takes.
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
-- Points down as drawn, so ascending flips it.
local IMG_SORT_ARROW = LUA_DIRNAME .. "widgets/chili/skins/Armada Blues/combobox_ctrl_arrow.png"
-- No third icon ships for "in progress", so the missing one is tinted amber instead.
local TINT_IDLE = {1, 1, 1, 1}
local TINT_BUSY = {1, 0.8, 0.2, 1}

local FOOTER_HEIGHT = 60

-- Project rows have no thumbnail to sit behind, so the text needs the inset the heading
-- buttons get from their own skin padding.
local CELL_INSET = 10

-- The scroll panel takes width off the right edge once the list scrolls, so right-anchored cells
-- drift out from under their heading.
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
	{name = "Project", x = "0%", cellX = CELL_INSET, right = "58%", align = "left"},
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
-- LuaMenu survives Spring.Reload, so this panel outlives every editor session launched from it.
local RefreshProjects

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

	if startButton and not launching then
		startButton:SetEnabled(entry ~= nil)
		startButton:SetCaption("Start")
	end

	if UpdateNewMapControls then
		UpdateNewMapControls()
	end
end

SetSelectedForward = function(mapName)
	selectedMap = mapName
	for i = 1, #rows do
		Highlight(rows[i].button, rows[i].mapName == mapName)
	end

	if UpdateNewMapControls then
		UpdateNewMapControls()
	end

	if not startButton or launching then
		return
	end

	local busy = mapName and downloading[mapName]
	startButton:SetEnabled(mapName ~= nil and not busy)
	-- mapDetails lists every map the lobby knows of, most of them not downloaded.
	local have = mapName and VFS.HasArchive(mapName)
	if busy then
		startButton:SetCaption("Downloading...")
	else
		startButton:SetCaption((mapName and not have) and "Download" or "Start")
	end
end

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

-- GetControl runs while Configuration is still being built, so GetFont has no font table yet.
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

	local function ItemInFilter(sortData)
		return sortData.alwaysShow or filterText == ""
			or (sortData.search or ""):find(filterText, 1, true) ~= nil
	end

	mapList = WG.Chobby.SortableList(mapHolder, MAP_COLUMNS, ROW_HEIGHT, 1, true, nil, ItemInFilter)

	local projectList =
		WG.Chobby.SortableList(projectHolder, PROJECT_COLUMNS, ROW_HEIGHT, COLUMN_MODIFIED, false, nil, ItemInFilter)

	-- Appending to a heading handler runs after the list has moved sortBy. The arrow sits on the
	-- holder because the button skin pads 10 all round and would cap the glyph at half this size.
	local function MarkSortedColumn(list, columns, holder)
		local arrows = {}
		for i = 1, #list.headingButtons do
			arrows[i] = Image:New {
				parent = holder,
				right = columns[i].right,
				y = 7,
				width = 34,
				height = 24,
				keepAspect = true,
				file = IMG_SORT_ARROW,
			}
		end

		local function Apply()
			for i = 1, #list.headingButtons do
				local active = i == list.sortBy
				Highlight(list.headingButtons[i], active)
				arrows[i]:SetVisibility(active)
				arrows[i].flip = list.smallToLarge
				arrows[i]:Invalidate()
			end
		end

		for i = 1, #list.headingButtons do
			local heading = list.headingButtons[i]
			heading.OnClick[#heading.OnClick + 1] = Apply
		end

		Apply()
	end

	MarkSortedColumn(mapList, MAP_COLUMNS, mapHolder)
	MarkSortedColumn(projectList, PROJECT_COLUMNS, projectHolder)

	-- VFS.GetMaps is not the source: the lobby knows maps through the generated mapDetails config.
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

	local newMapSizeLabel

	local function BuildProjectItems()
		projectRows = {}
		local projects = ListProjects()
		table.insert(projects, 1, NEW_PROJECT)
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
			local label = entry.folder and (entry.folder .. "/" .. entry.name) or entry.name
			local cells = {
				{caption = label, font = 3},
				{caption = entry.isNew and "Blank canvas" or sourceMap, font = 1},
				{caption = string.format("%dx%d", entry.sizeX or 0, entry.sizeZ or 0), font = 1},
				{caption = FormatModified(entry.modified), font = 1},
			}
			for c = 1, #cells do
				local column = PROJECT_COLUMNS[c]
				local cell = Label:New {
					parent = button,
					x = column.cellX or column.x,
					y = 0,
					right = column.right,
					height = ROW_HEIGHT,
					align = column.align or "center",
					autosize = false,
					valign = "center",
					caption = cells[c].caption,
					objectOverrideFont = Configuration:GetFont(cells[c].font),
				}
				if entry.isNew and column.name == "Size" then
					newMapSizeLabel = cell
				end
			end

			local sortData = {
				label:lower(),
				sourceMap:lower(),
				(entry.sizeX or 0) * (entry.sizeZ or 0),
				entry.modified or "",
			}
			sortData.search = label:lower() .. " " .. sourceMap:lower()
			-- Starting fresh is always an option, so it outranks both sort directions and the
			-- search box rather than being something you have to find.
			if entry.isNew then
				sortData.alwaysShow = true
			end

			projectRows[i] = {button = button, entry = entry}
			projectItems[i] = {entry.slug, root, sortData}
		end

		return projectItems
	end

	projectList.priorityList[NEW_PROJECT.slug] = true
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

	local newMapSizePanel = Control:New {
		parent = parent,
		right = 185,
		bottom = 8,
		width = 154,
		height = 45,
		padding = {0, 0, 0, 0},
		noFont = true,
	}

	local function RefreshNewMapSizeCell()
		if newMapSizeLabel then
			newMapSizeLabel:SetCaption(string.format("%dx%d", NEW_PROJECT.sizeX, NEW_PROJECT.sizeZ))
		end
	end

	ComboBox:New {
		parent = newMapSizePanel,
		x = 0,
		y = 7,
		width = 65,
		height = 30,
		items = NEWMAP_SIZES,
		selected = SizeToItem(NEW_PROJECT.sizeX),
		itemHeight = 22,
		objectOverrideFont = Configuration:GetFont(2),
		OnSelect = {
			function (obj, itemIndex)
				NEW_PROJECT.sizeX = NEWMAP_MIN_SIZE + (itemIndex - 1) * 2
				RefreshNewMapSizeCell()
			end
		},
	}

	Label:New {
		parent = newMapSizePanel,
		x = 69,
		y = 12,
		width = 16,
		height = 20,
		align = "center",
		caption = "x",
		objectOverrideFont = Configuration:GetFont(2),
	}

	ComboBox:New {
		parent = newMapSizePanel,
		x = 89,
		y = 7,
		width = 65,
		height = 30,
		items = NEWMAP_SIZES,
		selected = SizeToItem(NEW_PROJECT.sizeZ),
		itemHeight = 22,
		objectOverrideFont = Configuration:GetFont(2),
		OnSelect = {
			function (obj, itemIndex)
				NEW_PROJECT.sizeZ = NEWMAP_MIN_SIZE + (itemIndex - 1) * 2
				RefreshNewMapSizeCell()
			end
		},
	}

	-- Hidden rather than disabled while the editor runs: chili only dims a disabled control,
	-- it still opens the dropdown and takes the click.
	UpdateNewMapControls = function()
		newMapSizePanel:SetVisibility(
			(not launching and listMode == "projects" and selectedProject ~= nil and selectedProject.isNew)
				or false
		)
	end
	UpdateNewMapControls()

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
	launching = false
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
