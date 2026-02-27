AiListWindow = ListWindow:extends{}

local IMG_SETTINGS = LUA_DIRNAME .. "images/settings.png"

function AiListWindow:init(lobby, gameName)

	self:super('init', lobbyInterfaceHolder, "Choose AI", false, "main_window", nil, {6, 7, 7, 4})
	self.window:SetPos(nil, nil, 500, 700)

	self.lobby = lobby or self.lobby
	self.validAiNames = {}

	-- Disable game-specific AIs for now since it breaks /luaui reload
	local ais = VFS.GetAvailableAIs(gameName)
	-- Barb and nullai are always available, but the rest need to be added manually here, because f you thats why
	local numAis = #ais
	local unversionedGameAis = Configuration.gameConfig.unversionedGameAis or {}
	for _, unversionedGameAi in ipairs(unversionedGameAis) do
		local found = false
		for i=1, numAis do
			if unversionedGameAi == ais[i].shortName then
				found = true
				break
			end
		end
		if found == false then
			ais[#ais+1] = {shortName = unversionedGameAi, version = "<not-versioned>"}
		end
	end

	--Spring.Echo("VFS.GetAvailableAIs(gameName)",gameName)
	--Spring.Utilities.TableEcho(ais)

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
	self.isSinglePlayer = isSingleplayer
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
	if Configuration.showAiOptions then
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
		classname = "button_small",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		OnClick = {
			function()
				local successFunc = function(aioptions)
					self:AddAi(displayName, shortName, version, aioptions)
					self:HideWindow()
				end
				WG.Chobby.AiOptionsWindow(displayName, shortName, path, successFunc)
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
		classname = "button_small",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		tooltip = tooltip,
		OnClick = {
			function()
				self:AddAi(displayName, shortName, version)
				self:HideWindow()
			end
		},
	}
end


local function PickRandomColor()
	local colorOptions = {
		{math.random(50,255),	0,						0					},
		{0,						math.random(50,255),	0					},
		{0,						0,						math.random(50,255)},
		
		{math.random(50,255),	math.random(0,255),		0					},
		{math.random(50,255),	0,						math.random(0,255)	},
		{math.random(50,255),	math.random(0,200),		math.random(0,200)	},

		{math.random(0,255),	math.random(50,255),	0					},
		{0,						math.random(50,255),	math.random(0,255)	},
		{math.random(0,200),	math.random(50,255),	math.random(0,200)	},

		{math.random(0,255),	0,						math.random(50,255)},
		{0,						math.random(0,255),		math.random(50,255)},
		{math.random(0,200),	math.random(0,200),		math.random(50,255)},
	}	
	
	local r = math.random(1,#colorOptions)
	return {colorOptions[r][1]/255, colorOptions[r][2]/255, colorOptions[r][3]/255,}
end

function AiListWindow:AddAi(displayName, shortName, version, options)
	local aiName
	local counter = 1
	local found = true

	local nameSuffix = ""
	if options and options.profile and Configuration.gameConfig.GetProfileDisplayName then
		local profileName = (Configuration.gameConfig.GetProfileDisplayName(shortName, options.profile) or "Custom"):gsub("|", "-")
		if profileName then
			nameSuffix = " [" .. profileName .. "]"
		end
	elseif shortName == "BARb" then
		nameSuffix = "[Hard-Balanced]" --BARb default difficulty
	end

	while found do
		found = false
		aiName = displayName .. " (" .. tostring(counter) .. ")" .. nameSuffix
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
	
	local battleStatusOptions = {side = math.random(0,1), teamColor = PickRandomColor(),}
	
	self.lobby:AddAi(aiName, shortName, self.allyTeam, version, options, battleStatusOptions)
	if self.lobby.name ~= "singleplayer" and type(options) == "table" then
		self.lobby:SayBattle("!aiProfile " .. aiName .. " ".. Json.encode(options))
	end
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
