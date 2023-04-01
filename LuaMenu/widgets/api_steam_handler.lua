--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:GetInfo()
	return {
		name      = "Steam Handler",
		desc      = "Handles steam connection, friends etc..",
		author    = "GoogleFrog",
		date      = "4 February 2017",
		license   = "GPL-v2",
		layer     = 0,
		handler   = true,
		enabled   = true,
	}
end

local storedFriendList
local storedJoinFriendID

local steamFriendByID = {}
local overlayActive = false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utilities

local function AddSteamFriends(friendIDList)
	if not friendIDList then
		return
	end
	local lobby = WG.LibLobby.lobby
	for i = 1, #friendIDList do
		local userName = lobby:GetUserNameBySteamID(friendIDList[i])
		lobby:FriendRequest(userName, friendIDList[i])
	end
end

local function JoinFriend(friendID)
	if not friendID then
		return
	end
	local lobby = WG.LibLobby.lobby
	local userName = lobby:GetUserNameBySteamID(friendID)
	if not userName then
		-- Friend not online.
		return
	end
	--lobby:InviteToParty(userName) -- Do not do join server party, it is confusing.

	local userInfo = lobby:GetUser(userName) or {}
	if userInfo.battleID then
		WG.Chobby.interfaceRoot.TryToJoinBattle(userInfo.battleID)
	end
end

local listenersInitialized = false
local function InitializeListeners()
	local lobby = WG.LibLobby.lobby
	if listenersInitialized then
		return
	end
	listenersInitialized = true

	local function OnUsersSent()
		if storedFriendList then
			AddSteamFriends(storedFriendList)
			storedFriendList = nil
		end
		if storedJoinFriendID then
			JoinFriend(storedJoinFriendID)
			storedJoinFriendID = nil
		end
	end

	lobby:AddListener("OnFriendList", OnUsersSent) -- All users are present before FriendList is recieved.
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Externals Functions

local SteamHandler = {}

function SteamHandler.SteamOnline(authToken, joinFriendID, friendList, suggestedNameFromSteam, myDlc)
	local Configuration = WG.Chobby.Configuration
	if not Configuration then
		Spring.Echo("Loopback error: Sent steam before Configuration initialization")
		return
	end
	Spring.Echo("SteamOnline", "Received")
	Configuration:SetConfigValue("canAuthenticateWithSteam", true)
	Configuration:SetConfigValue("suggestedNameFromSteam", suggestedNameFromSteam)

	local lobby = WG.LibLobby.lobby
	if not lobby then
		Spring.Echo("Loopback error: Sent steam before lobby initialization")
		return
	end

	if authToken then
		lobby:SetSteamAuthToken(authToken)
	end
	if myDlc then
		lobby:SetSteamDlc(myDlc)
	end

	if storedFriendList then
		for i = 1, #storedFriendList do
			steamFriendByID[storedFriendList[i]] = true
		end
	end

	WG.LoginWindowHandler.TrySimpleSteamLogin()

	if lobby.status == "connected" then
		AddSteamFriends(storedFriendList)
	else
		storedFriendList = friendList
	end

end

function SteamHandler.SteamJoinFriend(joinFriendID)
	local lobby = WG.LibLobby.lobby
	if not lobby then
		Spring.Echo("Loopback error: Sent steam before lobby initialization")
		return
	end

	if lobby.status == "connected" then
		JoinFriend(joinFriendID)
	else
		storedJoinFriendID = joinFriendID
	end
end

function SteamHandler.InviteUserViaSteam(userName, steamID)
	if not steamID then
		local lobby = WG.LibLobby.lobby
		steamID = lobby:GetUser(userName).steamID
	end
	if steamID then
		WG.WrapperLoopback.SteamInviteFriendToGame(steamID)
	end
end

function SteamHandler.GetIsSteamFriend(steamID)
	return steamID and steamFriendByID[steamID]
end

function SteamHandler.SteamOverlayChanged(isActive)
	overlayActive = isActive
	WG.LimitFps.SetSteamFastUpdate(isActive)
	if not isActive then
		WG.LimitFps.ForceRedrawPeriod(3)
	end
end

function SteamHandler.OpenUrlIfActive(urlString)
	local Configuration = WG.Chobby.Configuration
	if Configuration.steamOverlayEnablable and Configuration.canAuthenticateWithSteam and Configuration.useSteamBrowser then
		WG.WrapperLoopback.SteamOpenWebsite(urlString)
		local function EnableFallback()
			if not overlayActive then
				WG.WrapperLoopback.OpenUrl(urlString)
			end
		end
		WG.Delay(EnableFallback, 0.5)
	else
		WG.WrapperLoopback.OpenUrl(urlString)
	end
end

function SteamHandler.OpenFriendList()
	local Configuration = WG.Chobby.Configuration
	if Configuration.steamOverlayEnablable and Configuration.canAuthenticateWithSteam then
		WG.WrapperLoopback.SteamOpenOverlaySection("LobbyInvite")
		local function EnableFallback()
			if not overlayActive then
				WG.Chobby.InformationPopup("The Steam overlay is disabled for performance reasons. Invite friends using the friend list in the Steam app.", {width = 380, height = 220})
			end
		end
		WG.Delay(EnableFallback, 0.5)
	else
		WG.Chobby.InformationPopup("The Steam overlay is disabled for performance reasons. Invite friends using the friend list in the Steam app.", {width = 380, height = 220})
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Initialization

function DelayedInitialize()
	InitializeListeners()
end

function widget:Initialize()
	WG.SteamHandler = SteamHandler
	WG.Delay(DelayedInitialize, 0.1)
end
