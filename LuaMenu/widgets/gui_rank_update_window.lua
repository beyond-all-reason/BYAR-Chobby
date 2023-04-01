--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Rank update window",
		desc      = "Displays a rank congratulation popup.",
		author    = "gajop",
		date      = "10 BC",
		license   = "GNU LGPL, v2.1 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Rank update popup

local currentIcon
local rankUpdateWindow

local function LoadRankEffects()
	local rankEffectDef = {
		shader = {
			fragment = VFS.LoadFile(CHOBBY_SHADERS_DIR .. "rank.frag"),
			uniformInt = { tex0 = 0 }
		},
		uniformNames = { "tex0", "time" },
		rawDraw = true,
		name = "rank",
	}
	ChiliFX:AddEffectDef(rankEffectDef)
end

local RANK_SIZE = 185

local function IconToLevelRank(icon)
	local split = icon:find("_")
	return tonumber(icon:sub(1, split-1)), tonumber(icon:sub(split+1))
end

local function CreateRankUpdateWindow(oldIcon, newIcon)
	local Configuration = WG.Chobby.Configuration

	local oldRank, oldLevel = IconToLevelRank(oldIcon)
	local newRank, newLevel = IconToLevelRank(newIcon)
	local isRankUp = newLevel > oldLevel or newRank > oldRank

	if not isRankUp then
		-- Seems like this is poor feedback?
		return
	end

	local rankFile = Configuration.gameConfig.largeRankFunction(newIcon)

	rankUpdateWindow = Window:New {
		caption = "",
		name = "rankUpdateWindow",
		parent = screen0,
		width = 280,
		height = 330,
		resizable = false,
		draggable = false,
		classname = "main_window",
	}

	local CloseFunction = function()
		rankUpdateWindow:Dispose()
		rankUpdateWindow = nil
	end

	local lblTitle = Label:New {
		x = 0,
		y = 15,
		width = rankUpdateWindow.width - rankUpdateWindow.padding[1] - rankUpdateWindow.padding[3],
		height = 35,
		align = "center",
		font = Configuration:GetFont(4),
		caption = (isRankUp and i18n("rank_gained")) or i18n("rank_lost"),
		parent = rankUpdateWindow,
	}

	local btnClose = Button:New {
		x = "25%",
		right = "25%",
		bottom = 1,
		height = 60, -- standard height is 70
		caption = i18n("close"),
		font = Configuration:GetFont(3),
		classname = "action_button",
		OnClick = { CloseFunction },
		parent = rankUpdateWindow,
	}

	local imRankImage = Image:New {
		x = (rankUpdateWindow.width - rankUpdateWindow.padding[1] - rankUpdateWindow.padding[3] - RANK_SIZE)/2,
		y = 45,
		width = RANK_SIZE,
		height = RANK_SIZE,
		keepAspect = true,
		file = rankFile,
		tex0 = rankFile,
		parent = rankUpdateWindow,
	}
	-- NOTICE: keep aspect doesn't work for ChiliFX
	ChiliFX:SetEffect({
		obj = imRankImage,
		effect = "rank",
	})
	if Configuration.animate_lobby then
		WG.LimitFps.ForceRedrawPeriod(8)
	end

	local popupHolder = WG.Chobby.PriorityPopup(rankUpdateWindow, CloseFunction, CloseFunction, screen0)

	local externalFunctions = {}

	return externalFunctions
end


function DelayedInitialize()
	local lobby = WG.LibLobby.lobby

	LoadRankEffects()

	local function OnUpdateUserStatus(listener, userName, status)
		if lobby:GetMyUserName() == userName and status.icon ~= nil then
			local oldIcon = currentIcon
			currentIcon = status.icon

			if oldIcon == nil or oldIcon == currentIcon then
				return
			end
			if rankUpdateWindow ~= nil then
				Log.Warning("New rank update while an existing rank update popup is displayed. Likely a bug")
				return
			end

			CreateRankUpdateWindow(oldIcon, currentIcon)
		end
	end

	lobby:AddListener("OnUpdateUserStatus", OnUpdateUserStatus)
	--WG.Delay(function() OnUpdateUserStatus(nil, lobby:GetMyUserName(), { icon = "5_5"}) end, 2)
end


function widget:Initialize()
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	WG.Delay(DelayedInitialize, 1)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
