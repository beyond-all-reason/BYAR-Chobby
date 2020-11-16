local baseConfig = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/byar/mainConfig.lua")
local shortname = "byar-dev"
local skirmishDefault    = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/" .. shortname .. "/skirmishDefault.lua")


---------------------------------------------------------------------------------
-- Getters
---------------------------------------------------------------------------------

baseConfig.dirName                 = "byar-dev"
baseConfig.name                    = "Beyond All Reason Dev"
baseConfig.taskbarTitle            = "Beyond All Reason Dev"
baseConfig.taskbarTitleShort       = "Beyond All Reason Dev"
baseConfig._defaultGameArchiveName = "Beyond All Reason $VERSION"
baseConfig._defaultGameRapidTag    = nil
baseConfig.skirmishDefault         = skirmishDefault


return baseConfig
