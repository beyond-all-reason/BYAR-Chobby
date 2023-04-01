function widget:GetInfo()
	return {
		name      = "Standalone lobby tools",
		desc      = "Standalone lobby tools",
		author    = "gajop",
		date      = "in the future",
		license   = "GPL-v2",
		layer     = 1001,
		enabled   = true,
	}
end

function widget:GameStart()
	-- Spring.SendCommands({
		-- "ResBar 0",
		-- "ToolTip 0",
		-- "Clock 0",
		-- "Info 0",
		-- "Console 0",

		-- "unbindall",

		-- "bind Any+enter chat",
		-- "bind Any+enter  edit_return",

		-- "bind Any+escape  edit_escape",
		-- "bind Any+tab  edit_complete",
		-- "bind Any+backspace  edit_backspace",
		-- "bind Any+delete  edit_delete",
		-- "bind Alt+left  edit_home",
		-- "bind Any+home  edit_home",
		-- "bind Alt+right  edit_end",
		-- "bind Any+end  edit_end",
		-- "bind Any+left  edit_prev_char",
		-- "bind Any+right  edit_next_char",
		-- "bind Ctrl+left  edit_prev_word",
		-- "bind Ctrl+right  edit_next_word",
		-- "bind Any+up  edit_prev_line",
		-- "bind Any+down  edit_next_line",
		-- "bind f12 screenshot",
		-- "bind Ctrl+f12 screenshot png",

		-- "bind Ctrl+v pastetext",
		-- "vsync 1",
	-- })
	-- Spring.SetConfigInt("MouseDragScrollThreshold", 0, true)
	-- Spring.LoadCmdColorsConfig("mouseBox 0.0 0.0 0.0 0.0")
	-- Spring.SetDrawSky(false)
	-- Spring.SetDrawWater(false)
	-- Spring.SetDrawGround(false)
	-- Spring.SetAtmosphere({fogColor = { 0.0, 0.0, 0.0, 0 }})
	-- gl.SlaveMiniMap(true)
	-- gl.ConfigMiniMap(-1,-1,-1,-1)
end
