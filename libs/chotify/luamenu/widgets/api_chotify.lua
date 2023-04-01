function widget:GetInfo()
return {
    name      = "Chotify",
    desc      = "Chili notification library",
    author    = "gajop",
    date      = "in the future",
    license   = "GPL-v2",
    layer     = -980,
    enabled   = true,
    api       = true,
    hidden    = true,
}
end

LIBS_DIR = "libs/"
LCS = loadstring(VFS.LoadFile(LIBS_DIR .. "lcs/LCS.lua"))
LCS = LCS()

CHOTIFY_DIR = LIBS_DIR .. "chotify/chotify/"

function widget:Initialize()
    if not WG.ChiliFX then
        Spring.Log("Chotify", LOG.ERROR, "Missing ChiliFX")
        widgetHandler:RemoveWidget(widget)
        return
    end
    if not WG.Chili then
        Spring.Log("Chotify", LOG.ERROR, "Missing ChiliUI.")
        widgetHandler:RemoveWidget(widget)
        return
    end

    Chotify = VFS.Include(CHOTIFY_DIR .. "core.lua", nil)

    WG.Chotify = Chotify
end

function widget:Shutdown()
    WG.Chotify = nil
end

function widget:Update()
    WG.Chotify:_Update()
end

function widget:ViewResize(vsx, vsy)
    WG.Chotify:ViewResize(vsx, vsy)
end
