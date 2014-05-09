#!/bin/sh
##############################################################################
user=$USER	# Database user: Assume same name as the Unix user
db=dspace	# Database name
only_show_users_who_can_login=0	# 0=Show all users; 1=Only show users who can login

if [ $only_show_users_who_can_login = 0 ]; then
  where_clause=""
else
  # Let's assume a user can login unless eperson.can_log_in='f'
  where_clause="where e.can_log_in<>'f' or e.can_log_in is null"
fi

# Queries for 'num_groups' and 'num_subs' could be simplified but I
# think it easier to understand if I replace 'name' with 'count(*)'
# in the queries for 'groups' and 'subscriptions' respectively.
sql="
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
  e.firstname,
  e.lastname,
  (select count(*) from epersongroup where eperson_group_id in
    (select eperson_group_id from epersongroup2eperson where eperson_id=e.eperson_id)
  ) num_groups,
  (select count(*) from collection where collection_id in
    (select collection_id from subscription where eperson_id = e.eperson_id)
  ) num_subs,
  array_to_string(array(
    select name from epersongroup where eperson_group_id in
      (select eperson_group_id from epersongroup2eperson where eperson_id=e.eperson_id)
    order by name
  ), '||') groups,
  array_to_string(array(
    select name from collection where collection_id in
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
psql_opts="-U $user -d $db -A -c \"$query\""
cmd="psql $psql_opts"

cat <<-EOF

	DESCRIPTION: $descr

	COMMAND: $cmd
	---
EOF
eval $cmd

