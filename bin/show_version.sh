#!/bin/sh
# show_version.sh
#
# Show the DSpace version which generated the specified URL.
#
# Copyright (c) 2014, Flinders University, South Australia. All rights reserved.
# Contributors: eResearch@Flinders, Library, Information Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
# 
##############################################################################
dspace_url="http://localhost/jspui"	# Default DSpace URL (which may not exist)
app=`basename $0`

wget_cmd="wget -q -O -"
curl_cmd="curl -s -o -"
cmd="$wget_cmd"				# Use either wget or curl to get web page

##############################################################################
# usage_exit(msg) -- Display specified message, then usage-message, then exit
##############################################################################
usage_exit() {
  msg="$1"
  [ "$msg" ] && echo "$msg"
  echo "Usage:  $app [A_DSPACE_URL]"
  echo "   Eg.  $app \"http://dspace.example.com/jspui/\""
  exit 1
}

##############################################################################
# Main
##############################################################################
[ "$1" = -h -o "$1" = --help ] && usage_exit
[ "$1" != "" ] && dspace_url="$1"

echo "DSpace version at URL $dspace_url is:"
$cmd "$dspace_url" |
  awk -F\" '/<meta *name=\"Generator\"/ {print $4}'

