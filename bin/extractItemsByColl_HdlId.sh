#!/bin/sh
#
# Copyright (c) 2014, Flinders University, South Australia. All rights reserved.
# Contributors: eResearch@Flinders, Library, Information Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
#
##############################################################################
user=$USER	# Database user: Assume same name as the Unix user
db=dspace	# Database name

# Handle of the collection which we are querying
collection_hdl="123456789/6071"

# The item_id and title columns may be handy for debugging.
# If you don't need them, then either remove the corresponding lines from
# the SELECT section of the query, or delete the columns using your
# favourite spreadsheet app.
sql="
select
  (select 'http://hdl.handle.net/'||handle from handle where resource_type_id=2 and resource_id=i.item_id) handle,
  (
    select text_value from metadatavalue where item_id=i.item_id and metadata_field_id =
      (select metadata_field_id from metadatafieldregistry where element='identifier' and qualifier is null)
  ) identifier,
  i.item_id,
  (
    select text_value from metadatavalue where item_id=i.item_id and metadata_field_id =
      (select metadata_field_id from metadatafieldregistry where element='title' and qualifier is null)
  ) title

from
  (
    select item_id from collection2item where collection_id in
      (select resource_id from handle where resource_type_id=3 and handle='$collection_hdl')
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
    force quote handle,identifier,item_id,title
"

descr="Show the handle and identifier of every item in the specified collection.
The output of this query can be used to load DSpace handle info back into the
original (Filemaker) database.
"

##############################################################################
psql_opts="-U $user -d $db -A -c \"$query\""
cmd="psql $psql_opts"

cat <<-EOF

	DESCRIPTION: $descr

	COMMAND: $cmd
	---
EOF
eval $cmd

