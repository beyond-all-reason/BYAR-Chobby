Downloader = Component:extends{}

function Downloader:init(buttonsMode, tbl, timeout, updateListener, completeListener, queueFont, visibleListener)
	self:super("init")

	self.wrapperAsFallback = false

	queueFont = queueFont or 1
	self.lblDownload = Label:New {
		x = 9 + ((buttonsMode and 75) or 0),
		y = 0 + ((buttonsMode and 8) or 0),
		right = 0,
		height = 20,
		align = "left",
		valign = "top",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(2),
		caption = "",
	}

	self.prDownload = Progressbar:New {
		x = 0,
		y = 24 + ((buttonsMode and 8) or 0),
		right = 0,
		height = 30,
		value = 0,
		objectOverrideFont = WG.Chobby.Configuration:GetButtonFont(10),
	}

	self.queueLabel = Label:New {
		x = 0,
		y = 60 + ((buttonsMode and 8) or 0),
		right = 0,
		height = 16,
		align = "left",
		valign = "center",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(queueFont),
		caption = "Queue:",
	}

	self.queueList = Label:New {
		x = 5,
		y = 80 + ((buttonsMode and 8) or 0),
		right = 0,
		bottom = 0,
		align = "left",
		valign = "top",
		objectOverrideFont = WG.Chobby.Configuration:GetFont(queueFont),
		caption = "",
	}

	self.window = Control:New(table.merge({
		caption = '',
		padding = {0, 0, 0, 0},
		resizable = false,
		draggable = false,
		children = {
			self.lblDownload,
			self.prDownload,
			self.queueLabel,
			self.queueList,
		},
	}, tbl))

	self.buttonsMode = buttonsMode
	if buttonsMode then
		local function CancelFunc()
			if not (self.startedDownload and self.downloads[self.startedDownload]) then
				return
			end
			local download = self.downloads[self.startedDownload]
			WG.DownloadHandler.CancelDownload(download.archiveName, download.archiveType)
		end

		self.cancelButton = Button:New {
			x = 1,
			y = 1,
			height = 30,
			width = 85,
			caption = "Cancel",
			classname = "negative_button",
			objectOverrideFont = Configuration:GetButtonFont(2),
			OnClick = {
				CancelFunc
			},
			parent = self.window,
		}
		self.cancelButton:Hide()
	end

	self.lblDownload:Hide()
	self.prDownload:Hide()
	self.queueLabel:Hide()
	self.queueList:Hide()

	self.duplicateDownloads = {}

	self.downloads = {}
	self._lastUpdate = Spring.GetTimer()
	self.delayID = 0
	self.timeout = timeout
	self.updateListener = updateListener
	self.completeListener = completeListener
	self.visibleListener = visibleListener

	WG.DownloadHandler.AddListener("DownloadProgress", function (...) self:DownloadProgress(...) end)
	WG.DownloadHandler.AddListener("DownloadStarted", function (...) self:DownloadStarted(...) end)
	WG.DownloadHandler.AddListener("DownloadFinished", function (...) self:DownloadFinished(...) end)
	WG.DownloadHandler.AddListener("DownloadFailed", function (...) self:DownloadFailed(...) end)
	WG.DownloadHandler.AddListener("DownloadQueued", function (...) self:DownloadQueued(...) end)
end

function Downloader:UpdateQueue()
	local downloadCount = 0
	local failure = false

	local queueText = false
	for downloadID, data in pairs(self.downloads) do
		downloadCount = downloadCount + 1
		if not data.started and not data.complete then
			local text = data.archiveName
			if data.failed then
				failure = true
				text = Configuration:GetErrorColor() .. "*" .. text .. "*" .. Configuration:GetNormalColor()
			end
			if queueText then
				queueText = queueText .. "\n" .. text
			else
				if not self.queueLabel.visible then
					self.queueLabel:Show()
					self.queueList:Show()
				end
				queueText = text
			end
		end
	end

	if queueText then
		self.queueList:SetCaption(queueText)
	else
		if self.queueLabel.visible then
			self.queueLabel:Hide()
			self.queueList:Hide()
		end
	end

	if self.updateListener then
		self.updateListener(downloadCount, failure)
	end

	if self.visibleListener then
		self.visibleListener(true)
	end
end

function Downloader:Hide()
	if self.prDownload.visible then
		self.lblDownload:Hide()
		self.prDownload:Hide()
	end
	if self.visibleListener then
		self.visibleListener(false)
	end
end

