VFS.Include(JSON_LIB_PATH, nil, VFS.DEF_MODE)

local LOG_SECTION = "spring-launcher"

local host, port
local client
local isConnected = false
local buffer = ""

local Connector = {
	callbacks = {}, -- name based callbacks
	commandQueue = {},
	enabled = true,
}

--------------------------------------------------------------------------------
-- Public interface
--------------------------------------------------------------------------------
function Connector.Send(name, opt)
	local command = { name = name, command = opt }
	if not isConnected then
		table.insert(Connector.commandQueue, command)
		return
	end

	Connector._SendCommandImmediate(command)
end

function Connector.Register(name, callback)
	if not Connector.callbacks[name] then
		Connector.callbacks[name] = {}
	end
	table.insert(Connector.callbacks[name], callback)
end

Connector.Register("LoadExtensionFailed", function(command)
	Spring.Log(LOG_SECTION, LOG.ERROR, command.error)
end)

function Connector.Unregister(name, callback)
	if not Connector.callbacks[name] then
		return
	end
	for i, clb in ipairs(Connector.callbacks[name]) do
		if clb == callback then
			table.remove(Connector.callbacks[name], i)
			return
		end
	end
	Spring.Log(LOG_SECTION, LOG.ERROR, "No callback to remove: ", name)
end
--------------------------------------------------------------------------------
-- End of Public interface
--------------------------------------------------------------------------------

function Connector._SendCommandImmediate(command)
	Spring.Log(LOG_SECTION, LOG.INFO, "Connector.SendCommand(...)")
	-- TODO: delete or add table.lua dependency
	-- local msg = table.show(command)
	-- Spring.Log(LOG_SECTION, LOG.INFO, msg)
	local encoded = json.encode(command)
	Spring.Log(LOG_SECTION, LOG.INFO, encoded)
	client:send(encoded .. "\n")
end

function Connector._FlushCommandQueue()
	for _, command in ipairs(Connector.commandQueue) do
		Connector._SendCommandImmediate(command)
	end
	Connector.commandQueue = {}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

local function explode(div,str)
	if div == '' then
		return false
	end
	local pos, arr = 0, {}
	-- for each divider found
	for st, sp in function() return string.find(str,div,pos,true) end do
		table.insert(arr,string.sub(str,pos,st-1)) -- Attach chars left of current divider
		pos = sp + 1 -- Jump past current divider
	end
	table.insert(arr,string.sub(str,pos)) -- Attach chars right of last divider
	return arr
end

function widget:SocketConnect()
	if client then
		client:close()
	end
	client = socket.tcp()
	client:settimeout(0)
	local res, err = client:connect(host, port)
	if not res and err ~= "timeout" then
		client:close()
		client = nil
		widgetHandler:RemoveWidget(self)
		Spring.Log(LOG_SECTION, LOG.ERROR, "Error in connect launcher: " .. err)
		return false
	end
	return true
end

-- init
function widget:Initialize()
	WG.Connector = Connector

	if Spring.GetModOptions ~= nil then
		local modOpts = Spring.GetModOptions()
		host = modOpts._sl_address
		port = modOpts._sl_port
		Connector.writePath = modOpts._sl_write_path
	elseif VFS.FileExists("sl-connection.json", nil, VFS.RAW_ONLY) then
		pcall(function()
			local connectionInfo = VFS.LoadFile("sl-connection.json", nil, VFS.RAW_ONLY)
			connectionInfo = json.decode(connectionInfo)
			host = connectionInfo._sl_address
			port = connectionInfo._sl_port
			Connector.writePath = connectionInfo._sl_write_path
		end)
	end
	if port == nil or host == nil then
		Spring.Log(LOG_SECTION, LOG.NOTICE, "Disabling spring-launcher due to missing connection detalis.")
		WG.Connector.enabled = false -- TODO: maybe better way to toggle this (e.g. when this widget errors)
		widgetHandler:RemoveWidget(self)
		return
	end
	if Game ~= nil then
		Connector.Send("LoadArchiveExtensions", {
			archivePath = VFS.GetArchivePath(Game.gameName .. " " .. Game.gameVersion)
		})
	end

	Spring.Log(LOG_SECTION, LOG.NOTICE, "Connecting to " ..
		tostring(host) .. ":" .. tostring(port))
	self:SocketConnect(host, port)
end

-- pocesses raw string line and executes command
local function CommandReceived(command)
	local success, obj = pcall(json.decode, command)
	if not success then
		Spring.Log(LOG_SECTION, LOG.ERROR, "Failed to parse JSON: " .. tostring(command))
		return
	end

	local name = obj.name
	local params = obj.command

	if Connector.callbacks[name] == nil then
		-- Spring.Log(LOG_SECTION, LOG.WARNING, "No callback defined for command: " .. tostring(name))
		return
	end

	for _, callback in pairs(Connector.callbacks[name]) do
		local err
		success, err = pcall(function()
			callback(params)
		end)
		if not success then
			Spring.Log(LOG_SECTION, LOG.ERROR, "Error invoking callback: " .. tostring(err))
			Spring.Log(LOG_SECTION, LOG.ERROR, debug.traceback())
			return
		end
	end
end

-- update socket - receive data and split into lines
function widget:Update()
	isConnected = client ~= nil and client:getpeername()
	if not isConnected then
		self:SocketConnect(host, port)
		return
	end
	Connector._FlushCommandQueue()

	self:ReadAvailableSockets()
end

function widget:ReadAvailableSockets()
	local readable, _, err = socket.select({client}, {client}, 0)
	if err ~= nil and err ~= "timeout" then
		Spring.Log(LOG_SECTION, "warning", "spring-launcher error in select", err)
		return
	end

	for _, input in ipairs(readable) do
		local _, status, str = input:receive('*a') --try to read all data
		if (status == "timeout" or status == nil) and str ~= nil and str ~= "" then
			self:ParseCommandsFromString(str)
		elseif status == "closed" then
			input:close()
			client = nil
		end
	end
end

function widget:ParseCommandsFromString(str)
	local commandList = explode("\n", str)
	commandList[1] = buffer .. commandList[1]
	for i = 1, #commandList-1 do
		local command = commandList[i]
		if command ~= nil then
			CommandReceived(command)
		end
	end
	buffer = commandList[#commandList]
end
