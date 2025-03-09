PartyWindow = LCS.class{}

function PartyWindow:init(parent)
    self.window = Window:New{
        x = 0,
        right = 0,
        y = 0,
        bottom = 0,
        parent = parent,
        resizable = false,
        draggable = false,
        classname = "PartyWindow"
    }

    Label:New {
        x = 40,
        y = 40,
        parent = self.window,
        caption = "Parties",
    }

    self.requiresLoginLabel = Label:New {
        x = 40,
        y = 60,
        parent = self.window,
        caption = "Requires login"
    }

    self.createPartyButton = Button:New {
        caption = "Create Party",
        parent = self.window,
        right = 40,
        y = 40,
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
        y = 60,
        x = 40,
        caption = "Your Party",
        parent = self.window
    }
    self.yourPartyLabel:Hide()

    self.invitesLabel = Label:New {
        x = 40,
        caption = "Your Invites:",
        parent = self.window
    }
    self.invitesLabel:Hide()

    self.leavePartyButton = Button:New {
        caption = "Leave Party",
        parent = self.window,
        right = 40,
        y = 60,
        OnClick = {
            function()
                self:LeaveMyCurrentParty()
            end
        }
    }
    self.leavePartyButton:Hide()

    self.partyWrappers = {}

    lobby:AddListener("OnAccepted", function()
        self.requiresLoginLabel:Hide()
        self.createPartyButton:Show()
    end)

    lobby:AddListener("OnDisconnected", function()
        self.requiresLoginLabel:Show()
        self.createPartyButton:Hide()
        self.leavePartyButton:Hide()
        self.invitesLabel:Hide()
        self.yourPartyLabel:Hide()

        for partyID, partyWrapper in pairs(self.partyWrappers) do
            partyWrapper.wrapper:Dispose()
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

PartyWindow.MY_PARTY_YOFFSET = 80
PartyWindow.SPACING = 8

function PartyWindow:UpdateLayout()
    local offset = lobby.myPartyID and (PartyWindow.MY_PARTY_YOFFSET + self.partyWrappers[lobby.myPartyID]:TotalHeight() + PartyWindow.SPACING) or PartyWindow.MY_PARTY_YOFFSET
    
    self.invitesLabel:SetPos(40, offset)
    self.invitesLabel:Hide()

    offset = offset + PartyWrapper.ROW_HEIGHT

    for partyID, partyWrapper in pairs(self.partyWrappers) do
        if partyID ~= lobby.myPartyID then
            self.invitesLabel:Show()
            partyWrapper.wrapper:SetPos(40, offset)
            offset = offset + partyWrapper:TotalHeight() + PartyWindow.SPACING
        end
    end
end

function PartyWindow:LeaveMyCurrentParty()
    local myPartyID = lobby.myPartyID
    lobby:LeaveMyCurrentParty(function()
        self.partyWrappers[myPartyID].wrapper:Dispose()
        self.partyWrappers[myPartyID] = nil
        self.yourPartyLabel:Hide()
        self.leavePartyButton:Hide()

        self:UpdateLayout()
    end)
end

function PartyWindow:LeftParty(partyID, username)
    if username == lobby.myUserName then
        self.partyWrappers[partyID].wrapper:Dispose()
        self.partyWrappers[partyID] = nil
    else
        self.partyWrappers[partyID]:RemoveMember(username)
        
        if not next(self.partyWrappers[partyID].rows) then
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
        end
        self.partyWrappers[partyID].wrapper:SetPos(40, PartyWindow.MY_PARTY_YOFFSET)
        self.partyWrappers[partyID].wrapper:Show()
        self.yourPartyLabel:Show()
        self.leavePartyButton:Show()
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
            x = 200,
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
    
    self.partyWrappers[partyID]:AddInvite(username)
    
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