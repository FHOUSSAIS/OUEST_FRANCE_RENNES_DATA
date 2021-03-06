SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON

CREATE PROCEDURE [dbo].[INT_DELETEGABARIT]
	@v_gbr_idgabarit tinyint
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

DECLARE
	@v_local bit,
	@v_transaction varchar(32),
	@v_error int,
	@v_status int,
	@v_retour int,
	@v_tra_idtraduction int

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_INEXISTANT tinyint,
	@CODE_KO_SQL tinyint,
	@CODE_KO_INATTENDU tinyint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_INEXISTANT = 4
	SET @CODE_KO_SQL = 13
	SET @CODE_KO_INATTENDU = 16

-- Initialisation des variables
	SET @v_transaction = 'DELETEGABARIT'
	SET @v_error = 0
	SET @v_status = @CODE_KO
	SET @v_retour = @CODE_KO

	IF @@TRANCOUNT > 0
		SET @v_local = 0
	ELSE
	BEGIN
		SET @v_local = 1
		BEGIN TRAN @v_transaction
	END
	-- Contrôle de l'existence du gabarit
	IF EXISTS (SELECT 1 FROM INT_GABARIT WHERE GBR_IDGABARIT = @v_gbr_idgabarit)
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM INT_CHARGE_VIVANTE WHERE CHG_IDGABARIT = @v_gbr_idgabarit)
		BEGIN
			SELECT @v_tra_idtraduction = GBR_IDTRADUCTION FROM INT_GABARIT WHERE GBR_IDGABARIT = @v_gbr_idgabarit
			DELETE GABARIT WHERE GBR_ID = @v_gbr_idgabarit
			SET @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				EXEC @v_status = LIB_TRADUCTION 2, NULL, NULL, @v_tra_idtraduction out
				SET @v_error = @@ERROR
				IF @v_status = @CODE_OK AND @v_error = 0
					SET @v_retour = @CODE_OK
				ELSE
					SET @v_retour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END
			END
			ELSE
				SET @v_retour = @CODE_KO_SQL
		END
		ELSE
			SET @v_retour = @CODE_KO_INATTENDU
	END
	ELSE
		SET @v_retour = @CODE_KO_INEXISTANT
	IF @v_local = 1
	BEGIN
		IF @v_retour <> @CODE_OK
			ROLLBACK TRAN @v_transaction
		ELSE
			COMMIT TRAN @v_transaction
	END
	RETURN @v_retour

