require("glsock")

--https://developer.valvesoftware.com/wiki/Master_Server_Query_Protocol

local function printh(str)
	str:gsub('.', function(a) print('', a, string.format('0x%02X', a:byte())) end)
end

local udp = GLSock(GLSOCK_TYPE_UDP)

local msg = table.concat({
	string.char(0x31),
	string.char(0xFF),
	'0.0.0.0:0',
	string.char(0x00),
	'\\appid\\4000',
	'\\version_match\\15.04.03',
	'\\gamedir\\garrysmod',
	string.char(0x00)
})

local buff = GLSockBuffer()

buff:Write(msg)

udp:SendTo(buff, 'hl2master.steampowered.com', 27011, function(sock, len, err)
	print(string.format('sent %u bytes:', len))
	printh(msg)
	print('')

	if(err == GLSOCK_ERROR_SUCCESS) then
		sock:ReadFrom(0xFF * 1024, function(sock, host, port, data, err)
			if(err == GLSOCK_ERROR_SUCCESS) then
				--this is always gonna be 0xFF 0xFF 0xFF 0xFF 0x66 0x0A
				--
				local len, buff = data:Read(6)

				print(string.format('received %u bytes:', len))
				printh(buff)
				print('')

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

				print('results:')
				PrintTable(ips)
			end
		end)
	else
		print(err)
	end
end)