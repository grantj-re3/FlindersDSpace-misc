#!/bin/sh
#
# Copyright (c) 2018, Flinders University, South Australia. All rights reserved.
# Contributors: Library, Corporate Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
#
# Usage:  check_net_connections.sh  [--email|-e]
#
# Count the (java) network connections from localhost to a remote host.
# The comments in this script assume that these are DSpace database
# connections. The results are displayed on stdout or sent via email.
#
# Unless run as root, netstat will only show the network connections
# owned by the user running the netstat command.
#
# If your DSpace instance also runs a DSpace Handle.net server,
# then these will also have a connection to the database (but
# since our handle server runs as a different user, they will not
# be counted by netstat in this script if this script runs as the
# DSpace user). These are represented in $HDL_NET_COUNT for
# information only.
#
# If your DSpace database also has connections from another app,
# these are represented in $ERA_NET_COUNT for information only.
#
##############################################################################
PATH=/bin:/usr/bin:/usr/local/bin; export PATH
USER=`id -un`
DSPACE_NET_COUNT_MAX=65		# Warn if $net_conn_total exceeds this

HDL_NET_COUNT=27		# CUSTOMISE: The handle DB *is* the DSpace DB
ERA_NET_COUNT=9			# CUSTOMISE

REMOTE_IP=1.2.3.4		# CUSTOMISE: Remote DB IP address

EMAIL_DEST="me@example.com"	# CUSTOMISE
EMAIL_SUBJECT="DSpace database network connections for `hostname`"	# CUSTOMISE

##############################################################################
# Optionally override any of the above variables.
ENV_PATH="`echo \"$0\" |sed 's/\.sh$/_env.sh/'`"      # Path to THIS_env.sh
[ -f $ENV_PATH ] && . $ENV_PATH

##############################################################################
getNetstatOutput() {
  netstat_output=`netstat -aneopT 2>/dev/null |
    egrep java |
    egrep $REMOTE_IP`
}

##############################################################################
getNetConnectionCount() {
  # Eg. netstat field 9 is "12345/java" (ie. ProcessID/ProcessName)
  net_conn_count=`echo "$netstat_output" |
    awk '{print $9}' |
    sort |
    uniq -c`
}

##############################################################################
getNetConnectionState() {
  # Eg. netstat field 6 is "ESTABLISHED" (ie. StateName)
  net_conn_state=`echo "$netstat_output" |
    awk '{print $6}' |
    sort |
    uniq -c`
}

##############################################################################
getNetConnectionsTotal() {
  net_conn_total=`echo "$netstat_output" |wc -l`

  net_conn_warn=""
  net_conn_subject_warn=""
  [ $net_conn_total -gt $DSPACE_NET_COUNT_MAX ] && {
    net_conn_warn="WARNING: Total connections exceeds $DSPACE_NET_COUNT_MAX"
    net_conn_subject_warn="WARNING: "
  }
}

##############################################################################
reportConnections() {
  email_addendum=""
  [ "$1" = --email -o "$1" = -e ] && email_addendum="This is an automated message, please do not reply."

  cat <<-EOF
	1/ The number of network database connections by '$USER' is:
	     $net_conn_total

	$net_conn_warn

	2/ The number of network database connection-states by '$USER' is:
	$net_conn_state

	where:
	- The first value is the connection-state count
	- The second value is the connection state; we only expect the
	  ESTABLISHED state to be present in the long term


	3/ The number of network database connection-processes by '$USER' is:
	$net_conn_count

	where:
	- The first value is the connection-process count
	- The second value is the Process ID of the java app


	Notes:
	- 55 total DSpace database connections is considered ok
	- 71 total DSpace database connections has caused problems in the past
	- Above about $DSPACE_NET_COUNT_MAX we may have trouble running new (eg. cron) jobs
	- Assumes Handle.net database connection count of $HDL_NET_COUNT
	- Assumes ERA database connection count of $ERA_NET_COUNT


	$email_addendum
EOF
}

##############################################################################
# Main
##############################################################################
getNetstatOutput

# Derive info from the netstat output
getNetConnectionsTotal			# Also gets 2x $net_conn_*warn
getNetConnectionState
getNetConnectionCount

if [ "$1" = --email -o "$1" = -e ]; then
  reportConnections "$1" |mailx -s "$net_conn_subject_warn$EMAIL_SUBJECT" $EMAIL_DEST
else
  reportConnections "$1"
fi

