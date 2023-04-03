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

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Initialization
local hexchars = {'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'}
local current_index = 1
local maxpools = 256
local current_pool = "" 
local VFS_RAW = VFS.RAW
local loaded = 0

function widget:Initialize()
	Spring.Echo("Initializing Cache Rapid Pool")
	local i = 1
	for _,c1 in ipairs(hexchars) do 
		for _,c2 in ipairs(hexchars) do 
			local pooldir = poolbasepath .. c1 ..c2 ..'/'
			poolDirs[i] = pooldir
			poolDirContents[pooldir] = false
			i = i + 1
		end
	end
	current_pool = poolDirs[current_index]
end

function widget:Update()
	local startTime = Spring.GetTimer()
	local loadedNow = 0
	while (Spring.DiffTimers(Spring.GetTimer(), startTime) < worktime) do
		if poolDirContents[current_pool] == false then -- fresh pool to work on	
			poolDirContents[current_pool] = VFS.DirList(current_pool, '*.gz',VFS_RAW)
			Spring.Echo("Adding dir to work", current_pool, #poolDirContents[current_pool])
		else
			local nextfile = next(poolDirContents[current_pool])
			if nextfile then 
				loaded = loaded + 1
				VFS.LoadFile(nextfile)
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
	Spring.Echo("Pool Cacher loaded ", loadedNow, "files total", loaded)
end

