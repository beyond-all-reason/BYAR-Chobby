--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "LibLobby API",
		desc      = "LibLobby GUI Framework",
		author    = "gajop",
		date      = "WIP",
		license   = "GPLv2",
		version   = "0.2",
		layer     = -1000,
		enabled   = true,  --  loaded by default?
		handler   = true,
		api       = true,
		hidden    = true,
	}
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- LibLobby's location

LIB_LOBBY_DIRNAME = "libs/liblobby/lobby/"

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local config
if VFS.FileExists(LUA_DIRNAME .. "configs/liblobby_configuration.lua") then
	config = VFS.Include(LUA_DIRNAME .. "configs/liblobby_configuration.lua", nil, VFS.RAW_FIRST)
else
	config = VFS.Include("libs/liblobby/" .. LUA_DIRNAME .. "configs/liblobby_configuration.lua", nil, VFS.RAW_FIRST)
end

function widget:Initialize()
	LCS = loadstring(VFS.LoadFile("libs/lcs/LCS.lua"))
	LCS = LCS()

	WG.Server = config.server
	Spring.Log("liblobby", LOG.NOTICE, "liblobby configuration: ")
	for k, v in pairs(WG.Server) do
		Spring.Log("liblobby", LOG.NOTICE, k, v)
	end
	if WG.Server.protocol == "zks" then
		Interface = VFS.Include(LIB_LOBBY_DIRNAME .. "interface_zerok.lua", nil, VFS.RAW_FIRST)
	elseif WG.Server.protocol == "spring" then
		Interface = VFS.Include(LIB_LOBBY_DIRNAME .. "interface.lua", nil, VFS.RAW_FIRST)
	else
		Spring.Log("liblobby", LOG.ERROR, "Invalid liblobby interface specified: " .. tostring(WG.Server.interface))
	end
	InterfaceSkirmish = VFS.Include(LIB_LOBBY_DIRNAME .. "interface_skirmish.lua", nil, VFS.RAW_FIRST)
	self.lobby = Interface()

	self.localLobby = InterfaceSkirmish()

	--// Export Widget Globals
	WG.LibLobby = {
		lobby = self.lobby, -- instance (singleton)
		localLobby = self.localLobby
	}

end

function widget:Shutdown()
	WG.LibLobby = nil
end

function widget:Update()
	WG.LibLobby.lobby:Update()
end
