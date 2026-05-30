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
			width = 235,
			caption = linkText,
			classname = "option_button",
			objectOverrideFont = Configuration:GetButtonFont(2),
			OnClick = {
				onClick
			},
			parent = lineHolder,
		}
	end

	local text = TextBox:New {
		name = "text",
		x = 250,
		y = 12,
		right = 0,
		height = 20,
		valign = 'center',
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		objectOverrideHintFont = WG.Chobby.Configuration:GetFont(2),
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
	{
		"Code of conduct and terms of use.",
		"Code of conduct",
		function ()
			WG.BrowserHandler.OpenUrl("https://www.beyondallreason.info/code-of-conduct")
		end
	},

	{
		"What information we store and how we use it.",
		"Privacy Policy",
		function ()
			WG.BrowserHandler.OpenUrl("https://www.beyondallreason.info/privacy")
		end
	},
	{
		"Official X.",
		"X",
		function ()
			WG.BrowserHandler.OpenUrl("https://x.com/BAR_RTS")
		end
	},
	{
		"Twitch channel.",
		"Twitch",
		function ()
			WG.BrowserHandler.OpenUrl("https://www.twitch.tv/beyondallreasonofficial")
		end
	},
	{
		"Channels streaming BAR on Twitch now.",
		"Live on Twitch",
		function ()
			WG.BrowserHandler.OpenUrl("https://www.twitch.tv/directory/category/beyond-all-reason")
		end
	},
	{
		"Youtube channel.",
		"Youtube",
		function ()
			WG.BrowserHandler.OpenUrl("https://www.youtube.com/BeyondAllReason")
		end
	},
--[[ 	{
		"Videos and streams about BAR on Youtube.",
		"Live on Youtube",
		function ()
			WG.BrowserHandler.OpenUrl("https://www.youtube.com/channel/UC-QkFO7qGgPv5J3c8pGOpIQ")
		end
	}, ]]
	{
		"Discord chat server.",
		"Discord",
		function ()
			WG.BrowserHandler.OpenUrl("https://discord.gg/beyond-all-reason")
		end
	},
	{
		"Use Discord #open-ticket channel to talk to moderation team.",
		"Contact moderation",
		function ()
			WG.BrowserHandler.OpenUrl("https://discord.com/channels/549281623154229250/1005537149564755989")
		end
	},
	{
		"Your match history",
		"Matches",
		function ()
			WG.BrowserHandler.OpenUrl("https://server4.beyondallreason.info/battle")
		end
	},
	{
		"Use to block, ignore, avoid, report players",
		"Relationship",
		function ()
			WG.BrowserHandler.OpenUrl("https://server4.beyondallreason.info/account/relationship/search")
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
			WG.BrowserHandler.OpenUrl("https://www.beyondallreason.info/maps")
		end
	},
    {
		"Browse and download replays.",
		"Replays",
		function ()
			WG.BrowserHandler.OpenUrl("https://www.beyondallreason.info/replays")
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
		"Upload your Infolog.txt to report any error",
		"Upload Infolog.txt",
		function ()
			--WG.WrapperLoopback.UploadLog()
			--We need the report kind of box here!
			if WG.TextEntryWindow then 
				WG.TextEntryWindow.CreateTextEntryWindow({
					defaultValue = "",
					caption = "Upload Infolog",
					labelCaption = "Your infolog.txt contains sensitive information such as your username and install location. These will be kept private. Please fill in the reason with a description of the problem you encountered. Click \"Send\" to send the infolog, escape or enter to cancel.",
					hint = "Type a description of the error",
					width = 500,
					--ebheight = 120,
					oklabel = "Send",
					OnAccepted = function(reportreason)
						local infolog = VFS.LoadFile("infolog.txt")
						local compressedlog = Spring.Utilities.Base64Encode(VFS.ZlibCompress(infolog))
						if WG.Analytics then 
							WG.Analytics.SendCrashReportOneTimeEvent("infolog.txt", "UserUpload", reportreason, compressedlog, false )
						end
					end
				})
			end

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
				objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
				caption = "Community and development links",
			}

			Button:New {
				right = 12,
				y = 7,
				width = 80,
				height = 45,
				objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
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
