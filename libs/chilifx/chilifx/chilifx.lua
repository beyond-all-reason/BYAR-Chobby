ChiliFX = LCS.class{}

LOG_SECTION = "ChiliFX"

----------------------------------------
-- Begin private methods
----------------------------------------

function ChiliFX:init()
    self.enabled = gl.CreateShader ~= nil
    Spring.Log(LOG_SECTION, LOG.NOTICE, "Enabled: " .. tostring(self.enabled))

    -- Definitions
    self.effectDefs = {}
    -- Compiled effects
    self.effects = {}
    -- Active effects
    self.activeEffects = {}
end

function ChiliFX:LoadEffectDefs()
    Spring.Log(LOG_SECTION, LOG.NOTICE, "Loading shaders...")
    for name, effectDef in pairs(self.effectDefs) do
        self:LoadEffectDef(effectDef)
    end
    Spring.Log(LOG_SECTION, LOG.NOTICE, "Finished loading shaders.")
end

function ChiliFX:LoadEffectDef(effectDef)
    if self.effects[effectDef.name] then
        error("Effect with name: " .. tostring(effectDef.name) ..
            " already exists. Remove it first")
    end
    if not self.enabled then
        return
    end

    -- Create effect object from the shader definition
    Spring.Log(LOG_SECTION, LOG.INFO, "Loading effect " .. tostring(effectDef.name) .. "...")
    local shader = gl.CreateShader(effectDef.shader)
    local glslLog = gl.GetShaderLog()
    if shader == nil then
        Spring.Log(LOG_SECTION, LOG.ERROR, "Error loading effect: " .. effectDef.name)
        Spring.Log(LOG_SECTION, LOG.ERROR, glslLog)
        return
    end
    if glslLog ~= "" then
        Spring.Log(LOG_SECTION, LOG.WARNING, "Warning loading effect: " .. effectDef.name)
        Spring.Log(LOG_SECTION, LOG.WARNING, glslLog)
    end
    local effectObj = {
        shader = shader,
        uniforms = {},
        textures = {},
    }

    -- Store all shader uniforms for easier access later
    for _, uName in pairs(effectDef.uniformNames) do
        effectObj.uniforms[uName] = gl.GetUniformLocation(effectObj.shader, uName)
        if effectObj.uniforms[uName] == nil then
            Spring.Log(LOG_SECTION, LOG.ERROR, "Error loading effect: " .. effectDef.name)
            Spring.Log(LOG_SECTION, LOG.ERROR, "Failed to find uniform: " .. uName)
            return
        end
        if uName:match("tex[0-3]") then
            local texID = tonumber(uName:sub(4, 4))
            effectObj.textures[texID] = uName
            --gl.Uniform(effectObj.uniforms[texName], texID)
        end
    end

    -- Finally store the newly created shader object
    self.effects[effectDef.name] = effectObj
end

function ChiliFX:UnloadEffectDef(effectName)
    -- Delete the shader object and unregister it
    local effectObj = self.effects[effectName]
    if not effectObj then
        Spring.Log(LOG_SECTION, LOG.WARNING,
            "Trying to unload effect that doesn't exist: " .. tostring(effectName))
        return
    end
    gl.DeleteShader(effectObj.shader)
    self.effects[effectName] = nil
end

----------------------------------------
-- End private methods
----------------------------------------

----------------------------------------
-- Begin public API
----------------------------------------

-- Definitions
function ChiliFX:AddEffectDef(effectDef)
    self:LoadEffectDef(effectDef)
    self.effectDefs[effectDef.name] = effectDef
end

function ChiliFX:RemoveEffectDef(effectName)
    if self.effectDefs[effectName] == nil then
        Spring.Log(LOG_SECTION, LOG.WARNING,
            "Trying to remove shader def that doesn't exist: " .. tostring(effectName))
    end
    if self.effects[effectName] then
        self:UnloadEffectDef(effectName)
    end
    self.effectDefs[effectName] = nil
