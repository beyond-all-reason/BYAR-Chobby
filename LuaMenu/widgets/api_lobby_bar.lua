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

	lobby.MyStatusIngame = false
	lobby.MyStatusAway = false
	lobby.MyStatus = 0


	lobby.RejoinBattle = function(self, battleID)
		local battle = self:GetBattle(battleID)
		if battle then
			self:JoinAsSpec()
			self:ConnectToBattle(self.useSpringRestart, battle.ip, battle.port, nil, self:GetScriptPassword())
		end

		return self
	end

	lobby.SetIngameStatus = function(self, ingame, away)
		-- this still isnt perfect; if away status is ever reported, then ingame status wont be returned by server when playing skirmish
		if ingame ~= nil then lobby.MyStatusIngame = ingame end

		if away ~= nil then lobby.MyStatusAway = away end

		local newstatus = 0
		if lobby.MyStatusIngame then  -- cant be away and ingame at the same time
			newstatus = 1
		else
			if lobby.MyStatusAway then newstatus =  2 end
		end

		--Spring.Echo("widget:api_lobby_bar.lua:","Interface:SetIngameStatus(ingame, away)",ingame, away, newstatus)
		if lobby.MyStatus ~= newstatus then -- dont spam clientstatus
			if newstatus == 1 and lobby.MyStatus == 2 then
				self:_SendCommand("MYSTATUS " .. 0) -- return from away BEFORE going ingame
			end
			self:_SendCommand("MYSTATUS " .. newstatus)
			lobby.MyStatus = newstatus
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
