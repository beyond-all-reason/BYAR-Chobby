--// =============================================================================
--//

TextureHandler = {}


--// =============================================================================
--//TWEAKING

local timeLimit = 1.0/15 --//time per second / desiredFPS


--// =============================================================================
--// SpeedUp

local next = next
local spGetTimer = Spring.GetTimer
local spDiffTimers = Spring.DiffTimers
local glActiveTexture = gl.ActiveTexture
local glCallList = gl.CallList

local weakMetaTable = {__mode = "k"}


--// =============================================================================
--// local

local loaded = {}
local requested = {}
local texInfoCache = {}

local placeholderFilename = CHILI_DIRNAME .. "skins/default/empty.png"
local placeholderDL -- NOTE: we cannot initialize a display list in this context, as it is too early and _will_ fail. It must be done on first LoadTexture!

local isEngineTexture = { [string.byte("!")] = true, [string.byte("%")] = true, [string.byte("#")] = true, [string.byte("$")] = true, [string.byte("^")] = true }

--// =============================================================================
--// Returns if the request is novel
local function AddRequest(filename, obj)
	local req = requested
	if (req[filename]) then
		local t = req[filename]
		t[obj] = true
		return false
	else
		req[filename] = setmetatable({[obj] = true}, weakMetaTable)
		return true
	end
end


--// =============================================================================
--// Destroy

TextureHandler._scream = Script.CreateScream()
TextureHandler._scream.func = function()
	requested = {}
	for filename, tex in pairs(loaded) do
		gl.DeleteList(tex.dl)
		gl.DeleteTexture(filename)
	end
	loaded = {}
end


--// =============================================================================
--// Returns the texture width and height from the texInfoCache to avoid gl.TextureInfo calls

function TextureHandler.LoadTexture(activeTexID, filename, obj)
	if placeholderDL == nil then 
		gl.Texture(placeholderFilename)
		gl.Texture(false)
		placeholderDL = gl.CreateList(gl.Texture, placeholderFilename)
	end

	local tex = loaded[filename]
	if (tex) then
		glActiveTexture(activeTexID, glCallList, tex.dl)
		local texInfo = texInfoCache[filename]
		if texInfo then
			return texInfo[1], texInfo[2]
		else
			return 1, 1
		end
	else
		AddRequest(filename, obj)
		if isEngineTexture[filename:byte(1)] then
			gl.Texture(activeTexID, filename)
		else
			glActiveTexture(activeTexID, glCallList, placeholderDL)
		end
		return 1, 1
	end
end


function TextureHandler.DeleteTexture(filename)
	local tex = loaded[filename]
	if (tex) then
		tex.references = tex.references - 1
		if (tex.references == 0) then
			gl.DeleteList(tex.dl)
			gl.DeleteTexture(filename)
			loaded[filename] = nil
			texInfoCache[filename] = nil
		end
	end
end


--// =============================================================================
--//

local usedTime = 0
local lastCall = spGetTimer()
local nullInfo = {xsize = 0}


function TextureHandler.Update()
	if (not next(requested)) then
		return
	end

	if (usedTime > 0) then
		thisCall = spGetTimer()

		usedTime = usedTime - spDiffTimers(thisCall, lastCall)
		lastCall = thisCall

		if (usedTime < 0) then
			usedTime = 0
		end
	end

	local broken = {}
	local timerStart = spGetTimer()
	local finished = false
	while (usedTime < timeLimit) and (not finished) do
		local filename, objs = next(requested)

		if (filename) then
			gl.Texture(filename)
			gl.Texture(false)
			local texInfo = gl.TextureInfo(filename)
			if (texInfo or nullInfo).xsize > 0 then
				local texture = {}
				texture.dl = gl.CreateList(gl.Texture, filename)
				loaded[filename] = texture
				texInfoCache[filename] = {texInfo.xsize, texInfo.ysize}
				for obj in pairs(objs) do
					obj:Invalidate()
					texture.references = (texture.references or 0) + 1
				end
			else
				broken[filename] = objs
			end

			requested[filename] = nil

			local timerEnd = spGetTimer()
			usedTime = usedTime + spDiffTimers(timerEnd, timerStart)
			timerStart = timerEnd
		else
			finished = true
		end
	end

	for i, v in pairs(broken) do
		requested[i] = v
	end

	lastCall = spGetTimer()
end

--// =============================================================================
