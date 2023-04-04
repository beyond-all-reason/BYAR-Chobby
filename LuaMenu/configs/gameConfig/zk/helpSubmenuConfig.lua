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
			WG.BrowserHandler.OpenUrl("https://zero-k.info/")
		end
	},
	{
		"Community forums.",
		"Forums",
		function ()
			WG.BrowserHandler.OpenUrl("https://zero-k.info/Forum")
		end
	},
	{
		"Wiki manual.",
		"Manual",
		function ()
			WG.BrowserHandler.OpenUrl("https://zero-k.info/mediawiki/index.php?title=Manual")
		end
	},
	{
		"Wiki FAQ.",
		"FAQ",
		function ()
			WG.BrowserHandler.OpenUrl("https://zero-k.info/mediawiki/index.php?title=FAQ")
		end
	},
	{
		"Discord chat server.",
		"Discord",
		function ()
			WG.BrowserHandler.OpenUrl("https://discord.gg/aab63Vt")
		end
	},
	{
		"Contributors and developers.",
		"Credits",
		function ()
			WG.BrowserHandler.OpenUrl("https://zero-k.info/mediawiki/index.php?title=Credits")
		end
	},
	{
		"Zero-K streams on Twitch.",
		"Twitch",
		function ()
			WG.BrowserHandler.OpenUrl("https://www.twitch.tv/directory/game/Zero-K")
		end
	},
	{
		"Shadowfury333's Youtube channel.",
		"Youtube",
		function ()
			WG.BrowserHandler.OpenUrl("https://www.youtube.com/user/Shadowfury333")
		end
	},
	{
		"Shadowfury333's Hitbox stream.",
		"Hitbox",
		function ()
			WG.BrowserHandler.OpenUrl("http://www.hitbox.tv/shadowfury333")
		end
	},
	{
		"Zero-K facebook page.",
		"Facebook",
		function ()
			WG.BrowserHandler.OpenUrl("https://www.facebook.com/ZeroK.RTS/")
		end
	},
	{
		"Top 50 players.",
		"Ladder",
		function ()
			WG.BrowserHandler.OpenUrl("https://zero-k.info/Ladders")
		end
	},
	{
		"Browse and download maps.",
		"Maps",
		function ()
			WG.BrowserHandler.OpenUrl("https://zero-k.info/Maps")
		end
	},
	{
		"Browse and download replays.",
		"Replays",
		function ()
			WG.BrowserHandler.OpenUrl("https://zero-k.info/Battles")
		end
	},
	{
		"View source code on GitHub.",
		"Source",
		function ()
			WG.BrowserHandler.OpenUrl("https://github.com/ZeroK-RTS")
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

--if VFS.HasArchive("Zero-K $VERSION") then
--	communityLines[#communityLines + 1] = {
--		"Run a benchmark game.",
--		"Benchmark",
--		function ()
--			local localLobby = WG.LibLobby and WG.LibLobby.localLobby
--			if localLobby then
--				localLobby:StartGameFromString(VFS.Include(LUA_DIRNAME .. "configs/gameConfig/zk/benchmarkFile.lua"))
--			end
--		end
--	}
--end
--
--if VFS.HasArchive("CAI Fight 2017 06 fix") then
--	communityLines[#communityLines + 1] = {
--		"Run a benchmark game.",
--		"CAI Fight",
--		function ()
--			local localLobby = WG.LibLobby and WG.LibLobby.localLobby
--			if localLobby then
--				localLobby:StartGameFromString(VFS.Include(LUA_DIRNAME .. "configs/gameConfig/zk/benchmarkFileCAIfight.lua"))
--			end
--		end
--	}
--end

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
-- Bug Reporting

local firstBugParent = true
local bugControl = Control:New {
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

			local Configuration = WG.Chobby.Configuration
			Label:New {
				x = 15,
				y = 11,
				width = 180,
				height = 30,
				parent = obj,
				font = Configuration:GetFont(3),
				caption = "Send a bug report",
			}

			Button:New {
				right = 11,
				y = 7,
				width = 80,
				height = 45,
				font = Configuration:GetFont(3),
				caption = i18n("close"),
				classname = "negative_button",
				OnClick = {
					function()
						obj:Hide()
					end
				},
				parent = obj,
			}

			local offset = 70
			TextBox:New {
				x = 21,
				width = 170,
				y = offset,
				height = 35,
				text ="Title:",
				fontsize = Configuration:GetFont(3).size,
				parent = obj,
			}
			offset = offset + 36
			local titleBox = EditBox:New {
				x = 24,
				right = 20,
				y = offset - 9,
				height = 35,
				text = "",
				font = Configuration:GetFont(3),
				parent = obj,
			}
			offset = offset + 36

			offset = offset + 8
			TextBox:New {
				x = 21,
				width = 170,
				y = offset,
				height = 35,
				text ="Description:",
				fontsize = Configuration:GetFont(3).size,
				parent = obj,
			}
			offset = offset + 36
			local descBox = EditBox:New {
				x = 24,
				right = 20,
				y = offset - 9,
				height = 35,
				text = "",
				font = Configuration:GetFont(3),
				parent = obj,
			}
			offset = offset + 36

			offset = offset + 8
			TextBox:New {
				x = 24,
				right = 24,
				y = offset,
				height = 35,
				text = "Using Spring engine version " .. Spring.Utilities.GetEngineVersion() .. " " .. ((WG.Chobby.Configuration:GetIsRunning64Bit() and "64-bit.") or "32-bit."),
				fontsize = Configuration:GetFont(2).size,
				parent = obj,
			}
			offset = offset + 36


			Button:New {
				x = "35%",
				right = "35%",
				bottom = 15,
				height = 80,
				caption = "Submit",
				tooltip = "Closes the game and submits the report. Click OK to the resulting pop-up.",
				font = Configuration:GetFont(4),
				classname = "action_button",
				OnClick = {
					function()
						WG.WrapperLoopback.SendBugReport(titleBox.text, descBox.text)
					end
				},
				parent = obj,
			}
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
	},
	{
		name = "tutorials",
		control = WG.MissionHandler.GetControl(),
	},
	{
		name = "benchmark",
		control = WG.BenchmarkHandler.GetControl(),
	},
	{
		name = "report_a_bug",
		control = bugControl,
	},
}
