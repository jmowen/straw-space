-- restore backups utility script.
-- note this is a standalone. 
-- To organize things you could import or alter this script to run a "main" procedure or use from a program; Used from a program the program must parse 
-- batch delimeter "GO"

-- schema for program to operate in

-- backup files
CREATE TABLE #BackupFile (
	FolderPath nvarchar(512) not null,
	FileName nvarchar(512) not null,
	PathFileName as (FolderPath+'/'+Filename),
	PathFileNameHash as (cast(hashbytes('sha2_256',FolderPath+'/'+Filename) as varbinary(32))) persisted not null primary key,
	Selection varchar(30) not null default ('Append'),
	constraint check_selection check (Selection in ('Append','Remain','Delete')));


-- Specifications to find backup files
CREATE TABLE #BackupFileSpec (
	FolderPath nvarchar(512) not null Primary Key,
	FileSpec nvarchar(128) not null default('%'));


GO
-- proc to add backup file specs
create procedure #NewBackupFileSpec 
	@FolderPath nvarchar(512), @FileSpec nvarchar(128) = null as Begin
	Set Nocount on
	insert  #BackupFileSpec (FolderPath,FileSpec) values(@FolderPath,@FileSpec);
	End
GO




-- table to manage xp_dirtree results

--Create a temp table to hold the results.
IF OBJECT_ID('tempdb..#DirectoryTree') IS NOT NULL
      DROP TABLE #DirectoryTree;

CREATE TABLE #DirectoryTree (
       id int IDENTITY(1,1)
      ,fullpath varchar(2000)
      ,subdirectory nvarchar(512)
      ,depth int
      ,isfile bit);

--Create a clustered primary to keep everything in order.
ALTER TABLE #DirectoryTree
ADD CONSTRAINT PK_DirectoryTree PRIMARY KEY CLUSTERED (id);

-- create unique c to find things and enforce actual data constraints




==========================================================================================
DECLARE
       @BasePath varchar(1000)
      ,@Path varchar(1000)
      ,@FullPath varchar(2000)
      ,@Id int;

--This is your starting point.
SET @BasePath = 'D:\Backup';

--Create a temp table to hold the results.
IF OBJECT_ID('tempdb..#DirectoryTree') IS NOT NULL
      DROP TABLE #DirectoryTree;

CREATE TABLE #DirectoryTree (
       id int IDENTITY(1,1)
      ,fullpath varchar(2000)
      ,subdirectory nvarchar(512)
      ,depth int
      ,isfile bit);

--Create a clustered index to keep everything in order.
ALTER TABLE #DirectoryTree
ADD CONSTRAINT PK_DirectoryTree PRIMARY KEY CLUSTERED (id);

--Populate the table using the initial base path.
INSERT #DirectoryTree (subdirectory,depth,isfile)
EXEC master.sys.xp_dirtree @BasePath,1,1;

UPDATE #DirectoryTree SET fullpath = @BasePath;

--Loop through the table as long as there are still folders to process.
WHILE EXISTS (SELECT id FROM #DirectoryTree WHERE isfile = 0)
BEGIN
      --Select the first row that is a folder.
      SELECT TOP (1)
             @Id = id
            ,@FullPath = fullpath
            ,@Path = @BasePath + '\' + subdirectory
      FROM #DirectoryTree WHERE isfile = 0;

      IF @FullPath = @Path
      BEGIN
            --Do this section if the we are still in the same folder.
            INSERT #DirectoryTree (subdirectory,depth,isfile)
            EXEC master.sys.xp_dirtree @Path,1,1;

            UPDATE #DirectoryTree
            SET fullpath = @Path
            WHERE fullpath IS NULL;

            --Delete the processed folder.
            DELETE FROM #DirectoryTree WHERE id = @Id;
      END
      ELSE
      BEGIN
            --Do this section if we need to jump down into another subfolder.
            SET @BasePath = @FullPath;

            --Select the first row that is a folder.
            SELECT TOP (1)
                   @Id = id
                  ,@FullPath = fullpath
                  ,@Path = @BasePath + '\' + subdirectory
            FROM #DirectoryTree WHERE isfile = 0;

            INSERT #DirectoryTree (subdirectory,depth,isfile)
            EXEC master.sys.xp_dirtree @Path,1,1;

            UPDATE #DirectoryTree
            SET fullpath = @Path
            WHERE fullpath IS NULL;

            --Delete the processed folder.
            DELETE FROM #DirectoryTree WHERE id = @Id;
      END
END

--Output the results.
SELECT fullpath + '\' + subdirectory AS 'CompleteFileList'
FROM #DirectoryTree
ORDER BY fullpath,subdirectory;

--Cleanup.
IF OBJECT_ID('tempdb..#DirectoryTree') IS NOT NULL
      DROP TABLE #DirectoryTree;
GO
