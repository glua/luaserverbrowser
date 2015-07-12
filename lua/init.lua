lsb = {
	initialized = false
}

include("util.lua")
include("ui.lua")

--
--
--	our setup
--
--

--GetServers = function(...) print(...) end

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

	--the first of our servers
	lsb.getServers({appid = 4000, version = lsb.util.getVersion()})

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

lsb.getServers = function(options)
	lsb.ui.call([[
		$scope.loading = 1;
		$scope.serverResults = [];
	]])

	--lsb.util.print('Requesting master server list...')

	lsb.util.fetchServers(nil, {appid = 4000, version = lsb.util.getVersion()}, function(ips)
		if not(ips) then
			--lsb.util.print('Master server list response timed out')

			lsb.ui.call('$scope.loading = false;')

			return
		end

		--lsb.util.print('Master server list received!')
		--lsb.util.print('Getting server info...')

		local pinged = #ips
		local ponged = 0
		local servers = {}

		lsb.ui.call(string.format(
			[[
				$scope.loading = 2;
				$scope.resultsLength = %s;
			]],
			pinged
		))

		lsb.util.fetchServerInfo(ips, function(ip, data) 
			if(data) then
				servers[ip] = data

				data.ip = ip

				lsb.ui.call(string.format(
					'$scope.serverResults.push({info:%s});',
					util.TableToJSON(data)
				))

				ponged = ponged + 1
			end
		end, function()
			--lsb.util.print('Server info received!')
			--lsb.util.print(string.format('%u%% success rate (%u/%u)', (ponged / pinged) * 100, ponged, pinged))

			--lsb.ui.call('console.log(JSON.stringify($scope.serverResults));')

			lsb.ui.call('$scope.loading = false;')
		end)
	end)
end

concommand.Add('lua_run_menu', function(ply, cmd, args, argstr)
	RunString(argstr)
end)