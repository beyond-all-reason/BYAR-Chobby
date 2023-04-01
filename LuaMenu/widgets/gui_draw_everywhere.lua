function widget:GetInfo()
	return {
		name      = "Draw Everywhere",
		desc      = "Draws everywhere.",
		author    = "GoogleFrog",
		date      = "3 Sep 2016",
		license   = "GNU GPL v2",
		layer     = -2000,
		enabled   = false
	}
end

function widget:DrawScreen()
	gl.Color(1,0,0.8,1)
	gl.Rect(-10, -10, 5000, 5000)
end

