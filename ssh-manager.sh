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
HOST_FILE="$CONF_DIR/servers.json"
CONF_FILE="$CONF_DIR/config"
# default structur is :
# {
#     "name": "$DATA_ALIAS",
#     "host": "$DATA_HADDR",
#     "port": $DATA_HPORT,
#     "user": "$DATA_HUSER",
#     "password": "test-2017.com",
#     "connecttype": "ssh",
#     "sshtype": "pass",
#     "language": "None"
# }
DATA_DELIM=":"
DATA_ALIAS=1
DATA_HADDR=2
DATA_HPORT=3
DATA_HUSER=4
DATA_HPASS=5
DATA_HPKEY=7
PING_DEFAULT_TTL=20
SSH_DEFAULT_PORT=22
ENABLE_CECHO=true

#================== Functions ================================================

# JSON.sh:
# @see https://github.com/dominictarr/JSON.sh

[ -z "$CONNJSON" ] && _BJSON=./JSON.sh || _BJSON=$CONNJSON
if [ ! -f $HOST_FILE ]; then
    echo "not fount profile file $HOST_FILE"
    exit 0
fi

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
	awk=$(cat $CONF_DIR/servers_list | grep "$als")
	if [[ -z "$awk" ]]; then
		return 1;
	fi
}

function get_raw ()
{
	als=$1
	cat $CONF_DIR/servers_list | grep "$als" | awk '{print $2}' 2> /dev/null
}

function get_addr ()
{
	als=$1
	get_raw "$als" | awk '{print substr($1, 2, length($1)-2)}' | awk -F "," '{ print $'$DATA_HADDR' }' | awk -F ":" '{ print $2 }' | awk '{print substr($1, 2, length($1)-2)}'
}

function get_port ()
{
	als=$1
	get_raw "$als" | awk '{print substr($1, 2, length($1)-2)}' | awk -F "," '{ print $'$DATA_HPORT' }' | awk -F ":" '{ print $2 }'
}

function get_user ()
{
	als=$1
	get_raw "$als" | awk '{print substr($1, 2, length($1)-2)}' | awk -F "," '{ print $'$DATA_HUSER' }' | awk -F ":" '{ print $2 }' | awk '{print substr($1, 2, length($1)-2)}'
}

function get_pass ()
{
	als=$1
	get_raw "$als" | awk '{print substr($1, 2, length($1)-2)}' | awk -F "," '{ print $'$DATA_HPASS' }' | awk -F ":" '{ print $2 }' | awk '{print substr($1, 2, length($1)-2)}'
}

function get_pkey ()
{
	als=$1
	get_raw "$als" | awk '{print substr($1, 2, length($1)-2)}' | awk -F "," '{ print $'$DATA_HPKEY' }' | awk -F ":" '{ print $2 }' | awk '{print substr($1, 2, length($1)-2)}'
}

function exec_ping() {
	_addr=$@
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
	config=`cat $HOST_FILE | $_BJSON -n | egrep '\[[[:digit:]{1}]\]'> $CONF_DIR/servers_list`

	while IFS="	" read index json
	do
        connname=`echo $json | $_BJSON -l | grep "name" | awk '{print substr($2, 2, length($2)-2)}'`
        connhost=`echo $json | $_BJSON -l | grep "host" | awk '{print substr($2, 2, length($2)-2)}'`
        connport=`echo $json | $_BJSON -l | grep "port" | awk '{print $2}'`
        connuser=`echo $json | $_BJSON -l | grep "user" | awk '{print substr($2, 2, length($2)-2)}'`
        connpass=`echo $json | $_BJSON -l | grep "password" | awk '{print substr($2, 2, length($2)-2)}'`
        connlang=`echo $json | $_BJSON -l | grep "lang" | awk '{print substr($2, 2, length($2)-2)}'`
        conntype=`echo $json | $_BJSON -l | grep "conn" | awk '{print substr($2, 2, length($2)-2)}'`
        conntssh=`echo $json | $_BJSON -l | grep "ssht" | awk '{print substr($2, 2, length($2)-2)}'`

		test_host $connhost
		echo -ne '|'
		cecho -n -blue $connname
		echo -ne '|'
		cecho -n -red $connuser
		echo -n "@"
		cecho -n -white $connhost
		echo -n ':'
		cecho -yellow $connport
	done < $CONF_DIR/servers_list
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

function server_auto_connect() {
	alias=${1}
	probe "$alias"
	if [ $? -eq 0 ]; then
		user=$(get_user "$alias")
		pass=$(get_pass "$alias")
		addr=$(get_addr "$alias")
		port=$(get_port "$alias")
		pkey=$(get_pkey "$alias")
		# Use default port when parameter is missing
		if [ "$port" == "" ]; then
			port=$SSH_DEFAULT_PORT
		fi

		echo "connecting to '$alias' ($addr:$port)"

		command="
	        expect {
                \"*password\" { send \"${pass}\n\"; exp_continue ; sleep 2; }
                \"*passphrase\" { send \"${pass}\r\"; exp_continue ; sleep 2; }
                \"yes/no\" { send \"yes\r\"; exp_continue; }
                \"Last*\" {  }
	        }
	        interact
	    ";

		if [ $pkey != "pass" ]
		then
			expect -c "
			    set timeout 2000
				spawn ssh ${user}@${addr} -p ${port} -i ${pkey}
				${command}
			"
		else
			expect -c "
			    set timeout 2000
				spawn ssh ${user}@${addr} -p ${port}
				${command}
			"
		fi

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
		server_auto_connect ${2} ${3}
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