end

local function Tex2Rect(x, y, w, h, t0, t1)
    gl.MultiTexCoord(t0, 0, 0 )
    gl.MultiTexCoord(t1, 0, 0 )
    gl.Vertex(x, y)

    gl.MultiTexCoord(t0, 0, 1 )
    gl.MultiTexCoord(t1, 0, 1 )
    gl.Vertex(x, y+h)

    gl.MultiTexCoord(t0, 1, 1 )
    gl.MultiTexCoord(t1, 1, 1 )
    gl.Vertex(x+w, y+h)

    gl.MultiTexCoord(t0, 1, 0 )
    gl.MultiTexCoord(t1, 1, 0 )
    gl.Vertex(x+w, y)
end

local function Tex3Rect(x, y, w, h, t0, t1, t2)
    gl.MultiTexCoord(t0, 0, 0 )
    gl.MultiTexCoord(t1, 0, 0 )
    gl.MultiTexCoord(t2, 0, 0 )
    gl.Vertex(x, y)

    gl.MultiTexCoord(t0, 0, 1 )
    gl.MultiTexCoord(t1, 0, 1 )
    gl.MultiTexCoord(t2, 0, 1 )
    gl.Vertex(x, y+h)

    gl.MultiTexCoord(t0, 1, 1 )
    gl.MultiTexCoord(t1, 1, 1 )
    gl.MultiTexCoord(t2, 1, 1 )
    gl.Vertex(x+w, y+h)

    gl.MultiTexCoord(t0, 1, 0 )
    gl.MultiTexCoord(t1, 1, 0 )
    gl.MultiTexCoord(t2, 1, 0 )
    gl.Vertex(x+w, y)
end

local function Tex4Rect(x, y, w, h, t0, t1, t2, t3)
    gl.MultiTexCoord(t0, 0, 0 )
    gl.MultiTexCoord(t1, 0, 0 )
    gl.MultiTexCoord(t2, 0, 0 )
    gl.MultiTexCoord(t3, 0, 0 )
    gl.Vertex(x, y)

    gl.MultiTexCoord(t0, 0, 1 )
    gl.MultiTexCoord(t1, 0, 1 )
    gl.MultiTexCoord(t2, 0, 1 )
    gl.MultiTexCoord(t3, 0, 1 )
    gl.Vertex(x, y+h)

    gl.MultiTexCoord(t0, 1, 1 )
    gl.MultiTexCoord(t1, 1, 1 )
    gl.MultiTexCoord(t2, 1, 1 )
    gl.MultiTexCoord(t3, 1, 1 )
    gl.Vertex(x+w, y+h)

    gl.MultiTexCoord(t0, 1, 0 )
    gl.MultiTexCoord(t1, 1, 0 )
    gl.MultiTexCoord(t2, 1, 0 )
    gl.MultiTexCoord(t3, 1, 0 )
    gl.Vertex(x+w, y)
end


