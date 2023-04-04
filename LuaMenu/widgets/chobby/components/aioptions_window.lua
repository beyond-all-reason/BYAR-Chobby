AiOptionsWindow = ListWindow:extends{}

function AiOptionsWindow:init(displayName, optionsPath, successFunc)
	self:super('init', lobbyInterfaceHolder, displayName.." Options", false, "main_window", nil, {6, 7, 7, 4})
	self.window:SetPos(nil, nil, 650, 700)
	WG.Chobby.PriorityPopup(self.window, nil, nil, nil, true)

	self.aioptions = {}

	local applyBtn = Button:New {
		right = 120,
		y = 7,
		width = 80,
		height = 45,
		caption = i18n("apply"),
		font = WG.Chobby.Configuration:GetFont(3),
		parent = self.window,
		classname = "action_button",
		OnClick = {
			function()
				successFunc(self.aioptions)
				self:HideWindow()
			end
		},
	}

	-- AIOptions
	local options = VFS.Include(optionsPath)
	for i = #options, 1, -1 do
		self:AddEntry(options[i], i)
	end
end

function AiOptionsWindow:AddEntry(data, index)
	if data.hide or data.type == "section" then
		return
	end

	self.aioptions[data.key] = tostring(data.def)

	if data.type == "list" then
		self:AddRow({self:MakeList(data)}, index)
	elseif data.type == "bool" then
		self:AddRow({self:MakeBool(data)}, index)
	elseif data.type == "number" then
		self:AddRow({self:MakeNumber(data)}, index)
	elseif data.type == "string" then
		self:AddRow({self:MakeString(data)}, index)
	end
end

function AiOptionsWindow:MakeList(data)
	local label = Label:New {
		x = 5,
		y = 0,
		width = 350,
		height = 30,
		valign = "center",
		align = "left",
		caption = data.name,
		font = WG.Chobby.Configuration:GetFont(2),
	}

	local defaultItem = 1
	local keyList = {}
	local nameList = {}
	for i, itemData in pairs(data.items) do
		keyList[i] = itemData.key
		nameList[i] = itemData.name

		if itemData.key == data.def then
			defaultItem = i
		end
	end

	local list = ComboBox:New {
		x = 340,
		y = 1,
		width = 250,
		height = 30,
		items = nameList,
		tooltip = data.desc,
		font = WG.Chobby.Configuration:GetFont(2),
		itemFontSize = WG.Chobby.Configuration:GetFont(2).size,
		selected = defaultItem,
		OnSelect = {
			function (obj)
				self.aioptions[data.key] = keyList[obj.selected]
			end
		},
	}

	return Control:New {
		x = 0,
		y = 0,
		width = 600,
		height = 32,
		padding = {0, 0, 0, 0},
		children = {
			label,
			list
		}
	}
end

function AiOptionsWindow:MakeBool(data)
	local checkBox = Checkbox:New {
		x = 5,
		y = 0,
		width = 355,
		height = 40,
		boxalign = "right",
		boxsize = 20,
		caption = data.name,
		checked = data.def,
		tooltip = data.desc,
		font = WG.Chobby.Configuration:GetFont(2),

		OnChange = {
			function (obj, newState)
				self.aioptions[data.key] = tostring(newState)
			end
		},
	}

	return checkBox
end

function AiOptionsWindow:MakeNumber(data)
	local label = Label:New {
		x = 5,
		y = 0,
		width = 350,
		height = 30,
		valign = "center",
		align = "left",
		caption = data.name,
		font = WG.Chobby.Configuration:GetFont(2),
	}

	local oldText = tostring(data.def);

	local numberBox = EditBox:New {
		x = 340,
		y = 1,
		width = 250,
		height = 30,
		text   = oldText,
		useIME = false,
		tooltip = data.desc,
		fontSize = WG.Chobby.Configuration:GetFont(2).size,
		OnFocusUpdate = {
			function (obj)
				if obj.focused then
					return
				end

				if not tonumber(obj.text) then
					obj:SetText(oldText)
					return
				end

				oldText = obj.text
				self.aioptions[data.key] = obj.text
			end
		}
	}

	return Control:New {
		x = 0,
		y = 0,
		width = 600,
		height = 32,
		padding = {0, 0, 0, 0},
		children = {
			label,
			numberBox
		}
	}
end

function AiOptionsWindow:MakeString(data)
	local label = Label:New {
		x = 5,
		y = 0,
		width = 350,
		height = 30,
		valign = "center",
		align = "left",
		caption = data.name,
		font = WG.Chobby.Configuration:GetFont(2),
	}

	local textBox = EditBox:New {
		x = 340,
		y = 1,
		width = 250,
		height = 30,
		text   = data.def,
		useIME = false,
		tooltip = data.desc,
		fontSize = WG.Chobby.Configuration:GetFont(2).size,
		OnFocusUpdate = {
			function (obj)
				if obj.focused then
					return
				end
				self.aioptions[data.key] = obj.text
			end
		}
	}

	return Control:New {
		x = 0,
		y = 0,
		width = 600,
		height = 32,
		padding = {0, 0, 0, 0},
		children = {
			label,
			textBox
		}
	}
end
