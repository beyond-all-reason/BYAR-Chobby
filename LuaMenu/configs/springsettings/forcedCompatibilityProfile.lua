
if Platform then
	Spring.Echo("Vendor and GL", Platform.gpuVendor, string.sub(Platform.glVersionShort or "x", 1, 1))
	if Platform.gpuVendor == "Intel" and Platform.glVersionShort and string.sub(Platform.glVersionShort or "3", 1, 1) == "3" then
		Spring.Echo("Applying Intel gl version 3.x compatibility profile.")
		return {
			ForceDisableShaders = 1,
			Shadows = 0,
		}
	end
end

return false
