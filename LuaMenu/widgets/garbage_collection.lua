
function widget:GetInfo()
	return {
		name = "Garbage Collection",
		desc = "Periodically forces garbage collection" ,
		layer = -math.huge,
		enabled   = true,
	}
end


local basememlimit = 200000
local garbagelimit = basememlimit -- in kilobytes, will adjust upwards as needed
local lastGCchecktime = Spring.GetTimer()

function widget:Update()
    if Spring.DiffTimers(Spring.GetTimer(), lastGCchecktime) > 1 then
		lastGCchecktime = Spring.GetTimer()
		local ramuse = gcinfo()
		--Spring.Echo("RAMUSE",ramuse)
		if ramuse > garbagelimit then 
			collectgarbage("collect")
			collectgarbage("collect")
			local notgarbagemem = gcinfo()
			local newgarbagelimit = math.min(1000000, notgarbagemem + basememlimit) -- peak 1 GB
			local msg = string.format("Chobby Using %d MB RAM > %d MB limit, performing garbage collection to %d MB and adjusting limit to %d MB",
				math.floor(ramuse/1000), 
				math.floor(garbagelimit/1000), 
				math.floor(notgarbagemem/1000),
				math.floor(newgarbagelimit/1000) ) 
			Spring.Log("Chobby", LOG.NOTICE, msg)
			garbagelimit = newgarbagelimit
		end
	end
end