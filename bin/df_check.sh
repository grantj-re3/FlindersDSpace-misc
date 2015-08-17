#!/bin/sh
# Issue a warning if any mount point exceeds its specified %-full threshold.
#
# Usage 1: df_check.sh			# Display result to STDOUT
# Usage 2: df_check.sh --email|-e	# Send email if result is not empty
#
# Copyright (c) 2015, Flinders University, South Australia. All rights reserved.
# Contributors: Library, Information Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
#
##############################################################################
PATH=/bin:/usr/bin:/usr/local/bin;	export PATH

# mailx: Space separated list of destination email addresses
email_dest_list="me@example.com you@example.com"
email_subject="WARNING: Disk too full on `hostname` at `date +%F\ %T`"

# Warning generated if df percent-column is above this percentage
PERCENT_FULL_DEFAULT_THRESHOLD=80

# Override the above default threshold for particular mount points.
# Line format is: MountPointName PercentThreshold
# Space/tab separated; leading/trailing space/tab ok
# Lines starting with '#' will be ignored
# Example:
#	/var	70
#	/opt	90
#	#/	80  This line is ignored

percent_full_indiv_threshold="
	#MntPt	%
	/var	70
	/opt	90
"

##############################################################################
# Algorithm:
#   Iterate through each mount point (using df)
#   Remove '%' symbol
#   Join line if mount point is on 1st line & df-info on next line
#   While(read pct mountpt) {
#     threshold = Value from above config (or else the default threshold)
#     Display warning if(pct > threshold)
#   }
##############################################################################
show_if_mountpt_too_full() {
df -m |
  tr -d % |
  awk 'NR>1 && NF==6 {print} NR>1 && NF==5 {print p $0} {p=$0}' |
    while read device f2 f3 f4 pct mountpt; do
      threshold=`echo "$percent_full_indiv_threshold" |
        egrep -v "^[[:space:]]*#" |
        awk -v mountpt="$mountpt" '$1==mountpt {print $2}'`

      # Use the default threshold if no individual threshold found
      [ "$threshold" = "" ] && threshold=$PERCENT_FULL_DEFAULT_THRESHOLD

      [ "$pct" -gt "$threshold" ] && echo "WARNING: $mountpt is $pct% full"
    done
}

##############################################################################
# main()
##############################################################################
if [ "$1" = "--email" -o "$1" = "-e" ]; then
  # Send email if result is not empty
  result=`show_if_mountpt_too_full`
  [ `echo "$result" |wc -c` -gt 1 ] && echo "$result" |mailx -s "$email_subject" $email_dest_list

else
  show_if_mountpt_too_full		# Display result to STDOUT
fi

