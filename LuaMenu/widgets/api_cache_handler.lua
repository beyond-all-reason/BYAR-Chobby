--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Cache Handler API",
		desc      = "Handles path cache deletion (for now).",
		author    = "GoogleFrog",
		date      = "31 December 2016",
		license   = "GNU LGPL, v2.1 or later",
		layer     = -10000,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local CacheHandler = {}

function CacheHandler.DeletePathCache()
	local path = "cache/103dev-develop/paths/"
	local cacheFiles = VFS.DirList(path)
	if cacheFiles then
		Spring.Echo("Deleting path cache", #cacheFiles)
		for i = 1, #cacheFiles do
			os.remove(cacheFiles[i])
		end
	else
		Spring.Echo("Deleting path cache error")
	end
end

function widget:Initialize()
	WG.CacheHandler = CacheHandler
end

-- May as well handle its own config, does not need to wait for the rest of chobby to load.
function widget:GetConfigData()
	return {
		engineVersion = Spring.Utilities.GetEngineVersion()
	}
end

function widget:SetConfigData(data)
	if data.engineVersion ~= Spring.Utilities.GetEngineVersion() then
		CacheHandler.DeletePathCache()
	end
	widgetHandler:RemoveCallIn("Update")
end

function widget:Update()
	CacheHandler.DeletePathCache()
	widgetHandler:RemoveCallIn("Update")
end
