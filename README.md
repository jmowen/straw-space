# straw-space
explorations in sql server

SQL Server database backups can be inspected by a SQL Server to see what's in them using the RESTORE LABELONLY and RESTORE HEADERONLY commands. Using this information it's possible to see what backup files need to be restored in what order to bring back a database or apply the next backupset in a restore chain. All that's needed is a SQL Server Login account with enough privilege (or a domain or local server windows account). "Enough Privilege" is thought to be SERVERADMIN.

I've seen several Powershell implementatations of this; They were not very good or clear (IMO anyway). So I'm taking a stab at it. 

This is a work in progress; no warranties or assertion of fitness for use is meant or implied, YMMV, use at your own risk.
