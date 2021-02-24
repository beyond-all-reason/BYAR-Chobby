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


-- TODO: Parse scores!
-- TODO: Get Scores!
-- TODO: Store scores locally!
-- TODO: unique ID on updates to mission that could affect scores
-- TODO: refresh button for EZ testing

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Local Variables

local scenarioWindow
local scenarios
local scenariosorter
local currentscenario
local mybonus = 0
local alreadyDownloaded = false
local barversion = nil
local myside = nil
local mydifficulty = nil
local myscores = {time = 0, resources = 0}
local myside = nil


local unitdefname_to_humanname = {} -- from en.lua
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

  
local function LoadScenarios()
	scenarios = {}
	local files = VFS.DirList("LuaMenu/configs/gameConfig/byar/scenarios/")
	for i = 1, #files do
		if string.find(files[i],".lua") then
			scenarios[#scenarios+1] = VFS.Include(files[i])
		end
	end

	local function SortFunc(a,b)
		return a.index < b.index
	end

	table.sort(scenarios, SortFunc )
end

local function EncodeScenarioOptions(luatable)
	return Spring.Utilities.Base64Encode(Spring.Utilities.json.encode(luatable))
end

local function GetBestScores(scenarioID,scenarioversoin,difficulty)
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
		height = "14%",
		parent = sPanel,
		horizontalScrollbar = true,
	}

	local summarytext = scen.summary .. "\nUnit Limits:"
	if scen.unitlimits == {} or scen.unitlimits == nil then
		summarytext = summarytext .. " none\n"
	else
		for unitid, count in pairs(scen.unitlimits) do 
			summarytext = summarytext .. "\n  - "..unitid .. ": " .. tostring(count)
		end
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

	local lblvictoryText = Label:New{
		x = 0,
		y = "20%",
		width = "50%",
		height = "5%",
		parent = sPanel,
		font = Configuration:GetFont(2),
		caption = "Victory",
	}

	
	local victoryText = Label:New{
		x = "16%",
		y = "20%",
		width = "50%",
		height = "5%",
		parent = sPanel,
		font = Configuration:GetFont(2),
		caption = scen.victorycondition,
	}

	local lbllossText = Label:New{
		x = 0,
		y = "24%",
		width = "50%",
		height = "5%",
		parent = sPanel,
		font = Configuration:GetFont(2),
		caption = "Loss" ,
	}

	local lossText = Label:New{
		x = "16%",
		y = "24%",
		width = "50%",
		height = "5%",
		parent = sPanel,
		font = Configuration:GetFont(2),
		caption = scen.losscondition,
	}

	local lbldifficultyText = Label:New{
		x = 0,
		y = "28%",
		width = "50%",
		height = "5%",
		parent = sPanel,
		font = Configuration:GetFont(2),
		caption = "Challenge",
	}
	
	local difficultyText = Label:New{
		x = "16%",
		y = "28%",
		width = "50%",
		height = "5%",
		parent = sPanel,
		font = Configuration:GetFont(2),
		caption = tostring(scen.difficulty),
	}

	local lblpartimeText = Label:New{
		x = 0,
		y = "32%",
		width = "50%",
		height = "5%",
		parent = sPanel,
		font = Configuration:GetFont(2),
		caption = "Par Time",
	}

	local partimeText = Label:New{
		x = "16%",
		y = "32%",
		width = "50%",
		height = "5%",
		parent = sPanel,
		font = Configuration:GetFont(2),
		caption = tostring(math.ceil(scen.partime/60)) .. " minutes",
	}

	local lblparresourcesText = Label:New{
		x = 0,
		y = "36%",
		width = "50%",
		height = "5%",
		parent = sPanel,
		font = Configuration:GetFont(2),
		caption = "Par Resources" ,
	}

	local parresourcesText = Label:New{
		x = "16%",
		y = "36%",
		width = "50%",
		height = "5%",
		parent = sPanel,
		font = Configuration:GetFont(2),
		caption =  tostring(math.ceil(scen.parresources/1000)) .. "K metal",
	}
