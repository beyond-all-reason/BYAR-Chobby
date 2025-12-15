--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "ChiliInspector",
    desc      = "",
    author    = "",
    date      = "2013",
    license   = "GPLv2",
    layer     = 3,
    enabled   = false  --  loaded by default?
  }
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local Chili
local window0
local tree0
local label0
local label1
local label2

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GetBooleanStr(b)
	return (b and "true") or "false"
end

local function trace(children, node, level, max_level)
	if not node then return end
	if (level or 0) > (max_level or math.huge) then return end
	for i=1,#children do
		local obj = children[i]
		if obj and (obj.name ~= "wnd_inspector") then
			local caption = ("%s: %s | %s (redrawn: %i/%i)"):format(obj.classname, obj.name, (obj.caption or ""), obj._redrawSelfCounter or 0, obj._redrawCounter or 0)
			local nodec = node:Add(caption)
			trace(obj.children, nodec, (level or 0) + 1, max_level)
		end
	end
end


local function traceLost(node)

	for i,obj in pairs(Chili.DebugHandler.allObjects) do
		if obj.name ~= "wnd_inspector" then
			if (not obj.parent)and(not obj:InheritsFrom("screen")) and (obj.classname ~= "treeviewnode") then
				local caption = ("%s: %s (redrawn: %i; disposed: %s; from %s)"):format(obj.classname, obj.name, obj._redrawCounter or 0, GetBooleanStr(obj.disposed), obj.allocatedfrom or "")
				local nodec = node:Add(caption)
				Spring.Echo("Lost: "..caption)
				trace(obj.children, nodec, 1, 1)
			end
		end
	end
end


local objects = 0
local fonts = 0

local function tracePerWidget(node)
	
	objects = 0
	fonts = 0
	collectgarbage("collect")
	for w,t in pairs(Chili.DebugHandler.objectsOwnedByWidgets) do
		if (w.whInfo.name ~= widget.whInfo.name) then
			local caption = ("%s"):format(w.whInfo.name)
			local nodec = node:Add(caption)
			for i,obj in pairs(t) do
				objects = objects + 1 
				local fontinfo = ""
				if obj.font then
					fonts = fonts + 1
					--local fontname = string.match(obj.font.font or "", "(%d+)/?$") -- remove all before trailing slash
					local fontname = string.sub(obj.font.font or "nil", -10) -- remove all before trailing slash
					
					fontinfo = ("Font:(%s[%i])"):format(fontname, obj.font.size or "0")
				end

				local positioninfo = ""
				if obj.x and obj.y then
					positioninfo = ("Pos(%i:%i)"):format(obj.x  or 0, obj.y or 0)
				end 

				local caption = ("%s->%s: %s; \"%s\" %s %s"):format(
					(obj.parent and obj.parent.name) or "orph",
					obj.classname,
					obj.name,
					obj.caption or "",
					fontinfo,
					positioninfo
				)
				local nodec2 = nodec:Add(caption)
			end
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
	Chili = WG.Chili

	if (not Chili) then
		widgetHandler:RemoveWidget()
		return
	end
	-- if this widget is enabled on startup then Configuration has not been loaded yet, so we can't access SetConfigValue. But it's ok. Wen only need to set the config value, when it's manually turned on by user.
	if WG and WG.Chobby and WG.Chobby.Configuration then
		WG.Chobby.Configuration:SetConfigValue("enableInspector", true)
	end

	window0 = Chili.Window:New{
		name = "wnd_inspector",
		caption = "Chili Inspector",
		x = 1200,
		y = 250,
		width  = 400,
		height = 400,
		parent = Chili.Screen0,

		children = {
			Chili.Label:New{
				name = "lbl_inspector_memusage",
				x=0, right = 50,
				y=0, bottom=-20,
				align = "right", valign = "bottom",
				caption = "Lua MemUsage: 0MB",

			},			
			Chili.Label:New{
				name = "lbl_inspector_memdelta",
				x=0, right = 50,
				y=20, bottom=-40,
				align = "right", valign = "bottom",
				caption = "Lua Memdelta: 0MB",

			},
			Chili.Label:New{
				name = "lbl_inspector_drawdata",
				x=0, right = 50,
				y=40, bottom=-60,
				align = "right", valign = "bottom",
				caption = "Lobbyinterfaceholder drawtime",

			},
			Chili.Button:New{
				right = 0, width = 50,
				y=5, bottom=-25,
				caption="gc",
				classname = "button_small",
				OnMouseUp = {function() collectgarbage("collect") end},
			},
			Chili.ScrollPanel:New{
				x=0, right=0,
				y=60, bottom=20,
				children = {
					Chili.TreeView:New{
						name = "tree_inspector";
						width="100%";
						height="100%";
					},
				},
			},
			Chili.StackPanel:New{
				x=0, right=0,
				y=-20, bottom=0,
				orientation = "horizontal",
				padding     = {0,0,0,0},
				itemMargin  = {0,0,0,0},
				itemPadding = {0,0,0,0},
				children = {
					Chili.Button:New{
						caption="visible objects",
						classname = "option_button",
						OnMouseUp = {function() tree0.root:Clear();
							for i, child in pairs(tree0.root.children) do
								child:Dispose()
							end
							
							trace(Chili.Screen0.children, tree0.root) end},
					},
					Chili.Button:New{
						caption="lost objects",
						classname = "option_button",
						OnMouseUp = {function() tree0.root:Clear(); traceLost(tree0.root) end},
					},
					Chili.Button:New{
						caption="per widget",
						classname = "option_button",
						OnMouseUp = {function() tree0.root:Clear(); tracePerWidget(tree0.root) end},
					},
					Chili.Button:New{
						caption="close",
						classname = "negative_button",
						OnMouseUp = {function()
										widgetHandler:RemoveWidget()
										WG.Chobby.Configuration:SetConfigValue("enableInspector", false)
									end},
					},
				},
			},
		},
	}

	tree0 = window0:GetObjectByName("tree_inspector")
	label0 = window0:GetObjectByName("lbl_inspector_memusage")
	label1 = window0:GetObjectByName("lbl_inspector_memdelta")
	label2 = window0:GetObjectByName("lbl_inspector_drawdata")

	trace(Chili.Screen0.children, tree0.root)
end

function widget:Shutdown()
	if (window0) then
		window0:Dispose()
	end
end

local updatecount = 0
local lastupdatetime = Spring.GetTimer()
local lastmemusagesec = 0
local lastmemusageframe = 0
local memdelta = 0
function widget:Update()
	updatecount = updatecount + 1
	local curUsage, gcLimit = gcinfo()
	local caption = ("O/F: %d/%d Frame:%i Lua MemUsage: %.2fMB"):format(objects, fonts,updatecount, curUsage / 1024)
	label0:SetCaption(caption)

	if Spring.DiffTimers(Spring.GetTimer(), lastupdatetime) > 1 then 
		memdelta = curUsage - lastmemusagesec
		lastmemusagesec = curUsage
		lastupdatetime = Spring.GetTimer()
	end
	label1:SetCaption(("Mem usage delta = %04d KB/s %04d KB/f"):format(memdelta, curUsage - lastmemusageframe))
	lastmemusageframe = curUsage
	local lobbyinterfaceholder = WG.Chobby.lobbyInterfaceHolder
	label2:SetCaption(("Draw Time = %3.2f ms"):format((lobbyinterfaceholder.drawTime or 0)*1000))
end