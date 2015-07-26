lsb.cv = {
	autoFetch = CreateConVar("lsb_auto_fetch", 		1, 	FCVAR_ARCHIVE, 	[[bool, automatically fetch a basic list of servers when starting up]]),
	debugLevel = CreateConVar("lsb_debug_level", 	0, 	FCVAR_ARCHIVE, 	[[]]),
	filterMode = CreateConVar("lsb_filter_mode", 	0,	FCVAR_ARCHIVE, 	[[0/1 to use patterns for filters]])
}