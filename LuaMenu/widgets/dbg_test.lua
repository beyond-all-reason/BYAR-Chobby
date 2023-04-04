function widget:GetInfo()
	return {
		name    = 'Test',
		desc    = 'Tests stuff',
		author  = 'GoogleFrog',
		date    = '23 October 2016',
		license = 'GNU GPL v3',
		layer   = -200000,
		--handler = true,
		--api     = true, -- Makes KeyPress occur before chili
		enabled = true,
	}
end

--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- Status and invites panel test
local function GetStatusControl(rank, alsoRemove)
	local name = "window" .. rank
	local window = Panel:New {
		name = name,
		x = 0,
		y = 0,
		caption = "Control " .. rank,
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
		children = {}
	}

	local AddWindow, RemoveWindow

	function AddWindow()
		local handler = WG.Chobby.interfaceRoot.GetStatusAndInvitesPanel()
		handler.AddControl(window, rank)

		if alsoRemove then
			WG.Delay(RemoveWindow, math.random()*4)
		end
	end

	function RemoveWindow()
		local handler = WG.Chobby.interfaceRoot.GetStatusAndInvitesPanel()
		handler.RemoveControl(name)

		WG.Delay(AddWindow, math.random()*4)
	end

	WG.Delay(AddWindow, math.random()*4)
end

local function StartStatusAndInvitesPanelTest()
	GetStatusControl(1, true)
	GetStatusControl(2, true)
	GetStatusControl(3, true)
	GetStatusControl(4, true)
end

local function AddStaticPanels()
	GetStatusControl(1)
	GetStatusControl(2)
	GetStatusControl(3)
	GetStatusControl(4)
end

--------------------------------------------------------------------------
--------------------------------------------------------------------------
local function DelayedInitialize()
	--StartStatusAndInvitesPanelTest()
	--AddStaticPanels()
end

function widget:Initialize()
	CHOBBY_DIR = LUA_DIRNAME .. "widgets/chobby/"
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	WG.Delay(DelayedInitialize, 1)
end

--------------------------------------------------------------------------
--------------------------------------------------------------------------
