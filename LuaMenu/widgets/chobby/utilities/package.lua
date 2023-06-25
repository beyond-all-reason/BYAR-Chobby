Package = {}
WG.Package = Package -- I hate this global variable system.

local RAPID_PREFIX = "rapid://"
local IGNORED_DEPS = {
    ["Spring content v1"] = true,
    ["Spring Bitmaps"] = true,
}

-- returns true | false, missingArchives
function Package.ArchiveExists(archiveName)
    if IGNORED_DEPS[archiveName] then
        return true
    end

    if archiveName:starts(RAPID_PREFIX) then
        local rapidTag = archiveName:sub(#RAPID_PREFIX+1)
        local nameFromRapid = VFS.GetNameFromRapidTag(rapidTag)
        if not nameFromRapid then
            return false, {archiveName}
        else
            archiveName = nameFromRapid
        end
    end

    if not VFS.HasArchive(archiveName) then
        return false, {archiveName}
    end

    local missing = {}
    local deps = VFS.GetArchiveDependencies(archiveName)
    for _, dep in pairs(deps) do
        local exists, depMissing = Package.ArchiveExists(dep)
        if not exists then
            for i = 1, #depMissing do
                table.insert(missing, depMissing[i])
            end
        end
    end

    if #missing > 0 then
        return false, missing
    end

    return true
end

function Package.DownloadWithDeps(archiveName, archiveType)
    local exists, missing = Package.ArchiveExists(archiveName)
    if exists then
        return
    end

    for i = 1, #missing do
        if missing[i] == archiveName then
            -- if the main archive is also missing, download using its type
            VFS.DownloadArchive(archiveName, archiveType)
        else
            -- assume all other dependencies are games
            VFS.DownloadArchive(missing[i], "game")
        end
    end
end
