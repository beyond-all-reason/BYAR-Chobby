--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utilities

local function CreateLine(lineText, linkText, onClick)
	local Configuration = WG.Chobby.Configuration

	local lineHolder = Control:New {
		x = 0,
		y = 0,
		width = "100%",
		resizable = false,
		draggable = false,
		padding = {0, 0, 0, 0},
	}

	if onClick then
		local linkButton = Button:New {
			x = 3,
			y = 3,
			height = 34,
			width = 95,
			caption = linkText,
			classname = "action_button",
			font = WG.Chobby.Configuration:GetFont(2),
			OnClick = {
				onClick
			},
			parent = lineHolder,
		}
	end

	local text = TextBox:New {
		name = "text",
		x = 110,
		y = 12,
		right = 0,
		height = 20,
		valign = 'center',
		fontsize = Configuration:GetFont(2).size,
		text = lineText,
		parent = lineHolder,
	}

	return lineHolder
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Community Links

local communityLines = {
	{
		"Site home page.",
		"Home",
		function ()
			WG.BrowserHandler.OpenUrl("https://www.beyondallreason.info/")
		end
	},
--	{
--		"Community forums.",
--		"Forums",
--		function ()
--			WG.BrowserHandler.OpenUrl("https://springrts.com/phpbb/viewforum.php?f=51")
--		end
--	},
	{
		"Youtube channel.",
		"Youtube",
		function ()
			WG.BrowserHandler.OpenUrl("https://www.youtube.com/user/Ruwetuin")
		end
	},
	{
		"Discord chat server.",
		"Discord",
		function ()
			WG.BrowserHandler.OpenUrl("https://discord.gg/mvVc9vH")
		end
	},
	{
		"Contributors and developers.",
		"Credits",
		function ()
			WG.BrowserHandler.OpenUrl("https://www.beyondallreason.info/team")
		end
	},
	{
		"Browse and download maps.",
		"Maps",
		function ()
			WG.BrowserHandler.OpenUrl("https://springfiles.com/spring/spring-maps")
		end
	},
	{
		"View source code on GitHub.",
		"Source",
		function ()
			WG.BrowserHandler.OpenUrl("https://github.com/beyond-all-reason/Beyond-All-Reason")
		end
	},
	{
		"Report bug on GitHub.",
		"Report bug",
		function ()
			WG.BrowserHandler.OpenUrl("https://github.com/beyond-all-reason/Beyond-All-Reason/issues/new")
		end
	},
	{
		"Upload Spring-Launcher log.",
		"Upload log",
		function ()
			WG.WrapperLoopback.UploadLog()
		end
	},
	{
		"Open game data folder to find config files and logs.",
		"Game Data",
		function ()
			WG.WrapperLoopback.OpenFolder()
		end
	},
}

local communityControl = Control:New {
	x = 0,
	y = 0,
	right = 0,
	bottom = 0,
	padding = {0, 0, 0, 0},
	OnParent = {
		function (obj)
			if not obj:IsEmpty() then
				return
			end

			Label:New {
				x = 15,
				y = 11,
				width = 180,
				height = 30,
				parent = obj,
				font = WG.Chobby.Configuration:GetFont(3),
				caption = "Community and development links",
			}

			Button:New {
				right = 11,
				y = 7,
				width = 80,
				height = 45,
				font = WG.Chobby.Configuration:GetFont(3),
				caption = i18n("close"),
				classname = "negative_button",
				OnClick = {
					function()
						obj:Hide()
					end
				},
				parent = obj,
			}

			local listHolder = Control:New {
				x = 12,
				right = 15,
				y = 52,
				bottom = 15,
				parent = obj,
				resizable = false,
				draggable = false,
				padding = {0, 0, 0, 0},
			}
			local list = SortableList(listHolder)

			local items = {}
			for i = 1, #communityLines do
				local data = communityLines[i]
				items[#items + 1] = {i, CreateLine(data[1], data[2], data[3]), {i}}
			end

			list:AddItems(items)
		end
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Structure

return {
	{
		name = "links",
		control = communityControl,
	}
}
