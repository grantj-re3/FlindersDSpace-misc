#!/bin/sh
#
# Copyright (c) 2014, Flinders University, South Australia. All rights reserved.
# Contributors: Library, Information Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
# 
##############################################################################
PATH=/bin:/usr/bin:/usr/local/bin;	export PATH
user=$USER	# Database user: Assume same name as the Unix user
db=dspace	# Database name
app=`basename $0`

##############################################################################
# usage_exit(msg) -- Display specified message, then usage-message, then exit
##############################################################################
usage_exit() {
  msg="$1"
  [ "$msg" ] && echo "$msg"
  echo "Usage:  $app GROUP_NAME"
  echo "   or:  $app --help|-h"
  exit 1
}

##############################################################################
# Main
##############################################################################

# Deal with command line parameters
[ "$1" = -h -o "$1" = --help ] && usage_exit
[ "$1" = "" ] && usage_exit "You must specify a DSpace group name Eg. 'Administrator'"

group_name="$1"

sql="
select
  rp.policy_id,
  rp.resource_id,
  (case resource_type_id
    when 0 then 'BITSTREAM'
    when 1 then 'BUNDLE'
    when 2 then 'ITEM'
    when 3 then 'COLLECTION'
    when 4 then 'COMMUNITY'
    when 5 then 'SITE'
    when 6 then 'GROUP'
    when 7 then 'EPERSON'
    else 'UNKNOWN_TYPE'
  end) resource_type,

  (case resource_type_id
    when 0 then (
      select '<<' || c.name || ' {' || com.name || '}>>'
      from collection c, community2collection com2c, community com,
        item i, bundle2bitstream bu2bs, item2bundle i2bu
      where bu2bs.bitstream_id=rp.resource_id and i2bu.bundle_id=bu2bs.bundle_id and
        i.item_id=i2bu.item_id and i.owning_collection=c.collection_id and 
        c.collection_id=com2c.collection_id and com.community_id=com2c.community_id
    )
    when 1 then (
      select '<<' || c.name || ' {' || com.name || '}>>'
      from collection c, community2collection com2c, community com,
        item i, item2bundle i2bu
      where i2bu.bundle_id=rp.resource_id and
        i.item_id=i2bu.item_id and i.owning_collection=c.collection_id and 
        c.collection_id=com2c.collection_id and com.community_id=com2c.community_id
    )
    when 2 then (
      select '<<' || c.name || ' {' || com.name || '}>>'
      from collection c, community2collection com2c, community com, item i
      where i.item_id=rp.resource_id and i.owning_collection=c.collection_id and
        c.collection_id=com2c.collection_id and com.community_id=com2c.community_id
    )
    when 3 then (
      select c.name || ' {' || com.name || '}' collection_name
      from collection c, community2collection com2c, community com
      where c.collection_id=rp.resource_id and
        c.collection_id=com2c.collection_id and com.community_id=com2c.community_id
    )
    when 4 then (select name from community where community_id=rp.resource_id)
    when 6 then (select name from epersongroup where eperson_group_id=rp.resource_id)
    when 7 then (select email from eperson where eperson_id=rp.resource_id)
    else null
  end) resource_name,

  (case action_id
    when 0 then 'READ'
    when 1 then 'WRITE'
    when 2 then 'OBSOLETE (DELETE)'
    when 3 then 'ADD'
    when 4 then 'REMOVE'
    when 5 then 'WORKFLOW_STEP_1'
    when 6 then 'WORKFLOW_STEP_2'
    when 7 then 'WORKFLOW_STEP_3'
    when 8 then 'WORKFLOW_ABORT'
    when 9 then 'DEFAULT_BITSTREAM_READ'
    when 10 then 'DEFAULT_ITEM_READ'
    when 11 then 'ADMIN'
    else 'UNKNOWN_ACTION'
  end) action_name,
  g.name group_name
from resourcepolicy rp, epersongroup g
where rp.epersongroup_id=g.eperson_group_id and g.name='$group_name'
order by 3,4,5,1
"

query="copy (
$sql
)
to stdout
with
  delimiter ','
  csv
    header
    force quote resource_name,group_name
"

descr="Extract authorisations against the specified group including:
- resource type (eg. ITEM, COLLECTION, COMMUNITY)
- resource name for a subset of resource types
- action name (eg. READ, WRITE, ADD)

For collections, the resource name is:
  CollectionName {ParentCommunityName}.
For items, bundles & bitstreams, the resource name is:
  <<OwingCollectionName {ParentCommunityName}>>.
For epersons, the resource name is their email address.
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

