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

-- Polygon data source is pending: maps-metadata#615 needs to ship polygon
-- payloads through the existing rect-sync pipeline (or an equivalent), at
-- which point a loader exposed under the same `loadPolygonStartboxes` key on
-- the module's return table will repopulate polygonConfig in the lobbyEntry
-- shape the renderer and encoder below expect. Until that lands, the call
-- sites in interface_skirmish.lua and gui_battle_room_window.lua guard on
-- the function's presence and the polygon path stays dormant.

local function makeAllyTeamBoxFromPolygon(polygonConfig, allyteamindex)
  -- The engine only understands AABB startrects, so we publish each polygon's
  -- bounding box here. The game-side gadget reads the full polygon from the
  -- mapmetadata_startboxes_set modoption (see encodeStartboxesSetModoption)
  -- and applies polygon containment on top, widening the engine AABB if
  -- needed via Spring.SetAllyTeamStartBox.
  local allyteamtable = { numallies = 0 }
  local entry = polygonConfig[allyteamindex + 1]
  if entry and entry.boundingBox then
    local bb = entry.boundingBox
    allyteamtable.startrectleft   = bb.left / 200
    allyteamtable.startrecttop    = bb.top / 200
    allyteamtable.startrectright  = bb.right / 200
    allyteamtable.startrectbottom = bb.bottom / 200
  end
  return allyteamtable
end

-- Builds the mapmetadata_startboxes_set modoption value for the game-side
-- gadget to consume. Shape matches the maps-metadata-native startboxesInfo
-- (one startboxesInfo per num_teams key), base64url(zlib(json))-encoded to
-- match the existing mapmetadata_startpos transport.
--
-- The game-side contract (resolution order, expected payload shape) lives in
-- beyond-all-reason/Beyond-All-Reason:
--   luarules/gadgets/include/startbox_utilities.lua
-- Any change here must keep that decoder/resolver in sync.
local function encodeStartboxesSetModoption(polygonConfig)
  if not polygonConfig then return nil end

  local sortedKeys = {}
  for k in pairs(polygonConfig) do
    sortedKeys[#sortedKeys + 1] = k
  end
  table.sort(sortedKeys)

  local numTeams = #sortedKeys
  if numTeams == 0 then return nil end

  local startboxes = {}
  for _, k in ipairs(sortedKeys) do
    local entry = polygonConfig[k]
    local sourcePoly = entry.anchorBoxes and entry.anchorBoxes[1] or entry.boxes and entry.boxes[1]
    local poly = {}
    if sourcePoly then
      for j, point in ipairs(sourcePoly) do
        local p = { x = point[1], y = point[2] }
        if point[3] ~= nil then p.strength = point[3] end
        poly[j] = p
      end
    end
    startboxes[#startboxes + 1] = { poly = poly }
  end

  local payload = {
    [tostring(numTeams)] = {
      startboxes = startboxes,
      maxPlayersPerStartbox = 8,
    },
  }

  local ok, encoded = pcall(Json.encode, payload)
  if not ok or not encoded then return nil end

  local compressed = VFS.ZlibCompress(encoded)
  if not compressed then return nil end

  return Spring.Utilities.Base64Encode(compressed)
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
  makeAllyTeamBoxFromPolygon = makeAllyTeamBoxFromPolygon,
  encodeStartboxesSetModoption = encodeStartboxesSetModoption,
  getBox = getBox,
  clearBoxes = clearBoxes,
  removeBox = removeBox,
  addBox = addBox,
  singleplayerboxes = singleplayerboxes,
}
