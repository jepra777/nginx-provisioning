#!/usr/bin/bash

#TEXT COLORING
G='\033[0;32m'
R='\033[0;31m'
C='\033[0m'

# STATUS
STATUS_OK="[${G}OK${C}]"
STATUS_FAIL="[${R}FAIL${C}]"

# VARIABLES
_ROOTDIR=""
ssh_user="${SSH_USER:-}"
ssh_host="${SSH_HOST:-}"

ok() { echo -e "$1 $STATUS_OK"; }
fail() { echo -e "$1 $STATUS_FAIL"; exit 1; }

# FUNCTION TO CHECK PROCESS SUCCESS OR FAILED
success_or_not () {
	if [[ $? -ne 0 ]]; then fail "$2"; fi    
    ok "$1"
}

# FUNCTION FOR SSH REMOTE
ssh_remote () {
    local commands="$@"
    ssh -T -l "$ssh_user" "$ssh_host" "$commands"
}

# BEGIN
if [[ -z "$ssh_user" || -z "$ssh_host" ]]; then
    fail "SSH_HOST or SSH_USER is not defined"
fi

echo "============================================"
echo "=[Virtual Host Creator Tool - For Smartbid]="
echo "============================================"
echo -n "Please input the subdomain: " 
read SUBDOMAIN

if [[ -z "$SUBDOMAIN" ]]; then
	fail "Subdomain required"
fi

_ROOTDIR="/var/www/prod/$SUBDOMAIN.smartbid.co.id/public_html"
_CONFIGFILE="/etc/nginx/sites-available/$SUBDOMAIN.smarbid.co.id"

if ssh_remote "[[ ! -d $_ROOTDIR ]]"; then 
	fail "The directory $_ROOTDIR already exists"
fi

ssh_remote "mkdir -p $_ROOTDIR" 

success_or_not "The directory $_ROOTDIR has been created" "Cannot create web root directory: $_ROOTDIR"

_HTMLMOCKUP="<h1>$SUBDOMAIN Site: Please Insert Web Code </h1><text> This Web Page is generated with Server Block Generator Tool by JePra <text>"
ssh_remote "echo '$_HTMLMOCKUP' > $_ROOTDIR/index.html"
success_or_not "Success to crete the HTML Mockup file in $_ROOTDIR" "Failed to create the HTML mockup file in $_ROOTDIR"


_UPSTREAM_CONF=$(sed "s/SUBDOMAIN/$SUBDOMAIN/g" ~/upstream.template)
success_or_not "Success to create the template with $SUBDOMAIN" "Failed to replace the template with $ubdomain"

if ssh_remote "[[ -f $_CONFIGFILE ]]"; then
	fail "The config file already exists: $_CONFIGFILE"
fi

ssh_remote "echo '$_UPSTREAM_CONF' > /etc/nginx/sites-available/$SUBDOMAIN.smartbid.co.id"
#echo "$_UPSTREAM_CONF" | ssh root@gerda.onlyirul.com tee /etc/nginx/sites-available/$SUBDOMAIN.smartbid.co.id
success_or_not "Success to create virtual host config in /etc/nginx/sites-available/$SUBDOMAIN.smartbid.co.id" "Failed to create virtual host config in /etc/nginx/sites-available/$SUBDOMAIN.smartbid.co.id"
	
ssh_remote "ln -s /etc/nginx/sites-available/$SUBDOMAIN.smartbid.co.id /etc/nginx/sites-enabled/" 
success_or_not "Success to enable config for $SUBDOMAIN" "Failed to enable config for $SUBDOMAIN"

ssh_remote "nginx -tq"
success_or_not "No error found in $SUBDOMAIN.smartbid.co.id configuration file" "Error found in $SUBDOMAIN.smartbid.co.id configuration file"

ssh_remote "nginx -s reload" 
ssh_remote "nginx -Tq | grep -q $SUBDOMAIN"
success_or_not "The $SUBDOMAIN.smartbid.co.id configuration has been loaded" "The $SUBDOMAIN.smartbid.co.id configuration failed to be loaded"
