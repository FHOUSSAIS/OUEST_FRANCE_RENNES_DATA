SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

CREATE PROCEDURE [dbo].[INT_SETPRIORITEMISSION]
	@v_mis_idmission int,
	@v_mis_priorite int
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
	@CODE_KO_SQL tinyint,
	@CODE_KO_MISSION_INCONNUE tinyint

-- Définition des constantes
	SELECT @CODE_OK = 0
	SELECT @CODE_KO = 1
	SELECT @CODE_KO_SQL = 13 
	SELECT @CODE_KO_MISSION_INCONNUE = 31

-- Initialisation des variables
	SELECT @v_transaction = 'SETPRIORITEMISSION'
	SELECT @v_error = 0
	SELECT @v_retour = @CODE_KO
	
	IF @@TRANCOUNT > 0
		SELECT @v_local = 0
	ELSE
	BEGIN
		SELECT @v_local = 1
		BEGIN TRAN @v_transaction
	END
	-- Contrôle de l'existence de la mission
	IF EXISTS (SELECT 1 FROM INT_MISSION_VIVANTE WHERE MIS_IDMISSION = @v_mis_idmission)
	BEGIN
		UPDATE MISSION SET MIS_PRIORITE = @v_mis_priorite WHERE MIS_IDMISSION = @v_mis_idmission
		SELECT @v_error = @@ERROR
		IF @v_error = 0
			SELECT @v_retour = @CODE_OK
		ELSE
			SELECT @v_retour = @CODE_KO_SQL
	END
	ELSE
		SELECT @v_retour = @CODE_KO_MISSION_INCONNUE
	IF @v_local = 1
	BEGIN
		IF @v_retour <> @CODE_OK
			ROLLBACK TRAN @v_transaction
		ELSE
			COMMIT TRAN @v_transaction
	END
	RETURN @v_retour


