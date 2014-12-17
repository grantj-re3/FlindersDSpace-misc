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
  echo "Usage:  $app [ COLLECTION_ID ]"
  echo "   or:  $app --help|-h"
  echo "Omit the COLLECTION_ID to gather CAUL statistics for all collections."
  exit 1
}

##############################################################################
# Main
##############################################################################

# Deal with command line parameters
[ "$1" = -h -o "$1" = --help ] && usage_exit

if [ "$1" = "" ]; then
  collection_id=""
  collection_clause=""
else
  collection_id="$1"
  collection_clause="and c.collection_id=$collection_id"
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
      exists (select resource_id from handle h where h.resource_type_id=2 and h.resource_id=i.item_id)
  ),
  embargo_items as (
    select distinct item_id from item2bundle where bundle_id in
      (select bundle_id from bundle where name='ORIGINAL' and bundle_id in
        (select bundle_id from bundle2bitstream where bitstream_id in
          (select bitstream_id from bitstream where deleted<>'t' and source is not null and bitstream_id in
            (select resource_id from resourcepolicy where resource_type_id=0 and start_date > 'now')
          )
        )
      )
  ),
  bitstream_items as (
    select distinct item_id from item2bundle where bundle_id in
      (select bundle_id from bundle where name='ORIGINAL' and bundle_id in
        (select bundle_id from bundle2bitstream where bitstream_id in
          (select bitstream_id from bitstream where deleted<>'t' and source is not null
          )
        )
      )
  )

select
  (select count(*) from published_items where item_id in
    (select item_id from bitstream_items) and item_id not in
	(select item_id from embargo_items)
  ) pub_bs_notemb_icount_1,
  (select count(*) from published_items where item_id in
    (select item_id from bitstream_items) and item_id in
	(select item_id from embargo_items)
  ) pub_bs_emb_icount_2,
  (select count(*) from published_items where item_id in
    (select item_id from bitstream_items)
  ) pub_bs_total_icount_3,

  (select count(*) from published_items where item_id not in
    (select item_id from bitstream_items)
  ) pub_notbs_total_icount_4,
  (select count(*) from published_items) pub_icount_7,

  to_char(now(), 'YYYY-MM-DD HH24:MI:SS') now,
  (case '$collection_id'
    when '' then 'All-Collections'
    else 'Collection-Id-$collection_id-Only'
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
    force quote now,db_range
"

descr="This query gives item-counts for CAUL institutional repository
statistics. CAUL is the Council of Australian University Librarians.

The items have the characteristics that they are:
- published items (in_archive is true and item has a handle); and
- have not been withdrawn; and
- are owned by a valid collection (sanity check)

If a single items contains several bitstreams (ie. works) the item
is only counted once.

If one bitstream is embargoed then the item is considered to be embargoed.

Column names are defined as follows:
  pub_bs_notemb_icount_1:
    Count of published items having bitstreams without a current embargo.
  pub_bs_emb_icount_2:
    Count of published items having bitstreams with a current embargo.
  pub_bs_total_icount_3:
    Total count of published items having bitstreams (ie. the sum of
    counts 1 and 2).
  pub_notbs_total_icount_4:
    Total count of published metadata-only items (ie. not having bitstreams).
  pub_icount_7:
    Total count of published items (ie. the sum of counts 3 and 4).
  now:
    The time this query was run.
  db_range:
    The database range against which this query was run. Eg. Either
    'All-Collections' or 'Collection-Id-561-Only' (for collection_id 561).
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

