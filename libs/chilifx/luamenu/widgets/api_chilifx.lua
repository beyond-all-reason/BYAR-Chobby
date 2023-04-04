function widget:GetInfo()
return {
    name      = "ChiliFX",
    desc      = "Chili Effects library",
    author    = "gajop",
    date      = "in the future",
    license   = "GPL-v2",
    layer     = -999,
    enabled   = true,
    api       = true,
    hidden    = true,
}
end

LIBS_DIR = "libs/"
LCS = loadstring(VFS.LoadFile(LIBS_DIR .. "lcs/LCS.lua"))
LCS = LCS()

CHILILFX_DIR = LIBS_DIR .. "chilifx/chilifx/"

function widget:Initialize()
    if not WG.Chili then
        Spring.Log("ChiliFX", LOG.ERROR, "Missing chiliui.")
        widgetHandler:RemoveWidget(widget)
        return
    end

    ChiliFX = VFS.Include(CHILILFX_DIR .. "core.lua", nil)

    WG.ChiliFX = ChiliFX()
end

function widget:Shutdown()
    WG.ChiliFX = nil
end
