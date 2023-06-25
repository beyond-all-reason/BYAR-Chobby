function widget:GetInfo()
	return {
		name    = "Spring-Launcher log-upload",
		desc    = "spring-launcher log uploading functionality",
		author  = "gajop",
		date    = "really late",
		license = "MIT",
		layer   = -10000,
		enabled = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

-- init
function widget:Initialize()
	if WG.Connector == nil or not WG.Connector.enabled then
		widgetHandler:RemoveWidget()
		Spring.Log("Chobby", LOG.NOTICE, "spring-launcher doesn't exist.")
		return
	end


	WG.Connector.Register('UploadLogFinished', function(command)
		local url = command.url
		local txt = 'Log uploaded to: ' .. tostring(url) .. " (Copied to clipboard)"
		WG.Chotify:Post({
			body = txt,
			title = "Log Uploaded",
			time = 15,
		})
		Spring.SetClipboard(url)
	end)

	WG.Connector.Register('UploadLogFailed', function(command)
		local msg = command.msg
		local txt = "\255\255\20\50Upload failed\b: " .. msg ..  "\n\255\255\255\255Please upload the log manually\b"
		WG.Chotify:Post({
			body = txt,
			title = "Log upload failed",
			time = 20,
		})
	end)
end

