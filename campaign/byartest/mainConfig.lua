local shortname = "byartest"

local planetDefs     = VFS.Include("campaign/" .. shortname .. "/planetDefs.lua")
--local codex          = VFS.Include("campaign/" .. shortname .. "/codex.lua")
local initialUnlocks = VFS.Include("campaign/" .. shortname .. "/initialUnlocks.lua")
local abilityDefs    = VFS.Include("campaign/" .. shortname .. "/abilityDefs.lua")
local unlocksList    = VFS.Include("campaign/" .. shortname .. "/unlocksList.lua")
local commConfig     = VFS.Include("campaign/" .. shortname .. "/commConfig.lua")
local aiConfig       = VFS.Include("campaign/" .. shortname .. "/aiConfig.lua")

---------------------------------------------------------------------------------
-- Getters
---------------------------------------------------------------------------------

local externalFuncAndData = {
	planetDefs = planetDefs,
	codex = codex,
	initialUnlocks = initialUnlocks,
	abilityDefs = abilityDefs,
	unlocksList = unlocksList,
	commConfig = commConfig,
	aiConfig = aiConfig,
}

return externalFuncAndData
