#!/bin/sh
#
# Copyright (c) 2014-2018, Flinders University, South Australia. All rights reserved.
# Contributors: Library, Corporate Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
# 
# This query gives item-counts for CAUL institutional repository
# statistics. CAUL is the Council of Australian University Librarians.
#
# This query should be run on DSpace v3.0 or newer (where embargo is
# defined by resourcepolicy.start_date > 'now').
#
# CSV query results are written to STDOUT; all other output is
# written to STDERR.
##############################################################################
PATH=/bin:/usr/bin:/usr/local/bin;	export PATH

user=$USER	# CUSTOMISE: Database user: Assume same name as the Unix user
db=dspace	# CUSTOMISE: Database name
rhost="dspace-db.example.com"			# CUSTOMISE: Database remotehost
psql_connect_opts="-h $rhost -U $user -d $db"	# CUSTOMISE: Connect options

is_dspace5=1	# CUSTOMISE: 1=DSpace 5 database schema; 0=DSpace 3 schema

app=`basename $0`

# The default year is the year which was this many days ago.
# I would like the year-counts to be for last-year for cron jobs on 1st Jan
# and 1st Feb; else I would like current-year counts.
num_days_ago=40

##############################################################################
# Optionally override the above psql_connect_opts variable.
psql_env_fname=`dirname $0`/psql_connect_env.sh	# Path to environment-file
[ -f $psql_env_fname ] && . $psql_env_fname

##############################################################################
# DSpace resource_type_id
# See https://github.com/DSpace/DSpace/blob/master/dspace-api/src/main/java/org/dspace/core/Constants.java
TYPE_BITSTREAM=0
TYPE_BUNDLE=1
TYPE_ITEM=2
TYPE_COLLECTION=3

##############################################################################
# usage_exit(msg) -- Display specified message, then usage-message, then exit
##############################################################################
usage_exit() {
  msg="$1"
  {
    [ "$msg" ] && echo "$msg"
    echo "Usage:  $app [ YEAR [ COLLECTION_HANDLE ] ]"
    echo "   or:  $app --help|-h"
    echo "If not specified, YEAR will default to the year which was $num_days_ago days ago."
    echo "Omit the COLLECTION_HANDLE to gather CAUL statistics for all collections."
  } >&2
  exit 1
}

##############################################################################
# Main
##############################################################################

# Deal with command line parameters
[ "$1" = -h -o "$1" = --help ] && usage_exit

if [ "$1" = "" ]; then
  year=`date -d "$num_days_ago days ago" +%Y`
else
  year="$1"
fi

shift
if [ "$1" = "" ]; then
  collection_hdl=""
  collection_clause=""
else
  collection_hdl="$1"
  collection_clause="and c.collection_id=
        (select resource_id from handle where resource_type_id=$TYPE_COLLECTION and handle='$collection_hdl')"
fi

if [ $is_dspace5 = 1 ]; then
  bundle_clause=`cat <<-EOSQL_BUNDLE_CLAUSE_DS5
	select resource_id from metadatavalue where text_value='ORIGINAL' and resource_type_id=$TYPE_BUNDLE and metadata_field_id in
	        (select metadata_field_id from metadatafieldregistry where element='title' and qualifier is null)
	        and resource_id in
	EOSQL_BUNDLE_CLAUSE_DS5
  `
  year_items_clause=`cat <<-EOSQL_YEAR_ITEMS_CLAUSE_DS5
	select resource_id item_id
	    from metadatavalue
	    where
	      resource_type_id=$TYPE_ITEM and
	EOSQL_YEAR_ITEMS_CLAUSE_DS5
  `
else
  bundle_clause=`cat <<-EOSQL_BUNDLE_CLAUSE_DS3
	select bundle_id from bundle where name='ORIGINAL' and bundle_id in
	EOSQL_BUNDLE_CLAUSE_DS3
  `
  year_items_clause=`cat <<-EOSQL_YEAR_ITEMS_CLAUSE_DS3
	select item_id
	    from metadatavalue
	    where
	EOSQL_YEAR_ITEMS_CLAUSE_DS3
  `
fi

