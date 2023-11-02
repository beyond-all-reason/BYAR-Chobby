ListWindow = Component:extends{}

function ListWindow:init(parent, title, noWindow, windowClassname, noClose, customPadding, bottomSpacing)
	self:DoInit() -- Lack of inheritance strikes again.

	self.CancelFunc = function ()
		self:HideWindow()
	end

	local ControlType = Window
	if noWindow then
		ControlType = Control
	end

	self.window = ControlType:New {
		x = 0,
		right = 0,
		y = 0,
		bottom = 0,
		parent = parent,
		resizable = false,
		draggable = false,
		padding = customPadding or {0, 0, 0, 0},
		classname = windowClassname,
		OnDispose = {
			function()
				self:RemoveListeners()
			end
		},
	}

	if title then
		self.lblTitle = Label:New {
			x = 20,
			right = 5,
			y = 17,
			height = 20,
			objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
			caption = title,
			parent = self.window
		}
	end

	if not noClose then
		self.btnClose = Button:New {
			right = 12,
			y = 7,
			width = 80,
			height = 45,
			caption = i18n("close"),
			objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
			classname = "negative_button",
			OnClick = {
				function()
					self.CancelFunc()
				end
			},
			parent = self.window
		}
	end

	self.listPanel = ScrollPanel:New {
		x = 12,
		right = 12,
		y = 57,
		bottom = bottomSpacing or 16,
		horizontalScrollbar = false,
		padding = {4, 4, 4, 4},
		borderColor = {0,0,0,0},
		OnResize = {
			function()
				self:OnResize()
			end
		},
		parent = self.window
	}
	self.scrollChildren = 0

	self.columns = 1
	self.itemHeight = 60
	self.itemPadding = 2
	self:Clear()
end

function ListWindow:OnResize()
	if self.listPanel and self.listPanel.clientWidth and self.minItemWidth then
		local myWidth = self.listPanel.clientWidth
		local widthFactor = math.floor(myWidth/self.minItemWidth)
		local newColumns = math.max(1, widthFactor)
		if self.columns ~= newColumns then
			self.columns = newColumns
			for i = 1, #self.orderPanelMapping do
				self:RecalculatePosition(i)
			end
		end
	end
end

function ListWindow:SetMinItemWidth(newMinItemWidth)
	if newMinItemWidth then
		self.minItemWidth = newMinItemWidth
		self:OnResize()
	else
		self.minItemWidth = false
	end
end

function ListWindow:HideWindow()
	self.window:Hide()
end

function ListWindow:AddListeners()
end

function ListWindow:RemoveListeners()
end

function ListWindow:Clear()
	self.listPanel:ClearChildren()
	self.scrollChildren = 0
	self.itemNames = {}
	self.itemPanelMapping = {} -- {id = panel{Index = placeinlist, id = id, inFilter = bool}}, maps 
	self.orderPanelMapping = {} -- {index = panel{Index = placeinlist, id = id, inFilter = bool}}
end

