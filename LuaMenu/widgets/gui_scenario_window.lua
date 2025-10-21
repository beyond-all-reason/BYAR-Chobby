--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Scenario window",
		desc      = "Handles Scenarios",
		author    = "Beherith",
		date      = "2021 Feb.",
		license   = "GNU LGPL, v2.1 or later",
		layer     = -10000,
		enabled   = true  --  loaded by default?
	}
end

-- TODO:
	-- gameside checking
	-- make nice dgun scenario
	-- push


-- Local Variables
local reloadcount = 0
local scenarioWindow
local scenarios
local scenariosorter
local scenarioSelectorCombo
local scenarioScrollPanel
local scenarioPanel
local scenarioSelectorPanel
local currentscenario
local mybonus = 0
local alreadyDownloaded = false
local barversion = nil
local myside = nil
local mydifficulty = {name = "Normal", playerhandicap = 100, enemyhandicap = 100}
local myscores = {time = 0, resources = 0}
local myside = nil

local lastScenarioID
local lastScenarioVersion
local lastDifficulty
local lastTime
local lastResources
local scoreLabels = {}
local scoreData = {} -- a table, with keys being scenario uniqueIDs, e.g.:
--[[
{ supcrossingvsbarbs001 = {
	"1.0" = {
		"Easy" = {
			time = 10000,
			resources = 10000,
		}
	}
	}
}
--]]
local unitdefname_to_humanname = {} -- from en.lua, attached at the end of the file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utilities

--- Format a number of seconds as a time string.
-- The formatting differs depending on whether the duration is at least one hour.
-- If there is a full hour: `h:mm:ss` and otherwise: `m:ss`
-- Example outputs:
-- - 10: `0:10`
-- - 60: `1:00`
-- - 3599: `59:59`
-- - 7280: `2:01:20`
local function SecondsToTimeString(s)
	local hours = math.floor(s/3600)
	s = math.fmod(s, 3600 )
	local minutes = math.floor(s/60)
	s = math.fmod(s,60)

	if hours>0 then
		return string.format("%d:%02d:%02d",hours,minutes,s)
	else
		return string.format("%d:%02d",minutes,s)
	end
end

local function MaybeDownloadMap(mapName)
	Spring.Echo("Scenario:", "Downloading map", mapName)

	WG.DownloadHandler.MaybeDownloadArchive(mapName, "map", -1)
end

local function ShortenGameName(gameName)
	gameName = gameName:gsub("Beyond All Reason","BAR")
	gameName = gameName:gsub("test","")
	if gameName:find("-[^-]*$") then
	  gameName = gameName:sub(1, gameName:find("-[^-]*$") -1 )
	end
	return gameName
end

local function DownloadRequirements()
	local config = WG.Chobby.Configuration
	local gameName = config:GetDefaultGameName()
	barversion = gameName
	--barversion = "Beyond All Reason $VERSION" --TESTING ONLY
	if gameName ~= nil and not alreadyDownloaded then
		Spring.Echo("Scenario:", "Downloading game", gameName)
		WG.DownloadHandler.MaybeDownloadArchive(gameName, "game", 1)
		alreadyDownloaded = true
	end
end

local function ShortenEngineName(engineName)
	if engineName:find("-[^-]*$") then
		engineName = engineName:sub(1, engineName:find("-[^-]*$") -1)
	end
	return engineName
end

local function ternary(condition, T, F)
	if condition then return T else return F end
end


