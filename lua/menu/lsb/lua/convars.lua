lsb.cv = {
	autoFetch 		= CreateConVar("lsb_auto_fetch", 		1, 		FCVAR_ARCHIVE, 	"bool, automatically fetch a basic list of servers when starting up"),
	debugLevel 		= CreateConVar("lsb_debug_level", 		0, 		FCVAR_ARCHIVE, 	"int, how much to print to console\n\t0: none\n\t1: basic debug info\n\t2: advanced debug info"),
	filterMode 		= CreateConVar("lsb_filter_mode", 		0, 		FCVAR_ARCHIVE, 	"bool, use lua patterns for filters (advanced)"), --todo 0: master 1: server 2: regex
	timeLimit 		= CreateConVar("lsb_time_limit", 		3, 		FCVAR_ARCHIVE, 	"int, how long before we cancel any connections (min 1s)"),
	serverCount 	= CreateConVar("lsb_server_count", 		1000, 	FCVAR_ARCHIVE, 	"int, how many servers to fetch from the master server\n\tnote: servers are retrieved in batches of 231, so e.g. 924 and 1155 will have the same effect"),
	maxConnections 	= CreateConVar("lsb_max_connections", 	20, 	FCVAR_ARCHIVE, 	"int, how many active sockets to use at a time (min 1, max 100)"),
	batchSize 		= CreateConVar("lsb_batch_size", 		50, 	FCVAR_ARCHIVE, 	"int, how many servers to add to the browser at a time (min 1)"),
}