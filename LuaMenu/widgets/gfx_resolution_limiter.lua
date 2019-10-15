
function widget:GetInfo()
	return {
		name = "Resolution limiter",
		desc = "resize resolution if is larger than screen resolution" ,
		author = "Floris",
		date = "",
		license = "",
		layer = 0,
		enabled = true
	}
end

function checkResolution()
	-- resize resolution if is larger than screen resolution
	local vsx,vsy = Spring.Orig.GetViewSizes()
	local ssx,ssy,spx,spy = Spring.GetScreenGeometry()
	if (vsx > ssx or vsy > ssy) and Spring.SendCommands then
		if tonumber(Spring.GetConfigInt("Fullscreen",1) or 1) == 1 then
			Spring.SendCommands("Fullscreen 0")
		else
			Spring.SendCommands("Fullscreen 1")
		end
		Spring.SetConfigInt("XResolution", tonumber(ssx))
		Spring.SetConfigInt("YResolution", tonumber(ssy))
		Spring.SetConfigInt("XResolutionWindowed", tonumber(ssx))
		Spring.SetConfigInt("YResolutionWindowed", tonumber(ssy))
		if tonumber(Spring.GetConfigInt("Fullscreen",1) or 1) == 1 then
			Spring.SendCommands("Fullscreen 0")
		else
			Spring.SendCommands("Fullscreen 1")
		end
	end
	if WG.Chobby and WG.Chobby.Configuration and WG.Chobby.Configuration.uiScale then
		WG.Chobby.Configuration:SetConfigValue('uiScale', vsx / 1800)
	end
end


function widget:ViewResize()
	checkResolution()
end


function widget:Initialize()
	widget:ViewResize()
end