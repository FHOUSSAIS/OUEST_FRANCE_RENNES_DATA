SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON

-----------------------------------------------------------------------------------------
-- Procédure		: CFG_MIROIR
-- Paramètre d'entrée	: @v_action : Action à mener
--						    0 : Première étape de mise en place du paramétrage
--						    1 : Deuxième étape de mise en place du paramétrage
-- (après l'exécution de la première étape sur le miroir)
--						    2 : Suppression du paramétrage
--						  @v_server1 : Instance serveur 1
--						  @v_server2 : Instance serveur 2
--						  @v_proxy_account : Compte proxy du serveur
--						  @v_password : Mot de passe
-- Paramètre de sortie	: 
-- Descriptif		: Paramétrage statique de la mise en miroir
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_MIROIR]
	@v_action smallint,
	@v_server1 varchar(max),
	@v_server2 varchar(max),
	@v_proxy_account varchar(max),
	@v_password varchar(max)
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
	@v_sql nvarchar(4000),
	@v_params nvarchar(32),	
	@v_date date,
	@v_mirror_instance varchar(max),
	@v_bdd_data sysname,
	@v_bdd_directory sysname,
	@v_principal_certificate_name varchar(max),
	@v_principal_certificate_file varchar(max),
	@v_mirror_certificate_name varchar(max),
	@v_mirror_certificate_file varchar(max),
	@v_mirror_endpoint varchar(max),
	@v_job_id binary(16),
	@v_job_name_statut varchar(255),
	@v_login sysname

