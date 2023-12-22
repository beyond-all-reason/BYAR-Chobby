--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Image Preloader",
    desc      = "Preloads images; fixes buildpic issues",
    author    = "jK",
    date      = "@2009",
    license   = "GPLv2",
    layer     = 1000,
    enabled   = false,  --  loaded by default?
    alwaysStart = true,
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local index = 1
local files = nil
local BATCH_SIZE = 60
local SCALE = 1
local holder

local function MaybeAddFile(fileName)
	if string.find(fileName, "%.dds") or string.find(fileName, "%.png") or string.find(fileName, "%.jpg") then
		files[#files+1] = fileName
	end
end

local function AddDir(path)
	for _, f in ipairs(VFS.DirList(path)) do
		MaybeAddFile(f)
	end
end

function widget:Update()
	if files == nil then
		files = {}
		AddDir("LuaMenu/widgets/chili/skins/Armada Blues")
		AddDir("LuaMenu/images")
		AddDir("LuaMenu/images/ranks")
		AddDir("LuaMenu/configs/gameConfig/byar/minimapThumbnail")
		AddDir("LuaMenu/configs/gameConfig/byar/scenarios")
		AddDir("LuaMenu/configs/gameConfig/byar/skinning")
	elseif index then
		if not holder then
			holder = WG.Chili.Control:New {
				name = "imagePreloadHolder",
				right = -20,
				bottom = 0,
				width = SCALE,
				height = SCALE,
				padding = {0, 0, 0, 0},
				parent = WG.Chili.Screen0,
			}
			WG.Chili.Trackbar:New {
				x = SCALE/50*(index%50),
				y = SCALE/50*math.floor(index/50),
				width = SCALE/50,
				height = SCALE/50,
				parent = holder,
			}
			WG.Chili.Checkbox:New {
				x = SCALE/50*(index%50),
				y = SCALE/50*math.floor(index/50),
				width = SCALE/50,
				height = SCALE/50,
				checked = true,
				parent = holder,
			}
			WG.Chili.Checkbox:New {
				x = SCALE/50*(index%50),
				y = SCALE/50*math.floor(index/50),
				width = SCALE/50,
				height = SCALE/50,
				checked = false,
				parent = holder,
			}
		end

		for i = 1, BATCH_SIZE do
			local file = files[index]
			holder:BringToFront()
			if file then
				WG.Chili.Image:New {
					x = SCALE/50*(index%50),
					y = SCALE/50*math.floor(index/50),
					width = SCALE/50,
					height = SCALE/50,
					file = file,
					parent = holder,
				}
				index = index + 1
			else
				index = false
				return
			end
		end
	else
		holder:Dispose()
		holder = nil
		widgetHandler:RemoveWidget()
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
