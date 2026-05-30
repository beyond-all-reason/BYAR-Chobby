PartyWindow = LCS.class{}

PartyWindow.RIGHT_MARGIN = 20
PartyWindow.LEFT_MARGIN = 20
PartyWindow.TOP_MARGIN = 17
PartyWindow.BOTTOM_MARGIN = 0

PartyWindow.TITLE_HEIGHT = 20
PartyWindow.SECTION_HEADER_HEIGHT = 15 -- font1 size

PartyWindow.MINOR_SPACING = 5
PartyWindow.MAJOR_SPACING = 20

PartyWindow.BUTTON_WIDTH = 100

PartyWindow.HEADER_HEIGHT = 57
PartyWindow.CONTENT_Y_OFFSET = 0
PartyWindow.NOTIFICATION_SOUND = "sounds/Alarm_light5_mixdown.wav" --same sfx as RING

local function ChobbyReady()
	return WG.Chobby ~= nil and WG.Chobby.Configuration ~= nil
end

function PartyWindow:GetPendingInviteCount()
    if not lobby or not lobby.parties or not lobby.myUserName then
        return 0
    end

    local inviteCount = 0
    for partyID, party in pairs(lobby.parties) do
        if partyID ~= lobby.myPartyID and party.invites and party.invites[lobby.myUserName] then
            inviteCount = inviteCount + 1
        end
    end
    return inviteCount
end

function PartyWindow:UpdatePartyTabActivity()

    if not interfaceRoot or not interfaceRoot.GetRightPanelHandler then
        return
    end
    local inviteCount = self:GetPendingInviteCount()
    interfaceRoot.GetRightPanelHandler().SetActivity("parties", inviteCount, (inviteCount > 0 and 2) or 1)
end

function PartyWindow:GetInviteSenderName(partyID)
    local party = lobby and lobby.parties and lobby.parties[partyID]
    if not party or not party.members then
        return nil
    end
    for userName in pairs(party.members) do
        if userName ~= lobby.myUserName then
            return userName
        end
    end
    return nil
end

function PartyWindow:NotifyIncomingInvite(partyID)
    if not ChobbyReady() or not WG.Chobby.Configuration:AllowNotification() then
        return
    end

    local function PostInviteNotification(senderName)
        if not ChobbyReady() then
            return
        end
        local body = senderName and (senderName .. " has invited you to their party") or i18n("party_invite")
        Chotify:Post({
            title = i18n("party"),
            body = body,
            sound = PartyWindow.NOTIFICATION_SOUND,
            soundVolume = WG.Chobby.Configuration.menuNotificationVolume or 1,
        })
    end

    -- Delay so party member data has time to populate and inviter name can be retrieved
    -- if delay removed or player cannot be fetched it defaults to a generic "party invite" message
    WG.Delay(function()
        if not ChobbyReady() then
            return
        end
        local senderName = self:GetInviteSenderName(partyID)
        PostInviteNotification(senderName)
    end, 0.3)
end

function PartyWindow:NotifyInviteAccepted(userName)
    if not ChobbyReady() or not WG.Chobby.Configuration:AllowNotification() then
        return
    end

    Chotify:Post({
        title = i18n("party"),
        body = userName .. " has joined your party",
        sound = PartyWindow.NOTIFICATION_SOUND,
        soundVolume = WG.Chobby.Configuration.menuNotificationVolume or 1,
    })
end

