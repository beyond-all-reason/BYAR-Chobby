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

-- Section 2: 'Creative' mis-spellings and phrases

-- Section 3: previously moderated usernames
}

do
	for index, word in ipairs(Word_Library.blacklisted_plain_strings) do
		word = string.lower(word)
		word = string.gsub(word, "([^%w])", "%%%1") -- Adds a '%' escape character before each non-alphanumeric character
		Word_Library.blacklisted_plain_strings[index] = word
	end
end
