#!/bin/sh
#
# Copyright (c) 2014-2018, Flinders University, South Australia. All rights reserved.
# Contributors: Library, Corporate Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
# 
# Modified for DSpace 5+ database metadata as described at
# https://wiki.duraspace.org/display/DSPACE/Metadata+for+all+DSpace+objects
# 
##############################################################################
PATH=/bin:/usr/bin:/usr/local/bin;	export PATH

user=$USER	# CUSTOMISE: Database user: Assume same name as the Unix user
db=dspace	# CUSTOMISE: Database name
rhost="dspace-db.example.com"			# CUSTOMISE: Database remotehost
psql_connect_opts="-h $rhost -U $user -d $db"	# CUSTOMISE: Connect options

##############################################################################
# Optionally override the above psql_connect_opts variable.
psql_env_fname=`dirname $0`/psql_connect_env.sh	# Path to environment-file
[ -f $psql_env_fname ] && . $psql_env_fname

##############################################################################
# DSpace resource_type_id
# See https://github.com/DSpace/DSpace/blob/master/dspace-api/src/main/java/org/dspace/core/Constants.java
TYPE_COLLECTION=3
TYPE_GROUP=6

##############################################################################
only_show_users_who_can_login=0	# 0=Show all users; 1=Only show users who can login
if [ $only_show_users_who_can_login = 0 ]; then
  where_clause=""
else
  # Let's assume a user can login unless eperson.can_log_in='f'
  where_clause="where e.can_log_in<>'f' or e.can_log_in is null"
fi

##############################################################################
# Queries for 'num_groups' and 'num_subs' could be simplified but I
# think it easier to understand if I replace 'name' with 'count(*)'
# in the queries for 'groups' and 'subscriptions' respectively.
sql="
with
  eperson_meta as (
    select
      mv_f.resource_id,
      mv_f.text_value firstname,
      mv_l.text_value lastname
    from
      metadataschemaregistry ms,
      metadatafieldregistry mf_f, metadatavalue mv_f,
      metadatafieldregistry mf_l, metadatavalue mv_l
    where
      ms.short_id='eperson' and mv_f.resource_id=mv_l.resource_id and mv_f.resource_type_id=mv_l.resource_type_id and
      ms.metadata_schema_id=mf_f.metadata_schema_id and mf_f.metadata_field_id=mv_f.metadata_field_id and mf_f.element='firstname' and
      ms.metadata_schema_id=mf_l.metadata_schema_id and mf_l.metadata_field_id=mv_l.metadata_field_id and mf_l.element='lastname'
  ),

  group_meta as (
    select
      resource_id,
      text_value title
    from metadatavalue
    where resource_type_id=$TYPE_GROUP and
      metadata_field_id = (
        select mf.metadata_field_id
        from metadataschemaregistry ms, metadatafieldregistry mf
        where
          ms.metadata_schema_id=mf.metadata_schema_id and
          ms.short_id='dc' and
          mf.element='title' and
          mf.qualifier is null
    )
  ),

  collection_meta as (
    select
      resource_id,
      text_value title
    from metadatavalue
    where resource_type_id=$TYPE_COLLECTION and
      metadata_field_id = (
        select mf.metadata_field_id
        from metadataschemaregistry ms, metadatafieldregistry mf
        where
          ms.metadata_schema_id=mf.metadata_schema_id and
          ms.short_id='dc' and
          mf.element='title' and
          mf.qualifier is null
    )
  )

select
  e.email,
  e.can_log_in,
  e.netid,
  (case
    when e.password is null then null
    when char_length(e.password)>=128 then 'long_pwh'
    when char_length(e.password)>=32 then 'norm_pwh'
    else 'short_pwh'
  end) pw_hash,
  (select count(*) from item where submitter_id=e.eperson_id) num_items,
  (select firstname from eperson_meta where resource_id=e.eperson_id) firstname,
  (select lastname  from eperson_meta where resource_id=e.eperson_id) lastname,
  (select count(*) from epersongroup where eperson_group_id in
    (select eperson_group_id from epersongroup2eperson where eperson_id=e.eperson_id)
  ) num_groups,
  (select count(*) from collection where collection_id in
    (select collection_id from subscription where eperson_id = e.eperson_id)
  ) num_subs,
  array_to_string(array(
    select gm.title from epersongroup g, group_meta gm
    where g.eperson_group_id=gm.resource_id and eperson_group_id in
      (select eperson_group_id from epersongroup2eperson where eperson_id=e.eperson_id)
    order by 1
  ), '||') groups,
  array_to_string(array(
    select cm.title from collection c, collection_meta cm
    where c.collection_id=cm.resource_id and collection_id in
      (select collection_id from subscription where eperson_id = e.eperson_id)
  ), '||') subscriptions
from eperson e
$where_clause
order by e.email
"

query="copy (
$sql
)
to stdout
with
  delimiter ','
  csv
    header
    force quote groups, subscriptions
"

descr="Extract eperson info including:
- number of submitted items (num_items)
- number of epersongroups for which eperson is a member (num_groups)
- list of epersongroups for which eperson is a member (groups)
- number of collections to which the eperson is subscribed (num_subs)
- list of collections to which the eperson is subscribed (subscriptions)
"

##############################################################################
cmd="psql $psql_connect_opts -A -c \"$query\""
cat <<-EOF

	DESCRIPTION: $descr

	COMMAND: $cmd
	---
EOF
eval $cmd

