var app = angular.module('lsbApp', []);

app.controller('serverBrowser', function($scope) {
	$scope.loading = false;
	$scope.serverResults = [];
	$scope.resultsLength = 0;
	
	$scope.loadingBarStyle = function() {
		var frac = $scope.serverResults.length / ($scope.resultsLength || 0);
		
		return {
			'width': (frac * 100) + '%',
			'background': 'hsla(' + Math.ceil(frac * 360) + ', 80%, 60%, 1)'
		}
	}
	
	$scope.viewServer = function($index) {
		$scope.curServer = $scope.serverResults[$index];
		
		lsb.getServerRules($scope.curServer.info.ip, $scope.curServer.info.port, $index);
	}
	
	//settings
	
	$scope.settings = {}
	
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

app.directive('sortable', function() {
	return {
		restrict: 'E',
		templateUrl: 'sortable-template.html',
		scope: {
			data: '='
		},
		link: function(scope, elem, attr) {
			scope.keys = {};
			
			for(var i = 0; i < scope.data.length; i++)
				for(var col in scope.data[i])
					if(row.hasOwnProperty(col))
						if(!scope.keys[col])
							scope.keys[col] = true;
		}
});