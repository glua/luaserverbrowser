lsb = {
	initialized = false
}

include("convars.lua")
include("util.lua")
include("ui.lua")

--
--
--	our setup
--
--

--GetServers = function(...) print(...) end

local dprint = function(level, ...)
	if(lsb.cv.debugLevel:GetInt() >= level) then
		lsb.util.print(...)
	end
end

function lsb.init()
	if(lsb.initialized) then return end

	--get our vgui ready
	lsb.ui.init()

	--holy hacks
	pnlMainMenu.HTML:AddFunction("lsb", "setVisible", function(b)
		--don't just hide the original, cancel it
		DoStopServers('internet')

		--use ours instead
		lsb.ui.vgui:SetVisible(b)
	end)

	--this code is bad
	pnlMainMenu.HTML:Call([[
		//angular event for ng-view changes

		$('body').scope().$root.$on('$viewContentLoaded', function() {
			var isServers = $('div.server_gamemodes').length > 0;

			lsb.setVisible(isServers);
			$('div.page').css('visibility', (isServers ? 'hidden' : 'visible'));
		});
	]])

	lsb.ui.vgui:AddFunction("lsb", "getServers", function(options)
		dprint(1, 'fetching servers with options:\n\t', options)

		options = util.JSONToTable(options)

		local region = string.char(options.master.region)
		options.master.region = nil

		--options.server.map = string.format('^%s$', options.server.map)

		lsb.getServers(region, options)
	end)

	if(lsb.cv.autoFetch:GetBool()) then
		--the first of our servers
		lsb.getServers(0xFF, {appid = 4000, version = lsb.util.getVersion()})
	end

	--done :)
	lsb.initialized = true
end

hook.Add("GameContentChanged", "lsb.GCC.init", lsb.init)

--
--
--	abstract our server-getting
--	this is to make it easy since we have to get our server list and
--	individual info for each server
--
--

lsb.getServers = function(region, options)
	lsb.ui.call([[
		$scope.loading = 1;
		$scope.serverResults = [];
		$scope.prettyResults = [];
		$scope.numResults = 0;
		$scope.resultsLength = 0;
	]])

	dprint(1, 'Requesting master server list...')

	lsb.util.fetchServers(nil, region, options.master, function(ips)
		if not(ips) then
			dprint(1, 'Master server list response timed out')

			lsb.ui.call('$scope.loading = false;')

			return
		end

		dprint(1, 'Master server list received!')
		dprint(1, string.format('Getting server info for %u servers', #ips))

		local ponged = 0

		lsb.ui.call(string.format(
			[[
				$scope.loading = 2;
				$scope.resultsLength = %s;
			]],
			#ips
		))

		lsb.util.fetchServerInfo(ips, function(ip, data) 
			if(data) then
				data.ip = ip

				local passed = true

				if(options.server) then
					for k, v in pairs(options.server) do
						if not(data[k]:lower():find(v, 0, lsb.cv.filterMode:GetBool())) then
							passed = false

							break
						end
					end
				end

				lsb.ui.call(string.format(
					'$scope.addResult(%s, %s);',
					(passed and string.format('{info:%s}', util.TableToJSON(data)) or 'undefined'),
					(passed and 'true' or 'false')
				))

				ponged = ponged + 1
			end
		end, function()
			dprint(1, 'Server info received!')
			dprint(1, string.format('%u%% success rate (%u/%u)', (ponged / #ips) * 100, ponged, #ips))

			--lsb.ui.call('console.log("$scope.addResult(" + JSON.stringify($scope.serverResults[0]) + ")");')

			lsb.ui.call('$scope.loading = false;')
		end)
	end)
end

concommand.Add('lua_run_menu', function(ply, cmd, args, argstr)
	RunString(argstr)
end)