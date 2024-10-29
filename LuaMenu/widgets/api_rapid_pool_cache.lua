--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:GetInfo()
	return {
		name      = "Rapid Pool Cache",
		desc      = "Runs through the HDD while lobby is open trying to open files",
		author    = "Beherith",
		date      = "2023.04.03",
		license   = "GPL-v2",
		layer     = -3000,
		enabled   = true,
	}
end

-- TODO:
-- X Stop caching on game start
-- X Display caching progress on bottom bar
-- X Disable FPS limit while caching
-- X Identify if files are already chached after running through first directory
-- X Enable for all
-- X Set default state as enabled
-- X loading image needed
-- X benchmark by running on pool dir 00

local worktime = 1/20 -- in seconds per update
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
local firsttime = 0.25
local garbage = 0
local cachingSpeed = 0
local dontspam = 0
local cachingLabel
local lobby
local localLobby

function widget:Initialize()
	Spring.Echo("Initializing Rapid Pool Cache")
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
end

local function OnBattleAboutToStart()
	Spring.Echo("Rapid Pool Cache: OnBattleAboutToStart, exiting")
	widgetHandler:RemoveWidget()
end


function widget:Update()
	if lobby == nil and WG.LibLobby then 
		lobby = WG.LibLobby.lobby
		lobby:AddListener("OnBattleAboutToStart", OnBattleAboutToStart)
	end
	if localLobby == nil and WG.LibLobby then 
		localLobby = WG.LibLobby.localLobby
		localLobby:AddListener("OnBattleAboutToStart", OnBattleAboutToStart)
	end

	local interfaceRoot = WG and WG.Chobby and WG.Chobby.interfaceRoot
	if interfaceRoot then
		--cachingImage = interfaceRoot.GetCachingImage()
		cachingLabel = interfaceRoot.GetCachingLabel()
	end
	if cachingLabel then 
		cachingLabel:SetCaption(string.format("\255\185\185\185" .. "Caching % 2d%% % 3dMB/s", (100* current_index)/maxpools, cachingSpeed))
		cachingLabel:Invalidate()
	end
	local startTime = Spring.GetTimer()
	local loadedNow = 0
	local nowKB = 0

	local thisframetime = (firstrun and firsttime) or worktime
	while (Spring.DiffTimers(Spring.GetTimer(), startTime) < thisframetime) do
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
					--Spring.Echo("Rapid Pool Cache: Pool Cacher Done, total files loaded:", loaded)
					widgetHandler:RemoveWidget()
					return
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
	cachingSpeed = 0.9 * (cachingSpeed) + 0.1 * (0.001*nowKB/realTime)


	if firstrun then
		if 0.001*nowKB/realTime < thresholdHDD then
			Spring.Echo(string.format("Rapid Pool Cache: Your load speed %dMB/s, below %dMB/s advise pre-caching", 0.001*nowKB/realTime, thresholdHDD))
		else
			Spring.Echo(string.format("Rapid Pool Cache: Your load speed %dMB/s, above %dMB/s, cache already present", 0.001*nowKB/realTime, thresholdHDD))
			widgetHandler:RemoveWidget()
		end
		firstrun = false
	else
		if dontspam % 10 == 0 then
			Spring.Echo(string.format("Rapid Pool Cache: loaded %d files (%d KB, %.2f MB/s) in %.2fs", loadedNow, nowKB, 0.001*nowKB/realTime, realTime))
		end
		dontspam = dontspam + 1
	end

end

function widget:Shutdown()
	Spring.Echo(string.format("Rapid Pool Cache: Done with %d files (%d KB, %.2f MB/s) in %.2fs", loaded, totalKB, 0.001*totalKB/totaltime,  totaltime))
	if lobby then
		lobby:RemoveListener("OnBattleAboutToStart", OnBattleAboutToStart)
	end
	if localLobby then
		localLobby:RemoveListener("OnBattleAboutToStart", OnBattleAboutToStart)
	end
	if cachingLabel then
		cachingLabel:SetVisibility(false)
	end
end