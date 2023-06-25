Console = LCS.class{}

function Console:init(channelName, sendMessageListener, noHistoryLoad, onResizeFunc, isBattleChat)
	self.listener = sendMessageListener
	self.showDate = true
	self.dateFormat = "%H:%M"

	-- List of sent messages sent by the viewer. self.sentMessages[1] will be the message the user was typing.
	-- self.sentMessages[2] is the start of history.
	self.sentMessages = {""}
	-- The index of the sent message currently being shown in the editbox.
	-- An index of 1 indicates the current message, index >= 2 indicates message history.
	self.sentMessageIndex = 1

	self.channelName = channelName

	local onResize
	if onResizeFunc then
		onResize = {
			function ()
				onResizeFunc(self)
			end
		}
	end

	-- TODO: currently this is handled by chat windows and battleroom chat separately
	self.unreadMessages = 0

	self.spHistory = ScrollPanel:New {
		name = self.channelName and (self.channelName .. " scroll panel"),
		x = 0,
		right = 2,
		y = 0,
		bottom = 35,
		verticalSmartScroll = true,
	}
	self.tbHistory = TextBox:New {
		x = 0,
		right = 0,
		y = 0,
		agressiveMaxLines = 500,
		agressiveMaxLinesPreserve = 100,
		lineSpacing = 2,
		bottom = 0,
		text = "",
		fontsize = Configuration.chatFontSize,
		parent = self.spHistory,
		selectable = true,
		subTooltips = true,

		_inmousemove = false,
		OnClick = { function(obj)
			if not obj._inmousemove then
				screen0:FocusControl(self.ebInputText)
			end
			obj._inmousemove = false
		end},
		OnMouseMove = { function(obj, x, y, dx, dy, button)
			if button ~= 1 then
				return
			end
			obj._inmousemove = true
		end},
		onResize = onResize
	}

	self.ebInputText = EditBox:New {
		x = 0,
		bottom = 7,
		height = 25,
		right = 2,
		text = "",
		fontsize = Configuration.chatFontSize,
		--hint = i18n("type_here_to_chat"),
	}

	local function onConfigurationChange(listener, key, value)
		if key == "chatFontSize" then
			local oldFont = self.ebInputText.font
			-- Relevant settings depend on skin
			local fontSettings = {
				font         = oldFont.font,
				color        = oldFont.color,
				outlineColor = oldFont.outlineColor,
				outline      = oldFont.outline,
				shadow       = oldFont.shadow,
				size         = value,
			}
			self.ebInputText.font = Font:New(fontSettings)
			self.ebInputText:UpdateLayout()

			self.tbHistory.font = Font:New(fontSettings)
			self.tbHistory:UpdateLayout()
		end
	end
	Configuration:AddListener("OnConfigurationChange", onConfigurationChange)

	self.ebInputText.KeyPress = function(something, key, ...)
		if key == Spring.GetKeyCode("tab") then
			local before = self.ebInputText.text
			self:Autocomplete(self.ebInputText.text)
			-- If text changes, reset the index.
			if before ~= self.ebInputText.text then
				self.sentMessageIndex = 1
			end
			return false
		else
			self.subword = nil
			return Chili.EditBox.KeyPress(something, key, ...)
		end
	end
	self.ebInputText.OnKeyPress = {
		function(obj, key, mods, ...)
			if key == Spring.GetKeyCode("enter") or
				key == Spring.GetKeyCode("numpad_enter") then
				self:SendMessage()
				return true
			elseif key == Spring.GetKeyCode("up") then
				self:FillPreviousSentMessage()
				return true
			elseif key == Spring.GetKeyCode("down") then
				self:FillNextSentMessage()
				return true
			end
		end
	}
	self.ebInputText.OnTextInput = {
		function(utf8char, ...)
			self.sentMessageIndex = 1
		end
	}
	self.fakeImage = Image:New {
		x = 0, y = 0,
		bottom = 0, right = 0,
		OnClick = { function()
			screen0:FocusControl(self.ebInputText)
		end}
	}

	self.panel = Control:New {
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		padding      = {0, 0, 0, 0},
		itemPadding  = {0, 0, 0, 0},
		itemMargin   = {0, 0, 0, 0},
		children = {
			self.spHistory,
			self.ebInputText,
			self.fakeImage,
		},
	}

	if not noHistoryLoad then
		self:LoadHistory(Configuration.lastLoginChatLength)
	end
