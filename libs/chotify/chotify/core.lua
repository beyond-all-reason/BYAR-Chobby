local includes = {
    -- order matters
    "chotify.lua",
}

local Core = widget

Chili = WG.Chili
ChiliFX = WG.ChiliFX

for _, file in ipairs(includes) do
    VFS.Include(CHOTIFY_DIR .. file, Core, VFS.RAW_FIRST)
end

return Core.Chotify
