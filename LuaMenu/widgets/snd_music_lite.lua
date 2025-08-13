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

Spring.CreateDir("music/custom/loading")
Spring.CreateDir("music/custom/peace")
Spring.CreateDir("music/custom/warlow")
Spring.CreateDir("music/custom/warhigh")
Spring.CreateDir("music/custom/war")
Spring.CreateDir("music/custom/interludes")
Spring.CreateDir("music/custom/bossfight")
Spring.CreateDir("music/custom/gameover")
Spring.CreateDir("music/custom/menu")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local playingTrack	-- boolean
local previousTrack
local previousTrackType = "intro" -- intro or peace
local loopTrack	-- string trackPath
local randomTrackList
local openTrack
local introTracksIndex = 0
local peaceTracksIndex = 0

local musicDirOriginal 			= 'luamenu/configs/gameconfig/byar/lobbyMusic/original'
local musicDirEventAprilFools 	= 'luamenu/configs/gameconfig/byar/lobbyMusic/event/aprilfools'
local musicDirEventXmas 		= 'luamenu/configs/gameconfig/byar/lobbyMusic/event/xmas'
local musicDirCustom 			= 'music/custom/menu'
local musicDirCustom2 			= 'music/custom/peace'

local allowedExtensions = "{*.ogg,*.mp3}"

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
	playlistBuild()
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

function playlistBuild()
	math.randomseed( math.ceil(os.clock()*1000000) )
	math.random(); math.random(); math.random()
	Spring.Echo("RANDOMSEED", math.ceil(os.clock()*1000000))

	randomTrackList = {}

	-- Original Soundtrack List
	if Spring.GetConfigInt('UseSoundtrackNew', 1) == 1 then
		customIntroTrack = "luamenu/configs/gameConfig/byar/lobbyMusic/original/matteo dell'acqua - foobar (intro).ogg"
		randomTrackList = playlistMerge(randomTrackList, VFS.DirList(musicDirOriginal, allowedExtensions))

		-- April Fools
		if Spring.GetConfigInt('UseSoundtrackAprilFools', 1) == 1 and (tonumber(os.date("%m")) == 4 and tonumber(os.date("%d")) <= 7) then
			randomTrackList = playlistMerge(randomTrackList, VFS.DirList(musicDirEventAprilFools, allowedExtensions))
		end
		if Spring.GetConfigInt('UseSoundtrackAprilFoolsPostEvent', 0) == 1 and (not (tonumber(os.date("%m")) == 4 and tonumber(os.date("%d")) <= 7)) then
			randomTrackList = playlistMerge(randomTrackList, VFS.DirList(musicDirEventAprilFools, allowedExtensions))
		end

		-- Xmas
		if (tonumber(os.date("%m")) == 12 and tonumber(os.date("%d")) >= 12) then
			randomTrackList = playlistMerge(randomTrackList, VFS.DirList(musicDirEventXmas, allowedExtensions))
			customIntroTrack = VFS.DirList(musicDirEventXmas, allowedExtensions)[math.random(1,#VFS.DirList(musicDirEventXmas, allowedExtensions))]
		end
	end

	-- Custom Soundtrack List
	if Spring.GetConfigInt('UseSoundtrackCustom', 1) == 1 then
		randomTrackList = playlistMerge(randomTrackList, VFS.DirList(musicDirCustom, allowedExtensions))
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
	
	--[[
	Spring.Echo("Intro Tracks")
	for _, file in pairs(introTrackList) do
		Spring.Echo(file)
	end

	Spring.Echo("Peace/Filler Tracks")
	for _, file in pairs(peaceTrackList) do
		Spring.Echo(file)
	end
	]]

	for i = 1,1000 do
		if customIntroTrack then
			openTrack = customIntroTrack
			break
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
		if openTrack then
			break
		end
	end
end

function widget:Initialize()
	playlistBuild()

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
