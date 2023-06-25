--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "SpringBoard Window",
		desc      = "veni vendi venditor",
		author    = "gajop",
		date      = "Stardate 42024.0",
		license   = "GNU LGPL, v2.1 or later",
		layer     = -100000,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Local Variables

local Configuration

local SpringBoard = {
    mapName = "",
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Helper functions

local function CheckEditorDependencies()
    if not Configuration.gameConfig.editor then
        return false, "Editor isn't specified in gameConfig"
    end
    return Package.ArchiveExists(Configuration.gameConfig.editor)
end

local function LaunchSpringBoard(opts)
	-- if not Configuration.gameConfig.editor then
	-- 	Chotify:Post({
	-- 		title = "SpringBoard",
	-- 		body  = "Editor isn't specified in gameConfig",
	-- 	})
	-- 	return
	-- end
	-- local archiveName = VFS.GetNameFromRapidTag(Configuration.gameConfig.editor)
	-- if not archiveName then
	-- 	Chotify:Post({
	-- 		title = "SpringBoard",
	-- 		body  = "Cannot find archive name for rapid tag: " .. tostring(Configuration.gameConfig.editor),
	-- 	})
	-- 	return
	-- end
	-- if not VFS.HasArchive(archiveName) then
	-- 	Chotify:Post({
	-- 		title = "SpringBoard",
	-- 		body  = "Downloading missing dependency: " .. archiveName,
	-- 	})
	-- 	VFS.DownloadArchive(archiveName, "game")
	-- end
	local success, missing = CheckEditorDependencies()
	if not success then
		Chotify:Post({
			title = "SpringBoard",
			body  = "Missing dependencies, downloading",
		})
		Package.DownloadWithDeps(Configuration.gameConfig.editor, "game")
		return
	end
	Chotify:Post({
		title = "SpringBoard",
		body  = "Launching SpringBoard",
	})
	localLobby:SetBattleState("Developer", Configuration.gameConfig.editor, opts.mapName, "SpringBoard")
	localLobby:SelectMap(opts.mapName)
	localLobby:StartBattle("springboard", Configuration:GetPlayerName())
end

function SpringBoard:SelectMap(mapName)
    SpringBoard.mapName = mapName

	LaunchSpringBoard({
		mapName = mapName
	})
    -- local width = 150

    -- mapHumanName = mapName:gsub("_", " ")
    -- mapHumanName = StringUtilities.GetTruncatedStringWithDotDot(mapHumanName, tbMapName.font, width - 22)
    -- tbMapName:SetText(mapHumanName)
    -- local length = tbMapName.font:GetTextWidth(mapHumanName)
    -- --imMapLink:SetPos(length + 5)
    -- imMinimap.file, imMinimap.checkFileExists = Configuration:GetMinimapImage(mapName)
    -- imMinimap:Invalidate()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Initialization

local function PopulateSaveList(saveList)
	saveList:Clear()
	local saves = {}
	local items = {}
	for name, save in pairs(saves) do
		local controls, order = AddSaveEntryButton(save, saveList)
		items[#items + 1] = {save.name, controls, order}
	end

	saveList:AddItems(items)
end

local function SaveGame(filename)
	local result = WG.CampaignData.SaveGame(filename)
	if result then
		WG.CampaignSaveWindow.PopulateSaveList()
	end
end

local function LoadGame(filename)
	WG.CampaignData.LoadGameByFilename(filename)
	WG.CampaignSaveWindow.PopulateSaveList()
end

local function DeleteSave(filename)
	WG.CampaignData.DeleteSave(filename)
	WG.CampaignSaveWindow.PopulateSaveList()
end

local function InitializeControls(window)
	Configuration = WG.Chobby.Configuration

	-------------------------
	-- Generate List
	-------------------------
	local listHolder = Control:New {
		x = 12,
		right = 15,
		y = 80,
		bottom = 15,
		parent = window,
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
	}

	local headings = {
		{name = "Name", x = 97, width = 200},
		--{name = "Campaign", x = 97 + 200, width = 220},
		{name = "Date", x = 97 + --[[200 +]] 220, width = 140},
	}

	local saveList = WG.Chobby.SortableList(listHolder, headings, 80, 2)
	PopulateSaveList(saveList)

	local saveButton = Button:New {
		width = 180,
		x = 12,
		y = 8,
		height = 64,
		caption = i18n("new_scenario"),
		OnClick = {
			function ()
				WG.MapListPanel.Show(SpringBoard, SpringBoard.mapName)
			end
		},
		font = Configuration:GetFont(3),
		parent = window,
	}
end

local function bla()
    local minimapBottomClearance = 135
    local mapLinkWidth = 150
    local EXTERNAL_PAD_VERT = 9
    local EXTERNAL_PAD_HOR = 12
    local INTERNAL_PAD = 2
    local BOTTOM_SPACING = 50

    local btnStart = WG.Chili.Button:New {
        name = "Start",
        x = 0,
        y = 0,
        width = 100,
        height = 55,
        parent = window,
        OnClick = {function()
        end}
    }

    local rightInfo = Control:New {
        x = "67%",
        y = 0,
        right = 0,
        bottom = 0,
        padding = {1, EXTERNAL_PAD_VERT, EXTERNAL_PAD_HOR, INTERNAL_PAD},
        parent = window,
    }

    if btnMapLink then
        btnMapLink:Dispose()
    end
    btnMapLink = Button:New {
        x = 3,
        y = 0,
        right = 3,
        height = 20,
        classname = "button_square",
        caption = "",
        padding = {0, 0, 0, 0},
        parent = rightInfo,
        OnClick = {
            function ()
                if SpringBoard.mapName and Configuration.gameConfig.link_particularMapPage ~= nil then
                    WG.BrowserHandler.OpenUrl(Configuration.gameConfig.link_particularMapPage(SpringBoard.mapName))
                end
            end
        }
    }

    tbMapName = TextBox:New {
        name = "tbMapName",
        x = 2,
        y = 3,
        right = 20,
        align = "left",
        parent = btnMapLink,
        fontsize = Configuration:GetFont(2).size,
        caption = "ABC",
    }

    local minimapPanel = Panel:New {
        x = 0,
        y = 0,
        right = 0,
        height = 200,
        padding = {1,1,1,1},
        parent = rightInfo,
    }
    local btnMinimap = Button:New {
        x = 0,
        y = 0,
        right = 0,
        bottom = 0,
        classname = "button_square",
        caption = "",
        parent = minimapPanel,
        padding = {2,2,2,2},
        OnClick = {
            function()
				WG.MapListPanel.Show(SpringBoard, SpringBoard.mapName)
            end
        },
    }
    imMinimap = Image:New {
        x = 0,
        y = 0,
        right = 0,
        bottom = 0,
        keepAspect = true,
        file = Configuration:GetMinimapImage(SpringBoard.mapName),
        parent = minimapPanel,
    }
    local function UpdateMapName(mapName, width)

    end
    --SetMapName(battle.mapName, mapLinkWidth)

    btnMapLink.OnResize[#btnMapLink.OnResize + 1] = function (self, xSize, ySize)
        --SetMapName(currentMapName, xSize)
    end

    rightInfo.OnResize = {
        function (obj, xSize, ySize)
            if xSize + minimapBottomClearance < ySize then
                minimapPanel._relativeBounds.left = 0
                minimapPanel._relativeBounds.right = 0
                minimapPanel:SetPos(nil, nil, nil, xSize)
                minimapPanel:UpdateClientArea()

                btnMapLink:SetPos(nil, xSize + 2)
            else
                local horPadding = ((xSize + minimapBottomClearance) - ySize)/2
                minimapPanel._relativeBounds.left = horPadding
                minimapPanel._relativeBounds.right = horPadding
                minimapPanel:SetPos(nil, nil, nil, ySize - minimapBottomClearance)
                minimapPanel:UpdateClientArea()

                btnMapLink:SetPos(nil, ySize - minimapBottomClearance + 2)
            end
        end
    }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- External Interface

local SpringBoardWindow = {}
local window = nil

function SpringBoardWindow.GetControl()
	if not window then
		window = Control:New {
			name = "campaignOptionsWindow",
			x = "0%",
			y = "0%",
			width = "100%",
			height = "100%",
			OnParentPost = {
				function(obj)
					if obj:IsEmpty() then
						InitializeControls(obj)
					end
				end
			},
		}
	end
	return window
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Callins

function widget:Initialize()
	CHOBBY_DIR = LUA_DIRNAME .. "widgets/chobby/"
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	WG.SpringBoardWindow = SpringBoardWindow
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
