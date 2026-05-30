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
-- Helpers
--------------------------------------------------------------------------------

--- Build a set of .sdp filesystem paths that are backing currently-loaded
--- archives (e.g. the chobby menu archive, base content).  These must NOT
--- be deleted or the engine will lose access to menu textures/etc. when it
--- performs internal VFS remap operations (e.g. battle preview UseArchive).
local function GetProtectedSdpPaths()
	local protected = {}
	local archives = VFS.GetLoadedArchives()
	if not archives then
		return protected
	end
	for i = 1, #archives do
		local archivePath = VFS.GetArchivePath(archives[i])
		if archivePath then
			-- Normalise path separators so the lookup works cross-platform
			archivePath = archivePath:gsub("\\", "/")
			protected[archivePath] = true
			Spring.Log(LOG_SECTION, LOG.INFO,
				"Protecting loaded archive: " .. archives[i] .. " -> " .. archivePath)
		end
	end
	return protected
end

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

	-- 2. Determine which .sdp files are backing currently-loaded archives.
	--    These MUST be preserved to avoid VFS failures during this session
	--    (e.g. texture loss when the engine remaps archives for battle preview).
	local protected = GetProtectedSdpPaths()

	-- 3. Delete stale .sdp manifests, skipping protected ones.
	--    Pool files (the actual game data, ~2 GB) are NOT touched.
	--    The launcher's pr-downloader will re-download active .sdp manifests
	--    (<1 MB total) before the next game launch.
	local deleted = 0
	local skipped = 0
	local failed  = 0
	for i = 1, totalCount do
		local path = sdpFiles[i]:gsub("\\", "/")
		if protected[path] then
			skipped = skipped + 1
		else
			local ok, err = os_remove(sdpFiles[i])
			if ok then
				deleted = deleted + 1
			else
				failed = failed + 1
				if failed <= 3 then
					Spring.Log(LOG_SECTION, LOG.WARNING,
						"Failed to remove: " .. tostring(sdpFiles[i]) .. " — " .. tostring(err))
				end
			end
		end
	end

	-- 4. Delete the archive cache so the engine rebuilds it smaller on next start.
	--    The current cache can be 10+ MB with 1000+ entries; after cleanup it
	--    will rebuild with only the remaining archives.
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

	-- 5. Log summary
	local savedMs = math.floor(deleted * MS_PER_PACKAGE)
	Spring.Echo(string.format(
		"[%s] Cleaned up %d / %d stale .sdp packages (%d skipped as in-use, %d failed). " ..
		"Estimated next-startup speedup: ~%dms. Pool files preserved.",
		LOG_SECTION, deleted, totalCount, skipped, failed, savedMs
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
