local mapsByGameType = {
	["1v1"] = {
		"Onyx Cauldron 2.2.1",
		"Avalanche 3.4",
		"Ravaged Remake v1.2",
		"Shallow Straits v1.0.1",
	},
	["2v2"] = {
		"Fallendell_V4",
		"Isidis crack 1.1",
		"Seths Ravine Remake 1.3.1",
		"Red Comet Remake 1.8",
	},
	["3v3"] = {
		"Eye Of Horus 1.7.1",
		"Charlie In The Hills Remake v1.1",
		"Altair_Crossing_V4.1",
		"Archsimkats_Valley_V1",
	},
	["Scavengers"] = {
		"Ancient Bastion Remake 0.5",
		"Ancient Vault v1.4",
		"All That Glitters v2.2",
		"Requiem Outpost 1.0.1",
	},
	["Raptors"] = {
		"Ancient Bastion Remake 0.5",
		"Ancient Vault v1.4",
		"All That Glitters v2.2",
		"Requiem Outpost 1.0.1",
	},
}

local gameTypes = {
	"1v1",
	"2v2",
	"3v3",
	"Scavengers",
	"Raptors",
}

local skirmishSetupData = {
	mapsByGameType = mapsByGameType,
	pages = {
		{
			humanName = "Select Game Type",
			name = "gameType",
			minimap = false,
			options = gameTypes,
			optionTooltip = {
				"1 vs 1 against AI",
				"2 vs 2 with an AI ally and enemies",
				"3 vs 3 with AI allies and enemies",
				"Survival: Defend against waves of Scavenger units",
				"Survival: Face hordes of alien Raptors",
			}
		},
		{
			humanName = "Select Difficulty",
			name = "difficulty",
			minimap = false,
			options = {
				"Easy",
				"Medium",
				"Hard",
			},
			optionTooltip = {
				"For players new to RTS games.",
				"For players familiar with RTS games.",
				"For veteran RTS players.",
			}
		},
		{
			humanName = "Select Map",
			name = "map",
			minimap = true,
			tipText = "Click 'Advanced' for more maps and options.",
			options = (function()
				local queueMapsForDownload = {}
				for _, maps in pairs(mapsByGameType) do
					for _, map in ipairs(maps) do
						table.insert(queueMapsForDownload, map)
					end
				end
				return queueMapsForDownload
			end)(),
			getDynamicOptions = function(pageChoices)
				local selectedGameType = gameTypes[pageChoices.gameType or 1]
				Spring.Echo("Selected game type string: " .. tostring(selectedGameType))
				return mapsByGameType[selectedGameType]
			end,
		},
	},
}

function skirmishSetupData.ApplyFunction(battleLobby, pageChoices)
	local difficulty = pageChoices.difficulty or 1
	local gameType = pageChoices.gameType or 1
	local map = pageChoices.map or 1

	local pageConfig = skirmishSetupData.pages
	local selectedGameType = pageConfig[1].options[gameType]
	local mapOptions = skirmishSetupData.mapsByGameType[selectedGameType]
	battleLobby:SelectMap(mapOptions[map])

	if mapOptions[map] == "Archsimkats_Valley_V1" then
		WG.BattleRoomWindow.RemoveStartRect()
		local l = 0
		local r = 70
		local t = 0
		local b = 90
		WG.BattleRoomWindow.AddStartRect(0, l, t, r, b)
		local l = 130
		local r = 200
		local t = 110
		local b = 200
		WG.BattleRoomWindow.AddStartRect(1, l, t, r, b)
	end

	battleLobby:SetBattleStatus({
		allyNumber = 0,
		isSpectator = false,
	})

	local pveDifficultyMap = {
		["Easy"] = "easy",
		["Medium"] = "normal",
		["Hard"] = "hard"
	}

	if gameType == 4 then -- Scavengers
		battleLobby:AddAi("ScavengersDefenseAI(1)", "ScavengersAI", 1)
		battleLobby:SetModOptions({scav_difficulty = pveDifficultyMap[pageConfig[2].options[difficulty]]})
		return
	elseif gameType == 5 then -- Raptors
		battleLobby:AddAi("RaptorsDefenseAI(1)", "RaptorsAI", 1)
		battleLobby:SetModOptions({raptor_difficulty = pveDifficultyMap[pageConfig[2].options[difficulty]]})
		return
	end

	-- Regular AI games
	local aiName = "BARbarianAI"
	local displayName = aiName
	local aiNumber = 1
	local allies = gameType - 1

	for i = 1, allies do
		local aiOptions = {
			profile = pageConfig[2].options[difficulty]
		}
		local battleStatusOptions = {
			allyNumber = 0,
			side = math.random(0, 1),
		}
		battleLobby:AddAi(displayName .. "(" .. aiNumber .. ")", "BARb", 0, nil, aiOptions, battleStatusOptions)
		aiNumber = aiNumber + 1
	end

	local enemies = gameType
	for i = 1, enemies do
		local aiOptions = {
			profile = pageConfig[2].options[difficulty]
		}
		local battleStatusOptions = {
			allyNumber = 1,
			side = math.random(0, 1),
		}
		battleLobby:AddAi(displayName .. "(" .. aiNumber .. ")", "BARb", 1, nil, aiOptions, battleStatusOptions)
		aiNumber = aiNumber + 1
	end
end

return skirmishSetupData
