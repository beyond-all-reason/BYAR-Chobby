
self = false
unused = true
-- unused_args = false
global = false --  IDEs tend to have issues with 'global = true', as they work on a per-file basis
allow_defined_top = true
codes = true

-- Something to think about in the future
max_cyclomatic_complexity = 10

-- Default is probably fine, but anyway
std=lua51

globals = {
    -- std extensions
    "math.round", "math.bit_or",
    "table.ifind", "table.show", "table.save", "table.echo", "table.print",
    -- Spring
    "Spring", "VFS", "gl", "GL", "Game", "socket",
    "UnitDefs", "UnitDefNames", "FeatureDefs", "FeatureDefNames",
    "WeaponDefs", "WeaponDefNames", "LOG", "KEYSYMS", "CMD", "Script",
    "SendToUnsynced", "Platform", "include",
    -- Gadgets
    "GG", "gadgetHandler", "gadget",
    -- Widgets
    "WG", "widgetHandler", "widget",


    -- Dependencies
    'json'
}