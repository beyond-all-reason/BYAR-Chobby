EmojiTextBox = Control:Inherit{
	classname = "emojitextbox",

	padding = {0, 0, 0, 0},
	text = "",
	autoHeight = true,
	agressiveMaxLines = false,
	agressiveMaxLinesPreserve = false,
	lineSpacing = 0,
	selectable = false,
	subTooltips = false,
	noFont = false,
	emojiScale = 0.95,
	emojiLinePadding = 2,
	lines = {},
	physicalLines = {},
}

local this = EmojiTextBox
local inherited = this.inherited

local function AddLineBreakIfMissing(text)
	if text:sub(-1) ~= "\n" then
		return text .. "\n"
	end
	return text
end

local function LineIterator(text)
	return AddLineBreakIfMissing(text):gmatch("(.-)\n")
end

local function IsAliasName(alias)
	return alias and alias ~= "" and string.match(alias, "^[%w_+%-]+$") ~= nil
end

local function Utf8Next(text, pos)
	local utf8NextChar = (Chili and Chili.Utf8NextChar) or (WG and WG.Chili and WG.Chili.Utf8NextChar) or Utf8NextChar
	if type(utf8NextChar) == "function" then
		return utf8NextChar(text, pos)
	end

	local byte = string.byte(text, pos)
	if not byte then
		return pos + 1
	end

	local length = 1
	if byte >= 240 then
		length = 4
	elseif byte >= 224 then
		length = 3
	elseif byte >= 192 then
		length = 2
	end
	return math.min(#text + 1, pos + length)
end

local function GetTextureHandler()
	return (Chili and Chili.TextureHandler) or (WG and WG.Chili and WG.Chili.TextureHandler)
end

function EmojiTextBox:New(obj)
	obj = inherited.New(self, obj)
	local text = obj.text or ""
	obj.text = ""
	obj.lines = {}
	obj.physicalLines = {}
	obj:SetText(text)
	return obj
end

function EmojiTextBox:GetEmojiSize()
	local fontLineHeight = self.font and self.font.GetLineHeight and self.font:GetLineHeight()
	local fontSize = self.font and self.font.size or 14
	return math.max(12, math.floor((fontLineHeight or fontSize) * (self.emojiScale or 1)))
end

function EmojiTextBox:GetLineHeight()
	local fontLineHeight = math.ceil(self.font:GetLineHeight()) + self.lineSpacing
	local emojiLineHeight = self:GetEmojiSize() + self.lineSpacing + ((self.emojiLinePadding or 0) * 2)
	return math.max(fontLineHeight, emojiLineHeight)
end

function EmojiTextBox:GetEmojiYOffset(size)
	local fontHeight = self.font and self.font.GetAscenderHeight and math.ceil(self.font:GetAscenderHeight()) or nil
	fontHeight = fontHeight or (self.font and self.font.GetLineHeight and math.ceil(self.font:GetLineHeight())) or self:GetLineHeight()
	return math.max(0, math.floor((fontHeight - size) * 0.5))
end

function EmojiTextBox:GetTextWidth(text)
	if not text or text == "" then
		return 0
	end
	return self.font:GetTextWidth(text)
end

function EmojiTextBox:CreateTextToken(text, startIndex, endIndex, colorPrefix)
	return {
		type = "text",
		text = text,
		startIndex = startIndex,
		endIndex = endIndex,
		colorPrefix = colorPrefix or "",
		width = self:GetTextWidth(text),
	}
end

function EmojiTextBox:CreateEmojiToken(alias, startIndex, endIndex)
	return {
		type = "emoji",
		alias = alias,
		startIndex = startIndex,
		endIndex = endIndex,
		image = ChatEmojis and ChatEmojis.GetImageFile and ChatEmojis.GetImageFile(alias),
		fallback = ChatEmojis and ChatEmojis.aliases and ChatEmojis.aliases[alias],
		width = self:GetEmojiSize() + 2,
	}
end

function EmojiTextBox:AppendTextTokens(tokens, text, startIndex, colorPrefix)
	local pos = 1
	local len = #text
	while pos <= len do
		local isSpace = string.find(string.sub(text, pos, pos), "%s") ~= nil
		local nextPos = pos + 1
		while nextPos <= len and (string.find(string.sub(text, nextPos, nextPos), "%s") ~= nil) == isSpace do
			nextPos = nextPos + 1
		end
		local chunk = string.sub(text, pos, nextPos - 1)
		local chunkStart = startIndex + pos - 1
		local token = self:CreateTextToken(chunk, chunkStart, chunkStart + #chunk - 1, colorPrefix)
		token.isSpace = isSpace
		tokens[#tokens + 1] = token
		pos = nextPos
	end
end

function EmojiTextBox:BuildDrawRuns(tokens)
	local runs = {}
	local x = 0
	local textX = 0
	local textParts = {}

	local function FlushText()
		if #textParts > 0 then
			runs[#runs + 1] = {
				type = "text",
				x = textX,
				text = table.concat(textParts),
			}
			textParts = {}
		end
	end

	for i = 1, #tokens do
		local token = tokens[i]
		local width = token.width or 0
		if token.type == "emoji" then
			FlushText()
			runs[#runs + 1] = {
				type = "emoji",
				x = x,
				token = token,
			}
			x = x + width
			textX = x
		elseif token.text and token.text ~= "" then
			textParts[#textParts + 1] = (token.colorPrefix or "") .. token.text
			x = x + width
		else
			x = x + width
		end
	end
	FlushText()

	return runs
end

function EmojiTextBox:Tokenize(text)
	local tokens = {}
	local pos = 1
	local textLen = #text
	local colorPrefix = ""

	while pos <= textLen do
		local byte = string.byte(text, pos)
		if byte == 255 and pos + 3 <= textLen then
			colorPrefix = string.sub(text, pos, pos + 3)
			pos = pos + 4
		elseif byte == 58 then
			local aliasEnd = string.find(text, ":", pos + 1, true)
			local alias = aliasEnd and string.sub(text, pos + 1, aliasEnd - 1)
			if IsAliasName(alias) and ChatEmojis and ChatEmojis.GetImageFile and ChatEmojis.GetImageFile(alias) then
				tokens[#tokens + 1] = self:CreateEmojiToken(alias, pos, aliasEnd)
				pos = aliasEnd + 1
			else
				self:AppendTextTokens(tokens, string.sub(text, pos, pos), pos, colorPrefix)
				pos = pos + 1
			end
		else
			local runStart = pos
			while pos <= textLen do
				local b = string.byte(text, pos)
				if b == 255 or b == 58 then
					break
				end
				pos = pos + 1
			end
			self:AppendTextTokens(tokens, string.sub(text, runStart, pos - 1), runStart, colorPrefix)
		end
	end

	return tokens
end

function EmojiTextBox:PushPhysicalLine(lineID, tokens, width)
	local prevLine = self.physicalLines[#self.physicalLines]
	local y = prevLine and (prevLine.y + self:GetLineHeight()) or 0
	self.physicalLines[#self.physicalLines + 1] = {
		lineID = lineID,
		tokens = tokens,
		drawRuns = self:BuildDrawRuns(tokens),
		width = width or 0,
		y = y,
	}
end

function EmojiTextBox:CopyToken(token)
	local copy = {}
	for key, value in pairs(token) do
		copy[key] = value
	end
	return copy
end

function EmojiTextBox:SplitTextToken(token, maxWidth, currentTokens, currentWidth, lineID)
	local text = token.text
	local pos = 1
	local textLen = #text
	local colorPrefix = token.colorPrefix
	while pos <= textLen do
		local tokenStart = token.startIndex + pos - 1
		local fitEnd = pos - 1
		local nextPos = pos
		while nextPos <= textLen do
			local charEnd = Utf8Next(text, nextPos) - 1
			local candidate = string.sub(text, pos, charEnd)
			local candidateWidth = self:GetTextWidth(candidate)
			if #currentTokens > 0 and currentWidth + candidateWidth > maxWidth then
				break
			end
			if #currentTokens == 0 and candidateWidth > maxWidth and fitEnd >= pos then
				break
			end
			fitEnd = charEnd
			nextPos = charEnd + 1
			if currentWidth + candidateWidth >= maxWidth then
				break
			end
		end

		if fitEnd < pos then
			if #currentTokens > 0 then
				self:PushPhysicalLine(lineID, currentTokens, currentWidth)
				currentTokens = {}
				currentWidth = 0
			else
				local charEnd = Utf8Next(text, pos) - 1
				local chunk = string.sub(text, pos, charEnd)
				local chunkToken = self:CreateTextToken(chunk, tokenStart, tokenStart + #chunk - 1, colorPrefix)
				currentTokens = {chunkToken}
				currentWidth = chunkToken.width
				pos = charEnd + 1
			end
		else
			local chunk = string.sub(text, pos, fitEnd)
			local chunkToken = self:CreateTextToken(chunk, tokenStart, tokenStart + #chunk - 1, colorPrefix)
			currentTokens[#currentTokens + 1] = chunkToken
			currentWidth = currentWidth + chunkToken.width
			pos = fitEnd + 1
			if pos <= textLen then
				self:PushPhysicalLine(lineID, currentTokens, currentWidth)
				currentTokens = {}
				currentWidth = 0
			end
		end
	end
	return currentTokens, currentWidth
end

function EmojiTextBox:GeneratePhysicalLines(lineID)
	local logicalLine = self.lines[lineID]
	local tokens = self:Tokenize(logicalLine.text)
	local padding = self.padding
	local maxWidth = math.max(1, self.width - padding[1] - padding[3])
	local currentTokens = {}
	local currentWidth = 0

	for i = 1, #tokens do
		local token = tokens[i]
		if token.type == "text" and token.isSpace and #currentTokens == 0 then
			-- Avoid leading spaces after a wrap.
		elseif token.type == "text" and token.width > maxWidth then
			currentTokens, currentWidth = self:SplitTextToken(token, maxWidth, currentTokens, currentWidth, lineID)
		else
			local width = token.width or 0
			if #currentTokens > 0 and currentWidth + width > maxWidth then
				self:PushPhysicalLine(lineID, currentTokens, currentWidth)
				currentTokens = {}
				currentWidth = 0
				if not (token.type == "text" and token.isSpace) then
					local tokenCopy = self:CopyToken(token)
					currentTokens[#currentTokens + 1] = tokenCopy
					currentWidth = width
				end
			else
				local tokenCopy = self:CopyToken(token)
				currentTokens[#currentTokens + 1] = tokenCopy
				currentWidth = currentWidth + width
			end
		end
	end

	self:PushPhysicalLine(lineID, currentTokens, currentWidth)
end

function EmojiTextBox:RebuildPhysicalLines()
	self.physicalLines = {}
	for lineID = 1, #self.lines do
		self:GeneratePhysicalLines(lineID)
	end
end

function EmojiTextBox:UpdateLayout()
	self:RebuildPhysicalLines()
	if self.autoHeight then
		self:Resize(nil, math.max(1, #self.physicalLines * self:GetLineHeight()), true, true)
	end
	self:Invalidate()
	return true
end

function EmojiTextBox:SetText(newtext, tooltips, OnTextClick)
	newtext = newtext or ""
	self.text = newtext
	self.lines = {}
	for line in LineIterator(newtext) do
		self.lines[#self.lines + 1] = {
			text = line,
			tooltips = tooltips,
			OnTextClick = OnTextClick,
		}
	end
	self:UpdateLayout()
end

function EmojiTextBox:AddLine(text, tooltips, OnTextClick)
	if self.agressiveMaxLines and #self.lines > self.agressiveMaxLines then
		local preserve = {}
		for i = math.max(1, #self.lines - self.agressiveMaxLinesPreserve), #self.lines do
			preserve[#preserve + 1] = self.lines[i]
		end
		self.lines = preserve
		local preservedText = {}
		for i = 1, #self.lines do
			preservedText[#preservedText + 1] = self.lines[i].text
		end
		self.text = table.concat(preservedText, "\n")
	end

	self.lines[#self.lines + 1] = {
		text = text or "",
		tooltips = tooltips,
		OnTextClick = OnTextClick,
	}
	self.text = self.text == "" and (text or "") or (self.text .. "\n" .. (text or ""))
	self:UpdateLayout()
end

function EmojiTextBox:GetPhysicalLinePosition(distanceFromBottom, usePhysical)
	if usePhysical then
		local lineID = #self.physicalLines - distanceFromBottom + 1
		if lineID and self.physicalLines[lineID] then
			return self.physicalLines[lineID].y
		end
		return 0
	end
	local lineID = #self.lines - distanceFromBottom + 1
	if lineID < 1 then
		return 0
	end
	local position = 0
	for i = #self.physicalLines, 1, -1 do
		local data = self.physicalLines[i]
		if data.lineID == lineID then
			position = data.y
		elseif data.lineID < lineID then
			return position
		end
	end
	return 0
end

function EmojiTextBox:DrawEmoji(token, x, y)
	local size = self:GetEmojiSize()
	local emojiY = y + self:GetEmojiYOffset(size)
	local textureHandler = GetTextureHandler()
	if token.image and textureHandler and textureHandler.LoadTexture then
		gl.Color(1, 1, 1, 1)
		local loaded = pcall(textureHandler.LoadTexture, 0, token.image, self)
		if loaded then
			gl.TexRect(x, emojiY, x + size, emojiY + size, false, true)
			gl.Texture(0, false)
			return
		end
		gl.Texture(0, false)
	end
	if token.fallback then
		self.font:Draw(token.fallback, x, y)
	end
end

function EmojiTextBox:DrawControl()
	local clientX, clientY = self.clientArea[1], self.clientArea[2]
	for i = 1, #self.physicalLines do
		local physicalLine = self.physicalLines[i]
		local y = clientY + physicalLine.y
		local drawRuns = physicalLine.drawRuns or {}
		for j = 1, #drawRuns do
			local run = drawRuns[j]
			if run.type == "emoji" then
				self:DrawEmoji(run.token, clientX + run.x, y)
			elseif run.text and run.text ~= "" then
				self.font:Draw(run.text, clientX + run.x, y)
			end
		end
	end
end

function EmojiTextBox:GetCursorByMousePos(x, y)
	local clientX, clientY = self.clientArea[1], self.clientArea[2]
	local localX = x - clientX
	local localY = y - clientY
	local lineHeight = self:GetLineHeight()
	local physicalLineID = math.min(#self.physicalLines, math.max(1, math.floor(localY / lineHeight) + 1))
	local physicalLine = self.physicalLines[physicalLineID]
	if not physicalLine then
		return nil
	end

	local cursorX = 0
	for i = 1, #physicalLine.tokens do
		local token = physicalLine.tokens[i]
		local width = token.width or 0
		if localX <= cursorX + width then
			if token.type == "text" and token.text and token.text ~= "" then
				local textPos = 1
				while textPos <= #token.text do
					local nextPos = Utf8Next(token.text, textPos)
					local partialWidth = self:GetTextWidth(string.sub(token.text, 1, nextPos - 1))
					if localX <= cursorX + partialWidth then
						return physicalLine.lineID, token.startIndex + textPos - 1
					end
					textPos = nextPos
				end
			end
			return physicalLine.lineID, token.startIndex
		end
		cursorX = cursorX + width
	end

	local lastToken = physicalLine.tokens[#physicalLine.tokens]
	return physicalLine.lineID, lastToken and lastToken.endIndex or 1
end

function EmojiTextBox:MouseDown(x, y, ...)
	local lineID, cursor = self:GetCursorByMousePos(x, y)
	local line = lineID and self.lines[lineID]
	if line and line.OnTextClick then
		local cx, cy = self:ScreenToLocal(x, y)
		for _, onTextClick in pairs(line.OnTextClick) do
			if onTextClick.startIndex <= cursor and onTextClick.endIndex >= cursor then
				for _, f in pairs(onTextClick.OnTextClick) do
					f(self, cx, cy, ...)
				end
				self:Invalidate()
				return self
			end
		end
	end
	return inherited.MouseDown(self, x, y, ...) or self
end

function EmojiTextBox:MouseMove(x, y, dx, dy, button)
	if self.subTooltips then
		local tooltipSet = false
		if button == nil then
			local lineID, cursor = self:GetCursorByMousePos(x, y)
			local line = lineID and self.lines[lineID]
			if line and line.tooltips then
				for _, tooltip in pairs(line.tooltips) do
					if tooltip.startIndex <= cursor and tooltip.endIndex >= cursor then
						self.tooltip = tooltip.tooltip
						tooltipSet = true
						break
					end
				end
			end
		end
		if not tooltipSet then
			self.tooltip = nil
		end
	end
	return inherited.MouseMove(self, x, y, dx, dy, button)
end

function EmojiTextBox:HitTest()
	return self.selectable and self
end
