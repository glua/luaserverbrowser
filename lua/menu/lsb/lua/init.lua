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

		lsb.getServers(region, options)
	end)

	if(lsb.cv.autoFetch:GetBool()) then
		--the first of our servers
		lsb.getServers(0xFF, {master = {appid = 4000, version = lsb.util.getVersion()}})
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
	--init our js variables
	lsb.ui.call([[
		$scope.loading = true;
		$scope.serverResults = [];
		$scope.prettyResults = [];
		$scope.numResults = 0;
		$scope.resultsLength = 0;
	]])

	dprint(1, 'Requesting master server list...')

	--query the master server
	lsb.util.fetchServers(region, options.master, function(ips)
		dprint(1, 'Master server list received!')
		dprint(1, string.format('Getting server info for %u servers', #ips))

		local pinged = #ips
		local ponged = 0

		lsb.ui.call(string.format('$scope.resultsLength = %s;', #ips))

		local num = 0
		local batch = {}

		local addResults = function()
			local str = '['

			for i = 1, #batch do
				local server = batch[i]

				str = string.format('%s{info:%s},', str, util.TableToJSON(server))
			end

			str = string.format('%s%s', str:sub(1, -2), ']')

			lsb.ui.call(string.format(
				'$scope.addResults(%u, %s);',
				num,
				str
			))

			num = 0
			table.Empty(batch)
		end

		--get the info for all of our ips
		lsb.util.fetchServerInfo(ips, function(ip, data) 
			if(data) then
				--for our own use later
				data.ip = ip

				local passed = true

				if(options.server) then
					for k, v in pairs(options.server) do
						if not(tostring(data[k]):lower():find(v, 0, lsb.cv.filterMode:GetBool())) then
							passed = false

							break
						end
					end
				end

				num = num + 1

				if(passed) then
					batch[#batch + 1] = data

					if(#batch >= math.max(lsb.cv.batchSize:GetInt(), 1)) then
						addResults()
					end
				end

				ponged = ponged + 1
			end
		end, function()
			if(#batch > 0) then
				addResults()
			end

			dprint(1, 'Server info received!')
			dprint(1, string.format('%u%% success rate (%u/%u)', (ponged / pinged) * 100, ponged, pinged))

			--lsb.ui.call('console.log("$scope.addResult(" + JSON.stringify($scope.serverResults[0]) + ")");')

			lsb.ui.call('$scope.loading = false;')
		end)
	end)
end

--will remove this eventually
concommand.Add('lua_run_menu', function(ply, cmd, args, argstr)
	RunString(argstr)
end)

--check for updates
http.Fetch("https://api.github.com/repos/glua/luaserverbrowser/commits?sha=master", function(body)
	local commits = util.JSONToTable(body)
	local headish = commits[2].sha --we can't get the current version cause there'd be no way to check

	local version = '761522a560c6a6e88779507345f6d10b6a72d3db' --I hate that I have to do this manually

	if not(version == headish) then
		lsb.util.print("Update available!")
		lsb.util.print("There is a new version of LSB available.")
		lsb.util.print(string.format("Visit https://github.com/glua/luaserverbrowser/compare/%s...%s to see changes.", version, commits[1].sha))
		lsb.util.print("Visit https://github.com/glua/luaserverbrowser to download.")
	end
end, function(err)
	lsb.util.print("Failed to check for updates!")
end)