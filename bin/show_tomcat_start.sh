#!/bin/sh
#
# Copyright (c) 2014, Flinders University, South Australia. All rights reserved.
# Contributors: eResearch@Flinders, Library, Information Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
# 
##############################################################################
PATH=/bin:/usr/bin:/usr/local/bin;	export PATH
tomcat_log_path=$HOME/tomcatlogs/catalina.out	# Perhaps /var/log/tomcat...
app=`basename $0`

##############################################################################
# usage_exit(msg) -- Display specified message, then usage-message, then exit
##############################################################################
usage_exit() {
  msg="$1"
  [ "$msg" ] && echo "$msg"
  echo "Usage:  $app [catalina.out[-YYYYMMDD.gz] ...]"
  echo "   or:  $app --help|-h"
  echo "File arguments can be all plain text files or all gzipped files."
  echo "If unspecified, catalina.out[-YYYYMMDD.gz] defaults to catalina.out"
  exit 1
}

##############################################################################
# Return the command needed to send the file(s) to stdout
##############################################################################
get_cat_command() {
  cat_cmd="cat"
  cat_msg="Assuming NO files need to be gunzipped"

  if echo "$1" |grep -q "\.gz$"; then
    cat_cmd="gunzip -c"
    cat_msg="Assuming ALL files need to be gunzipped"
  fi
}

##############################################################################
# Main
##############################################################################

# Deal with command line parameters
[ "$1" = -h -o "$1" = --help ] && usage_exit

if [ $# = 0 ]; then
  files="$tomcat_log_path"
  files_msg="Using default file: $files"
else
  files=$@
  files_msg=""
fi

get_cat_command $1

# Describe what we are doing
echo "Searching for DSpace tomcat startup events" >&2
echo "$cat_msg" >&2
[ "$files_msg" ] && echo "$files_msg" >&2
echo "---" >&2

$cat_cmd $files |grep -i startup.*load$

