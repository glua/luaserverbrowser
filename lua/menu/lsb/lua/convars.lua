lsb.cv = {
	autoFetch = CreateConVar("lsb_auto_fetch", 		1, 	FCVAR_ARCHIVE, 	[[bool, automatically fetch a basic list of servers when starting up]]),
	debugLevel = CreateConVar("lsb_debug_level", 	0, 	FCVAR_ARCHIVE, 	[[int, how much to print to console
	0: none
	1: basic debug info
	2: advanced debug info
	]]),
	filterMode = CreateConVar("lsb_filter_mode", 	0,	FCVAR_ARCHIVE, 	[[bool, use lua patterns for filters (advanced)]])
}