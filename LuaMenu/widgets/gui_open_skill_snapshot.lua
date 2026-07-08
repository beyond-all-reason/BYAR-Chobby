function widget:GetInfo()
	return {
		name    = "OpenSkill Snapshot Downloader",
		desc    = "Downloads the latest OpenSkill snapshot on startup.",
		author  = "Zain M",
		date    = "Jan 18, 2025", -- modified July 8th, 2025
		license = "GNU LGPL, v2.1 or later",
		layer   = -1000,
		enabled = true,
	}
end
--taken from the data processing repository in BAR. CSV format is used over parquet 
-- if download fails, current local csv is used and if there is no local file then snapshot cache is empty. Does not block UI startup
--.bak used  during refresh since launcher resource downloads are not overwriting
local SNAPSHOT_URL = "https://data-marts.beyondallreason.dev/player_skill_snapshot.csv"
local SNAPSHOT_DIR = "data-processing-main/data_export"
local SNAPSHOT_PATH = SNAPSHOT_DIR .. "/player_skill_snapshot.csv"
local SNAPSHOT_BACKUP_PATH = SNAPSHOT_PATH .. ".bak"
local LEGACY_SNAPSHOT_PATH = "data-processing-main/data-processing-main/data_export/player_skill_snapshot.csv"
local LEGACY_SNAPSHOT_BACKUP_PATH = LEGACY_SNAPSHOT_PATH .. ".bak"
local SNAPSHOT_DOWNLOAD_NAME = "open-skill-snapshot"
local SNAPSHOT_FETCH_INTERVAL = 24 * 60 * 60
local SNAPSHOT_FETCH_CONFIG_KEY = "OpenSkillSnapshotLastSuccessfulFetch"

local fetching = false
local fetchStartedAt = 0
local onFinished
local onFailed

local function RawFileExists(path)
	local file = io.open(path, "rb")
	if file then
		file:close()
	end
	return file ~= nil
end

local function ScanVfs()
	if VFS.ScanAllDirs then VFS.ScanAllDirs() end
end

local function RemoveLegacySnapshot()
	if RawFileExists(SNAPSHOT_PATH) then
		os.remove(LEGACY_SNAPSHOT_PATH)
		os.remove(LEGACY_SNAPSHOT_BACKUP_PATH)
	end
end

local function RestoreBackup()
	if RawFileExists(SNAPSHOT_BACKUP_PATH) and not RawFileExists(SNAPSHOT_PATH) then
		local ok, err = os.rename(SNAPSHOT_BACKUP_PATH, SNAPSHOT_PATH)
		if not ok then
			Spring.Log("Chobby", LOG.WARNING, "Failed to restore OpenSkill snapshot backup:", tostring(err))
		end
	end
	ScanVfs()
end

local function RemoveListeners()
	local handler = WG.DownloadHandler
	if handler then
		if onFinished then handler.RemoveListener("DownloadFinished", onFinished) end
		if onFailed then handler.RemoveListener("DownloadFailed", onFailed) end
	end
	onFinished, onFailed = nil, nil
end

local function FinishFetch(success, warning)
	fetching = false
	RemoveListeners()

	if success and RawFileExists(SNAPSHOT_PATH) then
		os.remove(SNAPSHOT_BACKUP_PATH)
		RemoveLegacySnapshot()
		Spring.SetConfigInt(SNAPSHOT_FETCH_CONFIG_KEY, fetchStartedAt)
		ScanVfs()
		return
	end

	if warning then
		Spring.Log("Chobby", LOG.WARNING, warning)
	end
	RestoreBackup()
end

local function download_snapshot()
	local handler = WG.DownloadHandler
	if not (handler and handler.MaybeDownloadArchive) or fetching then
		return
	end

	RestoreBackup()
	RemoveLegacySnapshot()

	local now = os.time()
	local lastFetch = Spring.GetConfigInt(SNAPSHOT_FETCH_CONFIG_KEY, 0)
	if RawFileExists(SNAPSHOT_PATH) and lastFetch > 0 and (now - lastFetch) < SNAPSHOT_FETCH_INTERVAL then
		return
	end

	Spring.CreateDir(SNAPSHOT_DIR)
	os.remove(SNAPSHOT_BACKUP_PATH)
	if RawFileExists(SNAPSHOT_PATH) then
		local ok, err = os.rename(SNAPSHOT_PATH, SNAPSHOT_BACKUP_PATH)
		if not ok then
			Spring.Log("Chobby", LOG.WARNING, "Failed to move old OpenSkill snapshot before refresh:", tostring(err))
			return
		end
	end

	fetching = true
	fetchStartedAt = now
	onFinished = function(_, _, name, fileType)
		if name == SNAPSHOT_DOWNLOAD_NAME and fileType == "resource" then
			FinishFetch(true, "OpenSkill snapshot download reported success but no file was written. Restoring previous snapshot")
		end
	end
	onFailed = function(_, _, errorID, name, fileType)
		if name == SNAPSHOT_DOWNLOAD_NAME and fileType == "resource" then
			FinishFetch(false, "OpenSkill csv download failed: " .. tostring(errorID))
		end
	end

	handler.AddListener("DownloadFinished", onFinished)
	handler.AddListener("DownloadFailed", onFailed)
	handler.MaybeDownloadArchive(SNAPSHOT_DOWNLOAD_NAME, "resource", -1, {
		url = SNAPSHOT_URL,
		destination = SNAPSHOT_PATH,
		extract = false,
	})
end

function widget:Initialize()
	WG.OpenSkillSnapshotPath = SNAPSHOT_PATH
	download_snapshot()
end