-- Sets a drawing effect on the Chili object
function ChiliFX:SetEffect(opts)
    local obj        = opts.obj     -- chili object
    local effectName = opts.effect  -- name of the effect def to apply

    if not self.enabled then
        return
    end

    local effectObj = self.effects[effectName]
    if not effectObj then
        Spring.Log(LOG_SECTION, LOG.ERROR, "No such effect: " .. tostring(effectName))
        Spring.Log(LOG_SECTION, LOG.ERROR, debug.traceback())
    end
    self.activeEffects[obj] = opts
    opts.DrawControl = obj.DrawControl

    local startTime = os.clock()

    local texs = {}
    for texID, texName in pairs(effectObj.textures) do
        table.insert(texs, texID)
    end

    if not self.effectDefs[effectName].rawDraw then
        Spring.Log(LOG_SECTION, LOG.ERROR, "Only effect defs with rawDraw=true are supported at this moment.")
        Spring.Log(LOG_SECTION, LOG.ERROR, debug.traceback())
        return
        --[[
        obj.DrawControl = function(...)
            local fboName1 = "_fbo_" .. "children"
            local fboName2 = "_fbo_" .. "all"
            if not obj._tex then
                obj._tex = gl.CreateTexture(obj.width, obj.height, {
                    border = false,
                    min_filter = GL.LINEAR,
                    mag_filter = GL.LINEAR,
                    wrap_s = GL.CLAMP_TO_EDGE,
                    wrap_t = GL.CLAMP_TO_EDGE,
                    fbo = true,
                })
                --gl.Blending("disable")

            end
            gl.RenderToTexture(obj._tex, function()
                self.activeEffects[obj].DrawControl(obj)
            end)
            --gl.Blending("enable")
            if true then
                --Spring.Echo(0, 0, obj.width, obj.height)
                gl.UseShader(effectObj.shader)
                if effectObj.uniforms.value then
                    gl.Uniform(effectObj.uniforms.value, (50 * os.clock()) % 1.0)
                end
                --gl.Texture(0, obj._tex)
                --gl.Texture(0, "!" .. tostring(math.random(1, 30)))
                --gl.Texture(0, "LuaMenu/images/dev_0008_Layer-5.png")
                gl.TexRect(0, 0, obj.width, obj.height)
                gl.UseShader(0)
            end
            if obj[fboName2] and false then
                gl.UseShader(effectObj.shader)
                gl.Texture(0, obj[fboName2].color0)
                --gl.Texture(0, obj.file)
                --gl.ActiveFBO(obj[fboName2], true)
                Spring.Echo(obj[fboName2].color0)
                gl.TexRect(0, 0, obj.width, obj.height)
                gl.UseShader(0)
            end

            WG.Delay(function() obj:Invalidate() end, 0.001)
        end
        ]]
    else
        obj.DrawControl = function(...)
            gl.UseShader(effectObj.shader)
            if effectObj.uniforms.time then
                gl.Uniform(effectObj.uniforms.time, os.clock() - startTime)
            end
    --            gl.Color(obj.color)
            for texID, texName in pairs(effectObj.textures) do
                gl.Texture(texID, obj[texName])
            end
            if not opts.dlist then
                opts.dlist = gl.CreateList(function()
                    if #texs == 1 then
                        gl.TexRect(0, 0, obj.width, obj.height, false, true)
                    elseif #texs == 2 then
                        gl.BeginEnd(GL.QUADS, Tex2Rect, 0, 0, obj.width, obj.height, texs[1], texs[2])
                    elseif #texs == 3 then
                        gl.BeginEnd(GL.QUADS, Tex3Rect, 0, 0, obj.width, obj.height, texs[1], texs[2], texs[3])
                    elseif #texs == 4 then
                        gl.BeginEnd(GL.QUADS, Tex4Rect, 0, 0, obj.width, obj.height, texs[1], texs[2], texs[3], texs[4])
                    end
                end)
            else
                gl.CallList(opts.dlist)
            end
            gl.UseShader(0)

            -- obj:Invalidate()
            -- FIXME: the line above doesn't seem to always cause a Draw to be invoked so we're hacking it with a delayed call
            WG.Delay(function() obj:Invalidate() end, 0.001)
        end
    end
    return opts
end

-- Removes the drawing effect from the Chili object
function ChiliFX:UnsetEffect(opts)
    local obj        = opts.obj    -- chili object

    if not self.enabled then
        return
    end

    obj.DrawControl = self.activeEffects[obj].DrawControl
    if self.activeEffects[obj].after then self.activeEffects[obj].after() end

    self.activeEffects[obj] = nil
end

-- Sets a timed drawing event on the Chili object
function ChiliFX:SetTimedEffect(opts)
    local obj        = opts.obj    -- chili object
    local time       = opts.time   -- time in seconds the effect should last
    local after      = opts.after  -- (optional) function to execute after the effect ends

    if not self.enabled then
        if after then after() end
        return
    end

    self:SetEffect(opts)

    WG.Delay(function()
        self:UnsetEffect({obj = obj})
        after()
    end, time)

    return opts
