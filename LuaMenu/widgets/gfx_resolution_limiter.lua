
function widget:GetInfo()
	return {
		name = "Resolution limiter",
		desc = "resize resolution if is larger than screen resolution" ,
		author = "Floris",
		date = "",
		license = "",
		layer = 1,
		enabled = true
	}
end

function checkResolution()
	-- resize resolution if is larger than screen resolution
	local wsx,wsy,wpx,wpy = Spring.GetWindowGeometry()
	local ssx,ssy,spx,spy = Spring.GetScreenGeometry()
	if wsx > ssx or wsy > ssy then
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
end

function widget:ViewResize()
	checkResolution()
end

function widget:Initialize()
	widget:ViewResize()
end