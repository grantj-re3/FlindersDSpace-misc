#!/bin/sh
#
# Copyright (c) 2016, Flinders University, South Australia. All rights reserved.
# Contributors: Library, Corporate Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
# 
# Current known bitstream formats can also been seen by navigating to
# http://my_dspace_server/xmlui > Login > Registries: Format
# 
##############################################################################
user=$USER	# Database user: Assume same name as the Unix user
db=dspace	# Database name

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

  psql_opts="-U $user -d $db -A -c \"$query\""
  cmd="psql $psql_opts"

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

  psql_opts="-U $user -d $db -H -c \"$query\""
  cmd="psql $psql_opts"

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

