--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:GetInfo()
	return {
		name      = "Cache Rapid Pool",
		desc      = "Runs through the HDD while lobby is open trying to open files",
		author    = "Beherith",
		date      = "2023.04.03",
		license   = "GPL-v2",
		layer     = -3000,
		enabled   = false,
	}
end

local worktime = 0.1 -- in seconds per update
local poolbasepath = "pool/"
local poolDirs = {} -- ordered list of pool dirs
local poolDirContents = {} -- table of pooldir to file contents, true for already managed, false for fresh
local hexchars = {'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'}
local thresholdHDD = 80 -- in MB/s 

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Initialization
local current_index = 1
local maxpools = 256
local current_pool = ""
local VFS_RAW = VFS.RAW
local loaded = 0
local totaltime = 0
local totalKB = 0
local firstrun = true
local garbage = 0

function widget:Initialize()
	Spring.Echo("Initializing Cache Rapid Pool")
	local i = 0
	for _,c1 in ipairs(hexchars) do 
		for _,c2 in ipairs(hexchars) do 
			i = i + 1
			local pooldir = poolbasepath .. c1 ..c2 ..'/'
			poolDirs[i] = pooldir
			poolDirContents[pooldir] = false
			maxpools = i
		end
	end
	current_pool = poolDirs[current_index]
	--if VFS.FileExists(current_pool, VFS_RAW) ~= true then 
	--	Spring.Echo("Unable to find rapid pool at", current_pool)
	--	widgetHandler:RemoveWidget()
	--end
end

function widget:Update()
	local startTime = Spring.GetTimer()
	local loadedNow = 0
	local nowKB = 0
	while (Spring.DiffTimers(Spring.GetTimer(), startTime) < worktime) do
		if poolDirContents[current_pool] == false then -- fresh pool to work on	
			poolDirContents[current_pool] = VFS.DirList(current_pool, '*.gz',VFS_RAW)
			--Spring.Echo("Adding dir to work", current_pool, #poolDirContents[current_pool])
		else
			local nextfile = next(poolDirContents[current_pool])
			if nextfile then 
				loaded = loaded + 1
				local data = VFS.LoadFile(poolDirContents[current_pool][nextfile], VFS_RAW)
				nowKB = nowKB + string.len(data) / 1024
				garbage = garbage + nowKB
				poolDirContents[current_pool][nextfile] = nil
				loadedNow = loadedNow + 1
			else
				poolDirContents[current_pool] = true -- clears the table
				-- increment pool counter
				if current_index < maxpools then 
					current_index = current_index + 1
					current_pool = poolDirs[current_index]
				else
					-- ran out of pools, remove self
					Spring.Echo("Pool Cacher Done, total files loaded:", loaded)
					widgetHandler:RemoveWidget()
					break
				end
			end
		end
	end

	if garbage > 300000 then
		collectgarbage("collect")
		garbage = 0
	end

	local realTime = Spring.DiffTimers(Spring.GetTimer(), startTime)
	totaltime = totaltime + realTime
	totalKB = totalKB + nowKB
	Spring.Echo(string.format("Pool Cacher loaded %d files (%d KB, %.2f MB/s) in %.2fs", loadedNow, nowKB, 0.001*nowKB/realTime, realTime))
	if firstrun then
		if (0.001*nowKB/realTime) < thresholdHDD then
			Spring.Echo("Cache Rapid Pool: Your load times are low, advise pre-caching")
		end
		firstrun = false
	end

end

function widget:Shutdown()
	Spring.Echo(string.format("Pool Cacher Done with %d files (%d KB, %.2f MB/s) in %.2fs", loaded, totalKB, 0.001*totalKB/totaltime,  totaltime))
end