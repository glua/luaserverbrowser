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
	
	$scope.fetchServers = function() {
		
	}
});