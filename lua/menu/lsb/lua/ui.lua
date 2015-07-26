lsb.ui = {}

--interacting with lua
local functions = {
	getServerRules = function(ip, port, index)
		lsb.util.fetchServerRules(ip, port, function(rules)
			lsb.ui.call(string.format(
				"$scope.addRules(%s, %s)",
				index,
				util.TableToJSON(rules)
			))
		end)
	end,

	getServerPlayers = function(ip, port, index)
		lsb.util.fetchServerPlayers(ip, port, function(players)
			lsb.ui.call(string.format(
				"$scope.addPlayers(%s, %s)",
				index,
				util.TableToJSON(players)
			))
		end)
	end,

	joinServer = function(ip, port)
		RawConsoleCommand(string.format(
			"connect %s:%s",
			ip,
			port
		))
	end
}

--make our replacement menu
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

	for k, v in pairs(functions) do
		lsb.ui.vgui:AddFunction("lsb", k, v)
	end
end

lsb.ui.call = function(str)
	if(lsb.cv.debugLevel:GetInt() >= 2) then
		lsb.util.print(string.format("running js '%s'", str))
	end

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