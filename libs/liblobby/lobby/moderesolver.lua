-- Shared resolver: turns a selected game mode into its full effective modoption
-- set. Single source of truth for singleplayer (interface_skirmish), the
-- multiplayer modoptions panel send-path, and the panel display, so they cannot
-- drift. The server SPADS ModeCommand plugin mirrors this same logic from
-- modes.json (baked by BAR CI from the same modes/*.lua) for the hosted game
-- version, so client and server agree as long as both are keyed to that version.
--
-- modes: the activeModes shape ->
--   { [category] = { modes = { { key=, category=, modOptions = {...} }, ... } } }
-- defs:  the modoptions list -> array of { key=, section=, type=, def=, ... }

ModeResolver = ModeResolver or {}

-- modoptions are strings on the wire; booleans map to the engine's "1"/"0".
-- Engine Lua numbers are float32, so plain tostring leaks precision noise
-- ("0.60000002"). Round at float32's ~7-digit precision with %.7f, then strip
-- trailing zeros (the engine's %g does not trim them). Yields "0.6", "30", "-1".
-- This MUST match the export widget's toModOptionValue (Beyond-All-Reason
-- modules/modes/widgets/export_modes.lua) byte-for-byte: the values we send must read
-- back identically to modes.json, which the export bakes the same way.
local function toVal(v)
	if type(v) == "boolean" then return v and "1" or "0" end
	if type(v) == "number" then
		return (string.format("%.7f", v):gsub("0+$", ""):gsub("%.$", ""))
	end
	return tostring(v)
end

local function findMode(modes, category, modeKey)
	local catModes = modes and modes[category]
	if not (catModes and catModes.modes) then return nil end
	for _, m in ipairs(catModes.modes) do
		if m.key == modeKey then return m end
	end
	return nil
end

-- Whether an option's section answers to the category: directly (section ==
-- category) or by declaration (the section entry's mode_category — a flavor's
-- dials handing the choice to a shared axis, e.g. scav_defense_options ->
-- game). Section entries ride in the same defs list, so governance is
-- computed from what the caller already has.
local function governedSections(defs, category)
	local governed = { [category] = true }
	for i = 1, #defs do
		local o = defs[i]
		if o.key and o.type == "section" and o.mode_category == category then
			governed[o.key] = true
		end
	end
	return governed
end

-- Full effective modoptions for a mode: the category's modoption defaults overlaid
-- with the mode preset, then any deviations, plus the <category>_mode selector.
-- Returns nil if the mode data is unavailable, so callers can fall back to whatever
-- options they were handed.
function ModeResolver.Resolve(modes, defs, category, modeKey, deviations)
	if not defs then return nil end
	local mode = findMode(modes, category, modeKey)
	if not mode then return nil end

	local selectorKey = category .. "_mode"
	local governed = governedSections(defs, category)
	local out = {}
	for i = 1, #defs do
		local o = defs[i]
		if governed[o.section] and o.key and o.key ~= selectorKey
				and o.type ~= "subheader" and o.type ~= "separator" and o.def ~= nil then
			out[o.key] = toVal(o.def)
		end
	end
	for k, rule in pairs(mode.modOptions or {}) do
		if k ~= selectorKey and rule.value ~= nil then out[k] = toVal(rule.value) end
	end
	if deviations then
		for k, v in pairs(deviations) do out[k] = toVal(v) end
	end
	out[selectorKey] = modeKey
	return out
end

-- The option set to send on a multiplayer !mode command (also the text SPADS shows
-- voters): the user's deviations from the SELECTED MODE's own preset -- options whose
-- effective value differs from what the mode itself sets them to. The baseline is the
-- mode preset (the category defaults overlaid with the mode's modOptions), NOT the
-- bare modoption defaults: a value the mode bakes in (e.g. tech_core's tax rates) is
-- part of the mode, not a deviation, so a clean mode pick sends NO option params --
-- just the mode key, which the server expands into the full preset from its
-- version-matched modes.json. Locked options can't be customized, so they never
-- appear here. Only the selector key is always omitted (the command carries it).
function ModeResolver.DeviationsFromMode(resolved, defs, mode, category)
	local params = {}
	if not (resolved and defs) then return params end

	local selectorKey = category .. "_mode"
	-- Baseline = the mode's preset effective values WITHOUT user deviations, i.e.
	-- exactly what Resolve(...) would return with no deviations. Run every value
	-- through the same toVal as `resolved` so the comparison is string-clean.
	local governed = governedSections(defs, category)
	local baseline = {}
	for i = 1, #defs do
		local o = defs[i]
		if governed[o.section] and o.key and o.key ~= selectorKey
				and o.type ~= "subheader" and o.type ~= "separator" and o.def ~= nil then
			baseline[o.key] = toVal(o.def)
		end
	end
	local modeOptions = mode and mode.modOptions
	if modeOptions then
		for k, rule in pairs(modeOptions) do
			if k ~= selectorKey and rule.value ~= nil then baseline[k] = toVal(rule.value) end
		end
	end

	for k, v in pairs(resolved) do
		if k ~= selectorKey and baseline[k] ~= v then params[k] = v end
	end
	return params
end

return ModeResolver
