var app = angular.module('lsbApp', []);

app.controller('serverBrowser', function($scope) {
	$scope.tabs = ['Internet', 'Favorites']; //, 'Local'];
	$scope.curTab = 0;
	
	$scope.serverResults = [];
	$scope.prettyResults = [];
	
	var serverTypes = {'100': 'Dedicated', '108': 'Listen', '112': 'SourceTV'}
	var serverEnvs = {'108': 'Linux', '119': 'Windows', '109': 'OSX', '111': 'OSX'}
	
	$scope.viewServer = function($index) {
		var curServer = $scope.curServer = $scope.serverResults[$index];
		
		if(!curServer.rules) 
			lsb.getServerRules(curServer.info.ip, curServer.info.port, $index);
		
		if(!curServer.players)
			lsb.getServerPlayers(curServer.info.ip, curServer.info.port, $index);
		
		
		if(!curServer.prettyInfo) {
			var info = curServer.info;
			
			curServer.prettyInfo = [
				{key: 'VAC enabled', 		value: info.VAC ? "Yes" : "No"},
				{key: 'Password protected', value: info.pass ? "Yes" : "No"},
				{key: 'Players', 			value: info.numPlayers},
				{key: 'Bots', 				value: info.numBots},
				{key: 'Max players', 		value: info.maxPlayers},
				{key: 'Map', 				value: info.map},
				{key: 'Ping', 				value: info.ping},
				{key: 'Folder', 			value: info.folder},
				{key: 'Version', 			value: info.version},
				{key: 'App ID', 			value: info.appid},
				{key: 'Server type', 		value: serverTypes[info.type]},
				{key: 'Server environment', value: serverEnvs[info.env]}
			];
		}
	}
	
	$scope.favoriteServer = function(fave) {
		lsb.favoriteServer($scope.curServer.info.ip + ':' + $scope.curServer.info.port, fave);
	}
	
	$scope.refreshServer = function() {
		var index = $scope.curServer.index;
		
		$scope.serverResults[index].rules = undefined;
		$scope.serverResults[index].players = undefined;
		
		lsb.getServerInfo($scope.curServer.info.ip, $scope.curServer.info.port, index);
		
		$scope.viewServer(index);
	}
	
	$scope.joinServer = function($index) {
		var server = $scope.serverResults[$index];
		
		lsb.joinServer(server.info.ip, server.info.port);
	}
	
	$scope.addResults = function(results) {
		for(var i = 0; i < results.length; i++) {
			var result = results[i];
			
			//weird, but it works
			result.index = $scope.serverResults.push(result) - 1;

			$scope.prettyResults[result.index] = {
				pass: 		result.info.pass,
				VAC: 		result.info.VAC,
				name: 		result.info.name,
				gamemode: 	result.info.gamemode,
				players: 	result.info.numPlayers + '/' + result.info.maxPlayers,
				map: 		result.info.map,
				ping: 		result.info.ping
			};
		}
	}
	
	$scope.addRules = function(index, rules) {
		var ret = [];
		
		for(var key in rules) {
			if(rules.hasOwnProperty(key)) {
				ret.push({
					key: key,
					value: rules[key]
				});
			}
		}
		
		$scope.serverResults[index].rules = ret;
	}
	
	$scope.addPlayers = function(index, players) {
		var ret = [];
		
		if(players['1']) {
			for(var id in players) {
				if(players.hasOwnProperty(id)) {
					var ply = players[id];

					var info = {
						name: 	(ply.name.length > 0 ? ply.name : '<Connecting>'),
						score: 	ply.score
					}

					var sec = parseFloat(ply.time);
					var min = sec / 60;
					var hour = min / 60;

					info.time = 
						(hour >= 1 ? Math.floor(hour) + 'h ' : '') +
						(min >= 1 ? (Math.floor(min) % 60) + 'm ' : '') +
						(Math.floor(sec) % 60) + 's';

					ret.push(info);
				}
			}
		} else {
			ret = [{
				name: '',
				score: '',
				time: ''
			}];
		}
		
		$scope.serverResults[index].players = ret;
	}
	
	//settings
	
	$scope.settings = {
		region: {
			0x00: 'U.S. East coast',
			0x01: 'U.S. West coast',
			0x02: 'South America',
			0x03: 'Europe',
			0x04: 'Asia',
			0x05: 'Australia',
			0x06: 'Middle East',
			0x07: 'Africa',
			0xFF: 'Rest of the world'
		},
		query: [
			{l: 'Generic stuff', d: [
				{l: 'Dedicated', 			t: 'tristate', 	k: 'type', 					tv: '100'},
				{l: 'Private', 				t: 'checkbox', 	k: 'pass'},
				{l: 'VAC', 					t: 'checkbox', 	k: 'VAC'},
				{l: 'Server empty', 		t: 'checkbox', 	k: 'noplayers'},
				{l: 'Server has players', 	t: 'checkbox', 	k: 'empty'},
				{l: 'Server not full', 		t: 'checkbox', 	k: 'full'}
				//{l: 'Tags', 				t: 'text', 		k: 'tags'}
				//{l: 'Whitelisted', 			t: 'checkbox', 	k: 'white'}
			]},
			{l: 'Specific stuff', d: [
				{l: 'Map', 					t: 'text', 		k: 'map'},
				{l: 'Name', 				t: 'text', 		k: 'name'},
				//{l: 'Hostname', 			t: 'text', 		k: 'name_match'},
				{l: 'IP Address', 			t: 'text', 		k: 'fullip'},
				{l: 'Gamemode', 			t: 'text', 		k: 'gamemode'}
			]},
			{l: 'Probably useless', d: [
				{l: 'Game directory', 		t: 'text', 		k: 'folder'},
				{l: 'Linux', 				t: 'checkbox', 	k: 'env',					tv: '108'},
				//{l: 'Spectator server', 	t: 'checkbox', 	k: 'proxy'},
				{l: 'App ID', 				t: 'text', 		k: 'appid', 				n: true},
				{l: 'Steam ID', 			t: 'text', 		k: 'steamID', 				n: true},
				{l: 'Version', 				t: 'text', 		k: 'version', 				n: true}
				//{l: 'Collapse multiples', 	t: 'checkbox', 	k: 'collapse_addr_hash'}
			]}
		]
	};
	
	$scope.region = 0xFF;
	
	$scope.setRegion = function(v) {
		$scope.region = v;
		$scope.regionSelect = false;
	}
	
	$scope.serverFilter = {
		folder: 'garrysmod',
		appid: '4000'
	}
	
	//filtering
	$scope.filterServers = function($index) {
		//gotta love how 0 == false :)
		if(typeof($index) !== 'number') return;
		
		var filter = $scope.serverFilter;
		var server = $scope.serverResults[$index];
		
		if(!server) return true;
		
		var shouldShow = true;

		for(var key in filter) {
			if(filter.hasOwnProperty(key)) {
				var filterVal = filter[key];
				var serverVal = server.info[key];
				
				var passed = true;

				if(typeof(filterVal) == 'string')
					passed = serverVal.toString().toLowerCase().indexOf(filterVal.toLowerCase()) > -1;
				else
					passed = serverVal == filterVal;

				if(!passed) {
					shouldShow = false;
					break
				}
			}
		}
		
		if(shouldShow && $scope.curTab == 1)
			shouldShow = server.favorite;

		return !shouldShow;
	}
	
	$scope.fetchServers = function(full) {
		lsb.getServers(full, $scope.region);
	}
});

app.directive('tristate', function($parse) {
	return {
		restrict: 'E',
		template: '<label ng-class="{t:val()===true,f:val()===false}"><input type="checkbox" ng-click="click(this)"></label>',
		require: '^ngModel',
		link: function(scope, elem, attr, ctrl) {
			var get = $parse(attr.ngModel);
			var set = get.assign;
			
			scope.val = function() {
				return get(scope);
			}
			
			scope.click = function() {
				set(scope, click(elem[0].children[0].children[0]));
			}
		}
	}
});

var click = function(cb) {
	if(cb.readOnly)
		cb.checked = cb.readOnly = false;
	else if(!cb.checked)
		cb.readOnly = cb.indeterminate = true;

	return cb.indeterminate ? undefined : cb.checked;
}