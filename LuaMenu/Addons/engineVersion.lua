
Spring.Utilities = Spring.Utilities or {}

-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
function widget:GetInfo()
	return {
		name      = "Engine Version",
		desc      = "Gets engine version",
		author    = "GoogleFrog",
		date      = "2017",
		license   = "GPL2",
		layer     = -999,
		enabled   = true,  --  loaded by default?
		api       = true,
		hidden    = true,
	}
	end
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------

function Spring.Utilities.GetEngineVersion()
	return (Game and Game.version) or (Engine and Engine.version) or "Engine version error"
end
