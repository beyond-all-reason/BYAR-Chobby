--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name	= "Music Player Lite",
		desc	= "Plays music for ingame lobby client",
		author	= "GoogleFrog and KingRaptor",
		date	= "25 September 2016",
		license	= "GNU GPL, v2 or later",
		layer	= 2000,
		enabled	= true	--	loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local playingTrack	-- boolean
local previousTrack
local previousTrackType = "intro" -- intro or peace
local loopTrack	-- string trackPath
local randomTrackList
local openTrack
local playedTracks = {}
local introTracksIndex = 0
local peaceTracksIndex = 0

local eventType = "none"
local eventTrackPlayed = false

local easterEggCountdown = Spring.GetConfigInt('ChobbyLaunchesCount', 0) + 1 -- Don't play easter egg intro song for first few launches to not make weird first impression
Spring.SetConfigInt('ChobbyLaunchesCount', easterEggCountdown)

local function GetRandomTrack(previousTrack)
	-- randomTrackList
	-- introTrackList
	-- peaceTrackList
	local nextTrack
	local trackType
	for i = 1, #randomTrackList do
		if (previousTrackType == "intro" or (not introTrackList[1])) and peaceTrackList[1] then -- we're checking if there are any peace tracks
			trackType = "peace"
			peaceTracksIndex = peaceTracksIndex + 1
			if not peaceTrackList[peaceTracksIndex] then
				peaceTracksIndex = 1
			end
			nextTrack = peaceTrackList[peaceTracksIndex]
		elseif (previousTrackType == "peace" or (not peaceTrackList[1])) and introTrackList[1] then -- we're checking if there are any intro tracks
			trackType = "intro"
			introTracksIndex = introTracksIndex + 1
			if not introTrackList[introTracksIndex] then
				introTracksIndex = 1
			end
			nextTrack = introTrackList[introTracksIndex]
		end

		if nextTrack and trackType then
			previousTrackType = trackType
			return nextTrack
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function StartTrack(trackName)
	trackName = trackName or GetRandomTrack(previousTrack)
	local volume = WG.Chobby.Configuration.menuMusicVolume
	Spring.Echo("Starting Track", trackName, volume)
	if volume == 0 then
		return
	end
	Spring.StopSoundStream()
	Spring.PlaySoundStream(trackName, 1)
	Spring.SetSoundStreamVolume(volume)
	playingTrack = true
end

local function LoopTrack(trackName, trackNameIntro)
	trackNameIntro = trackNameIntro or trackName
	loopTrack = trackName
	StartTrack(trackNameIntro)
end

local function StopTrack()
	Spring.StopSoundStream()
	playingTrack = false
	loopTrack = nil
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function SetTrackVolume()
	local volume = WG.Chobby.Configuration.menuMusicVolume
	if volume == 0 then
		StopTrack()
		return
	end
	if playingTrack then
		Spring.SetSoundStreamVolume(volume)
		return
	end
	StartTrack(GetRandomTrack())
	previousTrack = nil
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local firstActivation = true
local ingame = false

function widget:Update()

	if ingame or (WG.Chobby.Configuration.menuMusicVolume == 0 )then
		return
	end

	if not playingTrack then
		return
	end

	local playedTime, totalTime = Spring.GetSoundStreamTime()
	playedTime = math.floor(playedTime)
	totalTime = math.floor(totalTime)

	if (playedTime >= totalTime) then
		local newTrack = loopTrack or GetRandomTrack(previousTrack)
		StartTrack(newTrack)
		previousTrack = newTrack
	end
end

local MusicHandler = {
	StartTrack = StartTrack,
	StopTrack = StopTrack,
	LoopTrack = LoopTrack
}

-- Called just before the game loads
-- This could be used to implement music in the loadscreen
--function widget:GamePreload()
--	-- Ingame, no longer any of our business
--	if Spring.GetGameName() ~= "" then
--		ingame = true
--		StopTrack()
--	end
--end

-- called when returning to menu from a game
function widget:ActivateMenu()
	ingame = false
	if firstActivation then
		StartTrack(openTrack)
		previousTrack = openTrack
		firstActivation = false
		return
	end
	-- start playing music again
	local newTrack = GetRandomTrack(previousTrack)
	StartTrack(newTrack)
	previousTrack = newTrack
