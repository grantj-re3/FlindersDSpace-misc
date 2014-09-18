#!/bin/sh
# Usage: nla_unmatched.sh
#
# Copyright (c) 2014, Flinders University, South Australia. All rights reserved.
# Contributors: eResearch@Flinders, Library, Information Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
#
##############################################################################
# Short description:
# Attempt to access a list of URLs; send a failure notification email
# if any accesses fail; else do not send email.
#
##############################################################################
PATH=/bin:/usr/bin;	export PATH
datestamp=`date "+%a %F %H:%M"`

# mailx: Space separated list of destination email addresses
email_dest_list="me@example.com you@example.com"
email_subject="URL lookup failure(s) on $datestamp"

# Config below consists of 3 fields separated by white-space
# - Time limit (seconds)
# - URL
# - Description of URL being fetched
config_url="
	20	http://hdl.handle.net/xxxx/yyyyy	DSpace production handle
	20	http://my.dspace.site/xmlui/		DSpace production handle
"

##############################################################################
fail_msg=`
  count=0
  echo "$config_url" |
    while read timeout url desc; do
      [ "$timeout" = "" ] && continue 

      cmd="wget -q -O/dev/null -t1 -T$timeout \"$url\""
      #echo "CMD: $cmd" >&2
      eval $cmd

      if [ $? != 0 ]; then
        let count=$count+1
        echo -e "[$count] URL lookup failure for $desc\n - URL used was $url\n - no response received in $timeout seconds\n"
      fi
    done
`

if [ "$fail_msg" != "" ]; then
	# Send stdout in the block below as an email
	cat <<-EOMSG |mailx -s "$email_subject" $email_dest_list
		Below is the list of URL lookups which failed on $datestamp.

		$fail_msg

		-----
		This is an automatic email. Please do not reply
	EOMSG
fi

