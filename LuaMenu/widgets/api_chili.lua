--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Chili Framework",
		desc      = "Hot GUI Framework",
		author    = "jK",
		date      = "WIP",
		license   = "GPLv2",
		version   = "2.1",
		layer     = -1000,
		enabled   = true,  --  loaded by default?
		handler   = true,
		api       = true,
		hidden    = true,
	}
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local Chili
local screen0
local th
local tk
local tf

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Chili's location

CHILI_DIRNAME = "libs/chiliui/chili/"
SKIN_DIRNAME = LUA_DIRNAME .. "widgets/chili/skins/"
THEME_DIRNAME = LUA_DIRNAME .. "widgets/chili/themes/"

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
	Chili = VFS.Include(CHILI_DIRNAME .. "core.lua", nil, VFS.RAW_FIRST)

	screen0 = Chili.Screen:New{}
	th = Chili.TextureHandler
	tk = Chili.TaskHandler
	tf = Chili.FontHandler

	--// Export Widget Globals
	WG.Chili = Chili
	WG.Chili.Screen0 = screen0

	--// do this after the export to the WG table!
	--// because other widgets use it with `parent=Chili.Screen0`,
	--// but chili itself doesn't handle wrapped tables correctly (yet)
	screen0 = Chili.DebugHandler.SafeWrap(screen0)
end

function widget:Shutdown()
	--table.clear(Chili) the Chili table also is the global of the widget so it contains a lot more than chili's controls (pairs,select,...)
	WG.Chili = nil
end

function widget:Dispose()
	screen0:Dispose()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local lastTimer = Spring.GetTimer()
local startTimer = Spring.GetTimer()
local hideInterface = true
local loadFade = 1

local totalHideInterface = falase
local loadTex = "MenuLoadscreens/loadscreen.png"

function widget:DrawScreen()
	if startTimer then
		local timer = Spring.GetTimer()
		local diff = Spring.DiffTimers(timer, lastTimer)
		lastTimer = timer
		--Spring.Echo("diff", diff)
		if diff < 0.04 or Spring.DiffTimers(timer, startTimer) > 8 then
			hideInterface = false
			startTimer = false
		end
	end
	if totalHideInterface or (WG.Chobby and WG.Chobby.Configuration and WG.Chobby.Configuration.hideInterface) then
		return
	end

	gl.Color(1,1,1,1)
	if (not screen0:IsEmpty()) then
		gl.PushMatrix()
			local vsx,vsy = gl.GetViewSizes()
			if hideInterface then
				gl.Translate(0,0,0)
				gl.Scale(1,-1,1)
			else
				gl.Translate(0,vsy,0)
				gl.Scale(1,-1,1)
			end
			gl.Scale(WG.uiScale,WG.uiScale,1)
			screen0:Draw()
		gl.PopMatrix()
	end
	gl.Color(1,1,1,1)

	if loadFade then
		local vsx,vsy = gl.GetViewSizes()
		gl.Color(1,1,1,loadFade)
		gl.Texture(loadTex)    
    -- origin bottom left
    if (vsx>= vsy) then -- wider than tall
      local pad = (vsx-vsy) / 2
      gl.TexRect(pad,0,vsx-pad, vsy)
    else -- taller than wide
      local pad = (vsy-vsx) / 2
      gl.TexRect(0,pad,vsx, vsy-pad)
    end
		gl.Color(1,1,1,1)

		if not hideInterface then
			loadFade = loadFade - 0.18
			if loadFade <= 0 then
				loadFade = false
			end
		end
	end
end


function widget:DrawLoadScreen()
	if totalHideInterface or (WG.Chobby and WG.Chobby.Configuration and WG.Chobby.Configuration.hideInterface) then
		return
	end

	gl.Color(1,1,1,1)
	if (not screen0:IsEmpty()) then
		gl.PushMatrix()
			local vsx,vsy = gl.GetViewSizes()
			gl.Scale(1/vsx,1/vsy,1)
			gl.Translate(0,vsy,0)
			gl.Scale(1,-1,1)
			screen0:Draw()
		gl.PopMatrix()
	end
	gl.Color(1,1,1,1)
end


function widget:TweakDrawScreen()
	if totalHideInterface or (WG.Chobby and WG.Chobby.Configuration and WG.Chobby.Configuration.hideInterface) then
		return
	end

	gl.Color(1,1,1,1)
	if (not screen0:IsEmpty()) then
		gl.PushMatrix()
			local vsx,vsy = gl.GetViewSizes()
			gl.Translate(0,vsy,0)
			gl.Scale(1,-1,1)
			screen0:TweakDraw()
		gl.PopMatrix()
	end
	gl.Color(1,1,1,1)
