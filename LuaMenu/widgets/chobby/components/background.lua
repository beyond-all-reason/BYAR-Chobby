Background = LCS.class{}

function Background:init(imageOverride, colorOverride, backgroundFocus, alphaSettingName, alphaSettingInvert)
	self.colorOverride = colorOverride
	if imageOverride then
		self.imageOverride = imageOverride
		self.backgroundFocus = backgroundFocus
	end
	self:Enable()

	local function onConfigurationChange(listener, key, value)
		if (not imageOverride) and key == "gameConfigName" then
			self:SetDefaultImage()
		end
		if key == alphaSettingName then
			if alphaSettingInvert then
				value = 1 - value
			end
			self:SetAlpha(value)
		end
	end
	Configuration:AddListener("OnConfigurationChange", onConfigurationChange)
end

function Background:SetDefaultImage()
	local file = Configuration.gameConfig.background.image
	self.backgroundImage.file = file
	self.backgroundFocus = Configuration.gameConfig.background.backgroundFocus
	local texInfo = gl.TextureInfo(file)
	self.width, self.height = texInfo.xsize, texInfo.ysize
	self.backgroundControl:Invalidate()
	self:Resize()
end

function Background:SetAlpha(newAlpha)
	if self.backgroundImage then
		self.backgroundImage.color[4] = newAlpha
		self.backgroundImage:Invalidate()
	end
end

function Background:SetImageOverride(imageOverride)
	self.imageOverride = imageOverride
	self.backgroundImage.file = imageOverride

	local texInfo = gl.TextureInfo(imageOverride)
	self.width, self.height = texInfo.xsize, texInfo.ysize
	self.backgroundControl:Invalidate()
end

function Background:SetBoundOverride(imageBoundOverride)
	-- Only set bounds if the image is overridden, otherwise the default image can behave weirdly.
	if self.imageOverride then
		self.imageBoundOverride = imageBoundOverride
	end
end

function Background:RemoveOverride()
	self.imageOverride = nil
	self.imageBoundOverride = nil
	self:SetDefaultImage()
end

function Background:ResizeAspectWindow(windowX, windowY, windowWidth, windowHeight)
	local backgroundControl = self.backgroundControl

	if not self.imageBoundOverride then
		return false
	end

	local imageSizeX, imageSizeY = self.width, self.height
	if not (imageSizeX and imageSizeY) then
		return false
	end
	local winSizeX, winSizeY = Spring.GetWindowGeometry()

	if winSizeX <= 0 or winSizeY <= 0 or imageSizeX <= 0 or imageSizeY <= 0 then
		return false
	end

	local imageBound = self.imageBoundOverride
	local imageWidth = imageSizeX*imageBound.width
	local imageHeight = imageSizeY*imageBound.height

	local xOffset, yOffset = 0, 0

	local imageRatio = windowWidth*imageHeight/(windowHeight*imageWidth)
	if imageRatio > 1 then
		local newWidth = windowHeight*imageWidth/imageHeight
		xOffset = (windowWidth - newWidth)/2
		windowX = windowX + xOffset
		windowWidth = newWidth
	else
		local newHeight = windowWidth*imageHeight/imageWidth
		yOffset = (windowHeight - newHeight)/2
		windowY = windowY + yOffset
		windowHeight = newHeight
	end

	imageWidth = windowWidth/imageBound.width
	imageHeight = windowHeight/imageBound.height

	local imageX = windowX - imageWidth*imageBound.x
	local imageY = windowY - imageHeight*imageBound.y

	self.backgroundImage:SetPos(imageX, imageY, imageWidth, imageHeight)
	return xOffset, yOffset, windowWidth, windowHeight
end

function Background:Resize(backgroundControl)
	backgroundControl = backgroundControl or self.backgroundControl
	if not (self.backgroundImage and self.backgroundFocus) then
		return
	end

	if self.imageBoundOverride then
		return
	end

	local width, height = self.width, self.height
	if not (width and height) then
		return
	end
	local xSize, ySize = Spring.GetWindowGeometry()

	local xFocus, yFocus = self.backgroundFocus[1], self.backgroundFocus[2]

	local p1, p2, p3, p4
	if ySize * width == xSize * height then
		p1 = 0
		p2 = 0
		p3 = 0
		p4 = 0
	elseif ySize * width > xSize * height then
		-- Screen is thinner than image.
		local padding = (xSize - width * ySize/height)
		p1 = xFocus * padding
		p2 = 0
		p3 = (1 - xFocus) * padding
		p4 = 0
	else
		-- Screen is wider than image.
		local padding = (ySize - height * xSize/width)
		p1 = 0
		p2 = yFocus * padding
		p3 = 0
		p4 = (1 - yFocus) * padding
	end
	self.backgroundImage:SetPos(p1, p2, xSize - p1 - p3, ySize - p2 - p4)
end

function Background:SetEnabled(enable)
	if enable then
		self:Enable()
	else
		self:Disable()
	end
end

function Background:Enable()
	if not self.backgroundControl then
		local imageFile
		if self.imageOverride then
			imageFile = self.imageOverride
		else
			imageFile = Configuration.gameConfig.background.image
			self.backgroundFocus = Configuration.gameConfig.background.backgroundFocus
		end
		local texInfo = gl.TextureInfo(imageFile)
		self.width, self.height = texInfo.xsize, texInfo.ysize

		self.backgroundImage = Image:New {
			x = 0,
			y = 0,
			right = 0,
			bottom = 0,
			padding = {0,0,0,0},
			margin = {0,0,0,0},
			color = self.colorOverride,
			keepAspect = false,
			file = imageFile,
		}

		self.backgroundControl = Control:New {
			x = 0,
			y = 0,
			right = 0,
			bottom = 0,
			padding = {0,0,0,0},
			margin = {0,0,0,0},
			parent = screen0,
			children = {
				self.backgroundImage
			},
			OnResize = {
				function (obj)
					self:Resize(obj)
				end
			},
		}
	end
	if not self.backgroundImage.visible then
		self.backgroundImage:Show()
	end
end

function Background:Disable()
	if self.backgroundImage and self.backgroundImage.visible then
		self.backgroundImage:Hide()
	end
end
