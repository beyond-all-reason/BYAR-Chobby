
function widget:GetInfo()
	return {
		name = "UI scaler",
		desc = "auto scales the UI" ,
		author = "Floris",
		date = "",
		license = "",
		layer = 0,
		enabled = true
	}
end

function uiScaler()
	if WG.Chobby and WG.Chobby.Configuration and WG.Chobby.Configuration.uiScale then
		local vsx,vsy = Spring.Orig.GetViewSizes()
		WG.Chobby.Configuration:SetConfigValue('uiScale', vsx / 1850)
	end
end


function widget:ViewResize()
	uiScaler()
end


function widget:Initialize()
	widget:ViewResize()
end