sql="
with 
  published_items as (
    select
      item_id
    from item i
    where
      i.withdrawn='f' and
      i.in_archive = 't' and
      exists (select collection_id from collection c where i.owning_collection=c.collection_id $collection_clause) and
      exists (select resource_id from handle h where h.resource_type_id=$TYPE_ITEM and h.resource_id=i.item_id)
  ),
  embargo_items as (
    select distinct item_id from item2bundle where bundle_id in
      ($bundle_clause
        (select bundle_id from bundle2bitstream where bitstream_id in
          (select bitstream_id from bitstream where deleted<>'t' and bitstream_id in
            (select resource_id from resourcepolicy where resource_type_id=$TYPE_BITSTREAM and start_date > 'now')
          )
        )
      )
  ),
  bitstream_items as (
    select distinct item_id from item2bundle where bundle_id in
      ($bundle_clause
        (select bundle_id from bundle2bitstream where bitstream_id in
          (select bitstream_id from bitstream where deleted<>'t'
          )
        )
      )
  ),
  year_items as (
    $year_items_clause
      metadata_field_id =
        (select metadata_field_id from metadatafieldregistry where element='date' and qualifier='accessioned')
    group by item_id
    having min(substring(text_value from 1 for 4)) = '$year'
  )

select
  (select count(*) from published_items where item_id in
    (select item_id from bitstream_items) and item_id not in
	(select item_id from embargo_items)
  ) icount_1_bitstream_notembargo,
  (select count(*) from published_items where item_id in
    (select item_id from bitstream_items) and item_id in
	(select item_id from embargo_items)
  ) icount_2_bitstream_embargo,
  (select count(*) from published_items where item_id in
    (select item_id from bitstream_items)
  ) icount_3_bitstream_total,

  (select count(*) from published_items where item_id not in
    (select item_id from bitstream_items)
  ) icount_4_notbitstream_total,
  (select count(*) from published_items) icount_7_total,

  '$year' for_year,
  (select count(*) from published_items where item_id not in
    (select item_id from bitstream_items) and item_id in
    (select item_id from year_items)
  ) icount_5_notbitstream_year,
  (select count(*) from published_items where item_id in
    (select item_id from bitstream_items) and item_id in
    (select item_id from year_items)
  ) icount_6_bitstream_year,

  to_char(now(), 'YYYY-MM-DD HH24:MI:SS') now,
  (case '$collection_hdl'
    when '' then 'All-Collections'
    else 'Collection-Handle-$collection_hdl-Only'
  end) db_range
"

query="copy (
$sql
)
to stdout
with
  delimiter ','
  csv
    header
    force quote for_year,now,db_range
"

descr="This query gives item-counts for CAUL institutional repository
statistics. CAUL is the Council of Australian University Librarians.

The items have the characteristics that they are:
- published items (in_archive is true and item has a handle); and
- have not been withdrawn; and
- are owned by a valid collection (sanity check)

Mapped versions of an item are not counted (only the 'concrete' item
is counted).

If a single item contains several bitstreams (ie. works) the item
is only counted once.

If one bitstream is embargoed then the item is considered to be embargoed.

Column names are defined as follows:
  icount_1_bitstream_notembargo:
    Count of published items having bitstreams without a current embargo.
  icount_2_bitstream_embargo:
    Count of published items having bitstreams with a current embargo.
  icount_3_bitstream_total:
    Total count of published items having bitstreams (ie. the sum of
    counts 1 and 2).
  icount_4_notbitstream_total:
    Total count of published metadata-only items (ie. not having bitstreams).
  icount_7_total:
    Total count of published items (ie. the sum of counts 3 and 4).
  for_year:
    The year for the year-counts which follow (ie. counts 5 and 6).
  icount_5_notbitstream_year:
    Total count of published metadata-only items (ie. not having bitstreams)
    for the specified (dc.date.accessioned) year.
  icount_6_bitstream_year:
    Total count of published items having bitstreams for the specified
    (dc.date.accessioned) year.
  now:
    The time this query was run.
  db_range:
    The database range against which this query was run. Eg. Either
    'All-Collections' or 'Collection-Handle-123456789/26019-Only'
    (for collection handle 123456789/26019).
"

##############################################################################
cmd="psql $psql_connect_opts -A -c \"$query\""
{
cat <<-EOF

	DESCRIPTION: $descr

	QUERY: $query
	---
EOF
} >&2
eval $cmd

