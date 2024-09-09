local customProfiles = {
-- 	['BARb stable'] = {
-- 		{
-- 			key  = 'example',  -- must conform to directory name
-- 			name = 'Not so Hard',  -- human readable name displayed in a list
-- 			-- desc kept for consistency with AIOptions.lua
-- 			desc = 'Alas desc doesn\'t work - no way to display tooltip on a list item',
-- 		},
-- 	},
}

local blacklistProfiles = {
-- 	['BARb stable'] = {
-- 		dev = true,
-- 		hard = true,
-- 	},
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
	local customs = customProfiles[name]
	if customs then
		for _, v in ipairs(customs) do
			table.insert(items, v)
		end
	end
	local filter = blacklistProfiles[name]
	if filter then
		ArrayRemove(items, function(t, i, j) return not filter[t[i].key] end)
	end
end

return {
	CustomAiProfiles = CustomAiProfiles
}
