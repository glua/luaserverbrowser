local cfg = {
	autoFetch 		= {1, 		"bool, automatically fetch a basic list of servers when starting up"},
	debugLevel 		= {0, 		"int, how much to print to console\n\t0: none\n\t1: basic debug info\n\t2: advanced debug info"},
	filterMode 		= {0, 		"bool, use lua patterns for filters (advanced)"},
	timeLimit 		= {3, 		"int, how long before we cancel any connections (min 1s)"},
	serverCount 	= {500, 	"int, how many servers to fetch from the master server before slowing down\n\tnote: servers are retrieved in batches of 231, so e.g. 924 and 1155 will have the same effect\n\t\talso, this has no effect on which servers are retrieved, all servers will be fetched"},
	maxConnections 	= {20, 		"int, how many active sockets to use at a time (min 1, max 100)"}
}

for k, v in pairs(cfg) do
	local cvar = string.format("lsb_%s",
		k:gsub("%u", function(char) return string.format("_%s", string.char(char:byte() + 32)) end)
	)

	--don't know if FCVAR_ARCHIVE is necessary
	lsb.data.config[k] = CreateConVar(cvar, v[1], FCVAR_ARCHIVE, v[2])

	local val = cookie.GetString(cvar)

	if(val) then
		RunConsoleCommand(cvar, val)
	else
		cookie.Set(cvar, tostring(v[1]))
	end
end

local lastChecked = 0

local think = function()
	if(CurTime() > lastChecked + 1) then
		for k, v in pairs(cfg) do
			local cvar = string.format("lsb_%s",
				k:gsub("%u", function(char) return string.format("_%s", string.char(char:byte() + 32)) end)
			)

			local val = lsb.data.config[k]:GetString()

			--I'm assuming that cookie.Set is kinda expensive
			if not(val == cookie.GetString(cvar)) then
				cookie.Set(cvar, val)
			end
		end

		lastChecked = CurTime()
	end
end

hook.Add("Think", "lsbCookieCheck", think)