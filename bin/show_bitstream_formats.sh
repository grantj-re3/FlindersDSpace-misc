#!/bin/sh
#
# Copyright (c) 2016-2018, Flinders University, South Australia. All rights reserved.
# Contributors: Library, Corporate Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
# 
# Current known bitstream formats can also been seen by navigating to
# http://my_dspace_server/xmlui > Login > Registries: Format
# 
##############################################################################
user=$USER	# CUSTOMISE: Database user: Assume same name as the Unix user
db=dspace	# CUSTOMISE: Database name
rhost="dspace-db.example.com"			# CUSTOMISE: Database remotehost
psql_connect_opts="-h $rhost -U $user -d $db"	# CUSTOMISE: Connect options

##############################################################################
# Optionally override the above psql_connect_opts variable.
psql_env_fname=`dirname $0`/psql_connect_env.sh	# Path to environment-file
[ -f $psql_env_fname ] && . $psql_env_fname

##############################################################################
# The meaning of support levels are derived from
# https://github.com/DSpace/DSpace/blob/master/dspace-api/src/main/java/org/dspace/content/BitstreamFormat.java

sql="
select 
  short_description \\\"Name\\\",
  array_to_string(array(
    select extension from fileextension fe
    where fe.bitstream_format_id=bsfr.bitstream_format_id
  ), ', ') \\\"Extensions\\\",
  mimetype \\\"MIME Type\\\",
  (case support_level
    when 0 then 'Unknown'
    when 1 then 'Known'
    when 2 then 'Supported'
    else 'Unrecognised'
  end) \\\"Support Level\\\"
from
  bitstreamformatregistry bsfr
where internal<>'t'
order by short_description
"

descr="Extract known bitstream formats
"

##############################################################################
show_csv() {
  query="copy (
$sql
)
to stdout
with
  delimiter ','
  csv
    header
    force quote \\\"Extensions\\\"
"
  cmd="psql $psql_connect_opts -A -c \"$query\""
  cat <<-EOF_CSV

		DESCRIPTION: $descr

		COMMAND: $cmd
		---
	EOF_CSV
  eval $cmd
}

##############################################################################
show_html() {
  query="$sql"
  cmd="psql $psql_connect_opts -H -c \"$query\""
  cat <<-EOF_HTML

		DESCRIPTION: $descr

		COMMAND: $cmd
		---
	EOF_HTML
  eval $cmd
}

##############################################################################
if [ "$1" = -H -o "$1" = --html ]; then
  show_html
else
  show_csv
fi

