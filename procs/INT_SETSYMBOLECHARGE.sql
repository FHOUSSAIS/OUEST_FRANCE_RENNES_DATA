SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON

CREATE PROCEDURE [dbo].[INT_SETSYMBOLECHARGE]
	@v_chg_idcharge int,
	@v_sym_idsymbole varchar(32)
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

-- Déclaration des constantes de catégories
DECLARE
	@CATE_CHARGE tinyint

-- Définition des constantes
	SELECT @CODE_OK = 0
	SELECT @CODE_KO = 1
	SELECT @CODE_KO_INEXISTANT = 4
	SELECT @CODE_KO_INCONNU = 7
	SELECT @CODE_KO_SQL = 13
	SELECT @CATE_CHARGE = 5

-- Initialisation des variables
	SELECT @v_transaction = 'SETSYMBOLECHARGE'
	SELECT @v_error = 0
	SELECT @v_retour = @CODE_KO

	IF @@TRANCOUNT > 0
		SELECT @v_local = 0
	ELSE
	BEGIN
		SELECT @v_local = 1
		BEGIN TRAN @v_transaction
	END
	-- Contrôle de l'existence de la charge
	IF EXISTS (SELECT 1 FROM INT_CHARGE_VIVANTE WHERE CHG_IDCHARGE = @v_chg_idcharge)
	BEGIN
		-- Contrôle de l'existence du symbole
		IF EXISTS (SELECT 1 FROM ASSOCIATION_CATEGORIE_SYMBOLE WHERE ACM_SYMBOLE = @v_sym_idsymbole AND ACM_CATEGORIE = @CATE_CHARGE)
		BEGIN
			UPDATE CHARGE SET CHG_SYMBOLE = @v_sym_idsymbole WHERE CHG_ID = @v_chg_idcharge
			SELECT @v_error = @@ERROR
			IF @v_error = 0
				SELECT @v_retour = @CODE_OK
			ELSE
				SELECT @v_retour = @CODE_KO_SQL
		END
		ELSE
			SELECT @v_retour = @CODE_KO_INCONNU
	END
	ELSE
		SELECT @v_retour = @CODE_KO_INEXISTANT
	IF @v_local = 1
	BEGIN
		IF @v_retour <> @CODE_OK
			ROLLBACK TRAN @v_transaction
		ELSE
			COMMIT TRAN @v_transaction
	END
	RETURN @v_retour

