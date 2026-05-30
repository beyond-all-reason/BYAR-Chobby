local customProfiles = {
	['BARb'] = {
		{
			key  = 'hard_aggressive',  -- must conform to directory name
			name = 'Hard | Aggressive',  -- human readable name displayed in a list
			desc = 'Difficulty: Hard | Playstyle: Aggressive | Made by Flaka, tweaked by Corosus',
		},
		{
			key  = 'hard',
			name = 'Hard | Balanced',
			desc = 'Difficulty: Hard |Playstyle: Balanced |Made by Flaka',
		},
		{
			key  = 'medium',
			name = 'Medium | Lazy',
			desc = 'Difficulty: Medium |Playstyle: Learning mechanics',
		},
		{
			key  = 'easy',
			name = 'Easy | Slow',
			desc = 'Difficulty: Easy |Playstyle: First launch',
		},
		{
			key  = 'dev',
			name = 'Testing AI',
			desc = 'Testing config',
		},
	},
}

local blacklistProfiles = {
	['BARb'] = {
		dev = true,
		hard = true,
		medium = true,
		easy = true,
	},
}

local function ArrayRemove(t, fnKeep)
	local j, n = 1, #t;

	for i=1,n do
		if (fnKeep(t, i, j)) then
			-- Move i's kept value to j's position, if it's not already there.
			if (i ~= j) then
				t[j] = t[i];
				t[i] = nil;
			end
			j = j + 1; -- Increment position of where we'll place the next kept value.
		else
			t[i] = nil;
		end
	end

	return t;
end

function CustomAiProfiles(name, items)
	local filter = blacklistProfiles[name]
	if filter then
		ArrayRemove(items, function(t, i, j) return not filter[t[i].key] end)
	end
	local customs = customProfiles[name]
	if customs then
		for _, v in ipairs(customs) do
			table.insert(items, v)
		end
	end
end

return {
	CustomAiProfiles = CustomAiProfiles
}