-- Initialisation des variables
	SET @v_status = 0
	SET @v_retour = 0
	SET @v_error = 0
	
	SET @v_principal_certificate_name = @@SERVERNAME
	SET @v_principal_certificate_file = REPLACE(@v_principal_certificate_name, '\', '') + '.cer'
	IF @v_server1 = @@SERVERNAME
	BEGIN
		SET @v_mirror_instance = @v_server2
		SET @v_mirror_certificate_name = @v_server2
		SET @v_mirror_endpoint = @v_server2
	END
	ELSE
	BEGIN
		SET @v_mirror_instance = @v_server1
		SET @v_mirror_certificate_name = @v_server1
		SET @v_mirror_endpoint = @v_server1
	END
	SET @v_mirror_certificate_file = REPLACE(@v_mirror_certificate_name, '\', '') + '.cer'
	SET @v_job_id = NULL
	SET @v_bdd_data = DB_NAME()
	SET @v_job_name_statut = @v_bdd_data + '.Statut mise en miroir'
	SET @v_login = SYSTEM_USER
	SELECT @v_bdd_directory = SUBSTRING(physical_name, 1, CHARINDEX('\data', physical_name)) FROM sys.database_files WHERE file_id = 1
	IF @v_action = 0
	BEGIN
		SET @v_date = GETDATE()
		SET @v_sql = 'DECLARE @v_error int, @v_sql nvarchar(4000), @v_exists int IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = DB_NAME() AND is_master_key_encrypted_by_server = 1)	
			CREATE MASTER KEY ENCRYPTION BY PASSWORD = ''''' + @v_password + '''''
			SET @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				IF NOT EXISTS (SELECT 1 FROM sys.certificates WHERE name = ''''' + @v_principal_certificate_name + ''''')
					CREATE CERTIFICATE "' + @v_principal_certificate_name + '" WITH SUBJECT = ''''AGV Manager certificate mirroring'''', EXPIRY_DATE = ''''01/01/2100''''
				SET @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					IF NOT EXISTS (SELECT 1 FROM sys.endpoints WHERE name = ''''' + @v_mirror_endpoint + ''''')
						EXEC (''''CREATE ENDPOINT "' + @v_mirror_endpoint + '" STATE = STARTED AS TCP (LISTENER_PORT = 5022, LISTENER_IP = ALL) FOR DATABASE_MIRRORING (AUTHENTICATION = CERTIFICATE "' + @v_principal_certificate_name + '", ENCRYPTION = DISABLED, ROLE = ALL)'''')
					SET @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						EXEC xp_fileexist "' + @v_bdd_directory + @v_principal_certificate_file + '", @v_exists out
						SET @v_error = @@ERROR
						IF @v_error = 0 AND @v_exists = 1
						BEGIN
							SET @v_sql = ''''del "' + @v_bdd_directory + @v_principal_certificate_file + '"''''
							EXEC @v_error = master.dbo.xp_cmdshell @v_sql, no_output
						END
						IF @v_error = 0
							BACKUP CERTIFICATE "' + @v_principal_certificate_name + '" TO FILE = ''''' + @v_bdd_directory + @v_principal_certificate_file + '''''
					END
				END
			END'
		SET @v_sql = 'USE master; EXEC sp_executesql N''' + @v_sql + ''''
		EXEC (@v_sql)
		SET @v_error = @@ERROR
		IF @v_error = 0
		BEGIN
			SET @v_sql = 'DECLARE @v_error int IF NOT EXISTS (SELECT 1 FROM master.sys.servers WHERE name = ''' + @v_mirror_instance + ''')
			BEGIN
				EXEC master.dbo.sp_addlinkedserver @server = N''' + @v_mirror_instance + ''', @srvproduct = N''SQL Server''
				SET @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname = N''' + @v_mirror_instance + ''', @locallogin = N''' + SYSTEM_USER + ''', @useself = N''True''
					SET @v_error = @@ERROR
					IF @v_error = 0
						EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname = N''' + @v_mirror_instance + ''', @locallogin = NULL , @useself = N''False''
				END
			END'
			EXEC (@v_sql)
			SET @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				IF CHARINDEX('\', @v_proxy_account) = 0
					SET @v_proxy_account = CONVERT(varchar(max), SERVERPROPERTY('ComputerNamePhysicalNetBIOS')) + '\' + @v_proxy_account
				SET @v_sql = 'EXEC master.dbo.sp_xp_cmdshell_proxy_account ''' + @v_proxy_account + ''', ''' + @v_password + ''''
				BEGIN TRY
					EXEC (@v_sql)
					SET @v_error = @@ERROR
				END TRY
				BEGIN CATCH
					SET @v_error = 1734
				END CATCH
				IF @v_error = 0
				BEGIN
					IF NOT EXISTS (SELECT 1 FROM msdb.dbo.syscategories WHERE name = N'Evaluation données')
					BEGIN
						EXEC @v_status = msdb.dbo.sp_add_category @name = N'Evaluation données'
						SET @v_error = @@ERROR
					END
					IF ((@v_status = 0) AND (@v_error = 0))
					BEGIN
						SELECT @v_job_id = job_id FROM msdb.dbo.sysjobs WHERE name = @v_job_name_statut
						IF @v_job_id IS NULL
						BEGIN
							EXEC @v_status = msdb.dbo.sp_add_job @job_id = @v_job_id out, @job_name = @v_job_name_statut, @enabled = 1, @start_step_id = 1, @notify_level_eventlog = 2, @notify_level_email = 0, @notify_level_netsend = 0, @notify_level_page = 0, @delete_level = 0, @description = N'Mise à jour du statut de la mise en miroir', @category_name = N'Evaluation données', @owner_login_name = @v_login
							SET @v_error = @@ERROR
							IF ((@v_status = 0) AND (@v_error = 0))
							BEGIN
								EXEC @v_status = msdb.dbo.sp_add_jobstep @job_id = @v_job_id, @step_id = 1, @cmdEXEC_success_code = 0, @on_success_action = 1, @on_success_step_id = 0, @on_fail_action = 2, @on_fail_step_id = 0, @retry_attempts = 0, @retry_interval = 1, @flags = 0, @step_name = N'Etape statut mise en miroir', @subsystem = N'TSQL', @command = N'EXEC SPV_MIROIR 3, NULL', @server = @@SERVERNAME, @database_name = @v_bdd_data
								SET @v_error = @@ERROR
								IF ((@v_status = 0) AND (@v_error = 0))
								BEGIN
									EXEC @v_status = msdb.dbo.sp_update_job @job_id = @v_job_id, @start_step_id = 1
									SET @v_error = @@ERROR
									IF ((@v_status = 0) AND (@v_error = 0))
									BEGIN
										EXEC @v_status = msdb.dbo.sp_add_jobschedule @job_id = @v_job_id, @name = N'Planification statut mise en miroir', @enabled = 1, @freq_type = 4, @freq_interval = 1, @freq_subday_type = 2, @freq_subday_interval = 10, @freq_relative_interval = 0, @freq_recurrence_factor = 0, @active_start_date = 20051103, @active_end_date = 99991231, @active_start_time = 0, @active_end_time = 235959
										SET @v_error = @@ERROR
										IF ((@v_status = 0) AND (@v_error = 0))
										BEGIN
											EXEC @v_status = msdb.dbo.sp_add_jobserver @job_id = @v_job_id, @server_name = @@SERVERNAME
											SET @v_error = @@ERROR
										END
									END
								END
							END
						END
					END
					SET @v_retour = CASE @v_status WHEN 0 THEN @v_error ELSE @v_status END
				END
				ELSE
					SET @v_retour = @v_error
			END
			ELSE
				SET @v_retour = @v_error
		END
		ELSE
			SET @v_retour = @v_error
	END
	ELSE IF @v_action = 1
	BEGIN
		SET @v_sql = 'DECLARE @v_error int, @v_sql nvarchar(4000), @v_bdd_directory sysname, @v_mirror_computer varchar(8000), @v_mirror_certificate_file varchar(8000) EXEC [' + @v_mirror_instance + '].master.dbo.sp_executesql N''SELECT @v_mirror_computer = CONVERT(varchar(max), SERVERPROPERTY(''''ComputerNamePhysicalNetBIOS''''))'', N''@v_mirror_computer varchar(8000) out'', @v_mirror_computer out
			EXEC [' + @v_mirror_instance + '].master.dbo.sp_executesql N''SELECT @v_bdd_directory = SUBSTRING(physical_name, 1, CHARINDEX(''''\data'''', physical_name) ) FROM master.sys.databases d LEFT OUTER JOIN master.sys.master_files m ON m.database_id = d.database_id WHERE d.name = ''''' + DB_NAME() + ''''' AND m.file_id = 1'', N''@v_bdd_directory sysname out'', @v_bdd_directory out
			SET @v_mirror_certificate_file = ''\\'' + @v_mirror_computer + ''\'' + REPLACE(@v_bdd_directory, '':'', ''$'') + ''' + @v_mirror_certificate_file + '''
			SET @v_sql = ''IF NOT EXISTS (SELECT 1 FROM sys.sql_logins WHERE name = ''''''''tmpLogin'''''''')
				CREATE LOGIN tmpLogin WITH PASSWORD = '''''''''''''''', CHECK_POLICY = OFF
				IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = ''''''''tmpUser'''''''')
					CREATE USER tmpUser FOR LOGIN tmpLogin
				GRANT EXEC ON xp_cmdshell TO tmpUser''
			SET @v_sql = ''USE master; EXEC sp_executesql N'''''' + @v_sql + ''''''''
			EXEC (@v_sql)
			SET @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				SET @v_sql = ''copy "'' + @v_mirror_certificate_file + ''" "' + @v_bdd_directory + '"''
				USE master
				EXECUTE AS LOGIN = ''tmpLogin''
				EXEC master.dbo.xp_cmdshell @v_sql, no_output
				REVERT
				SET @v_sql = ''DROP USER tmpUser
					DROP LOGIN tmpLogin''
				SET @v_sql = ''USE master; EXEC sp_executesql N'''''' + @v_sql + ''''''''
				EXEC (@v_sql)
			END'
		EXEC (@v_sql)
		SET @v_error = @@ERROR
		IF @v_error = 0
		BEGIN
			SET @v_sql = 'IF NOT EXISTS (SELECT 1 FROM sys.certificates WHERE name = ''''' + @v_mirror_certificate_name + ''''')
				CREATE CERTIFICATE "' + @v_mirror_certificate_name + '" AUTHORIZATION dbo FROM FILE = ''''' + @v_bdd_directory + @v_mirror_certificate_file + ''''''
			SET @v_sql = 'USE master; EXEC sp_executesql N''' + @v_sql + ''''
			EXEC (@v_sql)
			SET @v_error = @@ERROR
		END
		SET @v_retour = @v_error
	END
	ELSE IF @v_action = 2
	BEGIN
		SET @v_job_id = NULL
		SELECT @v_job_id = job_id FROM msdb.dbo.sysjobs WHERE name = @v_job_name_statut
		IF @v_job_id IS NOT NULL
		BEGIN
			EXEC @v_status = msdb.dbo.sp_delete_job @job_id = @v_job_id, @delete_unused_schedule = 1
			SET @v_error = @@ERROR
		END
		IF ((@v_status = 0) AND (@v_error = 0))
		BEGIN
			SET @v_sql = 'EXEC master.dbo.sp_xp_cmdshell_proxy_account NULL'
			EXEC (@v_sql)
			SET @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				SET @v_sql = 'DECLARE @v_error int IF EXISTS (SELECT 1 FROM sys.certificates WHERE name = ''''' + @v_mirror_certificate_name + ''''')
					DROP CERTIFICATE "' + @v_mirror_certificate_name + '"
					SET @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						IF EXISTS (SELECT 1 FROM sys.endpoints WHERE name = ''''' + @v_mirror_endpoint + ''''')
						DROP ENDPOINT "' + @v_mirror_endpoint + '"
						SET @v_error = @@ERROR
						IF @v_error = 0
						BEGIN
							IF EXISTS (SELECT 1 FROM sys.certificates WHERE name = ''''' + @v_principal_certificate_name + ''''')
								DROP CERTIFICATE "' + @v_principal_certificate_name + '"			
							SET @v_error = @@ERROR
							IF @v_error = 0
							BEGIN
								IF EXISTS (SELECT 1 FROM sys.databases WHERE name = DB_NAME() AND is_master_key_encrypted_by_server = 1)	
									DROP MASTER KEY
							END
						END
					END'
				SET @v_sql = 'USE master; EXEC sp_executesql N''' + @v_sql + ''''
				EXEC (@v_sql)
				SET @v_error = @@ERROR
				SET @v_retour = @v_error
			END
			ELSE
				SET @v_retour = @v_error
		END
		ELSE
			SET @v_retour = CASE @v_status WHEN 0 THEN @v_error ELSE @v_status END
	END
	ELSE IF @v_action = 3
	BEGIN
			SET @v_sql = 'DECLARE @v_error int IF EXISTS (SELECT 1 FROM master.sys.servers WHERE name = ''' + @v_mirror_instance + ''')
				EXEC master.dbo.sp_dropserver @server = N''' + @v_mirror_instance + ''', @droplogins = N''droplogins'''
			EXEC (@v_sql)
			SET @v_retour = @@ERROR
	END
	RETURN @v_retour

