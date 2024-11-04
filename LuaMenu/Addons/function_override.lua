-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
function widget:GetInfo()
	return {
		name      = "Function Override",
		desc      = "Overrides some inbuilt spring functions",
		author    = "GoogleFrog",
		date      = "2018",
		license   = "GPL2",
		layer     = -9999,
		enabled   = true,
		api       = true,
		hidden    = true,
	}
	end
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
-- Scaling
-- hack window geometry

-- gl.GetViewSizes intentionally not overridden
function widget:Initialize()
	Spring.Orig = Spring.Orig or {}

	Spring.Echo("Spring.GetWindowGeometry", Spring.GetWindowGeometry())
	Spring.Echo("Spring.GetViewGeometry", Spring.GetViewGeometry())
	Spring.Echo("gl.GetViewSizes", gl.GetViewSizes())

	Spring.Orig.GetWindowGeometry = Spring.GetWindowGeometry
	Spring.Orig.GetViewGeometry = Spring.GetViewGeometry
	Spring.Orig.GetViewSizes = gl.GetViewSizes
	Spring.Orig.GetMouseState = Spring.GetMouseState

	Spring.GetWindowGeometry = function()
		local vsx, vsy, vx, vy = Spring.Orig.GetWindowGeometry()
		return vsx/(WG.uiScale or 1), vsy/(WG.uiScale or 1), vx, vy
	end

	Spring.GetViewGeometry = function()
		local vsx, vsy, vx, vy = Spring.Orig.GetViewGeometry()
		return vsx/(WG.uiScale or 1), vsy/(WG.uiScale or 1), vx, vy
	end

	Spring.GetViewSizes = function()
		local vsx, vsy = Spring.Orig.GetViewSizes()
		return vsx/(WG.uiScale or 1), vsy/(WG.uiScale or 1), vx, vy
	end

	Spring.GetMouseState = function()
		local mx, my, left, right, mid, offscreen = Spring.Orig.GetMouseState()
		return mx/(WG.uiScale or 1), my/(WG.uiScale or 1), left, right, mid, offscreen
	end
end