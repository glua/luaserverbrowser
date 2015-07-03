lsb.util = {
	print = function(...)
		print(string.format('[LSB] - %s', table.concat({...})))
	end,
	printh = function(str)
		if not(type(str) == 'string') then
			str = tostring(str)
		end

		local x = 1

		for i = 1, math.ceil(#str / 16) do
			local hex, dec = {}, {}

			for j = 1, 16 do
				local c = str[x]
				local b = c:byte()

				if(#c > 0) then
					hex[#hex + 1] = string.format('%02X', b)
					dec[#dec + 1] = (b > 0x1F and b ~= 0x7F) and c or '.'
				else
					hex[#hex + 1] = '  '
					dec[#dec + 1] = ' '
				end

				x = x + 1
			end

			print(table.concat(hex, ' '), '', table.concat(dec))
		end
	end,
	buildBuffer = function(...)
		local tab = {...}

		for i = 1, #tab do
			local v = tab[i]

			if(type(v) == 'number') then
				tab[i] = string.char(tab[i])
			end
		end

		return table.concat(tab)
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

--our main sock, we're gonna use it a lot
local sock = GLSock(GLSOCK_TYPE_UDP)

--all source queries start with -1
local neg1 = lsb.util.buildBuffer(0xFF, 0xFF, 0xFF, 0xFF)

--the types of requests that we can send to our servers
local query = {
	info 	= lsb.util.buildBuffer(neg1, 0x54, 'Source Engine Query', 0x00),
	player 	= lsb.util.buildBuffer(neg1, 0x55), 
	rules 	= lsb.util.buildBuffer(neg1, 0x56)
}

--simple error catching :)
local handleErr = function(err)
	if(err ~= GLSOCK_ERROR_SUCCESS) then
		--make sure we didn't throw it
		if(err ~= GLSOCK_ERROR_OPERATIONABORTED) then
			--this is a real error then, print it 

			lsb.util.print(string.format("GLSock error #%d", err))
		end

		return true
	end
end

--ugly code to skip the stupid first return value
local readBuffer = function(buff, type, ...)
	return select(2, buff[string.format("Read%s", type)](buff, ...)) or 0
end

--separate the parts of an ip
local sepIP = function(fullip)
	return fullip:match("(%d+%.%d+%.%d+%.%d+):(%d+)")
end

--the setup for our master server queries
--see https://developer.valvesoftware.com/wiki/Master_Server_Query_Protocol
local buildMessage = function(ip, options)
	local tab = {
		0x31,
		0x00,
		ip or '0.0.0.0:0',
		0x00
	}

	for k, v in pairs(options) do
		tab[#tab + 1] = string.format('\\%s\\%s', k, v)
	end

	tab[#tab + 1] = 0x00

	return lsb.util.buildBuffer(unpack(tab))
end

--unreliable as hell, this sucks
--see https://developer.valvesoftware.com/wiki/Server_Queries#A2S_RULES
local getChallenge = function(ip, port, msg, callback)
	local sock = GLSock(GLSOCK_TYPE_UDP)

	local buff = GLSockBuffer()

	buff:Write(msg)

	--we don't have our challenge yet, so we send -1
	buff:Write(neg1)

	sock:SendTo(buff, ip, port, function(sock, len, err)
		print(5)

		if(handleErr(err)) then return end

		sock:ReadFrom(1400, function(sock, host, port, data, err)
			print(6)

			if(handleErr(err)) then return end

			--this response is unreliable
			--possible responses:
			--	0xFFFFFFFF, 0x41, challenge
			--	0xFFFFFFFF, 0x45, rules
			--	0xFFFFFFFE, long, byte, byte, short, part one of rules

			local type = readBuffer(data, 'Long')

			if(type == 0xFFFFFFFF) then
				--the packet isn't split, but it could either be the challenge or rules

				local header = readBuffer(data, 'Byte')

				if(header == 0x41) then
					--we got our challenge

					callback(readBuffer(data, 'Long'))
				elseif(header == 0x45) then
					--we got rules

					callback()
				elseif(header == 0x44) then
					--we got players? (not sure if this will ever happen)

					callback()
				end
			else
				--oh boy
				--we probably got a bunch of rules
			end
		end)
	end)
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
			info.port 		= readBuffer(data, 'Short')
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

local readPacket = function(data)
	local header 		= readBuffer(data, 'Long')
	local id 			= readBuffer(data, 'Long')
	local numPackets 	= readBuffer(data, 'Byte')
	local packetNum 	= readBuffer(data, 'Byte')
	local packetLength 	= readBuffer(data, 'Short')

	local numRules

	if(packetNum == 0) then
		--0xFF 0xFF 0xFF 0xFF 0x45
		data:Clear(5)

		numRules = readBuffer(data, 'Short')

		packetLength = packetLength - 7
	end

	local str = readBuffer(data, '', packetLength)

	--print(packetNum)
	--lsb.util.printh(str)

	return packetNum, str, numRules
end

local readRules = function(data, numRules)
	local ret = {}

	data:Seek(0, GLSOCKBUFFER_SEEK_SET)

	for i = 1, numRules do
		local key, val = readBuffer(data, 'String'), readBuffer(data, 'String')

		ret[key] = val
	end

	return ret
end

local fetchServerRulesCallback = function(sock, callback)
	sock:ReadFrom(1400, function(sock, host, port, data, err)
		if(handleErr(err)) then return end

		local type = readBuffer(data, 'Long')

		if(type == 0xFFFFFFFF) then
			--single packet

			--todo

			return
		else
			--split packet

			local id 			= readBuffer(data, 'Long')
			local numPackets 	= readBuffer(data, 'Byte')

			data:Seek(0, GLSOCKBUFFER_SEEK_SET)

			local combined = {}
			local numRead = 1
			local numRules

			for i = 0, numPackets do
				if(i == 0) then
					--we already have our first packet

					local num, payload, rules = readPacket(data)

					numRules = rules

					--we have to use 1 indexing to play nice with table.concat
					combined[num + 1] = payload
				else
					--gotta read it

					sock:ReadFrom(1400, function(sock, host, port, data, err)
						local num, payload = readPacket(data)

						combined[num + 1] = payload

						numRead = numRead + 1

						if(numRead == numPackets) then
							local buff = GLSockBuffer()

							buff:Write(table.concat(combined))

							callback(readRules(buff, numRules))
						end
					end)
				end
			end
		end
	end)
end

--
--	
--	the public stuff
--	note, this assumes that only one batch of servers will be requested
--	at a time. this is intended because if you need a new batch of servers,
--	you shouldn't need the old ones anyway (might wanna rethink your batches
--	if that's not the case!)
--
--

local queue = {}
local alive = {}
local callback

--would have been nice to have this a coroutine
hook.Add("Think", "lsbCoreThink", function()
	--if we have connections open
	if(#alive > 0) then
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
	elseif(#queue == 0 and callback) then
		callback()

		callback = nil
	end

	--start the connection for the next server
	if(#queue > 0) then
		--get the bottom of our queue
		local curServer = table.remove(queue)

		local buff = GLSockBuffer()

		buff:Write(query.info)

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

				curServer.callback(curServer.fullip, info)
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

lsb.util.fetchServerInfo = function(ips, serverCallback, doneCallback)
	for i = 1, #ips do
		local fullip = ips[i]

		local ip, port = sepIP(fullip)

		ips[i] = {
			fullip = ip,
			ip = ip,
			port = port and tonumber(port) or 27015,
			callback = serverCallback
		}
	end

	queue = ips
	table.Empty(alive) --optimized :)
	callback = doneCallback
end

--todo: memoization
lsb.util.fetchServerRules = function(ip, port, callback)
	getChallenge(ip, port, query.rules, function(challenge)
		local sock = GLSock(GLSOCK_TYPE_UDP)

		local buff = GLSockBuffer()

		buff:Write(query.rules)
		buff:WriteLong(challenge)

		sock:SendTo(buff, ip, port, function(sock, len, err)
			if(handleErr(err)) then return end
			
			fetchServerRulesCallback(sock, callback)
		end)
	end)
end

--other public stuff

local version
lsb.util.getVersion = function()
	if not(version) then
	 	version = (file.Read("steam.inf", "MOD") or ""):match("PatchVersion=(%d-%.%d-%.%d+)")
	end

	return version
end