local function LoadScenarios()
	local dummyVar = 'temp'	-- delete this any time
    scenarios = {}
    local files = VFS.DirList("LuaMenu/configs/gameConfig/byar/scenarios/")
    for i = 1, #files do
        if string.find(files[i], ".lua") and string.find(files[i], "scenario") then
            local success, error = pcall ( function()
                local newscen = VFS.Include(files[i])
                scenarios[#scenarios+1] = newscen
            end)

            if not success then
                Spring.Echo("Error: loading scenario ",files[i], error)
                newscen = {title = "Error " ..files[i] ,
                            scenarioid = "failed to load",
                            index = -1,
                            difficulty = -1,
                            mapfilename = "",
                            error = files[i] .. '\n' .. error,
                }
                scenarios[#scenarios+1] = newscen
            end
        end
    end

    local function SortFunc(a,b)
        return a.difficulty < b.difficulty
    end

    table.sort(scenarios, SortFunc )
end

local function EncodeScenarioOptions(scenario)
	scenario.scenariooptions.version = scenario.version
	scenario.scenariooptions.scenarioid = scenario.scenarioid
	scenario.scenariooptions.difficulty = mydifficulty.name
	return Spring.Utilities.Base64Encode(Json.encode(scenario.scenariooptions))
end

local function GetBestScores(scenarioID,scenarioVersion,difficulty)
	--Spring.Echo("GetBestScores",scenarioID,scenarioVersion,difficulty)
	if scoreData[scenarioID] 
	and	scoreData[scenarioID][scenarioVersion] 
	and	scoreData[scenarioID][scenarioVersion][difficulty] then
		Spring.Echo(scoreData[scenarioID][scenarioVersion][difficulty])
		return scoreData[scenarioID][scenarioVersion][difficulty]
	else
		return nil
	end
end

local function RefreshScores(scenarioID,scenarioVersion,difficulty)
	Spring.Echo("Scenario Window RefreshScores")
	myscores = GetBestScores(scenarioID,scenarioVersion,difficulty)
	if myscores == nil then
		myscores = {time = "0", resources = "0"}
	end
	
	if scoreLabels[scenarioID] 
	and scoreLabels[scenarioID][scenarioVersion] 
	and scoreLabels[scenarioID][scenarioVersion][difficulty] then
		local labels = scoreLabels[scenarioID][scenarioVersion][difficulty]
		labels.time:SetCaption(SecondsToTimeString(myscores.time))
		labels.resources:SetCaption(string.format("%.2fK metal", myscores.resources / 1000.0))
	end
end

local function SetScore(scenarioID,scenarioVersion,difficulty,time,resources,gamewon)

	Spring.Echo("Scenario Window SetScore",scenarioID,scenarioVersion,difficulty,time,resources,gamewon)
	if scoreData[scenarioID] == nil then
		scoreData[scenarioID] = {}
	end
	if scoreData[scenarioID][scenarioVersion] == nil then
		scoreData[scenarioID][scenarioVersion] = {}
	end
	if scoreData[scenarioID][scenarioVersion][difficulty] == nil then
		scoreData[scenarioID][scenarioVersion][difficulty] = {}
	end
	if gamewon then
		local sd = scoreData[scenarioID][scenarioVersion][difficulty]
		if sd.time == nil or (time < sd.time) then sd.time = time end
		if sd.resources == nil or (resources < sd.resources) then sd.resources = resources end
		scoreData[scenarioID][scenarioVersion][difficulty] = sd
	end
end

--------------------------------------------------------------------------------
-- GUI


local function CreateScenarioPanel(shortname, sPanel)
	local Configuration = WG.Chobby.Configuration


	sPanel:ClearChildren()

	local scen = scenarios[1]
	for i, s in pairs(scenarios) do
		if shortname == s.title then
			scen = s
		end
	end
	
	MaybeDownloadMap(scen.mapfilename)

	local difficulties = {}
	local defaultdifficultyindex = 1
	for i,diff in pairs(scen.difficulties) do
		difficulties[#difficulties + 1] = diff.name
		if diff.name == scen.defaultdifficulty then
			defaultdifficultyindex = i
			mydifficulty = diff
		end
	end

	RefreshScores(scen.scenarioid, scen.version, mydifficulty.name)
	myside = (scen.allowedsides and scen.allowedsides[1]) or "Armada"


	local titletext = Label:New{
		x = 0,
		y = 0,
		width = "50%",
		height = "5%",
		parent = sPanel,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		caption = scen.title,
	}

	local summarySP = ScrollPanel:New {
		x = 0,
		y = "5%",
		width = "51%",
		height = "14%",
		parent = sPanel,
		horizontalScrollbar = true,
	}

	local summarytext = scen.summary
	local additionalText = "\nUnit Limits:"
	local numdisabledunits = 0
	if scen.unitlimits then
		for unitid, count in pairs(scen.unitlimits) do
			local humanName = unitdefname_to_humanname[unitid]
			if not humanName then
				Spring.Log("gui_scenario_window", LOG.ERROR, "Error No human name for: " .. unitid)
				humanName = "human name missing"
			end
	
			additionalText = additionalText .. "\n  - " .. humanName .. " (" .. unitid .. "): "
	
			if count == 0 then
				additionalText = additionalText .. "Disabled"
			else
				additionalText = additionalText .. tostring(count)
			end
	
			numdisabledunits = numdisabledunits + 1
		end
	end
	if numdisabledunits > 0 then
		summarytext = summarytext .. additionalText
	end

	local summarytextbox = TextBox:New {
		x = 0,
		y = 0,
		width = "100%",
		height = "100%",
		valign = 'top',
		objectOverrideFont = WG.Chobby.Configuration:GetFont(9),
		objectOverrideHintFont = WG.Chobby.Configuration:GetFont(9),
		text = summarytext,
		parent = summarySP,
		padding = {10,10,10,10},
	}

	local lblvictoryText = Label:New{
		x = 0,
		y = "20%",
		width = "50%",
		height = "5%",
		parent = sPanel,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2, "scn_label", {font = "fonts/n019003l.pfb", color = {0.7, 0.7, 0.7, 1.0}}),
		caption = "Victory",
	}

	local victoryText = Label:New{
		x = "16%",
		y = "20%",
		width = "50%",
		height = "5%",
		parent = sPanel,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(9),
		caption = scen.victorycondition,
	}

	local lbllossText = Label:New{
		x = 0,
		y = "24%",
		width = "50%",
		height = "5%",
		parent = sPanel,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2, "scn_label"),
		caption = "Loss" ,
	}

	local lossText = Label:New{
		x = "16%",
		y = "24%",
		width = "50%",
		height = "5%",
		parent = sPanel,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(9),
		caption = scen.losscondition,
	}

	local lbldifficultyText = Label:New{
		x = 0,
		y = "28%",
		width = "50%",
		height = "5%",
		parent = sPanel,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2, "scn_label"),
		caption = "Difficulty",
	}

	local difficultyText = Label:New{
		x = "16%",
		y = "28%",
		width = "50%",
		height = "5%",
		parent = sPanel,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		caption = tostring(math.floor(scen.difficulty)) .. "/15",
	}

	local lblpartimeText = Label:New{
		x = 0,
		y = "32%",
		width = "50%",
		height = "5%",
		parent = sPanel,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2, "scn_label"),
		caption = "Est. Time",
	}

	local partimeText = Label:New{
		x = "16%",
		y = "32%",
		width = "50%",
		height = "5%",
		parent = sPanel,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(9),
		caption = tostring(math.ceil(scen.partime/60)) .. " minutes",
	}

	local lblparresourcesText = Label:New{
		x = 0,
		y = "36%",
		width = "50%",
		height = "5%",
		parent = sPanel,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2, "scn_label"),
		caption = "Est. Resources" ,
	}

	local parresourcesText = Label:New{
		x = "16%",
		y = "36%",
		width = "50%",
		height = "5%",
		parent = sPanel,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(9),
		caption =  tostring(math.ceil(scen.parresources/1000)) .. "K metal",
	}


	---------------------------------

	local mapImage = Image:New {
		y = "0%",
		right = "0%",
		height = "47%",
		width = "47%",
		keepAspect = true,
		file =Configuration:GetMinimapImage(scen.mapfilename),
		parent = sPanel,
		tooltip = scen.mapfilename,
		padding = {0,0,0,0},
	}

	local commstartimg = Image:New { --LuaMenu/images/ranks/player.png
		x = scen.playerstartx,
		y = scen.playerstarty,
		width = "10%",
		height = "10%",
		keepAspect = true,
		file = "LuaMenu/images/ranks/player.png",
		parent = mapImage,
		tooltip = "You Start Here",
	}

	----------------------------------------------

	local flavorimage = Image:New {
		x = "0",
		y = "51%",
		width = "74%",
		height = "23%",
		keepAspect = false,
		crop = true,
		file = "LuaMenu/configs/gameConfig/byar/scenarios/" .. scen.imagepath,
		parent = sPanel,
		--tooltip = scen.mapfilename,
		padding = {10,10,10,10},
	}

	local flavortext = Label:New{
		x = "1.5%",
		bottom = "23%",
		width = "73%",
		height = "5%",
		parent = flavorimage,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(0),
		caption = scen.imageflavor,
	}

	----------------------

	local briefingtextSP = ScrollPanel:New {
		x = 0,
		y = "76%",
		width = "74%",
		bottom = 0,
		parent = sPanel,
		horizontalScrollbar = true,
		--padding = {10,10,10,10},
	}

	local briefingtext = TextBox:New {
		x = 0,
		y = 0,
		width = "100%",
		height = "100%",
		valign = 'top',
		objectOverrideFont = WG.Chobby.Configuration:GetFont(9),
		objectOverrideHintFont = WG.Chobby.Configuration:GetFont(9),
		text = scen.briefing,
		parent = briefingtextSP,

		padding = {10,10,10,10},
	}

	------------------------------------My Scores----------------------------
	local lblpersonal = Label:New{
		x = "76%",
		y = "67.5%",
		width = "20%",
		height = "5%",
		parent = sPanel,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		caption = "Personal Records",
	}

	local lbldifflevelpersonal = Label:New{
		x = "76%",
		y = "72.5%",
		width = "20%",
		height = "5%",
		parent = sPanel,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		caption = "Difficulty: "..tostring(mydifficulty.name),
	}

	local lblmytime = Label:New{
		x = "76%",
		y = "77.5%",
		width = "25%",
		height = "5%",
		parent = sPanel,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2, "scn_label"),
		caption = "My Best Time: ",
	}

	local mytime = Label:New{
		x = "76%",
		y = "80.5%",
		width = "25%",
		height = "5%",
		parent = sPanel,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		caption = SecondsToTimeString(myscores.time),
	}

	local lblmyresources = Label:New{
		x = "76%",
		y = "85%",
		width = "25%",
		height = "5%",
		parent = sPanel,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2, "scn_label"),
		caption = "My Resources: ",
	}

	local myresources = Label:New{
		x = "76%",
		y = "88%",
		width = "25%",
		height = "5%",
		parent = sPanel,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		caption = string.format( "%.2fK metal",myscores.resources/1000.0),
	}

	if scen.author then
		local lblauthor = Label:New{
			right = "1%",
			bottom = "1%",
			--width = "25%",
			--height = "5%",
			parent = sPanel,
			objectOverrideFont = WG.Chobby.Configuration:GetFont(2, "scn_label"),
			caption =  "Author: ".. scen.author,
		}
	end

	if math.floor(myscores.time) > 0 then
		local btnrating = Button:New {
			right = "0%",
			bottom = "4%",
			width = "24%",
			height = "4%",
			caption = "Submit Rating",
			classname = "option_button",
			objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
			tooltip = "Submit a rating to this scenario",
			OnClick = {
				function(obj)
					WG.IntegerSelectorWindow.CreateIntegerSelectorWindow({
						defaultValue = 5,
						minValue = 0,
						maxValue = 10,
						caption = "Rate this scenario",
						labelCaption = "How much did you enjoy this scenario?",
						OnAccepted = function(ratingvalue)
							if WG.Analytics and WG.Analytics.SendRepeatEvent then
								WG.Analytics.SendRepeatEvent("scenario:rating", {scenarioid = scen.scenarioid, rating = ratingvalue})
							end
						end
					})
				end
			},
			parent = sPanel,
		}
	end

    ------------------------------------------------------------------

	local sidelabel = Label:New{
		x = "0%",
		y = "40%" ,
		width = "100",
		height = "4%",
		parent = sPanel,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2, "scn_label"),
		caption = "Faction",
	}

	--[[
	local sidechangebutton  = Button:New {
		x = "25%",
		y = "50%" ,
		width = "100",
		height = "4%",
		caption = myside,
		classname = "option_button",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		tooltip = "Start the scenario",
		OnClick = {
			function(obj)
					Spring.Echo("Changing side:")
					WG.SideChangeWindow.CreateSideChangeWindow({
						initialSide = myside or 0,
						OnAccepted = function(sideId)
								local sidedata = Configuration:GetSideData()
								Spring.Echo("Chose side:",sideID,sidedata[sideID+1])
								myside = sidedata[sideID+1]
								obj:SetCaption(myside)
							end
					})
			end
		},
		parent = sPanel,
	}
	--]]

	local sideCombo = ComboBox:New{
		x = "16%",
		y = "40%" ,
		width = "33%",
		height = "4%",
		itemHeight = 22,
		valign = "center",
		align = "left",
		selectByName = true,
		--captionHorAlign = -32,
		text = "HasText",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		items = scen.allowedsides or {"Armada"}, --{"Coop", "Team", "1v1", "FFA", "Custom"},
		selected = 1,
		OnSelectName = {
			function (obj, selectedName)
					Spring.Echo("Faction selected:",selectedName)
					myside = selectedName
			end
		},
		parent = sPanel,
	}

	local difflabel = Label:New{
		x = "0%",
		y = "44%" ,
		width = "100",
		height = "4%",
		parent = sPanel,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2, "scn_label"),
		caption = "Difficulty",
	}

	local function UpdateDifficulty(newdifficultyname)
		for i, diff in pairs(scen.difficulties) do
			if diff.name == newdifficultyname then 
				mydifficulty = diff 
			end
		end

		lbldifflevelpersonal:SetCaption("Difficulty: "..tostring(mydifficulty.name))
		RefreshScores(scen.scenarioid, scen.version, mydifficulty.name)
	end

	local difficultCombo = ComboBox:New{
		x = "16%",
		y = "44%" ,
		width = "33%",
		height = "4%",
		itemHeight = 22,
		valign = "left",
		align = "left",
		selectByName = true,
		--captionHorAlign = -32,
		text = "HasText",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		items = difficulties, --{"Coop", "Team", "1v1", "FFA", "Custom"},
		selected = defaultdifficultyindex,
		OnSelectName = {
			function (obj, selectedName)
				Spring.Echo("Difficulty selected:",selectedName)
				UpdateDifficulty(selectedName,scenarioPanel)
			end
		},
		parent = sPanel,
	}

	local function SaveScoreLabels(scenarioID, scenarioVersion, difficulty)
		scoreLabels[scenarioID] = scoreLabels[scenarioID] or {}
		scoreLabels[scenarioID][scenarioVersion] = scoreLabels[scenarioID][scenarioVersion] or {}
		scoreLabels[scenarioID][scenarioVersion][difficulty] = scoreLabels[scenarioID][scenarioVersion][difficulty] or {}
		scoreLabels[scenarioID][scenarioVersion][difficulty] = {
			time = mytime,
			resources = myresources
		}
	end
	
	for _, diff in pairs(scen.difficulties) do
		SaveScoreLabels(scen.scenarioid, scen.version, diff.name)
	end

	local function createstartscript()
		local basescript = scen.startscript
		local numrestrictions = 0
		local restrictionstring = ''
		for unitid, count in pairs(scen.unitlimits) do
			restrictionstring = restrictionstring .. "Unit"..tostring(numrestrictions).."="..unitid..";\nLimit"..tostring(numrestrictions).."="..tostring(count)..";\n"
			numrestrictions = numrestrictions + 1
		end
		local myName = WG.Chobby.Configuration:GetPlayerName()
		basescript = basescript:gsub("__NUMRESTRICTIONS__",tostring(numrestrictions))
		basescript = basescript:gsub("__RESTRICTEDUNITS__",restrictionstring)
		basescript = basescript:gsub("__PLAYERNAME__",myName)

		for diffkey,diffvalue in pairs(mydifficulty) do
			if diffkey ~= "name" then
				basescript = basescript:gsub("__" .. string.upper(diffkey) .. "__", tostring(diffvalue))
			end

		end
		--basescript = basescript:gsub("__PLAYERHANDICAP__",tostring(mydifficulty.playerhandicap))
		--basescript = basescript:gsub("__ENEMYHANDICAP__",tostring(mydifficulty.enemyhandicap))
		basescript = basescript:gsub("__BARVERSION__",tostring(barversion))
		basescript = basescript:gsub("__MAPNAME__",tostring(scen.mapfilename))
		basescript = basescript:gsub("__PLAYERSIDE__",tostring(myside or scen.allowedsides[1]))
		basescript = basescript:gsub("__SCENARIOOPTIONS__",tostring(EncodeScenarioOptions(scen)))


		return basescript
	end

	local startmissionbutton = Button:New {
		x = "76%",
		y = "51%",
		right = 0,
		height = "7%",
		caption = "Start Scenario",
		classname = "ready_button",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		tooltip = "Start the scenario",
		OnClick = {
			function()
					local scriptTxt = createstartscript()
					Spring.Echo("Mission Ready")
					Spring.Echo(scriptTxt)
					if WG.Analytics and WG.Analytics.SendRepeatEvent then
						WG.Analytics.SendRepeatEvent("game_start:singleplayer:scenario_start", {scenarioid = scen.scenarioid, difficulty = mydifficulty.name})
					end

					if not VFS.HasArchive(barversion) then
						WG.Chobby.InformationPopup("You do not have the latest game version, check your downloads tab or update the game.", {caption = "OK"})
						return
					end

					if not VFS.HasArchive(scen.mapfilename) then
						WG.Chobby.InformationPopup("You do not have the map for this scenario, check your downloads tab to see the download progress.", {caption = "OK"})
						return
					end

					if WG and WG.Chobby and WG.Chobby.localLobby then 
						--Spring.Echo("Stop the music")
						WG.LibLobby.localLobby:StartGameFromString(scriptTxt, "scenario")
					else
						Spring.Reload(scriptTxt)
					end
			end
		},
		parent = sPanel,
	}

	startmissionbutton:SetEnabled(true)
	startmissionbutton:StyleReady()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Controls

