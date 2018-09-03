#!/bin/sh
#
# Copyright (c) 2018, Flinders University, South Australia. All rights reserved.
# Contributors: Library, Corporate Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
# 
# This query gives all values of the metadata field specified on the
# command line (eg. dc.contributor.advisor). The CSV output format shows:
# - the handle
# - the name of the metadata field
# - the value of the metadata field
# 
# This query should be run on DSpace v5.0 or newer
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

##############################################################################
# Optionally override the above psql_connect_opts variable.
psql_env_fname=`dirname $0`/psql_connect_env.sh	# Path to environment-file
[ -f $psql_env_fname ] && . $psql_env_fname

##############################################################################
# usage_exit(msg) -- Display specified message, then usage-message, then exit
##############################################################################
usage_exit() {
  msg="$1"
  {
    [ "$msg" ] && echo "$msg"
    echo "Usage:  $app  SCHEMA.ELEMENT[.QUALIFIER]"
    echo "  Eg1.  $app  dc.contributor.advisor"
    echo "  Eg2.  $app  dc.source"
  } >&2
  exit 1
}

##############################################################################
get_command_line_params() {
  [ $# != 1 ] && usage_exit
  metadata=`echo $1 |sed 's!\.! !g'`
  num_parts=`echo $metadata |wc -w`
  [ $num_parts != 2 -a $num_parts != 3 ] && usage_exit

  schema=`echo $metadata    |cut -d' ' -f1`	# Eg. 'dc'
  element=`echo $metadata   |cut -d' ' -f2`	# Eg. 'contributor'
  qualifier=`echo $metadata |cut -d' ' -f3`	# Eg1. 'advisor'. Eg2. ''

  [ -z "$qualifier" ] && {
    qualifier_clause="mf.qualifier is null"
  } || {
    qualifier_clause="mf.qualifier='$qualifier'"
  }
}

##############################################################################
# Main
##############################################################################
# Deal with command line parameters
[ "$1" = -h -o "$1" = --help ] && usage_exit
get_command_line_params $@

sql="
select
  h.handle,
  ms.short_id || '.' || mf.element || '.' || mf.qualifier as field_name,
  mv.text_value field_value
from
  metadatavalue mv,
  metadatafieldregistry mf,
  metadataschemaregistry ms,
  handle h
where
  mf.metadata_field_id=mv.metadata_field_id and
  mf.metadata_schema_id=ms.metadata_schema_id and
  ms.short_id='$schema' and
  mf.element='$element' and
  $qualifier_clause and
  h.resource_id=mv.resource_id and
  h.resource_type_id=mv.resource_type_id
order by 3
"

query="copy (
$sql
)
to stdout
with
  delimiter ','
  csv
    header
"

descr="This query gives all metadata for the metadata field '$1'"

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

