Word_Library = Word_Library or {}

-- Returns a blacklisted string from the word library contained within the provided 'searchStr'.
-- If 'searchStr' does not contain any blacklisted strings, nil is returned instead.
-- The search is case-insensitive.
function Word_Library.FindBlacklistedString(searchStr)
	local lowerStr = string.lower(searchStr)
	for index, badStr in ipairs(Word_Library.blacklisted_plain_strings) do
		if string.match(lowerStr, badStr) then
			return string.gsub(badStr, "%%", "") -- Remove any escape characters before returning.
		end
	end
	return nil
end

-- A list of plain strings (not patterns) that are considered bad.
-- Some postprocessing is performed on entries to allow for easier data entry; all strings are converted to lowercase and any special characters are escaped.

-- Examples:
-- "badword"
-- "[bad]user_name"
-- "[bAd]uSeR_nAmE"
Word_Library.blacklisted_plain_strings = {
-- Section 1: generic unwanted words
	"fuck",
	"cunt",
	"shit",
	"cock",
	"faggot",
	"adolf",
	"hitler",
	"nigger",
	"coochie", -- CoochieStretcher
	"gooch", -- Gooch_Snorkler
	"jigaboo", -- GangBangerJigaboo
	"molester", -- AdvancedMolester
	"molestor", -- ginge_the_molestor
	"pussy", -- Pussylover69 and XxPussySlayerXx
	"retard", -- fatretardgaming
	"semen", -- Semen_ and semen_swallow
	"hymen", -- Hymenhamburglar
	"kike", -- KikeKiller

-- Section 2: 'Creative' mis-spellings and phrases
	"1488", -- [1488]Thrump and [Azov]Bandera1488 (14 words, 88 = HH = Heil Hilter)
	"bigdick", -- bigdickrick, THEBIGDICKBANDIT
	"BigDik", -- BigDikVonQueefer
	"C0ck", -- C0ckSlayer95
	"H17L3R", -- [d604]K1llH17L3R, [G604]K1llH17L3R, K1llH17L3R
	"negger", -- xXNEGGERHADERXx
	"ni99er",
	"NIBBER", -- NIBBERSLAYER
	"NIG3R",
	"nigg", -- niggeerwarrior, ISMELLNIGGUER, Nigg
	"nijjer", -- nijjerphaggot
	"Nikher",
	"nikker", -- nikkerjew
	"phaggot", -- nijjerphaggot
	"zalupa", -- [zalupa2]vtlkru (zalupa apparently meaning dickhead in Russian)
}

do
	for index, word in ipairs(Word_Library.blacklisted_plain_strings) do
		word = string.lower(word)
		word = string.gsub(word, "([^%w])", "%%%1") -- Adds a '%' escape character before each non-alphanumeric character
		Word_Library.blacklisted_plain_strings[index] = word
	end
end
