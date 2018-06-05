#!/bin/bash
#########################################
# Original script by Errol Byrd
# Copyright (c) 2010, Errol Byrd <errolbyrd@gmail.com>
#########################################
# Modified by Robin Parisi
# Contact at parisi.robin@gmail.com
# Github https://github.com/robinparisi/ssh-manager
# github.io Page https://robinparisi.github.io/ssh-manager/
# Contributors https://github.com/robinparisi/ssh-manager/graphs/contributors

#================== Globals ==================================================

# Version
VERSION="0.7-dev"

# Default Configuration
CONF_DIR="$HOME/.ssh-manager"
HOST_FILE="$CONF_DIR/servers"
CONF_FILE="$CONF_DIR/config"
# default structur is $DATA_ALIAS$DATA_DELIM$DATA_HUSER$DATA_DELIM$DATA_HADDR$DATA_DELIM$DATA_HPORT
# or, more human friendly alias:user:host:port
DATA_DELIM=":"
DATA_ALIAS=1
DATA_HUSER=2
DATA_HADDR=3
DATA_HPORT=4
PING_DEFAULT_TTL=20
SSH_DEFAULT_PORT=22
ENABLE_CECHO=true
USE_IDN2=false

#================== Functions ================================================

function cecho() {
	one_line=false
	while [ "${1}" ]; do
		case "${1}" in
			-normal)        color="\033[00m" ;;
			-black)         color="\033[30;01m" ;;
			-red)           color="\033[31;01m" ;;
			-green)         color="\033[32;01m" ;;
			-yellow)        color="\033[33;01m" ;;
			-blue)          color="\033[34;01m" ;;
			-magenta)       color="\033[35;01m" ;;
			-cyan)          color="\033[36;01m" ;;
			-white)         color="\033[37;01m" ;;
			-n)             one_line=true;  shift ; continue ;;
			*)              echo -n "${1}"; shift ; continue ;;
		esac
		shift
		if ${ENABLE_CECHO}; then
			echo -en "${color}"
		fi
		echo -en "${1}"
		if ${ENABLE_CECHO}; then
			echo -en "\033[00m"
		fi
		shift
	done
	if ! ${one_line}; then
		echo
	fi
}

function probe ()
{
	als=$1
	awk=$(awk -F "$DATA_DELIM" -v als="$als" '$1 == als { print $0 }' $HOST_FILE 2> /dev/null)
	if [[ -z "$awk" ]]; then
		return 1;
	fi
}

function get_raw ()
{
	als=$1
	awk -F "$DATA_DELIM" -v als="$als" '$1 == als { print $0 }' $HOST_FILE 2> /dev/null
}

function get_addr ()
{
	als=$1
	get_raw "$als" | awk -F "$DATA_DELIM" '{ print $'$DATA_HADDR' }'
}

function get_port ()
{
	als=$1
	get_raw "$als" | awk -F "$DATA_DELIM" '{ print $'$DATA_HPORT'}'
}

function get_user ()
{
	als=$1
	get_raw "$als" | awk -F "$DATA_DELIM" '{ print $'$DATA_HUSER' }'
}

function exec_ping() {
	_addr=$@
	if ${USE_IDN2}; then
		_addr=$(idn2 $_addr)
	fi
	case $(uname) in
		MINGW*)
			ping -n 1 -i $PING_DEFAULT_TTL $_addr
			;;
		*)
			ping -c1 -t$PING_DEFAULT_TTL $_addr
			;;
	esac
}

function test_host() {
	exec_ping $* > /dev/null
	if [ $? != 0 ] ; then
		echo -n "["
		cecho -n -red "KO"
		echo -n "]"
	else
		echo -n "["
		cecho -n -green "UP"
		echo -n "]"
	fi
}

function show_server() {
	while IFS="$DATA_DELIM" read alias user password addr port
	do
		test_host $addr
		echo -ne '|'
		cecho -n -blue $alias
		echo -ne '|'
		cecho -n -red $user
		echo -n "@"
		cecho -n -white $addr
		echo -n ':'
		if [ "$port" == "" ]; then
			port=$SSH_DEFAULT_PORT
		fi
		cecho -yellow $port
	done < $HOST_FILE
}

function server_show() {
	echo -n "List of availables servers for user "; cecho -blue "$(whoami):"
	_check=$(show_server)
	echo -e "$_check"| column -t -s '|'
}

function list_commands() {
	echo -ne "List of availables commands:\n"
	echo -ne "$0 "; cecho -n -yellow "co"; echo -ne "\t<alias> [username]\t\t"; cecho -white "connect to server"
	echo -ne "$0 "; cecho -n -yellow "add"; echo -ne "\t<alias>:<user>:<host>:[port]\t"; cecho -white "add new server"
	echo -ne "$0 "; cecho -n -yellow "add"; echo -ne "\t<user>@<host>\t\t\t"; cecho -white "add new server"
	echo -ne "$0 "; cecho -n -yellow "del"; echo -ne "\t<alias>\t\t\t\t"; cecho -white "delete server"
	echo -ne "$0 "; cecho -n -yellow "export"; echo -ne "\t\t\t\t\t"; cecho -white "export config"
}

