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

local SplineLib = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/byar/lib_spline.lua")

local polygonCache = {}

local function getMapDimensionsFromMapDetails(mapName)
  local mapDetails = nil
  if WG and WG.Chobby and WG.Chobby.Configuration and WG.Chobby.Configuration.gameConfig then
    mapDetails = WG.Chobby.Configuration.gameConfig.mapDetails
  end
  if mapDetails and mapDetails[mapName] then
    local data = mapDetails[mapName]
    if data.Width and data.Height then
      -- spring map units to elmos
      return data.Width * 512, data.Height * 512
    end
  end
  return nil, nil
end

local function readInt32LE(data, offset)
  local b1, b2, b3, b4 = string.byte(data, offset, offset + 3)
  if not b1 or not b4 then return nil end
  return b1 + b2 * 256 + b3 * 65536 + b4 * 16777216
end

local function loadPolygonStartboxes(mapName)
  if mapName == nil then return nil end

  local cacheKey = tostring(mapName)
  if polygonCache[cacheKey] ~= nil then
    if polygonCache[cacheKey] == false then
      return nil
    end
    return polygonCache[cacheKey]
  end

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

      if VFS.FileExists("mapconfig/map_startboxes.lua") then
        local ok, cfg = pcall(function()
          return VFS.Include("mapconfig/map_startboxes.lua")
        end)
        if ok and cfg then
          result.config = cfg
        elseif not ok then
          Spring.Log("mapStartBoxes", LOG.WARNING, "Mapside include error: ", tostring(cfg))
        end
      end

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

  -- Real-world mapside configs (e.g. Cirolata, Onyx Cauldron) use 0-based allyTeam
  -- keys to match the game-side gadget; chobby's renderer and script generation are 1-based.
  if rawConfig[0] ~= nil then
    local shifted = {}
    for k, v in pairs(rawConfig) do
      shifted[k + 1] = v
    end
    rawConfig = shifted
  end

  local mapSizeX, mapSizeZ = getMapDimensionsFromMapDetails(mapName)
  if not mapSizeX or not mapSizeZ then
    mapSizeX = smfDimsX
    mapSizeZ = smfDimsZ
  end
  if not mapSizeX or not mapSizeZ then
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

  -- Tessellate unconditionally: anchors without strength are sharp corners,
  -- so plain polygons emerge vertex-identical. Preserve the raw anchor data
  -- alongside the tessellated polygon so we can encode it as the modoption
  -- the game-side gadget consumes (mapmetadata_startboxes_set).
  for _, entry in pairs(rawConfig) do
    if entry.boxes then
      entry.anchorBoxes = {}
      for i = 1, #entry.boxes do
        local anchors = entry.boxes[i]
        local copy = {}
        for j, a in ipairs(anchors) do
          copy[j] = { a[1], a[2], a[3] }
        end
        entry.anchorBoxes[i] = copy
        entry.boxes[i] = SplineLib.TessellateRing(anchors)
      end
    end
  end

  -- Lobby format: 1-based, 0-200 normalized space.
  local lobbyConfig = {}
  for allyTeamID, entry in pairs(rawConfig) do
    local lobbyEntry = {
      nameLong = entry.nameLong,
      nameShort = entry.nameShort,
      isPolygon = true,
      boxes = {},
      startpoints = {},
    }

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

    if entry.anchorBoxes then
      lobbyEntry.anchorBoxes = {}
      for i, anchorPoly in ipairs(entry.anchorBoxes) do
        local lobbyAnchors = {}
        for j, anchor in ipairs(anchorPoly) do
          lobbyAnchors[j] = {
            200 * anchor[1] / mapSizeX,
            200 * anchor[2] / mapSizeZ,
            anchor[3],
          }
        end
        lobbyEntry.anchorBoxes[i] = lobbyAnchors
      end
    end

    if entry.startpoints then
      for i, sp in ipairs(entry.startpoints) do
        lobbyEntry.startpoints[i] = {
          200 * sp[1] / mapSizeX,
          200 * sp[2] / mapSizeZ,
        }
      end
    end

    -- Bounding box drives engine startrects when launching the game.
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

    lobbyConfig[allyTeamID] = lobbyEntry
  end

  Spring.Log("mapStartBoxes", LOG.INFO, "Loaded polygon startboxes for ", mapName)
  polygonCache[cacheKey] = lobbyConfig
  return lobbyConfig
end

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
  loadPolygonStartboxes = loadPolygonStartboxes,
  makeAllyTeamBoxFromPolygon = makeAllyTeamBoxFromPolygon,
  encodeStartboxesSetModoption = encodeStartboxesSetModoption,
  getBox = getBox,
  clearBoxes = clearBoxes,
  removeBox = removeBox,
  addBox = addBox,
  singleplayerboxes = singleplayerboxes,
}
