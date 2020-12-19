--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "BAR LibLobby overrides",
		author    = "gajop",
		date      = "WIP",
		license   = "GPLv2",
		version   = "0.2",
		layer     = -999,
		enabled   = true,  --  loaded by default?
		handler   = true,
		api       = true,
		hidden    = true,
	}
end

function widget:Initialize()
	local lobby = WG.LibLobby.lobby

	lobby.RejoinBattle = function(self, battleID)
		local battle = self:GetBattle(battleID)
		if battle then
			self:JoinAsSpec()
			self:ConnectToBattle(self.useSpringRestart, battle.ip, battle.port, nil, self:GetScriptPassword())
		end

		return self
	end

	lobby.SetIngameStatus = function(self, status)
		--Spring.Echo("Interface:SetIngameStatus(status)",status)
		if status == true then
			self:_SendCommand(concat("MYSTATUS", "1"))
		elseif status == false then
			self:_SendCommand(concat("MYSTATUS", "0"))
		end

		return self
	end

	lobby.JoinAsSpec = function(self)
		Spring.Echo("BYAR-Chobby.sdd\\libs\\liblobby\\lobby\\lobby.lua","Lobby:JoinAsSpec()")
		self:SayBattle("!joinas spec")
	end

	lobby.VoteYes = function(self)
		self:SayBattle("!vote y")
		return self
	end

	lobby.VoteNo = function(self)
		self:SayBattle("!vote n")
		return self
	end

end
