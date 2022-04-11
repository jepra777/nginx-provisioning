#!/usr/bin/bash

#TEXT COLORING
G='\033[0;32m'
R='\033[0;31m'
C='\033[0m'

#STATUS 
STATUS_OK="[${G}OK${C}]"
STATUS_FAIL="[${R}FAIL${C}]"

#VARIABLES
_ROOTDIR=""

#FUNCTION FOR CHECK PROCESS SUCCESS OR FAILED
success_or_not () {
	if ssh_remote "[[ $? -eq 0 ]]"; then
		echo -e "$1 $STATUS_OK"
	else
		echo -e "$2 $STATUS_FAIL"
		exit 1
	fi
}

#FUNCTION FOR SSH REMOTE
ssh_remote () {
        ssh -T root@gerda.onlyirul.com "$1"
}


echo "============================================"
echo "=[Virtual Host Creator Tool - For Smartbid]="
echo "============================================"
echo -n "Please Input the Subdomain to Create: " 
read SUBDOMAIN

if [[ ! -z "$SUBDOMAIN" ]]; then
	_ROOTDIR="/var/www/prod/$SUBDOMAIN.smartbid.co.id/public_html"
	_CONFIGFILE="/etc/nginx/sites-available/$SUBDOMAIN.smarbid.co.id"
else
	echo -e "Subdomain required $STATUS_FAIL"
	exit 1
fi

if ssh_remote "[[ ! -d $_ROOTDIR ]]"; then 
	ssh_remote "mkdir -p $_ROOTDIR" 
	if ssh_remote "[[ $? -eq 0 ]]"; then	
		echo -e "The Directory $_ROOTDIR Has been Created $STATUS_OK"
		_HTMLMOCKUP="<h1>$SUBDOMAIN Site: Please Insert Web Code </h1><text> This Web Page Generate with Server Block Generator Tool by JePra <text>"
		ssh_remote "echo '$_HTMLMOCKUP' > $_ROOTDIR/index.html"
		success_or_not "HTML Mockup File in $_ROOTDIR Success to be Create" "HTML Mockup File in $_ROOTDIR Failed to be Create"
	else
		echo -e "Cannot Create Web Root Directory $STATUS_FAIL"
		exit 1
	fi	
else
	echo -e "The Directory $_ROOTDIR Already Exist $STATUS_FAIL"
	exit 1
fi

_UPSTREAM_CONF=$(sed "s/SUBDOMAIN/$SUBDOMAIN/g" ~/upstream.template)

success_or_not "Success to Replace the Template with current Subdomain" "Failed to Replace the Template with current Subdomain"

if ssh_remote "[[ ! -f $_CONFIGFILE ]]"; then
	ssh_remote "echo '$_UPSTREAM_CONF' > /etc/nginx/sites-available/$SUBDOMAIN.smartbid.co.id"
	#echo "$_UPSTREAM_CONF" | ssh root@gerda.onlyirul.com tee /etc/nginx/sites-available/$SUBDOMAIN.smartbid.co.id
	success_or_not "Success to Create Virtual Host Config in /etc/nginx/sites-available/$SUBDOMAIN.smartbid.co.id" "Failed to Create Virtual Host Config in /etc/nginx/sites-available/$SUBDOMAIN.smartbid.co.id"
else
	echo "The Config File Already Exist $STATUS_FAIL"
	exit 1
fi
	
ssh_remote "ln -s /etc/nginx/sites-available/$SUBDOMAIN.smartbid.co.id /etc/nginx/sites-enabled/" 

success_or_not "Success to Symlink Virtual Host Config in /etc/nginx/sites-available/$SUBDOMAIN.smartbid.co.id" "Failed to Symlink Virtual Host Config in /etc/nginx/sites-available/$SUBDOMAIN.smartbid.co.id"

ssh_remote "nginx -tq"
success_or_not "No Error Found in $SUBDOMAIN.smartbid.co.id Configuration File" "There is Error Found in $SUBDOMAIN.smartbid.co.id Configuration File"

ssh_remote "nginx -s reload" 
ssh_remote "nginx -Tq | grep -q $SUBDOMAIN"
success_or_not "The $SUBDOMAIN.smartbid.co.id Configuration Has Been Loaded" "The $SUBDOMAIN.smartbid.co.id Configuration Failed to Loaded"
