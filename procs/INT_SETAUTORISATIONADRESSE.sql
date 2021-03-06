SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

CREATE PROCEDURE [dbo].[INT_SETAUTORISATIONADRESSE]
	@v_type smallint,
	@v_adr_idsysteme bigint,
	@v_adr_idbase bigint,
	@v_adr_idsousbase bigint,
	@v_adr_niveau tinyint = NULL,
	@v_adr_autorisation_prise bit = NULL,
	@v_adr_autorisation_depose bit = NULL
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
	@v_adr_idtypemagasin tinyint,
	@v_adr_rayonnage bit,
	@v_adr_accumulation bit

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_INCORRECT tinyint,
	@CODE_KO_SQL tinyint,
	@CODE_KO_INTERDIT tinyint,
	@CODE_KO_ADR_INCONNUE tinyint

-- Déclaration des constantes de types de magasins
DECLARE
	@TYPE_INTERFACE tinyint,
	@TYPE_STOCK tinyint,
	@TYPE_PREPARATION tinyint
	
-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_INCORRECT = 11
	SET @CODE_KO_SQL = 13
	SET @CODE_KO_INTERDIT = 18
	SET @CODE_KO_ADR_INCONNUE = 28
	SET @TYPE_INTERFACE = 2
	SET @TYPE_STOCK = 3
	SET @TYPE_PREPARATION = 4

