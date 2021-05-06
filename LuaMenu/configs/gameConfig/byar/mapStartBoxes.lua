local function pyPartition(s,p,left)
  if string.find(s,p,nil,true) then
    local startfind, endfind =  string.find(s,p,nil,true)
    if left then
      return string.sub(s,1,startfind-1)
    else
      return string.sub(s,endfind+1)
    end
  else
    return s
  end
end

local function lines(str)
  local t = {}
  local function helper(line) table.insert(t, line) return "" end
  helper((str:gsub("(.-)\r?\n", helper)))
  return t
end

function split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end


local function parseSpadsBoxLine(sbl)
    sbl = pyPartition(sbl,"#",true)
    if sbl == nil or sbl:len() < 10 then return nil end
    local mapName = pyPartition(sbl,".smf:",true) --Aberdeen3v3v3.smf
    local startdata = pyPartition(sbl,".smf:",false) --2|0 0 50 200;150 0 200 200
    local playercount = tonumber(pyPartition(startdata,"|",true))
    local boxes = {}
    local boxinfo = pyPartition(startdata,"|",false)
    for i,strbox in pairs(split(boxinfo, ";")) do
        boxes[i] = {}
        for j, position in pairs(split(strbox," ")) do
          boxes[i][j] = tonumber(position)/200.0
        end
    end
    return mapName, playercount, boxes
end

--parseSpadsBoxLine("Aetherian Void 1.7.smf:4|0 0 80 80;120 120 200 200;0 120 80 200;120 0 200 80\n") --this is a unit test

-- spads style boxen: 	!addBox <left> <top> <right> <bottom> [<teamNumber>] - adds a new start box (0,0 is top left corner, 200,200 is bottom right corner)
-- make a table for each mapname
local savedBoxesFilename = LUA_DIRNAME .. "configs/gameConfig/byar/savedBoxes.dat" --taken from spads
local savedBoxesSpads =  VFS.LoadFile(savedBoxesFilename)
local singleplayerboxes = {}

local savedBoxes = {}
local numBoxes = 0
if savedBoxesSpads then
	local fileLines = lines(savedBoxesSpads)
	for i, line in ipairs(fileLines) do
    local mapname, playercount, boxes = parseSpadsBoxLine(line)
    --Spring.Echo("Start boxes parsed for",mapname,boxes,line,#savedBoxes)
    if mapname ~= nil then
        numBoxes = numBoxes + 1
        if savedBoxes[mapname] then
          savedBoxes[mapname][playercount] = boxes

          --Spring.Echo("updated existing",#savedBoxes,#boxes,playercount)

          --table.insert(savedBoxes[mapname],boxes,playercount)
        else
          --table.insert(savedBoxes,{playercount = boxes},mapname)
          savedBoxes[mapname] = {}
          savedBoxes[mapname][playercount] = boxes

          --Spring.Echo("added new entry",#savedBoxes,#boxes,playercount)
        end
    end
  end
end


Spring.Log("mapStartBoxes",LOG.INFO,"Parsed ",numBoxes, " start boxes from",savedBoxesFilename)


-- rules for boxes selection:
-- if there is a box set of the number of allyteams, use that
-- if there is no box set for the number of allyteams, but there is one that is larger, then use that
-- if there is no box set for the number of allyteams, but there is one that is smaller, then use that and blank the rest

local function selectStartBoxesForAllyTeamCount(startboxes, allyteamcount)
  if startboxes == nil then return nil end
  local mystartboxes = nil
  local closestlarger = 10000
  local closestsmaller = 0
  for i, boxset in pairs(startboxes) do
    if i == allyteamcount then
      Spring.Log("mapStartBoxes",LOG.INFO,"Found exact boxset for allyteamcount ",allyteamcount)
      return boxset
    end
    if i > allyteamcount and i < closestlarger then
      closestlarger = i
    end
    if i < allyteamcount and i > closestsmaller then
      closestsmaller = i
    end
  end
  if closestlarger < 10000 then
    Spring.Log("mapStartBoxes",LOG.INFO,"Found larger boxset ",closestlarger ," for allyteamcount ",allyteamcount)
    return startboxes[closestlarger]
  end
  if closestsmaller > 0 then
    Spring.Echo("Found smaller boxset ",closestsmaller, " for allyteamcount", allyteamcount)
    return startboxes[closestsmaller]
  end
  return nil
end

local function makeAllyTeamBox(startboxes, allyteamindex)
    -- -- spads style boxen: 	!addBox <left> <top> <right> <bottom> [<teamNumber>] - adds a new start box (0,0 is top left corner, 200,200 is bottom right corner)
    --  startrectbottom=1;
    --  startrectleft=0;
    --  startrecttop=0.75;
    --  startrectright=1;
    local allyteamtable = {
        numallies = 0,
      }
    if startboxes and startboxes[allyteamindex + 1] then
      if startboxes[allyteamindex + 1].spadsSizes then
       local spadsSizes = startboxes[allyteamindex + 1].spadsSizes
       Spring.Echo("Skirmish: startbox for team:",allyteamindex, "is", spadsSizes.left, spadsSizes.top, spadsSizes.right, spadsSizes.bottom)
        allyteamtable = {
          numallies = 0,
          startrectleft  = spadsSizes.left/200,
          startrecttop   = spadsSizes.top/200,
          startrectright = spadsSizes.right/200,
          startrectbottom= spadsSizes.bottom/200,
        }
      else
        allyteamtable = {
          numallies = 0,
          startrectleft  = startboxes[allyteamindex + 1][1],
          startrecttop   = startboxes[allyteamindex + 1][2],
          startrectright = startboxes[allyteamindex + 1][3],
          startrectbottom= startboxes[allyteamindex + 1][4],
        }
      end
    end
    return allyteamtable
end

-- how about some more helpers?
local function initCustomBox(mapName)
    singleplayerboxes = {}
end

local function addBox(left,top, right, bottom, allyTeam) --in spads order
  initCustomBox()
  singleplayerboxes[allyTeam] = {left,top,right,bottom}
  -- if online then: function Interface:AddStartRect(allyNo, left, top, right, bottom)
end

local function removeBox(allyTeam)
  initCustomBox()
  if singleplayerboxes[allyTeam] then
    singleplayerboxes[allyTeam] = nil
  end
end

local function clearBoxes()
  initCustomBox()
  singleplayerboxes = {}
end

local function getBox(allyTeam)
  if savedBoxes[mapName] == nil then
    initCustomBox(mapName)
  end
  if singleplayerboxes then
    return singleplayerboxes[allyTeam]
  else
    local defaultboxes =  selectStartBoxesForAllyTeamCount(mapName,2)
    if defaultboxes then
      return defaultboxes[allyTeam]
    end
  end
  return nil
end

return {
  savedBoxes = savedBoxes,
  selectStartBoxesForAllyTeamCount = selectStartBoxesForAllyTeamCount,
  makeAllyTeamBox = makeAllyTeamBox,
  getBox = getBox,
  clearBoxes = clearBoxes,
  removeBox = removeBox,
  addBox = addBox,
  singleplayerboxes = singleplayerboxes,
}
