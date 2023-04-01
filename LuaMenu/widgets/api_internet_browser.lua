--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Internet Browser API",
		desc      = "Provides the interface for opening URLs and interacting with a browser.",
		author    = "GoogleFrog",
		date      = "22 September 2016",
		license   = "GNU LGPL, v2.1 or later",
		layer     = -10000,
		enabled   = true  --  loaded by default?
	}
end

local urlPattern = "https?://[%w-_%.%?%.:/%+=&]+"

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utilities

local function IsZkSiteUrl(urlString)
	if string.find(urlString, "http://zero%-k%.info/") == 1 then
		return true
	end
	if string.find(urlString, "http://zero%-k%.info") == 1 and string.len(urlString) == 18 then
		return true
	end
	if string.find(urlString, "https://zero%-k%.info/") == 1 then
		return true
	end
	if string.find(urlString, "https://zero%-k%.info") == 1 and string.len(urlString) == 19 then
		return true
	end
	return false
end

local function ApplySessionToken(urlString)
	if not IsZkSiteUrl(urlString) then
		return urlString, false
	end
	local lobby = WG.LibLobby.lobby
	--if lobby:GetMyIsAdmin() then
	--	return urlString, false -- Don't use tokens for admins
	--end
	local token = lobby:GetMySessionToken()
	local isWiki = string.find(urlString, "/mediawiki/")
	if isWiki or (not token) then
		return urlString, not isWiki -- MediaWiki does not need token.
	end
	local alreadyAddedPos = string.find(urlString, "%?asmallcake=")
	if alreadyAddedPos then
		return string.sub(urlString, 0, alreadyAddedPos) .. token, false
	end
	local hasQuestionMark = string.find(urlString, "%?")
	if hasQuestionMark then
		return urlString .. "&asmallcake=" .. token, false
	end
	return urlString .. "?asmallcake=" .. token, false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- External Functions
local BrowserHandler = {}

function BrowserHandler.OpenUrl(rawUrlString)
	local urlString, needLogin = ApplySessionToken(rawUrlString)
	local Configuration = WG.Chobby.Configuration
	if WG.WrapperLoopback then
		if needLogin then
			local function TryClickAgain()
				WG.BrowserHandler.OpenUrl(rawUrlString)
			end
			local function DelayedTryClickAgain()
				WG.Delay(TryClickAgain, 0.05)
			end
			local function LoginFunc()
				WG.LoginWindowHandler.TryLogin(DelayedTryClickAgain)
			end
			local function GoAnywayFunc()
				WG.SteamHandler.OpenUrlIfActive(urlString)
			end
			WG.Chobby.ConfirmationPopup(LoginFunc, "Log in first to access more site features.", nil, 315, 200, "Log In", "Not Now", GoAnywayFunc)
		else
			WG.SteamHandler.OpenUrlIfActive(urlString)
		end
	else
		Spring.SetClipboard(urlString)
		WG.TooltipHandler.TooltipOverride("URL copied " .. urlString, 1)
	end
end

function BrowserHandler.AddClickableUrls(chatString, onTextClick, textTooltip)

	local urlStart, urlEnd = string.find(chatString, "http[^%s]*")
	--Spring.Echo("URL urlStart, urlEnd", chatString, urlStart, urlEnd)
	while urlStart do
		-- Cull end puncuation
		local endChar = string.sub(chatString, urlEnd, urlEnd)
		if string.find(endChar, "%p") then
			urlEnd = urlEnd - 1
		end

		local urlString = string.sub(chatString, urlStart, urlEnd)

		onTextClick[#onTextClick + 1] = {
			startIndex = urlStart,
			endIndex = urlEnd,
			OnTextClick = {
				function()
					BrowserHandler.OpenUrl(urlString)
				end
			}
		}

		textTooltip[#textTooltip + 1] = {
			startIndex = urlStart,
			endIndex = urlEnd,
			tooltip = urlString,
		}

		urlStart, urlEnd = string.find(chatString, urlPattern, urlEnd)
	end

	return onTextClick, textTooltip
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

function widget:Initialize()
	WG.BrowserHandler = BrowserHandler
end
