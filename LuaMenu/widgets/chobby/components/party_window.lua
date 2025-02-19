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
                self:LeaveCurrentParty()
                self:CreateNewParty()
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
                self:LeaveCurrentParty()
            end
        }
    }
    self.leavePartyButton:Hide()

    self.partyWrappers = {}

    lobby:AddListener("OnAccepted", function()
        self.requiresLoginLabel:Hide()
        self.createPartyButton:Show()

        -- For testing
        self:InvitedToParty(2, "MasterBel2")
        self:JoinedParty(2, "BelSon")
        self:JoinedParty(2, "Belmakor")

        self:InvitedToParty(3, "MasterBel2")
        self:JoinedParty(3, "Frank")
        self:JoinedParty(3, "Lorentz")
    end)
end

PartyWindow.MY_PARTY_YOFFSET = 80
PartyWindow.SPACING = 8

function PartyWindow:UpdateLayout()
    local offset = self.myPartyID and (PartyWindow.MY_PARTY_YOFFSET + self.partyWrappers[self.myPartyID]:TotalHeight() + PartyWindow.SPACING) or PartyWindow.MY_PARTY_YOFFSET
    
    self.invitesLabel:SetPos(40, offset)
    self.invitesLabel:Hide()

    offset = offset + PartyWrapper.ROW_HEIGHT

    for partyID, partyWrapper in pairs(self.partyWrappers) do
        if partyID ~= self.myPartyID then
            self.invitesLabel:Show()
            partyWrapper.wrapper:SetPos(40, offset)
            offset = offset + partyWrapper:TotalHeight() + PartyWindow.SPACING
        end
    end
end

-- LeftParty, JoinedParty, InvitedToParty, InviteToPartyCancelled are to be sent from teiserver to chobby
-- Chobby will need these only for parties they have been invited to or are a member of.
-- When a user is invited to a party, teiserver will send a list of `JOINEDPARTY partyID username`
-- This informs the user about all the current members of the party they are invited to.
-- After this, teiserver will continue sending updates on invites/cancels/joins/leaves 
-- until the invite is cancelled, or the player has joined & left the party.
-- Chobby can work out from the username field whether these operations refer to itself or not.
function PartyWindow:LeftParty(partyID, username)
    if username == lobby.myUserName then
        self:LeaveCurrentParty()
    end
    self.partyWrappers[partyID]:RemoveMember(username)

    self:UpdateLayout()
end
function PartyWindow:JoinedParty(partyID, username)
    if username == lobby.myUserName then
        self.myPartyID = partyID

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
            OnClick = { function() self:AcceptInviteToParty(partyID) end }
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

-- These are operations a chobby user will want to be able to perform, 
-- and what I estimate are the necessary arguments.
-- These will ideally each come with some form of confirmation / error message 
-- to indicate sucess status to the user.
function PartyWindow:InviteToMyParty(username)
    self:InvitedToParty(self.myPartyID, username)
end
function PartyWindow:CancelInviteToMyParty(username)
    self:InviteToPartyCancelled(self.myPartyID, username)
end
-- I don't know if this is current functionality, but it's likely desired.
function PartyWindow:RemovePlayerFromMyParty(username)
    self:LeftParty(self.myPartyID, username)
end
function PartyWindow:AcceptInviteToParty(partyID)
    self:LeaveCurrentParty()
    self:JoinedParty(partyID, lobby.myUserName)
end
function PartyWindow:LeaveCurrentParty()
    if self.myPartyID then
        self.partyWrappers[self.myPartyID].wrapper:Dispose()
        self.partyWrappers[self.myPartyID] = nil
        self.yourPartyLabel:Hide()
        self.leavePartyButton:Hide()
        self.myPartyID = nil

        self:UpdateLayout()
    end
end
function PartyWindow:CreateNewParty()
    self:JoinedParty(1, lobby.myUserName)
end