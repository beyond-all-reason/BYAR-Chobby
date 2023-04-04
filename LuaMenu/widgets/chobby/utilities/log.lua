Log = Log or {}

LOG_SECTION = "Chobby"

-- simplified Spring.Log, see https://springrts.com/wiki/Lua_UnsyncedCtrl#Ingame_Console

function Log.Error(text)
	Spring.Log(LOG_SECTION, LOG.ERROR, text)
end

function Log.Warning(text)
	Spring.Log(LOG_SECTION, LOG.WARNING, text)
end

-- this should perhaps be the default and replace Spring.Echo
-- tempted to call this Info, but the actual info (LOG.INFO doesn't get printed out by default)
function Log.Notice(text)
	Spring.Log(LOG_SECTION, LOG.NOTICE, text)
end

-- enable debug printout in dev builds? (Spring.SetLogSectionFilterLevel)
function Log.Debug(text)
	Spring.Log(LOG_SECTION, LOG.DEBUG, text)
end
