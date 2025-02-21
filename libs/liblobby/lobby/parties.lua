function Interface:CreateParty()
    self:LeaveMyCurrentParty()
    self:_SendCommand("c.party.create_party")
end

function Interface:AcceptInviteToParty(partyID)
    self:LeaveMyCurrentParty()
    self:_SendCommand("c.party.accept_invite_to_party " .. partyID)
end

function Interface:LeaveMyCurrentParty()
    self.myPartyID = nil
    self:_SendCommand("c.party.leave_current_party ")
end

function Interface:InvitePlayerToMyParty(username)
    self:_SendCommand("c.party.invite " .. username)
end

function Interface:CancelInviteToMyParty(username)
    self:_SendCommand("c.party.cancel_invite_to_my_party " .. username)
end

function Interface:_OnInvitedToParty(partyID, username)
    self.parties = self.parties or {}
    if username == self.myUserName then
        self.parties[partyID] = { invites = { [username] = true }, members = {} }
    else
        self.parties[partyID].invites[username] = true
    end

    self:CallListeners("OnInvitedToParty", partyID, username)
end
Interface.commands["s.party.invited_to_party"] = Interface._OnInvitedToParty
Interface.commandPattern["s.party.invited_to_party"] = "(%d+)%s(%S+)"
    

function Interface:_OnPartyInviteCancelled(partyID, username)
    if username == self.myUserName then
        self.parties[partyID] = nil
    else
        self.parties[partyID].invites[username] = nil
    end

    self:CallListeners("OnPartyInviteCancelled", partyID, username)
end
Interface.commands["s.party.invite_to_party_cancelled"] = Interface._OnPartyInviteCancelled
Interface.commandPattern["s.party.invite_to_party_cancelled"] = "(%d+)%s(%S+)"

function Interface:_OnJoinedParty(partyID, username)
    if username == self.myUserName then
        self.myPartyID = partyID
    end
    self.parties[partyID].invites[username] = nil
    self.parties[partyID].members[username] = true

    self:CallListeners("OnJoinedParty", partyID, username)
end
Interface.commands["s.party.joined_party"] = Interface._OnJoinedParty
Interface.commandPattern["s.party.joined_party"] = "(%d+)%s(%S+)"
    
function Interface:_OnLeftParty(partyID, username)
    if username == self.myUserName then
        self.parties[partyID] = nil
    else
        self.parties[partyID].members[username] = nil
    end

    self:CallListeners("OnLeftParty", partyID, username)
end
Interface.commands["s.party.left_party"] = Interface._OnLeftParty
Interface.commandPattern["s.party.left_party"] = "(%d+)%s(%S+)"