ChatEmojis = {}

ChatEmojis.imageDir = (LUA_DIRNAME or "LuaMenu/") .. "images/emojis/twemoji/"
ChatEmojis.customImageDir = (LUA_DIRNAME or "LuaMenu/") .. "images/emojis/custom/"

ChatEmojis.aliasData = {
	angry = { unicode = "\240\159\152\160", image = "angry.png" },
	clap = { unicode = "\240\159\145\143", image = "clap.png" },
	confused = { unicode = "\240\159\152\149", image = "confused.png" },
	cookie = { unicode = "\240\159\141\170", image = "cookie.png", custom = true },
	cool = { unicode = "\240\159\152\142", image = "cool.png" },
	cry = { unicode = "\240\159\152\162", image = "cry.png" },
	fire = { unicode = "\240\159\148\165", image = "fire.png" },
	gg = { unicode = "\240\159\164\157", image = "gg.png" },
	grin = { unicode = "\240\159\152\129", image = "grin.png" },
	heart = { unicode = "\226\157\164\239\184\143", image = "heart.png" },
	joy = { unicode = "\240\159\152\130", image = "joy.png" },
	laughing = { unicode = "\240\159\152\134", image = "laughing.png" },
	lol = { unicode = "\240\159\152\130", image = "lol.png" },
	ok_hand = { unicode = "\240\159\145\140", image = "ok_hand.png" },
	party = { unicode = "\240\159\165\179", image = "party.png" },
	pleading = { unicode = "\240\159\165\186", image = "pleading.png" },
	pray = { unicode = "\240\159\153\143", image = "praying.png" },
	rofl = { unicode = "\240\159\164\163", image = "rofl.png" },
	sad = { unicode = "\240\159\152\162", image = "sad.png" },
	salute = { unicode = "\240\159\171\161", image = "salute.png" },
	shrug = { unicode = "\240\159\164\183", image = "shrug.png" },
	slight_smile = { unicode = "\240\159\153\130", image = "slight_smile.png" },
	smile = { unicode = "\240\159\152\132", image = "smile.png" },
	smiley = { unicode = "\240\159\152\131", image = "smiley.png" },
	sob = { unicode = "\240\159\152\173", image = "sob.png" },
	skull = { unicode = "\240\159\146\128", image = "skull.png" },
	thinking = { unicode = "\240\159\164\148", image = "thinking.png" },
	thumbsdown = { unicode = "\240\159\145\142", image = "thumbsdown.png" },
	thumbsup = { unicode = "\240\159\145\141", image = "thumbsup.png" },
	tada = { unicode = "\240\159\142\137", image = "tada.png" },
	wave = { unicode = "\240\159\145\139", image = "wave.png" },
	wink = { unicode = "\240\159\152\137", image = "wink.png" },
}

ChatEmojis.aliases = {}
for alias, data in pairs(ChatEmojis.aliasData) do
	ChatEmojis.aliases[alias] = data.unicode
end

ChatEmojis.sortedAliases = {}
for alias in pairs(ChatEmojis.aliases) do
	ChatEmojis.sortedAliases[#ChatEmojis.sortedAliases + 1] = alias
end
table.sort(ChatEmojis.sortedAliases)

function ChatEmojis.GetImageFile(alias)
	local data = ChatEmojis.aliasData[alias]
	if not (data and data.image) then
		return
	end
	return (data.custom and ChatEmojis.customImageDir or ChatEmojis.imageDir) .. data.image
end

function ChatEmojis.GetDisplayEntries()
	local entries = {}
	for i = 1, #ChatEmojis.sortedAliases do
		local alias = ChatEmojis.sortedAliases[i]
		entries[#entries + 1] = {
			alias = alias,
			emoji = ChatEmojis.aliases[alias],
			image = ChatEmojis.GetImageFile(alias),
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
