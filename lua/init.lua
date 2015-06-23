lsb = {}

include("ui.lua")

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