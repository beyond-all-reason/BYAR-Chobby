# chilifx
ChiliFX: Library for creating effects for ChiliUI.

*Important:* Currently can only be used on Chili.Image objects or by overriding rendering completely.

Dependencies:
- LCS: https://github.com/gajop/chiliui
- ChiliUI: https://github.com/gajop/chiliui

Usage:

```lua
ChiliFX = WG.ChiliFX -- do this only once in your project


-- Add a new effect def
ChiliFX:AddEffectDef({
    shader = {
        -- GLSL shader you want compiled.
        -- Details at gl.CreateShader (https://springrts.com/wiki/Lua_GLSL_Api)
        fragment = ...
    },
    name = "string", -- effect definition name (must be unique)
    uniformNames = { "uniform1", "uniform2", ... } -- Uniform names that should be made available
    rawDraw = false, -- (optional, false by default); completely override DrawControl

    -- Special uniforms include (specify them in uniformNames and in the shader):
    -- uniform float time;     // time the effect is enabled (seconds); will be automatically updated if exists
    -- uniform sampler2D tex0; // texture 0, object should have obj.tex0
    -- uniform sampler2D tex1; // texture 1, object should have obj.tex1
    -- uniform sampler2D tex2; // texture 2, object should have obj.tex2
    -- uniform sampler2D tex3; // texture 3, object should have obj.tex3
})

-- Remove an effect def
ChiliFX:RemoveEffectDef(effectName)

-- Sets a drawing effect on the Chili object
ChiliFX:SetEffect({
    obj = myObject,    -- chili object
    effect = "effect", -- name of the effect def to apply
})

-- Removes the drawing effect from the Chili object
ChiliFX:UnsetEffect({
    obj = myObject, -- chili object
})

-- Sets a timed drawing event on the Chili object
ChiliFX:SetTimedEffect({
    obj = myObject,    -- chili object
    effect = "effect", -- name of the effect def to apply
    time = 3,          -- time in seconds the effect should last
    after = f,         -- (optional) function to execute after the effect ends
})

-- Disable the library: the Add*Effect calls will still work.
-- If disabled, the "after" function will be immediately executed without applying the effects
ChiliFX:Disable()

-- Enable the library again
ChiliFX:Enable()

-- Check if it's enabled
ChiliFX:IsEnabled()

```