function ListWindow:AddRow(items, id)
	if self.itemPanelMapping[id] then
		--Spring.Log("Chobby", LOG.ERROR, "Tried to add duplicate list window item", id)
		return
	end
	local thisWidth = items[#items].x + items[#items].width

	local itemNames = {}
	for i = 1, #items do
		itemNames[items[i].name] = items[i]
	end

	self.itemNames[id] = itemNames

	local container = Control:New {
		name = "container",
		width = "100%",
		y = 0,
		height = self.itemHeight,
		padding = {0, 0, 0, 0},
		children = items,
	}
	local panel = LayoutPanel:New {
		x = 0,
		right = 0,
		height = self.itemHeight,
		padding = {0, 0, 0, 0},
		itemMargin = {0, 0, 0, 0},
		itemPadding = {0, 0, 0, 0},
		children = { container },
	}

	local index = self.scrollChildren + 1
	local x,y,width,height = self:CalculatePosition(index)
	local w = Control:New {
		x = x,
		width = width,
		y = y,
		height = height,
		children = { panel },
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
		id = id,
		index = index
	}
	self.scrollChildren = index
	self.listPanel:AddChild(w)
	self.itemPanelMapping[id] = w
	self.orderPanelMapping[index] = w

	w.inFilter = self:ItemInFilter(id)
	w:SetVisibility(w.inFilter)
	self:RecalculateOrder(id)
end

function ListWindow:GetRowPosition(id)
	if id and self.itemPanelMapping[id] then
		return self.itemPanelMapping[id].y
	end
end

function ListWindow:GetRowItems(id)
	return self.itemNames[id]
end

function ListWindow:CalculatePosition(index)
	local xAcross = ((index - 1)%self.columns)/self.columns
	local row = math.floor((index - 1)/self.columns)

	local x = math.floor(1000*xAcross)/10 .. "%"
	local y = self.itemPadding + row * (self.itemHeight + self.itemPadding)
	local width = math.floor(1000/self.columns)/10 .. "%"
	local height = self.itemHeight
	return x,y,width,height
end

function ListWindow:RecalculatePosition(index)
	local x,y,width,height = self:CalculatePosition(index)

	local child = self.orderPanelMapping[index]

	child._relativeBounds.left = x
	child._relativeBounds.width = width
	child:SetPos(nil, y, nil, height)
	child:UpdateClientArea()
end

-- return true if id1 should be before id2
function ListWindow:CompareItems(id1, id2)
	return true
end

function ListWindow:ItemInFilter(id)
	return true
end

function ListWindow:SetPosition(panel, index)
	local x,y, width, height = self:CalculatePosition(index)
	panel._relativeBounds.left = x
	panel._relativeBounds.width = width
	panel:SetPos(nil,y, nil, adjustFeatureHeight)
	panel:UpdateClientArea()
end

function ListWindow:UpdateFilters()
	-- this updates all the elements	
	-- should only be really called when filter parameters change, 
	-- but is now fast enough to not really care about that
	-- dont even sort filtered out items
	-- filtered item positions are also set to the end of the list.
	-- refresh filtered items
	tracy.ZoneBeginN("ListWindow:UpdateFilters")
	local infilters = {} -- array of visible IDs
	local numinfilters = 0
	local invisible = {} -- array of invisible IDs
	local numinvisible = 0
	local prevfilter = 0
	for index, panel in ipairs(self.orderPanelMapping) do
		local oldFilter = panel.inFilter
		panel.inFilter = self:ItemInFilter(panel.id)
		if panel.inFilter then
			numinfilters = numinfilters + 1
			infilters[numinfilters] = panel.id
		else
			numinvisible = numinvisible + 1
			invisible[numinvisible] = panel.id
		end
		if oldFilter then 
			prevfilter = prevfilter + 1
		end
		if oldFilter ~= panel.inFilter then -- only update on status change
			panel:SetVisibility(panel.inFilter)
		end
	end

	-- get pre-filter items
	--[[
	if self.name == "BattleListWindow" then 
		local lobby = WG.LibLobby.lobby
		if lobby then 
			for index, panel in ipairs(self.orderPanelMapping) do
				if panel.inFilter then 
					local battle = lobby:GetBattle(panel.id)
					local playerCount = lobby:GetBattlePlayerCount(panel.id)
					Spring.Echo("PRE", index, panel.id, battle.founder, battle.isRunning, playerCount, battle.passworded, battle.locked)
				end
			end
		end
	end
	--]]

	-- Create a localized lambda sort function and sort the visible ones
	local listWindow = self
	local lambda = function (id1, id2)
		return listWindow:CompareItems(id1,id2)
	end
	
	tracy.ZoneBeginN("ListWindow:UpdateFilters:insertionSort")
	local comparisons
	--infilters, comparisons =  Spring.Utilities.insertionSort(infilters, lambda, true,true)

	local len = #infilters
	for j = 2, len do
		local key = infilters[j]
		local i = j - 1
		while i > 0 and self:CompareItems(key, infilters[i]) do
			infilters[i + 1] = infilters[i]
			i = i - 1
		end
		infilters[i+1] = key
	end


	tracy.ZoneEnd()
	
	
	--tracy.ZoneBeginN("ListWindow:UpdateFilters:mergeSort")
	--table.sort(infilters, lambda)
	--tracy.ZoneEnd()

	-- add the invisible ones to the end of the sorted list
	for i = 1, numinvisible do
		infilters[numinfilters+i] = invisible[i]
	end
	local numchanged = 0
	local strchanged = ''
	-- set the position of all of them one by one if it has changed
	for newindex, id in ipairs(infilters) do
		local panel = self.itemPanelMapping[id]
		if panel.index ~= newindex then
			self:SetPosition(panel, newindex)
			self.orderPanelMapping[newindex] = panel
			strchanged = strchanged .. panel.index .. '>' .. newindex .. ' '
			numchanged = numchanged + 1 
			panel.index = newindex
		end
	end

	--[[
	if self.name == "BattleListWindow" then 
		local lobby = WG.LibLobby.lobby
		if lobby then 
			for index, panel in ipairs(self.orderPanelMapping) do
				if panel.inFilter then 
					local battle = lobby:GetBattle(panel.id)
					local playerCount = lobby:GetBattlePlayerCount(panel.id)
					Spring.Echo("POST", index, panel.id, battle.founder, battle.isRunning, playerCount, battle.passworded, battle.locked)
				end
			end
		end
	end

	if self.name == "BattleListWindow" then 
		--Spring.Utilities.TraceEcho(4)
		Spring.Echo("UpdateFilters:", numchanged, prevfilter,numinfilters, numinvisible, strchanged,comparisons)
	end
	--]]
	
	tracy.ZoneEnd()
end

function ListWindow:SwapPlaces(panel1, panel2)
	tmp = panel1.index

	local x1,y1,w1,h1 = panel1._relativeBounds.left, panel1.y, panel1._relativeBounds.width, panel1.height
	local x2,y2,w2,h2 = panel2._relativeBounds.left, panel2.y, panel2._relativeBounds.width, panel2.height

	panel1._relativeBounds.left = x2
	panel1._relativeBounds.width = w2
	panel1:SetPos(nil, y2, nil, h2)
	panel1:UpdateClientArea()

	panel2._relativeBounds.left = x1
	panel2._relativeBounds.width = w1
	panel2:SetPos(nil, y1, nil, h1)
	panel2:UpdateClientArea()

	-- Swap positions in table
	panel1.index = panel2.index
	self.orderPanelMapping[panel1.index] = panel1

	panel2.index = tmp
	self.orderPanelMapping[panel2.index] = panel2
end

function ListWindow:RecalculateOrder(id)
	local panel = self.itemPanelMapping[id]
	if not panel then
		return
	end
	local index = panel.index
	panel:SetVisibility(panel.inFilter)

	-- move panel up if needed
	if panel.inFilter then
		while panel.index > 1 do
			local prevPanel = self.orderPanelMapping[panel.index - 1]
			if (not prevPanel.inFilter) or self:CompareItems(panel.id, prevPanel.id) then
				self:SwapPlaces(panel, prevPanel)
			else
				break
			end
		end
	end

	-- move panel down if needed
	while panel.index < self.scrollChildren do
		local nextPanel = self.orderPanelMapping[panel.index + 1]
		if (not panel.inFilter) or (nextPanel.inFilter and not self:CompareItems(panel.id, nextPanel.id)) then
			self:SwapPlaces(panel, nextPanel)
		else
			break
		end
	end
end

function ListWindow:RemoveRow(id)
	local panel = self.itemPanelMapping[id]
	if not panel then
		Spring.Log("Chobby", LOG.WARNING, "Trying to remove row which doesn't exist, with ID: " .. tostring(id))
		return
	end
	local index = panel.index

	-- move elements up
	while index < self.scrollChildren do
		local panel1 = self.orderPanelMapping[index]
		local panel2 = self.orderPanelMapping[index + 1]
		self:SwapPlaces(panel1, panel2)
		index = index + 1
	end
	self.orderPanelMapping[index] = nil

	self.listPanel:RemoveChild(panel)
	self.scrollChildren = self.scrollChildren - 1
	self.itemNames[id] = nil
	self.itemPanelMapping[id] = nil
end
