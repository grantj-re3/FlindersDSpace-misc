#!/bin/sh
# Usage: url_timout.sh
#
# Copyright (c) 2014-2018, Flinders University, South Australia. All rights reserved.
# Contributors: Library, Corporate Services, Flinders University.
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

app_dir_temp=`dirname "$0"`		# Might be relative (eg "." or "..") or absolute
etc_dir=`cd "$app_dir_temp/../etc" ; pwd`	# Absolute path of etc dir

# CUSTOMISE: Space separated list of (mailx) destination email addresses
email_dest_list="me@example.com you@example.com"
email_subject="URL lookup failure(s) on $datestamp"

# CUSTOMISE: Config below consists of 3 fields separated by white-space
# - Time limit (seconds)
# - URL
# - Description of URL being fetched
config_url="
	20	http://hdl.handle.net/xxxx/yyyyy	DSpace production handle
	20	http://my.dspace.site/xmlui/		DSpace home page
"

wget_cli="wget -q"	# CUSTOMISE: CLI including common switches for this app

##############################################################################
# Optionally override any of the above variables.
env_fname="$etc_dir/`basename $0 |sed 's/\.sh$/_env.sh/'`"	# Path to THIS_env.sh
[ -f $env_fname ] && . $env_fname

##############################################################################
# Increment the integer argument. Return via the count variable.
# (Workaround to avoid backticks within a backtick-block for sh compatibility)
increment_count() {
  count=`expr $1 + 1`
}

##############################################################################
fail_msg=`
  count=0
  echo "$config_url" |
    while read timeout url desc; do
      [ "$timeout" = "" ] && continue 

      cmd="$wget_cli -O/dev/null -t1 -T$timeout \"$url\""
      #echo "CMD: $cmd" >&2
      eval $cmd

      if [ $? != 0 ]; then
        increment_count $count
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

