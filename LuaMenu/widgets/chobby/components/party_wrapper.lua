PartyWrapper = LCS.class{}

PartyWrapper.ROW_HEIGHT = 25

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
    return (self.rowCount + self.inviteRowCount) * PartyWrapper.ROW_HEIGHT + PartyWindow.MINOR_SPACING * 2
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
        self.rows[username] = ComboBox:New{
            y = self:TotalHeight(),
            x = PartyWindow.MINOR_SPACING,
            width = 200 - PartyWindow.MINOR_SPACING * 3,
            parent = self.wrapper,
            showSelection = false,
            caption = username,
            ignoreItemCaption = true,
            selectByName = true,
            -- items = { (lobby.myUserName ~= username) and "Remove from party" },
            items = {},
            OnSelectName = {
                -- function(_, selectedName)
                --     if selectedName == "Remove from party" then
                        -- lobby:RemovePlayerFromMyParty(username)
                --     end
                -- end
            }
        }

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
        self.inviteRows[username] = ComboBox:New{
            y = self:TotalHeight(),
            parent = self.wrapper,
            showSelection = false,
            caption = username,
            ignoreItemCaption = true,
            selectByName = true,
            items = { (lobby.myUserName ~= username) and "Cancel invite" },
            OnSelectName = {
                function(_, selectedName)
                    if selectedName == "Cancel invite" then
                        lobby:CancelInviteToMyParty(username)
                    end
                end
            }
        }

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