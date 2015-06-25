lsb.ui = {}

lsb.ui.init = function()
	if(lsb.ui.vgui) then return end

	lsb.ui.vgui = vgui.Create("DHTML")
	lsb.ui.vgui:Dock(FILL)
	lsb.ui.vgui:DockMargin(0, 0, 0, 50)

	lsb.ui.vgui:OpenURL("asset://garrysmod/lua/menu/lsb/html/servers.html")
	lsb.ui.vgui:SetKeyboardInputEnabled(true)
	lsb.ui.vgui:SetMouseInputEnabled(true)
	lsb.ui.vgui:SetAllowLua(true)
	lsb.ui.vgui:RequestFocus()

	lsb.ui.vgui:MakePopup()
	lsb.ui.vgui:SetVisible(false)
end

lsb.ui.populate = function(servers)
	PrintTable(servers)
	
	local json = util.TableToJSON(servers)

	--print(json)

	lsb.ui.vgui:Call(string.format(
		[[
			var scope = angular.element(document.getElementsByTagName('body')[0]).scope();

			scope.$apply(function() {
				scope.serverResults = %s;
			});
		]],
		json
	))
end