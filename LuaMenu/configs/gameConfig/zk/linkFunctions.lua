local function link_reportPlayer(accountID)
	return "https://zero-k.info/Users/ReportToAdmin/" .. accountID
end

local function link_userPage(accountID)
	return "https://zero-k.info/Users/Detail/" .. accountID
end

local function link_homePage()
	return "https://zero-k.info/"
end

local function link_replays()
	return "https://zero-k.info/Battles"
end

local function link_maps()
	return "https://zero-k.info/Maps"
end

local function link_particularMapPage(mapName)
	return "https://zero-k.info/Maps/DetailName?name=" .. mapName
end

return link_reportPlayer, link_userPage, link_homePage, link_replays, link_maps, link_particularMapPage