local function MakeScenarioScrollPanelChildren()
	-- reloadcount = reloadcount + 1

	local Configuration = WG.Chobby.Configuration

	for i = #scenarioScrollPanel.children, 1, -1 do
		scenarioScrollPanel:RemoveChild(scenarioScrollPanel.children[i])
	end

	local spitemlist = {}
	for i, scen in ipairs(scenarios) do
		spitemlist[#spitemlist+1] = scen.title

		local mybestscore = nil
		local mybestdiff = nil
		local mybestrank = nil
		for j, diff in pairs(scen.difficulties or {}) do
			local s =  GetBestScores(scen.scenarioid, scen.version,diff.name)
			if s then
				mybestscore = s
				mybestdiff = diff.name
				mybestrank = j
			end
		end

		local scenorderindex = i
		local scenSelectorButton = Button:New {
			name = scen.scenarioid .. "button",
			x = "2%",
			y = 105 * (#spitemlist -1),
			right = "2%",
			height = 100,
			caption = "",
			classname = "battle_default_button",
			objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
			--objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
			--tooltip = "",
			OnClick = {
				function()
					if scen.error == nil then
						scenarioPanel:SetVisibility(true)
						scenarioSelectorPanel:SetVisibility(false)
						scenarioSelectorCombo:Select(scen.title)
						CreateScenarioPanel(scen.title,scenarioPanel)
						backbutton:SetVisibility(true)
						scenarioSelectorCombo:SetVisibility(true)
					end
				end
			},
			parent = scenarioScrollPanel,
		}
		if scen.error then
			local errormessage = TextBox:New{
				parent = scenSelectorButton,
				objectOverrideFont = WG.Chobby.Configuration:GetFont(1),
				objectOverrideHintFont = WG.Chobby.Configuration:GetFont(1),
				x = 0,
				y = 0,
				width = "100%",
				height = "100%",
				valign = 'top',
				text = scen.error,
			}
		else

			local spMinimapImg = Image:New {
				y = "1%",
				x = "1%",
				bottom = "1%",
				--width = "47%",
				keepAspect = true,
				file =Configuration:GetMinimapImage(scen.mapfilename),
				parent = scenSelectorButton,
				tooltip = scen.mapfilename,
				padding = {0,0,0,0},
			}

			local spTitleLbl = 	Label:New {
				x = 100,
				y = 10,
				width = 300,
				--height = 30,
				parent = scenSelectorButton,
				objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
				caption = string.format( "%03d. %s",i+reloadcount, scen.title ),
			}


			local spChallengeLbl = 	Label:New {
				right = "1%",
				y = 10,
				width = 100,
				--height = 30,
				parent = scenSelectorButton,
				objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
				caption = string.format( "Difficulty: % 2d/15",scen.difficulty ),
			}

			if scen.isnew then
				local spChallengeLbl = 	Label:New {
					right = "1%",
					bottom = 10,
					width = 100,
					--height = 30,
					parent = scenSelectorButton,
					objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
					caption = string.format( "New!"),
				}
			end



			if mybestdiff ~= nil then
				local spScoreRankImg = Image:New{
					y = "10%",
					x = "10%",
					bottom = "10%",
					right = "10%",
					keepAspect = true,
					file =Configuration.gameConfig.rankFunction(nil, mybestrank, nil, nil,nil ),
					parent = spMinimapImg,
					tooltip = scen.mapfilename,
					padding = {0,0,0,0},
				}

				local spMyScoreLbl = Label:New {
					x = 150,
					y = "60%",
					width = 500,
					--height = 30,
					parent = scenSelectorButton,
					objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
					caption = string.format( "Completed On: %s   Time: %s  Resources: %.2fK metal",mybestdiff, SecondsToTimeString(mybestscore.time), mybestscore.resources/1000.0 ),
				}
			else
				local spMyScoreLbl = Label:New {
					x = 150,
					y = "60%",
					width = 500,
					--height = 30,
					parent = scenSelectorButton,
					objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
					caption = "Not completed yet",
				}
			end
		end
		--[[local spMinimapImg = Image:New {
			y = "2%",
			x = "2%",
			bottom = "2%",
			--width = "47%",
			keepAspect = true,
			file =Configuration:GetMinimapImage(scen.mapfilename),
			parent = scenSelectorButton,
			tooltip = scen.mapfilename,
			padding = {0,0,0,0},
		}
		--]]
	end
end

local function InitializeControls(parentControl)
	local Configuration = WG.Chobby.Configuration

	DownloadRequirements()

	Label:New {
		x = 15,
		y = 14,
		width = 180,
		--height = 30,
		parent = parentControl,
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		caption = "Scenario",
	}

	scenarioSelectorPanel = Control:New{
		x = "2%",
		y = 55,
		right = "2%",
		bottom = '2%',

		padding = {0,0,0,0},
		parent = parentControl,
	}
	scenarioScrollPanel = ScrollPanel:New {
		x = 0,
		right = 0,
		y = 0,
		bottom = 0,
		parent = scenarioSelectorPanel,
		horizontalScrollbar = false,
	}

	scenarioPanel = Control:New{
		x = "2%",
		y = 55,
		right = "2%",
		bottom = '2%',

		padding = {0,0,0,0},
		parent = parentControl,
	}

	backbutton = Button:New {
		y = 2,
		right = 7,
		width = 80,
		height = 45,
		caption = "Back",
		classname = "negative_button",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		tooltip = "Back to the list of scenarios",
		OnClick = {
			function()
				scenarioPanel:SetVisibility(false)
				scenarioSelectorPanel:SetVisibility(true)
				backbutton:SetVisibility(false)
				--widget:Initialize()
			end
		},
		parent = parentControl,
	}
	backbutton:SetVisibility(false)
--[[
	local refreshbutton = Button:New {
		x = "86%",
		y = 14,
		right = "10%",
		height = 35,
		caption = "R",
		classname = "action_button",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		tooltip = "Back to the list of scenarios",
		OnClick = {
			function()
				MakeScenarioScrollPanelChildren()
			end
		},
		parent = parentControl,
	}
--]]
	-- make scenario scrollpanel children
	MakeScenarioScrollPanelChildren()

	local cbitemlist = {}
	for i, scen in ipairs(scenarios) do
		cbitemlist[#cbitemlist+1] = scen.title
	end

	scenarioSelectorCombo = ComboBox:New{
		x = 180,
		right = "15%",
		y = "16",
		height = 35,
		itemHeight = 35,
		selectByName = true,

		valign = "top",
		align = "left",
		--captionAlign  = 0, -- these dont work
		--captionHorAlign = 10,
		text = "HasText",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
		items = cbitemlist, --{"Coop", "Team", "1v1", "FFA", "Custom"},
		selected = 1,
		OnSelectName = {
			function (obj, selectedName)
				Spring.Echo(selectedName)
				backbutton:SetVisibility(true)
				scenarioPanel:SetVisibility(true)
				scenarioSelectorPanel:SetVisibility(false)
				CreateScenarioPanel(selectedName,scenarioPanel)
			end
		},
		parent = parentControl,

	}

	--CreateScenarioPanel(1,scenarioPanel)

	local externalFunctions = {parent = parent}

	function externalFunctions.Example(none)
	end

	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- External Interface

local ScenarioHandler = {}

function ScenarioHandler.GetControl()

	local window = Control:New {
		name = "ScenarioHandler",
		x = "0%",
		y = "0%",
		width = "100%",
		height = "100%",
		OnParent = {
			function(obj)
				if obj:IsEmpty() then
					scenarioWindow = InitializeControls(obj)
				end
			end
		},
	}
	return window
end

function ScenarioHandler.reloadGameVersion()
	DownloadRequirements()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

local SCENARIO_COMPLETE_STRING = "ScenarioGameEnd"


function widget:RecvLuaMsg(msg)
	-- prepare for: {"unitsReceived":0,"energyExcess":250,"energyProduced":250,"metalExcess":15,"scenariooptions":{"scenariooptions":"eyJkaWZmaWN1bHR5IjoiTm9ybWFsIiwic2NlbmFyaW9pZCI6ImRndW50ZXN0c2NlbmFyaW8iLCJ2ZXJzaW9uIjoiMS4wIiwibXlvcHRpb24iOiJkb3N0dWZmIn0="},"unitsSent":0,"time":10,"energySent":0,"endtime":10.0666666,"won":false,"metalReceived":0,"winners":1,"unitsDied":0,"unitsKilled":0,"metalProduced":15,"metalUsed":0,"energyUsed":0,"unitsCaptured":0,"energyReceived":0,"metalSent":0,"unitsProduced":1,"damageDealt":524.39447,"frame":302,"unitsOutCaptured":0,"damageReceived":420.846344}
	--Spring.Echo("scenario_complete_", msg)

	if string.find(msg, SCENARIO_COMPLETE_STRING) then
		msg = string.sub(msg, 16)
		local stats = Json.decode(msg)
		--Spring.Utilities.TableEcho(stats)

		if stats.benchmarkcommand then
			Spring.Echo("Recieved Benchmark Results")
			--Spring.Utilities.TableEcho(stats)
			if WG.Analytics and WG.Analytics.SendRepeatEvent then
				WG.Analytics.SendRepeatEvent("system:benchmark", stats)
			end
		else
			local decodedscenopts = Json.decode(Spring.Utilities
			.Base64Decode(stats.scenariooptions))
			lastScenarioID = decodedscenopts.scenarioid
			lastScenarioVersion = decodedscenopts.version
			lastDifficulty = decodedscenopts.difficulty
			lastTime = stats.endtime
			lastResources = (stats.metalUsed + stats.energyUsed/60.0) or 0
			local won = (stats.won and stats.cheated ~= true ) or false

			Spring.Echo(lastScenarioID, lastScenarioVersion, lastDifficulty, lastTime, lastResources, won)
			if WG.Analytics and WG.Analytics.SendRepeatEvent then
				WG.Analytics.SendRepeatEvent("game_start:singleplayer:scenario_end", {scenarioid = lastScenarioID, difficulty = lastDifficulty, won = won, endtime = lastTime, resources = lastResources })
			end

			if won then
				SetScore(lastScenarioID, lastScenarioVersion, lastDifficulty, lastTime, lastResources, won)
				widget:Initialize()
				MakeScenarioScrollPanelChildren()
			end
		end
	end
end

function widget:GetConfigData()
	Spring.Echo("Scenario Window GetConfigData")
	return {
		scores = scoreData,
	}
end

function widget:SetConfigData(data)
	Spring.Echo("Scenario Window SetConfigData")
	scoreData = data.scores or {}
end

local function DelayedInitialize()
	local Configuration = WG.Chobby.Configuration
	--SetScore("testscores","1.0","Hard",100,9999) -- seems to work
	if lastScenarioID and lastScenarioVersion and lastDifficulty then
		RefreshScores(lastScenarioID, lastScenarioVersion, lastDifficulty)
	end
end

function widget:Initialize()

	CHOBBY_DIR = LUA_DIRNAME .. "widgets/chobby/"
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	LoadScenarios()

	WG.Delay(DelayedInitialize, 1)

	WG.ScenarioHandler = ScenarioHandler

	--test scoring
end

function widget:Shutdown()
	widgetHandler:DeregisterGlobal('ScenarioGameEnd')
end


--[[
local framenum = 0
function widget:Update() -- just to check if this still runs, and yes
	framenum = framenum + 1
	if math.fmod(framenum,1000)==0 then
	end
end
--]]

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
unitdefname_to_humanname  = {
		armaak = "Archangel",
		armaap = "Advanced Aircraft Plant",
		armaas = "Archer",
		armaca = "Advanced Construction Aircraft",
		armack = "Advanced Construction Bot",
		armacsub = "Advanced Construction Sub",
		armacv = "Advanced Construction Vehicle",
		armadvsol = "Advanced Solar Collector",
		armafus = "Advanced Fusion Reactor",
		armageo = "Geothermal Powerplant",
		armah = "Swatter",
		armalab = "Advanced Bot Lab",
		armamb = "Ambusher",
		armamd = "Protector",
		armamex = "Twilight",
		armamph = "Pelican",
		armamsub = "Amphibious Complex",
		armanac = "Anaconda",
		armanni = "Annihilator",
		armap = "Aircraft Plant",
		armapt3 = "Tech 3 Aircraft Plant",
		armarad = "Advanced Radar Tower",
		armart = "Shellshocker",
		armaser = "Eraser",
		armason = "Advanced Sonar Station",
		armasp = "Air Repair Pad",
		armassimilator = "Assimilator",
		armasy = "Advanced Shipyard",
		armatl = "Moray",
		armatlas = "Atlas",
		armavp = "Advanced Vehicle Plant",
		armawac = "Eagle",
		armbanth = "Bantha",
		armbats = "Millennium",
		armbeamer = "Beamer",
		armbeaver = "Beaver",
		armblade = "Blade",
		armbrawl = "Brawler",
		armbrtha = "Big Bertha",
		armbull = "Bulldog",
		armca = "Construction Aircraft",
		armcarry = "Colossus",
		armch = "Construction Hovercraft",
		armcir = "Chainsaw",
		armck = "Construction Bot",
		armckfus = "Cloakable Fusion Reactor",
		armclaw = "Dragon's Claw",
		armcom = "Commander",
		armcomboss = "Epic Commander - Final Boss",
		armconsul = "Consul",
		armcroc = "Triton",
		armcrus = "Conqueror",
		armcs = "Construction Corvette",
		armcsa = "Construction Seaplane",
		armcv = "Construction Vehicle",
		armdecade = "Decade",
		armdecom = "Commander",
		armdf = "Fusion Reactor",
		armdfly = "Dragonfly",
		armdl = "Anemone",
		armdrag = "Dragon's Teeth",
		armemp = "Detonator",
		armepoch = "Epoch",
		armestor = "Energy Storage",
		armeyes = "Dragon's Eye",
		armfark = "Fark",
		armfast = "Zipper",
		armfatf = "Floating Targeting Facility",
		armfav = "Rover",
		armfboy = "Fatboy",
		armfdrag = "Shark's Teeth",
		armfepocht4 = "Flying Epoch",
		armferret = "Ferret",
		armfflak = "Flakker NS",
		armfgate = "Aurora",
		armfhlt = "Stingray",
		armfhp = "Floating Hovercraft Platform",
		armfido = "Fido",
		armfig = "Freedom Fighter",
		armflak = "Flakker",
		armflash = "Flash",
		armflea = "Flea",
		armfmine3 = "Mega NS",
		armfmkr = "Floating Energy Converter",
		armfort = "Fortification Wall",
		armfrad = "Floating Radar/Sonar Tower",
		armfrock = "Scumbag",
		armfrt = "Sentry",
		armfus = "Fusion Reactor",
		armgate = "Keeper",
		armgeo = "Geothermal Powerplant",
		armgmm = "Prude",
		armgplat = "Gun Platform",
		armgremlin = "Gremlin",
		armguard = "Guardian",
		armham = "Hammer",
		armhawk = "Hawk",
		armhlt = "Sentinel",
		armhp = "Hovercraft Platform",
		armjam = "Jammer",
		armjamt = "Sneaky Pete",
		armjanus = "Janus",
		armjeth = "Jethro",
		armjuno = "Arm Juno",
		armkam = "Banshee",
		armlab = "Bot Lab",
		armlance = "Lancet",
		armlatnk = "Panther",
		armliche = "Liche",
		armllt = "LLT",
		armlun = "Lun",
		armlunchbox = "Lunchbox",
		armmakr = "Energy Converter",
		armmanni = "Penetrator",
		armmar = "Marauder",
		armmark = "Marky",
		armmart = "Luger",
		armmav = "Maverick",
		armmeatball = "Meatball",
		armmercury = "Mercury",
		armmerl = "Merl",
		armmex = "Metal Extractor",
		armmh = "Wombat",
		armmine1 = "Micro",
		armmine2 = "Kilo",
		armmine3 = "Mega",
		armmls = "Valiant",
		armmlv = "Podger",
		armmmkr = "Energy Converter",
		armmoho = "Moho Mine",
		armmship = "Ranger",
		armmstor = "Metal Storage",
		armnanotc = "Nano Turret",
		armnanotcplat = "Nano Turret",
		armpb = "Pit Bull",
		armpeep = "Peeper",
		armpincer = "Pincer",
		armplat = "Seaplane Platform",
		armpnix = "Phoenix",
		armpship = "Ellysaw",
		armpt = "Skeeter",
		armptl = "Harpoon",
		armpw = "Peewee",
		armpwt4 = "Epic Peewee",
		armrad = "Radar Tower",
		armrattet4 = "Ratte",
		armraz = "Razorback",
		armrecl = "Grim Reaper",
		armrectr = "Rector",
		armrectrt4 = "Epic Rector",
		armrl = "Defender",
		armrock = "Rocko",
		armroy = "Crusader",
		armsaber = "Sabre",
		armsam = "Samson",
		armsb = "Tsunami",
		armscab = "Scarab",
		armsd = "Tracer",
		armseap = "Albatross",
		armseer = "Seer",
		armsehak = "Seahawk",
		armserp = "Serpent",
		armserpold = "Serpent",
		armsfig = "Tornado",
		armsh = "Skimmer",
		armshltx = "Experimental Gantry",
		armshltxuw = "Experimental Gantry",
		armsilo = "Retaliator",
		armsjam = "Escort",
		armsnipe = "Sharpshooter",
		armsolar = "Solar Collector",
		armsonar = "Sonar Station",
		armspid = "Spider",
		armsptk = "Recluse",
		armsptkt4 = "Epic Recluse",
		armspy = "Infiltrator",
		armstil = "Stiletto",
		armstone = "Commander Tombstone",
		armstump = "Stumpy",
		armsub = "Lurker",
		armsubk = "Piranha",
		armsubkold = "Piranha",
		armsy = "Shipyard",
		armtarg = "Targeting Facility",
		armthovr = "Bear",
		armthund = "Thunder",
		armthundt4 = "Epic Thunder",
		armtide = "Tidal Generator",
		armtl = "Harpoon",
		armtorps = "Torpedo Ship",
		armtship = "Hulk",
		armuwadves = "Hardened Energy Storage",
		armuwadvms = "Hardened Metal Storage",
		armuwes = "Underwater Energy Storage",
		armuwfus = "Underwater Fusion Plant",
		armuwmex = "Offshore Metal Extractor",
		armuwmme = "Underwater Moho Mine",
		armuwmmm = "Floating Energy Converter",
		armuwms = "Underwater Metal Storage",
		armvader = "Invader",
		armvadert4 = "Epic Invader",
		armvang = "Vanguard",
		armveil = "Veil",
		armvp = "Vehicle Plant",
		armvulc = "Vulcan",
		armwar = "Warrior",
		armwin = "Wind Generator",
		armyork = "Phalanx",
		armzeus = "Zeus",
		chicken1 = "Chicken",
		chicken1b = "Chicken",
		chicken1c = "Chicken",
		chicken1d = "Chicken",
		chicken1x = "Chicken",
		chicken1y = "Chicken",
		chicken1z = "Chicken",
		chicken2 = "Chicken",
		chicken2b = "Chicken",
		chicken_dodo1 = "Dodo",
		chicken_dodo2 = "Alpha Dodo",
		chickena1 = "Cockatrice",
		chickena1b = "Cockatrice",
		chickena1c = "Cockatrice",
		chickena2 = "Alpha Cockatrice",
		chickena2b = "Alpha Cockatrice",
		chickenc1 = "Basilisk",
		chickenc2 = "Manticore",
		chickenc3 = "Weevil",
		chickenc3b = "Weevil",
		chickenc3c = "Weevil",
		chickend1 = "Chicken Tube",
		chickenf1 = "Talon",
		chickenf1b = "Talon",
		chickenf2 = "Buzzard",
		chickenh1 = "Weaver",
		chickenh1b = "Weaver",
		chickenh2 = "Progenitor",
		chickenh3 = "Chicken",
		chickenh4 = "Chicken",
		chickenh5 = "Patriarch",
		chickenp1 = "Bombardier",
		chickenr1 = "Lobber",
		chickenr2 = "Enraged Lobber",
		chickenr3 = "Chicken Colonizer",
		chickens1 = "Spiker",
		chickens2 = "Advanced Spiker",
		chickens3 = "Fang",
		chickenw1 = "Claw",
		chickenw1b = "Claw",
		chickenw1c = "Claw",
		chickenw1d = "Claw",
		chickenw2 = "Crow",
		coraak = "Manticore",
		coraap = "Advanced Aircraft Plant",
		coraca = "Advanced Construction Aircraft",
		corack = "Advanced Construction Bot",
		coracsub = "Advanced Construction Sub",
		coracv = "Advanced Construction Vehicle",
		coradvsol = "Advanced Solar Collector",
		corafus = "Advanced Fusion Reactor",
		corageo = "Geothermal Powerplant",
		corah = "Slinger",
		corak = "A.K.",
		coralab = "Advanced Bot Lab",
		coramph = "Gimp",
		coramsub = "Amphibious Complex",
		corap = "Aircraft Plant",
		corape = "Rapier",
		corapt3 = "Tech 3 Aircraft Plant",
		corarad = "Advanced Radar Tower",
		corarch = "Shredder",
		corason = "Advanced Sonar Station",
		corasp = "Air Repair Pad",
		corasy = "Advanced Shipyard",
		coratl = "Lamprey",
		coravp = "Advanced Vehicle Plant",
		corawac = "Vulture",
		corban = "Banisher",
		corbats = "Warlord",
		corbhmth = "Behemoth",
		corblackhy = "Black Hydra",
		corbuzz = "Buzzsaw",
		corbw = "Bladewing",
		corca = "Construction Aircraft",
		corcan = "Can",
		corcarry = "Hive",
		corcat = "Catapult",
		corch = "Construction Hovercraft",
		corck = "Construction Bot",
		corcom = "Commander",
		corcomboss = "Epic Commander - Final Boss",
		corcrash = "Crasher",
		corcrus = "Executioner",
		corcrw = "Krow",
		corcrwt4 = "Epic Krow",
		corcs = "Construction Ship",
		corcsa = "Construction Seaplane",
		corcut = "Cutlass",
		corcv = "Construction Vehicle",
		cordecom = "Commander",
		cordemon = "Demon",
		cordl = "Jellyfish",
		cordoom = "Doomsday Machine",
		cordrag = "Dragon's Teeth",
		corenaa = "Cobra - NS",
		corerad = "Eradicator",
		corestor = "Energy Storage",
		coresupp = "Supporter",
		coreter = "Deleter",
		corexp = "Exploiter",
		coreyes = "Dragon's Eye",
		corfast = "Freaker",
		corfatf = "Floating Targeting Facility",
		corfav = "Weasel",
		corfblackhyt4 = "Flying Black Hydra",
		corfdrag = "Shark's Teeth",
		corfgate = "Atoll",
		corfhlt = "Thunderbolt",
		corfhp = "Floating Hovercraft Platform",
		corfink = "Fink",
		corflak = "Cobra",
		corfmd = "Fortitude",
		corfmine3 = "1100 NS",
		corfmkr = "Floating Energy Converter",
		corfort = "Fortification Wall",
		corfrad = "Floating Radar/Sonar Tower",
		corfrock = "Janitor",
		corfrt = "Stinger",
		corfus = "Fusion Reactor",
		corgant = "Experimental Gantry",
		corgantuw = "Experimental Gantry",
		corgarp = "Garpike",
		corgate = "Overseer",
		corgator = "Instigator",
		corgatreap = "Gaat Reaper",
		corgeo = "Geothermal Powerplant",
		corgol = "Goliath",
		corgolt4 = "Epic Goliath",
		corgplat = "Gun Platform",
		corhal = "Halberd",
		corhllt = "HLLT",
		corhlt = "Warden",
		corhp = "Hovercraft Platform",
		corhrk = "Dominator",
		corhunt = "Hunter",
		corhurc = "Hurricane",
		corint = "Intimidator",
		corintr = "Intruder",
		corjamt = "Castro",
		corjugg = "Juggernaut",
		corjuno = "Cortex Juno",
		corkarg = "Karganeth",
		corkarganetht4 = "Epic Karganeth",
		corkorg = "Korgoth",
		corlab = "Bot Lab",
		corlevlr = "Leveler",
		corllt = "LLT",
		cormabm = "Hedgehog",
		cormadsam = "SAM",
		cormakr = "Energy Converter",
		cormando = "Commando",
		cormart = "Pillager",
		cormaw = "Dragon's Maw",
		cormex = "Metal Extractor",
		cormexp = "Moho Exploiter",
		cormh = "Nixer",
		cormine1 = "11",
		cormine2 = "110",
		cormine3 = "1100",
		cormine4 = "112",
		cormist = "Slasher",
		cormls = "Pathfinder",
		cormlv = "Spoiler",
		cormmkr = "Energy Converter",
		cormoho = "Moho Mine",
		cormort = "Morty",
		cormship = "Messenger",
		cormstor = "Metal Storage",
		cormuskrat = "Muskrat",
		cornanotc = "Nano Turret",
		cornanotcplat = "Nano Turret",
		cornecro = "Necro",
		corparrow = "Poison Arrow",
		corplat = "Seaplane Platform",
		corpship = "Era",
		corpt = "Searcher",
		corptl = "Urchin",
		corpun = "Punisher",
		corpyro = "Pyro",
		corrad = "Radar Tower",
		corraid = "Raider",
		correap = "Reaper",
		correcl = "Death Cavalry",
		corrl = "Pulverizer",
		corroach = "Roach",
		corroy = "Enforcer",
		corsb = "Dam Buster",
		corscreamer = "Screamer",
		corsd = "Nemesis",
		corseah = "Seahook",
		corseal = "Croc",
		corseap = "Typhoon",
		corsent = "Copperhead",
		corsfig = "Voodoo",
		corsh = "Scrubber",
		corshad = "Shadow",
		corshark = "Shark",
		corsharkold = "Shark",
		corshiva = "Shiva",
		corshroud = "Shroud",
		corsilo = "Silencer",
		corsjam = "Phantom",
		corsktl = "Skuttle",
		corsnap = "Snapper",
		corsok = "Sokolov",
		corsolar = "Solar Collector",
		corsonar = "Sonar Station",
		corspec = "Spectre",
		corspy = "Parasite",
		corssub = "Leviathan",
		corssubold = "Leviathan",
		corstone = "Commander Tombstone",
		corstorm = "Storm",
		corsub = "Snake",
		corsumo = "Sumo",
		corsy = "Shipyard",
		cortarg = "Targeting Facility",
		cortermite = "Termite",
		corthovr = "Turtle",
		corthud = "Thud",
		cortide = "Tidal Generator",
		cortitan = "Titan",
		cortl = "Urchin",
		cortoast = "Toaster",
		cortrem = "Tremor",
		cortron = "Catalyst",
		cortship = "Envoy",
		coruwadves = "Hardened Energy Storage",
		coruwadvms = "Hardened Metal Storage",
		coruwes = "Underwater Energy Storage",
		coruwfus = "Underwater Fusion Plant",
		coruwmex = "Offshore Metal Extractor",
		coruwmme = "Underwater Moho Mine",
		coruwmmm = "Floating Energy Converter",
		coruwms = "Underwater Metal Storage",
		corvalk = "Valkyrie",
		corvamp = "Vamp",
		corveng = "Avenger",
		corvipe = "Viper",
		corvoyr = "Voyeur",
		corvp = "Vehicle Plant",
		corvrad = "Informer",
		corvroc = "Diplomat",
		corwin = "Wind Generator",
		corwolv = "Wolverine",
		e_chickenq = "Chicken Queen",
		epic_chickenq = "Epic Chicken Queen",
		h_chickenq = "Chicken Queen",
		n_chickenq = "Chicken Queen",
		roost = "Roost",
		ve_chickenq = "Chicken Queen",
		vh_chickenq = "Chicken Queen",
}
