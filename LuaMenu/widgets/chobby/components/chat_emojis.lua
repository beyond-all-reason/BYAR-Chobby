ChatEmojis = {}

ChatEmojis.aliases = {
	["+1"] = "\240\159\145\141",
	["-1"] = "\240\159\145\142",
	angry = "\240\159\152\160",
	clap = "\240\159\145\143",
	confused = "\240\159\152\149",
	cool = "\240\159\152\142",
	cry = "\240\159\152\162",
	fire = "\240\159\148\165",
	gg = "\240\159\164\157",
	grin = "\240\159\152\129",
	heart = "\226\157\164\239\184\143",
	joy = "\240\159\152\130",
	laughing = "\240\159\152\134",
	lol = "\240\159\152\130",
	ok_hand = "\240\159\145\140",
	party = "\240\159\165\179",
	pleading = "\240\159\165\186",
	rofl = "\240\159\164\163",
	sad = "\240\159\152\162",
	salute = "\240\159\171\161",
	shrug = "\240\159\164\183",
	slight_smile = "\240\159\153\130",
	smile = "\240\159\152\132",
	smiley = "\240\159\152\131",
	sob = "\240\159\152\173",
	thinking = "\240\159\164\148",
	thumbsdown = "\240\159\145\142",
	thumbsup = "\240\159\145\141",
	tada = "\240\159\142\137",
	wave = "\240\159\145\139",
	wink = "\240\159\152\137",
}

ChatEmojis.sortedAliases = {}
for alias in pairs(ChatEmojis.aliases) do
	ChatEmojis.sortedAliases[#ChatEmojis.sortedAliases + 1] = alias
end
table.sort(ChatEmojis.sortedAliases)

function ChatEmojis.GetDisplayEntries()
	local entries = {}
	for i = 1, #ChatEmojis.sortedAliases do
		local alias = ChatEmojis.sortedAliases[i]
		entries[#entries + 1] = {
			alias = alias,
			emoji = ChatEmojis.aliases[alias],
		}
	end
	return entries
end

function ChatEmojis.ReplaceAliases(text)
	if type(text) ~= "string" or not string.find(text, ":", 1, true) then
		return text
	end

	return (string.gsub(text, ":([%w_+%-]+):", function(alias)
		return ChatEmojis.aliases[alias] or (":" .. alias .. ":")
	end))
end

function ChatEmojis.GetCompletionSuffixes(prefix)
	local suffixes = {}
	if type(prefix) ~= "string" or string.sub(prefix, 1, 1) ~= ":" or string.find(prefix, ":", 2, true) then
		return suffixes
	end

	local aliasPrefix = string.sub(prefix, 2)
	if aliasPrefix == "" then
		return suffixes
	end

	for i = 1, #ChatEmojis.sortedAliases do
		local alias = ChatEmojis.sortedAliases[i]
		if string.sub(alias, 1, #aliasPrefix) == aliasPrefix then
			suffixes[#suffixes + 1] = string.sub(alias, #aliasPrefix + 1) .. ":"
		end
	end
	return suffixes
end
