VFS.Include(LIB_LOBBY_DIRNAME .. "lobby.lua")

LOG_SECTION = "liblobby"

if not Spring.GetConfigInt("LuaSocketEnabled", 0) == 1 then
	Spring.Log(LOG_SECTION, LOG.ERROR, "LuaSocketEnabled is disabled")
	return false
end

Interface = Lobby:extends{}

function Interface:init()
-- dumpConfig()
	self.messagesSentCount = 0
	self.lastSentSeconds = Spring.GetTimer()
	self.status = "offline"
	self.finishedConnecting = false
	self.listeners = {}

	-- timeout (in seconds) until first message is received from server before disconnect is assumed
	self.connectionTimeout = 50

	-- private
	self.buffer = ""

	self:super("init")
end

function Interface:Connect(host, port, user, password, cpu, localIP, lobbyVersion)
--host = "test.zero-k.info"
--port = 8202
	self:super("Connect", host, port)
	if self.client then
		self.client:close()
	end
	self.client = socket.tcp()
	self.client:settimeout(0)

	self.loginData = {user, password, cpu, localIP, lobbyVersion}

	self._startedConnectingTime = os.clock()
	local res, err = self.client:connect(host, port)
	if res == nil and err == "host not found" then
		self:_OnDisconnected("Host not found")
		-- The socket is expected to return "timeout" immediately since timeout time is set  to 0
	elseif not (res == nil and err == "timeout") then
		Spring.Log(LOG_SECTION, LOG.ERROR, "Error in connect: " .. err)
    else
        self.status = "connecting"
    end
	return true
end

function Interface:Disconnect(reason)
	self.status = "offline"
	self.finishedConnecting = false
	if self.client then
		self.client:close()
		self.client = nil
	end
	self:_OnDisconnected(reason, true)
end

function Interface:TextEraseNewline(str)
	-- if str == nil then
	-- 	Spring.Utilities.TraceEcho()
	-- end
	-- Spring.Echo("str:", str)
	local input_str = str
	str = string.gsub(str, "\n", "")
	str = string.gsub(str, "\r", "")
	-- if input_str ~= str then
	-- 	Spring.Echo("TextEraseNewline before:", input_str)
	-- 	Spring.Echo("TextEraseNewline after:", str)
	-- end
	return str
end

