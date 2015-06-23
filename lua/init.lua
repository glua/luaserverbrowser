lsb = {}

include("util.lua")
include("ui.lua")

lsb.util.fetchServers(nil, {appid = 4000, version = '15.04.03', }, function(ips)
	--[[
	
	new problem
	even after making a new buffer, it doesn't seem to work correctly
	the second buffer seems to be filled with garbage, the results of the first query, or my ram
	source never calls us back because our query isn't what they want

	]]

	local amt = 0

	for i = 1, 10 do
		print(i, ips[i], "sent")
		
		lsb.util.fetchServerInfo(ips[i], function(data) 
			print(i, "received")

			--PrintTable(data)

			amt = amt + 1
		end)
	end

	timer.Simple(1, function()
		print(amt, "/10 responses received")
	end)
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