end


function playlistMerge(t1, t2)
	for k,v in ipairs(t2) do
	   table.insert(t1, v)
	end 
	return t1
end

function tableshuffle(sequence, firstIndex) -- doesn't seem like Chobby has common functions, so i'll put this here
	firstIndex = firstIndex or 1
	for i = firstIndex, #sequence - 2 + firstIndex do
		local j = math.random(i, #sequence)
		sequence[i], sequence[j] = sequence[j], sequence[i]
	end
end

function widget:Initialize()

	math.randomseed( math.ceil(os.clock()*1000000) )
	math.random(); math.random(); math.random()
	Spring.Echo("RANDOMSEED", math.ceil(os.clock()*1000000))

	randomTrackList = {}
	booxmboxTrackList = {}
	local originalSoundtrackEnabled = Spring.GetConfigInt('UseSoundtrackNew', 1)
	local customSoundtrackEnabled	= Spring.GetConfigInt('UseSoundtrackCustom', 1)
	local allowedExtensions = "{*.ogg,*.mp3}"

	-- Original Soundtrack List
	if originalSoundtrackEnabled == 1 then
		local musicDirOriginal 		= 'luamenu/configs/gameconfig/byar/lobbyMusic/original'
		randomTrackList = playlistMerge(randomTrackList, VFS.DirList(musicDirOriginal, allowedExtensions))
	end
	if true then
		local musicDirEventBoombox = 'luamenu/configs/gameconfig/byar/lobbyMusic/event/boombox'
		booxmboxTrackList = VFS.DirList(musicDirEventBoombox, allowedExtensions)
	end

	-- Custom Soundtrack List
	if customSoundtrackEnabled == 1 then
		local musicDirCustom 		= 'music/custom/menu'
		randomTrackList = playlistMerge(randomTrackList, VFS.DirList(musicDirCustom, allowedExtensions))
		local musicDirCustom2 		= 'music/custom/peace'
		randomTrackList = playlistMerge(randomTrackList, VFS.DirList(musicDirCustom2, allowedExtensions))
	end

	if randomTrackList == nil or #randomTrackList == 0 then
		Spring.Log("snd_music.lite.lua", LOG.NOTICE, "No random track list found, disabling lobby music")
		widgetHandler:RemoveWidget()
		return
	end

	-- put all intro tracks in separate list
	introTrackList = {}
	peaceTrackList = {}
	for index, file in pairs(randomTrackList) do
		local trackTest = file
		if string.find(trackTest, "(intro)") or string.find(trackTest, "(INTRO)") then
			introTrackList[#introTrackList+1] = trackTest
		else
			peaceTrackList[#peaceTrackList+1] = trackTest
		end
	end

	tableshuffle(introTrackList)
	tableshuffle(peaceTrackList)

	Spring.Echo("Intro Tracks")
	for _, file in pairs(introTrackList) do
		Spring.Echo(file)
	end

	Spring.Echo("Peace/Filler Tracks")
	for _, file in pairs(peaceTrackList) do
		Spring.Echo(file)
	end

	for i = 1,1000 do
		if Spring.GetConfigInt("boomboxcaptured", 0) == 1 then -- Play Beyond All Rhythm once on next launch after capturing a boombox
			openTrack = booxmboxTrackList[math.random(1,#booxmboxTrackList)]
			Spring.SetConfigInt("boomboxcaptured", 0)
		end
		if openTrack then
			break
		else
			openTrack = introTrackList[1]
			introTracksIndex = 1
		end
		if openTrack then
			break
		else
			openTrack = peaceTrackList[1]
			peaceTracksIndex = 1
		end
	end

	local Configuration = WG.Chobby.Configuration

	local function onConfigurationChange(listener, key, value)
		if key == "menuMusicVolume" then
			SetTrackVolume()
		end
	end
	Configuration:AddListener("OnConfigurationChange", onConfigurationChange)

	local function OnBattleAboutToStart()
		ingame = true
		StopTrack()
	end
	WG.LibLobby.localLobby:AddListener("OnBattleAboutToStart", OnBattleAboutToStart)
	WG.LibLobby.lobby:AddListener("OnBattleAboutToStart", OnBattleAboutToStart)

	WG.MusicHandler = MusicHandler
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