function Interface:_SendCommand(command, sendMessageCount)
	-- command = self:TextEraseNewline(command) -- produces errors with telemetry commands
	if sendMessageCount then
		self.messagesSentCount = self.messagesSentCount + 1
		command = "#" .. self.messagesSentCount .. " " .. command
	end
	if not self.client then
		Spring.Echo("Missing self.client!!!")
		return
	end

	local numBytes, errorCode, numActuallySent
	local maxPacketSize = 32000 -- 65535 actually for TCP
	local commandLength = #command
	local totalSent = 0
	if commandLength > maxPacketSize then
		-- previously timeout was 0, which didnt allow sending large messages without timeouting
		self.client:settimeout(2)
		for i=1,commandLength, maxPacketSize do
			local commandPart = string.sub(command, i, i + maxPacketSize -1 )
			if i + maxPacketSize > commandLength and commandPart[#commandPart] ~= "\n" then
				commandPart = commandPart .. '\n'
			end
			-- https://w3.impa.br/~diego/software/luasocket/tcp.html#send
			--Spring.Echo("sending a big chunk",i, #commandpart)
			numBytes, errorCode, numActuallySent = self.client:send(commandPart)
			totalSent = totalSent + (numBytes or numActuallySent)
			if numBytes == nil then
				break
			end
		end
		self.client:settimeout(0)
	else
		if command[#command] ~= "\n" then
			command = command .. "\n"
		end
		numBytes, errorCode, numActuallySent = self.client:send(command)
		totalSent = totalSent + (numBytes or numActuallySent)
	end
	if numBytes == nil then
		Spring.Echo("Error in Interface:_SendCommand while sending", numBytes, errorCode, numActuallySent, commandLength, totalSent)
		--Spring.Echo(command)
	end

	if errorCode and errorCode == "closed" then
		self:Disconnect(errorCode)
		return
	end

	self:_CallListeners("OnCommandSent", command:sub(1, #command-1))
	self.lastSentSeconds = Spring.GetTimer()
end

function Interface:SendCustomCommand(command)
	self:_SendCommand(command, false)
end

function Interface:ProcessBuffer()
	if not self.commandBuffer then
		return false
	end

	self.bufferExecutionPos = self.bufferExecutionPos + 1
	local command = self.commandBuffer[self.bufferExecutionPos]
	if not self.commandBuffer[self.bufferExecutionPos + 1] then
		-- This means that there are no further commands to be executed, 
		-- so we should reset the state of the buffer  
		self:CommandReceived(command)
		self.commandBuffer = false
		self.commandsInBuffer = 0
		self.bufferExecutionPos = 0
		
		-- Sending MYBATTLESTATUS is disabled while executing buffer, so send it one time after
		if self:GetMyBattleID() then -- are we still in a battle ?
			self:SetBattleStatus(self.userBattleStatus[self:GetMyUserName()], true) -- force
		end
		return false
	end
	self:CommandReceived(command)
	return true
end

function Interface:SendCommandToBuffer(cmdName, arguments)
	if not self.bufferBypass then
		return true
	end
	if type(self.bufferBypass[cmdName]) == "function" then
		return not self.bufferBypass[cmdName](arguments)
	end
	return not self.bufferBypass[cmdName]
end

function Interface:CommandReceived(command)
	local cmdId, cmdName, arguments
	local argumentsPos = false
	if command:sub(1,1) == "#" then
		i = command:find(" ")
		cmdId = command:sub(2, i - 1)
		argumentsPos = command:find(" ", i + 1)
		if argumentsPos ~= nil then
			cmdName = command:sub(i + 1, argumentsPos - 1)
		else
			cmdName = command:sub(i + 1)
		end
	else
		argumentsPos = command:find(" ")
		if argumentsPos ~= nil then
			cmdName = command:sub(1, argumentsPos - 1)
		else
			cmdName = command
		end
	end

	if argumentsPos then
		arguments = command:sub(argumentsPos + 1)
	end

	if self.bufferCommandsEnabled and self:SendCommandToBuffer(cmdName, arguments) then
		if not self.commandBuffer then
			self.commandBuffer = {}
			self.commandsInBuffer = 0
			self.bufferExecutionPos = 0
		end
		self.commandsInBuffer = self.commandsInBuffer + 1
		self.commandBuffer[self.commandsInBuffer] = command
		self:_CallListeners("OnCommandBuffered", command)
		return
	end


	self:_OnCommandReceived(cmdName, arguments, cmdId)
end

function Interface:_GetCommandPattern(cmdName)
	return Interface.commandPattern[cmdName]
end

function Interface:_GetCommandFunction(cmdName)
	return Interface.commands[cmdName], Interface.commandPattern[cmdName]
end

function Interface:_GetJsonCommandFunction(cmdName)
	return Interface.jsonCommands[cmdName]
end

-- status can be one of: "offline", "connecting", "connected" and "disconnected"
function Interface:GetConnectionStatus()
	return self.status
end

function Interface:_GetFunArgs(cmdName, arguments)
	local commandFunction, pattern = self:_GetCommandFunction(cmdName)
	if not commandFunction then
		return false
	end
	
	local pattern = self:_GetCommandPattern(cmdName)
	if not pattern then
		return false
	end
	
	return {arguments:match(pattern)}
end

function Interface:_OnCommandReceived(cmdName, arguments, cmdId)
	local commandFunction, pattern = self:_GetCommandFunction(cmdName)
	local fullCmd
	if arguments ~= nil then
		fullCmd = cmdName .. " " .. arguments
	else
		fullCmd = cmdName
	end

	if commandFunction ~= nil then
		local pattern = self:_GetCommandPattern(cmdName)
		if pattern then
			local funArgs = {arguments:match(pattern)}
			if #funArgs ~= 0 then
				commandFunction(self, unpack(funArgs))
			else
				Spring.Log(LOG_SECTION, LOG.ERROR, "Failed to match command: ", cmdName, ", args: " .. tostring(arguments) .. " with pattern: ", pattern)
			end
		else
			--Spring.Echo("No pattern for command: " .. cmdName)
			commandFunction(self)
		end
	else
		local jsonCommandFunction = self:_GetJsonCommandFunction(cmdName)
		if jsonCommandFunction ~= nil then
			local success, obj = pcall(Json.decode, arguments)
			if not success then
				Spring.Log(LOG_SECTION, LOG.ERROR, "Failed to parse JSON: " .. tostring(arguments))
			end
			if obj then
				jsonCommandFunction(self, obj)
			end
		else
			Spring.Log(LOG_SECTION, LOG.ERROR, "No such function: " .. cmdName .. ", for command: " .. fullCmd)
		end
	end
	self:_CallListeners("OnCommandReceived", fullCmd)
end

function Interface:_SocketUpdate()
	if self.client == nil then
		return
	end
	-- get sockets ready for read
	local readable, writeable, err = socket.select({self.client}, {self.client}, 0)
	local host, port = self.client:getpeername()
--	if host == nil then
--		self.client:shutdown()
--		self.client = nil
--		self:_OnDisconnected("Cannot resolve host.")
--		return
--	end
	local brec, bsent, age = self.client:getstats()
	if err ~= nil then
		-- If any error happened, then clear the buffer for sure
		self.buffer = "" 
		-- some error happened in select
		if err == "timeout" then
			-- we've received no data after connecting for a while. assume connection cannot be established
			if brec == 0 and os.clock() - self._startedConnectingTime > self.connectionTimeout then
				self.client:shutdown()
				self.client = nil
				self:_OnDisconnected("No response from host.")
				Spring.Echo("No response from host.")
			end
			-- nothing to do, return
			return
		end
		Spring.Log(LOG_SECTION, LOG.ERROR, "Error in select: " .. err)
	end
	for _, input in ipairs(readable) do
		local s, status, commandsStr = input:receive('*a') --try to read all data
		if (status == "timeout" or status == nil) and commandsStr ~= nil and commandsStr ~= "" then
			Spring.Log(LOG_SECTION, LOG.DEBUG, commandsStr)
			local commands = explode("\n", commandsStr)
			commands[1] = self.buffer .. commands[1]
			for i = 1, #commands-1 do
				local command = commands[i]
				if command ~= nil then
					self:CommandReceived(command)
				end
			end
			self.buffer = commands[#commands]
		elseif status == "closed" then
			Spring.Log(LOG_SECTION, LOG.INFO, "Disconnected from server.")
			input:close()
			-- if status is "offline", user initiated the disconnection
			if self.status ~= "offline" then
				self.status = "disconnected"
			end
			-- If any error happened, then clear the buffer for sure
			self.buffer = "" 
			self:_OnDisconnected()
		end
	end
end

function Interface:SafeUpdate()
	self:super("SafeUpdate")
	self:_SocketUpdate()
	-- prevent timeout with PING
	if self.status == "connected" then
		local currentTime = Spring.GetTimer()
		if Spring.DiffTimers(currentTime, self.lastSentSeconds) > 30 then
			self:Ping()
		end
	end
end

function Interface:Update()
	xpcall(function() self:SafeUpdate() end,
		function(err) self:_PrintError(err) end )
end
