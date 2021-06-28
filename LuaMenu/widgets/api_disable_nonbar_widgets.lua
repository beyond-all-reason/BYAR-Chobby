
function widget:GetInfo()
	return {
		name	= "Disable NonBar Widgets",
		desc	= "What it says on the tin",
		author	= "Beherith",
		date	= "2021 june",
		license	= "GNU GPL, v2 or later",
		layer	= 100000000, -- last to load
		handler = true, -- otherwise it cant disable other widgets
		enabled	= true	--	loaded by default?
	}
end

--------------------------------------------------------------------

local unusedwidgets = {
	[[Community Window]],
	[[Planetwars List Window]],
	[[ZK Comm Config]],
	[[SpringBoard Window]],
	[[Queue status panel]],
	[[Chili Visual Novel]],
	[[Benchmark Handler]],
	[[Campaign Technology Panel]],
	[[Party status panel]],
	[[Campaign Options Window]],
	[[Campaign Handler ZK]],
	[[Campaign Commander Loadout]],
	[[Campaign Handler]],
	[[Campaign Save/Load]],
	[[Codex Handler]],
	[[Tutorial Handler]],
	[[Planet Battle Handler]],
	[[ZK replay downloader]],
	[[Rank update window]],
	[[Missions Handles]],
	[[bad widgets too]],
	-- [[Discord Handler]], -- cant disable api widget?
}

function widget:Initialize()
end

local removedwidgets = {}

function widget:Update()
	for i, widgetname in ipairs(unusedwidgets) do 
		
		local wijjit = widgetHandler:FindByName(widgetname)
		if wijjit then
			--Spring.Echo("Disable NonBar Widgets:", widgetname)
			removedwidgets[#removedwidgets+1] = widgetname
			widgetHandler:RemoveWidget(wijjit)
		end
	end
	Spring.Echo("Disabled NonBar Widgets:", table.concat(removedwidgets, ","))
	
	widgetHandler:RemoveWidget(widgetHandler:FindByName("Disable NonBar Widgets"))
end

