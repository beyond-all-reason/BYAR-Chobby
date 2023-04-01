--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Animation control",
		desc      = "Handles ChiliFX and Chobby integration",
		author    = "gajop",
		date      = "Heisei-era year 29, 3rd month, 11th day",
		license   = "GPL-v2",
		layer     = 0,
		handler   = true,
		enabled   = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Initialize

function DelayedInitialize()
	local Configuration = WG.Chobby.Configuration

	ChiliFX:SetEnabled(Configuration.animate_lobby)

	Configuration:AddListener("OnConfigurationChange",
		function(listener, key, value)
			if key == "animate_lobby" then
				ChiliFX:SetEnabled(value)
			end
		end
	)
end

function widget:Initialize()
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	WG.Delay(DelayedInitialize, 1)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
