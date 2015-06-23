require("glsock")

lsb.util = {
	printh = function(str)
		str:gsub('.', function(a) print('', a, string.format('0x%02X', a:byte())) end)
	end,

	sock = GLSock(GLSOCK_TYPE_UDP),
	--buff = GLSockBuffer() this is crashing

	timelimit = 0.1
}

local serverQuery = table.concat({
	string.char(0xFF),
	string.char(0xFF),
	string.char(0xFF),
	string.char(0xFF),
	string.char(0x54),
	'Source Engine Query',
	string.char(0x00)
})

local handleErr = function(err)
	if(err ~= GLSOCK_ERROR_SUCCESS) then
		ErrorNoHalt(string.format("GLSock error #%d", err))
		return true
	end
end

local readBuffer = function(buff, type, ...)
	return select(2, buff[string.format("Read%s", type)](buff, ...)) or 0
end

--https://developer.valvesoftware.com/wiki/Master_Server_Query_Protocol

lsb.util.buildMessage = function(ip, options)
	local tab = {
		string.char(0x31),
		string.char(0x00),
		ip or '0.0.0.0:0',
		string.char(0X00)
	}

	for k, v in pairs(options) do
		tab[#tab + 1] = string.format('\\%s\\%s', k, v)
	end

	tab[#tab + 1] = string.char(0x00)

	return table.concat(tab)
end

lsb.util.fetchServersCallback = function(sock, callback)
	--"Steam uses a packet size of 1400 bytes + IP/UDP headers. If a request or response needs more packets for the data it starts the packets with an additional header."
	sock:ReadFrom(1400, function(sock, host, port, data, err)
		if(handleErr(err)) then return end

		--this is always gonna be 0xFF 0xFF 0xFF 0xFF 0x66 0x0A
		data:Clear(6)

		local ips = {}

		while(ips[#ips] ~= '0.0.0.0:0') do
			ips[#ips + 1] = string.format('%u.%u.%u.%u:%u',
				readBuffer(data, 'Byte'),
				readBuffer(data, 'Byte'),
				readBuffer(data, 'Byte'),
				readBuffer(data, 'Byte'),
				readBuffer(data, 'Short', true)
			)
		end

		--pop the last one
		ips[#ips] = nil;

		sock:Cancel()
		data:Clear(data:Size())

		callback(ips)
	end)
end

lsb.util.fetchServers = function(ip, options, callback)
	local msg = lsb.util.buildMessage(ip, options or {})

	local buff = GLSockBuffer()

	buff:Write(msg)

	lsb.util.sock:SendTo(buff, 'hl2master.steampowered.com', 27011, function(sock, len, err)
		if(handleErr(err)) then return end

		lsb.util.fetchServersCallback(sock, callback)
	end)
end

--https://developer.valvesoftware.com/wiki/Server_Queries

lsb.util.fetchServerInfoCallback = function(sock, callback)
	sock:ReadFrom(1400, function(sock, host, port, data, err)
		if(handleErr(err)) then return end

		--this is always going to be 0x54
		data:Clear(1)

		local info = {
			protocol 		= readBuffer(data, 'Byte'),
			name 			= readBuffer(data, 'String'),
			map 			= readBuffer(data, 'String'),
			folder 			= readBuffer(data, 'String'),
			gamemode 		= readBuffer(data, 'String'),
			appid 			= readBuffer(data, 'Short'),
			numPlayers 		= readBuffer(data, 'Byte'),
			maxPlayers 		= readBuffer(data, 'Byte'),
			numBots 		= readBuffer(data, 'Byte'),
			type 			= readBuffer(data, 'Byte'),
			env 			= readBuffer(data, 'Byte'),
			pass 			= readBuffer(data, 'Byte'),
			VAC 			= readBuffer(data, 'Byte'),
			version 		= readBuffer(data, 'String')
		}

		local flag 			= readBuffer(data, 'Byte')

		if(bit.band(flag, 0x80) == 0x80) then
			info.port 		= readBuffer(data, 'Byte')
		end

		if(bit.band(flag, 0x10) == 0x10) then
			info.steamID 	= readBuffer(data, 'Long')
		end

		if(bit.band(flag, 0x40) == 0x40) then
			info.specPort 	= readBuffer(data, 'Short')
			info.specName 	= readBuffer(data, 'String')
		end

		if(bit.band(flag, 0x20) == 0x20) then
			info.tags 		= readBuffer(data, 'String')
		end

		if(bit.band(flag, 0x01) == 0x01) then
			info.gameID 	= readBuffer(data, 'Long')
		end

		callback(info)
	end)
end

lsb.util.fetchServerInfo = function(fullip, callback)
	local buff = GLSockBuffer()

	buff:Write(serverQuery)

	--this probably needs work
	local ip, port = fullip:match('(.*):(.*)')

	lsb.util.sock:SendTo(buff, ip, port and tonumber(port) or 27015, function(sock, len, err)
		if(handleErr(err)) then return end

		lsb.util.fetchServerInfoCallback(sock, callback)
	end)

	buff:Clear(buff:Size())
end