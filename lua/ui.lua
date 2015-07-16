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

	--let the browser know our version
	lsb.ui.call(string.format('$scope.query.master.version_match = "%s";', lsb.util.getVersion()))

	--our lua stuff
	lsb.ui.vgui:AddFunction("lsb", "getServerRules", function(ip, port, index)
		lsb.util.fetchServerRules(ip, port, function(rules)
			lsb.ui.call(string.format(
				"$scope.serverResults[%s].rules = %s",
				index,
				util.TableToJSON(rules)
			))
		end)
	end)

	lsb.ui.vgui:AddFunction("lsb", "joinServer", function(ip, port)
		RawConsoleCommand(string.format(
			"connect %s:%s",
			ip,
			port
		))
	end)
end

lsb.ui.call = function(str)
	--lsb.util.print(string.format("running js '%s'", str))

	return lsb.ui.vgui:Call(string.format(
		[[
			var $scope = angular.element(document.getElementsByTagName('body')[0]).scope();

			$scope.$apply(function() {
				%s
			});
		]],
		str
	))
end