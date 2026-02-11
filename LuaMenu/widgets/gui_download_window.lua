--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Download Window",
		desc      = "Handles download visuals.",
		author    = "GoogleFrog",
		date      = "19 July 2016",
		license   = "GNU LGPL, v2.1 or later",
		layer     = -100000,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Configuration

local STATUS_POSITION = 420
local BUTTON_WIDTH = 78

local STATUS_PRIORITY = {
	active = 1,
	pending = 2,
	cancelled = 3,
	failed = 4,
	unsupported = 5,
	success = 6,
}

local NAME_MAP = {
	active = "",
	connecting = "Connecting...",
	pending = "Queued",
	cancel = "\255\255\255\0Cancelled",
	fail = "\255\255\0\0Failed",
	unsupported = "\255\255\0\0Require spring-launcher",
	success = "\255\0\255\0Complete",
}

local BUTTON_MAP = {
	active = {cancel = true},
	connecting = {cancel = true},
	pending = {cancel = true, priority = true},
	cancel = {retry = true},
	fail = {retry = true},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Local Variables

local downloads = {}
local downloadList

local completedDownloads = 1

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utilities

local function CreateDownloadEntry(downloadData)
	local Configuration = WG.Chobby.Configuration

	local fileName = downloadData.name
	local fileType = downloadData.fileType
	local completionOrder = false

	local sortData = {downloadData.priority - downloadData.id/100000, downloadData.name, statusPriority}

	local progressBar
	local statusPriority = 1

	local holder = Panel:New {
		x = 0,
		y = 0,
		width = "100%",
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
	}

	local retryButton = Button:New {
		x = 7 + BUTTON_WIDTH + 4,
		y = 3,
		bottom = 3,
		width = BUTTON_WIDTH - 4,
		caption = i18n("retry"),
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		classname = "action_button",
		OnClick = {
			function ()
				WG.DownloadHandler.RetryDownload(fileName, fileType)
			end
		},
		parent = holder,
	}

	local cancelButton = Button:New {
		x = 7 + BUTTON_WIDTH + 4,
		y = 3,
		bottom = 3,
		width = BUTTON_WIDTH - 4,
		caption = i18n("cancel"),
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		classname = "negative_button",
		OnClick = {
			function ()
				WG.DownloadHandler.CancelDownload(fileName, fileType)
			end
		},
		parent = holder,
	}

	local priorityButton = Button:New {
		x = 3,
		y = 3,
		bottom = 3,
		width = BUTTON_WIDTH + 4,
		caption = i18n("to_front"),
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		classname = "action_button",
		OnClick = {
			function ()
				WG.DownloadHandler.SetDownloadTopPriority(fileName, fileType)
			end
		},
		parent = holder,
	}

	local downloadDataName = downloadData.name
	if Configuration.gameConfig.ShortenNameString then
		downloadDataName = Configuration.gameConfig.ShortenNameString(downloadDataName)
	end
	TextBox:New {
		x = 15 + BUTTON_WIDTH*2,
		y = 12,
		right = 0,
		height = 20,
		valign = 'center',
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		objectOverrideHintFont = WG.Chobby.Configuration:GetFont(2),
		text = downloadDataName,
		parent = holder,
	}

	local statusBox = TextBox:New {
		x = STATUS_POSITION + 12,
		y = 12,
		right = 0,
		height = 20,
		valign = 'center',
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		objectOverrideHintFont = WG.Chobby.Configuration:GetFont(2),
		text = downloadData.removalType or "pending",
		parent = holder,
	}

	local function UpdateStatus()
		local statusString = downloadData.removalType
		if statusString then
			if progressBar then
				progressBar:Dispose()
				progressBar = nil
			end
			if not completionOrder then
				completionOrder = completedDownloads - 1000000
				completedDownloads = completedDownloads + 1
			end
		else
			completionOrder = false
			if downloadData.active and not progressBar then
				statusString = "connecting"
			elseif progressBar then
				statusString = "active"
			else
				statusString = "pending"
			end
		end

		statusPriority = STATUS_PRIORITY[statusString] or 1
		statusBox:SetText(NAME_MAP[statusString] or "")

		local buttons = BUTTON_MAP[statusString]

		retryButton:SetVisibility((buttons and buttons.retry) or false)
		priorityButton:SetVisibility((buttons and buttons.priority) or false)
		cancelButton:SetVisibility((buttons and buttons.cancel) or false)
	end

	UpdateStatus()

	local externalFunctions = {}

	function externalFunctions.SetProgress(sizeCurrent, sizeTotal)
		if sizeCurrent == 0 then
			return
		end

		if not progressBar then
			progressBar = Progressbar:New {
				x = STATUS_POSITION,
				y = 2,
				right = 2,
				bottom = 2,
				value = 0,
				parent = holder,
			}
		end
		progressBar:SetCaption(string.format("%.1f", sizeCurrent) .. "/" .. string.format("%.1f", sizeTotal) .. " MB")
		progressBar:SetValue(100*sizeCurrent/sizeTotal)

		UpdateStatus()
	end

	function externalFunctions.GetHolder()
		return holder
	end

	function externalFunctions.UpdateAndGetSortOrder(newData)
		if not newData then
			return sortData
		end
		downloadData = newData
		UpdateStatus()

		sortData[1] = (completionOrder or downloadData.priority) - downloadData.id/100000
		sortData[3] = statusPriority

		return sortData
	end

	return externalFunctions
end

local function DownloadNumberUpdate(downloadCount)
	local interfaceRoot = WG.Chobby and WG.Chobby.interfaceRoot
	if not interfaceRoot then
		return
	end
	interfaceRoot.GetRightPanelHandler().SetActivity("downloads", downloadCount)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Initialization

local function AddDownloadEntry(data)
	local name = data.name
	downloads[name] = CreateDownloadEntry(data)
	local control = downloads[name].GetHolder()
	if control then
		return {name, control, downloads[name].UpdateAndGetSortOrder()}
	end
end

local function UpdateOrAddDownloadEntry(data)
	local name = data.name
	if downloads[name] then
		downloadList:UpdateItemSorting(name, downloads[name].UpdateAndGetSortOrder(data), true)
	else
		local entry = AddDownloadEntry(data)
		if entry then
			downloadList:AddItem(entry[1], entry[2], entry[3])
		end
	end
end

local function InitializeControls(window)
	Label:New {
		x = 15,
		y = 11,
		width = 180,
		height = 30,
		parent = window,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		caption = "Downloads",
	}

	-------------------------
	-- Download List
	-------------------------

	local listHolder = Control:New {
		x = 12,
		right = 15,
		y = 52,
		bottom = 15,
		parent = window,
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
	}

	local headings = {
		{name = "Order", x = 5, width = 2*BUTTON_WIDTH + 7},
		{name = "Name", x = 2*BUTTON_WIDTH + 12, width = STATUS_POSITION - 2*BUTTON_WIDTH - 9},
		{name = "Status", x = STATUS_POSITION + 3, right = 5},
	}

	downloadList = WG.Chobby.SortableList(listHolder, headings, nil, nil, false)

	local function AddCurrentDownloads()
		local queue, finished = WG.DownloadHandler.GetDownloadQueue()

		local items = {}
		for i = 1, #queue do
			local entry = AddDownloadEntry(queue[i])
			if entry then
				items[#items + 1] = entry
			end
		end

		for i = 1, #finished do
			local entry = AddDownloadEntry(finished[i])
			if entry then
				items[#items + 1] = entry
			end
		end

		downloadList:AddItems(items)
	end

	AddCurrentDownloads()
		-------------------------
	-- Buttons
	-------------------------

	Button:New {
		right = 17,
		y = 5,
		width = 165,
		height = 38,
		caption = i18n("rescan_files"),
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		classname = "option_button",
		parent = window,
		OnClick = {
			function ()
				VFS.ScanAllDirs()
			end
		},
	}

	-------------------------
	-- Listeners
	-------------------------

	local function DownloadQueueUpdate(_, queue, finished)
		for i = 1, #queue do
			UpdateOrAddDownloadEntry(queue[i])
		end

		for i = 1, #finished do
			UpdateOrAddDownloadEntry(finished[i])
		end
		downloadList:UpdateOrder(items)
	end

	WG.DownloadHandler.AddListener("DownloadQueueUpdate", DownloadQueueUpdate)

	local function DownloadProgress(_, _, sizeCurrent, sizeTotal, name)
		if downloads[name] then
			downloads[name].SetProgress(sizeCurrent, sizeTotal)
		else
			Spring.Log(LOG_SECTION, LOG.ERROR, "DownloadWindow:DownloadProgressListener not found")
		end
	end

	WG.DownloadHandler.AddListener("DownloadProgress", DownloadProgress)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- External Interface

local DownloadWindow = {}

local initialized = false
function DownloadWindow.GetControl()
	local window = Control:New {
		x = "0%",
		y = "0%",
		width = "100%",
		height = "100%",
		OnParent = {
			function(obj)
				if not initialized then
					initialized = true
					InitializeControls(obj)
				end
			end
		},
	}

	local function DownloadQueueUpdateAlways(_, queue, finished)
		DownloadNumberUpdate((queue and #queue) or 0)
	end

	WG.DownloadHandler.AddListener("DownloadQueueUpdate", DownloadQueueUpdateAlways)

	return window
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

local function DelayedInitialize()
end

function widget:Initialize()
	CHOBBY_DIR = LUA_DIRNAME .. "widgets/chobby/"
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	WG.Delay(DelayedInitialize, 1)

	WG.DownloadWindow = DownloadWindow
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
