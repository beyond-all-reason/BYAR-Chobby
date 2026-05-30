Spring.Utilities = Spring.Utilities or {}

function Spring.Utilities.GetEngineVersion()
	return (Game and Game.version) or (Engine and Engine.version) or "Engine version error"
end
