SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

CREATE PROCEDURE [dbo].[INT_SETCAPACITEZONE]
	@v_zne_idzone int,
	@v_zne_capaciteminimale tinyint = NULL,
	@v_zne_capacitemaximale tinyint = NULL
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
	@CODE_KO_INCONNU tinyint,
	@CODE_KO_INCORRECT tinyint,
	@CODE_KO_SQL tinyint

-- Définition des constantes
	SELECT @CODE_OK = 0
	SELECT @CODE_KO = 1
	SELECT @CODE_KO_INCONNU = 7
	SELECT @CODE_KO_INCORRECT = 11
	SELECT @CODE_KO_SQL = 13

-- Initialisation des variables
	SELECT @v_transaction = 'SETCAPACITEZONE'
	SELECT @v_error = 0
	SELECT @v_retour = @CODE_KO

	IF @@TRANCOUNT > 0
		SELECT @v_local = 0
	ELSE
	BEGIN
		SELECT @v_local = 1
		BEGIN TRAN @v_transaction
	END
	-- Contrôle de l'existence de la zone
	IF EXISTS (SELECT 1 FROM INT_ZONE WHERE ZNE_IDZONE = @v_zne_idzone)
	BEGIN
		-- Contrôle de la cohérence des modifications
		IF NOT EXISTS (SELECT 1 FROM INT_ZONE WHERE ZNE_IDZONE = @v_zne_idzone AND ((@v_zne_capaciteminimale IS NOT NULL AND @v_zne_capacitemaximale IS NULL AND @v_zne_capaciteminimale > ZNE_CAPACITEMAXIMALE)
			OR (@v_zne_capacitemaximale IS NOT NULL AND @v_zne_capaciteminimale IS NULL AND @v_zne_capacitemaximale < ZNE_CAPACITEMINIMALE)
			OR (@v_zne_capaciteminimale IS NOT NULL AND @v_zne_capacitemaximale IS NOT NULL AND @v_zne_capaciteminimale > @v_zne_capacitemaximale)))
		BEGIN
			UPDATE ZONE SET ZNE_CAP_MIN = CASE WHEN @v_zne_capaciteminimale IS NULL THEN ZNE_CAP_MIN ELSE @v_zne_capaciteminimale END,
				ZNE_CAP_MAX = CASE WHEN @v_zne_capacitemaximale IS NULL THEN ZNE_CAP_MAX ELSE @v_zne_capacitemaximale END
				WHERE ZNE_ID = @v_zne_idzone
			SELECT @v_error = @@ERROR
			IF @v_error = 0
				SELECT @v_retour = @CODE_OK
			ELSE
				SELECT @v_retour = @CODE_KO_SQL
		END
		ELSE
			SELECT @v_retour = @CODE_KO_INCORRECT
	END
	ELSE
		SELECT @v_retour = @CODE_KO_INCONNU
	IF @v_local = 1
	BEGIN
		IF @v_retour <> @CODE_OK
			ROLLBACK TRAN @v_transaction
		ELSE
			COMMIT TRAN @v_transaction
	END
	RETURN @v_retour


