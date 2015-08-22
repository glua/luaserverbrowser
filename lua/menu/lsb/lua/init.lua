lsb = {
	initialized = false,
	data = {
		favorites = {},
		config = {}
	}
}

--our files
if not(file.Exists("lsb", "DATA")) then
	file.CreateDir("lsb")
end

--include("manager.lua")

include("convars.lua")
include("util.lua")
include("ui.lua")

--
--
--	our setup
--
--

local dprint = function(level, ...)
	if(lsb.data.config.debugLevel:GetInt() >= level) then
		lsb.util.print(...)
	end
end

local init = function()
	if(lsb.initialized) then return end

	--our favorites
	if(file.Exists("lsb/favorites.dat", "DATA")) then
		for k, v in pairs(string.Explode("\n", file.Read("lsb/favorites.dat", "DATA"))) do
			lsb.data.favorites[v] = true
		end
	end

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

	lsb.ui.vgui:AddFunction("lsb", "getServers", function(fullRefresh, region)
		--avoid creating a table if we have to
		if(fullRefresh) then
			lsb.getServers(true, region, {appid = 4000, version = lsb.util.getVersion()})
		else
			lsb.getServers()
		end
	end)

	--the first of our servers
	if(lsb.data.config.autoFetch:GetBool()) then
		lsb.getServers(true, 0xFF, {appid = 4000, version = lsb.util.getVersion()})
	end

	--done :)
	lsb.initialized = true
end

hook.Add("GameContentChanged", "lsbInit", init)

--
--
--	abstract our server-getting
--	this is to make it easy since we have to get our server list and
--	individual info for each server
--
--

--setting stuff up for later
local time = math.huge
local batch = {}
local addbatch

--this is new and I don't like the way I do it 
local overflowCallback = function(ips)
	local data = {}

	for i = 1, #ips do
		local ip = ips[i]

		lsb.masterList[ip] = false

		data[ip] = false
	end

	time = 0

	lsb.util.fetchServerInfo(data, function(ip, data)
		if(data) then
			lsb.masterList[ip] = data
			batch[#batch + 1] = data
		end
	end, function()
		if(#batch > 0) then
			addbatch()
		end

		time = math.huge
	end)
end

lsb.getServers = function(fullRefresh, region, options)
	--either way we gotta redo the html part, so let's get ready
	lsb.ui.call("$scope.serverResults = []; $scope.prettyResults = [];")

	--only do this if we have to (faster)
	if(not lsb.masterList or fullRefresh) then
		dprint(1, "Requesting master server list...")

		lsb.util.fetchServers(region, options, function(ips)
			dprint(1, "Master server list received!")

			lsb.masterList = {}

			for k, v in pairs(lsb.data.favorites) do
				lsb.masterList[k] = false
			end

			for k, v in pairs(ips) do
				lsb.masterList[v] = false
			end

			--try again
			lsb.getServers(false)
		end, overflowCallback)

		return
	end

	--assume that we can prepare to send stuff
	time = 0
	batch = {}

	--we don't need to do this, assume that if the function is called we want a quick refresh

	--[[
	--same thing
	local gotinfo = false

	for k, v in pairs(lsb.masterList) do
		if(v) then
			gotinfo = true
			break
		end
	end

	if(not gotinfo or options.refreshType == 1) then ]]

		local pinged = table.Count(lsb.masterList)
		local ponged = 0

		dprint(1, string.format("Getting server info for %u servers", pinged))

		--get the info for all of our ips
		lsb.util.fetchServerInfo(lsb.masterList, function(ip, data) 
			if(data) then
				if(lsb.data.favorites[ip]) then
					data.favorite = true
				end

				lsb.masterList[ip] = data
				batch[#batch + 1] = data

				ponged = ponged + 1
			end
		end, function()
			dprint(1, 'Server info received!')
			dprint(1, string.format('%u%% success rate (%u/%u)', (ponged / pinged) * 100, ponged, pinged))

			if(#batch > 0) then
				addbatch()
			end

			time = math.huge

			options.refreshType = false

			--try again for a THIRD time
			--lsb.getServers(region, options)
		end)

		time = 0
	--end
end

--sending servers to html
addbatch = function()
	local str = ""

	for i = 1, #batch do
		local server = batch[i]

		str = string.format("%s{info:%s,favorite:%s},", str, util.TableToJSON(server), server.favorite and "true" or "false")
	end

	str = string.format("[%s]", str:sub(1, -2))

	lsb.ui.call(string.format("$scope.addResults(%s);", str))

	table.Empty(batch)
end

--only once a second
local think = function()
	if(CurTime() > time + 1 and #batch > 0) then
		addbatch()

		time = CurTime()
	end
end

hook.Add("Think", "lsb.think", think)