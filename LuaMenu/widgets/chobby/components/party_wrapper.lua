PartyWrapper = LCS.class{}

PartyWrapper.ROW_HEIGHT = 22

function PartyWrapper:init(parent)
    self.rows = {}
    self.inviteRows = {}
    self.parent = parent
    self.rowCount = 0
    self.inviteRowCount = 0

    self.wrapper = Control:New{
        classname = "party_wrapper",
        width = "100%",
        height = self:TotalHeight(),
        parent = parent
    }
end

function PartyWrapper:TotalHeight()
    return self:ContentHeight() + PartyWindow.MINOR_SPACING * 2
end

function PartyWrapper:ContentHeight()
    return (self.rowCount + self.inviteRowCount) * PartyWrapper.ROW_HEIGHT
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

    self.wrapper:Resize(nil, self:TotalHeight())
end

function PartyWrapper:AddMember(username)
    if not self.rows[username] then
        local userControl = WG.UserHandler.GetPartyUser(username, "member")
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
        local userControl = WG.UserHandler.GetPartyUser(username, "invite")
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