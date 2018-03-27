#!/bin/sh
# user_activity.sh
#
# Show one of the specified events: login, failed_login and autoregister.
# A logout event might also be useful but our default user interface XMLUI
# does not seem to log such events for DSpace 3.x (although the JSPUI does).
#
# Copyright (c) 2014-2018, Flinders University, South Australia. All rights reserved.
# Contributors: eResearch@Flinders, Library, Information Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
# 
##############################################################################
PATH=/bin:/usr/bin:/usr/local/bin;	export PATH
ds_log_path=$HOME/dspace/log/dspace.log
app=`basename $0`

##############################################################################
# usage_exit(msg) -- Display specified message, then usage-message, then exit
##############################################################################
usage_exit() {
  msg="$1"
  [ "$msg" ] && echo "$msg"
  echo "Usage:  $app login|failed_login|autoregister|sword_login [dspace.log.YYYY-MM-DD ...]"
  echo "   or:  cat dspace.log.YYYY-MM-DD ... |$app login|failed_login|autoregister|sword_login --"
  echo "   or:  $app --help|-h"
  echo "If unspecified, dspace.log.YYYY-MM-DD defaults to all days in this month."
  exit 1
}

##############################################################################
# Main
##############################################################################

# Deal with command line parameters
[ "$1" = -h -o "$1" = --help ] && usage_exit

param="$1"
shift
[ ! "$param" ] && usage_exit

is_stdin=0
if [ $# = 0 ]; then
  this_month=`date +%Y-%m`
  files="$ds_log_path.$this_month*"
  files_msg="Using default files: $files"

elif [ "$1" = "--" ]; then
  is_stdin=1
  files=""
  files_msg="Reading from STDIN..."

else
  files=$@
  files_msg="Reading from files given on command line..."
fi

# Describe what we are doing
echo "Searching for DSpace '$param' events" >&2
[ "$files_msg" ] && echo "$files_msg" >&2
echo "---" >&2

# Process the param
case "$param" in
  login)
    # Output format example: 2014-01-01 10:10:10 login USERNAME
    cmd="egrep -h \"(AuthenticationUtil|PasswordServlet).*:login:\" $files |
      sed 's/^\(.\{19\}\).* @ \(.*\):session_id=.*$/\1 login \2/'"
    ;;

  failed_login)
    # Output format example: 2014-01-01 10:10:10 failed_login USERNAME
    cmd="grep -h :failed_login: $files |
      sed 's/^\(.\{19\}\).*:email=\([^,]*\).*$/\1 failed_login \2/'"
    ;;

  autoregister)
    # Output format example: 2014-01-01 10:10:10 autoregister USERNAME
    cmd="egrep -h \":autoregister:\" $files |
      sed 's/^\(.\{19\}\).*:netid=\(.*\)$/\1 autoregister \2/'"
    ;;

  sword_login)
    # Output format example: 2014-01-01 10:10:10 sword_login USERNAME
    cmd="egrep -h \"SWORDService.*Authenticated user:\" $files |
      sed 's/^\(.\{19\}\).*Authenticated user: \(.*\); *$/\1 sword_login \2/'"
    ;;

  *)
    usage_exit "Unrecognised parameter '$param'"
    ;;
esac

[ $is_stdin = 1 ] && cmd="cat |$cmd"
eval $cmd