function PartyWindow:init(parent)
    self.window = Control:New{
        x = 0,
        right = 0,
        y = 0,
        bottom = 0,
        padding = { 0, 0, 0, 0 },
        parent = parent,
        resizable = false,
        draggable = false,
        classname = "PartyWindow"
    }

    Label:New {
        x = PartyWindow.LEFT_MARGIN,
        y = PartyWindow.TOP_MARGIN,
        height = PartyWindow.TITLE_HEIGHT,
        right = PartyWindow.RIGHT_MARGIN + PartyWindow.BUTTON_WIDTH + PartyWindow.MAJOR_SPACING,
        parent = self.window,
        objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
        caption = i18n("parties"),
    }

    self.requiresLoginLabel = Label:New {
        x = PartyWindow.LEFT_MARGIN,
        y = 42,
        objectOverrideFont = WG.Chobby.Configuration:GetFont(1, "parties_require_login"),
        parent = self.window,
        caption = "\255\138\138\138" .. i18n("parties_require_login")
    }

    self.createPartyButton = Button:New {
        caption = i18n("create_new_party"),
        parent = self.window,
        right = PartyWindow.RIGHT_MARGIN,
        width = PartyWindow.BUTTON_WIDTH,
        y = 15,
        height = 30,
        classname = "option_button",
        visible = false,
        OnClick = {
            function()
                if lobby.myPartyID then
                    self:LeaveMyCurrentParty()
                end
                lobby:CreateParty(
                    nil,
                    function(errorMessage)
                        ErrorPopup(i18n("error_party_create_failed", { error_message = errorMessage }))
                    end
                )
            end
        },
    }
    self.createPartyButton:Hide()

    self.contentScrollPanel = ScrollPanel:New {
        x = 12,
        right = 12,
        y = PartyWindow.HEADER_HEIGHT,
        bottom = 16,
        horizontalScrollbar = false,
        padding = {4, 4, 4, 4},
        borderColor = {0, 0, 0, 0},
        parent = self.window,
    }

    -- In a party

    self.yourPartyLabel = Label:New {
        y = PartyWindow.CONTENT_Y_OFFSET,
        caption = i18n("your_party_title"),
        parent = self.contentScrollPanel,
    }
    self.yourPartyLabel:Hide()

    self.invitesLabel = Label:New {
        caption = i18n("your_party_invites"),
        parent = self.contentScrollPanel,
    }
    self.invitesLabel:Hide()

    self.partyWrappers = {}

    lobby:AddListener("OnAccepted", function()
        self.requiresLoginLabel:Hide()
        self.createPartyButton:Show()
        self:UpdatePartyTabActivity()
    end)

    lobby:AddListener("OnDisconnected", function()
        self.requiresLoginLabel:Show()
        self.createPartyButton:Hide()
        self.invitesLabel:Hide()
        self.yourPartyLabel:Hide()

        for partyID, partyWrapper in pairs(self.partyWrappers) do
            partyWrapper.wrapper:Dispose()
            self.partyWrappers[partyID] = nil
        end
        self:UpdatePartyTabActivity()
    end)

    lobby:AddListener("OnRemoveUser", function(_, username)
        for partyID, partyWrapper in pairs(self.partyWrappers) do
            if partyWrapper.inviteRows[username] then
                partyWrapper:RemoveInvite(username)
            end
        end
        self:UpdatePartyTabActivity()
    end)

    lobby:AddListener("OnJoinedParty", function(_, ...)
        self:JoinedParty(...)
    end)

    lobby:AddListener("OnLeftParty", function(_, ...)
        self:LeftParty(...)
    end)

    lobby:AddListener("OnInvitedToParty", function(_, ...)
        self:InvitedToParty(...)
    end)

    lobby:AddListener("OnPartyInviteCancelled", function(_, ...)
        self:InviteToPartyCancelled(...)
    end)

    self:UpdatePartyTabActivity()
end

function PartyWindow:UpdateLayout()
    local offset = PartyWindow.CONTENT_Y_OFFSET

    if lobby.myPartyID then
        local myPartyWrapper = self.partyWrappers[lobby.myPartyID]
        if myPartyWrapper then
            offset = myPartyWrapper.wrapper.y +
                     myPartyWrapper:TotalHeight() +
                     PartyWindow.MINOR_SPACING
        end
    end

    self.invitesLabel:SetPos(0, offset)
    self.invitesLabel:Hide()

    offset = offset + PartyWindow.SECTION_HEADER_HEIGHT + PartyWindow.MINOR_SPACING

    for partyID, partyWrapper in pairs(self.partyWrappers) do
        if partyID ~= lobby.myPartyID then
            self.invitesLabel:Show()
            partyWrapper.wrapper:SetPos(0, offset)
            offset = offset + partyWrapper:TotalHeight() + PartyWindow.MINOR_SPACING
        end
    end
