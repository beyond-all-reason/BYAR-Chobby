--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:GetInfo()
	return {
		name      = "Download Handler",
		desc      = "Handles downloads",
		author    = "GoogleFrog",
		date      = "10 April 2017",
		license   = "GPL-v2",
		layer     = 0,
		handler   = true,
		api       = true,
		enabled   = true,
	}
end

local externalFunctions = {}
local listeners = {}
local wrapperFunctions = {}

local downloadQueue = {} -- {name, fileType, priority, id, retryCount}
local downloadCount = 0
local topPriority = 0
local removedDownloads = {}

local requestUpdate = false

local USE_WRAPPER_DOWNLOAD = true

-- Wrapper types are RAPID, MAP, MISSION, DEMO, ENGINE, NOTKNOWN
local typeMap = {
	game = "RAPID",
	map = "MAP",
	engine = "ENGINE",
	resource = "RESOURCE",
}
local reverseTypeMap = {
	RAPID = "game",
	MAP = "map",
	ENGINE = "engine",
	RESOURCE = "resource",
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Listeners

local function CallListeners(event, ...)
	if listeners[event] == nil then
		return nil -- no event listeners
	end
	local eventListeners = Spring.Utilities.ShallowCopy(listeners[event])
	for i = 1, #eventListeners do
		local listener = eventListeners[i]
		args = {...}
		xpcall(function() listener(listener, unpack(args)) end,
			function(err) Spring.Echo("Download Handler Listener Error", err, event) end )
	end
	return true
end

function externalFunctions.AddListener(event, listener)
	if listener == nil then
		Spring.Log(LOG_SECTION, LOG.ERROR, "Event: " .. tostring(event) .. ", listener cannot be nil")
		return
	end
	local eventListeners = listeners[event]
	if eventListeners == nil then
		eventListeners = {}
		listeners[event] = eventListeners
	end
	table.insert(eventListeners, listener)
end

function externalFunctions.RemoveListener(event, listener)
	if listeners[event] then
		for k, v in pairs(listeners[event]) do
			if v == listener then
				table.remove(listeners[event], k)
				if #listeners[event] == 0 then
					listeners[event] = nil
				end
				break
			end
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utilities
local SaveLobbyVersionGZPath = nil
local versionGZcache = nil
local function SaveVersionGZ(path)
	if versionGZcache == nil then
		versionGZcache = VFS.LoadFile(path)
		if versionGZcache ~= nil then
			Spring.Echo("Saved lobby versions.gz from", path, 'size = ', string.len(versionGZcache))
		else
			Spring.Echo("Failed to load versions.gz from", path)
		end
	else
		Spring.Echo("Lobby versions.gz already cached",path)
	end
end

local function RestoreVersionGZ(path)
	if versionGZcache ~= nil then
		local vgzfile, err = io.open(path,"wb")
		if vgzfile then
			vgzfile:write(versionGZcache)
			Spring.Echo("Wrote ", path, 'successfully')
			vgzfile:close()
		else
			Spring.Echo("Unable to open ", path, 'for writing the cache', err)
		end
	else
		Spring.Echo("Unable to restore versions.gz from", path, "as it has not been loaded")
	end
end


local function DownloadSortFunc(a, b)
	return a.priority > b.priority or (a.priority == b.priority and a.id < b.id)
end

local function DownloadQueueUpdate()
	requestUpdate = false

	if #downloadQueue == 0 then
		CallListeners("DownloadQueueUpdate", downloadQueue, removedDownloads)
		return
	end
	table.sort(downloadQueue, DownloadSortFunc)

	local front = downloadQueue[1]
	if not front.active then
		if USE_WRAPPER_DOWNLOAD and WG.WrapperLoopback and WG.WrapperLoopback.DownloadFile then
			WG.WrapperLoopback.DownloadFile(front.name, typeMap[front.fileType], front.resource)
			CallListeners("DownloadStarted", front.id, front.name, front.fileType)
		else
			VFS.DownloadArchive(front.name, front.fileType)
		end
		front.active = true
	end

	CallListeners("DownloadQueueUpdate", downloadQueue, removedDownloads)
end

local function GetDownloadIndex(downloadList, name, fileType)
	for i = 1, #downloadList do
		local data = downloadList[i]
		if data.name == name and data.fileType == fileType then
			return i
		end
	end
	return nil
end

local function GetDownloadBySpringDownloadID(downloadList, springDownloadID)
	for i = 1, #downloadList do
		local data = downloadList[i]
		if data.springDownloadID == springDownloadID then
			return i
		end
	end
	return nil
end

local function GetDownloadIndexByName(downloadList, downloadName)
	for i = 1, #downloadList do
		local data = downloadList[i]
		if data.name == downloadName then
			return i
		end
	end
	return nil
end

local function AssociatedSpringDownloadID(springDownloadID, name, fileType)
	local index = GetDownloadIndex(downloadQueue, name, fileType)
	if not index then
		return false
	end
	downloadQueue[index].springDownloadID = springDownloadID
end

local function RemoveDownload(name, fileType, putInRemoveList, removalType)
	-- The changes to this function deserve some documentation:
	-- Often, a map download won't truly fail, it will download just fine but return that it failed,
	-- and retrying it up to retrycount times will succeed.
	-- A game download will also return with failure often so we use VFS.ScanAllDirs() to check if we did actually
	-- successfully download it: if we were truly unsuccessful, then we retry downloading it again.

	local index = GetDownloadIndex(downloadQueue, name, fileType)
	if not index then
		return false
	end

	local downloadID = downloadQueue[index].id

	if removalType == "success" then
		CallListeners("DownloadFinished", downloadID, name, fileType)
	end

	if putInRemoveList then
		downloadQueue[index].removalType = removalType
		removedDownloads[#removedDownloads + 1] = downloadQueue[index]
	end
	downloadQueue[index] = downloadQueue[#downloadQueue]
	downloadQueue[#downloadQueue] = nil

	if putInRemoveList and removalType == "fail" and WG.Chobby.Configuration.downloadRetryCount then
		local lastFailed = removedDownloads[#removedDownloads]
		Spring.Log("Chobby", LOG.WARNING, "Downloading of ", name, fileType, "failed, retryCount=", lastFailed.retryCount)

		local retry = true

		if lastFailed.fileType == "game" then
			--Spring.Log("Chobby", LOG.WARNING, "trying to scanalldirs on game dl failure")
			VFS.ScanAllDirs()
			if VFS.HasArchive(name) then
				Spring.Log("Chobby", LOG.WARNING, "VFS.ScanAllDirs found downloaded item after failure",name)
				CallListeners("DownloadFinished", downloadID, name, fileType)
				lastFailed.removalType = "success"
				retry = false
			end
		end
		if retry then
			if lastFailed.retryCount < WG.Chobby.Configuration.downloadRetryCount then
				lastFailed.retryCount = lastFailed.retryCount + 1
				externalFunctions.RetryDownload(name,fileType)
			else
				CallListeners("DownloadFailed", downloadID, removalType, name, fileType)
			end
		end
	end
	requestUpdate = true
	return true
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Externals Functions

function externalFunctions.QueueDownload(name, fileType, priority, retryCount, resource)
	priority = priority or 1
	if priority == -1 then
		priority = topPriority + 1
	end

	if topPriority < priority then
		topPriority = priority
	end

	local index = GetDownloadIndex(downloadQueue, name, fileType)
	if index then
		local data = downloadQueue[index]
		if priority > data.priority then
			data.priority = priority
			requestUpdate = true
		end
		return
	end

	downloadCount = downloadCount + 1
	downloadQueue[#downloadQueue + 1] = {
		name = name,
		fileType = fileType,
		priority = priority,
		id = downloadCount,
		retryCount = retryCount or 0,
		resource = resource,
	}
	requestUpdate = true
	CallListeners("DownloadQueued", downloadCount, name, fileType, resource)
end

function externalFunctions.SetDownloadTopPriority(name, fileType)
	local index = GetDownloadIndex(downloadQueue, name, fileType)
	if not index then
		return
	end

	topPriority = topPriority + 1
	downloadQueue[index].priority = topPriority
	requestUpdate = true
	return true
end

function externalFunctions.CancelDownload(name, fileType, success)
	local index = GetDownloadIndex(downloadQueue, name, fileType)
	if not index then
		return false
	end

	downloadQueue[index].removalType = (success == "fail") and "fail" or "cancel"
	removedDownloads[#removedDownloads + 1] = downloadQueue[index]

	downloadQueue[index] = downloadQueue[#downloadQueue]
	downloadQueue[#downloadQueue] = nil
	requestUpdate = true
end

function externalFunctions.RetryDownload(name, fileType)
	local index = GetDownloadIndex(removedDownloads, name, fileType)
	if not index then
		return false
	end

	externalFunctions.QueueDownload(name, fileType, removedDownloads[index].priority,removedDownloads[index].retryCount)
	removedDownloads[index] = removedDownloads[#removedDownloads]
	removedDownloads[#removedDownloads] = nil
	requestUpdate = true
	return true
end

function externalFunctions.RemoveRemovedDownload(name, fileType)
	local index = GetDownloadIndex(removedDownloads, name, fileType)
	if not index then
		return false
	end

	removedDownloads[index] = removedDownloads[#removedDownloads]
	removedDownloads[#removedDownloads] = nil
	requestUpdate = true
	return true
end

local function haveEngineDir(path)
	local springExecutable = Platform.osFamily == "Windows" and "spring.exe" or "spring"
	return VFS.FileExists(path .. "//" .. springExecutable)
end

function externalFunctions.MaybeDownloadArchive(name, archiveType, priority, resource)
	if archiveType == "resource" then
		local haveEngine = haveEngineDir(resource.destination)
		if not haveEngine then
			externalFunctions.QueueDownload(name, archiveType, priority, _, resource)
		end
		return

	elseif not VFS.HasArchive(name) then
		externalFunctions.QueueDownload(name, archiveType, priority)
		return
	end
end

function externalFunctions.GetDownloadQueue()
	return downloadQueue, removedDownloads
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Wrapper Interface

function wrapperFunctions.DownloadFinished(name, fileType, success, aborted)
	fileType = fileType and reverseTypeMap[fileType]
	if fileType then
		if (fileType == 'RAPID' or fileType == 'game') and SaveLobbyVersionGZPath then
			RestoreVersionGZ(SaveLobbyVersionGZPath)
		end

		if not VFS.HasArchive(name) then
			VFS.ScanAllDirs() -- Find downloaded file (if it exists).
		end
		RemoveDownload(name, fileType, true, (aborted and "cancel") or (success and "success") or "fail")
	end

	if not success then
		Chotify:Post({
			title = i18n("download_failed"),
			body = (name or "???") .. " of type " .. (fileType or "???"),
		})
	end
end

function wrapperFunctions.DownloadFileProgress(name, progress, totalLength)
	local index = GetDownloadIndexByName(downloadQueue, name)
	if not index then
		return
	end

	totalLength = (tonumber(totalLength or 0) or 0)/1023^2
	CallListeners("DownloadProgress", downloadQueue[index].id, totalLength*math.min(1, (tonumber(progress or 0) or 0)/100), totalLength, downloadQueue[index].name)
end

function wrapperFunctions.ImageDownloadFinished(requestToken, imageUrl, imagePath)
	CallListeners("ImageDownloadFinished", requestToken, imageUrl, imagePath)
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

function widget:Update()
	if requestUpdate then
		DownloadQueueUpdate()
	end
end

function widget:DownloadProgress(downloadID, downloaded, total)
	local index = GetDownloadBySpringDownloadID(downloadQueue, downloadID)
	if not index then
		return
	end
	downloaded = downloaded / 1024 / 1024
	total = total / 1024 / 1024
	CallListeners("DownloadProgress", downloadQueue[index].id, downloaded, total, downloadQueue[index].name)
end

function widget:DownloadStarted(downloadID)
	local index = GetDownloadBySpringDownloadID(downloadQueue, downloadID)
	if not index then
		return
	end
	local data = downloadQueue[index]

	CallListeners("DownloadStarted", data.id, data.name, data.fileType)
end

function widget:DownloadFinished(downloadID)
	local index = GetDownloadBySpringDownloadID(downloadQueue, downloadID)
	if not index then
		return
	end
	local data = downloadQueue[index]

	if (data.fileType == 'RAPID' or data.fileType == 'game') and SaveLobbyVersionGZPath then
		RestoreVersionGZ(SaveLobbyVersionGZPath)
	end

	RemoveDownload(data.name, data.fileType, true, "success")
end

function widget:DownloadFailed(downloadID, errorID)
	local index = GetDownloadBySpringDownloadID(downloadQueue, downloadID)
	Spring.Log("Chobby", LOG.WARNING, "Download Failed for ID: " .. tostring(downloadID) .. ", errorID: " .. tostring(errorID))
	if not index then
		return
	end
	local data = downloadQueue[index]

	RemoveDownload(data.name, data.fileType, true, "fail")
end

function widget:DownloadQueued(downloadID, archiveName, archiveType)
	AssociatedSpringDownloadID(downloadID, archiveName, archiveType)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Initialization


local function TestDownload()
	WG.WrapperLoopback.DownloadFile("Sands of Time v1.0", "MAP")
	Spring.Echo("TestDownload")
	Chotify:Post({
		title = "Download Failed",
		body = "Starting backup download for " .. ("Sands of Time v1.0" or "???"),
	})
end

local function GetRequiredDownloads()
	local Configuration = WG.Chobby.Configuration
	SaveLobbyVersionGZPath = Configuration and Configuration.gameConfig and Configuration.gameConfig.SaveLobbyVersionGZPath
	if SaveLobbyVersionGZPath then
		SaveVersionGZ(SaveLobbyVersionGZPath)
		RestoreVersionGZ(SaveLobbyVersionGZPath .. "_cache.gz")
	end

	local skirmishPages = Configuration.gameConfig and Configuration.gameConfig.skirmishSetupData and Configuration.gameConfig.skirmishSetupData.pages
	if skirmishPages then
		for i = 1, #skirmishPages do
			local pageData = skirmishPages[i]
			if pageData.name == "map" and pageData.getDynamicOptions then
				local gameTypes = skirmishPages[1] and skirmishPages[1].options
                if gameTypes then
                    for gameTypeIndex = 1, #gameTypes do
                        local dynamicOptions = pageData.getDynamicOptions({gameType = gameTypeIndex})
                        if dynamicOptions then
                            for j = 1, #dynamicOptions do
                                externalFunctions.MaybeDownloadArchive(dynamicOptions[j], "map", 2)
                            end
                        end
                    end
                end
			end
		end
	end
end

-- Allow for earling listener registration.
WG.DownloadHandler = externalFunctions
function widget:Initialize()
	CHOBBY_DIR = LUA_DIRNAME .. "widgets/chobby/"
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	WG.DownloadWrapperInterface = wrapperFunctions
	WG.Delay(GetRequiredDownloads, 1)
end
