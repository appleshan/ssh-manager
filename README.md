# SSH Manager


A simple script to manage ssh connections on *inx ( Such as UNIX, Linux, Mac OS, etc)

![screenshot](https://github.com/robinparisi/ssh-manager/raw/master/screenshot.png)

## Basic introduction

    This shell script maintains a file database named " servers " which located in "$HOME/.ssh-manager/servers".
    With this sh, you can use its list to help you remember which hosts you can connect to and what username 
    and ip and port are them.

    You can customize it with more powerfull functions to easy and widly use.

    You may want to use the ` idn2 ` package if you use non ASCII domain.

    Thanks!

    # ./ssh-manager.sh add local1:root:localhost:22
	new alias 'local:root:localhost:22' added
    # ./ssh-manager.sh add local2:root:127.0.0.1:22
	new alias 'local:root:127.0.0.1:22' added
    # ./ssh-manager.sh add local3:root:10.20.0.7:22
	new alias 'local:root:10.20.0.7:22' added
    # ./ssh-manager.sh
	--------------------------------------------------------------------------------
	List of availables servers for user root 
	--------------------------------------------------------------------------------
	[UP]   local1 ==> root@localhost -> 22
	[UP]   local2 ==> root@127.0.0.1 -> 22
	[UP]   local3 ==> root@10.20.0.7 -> 22
	--------------------------------------------------------------------------------
	Availables commands
	--------------------------------------------------------------------------------
	co  <alias> [username]                           connect to server
	add <alias>:<user>:<host>:[port]                 add new server
	del <alias>                                      delete server
	export                                           export config
    # cat .ssh_servers 
	local:root:localhost:22:
	local:root:127.0.0.1:22:
	local:root:10.20.0.7:22:
    #

## Installation

    $ cd ~
    $ wget --no-check-certificate https://raw.github.com/robinparisi/ssh-manager/master/ssh-manager.sh
    $ chmod +x ssh-manager.sh
    $ ./ssh-manager.sh
    
For more convenience, you can create an alias into your .bashrc, .zshrc, etc...

For example :

    alias sshs="/Users/robin/ssh-manager.sh"

## Use

    co  <alias> [username]
    add <alias>:<user>:<host>:[port]                 
    del <alias>                                      
    export                                           

### Authors and Contributors

Original script by Errol Byrd
Copyright (c) 2010, Errol Byrd 

Modified by Robin Parisi (@robinparisi)
