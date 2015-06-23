lsb = {}

include("util.lua")
include("ui.lua")

lsb.util.fetchServers(nil, nil, function(ips)
	--why the hell is this crashinggggg
	--it makes no sense
	--I don't reuse any sockets, and I close the first before opening the second
	--help me
	
	lsb.util.fetchServerInfo('104.149.228.84:27035', PrintTable)
end)

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