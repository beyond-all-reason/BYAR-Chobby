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

-- Rapid tags whose current packages must survive cleanup even though they are
-- not loaded while Chobby runs (e.g. byar:test is only loaded in-game).  The
-- launcher expects these to stay installed (see dist_cfg/config.json "games")
-- and joining a battle launches the engine with them without re-downloading.
local PROTECTED_RAPID_TAGS = {
	"byar:test",
	"byar-chobby:test",
}

--------------------------------------------------------------------------------
-- Locals
--------------------------------------------------------------------------------

local VFS_RAW    = VFS.RAW
local os_remove  = os.remove
local LOG_SECTION = "PackageCleanup"

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

--- Extract the lowercased filename from a path. Comparison must happen on
--- the filename, not the full path: VFS.DirList returns datadir-relative
--- paths ("packages/xxx.sdp") while VFS.GetArchivePath returns absolute
--- ones, so full-path lookups never match (see BYAR-Chobby issue #1251).
--- The archive scanner itself indexes by lowercased filename, and rapid
--- .sdp names are unique content hashes, so this is collision-free.
local function GetFileName(path)
	local fileName = path:gsub("\\", "/"):match("([^/]+)$")
	return fileName and fileName:lower()
end

--- Protect an archive's backing file plus its whole dependency chain
--- (e.g. "BYAR Chobby $VERSION" pulls in "Beyond All Reason $VERSION").
local function ProtectArchiveAndDeps(protected, seen, archiveName, reason)
	if not archiveName or seen[archiveName] then
		return
	end
	seen[archiveName] = true
	local archivePath = VFS.GetArchivePath(archiveName)
	local fileName = archivePath and GetFileName(archivePath)
	if fileName then
		protected[fileName] = true
		Spring.Log(LOG_SECTION, LOG.INFO,
			"Protecting " .. reason .. " archive: " .. archiveName .. " -> " .. fileName)
	end
	local deps = VFS.GetArchiveDependencies and VFS.GetArchiveDependencies(archiveName)
	if deps then
		for i = 1, #deps do
			ProtectArchiveAndDeps(protected, seen, deps[i], reason)
		end
	end
end

--- Build a set of .sdp filenames that must NOT be deleted:
---  * archives backing currently-loaded ones (the chobby menu archive, base
---    content) — deleting these breaks the running session when the engine
---    performs internal VFS remap operations (e.g. battle preview UseArchive);
---  * the current packages of PROTECTED_RAPID_TAGS and their dependencies —
---    not loaded in the menu, but launching a battle expects them on disk
---    (deleting e.g. byar:test crashes the spawned engine with
---    "Dependent archive not found");
--- Returns nil when the loaded-archive set cannot be determined; callers
--- must then abort rather than delete blindly.
local function GetProtectedSdpNames()
	if not (VFS.GetLoadedArchives and VFS.GetArchivePath) then
		return nil
	end
	local archives = VFS.GetLoadedArchives()
	if not archives or #archives == 0 then
		return nil
	end
	local protected = {}
	local seen = {}
	for i = 1, #archives do
		ProtectArchiveAndDeps(protected, seen, archives[i], "loaded")
	end
	for i = 1, #PROTECTED_RAPID_TAGS do
		local tag = PROTECTED_RAPID_TAGS[i]
		-- Resolved offline from the local rapid index (rapid/*/versions.gz)
		local archiveName = VFS.GetNameFromRapidTag and VFS.GetNameFromRapidTag(tag)
		if archiveName then
			ProtectArchiveAndDeps(protected, seen, archiveName, "rapid tag " .. tag)
		else
			Spring.Log(LOG_SECTION, LOG.WARNING,
				"Could not resolve rapid tag " .. tag .. "; its package is not protected")
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
	--    (e.g. "Dependent archive not found" crashes when the engine rescans
	--    archives on battle join, or texture loss during battle preview).
	local protected = GetProtectedSdpNames()
	if not protected then
		Spring.Log(LOG_SECTION, LOG.WARNING,
			"Could not determine loaded archives; skipping cleanup to avoid deleting in-use packages")
		return false
	end

	-- 3. Delete stale .sdp manifests, skipping protected ones.
	--    Pool files (the actual game data, ~2 GB) are NOT touched.
	--    The launcher's pr-downloader will re-download active .sdp manifests
	--    (<1 MB total) before the next game launch.
	local deleted = 0
	local skipped = 0
	local failed  = 0
	for i = 1, totalCount do
		local fileName = GetFileName(sdpFiles[i])
		if fileName and protected[fileName] then
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

	-- 5. Resync the in-memory archive scanner with the disk state.  Without
	--    this, Chobby still believes deleted archives are installed
	--    (VFS.HasArchive returns true) and will launch the engine without
	--    re-downloading them, crashing the game with "Dependent archive not
	--    found".  After the rescan, missing archives are detected normally
	--    and re-downloaded on demand.  Typically blocks well under a second.
	if deleted > 0 and VFS.ScanAllDirs then
		VFS.ScanAllDirs()
	end

	-- 6. Log summary
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
