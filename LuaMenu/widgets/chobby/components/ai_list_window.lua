AiListWindow = ListWindow:extends{}

local IMG_SETTINGS = LUA_DIRNAME .. "images/settings.png"

function AiListWindow:init(lobby, gameName)

	self:super('init', lobbyInterfaceHolder, "Choose AI", false, "main_window", nil, {6, 7, 7, 4})
	self.window:SetPos(nil, nil, 500, 700)

	self.lobby = lobby or self.lobby
	self.validAiNames = {}

	-- Disable game-specific AIs for now since it breaks /luaui reload
	local ais = VFS.GetAvailableAIs(gameName)

	local blackList = Configuration.gameConfig.aiBlacklist
	local oldAiVersions = (not Configuration.showOldAiVersions) and Configuration.gameConfig.oldAiVersions
	local isRunning64Bit = Configuration:GetIsRunning64Bit()
	local isSingleplayer = lobby.name == "singleplayer"

	for i, ai in pairs(ais) do
		self:AddAiToList(ai, blackList, oldAiVersions, isRunning64Bit, isSingleplayer)
	end
end

function AiListWindow:CompareItems(id1, id2)
	local order = Configuration.simpleAiList and Configuration.gameConfig.simpleAiOrder
	if order then
		local pos1 = order[id1] or math.huge
		local pos2 = order[id2] or math.huge
		return pos1 < pos2
	end
	return true
end

function AiListWindow:AddAiToList(ai, blackList, oldAiVersions, isRunning64Bit, isSingleplayer)
	local shortName = ai.shortName or "Unknown"

	if blackList and blackList[shortName] then
		return
	end

	if (isRunning64Bit and string.find(shortName, "32")) or ((not isRunning64Bit) and string.find(shortName, "64")) then
		return
	end


	local version = ""
	if ai.version ~= "<not-versioned>" then
		version = " " .. ai.version
	end
	local aiName = shortName .. version

	if oldAiVersions then
		for i = 1, #oldAiVersions do
			if string.find(aiName, oldAiVersions[i]) then
				return
			end
		end
	end

	local displayName = aiName
	if Configuration.simpleAiList and Configuration.gameConfig.GetAiSimpleName then
		displayName = Configuration.gameConfig.GetAiSimpleName(displayName)
		if not displayName then
			return
		end
	end

	self.validAiNames[shortName] = displayName

	local tooltip = nil
	if Configuration.gameConfig.aiTooltip then
		tooltip = Configuration.gameConfig.aiTooltip[aiName]
	end

	local buttonList = {}
	local btnWidth = "100%"
	if Configuration.showAiOptions and isSingleplayer then
		local path = "AI/Skirmish/" .. shortName .. "/" .. ai.version .. "/AIOptions.lua"
		if VFS.FileExists(path) then
			buttonList[#buttonList + 1] = self:MakeAiOptionsButton(displayName, tooltip, shortName, ai.version, path)
			btnWidth = "80%"
		end
	end
	buttonList[#buttonList + 1] = self:MakeAiButton(btnWidth, displayName, tooltip, shortName, ai.version)
	self:AddRow(buttonList, aiName)
end

function AiListWindow:MakeAiOptionsButton(displayName, tooltip, shortName, version, path)
	local optionsButton = Button:New {
		x = "80%",
		y = 0,
		width = "20%",
		height = "100%",
		caption = "",
		font = Configuration:GetFont(3),
		OnClick = {
			function()
				local successFunc = function(aioptions)
					self:AddAi(displayName, shortName, version, aioptions)
					self:HideWindow()
				end
				WG.Chobby.AiOptionsWindow(displayName, path, successFunc)
			end
		},
	}
	local optionsImage = Image:New {
		x = "10%",
		y = "10%",
		width = "80%",
		height = "80%",
		file = IMG_SETTINGS,
		parent = optionsButton,
	}
	return optionsButton
end

function AiListWindow:MakeAiButton(btnWidth, displayName, tooltip, shortName, version)
	return Button:New {
		x = 0,
		y = 0,
		width = btnWidth,
		height = "100%",
		caption = displayName,
		font = Configuration:GetFont(3),
		tooltip = tooltip,
		OnClick = {
			function()
				self:AddAi(displayName, shortName, version)
				self:HideWindow()
			end
		},
	}
end

function AiListWindow:AddAi(displayName, shortName, version, options)
	local aiName
	local counter = 1
	local found = true
	while found do
		found = false
		aiName = displayName .. " (" .. tostring(counter) .. ")"
		-- Ubserver AI names cannot include whitespace
		if WG.Server.protocol == "spring" then
			aiName = aiName:gsub(" ", "")
		end
		for _, userName in pairs(self.lobby.battleAis) do
			if aiName == userName then
				found = true
				break
			end
		end
		counter = counter + 1
	end
	self.lobby:AddAi(aiName, shortName, self.allyTeam, version, options)
	self.lobby:UpdateAi(aiName, {side = math.random(0,1), teamColor = {math.random(),math.random(),math.random()},})
	Configuration:SetConfigValue("lastAddedAiName", shortName)
end

function AiListWindow:QuickAdd(shortName)
	if self.validAiNames[shortName] then
		self:AddAi(self.validAiNames[shortName], shortName)
		return true
	end
end

function AiListWindow:SetAllyTeam(allyTeam)
	self.allyTeam = allyTeam or self.allyTeam
end
