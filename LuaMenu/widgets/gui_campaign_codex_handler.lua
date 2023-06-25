--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Codex Handler",
		desc      = "Knowledge is power. Guard it well",
		author    = "GoogleFrog, KingRaptor",
		date      = "24 November 2016",
		license   = "GNU LGPL, v2.1 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Local Variables

local OUTLINE_COLOR = {0.54,0.72,1,0.3}
local IMAGE_SIZE = 96
local BUTTON_FONT = 2

local selectedButton
local codexManagerStuff -- FIXME rename
local codexTree

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utilities

local function SortCodexEntries(a, b)
	if (not entryA) or (not entryB) then
		return false
	end
	local aKey = entryA.sortkey or entryA.name
	local bKey = entryB.sortkey or entryB.name
	aKey = string.lower(aKey)
	bKey = string.lower(bKey)
	return aKey < bKey
end

local function LoadCodexEntries(path)
	local codexEntries = WG.Chobby.Configuration.campaignConfig.codex

	local categories = {}
	local categoriesOrdered = {}
	for id, entry in pairs(codexEntries) do
		categories[entry.category] = categories[entry.category] or {}
		local cat = categories[entry.category]
		cat[#cat + 1] = entry
	end

	-- sort categories
	for catID in pairs(categories) do
		categoriesOrdered[#categoriesOrdered + 1] = catID
	end
	table.sort(categoriesOrdered)
	return codexEntries, categories, categoriesOrdered
end

local function UpdateCodexEntry(entry, codexText, codexImage, entryButton)
	-- Codex should handle this itself..?
	--if not WG.CampaignAPI.IsCodexEntryRead(entry.id) then
	--	--entryButton.font.outline = false
	--	entryButton.font.shadow = false
	--	entryButton:Invalidate()
	--end
	--WG.CampaignAPI.MarkCodexEntryRead(entry.id)
	codexText:SetText(entry.text)
	codexImage.file = entry.image
	codexImage:Invalidate()
end

local function ClearCodexEntry(codexText, codexImage)
	codexText:SetText("")
	codexImage.file = nil
	codexImage:Invalidate()
end

local function PopulateCodexTree(parent, codexText, codexImage)
	if codexTree then
		codexTree:Dispose()
	end

	local categoryNewEntries = {}
	local nodes = {}
	local entryButtons = {}
	local codexEntries, categories, categoriesOrdered = LoadCodexEntries()

	-- make tree view nodes
	for i = 1, #categoriesOrdered do
		local catID = categoriesOrdered[i]
		local cat = categories[catID]
		categoryNewEntries[catID] = 0
		table.sort(cat, SortCodexEntries)
		local node = {catID, {}}
		local subnode = node[2]
		for j = 1, #cat do
			local entry = cat[j]
			local unlocked, alreadyRead = WG.CampaignData.GetCodexEntryIsUnlocked(entry.id)
			if unlocked then
				local button = Button:New{
					name = entry.id,
					height = 24,
					caption = entry.name,
					OnClick = {
						function(self)
							if selectedButton and selectedButton.name == self.name then
								ButtonUtilities.SetButtonDeselected(selectedButton)
								ClearCodexEntry(codexText, codexImage)
								selectedButton = nil
								return
							end
							UpdateCodexEntry(entry, codexText, codexImage, self)
							if selectedButton then
								ButtonUtilities.SetButtonDeselected(selectedButton)
							end
							ButtonUtilities.SetButtonSelected(self)
							if WG.CampaignData.SetCodexEntryRead(entry.id) then
								categoryNewEntries[catID] = categoryNewEntries[catID] - 1
								if categoryNewEntries[catID] <= 0 and codexTree then
									local node = codexTree:GetNodeByCaption(entry.category)
									node:SetHighlight(false)
								end
							end
							selectedButton = self
						end
					},
					font = WG.Chobby.Configuration:GetFont(BUTTON_FONT)
				}

				ButtonUtilities.SetFontSizeScale(button, BUTTON_FONT)

				if not alreadyRead then
					ButtonUtilities.SetButtonHighlighted(button)
					categoryNewEntries[catID] = categoryNewEntries[catID] + 1
				end
				subnode[#subnode + 1] = button
				entryButtons[entry.id] = button
			end
		end
		nodes[#nodes + 1] = node
	end

	-- make treeview
	for i = 1, #parent.children do
		parent.children[i]:Dispose()
	end
	codexTree = Chili.TreeView:New{
		parent = parent,
		clickTextToToggle = true,
		minItemHeight = 26,
		labelFontsize = WG.Chobby.Configuration:GetFont(BUTTON_FONT).size,
		nodes = nodes, --{"wtf", "lololol", {"omg"}},
	}
	codexText:SetText("")

	for i = 1, #nodes do
		local catID = nodes[i][1]
		if categoryNewEntries[catID] > 0 then
			local nodeObj = codexTree:GetNodeByCaption(catID)
			nodeObj:SetHighlight(true)
		end
	end

	local externalFunctions = {}

	function externalFunctions.OpenEntry(entryName)
		local entry = entryName and codexEntries[entryName]
		if not (entry and entryButtons[entryName]) then
			return
		end
		local categoryNode = entry.category and codexTree:GetNodeByCaption(entry.category)
		if not categoryNode then
			return
		end
		categoryNode:Expand()
		entryButtons[entryName].OnClick[1](entryButtons[entryName])
	end

	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Controls

local function InitializeControls(parentControl)
	local Configuration = WG.Chobby.Configuration

	Label:New {
		x = 20,
		right = 5,
		y = 17,
		height = 20,
		font = Configuration:GetFont(3),
		caption = i18n("codex"),
		parent = parentControl
	}

	local btnClose = Button:New {
		right = 11,
		y = 7,
		width = 80,
		height = 45,
		caption = i18n("close"),
		font = Configuration:GetFont(3),
		classname = "negative_button",
		OnClick = {
			function()
				parentControl:Hide()
			end
		},
		parent = parentControl
	}

	local codexTextScroll = ScrollPanel:New{
		parent = parentControl,
		x = "40%",
		y = IMAGE_SIZE + 54 + 8,
		bottom = 14,
		right = 12,
		orientation = "vertical",
		children = {}
	}
	local codexText = TextBox:New {
		parent = codexTextScroll,
		x = 0,
		y = 0,
		width = "100%",
		height = "100%",
		text = "",
		font = Configuration:GetFont(2),
	}

	local codexImagePanel = Panel:New{
		parent = parentControl,
		x = "41%",
		y = 54,
		height = IMAGE_SIZE,
		width = IMAGE_SIZE,
	}
	local codexImage = Image:New{
		parent = codexImagePanel,
		x = 0,
		y = 0,
		width = "100%",
		height = "100%",
	}

	local codexTreeScroll = ScrollPanel:New{
		parent = parentControl,
		x = 12,
		y = 54,
		bottom = 14,
		right = "60%",
		orientation = "vertical",
		children = {}
	}

	local externalFunctions = {}
	local codexFuncs

	function externalFunctions.PopulateCodexTree()
		codexFuncs = PopulateCodexTree(codexTreeScroll, codexText, codexImage)
	end
	externalFunctions.PopulateCodexTree()

	function externalFunctions.OpenEntry(entryName)
		if codexFuncs then
			codexFuncs.OpenEntry(entryName)
		end
	end

	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- External Interface

local CodexHandler = {}

function CodexHandler.GetControl()
	local window = Control:New {
		name = "codexHandler",
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		padding = {0, 0, 0, 0},
		OnParent = {
			function(obj)
				if obj:IsEmpty() then
					codexManagerStuff = InitializeControls(obj)
				end
			end
		},
	}
	return window
end

function CodexHandler.OpenEntry(entryName)
	if codexManagerStuff then
		codexManagerStuff.OpenEntry(entryName)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

function widget:Initialize()
	CHOBBY_DIR = LUA_DIRNAME .. "widgets/chobby/"
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	local function CampaignLoaded(listener)
		if codexManagerStuff then
			codexManagerStuff.PopulateCodexTree()
		end
	end
	WG.CampaignData.AddListener("CampaignLoaded", CampaignLoaded)

	local function RewardGained(listener, reward)
		if codexManagerStuff and reward.codexEntries then
			-- Should really use Add here.
			codexManagerStuff.PopulateCodexTree()
		end
	end
	WG.CampaignData.AddListener("RewardGained", RewardGained)

	WG.CodexHandler = CodexHandler
end

function widget:Shutdown()
	WG.CodexHandler = nil
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