--[[
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
	}]]--


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
		width = "73%",
		height = "23%",
		keepAspect = true,
		file = "LuaMenu/configs/gameConfig/byar/scenarios/" .. scen.imagepath,
		parent = sPanel,
		--tooltip = scen.mapfilename,
		padding = {10,10,10,10},
	}
	
	local flavortext = Label:New{
		x = "12.5%",
		y = "25%",
		width = "73%",
		height = "5%",
		parent = flavorimage,
		font = Configuration:GetFont(2),
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
		padding = {10,10,10,10},
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
		
		padding = {10,10,10,10},
	}

	------------------------
	local lblpersonal = Label:New{
		x = "77%",
		y = "67.5%",
		width = "20%",
		height = "5%",
		parent = sPanel,
		font = Configuration:GetFont(3),
		caption = "Personal Records",
	}

	
	local lbldifflevelpersonal = Label:New{
		x = "77%",
		y = "72.5%",
		width = "20%",
		height = "5%",
		parent = sPanel,
		font = Configuration:GetFont(2),
		caption = "Difficulty level: "..tostring(mydifficulty),
	}

	local lblmytime = Label:New{
		x = "77%",
		y = "77.5%",
		width = "25%",
		height = "5%",
		parent = sPanel,
		font = Configuration:GetFont(2),
		caption = "My Best Time: ",
	}
	
	local mytime = Label:New{
		x = "77%",
		y = "80.5%",
		width = "25%",
		height = "5%",
		parent = sPanel,
		font = Configuration:GetFont(2),
		caption = tostring(math.ceil(myscores.time/60)) .. " minutes",
	}

	local lblmyresources = Label:New{
		x = "77%",
		y = "85%",
		width = "25%",
		height = "5%",
		parent = sPanel,
		font = Configuration:GetFont(2),
		caption = "My Resources ",
	}

	local myresources = Label:New{
		x = "77%",
		y = "89%",
		width = "25%",
		height = "5%",
		parent = sPanel,
		font = Configuration:GetFont(2),
		caption = tostring(math.ceil(myscores.resources/1000)) .. "K metal",
	}

	
	local difficulties = {}
	local defaultdifficultyindex = 1
	for i,diff in pairs(scen.difficulties) do
		difficulties[#difficulties + 1] = diff.name
		if diff.name == scen.defaultdifficulty then 
			defaultdifficultyindex = i
			mydifficulty = diff
		end
	end

	myside = scen.defaultside

	local sidelabel = Label:New{
		x = "0%",
		y = "40%" ,
		width = "100",
		height = "4%",
		parent = sPanel,
		font = Configuration:GetFont(2),
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
		font = Configuration:GetFont(2),
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
	}]]--

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
		font = Configuration:GetFont(2),
		items = {"Armada", "Cortex", "Random"}, --{"Coop", "Team", "1v1", "FFA", "Custom"},
		itemFontSize = Configuration:GetFont(2).size,
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
		font = Configuration:GetFont(2),
		caption = "Difficulty",
	}

	local function UpdateDifficulty(newdifficulty)
		for i, diff in pairs(scen.difficulties) do 
			if diff.name == newdifficulty then mydifficulty = diff end
		end
		mydifficulty = newdifficulty
		lbldifflevelpersonal:SetCaption("Difficulty level: "..tostring(mydifficulty))
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
		font = Configuration:GetFont(2),
		items = difficulties, --{"Coop", "Team", "1v1", "FFA", "Custom"},
		itemFontSize = Configuration:GetFont(2).size,
		selected = 3,
		OnSelectName = {
			function (obj, selectedName)
				Spring.Echo("Difficulty selected:",selectedName)
				UpdateDifficulty(selectedName,scenarioPanel)
			end
		},
		parent = sPanel,
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
		basescript = basescript:gsub("__PLAYERBONUS__",tostring(mydifficulty.playerhandicap))
		basescript = basescript:gsub("__ENEMYBONUS__",tostring(mydifficulty.enemyhandicap))
		basescript = basescript:gsub("__BARVERSION__",tostring(barversion))
		if scen.adjustablediff then
			basescript = basescript:gsub("__PLAYERSIDE__",tostring(myside or scen.defaultside))
		else
			basescript = basescript:gsub("__PLAYERSIDE__",tostring(scen.defaultside))
		end
		basescript = basescript:gsub("__SCENARIOOPTIONS__",tostring(EncodeScenarioOptions(scen.scenariooptions)))

	
		return basescript
	end

	local startmissionbutton = Button:New {
		x = "76%",
		y = "52%",
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
					--Spring.Reload(scriptTxt)
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
		padding = {20,20,20,20},
		parent = parentControl,
	}

	local cbitemlist = {}
	for i, scen in ipairs(scenarios) do 
		cbitemlist[#cbitemlist+1] = scen.title
	end

	local scenarioSelectorCombo = ComboBox:New{
		x = 180,
		right = "3%",
		y = 12,
		height = 35,
		itemHeight = 35,
		selectByName = true,
		
		valign = "left",
		align = "left",
		--captionHorAlign = -32,
		text = "HasText",
		font = Configuration:GetFont(3),
		items = cbitemlist, --{"Coop", "Team", "1v1", "FFA", "Custom"},
		itemFontSize = Configuration:GetFont(3).size,
		selected = 1,
		OnSelectName = {
			function (obj, selectedName)
				Spring.Echo(selectedName)
				CreateScenarioPanel(selectedName,scenarioPanel)
			end
		},
		parent = parentControl,

	}

	CreateScenarioPanel(1,scenarioPanel)
	
	local externalFunctions = {}

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

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

local function DelayedInitialize()
	local Configuration = WG.Chobby.Configuration
end


function widget:Initialize()
	CHOBBY_DIR = LUA_DIRNAME .. "widgets/chobby/"
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	LoadScenarios()

	WG.Delay(DelayedInitialize, 1)

	WG.ScenarioHandler = ScenarioHandler
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
unitdefname_to_humanname  = {
	armaak = "Advanced Amphibious Anti-Air Bot",
	armaap = "Produces Level 2 Aircraft",
	armaas = "Anti-Air Ship",
	armaca = "Tech Level 2",
	armack = "Tech Level 2",
	armacsub = "Tech Level 2",
	armacv = "Tech Level 2",
	armadvsol = "Produces 75 Energy",
	armafus = "Produces 3000 Energy (Hazardous)",
	armageo = "Produces 1250 Energy (Hazardous)",
	armah = "Anti-Air Hovercraft",
	armalab = "Produces Level 2 Bots",
	armamb = "Cloakable Coastal Defense",
	armamd = "Anti-Nuke System",
	armamex = "Stealthy Cloakable Metal Extractor",
	armamph = "Amphibious Bot",
	armamsub = "Produces Amphibious/Underwater Units",
	armanac = "Hovertank",
	armanni = "Tachyon Accelerator",
	armap = "Produces Level 1 Aircraft",
	armapt3 = "Produces Level 3 Aircraft",
	armarad = "Long-Range Radar",
	armart = "Light Artillery Vehicle",
	armaser = "Radar Jammer Bot",
	armason = "Extended Sonar",
	armasp = "Automatically Repairs Aircraft",
	armassimilator = "Battle Mech",
	armasy = "Produces Level 2 Ships",
	armatl = "Advanced Torpedo Launcher",
	armatlas = "Air Transport",
	armavp = "Produces Level 2 Vehicles",
	armawac = "Radar/Sonar Plane",
	armbanth = "Assault Mech",
	armbats = "Battleship",
	armbeamer = "Beam Laser Turret. Transportable (Heavy)",
	armbeaver = "Amphibious Construction Vehicle",
	armblade = "Rapid Assault Gunship",
	armbrawl = "Gunship",
	armbrtha = "Long Range Plasma Cannon",
	armbull = "Heavy Assault Tank",
	armca = "Tech Level 1",
	armcarry = "Aircraft Carrier with Anti-Nuke",
	armch = "Tech Level 1",
	armcir = "Bomb-Resistant Medium-Range Anti-Air Missile Battery",
	armck = "Tech Level 1",
	armckfus = "Produces 1050 Energy",
	armclaw = "Pop-up Lightning Turret",
	armcom = "Commander",
	armcomboss = "Oh s##t we are so dead",
	armconsul = "Combat Engineer",
	armcroc = "Heavy Amphibious Tank",
	armcrus = "Cruiser",
	armcs = "Tech Level 1",
	armcsa = "Tech Level 1",
	armcv = "Tech Level 1",
	armdecade = "Fast Assault Corvette",
	armdecom = "Decoy Commander",
	armdf = "Produces Energy / Storage",
	armdfly = "Stealthy Armed Heavy Transport",
	armdl = "Coastal Torpedo Launcher",
	armdrag = "Dragons Teeth",
	armemp = "EMP Missile Launcher",
	armepoch = "Flagship",
	armestor = "Increases Energy Storage (6000)",
	armeyes = "Perimeter Camera",
	armfark = "Fast Assist/Repair Bot",
	armfast = "Fast Raider Bot",
	armfatf = "Enhanced Radar Targeting",
	armfav = "Light Scout Vehicle",
	armfboy = "Heavy Plasma Bot",
	armfdrag = "Shark's Teeth",
	armfepocht4 = "Flagship with Vtol thrusters... wait what?",
	armferret = "Pop-Up Anti-Air Missile Battery",
	armfflak = "Anti-Air Flak Gun - Naval Series",
	armfgate = "Floating Plasma Deflector",
	armfhlt = "Floating Heavy Laser Tower",
	armfhp = "Builds Hovercraft",
	armfido = "Mortar/Skirmish Bot",
	armfig = "Fighter",
	armflak = "Anti-Air Flak Gun",
	armflash = "Fast Assault Tank",
	armflea = "Fast Scout Bot",
	armfmine3 = "Heavy Mine, Naval Series",
	armfmkr = "Converts 70 energy into 1.1 metal per sec",
	armfort = "Fortification Wall",
	armfrad = "Early Warning System",
	armfrock = "Floating Anti-Air Missile Battery",
	armfrt = "Floating Anti-air Tower",
	armfus = "Produces 1000 Energy",
	armgate = "Plasma Deflector",
	armgeo = "Produces 300 Energy",
	armgmm = "Safe Geothermal Powerplant",
	armgplat = "Light Plasma Defense",
	armgremlin = "Stealth Tank",
	armguard = "Coastal Defense",
	armham = "Light Plasma Bot",
	armhawk = "Stealth Fighter",
	armhlt = "Heavy Laser Tower",
	armhp = "Builds Hovercraft",
	armjam = "Radar Jammer Vehicle",
	armjamt = "Cloakable Jammer Tower",
	armjanus = "Twin Medium Rocket Launcher",
	armjeth = "Amphibious Anti-air Bot",
	armjuno = "Anti Radar/Jammer/Minefield/ScoutSpam Weapon",
	armkam = "Light Gunship",
	armlab = "Produces Level 1 Bots",
	armlance = "Torpedo Bomber",
	armlatnk = "Lightning Tank",
	armliche = "Atomic Bomber",
	armllt = "Light Laser Tower. Transportable (Heavy)",
	armlun = "Heavy Hovertank",
	armlunchbox = "All-Terrain Heavy Plasma Cannon",
	armmakr = "Converts 70 energy into 1 metal per sec",
	armmanni = "Mobile Tachyon Weapon",
	armmar = "Amphibious Assault Mech",
	armmark = "Radar Bot",
	armmart = "Mobile Artillery",
	armmav = "Skirmish Bot (Fast Learning, Auto-Repair)",
	armmeatball = "Amphibious Assault Mech",
	armmercury = "Long Range Anti-Air Tower",
	armmerl = "Stealthy Rocket Launcher",
	armmex = "Extracts Metal from Metalspots",
	armmh = "Hovercraft Rocket Launcher",
	armmine1 = "Light Mine",
	armmine2 = "Medium Mine",
	armmine3 = "Heavy Mine",
	armmls = "Naval Engineer",
	armmlv = "Stealthy Minelayer/Minesweeper",
	armmmkr = "Converts 600 energy into 10.3 metal",
	armmoho = "Advanced Metal Extractor / Storage",
	armmship = "Missile Cruiser",
	armmstor = "Increases Metal Storage (3000)",
	armnanotc = "Assist & Repair in large radius. Transportable",
	armnanotcplat = "Repairs and builds in large radius",
	armpb = "Pop-up Gauss Cannon",
	armpeep = "Scout",
	armpincer = "Light Amphibious Tank",
	armplat = "Builds Seaplanes",
	armpnix = "Strategic Bomber",
	armpship = "Assault Frigate",
	armpt = "Patrol Boat/Light Anti Air/Sonar",
	armptl = "Pop-up Torpedo Launcher",
	armpw = "Fast Infantry Bot",
	armpwt4 = "Holy #### it's huge Peewee!",
	armrad = "Early Warning System. Transportable (Heavy)",
	armrattet4 = "Brick with huge as #### gun.",
	armraz = "Battle Mech",
	armrecl = "Ressurection Sub",
	armrectr = "Stealthy Rez/Repair/Reclaim Bot",
	armrectrt4 = "Stealthy Rez/Repair/Reclaim Bot",
	armrl = "Light Anti-air Tower. Transportable (Heavy)",
	armrock = "Rocket Bot - good vs. static defenses",
	armroy = "Destroyer",
	armsaber = "Seaplane Gunship",
	armsam = "Missile Truck",
	armsb = "Seaplane Bomber",
	armscab = "Mobile Anti-Nuke",
	armsd = "Intrusion Countermeasure System - tracks down stealthy units",
	armseap = "Torpedo Gunship",
	armseer = "Radar Vehicle",
	armsehak = "Advanced Radar/Sonar Plane",
	armserp = "Long-Range Battle Submarine",
	armserpold = "Battle Submarine",
	armsfig = "Seaplane Swarmer",
	armsh = "Fast Attack Hovercraft",
	armshltx = "Produces Level 3 Units",
	armshltxuw = "Produces Large Amphibious Units",
	armsilo = "Nuclear ICBM Launcher",
	armsjam = "Radar Jammer Ship",
	armsnipe = "Sniper Bot",
	armsolar = "Produces 20 Energy",
	armsonar = "Locates Water Units",
	armspid = "All-Terrain EMP Spider",
	armsptk = "All-Terrain Rocket Spider",
	armsptkt4 = "Recluse, but bigger.",
	armspy = "Radar-Invisible Spy Bot",
	armstil = "EMP Bomber",
	armstone = "Commander Tombstone",
	armstump = "Medium Assault Tank",
	armsub = "Submarine",
	armsubk = "Submarine Killer",
	armsubkold = "Submarine Killer",
	armsy = "Produces Level 1 Ships",
	armtarg = "Enhanced Radar Targeting, more facilities enhance accuracy",
	armthovr = "Heavy Transport Hovercraft",
	armthund = "Bomber",
	armthundt4 = "Epic T4 Carpet Bomber",
	armtide = "Produces Energy (depends on map)",
	armtl = "Offshore Torpedo Launcher",
	armtorps = "Torpedo Ship",
	armtship = "Armored Transport Ship",
	armuwadves = "Increases Energy Storage (40000)",
	armuwadvms = "Increases Metal Storage (10000)",
	armuwes = "Increases Energy Storage (6000)",
	armuwfus = "Produces 1200 Energy",
	armuwmex = "Extracts Metal",
	armuwmme = "Advanced Metal Extractor / Storage",
	armuwmmm = "Converts 650 energy into 11 metal per sec",
	armuwms = "Increases Metal Storage (3000)",
	armvader = "Amphibious Crawling Bomb",
	armvadert4 = "So it's a ball with nuke warhead inside",
	armvang = "All-Terrain Heavy Plasma Cannon",
	armveil = "Long-Range Jamming Tower",
	armvp = "Produces Level 1 Vehicles",
	armvulc = "Rapid-Fire Long-Range Plasma Cannon",
	armwar = "Medium Infantry Bot",
	armwin = "Produces Energy. Depends on wind strength.",
	armyork = "Anti-Air Flak Vehicle",
	armzeus = "Assault Bot",
	chicken1 = "Swarmer",
	chicken1b = "Swarmer",
	chicken1c = "Swarmer",
	chicken1d = "Swarmer",
	chicken1x = "Swarmer Assault",
	chicken1y = "Swarmer Assault",
	chicken1z = "Swarmer Assault",
	chicken2 = "Advanced Swarmer",
	chicken2b = "Apex Swarmer",
	chicken_dodo1 = "Chicken Bomb",
	chicken_dodo2 = "Chicken Bomb",
	chickena1 = "Assault",
	chickena1b = "Assault",
	chickena1c = "Assault",
	chickena2 = "Advanced Assault",
	chickena2b = "Advanced Assault",
	chickenc1 = "All-Terrain Assault",
	chickenc2 = "All-Terrain Assault",
	chickenc3 = "All-Terrain Swarmer",
	chickenc3b = "All-Terrain Swarmer",
	chickenc3c = "All-Terrain Swarmer",
	chickend1 = "Defense",
	chickenf1 = "Flying Chicken Bomber",
	chickenf1b = "Flying Chicken Bomber",
	chickenf2 = "Flying Chicken Scout",
	chickenh1 = "Chicken Healer",
	chickenh1b = "Chicken Healer",
	chickenh2 = "Chicken Spawner",
	chickenh3 = "Progenitor Hatchling",
	chickenh4 = "Hatchling Swarmer",
	chickenh5 = "Chicken Overseer",
	chickenp1 = "Chicken Flamer",
	chickenr1 = "Artillery",
	chickenr2 = "Chicken Assault",
	chickenr3 = "Meteor Launcher",
	chickens1 = "Spike Spitter",
	chickens2 = "Ghost Spiker",
	chickens3 = "Spiker Air Assault",
	chickenw1 = "Flying Spike Spitter",
	chickenw1b = "Flying Spike Spitter",
	chickenw1c = "Flying Spike Spitter",
	chickenw1d = "Flying Spike Spitter",
	chickenw2 = "Fighter",
	coraak = "Heavy Amphibious Anti-Air Bot",
	coraap = "Produces Level 2 Aircraft",
	coraca = "Tech Level 2",
	corack = "Tech Level 2",
	coracsub = "Tech Level 2",
	coracv = "Tech Level 2",
	coradvsol = "Produces 75 Energy",
	corafus = "Produces 3000 Energy (Hazardous)",
	corageo = "Produces 1250 Energy (Hazardous)",
	corah = "Anti-Air Hovercraft",
	corak = "Fast Infantry Bot",
	coralab = "Produces Level 2 Bots",
	coramph = "Amphibious Bot",
	coramsub = "Produces Amphibious/Underwater Units",
	corap = "Produces Level 1 Aircraft",
	corape = "Gunship",
	corapt3 = "Produces Level 3 Aircraft",
	corarad = "Long-Range Radar",
	corarch = "Anti-Air Ship",
	corason = "Extended Sonar",
	corasp = "Automatically Repairs Aircraft",
	corasy = "Produces Level 2 Ships",
	coratl = "Advanced Torpedo Launcher",
	coravp = "Produces Level 2 Vehicles",
	corawac = "Radar/Sonar Plane",
	corban = "Heavy Missile Tank",
	corbats = "Battleship",
	corbhmth = "Geothermal Plasma Battery",
	corblackhy = "Flagship",
	corbuzz = "Rapid-Fire Long-Range Plasma Cannon",
	corbw = "Light Paralyzer Drone",
	corca = "Tech Level 1",
	corcan = "Armored Assault Bot",
	corcarry = "Aircraft Carrier with Anti-Nuke",
	corcat = "Heavy Rocket Bot",
	corch = "Tech Level 1",
	corck = "Tech Level 1",
	corcom = "Commander",
	corcomboss = "Oh s##t we are so dead",
	corcrash = "Amphibious Anti-air Bot",
	corcrus = "Cruiser",
	corcrw = "Flying Fortress",
	corcrwt4 = "Well, it's Krow, but stronger.",
	corcs = "Tech Level 1",
	corcsa = "Tech Level 1",
	corcut = "Seaplane Gunship",
	corcv = "Tech Level 1",
	cordecom = "Decoy Commander",
	cordemont4 = "All-Terrain BRRRRRT Mech",
	cordl = "Coastal Torpedo Launcher",
	cordoom = "Energy Weapon",
	cordrag = "Dragons Teeth",
	corenaa = "Anti-Air Flak Gun - Naval Series",
	corerad = "Bomb-Resistant Medium-Range Anti-Air Missile Battery",
	corestor = "Increases Energy Storage (6000)",
	coresupp = "Fast Assault Corvette",
	coreter = "Radar Jammer Vehicle",
	corexp = "Armed Metal Extractor",
	coreyes = "Perimeter Camera",
	corfast = "Combat Engineer",
	corfatf = "Enhanced Radar Targeting",
	corfav = "Light Scout Vehicle",
	corfblackhyt4 = "Flagship with Vtol thrusters... wait what?",
	corfdrag = "Shark's Teeth",
	corfgate = "Floating Plasma Deflector",
	corfhlt = "Floating Heavy Laser Tower",
	corfhp = "Builds Hovercraft",
	corfink = "Scout",
	corflak = "Anti-Air Flak Gun",
	corfmd = "Anti-Nuke System",
	corfmine3 = "Heavy Mine, Naval Series",
	corfmkr = "Converts 70 energy into 1.1 metal per sec",
	corfort = "Perimeter Defense",
	corfrad = "Early Warning System",
	corfrock = "Floating Anti-Air Missile Battery",
	corfrt = "Floating Anti-air Tower",
	corfus = "Produces 1100 Energy",
	corgant = "Produces Level 3 Units",
	corgantuw = "Produces Large Amphibious Units",
	corgarp = "Light Amphibious Tank",
	corgate = "Plasma Deflector",
	corgator = "Light Tank",
	corgatreap = "Heavy Assault Tank",
	corgeo = "Produces 300 Energy",
	corgol = "Very Heavy Assault Tank",
	corgolt4 = "Goliath, but bigger.",
	corgplat = "Light Plasma Defense",
	corhal = "Assault Hovertank",
	corhllt = "Anti-Swarm Double LLT. Transportable (Heavy)",
	corhlt = "Heavy Laser Tower",
	corhp = "Builds Hovercraft",
	corhrk = "Heavy Rocket Bot",
	corhunt = "Advanced Radar/Sonar Plane",
	corhurc = "Heavy Strategic Bomber",
	corint = "Long Range Plasma Cannon",
	corintr = "Amphibious Heavy Assault Transport",
	corjamt = "Short-Range Jamming Device",
	corjugg = "(barely) Mobile Heavy Turret",
	corjuno = "Anti Radar/Jammer/Minefield/ScoutSpam Weapon",
	corkarg = "All-Terrain Assault Mech",
	corkarganetht4 = "All-Terrain Assault Mech",
	corkorg = "Experimental Assault Bot",
	corlab = "Produces Level 1 Bots",
	corlevlr = "Riot Tank",
	corllt = "Light Laser Tower. Transportable (Heavy)",
	cormabm = "Mobile Anti-Nuke",
	cormadsam = "Hardened Anti-Air Missile Battery",
	cormakr = "Converts 70 energy into 1 metal per sec",
	cormando = "Stealthy Paratrooper K-bot",
	cormart = "Mobile Artillery",
	cormaw = "Pop-up Flamethrower Turret",
	cormex = "Extracts Metal from Metalspots",
	cormexp = "Armed Moho Metal Extractor",
	cormh = "Hovercraft Rocket Launcher",
	cormine1 = "Light Mine",
	cormine2 = "Medium Mine",
	cormine3 = "Heavy Mine",
	cormine4 = "Medium Mine",
	cormist = "Missile Truck",
	cormls = "Naval Engineer",
	cormlv = "Stealthy Minelayer/Minesweeper",
	cormmkr = "Converts 600 energy into 10.3 metal per sec",
	cormoho = "Advanced Metal Extractor / Storage",
	cormort = "Mobile Mortar Bot",
	cormship = "Cruise Missile Ship",
	cormstor = "Increases Metal Storage (3000)",
	cormuskrat = "Amphibious Construction Vehicle",
	cornanotc = "Assist & Repair in large radius. Transportable",
	cornanotcplat = "Repairs and builds in large radius",
	cornecro = "Stealthy Rez/Reclaim/Repair Bot",
	corparrow = "Very Heavy Amphibious Tank",
	corplat = "Builds Seaplanes",
	corpship = "Assault Frigate",
	corpt = "Patrol Boat/Light Anti Air/Sonar",
	corptl = "Pop-up Torpedo Launcher",
	corpun = "Coastal Defense",
	corpyro = "Fast Assault Bot",
	corrad = "Early Warning System. Transportable (Heavy)",
	corraid = "Medium Assault Tank",
	correap = "Heavy Assault Tank",
	correcl = "Ressurection Sub",
	corrl = "Light Anti-air Tower. Transportable (Heavy)",
	corroach = "Amphibious Crawling Bomb",
	corroy = "Destroyer",
	corsb = "Seaplane Bomber",
	corscreamer = "Long Range Anti-Air Tower",
	corsd = "Intrusion Countermeasure System",
	corseah = "Assault Heavy Transport",
	corseal = "Medium Amphibious Tank",
	corseap = "Torpedo Gunship",
	corsent = "Anti-Air Flak Vehicle",
	corsfig = "Seaplane Swarmer",
	corsh = "Fast Attack Hovercraft",
	corshad = "Bomber",
	corshark = "Submarine Killer",
	corsharkold = "Submarine Killer",
	corshiva = "Amphibious Siege Mech",
	corshroud = "Long-Range Jamming Tower",
	corsilo = "Nuclear ICBM Launcher",
	corsjam = "Radar Jammer Ship",
	corsktl = "Advanced Amphibious Crawling Bomb",
	corsnap = "Hovertank",
	corsok = "Heavy Laser Hovertank",
	corsolar = "Produces 20 Energy",
	corsonar = "Locates Water Units",
	corspec = "Radar Jammer Bot",
	corspy = "Radar-Invisible Spy Bot",
	corssub = "Long-Range Battle Submarine",
	corssubold = "Battle Submarine",
	corstone = "Commander Tombstone",
	corstorm = "Rocket Bot - good vs. static defenses",
	corsub = "Submarine",
	corsumo = "Heavily Armored Assault Bot",
	corsy = "Produces Level 1 Ships",
	cortarg = "Enhanced Radar Targeting, more facilities enhance accuracy",
	cortermite = "Heavy All-terrain Assault Spider",
	corthovr = "Heavy Transport Hovercraft",
	corthud = "Light Plasma Bot",
	cortide = "Produces Energy (depends on map)",
	cortitan = "Torpedo Bomber",
	cortl = "Offshore Torpedo Launcher",
	cortoast = "Coastal Defense",
	cortrem = "Heavy Artillery Vehicle",
	cortron = "Tactical Nuke Launcher",
	cortship = "Armored Transport Ship",
	coruwadves = "Increases Energy Storage (40000)",
	coruwadvms = "Increases Metal Storage (10000)",
	coruwes = "Increases Energy Storage (6000)",
	coruwfus = "Produces 1220 Energy",
	coruwmex = "Extracts Metal",
	coruwmme = "Advanced Metal Extractor / Storage",
	coruwmmm = "Converts 650 energy into 11 metal per sec",
	coruwms = "Increases Metal Storage (3000)",
	corvalk = "Air Transport",
	corvamp = "Stealth Fighter",
	corveng = "Fighter",
	corvipe = "Pop-up Sabot Battery",
	corvoyr = "Radar Bot",
	corvp = "Produces Level 1 Vehicles",
	corvrad = "Radar Vehicle",
	corvroc = "Stealthy Rocket Launcher",
	corwin = "Produces Energy. Depends on wind strength.",
	corwolv = "Light Mobile Artillery",
	e_chickenq = "Clucking Hell! (Easy)",
	epic_chickenq = "Clucking Hell!",
	h_chickenq = "Clucking Hell! (Hard)",
	n_chickenq = "Clucking Hell!",
	roost = "Spawns Chicken",
	ve_chickenq = "Clucking Hell! (Very Easy)",
	vh_chickenq = "Clucking Hell! (Very Hard)"
}