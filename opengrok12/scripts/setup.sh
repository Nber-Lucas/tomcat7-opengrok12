#!/bin/bash

OPENGROK_ROOT=$(dirname "$PWD")
#OPENGROK_ROOT="$PWD"
OPENGROK_BIN="$OPENGROK_ROOT/bin"
OPENGROK_INDEX="$OPENGROK_ROOT/index"
OPENGROK_DATABASE="$OPENGROK_ROOT/database"
OPENGROK_LIB="$OPENGROK_ROOT/lib"
TOMCAT7_WEBAPPS="$OPENGROK_ROOT/../tomcat7/webapps"
PRODECT_INDEXPATH="$OPENGROK_INDEX/$1"
PRODECT_LINKPATH="$OPENGROK_DATABASE/$1"
Err=103
Ok=0

function setup_index()
{
	if [ ! -d $PRODECT_INDEXPATH ]; then
		mkdir $PRODECT_INDEXPATH
	else
		echo "file already exist"
		return $Err
	fi
}

function setup_database()
{
#	echo ln -s $1 $PRODECT_LINKPATH
	ln -s $1 $PRODECT_LINKPATH
}

function setup_run()
{
	export OPENGROK_INSTANCE_BASE="$PRODECT_INDEXPATH"
	cd ../	
	./bin/OpenGrok index $PRODECT_LINKPATH
}

function setup_tomcat()
{
	
	local SRC_FILE="$OPENGROK_LIB/source.war"
	local DEC_FILE="$TOMCAT7_WEBAPPS/$1.war"
	local REPLACE_STR0="\/var\/opengrok"
	local REPLACE_STR1=`echo $PRODECT_INDEXPATH | sed 's#\/#\\\/#g'`
	local REPLACE_DECFILE="$TOMCAT7_WEBAPPS/$1/WEB-INF/web.xml"
	local REPLACE_STR="$REPLACE_STR0/$REPLACE_STR1"


	echo "############### opengrok deploy start ###############"
	#echo $REPLACE_STR1
	cp $SRC_FILE $DEC_FILE
	sleep 10
	#echo '123456' | sudo -S sed -i 's/'$REPLACE_STR'/'  $REPLACE_DECFILE
	sudo -S sed -i 's/'$REPLACE_STR'/'  $REPLACE_DECFILE
	echo "############### opengrok deploy end ###############"
	echo ""
}


function _wrap_build()
{
#    local start_time=$(date +"%s")
#    local ret=$?
#    local end_time=$(date +"%s")
     local start_time=$1
     local ret=$2
     local end_time=$3
    local tdiff=$(($end_time-$start_time))
    local hours=$(($tdiff / 3600 ))
    local mins=$((($tdiff % 3600) / 60))
    local secs=$(($tdiff % 60))
    local ncolors=$(tput colors 2>/dev/null)
    if [ -n "$ncolors" ] && [ $ncolors -ge 8 ]; then
        color_failed=$'\E'"[0;31m"
        color_success=$'\E'"[0;32m"
        color_reset=$'\E'"[00m"
    else
        color_failed=""
        color_success=""
        color_reset=""
    fi
    echo
    if [ $ret -eq 0 ] ; then
        echo -n "${color_success}#### create opengrok successfully "
    else
        echo -n "${color_failed}#### creat opengrok failed "
    fi
    if [ $hours -gt 0 ] ; then
        printf "(%02g:%02g:%02g (hh:mm:ss))" $hours $mins $secs
    elif [ $mins -gt 0 ] ; then
        printf "(%02g:%02g (mm:ss))" $mins $secs
    elif [ $secs -gt 0 ] ; then
        printf "(%s seconds)" $secs
    fi
    echo " ####${color_reset}"
    echo
    return $ret
}

function running()
{
		local start_time=$(date +"%s")
        echo "============================"
        setup_index
		retn=$?
	 	if [ $retn -eq 0 ] ; then	
        	setup_database $2
			retn=$?
			if [ $retn -eq 0 ] ; then
				setup_run
				retn=$?
				#if [ $retn -eq 0 ] ; then
        			#setup_tomcat $1
					#retn=$?
				#fi
			fi
		fi
        echo "============================"
		local ret=$retn
		local end_time=$(date +"%s")
		_wrap_build $start_time $ret $end_time

	local color_failed=$'\E'"[0;31m"
	local color_success=$'\E'"[0;32m"
	local color_reset=$'\E'"[00m"

	if [ $retn -eq 0 ] ; then
		setup_tomcat $1
		echo
    	if [ $? -eq 0 ] ; then
        	echo -n "${color_success}#### opengrok deploy successfully "
    	else
        	echo -n "${color_failed}#### opengrok deploy failed "
    	fi
		echo " ####${color_reset}"
		echo
	fi

}
#
#Main Program
#
Usage()
{
	progname=`basename $0`	
	exec >&2
	echo "Usage: ${progname} <productname && productpath>"
	echo "Usage: $1 <productname>"
	echo "Usage: $2 <productpath>"
	echo ""
	exit 1
}

#tarttime=$(date +%s)
if [ $# -eq 0 ]; then
	Usage
else
	if [ ! -d $2 ]; then
		echo "product dir not found!!!"
	else

#		echo "============================"
#		setup_index
#		setup_database $2
#		setup_run
#		setup_tomcat $1
#		echo "============================"
	running $1 $2
	
	fi
fi
#endtime=$(date +%s)
#cost=$((endtime - starttime))
#echo $cost
