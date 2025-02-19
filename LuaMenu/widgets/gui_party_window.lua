--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Party Window",
		author    = "MasterBel2",
		date      = "February 2025",
		license   = "GNU LGPL, v2.1 or later",
		layer     = -100000,
		enabled   = true  --  loaded by default?
	}
end
local PartyWindow = {}

function PartyWindow.GetControl()
	partyWindow = partyWindow or WG.Chobby.PartyWindow()
	return partyWindow.window
end
function PartyWindow.Get()
    return partyWindow
end

function widget:Initialize()
	WG.PartyWindow = PartyWindow
end