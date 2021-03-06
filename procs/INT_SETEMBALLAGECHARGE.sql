SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

CREATE PROCEDURE [dbo].[INT_SETEMBALLAGECHARGE]
	@v_chg_idcharge int,
	@v_emb_idemballage tinyint
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
	@CODE_KO_INEXISTANT tinyint,
	@CODE_KO_INCONNU tinyint,
	@CODE_KO_SQL tinyint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_INEXISTANT = 4
	SET @CODE_KO_INCONNU = 7
	SET @CODE_KO_SQL = 13

-- Initialisation des variables
	SET @v_transaction = 'SETEMBALLAGECHARGE'
	SET @v_error = 0
	SET @v_retour = @CODE_KO

	IF @@TRANCOUNT > 0
		SET @v_local = 0
	ELSE
	BEGIN
		SET @v_local = 1
		BEGIN TRAN @v_transaction
	END
	-- Contrôle de l'existence de la charge
	IF EXISTS (SELECT 1 FROM INT_CHARGE_VIVANTE WHERE CHG_IDCHARGE = @v_chg_idcharge)
	BEGIN
		-- Contrôle de l'existence de l'emballage
		IF ((@v_emb_idemballage IS NULL) OR (@v_emb_idemballage IS NOT NULL AND EXISTS (SELECT 1 FROM EMBALLAGE WHERE EMB_ID = @v_emb_idemballage)))
		BEGIN
			UPDATE CHARGE SET CHG_EMBALLAGE = @v_emb_idemballage WHERE CHG_ID = @v_chg_idcharge
			SET @v_error = @@ERROR
			IF @v_error = 0
				SET @v_retour = @CODE_OK
			ELSE
				SET @v_retour = @CODE_KO_SQL
		END
		ELSE
			SET @v_retour = @CODE_KO_INCONNU
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

