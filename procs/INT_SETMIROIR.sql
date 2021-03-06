SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER OFF

CREATE PROCEDURE [dbo].[INT_SETMIROIR]
	@v_action smallint
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- Déclaration des variables
DECLARE
	@v_errorData int,
	@v_statusData int,
	@v_errorLog int,
	@v_statusLog int,
	@v_retour int,
	@v_bddData sysname,
	@v_bddLog sysname
	
-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_INCORRECT tinyint,
	@CODE_KO_ACTION_INCORRECTE_1 tinyint,
	@CODE_KO_ACTION_INCORRECTE_2 tinyint,
	@CODE_KO_ACTION_INCORRECTE_3 tinyint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_INCORRECT = 11
	SET @CODE_KO_ACTION_INCORRECTE_1 = 21
	SET @CODE_KO_ACTION_INCORRECTE_2 = 22
	SET @CODE_KO_ACTION_INCORRECTE_3 = 23

-- Initialisation des variables
	SET @v_errorData = 0
	SET @v_statusData = @CODE_KO
	SET @v_errorLog = @CODE_KO
	SET @v_statusLog = @CODE_KO
	SET @v_retour = @CODE_OK
	
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED
	 
	IF @v_action IN (0, 1, 2)
	BEGIN
		SET @v_bddData = DB_NAME()
		SET @v_bddLog = REPLACE(DB_NAME(), '_DATA', '_LOG')
		IF @v_action IN (0, 2) AND NOT EXISTS (SELECT 1 FROM sys.database_mirroring dm JOIN sys.databases d ON dm.database_id = d.database_id WHERE d.name = @v_bddData AND mirroring_guid IS NOT NULL)
			AND NOT EXISTS (SELECT 1 FROM sys.database_mirroring dm JOIN sys.databases d ON dm.database_id = d.database_id WHERE d.name = @v_bddLog AND mirroring_guid IS NOT NULL)
			SET @v_retour = @CODE_KO_ACTION_INCORRECTE_1
		ELSE IF @v_action = 1 AND EXISTS (SELECT 1 FROM sys.database_mirroring dm JOIN sys.databases d ON dm.database_id = d.database_id WHERE d.name = @v_bddData AND mirroring_guid IS NOT NULL)
			AND EXISTS (SELECT 1 FROM sys.database_mirroring dm JOIN sys.databases d ON dm.database_id = d.database_id WHERE d.name = @v_bddLog AND mirroring_guid IS NOT NULL)
			SET @v_retour = @CODE_KO_ACTION_INCORRECTE_3
		ELSE IF @v_action = 2 AND NOT EXISTS (SELECT 1 FROM sys.database_mirroring dm JOIN sys.databases d ON dm.database_id = d.database_id WHERE d.name = @v_bddData AND mirroring_guid IS NOT NULL AND mirroring_state IN (4, 6))
			AND NOT EXISTS (SELECT 1 FROM sys.database_mirroring dm JOIN sys.databases d ON dm.database_id = d.database_id WHERE d.name = @v_bddLog AND mirroring_guid IS NOT NULL AND mirroring_state IN (4, 6))
			SET @v_retour = @CODE_KO_ACTION_INCORRECTE_2
		ELSE
		BEGIN
			EXEC @v_statusData = SPV_MIROIR @v_action, @v_bddLog
			SET @v_errorData = @@ERROR
			EXEC @v_statusLog = SPV_MIROIR @v_action, @v_bddData
			SET @v_errorLog = @@ERROR
			IF @v_statusData = 0 AND @v_statusLog = 0
				SET @v_retour = CASE @v_errorData WHEN 0 THEN @v_errorLog ELSE @v_errorData END
			ELSE
				SET @v_retour = CASE @v_statusData WHEN 0 THEN @v_statusLog ELSE @v_statusData END
		END
	END
	ELSE
		SET @v_retour = @CODE_KO_INCORRECT
	RETURN @v_retour

