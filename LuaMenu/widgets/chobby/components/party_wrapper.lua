PartyWrapper = LCS.class{}

PartyWrapper.ROW_HEIGHT = 22

function PartyWrapper:init(parent, partyID)
    self.rows = {}
    self.inviteRows = {}
    self.actionButtons = {}
    self.rowCount = 0
    self.inviteRowCount = 0
    self.actionButtonCount = 0
    
    self.parent = parent
    self.partyID = partyID

    self.wrapper = Control:New{
        classname = "party_wrapper",
        width = "100%",
        height = self:TotalHeight(),
        parent = parent
    }

    self.inviteTip = Label:New{
        parent = self.wrapper,
        -- we only show this when we're the only player in the party, so can hard-code y
        y = PartyWrapper.ROW_HEIGHT,
        caption = i18n("how_to_invite_to_party"),
        objectOverrideFont = Configuration:GetFont(1, "how_to_invite_to_party", { color = { 0.5, 0.5, 0.5, 1 } })
    }
    self.inviteTip:Hide()
end

function PartyWrapper:TotalHeight()
    return self:ContentHeight() + PartyWindow.MINOR_SPACING * 2
end

function PartyWrapper:ContentHeight()
    return math.max(self.actionButtonCount, (self.rowCount + self.inviteRowCount + (self:ShouldShowInviteTip() and 1 or 0))) * PartyWrapper.ROW_HEIGHT
end

function PartyWrapper:ShouldShowInviteTip()
    return self.rowCount == 1 and self.inviteRowCount == 0 and self.rows[lobby.myUserName]
end

function PartyWrapper:AddActionButton(caption, classname, action)
    self.actionButtonCount = self.actionButtonCount + 1
    self.actionButtons[self.actionButtonCount] = Button:New{
        caption = caption,
        classname = classname,
        OnClick = { action },

        right = 0,
        width = PartyWindow.BUTTON_WIDTH,
        y = PartyWrapper.ROW_HEIGHT * (self.actionButtonCount - 1) + 1,
        parent = self.wrapper,
    }
    self:UpdateLayout()
end

function PartyWrapper:ClearActionButtons()
    for _, actionButton in ipairs(self.actionButtons) do
        actionButton:Dispose()
    end
    self.actionButtons = {}
    self.actionButtonCount = 0

    self:UpdateLayout()
end

function PartyWrapper:UpdateLayout()
    local index = 0
    for username, row in pairs(self.rows) do
        row:SetPos(nil, index * PartyWrapper.ROW_HEIGHT)
        index = index + 1
    end

    index = 0

    for username, inviteRow in pairs(self.inviteRows) do
        inviteRow:SetPos(nil, (index + self.rowCount) * PartyWrapper.ROW_HEIGHT)
        index = index + 1
    end

    if self:ShouldShowInviteTip() then
        self.inviteTip:Show()
    else
        self.inviteTip:Hide()
    end

    self.wrapper:Resize(nil, self:TotalHeight())
end

function PartyWrapper:AddMember(username)
    if not self.rows[username] then
        local userControl = WG.UserHandler.GetPartyUser(username, self.partyID, "party_status_member")
        userControl.y = self:ContentHeight()
        userControl._relativeBounds.right = PartyWindow.MAJOR_SPACING + PartyWindow.BUTTON_WIDTH
        self.wrapper:AddChild(userControl)
        self.rows[username] = userControl

        self.rowCount = self.rowCount + 1

        self:UpdateLayout()
    end
end

function PartyWrapper:RemoveMember(username)
    if self.rows[username] then
        self.wrapper:RemoveChild(self.rows[username])
        self.rowCount = self.rowCount - 1
        self.rows[username] = nil

        self:UpdateLayout()
    end
end

function PartyWrapper:AddInvite(username)
    if not self.inviteRows[username] then
        local userControl = WG.UserHandler.GetPartyUser(username, self.partyID, "party_status_invite")
        userControl.y = self:ContentHeight()
        userControl._relativeBounds.right = PartyWindow.MAJOR_SPACING + PartyWindow.BUTTON_WIDTH
        self.wrapper:AddChild(userControl)
        self.inviteRows[username] = userControl

        self.inviteRowCount = self.inviteRowCount + 1

        self:UpdateLayout()
    end
end

function PartyWrapper:RemoveInvite(username)
    if self.inviteRows[username] then
        self.wrapper:RemoveChild(self.inviteRows[username])
        self.inviteRowCount = self.inviteRowCount - 1
        self.inviteRows[username] = nil

        self:UpdateLayout()
    end
end