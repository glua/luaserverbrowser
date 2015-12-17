lsb.ui = {}

--interacting with lua
local functions = {
	getServerInfo = function(ip, port, index)
		lsb.util.fetchServerInfo({[string.format('%s:%s', ip, port)] = false}, function(ip, data)
			--data.ip = ip
			
			lsb.ui.call(string.format(
				"$scope.serverResults[%s].info = %s;",
				index,
				util.TableToJSON(data)
			))
		end)
	end,

	getServerRules = function(ip, port, index)
		lsb.util.fetchServerRules(ip, port, function(rules)
			lsb.ui.call(string.format(
				"$scope.addRules(%s, %s);",
				index,
				util.TableToJSON(rules)
			))
		end)
	end,

	getServerPlayers = function(ip, port, index)
		lsb.util.fetchServerPlayers(ip, port, function(players)
			lsb.ui.call(string.format(
				"$scope.addPlayers(%s, %s);",
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
	end,

	favoriteServer = function(fullip, fave)
		lsb.data.favorites[fullip] = fave or nil

		local str = ""
		local tab = "{"

		for k, v in pairs(lsb.data.favorites) do
			str = string.format("%s%s\n", str, k)
			tab = string.format("%s'%s':true,", tab, k)
		end

		file.Write("lsb/favorites.dat", str:sub(1, -2))

		lsb.ui.call(string.format([[
				var faves = %s;

				for(var i = 0; i < $scope.serverResults.length; i++) {
					var server = $scope.serverResults[i];

					server.favorite = faves[server.info.ip + ':' + server.info.port];

					//console.log(server.info.ip + ':' + server.info.port + ' ' + server.favorite);

					//if(server.favorite)
					//	console.log(JSON.stringify(server));
				}
			]],
			string.format("%s}", tab:sub(1, -2))
		))
	end

}

--make our replacement menu
lsb.ui.init = function()
	if(lsb.ui.vgui) then return end

	lsb.ui.vgui = vgui.Create("DHTML")
	lsb.ui.vgui:Dock(FILL)
	lsb.ui.vgui:DockMargin(0, 0, 0, 50)

	lsb.ui.vgui:OpenURL("asset://garrysmod/lua/menu/lsb/html/min.html")
	lsb.ui.vgui:SetKeyboardInputEnabled(true)
	lsb.ui.vgui:SetMouseInputEnabled(true)
	lsb.ui.vgui:SetAllowLua(true)
	lsb.ui.vgui:RequestFocus()

	lsb.ui.vgui:MakePopup()
	lsb.ui.vgui:SetVisible(false)

	--let the browser know our version
	lsb.ui.call(string.format("$scope.serverFilter.version = '%s';", lsb.util.getVersion()))

	for k, v in pairs(functions) do
		lsb.ui.vgui:AddFunction("lsb", k, v)
	end
end

lsb.ui.call = function(str)
	if(lsb.data.config.debugLevel:GetInt() >= 2) then
		lsb.util.print(string.format("running js '%s'", str))
	end

	return lsb.ui.vgui:Call(string.format([[
			var $scope = angular.element(document.getElementsByTagName('body')[0]).scope();

			$scope.$apply(function() {
				%s
			});
		]],
		str
	))
end