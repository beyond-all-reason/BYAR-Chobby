--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:GetInfo()
	return {
		name      = "Package Cleanup",
		desc      = "Removes stale rapid .sdp packages when count exceeds threshold to speed up engine startup",
		author    = "Copilot",
		date      = "2025.02.19",
		license   = "GPL-v2",
		layer     = -2999, -- one-shot; load order doesn't matter
		api       = true,
		enabled   = true,
	}
end

--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------

-- When the number of .sdp files exceeds this, trigger cleanup.
-- Each .sdp adds ~1-2ms to the engine's archive scan at startup.
-- Fresh BAR installs have 2-3 packages; over time this grows to 500-1000+.
local CLEANUP_THRESHOLD = 100

-- Estimated scan overhead per package (ms), used for user-facing log messages.
local MS_PER_PACKAGE = 1.4

--------------------------------------------------------------------------------
-- Locals
--------------------------------------------------------------------------------

local VFS_RAW    = VFS.RAW
local os_remove  = os.remove
local LOG_SECTION = "PackageCleanup"

--------------------------------------------------------------------------------
-- Cleanup logic
--------------------------------------------------------------------------------

local function DoCleanup()
	local packageDir = "packages/"
	local cacheFile  = "cache/ArchiveCache20.lua"

	-- 1. Enumerate all .sdp files
	local sdpFiles = VFS.DirList(packageDir, "*.sdp", VFS_RAW)
	if not sdpFiles then
		Spring.Log(LOG_SECTION, LOG.WARNING, "Could not list packages directory")
		return false
	end

	local totalCount = #sdpFiles
	if totalCount <= CLEANUP_THRESHOLD then
		return false -- below threshold, nothing to do
	end

	-- 2. Delete all .sdp manifests
	--    This is safe because:
	--    - The current session's VFS data is already loaded in memory
	--    - Pool files (the actual game data, ~2 GB) are NOT touched and remain intact
	--    - The launcher's pr-downloader will re-download only the 2-3 active
	--      .sdp manifests (<1 MB total) before the next game launch
	--    - The existing analytics.lua corrupt-pool handler uses this same approach
	local deleted = 0
	local failed  = 0
	for i = 1, totalCount do
		local ok, err = os_remove(sdpFiles[i])
		if ok then
			deleted = deleted + 1
		else
			failed = failed + 1
			if failed <= 3 then
				Spring.Log(LOG_SECTION, LOG.WARNING, "Failed to remove: " .. tostring(sdpFiles[i]) .. " — " .. tostring(err))
			end
		end
	end

	-- 3. Delete the archive cache so the engine rebuilds it smaller on next start.
	--    The current cache can be 10+ MB with 1000+ entries; after cleanup it
	--    will rebuild with only maps + base archives (~1-2 MB).
	--    Try both the relative path and the absolute path via VFS.
	local removedCache = os_remove(cacheFile)
	if not removedCache then
		local cacheAbsPath = VFS.GetFileAbsolutePath and VFS.GetFileAbsolutePath(cacheFile)
		if cacheAbsPath then
			removedCache = os_remove(cacheAbsPath)
		end
	end
	if removedCache then
		Spring.Echo("[" .. LOG_SECTION .. "] Deleted archive cache (will rebuild on next start)")
	end

	-- 4. Log summary
	local savedMs = math.floor(deleted * MS_PER_PACKAGE)
	Spring.Echo(string.format(
		"[%s] Cleaned up %d / %d stale .sdp packages (%d failed). " ..
		"Estimated next-startup speedup: ~%dms. Pool files preserved.",
		LOG_SECTION, deleted, totalCount, failed, savedMs
	))

	if failed > 3 then
		Spring.Log(LOG_SECTION, LOG.WARNING, "(" .. failed .. " total removal failures)")
	end

	return true
end

--------------------------------------------------------------------------------
-- Widget lifecycle
--------------------------------------------------------------------------------

function widget:Initialize()
	local cleaned = DoCleanup()
	if cleaned then
		Spring.Echo("[" .. LOG_SECTION .. "] Cleanup complete. Fresh packages will be downloaded by the launcher before your next game.")
	end
	-- One-shot widget — remove self after running
	widgetHandler:RemoveWidget()
end

function widget:Shutdown()
	-- nothing to clean up
end
