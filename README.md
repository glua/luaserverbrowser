# luaserverbrowser
### updated legacy server browser 

To install, just put the `lua` folder into your `common/garrysmod/garrysmod` folder.

note: this automatically overwrites your `lua/menu/menu.lua` file to include LSB. this may cause problems with any other menustate addons!
also, this project includes glsock2 for windows by default, if you use a different OS, gl! (I don't have a clue how to compile, and I haven't added support for serverlist yet :()

commands:
* `lsb_auto_fetch 0/1` - whether or not to start getting servers as soon as the game opens
* `lsb_debug_level 0/1/2` - how much debug info to print
* `lsb_filter_mode 0/1` - whether or not to use lua patterns for filters (advanced)
* `lsb_time_limit #` - how long before we assume a server connection timed out
* `lsb_server_count #` - how many ips to get from the master server
* `lsb_max_connections #` - how many active sockets to use at a time
* `lsb_batch_size #` - how many servers to add to the browser at a time


