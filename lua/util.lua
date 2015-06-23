require("glsock")

lsb.util = {
	printh = function(str)
		str:gsub('.', function(a) print('', a, string.format('0x%02X', a:byte())) end)
	end,

	--sock = GLSock(GLSOCK_TYPE_UDP), crashes :(
	buff = GLSockBuffer()
}

--https://developer.valvesoftware.com/wiki/Master_Server_Query_Protocol

lsb.util.buildMessage = function(ip, options)
	local tab = {
		string.char(0x31),
		string.char(0xFF),
		ip or '0.0.0.0:0',
		string.char(0X00)
	}

	for k, v in pairs(options) do
		tab[#tab + 1] = string.format('\\%s\\%s', k, v)
	end

	tab[#tab + 1] = string.char(0x00)

	return table.concat(tab)
end

lsb.util.fetchServers = function(ip, options, callback)
	local msg = lsb.util.buildMessage(ip, options or {})

	lsb.util.buff:Write(msg)

	local sock = GLSock(GLSOCK_TYPE_UDP)

	sock:SendTo(lsb.util.buff, 'hl2master.steampowered.com', 27011, function(sock2, len, err)
		--[[ print(string.format('sent %u bytes:', len))
		printh(msg)
		print('') ]]

		if(err ~= GLSOCK_ERROR_SUCCESS) then
			print(err)
			return
		end

		sock2:ReadFrom(1400, function(sock3, host, port, data, err)
			if(err ~= GLSOCK_ERROR_SUCCESS) then
				print(err)
				return
			end

			--this is always gonna be 0xFF 0xFF 0xFF 0xFF 0x66 0x0A
			data:Clear(6)

			local ips = {}

			while(ips[#ips] ~= '0.0.0.0:0') do
				ips[#ips + 1] = string.format('%u.%u.%u.%u:%u',
					select(2, data:ReadByte()) or 0,
					select(2, data:ReadByte()) or 0,
					select(2, data:ReadByte()) or 0,
					select(2, data:ReadByte()) or 0,
					select(2, data:ReadShort(true)) or 0
				)
			end

			ips[#ips] = nil;

			sock3:Cancel()
			sock3:Close()

			sock2:Cancel()
			sock2:Close()

			sock:Cancel()
			sock:Close()

			callback(ips)
		end)
	end)

	lsb.util.buff:Clear(lsb.util.buff:Size())
end

--https://developer.valvesoftware.com/wiki/Server_Queries

lsb.util.fetchServerInfo = function(fullip, callback)
	lsb.util.buff:Write(table.concat({
		string.char(0xFF),
		string.char(0xFF),
		string.char(0xFF),
		string.char(0xFF),
		string.char(0x54),
		'Source Engine Query',
		string.char(0x00)
	}))

	local ip, port = fullip:match('(.*):(.*)')

	local sock = GLSock(GLSOCK_TYPE_UDP)

	print('a')

	sock:SendTo(lsb.util.buff, ip, port and tonumber(port) or 27015, function(sock2, len, err)
		if(err ~= GLSOCK_ERROR_SUCCESS) then
			print(err)
			return
		end

		print('b')

		sock2:ReadFrom(1400, function(sock3, host, port, data, err)
			if(err ~= GLSOCK_ERROR_SUCCESS) then
				print(err)
				return
			end

			print('c')

			data:Clear(1)

			local info = {
				protocol = select(2, data:ReadByte()) or 0,
				name = select(2, data:ReadString()) or '',
				map = select(2, data:ReadString()) or '',
				folder = select(2, data:ReadString()) or '',
				gamemode = select(2, data:ReadString()) or '',
				appid = select(2, data:ReadShort()) or 0,
				numPlayers = select(2, data:ReadByte()) or 0,
				maxPlayers = select(2, data:ReadByte()) or 0,
				numBots = select(2, data:ReadByte()) or 0,
				type = select(2, data:ReadByte()) or 0,
				env = select(2, data:ReadByte()) or 0,
				pass = select(2, data:ReadByte()) or 0,
				VAC = select(2, data:ReadByte()) or 0,
				version = select(2, data:ReadString()) or 0
			}

			local flag = select(2, data:ReadByte()) or 0

			if(bit.band(flag, 0x80)) then
				info.port = select(2, data:ReadByte()) or 0
			end

			if(bit.band(flag, 0x10)) then
				info.steamID = select(2, data:ReadLong()) or 0
			end

			if(bit.band(flag, 0x40)) then
				info.specPort = select(2, data:ReadShort()) or 0
				info.specName = select(2, data:ReadString()) or 0
			end

			if(bit.band(flag, 0x20)) then
				info.tags = select(2, data:ReadByte()) or 0
			end

			if(bit.band(flag, 0x01)) then
				info.gameID = select(2, data:ReadLong()) or 0
			end

			sock3:Cancel()
			sock3:Close()

			sock2:Cancel()
			sock2:Close()

			sock:Cancel()
			sock:Close()

			callback(info)
		end)
	end)

	lsb.util.buff:Clear(lsb.util.buff:Size())
end