end

-- Changes the current console text entry to message sent after the one currently shown.
-- Shows the message that was being typed before retrieving past messages if there are no
-- messages sent since the one currently shown in the EditBox.
function Console:FillNextSentMessage()
	-- Only move forward if not looking at the past.
	if self.sentMessageIndex > 1 then
		self:FillSentMessage(self.sentMessageIndex - 1)
	end
end

-- Changes the current console text entry to the message sent further in the past than the one currently shown.
function Console:FillPreviousSentMessage()
	if self.sentMessageIndex == #self.sentMessages then
		-- Bail out if there's no previous history to see.
		return
	elseif self.sentMessageIndex == 1 then
		-- Save current message before we move into the past.
		self.sentMessages[1] = self.ebInputText.text
	end
	-- Move the index, and update the editBox
	self:FillSentMessage(self.sentMessageIndex + 1)
end

-- Changes the current console text entry to the specified sent message.
-- sentMessageIndex must be >= 0
function Console:FillSentMessage(sentMessageIndex)
	self.ebInputText:SetText(self.sentMessages[sentMessageIndex])
	self.sentMessageIndex = sentMessageIndex
end

function Console:Autocomplete(textSoFar)
	if not self.subword then
		local start = 0
		for i = 1, 100 do
			local newStart = (string.find(textSoFar, " ", start) or (start - 1)) + 1

			if start ~= newStart then
				start = newStart
			else
				break
			end
		end

		self.subword = string.sub(textSoFar, start)
		self.unmodifiedLength = string.len(textSoFar)
		local length = string.len(self.subword)

		self.suggestion = 0
		self.suggestions = {}

		if length == 0 then
			return
		end

		local users = lobby:GetUsers()
		for name, _ in pairs(users) do
			if name:starts(self.subword) then
				self.suggestions[#self.suggestions + 1] = string.sub(name, length + 1)
			end
		end
	end

	if #self.suggestions == 0 then
		return
	end

	self.suggestion = self.suggestion + 1
	if self.suggestion > #self.suggestions then
		self.suggestion = 1
	end

	self.ebInputText.selStart = self.unmodifiedLength + 1
	self.ebInputText.selEnd = string.len(textSoFar) + 1
	self.ebInputText:ClearSelected()

	self.ebInputText:TextInput(self.suggestions[self.suggestion])
end

function Console:SendMessage()
	if self.ebInputText.text ~= "" then
		message = self.ebInputText.text
		-- Listener handles sending the message.
		if self.listener then
			self.listener(message)
		end
		-- If the message is different than the last sent message, save the message for retrieval by uparrow.
		if self.sentMessages[2] ~= self.ebInputText.text then
			table.insert(self.sentMessages, 2, self.ebInputText.text)
		end
		self.ebInputText:SetText("")
		self.sentMessageIndex = 1
	end
end

-- if date is not passed, current time is assumed
function Console:AddMessage(message, userName, dateOverride, color, thirdPerson, nameColor, nameTooltip, supressNameClick)
	nameColor = nameColor or "\255\50\160\255"
	nameTooltip = nameTooltip or (userName and ("user_chat_s_" .. userName))
	local txt = ""
	local whiteText = ""
	if self.showDate then
		local timeOverride
		if dateOverride then
			local utcHour = tonumber(os.date("!%H"))
			local utcMinute = tonumber(os.date("!%M"))
			local localHour = tonumber(os.date("%H"))
			local localMinute = tonumber(os.date("%M"))

			local messageHour = tonumber(string.sub(dateOverride, 12, 13))
			local messageMinute = tonumber(string.sub(dateOverride, 15, 16))

			if messageHour and messageMinute then
				local hour = (localHour - utcHour + messageHour)%24
				if hour < 10 then
					hour = "0" .. hour
				end
				local minute = (localMinute - utcMinute + messageMinute)%60
				if minute < 10 then
					minute = "0" .. minute
				end

				timeOverride = hour .. ":" .. minute
			else
				Spring.Echo("Bad dateOverride", dateOverride, messageHour, messageMinute)
			end
		end
		-- FIXME: the input "date" should ideally be a table so we can coerce the format
		local currentDate = timeOverride or os.date(self.dateFormat)
		txt = txt .. "\255\128\128\128[" .. currentDate .. "] "
		whiteText = whiteText .. "[" .. currentDate .. "] "
		if color ~= nil then
			txt = txt .. color
		end
	end

	local textTooltip, onTextClick
	if userName ~= nil then
		local userStartIndex, userEndIndex
		if thirdPerson then
			userStartIndex = #txt
			txt = txt .. userName .. " "
			userEndIndex = userStartIndex + #userName
		else
			userStartIndex = #txt + 4
			txt = txt .. nameColor .. userName .. ": \255\255\255\255"
			userEndIndex = userStartIndex + #userName
			whiteText = whiteText .. userName .. ": "
			if color ~= nil then
				txt = txt .. color
			end
		end

		textTooltip = {
			{
				startIndex = userStartIndex,
				endIndex = userEndIndex,
				tooltip = nameTooltip
			}
		}
		if supressNameClick then
			onTextClick = {} -- Think about putting discord link here?
		else
			onTextClick = {
				{
					startIndex = userStartIndex,
					endIndex = userEndIndex,
					OnTextClick = {
						function()
							WG.UserHandler.GetUserDropdownMenu(userName, isBattleChat)
							--Spring.Echo("Clicked on " .. userName .. ". TODO: Spawn popup.")
						end
					}
				}
			}
		end
	end

	onTextClick, textTooltip = WG.BattleProposalHandler.AddClickableInvites(userName, txt, message, onTextClick or {}, textTooltip or {})

	txt = txt .. message
	onTextClick, textTooltip = WG.BrowserHandler.AddClickableUrls(txt, onTextClick or {}, textTooltip or {})

	whiteText = whiteText .. message
	if self.tbHistory.text == "" then
		self.tbHistory:SetText(txt, textTooltip, onTextClick)
	else
		self.tbHistory:AddLine(txt, textTooltip, onTextClick)
	end

	if self.channelName then
		Spring.CreateDir("chatLogs")
		local logFile, errorMessage = io.open('chatLogs/' .. self.channelName .. ".txt", 'a')
		if logFile then
			if dateOverride then
				logFile:write("\n" .. ((string.sub(dateOverride, 0, 19) .. " - ") or "") .. whiteText)
			else
				logFile:write("\n" .. whiteText)
			end
			io.close(logFile)
		end
	end
end

function Console:SetTopic(newTopic)
	self:AddMessage(newTopic, nil, nil, Configuration.meColor)
end

local function lineIterator(s)
	if s:sub(-1)~="\n" then s=s.."\n" end
	return s:gmatch("(.-)\n")
end

-- remove trailing whitespace from string.
local function rtrim(s)
	local n = #s
	while n > 0 and s:find("^%s", n) do n = n - 1 end
	return s:sub(1, n)
end

function Console:LoadHistory(numLines)
	if not self.channelName then
		return
	end
	local path = 'chatLogs/' .. self.channelName .. ".txt"
	if not VFS.FileExists(path) then
		return
	end

	local logfile = VFS.LoadFile(path)

	if string.len(logfile) > 150 * numLines then -- dont load huge logs only to discard most of it.
		logfile = string.sub(logfile, -150 * numLines)
	end
	
	local lineCount = 0
	for line in lineIterator(logfile) do
		lineCount = lineCount + 1
	end

	local waitToWrite = lineCount - numLines
	for line in lineIterator(logfile) do
		if waitToWrite > 0 then
			waitToWrite = waitToWrite - 1
		else
			line = rtrim(line)
			local start = string.find(line, "%[")
			if start then
				local txt = "\255\128\128\128" .. string.sub(line, start)
				if self.tbHistory.text == "" then
					self.tbHistory:SetText(txt)
				else
					self.tbHistory:AddLine(txt)
				end
			end
		end
	end
	--local logFile, errorMessage = io.open(, 'r')
end

function Console:ClearHistory()
	self.tbHistory:SetText("")
end

function Console:Delete()
	self = nil
end
