--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Mission Progress Handler",
		desc      = "Stores which missions have been completed.",
		author    = "GoogleFrog",
		date      = "20 November 2017",
		license   = "GNU LGPL, v2.1 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local progressData = {}
local MISSION_COMPLETE_STRING = "mission_complete_"

function widget:RecvLuaMsg(msg)
	if string.find(msg, MISSION_COMPLETE_STRING) then
		local missionName = string.sub(msg, string.len(MISSION_COMPLETE_STRING) + 1)
		progressData[missionName] = true
	end
end

local externalFunctions = {}
function externalFunctions.GetMissionCompletion(name)
	progressData[name] = true
end

function widget:Initialize()
	WG.MissionProgress = externalFunctions
end

function widget:GetConfigData()
	return {
		progress = progressData,
	}
end

function widget:SetConfigData(data)
	progressData = data.progress or {}
end