end

function ChiliFX:IsEnabled()
    return self.enabled
end

function ChiliFX:Enable()
    if self.enabled then
        return
    end
    if gl.CreateShader == nil then
        Spring.Log(LOG_SECTION, LOG.ERROR, "ChiliFX not loaded. Spring has failed to detect GLSL support on your system.")
        return
    end

    self.enabled = true
    if self.effects == nil then -- we haven't loaded shaders once yet
        self:LoadEffectDefs()
    end
    Spring.Log(LOG_SECTION, LOG.NOTICE, "ChiliFX enabled.")
end

-- Disable ChiliFX and unload all effect defs
function ChiliFX:Disable()
    if not self.enabled then
        return
    end

    self.enabled = false
    Spring.Log(LOG_SECTION, LOG.NOTICE, "ChiliFX disabled.")
end

function ChiliFX:SetEnabled(value)
    if value then
        self:Enable()
    else
        self:Disable()
    end
end

----------------------------------------
-- End public API
----------------------------------------

--[[
function ChiliFX:AddFadeEffect(effect)
    local obj = effect.obj
    local time = effect.time
    local after = effect.after
    local endValue = effect.endValue
    local startValue = effect.startValue or 1

    if not self.enabled then
        if after then after() end
        return
    end
    local effectObj = self.effects.fade
    if effectObj == nil then
        if after then after() end
        return
    end

    local start = os.clock()

    if obj._origDraw == nil then
        obj._origDraw = obj.DrawControl
    end

    obj.DrawControl = function(...)
        local progress = math.min((os.clock() - start) / time, 1)
        local value = startValue + progress * (endValue - startValue)

        gl.UseShader(effectObj.shader)
        gl.Uniform(effectObj.uniforms.tex, 0)
        gl.Uniform(effectObj.uniforms.multi, value)
        obj._origDraw(...)
        gl.UseShader(0)
        -- obj:Invalidate()
        -- FIXME: the line above doesn't seem to always cause a Draw to be invoked so we're hacking it with a delayed call
        WG.Delay(function() obj:Invalidate() end, 0.001)
        if progress == 1 then
            obj.DrawControl = obj._origDraw
            if after then after() end
        end
    end

    if not obj.children then return end
    for _, child in pairs(obj.children) do
        if type(child) == "table" then
            effect.obj = child
            effect.after = nil
            self:AddFadeEffect(effect)
        end
    end
    obj:Invalidate()
end

function ChiliFX:AddGlowEffect(effect)
    local obj = effect.obj
    local time = effect.time
    local after = effect.after
    local endValue = effect.endValue
    local startValue = effect.startValue or 1

    if not self.enabled then
        if after then after() end
        return
    end
    local effectObj = self.effects.glow
    if effectObj == nil then
        if after then after() end
        return
    end

    local start = os.clock()

    if obj._origDraw == nil then
        obj._origDraw = obj.DrawControl
    end

    obj.DrawControl = function(...)
        local progress = math.min((os.clock() - start) / time, 1)
        local value = startValue + progress * (endValue - startValue)

        gl.UseShader(effectObj.shader)
        gl.Uniform(effectObj.uniforms.tex, 0)
        gl.Uniform(effectObj.uniforms.multi, value)
        obj._origDraw(...)
        gl.UseShader(0)
        -- obj:Invalidate()
        -- FIXME: the line above doesn't seem to always cause a Draw to be invoked so we're hacking it with a delayed call
        WG.Delay(function() obj:Invalidate() end, 0.001)
        if progress == 1 then
            obj.DrawControl = obj._origDraw
            if after then after() end
        end
    end

    if not obj.children then return end
    for _, child in pairs(obj.children) do
        if type(child) == "table" then
            effect.obj = child
            effect.after = nil
            self:AddGlowEffect(effect)
        end
    end
    obj:Invalidate()
end
--]]
