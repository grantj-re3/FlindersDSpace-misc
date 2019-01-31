#!/bin/sh
#
# Copyright (c) 2018, Flinders University, South Australia. All rights reserved.
# Contributors: Library, Corporate Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
# 
# Usage:  show_deleted_bitstream_info.sh  70875  dspace.log.YYYY-MM-DD
#   where 70875 is the bitstream_id (eg. reported in the DSpace 5.x
#   "Checksum checker Report" email attachment)
#
# When bitstreams are deleted, you cannot find the associated bundle_id
# and item_id using the usual database method because typically (always?)
# the bundle_id has been removed from tables:
# - bundle
# - bundle2bitstream
# - item2bundle
#
##############################################################################
RHOST="dspace_database_remote_host.example.com"
DBNAME="dspace"
PSQL_CMD="psql -h $RHOST -d $DBNAME"

# The DSpace item URL to the left of HANDLE_PREFIX/HANDLE_SUFFIX.
# Eg1. http://hdl.handle.net/
# Eg2. https://dspace.example.com/xmlui/handle/
DSPACE_ITEM_URL_PART1="http://hdl.handle.net/"

##############################################################################
usage() {
  echo "Usage:  `basename $0`  BITSTREAM_ID  DSPACE_LOG1 [DSPACE_LOG2 ...]"
  echo "E.g.:   `basename $0`  70875  dspace.log.2018-10-19"
  exit 1
}

##############################################################################
show_bundle_id() {
  bitstream_id="$1"
  shift

  echo
  line_bitstr=`egrep ":remove_bitstream:bundle_id=.*,bitstream_id=$bitstream_id\$"  "$@"`
  echo "$line_bitstr"

  bundle_id=`echo "$line_bitstr" |sed 's!^.*bundle_id=!!; s!,.*$!!'`
  [ -z "$bundle_id" ] && {
    echo "No associated bundle_id was found!"
    exit 3
  }
  echo "### FOUND bundle_id '$bundle_id'"
}

##############################################################################
show_item_id() {
  bundle_id="$1"
  shift

  echo
  line_bundle=`egrep ":remove_bundle:item_id=.*bundle_id=$bundle_id\$"  "$@"`
  echo "$line_bundle"

  item_id=`echo "$line_bundle" |sed 's!^.*item_id=!!; s!,.*$!!'`
  [ -z "$item_id" ] && {
    echo "No associated item_id was found!"
    exit 4
  }
  echo "### FOUND item_id '$item_id'"
}

##############################################################################
show_url() {
  item_id="$1"
  [ "$item_id" ] && {
    echo
    sql_res=`$PSQL_CMD -c "select handle,resource_id item_id,'<<url_pt1>>' || handle url from handle where resource_type_id=2 and resource_id=$item_id"`
    echo "$sql_res" |sed "s~<<url_pt1>>~$DSPACE_ITEM_URL_PART1~"
  }
}

##############################################################################
# Main
##############################################################################
[ "$1" = -h -o "$1" = --help -o "$#" -lt 2 ] && usage

bitstream_id="$1"
shift

if echo "$bitstream_id" |grep -vqP "^\d+$"; then
  echo "ERROR: bitstream_id '$bitstream_id' is not an integer"
  usage
fi

echo "Attempting to find bundle_id, item_id and URL via DSpace logs for:"
echo "### bitstream_id '$bitstream_id'"
show_bundle_id  "$bitstream_id"  "$@"
show_item_id    "$bundle_id"     "$@"
show_url        "$item_id"

