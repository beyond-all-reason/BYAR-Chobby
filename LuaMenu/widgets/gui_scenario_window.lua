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

-- TODO: change sides!
-- TODO: Parse scores!
-- TODO: Get Scores!
-- TODO: Store scores locally!
-- TODO: unique ID on updates to mission that could affect scores

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Local Variables

local scenarioWindow
local scenarios
local currentscenario
local mybonus = 0
local alreadyDownloaded = false
local barversion = nil
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utilities


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

  


local function CreateScenarioPanel(shortname, sPanel)
	local Configuration = WG.Chobby.Configuration
	-- TODO: destroy old config:GetMinimapImage(

	local scen = scenarios

	MaybeDownloadMap(scen.mapfilename)
	
	local titletext = Label:New{
		x = 0,
		y = 0,
		width = "50%",
		height = "5%",
		parent = sPanel,
		font = Configuration:GetFont(3),
		caption = scen.title,
	}
	
	local summarySP = ScrollPanel:New {
		x = 0,
		y = "5%",
		width = "48%",
		height = "19%",
		parent = sPanel,
		horizontalScrollbar = true,
	}

	local summarytext = scen.summary .. "\nUnit Limits:"

	for unitid, count in pairs(scen.unitlimits) do 
		summarytext = summarytext .. "\n  - "..unitid .. ": " .. tostring(count)
	end

	local summarytextbox = TextBox:New {
		x = 0,
		y = 0,
		width = "100%",
		height = "100%",
		valign = 'top',
		fontsize = Configuration:GetFont(1).size,
		text = summarytext,
		parent = summarySP,
	}

	local victoryText = Label:New{
		x = 0,
		y = "25%",
		width = "50%",
		height = "5%",
		parent = sPanel,
		font = Configuration:GetFont(2),
		caption = "Victory Condition: " .. scen.victorycondition,
	}

	local lossText = Label:New{
		x = 0,
		y = "29%",
		width = "50%",
		height = "5%",
		parent = sPanel,
		font = Configuration:GetFont(2),
		caption = "Loss Condition: " .. scen.losscondition,
	}

	
	local difficultyText = Label:New{
		x = 0,
		y = "33%",
		width = "50%",
		height = "5%",
		parent = sPanel,
		font = Configuration:GetFont(2),
		caption = "Difficulty: " .. tostring(scen.difficulty),
	}

		
	local partimeText = Label:New{
		x = 0,
		y = "37%",
		width = "50%",
		height = "5%",
		parent = sPanel,
		font = Configuration:GetFont(2),
		caption = "Par Time: " .. tostring(math.ceil(scen.partime/60)) .. " minutes",
	}

	local parresourcesText = Label:New{
		x = 0,
		y = "41%",
		width = "50%",
		height = "5%",
		parent = sPanel,
		font = Configuration:GetFont(2),
		caption = "Par Resource usage: " .. tostring(math.ceil(scen.parresources/1000)) .. "K metal",
	}

	local function makebonuscaption(intbonus)
		return "Difficulty modifier " .. tostring(intbonus) .. "%"
	end

	local bonusText = Label:New{
		x = 0,
		y = "45%",
		width = "50%",
		height = "5%",
		parent = sPanel,
		font = Configuration:GetFont(2),
		caption = makebonuscaption(mybonus),
	}

	local setbonusbutton = Button:New{
		x = "25%",
		y = "44%" ,
		width = "100",
		height = "4%",
		caption = "Set Bonus",
		classname = "action_button",
		font = Configuration:GetFont(1),
		tooltip = "Set difficulty modifier. IF SET, YOUR SCORE WONT BE RECORDED!",
		OnClick = {
			function()
				WG.IntegerSelectorWindow.CreateIntegerSelectorWindow({
						defaultValue = 0,
						minValue = -100,
						maxValue = 100,
						caption = "Set Bonus",
						labelCaption = "Give yourself and additional % resource bonus. 100% means that you produce double the normal resource amount. 0% is regular resource production. Negative numbers reduce your resource income by that percentage",
						OnAccepted = function(bonusAmount)
							mybonus = bonusAmount
							bonusText:SetCaption(makebonuscaption(mybonus))
						end
				})
			end
		},
		parent = sPanel,
	}

	---------------------------------
		
	local mapImage = Image:New {
		x = "50%",
		y = 0,
		right = 0,
		bottom = "50%",
		keepAspect = true,
		file =Configuration:GetMinimapImage(scen.mapfilename),
		parent = sPanel,
		tooltip = scen.mapfilename,
		padding = {10,10,10,10},
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
		right = 0,
		height = "23%",
		keepAspect = true,
		file = "LuaMenu/configs/gameConfig/byar/scenarios/" .. scen.imagepath,
		parent = sPanel,
		tooltip = scen.mapfilename,
		padding = {10,10,10,10},
	}
	
	local flavortext = Label:New{
		x = "25%",
		y = "25%",
		width = "95%",
		height = "5%",
		parent = flavorimage,
		font = Configuration:GetFont(3),
		caption = scen.imageflavor,
	}

	----------------------

	local briefingtextSP = ScrollPanel:New {
		x = 0,
		right = "26%",
		y = "76%",
		bottom = 0,
		parent = sPanel,
		horizontalScrollbar = true,
	}

	local briefingtext = TextBox:New {
		x = 0,
		y = 0,
		width = "100%",
		height = "100%",
		valign = 'top',
		fontsize = Configuration:GetFont(1).size,
		text = scen.briefing,
		parent = briefingtextSP,
	}

	------------------------
	local mytime = Label:New{
		x = "75%",
		y = "80%",
		width = "25%",
		height = "5%",
		parent = sPanel,
		font = Configuration:GetFont(2),
		caption = "My Time: " .. tostring(math.ceil(scen.partime/60)) .. " minutes",
	}

	local myresources = Label:New{
		x = "75%",
		y = "85%",
		width = "25%",
		height = "5%",
		parent = sPanel,
		font = Configuration:GetFont(2),
		caption = "My Resources " .. tostring(math.ceil(scen.parresources/1000)) .. "K metal",
	}
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
		basescript = basescript:gsub("__PLAYERBONUS__",tostring(mybonus))
		basescript = basescript:gsub("__BARVERSION__",tostring(barversion))
	
		return basescript
	end

	local startmissionbutton = Button:New {
		x = "75%",
		bottom = 0,
		right = 0,
		height = "10%",
		caption = "Start Scenario",
		classname = "action_button",
		font = Configuration:GetFont(3),
		tooltip = "Start the scenario",
		OnClick = {
			function()
					local scriptTxt = createstartscript()
					Spring.Echo("Mission Ready")
					Spring.Echo(scriptTxt)
					-- TODO: check that map and game already downloaded!
					Spring.Reload(scriptTxt)
			end
		},
		parent = sPanel,
	}

end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Controls

local function InitializeControls(parentControl)
	local Configuration = WG.Chobby.Configuration

	DownloadRequirements()

	Label:New {
		x = 15,
		y = 11,
		width = 180,
		height = 30,
		parent = parentControl,
		font = Configuration:GetFont(3),
		caption = "Scenario",
	}

	local scenarioPanel = Control:New{
		x = 0,
		y = 46,
		width = '100%',
		bottom = '0%',
		padding = {10,10,10,10},
		parent = parentControl,
	}

	local scenarioSelectorCombo = ComboBox:New{
		x = 180,
		right = "1%",
		y = 12,
		height = 35,
		itemHeight = 22,
		selectByName = true,
		captionHorAlign = -32,
		text = "HasText",
		font = Configuration:GetFont(3),
		items = {"Coop", "Team", "1v1", "FFA", "Custom"},
		itemFontSize = Configuration:GetFont(3).size,
		selected = 1,
		OnSelectName = {
			function (obj, selectedName)
				Spring.Echo(selectedName)
				CreateScenarioPanel(1,scenarioPanel)
			end
		},
		parent = parentControl,

	}

	CreateScenarioPanel(1,scenarioPanel)
	

	local replayList
	

	local externalFunctions = {}

	function externalFunctions.AddReplay(replayPath, engine, game, map, script)
		local control, sortData = CreateReplayEntry(replayPath, engine, game, map)
		if control then
			replayList:AddItem(replayPath, control, sortData)
		end
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

function ScenarioHandler.ReadReplayInfoDone(path, engine, game, map, script)
	if not scenarioWindow then
		return
	end
	scenarioWindow.AddReplay(path, engine, game, map, script)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

local function DelayedInitialize()
	local Configuration = WG.Chobby.Configuration
	battleStartDisplay = Configuration.game_fullscree
end

function widget:Initialize()
	CHOBBY_DIR = LUA_DIRNAME .. "widgets/chobby/"
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	scenarios = VFS.Include("LuaMenu/configs/gameConfig/byar/scenarios/scenario001.lua", nil, VFS.RAW_FIRST)


	WG.Delay(DelayedInitialize, 1)

	WG.ScenarioHandler = ScenarioHandler
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
