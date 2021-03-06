SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON

-----------------------------------------------------------------------------------------
-- Procedure		: LIB_ADDTRACELOGICIEL
-- Paramètre d'entrée	:
-- Paramètre de sortie	:
-- Descriptif		: Ajout d'une trace logiciel
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].LIB_ADDTRACELOGICIEL
	@v_moniteur varchar(8000),
	@v_type varchar(8000),
	@v_debogage varchar(8000),
	@v_poste varchar(256),
	@v_utilisateur varchar(16),
	@v_message varchar(8000)
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
	@v_retour int,
	@v_base sysname,
	@v_sql varchar(8000)

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_SQL tinyint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_SQL = 13

-- Initialisation des variables
	SET @v_error = 0
	SET @v_retour = @CODE_KO

	BEGIN TRAN
	SET @v_base = REPLACE(DB_NAME(), '_DATA', '_LOG')
	SET @v_sql = 'INSERT INTO ' + @v_base + '.dbo.TRACE_LOGICIEL (TRL_DATE, TRL_MONITEUR, TRL_TYPE, TRL_DEBOGAGE, TRL_POSTE, TRL_UTILISATEUR, TRL_MESSAGE)
		VALUES (GETDATE(), ''' + @v_moniteur + ''', ''' + @v_type + ''', ''' + @v_debogage + ''', ''' + @v_poste + ''', ''' + ISNULL(@v_utilisateur, '') + ''', ''' + @v_message + ''')'
	EXEC (@v_sql)
	SET @v_error = @@ERROR
	IF @v_error = 0
		SELECT @v_retour = @CODE_OK
	ELSE
		SELECT @v_retour = @CODE_KO_SQL
	IF @v_error <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_retour

