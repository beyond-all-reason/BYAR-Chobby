local subnameMap = {
	['BARb stable'] = "BARbarian AI",
	['NullAI 0.1'] = "Inactive AI"
}

local function GetAiSimpleName(name)
	return subnameMap[name] or name
end

local simpleAiOrder = {
	['BARb stable'] = 01,
	['SimpleAI'] = 11,
	['SimpleCheaterAI'] = 12,
	['SimpleDefenderAI'] = 13,
	['SimpleConstructorAI'] = 14,
	['STAI'] = 21,
	['ScavengersAI'] = 31,
	['Chicken: Very Easy'] = 41,
	['Chicken: Easy'] = 42,
	['Chicken: Normal'] = 43,
	['Chicken: Hard'] = 44,
	['Chicken: Very Hard'] = 45,
	['Chicken: Epic!'] = 46,
	['Chicken: Survival'] = 47,
	['NullAI 0.1'] = 51,
}

local aiTooltip = {
	['SimpleAI'] = "A simple, easy playing beginner AI (Great for your first game!)",
	['SimpleCheaterAI'] = "A moderately difficult AI, cheats!",
	['SimpleDefenderAI'] = "An easy AI, mostly defends and doesnt attack much",
	['ScavengersAI'] = "This is a PvE game mode, with an increasing difficulty waves of Scavenger AI controlled units attacking the players. Only add 1 per game.",
	['STAI'] = "A medium to hard difficulty, experimental, non cheating AI.",
	['NullAI 0.1'] = "A game-testing AI. Literally does nothing.",
	['BARb stable'] = "The recommended excellent performance, adjustable difficulty, non-cheating AI. Add as many as you wish!",
	['Chicken: Very Easy'] = "A moderate difficulty PvE AI, where hordes of alien creatures attack the players. Only add 1 per game.",
	['Chicken: Easy'] = "An intermediate difficulty PvE AI, where hordes of alien creatures attack the players. Only add 1 per game.",
	['Chicken: Normal'] = "A hard difficulty PvE AI, where hordes of alien creatures attack the players. Only add 1 per game.",
	['Chicken: Hard'] = "A hard difficulty PvE AI, where hordes of alien creatures attack the players. Only add 1 per game.",
	['Chicken: Very Hard'] = "A very hard difficulty PvE AI, where hordes of alien creatures attack the players. Only add 1 per game.",
	['Chicken: Epic!'] = "An extreme difficulty PvE AI, where hordes of alien creatures attack the players. Only add 1 per game.",
	['Chicken: Survival'] = "An extreme difficulty PvE AI, where ENDLESS hordes of alien creatures attack the players. Only add 1 per game.",
}

return {
	GetAiSimpleName = GetAiSimpleName,
	simpleAiOrder = simpleAiOrder,
	aiTooltip = aiTooltip
}
