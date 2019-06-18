#!/bin/sh
#
# Copyright (c) 2014-2019, Flinders University, South Australia. All rights reserved.
# Contributors: Library, Corporate Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
#
##############################################################################
user=$USER	# Database user: Assume same name as the Unix user
db=dspace	# Database name

app=`basename $0`

##############################################################################
# Optionally override the above psql_connect_opts variable.
psql_env_fname=`dirname $0`/psql_connect_env.sh	# Path to environment-file
[ -f $psql_env_fname ] && . $psql_env_fname

##############################################################################
# DSpace resource_type_id
# See https://github.com/DSpace/DSpace/blob/master/dspace-api/src/main/java/org/dspace/core/Constants.java
TYPE_ITEM=2
TYPE_COLLECTION=3

##############################################################################
# usage_exit(msg) -- Display specified message, then usage-message, then exit
##############################################################################
usage_exit() {
  msg="$1"
  {
    [ "$msg" ] && echo "$msg"
    echo "Usage:  $app  COLLECTION_HANDLE"
    echo "   or:  $app --help|-h"
    echo "where COLLECTION_HANDLE is of the form 123456789/9999"
  } >&2
  exit 1
}

##############################################################################
# Main
##############################################################################
# Deal with command line parameters
[ "$1" = -h -o "$1" = --help -o "$1" = "" ] && usage_exit
collection_hdl="$1"

# The item_id and title columns may be handy for debugging.
# If you don't need them, then either remove the corresponding lines from
# the SELECT section of the query, or delete the columns using your
# favourite spreadsheet app.
sql="
select
  (select 'http://hdl.handle.net/'||handle from handle where resource_type_id=$TYPE_ITEM and resource_id=i.item_id) handle,

  array_to_string(array(
    select text_value from metadatavalue where resource_type_id=$TYPE_ITEM and resource_id=i.item_id and metadata_field_id=
      (select metadata_field_id from metadatafieldregistry where element='identifier' and qualifier is null and metadata_schema_id=
        (select metadata_schema_id from metadataschemaregistry where short_id='dc')
      )
  ), '||') identifiers,

  i.item_id,

  array_to_string(array(
    select text_value from metadatavalue where resource_type_id=$TYPE_ITEM and resource_id=i.item_id and metadata_field_id=
      (select metadata_field_id from metadatafieldregistry where element='title' and qualifier is null and metadata_schema_id=
        (select metadata_schema_id from metadataschemaregistry where short_id='dc')
      )
  ), '||') titles

from
  (
    select item_id from collection2item where collection_id in
      (select resource_id from handle where resource_type_id=$TYPE_COLLECTION and handle='$collection_hdl')
  ) i
order by 2
"

query="copy (
$sql
)
to stdout
with
  delimiter ','
  csv
    header
    force quote handle,identifiers,item_id,titles
"

descr="Show the handle and identifier of every item in the specified collection.
The output of this query can be used to load DSpace handle info back into the
original (Filemaker) database.
"

##############################################################################
cmd="psql $psql_connect_opts -A -c \"$query\""
cat <<-EOF

	DESCRIPTION: $descr

	COMMAND: $cmd
	---
EOF
eval $cmd

