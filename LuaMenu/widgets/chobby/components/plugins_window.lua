---@diagnostic disable: undefined-global
--------------------------------------------------------------------------------
-- PluginsWindow: Community Widgets Browser for BYAR-Chobby
--
-- A comprehensive UI for browsing, searching, and downloading community-made
-- widgets from the BAR Workshop CDN. Features a paginated grid view, search
-- filtering, detail modals with README display, and robust error handling.
--
-- CDN Structure:
--   Manifest:    /bar-workshop/manifests.json
--   Thumbnails:  /bar-workshop/sites/{id}/{id}_325x100.png
--   Cover art:   /bar-workshop/sites/{id}/{id}_460x300.png
--   README:      /bar-workshop/sites/{id}/{id}.md
--   Distribution:/bar-workshop/distributions/{id}.zip
--
-- Manifest entry fields:
--   id, display_name, name, author, description, tags, version, homepage
--------------------------------------------------------------------------------


-- Ensure json module is available
local json = json or VFS.Include and VFS.Include("libs/json.lua") or nil

PluginsWindow = LCS.class{}

--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------

local CDN_BASE         = "https://bar-workshop.zen-ben.com/bar-workshop"
local MANIFEST_URL     = CDN_BASE .. "/manifests.json"
local MANIFEST_DEST    = "LuaUI/Widgets/manifests.json"
local MANIFEST_NAME    = "plugin_manifest"

local PLUGINS_DIR         = "plugins/"
local IMG_FALLBACK_LARGE  = "LuaMenu/images/load_img_512.png"
local IMG_FALLBACK_MEDIUM = "LuaMenu/images/load_img_128.png"

local ITEM_MIN_WIDTH   = 300  -- Minimum width for a widget card; actual width is dynamic based on container size
local ITEM_HEIGHT      = 270
local ITEMS_PER_PAGE   = 10    -- 5 rows * 2 columns
local HEADER_HEIGHT    = 48
local HEADER_ROW_GAP   = 4
local HEADER_TOTAL_HEIGHT = HEADER_HEIGHT * 2 + HEADER_ROW_GAP
local PAGINATION_HEIGHT = 40

local STATE_LOADING    = "loading"
local STATE_LOADED     = "loaded"
local STATE_ERROR      = "error"

--------------------------------------------------------------------------------
-- Module-level state
--------------------------------------------------------------------------------

local widgetsList      = {}       -- Array of parsed widget entries
local widgetPanelCache = {}       -- id -> Chili panel cache
local currentFilter    = ""       -- Current search string
local currentPage      = 1        -- Current pagination page
local loadState        = STATE_LOADING
local loadError        = nil

-- UI references (set during init, cleared on dispose)
local mainGrid         = nil
local scrollPanel      = nil
local pageLabel        = nil
local statusLabel      = nil
local detailWindow     = nil      -- Currently open detail modal
local searchBox        = nil
local detailReadmeBox  = nil      -- TextBox inside detail modal showing README
local detailCoverImage = nil      -- Image inside detail modal showing cover art
local detailWidgetId   = nil      -- id of widget currently shown in detail modal

local installingWidgets = {}      -- id -> true while install download is in progress
local installedWidgets  = {}      -- id -> true after successful install
local upgradeBackups    = {}      -- id -> backup path for in-progress upgrades

-- Parallel download pipeline state
local downloadToWidgetId = {}     -- download name -> widget id (O(1) lookup)
local cardImageRefs      = {}     -- widget id -> Chili Image widget for in-place updates
local refreshPending     = false  -- debounce flag for grid refresh

--------------------------------------------------------------------------------
-- Utility: Safe string match (case-insensitive, pattern-safe)
--------------------------------------------------------------------------------

local function containsText(haystack, needle)
    if not haystack or not needle or needle == "" then return true end
    -- Use plain find to avoid pattern injection
    return string.find(string.lower(haystack), string.lower(needle), 1, true) ~= nil
end

--------------------------------------------------------------------------------
-- Utility: Clamp a number between min and max
--------------------------------------------------------------------------------

local function clamp(val, lo, hi)
    if val < lo then return lo end
    if val > hi then return hi end
    return val
end

--------------------------------------------------------------------------------
-- Utility: Compare two version strings (e.g. "1.2.3" vs "1.3.0")
-- Returns -1 if v1 < v2, 0 if equal, 1 if v1 > v2
--------------------------------------------------------------------------------

