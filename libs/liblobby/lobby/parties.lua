function Interface:CreateParty(successCallback, errorCallback)
    table.insert(self.commandsAwaitingResponse, { 
        cmd = "c.party.create_new_party", 
        successCallback = successCallback and function(tags)
            successCallback(getTag(tags, "party_id"))
        end, 
        errorCallback = errorCallback and function() errorCallback() end 
    })

    self:_SendCommand("c.party.create_new_party")
end

function Interface:AcceptInviteToParty(partyID, successCallback, errorCallback)
    table.insert(self.commandsAwaitingResponse, { 
        cmd = "c.party.accept_invite_to_party", 
        successCallback = successCallback and function() successCallback() end, 
        errorCallback = errorCallback and function() errorCallback() end 
    })
    
    self:_SendCommand("c.party.accept_invite_to_party " .. partyID)
end

function Interface:LeaveMyCurrentParty(successCallback, errorCallback)
    table.insert(self.commandsAwaitingResponse, { 
        cmd = "c.party.leave_current_party",
        successCallback = successCallback,
        errorCallback = errorCallback 
    })
    self.myPartyID = nil
    self:_SendCommand("c.party.leave_current_party ")
end

function Interface:InvitePlayerToMyParty(username, successCallback, errorCallback)
    table.insert(self.commandsAwaitingResponse, { 
        cmd = "c.party.invite_to_party", 
        successCallback = successCallback and function() successCallback() end, 
        errorCallback = errorCallback and function() errorCallback() end 
    })
    self:_SendCommand("c.party.invite_to_party " .. username)
end

function Interface:CancelInviteToMyParty(username, successCallback, errorCallback)
    table.insert(self.commandsAwaitingResponse, { 
        cmd = "c.party.cancel_invite_to_my_party", 
        successCallback = successCallback and function() successCallback() end, 
        errorCallback = errorCallback and function() errorCallback() end 
    })
    self:_SendCommand("c.party.cancel_invite_to_my_party " .. username)
end

function Interface:_OnInvitedToParty(partyID, username)
    self.parties = self.parties or {}
    if username == self.myUserName then
        self.parties[partyID] = { invites = { [username] = true }, members = {} }
    else
        self.parties[partyID].invites[username] = true
    end

    self:_CallListeners("OnInvitedToParty", partyID, username)
end
Interface.commands["s.party.invited_to_party"] = Interface._OnInvitedToParty
Interface.commandPattern["s.party.invited_to_party"] = "(%S+)%s(%S+)"

function Interface:_OnPartyInviteCancelled(partyID, username)
    if username == self.myUserName then
        self.parties[partyID] = nil
    else
        self.parties[partyID].invites[username] = nil
    end

    self:_CallListeners("OnPartyInviteCancelled", partyID, username)
end
Interface.commands["s.party.invite_to_party_cancelled"] = Interface._OnPartyInviteCancelled
Interface.commandPattern["s.party.invite_to_party_cancelled"] = "(%S+)%s(%S+)"

-- Warning: Duplicates of this message might be received, 
-- so it's important the implementation can handle that.
-- Ideally that would be fixed server-side, but we're 
-- trying to conserve effort on this feature.
function Interface:_OnJoinedParty(partyID, username)
    if self.parties[partyID] and self.parties[partyID].members[username] then
        return
    end

    if username == self.myUserName then
        self.parties[partyID] = self.parties[partyID] or { invites = {}, members = {} }
        self.myPartyID = partyID
    end
    self.parties[partyID].invites[username] = nil
    self.parties[partyID].members[username] = true

    self:_CallListeners("OnJoinedParty", partyID, username)
end
Interface.commands["s.party.joined_party"] = Interface._OnJoinedParty
Interface.commandPattern["s.party.joined_party"] = "(%S+)%s(%S+)"
    
function Interface:_OnLeftParty(partyID, username)
    if username == self.myUserName then
        self.parties[partyID] = nil
        self.myPartyID = nil
    else
        self.parties[partyID].members[username] = nil
    end

    self:_CallListeners("OnLeftParty", partyID, username)
end
Interface.commands["s.party.left_party"] = Interface._OnLeftParty
Interface.commandPattern["s.party.left_party"] = "(%S+)%s(%S+)"