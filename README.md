FlindersDSpace-misc
===================

Description
-----------
A set of useful utilities for DSpace.

- *user_activity.sh* extracts user event information (ie. login, failed_login
  and autoregister) from one or more dspace.log.YYYY-MM-DD log files.

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