local function compareVersions(v1, v2)
    -- Spring.Echo("[PluginsWindow] Comparing versions: '" .. tostring(v1) .. "' vs '" .. tostring(v2) .. "'")
    if not v1 and not v2 then return 0 end
    if not v1 then return -1 end
    if v1 == v2 then return 0 end
    local parts1 = {}
    for p in string.gmatch(tostring(v1), "(%d+)") do
        parts1[#parts1 + 1] = tonumber(p)
    end
    local parts2 = {}
    for p in string.gmatch(tostring(v2), "(%d+)") do
        parts2[#parts2 + 1] = tonumber(p)
    end
    local maxLen = math.max(#parts1, #parts2)
    for i = 1, maxLen do
        local a = parts1[i] or 0
        local b = parts2[i] or 0
        if a < b then return -1 end
        if a > b then return 1 end
    end
    return 0
end

--------------------------------------------------------------------------------
-- Asset path helpers
--------------------------------------------------------------------------------

local function getThumbnailPath(widgetId)
    return PLUGINS_DIR .. widgetId .. "_325x100.png"
end

local function getCoverPath(widgetId)
    return PLUGINS_DIR .. widgetId .. "_460x300.png"
end

local function getReadmePath(widgetId)
    return PLUGINS_DIR .. widgetId .. "_README.md"
end

local function getDistributionUrl(widgetId)
    return CDN_BASE .. "/distributions/" .. widgetId .. ".zip"
end

local function getInstallPath(widgetId)
    return "LuaUI/Widgets/" .. widgetId
end

--------------------------------------------------------------------------------
-- Install helpers
--------------------------------------------------------------------------------

local function isWidgetInstalled(widgetId)
    if installedWidgets[widgetId] then return true end
    -- Check if the install directory already exists on disk
    local installDir = getInstallPath(widgetId) .. "/"
    local files = VFS.DirList(installDir)
    if files and #files > 0 then
        installedWidgets[widgetId] = true
        return true
    end
    return false
end

local function installWidget(widget)
    local widgetId = widget.id or widget.name or "unknown"
    if installingWidgets[widgetId] then return end -- already in progress

    installingWidgets[widgetId] = true
    local installDir = getInstallPath(widgetId)

    local downloadName = "install_" .. widgetId
    local url = getDistributionUrl(widgetId)

    if WG.DownloadHandler and WG.DownloadHandler.QueueDownload then
        WG.DownloadHandler.QueueDownload(downloadName, "resource", -1, 0, {
            url = url,
            destination = installDir,
            extract = true,
        })
        Spring.Echo("[PluginsWindow] Installing widget: " .. widgetId)
    else
        installingWidgets[widgetId] = nil
        Spring.Echo("[PluginsWindow] Cannot install: DownloadHandler not available")
    end
end

--------------------------------------------------------------------------------
-- Upgrade helpers
--------------------------------------------------------------------------------

local function getInstalledVersion(widgetId)
    local manifestPath = getInstallPath(widgetId) .. "/manifest.json"
    local content = VFS.LoadFile(manifestPath)
    if not content then
        local f = io.open(manifestPath, "r")
        if f then
            content = f:read("*all")
            f:close()
        end
    end
    if not content then return nil end
    if not json then VFS.Include("libs/json.lua") end
    local ok, data = pcall(function() return json.decode(content) end)
    if ok and type(data) == "table" then
        return data.version
    end
    return nil
end

local function backupDirectory(dirPath)
    -- Strip trailing slash for a clean rename
    local cleanPath = dirPath
    if string.sub(cleanPath, -1) == "/" then
        cleanPath = string.sub(cleanPath, 1, -2)
    end
    local stamp = os.date("%Y%m%d_%H%M%S")
    local backupPath = cleanPath .. "_backup_" .. stamp
    local ok, err = os.rename(cleanPath, backupPath)
    if ok then
        Spring.Echo("[PluginsWindow] Backed up directory: " .. cleanPath .. " -> " .. backupPath)
        -- Rename all .lua files to .lua.backup so the engine won't load them
        local luaFiles = VFS.DirList(backupPath .. "/", "*.lua")
        if luaFiles then
            for _, luaFile in ipairs(luaFiles) do
                os.rename(luaFile, luaFile .. ".backup")
            end
        end
        local subDirs = VFS.SubDirs(backupPath .. "/")
        if subDirs then
            for _, subDir in ipairs(subDirs) do
                local subLuaFiles = VFS.DirList(subDir, "*.lua")
                if subLuaFiles then
                    for _, luaFile in ipairs(subLuaFiles) do
                        os.rename(luaFile, luaFile .. ".backup")
                    end
                end
            end
        end
    else
        Spring.Echo("[PluginsWindow] Failed to backup directory: " .. tostring(cleanPath) .. " - " .. tostring(err))
    end
    return ok, backupPath
end

local function checkForUpgrades()
    if #widgetsList == 0 then return end
    for _, widget in ipairs(widgetsList) do
        local widgetId = widget.id
        if widgetId and widget.version and isWidgetInstalled(widgetId) then
            local installedVersion = getInstalledVersion(widgetId)
            if compareVersions(installedVersion, widget.version) < 0 then
                Spring.Echo("[PluginsWindow] Upgrading " .. widgetId .. " from v" .. tostring(installedVersion) .. " to v" .. tostring(widget.version))
                if installingWidgets[widgetId] then
                    Spring.Echo("[PluginsWindow] Upgrade already in progress for " .. widgetId .. ", skipping")
                    return
                end

                -- Backup the existing install folder by renaming it
                local installDir = getInstallPath(widgetId)
                local ok, backupPath = backupDirectory(installDir)
                if not ok then
                    Spring.Echo("[PluginsWindow] Cannot upgrade " .. widgetId .. ": failed to backup existing install")
                    return
                end

                installingWidgets[widgetId] = true
                upgradeBackups[widgetId] = backupPath

                -- Download and extract to the original install path (same as fresh install)
                local downloadName = "upgrade_" .. widgetId
                local url = getDistributionUrl(widgetId) .. "?t=" .. os.time()

                if WG.DownloadHandler and WG.DownloadHandler.QueueDownload then
                    WG.DownloadHandler.QueueDownload(downloadName, "resource", -1, 0, {
                        url = url,
                        destination = installDir,
                        extract = true,
                    })
                    Spring.Echo("[PluginsWindow] Queued upgrade download to: " .. installDir)
                else
                    -- Restore backup since we can't proceed
                    os.rename(backupPath, installDir)
                    installingWidgets[widgetId] = nil
                    upgradeBackups[widgetId] = nil
                    Spring.Echo("[PluginsWindow] Cannot upgrade: DownloadHandler not available")
                end
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Asset downloading via DownloadHandler
--------------------------------------------------------------------------------

local function ensureDirectoryExists(filePath)
    local dir = string.match(filePath, "^(.+)/[^/]+$")
    if dir then Spring.CreateDir(dir) end
end

local ASSET_PRIORITY_CURRENT = 3   -- Priority for current-page asset downloads
local ASSET_PRIORITY_PREFETCH = 1  -- Lower priority for next-page prefetches

local function downloadAsset(downloadName, cdnPath, localPath, priority)
    if VFS.FileExists(localPath) then
        return localPath
    end

    ensureDirectoryExists(localPath)

    local url = CDN_BASE .. cdnPath
    if WG.DownloadHandler and WG.DownloadHandler.MaybeDownloadArchive then
        WG.DownloadHandler.MaybeDownloadArchive(downloadName, "resource", priority or ASSET_PRIORITY_CURRENT, {
            url = url,
            destination = localPath,
            extract = false,
            hidden = true,  -- background asset; suppress from user-facing download UI
        })
    end
    return nil -- Not yet available
end

local function ensureThumbnail(widget, priority)
    local id = widget.id or "unknown"
    local localPath = getThumbnailPath(id)
    local cdnPath = "/sites/" .. id .. "/" .. id .. "_325x100.png"
    local result = downloadAsset(id .. "_thumb", cdnPath, localPath, priority)
    return result or IMG_FALLBACK_MEDIUM
end

local function ensureCover(widget, priority)
    local id = widget.id or "unknown"
    local localPath = getCoverPath(id)
    local cdnPath = "/sites/" .. id .. "/" .. id .. "_460x300.png"
    local result = downloadAsset(id .. "_cover", cdnPath, localPath, priority)
    return result or IMG_FALLBACK_LARGE
end

local function ensureReadme(widget, priority)
    local id = widget.id or "unknown"
    local localPath = getReadmePath(id)
    local cdnPath = "/sites/" .. id .. "/" .. id .. ".md"
    downloadAsset(id .. "_readme", cdnPath, localPath, priority)
    return localPath
end

--------------------------------------------------------------------------------
-- Filtering
--------------------------------------------------------------------------------

local function matchesFilter(widget, filter)
    if not filter or filter == "" then return true end
    if containsText(widget.name, filter) then return true end
    if containsText(widget.author, filter) then return true end
    if containsText(widget.description, filter) then return true end
    -- Search in tags array
    if widget.tags then
        for _, tag in ipairs(widget.tags) do
            if containsText(tag, filter) then return true end
        end
    end
    return false
end

local function getFilteredWidgets()
    if currentFilter == "" then
        return widgetsList
    end
    local results = {}
    for _, widget in ipairs(widgetsList) do
        if matchesFilter(widget, currentFilter) then
            results[#results + 1] = widget
        end
    end
    return results
end

--------------------------------------------------------------------------------
-- Pagination
--------------------------------------------------------------------------------

local function getTotalPages(filteredCount)
    if filteredCount <= 0 then return 1 end
    return math.ceil(filteredCount / ITEMS_PER_PAGE)
end

local function getPageSlice(filteredList, page)
    local startIdx = (page - 1) * ITEMS_PER_PAGE + 1
    local endIdx = math.min(startIdx + ITEMS_PER_PAGE - 1, #filteredList)
    local slice = {}
    for i = startIdx, endIdx do
        slice[#slice + 1] = filteredList[i]
    end
    return slice
end

--------------------------------------------------------------------------------
-- Detail Modal
--------------------------------------------------------------------------------

local function closeDetail()
    if detailWindow then
        detailWindow:Dispose()
        detailWindow = nil
        detailReadmeBox = nil
        detailCoverImage = nil
        detailWidgetId = nil
    end
end

local function openDetail(widget)
    closeDetail()

    local coverPath = ensureCover(widget)
    local readmePath = ensureReadme(widget)
    local readmeContent = VFS.LoadFile(readmePath) or "README is loading or unavailable."
    local widgetId = widget.id or widget.name or "unknown"
    detailWidgetId = widgetId

    detailWindow = Window:New {
        x = "15%",
        y = "10%",
        right = "15%",
        bottom = "10%",
        caption = "",
        resizable = false,
        draggable = false,
        parent = WG.Chobby.lobbyInterfaceHolder,
        classname = "main_window",
        OnDispose = {
            function()
                detailWindow = nil
            end
        },
    }

    -- Title
    Label:New {
        caption = widget.name or "Unknown Widget",
        x = 15,
        y = 8,
        right = 100,
        height = 30,
        objectOverrideFont = WG.Chobby.Configuration:GetFont(4),
        valign = "center",
        parent = detailWindow,
    }

    -- Close button
    Button:New {
        right = 8,
        y = 5,
        width = 80,
        height = 40,
        caption = i18n("close"),
        objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
        classname = "negative_button",
        OnClick = { function() closeDetail() end },
        parent = detailWindow,
    }

    -- Metadata bar
    local metaY = 45
    Label:New {
        caption = "by " .. (widget.author or "Unknown"),
        x = 15,
        y = metaY,
        width = 300,
        height = 22,
        objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
        parent = detailWindow,
    }

    if widget.version then
        Label:New {
            caption = "v" .. widget.version,
            x = 250,
            y = metaY,
            width = 100,
            height = 22,
            objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
            parent = detailWindow,
        }
    end

    -- Tags display
    if widget.tags and #widget.tags > 0 then
        local tagStr = table.concat(widget.tags, ", ")
        Label:New {
            caption = "Tags: " .. tagStr,
            x = 15,
            y = metaY + 22,
            right = 15,
            height = 20,
            fontSize = 12,
            parent = detailWindow,
        }
    end

    local contentY = metaY + 48

    -- Left side: README content in a scroll panel
    ScrollPanel:New {
        x = 10,
        y = contentY,
        width = "58%",
        bottom = 15,
        horizontalScrollbar = false,
        borderColor = {0, 0, 0, 0},
        parent = detailWindow,
        children = {
            (function()
                local tb = TextBox:New {
                    x = 5,
                    y = 5,
                    right = 5,
                    bottom = 5,
                    text = readmeContent,
                    objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
                }
                detailReadmeBox = tb
                return tb
            end)(),
        },
    }

    -- Right side: cover image and action buttons
    local rightX = "62%"

    do
        local img = Image:New {
            x = rightX,
            y = contentY,
            right = 10,
            height = "40%",
            keepAspect = true,
            checkFileExists = true,
            file = coverPath,
            fallbackFile = IMG_FALLBACK,
            parent = detailWindow,
        }
        detailCoverImage = img
    end

    local btnY = contentY + 10

    Button:New {
        caption = isWidgetInstalled(widgetId) and "Installed" or (installingWidgets[widgetId] and "Installing..." or "Install"),
        x = rightX,
        bottom = 120,
        right = 10,
        height = 45,
        objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
        classname = isWidgetInstalled(widgetId) and "option_button" or "action_button",
        OnClick = {
            function()
                if not isWidgetInstalled(widgetId) and not installingWidgets[widgetId] then
                    installWidget(widget)
                end
            end
        },
        parent = detailWindow,
    }

    if widget.homepage then
        Button:New {
            caption = "Homepage",
            x = rightX,
            bottom = 65,
            right = 10,
            height = 45,
            objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
            OnClick = {
                function()
                    WG.WrapperLoopback.OpenUrl(widget.homepage)
                end
            },
            parent = detailWindow,
        }
    end

    -- Modal overlay background
    PriorityPopup(detailWindow, closeDetail, nil, nil, nil, true)
end

--------------------------------------------------------------------------------
-- Widget Card Panel (for grid items)
--------------------------------------------------------------------------------

local function createWidgetCard(widget, itemWidth)
    local id = widget.id
    if id and widgetPanelCache[id] then
        return widgetPanelCache[id]
    end

    local thumbPath = ensureThumbnail(widget)

    -- Create thumbnail image separately so we can store a reference for in-place updates
    local thumbImage = Image:New {
        file = thumbPath,
        x = 0,
        y = 0,
        width = "100%",
        height = 100,
        keepAspect = true,
        checkFileExists = true,
        fallbackFile = IMG_FALLBACK,
    }
    if id then
        cardImageRefs[id] = thumbImage
    end

    -- Use a fixed item height to avoid variable sizing on the last page
    local cardHeight = ITEM_HEIGHT
    local card = Panel:New {
        width = itemWidth,
        height = cardHeight,
        padding = {4, 4, 4, 4},
        children = {
            -- Thumbnail image at top (pre-created for in-place updates)
            thumbImage,
            -- Widget name
            Label:New {
                caption = widget.name or "Unnamed Widget",
                x = 8,
                y = 105,
                right = 8,
                height = 40,
                fontSize = 16,
                autosize = false,
                wordwrap = true,
            },
            -- Author
            Label:New {
                caption = "by " .. (widget.author or "Unknown"),
                x = 8,
                y = 145,
                right = 8,
                height = 18,
                fontSize = 11,
                autosize = false,
            },
            -- Short description
            Label:New {
                caption = widget.description or "",
                x = 8,
                y = 163,
                right = 8,
                height = 50,
                fontSize = 12,
                autosize = false,
                wordwrap = true,
            },
            -- Install button
            Button:New {
                caption = isWidgetInstalled(id) and "Installed" or (installingWidgets[id] and "Installing..." or "Install"),
                right = 85,
                bottom = 4,
                width = 75,
                height = 28,
                fontSize = 12,
                classname = isWidgetInstalled(id) and "option_button" or "action_button",
                OnClick = {
                    function()
                        if not isWidgetInstalled(id) and not installingWidgets[id] then
                            installWidget(widget)
                            widgetPanelCache[id] = nil
                            refreshGrid()
                        end
                    end
                },
            },
            -- Details button
            Button:New {
                caption = "Details",
                right = 4,
                bottom = 4,
                width = 75,
                height = 28,
                fontSize = 12,
                OnClick = {
                    function()
                        openDetail(widget)
                    end
                },
            },
        },
    }

    card.pluginId = id
    if id then
        widgetPanelCache[id] = card
    end
    return card
end

--------------------------------------------------------------------------------
-- Grid Refresh
--------------------------------------------------------------------------------

local function refreshGrid()
    if not mainGrid then return end

    mainGrid:ClearChildren()

    if loadState == STATE_LOADING then
        if statusLabel then
            statusLabel:SetCaption("Loading widgets...")
            statusLabel:SetVisibility(true)
        end
        if pageLabel then pageLabel:SetCaption("") end
        return
    end

    if loadState == STATE_ERROR then
        if statusLabel then
            statusLabel:SetCaption("Failed to load widgets: " .. (loadError or "Unknown error"))
            statusLabel:SetVisibility(true)
        end
        if pageLabel then pageLabel:SetCaption("") end
        return
    end

    local filtered = getFilteredWidgets()
    local totalPages = getTotalPages(#filtered)
    currentPage = clamp(currentPage, 1, totalPages)
    local pageSlice = getPageSlice(filtered, currentPage)

    if #filtered == 0 then
        if statusLabel then
            if currentFilter ~= "" then
                statusLabel:SetCaption("No widgets match your search.")
            else
                statusLabel:SetCaption("No widgets available.")
            end
            statusLabel:SetVisibility(true)
        end
        if pageLabel then pageLabel:SetCaption("") end
        return
    end

    -- Hide status when we have results
    if statusLabel then statusLabel:SetVisibility(false) end

    -- Calculate grid dimensions.
    -- Use scrollPanel.clientWidth for accurate container width.
    -- If not yet available (first frame), defer the refresh.
    local margin = 8
    local containerWidth = scrollPanel and scrollPanel.clientWidth or 0
    if containerWidth <= 0 then
        -- clientWidth not available yet; schedule a deferred refresh
        WG.Delay(function() refreshGrid() end, 0.05)
        return
    end
    local columns = math.max(1, math.floor((containerWidth + margin) / (ITEM_MIN_WIDTH + margin)))
    local itemWidth = math.floor((containerWidth - margin * (columns + 1)) / columns)
    local rows = math.ceil(#pageSlice / columns)

    -- Manually position each card so size is always exactly ITEM_HEIGHT,
    -- regardless of how many items are on the page.
    local index = 0
    for _, widget in ipairs(pageSlice) do
        if widget.id then
            local col = index % columns
            local row = math.floor(index / columns)
            local x = margin + col * (itemWidth + margin)
            local y = row * ITEM_HEIGHT
            local card = createWidgetCard(widget, itemWidth)
            card:SetPos(x, y, itemWidth, ITEM_HEIGHT)
            mainGrid:AddChild(card)
            index = index + 1
        end
    end

    -- Set the container height to exactly fit the occupied rows.
    mainGrid:SetPos(nil, nil, nil, math.max(rows, 1) * ITEM_HEIGHT)
    mainGrid:UpdateLayout()

    -- Update pagination label
    if pageLabel then
        pageLabel:SetCaption("Page " .. currentPage .. " of " .. totalPages .. "  (" .. #filtered .. " widgets)")
    end

    -- Prefetch thumbnails for the next page at lower priority
    local nextPage = currentPage + 1
    if nextPage <= totalPages then
        local nextSlice = getPageSlice(filtered, nextPage)
        for _, w in ipairs(nextSlice) do
            if w.id then ensureThumbnail(w, ASSET_PRIORITY_PREFETCH) end
        end
    end
end

-- Debounced grid refresh: coalesces rapid download completions into a single rebuild
local function scheduleRefresh()
    if refreshPending then return end
    refreshPending = true
    WG.Delay(function()
        refreshPending = false
        refreshGrid()
    end, 0.15)
end

--------------------------------------------------------------------------------
-- Manifest Download and Parsing
--------------------------------------------------------------------------------

local function parseManifest(rawJson)
    if not json then
        VFS.Include("libs/json.lua")
    end
    local ok, data = pcall(function()
        return json.decode(rawJson)
    end)

    if not ok or type(data) ~= "table" then
        loadState = STATE_ERROR
        loadError = "Invalid manifest format"
        Spring.Echo("[PluginsWindow] Failed to parse manifest JSON: " .. tostring(data))
        return
    end

    widgetsList = {}
    downloadToWidgetId = {} -- rebuild lookup map
    for _, entry in ipairs(data) do
        -- Normalize: use display_name as name if available
        if entry.display_name and (not entry.name or entry.name == "") then
            entry.name = entry.display_name
        end
        -- Ensure tags is always a table
        if type(entry.tags) ~= "table" then
            entry.tags = {}
        end
        widgetsList[#widgetsList + 1] = entry
        -- Register asset download names for O(1) lookup on completion
        if entry.id then
            downloadToWidgetId[entry.id .. "_thumb"] = entry.id
            downloadToWidgetId[entry.id .. "_cover"] = entry.id
            downloadToWidgetId[entry.id .. "_readme"] = entry.id
        end
    end

    Spring.Echo("[PluginsWindow] Loaded " .. #widgetsList .. " widgets from manifest")
    loadState = STATE_LOADED
    loadError = nil
    currentPage = 1
end

local function onDownloadFinished(listener, downloadID, downloadName, downloadFileType)
    if downloadName == MANIFEST_NAME then
        local f = io.open(MANIFEST_DEST, "r")
        if f then
            local content = f:read("*all")
            f:close()
            parseManifest(content)
        else
            -- Try VFS as fallback
            local content = VFS.LoadFile(MANIFEST_DEST)
            if content then
                parseManifest(content)
            else
                loadState = STATE_ERROR
                loadError = "Could not read downloaded manifest file"
                Spring.Echo("[PluginsWindow] Could not open manifest file at: " .. MANIFEST_DEST)
            end
        end
        -- Auto-upgrade installed widgets that have newer versions available
        if loadState == STATE_LOADED then
            checkForUpgrades()
        end
        refreshGrid()
        return
    end

    -- Check if this is an upgrade completion
    if string.find(downloadName, "^upgrade_") then
        local widgetId = string.sub(downloadName, 9) -- strip "upgrade_" prefix
        installingWidgets[widgetId] = nil
        installedWidgets[widgetId] = true
        upgradeBackups[widgetId] = nil -- backup kept on disk but no longer tracked
        widgetPanelCache[widgetId] = nil
        Spring.Echo("[PluginsWindow] Widget upgraded: " .. widgetId)
        refreshGrid()
        return
    end

    -- Check if this is a widget install completion
    if string.find(downloadName, "^install_") then
        local widgetId = string.sub(downloadName, 9) -- strip "install_" prefix
        installingWidgets[widgetId] = nil
        installedWidgets[widgetId] = true
        widgetPanelCache[widgetId] = nil
        Spring.Echo("[PluginsWindow] Widget installed: " .. widgetId)
        refreshGrid()
        return
    end

    -- For asset downloads (images, readmes), use O(1) lookup and in-place updates
    local widgetId = downloadToWidgetId[downloadName]
    if widgetId then
        -- Try in-place thumbnail update (avoids full grid rebuild)
        if string.find(downloadName, "_thumb", 1, true) then
            local imageRef = cardImageRefs[widgetId]
            if imageRef then
                local thumbPath = getThumbnailPath(widgetId)
                if VFS.FileExists(thumbPath) then
                    imageRef.file = thumbPath
                    if type(imageRef.Invalidate) == "function" then
                        imageRef:Invalidate()
                    end
                end
            else
                -- No cached image ref; invalidate panel so next refresh rebuilds it
                widgetPanelCache[widgetId] = nil
            end
        end

        -- If the detail modal is open for this widget, update it in-place
        if detailWidgetId == widgetId then
            if string.find(downloadName, "_readme", 1, true) then
                local readmePath = getReadmePath(widgetId)
                if VFS.FileExists(readmePath) and detailReadmeBox then
                    local content = VFS.LoadFile(readmePath) or ""
                    if type(detailReadmeBox.SetText) == "function" then
                        detailReadmeBox:SetText(content)
                    else
                        detailReadmeBox.text = content
                    end
                end
            end
            if string.find(downloadName, "_cover", 1, true) and detailCoverImage then
                local coverPath = getCoverPath(widgetId)
                if VFS.FileExists(coverPath) then
                    detailCoverImage.file = coverPath
                end
                if type(detailCoverImage.Invalidate) == "function" then
                    detailCoverImage:Invalidate()
                end
            end
        end

        -- Debounced refresh as safety net (handles edge cases like first-time cache miss)
        scheduleRefresh()
        return
    end

    -- Unknown download name — debounced refresh
    scheduleRefresh()
end

local function onDownloadFailed(listener, downloadID, errorID, downloadName, downloadFileType)
    if downloadName == MANIFEST_NAME then
        loadState = STATE_ERROR
        loadError = "Network error (code " .. tostring(errorID) .. ")"
        Spring.Echo("[PluginsWindow] Manifest download failed: " .. tostring(errorID))
        refreshGrid()
        return
    end

    -- Handle upgrade failures — restore from backup
    if string.find(downloadName, "^upgrade_") then
        local widgetId = string.sub(downloadName, 9)
        local backupPath = upgradeBackups[widgetId]
        if backupPath then
            local installDir = getInstallPath(widgetId)
            Spring.Echo("[PluginsWindow] Restoring backup after failed upgrade: " .. backupPath .. " -> " .. installDir)
            os.rename(backupPath, installDir)
        end
        installingWidgets[widgetId] = nil
        upgradeBackups[widgetId] = nil
        widgetPanelCache[widgetId] = nil
        Spring.Echo("[PluginsWindow] Widget upgrade failed: " .. widgetId .. " (error " .. tostring(errorID) .. ")")
        refreshGrid()
        return
    end

    -- Handle install failures
    if string.find(downloadName, "^install_") then
        local widgetId = string.sub(downloadName, 9)
        installingWidgets[widgetId] = nil
        widgetPanelCache[widgetId] = nil
        Spring.Echo("[PluginsWindow] Widget install failed: " .. widgetId .. " (error " .. tostring(errorID) .. ")")
        refreshGrid()
    end
end

local function fetchManifest()
    loadState = STATE_LOADING
    loadError = nil

    -- Remove stale cached manifest
    if VFS.FileExists(MANIFEST_DEST) then
        local ok, err = os.remove(MANIFEST_DEST)
        if not ok then
            Spring.Echo("[PluginsWindow] Failed to remove stale manifest: " .. tostring(err))
        end
    end

    -- Cache-bust the URL with a timestamp
    local url = MANIFEST_URL .. "?t=" .. os.time()

    if WG.DownloadHandler and WG.DownloadHandler.QueueDownload then
        WG.DownloadHandler.QueueDownload(MANIFEST_NAME, "resource", -1, 0, {
            url = url,
            destination = MANIFEST_DEST,
            extract = false,
        })
    else
        loadState = STATE_ERROR
        loadError = "Download handler not available"
        Spring.Echo("[PluginsWindow] DownloadHandler not available")
    end
end

--------------------------------------------------------------------------------
-- Search Handler
--------------------------------------------------------------------------------

local function onSearchChanged(newText)
    local text = newText or ""
    if text == currentFilter then return end
    currentFilter = text
    currentPage = 1
    -- Clear panel cache so filter results get fresh panels
    widgetPanelCache = {}
    cardImageRefs = {}
    refreshGrid()
end

--------------------------------------------------------------------------------
-- Pagination Controls
--------------------------------------------------------------------------------

local function goToPage(page)
    local filtered = getFilteredWidgets()
    local totalPages = getTotalPages(#filtered)
    local newPage = clamp(page, 1, totalPages)
    if newPage ~= currentPage then
        currentPage = newPage
        widgetPanelCache = {}
        cardImageRefs = {}
        refreshGrid()
        -- Reset scroll to top when changing pages
        if scrollPanel and type(scrollPanel.SetScrollPos) == "function" then
            scrollPanel:SetScrollPos(0, 0, false, false)
        end
    end
end

local function prevPage()
    goToPage(currentPage - 1)
end

local function nextPage()
    goToPage(currentPage + 1)
end

local function firstPage()
    goToPage(1)
end

local function lastPage()
    local filtered = getFilteredWidgets()
    goToPage(getTotalPages(#filtered))
end

--------------------------------------------------------------------------------
-- Initialization
--------------------------------------------------------------------------------

function PluginsWindow:init(parent)
    -- Register download event listeners
    if WG.DownloadHandler and WG.DownloadHandler.AddListener then
        WG.DownloadHandler.AddListener("DownloadFinished", onDownloadFinished)
        WG.DownloadHandler.AddListener("DownloadFailed", onDownloadFailed)
    else
        Spring.Echo("[PluginsWindow] WARNING: DownloadHandler not available for event registration")
    end

    -- Compute dynamic item width inside init based on parent width
    local parentWidth = (parent and parent.width) or 1300
    local usableWidth = parentWidth - 40  -- margins
    local columns = math.max(1, math.floor((usableWidth + 8) / (ITEM_MIN_WIDTH + 8))) -- 8 is margin
    local itemWidth = math.floor(usableWidth / columns)

    -- Main container (use Control to avoid nesting a full Window inside the main window)
    self.window = Control:New {
        x = 0,
        right = 0,
        y = 0,
        bottom = 0,
        padding = {20, 17, 20, 0},
        parent = parent,
        resizable = false,
        draggable = false,
    }

    -- Track disposal for cleanup
    self.window.OnDispose = self.window.OnDispose or {}
    self.window.OnDispose[#self.window.OnDispose + 1] = function()
        self:cleanup()
    end

    ----------------------------------------------------------------------
    -- Header bar (two rows)
    ----------------------------------------------------------------------

    -- First row: title and disclaimer only
    local btnW = 110
    local btnH = 28
    local btnFont = 12
    local row1Y = 0
    local row2Y = HEADER_HEIGHT + HEADER_ROW_GAP

    Label:New {
        objectOverrideFont = WG.Chobby.Configuration:GetFont(4),
        caption = "Widgets",
        x = 0,
        y = row1Y,
        width = 110,
        height = HEADER_HEIGHT,
        valign = "center",
        parent = self.window,
    }

    Label:New {
        caption = "Community widgets. BAR is not responsible for their content.",
        x = 120,
        right = 0,
        y = row1Y,
        height = HEADER_HEIGHT,
        autosize = false,
        valign = "center",
        fontSize = 12,
        parent = self.window,
    }

    -- Second row: all header buttons (left), search box (right)
    local btnY = row2Y + 6
    local btnGap = 8
    local btnW = 110
    local btnH = 28
    local btnFont = 12
    local btnLeft = 0
    Button:New {
        caption = "Widgets Folder",
        tooltip = "Open the local folder where installed widgets are stored (opens in file explorer)",
        x = btnLeft,
        y = btnY,
        width = btnW,
        height = btnH,
        fontSize = btnFont,
        OnClick = { function() if WG.Connector and WG.Connector.writePath then WG.WrapperLoopback.OpenFolder(WG.Connector.writePath .. "/LuaUI/Widgets") end end },
        parent = self.window,
    }
    Button:New {
        caption = "Contribute",
        tooltip = "Learn how to submit your own widget to the community repository (opens in browser)",
        x = btnLeft + btnW + btnGap,
        y = btnY,
        width = btnW - 10,
        height = btnH,
        fontSize = btnFont,
        OnClick = { function() WG.WrapperLoopback.OpenUrl("https://github.com/WybrenKoelmans/Public-BAR-Widgets?tab=readme-ov-file#how-to-contribute-a-new-widget") end },
        parent = self.window,
    }
    Button:New {
        caption = "Refresh",
        tooltip = "Re-download the widget list from the community repository",
        x = btnLeft + 2 * btnW - 10 + 2 * btnGap,
        y = btnY,
        width = btnW - 20,
        height = btnH,
        fontSize = btnFont,
        OnClick = { function() widgetPanelCache = {}; cardImageRefs = {}; widgetsList = {}; downloadToWidgetId = {}; currentPage = 1; fetchManifest(); refreshGrid() end },
        parent = self.window,
    }

    searchBox = EditBox:New {
        text = "",
        right = 0,
        y = btnY,
        width = 180,
        height = btnH,
        hint = "Search widgets...",
        objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
        objectOverrideHintFont = WG.Chobby.Configuration:GetFont(2),
        OnKeyPress = {
            function(obj, key)
                WG.Delay(function()
                    if obj and obj.text then
                        onSearchChanged(obj.text)
                    end
                end, 0.05)
            end
        },
        parent = self.window,
    }

    ----------------------------------------------------------------------
    -- Pagination bar (below header)
    ----------------------------------------------------------------------

    local paginationY = HEADER_TOTAL_HEIGHT + 2

    -- Pagination bar: use relative positions (left, right, center)
    local pagBtnW = 40
    local pagBtnH = 30
    local pagFont = 13
    local pagPad = 10
    local pagBtnGap = 8

    Button:New {
        caption = "<<",
        x = 0,
        y = paginationY,
        width = pagBtnW,
        height = pagBtnH,
        fontSize = pagFont,
        OnClick = { function() firstPage() end },
        parent = self.window,
    }

    Button:New {
        caption = "<",
        x = pagBtnW + pagBtnGap,
        y = paginationY,
        width = pagBtnW,
        height = pagBtnH,
        fontSize = pagFont,
        OnClick = { function() prevPage() end },
        parent = self.window,
    }

    pageLabel = Label:New {
        caption = "Loading...",
        x = (pagBtnW + pagBtnGap) * 2,
        right = (pagBtnW + pagBtnGap) * 2,
        y = paginationY,
        height = pagBtnH,
        valign = "center",
        autosize = false,
        fontSize = 14,
        align = "center",
        parent = self.window,
    }

    Button:New {
        caption = ">",
        right = pagBtnW + pagBtnGap,
        y = paginationY,
        width = pagBtnW,
        height = pagBtnH,
        fontSize = pagFont,
        OnClick = { function() nextPage() end },
        parent = self.window,
    }

    Button:New {
        caption = ">>",
        right = 0,
        y = paginationY,
        width = pagBtnW,
        height = pagBtnH,
        fontSize = pagFont,
        OnClick = { function() lastPage() end },
        parent = self.window,
    }

    ----------------------------------------------------------------------
    -- Status label (shown during loading/error/empty states)
    ----------------------------------------------------------------------

    local contentY = paginationY + PAGINATION_HEIGHT + 5

    statusLabel = Label:New {
        caption = "Loading widgets...",
        x = 0,
        y = contentY + 40,
        right = 0,
        height = 40,
        autosize = false,
        align = "center",
        objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
        parent = self.window,
    }

    ----------------------------------------------------------------------
    -- Grid inside ScrollPanel
    ----------------------------------------------------------------------

    -- Use a plain Control so cards can be manually positioned with exact sizes.
    -- The Grid widget's resizeItems logic was stretching cards on partial pages.
    mainGrid = Control:New {
        width = "100%",
        height = ITEM_HEIGHT,
        padding = {0, 0, 0, 0},
        resizable = false,
        draggable = false,
        children = {},
    }
    mainGrid.itemWidth = itemWidth  -- keep for refreshGrid reference

    scrollPanel = ScrollPanel:New {
        x = 0,
        right = 0,
        y = contentY,
        bottom = 15,
        horizontalScrollbar = false,
        borderColor = {0, 0, 0, 0},
        padding = {0, 0, 0, 0},
        parent = self.window,
        children = { mainGrid },
        OnResize = {
            function()
                refreshGrid()
            end
        },
    }

    ----------------------------------------------------------------------
    -- Kick off manifest download
    ----------------------------------------------------------------------

    fetchManifest()

    -- Schedule a deferred grid refresh so clientWidth is available on first render
    WG.Delay(function() refreshGrid() end, 0.1)

    Spring.Echo("[PluginsWindow] Initialized")
end

--------------------------------------------------------------------------------
-- Cleanup
--------------------------------------------------------------------------------

function PluginsWindow:cleanup()
    closeDetail()
    mainGrid = nil
    scrollPanel = nil
    pageLabel = nil
    statusLabel = nil
    searchBox = nil
    widgetPanelCache = {}
    installingWidgets = {}
    upgradeBackups = {}
    downloadToWidgetId = {}
    cardImageRefs = {}
    refreshPending = false
    Spring.Echo("[PluginsWindow] Cleaned up")
end
