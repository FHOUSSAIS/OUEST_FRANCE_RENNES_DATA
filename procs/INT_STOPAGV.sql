SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

CREATE  PROCEDURE [dbo].[INT_STOPAGV]
	@v_agv varchar(8000) = NULL
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- Déclaration des variables
DECLARE
	@v_local bit,
	@v_transaction varchar(32),
	@v_error int,
	@v_retour int,
	@v_sql varchar(8000)

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_SQL tinyint

-- Déclaration des constantes d'objets
DECLARE
	@OBJE_STOP_AGV tinyint

-- Définition des constantes
	SELECT @CODE_OK = 0
	SELECT @CODE_KO = 1
	SELECT @CODE_KO_SQL = 13
	SELECT @OBJE_STOP_AGV = 19

-- Initialisation des variables
	SELECT @v_transaction = 'STOPAGV'
	SELECT @v_error = 0
	SELECT @v_retour = @CODE_KO

	IF @@TRANCOUNT > 0
		SELECT @v_local = 0
	ELSE
	BEGIN
		SELECT @v_local = 1
		BEGIN TRAN @v_transaction
	END
	INSERT INTO JDB_EXPLOITATION (JDE_DATE, JDE_OBJECT, JDE_VALUE) VALUES (GETDATE(), @OBJE_STOP_AGV, @v_agv)
	SET @v_error = @@ERROR
	IF @v_error = 0
	BEGIN
		IF @v_agv = ''
			SET @v_agv = NULL
		IF @v_agv IS NULL
		BEGIN
			UPDATE INFO_AGV SET IAG_MOTIFARRETDISTANCE = 1
			SET @v_error = @@ERROR
		END
		ELSE
		BEGIN
			SET @v_sql = 'UPDATE INFO_AGV SET IAG_MOTIFARRETDISTANCE = 1 WHERE IAG_ID IN (' + @v_agv + ')'
			EXEC (@v_sql)
			SET @v_error = @@ERROR
		END
	END
	
	IF @v_error = 0
		SET @v_retour = @CODE_OK
	ELSE
		SET @v_retour = @CODE_KO_SQL
	IF @v_local = 1
	BEGIN
		IF @v_retour <> @CODE_OK
			ROLLBACK TRAN @v_transaction
		ELSE
			COMMIT TRAN @v_transaction
	END
	RETURN @v_retour



