local subnameMap = {
	['BARb stable'] = "BARbarian AI",
	['NullAI 0.1'] = "Inactive AI",
	['ScavengersAI'] = "ScavengersDefense AI",
	['ChickensAI'] = "RaptorsDefense AI",
	['STAI'] = "STAI",
}

local function GetAiSimpleName(name)
	return subnameMap[name] or name
end

local simpleAiOrder = {
	['BARb stable'] = 01,
	['STAI'] = 02,
	['SimpleAI'] = 11,
	['SimpleCheaterAI'] = 12,
	['SimpleDefenderAI'] = 13,
	['SimpleConstructorAI'] = 14,
	['ScavengersAI'] = 31,
	['ChickensAI'] = 41,
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
	['ChickensAI'] = "This is a PvE game mode, where hordes of alien creatures attack the players. Only add 1 per game.",
}

return {
	GetAiSimpleName = GetAiSimpleName,
	simpleAiOrder = simpleAiOrder,
	aiTooltip = aiTooltip
}
