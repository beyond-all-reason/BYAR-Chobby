local includes = {
    -- order matters
    "chilifx.lua",
}

local Core = widget

for _, file in ipairs(includes) do
    VFS.Include(CHILILFX_DIR .. file, Core, VFS.RAW_FIRST)
end

return Core.ChiliFX
