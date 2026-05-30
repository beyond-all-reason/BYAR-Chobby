
Spring.Utilities = Spring.Utilities or {}

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Date formats are insane

-- Leap seconds are ignored.
-- Daylight savings is not handled and needs to be eradicated.

local function IsLeapYear(year)
	return year%4 == 0 and (year%100 ~= 0 or year%400 == 0)
end

local function DaysInAYear(year)
	return IsLeapYear(year) and 366 or 365
end

local base = {60, 60, 24}

local monthDays = {
	[1] = 31,
	[2] = 28,
	[3] = 31,
	[4] = 30,
	[5] = 31,
	[6] = 30,
	[7] = 31,
	[8] = 31,
	[9] = 30,
	[10] = 31,
	[11] = 30,
	[12] = 31,
}

local baseName = {
	"second",
	"minute",
	"hour",
	"day",
}

local monthsInEveryYear = 12

local sumMonthDays = {}
for i = 1, #monthDays do
	sumMonthDays[i] = (sumMonthDays[i-1] or 0) + (monthDays[i - 1] or 0)
end

local function MonthToDays(timeTable)
	local days = sumMonthDays[timeTable[5]]
	if timeTable[5] > 2 and IsLeapYear(timeTable[6]) then
		days = days + 1
	end
	return days
end

local function FixTimeOutOfBounds(timeTable)
	-- Seconds, Minutes and Hours are relatively well behaved.
	for i = 1, 3 do
		while timeTable[i] < 0 do
			timeTable[i] = timeTable[i] + base[i]
			timeTable[i + 1] = timeTable[i + 1] - 1
		end
		while timeTable[i] >= base[i] do
			timeTable[i] = timeTable[i] - base[i]
			timeTable[i + 1] = timeTable[i + 1] + 1
		end
	end

	repeat
		local updated = false
		-- Overflow
		local daysInThisMonth = monthDays[timeTable[5]] or 31
		if timeTable[5] == 2 and IsLeapYear(timeTable[6]) then
			daysInThisMonth = 29
		end

		if timeTable[4] > daysInThisMonth then -- Some bases are one index and some are zero indexed FFS!!
			timeTable[4] = timeTable[4] - daysInThisMonth
			timeTable[5] = timeTable[5] + 1
			updated = true
		end
		if timeTable[5] > monthsInEveryYear then
			timeTable[5] = timeTable[5] - monthsInEveryYear
			timeTable[6] = timeTable[6] + 1
			updated = true
		end

		-- Underflow
		local daysInLastMonth = monthDays[(timeTable[5] - 2)%12 + 1] or 31
		if timeTable[4] < 1 then
			timeTable[4] = timeTable[4] + daysInLastMonth
			timeTable[5] = timeTable[5] - 1
			updated = true
		end
		if timeTable[5] < 1 then
			timeTable[5] = timeTable[5] + monthsInEveryYear
			timeTable[6] = timeTable[6] - 1
			updated = true
		end
	until (not updated)

	return timeTable
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Utilities

function Spring.Utilities.FormatTime(seconds, includeSeconds)
	if seconds < 0 then
		return (includeSeconds and "0s") or "0m"
	end

	local hours = math.floor(seconds/3600)
	local minutes = math.floor(seconds/60)%60
	local seconds = math.floor(seconds)%60

	--Spring.Echo("pastTime", pastTime[1], pastTime[2], pastTime[3], pastTime[4], "pastSeconds", pastSeconds)
	--Spring.Echo("currentTime", currentTime[1], currentTime[2], currentTime[3], currentTime[4], "currentSeconds", currentSeconds)
	--Spring.Echo("seconds", seconds)

	local timeText = ""
	if hours > 0 then
		timeText = timeText .. hours .. "h "
	end
	if hours > 0 or minutes > 0 or (not includeSeconds) then
		timeText = timeText .. minutes .. "m "
	end
	if includeSeconds then
		timeText = timeText .. seconds .. "s "
	end

	return timeText
