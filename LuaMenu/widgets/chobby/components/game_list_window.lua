GameListWindow = ListWindow:extends{}

function GameListWindow:init(failFunction, sucessFunction)

	self:super('init', WG.Chobby.lobbyInterfaceHolder, "Select Game", false, "main_window", nil, {6, 7, 7, 4})
	self.window:SetPos(nil, nil, 500, 700)

	for i, archive in pairs(VFS.GetAllArchives()) do
		local info = VFS.GetArchiveInfo(archive)
		if info and info.modtype == 1 then
			local pickMapButton = Button:New {
				x = 0,
				y = 0,
				width = "100%",
				height = "100%",
				caption = info.name,
				font = Configuration:GetFont(3),
				OnClick = {
					function()
						sucessFunction(info.name)
						self:HideWindow()
					end
				},
			}
			self:AddRow({pickMapButton}, info.name)
		end
	end

	self.window.OnDispose = self.window.OnDispose or {}
	self.window.OnDispose[#self.window.OnDispose + 1] = failFunction

	self.popupHolder = PriorityPopup(self.window, self.CancelFunc)
end