-- Initialisation des variables
	SET @v_transaction = 'SETAUTORISATIONADRESSE'
	SET @v_error = 0
	SET @v_retour = @CODE_KO

	IF @@TRANCOUNT > 0
		SET @v_local = 0
	ELSE
	BEGIN
		SET @v_local = 1
		BEGIN TRAN @v_transaction
	END
	-- Contrôle de l'existence de l'adresse
	SELECT @v_adr_idtypemagasin = ADR_IDTYPEMAGASIN, @v_adr_rayonnage = ADR_RAYONNAGE, @v_adr_accumulation = ADR_ACCUMULATION FROM INT_ADRESSE WHERE ADR_IDSYSTEME = @v_adr_idsysteme AND ADR_IDBASE = @v_adr_idbase AND ADR_IDSOUSBASE = @v_adr_idsousbase
	IF @v_adr_rayonnage IS NOT NULL AND @v_adr_accumulation IS NOT NULL
	BEGIN
		IF @v_adr_idtypemagasin IN (@TYPE_INTERFACE, @TYPE_STOCK, @TYPE_PREPARATION)
		BEGIN
			IF @v_type IN (0, 1, 2)
			BEGIN
				IF ((@v_adr_autorisation_prise IS NOT NULL) OR (@v_adr_autorisation_depose IS NOT NULL))
				BEGIN
					IF NOT (@v_adr_rayonnage = 1 AND @v_adr_accumulation = 1) OR (@v_adr_rayonnage = 1 AND @v_adr_accumulation = 1 AND @v_adr_niveau IS NULL)
					BEGIN
						IF @v_type = 0
							UPDATE ADRESSE SET ADR_AUT_PRISE = CASE WHEN @v_adr_autorisation_prise IS NULL THEN ADR_AUT_PRISE ELSE @v_adr_autorisation_prise END,
								ADR_AUT_DEPOSE = CASE WHEN @v_adr_autorisation_depose IS NULL THEN ADR_AUT_DEPOSE ELSE @v_adr_autorisation_depose END
								WHERE ADR_SYSTEME = @v_adr_idsysteme AND ADR_BASE = @v_adr_idbase AND ADR_SOUSBASE = @v_adr_idsousbase
						ELSE IF @v_type = 1
						BEGIN
							IF NOT (@v_adr_rayonnage = 1 AND @v_adr_accumulation = 1)
								UPDATE ADRESSE SET ADR_AUT_PRISE = CASE WHEN @v_adr_autorisation_prise IS NULL THEN ADR_AUT_PRISE ELSE @v_adr_autorisation_prise END,
									ADR_AUT_DEPOSE = CASE WHEN @v_adr_autorisation_depose IS NULL THEN ADR_AUT_DEPOSE ELSE @v_adr_autorisation_depose END
									WHERE ADR_SYSTEME = @v_adr_idsysteme AND ADR_BASE = @v_adr_idbase
							ELSE
								UPDATE STRUCTURE SET STR_AUTORISATION_PRISE = CASE WHEN @v_adr_autorisation_prise IS NULL THEN STR_AUTORISATION_PRISE ELSE @v_adr_autorisation_prise END,
									STR_AUTORISATION_DEPOSE = CASE WHEN @v_adr_autorisation_depose IS NULL THEN STR_AUTORISATION_DEPOSE ELSE @v_adr_autorisation_depose END
									WHERE STR_SYSTEME = @v_adr_idsysteme AND STR_BASE = @v_adr_idbase AND STR_SOUSBASE = @v_adr_idsousbase
						END
						ELSE IF @v_type = 2
							UPDATE ADRESSE SET ADR_AUT_PRISE = CASE WHEN @v_adr_autorisation_prise IS NULL THEN ADR_AUT_PRISE ELSE @v_adr_autorisation_prise END,
								ADR_AUT_DEPOSE = CASE WHEN @v_adr_autorisation_depose IS NULL THEN ADR_AUT_DEPOSE ELSE @v_adr_autorisation_depose END
								FROM BASE, ADRESSE WHERE BAS_SYSTEME = @v_adr_idsysteme AND ADR_SYSTEME = BAS_SYSTEME AND ADR_BASE = BAS_BASE AND ((BAS_BASE - BAS_RACK)
								= (@v_adr_idbase - (SELECT BAS_RACK FROM BASE WHERE BAS_SYSTEME = @v_adr_idsysteme AND BAS_BASE = @v_adr_idbase)))
					END
					ELSE
					BEGIN
						IF @v_type IN (0, 2)
						BEGIN
							IF @v_type = 0
								UPDATE STRUCTURE SET STR_AUTORISATION_PRISE = CASE WHEN @v_adr_autorisation_prise IS NULL THEN STR_AUTORISATION_PRISE ELSE @v_adr_autorisation_prise END,
									STR_AUTORISATION_DEPOSE = CASE WHEN @v_adr_autorisation_depose IS NULL THEN STR_AUTORISATION_DEPOSE ELSE @v_adr_autorisation_depose END
									WHERE STR_SYSTEME = @v_adr_idsysteme AND STR_BASE = @v_adr_idbase AND STR_SOUSBASE = @v_adr_idsousbase
									AND STR_COUCHE = @v_adr_niveau
							ELSE IF @v_type = 2
								UPDATE STRUCTURE SET STR_AUTORISATION_PRISE = CASE WHEN @v_adr_autorisation_prise IS NULL THEN STR_AUTORISATION_PRISE ELSE @v_adr_autorisation_prise END,
									STR_AUTORISATION_DEPOSE = CASE WHEN @v_adr_autorisation_depose IS NULL THEN STR_AUTORISATION_DEPOSE ELSE @v_adr_autorisation_depose END
									FROM BASE, ADRESSE, STRUCTURE WHERE BAS_SYSTEME = @v_adr_idsysteme AND ADR_SYSTEME = BAS_SYSTEME AND ADR_BASE = BAS_BASE AND ((BAS_BASE - BAS_RACK)
									= (@v_adr_idbase - (SELECT BAS_RACK FROM BASE WHERE BAS_SYSTEME = @v_adr_idsysteme AND BAS_BASE = @v_adr_idbase)))
									AND STR_SYSTEME = ADR_SYSTEME AND STR_BASE = ADR_BASE AND STR_SOUSBASE = ADR_SOUSBASE AND STR_COUCHE = @v_adr_niveau
						END
						ELSE
							SET @v_retour = @CODE_KO_INCORRECT
					END
					SET @v_error = @@ERROR
					IF @v_error = 0
						SET @v_retour = @CODE_OK
					ELSE
						SET @v_retour = @CODE_KO_SQL
				END
				ELSE
					SET @v_retour = @CODE_KO_INCORRECT
			END
			ELSE
				SET @v_retour = @CODE_KO_INCORRECT
		END
		ELSE
			SET @v_retour = @CODE_KO_INTERDIT
	END
	ELSE
		SET @v_retour = @CODE_KO_ADR_INCONNUE
	IF @v_local = 1
	BEGIN
		IF @v_retour <> @CODE_OK
			ROLLBACK TRAN @v_transaction
		ELSE
			COMMIT TRAN @v_transaction
	END
	RETURN @v_retour


