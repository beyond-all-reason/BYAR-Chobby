
function widget:GetInfo()
	return {
		name = "Cursor scaler",
		desc = "auto sets a scale for the cursor based on screen resolution" ,
		author = "Floris",
		date = "",
		license = "",
		layer = 1,
		enabled = true
	}
end

local Settings = {}
Settings['cursorSet'] = 'icexuick'
Settings['cursorSize'] = 100

function split(inputstr, sep)
	sep = sep or '%s'
	local t = {}
	for field, s in string.gmatch(inputstr, "([^"..sep.."]*)("..sep.."?)") do
		table.insert(t,field)
		if s == "" then
			return t
		end
	end
end

-- note: first entry should be icons inside base /anims folder
local cursorSets = {}
for k, subdir in pairs(VFS.SubDirs('anims')) do
	local set = string.gsub(string.sub(subdir, 1, #subdir-1), 'anims/', '')	-- game anims folder
	set = string.gsub(string.sub(set, 1, #subdir), 'anims\\', '')	-- spring anims folder
	local subdirSplit = split(set, '_')
	if cursorSets[subdirSplit[1]] == nil then
		cursorSets[subdirSplit[1]] = {}
	end
	cursorSets[subdirSplit[1]][#cursorSets[subdirSplit[1]]+1] = subdirSplit[2]
end

function NearestValue(table, number)
	local smallestSoFar, smallestIndex
	for i, y in ipairs(table) do
		if not smallestSoFar or (math.abs(number-y) < smallestSoFar) then
			smallestSoFar = math.abs(number-y)
			smallestIndex = i
		end
	end
	return smallestIndex, table[smallestIndex]
end

function widget:ViewResize()
	local ssx,ssy = Spring.GetScreenGeometry()
	autoCursorSize = 100 * (0.6 + (ssx*ssy / 10000000)) * Spring.GetConfigFloat('cursorsize', 1)
	SetCursor(Settings['cursorSet'])
end

function widget:Initialize()
	widget:ViewResize()
end

function SetCursor(cursorSet)
	Settings['cursorSet'] = cursorSet
	Settings['cursorSize'] = cursorSets[cursorSet][NearestValue(cursorSets[cursorSet], autoCursorSize)]
	cursorSet = cursorSet..'_'..Settings['cursorSize']
	local files = VFS.DirList("anims/"..cursorSet.."/")
	for i=1, #files do
		local fileName = files[i]
		if string.find(fileName, "_0.") then
			local cursorName = string.sub(fileName, string.len("anims/"..cursorSet.."/")+1, string.find(fileName, "_0.") -1)
			Spring.ReplaceMouseCursor(cursorName, cursorSet..'/'..cursorName, (cursorName == 'cursornormal'))
		end
	end
end
