local settings = {
	FontSize = 18,
	OverheadMaxHeightFactor = 1.4,
	HangTimeout = 30,
	ROAM = 1,
	SplashScreenDir = "./MenuLoadscreens",
	UseDistToGroundForIcons = 1.1,
	UseLuaMemPools = 0,
	LuaGarbageCollectionMemLoadMult = 100,
	VFSCacheArchiveFiles = 0,
}

local onlyIfMissingSettings = {
	FeatureDrawDistance = 600000,
	FeatureFadeDistance = 600000,
	UseNetMessageSmoothingBuffer = 0,
	NetworkLossFactor = 2,
	LinkOutgoingBandwidth= 262144,
	LinkIncomingSustainedBandwidth = 262144,
	LinkIncomingPeakBandwidth = 262144,
	LinkIncomingMaxPacketRate = 2048,
}

return settings, onlyIfMissingSettings
