----------------------------------------------------------------------------
----------------------------------------------------------------------------
-- Copy this file to the luaui/widgets folder

-- Set this line to the spring-wrapper-connection installation folder
SPRING_LAUNCHER_DIR = "libs/spring-launcher/"
JSON_LIB_PATH = "libs/json.lua"

-- Do NOT modify the following lines
function widget:GetInfo()
	return {
		name      = "spring-launcher",
		desc      = "Spring launcher connection provider",
		author    = "gajop",
		license   = "MIT",
		layer     = -10010,
		enabled   = true,
		handler   = true,
		api       = true,
		hidden    = true,
	}
end

if Script.GetName() == "LuaUI" then
	VFS.Include(SPRING_LAUNCHER_DIR .. "luaui/widgets/api_spring_launcher.lua", nil, VFS.DEF_MODE)
end
