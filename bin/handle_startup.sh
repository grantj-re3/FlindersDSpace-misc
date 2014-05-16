#!/bin/sh
# handle_startup.sh
#
# Copyright (c) 2014, Flinders University, South Australia. All rights reserved.
# Contributors: eResearch@Flinders, Library, Information Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
# 
##############################################################################
PATH=/bin:/usr/bin:/usr/local/bin;	export PATH
hdl_log_path=$HOME/dspace/log/handle-plugin.log
app=`basename $0`

##############################################################################
# usage_exit(msg) -- Display specified message, then usage-message, then exit
##############################################################################
usage_exit() {
  msg="$1"
  [ "$msg" ] && echo "$msg"
  echo "Usage:  $app [handle-plugin.log[.YYYY-MM-DD] ...]"
  echo "   or:  $app --help|-h"
  echo "If unspecified, handle-plugin.log[.YYYY-MM-DD] defaults to handle-plugin.log*"
  exit 1
}

##############################################################################
# Main
##############################################################################

# Deal with command line parameters
[ "$1" = -h -o "$1" = --help ] && usage_exit

if [ $# = 0 ]; then
  files="$hdl_log_path*"
  files_msg="Using default files: $files"
else
  files=$@
  files_msg=""
fi

# Describe what we are doing
echo "Searching for DSpace handle.net startup events" >&2
[ "$files_msg" ] && echo "$files_msg" >&2
echo "---" >&2

#grep -h " @ Loading " $files |sort
matching_lines=`grep -h " @ Loading " $files`

if [ $? = 0 -o $? = 1 ]; then
  echo "$matching_lines" |sort
else
  usage_exit "---"
fi

