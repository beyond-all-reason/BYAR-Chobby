
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
	--[[Community Window]]
	[[Party status panel]],
	[[bad widgets too]],
	-- [[Discord Handler]], -- cant disable api widget?
}

function widget:Initialize()
end

local removedwidgets = {}

function widget:Update()
	if widgetHandler:FindByName("Image Preloader") then
		widgetHandler:DisableWidget("Image Preloader")
	end
	widgetHandler:EnableWidget("Rapid Pool Cache")
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

