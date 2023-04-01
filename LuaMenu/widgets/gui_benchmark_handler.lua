--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Benchmark Handler",
		desc      = "Handles running and reporting benchmarks.",
		author    = "GoogleFrog",
		date      = "3 November 2018",
		license   = "GNU LGPL, v2.1 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utilities

local function UploadBenchmarkFile(config, dataFilePath)
	local dataFile = io.open(dataFilePath, "r")
	local playerName = WG.Chobby.Configuration:GetPlayerName()
	local output = "Benchmark by " .. playerName .. "\n```"
	local sortedLines = {}
	local topLine
	local line = dataFile:read()
	while line do
		if topLine then
			sortedLines[#sortedLines + 1] = line
		else
			topLine = line
		end
		line = dataFile:read()
	end

	table.sort(sortedLines)

	Spring.Echo(topLine or "no top line")
	output = output .. playerName .. (topLine or ",no top line") .. "```\n```"
	for i = 1, #sortedLines do
		Spring.Echo(sortedLines[i])
		output = output .. sortedLines[i] .. "```\n```"
	end

	WG.WrapperLoopback.SendBugReport(config.name, output)
end

local function GetIdentityPermutation(n)
	local perm = {}
	for i = 1, n do
		perm[i] = i
	end
	return perm
end

local function GetRandomPermutation(n)
	local perm = GetIdentityPermutation(n)
	for i = 1, n - 1 do
		local swap = i + math.floor(math.random()*(n - i + 1))
		perm[i], perm[swap] = perm[swap], perm[i]
	end
	return perm
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Running the benchmark

local function RunBenchmark(config)
	local dataFilePath = "benchmarks/" .. Spring.Utilities.GetCompactCurrentUtc() .. "_dataFile.csv"
	local aborted = false
	local function CancelFunc()
		aborted = true
	end

	WG.BattleRoomWindow.LeaveBattle()
	WG.LibLobby.lobby:LeaveMatchMakingAll()

	local duplicates = config.duplicates or 1
	local runTypes = (#config.runs)
	local totalRuns = runTypes * duplicates

	local perm = (config.fixedOrder and GetIdentityPermutation(totalRuns)) or GetRandomPermutation(totalRuns)

	local function DownloadsComplete()
		WG.Chobby.InformationPopup("Running the benchmark. It may take a few minutes to launch each test case. Zero-K will close when the benchmark is complete. Submit the result by allowing the upload of an automated crash report.", {caption = "Abort", closeFunc = CancelFunc, buttonClass = "negative_button", width = 524, height = 260})

		local runData = config.runs
		local dataFile = io.open(dataFilePath, "w")
		dataFile:write(config.topRow)
		dataFile:close()

		local index = 1
		local realIndex, realName = 1, 1
		local RunNext, CheckNextRun

		function RunNext()
			if aborted then
				return
			end
			realIndex = perm[index]%runTypes + 1
			realName = runData[realIndex].runName .. " r" .. index

			local settings = runData[realIndex].settings
			settings = settings .. "\nbenchmark_file_name = " .. dataFilePath
			settings = settings .. "\nbenchmark_run_name = " .. realName

			local params = {
				StartDemoName = runData[realIndex].file,
				Engine = runData[realIndex].engine,
				SpringSettings = settings,
			}
			WG.WrapperLoopback.StartNewSpring(params)
		end

		function CheckNextRun()
			if aborted then
				return
			end
			dataFile = io.open(dataFilePath, "r")
			local fileString = dataFile:read("*a")
			dataFile:close()
			if fileString:find(realName) then
				-- The delay is to give Spring time to close
				index = index + 1
				realIndex = perm[index%runTypes + 1]
				if index <= totalRuns then
					WG.Delay(RunNext, 4)
				else
					UploadBenchmarkFile(config, dataFilePath)
					return
				end
			end
			WG.Delay(CheckNextRun, 5)
		end

		RunNext()
		WG.Delay(CheckNextRun, 5)
	end

	if WG.SteamCoopHandler.CheckDownloads(config.game, config.map, DownloadsComplete, config.gameList) then
		DownloadsComplete()
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Controls

local function InitializeControls(parentControl)
	local Configuration = WG.Chobby.Configuration

	Label:New {
		x = 15,
		y = 11,
		width = 180,
		height = 30,
		parent = parentControl,
		font = Configuration:GetFont(3),
		caption = "Benchmarker",
	}

	Button:New {
		right = 11,
		y = 7,
		width = 80,
		height = 45,
		font = Configuration:GetFont(3),
		caption = i18n("close"),
		classname = "negative_button",
		OnClick = {
			function()
				parentControl:Hide()
			end
		},
		parent = parentControl,
	}

	local benchmarkData = VFS.Include("benchmarks/config.lua")

	local offset = 70

	for i = 1, #benchmarkData do
		Button:New {
			x = 10,
			width = 180,
			y = offset,
			height = 50,
			caption = benchmarkData[i].humanName,
			font = Configuration:GetFont(3),
			classname = "action_button",
			OnClick = {
				function()
					benchmarkData = VFS.Include("benchmarks/config.lua")
					RunBenchmark(benchmarkData[i])
				end
			},
			parent = parentControl,
		}

		TextBox:New {
			x = 200,
			right = 15,
			y = offset + 6,
			height = 70,
			font = Configuration:GetFont(3),
			text = benchmarkData[i].decription,
			parent = parentControl,
		}
		offset = offset + 90
	end

	if VFS.HasArchive("Zero-K $VERSION") then
		Button:New {
			x = "35%",
			right = "35%",
			y = offset,
			height = 80,
			caption = "Generate Script",
			tooltip = "Generates a startscript from luamenu/startscripts/config.lua.",
			font = Configuration:GetFont(4),
			classname = "action_button",
			OnClick = {
				function()
					local scriptFile = VFS.Include("luamenu/startscripts/config.lua")
					if scriptFile then
						WG.ScriptGenerator.GenerateScript(scriptFile)
					else
						WG.Chobby.InformationPopup("Missing file luamenu/startscripts/config.lua.", {width = 380, height = 220})
					end
				end
			},
			parent = parentControl,
		}
		offset = offset + 90
	end

	-- No external functions as yet.
	--local externalFunctions = {}
	--return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- External Functions
local BenchmarkHandler = {}

function BenchmarkHandler.GetControl()
	local window = Control:New {
		name = "benchmarkHandler",
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		padding = {0, 0, 0, 0},
		OnParent = {
			function(obj)
				if obj:IsEmpty() then
					InitializeControls(obj)
				end
			end
		},
	}
	return window
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

function widget:Initialize()
	CHOBBY_DIR = LUA_DIRNAME .. "widgets/chobby/"
	VFS.Include(LUA_DIRNAME .. "widgets/chobby/headers/exports.lua", nil, VFS.RAW_FIRST)

	WG.BenchmarkHandler = BenchmarkHandler
end
