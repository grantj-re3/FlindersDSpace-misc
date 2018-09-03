FlindersDSpace-misc
===================

Description
-----------
A set of useful utilities for DSpace.

- *caul_stats.sh* extracts DSpace item-counts for CAUL institutional
  repository statistics. CAUL is the Council of Australian University
  Librarians.  This query should be run on DSpace v3.0 or newer
  (where embargo is defined by resourcepolicy.start_date > 'now').

- *checker_wrap.sh* does the following.
  * Ensures that checker-emailer reports are not run until *after*
    the checker job has successfully completed.
  * There appears to be a bug in DSpace v5.6 (and perhaps other
    versions) where if you run say "dspace checker-emailer -c -m"
    and there is a checksum problem but not missing-bitstream problem,
    then no email report will be sent! Hence this script invokes
    checker-emailer reports as *separate* commands.
  * Sends an email confirmation regarding all the checker and
    checker-emailer jobs which have been run (so we can see the
    difference between *nothing to report* vs *checker was not run*).

- *dc_relation.sh* extracts all DSpace items containing dc.relation
  *or* dc.relation.uri fields (depending on configuration).

- *dc_relation_nhmrc.sh* extracts items from the NHMRC collection
  containing dc.relation *or* dc.relation.uri fields (depending on
  configuration).

- *df_check.sh* issues a warning if any mount point exceeds its
  specified percent-full threshold.

- *extractItemsByColl_HdlId.sh* shows the handle and identifier of
  every item in the specified collection. The output of this query
  can be used to load DSpace handle info back into the original
  (Filemaker) database.

- *group_auths.sh* extracts authorisations against the specified
  group including:
  * resource type (eg. ITEM, COLLECTION, COMMUNITY)
  * resource name for some resource types
  * action name (eg. READ, WRITE, ADD)

- *show_all_metadata.sh* shows all values of the metadata field
  specified on the command line (eg. dc.contributor.advisor).

- *show_bitstream_formats.sh* shows known bitstream formats.

- *show_handle_start.sh* shows DSpace handle.net startup events,
  in particular the config file read by the handle server.
  * Takes zero or more handle-plugin.log files as parameters.

- *show_tomcat_start.sh* shows DSpace tomcat startup events.
  * Takes zero or more catalina.out files as parameters.
  * File parameters can be all plain text files or all gzipped files.

- *show_version.sh* shows the version of DSpace which generated the
  web page at the specified URL.

- *url_timout.sh* attempts to access a list of URLs. It sends a
  failure notification email if any accesses fail, otherwise no
  email is sent.

- *user_activity.sh* extracts user event information (ie. login, failed_login
  and autoregister) from one or more dspace.log.YYYY-MM-DD log files.

- *user_cleanup_info.sh* extracts DSpace user information including:
  * number of submitted items
  * number of epersongroups for which eperson is a member
  * list of epersongroups for which eperson is a member
  * number of collections to which the eperson is subscribed
  * list of collections to which the eperson is subscribed

- *user_subscription_info.sh* extracts DSpace subscription info including:
  * email address of eperson
  * whether the eperson can login
  * handle of the collection (because the eperson subscription-list in the
    GUI does not distinguish between collections with identical names)

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

