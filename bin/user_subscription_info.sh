#!/bin/sh
#
# Copyright (c) 2017, Flinders University, South Australia. All rights reserved.
# Contributors: Library, Corporate Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
# 
##############################################################################
user=$USER	# Database user: Assume same name as the Unix user
db=dspace	# Database name
collection_resource_type=3

sql="
select
  s.subscription_id sub_id,
  s.eperson_id usr_id,
  e.email,
  e.firstname,
  e.lastname,
  e.can_log_in,
  s.collection_id coll_id,
  (select handle from handle where
   resource_type_id=$collection_resource_type and resource_id=s.collection_id
  ) coll_hdl,
  c.name coll_name
from
  subscription s,
  eperson e,
  collection c 
where
  s.eperson_id=e.eperson_id and s.collection_id=c.collection_id
order by e.email,coll_name,coll_hdl
"

query="copy (
$sql
)
to stdout
with
  delimiter ','
  csv
    header
    force quote coll_name
"

descr="Extract subscription info including:
- email address of eperson
- whether the eperson can login
- handle of the collection (because the eperson subscription-list in the
  GUI does not distinguish between collections with identical names)
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

