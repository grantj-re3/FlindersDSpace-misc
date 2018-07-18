#!/bin/sh
#
# Copyright (c) 2018, Flinders University, South Australia. All rights reserved.
# Contributors: Library, Corporate Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
#
# Usage:  checker_wrap.sh [-a|--all]
#
# This script does the following.
# - Ensures that checker-emailer reports are not run until *after*
#   the checker job has successfully completed.
# - There appears to be a bug in DSpace v5.6 (and perhaps other
#   versions) where if you run say "dspace checker-emailer -c -m"
#   and there is a checksum problem but not missing-bitstream problem,
#   then no email report will be sent! Hence this script invokes
#   checker-emailer reports as *separate* commands.
# - Sends an email confirmation regarding all the checker and
#   checker-emailer jobs which have been run (so we can see the
#   difference between "nothing to report" vs "checker was not run").
#
##############################################################################
PATH=/bin:/usr/bin:/usr/local/bin; export PATH

# Build email parameters
APP=`basename $0`
DATESTAMP=`date "+%F %T"`
HOST=`hostname -s`

EMAIL_SUBJECT="$HOST - $APP - $DATESTAMP"	# CUSTOMISE
EMAIL_LIST="me@example.com you@example.com"	# CUSTOMISE

# Build commands
DSPACE_PATH="$HOME/dspace/bin/dspace"		# CUSTOMISE
CHECKER_OPTS="-lp"				# CUSTOMISE

# Commands to execute (and for reporting purposes)
cmd_chk="$DSPACE_PATH checker $CHECKER_OPTS"	# CUSTOMISE
cmd_c="$DSPACE_PATH   checker-emailer -c"	# Changes-report
cmd_m="$DSPACE_PATH   checker-emailer -m"	# Missing-report
cmd_a="$DSPACE_PATH   checker-emailer -a"	# All-reports

# Return code message strings
S_SUCCESS="Success"
S_FAILURE="FailErrorCode:"
S_NOT_RUN="DidNotRun"

# Return codes (for reporting purposes). Set default values.
ret_c="$S_NOT_RUN"
ret_m="$S_NOT_RUN"
ret_a="$S_NOT_RUN"

# Report on these results
# Eg. For suffix="chk", report on command $cmd_chk & its return code $ret_chk.
RESULTS_CONF="
# SUFFIX LABEL

  chk	Verify bitstream checksums
  c	Generate Changes-report
  m	Generate Missing-report
"

##############################################################################
# Optionally override any of the above variables.
ENV_PATH="`echo \"$0\" |sed 's/\.sh$/_env.sh/'`"      # Path to THIS_env.sh
[ -f $ENV_PATH ] && . $ENV_PATH

##############################################################################
return_code_to_message() {
  ret="$1"
  if [ "$ret" = 0 ]; then
    msg="$S_SUCCESS"

  elif [ "$ret" = "$S_NOT_RUN" ]; then
    msg="$S_NOT_RUN"

  else
    msg="$S_FAILURE'$ret'"
  fi
}

##############################################################################
show_results() {
  cmd="$1"
  ret="$2"
  label="$3"
  return_code_to_message "$ret"

  echo
  echo "Label:    $label"
  echo "Command:  $cmd"
  echo "Result:   $msg"
}

##############################################################################
do_checksum_check() {
  $cmd_chk
  ret_chk=$?

  # Only run email reports if checker successfully completed
  [ "$ret_chk" = 0 ] && {
    $cmd_c
    ret_c=$?

    $cmd_m
    ret_m=$?

    [ "$1" = "-a" -o "$1" = "--all" ] && {
      $cmd_a
      ret_a=$?
    }
  }

  # Report the status of all DSpace commands above
  echo
  echo "--"
  echo "SHOW SUCCESS AND FAILURE OF DSPACE CHECKSUM-VERIFICATION"

  echo "$RESULTS_CONF" |
    while read suffix label; do
      if echo "$suffix" |egrep -q "^[ 	]*(#|$)"; then continue; fi	# Skip empty lines

      # Eg. Evaluate:  show_results "$cmd_chk" "$ret_chk" "$label"
      eval_cmd="show_results \"\$cmd_$suffix\" \"\$ret_$suffix\" \"$label\""
      eval $eval_cmd
    done

  [ "$1" = "-a" -o "$1" = "--all" ] && {
    show_results "$cmd_a" "$ret_a" "Generate All-reports"
  }
}

##############################################################################
# Main
##############################################################################
do_checksum_check $@ 2>&1 |mailx -s "$EMAIL_SUBJECT" $EMAIL_LIST