end

function Spring.Utilities.ArchaicFormatDate(timeTable, translator)
	if not timeTable then
		return false
	end

	local daySuffix
	if timeTable[4]%10 == 1 and timeTable[4]%100 ~= 11 then
		daySuffix = "st"
	elseif timeTable[4]%10 == 2 and timeTable[4]%100 ~= 12 then
		daySuffix = "nd"
	elseif timeTable[4]%10 == 3 and timeTable[4]%100 ~= 13 then
		daySuffix = "rd"
	else
		daySuffix = "th"
	end

	local timeSuffix = (timeTable[3] < 12 and "AM") or "PM"
	local hour = (timeTable[3] - 1)%12 + 1

	local stringToFormat = "%d" .. daySuffix .. " of " .. translator("month_" .. timeTable[5]) .. " at " .. "%d:%02d " .. timeSuffix
	local timeString = string.format(stringToFormat, timeTable[4], hour, timeTable[2])
	return timeString
end

function Spring.Utilities.FormatRelativeTime(timeTable)
	local timeText
	for i = 4, 2, -1 do
		if timeText or timeTable[i] > 0 then
			timeText = string.format((timeText or "") .. (timeText and ", " or "") .. "%d" .. " " .. baseName[i] .. (timeTable[i] == 1 and "" or "s"), timeTable[i])
		end
	end
	if not timeText then
		return "now", true
	end
	return timeText
end

function Spring.Utilities.GetTimeToPast(pastTimeString, includeSeconds)
	if (not pastTimeString) or (type(pastTimeString) ~= "string") then
		return "??"
	end

	-- Example: 2016-07-21T14:49:00.4731696Z
	local pastTime = {
		string.sub(pastTimeString, 18, 19),
		string.sub(pastTimeString, 15, 16),
		string.sub(pastTimeString, 12, 13),
		string.sub(pastTimeString, 9, 10),
		--string.sub(pastTimeString, 6, 7),
		--string.sub(pastTimeString, 0, 4),
	}

	for i = 1, #pastTime do
		pastTime[i] = tonumber(pastTime[i])
		if not pastTime[i] then
			return "??"
		end
	end

	local utcNow = os.date("!*t")
	local currentTime = {
		utcNow.sec,
		utcNow.min,
		utcNow.hour,
		utcNow.day,
		--utcNow.month,
		--utcNow.year,
	}

	local pastSeconds = pastTime[1] + 60*(pastTime[2] + 60*pastTime[3])
	local currentSeconds = currentTime[1] + 60*(currentTime[2] + 60*currentTime[3])
	if currentTime[4] ~= pastTime[4] then
		-- Always assume that the past time is one day behind.
		currentSeconds = currentSeconds + 86400
	end

	return Spring.Utilities.FormatTime(currentSeconds - pastSeconds, includeSeconds)
end

function Spring.Utilities.GetTimeDifferenceTable(targetTime, currentTime)
	if not targetTime then
		return false
	end
	if not currentTime then
		local utcNow = os.date("!*t")
		currentTime = {
			utcNow.sec,  -- Second
			utcNow.min,  -- Minute
			utcNow.hour, -- Hour
			utcNow.day,  -- Day
			utcNow.month, -- Month
			utcNow.year, -- Year
		}
	end

	for i = 1, #targetTime do
		if not (targetTime[i] and currentTime[i]) then
			return false
		end
	end

	-- Order times.
	local before, after = currentTime, targetTime

	local targetInTheFuture = true
	for i = 6, 1, -1 do
		if before[i] ~= after[i] then
			if before[i] > after[i] then
				before, after = after, before
				targetInTheFuture = false
			end
			break
		end
	end

	-- Add days based on year difference.
	local year = before[6]
	while before[6] < after[6] do
		after[4] = after[4] + DaysInAYear(before[6])
		before[6] = before[6] + 1
	end

	-- Convert month to day.
	before[4] = before[4] + MonthToDays(before)
	after[4] = after[4] + MonthToDays(after)

	-- Clear year and month now that conversion to day is complete.
	after[5] = 0
	after[6] = 0

	-- Do subtraction with unbounded days.
	for i = 1, 4 do
		after[i] = after[i] - before[i]
		while base[i] and after[i] < 0 do
			after[i] = after[i] + base[i]
			after[i + 1] = after[i + 1] - 1
		end
	end

	return after, targetInTheFuture
