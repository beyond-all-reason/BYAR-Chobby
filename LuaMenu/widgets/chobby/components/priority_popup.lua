PriorityPopup = Component:extends{}

function PriorityPopup:init(mainWindow, cancelFunction, acceptFunction, parentControlOverride, hideWindow, disableAcceptHotkey)
	local sentTime
	local startTime

	self.mainWindow = mainWindow

	self.hideWindow = hideWindow

	local function KeyListener(key)
		if cancelFunction and key == Spring.GetKeyCode("esc") then
			cancelFunction()
			return true
		elseif (not disableAcceptHotkey) and (acceptFunction and (key == Spring.GetKeyCode("enter") or key == Spring.GetKeyCode("numpad_enter"))) then
			acceptFunction()
			return true
		end
	end

	interfaceRoot.SetGlobalKeyListener(KeyListener)

	self.background = Control:New {
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		padding = {0,0,0,0},
		margin = {0,0,0,0},
		parent = parentControlOverride or WG.Chobby.lobbyInterfaceHolder,
		greedyHitTest = true,
		Draw = function()
			if not startTime then
				startTime = os.clock()
				WG.LimitFps.ForceRedrawPeriod(1)
			end

			if not sentTime then
				local diff = os.clock() - startTime
				diff = math.min(0.1, diff) / 0.1

				gl.PushMatrix()
				gl.Color(0, 0, 0, 0.5 * diff)

				gl.BeginEnd(GL.QUADS,
					function()
						local w, h = gl.GetViewSizes()

						gl.TexCoord(0, 1)
						gl.Vertex(0, 0)

						gl.TexCoord(0, 0)
						gl.Vertex(0, h/(WG.uiScale or 1))

						gl.TexCoord(1, 0)
						gl.Vertex(w/(WG.uiScale or 1), h/(WG.uiScale or 1))

						gl.TexCoord(1, 1)
						gl.Vertex(w/(WG.uiScale or 1), 0)
					end
				)
				gl.PopMatrix()
			else
				local diff = os.clock() - sentTime
				diff = math.min(0.1, diff) / 0.1
				if diff == 1 then
					self.background:Dispose()
				end

				gl.PushMatrix()
				gl.Color(0.5, 0.5, 0.5, 0.7 * (1 - diff))

				gl.BeginEnd(GL.QUADS,
					function()
						local w, h = gl.GetViewSizes()

						gl.TexCoord(0, 1)
						gl.Vertex(0, 0)

						gl.TexCoord(0, 0)
						gl.Vertex(0, h/(WG.uiScale or 1))

						gl.TexCoord(1, 0)
						gl.Vertex(w/(WG.uiScale or 1), h/(WG.uiScale or 1))

						gl.TexCoord(1, 1)
						gl.Vertex(w/(WG.uiScale or 1), 0)
					end
				)
				gl.PopMatrix()
			end
		end,
		OnMouseDown = {
			function ()
				return true -- Eat all the mouse clicks.
			end
		},
	}

	screen0:FocusControl(self.background)

	local function HideDisposeFunc()
		self:unregister()
		self.background:Dispose()
		interfaceRoot.SetGlobalKeyListener()
	end

	self.mainWindow:BringToFront()

	self.mainWindow.OnDispose = self.mainWindow.OnDispose or {}
	self.mainWindow.OnDispose[#self.mainWindow.OnDispose + 1] = HideDisposeFunc
	self.mainWindow.OnHide = self.mainWindow.OnHide or {}
	self.mainWindow.OnHide[#self.mainWindow.OnHide + 1] = HideDisposeFunc

	local sw, sh = Spring.GetWindowGeometry()
	self:ViewResize(sw, sh)

	self:super('init')
end

function PriorityPopup:ViewResize(screenWidth, screenHeight)
	self.background:BringToFront()
	self.mainWindow:BringToFront()

	self.mainWindow:SetPos(
		math.floor((screenWidth - self.mainWindow.width)/2),
		math.floor((screenHeight - self.mainWindow.height)/2)
	)
end

function PriorityPopup:GetWindow()
	return self.mainWindow
end

function PriorityPopup:ClosePopup()
	if self.hideWindow then
		self.mainWindow:Hide()
	else
		self.mainWindow:Dispose()
	end
end
