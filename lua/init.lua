lsb = {}

include("util.lua")
include("ui.lua")

lsb.util.fetchServers(nil, {appid = 4000}, function(ips)
	--[[
	
	new problem
	even after making a new buffer, it doesn't seem to work correctly
	the second buffer seems to be filled with garbage, the results of the first query, or my ram
	source never calls us back because our query isn't what they want

	]]

	lsb.util.fetchServerInfo("76.23.113.56:27015", PrintTable)
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