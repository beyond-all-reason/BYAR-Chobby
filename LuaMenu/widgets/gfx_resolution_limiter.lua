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
	-- resize resolution if is larger than screen resolution.
	--
	-- HiDPI note: Spring.Orig.GetViewSizes() (gl.GetViewSizes) returns BACKING
	-- pixels while Spring.GetScreenGeometry() returns LOGICAL points. On any
	-- HiDPI display these diverge and the original comparison would re-fire
	-- every ViewResize, creating a feedback loop (ViewResize -> SetConfigInt
	-- -> SDL_SetWindowSize -> ViewResize). Compare the *configured* resolution
	-- (logical points, as written by SaveWindowPosAndSize) against the screen
	-- instead.
	local vsx = Spring.GetConfigInt("XResolutionWindowed", 0)
	local vsy = Spring.GetConfigInt("YResolutionWindowed", 0)
	if vsx == 0 or vsy == 0 then
		vsx, vsy = Spring.Orig.GetViewSizes()
	end
	local ssx,ssy,spx,spy = Spring.GetScreenGeometry()
	if (vsx > ssx or vsy > ssy)  then
		if Spring.SendCommands ~= nil then
			if tonumber(Spring.GetConfigInt("Fullscreen",1) or 1) == 1 then
				Spring.SendCommands("Fullscreen 0")
			else
				Spring.SendCommands("Fullscreen 1")
			end
		end
		Spring.SetConfigInt("XResolution", tonumber(ssx))
		Spring.SetConfigInt("YResolution", tonumber(ssy))
		Spring.SetConfigInt("XResolutionWindowed", tonumber(ssx))
		Spring.SetConfigInt("YResolutionWindowed", tonumber(ssy))
		if Spring.SendCommands ~= nil then
			if tonumber(Spring.GetConfigInt("Fullscreen",1) or 1) == 1 then
				Spring.SendCommands("Fullscreen 0")
			else
				Spring.SendCommands("Fullscreen 1")
			end
		end
	end
end


function widget:ViewResize()
	checkResolution()
end


function widget:Initialize()
	checkResolution()
end