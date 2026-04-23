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

-- Polygon startbox loading from map archives
local polygonCache = {} -- cache keyed by mapName

local function clearPolygonCache()
  polygonCache = {}
end

local function getMapDimensionsFromMapDetails(mapName)
  -- mapDetails has Width/Height in spring map units (multiply by 512 for elmos)
  local mapDetails = nil
  if WG and WG.Chobby and WG.Chobby.Configuration and WG.Chobby.Configuration.gameConfig then
    mapDetails = WG.Chobby.Configuration.gameConfig.mapDetails
  end
  if not mapDetails then
    local ok, details = pcall(function()
      return VFS.Include(LUA_DIRNAME .. "configs/gameConfig/byar/mapDetails.lua")
    end)
    if ok and details then
      mapDetails = details
    end
  end
  if mapDetails and mapDetails[mapName] then
    local data = mapDetails[mapName]
    if data.Width and data.Height then
      return data.Width * 512, data.Height * 512
    end
  end
  return nil, nil
end

local function readInt32LE(data, offset)
  -- Read a 4-byte little-endian int32 from a string at 1-based offset
  local b1, b2, b3, b4 = string.byte(data, offset, offset + 3)
  if not b1 or not b4 then return nil end
  return b1 + b2 * 256 + b3 * 65536 + b4 * 16777216
end

