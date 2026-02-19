--chili export
CHOBBY_DIR = CHOBBY_DIR or LUA_DIRNAME .. "widgets/chobby/"
CHOBBY_IMG_DIR = CHOBBY_DIR .. "images/"
CHOBBY_SHADERS_DIR = "shaders/"

if WG and WG.Chili then
	-- setup Chili
	Chili = WG.Chili
	Checkbox = Chili.Checkbox
	Control = Chili.Control
	ComboBox = Chili.ComboBox
	Button = Chili.Button
	Label = Chili.Label
	Line = Chili.Line
	EditBox = Chili.EditBox
	Font = Chili.Font
	Window = Chili.Window
	ScrollPanel = Chili.ScrollPanel
	LayoutPanel = Chili.LayoutPanel
	Panel = Chili.Panel
	StackPanel = Chili.StackPanel
	Grid = Chili.Grid
	TextBox = Chili.TextBox
	Image = Chili.Image
	TreeView = Chili.TreeView
	Trackbar = Chili.Trackbar
	DetachableTabPanel = Chili.DetachableTabPanel
	screen0 = Chili.Screen0
	Progressbar = Chili.Progressbar
end

-- Guard utility includes — they are idempotent and only need to load once.
-- 33 widgets include exports.lua, saving ~128 VFS.Include calls on startup.
if not _CHOBBY_UTILITIES_LOADED then
	local includes = {
		"utilities/buttons.lua",
		"utilities/stringUtilities.lua",
		"utilities/log.lua",
		"utilities/package.lua",
	}

	for _, file in ipairs(includes) do
		VFS.Include(CHOBBY_DIR .. file, Chobby, VFS.RAW_FIRST)
	end
	_CHOBBY_UTILITIES_LOADED = true
end

-- liblobby export
if WG and WG.LibLobby then
	LibLobby = WG.LibLobby
	lobby = LibLobby.lobby
	localLobby = LibLobby.localLobby
end

if WG and WG.i18n then
	i18n = WG.i18n
	if not i18n._loaded then
		i18n.loadFile(CHOBBY_DIR .. "i18n/chililobby.lua")
		i18n._loaded = true
	end
end

ChiliFX = WG.ChiliFX
Chotify = WG.Chotify
