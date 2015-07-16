var app = angular.module('lsbApp', []);

app.controller('serverBrowser', function($scope) {
	$scope.loading = false;
	$scope.serverResults = [];
	$scope.prettyResults = [];
	$scope.resultsLength = 0;
	
	$scope.loadingBarStyle = function() {
		var frac = ($scope.serverResults.length || 0) / ($scope.resultsLength || 0);
		
		return {
			'width': (frac * 100) + '%',
			'background': 'hsla(' + Math.ceil(frac * 360) + ', 80%, 60%, 1)'
		}
	}
	
	$scope.viewServer = function($index) {
		$scope.curServer = $scope.serverResults[$index];
		
		lsb.getServerRules($scope.curServer.info.ip, $scope.curServer.info.port, $index);
	}
	
	$scope.addResult = function(result) {
		$scope.serverResults.push(result);
		
		$scope.prettyResults.push({
			pass: 		result.info.pass,
			VAC: 		result.info.VAC,
			name: 		result.info.name,
			gamemode: 	result.info.gamemode,
			players: 	result.info.numPlayers + '/' + result.info.maxPlayers,
			map: 		result.info.map,
			ping: 		result.info.ping
		});
	}
	
	//settings
	
	$scope.settings = {
		region: {},
		query: [
			['Generic stuff', [
				['Dedicated', 			'checkbox', 'master', 	'type'],
				['VAC', 				'checkbox', 'master', 	'secure'],
				['Server empty', 		'checkbox', 'master', 	'noplayers'],
				['Server has players', 	'checkbox', 'master', 	'empty'],
				['Server not full', 	'checkbox', 'master', 	'full'],
				['Whitelisted', 		'checkbox', 'master', 	'white'],
			]],
			['Specific stuff', [
				['Map', 				'text', 	'master', 	'map'],
				['Hostname', 			'text', 	'master',	'name_match'],
				['IP Address', 			'text', 	'master',	'gameaddr']
			]],
			['Probably useless', [
				['Game directory', 		'text', 	'master', 	'gamedir'],
				['Linux', 				'checkbox', 'master', 	'linux'],
				['Spectator server', 	'checkbox', 'master', 	'proxy'],
				['App ID', 				'text', 	'master', 	'appid',		 		true],
				['Version', 			'text', 	'master', 	'version_match', 		true],
				['Collapse multiples', 	'checkbox', 'master', 	'collapse_addr_hash']
			]]
		]
	};
	
	var c = String.fromCharCode;
	
	//sure would have liked to do this inline
	
	$scope.settings.region[c(0x00)] = 'U.S. East coast';
	$scope.settings.region[c(0x01)] = 'U.S. West coast';
	$scope.settings.region[c(0x02)] = 'South America';
	$scope.settings.region[c(0x03)] = 'Europe';
	$scope.settings.region[c(0x04)] = 'Asia';
	$scope.settings.region[c(0x05)] = 'Australia';
	$scope.settings.region[c(0x06)] = 'Middle East';
	$scope.settings.region[c(0x07)] = 'Africa';
	$scope.settings.region[c(0xFF)] = 'Rest of the world';
	
	$scope.setRegion = function(v) {
		$scope.query.master.region = v;
		$scope.regionSelect = false;
	}
	
	//the stuff we send to lua 
	
	$scope.query = {
		master: {
			region: c(0x00),
			gamedir: 'garrysmod',
			appid: 4000
		},
		server: {
			
		}
	};
	
	$scope.fetchServers = function() {
		
	}
});

app.directive('sortable', function($rootScope) {
	return {
		restrict: 'E',
		templateUrl: 'sortable-template.html',
		scope: {
			object: '=',
			ngShow: '='
		},
		link: function(scope, elem, attr) {
			scope.data = [];
			scope.keys = [];
			
			//????			
			scope.$watch('object', function(data) {
				scope.data = data;
				
				if(data.length) {
					scope.keys = Object.keys(data[0]);
					
					//angular $$hashkey
					scope.keys.pop();
				}
			}, true);
			
			//isolated scope breaks ng-show pre 1.3
			scope.$watch('ngShow', function(val) {
				if(val)
					elem[0].style.display = '';
				else 
					elem[0].style.display = 'none';
			});
			
			//now for the fun stuff
			
			scope.reverse = false;
			scope.key = '';
			
			scope.sortBy = function(key) {
				if(scope.key === key)
					scope.reverse = !scope.reverse;
				else {
					scope.key = key;
					scope.reverse = false;
				}

				scope.data.sort(function(a, b) {
					var comp = 0;

					if(a[key] > b[key])
						comp = 1;
					else if(a[key] < b[key])
						comp = -1;

					return comp * (scope.reverse ? -1 : 1);
				});
			}
		}
	}
});