function Downloader:_CleanupDownload(myDelayID)
	if myDelayID and (self.delayID ~= myDelayID) then
		return
	end

	for downloadID, data in pairs(self.downloads) do
		if data.failed or data.complete then
			self.downloads[downloadID] = nil
		end
	end
	self:UpdateQueue()

	for _, _ in pairs(self.downloads) do
		return -- don't hide progress bar if there are active downloads
	end
-- 	if window.disposed then
-- 		return
-- 	end
	self.prDownload:SetVisibility(false)
	self.lblDownload:SetVisibility(false)
	if self.cancelButton then
		self.cancelButton:SetVisibility(false)
	end
	if self.visibleListener then
		self.visibleListener(false)
	end
end

-- util function to round to decimal spaces
function round2(num, idp)
  return string.format("%." .. (idp or 0) .. "f", num)
end

function Downloader:DownloadProgress(listener, downloadID, downloaded, total)
	if not self.downloads[downloadID] then
		return
	end
	local currentTime = Spring.GetTimer()
	if self._lastUpdate and Spring.DiffTimers(currentTime, self._lastUpdate) < 0.5 or total == 0 then
		return
	end

	self._lastUpdate = currentTime

	-- round to one decimal
	local totalStr = round2(total, 1)
	local downloadedStr = round2(downloaded, 1)

	self.prDownload:SetCaption(downloadedStr .. "/" .. totalStr .. " MB")
	self.prDownload:SetValue(100 * downloaded / total)
end

function Downloader:DownloadStarted(listener, downloadID)
	if not self.downloads[downloadID] then
		return
	end
	self.prDownload:SetVisibility(true)
	self.lblDownload:SetVisibility(true)
	if self.cancelButton then
		self.cancelButton:SetVisibility(true)
	end
	self.lblDownload:SetCaption(self.downloads[downloadID].archiveName)
	self.downloads[downloadID].started = true
	self.startedDownload = downloadID
	self:UpdateQueue()
end

function Downloader:DownloadFinished(listener, downloadID)
	if not (downloadID and self.downloads[downloadID]) then
		return
	end
	self.downloads[downloadID].complete = true
	if self.completeListener then
		self.completeListener(self.downloads[downloadID].archiveName, self.downloads[downloadID].archiveType, true)
	end

	if self.duplicateDownloads[self.downloads[downloadID].archiveName] then
		if WG.WrapperLoopback and WG.WrapperLoopback.DownloadFile then
			WG.WrapperLoopback.DownloadFile(self.downloads[downloadID].archiveName, ((self.downloads[downloadID].archiveType == "map") and "MAP") or "RAPID")
			Chotify:Post({
				title = "Download Failed",
				body = "Starting backup download for " .. (self.downloads[downloadID].archiveName or "???"),
			})
		end
	else
		self.duplicateDownloads[self.downloads[downloadID].archiveName] = true
	end
	self.prDownload:SetCaption("\255\0\255\0Download complete.\b")

	-- Effectively a reimplementation of SignalMask from LUS
	if self.timeout then
		self.delayID = self.delayID + 1
		local thisDelayID = self.delayID
		WG.Delay(function() self:_CleanupDownload(thisDelayID) end, self.timeout)
	else
		self:_CleanupDownload()
	end
	self:UpdateQueue()
end

function Downloader:DownloadFailed(listener, downloadID, errorID)
	if not (downloadID and self.downloads[downloadID]) then
		return
	end
	self.downloads[downloadID].failed = true
	if self.completeListener then
		self.completeListener(self.downloads[downloadID].archiveName, self.downloads[downloadID].archiveType, false)
	end

	if self.wrapperAsFallback and WG.WrapperLoopback and WG.WrapperLoopback.DownloadFile then
		WG.WrapperLoopback.DownloadFile(self.downloads[downloadID].archiveName, ((self.downloads[downloadID].archiveType == "map") and "MAP") or "RAPID")
		Chotify:Post({
			title = "Download Failed",
			body = "Starting backup download for " .. (self.downloads[downloadID].archiveName or "???"),
		})
	end

	self.prDownload:SetCaption("\255\255\0\0Download failed [".. errorID .."].\b")

	-- Effectively a reimplementation of SignalMask from LUS
	if self.timeout then
		self.delayID = self.delayID + 1
		local thisDelayID = self.delayID
		WG.Delay(function() self:_CleanupDownload(thisDelayID) end, self.timeout)
	else
		self:_CleanupDownload()
	end
	self:UpdateQueue()
end

function Downloader:DownloadQueued(listener, downloadID, archiveName, archiveType, resource)
	self.downloads[downloadID] = {
		archiveName = archiveName,
		archiveType = archiveType,
		resource = resource,
		startTime = os.clock() }
	self:UpdateQueue()
end
