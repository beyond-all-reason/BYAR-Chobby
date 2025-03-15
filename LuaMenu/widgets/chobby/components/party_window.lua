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

PartyWindow.CONTENT_Y_OFFSET = PartyWindow.TITLE_HEIGHT + PartyWindow.MINOR_SPACING

function PartyWindow:init(parent)
    self.window = Window:New{
        x = 0,
        right = 0,
        y = 0,
        bottom = 0,
        padding = { PartyWindow.LEFT_MARGIN, PartyWindow.TOP_MARGIN, PartyWindow.RIGHT_MARGIN, PartyWindow.BOTTOM_MARGIN },
        parent = parent,
        resizable = false,
        draggable = false,
        classname = "PartyWindow"
    }

    Label:New {
        parent = self.window,
        objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
        caption = i18n("parties"),
    }

    self.requiresLoginLabel = Label:New {
        y = PartyWindow.CONTENT_Y_OFFSET,
        objectOverrideFont = WG.Chobby.Configuration:GetFont(1, "parties_require_login", { color = { 0.5, 0.5, 0.5, 1 } }),
        parent = self.window,
        caption = "(Requires login)"
    }

    self.createPartyButton = Button:New {
        caption = "Create Party",
        parent = self.window,
        right = 0,
        width = PartyWindow.BUTTON_WIDTH,
        classname = "option_button",
        visible = false,
        OnClick = {
            function()
                if lobby.myPartyID then
                    self:LeaveMyCurrentParty()
                end
                lobby:CreateParty()
            end
        },
    }
    self.createPartyButton:Hide()

    -- In a party

    self.yourPartyLabel = Label:New {
        y = PartyWindow.CONTENT_Y_OFFSET,
        caption = "Your Party",
        parent = self.window
    }
    self.yourPartyLabel:Hide()

    self.invitesLabel = Label:New {
        caption = "Your Invites:",
        parent = self.window
    }
    self.invitesLabel:Hide()

    self.partyWrappers = {}

    lobby:AddListener("OnAccepted", function()
        self.requiresLoginLabel:Hide()
        self.createPartyButton:Show()
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
end

function PartyWindow:UpdateLayout()
    local offset = PartyWindow.CONTENT_Y_OFFSET
    
    if lobby.myPartyID then
        local myPartyWrapper = self.partyWrappers[lobby.myPartyID]
        offset = myPartyWrapper.wrapper.y +
                 myPartyWrapper:TotalHeight() + 
                 PartyWindow.MINOR_SPACING
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
    lobby:LeaveMyCurrentParty(function()
        self.partyWrappers[myPartyID].wrapper:Dispose()
        self.partyWrappers[myPartyID] = nil
        self.yourPartyLabel:Hide()

        self:UpdateLayout()
    end)
end

function PartyWindow:LeftParty(partyID, username)
    if username == lobby.myUserName then
        self.partyWrappers[partyID].wrapper:Dispose()
        self.partyWrappers[partyID] = nil
    else
        self.partyWrappers[partyID]:RemoveMember(username)
        
        if not next(lobby.parties[partyID].members) then
            self.partyWrappers[partyID].wrapper:Dispose()
            self.partyWrappers[partyID] = nil
        end
    end

    self:UpdateLayout()
end
function PartyWindow:JoinedParty(partyID, username)
    if username == lobby.myUserName then
        self.partyWrappers[partyID] = self.partyWrappers[partyID] or PartyWrapper(self.window)
        if self.partyWrappers[partyID].acceptInviteButton then
            self.partyWrappers[partyID].acceptInviteButton:Dispose()
            self.partyWrappers[partyID].acceptInviteButton = nil
        end
        Button:New {
            caption = "Leave Party",
            parent = self.partyWrappers[partyID].wrapper,
            width = PartyWindow.BUTTON_WIDTH,
            right = 0,
            y = 0,
            classname = "negative_button",
            OnClick = {
                function()
                    self:LeaveMyCurrentParty()
                end
            }
        }

        self.partyWrappers[partyID].wrapper:SetPos(0, PartyWindow.CONTENT_Y_OFFSET + PartyWindow.SECTION_HEADER_HEIGHT + PartyWindow.MINOR_SPACING)
        self.partyWrappers[partyID].wrapper:Show()
        self.yourPartyLabel:Show()
    end

    self.partyWrappers[partyID]:RemoveInvite(username)
    self.partyWrappers[partyID]:AddMember(username)

    self:UpdateLayout()
end
function PartyWindow:InvitedToParty(partyID, username)
    if username == lobby.myUserName then
        self.partyWrappers[partyID] = PartyWrapper(self.window)
        self.partyWrappers[partyID].acceptInviteButton = Button:New{
            caption = "Accept invite",
            classname = "positive_button",
            right = 0,
            width = PartyWindow.BUTTON_WIDTH,
            parent = self.partyWrappers[partyID].wrapper,
            OnClick = {
                function() 
                    if lobby.myPartyID then
                        self:LeaveMyCurrentParty()
                    end
                    lobby:AcceptInviteToParty(partyID)
                end
            }
        }

        self.partyWrappers[partyID].wrapper:Show()

        self.invitesLabel:Show()
    end
    
    if partyID == lobby.myPartyID then
        self.partyWrappers[partyID]:AddInvite(username)
    end

    self:UpdateLayout()
end
function PartyWindow:InviteToPartyCancelled(partyID, username)
    self.partyWrappers[partyID]:RemoveInvite(username)

    if username == lobby.myUserName then
        self.partyWrappers[partyID].wrapper:Dispose()
        self.partyWrappers[partyID] = nil
    end

    self:UpdateLayout()
end