end


function widget:DrawGenesis()
	if totalHideInterface or (WG.Chobby and WG.Chobby.Configuration and WG.Chobby.Configuration.hideInterface) then
		return
	end

	gl.Color(1,1,1,1)
	tf.Update()
	th.Update()
	tk.Update()
	gl.Color(1,1,1,1)
end


function widget:IsAbove(x,y)
	if Spring.IsGUIHidden() or totalHideInterface then
		return false
	end
	if WG.uiScale and WG.uiScale ~= 1 then
		x, y = x/WG.uiScale, y/WG.uiScale
	end

	return screen0:IsAbove(x,y)
end


local mods = {}
function widget:MousePress(x,y,button)
	if Spring.IsGUIHidden() or totalHideInterface then
		return false
	end
	if WG.uiScale and WG.uiScale ~= 1 then
		x, y = x/WG.uiScale, y/WG.uiScale
	end

	local alt, ctrl, meta, shift = Spring.GetModKeyState()
	mods.alt=alt; mods.ctrl=ctrl; mods.meta=meta; mods.shift=shift;
	return screen0:MouseDown(x,y,button,mods)
end


function widget:MouseRelease(x,y,button)
	if Spring.IsGUIHidden() or totalHideInterface then
		return false
	end
	if WG.uiScale and WG.uiScale ~= 1 then
		x, y = x/WG.uiScale, y/WG.uiScale
	end

	local alt, ctrl, meta, shift = Spring.GetModKeyState()
	mods.alt=alt; mods.ctrl=ctrl; mods.meta=meta; mods.shift=shift;
	return screen0:MouseUp(x,y,button,mods)
end


function widget:MouseMove(x,y,dx,dy,button)
	if Spring.IsGUIHidden() or totalHideInterface then
		return false
	end
	if WG.uiScale and WG.uiScale ~= 1 then
		x, y, dx, dy = x/WG.uiScale, y/WG.uiScale, dx/WG.uiScale, dy/WG.uiScale
	end

	local alt, ctrl, meta, shift = Spring.GetModKeyState()
	mods.alt=alt; mods.ctrl=ctrl; mods.meta=meta; mods.shift=shift;
	return screen0:MouseMove(x,y,dx,dy,button,mods)
end


function widget:MouseWheel(up,value)
	if Spring.IsGUIHidden() or totalHideInterface then
		return false
	end

	local x,y = Spring.GetMouseState()
	local alt, ctrl, meta, shift = Spring.GetModKeyState()
	mods.alt=alt; mods.ctrl=ctrl; mods.meta=meta; mods.shift=shift;
	return screen0:MouseWheel(x,y,up,value,mods)
end


local keyPressed = true
function widget:KeyPress(key, mods, isRepeat, label, unicode)
	if Spring.IsGUIHidden() or totalHideInterface then
		return false
	end

	keyPressed = screen0:KeyPress(key, mods, isRepeat, label, unicode)
	return keyPressed
end


function widget:KeyRelease()
	if Spring.IsGUIHidden() or totalHideInterface then
		return false
	end

	local _keyPressed = keyPressed
	keyPressed = false
	return _keyPressed -- block engine actions when we processed it
end

function widget:TextInput(utf8, ...)
	if Spring.IsGUIHidden() or totalHideInterface then
		return false
	end

	return screen0:TextInput(utf8, ...)
end

function widget:TextEditing(utf8, start, length, ...)
	if Spring.IsGUIHidden() or totalHideInterface then
		return false
	end

	return screen0:TextEditing(utf8, start, length, ...)
end


local oldSizeX, oldSizeY
function widget:ViewResize(vsx, vsy)
	if totalHideInterface then
		return
	end
	local ssx, ssy = vsx/(WG.uiScale or 1), vsy/(WG.uiScale or 1)
	if oldSizeX ~= vsx or oldSizeY ~= vsy then
		oldSizeX, oldSizeY = vsx, vsy
		screen0:Resize(ssx, ssy)
	end
end

function widget:Update()
	totalHideInterface = WG.CheckTotalHideInterface and WG.CheckTotalHideInterface()
	if totalHideInterface then
		return
	end
	local screenWidth, screenHeight = Spring.Orig.GetViewSizes()
	if screenWidth ~= oldSizeX or screenHeight ~= oldSizeY then
		widget:ViewResize(screenWidth, screenHeight)
	end
end

widget.TweakIsAbove      = widget.IsAbove
widget.TweakMousePress   = widget.MousePress
widget.TweakMouseRelease = widget.MouseRelease
widget.TweakMouseMove    = widget.MouseMove
widget.TweakMouseWheel   = widget.MouseWheel

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
