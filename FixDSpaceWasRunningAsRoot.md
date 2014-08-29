# Fixes to apply if DSpace was running as root

## DISCLAIMER

These instructions have been written after the event and may lack
accuracy. They are expected to be a guide only. You are expected
to understand the consequences of any Linux commands which you
invoke. ___Use at your own risk.___

## Guidelines

If the DSpace web app (ie. java tomcat) is started as the root user by
mistake, then started later as the unprivileged DSPACE_OWNER, you are
likely to encounter ownership problems in the following directory trees.  

1. DSPACE_DIR (where DSPACE_DIR is dspace.dir within the dspace.cfg
   configuration file)
1. ~tomcat/logs
1. /var/cache/tomcat*/work/Catalina/localhost/xmlui/cache-dir

The above problems can probably be fixed with a recursive correction of
ownership in each of the above directory trees. Ie.
```
  chown -R DSPACE_OWNER ...
```
  
- Fixing item 1 should allow you to see permission errors
  (eg. in DSPACE_DIR/log) and fix SOLR errors.
- Fixing item 2 should allow you to see some more the permission errors.
  At this point the JSPUI should work.
- Fixing item 3 should allow the XMLUI to work.

Some useful commands were:

```
grep -i permission ~tomcat/logs/catalina.out
grep -i permission DSPACE_DIR/log/cocoon.log.YYYY-MM-DD
less DSPACE_DIR/log/dspace.log.YYYY-MM-DD
```

