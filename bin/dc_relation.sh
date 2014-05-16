#!/bin/sh
#
# Copyright (c) 2014, Flinders University, South Australia. All rights reserved.
# Contributors: eResearch@Flinders, Library, Information Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
# 
##############################################################################
user=$USER	# Database user: Assume same name as the Unix user
db=dspace	# Database name
show_dc_relation_uri=0	# 1=Show dc.relation.uri info; 0=Show dc.relation info

if [ $show_dc_relation_uri = 1 ]; then
  where_subclause="mfr.qualifier='uri'"
else
  where_subclause="mfr.qualifier is null"
fi

sql="
select
  mv.item_id,
  'http://hdl.handle.net/' || (select handle from handle where resource_type_id=2 and resource_id=mv.item_id) handle,
  (case
    when mfr.qualifier is null then 'dc.' || mfr.element
    else 'dc.' || mfr.element || '.'|| mfr.qualifier
  end) dc_field,
  mv.text_value dc_value,
  (select text_value from metadatavalue where item_id=mv.item_id and metadata_field_id =
    (select metadata_field_id from metadatafieldregistry where element = 'title' and qualifier is null)
  ) item_title,
  (select name from collection where collection_id=
    (select owning_collection from item where item_id=mv.item_id)
  ) owning_collection_name,
  (select email from eperson where eperson_id=
    (select submitter_id from item where item_id=mv.item_id)
  ) submitter_email
from
  metadatavalue mv,
  metadatafieldregistry mfr
where 
  mv.metadata_field_id = mfr.metadata_field_id and
  mfr.element='relation' and
  $where_subclause
order by item_id
"

query="copy (
$sql
)
to stdout
with
  delimiter ','
  csv
    header
    force quote item_title, owning_collection_name, submitter_email
"

descr="Extract DSpace items containing dc.relation OR dc.relation.uri fields
for investigation
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

