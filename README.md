FlindersDSpace-misc
===================

Description
-----------
A set of useful utilities for DSpace.

- *dc_relation.sh* extracts all DSpace items containing dc.relation
  *or* dc.relation.uri fields (depending on configuration).

- *show_handle_start.sh* shows DSpace handle.net startup events,
  in particular the config file read by the handle server.
  * Takes zero or more handle-plugin.log files as parameters.

- *show_tomcat_start.sh* shows DSpace tomcat startup events.
  * Takes zero or more catalina.out files as parameters.
  * File parameters can be all plain text files or all gzipped files.

- *user_activity.sh* extracts user event information (ie. login, failed_login
  and autoregister) from one or more dspace.log.YYYY-MM-DD log files.

- *user_cleanup_info.sh* extracts DSpace user information including:
  * number of submitted items
  * number of epersongroups for which eperson is a member
  * list of epersongroups for which eperson is a member
  * number of collections to which the eperson is subscribed
  * list of collections to which the eperson is subscribed

Application environment
-----------------------
Read the INSTALL file.


Installation
------------
Read the INSTALL file.


Example usage
-------------

After installation and configuration, this program can be used as follows.

- List successful user login events
```
# Search log files which have this month appended to the filename (eg. 2014-05*)
bin/user_activity.sh login

# Search the specified log files
bin/user_activity.sh login ~/dspace/log/dspace.log.2014-05-0[789]
```

- List unsuccessful user login events
```
# Search log files which have this month appended to the filename (eg. 2014-05*)
bin/user_activity.sh failed_login

# Search the specified log files
bin/user_activity.sh failed_login ~/dspace/log/dspace.log.2014-05-0[789]
```

- List autoregister user events
```
# Search log files which have this month appended to the filename (eg. 2014-05*)
bin/user_activity.sh autoregister

# Search the specified log files
bin/user_activity.sh autoregister ~/dspace/log/dspace.log.2014-0[45]*
```

