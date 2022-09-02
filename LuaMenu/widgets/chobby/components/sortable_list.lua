SortableList = Component:extends{}

function SortableList:init(holder, headings, itemHeight, defaultSort, sortDirection, scrollPanelOverride)
	self:DoInit() -- Lack of inheritance strikes again.

	self.sortBy = false
	self.smallToLarge = sortDirection
	if self.smallToLarge == nil then
		self.smallToLarge = true
	end

	self.holder = holder

	self.controlById = {}
	self.sortDataById = {}
	self.items = 0
	self.identifierList = {}

	self.headingButtons = {}

	self.sortBy = defaultSort or 1
	if headings then
		for i = 1, #headings do
			local heading = headings[i]
			self.headingButtons[i] = Button:New {
				x = heading.x,
				y = 0,
				right = heading.right,
				width = heading.width,
				height = 38,
				caption = heading.name,
				font = Configuration:GetFont(3),
				tooltip = heading.tooltip,
				classname = "button_small",
				parent = self.holder,
				OnClick = {
					function ()
						if self.sortBy == i then
							self.smallToLarge = not self.smallToLarge
						else
							self.sortBy = i
							self.smallToLarge = true
						end
						self:UpdateOrder()
					end
				},
			}
			if heading.image then
				Image:New {
					x = 0,
					y = 0,
					right = 0,
					bottom = 0,
					keepAspect = true,
					file = heading.image,
					parent = self.headingButtons[i],
				}
			end
		end
	end

	if scrollPanelOverride then
		scrollPanelOverride.OnResize = scrollPanelOverride.OnResize or {}
		scrollPanelOverride.OnResize[#scrollPanelOverride.OnResize + 1] = function()
			self:OnResize()
		end
		self.listPanel = scrollPanelOverride
	else
		self.listPanel = ScrollPanel:New {
			x = 0,
			right = 0,
			y = (headings and 42) or 0,
			bottom = 0,
			borderColor = {0,0,0,0},
			horizontalScrollbar = false,
			parent = self.holder,
			OnResize = {
				function()
					self:OnResize()
				end
			}
		}
	end

	self.itemHeight = itemHeight or 40
	self.itemPadding = 3
end

function SortableList:OnResize()
	for i = 1, self.items do
		self:RecalculatePosition(i)
	end
end

function SortableList:Clear()
	self.listPanel:ClearChildren()
	self.controlById = {}
	self.sortDataById = {}
	self.items = 0
	self.identifierList = {}
end

function SortableList:AddItem(id, control, sorting)
	if self.controlById[id] then
		Spring.Echo("ListWindow dupicate item", id)
		return
	end

	self.controlById[id] = control
	self.sortDataById[id] = sorting
	self.items = self.items + 1
	self.identifierList[self.items] = id

	self.listPanel:AddChild(control)

	self:UpdateOrder()
end

function SortableList:UpdateItemSorting(id, sorting, supressResort)
	if not self.controlById[id] then
		Spring.Echo("ListWindow missing item", id)
		return
	end

	self.sortDataById[id] = sorting
	if not supressResort then
		self:UpdateOrder()
	end
end

function SortableList:AddItems(items)
	local id, control, sorting
	for i = 1, #items do
		if not self.controlById[items[i][1]] then
			id, control, sorting = items[i][1], items[i][2], items[i][3]
			self.controlById[id] = control
			self.sortDataById[id] = sorting
			self.items = self.items + 1
			self.identifierList[self.items] = id

			self.listPanel:AddChild(control)
		end
	end

	self:UpdateOrder()
end

function SortableList:RemoveItem(id)
	if not self.controlById[id] then
		Spring.Echo("SortableList tried to remove non-existent item", id)
		return
	end

	for i = 1, self.items do
		if self.identifierList[i] == id then
			self.identifierList[i] = self.identifierList[self.items]
			self.identifierList[self.items] = nil
			self.items = self.items - 1
			break
		end
	end

	self.listPanel:RemoveChild(self.controlById[id])
	self.controlById[id] = nil
	self.sortDataById[id] = nil

	self:UpdateOrder()
end

function SortableList:ScrollToItem(id)
	if not self.controlById[id] then
		Spring.Echo("SortableList tried to scroll to non-existent item", id)
		return
	end

	local zoomY = self.controlById[id].y or 0
	self.listPanel:SetScrollPos(0, zoomY, false, false)
end

function SortableList:RecalculatePosition(index)
	local id = self.identifierList[index]
	local y = (index - 1)*(self.itemHeight + self.itemPadding) + self.itemPadding

	local child = self.controlById[id]
	child._relativeBounds.left = self.itemPadding
	child._relativeBounds.width = nil
	child._relativeBounds.right = self.itemPadding
	child:SetPos(nil, y, nil, self.itemHeight)
	child:UpdateClientArea()
end

function SortableList:UpdateOrder()

	local function SortFunction(a, b)
		local noNil = self.sortDataById[a] and self.sortDataById[b] and self.sortDataById[a][self.sortBy] and self.sortDataById[b][self.sortBy]
		if self.smallToLarge then
			return noNil and self.sortDataById[a][self.sortBy] < self.sortDataById[b][self.sortBy]
		else
			return noNil and self.sortDataById[a][self.sortBy] > self.sortDataById[b][self.sortBy]
		end
	end

	if self.sortBy then
		table.sort(self.identifierList, SortFunction)
	end

	for i = 1, self.items do
		self:RecalculatePosition(i)
	end
end
