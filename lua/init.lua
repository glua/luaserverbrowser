lsb = {}

include("util.lua")
include("ui.lua")

--
--
-- our setup
--
--

function lsb.init()
	--get our vgui ready
	lsb.ui.init()

	--holy hacks
	pnlMainMenu.HTML:AddFunction("lsb", "setVisible", function(b)
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
end

hook.Add("GameContentChanged", "lsb", lsb.init)

--
--
-- fetch the first of our servers
--
--

lsb.util.fetchServers(nil, {appid = 4000, version = lsb.util.getVersion()}, function(ips)
	if not(ips) then
		lsb.util.print('Master list response timed out')
		return
	end

	local amt = 0
	local servers = {}

	for i = 1, #ips do
		lsb.util.fetchServerInfo(ips[i], function(data) 
			if(data) then
				servers[ips[i]] = data

				amt = amt + 1
			end
		end)
	end

	timer.Simple(15, function()
		lsb.ui.populate(servers)
	end)
end)