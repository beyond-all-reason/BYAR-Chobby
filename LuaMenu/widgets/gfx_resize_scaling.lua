function widget:GetInfo()
	return {
		name = "Resize Scaling",
		desc = "Updates scaling on screen resize" ,
		author = "Floris",
		date = "",
		license = "",
		layer = 0,
		enabled = true
	}
end

function widget:ViewResize()
    if WG.Chobby and WG.Chobby.Configuration then
		WG.Chobby.Configuration:UpdateUiScaleMaxMin()
        WG.Chobby.Configuration:SetUiScale()
    end
end