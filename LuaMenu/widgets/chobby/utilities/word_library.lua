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

-- Section 2: 'Creative' mis-spellings and phrases
	"1488", -- [1488]Thrump and [Azov]Bandera1488 (14 words, 88 = HH = Heil Hilter)
	"analbeads", -- analbeadsunt
	"bigdick", -- bigdickrick, THEBIGDICKBANDIT
	"BigDik", -- BigDikVonQueefer
	"BigDingDong", -- BigDingDong95
	"C0ck", -- C0ckSlayer95
	"H17L3R", -- [d604]K1llH17L3R, [G604]K1llH17L3R, K1llH17L3R
	"negger", -- xXNEGGERHADERXx
	"niggeer", -- niggeerwarrior
	"nigguer", -- ISMELLNIGGUER
	"nijjer", -- nijjerphaggot
	"nikker", -- nikkerjew
	"phaggot", -- nijjerphaggot
	"SisterFister", -- ListerDaSisterFister
	"SmallDick", -- SmallDickBigBrain
	"zalupa", -- [zalupa2]vtlkru (zalupa apparently meaning dickhead in Russian)
	"[KYS]", -- [KYS]HugeGuy

-- Section 3: previously moderated usernames (beginning of time through 2024/1/15)
	"AbuseYoungBoys", -- AbuseYoungBoys123
	"Bambusneger", -- (translated: "Bamboo negro")
	"BanAllRussians",
	"Ban_Russians",
	"BigNickDigger",
	"BlacksVsTeens",
	"CoonHunter",
	"coonhunting",
	"DebilPL", -- (translated: 'moron PL/Poland'
	"dickassman",
	"diggernick",
	"ErikVonManstein", -- (was a nazi apparently)
	"fagmuffin",
	"FatKidsLagIRL",
	"fatqueefclit",
	"F_A_T_C_O_C_K",
	"Gay_killer",
	"GEORGfloydcantbreath", -- (keep politics out of BAR)
	"GreaterIsrael",
	"Himenhamburglar",
	"HomoFaggins",
	"Hugh_G_Rection",
	"Hymenhamburglar",
	"imurderamericans",
	"IrishInbreeding",
	"ISISRecruiter",
	"KikeKiller",
	"KillNazis", -- (see https://discord.com/channels/549281623154229250/774771372579880980/1097122276786319481)
	"kill_nigers",
	"kkk",
	"kuroNIGHER",
	"madarchode", -- (translated: motherfucker)
	"MohammedwasLGBTQ",
	"MrEnWord",
	"Muschiduft", -- (translated: Pussysmell)
	"NateHiggers",
	"Necrosexual",
	"ni999er",
	"NIBBERSLAYER",
	"NickGhur",
	"NIG3R",
	"nigerfrombehind",
	"Nigg",
	"nignog",
	"Nigward",
	"nig_ger",
	"Nikher",
	"NilleachKigger",
	"NillKigger", -- (also renamed to "NillKiggerPls")
	"nlackbigger",
	"NuckFiggers",
	"NupidStigger",
	"NWord", -- TheNWord
	"N_igger",
	"N_WORD", -- N_WORDS_IN_PARIS
	"ObamerTheRacistObama",
	"onlytalk2whites",
	"P3dospid3r",
	"phatdik",
	"Prigozhin",
	"rapeepat",
	"rasha_parasha", -- (translated: 'Russia shithole')
	"reformthe3rdreich",
	"RunGayRun",
	"Schnaebichaetscher", -- (translated: Cocksucker)
	"SchoolShootingsAreOK",
	"sligghernayer", -- (spoonerism of niggherslayer)
	"Slvtcrvsher", -- (gawlix of 'slut crusher')
	"SmoakMyBenis",
	"SpitOnWomen",
	"TheFinalJew",
	"THeThirdReich",
	"The_3rd_Reich",
	"Totenkopfverband", -- (pro-nazi name)
	"Twateifion", -- Twateifion666
	"UnInstallLyf", -- [DSM]UnInstallLyf
	"Vaginafucker",
	"warcrimeenjoyer", -- warcrimeenjoyer9999
	"Womanbeater",
	"yolocaust", -- yolocaust420
	"ZOV_EBAT_AZOV", -- ('zov' is associated with the Russian military, 'ebat' is 'fuck' in Russian, and 'azov' is associated with the Ukranian military)
}

do
	for index, word in ipairs(Word_Library.blacklisted_plain_strings) do
		word = string.lower(word)
		word = string.gsub(word, "([^%w])", "%%%1") -- Adds a '%' escape character before each non-alphanumeric character
		Word_Library.blacklisted_plain_strings[index] = word
	end
end
