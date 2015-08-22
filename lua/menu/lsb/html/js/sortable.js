angular.module('lsbApp')
.directive('sortable', function($rootScope) {
	return {
		restrict: 'E',
		templateUrl: 'sortable-template.html',
		scope: {
			object: '=',
			show: '=',
			click: '&',
			dblClick: '&',
			filter: '&'
		},
		link: function(scope, elem, attr) {
			scope.data = [];
			scope.keys = [];
			
			var badKeys = {'$$hashKey': true, '_index': true}
			
			//????			
			scope.$watch('object', function(data) {
				if(!data) return;
				
				scope.data = data;
				
				if(data.length) {
					scope.keys = Object.keys(data[0]);
				
					//add indices
					if(!data[0]._index) {
						for(var i = 0; i < data.length; i++) {
							scope.data[i]._index = i;
						}
					}
					
					//get rid of our _index and angular's $$hashkey
					for(var i = scope.keys.length - 1; i > -1; i--) {
						if(badKeys[scope.keys[i]])
							scope.keys.splice(i, 1);
					}
				}
			}, true);
			
			//isolated scope breaks ng-show pre 1.3
			if(attr.show) {
				scope.$watch('show', function(val) {
					if(val)
						elem[0].style.display = '';
					else 
						elem[0].style.display = 'none';
				});
			}
			
			//now for the fun stuff
			
			scope.reverse = false;
			scope.key = '';
			
			//http://web.archive.org/web/20130826203933/http://my.opera.com/GreyWyvern/blog/show.dml/1671288
			var chunkify = function(t) {
				var tz = [], x = 0, y = -1, n = 0, i, j;

				while (i = (j = t.charAt(x++)).charCodeAt(0)) {
					var m = (i == 46 || (i >=48 && i <= 57));
					if (m !== n) {
						tz[++y] = "";
						n = m;
					}
					tz[y] += j;
				}
				return tz;
			}
			
			var alphanum = function(a, b) {
				var aa = chunkify(a.toLowerCase());
				var bb = chunkify(b.toLowerCase());

				for (x = 0; aa[x] && bb[x]; x++) {
					if (aa[x] !== bb[x]) {
						var c = Number(aa[x]), d = Number(bb[x]);
						if (c == aa[x] && d == bb[x]) {
							return c - d;
						} else return (aa[x] > bb[x]) ? 1 : -1;
					}
				}
				return aa.length - bb.length;
			}
			
			scope.sortBy = function(key) {
				if(scope.key === key)
					scope.reverse = !scope.reverse;
				else {
					scope.key = key;
					scope.reverse = false;
				}

				scope.data.sort(function(a, b) {
					var foo = a[key];
					var bar = b[key];
					
					//this is so hacky
					if(key == 'time') {
						var t = {h: 3600, m: 60, s: 1}
						
						foo = 0; a[key].replace(/(\d*)([hms])/gi, function(a, b, c) { foo += parseInt(b) * t[c] });
						bar = 0; b[key].replace(/(\d*)([hms])/gi, function(a, b, c) { bar += parseInt(b) * t[c] });
					}
					
					return alphanum(
						foo.toString().toLowerCase(), 
						bar.toString().toLowerCase()
					) * (scope.reverse ? -1 : 1);
				});
			}
		}
	}
});