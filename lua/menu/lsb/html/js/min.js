var app=angular.module("lsbApp",[]);app.controller("serverBrowser",["$scope",function(e){e.tabs=["Internet","Favorites"],e.curTab=0,e.serverResults=[],e.prettyResults=[];var r={100:"Dedicated",108:"Listen",112:"SourceTV"},t={108:"Linux",119:"Windows",109:"OSX",111:"OSX"};e.viewServer=function(n){var a=e.curServer=e.serverResults[n];if(a.rules||lsb.getServerRules(a.info.ip,a.info.port,n),a.players||lsb.getServerPlayers(a.info.ip,a.info.port,n),!a.prettyInfo){var i=a.info;a.prettyInfo=[{key:"VAC enabled",value:i.VAC?"Yes":"No"},{key:"Password protected",value:i.pass?"Yes":"No"},{key:"Players",value:i.numPlayers},{key:"Bots",value:i.numBots},{key:"Max players",value:i.maxPlayers},{key:"Map",value:i.map},{key:"Ping",value:i.ping},{key:"Folder",value:i.folder},{key:"Version",value:i.version},{key:"App ID",value:i.appid},{key:"Server type",value:r[i.type]},{key:"Server environment",value:t[i.env]}]}},e.favoriteServer=function(r){lsb.favoriteServer(e.curServer.info.ip+":"+e.curServer.info.port,r)},e.refreshServer=function(){var r=e.curServer.index;e.serverResults[r].rules=void 0,e.serverResults[r].players=void 0,lsb.getServerInfo(e.curServer.info.ip,e.curServer.info.port,r),e.viewServer(r)},e.joinServer=function(r){var t=e.serverResults[r];lsb.joinServer(t.info.ip,t.info.port)},e.addResults=function(r){for(var t=0;t<r.length;t++){var n=r[t];n.index=e.serverResults.push(n)-1,e.prettyResults[n.index]={pass:n.info.pass,VAC:n.info.VAC,name:n.info.name,gamemode:n.info.gamemode,players:n.info.numPlayers+"/"+n.info.maxPlayers,map:n.info.map,ping:n.info.ping}}},e.addRules=function(r,t){var n=[];for(var a in t)t.hasOwnProperty(a)&&n.push({key:a,value:t[a]});e.serverResults[r].rules=n},e.addPlayers=function(r,t){var n=[];if(t[1]){for(var a in t)if(t.hasOwnProperty(a)){var i=t[a],s={name:i.name.length>0?i.name:"<Connecting>",score:i.score},o=parseFloat(i.time),l=o/60,c=l/60;s.time=(c>=1?Math.floor(c)+"h ":"")+(l>=1?Math.floor(l)%60+"m ":"")+Math.floor(o)%60+"s",n.push(s)}}else n=[{name:"",score:"",time:""}];e.serverResults[r].players=n},e.settings={region:{0:"U.S. East coast",1:"U.S. West coast",2:"South America",3:"Europe",4:"Asia",5:"Australia",6:"Middle East",7:"Africa",255:"Rest of the world"},query:[{l:"Generic stuff",d:[{l:"Dedicated",t:"tristate",k:"type",tv:"100"},{l:"Private",t:"tristate",k:"pass"},{l:"VAC",t:"tristate",k:"VAC"},{l:"Server empty",t:"tristate",k:"noplayers"},{l:"Server has players",t:"tristate",k:"empty"},{l:"Server not full",t:"tristate",k:"full"}]},{l:"Specific stuff",d:[{l:"Map",t:"text",k:"map"},{l:"Name",t:"text",k:"name"},{l:"IP Address",t:"text",k:"fullip"},{l:"Gamemode",t:"text",k:"gamemode"}]},{l:"Probably useless",d:[{l:"Game directory",t:"text",k:"folder"},{l:"Linux",t:"tristate",k:"env",tv:"108"},{l:"Steam ID",t:"text",k:"steamID",n:!0},{l:"Version",t:"text",k:"version",n:!0}]}]},e.region=255,e.setRegion=function(r){e.region=r,e.regionSelect=!1},e.serverFilter={folder:"garrysmod"},e.filterServers=function(r){if("number"==typeof r){var t=e.serverFilter,n=e.serverResults[r];if(!n)return!0;var a=!0;for(var i in t)if(t.hasOwnProperty(i)){var s=t[i],o=n.info[i],l=!0;if("string"==typeof s?l=o.toString().toLowerCase().indexOf(s.toLowerCase())>-1:"undefined"!=typeof s&&(l=o==s),!l){a=!1;break}}return a&&1==e.curTab&&(a=n.favorite),!a}},e.fetchServers=function(r){lsb.getServers(r,e.region)}}]),app.directive("tristate",["$parse",function(e){return{restrict:"E",template:'<label ng-class="{t:val()===true,f:val()===false}"><input type="checkbox" ng-click="click(this)"></label>',require:"^ngModel",link:function(r,t,n){var a=e(n.ngModel),i=a.assign;r.val=function(){return a(r)},r.click=function(){i(r,click(t[0].children[0].children[0]))}}}}]);var click=function(e){return e.readOnly?e.checked=e.readOnly=!1:e.checked||(e.readOnly=e.indeterminate=!0),e.indeterminate?void 0:e.checked};app.directive("sortable",["$rootScope",function(){return{restrict:"E",template:'<table class="sortable"><thead><tr><td ng-repeat="col in keys"ng-bind="col"ng-click="sortBy(col)"ng-class="{active: (key===col), reversed: reverse}"></td></tr></thead><tbody><tr ng-repeat="row in data"ng-hide="filter({\'$index\': row._index})"ng-click="click({\'$index\': row._index})"ng-dblclick="dblClick({\'$index\': row._index})"><td ng-repeat="col in keys"ng-bind="row[col]"ng-class="{truthy: !!row[col]}"></td></tr></tbody></table>',scope:{object:"=",show:"=",click:"&",dblClick:"&",filter:"&"},link:function(e,r,t){e.data=[],e.keys=[];var n={$$hashKey:!0,_index:!0};e.$watch("object",function(r){if(r&&(e.data=r,r.length)){if(e.keys=Object.keys(r[0]),!r[0]._index)for(var t=0;t<r.length;t++)e.data[t]._index=t;for(var t=e.keys.length-1;t>-1;t--)n[e.keys[t]]&&e.keys.splice(t,1)}},!0),t.show&&e.$watch("show",function(e){r[0].style.display=e?"":"none"}),e.reverse=!1,e.key="";var a=function(e){for(var r,t,n=[],a=0,i=-1,s=0;r=(t=e.charAt(a++)).charCodeAt(0);){var o=46==r||r>=48&&57>=r;o!==s&&(n[++i]="",s=o),n[i]+=t}return n},i=function(e,r){var t=a(e.toLowerCase()),n=a(r.toLowerCase());for(x=0;t[x]&&n[x];x++)if(t[x]!==n[x]){var i=Number(t[x]),s=Number(n[x]);return i==t[x]&&s==n[x]?i-s:t[x]>n[x]?1:-1}return t.length-n.length};e.sortBy=function(r){e.key===r?e.reverse=!e.reverse:(e.key=r,e.reverse=!1),e.data.sort(function(t,n){var a=t[r],s=n[r];if("time"==r){var o={h:3600,m:60,s:1};a=0,t[r].replace(/(\d*)([hms])/gi,function(e,r,t){a+=parseInt(r)*o[t]}),s=0,n[r].replace(/(\d*)([hms])/gi,function(e,r,t){s+=parseInt(r)*o[t]})}return i(a.toString().toLowerCase(),s.toString().toLowerCase())*(e.reverse?-1:1)})}}}}]);