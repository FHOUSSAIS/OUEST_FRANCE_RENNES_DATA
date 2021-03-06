SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

CREATE  PROCEDURE [dbo].[INT_STOPAPPLICATION]
	@v_arret smallint
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
	@v_retour int

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_PARAM tinyint,
	@CODE_KO_SQL tinyint

-- Déclaration des constantes d'objets
DECLARE
	@OBJE_STOP_APPLICATION tinyint

-- Définition des constantes
	SELECT @CODE_OK = 0
	SELECT @CODE_KO = 1
	SELECT @CODE_KO_PARAM = 8
	SELECT @CODE_KO_SQL = 13
	SELECT @OBJE_STOP_APPLICATION = 24

-- Initialisation des variables
	SELECT @v_transaction = 'STOPAPPLICATION'
	SELECT @v_error = 0
	SELECT @v_retour = @CODE_KO

	IF @@TRANCOUNT > 0
		SELECT @v_local = 0
	ELSE
	BEGIN
		SELECT @v_local = 1
		BEGIN TRAN @v_transaction
	END
	IF @v_arret IN (1, 2, 3)
	BEGIN
		INSERT INTO JDB_EXPLOITATION (JDE_DATE, JDE_OBJECT, JDE_VALUE) VALUES (GETDATE(), @OBJE_STOP_APPLICATION, @v_arret)
		SELECT @v_error = @@ERROR
		IF @v_error = 0
			SELECT @v_retour = @CODE_OK
		ELSE
			SELECT @v_retour = @CODE_KO_SQL
	END
	ELSE
		SELECT @v_retour = @CODE_KO_PARAM
	IF @v_local = 1
	BEGIN
		IF @v_retour <> @CODE_OK
			ROLLBACK TRAN @v_transaction
		ELSE
			COMMIT TRAN @v_transaction
	END
	RETURN @v_retour



