----------------------
-- Client -> Server --
----------------------

function Interface:CreateParty(successCallback, errorCallback)
    table.insert(self.commandsAwaitingResponse, {
        cmd = "c.party.create_new_party",
        successCallback = successCallback and function(tags)
            successCallback(getTag(tags, "party_id"))
        end,
        errorCallback = errorCallback and function(tags) errorCallback(getTag(tags, "msg")) end
    })

    self:_SendCommand("c.party.create_new_party")
end

function Interface:AcceptInviteToParty(partyID, successCallback, errorCallback)
    table.insert(self.commandsAwaitingResponse, {
        cmd = "c.party.accept_invite_to_party",
        successCallback = successCallback and function() successCallback() end,
        errorCallback = errorCallback and function(tags) errorCallback(getTag(tags, "msg")) end
    })

    self:_SendCommand("c.party.accept_invite_to_party " .. partyID)
end

function Interface:LeaveMyCurrentParty(successCallback, errorCallback)
    table.insert(self.commandsAwaitingResponse, {
        cmd = "c.party.leave_current_party",
        successCallback = function(tags)
            self:_OnLeftParty(self.myPartyID, self.myUserName)
            if successCallback then
                successCallback()
            end
        end,
        errorCallback = errorCallback and function(tags) errorCallback(getTag(tags, "msg")) end
    })

    self:_SendCommand("c.party.leave_current_party ")
end

function Interface:InvitePlayerToMyParty(username, successCallback, errorCallback)
    table.insert(self.commandsAwaitingResponse, {
        cmd = "c.party.invite_to_party",
        successCallback = function()
                self:_OnInvitedToParty(self.myPartyID, username)
                if successCallback then successCallback() end
            end, 
            errorCallback = errorCallback and function(tags) errorCallback(getTag(tags, "msg")) end
    })
    self:_SendCommand("c.party.invite_to_party " .. username)
end

function Interface:CancelInviteToMyParty(username, successCallback, errorCallback)
    table.insert(self.commandsAwaitingResponse, {
        cmd = "c.party.cancel_invite_to_party",
        successCallback = successCallback and function() successCallback() end, 
        errorCallback = errorCallback and function(tags) errorCallback(getTag(tags, "msg")) end
    })
    self:_SendCommand("c.party.cancel_invite_to_party " .. username)
end

----------------------
-- Server -> Client --
----------------------
-- Party-related server messages may be erroneously duplicated.
-- Thus, all commands implement checks to safely handle erroneous duplicates.
function Interface:_OnInvitedToParty(partyID, username)
    local party = self.parties[partyID]
    if party and party.invites[username] then
        return
    end

    if username == self.myUserName then
        self.parties[partyID] = { invites = { [username] = true }, members = {} }
    else
        party.invites[username] = true
    end

    self:_CallListeners("OnInvitedToParty", partyID, username)
end
Interface.commands["s.party.invited_to_party"] = Interface._OnInvitedToParty
Interface.commandPattern["s.party.invited_to_party"] = "(%S+)%s(%S+)"

function Interface:_OnPartyInviteCancelled(partyID, username)
    local party = self.parties[partyID]
    if not (party and party.invites[username]) then
        return
    end 

    if username == self.myUserName then
        self.parties[partyID] = nil
    else
        party.invites[username] = nil
    end

    self:_CallListeners("OnPartyInviteCancelled", partyID, username)
end
Interface.commands["s.party.invite_cancelled"] = Interface._OnPartyInviteCancelled
Interface.commandPattern["s.party.invite_cancelled"] = "(%S+)%s(%S+)"

function Interface:_OnJoinedParty(partyID, username)
    local party = self.parties[partyID]
    if party and party.members[username] then
        return
    end

    if username == self.myUserName then
        party = party or { invites = {}, members = {} }
        self.parties[partyID] = party
        self.myPartyID = partyID
    end
    party.invites[username] = nil
    party.members[username] = true

    self:_CallListeners("OnJoinedParty", partyID, username)
end
Interface.commands["s.party.joined_party"] = Interface._OnJoinedParty
Interface.commandPattern["s.party.joined_party"] = "(%S+)%s(%S+)"

function Interface:_OnLeftParty(partyID, username)
    local party = self.parties[partyID]
    if not (party and party.members[username]) then return end

    local partyDestroyed

    if username == self.myUserName then
        self.parties[partyID] = nil
        self.myPartyID = nil

        partyDestroyed = true
    else
        party.members[username] = nil

        if not next(party.members) then
            self.parties[partyID] = nil
            partyDestroyed = true
        end
    end

    self:_CallListeners("OnLeftParty", partyID, username, partyDestroyed)
end
Interface.commands["s.party.left_party"] = Interface._OnLeftParty
Interface.commandPattern["s.party.left_party"] = "(%S+)%s(%S+)"