#!/bin/sh
# df_check.sh
# Issue a warning if any mount point exceeds its specified %-full threshold.
#
# Copyright (c) 2014, Flinders University, South Australia. All rights reserved.
# Contributors: Library, Information Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
#
##############################################################################
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
#     threshold = Value from above config
#     Display warning if(pct > threshold)
#   }
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

