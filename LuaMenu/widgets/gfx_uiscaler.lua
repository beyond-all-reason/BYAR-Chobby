
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

local vsx,vsy = 0,0
local panel_layout = 1

function uiScaler()
	if WG.Chobby and WG.Chobby.Configuration and WG.Chobby.Configuration.uiScale then
        local old_vsx, old_vsy = vsx, vsy
		vsx,vsy = Spring.Orig.GetViewSizes()

        if vsx ~= old_vsx or vsy ~= old_vsy or panel_layout ~= WG.Chobby.Configuration.panel_layout then
			panel_layout = WG.Chobby.Configuration.panel_layout
			if WG.Chobby.Configuration.panel_layout == 1 then
				WG.Chobby.Configuration:SetConfigValue('uiScale', vsx / 1920)	-- two panels
			else
				WG.Chobby.Configuration:SetConfigValue('uiScale', vsx / 1600)	-- single panel
			end
        end
	end
end

function widget:ViewResize()
	uiScaler()
end

function widget:Update()
	uiScaler()
end

function widget:Initialize()
	widget:ViewResize()
end