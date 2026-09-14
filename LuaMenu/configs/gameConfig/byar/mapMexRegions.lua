-- A map's region layout rides in mapDetails.lua as the encoded MexRegionsLayout field, synced
-- from beyond-all-reason/maps-metadata the way StartboxesSet is: base64url(zlib(json)) of
--   { regions = { <region type> = { <region>, ... }, ... } }
-- The lobby never interprets it; it hands the blob to the game as the mex_regions_layout
-- modoption, which the game reads when Mex Splitting is Map Assigned. What a region is, and
-- whether a layout is a good one, is the game's to say: its regions module checks it.
--
-- Multiplayer battles get the modoption from the server, like mapmetadata_startboxes_set;
-- this file feeds skirmish, and checks only that maps-metadata handed us something that
-- decodes, so a row that does not is a log line here rather than a chat error in game.

local mapDetails = VFS.Include(LUA_DIRNAME .. "configs/gameConfig/byar/mapDetails.lua")
local layoutByMap = {} -- springName -> encoded blob, or false when none or undecodable

local function decodeBlob(encoded)
  local ok, parsed = pcall(function()
    local padded = encoded
    local pad = #padded % 4
    if pad > 0 then padded = padded .. string.rep("=", 4 - pad) end
    local bytes = Spring.Utilities.Base64Decode(padded)
    if not bytes or bytes == "" then return nil end

    return Json.decode(VFS.ZlibDecompress(bytes))
  end)
  if not ok or type(parsed) ~= "table" then return nil end

  return parsed
end

-- The layout table, or nil when the blob does not decode to one.
local function decodeLayout(encoded)
  if type(encoded) ~= "string" or encoded == "" then return nil end
  local parsed = decodeBlob(encoded)
  if not parsed or type(parsed.regions) ~= "table" or next(parsed.regions) == nil then return nil end

  return parsed
end

-- The blob to put on mex_regions_layout for this map, or nil when maps-metadata has none.
local function getLayoutBlob(mapName)
  local cached = layoutByMap[mapName]
  if cached ~= nil then return cached or nil end
  local entry = mapDetails[mapName]
  local encoded = entry and entry.MexRegionsLayout
  local layout = encoded and decodeLayout(encoded)
  if encoded and not layout then
    Spring.Log("mapMexRegions", LOG.WARNING, "Could not decode MexRegionsLayout for", mapName)
  end
  layoutByMap[mapName] = layout and encoded or false
  return layout and encoded or nil
end

return {
  getLayoutBlob = getLayoutBlob,
  decodeLayout = decodeLayout,
}