local function loadPolygonStartboxes(mapName)
  if mapName == nil then return nil end

  -- Return cached result
  local cacheKey = tostring(mapName)
  if polygonCache[cacheKey] ~= nil then
    if polygonCache[cacheKey] == false then
      return nil
    end
    return polygonCache[cacheKey]
  end

  -- Check map archive for mapside config + SMF dimensions
  local rawConfig = nil
  local smfDimsX, smfDimsZ = nil, nil
  local mapArchiveAvailable = VFS.HasArchive(mapName)

  if mapArchiveAvailable then
    local mapAlreadyLoaded = false
    for _, archive in pairs(VFS.GetLoadedArchives()) do
      if archive == mapName then
        mapAlreadyLoaded = true
        break
      end
    end

    local loadFromMap = function()
      local result = { config = nil, smfDimsX = nil, smfDimsZ = nil }

      -- Load mapside polygon startbox config
      if VFS.FileExists("mapconfig/map_startboxes.lua") then
        -- Some map configs reference Spring.Utilities.Gametype which doesn't exist
        -- in the lobby. Provide stubs that return false so configs fall through
        -- to their default (typically 2-team) branch.
        local savedGametype = Spring.Utilities and Spring.Utilities.Gametype
        if Spring.Utilities then
          Spring.Utilities.Gametype = setmetatable({}, {
            __index = function() return function() return false end end,
          })
        end
        local ok, cfg = pcall(function()
          return VFS.Include("mapconfig/map_startboxes.lua")
        end)
        -- Restore original Gametype (or remove stub)
        if Spring.Utilities then
          Spring.Utilities.Gametype = savedGametype
        end
        if ok and cfg then
          result.config = cfg
        elseif not ok then
          Spring.Log("mapStartBoxes", LOG.WARNING, "Mapside include error: ", tostring(cfg))
        end
      end

      -- Try to read SMF header for map dimensions (fallback for maps not in mapDetails)
      -- SMF header: magic(16) + version(4) + mapid(4) + mapx(4) + mapy(4)
      local ok2, smfResult = pcall(function()
        local smfFiles = VFS.DirList("maps/", "*.smf")
        if smfFiles and #smfFiles > 0 then
          local data = VFS.LoadFile(smfFiles[1])
          if data and #data >= 32 then
            local magic = string.sub(data, 1, 15)
            if magic == "spring map file" then
              local mapx = readInt32LE(data, 25)
              local mapy = readInt32LE(data, 29)
              if mapx and mapy and mapx > 0 and mapy > 0 then
                return { x = mapx * 8, z = mapy * 8 }
              end
            end
          end
        end
        return nil
      end)
      if ok2 and smfResult then
        result.smfDimsX = smfResult.x
        result.smfDimsZ = smfResult.z
      end

      return result
    end

    local mapData
    if mapAlreadyLoaded then
      mapData = loadFromMap()
    else
      mapData = VFS.UseArchive(mapName, loadFromMap)
    end

    if mapData then
      rawConfig = mapData.config
      smfDimsX = mapData.smfDimsX
      smfDimsZ = mapData.smfDimsZ
    end
  end

  if not rawConfig or not next(rawConfig) then
    if mapArchiveAvailable then
      polygonCache[cacheKey] = false
    end
    return nil
  end

  -- Get map dimensions: try mapDetails first, then SMF header, then infer from polygon coords
  local mapSizeX, mapSizeZ = getMapDimensionsFromMapDetails(mapName)
  if not mapSizeX or not mapSizeZ then
    mapSizeX = smfDimsX
    mapSizeZ = smfDimsZ
  end
  if not mapSizeX or not mapSizeZ then
    -- Last resort: infer from polygon coordinates (round up to nearest multiple of 512)
    local maxX, maxZ = 0, 0
    for _, entry in pairs(rawConfig) do
      if entry.boxes then
        for _, polygon in ipairs(entry.boxes) do
          for _, vertex in ipairs(polygon) do
            if vertex[1] > maxX then maxX = vertex[1] end
            if vertex[2] > maxZ then maxZ = vertex[2] end
          end
        end
      end
    end
    if maxX > 0 and maxZ > 0 then
      mapSizeX = math.ceil(maxX / 512) * 512
      mapSizeZ = math.ceil(maxZ / 512) * 512
    end
  end
  if not mapSizeX or not mapSizeZ then
    Spring.Log("mapStartBoxes", LOG.WARNING, "Cannot get map dimensions for polygon startboxes: ", mapName)
    polygonCache[cacheKey] = false
    return nil
  end

  -- Convert the raw config to lobby format (1-based, 0-200 space).
  -- Modside configs use 0-based keys ([0]={...},[1]={...}), mapside configs
  -- use 1-based array keys ({entry1, entry2}). Detect which format and normalize.
  local has0Key = rawConfig[0] ~= nil
  local lobbyConfig = {}
  for allyTeamID, entry in pairs(rawConfig) do
    local lobbyEntry = {
      nameLong = entry.nameLong,
      nameShort = entry.nameShort,
      isPolygon = true,
      boxes = {},
      startpoints = {},
    }

    -- Convert polygon vertices from world coords to 0-200 normalized space
    if entry.boxes then
      for i, polygon in ipairs(entry.boxes) do
        local lobbyPolygon = {}
        for j, vertex in ipairs(polygon) do
          lobbyPolygon[j] = {
            200 * vertex[1] / mapSizeX,
            200 * vertex[2] / mapSizeZ,
          }
        end
        lobbyEntry.boxes[i] = lobbyPolygon
      end
    end

    -- Convert startpoints
    if entry.startpoints then
      for i, sp in ipairs(entry.startpoints) do
        lobbyEntry.startpoints[i] = {
          200 * sp[1] / mapSizeX,
          200 * sp[2] / mapSizeZ,
        }
      end
    end

    -- Compute bounding box in 0-200 space for engine startrects
    local xmin, zmin = 200, 200
    local xmax, zmax = 0, 0
    for _, polygon in ipairs(lobbyEntry.boxes) do
      for _, vertex in ipairs(polygon) do
        if vertex[1] < xmin then xmin = vertex[1] end
        if vertex[1] > xmax then xmax = vertex[1] end
        if vertex[2] < zmin then zmin = vertex[2] end
        if vertex[2] > zmax then zmax = vertex[2] end
      end
    end
    lobbyEntry.boundingBox = { left = xmin, top = zmin, right = xmax, bottom = zmax }

    -- Normalize to 1-based indexing for consistency with rest of lobby code
    local lobbyIdx = has0Key and (allyTeamID + 1) or allyTeamID
    lobbyConfig[lobbyIdx] = lobbyEntry
  end

  Spring.Log("mapStartBoxes", LOG.INFO, "Loaded polygon startboxes for ", mapName)
  polygonCache[cacheKey] = lobbyConfig
  return lobbyConfig
end

local function makeAllyTeamBoxPolygon(polygonConfig, allyteamindex)
  -- For polygon maps, send the bounding box as engine startrects
  -- The game's startbox_utilities.lua loads polygon config directly from the map archive
  -- and game_startbox_config.lua expands the engine AABB to cover polygon bounds
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
  loadPolygonStartboxes = loadPolygonStartboxes,
  makeAllyTeamBoxPolygon = makeAllyTeamBoxPolygon,
  clearPolygonCache = clearPolygonCache,
  getBox = getBox,
  clearBoxes = clearBoxes,
  removeBox = removeBox,
  addBox = addBox,
  singleplayerboxes = singleplayerboxes,
}
