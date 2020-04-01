
self = false
unused = false
-- unused_args = false
global = false
allow_defined_top = true
max_line_length = false
codes = true

-- Ideally reenable these warnings later
redefined = false

ignore = {
    "512" -- Loop can be executed at most once.
}
-- Something to think about in the future
-- max_cyclomatic_complexity = 10

-- Lua (unnecessary)
-- "os", "pairs", "math", "pcall", "table", "type", "unpack", "assert",
-- "ipairs", "tostring", "tonumber", "debug", "getfenv", "setfenv",
-- "loadstring", "io", "xpcall", "string", "collectgarbage",
-- "getmetatable", "setmetatable", "next",

-- Default is probably fine, but anyway
std=lua51

globals = {
    -- std extensions
    "math.round", "math.bit_or",
    "table.ifind", "table.show", "table.save", "table.echo", "table.print",
    -- Spring
    "Spring", "VFS", "gl", "GL", "Game",
    "UnitDefs", "UnitDefNames", "FeatureDefs", "FeatureDefNames",
    "WeaponDefs", "WeaponDefNames", "LOG", "KEYSYMS", "CMD", "Script",
    "SendToUnsynced", "Platform", "include",
    -- Gadgets
    "GG", "gadgetHandler", "gadget",
    -- Widgets
    "WG", "widgetHandler", "widget",
    -- Chili
    "Chili", "Checkbox", "Control", "ComboBox", "Button", "Label",
    "Line", "EditBox", "Font", "Window", "ScrollPanel", "LayoutPanel",
    "Panel", "StackPanel", "Grid", "TextBox", "Image", "TreeView", "Trackbar",
    "DetachableTabPanel", "screen0", "Progressbar",
    -- Libs
    -- "LCS", "Path", "Table", "Log", "String", "Shaders", "Time", "Array", "StartScript",
}