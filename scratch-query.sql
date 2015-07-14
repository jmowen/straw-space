-- some queries for backups



-- take a backup of master to the default location
declare @BackupFile nvarchar(max) = 'master-database-example.bak'

backup database master to disk = @backupfile with init, copy_only, compression;


-- The default backup directory
DECLARE    @BackupDirectory nvarchar(1000)
EXEC master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',
N'Software\Microsoft\MSSQLServer\MSSQLServer',N'BackupDirectory',@BackupDirectory OUTPUT ;

select @BackupDirectory


-- Query the filesystem the database server can see to return any backup files in particular path
-- Uses un-official xp_dirtree 
if object_id ('tempdb..#xp_dirtree') is not null drop table #xp_dirtree

create table #xp_dirtree (subdirectory nvarchar(max), depth int, [file] int) 
insert #xp_dirtree (subdirectory, depth , [file] ) EXEC master.sys.xp_dirtree @BackupDirectory,1,1 ;

-- We're just going to find the first file named master*.bak to read the file info, this is to demo.
-- prefixing the name with the path we found in the registry
declare @BackupFileFullName nvarchar(max) = @BackupDirectory + '\'+ (select top 1 subdirectory from #xp_dirtree where subdirectory like 'master%.bak')

-- run the special restore commands to read the file information. 
restore headeronly from disk = @BackupFileFullName
restore labelonly from disk = @BackupFileFullName







