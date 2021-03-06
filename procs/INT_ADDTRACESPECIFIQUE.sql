SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON

CREATE PROCEDURE [dbo].[INT_ADDTRACESPECIFIQUE]
	@v_mon_idmoniteur varchar(128),
	@v_log_idlog varchar(128),
	@v_trace varchar(7500)
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
	@v_serveur sysname,
	@v_base sysname,
	@v_commande varchar(8000)

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1

-- Initialisation des variables
	SET @v_error = 0
	SET @v_status = @CODE_KO
	SET @v_retour = @CODE_KO

	IF NOT EXISTS (SELECT 1 FROM MONITEUR WHERE MON_ID = @v_mon_idmoniteur)
	BEGIN
		INSERT INTO MONITEUR (MON_ID) VALUES (@v_mon_idmoniteur)
		INSERT INTO ASSOCIATION_LOG_MONITEUR (ALM_MONITEUR, ALM_LOG, ALM_ACTIF) SELECT @v_mon_idmoniteur, LOG_ID, 1 FROM LOG
	END
	IF NOT EXISTS (SELECT 1 FROM LOG WHERE LOG_ID = @v_log_idlog)
	BEGIN
		INSERT INTO LOG (LOG_ID) VALUES (@v_log_idlog)
		INSERT INTO ASSOCIATION_LOG_MONITEUR (ALM_MONITEUR, ALM_LOG, ALM_ACTIF) SELECT MON_ID, @v_log_idlog, 1 FROM MONITEUR
	END
	IF EXISTS (SELECT 1 FROM ASSOCIATION_LOG_MONITEUR WHERE ALM_MONITEUR = @v_mon_idmoniteur AND ALM_LOG = @v_log_idlog AND ALM_ACTIF = 1)
	BEGIN
		IF(@@TRANCOUNT > 0 )
		BEGIN
			SET @v_serveur = @@SERVERNAME
			SET @v_base = DB_NAME()
			SET @v_commande = 'sqlcmd -S ' + @v_serveur + ' -E -d ' + @v_base + ' -q "INSERT INTO TRACE_SPECIFIQUE (TRS_DATE, TRS_MONITEUR, TRS_LOG, TRS_TRACE) VALUES (GETDATE(), ''' + @v_mon_idmoniteur + ''', ''' + @v_log_idlog + ''', ''' + @v_trace + ''')"'
			EXEC @v_status = master.dbo.xp_cmdshell @v_commande, no_output
			SET @v_error = @@ERROR
			IF @v_status = @CODE_OK AND @v_error = 0
				SET @v_retour = @CODE_OK
			ELSE
				SET @v_retour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END
		END
		ELSE
		BEGIN
			INSERT INTO TRACE_SPECIFIQUE (TRS_DATE, TRS_MONITEUR, TRS_LOG, TRS_TRACE) VALUES (GETDATE(), @v_mon_idmoniteur, @v_log_idlog, @v_trace)
		END
	END
	RETURN @v_retour

