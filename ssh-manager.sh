#!/bin/bash
#########################################
# Original script by Errol Byrd
# Copyright (c) 2010, Errol Byrd <errolbyrd@gmail.com>
#########################################
# Modified by Robin Parisi
# Contact at parisi.robin@gmail.com
# Github https://github.com/robinparisi/ssh-manager
# github.io Page https://robinparisi.github.io/ssh-manager/

#================== Globals ==================================================

# Version
VERSION="0.7-dev"

# Configuration
HOST_FILE="$HOME/.ssh_servers"
# default structur is $DATA_ALIAS$DATA_DELIM$DATA_HUSER$DATA_DELIM$DATA_HADDR$DATA_DELIM$DATA_HPORT
# or, more human friendly alias:user:host:port
DATA_DELIM=":"
DATA_ALIAS=1
DATA_HUSER=2
DATA_HADDR=3
DATA_HPORT=4
PING_DEFAULT_TTL=20
SSH_DEFAULT_PORT=22

#================== Functions ================================================

function exec_ping() {
	case $(uname) in 
		MINGW*)
			ping -n 1 -i $PING_DEFAULT_TTL $@
			;;
		*)
			ping -c1 -t$PING_DEFAULT_TTL $@
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

function separator() {
	echo -e "----\t----\t----\t----\t----\t----\t----\t----"
}

function list_commands() {
	separator
	echo -e "Availables commands"
	separator
	echo -e "$0 cc\t<alias> [username]\t\tconnect to server"
	echo -e "$0 add\t<alias>:<user>:<host>:[port]\tadd new server"
	echo -e "$0 del\t<alias>\t\t\t\tdelete server"
	echo -e "$0 export\t\t\t\t\texport config"
}

function probe ()
{
	als=$1
	grep -w -e $als $HOST_FILE > /dev/null
	return $?
}

function get_raw ()
{
	als=$1
	grep -w -e $als $HOST_FILE 2> /dev/null
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
	elif echo ${1} | grep -xq "^[[:alnum:].-]\{1,\}\($DATA_DELIM[[:alnum:].-]\{1,\}\)\{2\}\($DATA_DELIM[[:digit:].-]\{1,\}\)\{0,1\}$"
		then
		_alias=`echo ${1} | cut -d $DATA_DELIM -f 1`
		_user=`echo ${1} | cut -d $DATA_DELIM -f 2`
		_host=`echo ${1} | cut -d $DATA_DELIM -f 3`
		_port=`echo ${1} | cut -d $DATA_DELIM -f 4`; if [ -z "$_port"]; then _port=$SSH_DEFAULT_PORT; fi
		_full="$_alias$DATA_DELIM$_user$DATA_DELIM$_host$DATA_DELIM$_port"
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

function cecho() {
	while [ "$1" ]; do
		case "$1" in 
			-normal)        color="\033[00m" ;;
			-black)         color="\033[30;01m" ;;
			-red)           color="\033[31;01m" ;;
			-green)         color="\033[32;01m" ;;
			-yellow)        color="\033[33;01m" ;;
			-blue)          color="\033[34;01m" ;;
			-magenta)       color="\033[35;01m" ;;
			-cyan)          color="\033[36;01m" ;;
			-white)         color="\033[37;01m" ;;
			-n)             one_line=1;   shift ; continue ;;
			*)              echo -n "$1"; shift ; continue ;;
		esac
	shift
	echo -en "$color"
	echo -en "$1"
	echo -en "\033[00m"
	shift
done
if [ ! $one_line ]; then
	echo
fi
}

#=============================================================================

cmd=$1
alias=$2
user=$3

# if config file doesn't exist
if [ ! -f $HOST_FILE ]; then touch "$HOST_FILE"; fi

# without args
if [ $# -eq 0 ]; then
	separator 
	echo "List of availables servers for user $(whoami) "
	separator
	while IFS=: read label user ip port         
	do    
	test_host $ip
	echo -ne "\t"
	cecho -n -blue $label
	echo -ne ' ==> '
	cecho -n -red $user 
	cecho -n -yellow "@"
	cecho -n -white $ip
	echo -ne ' -> '
	if [ "$port" == "" ]; then
		port=$SSH_DEFAULT_PORT
	fi
	cecho -yellow $port
	echo
done < $HOST_FILE

list_commands

exit 0
fi

case "$cmd" in
	# Connect to host
	cc )
		probe "${1}"
		if [ $? -eq 0 ]; then
			if [ "$user" == ""  ]; then
				user=$(get_user "${1}")
			fi
			addr=$(get_addr "${1}")
			port=$(get_port "${1}")
			# Use default port when parameter is missing
			if [ "$port" == "" ]; then
				port=$SSH_DEFAULT_PORT
			fi
			echo "connecting to '${1}' ($addr:$port)"
			ssh $user@$addr -p $port
		else
			echo "$0: unknown alias '${1}'"
			exit 1
		fi
		;;

	# Add new alias
	add )
		server_add ${2}
		;;
	# Export config
	export )
		echo
		cat $HOST_FILE
		;;
	# Delete ali
	del )
		probe "${1}"
		if [ $? -eq 0 ]; then
			cat $HOST_FILE | sed '/^'${1}$DATA_DELIM'/d' > /tmp/.tmp.$$
			mv /tmp/.tmp.$$ $HOST_FILE
			echo "alias '${1}' removed"
		else
			echo "$0: unknown alias '${1}'"
		fi
		;;
	* )
		echo "$0: unrecognised command '$cmd'"
		exit 1
		;;
esac