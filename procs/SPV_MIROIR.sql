SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

-----------------------------------------------------------------------------------------
-- Procédure		: SPV_MIROIR
-- Paramètre d'entrée	: @v_action : Action à mener
--						    0 : Désactivation
--						    1 : Activation
--						    2 : Basculement
--						  @v_bdd : Base de données courante (_DATA ou _LOG)
-- Paramètre de sortie	: 
-- Descriptif		: Paramétrage dynamique de la mise en miroir
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_MIROIR]
	@v_action smallint,
	@v_bdd sysname
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- Déclaration des variables
DECLARE
	@v_error int,
	@v_status int,
	@v_retour int,
	@v_spid smallint,
	@v_expression varchar(8000),
	@v_sql nvarchar(4000),
	@v_params nvarchar(32),
	@v_bdd_directory sysname,
	@v_bdd_backup_directory sysname,
	@v_bdd_backup_database sysname,
	@v_bdd_backup_log sysname,
	@v_bdd_backup_files sysname,
	@v_mirror_instance varchar(max),
	@v_mirroring_state_data tinyint,
	@v_mirroring_state_log tinyint,
	@v_par_val varchar(128)
	
-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1

-- Initialisation des variables
	SET @v_error = 0
	SET @v_retour = @CODE_KO

	SET TRANSACTION ISOLATION LEVEL READ COMMITTED

	SELECT @v_par_val = PAR_VAL FROM PARAMETRE WHERE PAR_NOM = 'DNSSUFFIX'
	IF @v_par_val <> ''
		SET @v_par_val = '.' + @v_par_val
	SELECT @v_mirror_instance = name FROM master.sys.certificates WHERE name <> @@SERVERNAME AND subject = 'AGV Manager certificate mirroring'
	IF @v_action = 0
	BEGIN
		SET @v_sql = 'ALTER DATABASE ' + @v_bdd + ' SET PARTNER OFF
			IF EXISTS (SELECT 1 FROM sys.databases WHERE name = ''''' + @v_bdd + ''''' AND state = 1)
				RESTORE DATABASE ' + @v_bdd + ' WITH RECOVERY'
		SET @v_sql = 'EXEC (''' + @v_sql + ''') AT [' + @v_mirror_instance + ']'
		EXEC (@v_sql)
		SET @v_error = @@ERROR
		IF @v_error = 0
			SET @v_retour = @CODE_OK
	END
	ELSE IF @v_action = 1
	BEGIN
		IF CHARINDEX('_DATA', @v_bdd) <> 0
			SET @v_expression = '\data'
		ELSE
			SET @v_expression = '\log'
		SELECT @v_bdd_directory = SUBSTRING(physical_name, 1, CHARINDEX(@v_expression, physical_name)) FROM master.sys.databases d LEFT OUTER JOIN master.sys.master_files m ON m.database_id = d.database_id WHERE d.name = '' + @v_bdd + '' AND file_id = 1
		SET @v_bdd_backup_directory = @v_bdd_directory
		SET @v_bdd_backup_database = @v_bdd + '_mirroring.bak'
		SET @v_bdd_backup_log = @v_bdd + '_mirroring.trn'		
		SET @v_sql = 'IF EXISTS (SELECT 1 FROM sys.database_mirroring dm JOIN sys.databases d ON dm.database_id = d.database_id WHERE d.name = ''' + @v_bdd + ''' AND mirroring_guid IS NOT NULL)
			OR EXISTS (SELECT 1 FROM sys.databases WHERE name = ''' + @v_bdd + ''' AND state = 2)
				ALTER DATABASE ' + @v_bdd + ' SET PARTNER OFF
			IF EXISTS (SELECT 1 FROM sys.databases WHERE name = ''' + @v_bdd + ''' AND state = 1)
				RESTORE DATABASE ' + @v_bdd + ' WITH RECOVERY					
			BACKUP DATABASE ' + @v_bdd + ' TO DISK = ''' + @v_bdd_backup_directory + @v_bdd_backup_database + ''' WITH FORMAT
			BACKUP LOG ' + @v_bdd + ' TO DISK = ''' + @v_bdd_backup_directory + @v_bdd_backup_log + ''' WITH FORMAT'
		EXEC (@v_sql)
		SET @v_error = @@ERROR
		IF @v_error = 0
		BEGIN
			SET @v_bdd_backup_files = '\\' + CONVERT(varchar(max), SERVERPROPERTY('ComputerNamePhysicalNetBIOS')) + @v_par_val + '\' + REPLACE(@v_bdd_backup_directory, ':', '$') + '*_mirroring.*'
			SET @v_sql = 'DECLARE @v_error int, @v_sql nvarchar(4000), @v_bdd_directory sysname, @v_bdd_backup_directory varchar(8000)
			SELECT @v_bdd_directory = SUBSTRING(physical_name, 1, CHARINDEX(''''\data'''', physical_name)) FROM master.sys.databases d LEFT OUTER JOIN master.sys.master_files m ON m.database_id = d.database_id WHERE d.name = ''''' + DB_NAME() + ''''' AND m.file_id = 1
			SET @v_bdd_backup_directory = @v_bdd_directory
			SET @v_sql = ''''IF NOT EXISTS (SELECT 1 FROM sys.sql_logins WHERE name = ''''''''''''''''tmpLogin'''''''''''''''')
				CREATE LOGIN tmpLogin WITH PASSWORD = '''''''''''''''''''''''''''''''', CHECK_POLICY = OFF
				IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = ''''''''''''''''tmpUser'''''''''''''''')
					CREATE USER tmpUser FOR LOGIN tmpLogin
				GRANT EXEC ON xp_cmdshell TO tmpUser''''
			SET @v_sql = ''''USE master; EXEC sp_executesql N'''''''''''' + @v_sql + '''''''''''' ''''
			EXEC (@v_sql)
			SET @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				SET @v_sql = ''''copy "' + @v_bdd_backup_files + '" "'''' + @v_bdd_backup_directory + ''''"''''
				EXECUTE AS LOGIN = ''''tmpLogin''''
				EXEC @v_error = master.dbo.xp_cmdshell @v_sql, no_output
				REVERT
				SET @v_sql = ''''DROP USER tmpUser
					DROP LOGIN tmpLogin''''
				SET @v_sql = ''''USE master; EXEC sp_executesql N'''''''''''' + @v_sql + ''''''''''''''''
				EXEC (@v_sql)
				IF @v_error = 0
				BEGIN
					IF EXISTS (SELECT 1 FROM sys.database_mirroring dm JOIN sys.databases d ON dm.database_id = d.database_id WHERE d.name = ''''' + @v_bdd + ''''' AND mirroring_guid IS NOT NULL)
						OR EXISTS (SELECT 1 FROM sys.databases WHERE name = ''''' + @v_bdd + ''''' AND state = 2)
						ALTER DATABASE ' + @v_bdd + ' SET PARTNER OFF
					IF EXISTS (SELECT 1 FROM sys.databases WHERE name = ''''' + @v_bdd + ''''' AND state = 1)
						RESTORE DATABASE ' + @v_bdd + ' WITH RECOVERY					
					ALTER DATABASE ' + @v_bdd + ' SET SINGLE_USER WITH ROLLBACK IMMEDIATE
					ALTER DATABASE ' + @v_bdd + ' SET MULTI_USER WITH ROLLBACK IMMEDIATE
					SET @v_sql = ''''RESTORE DATABASE ' + @v_bdd + ' FROM DISK = '''''''''''' + @v_bdd_backup_directory + ''''' + @v_bdd_backup_database + ''''''''' WITH NORECOVERY, REPLACE''''
					EXEC (@v_sql)
					SET @v_sql = ''''RESTORE LOG ' + @v_bdd + ' FROM DISK = '''''''''''' + @v_bdd_backup_directory + ''''' + @v_bdd_backup_log + ''''''''' WITH NORECOVERY''''
					EXEC (@v_sql)
				END
			END'
			SET @v_sql = 'EXEC (''' + @v_sql + ''') AT [' + @v_mirror_instance + ']'
			EXEC (@v_sql)
			SET @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				SET @v_sql = 'ALTER DATABASE ' + @v_bdd + ' SET PARTNER = ''''TCP://' + CONVERT(varchar(max), SERVERPROPERTY('ComputerNamePhysicalNetBIOS')) + @v_par_val + ':5022'''''
				SET @v_sql = 'EXEC (''' + @v_sql + ''') AT [' + @v_mirror_instance + ']'
				EXEC (@v_sql)
				SET @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					SET @v_sql = 'DECLARE @v_sql nvarchar(4000), @v_mirror_computer varchar(8000) EXEC [' + @v_mirror_instance + '].master.dbo.sp_executesql N''SELECT @v_mirror_computer = CONVERT(varchar(max), SERVERPROPERTY(''''ComputerNamePhysicalNetBIOS''''))'', N''@v_mirror_computer varchar(8000) out'', @v_mirror_computer out
						SET @v_sql = ''ALTER DATABASE ' + @v_bdd + ' SET PARTNER = ''''TCP://'' + @v_mirror_computer + ''' + @v_par_val + ''' + '':5022''''''
						EXEC (@v_sql)'
					EXEC (@v_sql)
					SET @v_error = @@ERROR
					IF @v_error = 0
						SET @v_retour = @CODE_OK
				END
			END
		END
	END
	ELSE IF @v_action = 2
	BEGIN
		SET @v_sql = 'USE master; ALTER DATABASE ' + @v_bdd + ' SET PARTNER FAILOVER'
		EXEC (@v_sql)
		SET @v_error = @@ERROR
		IF @v_error = 0
			SET @v_retour = @CODE_OK
	END
	ELSE IF @v_action = 3
	BEGIN
		SELECT @v_mirroring_state_data = dm.mirroring_state FROM sys.database_mirroring dm JOIN sys.databases d ON dm.database_id = d.database_id WHERE d.name = DB_NAME()
		SELECT @v_mirroring_state_log = dm.mirroring_state FROM sys.database_mirroring dm JOIN sys.databases d ON dm.database_id = d.database_id WHERE d.name = REPLACE(DB_NAME(), '_DATA', '_LOG')
		UPDATE PARAMETRE SET PAR_VAL = CASE WHEN @v_mirroring_state_data IS NULL AND @v_mirroring_state_log IS NULL THEN 0
			WHEN @v_mirroring_state_data IS NULL OR @v_mirroring_state_log IS NULL OR @v_mirroring_state_data IN (0, 1, 3) OR @v_mirroring_state_log IN (0, 1, 3) THEN 3
			WHEN @v_mirroring_state_data IN (2, 5) OR @v_mirroring_state_log IN (2, 5) THEN 1
			WHEN @v_mirroring_state_data IN (4, 6) AND @v_mirroring_state_log IN (4, 6) THEN 2
			ELSE 0 END WHERE PAR_NOM = 'MIR_STATE'
		SET @v_error = @@ERROR
		IF @v_error = 0
		BEGIN
			IF @v_mirroring_state_log = 0 AND @v_mirroring_state_data = 0
			BEGIN
				SET @v_sql = 'ALTER DATABASE ' + REPLACE(DB_NAME(), '_DATA', '_LOG') + ' SET PARTNER RESUME'
				EXEC (@v_sql)
				SET @v_sql = 'ALTER DATABASE ' + DB_NAME() + ' SET PARTNER RESUME'
				EXEC (@v_sql)
			END
		END
	END
	RETURN @v_retour

