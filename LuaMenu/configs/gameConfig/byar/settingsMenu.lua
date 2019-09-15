local invertZoomMult = -1

local settingsConfig = {
	{
		name = "Graphics",
		presets = {
			{
				name = "Minimal",
				settings = {
					WaterType = "Basic",
					WaterQuality = "Low",
					DeferredRendering = "Off",
					Shadows = "None",
					ShadowDetail = "Low",
					ParticleLimit = "Minimal",
					TerrainDetail = "Minimal",
					VegetationDetail = "Minimal",
					--CompatibilityMode = "On",
					AntiAliasing = "Off",
					ShaderDetail = "Minimal",
					FancySky = "Off",
				}
			},
			{
				name = "Low",
				settings = {
					WaterType = "Refractive",
					WaterQuality = "Low",
					DeferredRendering = "Off",
					Shadows = "Units Only",
					ShadowDetail = "Low",
					ParticleLimit = "Low",
					TerrainDetail = "Low",
					VegetationDetail = "Low",
					--CompatibilityMode = "Off",
					AntiAliasing = "Off",
					ShaderDetail = "Low",
					FancySky = "Off",
				}
			},
			{
				name = "Medium",
				settings = {
					WaterType = "Refractive",
					WaterQuality = "Medium",
					DeferredRendering = "On",
					Shadows = "Units Only",
					ShadowDetail = "Medium",
					ParticleLimit = "Medium",
					TerrainDetail = "Medium",
					VegetationDetail = "Medium",
					--CompatibilityMode = "Off",
					AntiAliasing = "Off",
					ShaderDetail = "Medium",
					FancySky = "Off",
				}
			},
			{
				name = "High",
				settings = {
					WaterType = "Refractive",
					WaterQuality = "High",
					DeferredRendering = "On",
					Shadows = "Units and Terrain",
					ShadowDetail = "Medium",
					ParticleLimit = "High",
					TerrainDetail = "High",
					VegetationDetail = "High",
					--CompatibilityMode = "Off",
					AntiAliasing = "Low",
					ShaderDetail = "High",
					FancySky = "Off",
				}
			},
			{
				name = "Ultra",
				settings = {
					WaterType = "Refractive",
					WaterQuality = "High",
					DeferredRendering = "On",
					Shadows = "Units and Terrain",
					ShadowDetail = "Ultra",
					ParticleLimit = "Ultra",
					TerrainDetail = "Ultra",
					VegetationDetail = "Ultra",
					--CompatibilityMode = "Off",
					AntiAliasing = "High",
					ShaderDetail = "Ultra",
					FancySky = "On",
				}
			},
		},

		settings = {
			{
				name = "DisplayMode",
				humanName = "Display",
				displayModeToggle = true,
			},
			{
				name = "WaterType",
				humanName = "Water Type",
				options = {
					{
						name = "Basic",
						apply = {
							Water = 0,
						}
					},
					{
						name = "Reflective",
						apply = {
							Water = 1,
						}
					},
					{
						name = "Refractive",
						apply = {
							Water = 2,
						}
					},
					{
						name = "Dynamic",
						apply = {
							Water = 3,
						}
					},
					{
						name = "Bumpmapped",
						apply = {
							Water = 4,
						}
					},
				},
			},
			{
				name = "WaterQuality",
				humanName = "Water Quality",
				options = {
					{
						name = "Low",
						apply = {
							BumpWaterAnisotropy = 0,
							BumpWaterBlurReflection = 0,
							BumpWaterReflection = 0,
							BumpWaterRefraction = 0,
							BumpWaterDepthBits = 16,
							BumpWaterShoreWaves = 0,
							BumpWaterTexSizeReflection = 64,
						}
					},
					{
						name = "Medium",
						apply = {
							BumpWaterAnisotropy = 0,
							BumpWaterBlurReflection = 1,
							BumpWaterReflection = 1,
							BumpWaterRefraction = 1,
							BumpWaterDepthBits = 24,
							BumpWaterShoreWaves = 1,
							BumpWaterTexSizeReflection = 128,
						}
					},
					{
						name = "High",
						apply = {
							BumpWaterAnisotropy = 2,
							BumpWaterBlurReflection = 1,
							BumpWaterReflection = 2,
							BumpWaterRefraction = 1,
							BumpWaterDepthBits = 32,
							BumpWaterShoreWaves = 1,
							BumpWaterTexSizeReflection = 256,
						}
					},
				},
			},
			{
				name = "DeferredRendering",
				humanName = "Deferred Rendering",
				options = {
					{
						name = "On",
						apply = {
							AllowDeferredModelRendering = 1,
							AllowDeferredMapRendering = 1,
						}
					},
					{
						name = "Off",
						apply = {
							AllowDeferredModelRendering = 0,
							AllowDeferredMapRendering = 0,
						}
					},
				},
			},
			{
				name = "Shadows",
				humanName = "Shadows",
				options = {
					{
						name = "None",
						apply = {
							Shadows = 0
						}
					},
					{
						name = "Units Only",
						apply = {
							Shadows = 2
						}
					},
					{
						name = "Units and Terrain",
						apply = {
							Shadows = 1
						}
					},
				},
			},
			{
				name = "ShadowDetail",
				humanName = "Shadow Detail",
				options = {
					{
						name = "Low",
						apply = {
							ShadowMapSize = 1024
						}
					},
					{
						name = "Medium",
						apply = {
							ShadowMapSize = 2048
						}
					},
					{
						name = "High",
						apply = {
							ShadowMapSize = 4096
						}
					},
					{
						name = "Ultra",
						apply = {
							ShadowMapSize = 8192
						}
					},
				},
			},
			{
				name = "ParticleLimit",
				humanName = "Particle Limit",
				options = {
					{
						name = "Minimal",
						apply = {
							MaxParticles = 10000
						}
					},
					{
						name = "Low",
						apply = {
							MaxParticles = 15000
						}
					},
					{
						name = "Medium",
						apply = {
							MaxParticles = 20000
						}
					},
					{
						name = "High",
						apply = {
							MaxParticles = 30000
						}
					},
					{
						name = "Ultra",
						apply = {
							MaxParticles = 40000
						}
					},
				},
			},
			{
				name = "ShaderDetail",
				humanName = "Shader Detail",
				fileTarget = "lups.cfg",
				options = {
					{
						name = "Minimal",
						file = "LuaMenu/configs/gameConfig/byar/lups/lups0.cfg"
					},
					{
						name = "Low",
						file = "LuaMenu/configs/gameConfig/byar/lups/lups1.cfg"
					},
					{
						name = "Medium",
						file = "LuaMenu/configs/gameConfig/byar/lups/lups2.cfg"
					},
					{
						name = "High",
						file = "LuaMenu/configs/gameConfig/byar/lups/lups3.cfg"
					},
					{
						name = "Ultra",
						file = "LuaMenu/configs/gameConfig/byar/lups/lups4.cfg"
					},
				},
			},
			{
				name = "TerrainDetail",
				humanName = "Terrain Detail",
				options = {
					{
						name = "Minimal",
						apply = {
							GroundScarAlphaFade = 0,
							GroundDecals = 0,
							GroundDetail = 75,
						}
					},
					{
						name = "Low",
						apply = {
							GroundScarAlphaFade = 0,
							GroundDecals = 1,
							GroundDetail = 100,
						}
					},
					{
						name = "Medium",
						apply = {
							GroundScarAlphaFade = 1,
							GroundDecals = 2,
							GroundDetail = 120,
						}
					},
					{
						name = "High",
						apply = {
							GroundScarAlphaFade = 1,
							GroundDecals = 3,
							GroundDetail = 150,
						}
					},
					{
						name = "Ultra",
						apply = {
							GroundScarAlphaFade = 1,
							GroundDecals = 5,
							GroundDetail = 200,
						}
					},
				},
			},
			{
				name = "VegetationDetail",
				humanName = "Vegetation Detail",
				options = {
					{
						name = "Minimal",
						apply = {
							TreeRadius = 1000,
							GrassDetail = 0,
						}
					},
					{
						name = "Low",
						apply = {
							TreeRadius = 1000,
							GrassDetail = 1,
						}
					},
					{
						name = "Medium",
						apply = {
							TreeRadius = 1200,
							GrassDetail = 4,
						}
					},
					{
						name = "High",
						apply = {
							TreeRadius = 1500,
							GrassDetail = 7,
						}
					},
					{
						name = "Ultra",
						apply = {
							TreeRadius = 2500,
							GrassDetail = 10,
						}
					},
				},
			},
			{
				name = "FancySky",
				humanName = "Fancy Sky",
				options = {
					{
						name = "On",
						apply = {
							DynamicSky = 1,
							AdvSky = 1,
						}
					},
					{
						name = "Off",
						apply = {
							DynamicSky = 1,
							AdvSky = 1,
						}
					},
				},
			},
			--{
			--	name = "CompatibilityMode",
			--	humanName = "Compatibility Mode",
			--	options = {
			--		{
			--			name = "On",
			--			apply = {
			--				LoadingMT = 0,
			--				AdvUnitShading = 0,
			--				LuaShaders = 0,
			--				UsePBO = 0,
			--			}
			--		},
			--		{
			--			name = "Off",
			--			apply = {
			--				LoadingMT = 1,
			--				AdvUnitShading = 1,
			--				LuaShaders = 1,
			--				UsePBO = 1,
			--			}
			--		},
			--	},
			--},
			{
				name = "AntiAliasing",
				humanName = "Anti Aliasing",
				options = {
					{
						name = "Off",
						apply = {
							FSAALevel = 1,
							FSAA = 0,
							SmoothLines = 0,
						}
					},
					{
						name = "Low",
						apply = {
							FSAALevel = 1,
							FSAA = 1,
							SmoothLines = 1,
						}
					},
                    {
                        name = "Medium",
                        apply = {
                            FSAALevel = 2,
                            FSAA = 1,
                            SmoothLines = 2,
                        }
                    },
                    {
                        name = "High",
                        apply = {
                            FSAALevel = 4,
                            FSAA = 1,
                            SmoothLines = 3,
                        }
                    },
				},
			},
		},
	},
	{
		name = "Interface",
		presets = {
			{
				name = "Default",
				settings = {
					IconDistance = 151,
					MouseZoomSpeed = 25,
					InvertZoom = "On",
					MiddlePanSpeed = 10,
					CameraPanSpeed = 10,
				}
			},
		},
		settings = {
			{
				name = "IconDistance",
				humanName = "Icon Distance",
				isNumberSetting = true,
				applyName = "UnitIconDist",
				minValue = 0,
				maxValue = 10000,
				springConversion = function(value)
					return value
				end,
			},
			{
				name = "MouseZoomSpeed",
				humanName = "Mouse Zoom Speed",
				isNumberSetting = true,
				applyName = "ScrollWheelSpeed",
				minValue = 1,
				maxValue = 500,
				springConversion = function(value)
					return value*invertZoomMult
				end,
			},
			{
				name = "InvertZoom",
				humanName = "Invert Zoom",
				options = {
					{
						name = "On",
						applyFunction = function()
							if not WG.Chobby then
								return
							end
							invertZoomMult = 1
							local currentZoom = WG.Chobby.Configuration.settingsMenuValues["MouseZoomSpeed"] or 25
							return {
								ScrollWheelSpeed = currentZoom,
							}
						end
					},
					{
						name = "Off",
						applyFunction = function()
							if not WG.Chobby then
								return
							end
							invertZoomMult = -1
							local currentZoom = WG.Chobby.Configuration.settingsMenuValues["MouseZoomSpeed"] or 25
							return {
								ScrollWheelSpeed = currentZoom * -1,
							}
						end
					},
				},
			},
			{
				name = "MiddlePanSpeed",
				humanName = "Middle Click Pan Speed",
				isNumberSetting = true,
				applyName = "MiddleClickScrollSpeed",
				minValue = 0,
				maxValue = 1000,
				springConversion = function(value)
					return value*-1/2000
				end,
			},
			{
				name = "CameraPanSpeed",
				humanName = "Camera Pan Speed",
				isNumberSetting = true,
				applyName = "OverheadScrollSpeed",
				minValue = 0,
				maxValue = 1000,
				springConversion = function(value)
					return value
				end,
			},
		},
	},
}

local settingsDefault = {
	WaterType = "Refractive",
	WaterQuality = "High",
	DeferredRendering = "On",
	Shadows = "Units and Terrain",
	ShadowDetail = "Medium",
	ParticleLimit = "High",
	TerrainDetail = "High",
	VegetationDetail = "High",
	--CompatibilityMode = "Off",
	AntiAliasing = "Low",
	ShaderDetail = "High",
	FancySky = "Off",
	IconDistance = 151,
	MouseZoomSpeed = 25,
	InvertZoom = "Off",
	MiddlePanSpeed = 10,
	CameraPanSpeed = 10,
}

local settingsNames = {}
for i = 1, #settingsConfig do
	local subSettings = settingsConfig[i].settings
	for j = 1, #subSettings do
		local data = subSettings[j]
		settingsNames[data.name] = data
		if data.options then
			data.optionNames = {}
			for k = 1, #data.options do
				data.optionNames[data.options[k].name] = data.options[k]
			end
		end
	end
end

return {}, {}, {}	-- disabled graphics/interface settings, these settings are handled ingame

--return settingsConfig, settingsNames, settingsDefault