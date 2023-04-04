local DEV_NAME = ""
local STABLE_NAME = " (old)"

local stableSubnameMap = {
	{"CircuitAIBeginner", "AI: Beginner" .. STABLE_NAME},
	{"CircuitAINovice", "AI: Novice" .. STABLE_NAME},
	{"CircuitAIEasy", "AI: Easy" .. STABLE_NAME},
	{"CircuitAINormal", "AI: Normal" .. STABLE_NAME},
	{"CircuitAIHard", "AI: Hard" .. STABLE_NAME},
	{"CircuitAIBrutal", "AI: Brutal" .. STABLE_NAME},
	{"CAI", "AI: Legacy"},
}

local devSubnameMap = {
	{"DevCircuitAIBeginner", "AI: Beginner" .. DEV_NAME},
	{"DevCircuitAINovice", "AI: Novice" .. DEV_NAME},
	{"DevCircuitAIEasy", "AI: Easy" .. DEV_NAME},
	{"DevCircuitAINormal", "AI: Normal" .. DEV_NAME},
	{"DevCircuitAIHard", "AI: Hard" .. DEV_NAME},
	{"DevCircuitAIBrutal", "AI: Brutal" .. DEV_NAME},
	{"DevCircuitEconomist", "AI: Economist Personality" .. DEV_NAME},
	{"CAI", "AI: Legacy"},
}

local function GetAiSimpleName(name)
	if name == "Null AI" then
		return "Inactive AI"
	end
	if string.find(name, "Chicken") then
		return name
	end
	local subnameMap = (WG.Chobby.Configuration:GetIsDevEngine() and devSubnameMap) or stableSubnameMap
	for i = 1, #subnameMap do
		if string.find(name, subnameMap[i][1]) then
			return subnameMap[i][2]
		end
	end
	return false
end

local simpleAiOrder = {
	["AI: Beginner" .. DEV_NAME] = -6,
	["AI: Novice" .. DEV_NAME] = -5,
	["AI: Easy" .. DEV_NAME] = -4,
	["AI: Normal" .. DEV_NAME] = -3,
	["AI: Hard" .. DEV_NAME] = -2,
	["AI: Brutal" .. DEV_NAME] = -1,
	["AI: Economist Personality" .. DEV_NAME] = -0.9,
	["AI: Beginner" .. STABLE_NAME] = 0,
	["AI: Novice" .. STABLE_NAME] = 1,
	["AI: Easy" .. STABLE_NAME] = 2,
	["AI: Normal" .. STABLE_NAME] = 3,
	["AI: Hard" .. STABLE_NAME] = 4,
	["AI: Brutal" .. STABLE_NAME] = 5,
	["Inactive AI"] = 6,
	["Chicken: Beginner"] = 6.5,
	["Chicken: Very Easy"] = 7,
	["Chicken: Easy"] = 8,
	["Chicken: Normal"] = 9,
	["Chicken: Hard"] = 10,
	["Chicken: Suicidal"] = 11,
	["Chicken: Custom"] = 12,
	["AI: Legacy"] = 13,
}

local aiTooltip = {
	["AI: Beginner" .. DEV_NAME] = "Recommended for players with no strategy game experience.",
	["AI: Novice" .. DEV_NAME] = "Recommended for players with some strategy game experience, or experience with related genres (such as MOBA).",
	["AI: Easy" .. DEV_NAME] = "Recommended for experienced strategy gamers with some experience of streaming economy.",
	["AI: Normal" .. DEV_NAME] = "Recommended for veteran strategy gamers.",
	["AI: Hard" .. DEV_NAME] = "Recommended for veteran strategy gamers who aren't afraid of losing.",
	["AI: Brutal" .. DEV_NAME] = "Recommended for veterans of Zero-K.",
	["AI: Economist Personality" .. DEV_NAME] = "Brutal AI with a bias for escalating and economy.",
	["AI: Beginner" .. STABLE_NAME] = "Recommended for players with no strategy game experience.",
	["AI: Novice" .. STABLE_NAME] = "Recommended for players with some strategy game experience, or experience with related genres (such as MOBA).",
	["AI: Easy" .. STABLE_NAME] = "Recommended for experienced strategy gamers with some experience of streaming economy.",
	["AI: Normal" .. STABLE_NAME] = "Recommended for veteran strategy gamers.",
	["AI: Hard" .. STABLE_NAME] = "Recommended for veteran strategy gamers who aren't afraid of losing.",
	["AI: Brutal" .. STABLE_NAME] = "Recommended for veterans of Zero-K.",
	["AI: Legacy"] = "Older unsupported AI, still potentially challenging.",
	["Inactive AI"] = "This AI does absolutely nothing after spawning.",
	["Chicken: Beginner"] = "Defeat waves of aliens.",
	["Chicken: Very Easy"] = "Defeat waves of aliens.",
	["Chicken: Easy"] = "Defeat waves of aliens.",
	["Chicken: Normal"] = "Defeat waves of aliens.",
	["Chicken: Hard"] = "Defeat waves of aliens.",
	["Chicken: Suicidal"] = "Defeat waves of aliens. Good luck.",
	["Chicken: Custom"] = "Customizable chicken defense. Look in Adv Options.",
}

return {
	GetAiSimpleName = GetAiSimpleName,
	simpleAiOrder = simpleAiOrder,
	aiTooltip = aiTooltip
}
