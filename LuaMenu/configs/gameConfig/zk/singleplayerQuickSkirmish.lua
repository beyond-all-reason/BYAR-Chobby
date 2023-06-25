local skirmishSetupData = {
	pages = {
		{
			humanName = "Select Game Type",
			name = "gameType",
			options = {
				"1v1",
				"2v2",
				"3v3",
				"Survival",
			},
		},
		{
			humanName = "Select Difficulty",
			name = "difficulty",
			options = {
				"Beginner",
				"Novice",
				"Easy",
				"Normal",
				"Hard",
				"Brutal",
			},
			optionTooltip = {
				"Recommended for players with no strategy game experience.",
				"Recommended for players with some strategy game experience, or experience with related genres (such as MOBA).",
				"Recommended for experienced strategy gamers with some familiarity with streaming economy.",
				"Recommended for veteran strategy gamers.",
				"Recommended for veteran strategy gamers who aren't afraid of losing.",
				"Recommended for veterans of Zero-K.",
			}
		},
		{
			humanName = "Select Map",
			name = "map",
			tipText = "Click 'Advanced' for more maps and game modes.",
			minimap = true,
			options = {
				"TitanDuel 2.2",
				"Obsidian_1.5",
				"Fairyland 1.31",
				"Calamity 1.1",
			},
		},
	},
}

local chickenDifficulty = {
	"Chicken: Beginner",
	"Chicken: Very Easy",
	"Chicken: Easy",
	"Chicken: Normal",
	"Chicken: Hard",
	"Chicken: Suicidal",
}

local aiDifficultyMap = {
	"CircuitAIBeginner",
	"CircuitAINovice",
	"CircuitAIEasy",
	"CircuitAINormal",
	"CircuitAIHard",
	"CircuitAIBrutal",
}

function skirmishSetupData.ApplyFunction(battleLobby, pageChoices)
	local difficulty = pageChoices.difficulty or 2 -- easy is default
	local gameType = pageChoices.gameType or 1
	local map = pageChoices.map or 1

	local Configuration = WG.Chobby.Configuration
	local pageConfig = skirmishSetupData.pages
	battleLobby:SelectMap(pageConfig[3].options[map])

	battleLobby:SetBattleStatus({
		allyNumber = 0,
		isSpectator = false,
	})

	-- Chickens
	if gameType == 4 then
		battleLobby:AddAi(chickenDifficulty[difficulty], chickenDifficulty[difficulty], 1)
		return
	end

	local bitAppend = (Configuration:GetIsRunning64Bit() and "64") or "32"
	local devString = ((Configuration:GetIsDevEngine() and "Dev") or "")
	local aiName = devString .. aiDifficultyMap[difficulty] .. bitAppend
	local displayName = aiName

	if Configuration.gameConfig.GetAiSimpleName then
		local betterName = Configuration.gameConfig.GetAiSimpleName(displayName)
		if betterName then
			displayName = betterName
		end
	end

	-- AI game
	local aiNumber = 1
	local allies = gameType - 1
	for i = 1, allies do
		battleLobby:AddAi(displayName .. " (" .. aiNumber .. ")", aiName, 0, Configuration.gameConfig.aiVersion)
		aiNumber = aiNumber + 1
	end

	local enemies = gameType
	for i = 1, enemies do
		battleLobby:AddAi(displayName .. " (" .. aiNumber .. ")", aiName, 1, Configuration.gameConfig.aiVersion)
		aiNumber = aiNumber + 1
	end
end

return skirmishSetupData