end

function Spring.Utilities.TimeToSeconds(timeTable)
	if not timeTable then
		return
	end
	timeTable[3] = timeTable[3] + timeTable[4]*24
	timeTable[2] = timeTable[2] + timeTable[3]*60
	timeTable[1] = timeTable[1] + timeTable[2]*60
	return timeTable[1]
end

function Spring.Utilities.TimeStringToTable(timeString)
	if (not timeString) or (type(timeString) ~= "string") then
		return false
	end

	-- Example: 2016-07-21T14:49:00.4731696Z
	local timeTable = {
		string.sub(timeString, 18, 19), -- Second
		string.sub(timeString, 15, 16), -- Minute
		string.sub(timeString, 12, 13), -- Hour
		string.sub(timeString, 9, 10),  -- Day
		string.sub(timeString, 6, 7),   -- Month
		string.sub(timeString, 0, 4),   -- Year
	}

	for i = 1, #timeTable do
		timeTable[i] = tonumber(timeTable[i])
		if not timeTable[i] then
			return false
		end
	end

	return timeTable
end

function Spring.Utilities.GetTimeDifference(targetTimeString, otherTime)
	local targetTime = Spring.Utilities.TimeStringToTable(targetTimeString)
	if not targetTime then
		return false
	end
	if otherTime then
		otherTime = Spring.Utilities.TimeStringToTable(otherTime)
	end

	local difference, targetInTheFuture = Spring.Utilities.GetTimeDifferenceTable(targetTime, otherTime)
	local timeText, isNow = Spring.Utilities.FormatRelativeTime(difference, targetInTheFuture)
	return timeText, targetInTheFuture, isNow
end

function Spring.Utilities.UtcToLocal(utcTimeString)
	local localNow = os.date("*t")
	local localTime = {
		localNow.sec,  -- Second
		localNow.min,  -- Minute
		localNow.hour, -- Hour
		localNow.day,  -- Day
		localNow.month, -- Month
		localNow.year, -- Year
	}

	for i = 1, #localTime do
		if not localTime[i] then
			return false
		end
	end

	local utcTime = Spring.Utilities.TimeStringToTable(utcTimeString)
	if not utcTime then
		return false
	end

	local difference, localInTheFuture = Spring.Utilities.GetTimeDifferenceTable(localTime)
	if not difference then
		return
	end

	if localInTheFuture then
		for i = 1, 6 do
			utcTime[i] = utcTime[i] + difference[i]
		end
	else
		for i = 1, 6 do
			utcTime[i] = utcTime[i] - difference[i]
		end
	end

	return FixTimeOutOfBounds(utcTime)
end

function Spring.Utilities.ArchaicUtcToLocal(utcTimeString, translator)
	return Spring.Utilities.ArchaicFormatDate(Spring.Utilities.UtcToLocal(utcTimeString), translator)
end

function Spring.Utilities.GetCurrentUtc()
	local t = os.date("!*t")
	return string.format("%04d-%02d-%02dT%02d:%02d:%02d", t.year, t.month, t.day, t.hour, t.min, t.sec)
end

function Spring.Utilities.GetCompactCurrentUtc()
	local t = os.date("!*t")
	return string.format("%04d%02d%02d_%02d%02d%02d", t.year, t.month, t.day, t.hour, t.min, t.sec)
end