function server_add() {
	# if user@host
	# This grep syntaxt SHOULD be POSIX BRE compliant
	if echo ${1} | grep -xq "^[[:alnum:].-]\{1,\}@[[:alnum:].-]\{1,\}$"
		then
		_user=`echo ${1} | cut -d @ -f 1`
		_host=`echo ${1} | cut -d @ -f 2`
		_alias=$_host
		_port=$SSH_DEFAULT_PORT
		_full="$_alias$DATA_DELIM$_user$DATA_DELIM$_host$DATA_DELIM$_port"
	# elif alias:user:host(:port)?
	elif echo ${1} | grep -xq "^[[:alnum:].-]\{1,\}\($DATA_DELIM[[:alnum:].-]\{1,\}\)\($DATA_DELIM[[:alnum:].-]\{1,\}\)\{2\}\($DATA_DELIM[[:digit:].-]\{1,\}\)\{0,1\}$"
		then
		_alias=`echo ${1} | cut -d $DATA_DELIM -f 1`
		_user=`echo ${1} | cut -d $DATA_DELIM -f 2`
		_password=`echo ${1} | cut -d $DATA_DELIM -f 3`
		_host=`echo ${1} | cut -d $DATA_DELIM -f 4`
		_port=`echo ${1} | cut -d $DATA_DELIM -f 5`; if [ -z "$_port" ]; then _port=$SSH_DEFAULT_PORT; fi
		_full="$_alias$DATA_DELIM$_user$DATA_DELIM$_password$DATA_DELIM$_host$DATA_DELIM$_port"
	else
		echo "${1}: is not a valid input."
		exit 1;
	fi
	probe "$_alias"
	if [ $? -eq 0 ]; then
		echo "$0: alias '${1}' already exist"
	else
		echo "$_full" >> $HOST_FILE
		echo "new alias '$_full' added"
	fi
}

function server_delete() {
	alias=${1}
	probe "$alias"
	if [ $? -eq 0 ]; then
		cat $HOST_FILE | sed '/^'$alias$DATA_DELIM'/d' > /tmp/.tmp.$$
		mv /tmp/.tmp.$$ $HOST_FILE
		echo "alias '$alias' removed"
	else
		echo "$0: unknown alias '$alias'"
	fi
}

function server_connect() {
	alias=${1}
	probe "$alias"
	if [ $? -eq 0 ]; then
		if [ "${2}" == ""  ]; then
			user=$(get_user "$alias")
		fi
		addr=$(get_addr "$alias")
		if ${USE_IDN2}; then
			addr=$(idn2 $addr)
		fi
		port=$(get_port "$alias")
		# Use default port when parameter is missing
		if [ "$port" == "" ]; then
			port=$SSH_DEFAULT_PORT
		fi
		echo "connecting to '$alias' ($addr:$port)"
		ssh $user@$addr -p $port
	else
		echo "$0: unknown alias '$alias'"
		exit 1
	fi
}

#=============================================================================

# if config directory doesn't exist
if [ ! -d $CONF_DIR ]; then mkdir "$CONF_DIR"; fi
# if host file doesn't exist
if [ ! -f $HOST_FILE ]; then
	# if the old config file is found
	if [ -f "$HOME/.ssh_servers" ]; then
		mv "$HOME/.ssh_servers" $HOST_FILE
	else
		touch "$HOST_FILE"
	fi
fi
# if config file doesn't exist
if [ ! -f $CONF_FILE ]; then
	touch "$CONF_FILE"
	else
		source "$CONF_FILE"
fi
# if idn2 is not present but configured
if (${USE_IDN2} && ! [ -x "$(command -v idn2)" ]); then
	echo "$0: command idn2 not found, but USE_IDN2 set to true in configuration. (Edit $CONF_FILE to solve this issue.)"
	exit 1
fi

# without args
if [ $# -eq 0 ]; then
	server_show
	echo
	list_commands
	exit 0
fi

while [[ $# -gt 0 ]]; do
key="${1}"
case "$key" in
	cc|co|connect )
		server_connect ${2} ${3}
		exit 0
		;;
	add )
		server_add ${2}
		exit 0
		;;
	export )
		cat $HOST_FILE
		exit 0
		;;
	del|delete )
		server_delete ${2}
		exit 0
		;;
	show|list )
		server_show
		exit 0
		;;
	-h|--help|help )
		list_commands
		exit 0
		;;
	* )
		echo "$0: unrecognised command '$key'"
		exit 1
		;;
esac
done