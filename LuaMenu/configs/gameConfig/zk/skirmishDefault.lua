return {
	map = "TitanDuel 2.2",
	enemyAI = ((Configuration:GetIsDevEngine() and "Dev") or "") .. "CircuitAIEasy" .. ((Configuration:GetIsRunning64Bit() and "64") or "32"),
}