end

function PartyWindow:LeaveMyCurrentParty()
    local myPartyID = lobby.myPartyID
    lobby:LeaveMyCurrentParty(nil, 
    function(errorMessage)
        ErrorPopup(i18n("error_party_leave_failed", { error_message = errorMessage }))
    end)
end

function PartyWindow:LeftParty(partyID, username, partyDestroyed)
    if partyDestroyed then
        self.partyWrappers[partyID].wrapper:Dispose()
        self.partyWrappers[partyID] = nil
        if username == lobby.myUserName then
            self.yourPartyLabel:Hide()
        end
    else
        self.partyWrappers[partyID]:RemoveMember(username)
    end

    self:UpdateLayout()
    self:UpdatePartyTabActivity()
end
function PartyWindow:JoinedParty(partyID, username)
    local partyWrapper = self.partyWrappers[partyID] or PartyWrapper(self.contentScrollPanel, partyID)
    local wasInvited = partyWrapper.inviteRows and partyWrapper.inviteRows[username]

    if username == lobby.myUserName then
        partyWrapper:ClearActionButtons()
        partyWrapper:AddActionButton(i18n("leave_my_party"), "negative_button", function() self:LeaveMyCurrentParty() end)

        partyWrapper.wrapper:SetPos(0, PartyWindow.CONTENT_Y_OFFSET + PartyWindow.SECTION_HEADER_HEIGHT + PartyWindow.MINOR_SPACING)
        partyWrapper.wrapper:Show()
        self.yourPartyLabel:Show()
    end
    
    partyWrapper:RemoveInvite(username)
    partyWrapper:AddMember(username)
    
    self.partyWrappers[partyID] = partyWrapper

    if partyID == lobby.myPartyID and username ~= lobby.myUserName and wasInvited then
        self:NotifyInviteAccepted(username)
    end

    self:UpdateLayout()
    self:UpdatePartyTabActivity()
end
function PartyWindow:InvitedToParty(partyID, username)
    if username == lobby.myUserName then
        -- Invite targeted at us: show actions (accept/decline) and notification.
        self:NotifyIncomingInvite(partyID)
        self.partyWrappers[partyID] = PartyWrapper(self.contentScrollPanel, partyID)
        self.partyWrappers[partyID]:AddActionButton(i18n("accept_party_invite"), "positive_button", function() 
            if lobby.myPartyID then
                self:LeaveMyCurrentParty()
            end
            lobby:AcceptInviteToParty(
                partyID,
                nil, 
                function(errorMessage)
                    ErrorPopup(i18n("error_party_accept_invite_failed", { error_message = errorMessage }))
                end
            )
        end)

        self.partyWrappers[partyID]:AddActionButton(i18n("decline_party_invite"), "negative_button",
            function() 
                lobby:DeclineInviteToParty(
                    partyID,
                    nil, 
                    function(errorMessage)
                        ErrorPopup(i18n("error_party_decline_invite_failed", { error_message = errorMessage }))
                    end
                )
            end
        )

        self.partyWrappers[partyID].wrapper:Show()
        self.invitesLabel:Show()
    else
        self.partyWrappers[partyID]:AddInvite(username)
    end

    self:UpdateLayout()
    self:UpdatePartyTabActivity()
end
function PartyWindow:InviteToPartyCancelled(partyID, username)
    if not self.partyWrappers[partyID] then
        self:UpdatePartyTabActivity()
        return
    end
    self.partyWrappers[partyID]:RemoveInvite(username)

    if username == lobby.myUserName then
        self.partyWrappers[partyID].wrapper:Dispose()
        self.partyWrappers[partyID] = nil
    end

    self:UpdateLayout()
    self:UpdatePartyTabActivity()
end
