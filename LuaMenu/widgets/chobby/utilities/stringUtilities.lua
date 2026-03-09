
StringUtilities = StringUtilities or {}

function StringUtilities.GetTruncatedString(myString, myFont, maxLength)
    if (not maxLength) then
        return myString
    end
    if myFont:GetTextWidth(myString) <= maxLength then
        return myString
    end
    -- Binary search for the longest prefix that fits
    local lo, hi = 0, string.len(myString)
    local sub = string.sub
    while lo < hi do
        local mid = lo + math.floor((hi - lo + 1) / 2)
        if myFont:GetTextWidth(sub(myString, 1, mid)) <= maxLength then
            lo = mid
        else
            hi = mid - 1
        end
    end
    if lo < 1 then
        return ""
    end
    return sub(myString, 1, lo)
end

function StringUtilities.GetTruncatedStringWithDotDot(myString, myFont, maxLength)
	if (not maxLength) or (myFont:GetTextWidth(myString) <= maxLength) then
		return myString
	end
	local dotDotWidth = myFont:GetTextWidth("..")
	local truncation = StringUtilities.GetTruncatedString(myString, myFont, maxLength - dotDotWidth)
	return truncation .. ".."
end

function StringUtilities.TruncateStringIfRequired(myString, myFont, maxLength)
	if (not maxLength) or (myFont:GetTextWidth(myString) <= maxLength) then
		return false
	end
	return StringUtilities.GetTruncatedString(myString, myFont, maxLength)
end

function StringUtilities.TruncateStringIfRequiredAndDotDot(myString, myFont, maxLength)
	if (not maxLength) or (myFont:GetTextWidth(myString) <= maxLength) then
		return false
	end
	return StringUtilities.GetTruncatedStringWithDotDot(myString, myFont, maxLength)
end

function string.starts(String,Start)
	return string.sub(String,1,string.len(Start))==Start
end

function string.ends(String,End)
	return End=='' or string.sub(String,-string.len(End))==End
end

function string.trim(str)
	return str:match'^()%s*$' and '' or str:match'^%s*(.*%S)'
end
