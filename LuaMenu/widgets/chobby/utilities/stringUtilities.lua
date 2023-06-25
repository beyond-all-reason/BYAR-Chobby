
StringUtilities = StringUtilities or {}

function StringUtilities.GetTruncatedString(myString, myFont, maxLength)
	if (not maxLength) then
		return myString
	end
	local length = string.len(myString)
	while myFont:GetTextWidth(myString) > maxLength do
		length = length - 1
		myString = string.sub(myString, 0, length)
		if length < 1 then
			return ""
		end
	end
	return myString
end

function StringUtilities.GetTruncatedStringWithDotDot(myString, myFont, maxLength)
	if (not maxLength) or (myFont:GetTextWidth(myString) <= maxLength) then
		return myString
	end
	local truncation = StringUtilities.GetTruncatedString(myString, myFont, maxLength)
	local dotDotWidth = myFont:GetTextWidth("..")
	truncation = StringUtilities.GetTruncatedString(truncation, myFont, maxLength - dotDotWidth)
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
