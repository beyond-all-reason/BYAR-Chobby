function widget:GetInfo()
	return {
		name    = "OpenSkill Snapshot Downloader",
		desc    = "Downloads the latest OpenSkill snapshot on startup.",
		author  = "Zain M",
		date    = "Jan 18, 2025",
		license = "GNU LGPL, v2.1 or later",
		layer   = -1000,
		enabled = true,
	}
end
--taken from the data processing repository in BAR. CSV format is used over parquet 
-- if download fails, current local csv is used and if there is no local file then snapshot cache is empty. Does not block UI startup
local SNAPSHOT_URL = "https://data-marts.beyondallreason.dev/player_skill_snapshot.csv"
local SNAPSHOT_PATH = "data-processing-main/data-processing-main/data_export/player_skill_snapshot.csv"

local function download_snapshot()
	if not (WG.DownloadHandler and WG.DownloadHandler.MaybeDownloadArchive) then
		return
	end

	Spring.CreateDir("data-processing-main/data-processing-main/data_export")
	WG.DownloadHandler.MaybeDownloadArchive(
		"open-skill-snapshot",
		"resource",
		-1,
		{
			url = SNAPSHOT_URL,
			destination = SNAPSHOT_PATH,
			extract = false,
		}
	)
end

function widget:Initialize()
	WG.OpenSkillSnapshotPath = SNAPSHOT_PATH
	download_snapshot()
end
