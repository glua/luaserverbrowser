lsb.util = {
	print = function(...)
		print(string.format('[LSB] - %s', table.concat({...})))
	end,
	printh = function(str)
		str:gsub('.', function(a) print('', a, string.format('0x%02X', a:byte())) end)
	end,

	timelimit = 10
}

--
--
--	our setup
--	todo: use serverlist.query if module not found
--
--

if not(pcall(require, 'glsock')) then
	lsb.util.print('GLSock module not found - falling back to serverlist')

	lsb.util.fetchServers = serverlist.Query

	return
end

--
--
--	private stuff, just for us :ssh:
--
--

local sock = GLSock(GLSOCK_TYPE_UDP)

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
		--if(err ~= GLSOCK_ERROR_OPERATIONABORTED) then
			print(string.format("GLSock error #%d", err))
		--end

		return true
	end
end

local readBuffer = function(buff, type, ...)
	return select(2, buff[string.format("Read%s", type)](buff, ...)) or 0
end

--https://developer.valvesoftware.com/wiki/Master_Server_Query_Protocol

local buildMessage = function(ip, options)
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

--
--
--	our callbacks
--	this is where most of the fun stuff happens
--
--

local fetchServersCallback = function(sock, callback)
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

--https://developer.valvesoftware.com/wiki/Server_Queries

local fetchServerInfoCallback = function(sock, callback)
	sock:ReadFrom(1400, function(sock, host, port, data, err)
		if(handleErr(err)) then return end

		--first byte is always going to be 0x54
		--I think protocal is useless too, and then there's trash right after it
		--so let's just get rid of all of it 
		data:Clear(6)

		local info = {
			--protocol 		= readBuffer(data, 'Byte'),
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
			version 		= readBuffer(data, 'String'),
			EDF 			= readBuffer(data, 'Byte')
		}

		if(bit.band(info.EDF, 0x80) == 0x80) then
			info.port 		= readBuffer(data, 'Byte')
		end

		if(bit.band(info.EDF, 0x10) == 0x10) then
			info.steamID 	= readBuffer(data, 'Long')
		end

		if(bit.band(info.EDF, 0x40) == 0x40) then
			info.specPort 	= readBuffer(data, 'Short')
			info.specName 	= readBuffer(data, 'String')
		end

		if(bit.band(info.EDF, 0x20) == 0x20) then
			--more trash??
			data:Clear(5)

			info.tags 		= readBuffer(data, 'String')
		end

		if(bit.band(info.EDF, 0x01) == 0x01) then
			info.gameID 	= readBuffer(data, 'Long')
		end

		callback(info)
	end)
end

--
--	
--	the public stuff
--
--

local queue = {}
local alive = {}

--would have been nice to have this a coroutine
hook.Add("Think", "lsbCoreThink", function()
	--check to see if any of our servers timed out 
	for i = 1, #alive do
		--always gonna be on top of the stack
		local curCon = alive[1]

		if(curCon.stime + lsb.util.timelimit < CurTime()) then
			--cancel?

			curCon.callback()

			--remove this connection
			table.remove(alive, 1)
		else
			--all of our connections were made and added in chronological order
			--so if one isn't old enough to timeout, the rest won't be either
			break
		end
	end

	--start the connection for the next server
	if(#queue > 0) then
		--get the bottom of our queue
		local curServer = table.remove(queue)

		local buff = GLSockBuffer()

		buff:Write(serverQuery)

		--send our query
		sock:SendTo(buff, curServer.ip, curServer.port, function(sock, len, err)
			if(handleErr(err)) then return end

			local stime = CurTime()

			--hopefully this will get called
			fetchServerInfoCallback(sock, function(info)
				--if it does, we want to remove this connection from the list of
				--potentially timed out ones
				for i = 1, #alive do
					local curCon = alive[i]

					--we can use our start time to identify this connection because
					--we only do one connection per frame
					if(curCon.stime == stime) then
						table.remove(alive, i)
						break
					end
				end

				info.ping = math.floor((CurTime() - stime) * 1000)

				curServer.callback(info)
			end)
			
			--make sure we can still interact with this connection
			table.insert(alive, {
				stime = stime,
				--sock = sock, save this until I find out how to cancel connections
				callback = curServer.callback
			})
		end)
	end
end)

lsb.util.fetchServers = function(ip, options, callback)
	local msg = buildMessage(ip, options or {})

	local buff = GLSockBuffer()

	buff:Write(msg)

	sock:SendTo(buff, 'hl2master.steampowered.com', 27011, function(sock, len, err)
		if(handleErr(err)) then return end

		local resolved = false

		fetchServersCallback(sock, function(info)
			if(resolved) then return end
			resolved = true

			--cancel timer?

			callback(info)
		end)

		timer.Simple(lsb.util.timelimit, function()
			if(resolved) then return end
			resolved = true

			sock:Cancel()

			callback()
		end)
	end)
end

lsb.util.fetchServerInfo = function(fullip, callback)
	--this probably needs work
	local ip, port = fullip:match('(.*):(.*)')

	table.insert(queue, 1, {
		ip = ip,
		port = port and tonumber(port) or 27015,
		callback = callback
	})
end

--other public stuff

local version
lsb.util.getVersion = function()
	if not(version) then
	 	version = (file.Read("steam.inf", "MOD") or ""):match("PatchVersion=([^\n]+)")
	end

	return version
end